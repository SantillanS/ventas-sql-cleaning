# ventas-sql-cleaning
SQL project focused on cleaning, normalizing and deduplicating sales data imported from Excel, preparing a final table for analysis and Power BI.

## Dataset
Sales data imported from Excel with common data quality issues:
- Encoding problems (UTF-8 / BOM)
- Duplicated operation numbers
- Inconsistent text formatting
- Invalid dates and numeric values

## Common Issues
- Excel UTF-8 BOM encoding may introduce hidden characters in column names.
- Solution: re-import file using UTF-8 without BOM or normalize column names in SQL.
- MySQL Safe Update Mode may block UPDATE statements without a WHERE clause.
  Solution: disable Safe Update Mode for the session when running the pipeline.
