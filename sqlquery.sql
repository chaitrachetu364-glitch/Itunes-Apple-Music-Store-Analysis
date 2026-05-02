# Find Duplicate Records in customer table
show databases;
use itunes_music;
SELECT email, COUNT(*)
FROM customer
GROUP BY email
HAVING COUNT(*) > 1;

#Track table
SELECT name, album_id, COUNT(*)
FROM track

GROUP BY name, album_id
HAVING COUNT(*) > 1;

# remove duplicate of album_id 25
DELETE t269
FROM track t269
JOIN track t270
  ON t269.Name = t270.Name
  AND t269.album_id = t270.album_id
  AND t269.track_id > t270.track_id;
 
 #check for null values
 SELECT *
FROM customer
WHERE email IS NULL
   OR first_Name IS NULL;
   
   SELECT *
FROM invoice
WHERE customer_id IS NULL
   OR total IS NULL;
   
SELECT *
FROM track
WHERE name IS NULL
   OR unit_price IS NULL;
   
 #Invoice_line without invoice
SELECT *
FROM invoice_line il
LEFT JOIN invoice i ON il.invoice_id = i.invoice_id
WHERE i.invoice_id IS NULL;

#Realistic Business Questions
#1. Customer Analytics
# ●	Which customers have spent the most money on music?
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(i.total) AS total_spent
FROM customer c
JOIN invoice i 
    ON c.customer_id = i.customer_id
GROUP BY 
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC;

#●	What is the average customer lifetime value?
SELECT 
    AVG(customer_total) AS Avg_Customer_Lifetime_Value
FROM (
    SELECT 
        c.customer_id,
        SUM(i.total) AS customer_total
    FROM customer c
    JOIN invoice i 
        ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
) AS customer_spending;

# ●	How many customers have made repeat purchases versus one-time purchases?
SELECT 
    customer_id,
    COUNT(invoice_id) AS Purchase_Count
FROM invoice
GROUP BY customer_id;

SELECT 
    CASE 
        WHEN Purchase_Count = 1 THEN 'One-Time Purchase'
        ELSE 'Repeat Purchase'
    END AS Customer_Type,
    COUNT(*) AS Number_of_Customers
FROM (
    SELECT 
        customer_id,
        COUNT(invoice_id) AS Purchase_Count
    FROM invoice
    GROUP BY customer_id
) AS Customer_Purchases
GROUP BY Customer_Type;

#●	Which country generates the most revenue per customer?
SELECT 
    c.country,
    SUM(i.total) / COUNT(DISTINCT c.customer_id) AS Revenue_Per_Customer
FROM customer c
JOIN invoice i
    ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY Revenue_Per_Customer DESC
LIMIT 1;

#●Which customers haven't made a purchase in the last 6 months?
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    MAX(i.invoice_date) AS Last_Purchase_Date
FROM customer c
LEFT JOIN invoice i
    ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING MAX(i.invoice_date) < DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    OR MAX(i.Invoice_date) IS NULL;
    
   # 2. Sales & Revenue Analysis
 #  ●	What are the monthly revenue trends for the last two years?
 SELECT 
    DATE_FORMAT(invoice_date, '%Y-%m') AS YearMonth,
    SUM(total) AS Monthly_Revenue
FROM invoice
WHERE invoice_date >=(SELECT DATE_SUB(MAX(invoice_date), INTERVAL 2 YEAR)
FROM Invoice)
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
ORDER BY DATE_FORMAT(invoice_date, '%Y-%m');

# ●	What is the average value of an invoice (purchase)?
   SELECT 
    COUNT(invoice_id) AS Total_Invoices,
    SUM(total) AS Total_Revenue,
    ROUND(AVG(total), 2) AS Average_Invoice_Value
FROM invoice;

# ●	Which billing country are used most frequently?
SELECT 
    billing_country,
    COUNT(*) AS Number_of_Purchases
FROM invoice
GROUP BY billing_country
ORDER BY Number_of_Purchases DESC;

#●	How much revenue does each sales representative contribute?
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS Sales_Representative,
    ROUND(SUM(i.total), 2) AS Total_Revenue
FROM employee e
JOIN customer c 
    ON e.employee_id = c.support_rep_id
