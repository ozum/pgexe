{% from './util.njk' import iName, name, query, hasValue, valueColumn, isDistinctValue %}

{%- macro funcSchema() -%}
    "{{ outputSchema | d(schema) | d('public') }}"
{%- endmacro -%}

DROP TRIGGER IF EXISTS "fkc_{{ name(foreignSchema, foreignTable) }}_insert" ON {{ iName(schema, table) }};
DROP TRIGGER IF EXISTS "fkc_{{ name(foreignSchema, foreignTable) }}_delete" ON {{ iName(schema, table) }};
DROP TRIGGER IF EXISTS "fkc_{{ name(foreignSchema, foreignTable) }}_update" ON {{ iName(schema, table) }};

DROP FUNCTION IF EXISTS {{ funcSchema() }}."t_fkc_{{ name(schema, table) }}_insert_to_{{ name(foreignSchema, foreignTable) }}"();
DROP FUNCTION IF EXISTS {{ funcSchema() }}."t_fkc_{{ name(schema, table) }}_delete_to_{{ name(foreignSchema, foreignTable) }}"();
DROP FUNCTION IF EXISTS {{ funcSchema() }}."t_fkc_{{ name(schema, table) }}_update_to_{{ name(foreignSchema, foreignTable) }}"();

DROP TRIGGER IF EXISTS "fkc_recursive_{{ name(schema, table) }}_insert" ON {{ iName(schema, table) }};
DROP TRIGGER IF EXISTS "fkc_recursive_{{ name(schema, table) }}_delete" ON {{ iName(schema, table) }};
DROP TRIGGER IF EXISTS "fkc_recursive_{{ name(schema, table) }}_update" ON {{ iName(schema, table) }};

DROP FUNCTION IF EXISTS {{ funcSchema() }}."t_fkc_recursive_{{ name(schema, table) }}_insert"();
DROP FUNCTION IF EXISTS {{ funcSchema() }}."t_fkc_recursive_{{ name(schema, table) }}_delete"();
DROP FUNCTION IF EXISTS {{ funcSchema() }}."t_fkc_recursive_{{ name(schema, table) }}_update"();

