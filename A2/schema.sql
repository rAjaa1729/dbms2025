%%sql
create table season(
    season_id varchar(20) primary key not null,
    year smallint check(year between 1900 and 2025) not null,
    start_date date not null,
    end_date date not null
);

create table team(
    team_id varchar(20) primary key not null,
    team_name varchar(255) unique not null,
    coach_name varchar(255) not null,
    region varchar(20) unique not null
);

create table player(
    player_id varchar(20) primary key not null,
    player_name varchar(255) not null,
    dob date check (dob < '2016-01-01') not null,
    batting_hand varchar(20) check (batting_hand in ('left','right')) not null,
    bowling_skill varchar(20) check (bowling_skill in ('fast','medium','legspin','offspin')),
    country_name varchar(20) not null
);

create table match(
    match_id varchar(20) primary key not null,
    match_type varchar(20) check ( match_type in ('league','playoff','knockout')) not null,
    venue varchar(20) not null,
    team_1_id varchar(20) references team(team_id) not null,
    team_2_id varchar(20) references team(team_id) not null,
    match_date date not null,
    season_id varchar(20) references season(season_id) not null,
    win_run_margin smallint,
    win_run_wickets smallint,
    win_type varchar(20) check ( win_type in ('runs','wickets','draw')),
    toss_winner smallint check ( toss_winner in (1,2)),
    toss_decide varchar(20) check ( toss_decide in ('bowl','bat')),
    winner_team_id varchar(20) references team(team_id),
    check(
        (win_type = 'draw' and win_run_margin is null and win_run_wickets is null)
        or (win_type = 'runs' and win_run_margin is not null and win_run_wickets is null)
        or (win_type = 'wickets' and win_run_margin is null and win_run_wickets is not null)
    )
);


create table auction(
    auction_id varchar(20) primary key not null,
    season_id varchar(20) references season(season_id) not null,
    player_id varchar(20)  references player(player_id) not null,
    base_price bigint check( base_price >= 1000000) not null,
    sold_price bigint,
    is_sold boolean not null,
    team_id varchar(20)     references team(team_id),
    check(is_sold and sold_price is not null and team_id is not null and sold_price >= base_price),
    unique(player_id,team_id,season_id)
);


create table player_team (
    player_id varchar(20) references player(player_id) not null,
    team_id varchar(20) references team(team_id) not null,
    season_id varchar(20) references season(season_id) not null,
    primary key(player_id,team_id,season_id),
    foreign key (player_id, team_id, season_id)
        references auction(player_id, team_id, season_id)
);


create table player_match(
    player_id varchar(20) references player(player_id) not null,
    match_id varchar(20) references match(match_id) not null,
    role varchar(20)    check(role in ('bowler','batter','allrounder','wicketkeeper')),
    team_id varchar(20) references team(team_id) not null,
    is_extra boolean not null,
    primary key (player_id,match_id)
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
    primary key (match_id,innings_num,over_num,ball_num),
    foreign key (match_id,innings_num,over_num,ball_num)
        references balls(match_id,innings_num,over_num,ball_num)
);

create table extras (
    match_id varchar(20) references match(match_id) not null,
    innings_num smallint not null,
    over_num smallint not null,
    ball_num smallint not null,
    extras_runs smallint check (extras_runs >= 0) not null,
    extra_type varchar(20) check( extra_type in ('no_balls','wide','byes','legbyes')) not null,
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


create table awards(
    match_id varchar(20) references match(match_id) not null,
    award_type varchar(20) check (award_type in ('orange_cap','purple_cap')) not null,
    player_id varchar(20) references player(player_id) not null,
    primary key (match_id, award_type)
);


-- wicket keeper validation
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

-- automatic insertion into player team
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

-- automatic season id generation
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

-- match_id validation 
create or replace function validate_match_id()
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
    
    if match_id <> expected_match_id then
        raise exception 'sequence of match id violated';
    end if;

    return new;
end; 
$$ language plpgsql;

create trigger check_match_id
before insert or update on match
for each row 
execute function validate_match_id();

-- limit on internation player per team
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

        if num_player>2 then
            raise exception 'there could be atmost 3 international player per team per season';
        end if;
        
    end if;
    return new;
end;
$$ 
language plpgsql;

create trigger limit_inter_player
before insert or update on player_team
for each row
execute function check_inter_player();

-- limit on number of home matches

create or replace function limit_home_matches()
returns trigger as 
$$
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
        where (team_1_id = new.team_1_id or team_2_id = new.team_1_id)
        and venue = team_1_region;

        select coalesce(count(*),0) into count_2
        from match
        where (team_1_id = new.team_2_id or team_2_id = new.team_2_id)
        and venue = team_2_region;

        if new.venue = team_1_region then
            count_1 = count_1 + 1;
        end if;

        if new.venue = team_2_region then
            count_2 = count_2 + 1;
        end if;

        if (count_1 >1 or count_2 > 1 ) then
            raise exception 'each team can play only one home match in a league against another team';
        end if;
    end if;
    return new;
end;
$$
language plpgsql;


create trigger limit_count_home_matches
before insert or update on match
for each row
execute function limit_home_matches();

-- 
create or replace function updating_match_row()
returns trigger as 
$$
declare
    best_batter int;
    best_bowler int;
begin
    if new.win_type='draw' then
        winner_team_id = null;
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
    from balls as b natural join batter_score as bt
    where match_id = new.match_id
    group by striker_id
    order by sum(run_scored) desc,striker_id
    limit 1;

    select top 1 bowler_id 
    into best_bowler
    from balls as b natural join wickets as w
    where match_id = new.match_id
    group by bowler_id
    order by count(*) desc,bowler_id
    limit 1;

    insert into awards (match_id,award_type,player_id)
    values (new.match_id,'orange_cap',best_batter);

    insert into awards (match_id,award_type,player_id)
    values (new.match_id,'purple_cap',best_bowler);

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
