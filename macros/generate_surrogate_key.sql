-- Macro to generate surrogate keys using MD5 hash
-- Usage: {{ generate_surrogate_key(['column1', 'column2']) }}

{% macro generate_surrogate_key(column_list) -%}
    to_hex(md5(concat(
        {%- for column in column_list -%}
            cast({{ column }} as string)
            {%- if not loop.last %}, '-', {% endif -%}
        {%- endfor -%}
    )))
{%- endmacro %}