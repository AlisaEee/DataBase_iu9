use master;
go
if DB_ID (N'LAB14_1') is not null
drop database LAB14_1;
go
create database LAB14_1
on (
NAME = LAB14_1dat,
FILENAME = 'C:\DB\LAB14_1dat.mdf',
SIZE = 5,
MAXSIZE = 20,
FILEGROWTH = 5
)
log on (
NAME = LAB14_1log,
FILENAME = 'C:\DB\LAB14_1log.ldf',
SIZE = 5,
MAXSIZE = 20,
FILEGROWTH = 5
);
go 

use master;
go
if DB_ID (N'LAB14_2') is not null
drop database LAB14_2;
go
create database LAB14_2
on (
NAME = LAB14_2dat,
FILENAME = 'C:\DB\LAB14_2dat.mdf',
SIZE = 5,
MAXSIZE = 20,
FILEGROWTH = 5
)
log on (
NAME = LAB13_2log,
FILENAME = 'C:\DB\LAB14_2log.ldf',
SIZE = 5,
MAXSIZE = 20,
FILEGROWTH = 5
);
go 
-- 1.Создать в базах данных пункта 1 задания 13 таблицы, содержащие вертикально фрагментированные данные.
use LAB14_1;
go
if OBJECT_ID(N'Tickets',N'U') is NOT NULL
	DROP TABLE Tickets;
go

CREATE TABLE Tickets (
	flight_number int NOT NULL,
	departure_date date  NOT NULL,
	--departure_time time NOT NULL,
	--arrival_date date  NOT NULL,
	--arrival_time time NOT NULL,
	departure_airport char(3) NOT NULL DEFAULT ('MSK'), 
	--arrival_airport char(3) NOT NULL,
	gate int NOT NULL,
	
    PRIMARY KEY (flight_number, departure_date)
);
go

use LAB14_2;
go
if OBJECT_ID(N'Tickets',N'U') is NOT NULL
	DROP TABLE Tickets;
go

CREATE TABLE Tickets (
	flight_number int NOT NULL,
	departure_date date  NOT NULL,
	departure_time time NOT NULL,
	arrival_date date  NOT NULL,
	arrival_time time NOT NULL,
	--departure_airport char(3) NOT NULL DEFAULT ('MSK'), 
	arrival_airport char(3) NOT NULL,
	--gate int NOT NULL,
	
    PRIMARY KEY (flight_number, departure_date)
);
go
-- 2.Создать необходимые элементы базы данных (представления, триггеры), 
-- обеспечивающие работу с данными вертикально фрагментированных таблиц 
-- (выборку, вставку, изменение, удаление). 
if OBJECT_ID(N'TicketsView',N'V') is NOT NULL
	DROP VIEW TicketsView;
go

CREATE VIEW TicketsView AS
    SELECT 
        A.flight_number, 
        A.departure_date, 
        A.departure_time, 
        A.arrival_date, 
        A.arrival_time, 
        B.departure_airport, 
		A.arrival_airport, 
        B.gate
    FROM 
        LAB14_2.dbo.Tickets AS A
    JOIN 
        LAB14_1.dbo.Tickets AS B 
    ON 
        A.flight_number = B.flight_number AND 
        A.departure_date = B.departure_date;
IF OBJECT_ID(N'InsertTicketsView',N'TR') IS NOT NULL
	DROP TRIGGER InsertTicketsView
go

CREATE TRIGGER InsertTicketsView
ON TicketsView
INSTEAD OF INSERT 
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM LAB14_1.dbo.Tickets AS A,
        inserted AS I WHERE A.flight_number = I.flight_number AND A.departure_date = I.departure_date
    )
    BEGIN
         THROW 50006, 'Этот билет уже был добавлен', 103;
    END
    ELSE
    BEGIN
        -- Вставка в первую таблицу
        INSERT INTO LAB14_1.dbo.Tickets(flight_number,departure_date, departure_airport, gate)
        SELECT flight_number,departure_date, departure_airport, gate FROM inserted;

        -- Вставка во вторую таблицу
        INSERT INTO LAB14_2.dbo.Tickets(flight_number,departure_date, departure_time, arrival_date, arrival_time, arrival_airport)
        SELECT flight_number,departure_date, departure_time, arrival_date, arrival_time, arrival_airport FROM inserted;
    END
END
GO

