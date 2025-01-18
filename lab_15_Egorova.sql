--—оздать в базах данных пункта 1 задани€ 13 св€занные таблицы.
USE LAB13_1;
GO

IF OBJECT_ID(N'Passengers', N'U') IS NOT NULL
    DROP TABLE Passengers;
GO

CREATE TABLE Passengers (
    passport_number INT PRIMARY KEY NOT NULL,
    first_name VARCHAR(40) NOT NULL,
    last_name VARCHAR(40) NOT NULL,
    phone CHAR(11) NULL,
    email VARCHAR(256) NOT NULL
);
GO

USE LAB13_2;
GO

IF OBJECT_ID(N'FlightInfo', N'U') IS NOT NULL
    DROP TABLE FlightInfo;
GO

CREATE TABLE FlightInfo (
	ticket_id int PRIMARY KEY,
	passport_number int NOT NULL, -- FOREIGN
	departure_date date  NOT NULL,
	departure_time time NOT NULL,
	arrival_date date  NOT NULL,
	arrival_time time NOT NULL,
	departure_airport char(3) NOT NULL DEFAULT ('MSK'), 
	arrival_airport char(3) NOT NULL,
	gate int NOT NULL,
);
go
--—оздать необходимые элементы базы данных
--(представлени€, триггеры), обеспечивающие работу
--с данными св€занных таблиц (выборку, вставку,
--изменение, удаление).
USE LAB13_2;
GO

if OBJECT_ID(N'FlightInfoInsertUpdate',N'TR') is NOT NULL
	DROP TRIGGER FlightInfoInsertUpdate;
go

CREATE TRIGGER FlightInfoInsertUpdate 
ON FlightInfo
AFTER INSERT, UPDATE
AS
    IF EXISTS (
        SELECT 1 FROM inserted WHERE passport_number NOT IN (SELECT passport_number FROM LAB13_1.dbo.Passengers))
    BEGIN
        RAISERROR('ERROR: Passengers does not exist', 15, 3); --об€зан быть св€зан с пассажиром
        ROLLBACK;
    END
GO


USE LAB13_1
GO
IF OBJECT_ID(N'PassengersDelete', N'TR') IS NOT NULL
    DROP TRIGGER PassengersDelete;
GO

CREATE TRIGGER PassengersDelete
ON Passengers
FOR DELETE
AS
BEGIN
    DELETE FROM LAB13_2.dbo.FlightInfo
    WHERE passport_number IN (SELECT passport_number FROM deleted);
END;
GO

IF OBJECT_ID(N'PassengersUpdate', N'TR') IS NOT NULL 
DROP TRIGGER PassengersUpdate; 
GO 

CREATE TRIGGER PassengersUpdate 
ON Passengers 
AFTER UPDATE 
AS 
BEGIN 
    IF UPDATE(passport_number)
    BEGIN
        RAISERROR('ERROR: passport_number cannot be updated.', 16, 1);
        ROLLBACK;
    END
END;


INSERT INTO LAB13_2.dbo.FlightInfo (ticket_id,passport_number,departure_date,departure_time,arrival_date,arrival_time,departure_airport,arrival_airport,gate)
VALUES
(1, 1, CONVERT(date,'2025-05-14'),CONVERT(time,'10:00'),CONVERT(date,'2025-05-14'),CONVERT(time,'13:00'),'FRA','MSK',12),
(2, 2, CONVERT(date,'2025-05-14'),CONVERT(time,'11:00'),CONVERT(date,'2025-05-14'),CONVERT(time,'14:00'),'USA','MSK',12),
(3, 2, CONVERT(date,'2025-05-14'),CONVERT(time,'15:00'),CONVERT(date,'2025-05-14'),CONVERT(time,'18:00'),'USA','MSK',12)
GO
INSERT INTO LAB13_1.dbo.Passengers (passport_number,first_name,last_name,phone,email)
VALUES
(1,'Andrew','Right','1234567891' ,'user1@mail.com'),
(2,'John','Stanson','56787654' ,'user2@mail.com')
SELECT * FROM LAB13_1.dbo.Passengers
SELECT * FROM LAB13_2.dbo.FlightInfo
GO
UPDATE LAB13_1.dbo.Passengers SET first_name='Eric' WHERE passport_number=1
UPDATE LAB13_2.dbo.FlightInfo SET passport_number=1 WHERE ticket_id=3
UPDATE LAB13_1.dbo.Passengers SET passport_number=9 WHERE passport_number=2

DELETE FROM LAB13_1.dbo.Passengers WHERE passport_number=2
