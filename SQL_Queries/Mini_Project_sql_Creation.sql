
-- ==========================================================
-- FILE 1: Database Creation & Setup
-- Contains: Table creation, data loading (INSERT), Views,
-- Stored Procedure, and Index creation.
-- ==========================================================
 
-- Create dimension and fact tables
CREATE TABLE Dim_Date
(
Date_ID INT PRIMARY KEY,
Full_Date DATE NOT NULL,
Day INT NOT NULL,
Month INT NOT NULL,
Month_Name VARCHAR(20) NOT NULL,
Quarter INT NOT NULL,
Year INT NOT NULL,
Day_Name VARCHAR(20) NOT NULL
);
 
CREATE TABLE Dim_Customer
(
Customer_ID VARCHAR(20) PRIMARY KEY,
Customer_Name VARCHAR(100) NOT NULL,
Segment VARCHAR(50) NOT NULL
);
 
CREATE TABLE Dim_Product
(
Product_ID VARCHAR(50) PRIMARY KEY,
Product_Name VARCHAR(255) NOT NULL,
Category VARCHAR(50) NOT NULL,
Sub_Category VARCHAR(50) NOT NULL
);
 
CREATE TABLE Dim_Location
(
Location_ID INT IDENTITY(1,1) PRIMARY KEY,
Country VARCHAR(50) NOT NULL,
City VARCHAR(50) NOT NULL,
State VARCHAR(50) NOT NULL,
Postal_Code INT NOT NULL,
Region VARCHAR(50) NOT NULL
);
 
CREATE TABLE Dim_ShipMode
(
Ship_Mode_ID INT IDENTITY(1,1) PRIMARY KEY,
Ship_Mode VARCHAR(50) NOT NULL
);
 
CREATE TABLE Fact_Sales
(
Sales_ID INT IDENTITY(1,1) PRIMARY KEY,
Row_ID INT NOT NULL,
Order_ID VARCHAR(50) NOT NULL,
Order_Date_ID INT NOT NULL,
Ship_Date_ID INT NOT NULL,
Customer_ID VARCHAR(20) NOT NULL,
Product_ID VARCHAR(50) NOT NULL,
Ship_Mode_ID INT NOT NULL,
Location_ID INT NOT NULL,
Sales FLOAT NOT NULL,
Quantity INT NOT NULL,
Discount FLOAT NOT NULL,
Profit FLOAT NOT NULL,
CONSTRAINT FK_Fact_OrderDate FOREIGN KEY(Order_Date_ID) REFERENCES Dim_Date(Date_ID),
CONSTRAINT FK_Fact_ShipDate FOREIGN KEY (Ship_Date_ID) REFERENCES Dim_Date(Date_ID),
CONSTRAINT FK_Fact_Customer FOREIGN KEY (Customer_ID) REFERENCES Dim_Customer(Customer_ID),
CONSTRAINT FK_Fact_Product FOREIGN KEY (Product_ID) REFERENCES Dim_Product(Product_ID),
CONSTRAINT FK_Fact_ShipMode FOREIGN KEY (Ship_Mode_ID) REFERENCES Dim_ShipMode(Ship_Mode_ID),
CONSTRAINT FK_Fact_Location FOREIGN KEY (Location_ID) REFERENCES Dim_Location(Location_ID)
);
 
-- Load data into Dim_Customer
INSERT INTO Dim_Customer (Customer_ID, Customer_Name, Segment)
SELECT DISTINCT Customer_ID, Customer_Name, Segment
FROM [dbo].[Central_Superstore];
 
-- Load data into Dim_Product (deduplicated by most frequent name)
;WITH ProductCounts AS (
SELECT Product_ID, Product_Name, Category, Sub_Category, COUNT(*) AS NameFreq
FROM [dbo].[Central_Superstore]
GROUP BY Product_ID, Product_Name, Category, Sub_Category
),
RankedProducts AS (
SELECT Product_ID, Product_Name, Category, Sub_Category,
ROW_NUMBER() OVER (PARTITION BY Product_ID ORDER BY NameFreq DESC) AS rn
FROM ProductCounts
)
INSERT INTO Dim_Product (Product_ID, Product_Name, Category, Sub_Category)
SELECT Product_ID, Product_Name, Category, Sub_Category
FROM RankedProducts
WHERE rn = 1;
 
-- Load data into Dim_ShipMode
INSERT INTO Dim_ShipMode (Ship_Mode)
SELECT DISTINCT Ship_Mode FROM [dbo].[Central_Superstore];
 
