create database supplychain;
use supplychain;
select * from supplychain;
describe supplychain;
alter table supplychain drop column `Customer Email`, drop column`Customer Password`;
alter table supplychain change column  `order date (DateOrders)`  `Order date` text , change column `shipping date (DateOrders)` `Shipping date` text;
alter table supplychain drop column `Customer Country`, drop column`Order Zipcode`,drop column`Product Image`,drop column`Product Description`;
select `Order Date` from supplychain;
ALTER TABLE supplychain
MODIFY COLUMN `Order date` DATETIME;
select `Order date`,`Shipping date` from supplychain;
ALTER TABLE supplychain
MODIFY COLUMN `Shipping date` DATETIME;
alter table supplychain change column `Sales` `Total Selling Price` int;
SELECT
  `Order date`,
  EXTRACT(YEAR FROM `Order date`) AS year,
  EXTRACT(MONTH FROM `Order date`) AS month,
  MONTHNAME(`Order date`) AS month_name, 
  EXTRACT(DAY FROM `Order date`) AS day,
  EXTRACT(HOUR FROM `Order date`) AS hour,
  EXTRACT(MINUTE FROM `Order date`) AS minute
FROM
  supplychain;
  
  SELECT
  `Shipping date`,
  EXTRACT(YEAR FROM `Shipping date`) AS year,
  EXTRACT(MONTH FROM `Shipping date`) AS month,
  MONTHNAME(`Shipping date`) AS month_name,
  EXTRACT(DAY FROM `Shipping date`) AS day,
  EXTRACT(HOUR FROM `Shipping date`) AS hour,
  EXTRACT(MINUTE FROM `Shipping date`) AS minute
FROM
  supplychain;
  select*from supplychain;
  
ALTER TABLE supplychain ADD COLUMN `Order year` int , ADD COLUMN `Order month` varchar(10) , ADD COLUMN `Order day` int  , ADD COLUMN ` Order Hour` int , ADD COLUMN `ORDER min` int;
  
UPDATE supplychain
SET `Order year` = EXTRACT(YEAR FROM `Order date`),
    `Order month` = MONTHNAME(`Order date`),
    `Order day` = EXTRACT(DAY FROM `Order date`),
    ` Order Hour` = EXTRACT(HOUR FROM `Order date`),
    `Order min` = EXTRACT(MINUTE FROM `Order date`);  

ALTER TABLE supplychain ADD COLUMN `Shipping year` int , ADD COLUMN `Shipping month` varchar(10) , ADD COLUMN `Shipping day` int  , ADD COLUMN `Shipping Hour` int , ADD COLUMN `Shipping min` int;

UPDATE supplychain
SET `Shipping year` = EXTRACT(YEAR FROM `Shipping date`),
    `Shipping month` = MONTHNAME(`Shipping date`),
    `Shipping day` = EXTRACT(DAY FROM `Shipping date`),
    `Shipping Hour` = EXTRACT(HOUR FROM `Shipping date`),
    `Shipping min` = EXTRACT(MINUTE FROM `Shipping date`);
    
select * from supplychain;
select * from supply_chaindata;



----------  KPIs ------------
--------------------  Customer Analysis Measures (2) --------------------------------------------------------



--- Average_Purchase_Value ---
SELECT SUM(scd.`Total Selling price`) / COUNT(sc.`Order Id`) AS Average_Purchase_Value FROM  supply_chaindata as scd JOIN  supplychain  as sc ON scd.`Order Id` = sc.`Order Id`;
 
 
 
---------------------------------------------------------------------------------------------------------

---  Customers_With_More_Than_One_Purchase ---

SELECT COUNT(*) AS Customers_With_More_Than_One_Purchase FROM (SELECT `Order Customer Id`, COUNT(`Order Id`) AS PurchaseCount
FROM Supplychain GROUP BY  `Order Customer Id` HAVING COUNT(`Order Id`) > 1 ) AS SubQuery;


------------------------------------------------------------------------------------

--- AverageDiscountRate ---
SELECT AVG(`Order Item Discount Rate`)*100 AS AverageDiscountRate FROM Supply_chaindata;

-------------------------------------------------------------------------------------

--- GrossMarginPercentage ---
SELECT (subquery.total_selling_price_sum - subquery.cost_price_sum) / NULLIF(subquery.total_selling_price_sum, 0) AS GrossMarginPercentage
FROM (SELECT SUM(scd.`Total Selling Price`) AS total_selling_price_sum, SUM(scd.`Cost Price`) AS cost_price_sum FROM  Supply_chaindata as scd JOIN  supplychain as sc  ON scd.`Order Id` = sc.`Order Id`) AS subquery;
    
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------  Financial Performance Measures ------------------------------------------------------------------------------------------
--- Running_Total_Sales ---    

