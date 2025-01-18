USE master;
GO
/*

соединение таблиц (INNER JOIN / LEFT JOIN / RIGHT JOIN / FULL OUTER JOIN);

–
вложенные запросы.
*/
IF DB_ID (N'lab11') IS NOT NULL
DROP DATABASE lab11;
GO

CREATE DATABASE lab11
ON
(
	NAME = lab11dat,
	FILENAME = 'C:\DB\lab11_dat.mdf', 
	SIZE = 5,
	MAXSIZE = 20, 
	FILEGROWTH = 5
)
LOG ON
(
	NAME = lab8_Log,
	FILENAME = 'C:\DB\lab11_log.ldf',
	SIZE = 5MB,
	MAXSIZE = 25MB,
	FILEGROWTH = 5MB
)
GO

USE lab11
GO
DROP TABLE IF EXISTS Tickets;
DROP TABLE IF EXISTS Seats;
go
DROP TABLE IF EXISTS Aircrafts;
DROP TABLE IF EXISTS Flight;
DROP TABLE IF EXISTS Passengers;
GO

CREATE TABLE Aircrafts
(
    registration_number NVARCHAR(7) PRIMARY KEY NOT NULL,
    model NVARCHAR(40) NOT NULL,
    capacity int NOT NULL,
    aviacompany NVARCHAR(40) NOT NULL
);
go
CREATE TABLE Passengers
(
    passport_number int PRIMARY KEY NOT NULL,
	first_name NVARCHAR(40) NOT NULL,
	last_name NVARCHAR(40) NOT NULL,
	phone NVARCHAR(40) NULL,
	email CHAR(256) UNIQUE NOT NULL
);
go

CREATE INDEX idx_email
    ON Passengers (email);
go
CREATE TABLE Flight (
	flight_number int NOT NULL,
	departure_date date  NOT NULL, CHECK (departure_date>'2000-12-30' AND departure_date<'2070-12-30'),
	departure_time time NOT NULL,
	arrival_date date  NOT NULL, CHECK (arrival_date>'2000-12-30' AND arrival_date<'2070-12-30'),
	arrival_time time NOT NULL,
	departure_airport char(3) NOT NULL DEFAULT ('MSK'), 
	arrival_airport char(3) NOT NULL,
	gate int NOT NULL,
	registration_number NVARCHAR(7) NOT NULL,
	FOREIGN KEY (registration_number) REFERENCES Aircrafts (registration_number),
	CONSTRAINT checkTicket CHECK (departure_date<=arrival_date AND departure_date >= GETDATE()),
	PRIMARY KEY (flight_number, departure_date)
);
go

CREATE TABLE Seats(
    seat_number nvarchar(3) NOT NULL,
    class int NOT NULL DEFAULT 0,
    registration_number NVARCHAR(7) NOT NULL,
    PRIMARY KEY (seat_number, registration_number),
    FOREIGN KEY (registration_number) REFERENCES Aircrafts (registration_number)
);
GO

CREATE TABLE Tickets (
    ticket_id int IDENTITY(1,1) PRIMARY KEY NOT NULL,
    flight_number int NOT NULL,
    departure_date date NOT NULL,
    seat_number nvarchar(3) NOT NULL,
    registration_number NVARCHAR(7) NOT NULL,
    passport_number int NOT NULL,
    MealInfo bit NOT NULL,
    BaggageInfo bit NOT NULL,
    Paid bit NOT NULL,
    FOREIGN KEY (flight_number, departure_date) REFERENCES Flight (flight_number, departure_date),
    FOREIGN KEY (seat_number, registration_number) REFERENCES Seats (seat_number, registration_number),
    FOREIGN KEY (passport_number) REFERENCES Passengers (passport_number)
);
GO

DROP TRIGGER IF EXISTS InsertAircrafts;
go
CREATE TRIGGER InsertAircrafts ON Aircrafts
AFTER INSERT
AS
	BEGIN
		-- Вставляем места для каждого нового самолета
		INSERT INTO Seats (registration_number, class, seat_number)
		SELECT 
			registration_number,
			class,
			seat_number
		FROM (
			SELECT registration_number, 1 AS class, '1A' AS seat_number FROM inserted
			UNION ALL
			SELECT registration_number, 2 AS class, '2B' AS seat_number FROM inserted
			UNION ALL
			SELECT registration_number, 1 AS class, '4B' AS seat_number FROM inserted
		) AS SeatsToInsert
		WHERE NOT EXISTS (
			SELECT 1 FROM Seats 
			WHERE Seats.registration_number = SeatsToInsert.registration_number 
			AND Seats.seat_number = SeatsToInsert.seat_number
		);
	END

