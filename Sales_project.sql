USE sales_project;
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
SELECT COALESCE(CAST(order_year AS CHAR), 'Overall') AS period,
       ROUND(SUM(revenue), 2)                        AS total_revenue,
       ROUND(SUM(profit), 2)                         AS total_profit,
       ROUND(SUM(profit) / SUM(revenue) * 100, 2)    AS margin_pct
FROM vw_sales
GROUP BY order_year WITH ROLLUP;
WITH monthly AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS ym,
           SUM(revenue) AS revenue
    FROM vw_sales
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT ym,
       ROUND(revenue, 2)                                   AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY ym), 2)           AS prev_month_revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY ym))
             / LAG(revenue) OVER (ORDER BY ym) * 100, 2)  AS mom_growth_pct
FROM monthly
ORDER BY ym;
SELECT customer_id, customer_name, segment, state,
       COUNT(*)                AS orders,
       ROUND(SUM(revenue), 2)  AS total_revenue,
       ROUND(SUM(profit), 2)   AS total_profit
FROM vw_sales
GROUP BY customer_id, customer_name, segment, state
ORDER BY total_revenue DESC
LIMIT 10;
SELECT category,
       ROUND(SUM(revenue), 2)                      AS revenue,
       ROUND(SUM(profit), 2)                       AS profit,
       ROUND(SUM(profit) / SUM(revenue) * 100, 2)  AS margin_pct
FROM vw_sales
GROUP BY category
ORDER BY profit DESC;
WITH ranked AS (
    SELECT category, product_id, product_name,
           SUM(qty)      AS units_sold,
           SUM(revenue)  AS revenue,
           DENSE_RANK() OVER (PARTITION BY category ORDER BY SUM(revenue) DESC) AS rnk
    FROM vw_sales
    GROUP BY category, product_id, product_name
)
SELECT category, rnk AS `rank`, product_id, product_name, units_sold,
       ROUND(revenue, 2) AS revenue
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk;
SELECT state,
       COUNT(*)                 AS orders,
       ROUND(SUM(revenue), 2)   AS total_revenue,
       ROUND(AVG(revenue), 2)   AS avg_order_value
FROM vw_sales
GROUP BY state
ORDER BY total_revenue DESC;

SELECT segment,
       COUNT(*)                 AS orders,
       ROUND(SUM(revenue), 2)   AS total_revenue,
       ROUND(AVG(revenue), 2)   AS avg_order_value
FROM vw_sales
GROUP BY segment
ORDER BY total_revenue DESC;
SELECT state, segment,
       COUNT(*)                 AS orders,
       ROUND(AVG(revenue), 2)   AS avg_order_value
FROM vw_sales
GROUP BY state, segment
HAVING COUNT(*) >= 3
ORDER BY avg_order_value DESC
LIMIT 10;
SELECT c.customer_id, c.customer_name, c.city, c.state,
       c.segment, c.join_year, c.customer_status
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

SELECT COUNT(*) AS never_ordered,
       ROUND(COUNT(*) / (SELECT COUNT(*) FROM customers) * 100, 2) AS pct_of_customers
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
SELECT product_id, product_name, category,
       unit_price, cost_price,
       SUM(qty)                 AS units_sold,
       ROUND(SUM(revenue), 2)   AS revenue,
       ROUND(SUM(cogs), 2)      AS cogs,
       ROUND(SUM(profit), 2)    AS net_loss
FROM vw_sales
GROUP BY product_id, product_name, category, unit_price, cost_price
HAVING SUM(profit) < 0
ORDER BY net_loss ASC;
SELECT ROUND(SUM(net_loss), 2) AS total_loss
FROM (
    SELECT SUM(profit) AS net_loss
    FROM vw_sales
    GROUP BY product_id
    HAVING SUM(profit) < 0
) t;
SELECT product_id, product_name, category, unit_price, cost_price,
       cost_price - unit_price AS loss_per_unit
FROM products
WHERE cost_price > unit_price
ORDER BY loss_per_unit DESC;