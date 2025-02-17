#!/bin/bash

# Assign command-line arguments to variables
DB_NAME="$1"
DB_USER="$2"
DB_PASSWORD="$3"
SQL_FILE="$4"
DB_HOST="localhost"
DB_PORT="5432"  # Default PostgreSQL port

# Export the password as an environment variable for psql
export PGPASSWORD=$DB_PASSWORD

# Run the SQL file using psql
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -f $SQL_FILE

# Unset the password after execution for security reasons
unset PGPASSWORD
