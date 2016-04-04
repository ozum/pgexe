CREATE OR REPLACE FUNCTION public.test_calculate_product_chain(
    p_record_id character varying DEFAULT NULL::integer,
    p_parent_chain character varying[] DEFAULT NULL::integer[],
    p_stack_depth integer DEFAULT 0)
  RETURNS record AS
$BODY$
DECLARE
    p_current_record        RECORD;
    p_children              VARCHAR[];
    p_result				RECORD;
    p_new_result			RECORD;
    p_invoices              VARCHAR[];
    p_line_items            VARCHAR[];
    p_total                 INTEGER     := 0;
    p_tags                  VARCHAR[];
    p_max_stack_depth       INTEGER     := 20;
    p_valid_table_names     VARCHAR[]   := ARRAY['entity', 'business_unit'];
BEGIN


    /****************************************************************
    *                         INITIALIZER                           *
    ****************************************************************/
  	IF p_record_id IS NULL THEN
        -- Parent ID'si NULL olanları bul ve onlar tree güncelleme fonksiyonunu çağır.

        FOR p_current_record IN
            SELECT * FROM "Product" WHERE "parentProductCode" IS NULL
        LOOP
            PERFORM test_calculate_product_chain(p_current_record.code);
        END LOOP;
	END IF;


    /****************************************************************
    *                       RECURSIVE STEPS                         *
    ****************************************************************/
    -- Initializer tarafından parametrelerle çağrılır ve recursive olarak kendini çağırır.
    IF p_stack_depth >= p_max_stack_depth THEN
        RAISE EXCEPTION 'Too deep stack depth in % table parent tree. It is a possible cycle (infinite loop) indication. Please check. (Depth:%, id:%)', p_table_name, p_stack_depth, p_record_id;
    END IF;

    FOR p_current_record IN
        SELECT * FROM "Product" WHERE "parentProductCode" = p_record_id
    LOOP
    	p_result 		:= test_calculate_product_chain(p_current_record.code, p_record_id || p_parent_chain, p_stack_depth + 1 );
 		p_children 		:= array_remove(p_current_record.code || p_result.children || p_children, NULL);
        p_invoices  	:= array_remove(p_current_record."cacheInvoices" || p_result.invoices || p_invoices, NULL);
        p_line_items  	:= array_remove(p_current_record."cacheLineItems" || p_result."lineItems" || p_line_items, NULL);
        p_total  	    := p_current_record."cacheTotal" + p_result."total" + p_total;
        p_tags          := array_remove(p_current_record."tag" || p_result."tags" || p_tags, NULL);

    END LOOP;

    -- Circular zincir var mı kontrol et. Parent chain array'inde kendisi olmaması lazım.
    --IF extra_modules.idx(COALESCE(p_parent_chain, ARRAY[]::INTEGER[]), p_record_id) > 0 THEN
    --  RAISE EXCEPTION 'Circular parent-child chain detected. Operation aborted. id (%) found in parents %', p_record_id, p_parent_chain;
    --END IF;


    UPDATE "Product"
    SET
    	"resetCacheChildren" = COALESCE(p_children, '{}'),
        "resetCacheChildrenInvoices" = COALESCE(p_invoices, '{}'),
        "resetCacheChildrenLineItems" = COALESCE(p_line_items, '{}'),
        "resetCacheChildrenTotal" = COALESCE(p_total, 0),
        "resetCacheChildrenTags" = COALESCE(p_tags, '{}'),
        "resetCacheParents" = COALESCE(p_parent_chain, '{}')

    WHERE
    	code = p_record_id;

    SELECT p_children AS children, p_invoices AS invoices, p_line_items AS "lineItems", p_total AS total, p_tags AS tags INTO p_new_result;
    RETURN p_new_result;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION public.test_array_sort (
  pg_catalog.anyarray
)
RETURNS pg_catalog.anyarray AS
$body$
SELECT ARRAY(SELECT unnest($1) ORDER BY 1)
$body$
LANGUAGE 'sql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;



CREATE OR REPLACE VIEW "vProduct"AS
SELECT
	code,
    "parentProductCode",
	test_array_sort("cacheParents") AS "cacheParents",
    test_array_sort("cacheChildren") AS "cacheChildren",
    test_array_sort("cacheChildrenInvoices") AS "cacheChildrenInvoices",
    test_array_sort("cacheChildrenLineItems") AS "cacheChildrenLineItems",
    "cacheChildrenTotal",
    test_array_sort("cacheChildrenTags") AS "cacheChildrenTags"
FROM
    "Product"
ORDER BY
    code;




CREATE OR REPLACE VIEW "vProductCalculated" AS
SELECT
	code,
    "parentProductCode",
    test_array_sort("resetCacheParents") AS "cacheParents",
    test_array_sort("resetCacheChildren") AS "cacheChildren",
    test_array_sort("resetCacheChildrenInvoices") AS "cacheChildrenInvoices",
    test_array_sort("resetCacheChildrenLineItems") AS "cacheChildrenLineItems",
    "resetCacheChildrenTotal" AS "cacheChildrenTotal",
    test_array_sort("resetCacheChildrenTags") AS "cacheChildrenTags"
FROM
	"Product"
ORDER BY
	code;