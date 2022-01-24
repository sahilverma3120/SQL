USE AdventureWorks2008R2
GO

                                                    --Excercise 1--
/*
The exercise requires SQL Server AdventureWorks OLTP database which can be found at Codeplex. Download and attach a copy of the 
database to your server instance. Take some time to appreciate the entire schema of the database, and functions and stored 
procedures (refer AdventureWorks 2008 OLTP Schema.pdf). Using the AdventureWorks database, perform the following queries.*/
/*
	Query-1.1:: Display the number of records in the [SalesPerson] table. 
				(Schema(s) involved: Sales)
*/

SELECT Count(BusinessEntityID) AS 'Records'
FROM Sales.SalesPerson;

/*
	Query-1.2:: Select both the FirstName and LastName of records from the Person table 
				where the FirstName begins with the letter ‘B’. (Schema(s) involved: Person).
*/

SELECT FirstName ,LastName
FROM Person.Person
WHERE FirstName LIKE 'B%';

/*
	Query-1.3:: Select a list of FirstName and LastName for employees 
				where Title is one of Design Engineer, Tool Designer or Marketing Assistant.
				(Schema(s) involved:HumanResources, Person)
*/

SELECT Per.FirstName,
	   Per.LastName
FROM Person.Person AS Per INNER JOIN
	 HumanResources.Employee HE ON
	 Per.BusinessEntityID = Per.BusinessEntityID
WHERE HE.JobTitle = 'Design Engineer' OR
	  HE.JobTitle = 'Tool Designer' OR
	  HE.JobTitle = 'Marketing Assistant';

/*
	Query-1.4:: Display the Name and Color of the Product with the maximum weight.
				(Schema(s) involved: Production)
*/

SELECT Name,Color
FROM Production.Product
WHERE Weight = (Select MAX(Weight) FROM Production.Product);

/*
	Query-1.5:: Display Description and MaxQty fields from the SpecialOffer table.
				Some of the MaxQty values are NULL, in this case display 
				the value 0.00 instead.(Schema(s) involved: Sales)
*/

SELECT Description,
COALESCE(MaxQty,0.00) AS 'MAX Quantity'
FROM Sales.SpecialOffer;

/*
	Query-1.6:: Display the overall Average of the [CurrencyRate].[AverageRate] values for 
				the exchange rate ‘USD’ to ‘GBP’ for the year 2005 
				i.e. FromCurrencyCode = ‘USD’ and ToCurrencyCode = ‘GBP’. 
				Note: The field [CurrencyRate].[AverageRate] is defined as Average exchange rate for the day.'
				(Schema(s) involved: Sales)
*/

SELECT AVG(AverageRate) AS 'Average exchange rate for the day'
FROM Sales.CurrencyRate
WHERE datepart(year,CurrencyRateDate)=2005 
	AND FromCurrencyCode='USD'
	AND ToCurrencyCode='GBP';


/*
	Query-1.7:: Display the FirstName and LastName of records from the Person table 
				where FirstName contains the letters ‘ss’. Display an additional column 
				with sequential numbers for each row returned beginning at integer 1. 
				(Schema(s) involved: Person)
*/

SELECT ROW_NUMBER() OVER(ORDER BY FirstName) AS 'Sequence',FirstName,LastName
FROM Person.Person
WHERE FirstName LIKE '%ss%';

/*
	Query-1.8:: Sales people receive various commission rates that belong to 1 of 4 bands.
				(Schema(s) involved: Sales)
				CommissionPct	Commission Band
				0.00			Band 0
				Up To 1%		Band 1
				Up To 1.5%		Band 2
				Greater 1.5%	Band 3
				
				Display the [SalesPersonID] with an additional column entitled ‘Commission Band’ 
				indicating the appropriate band as above.
*/

SELECT BusinessEntityID AS 'SalesPersonID',
CASE
			WHEN CommissionPct = 0.00 THEN 'BAND 0'
			WHEN CommissionPct > 0.00 AND CommissionPct <= 0.01 THEN 'BAND 1'
			WHEN CommissionPct > 0.01 AND CommissionPct <= 0.015 THEN 'BAND 2'
			WHEN CommissionPct > 0.015 THEN 'BAND 3'
	  END AS 'Band of Commisson'
FROM Sales.SalesPerson
ORDER BY [Commission Band];

/*
	Query-1.9::	Display the managerial hierarchy from Ruth Ellerbrock (person type – EM) up to 
				CEO Ken Sanchez. Hint: use [uspGetEmployeeManagers] 
				(Schema(s) involved: [Person], [HumanResources])
*/

DECLARE @RuthEllerbrockID int = 
	(
	SELECT BusinessEntityID
	FROM Person.Person
	WHERE PersonType = 'EM'
		AND FirstName = 'Ruth'
		AND LastName = 'Ellerbrock'
	);

EXEC dbo.uspGetEmployeeManagers @RuthEllerbrockID; 
GO

/*
	Query-1.10:: Display the ProductId of the product with the largest stock level. 
				 Hint: Use the Scalar-valued function [dbo]. [UfnGetStock]. 
				 (Schema(s) involved: Production)
*/

SELECT TOP 1 ProductID,dbo.ufnGetStock(ProductID) AS Quantity
FROM Production.ProductInventory
ORDER BY Quantity DESC;

										--Excercise 2--
/*
	Query-2:Write separate queries using a join, a subquery, a CTE, and then an EXISTS to list all AdventureWorks customers who have not placed 
an order
*/


