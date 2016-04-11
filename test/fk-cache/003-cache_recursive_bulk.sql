SELECT plan(7);

DELETE FROM "Product";
DELETE FROM "Invoice";
DELETE FROM "LineItem";

\ir utility/data_bulk.sql;

-- INSERT TESTS

SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Bulk Test Result');

DELETE FROM "Product" WHERE code IN (SELECT code FROM "Product" ORDER BY random() LIMIT 20);
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Delete Product 1');

DELETE FROM "Product" WHERE code IN (SELECT code FROM "Product" ORDER BY random() LIMIT 30);
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Delete Product 2');

DELETE FROM "LineItem" WHERE code IN (SELECT code FROM "LineItem" ORDER BY random() LIMIT 50);
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Delete LineItem 1');

DELETE FROM "LineItem" WHERE code IN (SELECT code FROM "LineItem" ORDER BY random() LIMIT 50);
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Delete LineItem 2');

DELETE FROM "Invoice" WHERE code IN (SELECT code FROM "Invoice" ORDER BY random() LIMIT 30);
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Delete Invoice 1');

DELETE FROM "Invoice" WHERE code IN (SELECT code FROM "Invoice" ORDER BY random() LIMIT 30);
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Delete Invoice 2');

SELECT * FROM finish();