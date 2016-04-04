#!/usr/bin/env bash

# NOTE: Test requires pgtap PostgreSQL test extension.
# Get file dir
file_dir=$( cd "$(dirname "${BASH_SOURCE}")" ; pwd -P );

$file_dir/fk-cache/runtest.sh;