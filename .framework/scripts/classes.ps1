# Column structure classes
class cl_column {
  [string]$ColumnName
  [string]$DataType
  [int]$MaxLength
  [int]$Precision
  [int]$Scale
  [bool]$IsNullable
  [string]$DefaultValue
  [bool]$IsIdentity
  [int]$OrdinalPosition
}

# Table structure classes
class cl_table {
    [string]$Database
    [string]$TableName
    [string]$SchemaName
    [System.Collections.ArrayList]$Columns = @()
    [System.Collections.ArrayList]$Indexes = @()
    [System.Collections.ArrayList]$Constraints = @()
}