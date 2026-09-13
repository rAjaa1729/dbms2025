# DB362 Indexes

Index implementations for **DB362**, a course-provided toy in-memory
database engine that loads a CSV file into memory and evaluates boolean
queries over it. These indexes speed up lookups against the loaded data.

- `BPlusTreeIndex.java` — a B+ Tree index: node splitting on insert,
  ordered leaf traversal for range queries.
- `ExtendibleHashing.java` — an extendible hashing index: a directory of
  buckets that doubles and splits as needed on insert.

(Bonus deletion logic for both was left unimplemented — everything else
required by the assignment is complete.)

## Note

Only these two index files are included — the rest of DB362 (the query
parser, CSV loader, boolean-query evaluator) is course-provided starter
code distributed separately and isn't in this repo, so this isn't
runnable standalone. `docs/assignment-brief.pdf` describes the full
system these plug into.
