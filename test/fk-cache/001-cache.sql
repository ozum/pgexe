DELETE FROM "Person";
DELETE FROM "Address";

INSERT INTO "Person" VALUES ('George');
INSERT INTO "Person" VALUES ('Max');
INSERT INTO "Person" VALUES ('Susan');

SELECT plan(13);

-- INSERT TESTS

INSERT INTO "Address" ("idCode", "personIdNo", "transitCodes", "point", "label") VALUES ('g1', 'George', '{cg1, cg2}', NULL, 'Red'); 
PREPARE in01 AS SELECT * FROM "Person" WHERE "idNo" = 'George';
SELECT row_eq('in01', ROW('George', '{g1}', '{cg1, cg2}', 0, '{Red}')::"Person",
    'Standard Insert');


INSERT INTO "Address" ("idCode", "personIdNo", "transitCodes", "point", "label") VALUES ('g2', 'George', '{cg3}', 2, 'Green'); 
PREPARE in02 AS SELECT * FROM "Person" WHERE "idNo" = 'George';
SELECT row_eq('in02', ROW('George', '{g1, g2}', '{cg1, cg2, cg3}', 2, '{Red, Green}')::"Person",
    'Additional Insert');


INSERT INTO "Address" ("idCode", "personIdNo", "transitCodes", "point", "label") VALUES ('m2', 'Max', NULL, NULL, 'Blue'); 
PREPARE in03 AS SELECT * FROM "Person" WHERE "idNo" = 'Max';
SELECT row_eq('in03', ROW('Max', '{m2}', '{}', 0, '{Blue}')::"Person",
    'NULL Insert');


-- UPDATE TESTS

UPDATE "Address" SET "idCode" = 'gx', "personIdNo" = 'George', "transitCodes" = '{cx1}', "point" = 3 WHERE "idCode" = 'm2';
PREPARE up01 AS SELECT * FROM "Person" WHERE "idNo" = 'George';
SELECT row_eq('up01', ROW('George', '{g1, g2, gx}', '{cg1, cg2, cg3, cx1}', 5, '{Red, Green, Blue}')::"Person",
    'Full Update');

UPDATE "Address" SET "personIdNo" = NULL WHERE "idCode" = 'gx';
PREPARE up02 AS SELECT * FROM "Person" WHERE "idNo" = 'George';
SELECT row_eq('up02', ROW('George', '{g1, g2}', '{cg1, cg2, cg3}', 2, '{Red, Green}')::"Person",
    'Update FK to NULL');

UPDATE "Address" SET "personIdNo" = 'George' WHERE "idCode" = 'gx';
PREPARE up03 AS SELECT * FROM "Person" WHERE "idNo" = 'George';
SELECT row_eq('up03', ROW('George', '{g1, g2, gx}', '{cg1, cg2, cg3, cx1}', 5, '{Red, Green, Blue}')::"Person",
    'Update FK from NULL to NOT NULL');

UPDATE "Address" SET "transitCodes" = '{nx1}' WHERE "idCode" = 'gx';
PREPARE up04 AS SELECT * FROM "Person" WHERE "idNo" = 'George';
SELECT row_eq('up04', ROW('George', '{g1, g2, gx}', '{cg1, cg2, cg3, nx1}', 5, '{Red, Green, Blue}')::"Person",
    'Update non FK field');

UPDATE "Address" SET "idCode" = 'gx2' WHERE "idCode" = 'gx';
PREPARE up05 AS SELECT * FROM "Person" WHERE "idNo" = 'George';
SELECT row_eq('up05', ROW('George', '{g1, g2, gx2}', '{cg1, cg2, cg3, nx1}', 5, '{Red, Green, Blue}')::"Person",
    'Update PK field');

UPDATE "Person" SET "idNo" = 'George2' WHERE "idNo" = 'George';
PREPARE up06 AS SELECT * FROM "Person" WHERE "idNo" = 'George2';
SELECT row_eq('up06', ROW('George2', '{g1, g2, gx2}', '{cg1, cg2, cg3, nx1}', 5, '{Red, Green, Blue}')::"Person",
    'Cascaded Update');

UPDATE "Address" SET "label" = 'Purple' WHERE "idCode" = 'gx2';
PREPARE up07 AS SELECT * FROM "Person" WHERE "idNo" = 'George2';
SELECT row_eq('up07', ROW('George2', '{g1, g2, gx2}', '{cg1, cg2, cg3, nx1}', 5, '{Red, Green, Purple}')::"Person",
    'Update Value Column');

UPDATE "Address" SET "label" = NULL WHERE "idCode" = 'gx2';
PREPARE up08 AS SELECT * FROM "Person" WHERE "idNo" = 'George2';
SELECT row_eq('up08', ROW('George2', '{g1, g2, gx2}', '{cg1, cg2, cg3, nx1}', 5, '{Red, Green}')::"Person",
    'Update Value Column to NULL');

UPDATE "Address" SET "label" = 'Blue' WHERE "idCode" = 'gx2';
PREPARE up09 AS SELECT * FROM "Person" WHERE "idNo" = 'George2';
SELECT row_eq('up09', ROW('George2', '{g1, g2, gx2}', '{cg1, cg2, cg3, nx1}', 5, '{Red, Green, Blue}')::"Person",
    'Update Value Column from NULL to NOT NULL');



UPDATE "Person" SET "idNo" = 'George' WHERE "idNo" = 'George2'; -- Revert back;





-- DELETE TESTS

DELETE FROM "Address" WHERE "idCode" = 'gx2';
PREPARE de01 AS SELECT * FROM "Person" WHERE "idNo" = 'George';
SELECT row_eq('de01', ROW('George', '{g1, g2}', '{cg1, cg2, cg3}', 2, '{Red, Green}')::"Person",
    'Update PK field');

SELECT * FROM finish();