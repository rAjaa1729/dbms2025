create table player(
    player_id varchar(20) primary key not null,
    player_name varchar(255) not null,
    dob date check (dob < '2016-01-01') not null,
    batting_hand varchar(20) check (batting_hand in ('left','right')) not null,
    bowling_skill varchar(20) check (bowling_skill in ('fast','medium','legspin','offspin')),
    country_name varchar(20) not null
);


create table team(
    team_id varchar(20) primary key not null,
    team_name varchar(255) unique not null,
    coach_name varchar(255) not null,
    region varchar(20) unique not null
);

create table season(
    season_id varchar(20) primary key not null,
    year smallint check(year between 1900 and 2025) not null,
    start_date date not null,
    end_date date not null
);

create table match(
    match_id varchar(20) primary key,
    match_type varchar(20) check ( match_type in ('league','playoff','knockout')) not null,
    venue varchar(20) not null,
    team_1_id varchar(20) references team(team_id) not null,
    team_2_id varchar(20) references team(team_id) not null,
    match_date date not null,
    season_id varchar(20) references season(season_id) not null,
    win_run_margin smallint,
    win_by_wickets smallint,
    win_type varchar(20) check ( win_type in ('runs','wickets','draw')),
    toss_winner smallint check ( toss_winner in (1,2)),
    toss_decide varchar(20) check ( toss_decide in ('bowl','bat')),
    winner_team_id varchar(20) references team(team_id),
    check(
        win_type is null
        or (win_type = 'draw' and win_run_margin is null and win_by_wickets is null)
        or (win_type = 'runs' and win_run_margin is not null and win_by_wickets is null)
        or (win_type = 'wickets' and win_run_margin is null and win_by_wickets is not null)
    )
);

create table player_match(
    player_id varchar(20) references player(player_id) not null,
    match_id varchar(20) references match(match_id) not null,
    role varchar(20)    check(role in ('bowler','batter','allrounder','wicketkeeper')) not null,
    team_id varchar(20) references team(team_id) not null,
    is_extra boolean not null,
    primary key (player_id,match_id)
);

create table auction(
    auction_id varchar(20) primary key not null,
    season_id varchar(20) references season(season_id) not null,
    player_id varchar(20)  references player(player_id) not null,
    base_price bigint check( base_price >= 1000000) not null,
    sold_price bigint,
    is_sold boolean not null,
    team_id varchar(20)     references team(team_id),
    check(is_sold is false or (is_sold is true and sold_price is not null and team_id is not null and sold_price >= base_price)),
    unique(player_id,team_id,season_id)
);

create table awards(
    match_id varchar(20) references match(match_id) not null,
    award_type varchar(20) check (award_type in ('orange_cap','purple_cap')) not null,
    player_id varchar(20) references player(player_id) not null,
    primary key (match_id, award_type)
);


create table player_team (
    player_id varchar(20) references player(player_id) not null,
    team_id varchar(20) references team(team_id) not null,
    season_id varchar(20) references season(season_id) not null,
    primary key(player_id,team_id,season_id),
    foreign key (player_id, team_id, season_id)
        references auction(player_id, team_id, season_id)
);




create table balls (
    match_id varchar(20) references match(match_id) not null,
    innings_num smallint not null,
    over_num smallint not null,
    ball_num smallint not null,
    striker_id varchar(20) references player(player_id) not null,
    non_striker_id varchar(20) references player(player_id) not null,
    bowler_id varchar(20) references player(player_id) not null,
    primary key ( match_id,innings_num,over_num,ball_num)
);

create table batter_score (
    match_id varchar(20) references match(match_id) not null,
    over_num smallint not null,
    innings_num smallint not null,
    ball_num smallint not null,
    run_scored smallint check(run_scored >= 0) not null,
    type_run varchar(20) check ( type_run in ('running','boundary')),
    primary key (match_id,over_num,innings_num,ball_num),
    foreign key (match_id,over_num,innings_num,ball_num)
        references balls(match_id,over_num,innings_num,ball_num)
);

