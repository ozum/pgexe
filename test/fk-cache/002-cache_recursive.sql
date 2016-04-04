SELECT plan(19);

DELETE FROM "Product";
DELETE FROM "Invoice";
DELETE FROM "LineItem";

-- INSERT TESTS
INSERT INTO "Product" ("code", "parentProductCode", "tag") VALUES ('p1', NULL, NULL);
INSERT INTO "Product" ("code", "parentProductCode", "tag") VALUES ('p2', 'p1', 'Fast');
INSERT INTO "Product" ("code", "parentProductCode", "tag") VALUES ('p3', 'p2', NULL);
INSERT INTO "Product" ("code", "parentProductCode", "tag") VALUES ('p4', 'p3', 'Slow');
INSERT INTO "Product" ("code", "parentProductCode", "tag") VALUES ('p5', 'p4', 'Retail');
INSERT INTO "Product" ("code", "parentProductCode", "tag") VALUES ('p6', 'p4', NULL);
INSERT INTO "Product" ("code", "parentProductCode", "tag") VALUES ('p7', 'p6', 'Return');

INSERT INTO "Invoice" ("code") VALUES ('i1');
INSERT INTO "Invoice" ("code") VALUES ('i2');
INSERT INTO "Invoice" ("code") VALUES ('i3');
INSERT INTO "Invoice" ("code") VALUES ('i4');
INSERT INTO "Invoice" ("code") VALUES ('i5');

INSERT INTO "LineItem" ("code", "productCode", "invoiceCode", "total") VALUES ('l1', 'p1', 'i1', 2);
INSERT INTO "LineItem" ("code", "productCode", "invoiceCode", "total") VALUES ('l2', 'p2', 'i2', 3);
INSERT INTO "LineItem" ("code", "productCode", "invoiceCode", "total") VALUES ('l3', 'p7', 'i2', 4);

SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Insert Test 1');

-- UPDATE TESTS
UPDATE "Product" SET "code" = 'px' WHERE "code" = 'p1';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update PK 1');

UPDATE "Product" SET "code" = 'p1' WHERE "code" = 'px';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update PK 2');

UPDATE "Product" SET "parentProductCode" = 'p1' WHERE "code" = 'p4';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update FK 1');

UPDATE "Product" SET "parentProductCode" = NULL WHERE "code" = 'p4';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update FK to NULL');

UPDATE "Product" SET "parentProductCode" = 'p3' WHERE "code" = 'p4';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update FK NULL to NOT NULL');

UPDATE "Product" SET "tag" = 'Cancel' WHERE "code" = 'p4';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update Value');

UPDATE "Product" SET "tag" = NULL WHERE "code" = 'p4';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update Value to NULL');

UPDATE "Product" SET "tag" = 'Slow' WHERE "code" = 'p4';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update Value NULL to NOT NULL');

UPDATE "LineItem" SET code = code || 'b';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update join table multiple PK (Cascade)');

UPDATE "LineItem" SET code = trim(code, 'b');
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Undo Update join table multiple PK (Cascade)');

UPDATE "LineItem" SET "code" = 'l2-b', "productCode" = 'p5', "invoiceCode" = 'i1', total = 11 WHERE "code" = 'l2';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update join table multiple PK-FK-Value');

UPDATE "LineItem" SET "code" = 'l2', "productCode" = 'p2', "invoiceCode" = 'i2', total = 3 WHERE "code" = 'l2-b';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Undo Update join table multiple PK-FK-Value');

UPDATE "Invoice" SET "code" = "code" || 'b';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update foreign table multiple PK (Cascaded)');

UPDATE "Invoice" SET "code" = trim("code", 'b');
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Undo Update foreign table multiple PK (Cascaded)');

-- DELETE TESTS
DELETE FROM "Product" WHERE "code" = 'p4';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Delete Product');

DELETE FROM "LineItem" WHERE "code" = 'l2';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Delete Line Item');

DELETE FROM "Invoice" WHERE "code" = 'i1';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Delete Invoice');

DELETE FROM "Product" WHERE "code" = 'p1';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Delete All Products');


SELECT * FROM finish();
