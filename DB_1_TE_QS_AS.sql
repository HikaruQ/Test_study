-- Create DB
DROP DATABASE IF EXISTS Project;
CREATE DATABASE IF NOT EXISTS Project;
-- Use Database
USE Project;

-- Create Table Employee
CREATE TABLE 	CUSTOMER ( 
	CustomerID 					INT AUTO_INCREMENT PRIMARY KEY,
	`Name`						VARCHAR(30) NOT NULL,
	Phone 						CHAR(13) NOT NULL,
	Email 						VARCHAR(50) UNIQUE NOT NULL,
	Address 					VARCHAR(100) NOT NULL,
    Note						VARCHAR(500) NOT NULL
);

-- Create Table CAR
CREATE TABLE 	CAR (
	CarID 						INT AUTO_INCREMENT PRIMARY KEY,
	Maker						ENUM('HONDA','TOYOTA','NISSAN') NOT NULL ,
	Model 						CHAR(13) NOT NULL,
	`Year` 						SMALLINT UNIQUE NOT NULL,
	Color 						VARCHAR(50) NOT NULL,
    Note						VARCHAR(500) NOT NULL
);

-- Create Table CAR_ORDER
CREATE TABLE 	CAR_ORDER ( 
	OrderID 					INT AUTO_INCREMENT PRIMARY KEY,
	CustomerID					INT NOT NULL ,
	CarID 						INT NOT NULL,
	Amount						SMALLINT DEFAULT 1 NOT NULL,
	SalePrice 					DOUBLE NOT NULL,
	OrderDate 					DATE NOT NULL,
	DeliveryDate 				DATE NOT NULL,
	DeliveryAddress 			VARCHAR(100) NOT NULL,
	Staus 						TINYINT(2) DEFAULT 0 NOT NULL,
    Note						VARCHAR(500) NOT NULL,
    FOREIGN KEY (CarID) REFERENCES  CAR(CarID) ON DELETE CASCADE,
    FOREIGN KEY (CustomerID) REFERENCES  CUSTOMER(CustomerID) ON DELETE CASCADE
);

 -- Insert CUSTOMER
INSERT INTO	CUSTOMER
	(`Name`,				Phone,				Email,					Address,						Note	)
	VALUES
	('A',					'123456',			'acb@gmail.com',		'HN',							'1'		),
	('A1',					'1234562',			'acb1@gmail.com',		'H1N',							'21'	),
	('A2',					'1234564',			'acb2@gmail.com',		'HN2',							'12'	);
	
 INSERT INTO	CAR
	(Maker,					 Model,				`Year`,					Color,							Note)
	VALUES
	('HONDA',				'HONDA1',			1990,					'YEALLOW',						'1'		),
	('TOYOTA',				'TOYOTA1',			1992,					'BLUE',							'12'	),
	('NISSAN',				'NISSAN1',			1994,					'RED',							'111'	);
	
INSERT INTO		CAR_ORDER 
	(CustomerID,			CarID,				Amount,					SalePrice, 						OrderDate, 					DeliveryDate, 				DeliveryAddress,		Note)
	VALUES
	(1,						2,					2,						 5.000000,						'2000-03-01',				'2000-03-21',				 'HN' ,					'123'	),
	(2,						2,					2,						 6.000000,						'2000-03-04',				'2000-03-10',				 'HN1',					'1234'	),
	(3,						2,					2,						 8.000000,						'2000-03-08',				'2000-03-15',				 'HN2',					'1235'	),
	(3,						1,					7,						 8.000000,						'2000-03-08',				'2000-03-15',				 'HN2',					'1235'	);

--b)	Write SQL script to list out information (Customer’s name, number of cars that customer bought) and sort ascending by number of cars.
		-- Outer Query Get name from CustomerID of SUBQUERY
		SELECT		C.Name, t.NumberCars
		FROM		dbo.CUSTOMER	c		
		JOIN		(
						-- SUBQUERY GET CUSTOMER ID bought AND number of cars
						SELECT		co.CustomerID ,SUM(co.Amount) AS NumberCars
						FROM		dbo.CAR_ORDER	co
						WHERE		co.Staus = 1
						GROUP BY	co.CustomerID
						HAVING		SUM(co.Amount) > 0
					)	AS	t	ON c.CustomerID = t.CustomerID
		ORDER BY t.NumberCars ASC	-- sort ascending by number of cars
	
