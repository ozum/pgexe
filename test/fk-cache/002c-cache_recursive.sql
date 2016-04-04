-- Captured BUG from bulk

SELECT plan(5);

DELETE FROM "Product";
DELETE FROM "Invoice";
DELETE FROM "LineItem";

-- INSERT TESTS
INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'monitor', NULL, NULL);

INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'lcd', E'monitor', E'rvwg');

INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'lcd2', E'monitor', NULL);

INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'gamer', E'lcd', NULL);

INSERT INTO "Product" ("code", "parentProductCode", "tag")
VALUES (E'gamer2', E'gamer', NULL);


PREPARE up01 AS UPDATE "Product" SET code = 'gamerError', "parentProductCode" = 'gamer', tag = 'jvubrp' WHERE code = 'gamer';
SELECT throws_ilike( 'up01', 'Circular parent-child chain detected%', 'Should detect circular to its old PK' );

SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'UPDATE Circular to OLD PK');

PREPARE up02 AS UPDATE "Product" SET code = 'lcdError', "parentProductCode" = 'gamer', tag = 'jvubrp' WHERE code = 'lcd';
SELECT throws_ilike( 'up02', 'Circular parent-child chain detected%', 'Should detect circular to its children while updating PK' );

SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'UPDATE Circular to Children While PK Update');

UPDATE "Product" SET code = code || '3', "parentProductCode" = "parentProductCode" || '2' WHERE code IN ('gamer', 'gamer');

SELECT test_calculate_product_chain();
SELECT results_eq('SELECT * FROM "vProduct"', 'SELECT * FROM "vProductCalculated"',
    'UPDATE multiple row');

SELECT * FROM finish();