create table extras (
    match_id varchar(20) references match(match_id) not null,
    innings_num smallint not null,
    over_num smallint not null,
    ball_num smallint not null,
    extra_runs smallint check (extra_runs >= 0) not null,
    extra_type varchar(20) check( extra_type in ('no_ball','wide','byes','legbyes')) not null,
    primary key (match_id,innings_num,over_num,ball_num),
    foreign key (match_id,innings_num,over_num,ball_num)
        references balls(match_id,innings_num,over_num,ball_num)
);

create table wickets (
    match_id varchar(20) references match(match_id) not null,
    innings_num smallint not null,
    over_num smallint not null,
    ball_num smallint not null,
    player_out_id varchar(20) references player(player_id) not null,
    kind_out varchar(20) check (kind_out in ('bowled','caught','lbw','runout','stumped','hitwicket')) not null,
    fielder_id varchar(20) references player(player_id),
    check(
        (kind_out in ('caught','runout','stumped') and fielder_id is not null)
        or (kind_out not in  ('caught','runout','stumped'))
    ),
    primary key (match_id,innings_num,over_num,ball_num),
    foreign key (match_id,innings_num,over_num,ball_num)
        references balls(match_id,innings_num,over_num,ball_num)
);




-- wicket keeper validation : check done
create or replace function validate_wicketkeeper_role()
returns trigger as 
$$
begin 
    if new.kind_out = 'stumped' then
        if not exists (
            select true 
            from player_match 
            where player_id = new.fielder_id
            and role = 'wicketkeeper'
            and match_id = new.match_id
        ) then
            raise exception 'for stumped dismissal, fielder must be a wicketkeeper';
        end if;
    end if;
    return new;
end;
$$ 
language plpgsql;

create trigger check_wicketkeeper_role
before insert or update on wickets
for each row 
execute function validate_wicketkeeper_role();

-- automatic insertion into player team : check done
create or replace function play_team_by_auction()
returns trigger as 
$$
begin 
    if new.is_sold = true then
        insert into player_team (player_id,team_id,season_id)
        values (new.player_id,new.team_id,new.season_id);
    end if;
    return new;
end;
$$ 
language plpgsql;

create trigger player_team_dueto_auction
after insert on auction
for each row
execute function play_team_by_auction();

-- automatic season id generation : check done
create or replace function update_season_id()
returns trigger  as 
$$
begin
    new.season_id = 'IPL' || new.year;
    return new;
end;
$$ 
language plpgsql;

create trigger generate_season_id
before insert on season
for each row
execute function update_season_id();

-- match_id validation  : checked
create or replace function insert_validate_match_id()
returns trigger as $$
declare 
    maxserial int;
    expected_match_id varchar(20);

begin

    select coalesce(max(right(match_id,3)::int),0)
    into maxserial 
    from match
    where season_id = new.season_id;

    expected_match_id := new.season_id || lpad((maxserial+1)::text,3,'0');
    
    if new.match_id <> expected_match_id then
        raise exception 'sequence of match id violated';
    end if;

    return new;
end; 
$$ language plpgsql;

create trigger insert_check_match_id
before insert on match
for each row 
execute function insert_validate_match_id();

-- limit on internation player per team : checked
create or replace function check_inter_player()
returns trigger as 
$$
declare
    num_player int;
    player_type varchar(20);
begin

    select country_name 
    into player_type
    from player 
    where player_id = new.player_id;
    if player_type <> 'India' then 

        select coalesce(count(*),0)
        into num_player
        from player_team  as pt join player as p on pt.player_id = p.player_id
        where new.season_id = pt.season_id and p.country_name <> 'India' and team_id = new.team_id;

        if num_player>3 then
            raise exception 'there could be atmost 3 international player per team per season';
        end if;
        
    end if;
    return new;
end;
$$ 
language plpgsql;

create trigger limit_inter_player
after insert or update on player_team
for each row
execute function check_inter_player();