SET @running_total := 0;
SELECT sc.`Order Date`, @running_total := @running_total + scd.`Total Selling price` 
AS Running_Total_Sales FROM supplychain as sc JOIN supply_chaindata as scd ON 
sc.`Order Id` = scd.`Order Id` ORDER BY sc.`Order Date`;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- category breakdown with respect to profit ---

SELECT sc.`Category Name`, AVG(scd.`Order Item Discount Rate`) AS AvgDiscountRate, SUM(scd.`Profit per order`)
 AS TotalProfit FROM supply_chaindata AS scd JOIN supplychain AS sc ON scd.`Order Id` = sc.`Order Id`
GROUP BY sc.`Category Name` ,scd.`Order Id` ORDER BY TotalProfit;
 
 -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
--- product which incure loss ---

SELECT sc.`Product Name`, SUM(scd.`Profit per order`) AS Total_Loss FROM 
 supply_chaindata scd JOIN supplychain sc ON scd.`Order Id` = sc.`Order Id`
GROUP BY sc.`Product Name` HAVING Total_Loss < 0 ORDER BY Total_Loss ASC;





--- Total Sales ---
 select sum(`Total selling price`) as total_sales from supply_chaindata ;
 -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 
 --- impact of shipping delay on profit ---
 
SELECT CASE WHEN sc.`Days for shipping (real)` > sc.`Days for shipment (scheduled)` THEN 'Late' ELSE 'On Time' END AS ShippingStatus, AVG(scd.`Profit per order`) AS AverageProfit
FROM supplychain sc JOIN  supply_chaindata scd ON sc.`Order Id` = scd.`Order Id` GROUP BY ShippingStatus;

  
  -------------------------------- Order Analysis Measures ---------------------------------------------------------
  
  --- Count of Non Profitable Orders ---
SELECT COUNT(CASE WHEN `Order Item Profit Ratio` < 0 THEN 1 ELSE NULL END)
 AS `Non Profitable Orders` FROM supply_chaindata;


--- Early Order ---
SELECT COUNT(*) AS `Early Order` FROM supplychain WHERE `Days for shipping (real)` < `Days for shipment (scheduled)`;


--- Late Order ---
SELECT COUNT(*) AS `Late Order` FROM supplychain WHERE
`Days for shipping (real)` > `Days for shipment (scheduled)`;

--- On time ---
SELECT COUNT(*) AS `Early Order` FROM supplychain WHERE `Days for shipping (real)` = `Days for shipment (scheduled)`;

---- late delivery percentage ----

SELECT COALESCE(SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END)
* 100.0 / COUNT(`Order Id`), 0)AS `Percentage Late Deliveries` FROM supply_chaindata;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
---- window function ----

--- Top 10 Customers with highest revenue generation ---

WITH CustomerRevenue AS (SELECT sc.`Customer Id`, CONCAT(sc.`Customer Fname`, ' ', sc.`Customer Lname`)
 AS CustomerName, SUM(scd.`Order Item Quantity` * scd.`Product Selling Price`) AS TotalRevenue
FROM supplychain sc JOIN supply_chaindata scd ON sc.`Order Id` = scd.`Order Id` GROUP BY
 sc.`Customer Id`, CustomerName ), RankedCustomers AS ( SELECT CustomerName, TotalRevenue,
DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank FROM CustomerRevenue) SELECT
 CustomerName, TotalRevenue FROM RankedCustomers WHERE RevenueRank <= 10;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Customer with top Purchase----
WITH CustomerTopPurchase AS (SELECT sc.`Customer Fname`, MAX(scd.`Total Selling Price`)
 AS MaxPurchase FROM supplychain sc INNER JOIN supply_chaindata scd ON 
sc.`Order Id` = scd.`Order Id` GROUP BY sc.`Customer Fname`),RankedCustomers AS
 (SELECT `Customer Fname`, MaxPurchase,RANK() OVER (ORDER BY MaxPurchase DESC) AS PurchaseRank
FROM CustomerTopPurchase) SELECT * FROM RankedCustomers ORDER BY PurchaseRank;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- CustomerLeastPurchase----------

