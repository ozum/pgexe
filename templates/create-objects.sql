{%- macro functionSchema() -%}
    {%- if (outputSchema) -%}
        "{{ outputSchema }}"
    {%- else -%}
        "{{ schema }}"
    {%- endif -%}
{%- endmacro -%}

{%- if outputSchema -%}
    CREATE SCHEMA IF NOT EXISTS "{{ outputSchema }}";
{%- endif %}

CREATE OR REPLACE FUNCTION {{ functionSchema() }}.fkc_array_insert (
  source pg_catalog.anyarray,
  element pg_catalog.anyelement,
  new_elements pg_catalog.anyarray
)
RETURNS pg_catalog.anyarray AS
$body$
DECLARE
    pos INTEGER DEFAULT array_position(source, element);
BEGIN
    IF pos IS NULL THEN
        RETURN source || new_elements;
    END IF;

    RETURN source[array_lower(source, 1) : pos] || new_elements || source[pos + 1 : array_upper(source, 1)];
END;
$body$
LANGUAGE 'plpgsql'
IMMUTABLE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

COMMENT ON FUNCTION {{ functionSchema() }}.fkc_array_insert(source pg_catalog.anyarray, element pg_catalog.anyelement, new_elements pg_catalog.anyarray)
IS '(anyarray source, anyelement element, anyarray new_elements)

new_elements array''indeki değerleri source array''indeki element elemanının
arkasına yerleştirir. Depth first array''ler için faydalı.';



CREATE OR REPLACE FUNCTION {{ functionSchema() }}.fkc_array_insert (
  source pg_catalog.anyarray,
  element pg_catalog.anyelement,
  new_elements pg_catalog.anyelement
)
RETURNS pg_catalog.anyarray AS
$body$
DECLARE
    pos INTEGER DEFAULT array_position(source, element);
BEGIN
    IF pos IS NULL THEN
        RETURN source || new_elements;
    END IF;

    RETURN source[array_lower(source, 1) : pos] || new_elements || source[pos + 1 : array_upper(source, 1)];
END;
$body$
LANGUAGE 'plpgsql'
IMMUTABLE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

COMMENT ON FUNCTION {{ functionSchema() }}.fkc_array_insert(source pg_catalog.anyarray, element pg_catalog.anyelement, new_elements pg_catalog.anyelement)
IS '(anyarray source, anyelement element, anyelement new_element)

new_element değerini source array''indeki element elemanının
arkasına yerleştirir. Depth first array''ler için faydalı.';



CREATE OR REPLACE FUNCTION {{ functionSchema() }}.fkc_array_subtract (
  inout lv pg_catalog.anyarray,
  rv pg_catalog.anyarray
)
RETURNS pg_catalog.anyarray AS
$body$
DECLARE
    pos 	INTEGER;
    i		INTEGER;
BEGIN
    IF rv IS NULL OR rv = '{}' THEN
        RETURN;
    END IF;

    FOR i IN array_lower(rv, 1)..array_upper(rv,1) LOOP
    	pos := array_position(lv, rv[i]);
    	IF pos IS NOT NULL THEN
        	lv := lv[array_lower(lv, 1) : pos - 1] || lv[pos + 1 : array_upper(lv, 1)];
    	END IF;
    END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
IMMUTABLE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

COMMENT ON FUNCTION {{ functionSchema() }}.fkc_array_subtract(inout lv pg_catalog.anyarray, rv pg_catalog.anyarray)
IS '(inout anyarray lv , anyarray rv)

Removes all elements in rv array from lv array only one time on first occurence.

Ex:
{1,1,1}   - {1}   = {1,1}
{1,2,2,3} - {1,2} = {2,3}

Array must be one-dimensional.';




CREATE OR REPLACE FUNCTION {{ functionSchema() }}.fkc_array_subtract (
  inout lv pg_catalog.anyarray,
  rv pg_catalog.anynonarray
)
RETURNS pg_catalog.anyarray AS
$body$
DECLARE
  	pos INTEGER;
BEGIN
	IF rv IS NULL THEN
        RETURN;
    END IF;

    pos := array_position(lv, rv);
    
    IF pos IS NOT NULL THEN
        lv := lv[array_lower(lv, 1) : pos - 1] || lv[pos + 1 : array_upper(lv, 1)];
    END IF; 
END;
$body$
LANGUAGE 'plpgsql'
IMMUTABLE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

COMMENT ON FUNCTION {{ functionSchema() }}.fkc_array_subtract(inout lv pg_catalog.anyarray, rv pg_catalog.anynonarray)
IS '(inout anyarray lv, anyelement rv)

Removes first element equal to the given value from the array. Array must be
one-dimensional.';


DROP OPERATOR IF EXISTS {{ functionSchema() }}.-# (anyarray, anynonarray);
CREATE OPERATOR {{ functionSchema() }}.-# ( PROCEDURE = {{ functionSchema() }}.fkc_array_subtract,
LEFTARG = anyarray, RIGHTARG = anynonarray);

DROP OPERATOR IF EXISTS {{ functionSchema() }}.-# (anyarray, anyarray);
CREATE OPERATOR {{ functionSchema() }}.-# ( PROCEDURE = {{ functionSchema() }}.fkc_array_subtract,
LEFTARG = anyarray, RIGHTARG = anyarray);