-- limit on number of home matches : checked

declare 
    team_1_region varchar(20);
    team_2_region varchar(20);
    count_1 int;
    count_2 int;
begin
    if new.match_type = 'league' then
        select region into team_1_region
        from team where team_id = new.team_1_id;

        select region into team_2_region 
        from team where team_id = new.team_2_id;

        if (new.venue <> team_1_region and new.venue <> team_2_region) then
            raise exception 'league match must be played at home ground of one of the teams';
        end if;

        select coalesce(count(*),0) into count_1
        from match
        where ((team_1_id = new.team_1_id and team_2_id = new.team_2_id)
        or (team_1_id = new.team_2_id and team_2_id = new.team_1_id))
        and venue = team_1_region;

        select coalesce(count(*),0) into count_2
        from match
        where ((team_1_id = new.team_2_id and team_2_id = new.team_2_id)
        or (team_1_id = new.team_2_id and team_2_id = new.team_1_id))
        and venue = team_2_region;


        if (count_1 >1 or count_2 > 1 ) then
            raise exception 'each team can play only one home match in a league against another team';
        end if;
    end if;
    return new;
end;
$$
language plpgsql;


create trigger limit_count_home_matches
after insert or update on match
for each row
execute function limit_home_matches();

--  updating match row : checked
%%sql
create or replace function updating_match_row()
returns trigger as 
$$
declare
    best_batter varchar(20);
    best_bowler varchar(20);
begin
    if new.win_type='draw' then
        new.winner_team_id := null;
    end if;
    if new.win_type='runs' then
        new.winner_team_id = 
        case 
            when old.toss_winner = 1 and old.toss_decide = 'bat' then old.team_2_id
            when old.toss_winner = 1 and old.toss_decide = 'bowl'then  old.team_1_id
            when old.toss_winner = 2 and old.toss_decide = 'bat' then old.team_1_id
            when old.toss_winner = 2 and old.toss_decide = 'bowl'then  old.team_2_id
        end;
    end if;
    if new.win_type='wickets' then
        new.winner_team_id = 
        case 
            when old.toss_winner = 1 and old.toss_decide = 'bat' then old.team_1_id
            when old.toss_winner = 1 and old.toss_decide = 'bowl'then  old.team_2_id
            when old.toss_winner = 2 and old.toss_decide = 'bat' then old.team_2_id
            when old.toss_winner = 2 and old.toss_decide = 'bowl'then  old.team_1_id
        end;
    end if;
    -- awards updated 
    
    select striker_id
    into best_batter 
    from balls as b join batter_score as bt
    on b.match_id = bt.match_id
    and b.innings_num = bt.innings_num
    and b.over_num = bt.over_num
    and b.ball_num = bt.ball_num
    where b.match_id = new.match_id
    group by striker_id
    order by sum(run_scored) desc,striker_id
    limit 1;

    select bowler_id 
    into best_bowler
    from balls as b join wickets as w
    on b.match_id = w.match_id
    and b.innings_num = w.innings_num
    and b.over_num = w.over_num
    and b.ball_num = w.ball_num
    where b.match_id = new.match_id
    group by bowler_id
    order by count(*) desc,bowler_id
    limit 1;

    if best_batter is not null then
        insert into awards (match_id,award_type,player_id)
        values (new.match_id,'orange_cap',best_batter);
    end if;

    if best_bowler is not null then
        insert into awards (match_id,award_type,player_id)
        values (new.match_id,'purple_cap',best_bowler);
    end if;

    return new;
end;
$$
language plpgsql;


create trigger update_match_row
before update on match
for each row
when (old.win_type is null and new.win_type is not null)
execute function updating_match_row();

