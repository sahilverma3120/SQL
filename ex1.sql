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

SELECT Count(BusinessEntityID) AS 'Number Of Records'
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

SELECT PP.FirstName,
	   pp.LastName
FROM Person.Person AS PP INNER JOIN
	 HumanResources.Employee HE ON
	 PP.BusinessEntityID = HE.BusinessEntityID
WHERE HE.JobTitle = 'Design Engineer' OR
	  HE.JobTitle = 'Tool Designer' OR
	  He.JobTitle = 'Marketing Assistant';

/*
	Query-1.4:: Display the Name and Color of the Product with the maximum weight.
				(Schema(s) involved: Production)
*/

SELECT [Name],Color
FROM Production.Product
WHERE Weight = (Select MAX(Weight)
FROM Production.Product);


/*
	Query-1.5:: Display Description and MaxQty fields from the SpecialOffer table.
				Some of the MaxQty values are NULL, in this case display 
				the value 0.00 instead.(Schema(s) involved: Sales)
*/

SELECT Description,
COALESCE(MaxQty,0.00) AS 'MAXIMUM Quantity'
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
WHERE FromCurrencyCode = 'USD' AND ToCurrencyCode = 'GBP';


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
	   END AS 'Commission Band'
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

SELECT ProductID AS 'Product ID'
FROM Production.Product
WHERE SafetyStockLevel = (SELECT MAX(SafetyStockLevel)
						  FROM Production.Product);




										--Excercise 2--

/*
	Query-2:Write separate queries using a join, a subquery, a CTE, and then an EXISTS to list all AdventureWorks customers who have not placed 
an order
*/

-- 2.1:: By Using JOIN Statement
SELECT PP.FirstName + PP.LastName AS 'Customer Name'
FROM Person.Person PP INNER JOIN
	 Sales.Customer SC ON
	 PP.BusinessEntityID = SC.CustomerID LEFT JOIN
	 Sales.SalesOrderHeader SS ON
	 SC.CustomerID = SS.CustomerID
WHERE SS.SalesOrderID IS NULL;

-- 2.2:: By Using SubQuery



SELECT FirstName + LastName AS 'Customer Name'
FROM Person.Person
Where BusinessEntityID IN (SELECT CustomerID
							  FROM Sales.Customer
							  WHERE CustomerID NOT IN  (SELECT CustomerID
														   FROM Sales.SalesOrderHeader));


-- 2.3:: By Using CTEs

WITH UnorderProductCustomers (CustomerName)
AS (
	SELECT PP.FirstName + PP.LastName AS 'CustomerName'
	FROM Person.Person PP INNER JOIN
	 Sales.Customer SC ON
	 PP.BusinessEntityID = SC.CustomerID LEFT JOIN
	 Sales.SalesOrderHeader SS ON
	 SC.CustomerID = SS.CustomerID
	WHERE SS.SalesOrderID IS NULL
   )
SELECT CustomerName
FROM UnorderProductCustomers;


-- 2.4:: By Using EXISTS

SELECT PP.FirstName + PP.LastName AS 'Customer Name'
FROM Person.Person PP
WHERE EXISTS (SELECT SC.CustomerID
			  FROM Sales.Customer SC
			  WHERE PP.BusinessEntityID = SC.CustomerID AND
					NOT EXISTS(SELECT SS.CustomerID
							   FROM Sales.SalesOrderHeader SS
							   WHERE SC.CustomerID = SS.CustomerID));


										--Excercise 3--

/*
	Query-3:: Show the most recent five orders that were purchased from account numbers that have spent more than $70,000 with 
AdventureWorks
*/

SELECT TOP 5 SalesOrderID AS 'Order ID',
	   OrderDate AS 'Date Of Order',
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
	Query-4:: Create a function that takes as inputs a SalesOrderID, a Currency Code, 
			  and a date, and returns a table of all the SalesOrderDetail rows for 
			  that Sales Order including Quantity, ProductID, UnitPrice, and the unit
			  price converted to the target currency based on the end of day rate for
			  the date provided. Exchange rates can be found in the Sales.CurrencyRate 
			  table. ( Use AdventureWorks)
*/

GO
CREATE FUNCTION Sales.uf_NewFunction(@SalesOrderId int,@CurrencyCode nchar(3),@Date datetime)
RETURNS TABLE
AS
RETURN 
	SELECT sod.ProductID AS 'Product ID',
		   sod.OrderQty AS ' Order Quantity',
		   sod.UnitPrice As 'Unit Price',
		   sod.UnitPrice*scr.EndOfDayRate AS 'Target Price'
	FROM Sales.SalesOrderDetail AS sod,
		 Sales.CurrencyRate AS scr
	WHERE scr.ToCurrencyCode = @CurrencyCode AND
		  scr.ModifiedDate = @Date AND 
		  sod.SalesOrderID = @SalesOrderID

GO

Select * from Sales.uf_NewFunction(43659,'MXN','2005-09-05');



										--Excercise 5--

/*
	Query-5:: Write a Procedure supplying name information from the Person.
			  Person table and accepting a filter for the first name. 
			  Alter the above Store Procedure to supply Default Values 
			  if user does not enter any value.( Use AdventureWorks).
*/

GO
CREATE PROCEDURE Person.up_DisplayPersonInfo
	@FirstName nvarchar(20) = 'Tommy'
AS
BEGIN
	SELECT BusinessEntityID AS 'ID',
		   FirstName + LastName AS 'NAME',
		   PersonType
	FROM Person.Person
	WHERE FirstName = @FirstName
END

EXECUTE Person.up_DisplayPersonInfo
EXECUTE Person.up_DisplayPersonInfo @FirstName = 'Blake'

GO


										--Excercise 6--

/*
	Query-6:: Write a trigger for the Product table to ensure the list price
			  can never be raised more than 15 Percent in a single change.
			  Modify the above trigger to execute its check code only if the
			  ListPrice column is   updated (Use AdventureWorks Database).
*/

GO
CREATE OR ALTER TRIGGER [Production].UpdateTrigger
ON Production.Product
INSTEAD OF UPDATE
AS
SET NOCOUNT ON
BEGIN
	IF UPDATE(ListPrice)						-- Modification A.T.Q second requirement
	DECLARE @OldListPrice money
	DECLARE @InsertedListPrice money
	DECLARE @ID int
	SELECT @OldListPrice = p.ListPrice,
		   @InsertedListPrice=inserted.ListPrice,
		   @ID = inserted.ProductID
	FROM Production.Product p, inserted
	WHERE p.ProductID = inserted.ProductID;

	IF( @InsertedListPrice > ( @OldListPrice + (0.15*@OldListPrice) ) ) 
	BEGIN
		RAISERROR('LIST PRICE MORE THAN 15 PERCENT, TRANSACTION FAILED',16,0)
		ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		Update Production.Product SET ListPrice=@InsertedListPrice 
		WHERE Production.Product.ProductID = @ID;
	END
	
END;
SELECT Production.Product.ProductID,
	   Production.Product.ListPrice
FROM PRODUCTION.Product;

UPDATE PRODUCTION.Product 
SET ListPrice=2
WHERE Product.ProductID=4;
