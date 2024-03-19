-- Fimiliar with dataset

-- Show available databases
SHOW DATABASES;

-- Switch to the "mintclassics" database
USE mintclassics;

-- Show tables in the "mintclassics" database
SHOW TABLES;

-- Select all columns from the "customers" table
SELECT * FROM customers;

-- Select the "productName" column from the "products" table
SELECT productName FROM products;

-- Count the number of rows in the "products" table
SELECT COUNT(productName) FROM products;

-- Group products by product line and count the number of products for each product line
SELECT productLine, COUNT(productName) AS productCount
FROM products
GROUP BY productLine;

-- 1. Where are items stored? Can warehouse elimination be considered through rearrangement?

SELECT * FROM WarehouseStockView;
SELECT * FROM WarehouseProductStockView;
SELECT * FROM product_count_view;
SELECT * FROM WarehouseProductAvailabilityView;
SELECT * FROM LowSalesProductsView;

CREATE VIEW WarehouseStockView AS;
SELECT
    w.warehouseCode,
    w.warehouseName,
    SUM(p.quantityInStock) AS 'ItemQuantityInStock'
FROM
    products p
JOIN
    warehouses w ON p.warehouseCode = w.warehouseCode
GROUP BY
    w.warehouseCode,
    w.warehouseName;

CREATE VIEW WarehouseProductStockView AS;
SELECT
    w.warehouseCode,
    w.warehouseName,
    p.productLine,
    SUM(p.quantityInStock) AS 'ItemQuantityInStock'
FROM
    products p
JOIN
    warehouses w ON p.warehouseCode = w.warehouseCode
GROUP BY
    w.warehouseCode,
    w.warehouseName,
    p.productLine;
    
CREATE VIEW product_count_view AS;
SELECT
    w.warehouseName,
    p.productLine,
    COUNT(p.productName) AS productCount
FROM
    products p
JOIN
    warehouses w ON p.warehouseCode = w.warehouseCode
GROUP BY
    w.warehouseName,
    p.productLine;

-- 2. How are inventory numbers correlated with sales figures? Are counts appropriate for each item?

CREATE VIEW WarehouseProductAvailabilityView AS;
SELECT
    w.warehouseName,
    p.productLine,
    p.productCode,
    p.productName,
    SUM(p.quantityInStock) AS 'ItemQuantityInStock',
    COALESCE(SUM(od.quantityOrdered), 0) AS 'TotalQuantityOrdered',
    SUM(p.quantityInStock) - COALESCE(SUM(od.quantityOrdered), 0) AS 'AvailableQuantity'
FROM
    products p
    LEFT JOIN orderdetails od ON p.productCode = od.productCode
    LEFT JOIN warehouses w ON p.warehouseCode = w.warehouseCode
GROUP BY
    w.warehouseName,
    p.productLine,
    p.productCode,
    p.productName;

-- 3. Are stagnant items present? Identify candidates for removal from the product line.

CREATE VIEW LowSalesProductsView AS;
SELECT
    p.productCode,
    p.productName,
    p.productLine,
    p.quantityInStock,
    COALESCE(SUM(od.quantityOrdered), 0) AS totalSalesQuantity
FROM
    products p
LEFT JOIN
    orderdetails od ON p.productCode = od.productCode
GROUP BY
    p.productCode,
    p.productName,
    p.productLine,
    p.quantityInStock
HAVING
    totalSalesQuantity = 0 OR totalSalesQuantity < 5; -- Adjust the threshold as needed
-- -----

SELECT
    w.warehouseName,
    p.productLine,
    p.productCode,
    p.productName,
    SUM(p.quantityInStock) AS 'ItemQuantityInStock',
    COALESCE(SUM(od.quantityOrdered), 0) AS 'TotalQuantityOrdered',
    SUM(p.quantityInStock) - COALESCE(SUM(od.quantityOrdered), 0) AS 'AvailableQuantity',
    SUM(pt.amount) AS 'TotalAmount'
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    w.warehouseName,
    p.productLine,
    p.productCode,
    p.productName;

-- --------------------------------------

-- 1. Determine important factors that may influence inventory reorganization/reduction.

Select status,count(orderNumber) from orders group by status;
Select orderNumber,count(quantityOrdered) from orderdetails group by orderNumber;

Select country,count(city) from offices group by country;
Select city,count(country) from offices group by city;

Select distinct(city) from customers;
Select count(city) from customers;