WITH CustomerLeastPurchase AS (SELECT sc.`Customer Fname`, MIN(scd.`Total Selling Price`) AS LeastPurchase FROM supplychain sc INNER JOIN supply_chaindata scd ON 
sc.`Order Id` = scd.`Order Id` GROUP BY sc.`Customer Fname`),RankedCustomers AS (SELECT `Customer Fname`, LeastPurchase,row_number() OVER (ORDER BY LeastPurchase ASC) AS PurchaseRank
FROM CustomerLeastPurchase) SELECT * FROM RankedCustomers ORDER BY PurchaseRank;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Top Product ---
SELECT ProductName, TotalRevenue FROM (SELECT sc.`Product Name` AS ProductName, SUM(scd.`Order Item Quantity` * scd.`Product Selling Price`) AS TotalRevenue,
RANK() OVER (ORDER BY SUM(scd.`Order Item Quantity` * scd.`Product Selling Price`) DESC) AS RevenueRank FROM supply_chaindata AS scd 
JOIN supplychain AS sc ON scd.`Order Id` = sc.`Order Id`GROUP BY sc.`Product Name`) AS RankedProducts WHERE RevenueRank = 1;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- top 10 Product ---
SELECT ProductName, TotalRevenue FROM (SELECT sc.`Product Name` AS ProductName, SUM(scd.`Order Item Quantity` * scd.`Product Selling Price`) AS TotalRevenue,
RANK() OVER (ORDER BY SUM(scd.`Order Item Quantity` * scd.`Product Selling Price`) DESC) AS RevenueRank
FROM supply_chaindata AS scd JOIN supplychain AS sc ON scd.`Order Id` = sc.`Order Id`
GROUP BY sc.`Product Name`) AS RankedProducts WHERE RevenueRank <= 10;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Bottom 10 Products ---
SELECT ProductName, TotalRevenue FROM (SELECT sc.`Product Name` AS ProductName, SUM(scd.`Order Item Quantity` * scd.`Product Selling Price`) AS TotalRevenue,
RANK() OVER (ORDER BY SUM(scd.`Order Item Quantity` * scd.`Product Selling Price`) ASC) AS RevenueRank FROM supply_chaindata AS scd 
JOIN supplychain AS sc ON scd.`Order Id` = sc.`Order Id` GROUP BY sc.`Product Name`) AS RankedProducts WHERE RevenueRank <= 10;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- top customer name with respect to total sales ---
SELECT CustomerName, TotalSales FROM (SELECT CONCAT(sc.`Customer Fname`, ' ', sc.`Customer Lname`) AS CustomerName, SUM(scd.`Total Selling Price`) AS TotalSales, 
RANK() OVER (ORDER BY SUM(scd.`Total Selling Price`) DESC) AS SalesRank FROM supplychain AS sc JOIN supply_chaindata AS scd ON sc.`Order Id` = scd.`Order Id` GROUP BY 
sc.`Customer Id`, CustomerName) AS RankedCustomers WHERE SalesRank = 1;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- Top 10 Customer with respect Total sales ---

SELECT CustomerName, TotalSales FROM (SELECT CONCAT(sc.`Customer Fname`, ' ', sc.`Customer Lname`) AS CustomerName, SUM(scd.`Total Selling Price`) AS TotalSales, 
RANK() OVER (ORDER BY SUM(scd.`Total Selling Price`) DESC) AS SalesRank FROM supplychain AS sc JOIN supply_chaindata AS scd ON sc.`Order Id` = scd.`Order Id` GROUP BY 
sc.`Customer Id`, CustomerName) AS RankedCustomers WHERE SalesRank <= 10;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- TOP 10 Customers with Respect to product sales ---


SELECT CustomerName,ProductCount FROM(SELECT CONCAT(sc.`Customer Fname`, ' ', sc.`Customer Lname`) AS CustomerName, COUNT(sc.`Product Name`) AS ProductCount,
RANK() OVER (ORDER BY COUNT(sc.`Product Name`) DESC) AS ProductRank FROM supplychain AS sc JOIN supply_chaindata AS scd ON sc.`Order Id` = scd.`Order Id` 
GROUP BY sc.`Customer Id`, CustomerName) AS RankedCustomers WHERE  ProductRank <= 10;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- top 3 market with respect to profit generation ---

