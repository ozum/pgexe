-- Captured BUG from bulk

SELECT plan(7);

DELETE FROM "Product";
DELETE FROM "Invoice";
DELETE FROM "LineItem";

-- INSERT TESTS

/* Data for the 'Product' table  (Records 1 - 7) */
INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'mnbjmvgz', NULL, E'i');

INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'qyhljcpx', NULL, NULL);

INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'gdmmufto', E'qyhljcpx', E'rvwg');

INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'froonjrvg', E'gdmmufto', NULL);

INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'iyouv', E'froonjrvg', E'czs');

INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'irpocv', E'iyouv', E'lgg');

INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'yhklol', E'irpocv', E'jvubrp');


SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Insert Test 1');

UPDATE "Product" SET code = 'viwlixmroh', "parentProductCode" = 'mnbjmvgz', tag = 'qaBBsqvpwn' WHERE code = 'yhklol';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update PK and FK');

UPDATE "Product" SET code = 'yhklol', "parentProductCode" = 'irpocv', tag = 'jvubrp' WHERE code = 'viwlixmroh';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update PK and FK (ROLLBACK)');

UPDATE "Product" SET code = 'viwlixmroh', "parentProductCode" = NULL, tag = 'qaBBsqvpwn' WHERE code = 'yhklol';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update PK and FK 2');

UPDATE "Product" SET code = 'yhklol', "parentProductCode" = 'irpocv', tag = 'jvubrp' WHERE code = 'viwlixmroh';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update PK and FK 2 (ROLLBACK)');

UPDATE "Product" SET code = 'viwlixmroh', "parentProductCode" = 'froonjrvg', tag = 'qaBBsqvpwn' WHERE code = 'yhklol';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update PK and FK 3');

UPDATE "Product" SET code = 'yhklol', "parentProductCode" = 'irpocv', tag = 'jvubrp' WHERE code = 'viwlixmroh';
SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'Update PK and FK 3 (ROLLBACK)');



SELECT * FROM finish();