GO
DROP TRIGGER IF EXISTS DeleteAircrafts;
go

CREATE TRIGGER DeleteAircrafts 
ON Aircrafts
INSTEAD OF DELETE
AS
BEGIN
    -- Удаляем места, связанные с самолетами
    DELETE FROM Seats 
    WHERE registration_number IN (SELECT registration_number FROM deleted);

    --удаляем самолеты
    DELETE FROM Aircrafts 
    WHERE registration_number IN (SELECT registration_number FROM deleted);
END
GO

DROP TRIGGER IF EXISTS DeletePassenger;
go

CREATE TRIGGER DeletePassenger
ON Passengers
INSTEAD OF DELETE
AS
BEGIN
    -- Удаляем билеты
    DELETE FROM Tickets 
    WHERE passport_number IN (SELECT passport_number FROM deleted);

    --удаляем пассажиров
    DELETE FROM Passengers 
    WHERE passport_number IN (SELECT passport_number FROM deleted);
END
GO
INSERT INTO Aircrafts
    (registration_number,model, capacity, aviacompany)
VALUES
    (1,'Bombardier', 300, 'Airflot'),
	(2,'Bombardier1', 400, 'S7'),
	(3,'Bombardier2', 300, 'Airflot'),
	(4,'Bombardier3', 100, 'American Airlines')
go
select * from Aircrafts
go
DELETE FROM Aircrafts where registration_number=4
select * from Seats
go
select * from Tickets
INSERT INTO Flight(flight_number,departure_date,departure_time,arrival_date,arrival_time,arrival_airport,gate,registration_number)
VALUES 
	(2, CONVERT(date,'2025-08-14'), CONVERT(time,'10:12'), CONVERT(date,'2025-08-15'), CONVERT(time,'19:12'),'TUR', 2,3),
	(1,CONVERT(date,'2025-05-14'), CONVERT(time,'13:12'), CONVERT(date,'2025-05-15'), CONVERT(time,'15:12'),'FRA', 2,3),
	(2, CONVERT(date,'2025-05-14'), CONVERT(time,'16:12'), CONVERT(date,'2025-05-15'), CONVERT(time,'19:12'),'FRA', 12,4)
INSERT INTO Passengers
    (passport_number,first_name, last_name,phone,email)
VALUES
    (1, 'Deny','Richards','4985678543','users7@mail.ru'),
	(3, 'Eric','Tomson','1345678','users3@mail.ru'),
	(4, 'Ann','Stanson','34567','users4@mail.ru')
go
INSERT INTO Tickets
    (flight_number,departure_date,seat_number ,registration_number,passport_number,MealInfo, BaggageInfo,Paid)
VALUES
	(1, CONVERT(date,'2025-05-14'),'1A',3,1,1,1,0),
	(2, CONVERT(date,'2025-08-14'),'2B',3,3,1,1,0),
	(2, CONVERT(date,'2025-05-14'),'4B',4,4,1,1,1)

go
DROP FUNCTION IF EXISTS CalculateTicketPrice
go
CREATE FUNCTION CalculateTicketPrice
(
    @MealInfo BIT,
    @BaggageInfo BIT,
    @Paid BIT
)
RETURNS INT
AS
BEGIN
    DECLARE @BasePrice INT = 100; -- Базовая стоимость
    DECLARE @MealPrice INT = 20;   -- Доплата за еду
    DECLARE @BaggagePrice INT = 30; -- Доплата за багаж
    DECLARE @Discount INT = 10;     -- Скидка

    DECLARE @TotalPrice INT;

    SET @TotalPrice = @BasePrice;

    IF @MealInfo = 1
    BEGIN
        SET @TotalPrice = @TotalPrice + @MealPrice;
    END

    IF @BaggageInfo = 1
    BEGIN
        SET @TotalPrice = @TotalPrice + @BaggagePrice;
    END

    IF @Paid = 1
    BEGIN
        SET @TotalPrice = @TotalPrice - @Discount;
    END
    RETURN @TotalPrice;