JOIN invoice i
    ON c.customer_id = i.customer_id
GROUP BY e.employee_id, Sales_Representative
ORDER BY Total_Revenue;
   
 #  ●	Which months or quarters have peak music sales?
 SELECT 
    DATE_FORMAT(invoice_date, '%Y-%m') AS YearMonth,
    ROUND(SUM(Total), 2) AS Monthly_Revenue
FROM invoice
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
ORDER BY Monthly_Revenue DESC;

# 3. Product & Content Analysis
#●	Which tracks generated the most revenue?
SELECT 
    t.track_id,
    t.name AS track_name,
    ROUND(SUM(il.unit_price * il.quantity), 2) AS Total_Revenue
FROM invoice_line il
JOIN track t 
    ON il.track_id = t.track_id
GROUP BY t.track_id, t.name
ORDER BY Total_Revenue DESC;


#●	Are there any tracks or albums that have never been purchased?
SELECT 
    t.track_id,
    t.name AS Track_Name
FROM track t
LEFT JOIN invoice_line il
    ON t.track_id = il.track_id
WHERE il.track_id IS NULL;

#●	What is the average price per track across different genres?
SELECT 
    g.name AS Genre,
    ROUND(AVG(t.unit_price), 2) AS Avg_Track_Price
FROM track t
JOIN genre g 
    ON t.genre_id = g.genre_id
GROUP BY g.name
ORDER BY Avg_Track_Price DESC;

#●	How many tracks does the store have per genre and how does it correlate with sales?
SELECT 
    g.name AS genre,
    COUNT(DISTINCT t.track_id) AS Total_Tracks,
    ROUND(SUM(il.unit_price * il.quantity), 2) AS Total_Revenue
FROM genre g
LEFT JOIN track t 
    ON g.genre_id = t.genre_id
LEFT JOIN invoice_line il 
    ON t.track_id = il.track_id
GROUP BY g.name
ORDER BY Total_Revenue DESC;

#4. Artist & Genre Performance
#●	Which music genres are most popular in terms of:*Number of tracks sold *Total revenue
SELECT 
    g.name AS genre,
    SUM(il.quantity) AS Total_Tracks_Sold
FROM genre g
JOIN track t 
    ON g.genre_id = t.genre_id
JOIN invoice_line il 
    ON t.track_id = il.track_id
GROUP BY g.name
ORDER BY Total_Tracks_Sold DESC;

SELECT 
    g.name AS genre,
    ROUND(SUM(il.unit_price * il.quantity), 2) AS Total_Revenue
FROM genre g
JOIN track t 
    ON g.genre_id = t.genre_id
JOIN invoice_line il 
    ON t.track_id = il.track_id
GROUP BY g.name
ORDER BY Total_Revenue DESC;

# ●	Are certain genres more popular in specific countries?
SELECT 
    i.billing_country,
    g.name AS genre,
    SUM(il.quantity) AS Total_Tracks_Sold
FROM invoice i
JOIN invoice_line il 
    ON i.invoice_id = il.invoice_id
JOIN track t 
    ON il.track_id = t.track_id
JOIN genre g 
    ON t.genre_id = g.genre_id
GROUP BY i.billing_country, g.name
ORDER BY i.billing_country, Total_Tracks_Sold DESC;

#5. Employee & Operational Efficiency
#●	Which employees (support representatives) are managing the highest-spending customers?
SELECT 
    customer_id,
    ROUND(SUM(total), 2) AS Customer_Total_Spending
FROM invoice
GROUP BY customer_id;

SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS Support_Rep,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS Customer_Name,
    ROUND(SUM(i.total), 2) AS Customer_Total_Spending
FROM employee e
JOIN customer c 
    ON e.employee_id = c.support_rep_id
JOIN invoice i 
    ON c.customer_id = i.customer_id
GROUP BY e.employee_id, Support_Rep, c.customer_id, Customer_Name
ORDER BY Customer_Total_Spending DESC;

# ●	What is the average number of customers per employee?
SELECT 
    ROUND(COUNT(*) * 1.0 / 
          (SELECT COUNT(*) FROM employee), 2) 
    AS Avg_Customers_Per_Employee