select * from LAB14_1.dbo.Tickets
--ok
INSERT INTO TicketsView (flight_number, departure_date, departure_time, arrival_date, arrival_time, departure_airport, arrival_airport, gate)
VALUES (1, CONVERT(date, '2025-05-14'), CONVERT(time, '13:12'), CONVERT(date, '2025-05-15'), CONVERT(time, '15:12'), 'MSK', 'FRA', 2);
--error (already exists) Этот билет уже был добавлен
--INSERT INTO TicketsView(flight_number, departure_date,departure_time,arrival_date,arrival_time,departure_airport,arrival_airport,gate)
--VALUES 	(1, CONVERT(date,'2025-05-14'), CONVERT(time,'16:12'), CONVERT(date,'2025-05-15'), CONVERT(time,'19:12'),'SPB','FRA', 13)

--ok
INSERT INTO TicketsView(flight_number, departure_date,departure_time,arrival_date,arrival_time,departure_airport,arrival_airport,gate)
VALUES 		(2, CONVERT(date,'2025-05-14'), CONVERT(time,'19:12'), CONVERT(date,'2025-05-15'), CONVERT(time,'21:12'),'MSK','USA', 22)
 --Error: Рейсы в Турцию отменены
--INSERT INTO TicketsView(flight_number,departure_date,departure_time,arrival_date,arrival_time,departure_airport,arrival_airport,gate)
--VALUES 	(1, CONVERT(date,'2025-05-14'), CONVERT(time,'11:12'), CONVERT(date,'2025-05-15'), CONVERT(time,'14:15'),'SPB','TUR', 12)

SELECT * FROM TicketsView
go

IF OBJECT_ID(N'UpdateTicketsView', N'TR') IS NOT NULL
    DROP TRIGGER UpdateTicketsView;
GO

CREATE TRIGGER UpdateTicketsView
ON TicketsView
INSTEAD OF UPDATE
AS
BEGIN
    -- Check for changes in arrival_airport
    IF UPDATE(flight_number)
    BEGIN
        THROW 50008, 'Updating flight_number is not allowed.', 104;
    END;
	IF UPDATE(departure_date)
    BEGIN
        THROW 50008, 'Updating flight_number is not allowed.', 104;
    END;
    UPDATE LAB14_1.dbo.Tickets
    SET departure_airport = U.departure_airport, gate = U.gate
    FROM inserted U
    WHERE LAB14_1.dbo.Tickets.flight_number = U.flight_number AND LAB14_1.dbo.Tickets.departure_date = U.departure_date;

    UPDATE LAB14_2.dbo.Tickets
    SET departure_date = U.departure_date, departure_time = U.departure_time, 
        arrival_date = U.arrival_date, arrival_time = U.arrival_time,
		arrival_airport = U.arrival_airport
    FROM inserted U
    WHERE LAB14_2.dbo.Tickets.flight_number = U.flight_number AND LAB14_2.dbo.Tickets.departure_date = U.departure_date;
END;
GO

--ok
UPDATE TicketsView SET arrival_airport = 'USA', departure_time = CONVERT(time,'10:12') WHERE flight_number = 1
go
SELECT * FROM TicketsView
go
--error
--UPDATE TicketsView SET flight_number = 4 WHERE flight_number = 2
--go

IF OBJECT_ID(N'DeleteTicketsView', N'TR') IS NOT NULL
    DROP TRIGGER DeleteTicketsView;
GO
if OBJECT_ID(N'DeleteTable') is NOT NULL
	DROP TABLE DeleteTable;
go
CREATE TABLE DeleteTable(
    flight_number INT
);
go

CREATE TRIGGER Delete_Aircraft
ON TicketsView
INSTEAD OF DELETE
AS
BEGIN
    INSERT INTO DeleteTable (flight_number)
    SELECT flight_number
    FROM deleted;
	BEGIN
		DELETE T FROM LAB14_1.dbo.Tickets AS T INNER JOIN deleted AS d ON T.flight_number = d.flight_number AND T.departure_date = d.departure_date
		DELETE T FROM LAB14_2.dbo.Tickets AS T INNER JOIN deleted AS d ON T.flight_number = d.flight_number AND T.departure_date = d.departure_date
	END
END;
DELETE FROM TicketsView where flight_number=1
SELECT * from DeleteTable

SELECT * from TicketsView