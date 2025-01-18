use AirlineDB;
go

if OBJECT_ID(N'AirCraftView',N'V') is NOT NULL
	DROP VIEW AirCraftView;
go

CREATE VIEW AirCraftView AS
	SELECT *
	FROM AirCraft
go

SELECT * FROM AirCraftView
go

if OBJECT_ID(N'SeatView',N'V') is NOT NULL
	DROP VIEW SeatView;
go
-- Создать представление на основе полей связанных таблиц
CREATE VIEW SeatView AS
	SELECT p.class,p.registration_number AS seat_registration_number, v.registration_number AS aircraft_registration_number,v.model,v.capacity,v.aviacompany
	FROM Seats as p INNER JOIN AirCraft as v ON p.registration_number = v.registration_number
	--WITH CHECK OPTION 
go

SELECT * FROM SeatView
go

-- Создать индекс таблицы + дополнительные неключевые поля

IF EXISTS (SELECT * FROM sys.indexes WHERE name = N'Seat_Idx')  
    DROP INDEX Seat_Idx ON Seats;  
go
---индекс на столбце seat_number и включает в индекс дополнительные столбцы class и registration_number
CREATE INDEX  Seat_Idx  
    ON Seats (registration_number)
	INCLUDE (class);--,registration_number);
go

select registration_number,class from Seats where registration_number=1
select * from Seats where class=1
go

if OBJECT_ID(N'AircraftIndexView',N'V') is NOT NULL
	DROP VIEW AircraftIndexView;
go
CREATE VIEW AircraftIndexView 
WITH SCHEMABINDING 
AS
	SELECT registration_number,model,capacity,aviacompany
	FROM dbo.Aircraft
	WHERE capacity > 100;
go
CREATE UNIQUE CLUSTERED INDEX Idx_Air ON AircraftIndexView (
    registration_number
);
SELECT * FROM AircraftIndexView
go