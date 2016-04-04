'use strict';

// Normal parameter template: {'table': '', 'pk': '', 'fk': '', 'columns': [{'value': '', 'cache': ''}]}
// Recursive parameter template: {'pk': '', 'fk': '', 'parents': '', 'children': '', 'columns': [{'value': '', 'cache': ''}]}

let nunjucks    = require('nunjucks');
let fs          = require('fs');
let exec        = require('child_process').exec;

let template    = {
    normal: 'templates/create-normal-triggers.sql',
    recursive: 'templates/create-recursive-triggers.sql'
};

fs.writeFileSync('out.sql', '');

let conf = {
    db: 'cache_development',
    user: 'postgres',
    outputSchema: 'extra_modules',
    conf: [
        {type: 'normal', schema: 'public', table: 'Address', foreignSchema: 'public', foreignTable: 'Person', foreignPk: 'idNo', fk: 'personIdNo', columns: [
            {value: 'idCode', cache: 'cacheAddresses', cacheType: 'concat'},
            {value: 'transitCodes', cache: 'cacheTransitCodes', cacheType: 'concat'},
            {value: 'point', cache: 'cachePoint', cacheType: 'sum'},
            {value: 'label', cache: 'cacheLabel', cacheType: 'concat'}
        ]},
        {type: 'normal', table: 'LineItem', foreignTable: 'Product', foreignPk: 'code', fk: 'productCode', columns: [
            {value: 'code', cache: 'cacheLineItems', cacheType: 'concat'},
            {value: 'invoiceCode', cache: 'cacheInvoices', cacheType: 'concat'},
            {value: 'total', cache: 'cacheTotal', cacheType: 'sum'}
        ]},
        {type: 'recursive', table: 'Product', pk: 'code', fk: 'parentProductCode', parents: 'cacheParents', children: 'cacheChildren', columns: [
            {value: 'cacheInvoices', cache: 'cacheChildrenInvoices', cacheType: 'concat'},
            {value: 'cacheLineItems', cache: 'cacheChildrenLineItems', cacheType: 'concat'},
            {value: 'cacheTotal', cache: 'cacheChildrenTotal', cacheType: 'sum'},
            {value: 'tag', cache: 'cacheChildrenTags', cacheType: 'concat'}
        ]}
    ]
};

console.log(JSON.stringify(conf));


fs.appendFileSync('out.sql', nunjucks.render('templates/create-objects.sql', conf));
//fs.appendFileSync('out.sql', nunjucks.render('templates/drop-objects.sql', conf));

for (let one of conf.conf) {
    fs.appendFileSync('out.sql', nunjucks.render(template[one.type], Object.assign({}, one, { outputSchema: conf.outputSchema })));
//    fs.appendFileSync('out.sql', nunjucks.render('templates/drop-triggers.sql', Object.assign({}, one, { outputSchema: conf.outputSchema })));
}

let cmd = `psql -f out.sql -U ${conf.user} -d ${conf.db}`;

exec(cmd, (error, stdout, stderr) => {
    if (error) {
        throw error;
    }
    if (stderr) {
        console.log(stderr);
    } else {
        console.log(stdout);
    }
});


