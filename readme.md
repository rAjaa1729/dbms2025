# DBMS Labs

Four assignments from an undergraduate Database Management Systems course
(IIT Delhi, COL362/632), covering SQL, relational schema design with
triggers, and building index and query-execution components of a small
database engine.

| Project | Topic |
|---|---|
| [sql-mimic-queries](sql-mimic-queries) | SQL queries against a real hospital-admissions dataset (MIMIC) |
| [ipl-database](ipl-database) | Relational schema + trigger-based business rules for an IPL (cricket) database |
| [db362-indexes](db362-indexes) | B+ Tree and Extendible Hashing indexes for a toy in-memory database engine |
| [query-execution-engine](query-execution-engine) | Query execution operators and a query optimizer for the same engine |

## Note on query-execution-engine

The actual solution for this one is not recoverable: it was committed as
a nested clone of another repo, which git silently recorded as an empty
submodule reference instead of adding its files (no `.gitmodules` entry
was ever created). Only the assignment brief survived.