-- auction deletion
create or replace function auction_delete_cascade()
returns trigger as 
$$
begin
    -- Create a temporary table to store bad balls
    create temporary table bad_balls (
        match_id varchar(20),
        innings_num smallint,
        over_num smallint,
        ball_num smallint
    );

    -- storing bad balls
    insert into bad_balls (match_id, innings_num, over_num, ball_num)
    select b.match_id, b.innings_num, b.over_num, b.ball_num
    from balls as b
    where left(b.match_id, 7) = old.season_id
    and (b.striker_id = old.player_id 
        or b.non_striker_id = old.player_id 
        or b.bowler_id = old.player_id);

    -- storing bad balls
    insert into bad_balls (match_id, innings_num, over_num, ball_num)
    select w.match_id, w.innings_num, w.over_num, w.ball_num
    from wickets as w
    where left(w.match_id, 7) = old.season_id
    and (w.fielder_id = old.player_id 
        or w.player_out_id = old.player_id);

    -- remove from batter score
    delete from batter_score as bs
    where exists (
        select 1
        from bad_balls as tbb
        where bs.match_id = tbb.match_id 
        and bs.innings_num = tbb.innings_num 
        and bs.over_num = tbb.over_num 
        and bs.ball_num = tbb.ball_num
    );

    -- remove from extras 
    delete from extras as e
    where exists (
        select 1
        from bad_balls as tbb
        where e.match_id = tbb.match_id 
        and e.innings_num = tbb.innings_num 
        and e.over_num = tbb.over_num 
        and e.ball_num = tbb.ball_num
    );

    -- removing wickets related 
    delete from wickets as w
    where exists (
        select 1
        from bad_balls as tbb
        where w.match_id = tbb.match_id 
        and w.innings_num = tbb.innings_num 
        and w.over_num = tbb.over_num 
        and w.ball_num = tbb.ball_num
    );

    -- removing bad balls
    delete from balls as b
    where exists (
        select 1
        from bad_balls as tbb
        where b.match_id = tbb.match_id 
        and b.innings_num = tbb.innings_num 
        and b.over_num = tbb.over_num 
        and b.ball_num = tbb.ball_num
    );

    -- Clean up the temporary table
    drop table if exists bad_balls;

    -- Return the old record
    return old;
end;
$$
language plpgsql;

create trigger auction_delete 
after delete on auction
for each row 
when (old.is_sold is true)
execute function auction_delete_cascade();


-- match deletion 
replace or create function match_delete()
returns trigger as 
$$
begin
    delete from awards where match_id = old.match_id;
    delete from balls where match_id = old.match_id;
    delete from batter_score where match_id = old.match_id;
    delete from extras where match_id = old.match_id;
    delete from wickets where match_id = old.match_id;
    delete from player_match where match_id = old.match_id;
end;
$$
language plpgsql;

create trigger match_delete_cascade
after delete on match
for each row 
execute function match_delete();

-- season deletion 
create or replace function season_delete()
return trigger as 
$$
begin   
    delete from auction where season_id = old.season_id;
    delete from awards where left(match_id,7) = old.season_id;
    delete from balls where left(match_id,7) = old.season_id;
    delete from batter_score where left(match_id,7) = old.season_id;
    delete from extras where left(match_id,7) = old.season_id;
    delete from match where season_id = old.season_id;
    delete from player_match where left(match_id,7) = old.season_id;
    delete from player_team where season_id = old.season_id;
    delete from wickets where left(match_id,7) = old.season_id;
end;
$$
language plpgsql;

create trigger season_delete_cascase
after delete on season
for each row
execute function season_delete();

-- view for batter_stats 

