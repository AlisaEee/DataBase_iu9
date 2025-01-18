use master;
use AirlineDB;
--Создать хранимую процедуру, производящую выборку из некоторой таблицы и возвращающую результат выборки в виде курсора.

IF OBJECT_ID(N'dbo.Select_Func', N'P') IS NOT NULL
	DROP PROCEDURE dbo.Select_Func
GO

CREATE PROCEDURE dbo.Select_Func
	@cursor CURSOR VARYING OUTPUT
AS
	SET @cursor = CURSOR 
		FORWARD_ONLY STATIC FOR
		SELECT registration_number,model, capacity, aviacompany
		FROM AirCraft
OPEN @cursor;
GO

DECLARE @air_cursor CURSOR;
EXECUTE dbo.Select_Func @cursor = @air_cursor OUTPUT;


FETCH NEXT FROM @air_cursor;
WHILE (@@FETCH_STATUS = 0)
BEGIN
	FETCH NEXT FROM @air_cursor;
END

CLOSE @air_cursor;
DEALLOCATE @air_cursor;
GO
-- Модифицировать хранимую процедуру, чтобы выборка осуществлялась с формированием столбца

IF OBJECT_ID('dbo.AirCraftCost', 'FN') IS NOT NULL
	DROP FUNCTION dbo.AirCraftCost;
GO

CREATE FUNCTION dbo.AirCraftCost(@aviacompany NVARCHAR(40))
RETURNS INT
AS
BEGIN
    DECLARE @flight_cost INT;
    
    SET @flight_cost = CASE
                        WHEN @aviacompany = 'Airflot' THEN 300
                        ELSE 100
                        END;
                        
    RETURN @flight_cost;
END;
GO

IF OBJECT_ID(N'dbo.Select_Func', N'P') IS NOT NULL
	DROP PROCEDURE dbo.Select_Func
GO

CREATE PROCEDURE dbo.Select_Func
	@cursor CURSOR VARYING OUTPUT
AS
	SET @cursor = CURSOR 
		FORWARD_ONLY STATIC FOR
		SELECT registration_number,model, capacity, aviacompany,dbo.AirCraftCost(aviacompany) AS flight_cost
		FROM AirCraft
	OPEN @cursor;
GO
--USE
DECLARE @air_mod_cursor CURSOR;
EXECUTE dbo.Select_Func @cursor = @air_mod_cursor OUTPUT;

FETCH NEXT FROM @air_mod_cursor;
WHILE @@FETCH_STATUS = 0
BEGIN
    FETCH NEXT FROM @air_mod_cursor;
END;

CLOSE @air_mod_cursor;
DEALLOCATE @air_mod_cursor;
GO

-- Создать хранимую процедуру, вызывающую процедуру, осуществляющую прокрутку возвращаемого 
-- курсора и выводящую сообщения, сформированные из записей при выполнении условия, заданного еще одной пользовательской функцией.	
IF OBJECT_ID(N'aviacompany',N'FN') IS NOT NULL
	DROP FUNCTION aviacompany
go

CREATE FUNCTION aviacompany(@a NVARCHAR(40))
	RETURNS NVARCHAR(20)
	AS
		BEGIN
			DECLARE @result NVARCHAR(20);
			IF (@a = 'Airflot' or @a = 'S7')
				SET @result = 'Russian'
			ELSE
				SET @result = 'American'
			RETURN (@result)
		END;
go

IF OBJECT_ID(N'dbo.Third_proc',N'P') IS NOT NULL
	DROP PROCEDURE dbo.Third_proc
GO

CREATE PROCEDURE dbo.Third_proc 
AS
	DECLARE @third_cursor CURSOR;
	DECLARE	@registration_number int;
	DECLARE @model NVARCHAR(40);
	DECLARE @capacity int;
	DECLARE @aviacompany NVARCHAR(40);
	DECLARE @flight_cost int;
	
	EXECUTE dbo.Select_Func @cursor = @third_cursor OUTPUT;

	FETCH NEXT FROM @third_cursor INTO @registration_number,@model,@capacity,@aviacompany,@flight_cost
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF (dbo.aviacompany(@aviacompany)='Russian')
			PRINT CAST(@registration_number AS NVARCHAR(10)) + ' ' + @model + ' ' + CAST(@capacity AS NVARCHAR(10)) +' '+ @aviacompany + N' (Russian aviacompany)'
		ELSE
			PRINT CAST(@registration_number AS NVARCHAR(10)) + ' ' + @model + ' ' + CAST(@capacity AS NVARCHAR(10)) +' '+ @aviacompany +N' (American aviacompany)'
		FETCH NEXT FROM @third_cursor INTO @registration_number,@model,@capacity,@aviacompany,@flight_cost;
	END

	CLOSE @third_cursor;
	DEALLOCATE @third_cursor;

GO

EXECUTE dbo.Third_proc
GO
--- Модифицировать хранимую процедуру таким образом, чтобы выборка
--- формировалась с помощью табличной функции.
IF OBJECT_ID(N'dbo.tableOutput') IS NOT NULL
	DROP FUNCTION dbo.tableOutput
go	
CREATE FUNCTION dbo.tableOutput()
	RETURNS @retTableOutput TABLE
	(	registration_number int PRIMARY KEY NOT NULL,
		model NVARCHAR(40) NOT NULL,
		capacity int NOT NULL,
		aviacompany NVARCHAR(40) NOT NULL,
		flighCost INT NOT NULL
	)
AS
	BEGIN
		WITH DirectReports(registration_number, model, capacity, aviacompany,flighCost) AS
			(SELECT registration_number,model, capacity, aviacompany,dbo.AirCraftCost(aviacompany) AS flighCost
			FROM AirCraft)
		INSERT INTO @retTableOutput
		SELECT registration_number, model, capacity, aviacompany, dbo.AirCraftCost(aviacompany) AS flightCost
		FROM DirectReports
		WHERE aviacompany = 'S7'
		RETURN
	END;
GO
CREATE FUNCTION dbo.tableOutput2()
	RETURNS TABLE
AS
	RETURN(
		SELECT registration_number, model, capacity, aviacompany, dbo.AirCraftCost(aviacompany) AS flightCost FROM AirCraft
	);
GO
ALTER PROCEDURE dbo.Select_Func
	@cursor CURSOR VARYING OUTPUT
AS
	SET @cursor = CURSOR 
	FORWARD_ONLY STATIC FOR 
	SELECT * FROM dbo.tableOutput2()
	OPEN @cursor;
GO
DECLARE @table_cursor CURSOR;
EXECUTE dbo.Select_Func @cursor = @table_cursor OUTPUT;

FETCH NEXT FROM @table_cursor;
WHILE (@@FETCH_STATUS = 0)
	BEGIN
		FETCH NEXT FROM @table_cursor;
	END

CLOSE @table_cursor;
DEALLOCATE @table_cursor;
GO