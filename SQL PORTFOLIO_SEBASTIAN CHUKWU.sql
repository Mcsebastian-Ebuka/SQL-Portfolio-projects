/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [SalesOrderID]
      ,[SalesOrderDetailID]
      ,[CarrierTrackingNumber]
      ,[OrderQty]
      ,[ProductID]
      ,[SpecialOfferID]
      ,[UnitPrice]
      ,[UnitPriceDiscount]
      ,[LineTotal]
      ,[rowguid]
      ,[ModifiedDate]
  FROM [AdventuresWork2019].[Sales].[SalesOrderDetail]


--SUB QUERIES----
--TOTAL NUMBERS OF UNITS SOLD
SELECT PRODUCTID, SUM(ORDERQTY) AS TOTAL_UNITS 
FROM [AdventuresWork2019].[Sales].[SalesOrderDetail] GROUP BY PRODUCTID ORDER BY TOTAL_UNITS DESC; 

---Sales person that exceed the average Total sales
SELECT* FROM [Sales].[SalesPerson] WHERE 
SalesYTD > (SELECT AVG(SALESYTD) FROM [Sales].[SalesPerson])

----top selling products with total sales
SELECT  p.Name AS ProductName, SUM(sod.OrderQty * sod.UnitPrice) AS TotalSales
FROM [Sales].[SalesOrderDetail] sod
JOIN [Production].[Product] p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalSales DESC

------top 5 region sales performance showing product name and unit price  
SELECT sp.TerritoryID AS RegionID, p.Name AS ProductName, sod.UnitPrice,
    SUM(sod.OrderQty * sod.UnitPrice) AS TotalSales
FROM [Sales].[SalesOrderDetail] sod
JOIN [Production].[Product] p ON sod.ProductID = p.ProductID
JOIN [Sales].[SalesOrderHeader] soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN [Sales].[SalesPerson] sp ON soh.SalesPersonID = sp.BusinessEntityID
GROUP BY sp.TerritoryID, p.Name, sod.UnitPrice
ORDER BY SUM(sod.OrderQty * sod.UnitPrice) DESC
OFFSET 0 ROWS
FETCH NEXT 5 ROWS ONLY;

-----the total purchase of each customer by region (top 30)
SELECT soh.TerritoryID AS RegionID, CONCAT(p.FirstName, ' ', p.LastName) AS CustomerName,
SUM(sod.OrderQty * sod.UnitPrice) AS TotalSales
FROM [Sales].[SalesOrderDetail] sod
JOIN [Sales].[SalesOrderHeader] soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN [Sales].[Customer] c ON soh.CustomerID = c.CustomerID
JOIN [Person].[Person] p ON c.PersonID = p.BusinessEntityID
GROUP BY soh.TerritoryID, CONCAT(p.FirstName, ' ', p.LastName)
ORDER BY soh.TerritoryID, TotalSales DESC
OFFSET 0 ROWS
FETCH NEXT 30 ROWS ONLY;

------------------CTEs-------------------------
------highest sold product by  order quantity (first 30 rows)
WITH ProductSales AS (
SELECT ProductID,SUM(OrderQty) AS TotalQuantity
FROM [Sales].[SalesOrderDetail] GROUP BY ProductID
)

SELECT ps.ProductID,ps.TotalQuantity
FROM ProductSales ps
ORDER BY ps.TotalQuantity DESC
OFFSET 0 ROWS
FETCH NEXT 30 ROWS ONLY;

-------most ordered products (first 30 rows)
WITH ProductOrderSummary AS (
SELECT ProductID, SUM(OrderQty) AS TotalQuantityOrdered
FROM [Sales].[SalesOrderDetail] GROUP BY ProductID
)
SELECT pos.ProductID,pos.TotalQuantityOrdered,p.Name AS ProductName
FROM ProductOrderSummary pos
JOIN [Production].[Product] p ON pos.ProductID = p.ProductID
ORDER BY pos.TotalQuantityOrdered DESC;

----- total amount of units sold 
WITH SoldUnits AS (
SELECT SalesOrderID, SUM(OrderQty) AS TotalUnits
FROM [Sales].[SalesOrderDetail] GROUP BY SalesOrderID
)
SELECT SUM(TotalUnits) AS TotalUnitsSold
FROM SoldUnits;

