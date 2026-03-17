# How to design/setup your definitions

In the folders `1-inbound`, `2_intermeidate` and `3-delivery` the tables and respective views are defined. Each table should have a view which is used to populate the table.

## Naming convention

A object should be following `${nm_database_target}<virtual-schema-name>_<object-type-code>_<object-name>`

| Part | Description |
|------|-------------|
| `${nm_database_target}` | This will be automatically replace when deploying, with value from enviroment configuaration. |
| `<virtual-schema-name>` | short logica name, that caputures the genaral theme of the dataset for the `virtual schema`. |
| `<object-type-code>`    | Type of the Object `tbl` for table and `viw` for a view. |
| `<object-name>`         | Name of the dataset. |

## Base folder structure

```Text
project/
├── 1-inbound/                # Inboud (ingestion) datasets should be organized here by `virtual-schema`
│   └── <virtual-scehma-name> # Name of the virtual schema
│       ├── tables            # defintions/create table statment per table one sql-file
│       └── views             # defintions/replace view statments per table one view-definition with same object name
├── 2-intermediate/           # Intermediate (transformation) datasets should be organized here by `virtual-schema`
│   └── <virtual-scehma-name> # Name of the virtual schema
│       ├── tables            # defintions/create table statment per table one sql-file
│       └── views             # defintions/replace view statments per table one view-definition with same object name```
└── 3-delivery/               # Delivery (outbound) datasets should be organized here by `virtual-schema`
    └── <virtual-scehma-name> # Name of the virtual schema
        ├── tables            # defintions/create table statment per table one sql-file
        └── views             # defintions/replace view statments per table one view-definition with same object name
```

### virual schema

A `Virtual schema` is a means to organize the dataset in logic/related group and to convee functional information on th intended use.

### object name

A dataset has two part of the definitions the table definition and view definition. The table describes the physical structure of the dataset with the database then `view` describes how the data is `transformed` before in is loaded into the table.
