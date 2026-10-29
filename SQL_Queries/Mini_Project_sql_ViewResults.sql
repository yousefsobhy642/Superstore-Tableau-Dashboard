
 
-- Preview original source table
SELECT * FROM [dbo].[Central_Superstore]
 
-- Test Normalization
SELECT COUNT(*) AS 'Origin' FROM [dbo].[Central_Superstore] 
SELECT COUNT(*) AS'Custumers' FROM [dbo].[Dim_Customer]
SELECT COUNT(*) AS 'Dates' FROM [dbo].[Dim_Date]
SELECT COUNT(*) AS 'Location'FROM [dbo].[Dim_Location]
SELECT COUNT(*) AS 'Products' FROM [dbo].[Dim_Product]
SELECT COUNT(*) AS 'Ship Modes'FROM [dbo].[Dim_ShipMode]
SELECT COUNT(*) AS 'Sales'FROM [dbo].[Fact_Sales]
 
 
---1:-
-- Query 1: Total sales by category
SELECT DP.Category,SUM(FS.Sales) AS Total_Sales
FROM [dbo].[Dim_Product]  DP
JOIN [dbo].[Fact_Sales] FS
ON
DP.Product_ID=FS.Product_ID
GROUP BY DP.Category
ORDER BY Total_Sales DESC
 
 
 
---2:-
-- Query 2: Total sales by category and sub-category
SELECT DP.Category,DP.Sub_Category,SUM(FS.Sales) AS Total_Sales
FROM [dbo].[Dim_Product]  DP
JOIN [dbo].[Fact_Sales] FS
ON
DP.Product_ID=FS.Product_ID
GROUP BY DP.Category,DP.Sub_Category
ORDER BY Total_Sales DESC
 
---3:-
-- Query 3: Total sales by customer segment and region
SELECT DC.Segment,DL.Region,SUM(FS.Sales) AS Total_Sales
FROM [dbo].[Dim_Customer]DC
JOIN [dbo].[Fact_Sales] FS
ON
DC.Customer_ID=FS.Customer_ID
JOIN [dbo].[Dim_Location] DL
ON DL.Location_ID=FS.Location_ID
GROUP BY DC.Segment,DL.Region
ORDER BY Total_Sales DESC
 
---4:-
-- Query 4: Total sales by year and quarter
SELECT DD.Year,DD.Quarter,SUM(FS.Sales) AS Total_Sales
FROM [dbo].[Dim_Date] DD
JOIN [dbo].[Fact_Sales] FS
ON DD.Date_ID=FS.Order_Date_ID
GROUP BY DD.Year,DD.Quarter
 
 
---5:-
-- Query 5: Customers whose total sales are above the average customer sales
SELECT DC.Customer_Name,SUM(FS.Sales) AS 'Total Sales'
FROM [dbo].[Dim_Customer] DC JOIN 
[dbo].[Fact_Sales] FS
ON DC.Customer_ID=FS.Customer_ID
GROUP BY DC.Customer_Name
HAVING SUM(FS.Sales)>
(
SELECT AVG(custumers_sales.total_custumers_sales) FROM
(SELECT SUM(Sales)  as total_custumers_sales
FROM
[dbo].[Fact_Sales] 
GROUP BY Customer_ID)as custumers_sales
 
) 
 
 
---6:-
-- Query 6: Total sales by year and month
SELECT DD.Year,DD.Month_Name,SUM(FS.Sales) AS Total_Sales
FROM [dbo].[Dim_Date] DD
JOIN [dbo].[Fact_Sales] FS
ON DD.Date_ID=FS.Order_Date_ID
GROUP BY DD.Year,DD.Month_Name
 
---7:-
-- Query 7: Total sales by product, sorted descending
SELECT DP.Product_Name,SUM(FS.Sales) AS Total_Sales
FROM [dbo].[Dim_Product] DP
JOIN [dbo].[Fact_Sales] FS
ON DP.Product_ID=FS.Product_ID
GROUP BY DP.Product_Name
ORDER BY SUM(FS.Sales) DESC
 
---8:-
-- Query 8: Profit margin per sale with CASE classification
SELECT Sales_ID,Sales,Profit
,(Profit/Sales) as Profit_Margin,
CASE 
WHEN 
Sales=0 THEN 'N/A'
WHEN (Profit/Sales)<0 THEN 'Loss'
WHEN (Profit/Sales)<.1 THEN 'Low'
WHEN (Profit/Sales)<.25 THEN 'Medium'
ELSE 'High'
END AS 'Profit Margin Category'
FROM [dbo].[Fact_Sales]
 
---9:-
-- Query 9: Categories with a negative overall profit margin
SELECT DP.Category,SUM(FS.Profit)/SUM(FS.Sales) as 'total'
FROM [dbo].[Dim_Product]DP
JOIN [dbo].[Fact_Sales]FS
ON DP.Product_ID=FS.Product_ID
GROUP BY DP.Category
HAVING SUM(FS.Profit)/SUM(FS.Sales)<0
 
 
---10:-
-- Query 10: Top 10 customers by total sales
SELECT TOP 10
DC.Customer_Name,SUM(FS.Sales) AS 'Total Sales'
FROM [dbo].[Dim_Customer] DC JOIN 
[dbo].[Fact_Sales] FS
ON DC.Customer_ID=FS.Customer_ID
GROUP BY DC.Customer_Name
ORDER BY SUM(FS.Sales) DESC
 
