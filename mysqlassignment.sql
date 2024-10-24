/* 1.a)	Fetch the employee number, first name and last name of those employees who are working as Sales Rep 
reporting to employee with employeenumber 1102. */

USE classicmodels;

SELECT employeeNumber, firstName, lastName
FROM employees
WHERE jobTitle = 'Sales Rep'
AND reportsTo = 1102;


-- 1.b) Show the unique productline values containing the word cars at the end from the products table. ----

SELECT DISTINCT productLine
FROM products
WHERE productLine LIKE '%Cars';


/* 2) Using a CASE statement, segment customers into three categories based on their country:
                        "North America" for customers from USA or Canada
                        "Europe" for customers from UK, France, or Germany
                        "Other" for all remaining countries
   Select the customerNumber, customerName, and the assigned region as "CustomerSegment". */
   
SELECT 
    customerNumber,
    customerName,
CASE 
	WHEN country IN ('USA', 'Canada') THEN 'North America'
	WHEN country IN ('UK', 'France', 'Germany') THEN 'Europe'
	ELSE 'Other'
END AS CustomerSegment
FROM 
    customers
WHERE 
    customerNumber BETWEEN 103 AND 146
ORDER BY 
    customerNumber;
    
    
/* 3.a)	Using the OrderDetails table, identify the top 10 products (by productCode) with the highest total 
order quantity across all orders. */

SELECT productCode, 
       SUM(quantityOrdered) AS total_ordered
FROM orderdetails
GROUP BY productCode
ORDER BY total_ordered DESC
LIMIT 10;


/* 3.b) Company wants to analyse payment frequency by month. Extract the month name from the payment date to
count the total number of payments for each month and include only those months with a payment count 
exceeding 20. Sort the results by total number of payments in descending order. */ 

SELECT MONTHNAME(paymentDate) AS payment_month, 
       COUNT(*) AS num_payments
FROM payments
GROUP BY MONTHNAME(paymentDate)
HAVING COUNT(*) > 20
ORDER BY COUNT(*) DESC;


-- 4. ------------------------------------------------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS Customers_Orders;
USE Customers_Orders;

-- 4.a) ----------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20)
);

-- 4.b) ----------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    CHECK (total_amount > 0)
);


-- 5. List the top 5 countries (by order count) that Classic Models ships to. ------------------------------

USE classicmodels;

SELECT 
    c.country, 
    COUNT(o.orderNumber) AS order_count
FROM customers c
INNER JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.country
ORDER BY order_count DESC
LIMIT 5;


-- 6. ------------------------------------------------------------------------------------------------------

USE classicmodels;

DROP TABLE IF EXISTS project;

CREATE TABLE project (
    EmployeeID INT PRIMARY KEY AUTO_INCREMENT,
    FullName VARCHAR(50) NOT NULL,
    Gender ENUM('Male', 'Female') NOT NULL,
    ManagerID INT
);

INSERT INTO project (FullName, Gender, ManagerID)
VALUES ('Pranaya', 'Male', 3),
       ('Priyanka', 'Female', 1),
       ('Preety', 'Female', NULL),
       ('Anurag', 'Male', 1),
       ('Sambit', 'Male', 1),
       ('Rajesh', 'Male', 3),
       ('Hina', 'Female', 3);

SELECT 
    m.FullName AS 'Manager Name',
    e.FullName AS 'Emp Name'
FROM project e
JOIN project m ON e.ManagerID = m.EmployeeID
ORDER BY m.FullName;


-- 7. ------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS facility;
CREATE TABLE facility (
    Field VARCHAR(100),
    Type VARCHAR(100),
    `Null` VARCHAR(3),
    `Key` VARCHAR(3),
    `Default` VARCHAR(100),
    Extra VARCHAR(100)
);

INSERT INTO facility (Field, Type, `Null`, `Key`, `Default`, Extra) VALUES
('Facility ID', 'int', 'NO', 'PRI', NULL, 'auto increment'),
('Name', 'varchar(100)', 'YES', '', NULL, ''),
('City', 'varchar(100)', 'NO', '', NULL, ''),
('State', 'varchar(100)', 'YES', '', NULL, ''),
('Country', 'varchar(100)', 'YES', '', NULL, '');

SELECT * FROM facility;


-- 8. ------------------------------------------------------------------------------------------------------

USE classicmodels;

DROP VIEW IF EXISTS product_category_sales;
CREATE VIEW product_category_sales AS
SELECT 
    pl.productLine as productLine,
    ROUND(SUM(od.quantityOrdered * od.priceEach), 2) as total_sales,
    COUNT(DISTINCT o.orderNumber) as number_of_orders
FROM
    productLines pl
    LEFT JOIN products p ON pl.productLine = p.productLine
    LEFT JOIN orderdetails od ON p.productCode = od.productCode
    LEFT JOIN orders o ON od.orderNumber = o.orderNumber
GROUP BY 
    pl.productLine
ORDER BY 
    pl.productLine;
    
SELECT * FROM product_category_sales;


-- 9. ------------------------------------------------------------------------------------------------------

DELIMITER //
DROP PROCEDURE IF EXISTS Get_country_payments//
CREATE PROCEDURE Get_country_payments(IN in_year INT, IN in_country VARCHAR(50))
BEGIN
    SELECT 
        YEAR(paymentDate) as Year,
        country,
        CONCAT(FORMAT(SUM(amount)/1000, 0), 'K') as 'Total Amount'
    FROM 
        customers c
        JOIN payments p ON c.customerNumber = p.customerNumber
    WHERE 
        YEAR(paymentDate) = in_year 
        AND country = in_country
    GROUP BY 
        YEAR(paymentDate), 
        country;
