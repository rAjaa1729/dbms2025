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
    expected_season_id varchar(20);
    extracted_serial_no int;
begin
    expected_season_id := left(new.match_id,7);
    extracted_serial_no := right(new.match_id,3)::int;

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