---11:-
-- Query 11: Full denormalized sales report (all dimensions joined)
SELECT 
FS.Order_ID,FS.Row_ID,DC.Customer_Name,DC.Segment,
DP.Product_Name,DP.Category,DP.Sub_Category,
DL.Region,DL.City,DL.State,DSM.Ship_Mode,
DDO.Full_Date AS Order_Date,DDS.Full_Date AS Ship_Date,
FS.Sales,FS.Quantity,FS.Discount,FS.Profit
FROM [dbo].[Fact_Sales] FS
JOIN [dbo].[Dim_ShipMode] DSM
ON FS.Ship_Mode_ID=DSM.Ship_Mode_ID
JOIN  [dbo].[Dim_Product] DP
ON FS.Product_ID=DP.Product_ID
JOIN [dbo].[Dim_Location] DL
ON FS.Location_ID=DL.Location_ID
JOIN [dbo].[Dim_Date] DDO
ON FS.Order_Date_ID=DDO.Date_ID
JOIN [dbo].[Dim_Date] DDS
ON FS.Ship_Date_ID=DDS.Date_ID
JOIN [dbo].[Dim_Customer] DC
ON FS.Customer_ID=DC.Customer_ID
 
 
---12:-
-- Query 12: Average profit and order count by discount category
SELECT 
CASE WHEN Discount=0 THEN 'Without Discount'
WHEN Discount<.25 THEN 'Low'
WHEN Discount<.5 THEN 'Medium'
WHEN DiscounT<.75 THEN 'High'
ELSE 'Very High' END AS Discount_category,
AVG(Profit) AS 'Avarege Profit',
COUNT(*) AS 'Number of orders'
FROM [dbo].[Fact_Sales]
GROUP BY CASE WHEN Discount=0 THEN 'Without Discount'
WHEN Discount<.25 THEN 'Low'
WHEN Discount<.5 THEN 'Medium'
WHEN DiscounT<.75 THEN 'High'
ELSE 'Very High' END 
 
---OR---
-- Query 12 (alternative version): same, broken down by year and month
SELECT dd.Year,dd.Month_Name,
CASE WHEN fs.Discount=0 THEN 'Without Discount'
WHEN fs.Discount<.25 THEN 'Low'
WHEN fs.Discount<.5 THEN 'Medium'
WHEN fs.DiscounT<.75 THEN 'High'
ELSE 'Very High' END AS Discount_category,
AVG(Profit) AS 'Avarege Profit',
COUNT(*) AS 'Number of orders'
FROM [dbo].[Fact_Sales]fs join [dbo].[Dim_Date] dd
on fs.Order_Date_ID=dd.Date_ID
GROUP BY dd.Year,dd.Month_Name ,CASE WHEN fs.Discount=0 THEN 'Without Discount'
WHEN fs.Discount<.25 THEN 'Low'
WHEN fs.Discount<.5 THEN 'Medium'
WHEN fs.DiscounT<.75 THEN 'High'
ELSE 'Very High' END
ORDER BY dd.Year,dd.Month_Name
 
 
 
---13:-
-- Test: query the vw_Sales_Summary view
SELECT * FROM [dbo].[vw_Sales_Summary] order by Year
SELECT * FROM [dbo].[vw_Sales_Summary] where Category='Office Supplies'
 
 
---14:-
-- Test: query the vw_Customer_Profitability view
SELECT * FROM vw_Customer_Profitability
ORDER BY Profit_Margin DESC
 
 
-- Test: execute the stored procedure with a sample date range
EXEC Get_Sumary_by_Date_range @StartDate = '2013-5-1', @EndDate = '2014-5-1';
 
 
--CTE:-
--1:-
-- CTE 1: Months with above-average total sales
WITH Mnthly_Sales as(
SELECT DD.Year,DD.Month_Name,SUM(FS.Sales)
AS Total_Sales
FROM [dbo].[Fact_Sales]FS JOIN [dbo].[Dim_Date]DD
ON FS.Order_Date_ID=DD.Date_ID 
GROUP BY DD.Year,DD.Month_Name
)
SELECT * FROM Mnthly_Sales
WHERE Total_Sales>
(SELECT AVG(Total_Sales) FROM Mnthly_Sales);
 
 
---2:-
-- CTE 2: Rank products by total profit
WITH Products_Profit AS(
SELECT PD.Product_Name, SUM(FS.Profit) AS Total_Profit
FROM [dbo].[Dim_Product] PD
JOIN [dbo].[Fact_Sales] FS ON PD.Product_ID = FS.Product_ID
GROUP BY PD.Product_Name)
SELECT *,RANK() OVER 
(ORDER BY Total_Profit DESC) AS Profit_Rank
FROM Products_Profit;
 