create or replace view batter_stats as 
with player_Mat as (
    select p.player_id, coalesce(count(distinct match_id), 0) as Mat
    from player as p 
    join player_match as pm on p.player_id = pm.player_id 
    group by p.player_id
),
player_Inns as (
    select striker_id as player_id, coalesce(count(distinct match_id), 0) as Inns
    from balls
    group by striker_id
),
player_R as (
    select striker_id as player_id, coalesce(sum(run_scored), 0) as R 
    from balls as b 
    left join batter_score as bs 
    on b.match_id = bs.match_id
    and b.innings_num = bs.innings_num 
    and b.over_num = bs.over_num
    and b.ball_num = bs.ball_num
    group by striker_id
),
player_runs_innings as (
    select striker_id as player_id, b.match_id, coalesce(sum(run_scored), 0) as runs 
    from balls as b 
    left join batter_score as bs 
    on b.match_id = bs.match_id
    and b.innings_num = bs.innings_num 
    and b.over_num = bs.over_num
    and b.ball_num = bs.ball_num
    group by striker_id, b.match_id
),
player_HS as (
    select player_id, max(runs) as HS
    from player_runs_innings
    group by player_id
),
player_dismissals as (
    select player_out_id as player_id, count(distinct match_id) as dismissals 
    from wickets 
    group by player_out_id
),
player_Avg as (
    select pr.player_id, 
        case when coalesce(d.dismissals, 0) = 0 then 0 
        else pr.R::numeric / d.dismissals 
        end as Avg
    from player_R pr
    left join player_dismissals d on pr.player_id = d.player_id
),
player_100s as (
    select player_id, count(distinct match_id) as hundreds
    from player_runs_innings 
    where runs >= 100
    group by player_id
),
player_50s as (
    select player_id, count(distinct match_id) as fifties
    from player_runs_innings 
    where runs >= 50 and runs < 100
    group by player_id
),
player_ducks as (
    select w.player_out_id as player_id, coalesce(count(distinct p.match_id), 0) as ducks
    from player_runs_innings as p 
    join wickets as w
    on p.player_id = w.player_out_id 
    and p.match_id = w.match_id 
    and p.runs = 0
    group by w.player_out_id
),
player_BF as (
    select striker_id as player_id, coalesce(count(*), 0) as BF
    from balls 
    where ball_num is not null
    group by striker_id
),
player_boundaries as (
    select striker_id as player_id, coalesce(count(*), 0) as boundaries
    from balls as b 
    join batter_score as bs
    on b.match_id = bs.match_id
    and b.innings_num = bs.innings_num 
    and b.over_num = bs.over_num
    and b.ball_num = bs.ball_num
    where type_run = 'boundary'
    group by striker_id
),
player_not_outs as (
    select b.striker_id as player_id, coalesce(count(distinct b.match_id), 0) as not_outs
    from balls as b 
    left join wickets as w
    on b.match_id = w.match_id
    and b.innings_num = w.innings_num 
    and b.over_num = w.over_num 
    and b.ball_num = w.ball_num
    where w.match_id is null
    group by b.striker_id
)
select 
    pm.player_id,
    coalesce(pm.Mat, 0) as Mat,
    coalesce(pi.Inns, 0) as Inns,
    coalesce(pr.R, 0) as Runs,
    coalesce(ph.HS, 0) as HS,
    coalesce(pa.Avg, 0) as Avg,
    coalesce(p100.hundreds, 0) as "100s",
    coalesce(p50.fifties, 0) as "50s",
    coalesce(pd.ducks, 0) as Ducks,
    coalesce(pb.BF, 0) as BF,
    coalesce(pbnd.boundaries, 0) as Boundaries,
    coalesce(pno.not_outs, 0) as NO
from player_Mat pm
left join  player_Inns pi on pm.player_id = pi.player_id
left join player_R pr on  pm.player_id = pr.player_id
left join player_HS ph on pm.player_id = ph.player_id
left join player_Avg pa  on pm.player_id =  pa.player_id
left join player_100s p100 on pm.player_id = p100.player_id
left join player_50s p50  on pm.player_id = p50.player_id
left join player_ducks  pd on pm.player_id = pd.player_id
left join player_BF pb  on pm.player_id  = pb.player_id
left join player_boundaries pbnd  on pm.player_id = pbnd.player_id
left join player_not_outs  pno on pm.player_id = pno.player_id;

