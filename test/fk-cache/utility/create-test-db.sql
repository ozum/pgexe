-- SQL Manager for PostgreSQL 5.7.0.46946
-- ---------------------------------------
-- Host      : 10.37.129.2
-- Database  : cache_development
-- Version   : PostgreSQL 9.5.1 on x86_64-apple-darwin14.5.0, compiled by Apple LLVM version 7.0.0 (clang-700.1.76), 64-bit

CREATE EXTENSION IF NOT EXISTS pgtap;

SET search_path = public, pg_catalog;
DROP TABLE IF EXISTS public."LineItem";
DROP TABLE IF EXISTS public."Product";
DROP TABLE IF EXISTS public."Invoice";
DROP TABLE IF EXISTS public."Address";
DROP TABLE IF EXISTS public."Person";
SET check_function_bodies = false;
--
-- Structure for table Address (OID = 1593552) :
--
CREATE TABLE public."Address" (
    "idCode" varchar(10) NOT NULL,
    "personIdNo" varchar(10),
    "transitCodes" varchar(10)[],
    point numeric(4,2),
    label varchar(10)
)
WITH (oids = false);
--
-- Structure for table Invoice (OID = 1593558) :
--
CREATE TABLE public."Invoice" (
    code varchar(10) NOT NULL,
    "cacheProducts" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "cacheLineItems" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL
)
WITH (oids = false);
ALTER TABLE ONLY public."Invoice" ALTER COLUMN "cacheProducts" SET STATISTICS 0;
--
-- Structure for table LineItem (OID = 1593566) :
--
CREATE TABLE public."LineItem" (
    code varchar(10) NOT NULL,
    "productCode" varchar(10),
    "invoiceCode" varchar(10) NOT NULL,
    total integer
)
WITH (oids = false);
ALTER TABLE ONLY public."LineItem" ALTER COLUMN code SET STATISTICS 0;
--
-- Structure for table Person (OID = 1593569) :
--
CREATE TABLE public."Person" (
    "idNo" varchar(10) NOT NULL,
    "cacheAddresses" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "cacheTransitCodes" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "cachePoint" numeric(4,2) DEFAULT 0 NOT NULL,
    "cacheLabel" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL
)
WITH (oids = false);
--
-- Structure for table Product (OID = 1593577) :
--
CREATE TABLE public."Product" (
    code varchar(10) NOT NULL,
    "parentProductCode" varchar(10),
    "cacheParents" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "resetCacheParents" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "cacheChildren" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "resetCacheChildren" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "cacheInvoices" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "cacheChildrenInvoices" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "resetCacheChildrenInvoices" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "cacheLineItems" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "cacheChildrenLineItems" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "resetCacheChildrenLineItems" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "cacheTotal" integer DEFAULT 0 NOT NULL,
    "cacheChildrenTotal" integer DEFAULT 0 NOT NULL,
    "resetCacheChildrenTotal" integer DEFAULT 0 NOT NULL,
    tag varchar(10),
    "cacheChildrenTags" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL,
    "resetCacheChildrenTags" varchar(10)[] DEFAULT '{}'::character varying[] NOT NULL
)
WITH (oids = false);


--
-- Definition for index Invoice_pkey (OID = 1593649) :
--
ALTER TABLE ONLY "Invoice"
    ADD CONSTRAINT "Invoice_pkey"
    PRIMARY KEY (code);
--
-- Definition for index LineItem_pkey (OID = 1593651) :
--
ALTER TABLE ONLY "LineItem"
    ADD CONSTRAINT "LineItem_pkey"
    PRIMARY KEY (code);
--
-- Definition for index Person_pkey (OID = 1593653) :
--
ALTER TABLE ONLY "Person"
    ADD CONSTRAINT "Person_pkey"
    PRIMARY KEY ("idNo");
--
-- Definition for index Product_pkey (OID = 1593655) :
--
ALTER TABLE ONLY "Product"
    ADD CONSTRAINT "Product_pkey"
    PRIMARY KEY (code);
--
-- Definition for index address_pkey (OID = 1593657) :
--
ALTER TABLE ONLY "Address"
    ADD CONSTRAINT address_pkey
    PRIMARY KEY ("idCode");
--
-- Definition for index Address_fk (OID = 1593678) :
--
ALTER TABLE ONLY "Address"
    ADD CONSTRAINT "Address_fk"
    FOREIGN KEY ("personIdNo") REFERENCES "Person"("idNo") ON UPDATE CASCADE ON DELETE CASCADE;
--
-- Definition for index LineItemInvoices (OID = 1593683) :
--
ALTER TABLE ONLY "LineItem"
    ADD CONSTRAINT "LineItemInvoices"
    FOREIGN KEY ("invoiceCode") REFERENCES "Invoice"(code) ON UPDATE CASCADE ON DELETE CASCADE;
--
-- Definition for index LineItem_fk (OID = 1593688) :
--
ALTER TABLE ONLY "LineItem"
    ADD CONSTRAINT "LineItem_fk"
    FOREIGN KEY ("productCode") REFERENCES "Product"(code) ON UPDATE CASCADE ON DELETE CASCADE;
--
-- Definition for index Product_fk (OID = 1593693) :
--
ALTER TABLE ONLY "Product"
    ADD CONSTRAINT "Product_fk"
    FOREIGN KEY ("parentProductCode") REFERENCES "Product"(code) ON UPDATE CASCADE ON DELETE CASCADE;