FROM customer;

#●	Which employee regions bring in the most revenue?
SELECT 
    e.country AS Employee_Country,
    ROUND(SUM(i.total), 2) AS Total_Revenue
FROM employee e
JOIN customer c 
    ON e.employee_id = c.support_rep_id
JOIN invoice i 
    ON c.customer_id = i.customer_id
GROUP BY e.country
ORDER BY Total_Revenue DESC;

#6. Geographic Trends
#●	Which countries or cities have the highest number of customers?
SELECT 
    country,
    COUNT(customer_id) AS Total_Customers
FROM customer
GROUP BY country
ORDER BY Total_Customers DESC;

#●	How does revenue vary by region?
SELECT 
    billing_country AS Country,
    ROUND(SUM(total), 2) AS Total_Revenue
FROM invoice
GROUP BY billing_country
ORDER BY Total_Revenue DESC;

#●	Are there any underserved geographic regions (high users, low sales)?
SELECT 
    billing_country,
    COUNT(DISTINCT customer_id) AS Total_Customers,
    ROUND(SUM(total), 2) AS Total_Revenue,
    ROUND(SUM(total) / COUNT(DISTINCT customer_id), 2) AS Revenue_Per_Customer
FROM invoice
GROUP BY billing_country
ORDER BY Total_Customers DESC;

#7. Customer Retention & Purchase Patterns
#●	What is the distribution of purchase frequency per customer?
SELECT 
    customer_id,
    COUNT(invoice_id) AS Purchase_Count
FROM invoice
GROUP BY customer_id
ORDER BY Purchase_Count DESC;

#● How long is the average time between customer purchases?
SELECT 
    ROUND(AVG(DATEDIFF(next_purchase, invoice_date)), 2) 
    AS Avg_Days_Between_Purchases
FROM (
    SELECT 
        customer_id,
        invoice_date,
        LEAD(invoice_date) OVER (
            PARTITION BY customer_id 
            ORDER BY invoice_date
        ) AS next_purchase
    FROM invoice
) t
WHERE next_purchase IS NOT NULL;

#●	What percentage of customers purchase tracks from more than one genre?
SELECT 
    c.customer_id,
    COUNT(DISTINCT g.genre_id) AS Genre_Count
FROM customer c
JOIN invoice i 
    ON c.customer_id = i.customer_id
JOIN invoice_line il 
    ON i.invoice_id = il.invoice_id
JOIN track t 
    ON il.track_id = t.track_id
JOIN genre g 
    ON t.genre_id = g.genre_id
GROUP BY c.customer_id;

# 8. Operational Optimization
#●	What are the most common combinations of tracks purchased together?
SELECT 
    t1.name AS Track_1,
    t2.name AS Track_2,
    COUNT(*) AS Times_Purchased_Together
FROM invoice_line il1
JOIN invoice_line il2 
    ON il1.invoice_id = il2.invoice_id
    AND il1.track_id < il2.track_id   -- avoid duplicates & self-join
JOIN track t1 
    ON il1.track_id = t1.track_id
JOIN track t2 
    ON il2.track_id = t2.track_id
GROUP BY t1.name, t2.name
ORDER BY Times_Purchased_Together DESC
LIMIT 10;

#●	Are there pricing patterns that lead to higher or lower sales?
SELECT 
    t.unit_price,
    SUM(il.quantity) AS Total_Units_Sold,
    ROUND(SUM(il.unit_price * il.quantity), 2) AS Total_Revenue
FROM track t
JOIN invoice_line il 
    ON t.track_id = il.track_id
GROUP BY t.unit_price
ORDER BY t.unit_price;

#●	Which media types (e.g., MPEG, AAC) are declining or increasing in usage?
SELECT 
    YEAR(i.invoice_date) AS Year,
    m.name AS Media_Type,
    SUM(il.quantity) AS Total_Units_Sold
FROM invoice i
JOIN invoice_line il 
    ON i.invoice_id = il.invoice_id
JOIN track t 
    ON il.track_id = t.track_id
JOIN media_type m 
    ON t.media_type_id = m.media_type_id
GROUP BY Year, m.name
ORDER BY Year, Total_Units_Sold DESC;