-- bowler_stats 
create or replace view bowler_stats as 
with bowler_B as (
    select bowler_id as player_id, count(*) as B
    from balls
    group by bowler_id
),
bowler_W as (
    select bowler_id as player_id, count(*) as W
    from balls as b 
    join wickets as w
    on b.match_id = w.match_id
    and b.innings_num = w.innings_num
    and b.over_num = w.over_num
    and b.ball_num = w.ball_num
    where w.kind_out in ('bowled', 'caught', 'lbw', 'stumped')
    group by bowler_id
),
bowler_Runs as (
    select bowler_id as player_id, coalesce(sum(bs.run_scored), 0) + coalesce(sum(e.extra_runs), 0) as Runs
    from balls as b
    left join batter_score as bs 
    on b.match_id = bs.match_id
    and b.innings_num = bs.innings_num 
    and b.over_num = bs.over_num
    and b.ball_num = bs.ball_num
    left join extras as e 
    on b.match_id = e.match_id
    and b.innings_num = e.innings_num 
    and b.over_num = e.over_num
    and b.ball_num = e.ball_num
    group by bowler_id
),
bowler_Over as (
    select bowler_id as player_id, 
           count(distinct concat(match_id, innings_num, over_num)) as total_overs
    from balls
    group by bowler_id
),
bowler_Avg as (
    select br.player_id, 
           case when coalesce(bw.W, 0) = 0 then 0 
           else cast(br.Runs as double precision) / cast(bw.W as double precision)
           end as Avg
    from bowler_Runs as br
    left join bowler_W as bw on br.player_id = bw.player_id
),
bowler_Econ as (
    select br.player_id,
           case when coalesce(bo.total_overs, 0) = 0 then 0 
           else cast(br.Runs as double precision) / (cast(bo.total_overs * 6 as double precision))
           end as Econ
    from bowler_Runs as br
    left join bowler_Over as bo on br.player_id = bo.player_id
),
bowler_SR as (
    select bb.player_id, 
           case when coalesce(bw.W, 0) = 0 then 0 
           else cast(bb.B as double precision) / cast(bw.W as double precision)
           end as SR
    from bowler_B as bb
    left join bowler_W as bw on bb.player_id = bw.player_id
),
bowler_Extras as (
    select bowler_id as player_id, coalesce(sum(e.extra_runs), 0) as Extras
    from balls as b
    left join extras as e 
    on b.match_id = e.match_id
    and b.innings_num = e.innings_num 
    and b.over_num = e.over_num
    and b.ball_num = e.ball_num
    group by bowler_id
)
select 
    bb.player_id,
    coalesce(bb.B, 0) as B,
    coalesce(bw.W, 0) as W,
    coalesce(br.Runs, 0) as Runs,
    coalesce(ba.Avg, 0)::double precision as Avg,
    coalesce(be.Econ, 0)::double precision as Econ,
    coalesce(bs.SR, 0)::double precision as SR,
    coalesce(bex.Extras, 0) as Extras
from bowler_B bb
left join bowler_W bw on bb.player_id = bw.player_id
left join bowler_Runs br on bb.player_id = br.player_id
left join bowler_Avg ba on bb.player_id = ba.player_id
left join bowler_Econ be on bb.player_id = be.player_id
left join bowler_SR bs on bb.player_id = bs.player_id
left join bowler_Extras bex on bb.player_id = bex.player_id;

-- fielder stats

create or replace view fielder_stats as 
with fielder_C as (
    select fielder_id as player_id, count(*) as C
    from wickets
    where kind_out = 'caught'
    group by fielder_id
),
fielder_St as (
    select fielder_id as player_id, count(*) as St
    from wickets
    where kind_out = 'stumped'
    group by fielder_id
),
fielder_RO as (
    select fielder_id as player_id, count(*) as RO
    from wickets
    where kind_out = 'runout'
    group by fielder_id
)
select 
    p.player_id,
    coalesce(fc.C, 0) as C,
    coalesce(fs.St, 0) as St,
    coalesce(fro.RO, 0) as RO
from player p
left join fielder_C fc on p.player_id = fc.player_id
left join fielder_St fs on p.player_id = fs.player_id
left join fielder_RO fro on p.player_id = fro.player_id;