--c)	Write a user function (without parameter) that return maker who has sale most cars in this year.
		-- Drop the UDF if it already exists

		IF OBJECT_ID (N'dbo.UDF_Bought_Most_Cars_Year') IS NOT NULL
			DROP FUNCTION dbo.UDF_Bought_Most_Cars_Year
		GO
		-- Create UDF
		CREATE FUNCTION dbo.UDF_Bought_Most_Cars_Year()
		RETURNS TABLE
		AS RETURN
		(		
			WITH CTE_Bought_Most_Cars_Year
			AS ( 
					SELECT		TOP 1 SUM(Amount)  AS MaxAmount
					FROM		dbo.CAR_ORDER 
					WHERE		YEAR(GETDATE()) = YEAR(DeliveryDate) AND Staus = 1
					GROUP BY	CustomerID
					ORDER BY	MaxAmount DESC
				)
			-- Get name from MaxAmount of CTE
			SELECT	c.Name
			FROM	dbo.CUSTOMER	c	
			JOIN	(	
						-- SUBQUERY GET CUSTOMER ID bought most cars in this year. 
						SELECT		CustomerID 
						FROM		dbo.CAR_ORDER
						WHERE		YEAR(GETDATE()) = YEAR(DeliveryDate) AND Staus = 1
						GROUP BY	CustomerID
						HAVING		COUNT(Amount) = (	SELECT	MaxAmount 
														FROM	CTE_Bought_Most_Cars_Year)			
					)	AS bmcy ON	bmcy.CustomerID = c.CustomerID
		)
		GO

		-- Display result function
		SELECT	*
		FROM	dbo.UDF_Bought_Most_Cars_Year()

--d)	Write a stored procedure (without parameter) to remove the orders have status is canceled in the years before. Print out the number of records which are removed.
		-- Drop the Store Procedure if it already exists
		IF EXISTS (
			SELECT * 
			FROM INFORMATION_SCHEMA.ROUTINES 
			WHERE	SPECIFIC_SCHEMA = N'dbo'
				AND SPECIFIC_NAME = N'SP_remove_customer_years_before' 
		)
		   DROP PROCEDURE dbo.SP_remove_customer_years_before
		GO
		-- Create Store Procedure
		CREATE PROCEDURE dbo.SP_remove_customer_years_before
		AS
			SET NOCOUNT ON;

			-- remove the orders have status is canceled in the years before
			DELETE
			FROM	dbo.CAR_ORDER
			WHERE	Staus = 2 AND YEAR(GETDATE()) < YEAR(OrderDate)
			-- Print out the number of records which are removed
			PRINT @@ROWCOUNT
		GO

		-- Display result store procedure
		EXECUTE dbo.SP_remove_customer_years_before
		GO


--e)	Write a stored procedure (with CustomerID parameter) to print out information (Customer’s name, OrderID, Amount, Maker) that have status of the order is ordered.
		-- Drop the Store Procedure if it already exists
		IF EXISTS (
			SELECT * 
			FROM INFORMATION_SCHEMA.ROUTINES 
			WHERE	SPECIFIC_SCHEMA = N'dbo'
				AND SPECIFIC_NAME = N'SP_Customers_ordered' 
		)
		   DROP PROCEDURE dbo.SP_Customers_ordered
		GO
		-- Create Store Procedure
		CREATE PROCEDURE	dbo.SP_Customers_ordered
							@CustomerID_IN				INT
		AS
			SET NOCOUNT ON;

			-- print out information (Customer’s name, OrderID, Amount, Maker) that have status of the order is ordered
			SELECT		c.Name, co.OrderID, co.Amount
			FROM		dbo.CAR_ORDER	co 
			JOIN		dbo.CUSTOMER	c	ON c.CustomerID = co.CustomerID
			WHERE		co.Staus = 0 AND co.CustomerID = @CustomerID_IN
		GO

		-- Display result store procedure
		EXECUTE		dbo.SP_Customers_ordered 1
		GO


--f)	Write the trigger(s) to prevent the case that the end user to input invalid order information (DeliveryDate < OrderDate + 15).
		-- Drop the Trigger if it already exists
		IF OBJECT_ID ('dbo.TR_CAR_ORDER','TR') IS NOT NULL
		   DROP TRIGGER dbo.TR_CAR_ORDER
		GO
		-- Create Trigger
		CREATE TRIGGER dbo.TR_CAR_ORDER 
			ON  dbo.CAR_ORDER 
		   FOR  INSERT, UPDATE
		AS 
			-- DECLARE
			DECLARE		@DeliveryDate_IN	DATE,
						@OrderDate_IN		DATE
			-- get DeliveryDate and OrderDate inserted recent 
			SELECT	@DeliveryDate_IN = DeliveryDate, @OrderDate_IN = OrderDate
			FROM	INSERTED 
			-- Logic: If DeliveryDate < OrderDate + 15 then ROLLBACK
			IF @DeliveryDate_IN < DATEADD(D, 15, @OrderDate_IN)
				BEGIN
					PRINT 'Error: eliveryDate < OrderDate + 15' 
					ROLLBACK TRAN
				END
			-- else continue
		GO
							
-- Test function of Git 
    