END;
go
DROP VIEW if exists InfoForPersonal
go
CREATE VIEW InfoForPersonal AS
	SELECT
		flight_number,
		departure_date,
		seat_number,
		MealInfo,
		BaggageInfo,
		Paid,
		dbo.CalculateTicketPrice(MealInfo, BaggageInfo, Paid) AS TotalPrice
	FROM Tickets;
go

select * from InfoForPersonal


SELECT * FROM Tickets;
SELECT * FROM Seats;
SELECT * FROM Aircrafts;
SELECT * FROM Passengers;

DELETE FROM Passengers WHERE email='users1@mail.ru';

UPDATE Aircrafts SET model='TU160' WHERE registration_number=2;
SELECT * FROM Aircrafts;

SELECT DISTINCT last_name FROM Passengers

-- JOINы
SELECT A.passport_number,A.email, B.ticket_id, B.Paid FROM Passengers as A RIGHT JOIN Tickets as B ON a.passport_number=B.passport_number
SELECT A.passport_number,A.email, B.ticket_id, B.Paid FROM Passengers as A FULL OUTER JOIN Tickets as B ON a.passport_number=B.passport_number
SELECT A.passport_number,A.email, B.ticket_id, B.Paid FROM Passengers as A INNER JOIN Tickets as B ON a.passport_number=B.passport_number
SELECT A.passport_number,A.email, B.ticket_id, B.Paid FROM Passengers as A LEFT JOIN Tickets as B ON a.passport_number=B.passport_number


SELECT * FROM Passengers WHERE phone IS NULL
SELECT * FROM Passengers WHERE phone IS NOT NULL

SELECT * FROM Passengers WHERE last_name LIKE '%son'
--Make discount for next time
SELECT * FROM InfoForPersonal WHERE TotalPrice BETWEEN 100 AND 145 ORDER BY flight_number DESC

SELECT * FROM Passengers WHERE email IN ('users3@mail.ru','users1@mail.ru')
-- EXISTS кто купил билет
SELECT * FROM Passengers WHERE EXISTS(SELECT * FROM Tickets WHERE Tickets.Paid=1)

SELECT MealInfo, COUNT(*) as count FROM InfoForPersonal GROUP BY MealInfo

SELECT flight_number, AVG(TotalPrice) AS avg_price 
FROM InfoForPersonal 
GROUP BY flight_number 
HAVING AVG(TotalPrice) > 145;

SELECT * FROM InfoForPersonal ORDER BY TotalPrice
SELECT * FROM InfoForPersonal ORDER BY TotalPrice ASC
SELECT * FROM InfoForPersonal ORDER BY TotalPrice DESC


SELECT flight_number, SUM(CONVERT(int,MealInfo)) as sum_meals FROM Tickets GROUP BY flight_number
SELECT flight_number, MIN(CONVERT(int,MealInfo)) as min_meals FROM Tickets WHERE departure_date=CONVERT(date,'2025-05-14') GROUP BY flight_number
SELECT flight_number, MAX(CONVERT(int,MealInfo)) as max_meals FROM Tickets WHERE departure_date=CONVERT(date,'2025-05-14') GROUP BY flight_number

SELECT * FROM Tickets WHERE departure_date = CONVERT(date,'2025-05-14')
UNION 
SELECT * FROM Tickets WHERE departure_date = CONVERT(date,'2025-08-14')
ORDER BY ticket_id DESC
GO


SELECT * FROM Tickets WHERE departure_date = CONVERT(date,'2025-05-14')
UNION ALL
SELECT * FROM Tickets WHERE departure_date = CONVERT(date,'2025-08-14')
ORDER BY ticket_id DESC
GO

SELECT * FROM Tickets WHERE departure_date = CONVERT(date,'2025-05-14')
EXCEPT
SELECT * FROM Tickets WHERE departure_date = CONVERT(date,'2025-08-14')
GO


SELECT * FROM Tickets WHERE departure_date = CONVERT(date,'2025-05-14')
INTERSECT
SELECT * FROM Tickets WHERE departure_date = CONVERT(date,'2025-08-14')
GO

--Окупится?
SELECT flight_number
FROM InfoForPersonal
WHERE TotalPrice > (
    SELECT SUM(CONVERT(int,MealInfo))
    FROM Tickets
    WHERE flight_number = InfoForPersonal.flight_number
);