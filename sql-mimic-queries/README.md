# SQL Queries on MIMIC

30 SQL queries against [MIMIC](https://mimic.mit.edu/), a real de-identified
hospital admissions/patients dataset, split into four difficulty tiers:
`BASIC`, `INTERMEDIATE`, `ADVANCED`, `GRAPH`.

The `GRAPH` tier models patient overlap as a graph — e.g. finding patients
whose hospital stays overlapped with a given patient's, via a recursive
CTE walking a graph of overlapping admission windows.

## Run it

`assign.ipynb` runs each query against a local Postgres instance loaded
with the MIMIC `hosp` schema, via `%sql`/`%%sql` magic
(`ipython-sql` + `psycopg2`).

## `docs/`, `archive/`

`docs/assignment-brief.pdf` is the original spec. `archive/graph-scratch.sql`
is an earlier draft graph query, kept for reference.
