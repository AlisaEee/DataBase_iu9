--Для одной из таблиц пункта 2 задания 7 создать триггеры на вставку, удаление и добавление, при
--выполнении заданных условий один из триггеров должен инициировать возникновение ошибки (RAISERROR / THROW).
use AirlineDB;
--INSERT TRIGER
IF OBJECT_ID(N'insert_Aircraft',N'TR') IS NOT NULL
	DROP TRIGGER insert_Aircraft
go

CREATE TRIGGER insert_Aircraft
	ON Aircraft
	AFTER INSERT 
AS
	BEGIN
		DECLARE @WarCount INT;
		SELECT @WarCount = COUNT(*) FROM inserted WHERE model = 'TU160';

		IF @WarCount >= 1
			BEGIN
				RAISERROR('Нельзя добавить военный самолет', 15, 100);
				ROLLBACK TRANSACTION;
			END;
		ELSE
			PRINT 'Все самолеты - гражданские';
	END
go

INSERT INTO Aircraft
	(registration_number,model, capacity, aviacompany)
VALUES  --(5,'TU160', 10, 'Airflot'),
	    (6,'Bombardier', 300, 'American Airlines')
SELECT * FROM Aircraft
go
-- Update
IF OBJECT_ID(N'update_Aircraft',N'TR') IS NOT NULL
	DROP TRIGGER update_Aircraft
go
CREATE TRIGGER update_Aircraft
ON Aircraft
AFTER UPDATE
AS
BEGIN
    DECLARE @TooLongModelExists BIT;
    WITH UpdatedModels AS (
        SELECT model
        FROM inserted
        WHERE LEN(model) > 15
    )
    SELECT @TooLongModelExists = CASE WHEN EXISTS (SELECT 1 FROM UpdatedModels) THEN 1 ELSE 0 END;

    IF @TooLongModelExists = 1
    BEGIN
        RAISERROR('Too long model', 15, 100);
        ROLLBACK TRANSACTION;
    END;
END;
UPDATE Aircraft
SET model = 'TU161' WHERE capacity = 100
GO

--error but no threat
/*UPDATE Aircraft
SET model = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' WHERE capacity = 10
GO*/
SELECT * FROM Aircraft
go
IF OBJECT_ID(N'Delete_Aircraft',N'TR') IS NOT NULL
	DROP TRIGGER Delete_Aircraft
go
if OBJECT_ID(N'DeleteTable') is NOT NULL
	DROP TABLE DeleteTable;
go

CREATE TABLE DeleteTable(
    registration_number INT,
    aviacompany NVARCHAR(40),
);
go

CREATE TRIGGER Delete_Aircraft
ON Aircraft
AFTER DELETE
AS
BEGIN
    INSERT INTO DeleteTable
	(registration_number, aviacompany)
    SELECT registration_number, aviacompany
    FROM deleted;
	IF EXISTS (
        SELECT 1
        FROM deleted
        WHERE aviacompany = 'American Airlines'
    ) 
	THROW 50005, 'Самолеты American Airlines нельзя удалить. Это может сделать только представитель компании', 101;
END;
INSERT INTO AirCraftView
	(registration_number,model, capacity, aviacompany)
VALUES (110,'SU901', 200, 'American Airlines')
--ошибка
--DELETE FROM Aircraft WHERE registration_number=110
--ок
--DELETE FROM Aircraft WHERE registration_number=4
SELECT * FROM Aircraft;
GO

--Для представления пункта 2 задания 7 создать триггеры на вставку, удаление и добавление,
--обеспечивающие возможность выполнения операций с данными непосредственно через представление.

if OBJECT_ID(N'PassengersBase',N'U') is NOT NULL
	DROP TABLE PassengersBase;
go
if OBJECT_ID(N'PassengersDetails',N'U') is NOT NULL
	DROP TABLE PassengersDetails;
go

CREATE TABLE PassengersBase (
	passport_number int PRIMARY KEY NOT NULL,
	email VARCHAR(256) UNIQUE NOT NULL,
);
go
CREATE TABLE PassengersDetails (
	passport_number int PRIMARY KEY NOT NULL,
	first_name VARCHAR(40) NOT NULL,
	last_name VARCHAR(40) NOT NULL,
	phone CHAR(11) NULL,
);
go