Select Distinct(country) , customerNumber from customers;

Select Distinct(country) from customers;

-- TOTAL PRODUCT

Select sum(quantityInStock)
from products;

-- happy
   
-- Warehouse Utilization:
-- 1)Which items have the highest and lowest storage quantities in each warehouse?
-- 2)Are there items that are stored in multiple warehouses? If so, can they be consolidated to a single warehouse?

-- Quantity Order
 

-- Identify the top ten customers.
SELECT
    pt.customerNumber,
    c.customerName,
    round(sum(pt.amount)) as "Total Amount"
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    pt.customerNumber,
    c.customerName
ORDER BY pt.customerNumber desc
limit 10;

-- Top ten cities.

SELECT
    c.city,
    round(sum(pt.amount)) as "Total Sales"
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    c.city
ORDER BY 2 desc
limit 10;

-- Top five countries.

SELECT
    c.country,
    round(sum(pt.amount)) as "Total Sales"
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    c.country
ORDER BY 2 desc;

-- Products with most sales and least sales.
SELECT
    p.productCode,
    p.productName,
    round(sum(pt.amount)) as "Total Sales",
	round(sum(pt.amount)) as "Total Sales"
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    p.productCode,
    p.productName
ORDER BY 3 desc, 3 asc
limit 10;

-- Products with most sales and least sales.
SELECT
    p.productCode,
    p.productName,
	round(sum(pt.amount)) as "Total Sales"
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    p.productCode,
    p.productName
ORDER BY 3 asc
limit 10;

-- Most ordered product
SELECT
    p.productName,
    count(od.orderNumber) as "Most Orders"
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    p.productName
ORDER BY 2 desc
limit 5;

-- Least ordered product
SELECT
    p.productName,
    count(od.orderNumber) as "Least Orders"
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    p.productName
ORDER BY 2 asc
limit 5;

-- Year wise ordered product
SELECT
    p.productName,
     year(o.orderDate) as "Year"
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    p.productName,
	o.orderDate
ORDER BY 2 asc;

SELECT 
distinct YEAR(o.orderDate) AS "Year",
    p.productName,
    round(sum(pt.amount)) as "Total Sales Amt.",
    count(od.quantityOrdered),
    od.priceEach
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    p.productName,
    YEAR(o.orderDate),
	od.quantityOrdered,
    od.priceEach
ORDER BY
    YEAR(o.orderDate) asc;

SELECT DISTINCT YEAR(paymentDate) AS Year,
MIN(amount) AS Min_Amount
FROM payments GROUP BY Year
order by Year asc;

SELECT DISTINCT YEAR(paymentDate) AS Year,
MIN(amount) AS Min_Amount
FROM payments GROUP BY Year
order by Year desc;

-- year wise product orderd n each product total price
SELECT 
	YEAR(o.orderDate) AS "Year",
    p.productName,
	od.productCode,
    od.quantityOrdered,
    od.priceEach,
	SUM(quantityOrdered) * SUM(od.priceEach) AS 'Total Price'
FROM
    products p
    JOIN warehouses w ON p.warehouseCode = w.warehouseCode
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON o.orderNumber = od.orderNumber
    JOIN payments pt ON pt.customerNumber = o.customerNumber
    JOIN customers c ON c.customerNumber = pt.customerNumber
    JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
    JOIN offices f ON f.officeCode = e.officeCode
    JOIN productlines pl ON pl.productLine = p.productLine
GROUP BY
    p.productName,
    YEAR(o.orderDate),
	od.quantityOrdered,
    od.productCode,
    od.priceEach
ORDER BY
    YEAR(o.orderDate) asc;
    
SELECT SUM(amount) AS "Total sales Amt. in 2003"
FROM payments
WHERE year(paymentDate) between "2003–12–31" and "2003–01–01";

SELECT SUM(amount) AS "Total sales Amt. in 2004"
FROM payments
WHERE year(paymentDate) between "2004–12–31" and "2004–01–01";

SELECT SUM(amount) AS "Total sales Amt. in 2005"
FROM payments
WHERE year(paymentDate) between "2005–12–31" and "2005–01–01";

SELECT SUM(amount) AS "Total Sales Amount"
FROM payments
WHERE (YEAR(paymentDate) BETWEEN '2003-01-01' AND '2003-12-31')
   OR (YEAR(paymentDate) BETWEEN '2004-01-01' AND '2004-12-31');