-- Load data into Dim_Location
INSERT INTO Dim_Location (Country, City, State, Postal_Code, Region)
SELECT DISTINCT Country, City, State, Postal_Code, Region
FROM [dbo].[Central_Superstore];
 
-- Load data into Dim_Date (from both Order_Date and Ship_Date)
INSERT INTO Dim_Date (Date_ID, Full_Date, Day, Month, Month_Name, Quarter, Year, Day_Name)
SELECT DISTINCT
CONVERT(INT, FORMAT(D.TheDate, 'yyyyMMdd')) AS Date_ID,
D.TheDate,
DAY(D.TheDate),
MONTH(D.TheDate),
DATENAME(MONTH, D.TheDate),
DATEPART(QUARTER, D.TheDate),
YEAR(D.TheDate),
DATENAME(WEEKDAY, D.TheDate)
FROM (
SELECT Order_Date AS TheDate FROM [dbo].[Central_Superstore]
UNION
SELECT Ship_Date FROM [dbo].[Central_Superstore]
) D;
 
-- Load data into Fact_Sales
INSERT INTO Fact_Sales (
Row_ID, Order_ID, Order_Date_ID, Ship_Date_ID,
Customer_ID, Product_ID, Ship_Mode_ID, Location_ID,
Sales, Quantity, Discount, Profit
)
SELECT
cs.Row_ID,
cs.Order_ID,
CONVERT(INT, FORMAT(cs.Order_Date, 'yyyyMMdd')),
CONVERT(INT, FORMAT(cs.Ship_Date, 'yyyyMMdd')),
cs.Customer_ID,
cs.Product_ID,
sm.Ship_Mode_ID,
loc.Location_ID,
cs.Sales,
cs.Quantity,
cs.Discount,
cs.Profit
FROM [dbo].[Central_Superstore] cs
JOIN Dim_ShipMode sm ON cs.Ship_Mode = sm.Ship_Mode
JOIN Dim_Location loc ON cs.City = loc.City 
AND cs.State = loc.State 
AND cs.Postal_Code = loc.Postal_Code;
 
-- Create view: yearly/region/category sales summary
CREATE VIEW vw_Sales_Summary AS
SELECT
DD.Year,DL.Region,DP.Category,
COUNT(*) AS 'Total Orders',SUM(Sales) AS 'Total Sales'
FROM [dbo].[Fact_Sales] FS JOIN [dbo].[Dim_Date] DD
ON FS.Order_Date_ID=DD.Date_ID
JOIN [dbo].[Dim_Location] DL
ON FS.Location_ID=DL.Location_ID
JOIN [dbo].[Dim_Product] DP
ON FS.Product_ID=DP.Product_ID 
GROUP BY DD.Year,DL.Region,DP.Category
 
-- Create view: customer profitability summary
CREATE VIEW vw_Customer_Profitability AS
SELECT DC.Customer_Name, SUM(FS.Profit) AS Total_Profit,
SUM (FS.Sales) AS Total_Sales,
SUM(FS.Profit)/SUM(FS.Sales) AS Profit_Margin
FROM [dbo].[Dim_Customer]DC JOIN [dbo].[Fact_Sales] FS
ON FS.Customer_ID=DC.Customer_ID
GROUP BY DC.Customer_Name
 
-- Create stored procedure: get sales summary within a date range
CREATE PROCEDURE Get_Sumary_by_Date_range
  @StartDate DATE,
  @EndDate DATE
AS
BEGIN
SELECT 
FS.Order_ID,DC.Customer_Name,DP.Product_Name,
DD.Full_Date AS Order_Date,
FS.Sales,FS.Profit
FROM [dbo].[Fact_Sales] FS JOIN
[dbo].[Dim_Customer] DC
ON FS.Customer_ID=DC.Customer_ID
JOIN [dbo].[Dim_Date] DD
ON DD.Date_ID=FS.Order_Date_ID
JOIN [dbo].[Dim_Product] DP
ON FS.Product_ID=DP.Product_ID
WHERE DD.Full_Date BETWEEN @StartDate AND @EndDate
 
END
 
-- Create indexes for performance optimization
CREATE INDEX  IX_FactSales_CustomerID 
ON Fact_Sales(Customer_ID);
CREATE INDEX IX_FactSales_ProductID ON 
Fact_Sales(Product_ID);
CREATE INDEX IX_FactSales_OrderDateID 
ON Fact_Sales(Order_Date_ID);
CREATE INDEX IX_FactSales_LocationID
ON Fact_Sales(Location_ID);
CREATE INDEX IX_FactSales_ShipModeID 
ON Fact_Sales(Ship_Mode_ID);
 
