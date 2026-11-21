-- ==========================================================
-- SALES ANALYTICS PROJECT  |  MySQL 8.0+
-- Run order: schema -> load CSVs -> view -> sanity checks
-- ==========================================================
DROP DATABASE IF EXISTS sales_project;
CREATE DATABASE sales_project;
USE sales_project;

-- ---------- 1. TABLES ----------
CREATE TABLE suppliers (
    supplier_id   VARCHAR(10) PRIMARY KEY,
    supplier_name VARCHAR(50),
    city          VARCHAR(50),
    rating        TINYINT
);

CREATE TABLE products (
    product_id    VARCHAR(10) PRIMARY KEY,
    product_name  VARCHAR(50),
    category      VARCHAR(50),
    sub_category  VARCHAR(50),
    brand         VARCHAR(30),
    unit_price    INT,
    cost_price    INT,
    supplier_id   VARCHAR(10),
    launch_year   INT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

CREATE TABLE customers (
    customer_id     VARCHAR(10) PRIMARY KEY,
    customer_name   VARCHAR(60),
    gender          VARCHAR(10),
    age             INT,
    city            VARCHAR(50),
    state           VARCHAR(50),
    segment         VARCHAR(20),
    join_year       INT,
    email           VARCHAR(80),
    customer_status VARCHAR(15)
);

CREATE TABLE sales_employees (
    salesperson_id   VARCHAR(10) PRIMARY KEY,
    salesperson_name VARCHAR(50),
    gender           VARCHAR(10),
    region           VARCHAR(20),
    designation      VARCHAR(30),
    experience       INT,
    joining_year     INT,
    target_amount    INT
);

CREATE TABLE orders (
    order_id       VARCHAR(10) PRIMARY KEY,
    order_date     DATE,
    customer_id    VARCHAR(10),
    product_id     VARCHAR(10),
    qty            INT,
    salesperson_id VARCHAR(10),
    discount_pct   INT,
    FOREIGN KEY (customer_id)    REFERENCES customers(customer_id),
    FOREIGN KEY (product_id)     REFERENCES products(product_id),
    FOREIGN KEY (salesperson_id) REFERENCES sales_employees(salesperson_id)
);

-- ---------- 2. LOAD DATA ----------
-- Change the folder path to where you saved the CSVs (use forward slashes).
-- If you get error 3948/1290, run:  SET GLOBAL local_infile = 1;
-- and enable "OPT_LOCAL_INFILE=1" in Workbench connection > Advanced.
-- (Alternative: right-click each table in Workbench > Table Data Import Wizard)

LOAD DATA LOCAL INFILE 'C:/sales_project/suppliers.csv'
INTO TABLE suppliers FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/sales_project/products.csv'
INTO TABLE products FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/sales_project/customers.csv'
INTO TABLE customers FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS
(customer_id, customer_name, gender, age, city, state, segment, join_year, @email, customer_status)
SET email = NULLIF(@email, '');

LOAD DATA LOCAL INFILE 'C:/sales_project/sales_employees.csv'
INTO TABLE sales_employees FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/sales_project/orders.csv'
INTO TABLE orders FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- ---------- 3. SANITY CHECKS (expected: 30 / 250 / 120 / 25 / 300) ----------
SELECT 'suppliers' t, COUNT(*) n FROM suppliers
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sales_employees', COUNT(*) FROM sales_employees
UNION ALL SELECT 'orders', COUNT(*) FROM orders;

-- ---------- 4. MASTER VIEW (use this for most questions) ----------
-- gross_amount = qty * unit_price
-- revenue      = gross_amount after discount
-- cogs         = qty * cost_price
-- profit       = revenue - cogs
CREATE OR REPLACE VIEW vw_sales AS
SELECT
    o.order_id, o.order_date,
    YEAR(o.order_date)  AS order_year,
    MONTH(o.order_date) AS order_month,
    o.qty, o.discount_pct,
    c.customer_id, c.customer_name, c.gender AS customer_gender, c.age,
    c.city, c.state, c.segment, c.customer_status,
    p.product_id, p.product_name, p.category, p.sub_category, p.brand,
    p.unit_price, p.cost_price,
    s.supplier_id, s.supplier_name, s.rating AS supplier_rating,
    e.salesperson_id, e.salesperson_name, e.region, e.designation, e.target_amount,
    o.qty * p.unit_price                                        AS gross_amount,
    ROUND(o.qty * p.unit_price * (1 - o.discount_pct/100), 2)   AS revenue,
    o.qty * p.cost_price                                        AS cogs,
    ROUND(o.qty * p.unit_price * (1 - o.discount_pct/100)
          - o.qty * p.cost_price, 2)                            AS profit
FROM orders o
JOIN customers       c ON o.customer_id    = c.customer_id
JOIN products        p ON o.product_id     = p.product_id
JOIN suppliers       s ON p.supplier_id    = s.supplier_id
JOIN sales_employees e ON o.salesperson_id = e.salesperson_id;

SELECT COUNT(*) AS rows_in_view FROM vw_sales;   -- expected 300