------top five sales person 
WITH TotalSalesCTE AS (
SELECT sp.BusinessEntityID, CONCAT(p.FirstName, ' ', p.LastName) AS SalesPersonName,
SUM(sod.OrderQty * sod.UnitPrice) AS TotalSales
FROM [Sales].[SalesPerson] sp
JOIN [Sales].[SalesOrderHeader] soh ON sp.BusinessEntityID = soh.SalesPersonID
JOIN [Sales].[SalesOrderDetail] sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN [Person].[Person] p ON sp.BusinessEntityID = p.BusinessEntityID
GROUP BY sp.BusinessEntityID, p.FirstName, p.LastName
)
SELECT BusinessEntityID,SalesPersonName,TotalSales
FROM TotalSalesCTE
ORDER BY TotalSales DESC
OFFSET 0 ROWS 
FETCH NEXT 5 ROWS ONLY;

---------sales persons performance by territory 
WITH SalesPerformance AS (
SELECT sp.BusinessEntityID,sp.TerritoryID,
SUM(sod.OrderQty * sod.UnitPrice) AS TotalSales
FROM [Sales].[SalesPerson] sp
JOIN [Sales].[SalesOrderHeader] soh ON sp.BusinessEntityID = soh.SalesPersonID
JOIN [Sales].[SalesOrderDetail] sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY sp.BusinessEntityID, sp.TerritoryID
)
SELECT sp.BusinessEntityID,sp.TerritoryID,sp.TotalSales
FROM SalesPerformance sp
ORDER BY sp.TerritoryID, sp.TotalSales DESC
OFFSET 0 ROWS 
FETCH NEXT 20 ROWS ONLY;

----------------------JOIN---------------------
-----Top ten customers by order quantity 
SELECT c.CustomerID, CONCAT(p.FirstName, ' ', p.LastName) AS CustomerName,
SUM(sod.OrderQty) AS TotalOrderQuantity
FROM [Sales].[SalesOrderDetail] sod
JOIN [Sales].[SalesOrderHeader] soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN [Sales].[Customer] c ON soh.CustomerID = c.CustomerID
JOIN [Person].[Person] p ON c.PersonID = p.BusinessEntityID
GROUP BY c.CustomerID, CONCAT(p.FirstName, ' ', p.LastName)
ORDER BY TotalOrderQuantity DESC
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;

------- Top five products (names) by order quantity
SELECT p.Name AS ProductName,
SUM(sod.OrderQty) AS TotalOrderQuantity
FROM [Sales].[SalesOrderDetail] sod
JOIN [Production].[Product] p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalOrderQuantity DESC
OFFSET 0 ROWS
FETCH NEXT 5 ROWS ONLY;

-------- highest sold products (name) by territory and order quantity
SELECT p.Name AS ProductName,soh.TerritoryID AS TerritoryID,
SUM(sod.OrderQty) AS TotalOrderQuantity
FROM [Sales].[SalesOrderDetail] sod
JOIN [Sales].[SalesOrderHeader] soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN [Production].[Product] p ON sod.ProductID = p.ProductID
GROUP BY p.Name, soh.TerritoryID
ORDER BY TotalOrderQuantity DESC;

-------- products without sales 
SELECT p.ProductID,p.Name AS ProductName
FROM [Production].[Product] p
WHERE 
NOT EXISTS (
SELECT 1 FROM [Sales].[SalesOrderDetail] sod
JOIN [Sales].[SalesOrderHeader] soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE sod.ProductID = p.ProductID
            AND soh.OrderDate >= DATEADD(MONTH, -3, GETDATE())
);
-------Sales performance by product category
SELECT p.ProductID,p.Name AS ProductName
FROM [Production].[Product] p
LEFT JOIN 
[Sales].[SalesOrderDetail] sod ON p.ProductID = sod.ProductID
LEFT JOIN 
[Sales].[SalesOrderHeader] soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE soh.OrderDate < DATEADD(MONTH, -3, GETDATE()) OR soh.OrderDate IS NULL
GROUP BY p.ProductID, p.Name
HAVING 
COUNT(sod.ProductID) = 0;

