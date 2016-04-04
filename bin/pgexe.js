#!/usr/bin/env node --harmony --harmony_destructuring --harmony_default_parameters
'use strict';

const fs        = require('fs');
const vorpal    = require('vorpal')();
const fkCache   = require('../lib/fk-cache');

vorpal
    .delimiter('pgexe$');

vorpal
    .command('fk-cache-create [configFile]')
    .option('-d, --db <db>', 'Database name.')
    .option('-u, --user <user>', 'Database user name.')
    .option('-s, --outputSchema <outputSchema>', 'Schema name to create function in.')
    .option('--keepFiles', 'Keeps generated scripts for examination.')
    .action(fkCache.create)
    .description('Creates fk-cache functions and triggers for given config file.');

vorpal
    .command('fk-cache-drop [configFile]')
    .option('-d, --db <db>', 'Database name.')
    .option('-u, --user <user>', 'Database user name.')
    .option('-s, --outputSchema <outputSchema>', 'Schema name to create function in.')
    .option('--keepFiles', 'Keeps generated scripts for examination.')
    .action(fkCache.drop)
    .description('Drops fk-cache functions and triggers for given config file.');

if (process.argv.length === 2) {
    vorpal.show();                  // If called without any parameter as "pgexe", then enter interactive shell.
} else {
    vorpal.parse(process.argv);     // If called with parameters execute command.
}