INSERT INTO PassengersDetails (passport_number, first_name, last_name, phone)
VALUES
    (1, 'Andrew','Right','1234567891'),
    (2, 'John','Owen','1564567891')
GO
INSERT INTO PassengersBase (passport_number, email)
VALUES
    (1, 'user1@mail.com'),
    (2, 'user2@mail.com')
go
select * from PassengersDetails
go
IF OBJECT_ID(N'PassengersView', N'V') IS NOT NULL
    DROP VIEW PassengersView;
GO

CREATE VIEW PassengersView  
AS
SELECT 
    d.passport_number, 
    d.first_name, 
    d.last_name, 
    d.phone,
    b.email
FROM 
    dbo.PassengersDetails d
INNER JOIN  
    dbo.PassengersBase b ON b.passport_number = d.passport_number;
GO
select * from PassengersView
go
IF OBJECT_ID(N'Passengers_Insert', N'TR') IS NOT NULL
    DROP TRIGGER Passengers_Insert;
GO

CREATE TRIGGER Passengers_Insert
ON dbo.PassengersView
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO dbo.PassengersBase (passport_number, email)
    SELECT I.passport_number, I.email
    FROM inserted AS I

    INSERT INTO dbo.PassengersDetails (passport_number, first_name, last_name, phone)
    SELECT I.passport_number, I.first_name, I.last_name, I.phone
    FROM inserted AS I
END;
GO
INSERT INTO PassengersView (passport_number, first_name, last_name, phone, email)
VALUES
    (7, 'Dilan','Hofman','1234567891' ,'user7@mail.com')
GO

-- НЕ вставится тк есть такой (Но ошибки не будет)
/*INSERT INTO PassengersView (passport_number, first_name, last_name, phone, email)
VALUES
    (3, 'Eric','Right','1234567891' ,'user1@mail.com')
GO*/
--DELETE FROM PassengersView WHERE passport_number=3
select * from PassengersView
go

IF OBJECT_ID(N'Passengers_Delete', N'TR') IS NOT NULL
    DROP TRIGGER Passengers_Delete;
GO

CREATE TRIGGER Passengers_Delete
ON PassengersView
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @passport_number INT;

    DECLARE deleted_cursor CURSOR FOR
    SELECT passport_number FROM deleted;

    OPEN deleted_cursor;
    FETCH NEXT FROM deleted_cursor INTO @passport_number;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DELETE FROM PassengersBase 
        WHERE passport_number = @passport_number;

        DELETE FROM PassengersDetails 
        WHERE passport_number = @passport_number;

        PRINT 'Пассажир с номером паспорта ' + CAST(@passport_number AS VARCHAR) + ' был удален.';

        FETCH NEXT FROM deleted_cursor INTO @passport_number;
    END;

    CLOSE deleted_cursor;
    DEALLOCATE deleted_cursor;
END;
GO

DELETE from PassengersView where passport_number=3
go
select * from PassengersDetails
go
select * from PassengersBase
go

IF OBJECT_ID(N'Passengers_Update', N'TR') IS NOT NULL
    DROP TRIGGER Passengers_Update;
GO

CREATE TRIGGER Passengers_Update
ON PassengersView
INSTEAD OF UPDATE
AS
BEGIN
	if UPDATE(passport_number)

		THROW 50003, 'passport_number cannot be updated', 3;
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE LEN(phone) <> 11
    )
    BEGIN
        THROW 50001, 'Номер телефона должен содержать ровно 11 цифр', 1;
    END
    

	UPDATE b
	SET b.email = i.email
	FROM PassengersBase b
	INNER JOIN inserted i ON b.passport_number = i.passport_number;

	UPDATE d
	SET d.first_name = i.first_name,
		d.last_name = i.last_name,
		d.phone = i.phone
	FROM PassengersDetails d
	INNER JOIN inserted i ON d.passport_number = i.passport_number;

END;
GO


select * from PassengersView
go
INSERT INTO PassengersView (passport_number, first_name, last_name, phone, email)
VALUES
    (5, 'Eric','Stanford','6565757' ,'user5@mail.com')
GO
UPDATE PassengersView
SET passport_number=9, last_name = 'fggjhg',phone= '88003933339',email = 'another80@mail.com' WHERE passport_number = 5
GO

select * from PassengersBase
go
/* ERROR
UPDATE PassengersView
SET phone = '6565757' WHERE passport_number = 5
GO
*/