# Sales Analytics Project (MySQL)

A SQL-only sales analytics project on **MySQL 8.0+**. It uses a normalised 5-table schema and one master view (`vw_sales`) to answer business questions on revenue, profit, customers, products and regions.

## Dataset
| Table | Rows | Description |
|---|---|---|
| `suppliers` | 30 | Supplier city and rating |
| `products` | 120 | Category, sub-category, brand, unit and cost price |
| `customers` | 250 | Location, segment, join year, status |
| `sales_employees` | 25 | Region, designation, experience, target |
| `orders` | 300 | Order date (2023 to 2025), quantity, discount |

**Relationships:** `orders` links to `customers`, `products` and `sales_employees`, and `products` links to `suppliers`.

## Master View: `vw_sales`
Joins all five tables and adds calculated columns:
- `gross_amount` = qty × unit_price
- `revenue` = gross_amount after discount
- `cogs` = qty × cost_price
- `profit` = revenue − cogs

## Business Questions Answered
| # | Analysis | SQL concepts |
|---|---|---|
| 1 | Revenue, profit and margin % by year, with overall total | `GROUP BY ... WITH ROLLUP` |
| 2 | Month-over-month revenue growth | CTE, `LAG()` |
| 3 | Top 10 customers by revenue | `ORDER BY`, `LIMIT` |
| 4 | Category-wise revenue, profit and margin | Aggregation |
| 5 | Top 3 products per category | CTE, `DENSE_RANK()`, `PARTITION BY` |
| 6 | Revenue and average order value by state | Aggregation |
| 7 | Revenue and average order value by customer segment | Aggregation |
| 8 | Top state and segment combinations by average order value | `HAVING` |
| 9 | Customers who never ordered, with their % of all customers | `LEFT JOIN`, `IS NULL`, subquery |
| 10 | Loss-making products and total loss | `HAVING`, nested subquery |
| 11 | Products priced below cost | Filtering, derived column |

## Project Structure
| File | Description |
|---|---|
| `setup.sql` | Creates the database, tables, loads the CSVs, builds `vw_sales`, runs sanity checks |
| `Sales_project.sql` | The analysis queries |
| `customers.csv`, `orders.csv`, `products.csv`, `sales_employees.csv`, `suppliers.csv` | Source data |

## How to Run
1. Put the CSV files in a folder, for example `C:/sales_project/`.
2. In `setup.sql`, update the `LOAD DATA LOCAL INFILE` paths to that folder (use forward slashes).
3. If you get error 3948 or 1290, run `SET GLOBAL local_infile = 1;` and enable `OPT_LOCAL_INFILE=1` in the Workbench connection settings. Or use the Table Data Import Wizard instead.
4. Run `setup.sql`. The sanity check should return 30 / 250 / 120 / 25 / 300, and `vw_sales` should have 300 rows.
5. Run `Sales_project.sql` to see the analysis.

## Data Quality Notes
- Customer names have inconsistent casing (for example `KARTHIK NAIR`, `kavya gupta`). Names are left as-is, so clean them with `UPPER()` or `INITCAP`-style logic if you group by name.
- One customer (`C081`) has no email, which loads as `NULL`.
- Some products have `cost_price` above `unit_price`, which produces negative profit. Queries 10 and 11 flag these.

## Skills Demonstrated
MySQL, joins, views, CTEs, window functions (`LAG`, `DENSE_RANK`), `ROLLUP`, subqueries, aggregation, data validation

## Author
**Yogesh Rhaja** – Data Analyst & Power BI Developer
[LinkedIn](https://www.linkedin.com/in/yogeshrhaja-s/) | [GitHub](https://github.com/YogeshRhaja) | [Portfolio](https://yogeshrhaja-portfolio.vercel.app/)
