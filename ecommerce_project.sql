-- ==================================================
-- PROJECT: E-COMMERCE SALES & CUSTOMER ANALYTICS
-- ==================================================
CREATE DATABASE ecommerce_project;
USE ecommerce_project;

CREATE TABLE categories(
id INT PRIMARY KEY,
category_name VARCHAR(100) NOT NULL,
category_description VARCHAR(255),
average_price DECIMAL(10,2)
);


CREATE TABLE products(
id INT PRIMARY KEY,
product_name VARCHAR(100) NOT NULL,
category_id INT,
price DECIMAL(10,2),
stock_quantity INT,
rating DECIMAL(3,2),
FOREIGN KEY(category_id)
REFERENCES categories(id)
);

CREATE TABLE customers(
id INT PRIMARY KEY,
full_name VARCHAR(50) NOT NULL,
email VARCHAR(75) UNIQUE NOT NULL,
registration_date DATE,
city VARCHAR(50)
); 



CREATE TABLE orders(
id INT PRIMARY KEY,
customer_id INT NOT NULL,
order_date DATETIME,
total_amount DECIMAL(10,2),
quantity INT,
discount_amount DECIMAL(10,2),
FOREIGN KEY(customer_id)
REFERENCES customers(id)
);

CREATE TABLE payments(
id INT PRIMARY KEY,
order_id INT NOT NULL,
payment_method VARCHAR(50) NOT NULL,
payment_date DATETIME,
transaction_fee DECIMAL(10,2),
FOREIGN KEY(order_id)
REFERENCES orders(id)
);


-- ==================================================
-- 01. DATA CLEANING & VALIDATION
-- ==================================================
SELECT * FROM customers;
UPDATE customers
SET city = 'Unknown'
WHERE id IN (
    SELECT id
    FROM (
        SELECT id
        FROM customers
        WHERE city = ''
    ) AS temp
);
-- a. Customer Table
SELECT
    COUNT(CASE WHEN id IS NULL THEN 1 END) AS null_id,
    COUNT(CASE WHEN full_name IS NULL THEN 1 END) AS null_name,
    COUNT(CASE WHEN email IS NULL THEN 1 END) AS null_email,
    COUNT(CASE WHEN registration_date IS NULL THEN 1 END) AS null_date,
    COUNT(CASE WHEN city IS NULL THEN 1 END) AS null_city
FROM customers;

-- b. Orders Table
SELECT
	COUNT(CASE WHEN id IS NULL THEN 1 END) AS null_id,
    COUNT(CASE WHEN order_date IS NULL THEN 1 END) AS null_date,
    COUNT(CASE WHEN total_amount IS NULL THEN 1 END) AS null_amount,
    COUNT(CASE WHEN quantity IS NULL THEN 1 END) AS null_quantity,
    COUNT(CASE WHEN discount_amount IS NULL THEN 1 END) AS null_discount
FROM orders;

-- c. Categories Table
SELECT 
	COUNT(CASE WHEN id IS NULL THEN 1 END) AS null_id,
    COUNT(CASE WHEN category_name IS NULL THEN 1 END) AS null_name,
    COUNT(CASE WHEN category_description IS NULL THEN 1 END) AS null_description,
    COUNT(CASE WHEN average_price IS NULL THEN 1 END) AS null_price
FROM categories;

-- d. Products  Table
SELECT
	COUNT(CASE WHEN id IS NULL THEN 1 END) AS null_id,
    COUNT(CASE WHEN price IS NULL THEN 1 END) AS null_price,
    COUNT(CASE WHEN stock_quantity IS NULL THEN 1 END) AS null_quantity,
    COUNT(CASE WHEN rating IS NULL THEN 1 END) AS null_rating
FROM products;

-- e. Payments Table
SELECT
	COUNT(CASE WHEN id IS NULL THEN 1 END) AS null_id,
    COUNT(CASE WHEN payment_method IS NULL THEN 1 END) AS null_method,
    COUNT(CASE WHEN payment_date IS NULL THEN 1 END) AS null_date,
    COUNT(CASE WHEN transaction_fee IS NULL THEN 1 END) AS null_fee
FROM payments;

-- ==================================================
-- 02. CUSTOMER ANALYSIS
-- ==================================================

-- 1. Which 5 cities have the highest number of customers?
SELECT city, COUNT(id) AS total_customers	
FROM customers
GROUP BY city
ORDER BY total_customers DESC
LIMIT 5;

-- 2. 	Who are the top 10 customers based on their total spending?
SELECT full_name, customers.id AS cust_id , SUM(total_amount) AS total_spending 
FROM customers 
JOIN orders
ON customers.id = orders.customer_id
GROUP BY customers.id , full_name
ORDER BY total_spending DESC
LIMIT 10;

-- 3. Which customers have placed the highest number of orders?
SELECT full_name ,COUNT(orders.id)  as total_orders , customers.id AS customer_ID
FROM customers
JOIN orders
ON customers.id = orders.customer_id
GROUP BY customers.id , full_name
ORDER BY total_orders DESC; 


-- 4. Which registered customers have never placed an order?

SELECT full_name , orders.id
FROM customers
LEFT JOIN orders
ON customers.id = orders.customer_id
WHERE orders.id IS NULL;

-- 5. Which cities generate the highest revenue, and how much revenue does each city contribute?
SELECT city , SUM(total_amount) AS revenue
FROM customers
INNER JOIN orders
ON customers.id = orders.customer_id
GROUP BY city
ORDER BY revenue DESC;


