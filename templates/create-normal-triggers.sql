{% from './util.njk' import iName, name, query, hasValue, valueColumn, isDistinctValue %}

{%- macro removeQuery() -%}
    UPDATE {{ iName(foreignSchema, foreignTable) }} SET {{ query('remove', columns, false) }} WHERE "{{ foreignPk }}" = OLD."{{ fk }}";
{%- endmacro -%}

{%- macro addQuery() -%}
    UPDATE {{ iName(foreignSchema, foreignTable) }} SET {{ query('add', columns, false) }} WHERE "{{ foreignPk }}" = NEW."{{ fk }}";
{%- endmacro -%}

{%- macro addRemoveQuery() -%}
    UPDATE {{ iName(foreignSchema, foreignTable) }} SET {{ query('addRemove', columns, false) }} WHERE "{{ foreignPk }}" = NEW."{{ fk }}";
{%- endmacro -%}

{%- macro funcSchema() -%}
    "{{ outputSchema | d(schema) | d('public') }}"
{%- endmacro -%}

{%- macro setSearchPath() -%}
    {%- if outputSchema -%}
        SET LOCAL search_path TO "{{ outputSchema }}", "public";
    {%- endif -%}
{%- endmacro -%}

/*-----------------------------------------------------------------------------------
                            TRIGGERS FOR {{ name(schema, table) }}
-----------------------------------------------------------------------------------*/

CREATE OR REPLACE FUNCTION {{ funcSchema() }}."t_fkc_{{ name(schema, table) }}_insert_to_{{ name(foreignSchema, foreignTable) }}" ()
RETURNS trigger AS
$body$
BEGIN
    -- Auto generated function by pg-fk-cache-generator node.js module.
    {{ setSearchPath() }}
    {{ addQuery() }}

    RETURN NULL;
END;
$body$
LANGUAGE 'plpgsql' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER COST 100;

 -- object recreation
DROP TRIGGER IF EXISTS "{{ triggerPrefix }}fkc_{{ name(foreignSchema, foreignTable) }}_insert" ON {{ iName(schema, table) }};

CREATE TRIGGER "{{ triggerPrefix }}fkc_{{ name(foreignSchema, foreignTable) }}_insert"
    AFTER INSERT ON {{ iName(schema, table) }} FOR EACH ROW
    {#- If record has foreign key, and has values, add them to to foreign record. #}
    WHEN (NEW."{{ fk }}" IS NOT NULL AND ({{ hasValue(columns, 'NEW') }}))
    EXECUTE PROCEDURE {{ funcSchema() }}."t_fkc_{{ name(schema, table) }}_insert_to_{{ name(foreignSchema, foreignTable) }}"();


CREATE OR REPLACE FUNCTION {{ funcSchema() }}."t_fkc_{{ name(schema, table) }}_delete_to_{{ name(foreignSchema, foreignTable) }}" ()
RETURNS trigger AS
$body$
BEGIN
    -- Auto generated function by pg-fk-cache-generator node.js module.
    {{ setSearchPath() }}
    {{ removeQuery() }}

    RETURN NULL;
END;
$body$
LANGUAGE 'plpgsql' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER COST 100;

 -- object recreation
DROP TRIGGER IF EXISTS "{{ triggerPrefix }}fkc_{{ name(foreignSchema, foreignTable) }}_delete" ON {{ iName(schema, table) }};

CREATE TRIGGER "{{ triggerPrefix }}fkc_{{ name(foreignSchema, foreignTable) }}_delete"
    AFTER DELETE ON {{ iName(schema, table) }} FOR EACH ROW
    {#- If old record has foreign key and has values. Remove them from foreign record. #}
    WHEN (OLD."{{ fk }}" IS NOT NULL AND ({{ hasValue(columns, 'OLD') }}))
    EXECUTE PROCEDURE {{ funcSchema() }}."t_fkc_{{ name(schema, table) }}_delete_to_{{ name(foreignSchema, foreignTable) }}"();


CREATE OR REPLACE FUNCTION {{ funcSchema() }}."t_fkc_{{ name(schema, table) }}_update_to_{{ name(foreignSchema, foreignTable) }}" ()
RETURNS trigger AS
$body$
DECLARE
    v_updated_count INTEGER := 1;
BEGIN
    -- Auto generated function by pg-fk-cache-generator node.js module.
    {{ setSearchPath() }}
    IF OLD."{{ fk }}" IS DISTINCT FROM NEW."{{ fk }}" THEN
        IF OLD."{{ fk }}" IS NOT NULL THEN -- Remove if it had old foreign record.
            {{ removeQuery() }}
            GET DIAGNOSTICS v_updated_count = ROW_COUNT;
        END IF;

        IF NEW."{{ fk }}" IS NOT NULL AND v_updated_count > 0 THEN    -- Add if it has new foreign record.
            {{ addQuery() }}
        END IF;

    ELSE
        -- If record has foreign key and it is not changed, and values are changed, update them in foreign record.
        {{ addRemoveQuery() }}

    END IF;

    RETURN NULL;
END;
$body$
LANGUAGE 'plpgsql' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER COST 100;

 -- object recreation
DROP TRIGGER IF EXISTS "{{ triggerPrefix }}fkc_{{ name(foreignSchema, foreignTable) }}_update" ON {{ iName(schema, table) }};

CREATE TRIGGER "{{ triggerPrefix }}fkc_{{ name(foreignSchema, foreignTable) }}_update"
    AFTER UPDATE OF "{{ fk }}", {{ valueColumn(columns) }} ON {{ iName(schema, table) }} FOR EACH ROW
    {#- Execute if FK is changed or FK is not null and one of the values is changed #}
    WHEN (OLD."{{ fk }}" IS DISTINCT FROM NEW."{{ fk }}" OR (NEW."{{ fk }}" IS NOT NULL AND ({{ isDistinctValue(columns) }})))
    EXECUTE PROCEDURE {{ funcSchema() }}."t_fkc_{{ name(schema, table) }}_update_to_{{ name(foreignSchema, foreignTable) }}"();
