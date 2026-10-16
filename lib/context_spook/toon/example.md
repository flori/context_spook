# TOON format — quick reference
#
# key: value                  scalar (bare if safe)
# key[2]:                     array with length
#   - item                    list item
# key[4]{col1,col2}:          tabular array (CSV rows)
#   val1,val2                 one row per line
#
# Quoting: double-quote a string only if it contains
# , { } [ ] # " \  or starts/ends with whitespace, or looks
# like a number / true / false / null.

files:
  "app/models/user.rb":
    content[4]{linenumber,line}:
      1,require 'json'
      2,""
      3,"# a comment line"
      4,def parse(data)
    size: 42
    lines: 4
database:
  name: user_management
  tables[2]:
    - name: users
      columns[2]:
        - name: id
          type: integer
          primary_key: true
        - name: email
          type: string
      row_count: 1000
    - name: orders
      columns[2]:
        - name: id
          type: integer
        - name: user_id
          type: integer
      row_count: 5000