SELECT sc.`Market`, SUM(scd.`Profit per order`) AS TotalProfit 
FROM supplychain AS sc 
JOIN supply_chaindata AS scd ON sc.`Order Id` = scd.`Order Id` 
GROUP BY sc.`Market`
ORDER BY TotalProfit DESC 
LIMIT 3;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- top 10 Countries with Total Sales ---
SELECT sc.`Order Country` AS Country,ABS(SUM(scd.`Total Selling Price`)) AS TotalSales FROM supplychain AS sc JOIN 
supply_chaindata AS scd ON sc.`Order Id` = scd.`Order Id`  GROUP BY 
sc.`Order Country`  ORDER BY  TotalSales DESC LIMIT 10;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- top 10 Countries with Loss ---
SELECT sc.`Order Country` AS Country,ABS(SUM(scd.`Profit per order`)) AS Loss FROM supplychain AS sc JOIN 
supply_chaindata AS scd ON sc.`Order Id` = scd.`Order Id` WHERE scd.`Profit per order` < 0 GROUP BY 
sc.`Order Country` HAVING  SUM(scd.`Profit per order`) < 0 ORDER BY  Loss DESC LIMIT 10;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- top 10 Countries with Profit ---

WITH CountryProfit AS (SELECT sc.`Order Country` AS Country, SUM(scd.`Profit per order`) AS TotalProfit FROM supplychain AS sc JOIN supply_chaindata AS scd ON sc.`Order Id` = scd.`Order Id`
WHERE scd.`Profit per order` > 0 GROUP BY sc.`Order Country` HAVING SUM(scd.`Profit per order`) > 0) SELECT Country, ABS(TotalProfit) AS Profit  FROM CountryProfit
ORDER BY Profit DESC LIMIT 10;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- top 10 Product with highest Profit ratio ---

WITH ProductProfitRatios AS (SELECT sc.`Product Name`,SUM(scd.`Profit per order`) / NULLIF(SUM(scd.`Total Selling Price`), 0) AS ProfitRatio FROM supply_chaindata AS scd JOIN 
supplychain AS sc ON scd.`Order Id` = sc.`Order Id` GROUP BY sc.`Product Name`) SELECT  `Product Name`, ProfitRatio FROM ProductProfitRatios ORDER BY ProfitRatio DESC LIMIT 10;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- top 5 Category Name ---

WITH CategorySales AS ( SELECT sc.`Category Name`, SUM(scd.`Order Item Quantity` * scd.`Product Selling Price`) AS TotalSales FROM supplychain AS sc JOIN supply_chaindata AS scd ON sc.`Order Id` = scd.`Order Id`
GROUP BY sc.`Category Name`) SELECT `Category Name`, TotalSales FROM CategorySales ORDER BY TotalSales DESC LIMIT 5;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---  rank of shipping mode by  Profit---

WITH ShippingModeProfit AS (SELECT sc.`Shipping Mode`, SUM(scd.`Profit per order`) AS TotalProfit, RANK() OVER (ORDER BY SUM(scd.`Profit per order`) DESC) AS ProfitRank FROM
supplychain AS sc JOIN supply_chaindata AS scd ON sc.`Order Id` = scd.`Order Id` GROUP BY sc.`Shipping Mode`) SELECT `Shipping Mode`, TotalProfit, ProfitRank FROM ShippingModeProfit
ORDER BY ProfitRank ;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Order Status BreakDown by Total sales ---

SELECT DISTINCT`Order Status`,SUM(`Total Selling Price`) OVER(PARTITION BY `Order Status`) AS TotalSales FROM (SELECT sc.`Order Status`, scd.`Total Selling Price` FROM
supplychain sc JOIN supply_chaindata scd ON sc.`Order Id` = scd.`Order Id`) AS JoinedData;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------ year over year % change ----------------------------------------

--- Month on Month % Change By LAG ---

