# TOON (Token-Oriented Object Notation)

It is a compact, human-readable serialization format that reduces JSON token
count by 30-40% while maintaining lossless data fidelity. It uses CSV-style
tabular arrays for uniform data structures and YAML-like indentation for nested
objects, making it ideal for LLM input where token efficiency and parsing
reliability matter.

Key benefit: Same data, fewer tokens, better LLM understanding.

**Original JSON:**
```json
{
  "database": {
    "name": "user_management",
    "tables": [
      {
        "name": "users",
        "columns": [
          {
            "name": "id",
            "type": "integer",
            "primary_key": true
          },
          {
            "name": "email",
            "type": "string",
            "unique": true
          }
        ],
        "row_count": 1000
      },
      {
        "name": "orders",
        "columns": [
          {
            "name": "id",
            "type": "integer",
            "primary_key": true
          },
          {
            "name": "user_id",
            "type": "integer"
          }
        ],
        "row_count": 5000
      }
    ]
  }
}
```

**TOON equivalent:**
```
database:
  name: user_management
  tables[2]{name,row_count}:
    users,1000
    orders,5000
  tables[2]{name,columns}:
    users:
      columns[2]{name,type,primary_key}:
        id,integer,true
        email,string,true
    orders:
      columns[2]{name,type}:
        id,integer,true
        user_id,integer,false
```