-- Using join
SELECT c.CustomerID
FROM Sales.Customer AS c LEFT OUTER JOIN 
	 Sales.SalesOrderHeader AS OH
	 ON c.CustomerID=OH.CustomerID
WHERE oH.SalesOrderID IS NULL;


-- Using Subquery
SELECT C.CustomerID
FROM Sales.Customer C
WHERE CustomerID NOT IN (SELECT OH.CustomerID FROM Sales.SalesOrderHeader OH);


-- USING CTE
WITH CUSTOMERS(CustomerId)
AS(
	SELECT C.CustomerID
	FROM Sales.Customer C
	WHERE CustomerID NOT IN (SELECT OH.CustomerID FROM Sales.SalesOrderHeader OH) 
)

SELECT CustomerId
FROM CUSTOMERS;

--USING EXISTS
SELECT c.CustomerID
FROM Sales.Customer  c
WHERE NOT EXISTS (SELECT OH.CustomerID 
FROM Sales.SalesOrderHeader  OH
WHERE OH.CustomerID=c.CustomerID)


										--Excercise 3--

/*
	 Show the most recent five orders that were purchased from account numbers that have spent more than $70,000 with 
AdventureWorks
*/

SELECT TOP 5 SalesOrderID AS 'Order ID',
	   OrderDate AS    'Date Of Order',
	   AccountNumber AS 'Account Number',
	   SUM(TotalDue) AS 'Amount Spent'
FROM Sales.SalesOrderHeader
GROUP BY AccountNumber,
		 OrderDate,
		 SalesOrderID
HAVING SUM(TotalDue) > 70000
ORDER BY OrderDate DESC;


										--Excercise 4--

/*
	          Create a function that takes as inputs a SalesOrderID, a Currency Code, 
			  and a date, and returns a table of all the SalesOrderDetail rows for 
			  that Sales Order including Quantity, ProductID, UnitPrice, and the unit
			  price converted to the target currency based on the end of day rate for
			  the date provided. Exchange rates can be found in the Sales.CurrencyRate 
			  table. ( Use AdventureWorks)
*/


--function
CREATE FUNCTION dbo.LineitemcurrencyExchange (
@SalesOrderID INT,
@TargetCurrencyCode nchar(3),
@CurrencyRateDate DATETIME
)
RETURNS @OutTable TABLE (
SalesOrderDetailID INT,
OrderQty SMALLINT,
ProductID INT,
UnitPrice MONEY,
UnitPriceConverted MONEY
)
AS
BEGIN
DECLARE @EndOfDayRate MONEY;
SELECT @EndOfDayRate = EndOfDayRate
FROM Sales.CurrencyRate
WHERE CurrencyRateDate = @CurrencyRateDate
AND ToCurrencyCode = @TargetCurrencyCode;
INSERT @OutTable
SELECT SalesOrderDetailID,
OrderQty,
ProductID,
UnitPrice,
UnitPrice * @EndOfDayRate
FROM Sales.SalesOrderDetail
WHERE SalesOrderID = @SalesOrderID
RETURN;
END
GO

-- For Testing Above Function
SELECT *
FROM dbo.LineitemcurrencyExchange (
43659,'EUR','2005-07-05 00:00:00.000'
)


										--Excercise 5--
/*
	          Write a Procedure supplying name information from the Person.
			  Person table and accepting a filter for the first name. 
			  Alter the above Store Procedure to supply Default Values 
			  if user does not enter any value.( Use AdventureWorks).
*/

CREATE PROCEDURE filterFirstName
	@FirstName varchar(50)
AS
SELECT FirstName
FROM Person.Person
WHERE FirstName LIKE '%' + @FirstName + '%';
GO
--For Test Filter by Name
EXEC filterFirstName2 @FirstName = 'ss'
GO

--Alter Method
ALTER PROCEDURE filterFirstName
	@FirstName varchar(50) = 'sa'
AS
SELECT FirstName
FROM Person.Person
WHERE FirstName LIKE '%' + @FirstName + '%';
GO
--For Test Alter method
EXEC filterFirstName1
GO

										--Excercise 6--

/*
	          Write a trigger for the Product table to ensure the list price
			  can never be raised more than 15 Percent in a single change.
			  Modify the above trigger to execute its check code only if the
			  ListPrice column is   updated (Use AdventureWorks Database).
*/

CREATE TRIGGER [Production].[trgLimitPriceChanges]
ON [Production].[Product]
FOR UPDATE
AS
IF EXISTS (
SELECT * FROM inserted i
JOIN deleted d
ON i.ProductID = d.ProductID
WHERE i.ListPrice > (d.ListPrice * 1.15)
)
BEGIN
RAISERROR('Price increased may not be greater than 15 percent.Therefore Transaction Failed.',16,1)
ROLLBACK TRAN
END
GO
ALTER TRIGGER [Production].[trgLimitPriceChanges]
ON [Production].[Product]
FOR UPDATE
AS
IF UPDATE(ListPrice)
BEGIN
IF EXISTS
(
SELECT *
FROM inserted i
JOIN deleted d
ON i.ProductID = d.ProductID
WHERE i.ListPrice > (d.ListPrice * 1.15)
 )
BEGIN RAISERROR('Price increased may not be greater than 15 percent.Therefore Transaction Failed.',16,1)
ROLLBACK TRAN
END
END
GO

--first we perform update query to raise the list price--

update Production.Product
set ListPrice = 60
where ProductID = 985

--after update is done successfully check the List Price is updated--
select*
from Production.Product
where ProductID = 987
