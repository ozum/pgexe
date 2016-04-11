{% from './util.njk' import iName, name, query, hasValue, valueColumn, isDistinctValue %}

{%- macro removeFromParents() -%}
    -- REMOVE CHILDREN FROM PARENTS
    UPDATE {{ iName(schema, table) }} SET "{{ children }}" = array_remove("{{ children }}" -# (OLD."{{ pk }}" || OLD."{{ children }}"), NULL),
        {{ query('remove', columns, true) }}
        WHERE {{ pk }} = ANY(OLD."{{ parents }}");
{%- endmacro -%}

{%- macro removeFromChildren(op) -%}
    -- REMOVE PARENTS FROM CHILDREN
    -- (Including NEW PK, because PK also may have changed, and OLD.PK is not available)
    UPDATE {{ iName(schema, table) }} SET "{{ parents }}" = array_remove("{{ parents }}" -# (OLD."{{ pk }}" || OLD."{{ parents }}"), NULL) WHERE {{ pk }} = ANY(OLD."{{ children }}" || OLD."{{ pk }}" {{ ('|| NEW."' + pk + '"') | safe if op == 'UPDATE' }});
{%- endmacro -%}

{%- macro checkCircular(op) -%}
    IF NEW."{{ fk }}" IS NOT NULL THEN    -- Check circular
        SELECT * INTO v_parent FROM {{ iName(schema, table) }} WHERE "{{ pk }}" = NEW."{{ fk }}";

        {#- If it is update it may be updates PK too so check for OLD Pk too. #}
        {%- if op == 'UPDATE' %}
            IF (v_parent."{{ parents }}" && ARRAY[NEW."{{ pk }}", OLD."{{ pk }}"]) OR NEW."{{ fk }}" IN (NEW."{{ pk }}", OLD."{{ pk }}") THEN
        {%- else %}
            IF NEW."{{ pk }}" = ANY(v_parent."{{ parents }}") OR NEW."{{ fk }}" = NEW."{{ pk }}" THEN
        {%- endif %}
            RAISE EXCEPTION 'Circular parent-child chain detected in table ({{ iName(schema, table) }}). Operation aborted. Primary key (%) is in new parents (%)', NEW."{{ pk }}", NEW."{{ parents }}";
        END IF;
    END IF;
{%- endmacro -%}

{%- macro addToParents() -%}
    -- ADD CHILDREN TO PARENTS
    UPDATE {{ iName(schema, table) }} SET "{{ children }}" = array_remove(fkc_array_insert("{{ children }}", NEW."{{ fk }}", NEW."{{ pk }}" || COALESCE(NEW."{{ children }}", '{}')), NULL),
        {{ query('add', columns, true) }}
        WHERE "{{ pk }}" = ANY(NEW."{{ fk }}" || COALESCE(v_parent."{{ parents }}", '{}'));
{%- endmacro -%}

{%- macro addToChildren() -%}
    -- ADD PARENTS TO CHILDREN
    UPDATE {{ iName(schema, table) }} SET "{{ parents }}" = array_remove(("{{ parents }}" || NEW."{{ pk }}" || NEW."{{ fk }}" || v_parent."{{ parents }}" -# "{{ pk }}"), NULL)
        WHERE "{{ pk }}" = ANY(NEW."{{ pk }}" || COALESCE(NEW."{{ children }}", '{}'));
{%- endmacro -%}

{%- macro addRemoveQuery() -%}
    UPDATE {{ iName(schema, table) }} SET "{{ children }}" = array_remove(fkc_array_insert("{{ children }}", NEW."{{ fk }}", NEW."{{ pk }}" || COALESCE(NEW."{{ children }}", '{}')) -# (OLD."{{ pk }}" || COALESCE(OLD."{{ children }}", '{}')), NULL),
        {{ query('addRemove', columns, true) }}
        WHERE "{{ pk }}" = ANY(NEW."{{ parents }}");
{%- endmacro -%}

{%- macro isCascadedQuery() -%}
    SELECT COUNT("{{ pk }}") = 0 INTO v_is_cascaded FROM {{ iName(schema, table) }} WHERE "{{ pk }}" = OLD."{{ fk }}";
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
                            TRIGGERS FOR {{ iName(schema, table) }}
-----------------------------------------------------------------------------------*/

CREATE OR REPLACE FUNCTION {{ funcSchema() }}."t_fkc_recursive_{{ name(schema, table) }}_insert" ()
RETURNS trigger AS
$body$
DECLARE
    v_parent    {{ iName(schema, table) }}%ROWTYPE;
BEGIN
    -- Auto generated function by pg-fk-cache-generator node.js module.
    {{ setSearchPath() }}
    {{ checkCircular() }}
    {{ addToParents() }}
    {{ addToChildren() }}

    RETURN NULL;
END;
$body$
LANGUAGE 'plpgsql' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER COST 100;

 -- object recreation
DROP TRIGGER IF EXISTS "{{ triggerPrefix }}fkc_recursive_{{ name(schema, table) }}_insert" ON {{ iName(schema, table) }};

CREATE TRIGGER "{{ triggerPrefix }}fkc_recursive_{{ name(schema, table) }}_insert"
    AFTER INSERT ON {{ iName(schema, table) }} FOR EACH ROW
    {#- If record has foreign key, and has values, add them to to foreign record. #}
    WHEN (NEW."{{ fk }}" IS NOT NULL AND (NEW."{{ fk }}" IS NOT NULL OR {{ hasValue(columns, 'NEW') }}))
    EXECUTE PROCEDURE {{ funcSchema() }}."t_fkc_recursive_{{ name(schema, table) }}_insert"();


CREATE OR REPLACE FUNCTION {{ funcSchema() }}."t_fkc_recursive_{{ name(schema, table) }}_delete" ()
RETURNS trigger AS
$body$
DECLARE
    v_is_cascaded BOOLEAN := FALSE;
BEGIN
    -- Auto generated function by pg-fk-cache-generator node.js module.
    {{ setSearchPath() }}
    IF OLD."{{ fk }}" IS NOT NULL THEN
        {{ isCascadedQuery() }}
        IF v_is_cascaded THEN
            -- Delete operation already updated related parent records via special remove query (operation = RECURSIVE DELETE in fk_get_operation).
            -- Children are deleted via cascade. So nothing needs to be done.
            RETURN NULL;
        END IF;
    END IF;

    {{ removeFromParents() }}
    {{ removeFromChildren() }}

    RETURN NULL;
END;
$body$
LANGUAGE 'plpgsql' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER COST 100;

 -- object recreation
DROP TRIGGER IF EXISTS "{{ triggerPrefix }}fkc_recursive_{{ name(schema, table) }}_delete" ON {{ iName(schema, table) }};

CREATE TRIGGER "{{ triggerPrefix }}fkc_recursive_{{ name(schema, table) }}_delete"
    AFTER DELETE ON {{ iName(schema, table) }} FOR EACH ROW
    {#- If old record has foreign key and has values. Remove them from foreign record. #}
    WHEN (OLD."{{ fk }}" IS NOT NULL AND (OLD."{{ fk }}" IS NOT NULL OR {{ hasValue(columns, 'OLD') }}))
    EXECUTE PROCEDURE {{ funcSchema() }}."t_fkc_recursive_{{ name(schema, table) }}_delete"();


CREATE OR REPLACE FUNCTION {{ funcSchema() }}."t_fkc_recursive_{{ name(schema, table) }}_update" ()
RETURNS trigger AS
$body$
DECLARE
    v_updated_count INTEGER := 1;
    v_is_cascaded   BOOLEAN := FALSE;
    v_parent        {{ iName(schema, table) }}%ROWTYPE;

BEGIN
    -- Auto generated function by pg-fk-cache-generator node.js module.
    {{ setSearchPath() }}
    IF OLD."{{ fk }}" IS NOT NULL AND OLD."{{ fk }}" IS DISTINCT FROM NEW."{{ fk }}" THEN
        {{ isCascadedQuery() }}
        IF v_is_cascaded THEN
            -- Only foreign key is updated via cascade, just replace it in children cache. Parent's cache was updated via PK change of original record.
            UPDATE {{ iName(schema, table) }} SET "{{ parents }}" = array_replace("{{ parents }}", OLD."{{ fk }}", NEW."{{ fk }}")
                WHERE "{{ pk }}" = ANY(NEW."{{ pk }}" || COALESCE(NEW."{{ children }}", '{}'));

            RETURN NULL;
        END IF;
    END IF;

    IF OLD."{{ fk }}" IS DISTINCT FROM NEW."{{ fk }}" THEN
        {{ checkCircular('UPDATE') | indent(4) }}

        IF OLD."{{ fk }}" IS NOT NULL THEN -- Remove if it had old foreign record.
            {{ removeFromParents() | indent(8) }}
        END IF;

        {{ removeFromChildren('UPDATE') | indent(4) }}

        IF NEW."{{ fk }}" IS NOT NULL THEN    -- Add if it has new foreign record.
            {{ addToParents() | indent(8) }}
        END IF;

        {{ addToChildren() | indent(4) }}

    ELSE
        -- If record has foreign key and it is not changed, and values are changed, update them in foreign record.
        {{ addRemoveQuery() }}

    END IF;

    RETURN NULL;
END;
$body$
LANGUAGE 'plpgsql' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER COST 100;

 -- object recreation
DROP TRIGGER IF EXISTS "{{ triggerPrefix }}fkc_recursive_{{ name(schema, table) }}_update" ON {{ iName(schema, table) }};

CREATE TRIGGER "{{ triggerPrefix }}fkc_recursive_{{ name(schema, table) }}_update"
    AFTER UPDATE OF "{{ fk }}", {{ valueColumn(columns) }} ON {{ iName(schema, table) }} FOR EACH ROW
    {#- Execute if FK is changed or FK is not null and one of the values is changed #}
    WHEN (OLD."{{ pk }}" <> NEW."{{ pk }}" OR OLD."{{ fk }}" IS DISTINCT FROM NEW."{{ fk }}" OR (NEW."{{ fk }}" IS NOT NULL AND (NEW."{{ fk }}" IS NOT NULL OR {{ isDistinctValue(columns) }})))
    EXECUTE PROCEDURE {{ funcSchema() }}."t_fkc_recursive_{{ name(schema, table) }}_update"();
