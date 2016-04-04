{%- macro schema() -%}
    {%- if (outputSchema) -%}
        "{{ outputSchema }}"
    {%- else -%}
        "public"
    {%- endif -%}
{%- endmacro -%}

DROP OPERATOR IF EXISTS {{ schema() }}.-# (anyarray, anynonarray);
DROP OPERATOR IF EXISTS {{ schema() }}.-# (anyarray, anyarray);
DROP FUNCTION IF EXISTS {{ schema() }}.cache_fk_array_insert(source pg_catalog.anyarray, element pg_catalog.anyelement, new_elements pg_catalog.anyarray);
DROP FUNCTION IF EXISTS {{ schema() }}.cache_fk_array_insert(source pg_catalog.anyarray, element pg_catalog.anyelement, new_elements pg_catalog.anyelement);
DROP FUNCTION IF EXISTS {{ schema() }}.cache_fk_array_subtract(inout lv pg_catalog.anyarray, rv pg_catalog.anyarray);
DROP FUNCTION IF EXISTS {{ schema() }}.cache_fk_array_subtract(inout lv pg_catalog.anyarray, rv pg_catalog.anynonarray);
