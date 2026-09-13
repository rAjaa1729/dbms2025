# IPL Database

A relational schema and trigger-based rule engine for an IPL (cricket
league) database: teams, players, seasons, matches, auctions, ball-by-ball
scoring, and awards — with real league rules enforced at the database
level rather than in application code.

## Schema

12 tables (`schema.sql`): `player`, `team`, `season`, `match`,
`player_match`, `auction`, `awards`, `player_team`, `balls`,
`batter_score`, `extras`, `wickets`.

## Trigger-enforced rules

- **Auction → roster**: a player's `player_team` row is generated
  automatically from `auction` results, not inserted directly.
- **Foreign-player cap**: at most 3 non-Indian players per team per season.
- **Home-ground rule**: a league match must be played at one team's home
  ground, and a team can host a given opponent at home at most once.
- **Wicketkeeper validation**, auto-generated season/match IDs.
- **Cascading deletes**: deleting a season/match/auction row cleans up
  every dependent row (player_team, balls, scores, etc.) via trigger
  functions rather than plain `ON DELETE CASCADE`, since some of the
  cleanup logic is conditional.

## Testing

`a2-tester/` is a JUnit test harness (Maven) that runs `schema.sql`
against a real Postgres instance and checks the trigger behavior above.
See `a2-tester/readme.md` for setup. `Assig2.ipynb` was used for
exploratory querying during development.

## `docs/`

`docs/assignment-brief.pdf` is the original spec.