SELECT SalesMonth, TotalSales AS current_month_sales, LAG(TotalSales) OVER (ORDER BY SalesMonth) AS previous_month_sales, TotalSales - LAG(TotalSales) OVER (ORDER BY SalesMonth) AS Diff,
COALESCE(((TotalSales - LAG(TotalSales) OVER (ORDER BY SalesMonth)) / NULLIF(LAG(TotalSales) OVER (ORDER BY SalesMonth), 0)) * 100, 0) AS PercentageChange FROM (SELECT 
DATE_FORMAT(sc.`Order Date`, '%Y-%m') AS SalesMonth, SUM(scd.`Total Selling Price`) AS TotalSales FROM supplychain sc JOIN supply_chaindata scd ON sc.`Order Id` = scd.`Order Id` 
GROUP BY SalesMonth) AS MonthlySales ORDER BY SalesMonth;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Month on Month % Change By LEAD ---
SELECT SalesMonth, TotalSales AS current_month_sales, LEAD(TotalSales) OVER (ORDER BY SalesMonth) AS previous_month_sales, TotalSales - LEAD(TotalSales) OVER (ORDER BY SalesMonth) AS Diff,
COALESCE(((TotalSales - LEAD(TotalSales) OVER (ORDER BY SalesMonth)) / NULLIF(LEAD(TotalSales) OVER (ORDER BY SalesMonth), 0)) * 100, 0) AS PercentageChange FROM (SELECT 
DATE_FORMAT(sc.`Order Date`, '%Y-%m') AS SalesMonth, SUM(scd.`Total Selling Price`) AS TotalSales FROM supplychain sc JOIN supply_chaindata scd ON sc.`Order Id` = scd.`Order Id` 
GROUP BY SalesMonth) AS MonthlySales ORDER BY SalesMonth;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Quarter on Quarter % Change By LAG ---
SELECT CONCAT(Year, '-', Quarter) AS YearQuarter, TotalSales AS current_quarter_sales, LAG(TotalSales) OVER (ORDER BY Year, Quarter) AS previous_quarter_sales, 
TotalSales - LAG(TotalSales) OVER (ORDER BY Year, Quarter) AS Diff,COALESCE(((TotalSales - LAG(TotalSales) OVER (ORDER BY Year, Quarter)) / NULLIF(LAG(TotalSales)
OVER (ORDER BY Year, Quarter), 0)) * 100, 0) AS PercentageChange FROM (SELECT YEAR(sc.`Order Date`) AS Year, QUARTER(sc.`Order Date`) AS Quarter, 
SUM(scd.`Total Selling Price`) AS TotalSales FROM supplychain sc JOIN supply_chaindata scd ON sc.`Order Id` = scd.`Order Id` GROUP BY 
Year, Quarter) AS QuarterlySales ORDER BY YearQuarter;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Quarter on Quarter % Change By LEAD ---

SELECT CONCAT(Year, '-', Quarter) AS YearQuarter, TotalSales AS current_quarter_sales, LEAD(TotalSales) OVER (ORDER BY Year, Quarter) AS previous_quarter_sales, 
TotalSales - LEAD(TotalSales) OVER (ORDER BY Year, Quarter) AS Diff,COALESCE(((TotalSales - LEAD(TotalSales) OVER (ORDER BY Year, Quarter)) / NULLIF(LEAD(TotalSales)
OVER (ORDER BY Year, Quarter), 0)) * 100, 0) AS PercentageChange FROM (SELECT YEAR(sc.`Order Date`) AS Year, QUARTER(sc.`Order Date`) AS Quarter, 
SUM(scd.`Total Selling Price`) AS TotalSales FROM supplychain sc JOIN supply_chaindata scd ON sc.`Order Id` = scd.`Order Id` GROUP BY 
Year, Quarter) AS QuarterlySales ORDER BY YearQuarter;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Year on Year % Change By LAG ---

SELECT SaleYear, TotalSales AS current_year_sales, COALESCE(LAG(TotalSales) OVER (ORDER BY SaleYear), 0) AS previous_year_sales, 
COALESCE(TotalSales - LAG(TotalSales) OVER (ORDER BY SaleYear), 0) AS Diff, 
COALESCE(((TotalSales - LAG(TotalSales) OVER (ORDER BY SaleYear)) / LAG(TotalSales) OVER (ORDER BY SaleYear)) * 100, 0) AS PercentageChange
FROM (SELECT YEAR(sc.`Order Date`) AS SaleYear, SUM(scd.`Total Selling Price`) AS TotalSales FROM supplychain sc JOIN supply_chaindata scd ON sc.`Order Id` = scd.`Order Id`
GROUP BY SaleYear) AS YearlySales ORDER BY SaleYear;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Year on Year % Change By LEAD ---
SELECT SaleYear, TotalSales AS current_year_sales, COALESCE(LEAD(TotalSales) OVER (ORDER BY SaleYear), 0) AS previous_year_sales, 
COALESCE(TotalSales - LEAD(TotalSales) OVER (ORDER BY SaleYear), 0) AS Diff, 
COALESCE(((TotalSales - LEAD(TotalSales) OVER (ORDER BY SaleYear)) / LEAD(TotalSales) OVER (ORDER BY SaleYear)) * 100, 0) AS PercentageChange
FROM (SELECT YEAR(sc.`Order Date`) AS SaleYear, SUM(scd.`Total Selling Price`) AS TotalSales FROM supplychain sc JOIN supply_chaindata scd ON sc.`Order Id` = scd.`Order Id`
GROUP BY SaleYear) AS YearlySales ORDER BY SaleYear;








