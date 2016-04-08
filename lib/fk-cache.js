'use strict';

const nunjucks  = require('nunjucks');
const fs        = require('fs');
const path      = require('path');
const exec      = require('child_process').exec;

const template    = {
    normal: { create: 'create-normal-triggers.sql', drop: 'drop-normal-triggers.sql' },
    recursive: { create: 'create-recursive-triggers.sql', drop: 'drop-recursive-triggers.sql' }
};

nunjucks.configure(path.join(__dirname, '../templates'));

function getConfig(args) {
    let configFilePath  = args.configFile || 'fk-cache.json';
    // Convert file path to absolute if it is relative.
    configFilePath      = path.isAbsolute(configFilePath) ? configFilePath : path.join(process.cwd(), configFilePath);
    let config          = require(configFilePath);
    config.db           = args.options.db || config.db;
    config.user         = args.options.user || config.user;
    config.outputSchema = args.options.outputSchema || config.outputSchema;
    config.keepFiles    = args.options.keepFiles || config.keepFiles;
    return config;
}

function execute(config) {
    let cmd = `psql -f out.sql -U ${config.user} -d ${config.db};`;

    exec(cmd, (error, stdout, stderr) => {
        if (error) {
            throw error;
        }
        if (stderr) {
            console.log(stderr);
        }
        console.log('Operation completed.');

        if (!config.keepFiles) {
            fs.unlinkSync('out.sql');
        }
    });
}

function fkCacheCreate(args, callback) {
    let config    = getConfig(args);
    let objectSql = nunjucks.render('create-objects.sql', config);

    fs.writeFileSync('out.sql', '');
    fs.appendFileSync('out.sql', objectSql);

    for (let cache of config.cache) {
        if (cache.triggerPrefix[0].match(/[0-9]/)) {
            throw new Error(`Trigger prefix cannot start with a number. Trigger prefix for table '${cache.table}' starts with a number: '${cache.triggerPrefix}'`);  // Unknown reason PostgreSQL fails a name starting with number even in double quotes. Change prefix in test config and see that.
        }
        let context     = Object.assign({}, cache, { outputSchema: config.outputSchema });
        let triggerSql  = nunjucks.render(template[cache.type].create, context);
        fs.appendFileSync('out.sql', triggerSql);
    }

    execute(config);
    callback();
}

function fkCacheDrop(args, callback) {
    let config    = getConfig(args);
    let objectSql = nunjucks.render('drop-objects.sql', config);

    fs.writeFileSync('out.sql', '');
    fs.appendFileSync('out.sql', objectSql);

    for (let cache of config.cache) {
        let context     = Object.assign({}, cache, { outputSchema: config.outputSchema });
        let triggerSql  = nunjucks.render(template[cache.type].drop, context);
        fs.appendFileSync('out.sql', triggerSql);
    }

    execute(config);
    callback();
}

module.exports = {
    create: fkCacheCreate,
    drop: fkCacheDrop
};