END//
DELIMITER ;

CALL Get_country_payments(2003, 'France');


-- 10.a) ---------------------------------------------------------------------------------------------------

SELECT 
    customerName,
    COUNT(orderNumber) as Order_count,
    DENSE_RANK() OVER (ORDER BY COUNT(orderNumber) DESC) as order_frequency_rnk
FROM 
    customers c
    JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY 
    customerName
ORDER BY 
    Order_count DESC;


-- 10.b) ---------------------------------------------------------------------------------------------------

WITH OrderCounts AS (
  SELECT 
    YEAR(orderDate) as Year,
    MONTHNAME(orderDate) as Month,
    COUNT(*) as Total_Orders,
    MONTH(orderDate) as Month_Num
  FROM classicmodels.orders
  GROUP BY YEAR(orderDate), MONTH(orderDate), MONTHNAME(orderDate)
),
YoY_Change AS (
  SELECT 
    o1.Year,
    o1.Month,
    o1.Total_Orders,
    o1.Month_Num,
    CASE 
      WHEN o1.Month_Num = 1 AND o2.Month_Num = 12 THEN 
        ROUND(((o1.Total_Orders - o2.Total_Orders) / o2.Total_Orders * 100), 0)
      ELSE 
        ROUND(((o1.Total_Orders - LAG(o1.Total_Orders) OVER (ORDER BY o1.Year, o1.Month_Num)) / 
        LAG(o1.Total_Orders) OVER (ORDER BY o1.Year, o1.Month_Num) * 100), 0)
    END as YoY_Change
  FROM OrderCounts o1
  LEFT JOIN OrderCounts o2 
    ON o1.Year = o2.Year + 1 
    AND o1.Month_Num = 1 
    AND o2.Month_Num = 12
)
SELECT 
  Year,
  Month,
  Total_Orders,
  CASE 
    WHEN YoY_Change IS NULL THEN 'NULL'
    ELSE CONCAT(YoY_Change, '%')
  END as '% YoY Change'
FROM YoY_Change
ORDER BY Year, Field(Month, 
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December');


-- 11. -----------------------------------------------------------------------------------------------------

WITH AvgBuyPrice AS (
    SELECT AVG(buyPrice) as avg_price
    FROM products
)
SELECT 
    p.productLine,
    COUNT(*) as Total
FROM products p
CROSS JOIN AvgBuyPrice avg
WHERE p.buyPrice > avg.avg_price
GROUP BY p.productLine
ORDER BY Total DESC;


-- 12. -----------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS Error_EH (
    EmpID INT PRIMARY KEY,
    EmpName VARCHAR(100),
    EmpAddress VARCHAR(255)
);

DELIMITER //

DROP PROCEDURE IF EXISTS InsertEmployee //

CREATE PROCEDURE InsertEmployee(
    IN p_EmpID INT,
    IN p_EmpName VARCHAR(100),
    IN p_EmpAddress VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error occurred' as ErrorMessage;
    END;

    START TRANSACTION;
        INSERT INTO Error_EH (EmpID, EmpName, EmpAddress)
        VALUES (p_EmpID, p_EmpName, p_EmpAddress);
    COMMIT;
END //

DELIMITER ;

-- checking if it's handling the error properly or not using different scenarios
-- Test cases
CALL InsertEmployee(1, 'John Doe', '123 Street');
SELECT * FROM Error_EH;
CALL InsertEmployee(1, 'Jane Doe', '456 Avenue');  -- Should show error (duplicate key)
CALL InsertEmployee(NULL, 'Bob Smith', '789 Road');  -- Should show error (NULL primary key)


-- 13. -----------------------------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS before_emp_insert;
DROP TABLE IF EXISTS Emp_BIT;

CREATE TABLE IF NOT EXISTS Emp_BIT (
    Name VARCHAR(100) PRIMARY KEY,  
    Occupation VARCHAR(100),
    Working_date DATE,
    Working_hours INT
);

-- Creating the trigger to handle negative working hours
DELIMITER //

CREATE TRIGGER before_emp_insert
BEFORE INSERT ON Emp_BIT
FOR EACH ROW 
BEGIN
    IF NEW.Working_hours < 0 THEN
        SET NEW.Working_hours = ABS(NEW.Working_hours);
    END IF;
END //

DELIMITER ;

-- Inserting the initial data
INSERT INTO Emp_BIT VALUES
    ('Robin', 'Scientist', '2020-10-04', 12),
    ('Warner', 'Engineer', '2020-10-04', 10),
    ('Peter', 'Actor', '2020-10-04', 13),
    ('Marco', 'Doctor', '2020-10-04', 14),
    ('Brayden', 'Teacher', '2020-10-04', 12),
    ('Antonio', 'Business', '2020-10-04', 11);

-- To test the trigger with negative value (this will fail if John already exists)
-- If you need to test again, you'll need to delete John first
INSERT INTO Emp_BIT VALUES ('John', 'Developer', '2020-10-04', -5);

SELECT * FROM Emp_BIT ORDER BY Name;

DELETE FROM Emp_BIT WHERE Name = 'John';