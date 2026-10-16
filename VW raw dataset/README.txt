VOLKSWAGEN INDIA SALES ANALYSIS - SYNTHETIC MESSY DATASET
=============================================================

IMPORTANT:
This is SYNTHETIC practice data. It uses real Volkswagen model names, but the
sales transactions, customers, dealers, prices and quantities are fabricated.


FILES
-----
cars_raw.csv       Vehicle/model master data (~26 rows)
dealers_raw.csv    Dealer master data (100 rows)
customers_raw.csv  Customer data (~20,150 rows including deliberate duplicates)
sales_raw.csv      Sales transactions (~120,800 rows including deliberate duplicates)

INTENTIONAL DATA-QUALITY ISSUES
-------------------------------
- Duplicate sales records
- Duplicate customer records
- Missing customer/dealer/payment/discount values
- Mixed date formats
- Inconsistent city names (Bangalore/Bengaluru/B'lore etc.)
- State abbreviations and capitalization differences
- Inconsistent payment-type casing/spacing
- Inconsistent fuel-type values
- Negative discounts
- Zero selling prices
- Zero units sold
- Extra whitespace

PROJECT FLOW
------------------------
1. Load raw tables into your database.
2. Profile row counts, NULLs, duplicates and invalid values.
3. Create cleaned/staging tables rather than modifying raw data.
4. Standardize dates, cities, states, categories and numeric fields.
5. Validate relationships between sales, customers, dealers and cars.
6. Analyze revenue, units, monthly trends, model performance and dealer performance.
7. Use CTEs, subqueries and window functions for advanced questions.
8. Export useful results to Excel for a dashboard.