-- ==================================================
-- 03. SALES & ORDER ANALYSIS
-- ==================================================

-- 1. What are the total revenue, average order value and total number of orders?
SELECT SUM(total_amount) AS total_revenue , AVG(total_amount) AS AOV, COUNT(id)
FROM orders;

-- 2. Which months generate the highest revenue?
SELECT MONTH(order_date) AS monthly, YEAR(order_date) AS yearly  , SUM(total_amount) AS revenue
FROM orders
GROUP BY  yearly ,monthly
ORDER BY revenue DESC;

-- 3. What are the 10 highest-value orders?
SELECT id, total_amount 
FROM orders
ORDER BY total_amount DESC
LIMIT 10;

-- 4. 	How much discount has the business given, and what percentage of total order value does it represent?

SELECT
    SUM(discount_amount) AS total_discount,
    SUM(total_amount) AS total_order_value,
    (SUM(discount_amount) / NULLIF(SUM(total_amount), 0)) * 100 AS discount_percentage
FROM orders;

-- 5. Which months have declining sales compared with the previous month?
WITH monthly_sales AS (
    SELECT
        SUM(total_amount) AS revenue,
        MONTH(order_date) AS month,
        YEAR(order_date) AS year
    FROM orders
    GROUP BY year, month
),

monthly_comparison AS (
    SELECT
        year, month, revenue,
        LAG(revenue) OVER (
            ORDER BY year, month
        ) AS previous_revenue
    FROM monthly_sales
)
SELECT
    year,
    month,
    revenue,
    previous_revenue,
    previous_revenue - revenue AS revenue_decline
FROM monthly_comparison
WHERE revenue < previous_revenue
ORDER BY year, month;


-- ==================================================
-- 04. PRODUCT & CATEGORY ANALYSIS
-- ==================================================

-- 1. Which product categories have the highest average product prices?
SELECT categories.id , category_name, AVG(products.price) AS average_price
FROM categories
JOIN products
ON categories.id = products.category_id
GROUP BY categories.id  , category_name
ORDER BY average_price DESC;

-- 2. 	Which are the 10 highest-rated products?
SELECT product_name , rating 
FROM products
ORDER BY rating DESC
LIMIT 10;

-- 3. Which products have low stock and need restocking?

-- Inventory Monitoring
SELECT * FROM products;
SELECT id , product_name , stock_quantity 
FROM products
WHERE stock_quantity < 250; -- 250 is considered as threshold 

-- Inventory BenchMarking 
WITH avg_stock AS (
	SELECT 
		id , product_name , stock_quantity,
        AVG(stock_quantity) OVER () AS avg_stock
	FROM products
)
SELECT id , product_name , stock_quantity
FROM avg_stock
WHERE stock_quantity < avg_stock;

-- 4. 	Which categories contain the highest number of products?
SELECT
    categories.id,
    category_name,
    COUNT(products.id) AS total_products
FROM categories
JOIN products
    ON categories.id = products.category_id
GROUP BY categories.id, category_name
ORDER BY total_products DESC;

-- 5. 	Within each category, which products are the top 3 highest-priced?
WITH ranked_products AS (
	SELECT category_name , product_name , price,
    ROW_NUMBER() OVER (
    PARTITION BY category_id
    ORDER BY price DESC
	) AS product_rank
    FROM categories
    JOIN products
    ON categories.id = products.category_id
)
SELECT category_name , product_name , price
FROM ranked_products
WHERE product_rank <= 3;
    
-- ==================================================
-- 05. PAYMENT & BUSINESS INSIGHTS
-- ==================================================

-- 1. Which payment methods are used most frequently?
SELECT payment_method , COUNT(payment_method) AS total_method 
FROM payments 
GROUP BY payment_method
ORDER BY total_method DESC;

-- 2. Which payment methods have the highest average transaction fees?
SELECT payment_method , AVG(transaction_fee) AS avg_transaction
FROM payments
GROUP BY payment_method
ORDER BY avg_transaction DESC;

-- 3. What percentage of orders have suspicious discounts?
WITH discount_analysis AS (
    SELECT
        SUM(CASE WHEN discount_amount > total_amount THEN 1 ELSE 0 END) AS suspicious_orders,
        COUNT(id) AS total_orders
    FROM orders
)
SELECT
    suspicious_orders,
    total_orders,
    ROUND((suspicious_orders / NULLIF(total_orders)) * 100, 2) AS suspicious_percentage
FROM discount_analysis;

-- 4. 	Which customers contribute the most revenue, and what percentage of total revenue do they generate?

WITH customer_revenue AS (
	SELECT SUM(total_amount) AS revenue , full_name 
    FROM customers
    JOIN orders
    ON customers.id = orders.customer_id
    GROUP BY customers.id , full_name
)
SELECT full_name , 
		revenue,
        SUM(revenue) OVER() AS total_revenue,
        ROUND((revenue / SUM(revenue) OVER()) * 100,2) AS revenue_percentage
FROM customer_revenue;


-- Referential Integrity Check

-- 1
SELECT product_name , categories.id
FROM products
LEFT JOIN categories 
ON categories.id = products.category_id
WHERE categories.id IS NULL;

-- 2
SELECT orders.id , customers.id
FROM orders 
LEFT JOIN customers 
ON orders.customer_id = customers.id
WHERE customers.id IS NULL;

-- 3 
SELECT payments.id , orders.id
FROM payments
LEFT JOIN orders
ON payments.order_id = orders.id
WHERE orders.id IS NULL;