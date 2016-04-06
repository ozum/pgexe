#! /usr/bin/env bash

# NOTE: Test requires pgtap PostgreSQL test extension.
# Get file dir
file_dir=$( cd "$(dirname "${BASH_SOURCE}")" ; pwd -P );

# Set env var to look db credentials, hide notice messages.
export PGOPTIONS='--client-min-messages=warning'
export PGUSER=user
export PGPASSWORD=password

db="cache_development_7253";

# Create test db
createdb -h 127.0.0.1 -U user --no-password $db;
psql -f $file_dir/utility/create-test-db.sql -U user -d $db --no-password --echo-errors -q;
psql -f $file_dir/utility/create-test-objects.sql -U user -d $db --no-password --echo-errors -q;

# Test DB
pgexe fk-cache-create -d $db $file_dir/utility/fk-cache.json;
pg_prove -d $db -U user $file_dir/*.sql;
#pg_prove -d $db -U user $file_dir/002-cache_recursive.sql;
#pg_prove -d $db -U user $file_dir/002c-cache_recursive.sql;
#psql -f $file_dir/utility/data_bulk.sql -U user -d $db --no-password --echo-errors -q;

dropdb -h 127.0.0.1 -U user --no-password $db;
