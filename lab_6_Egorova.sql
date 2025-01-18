use master;
use AirlineDB;
go 
if OBJECT_ID(N'Tickets',N'U') is NOT NULL
	DROP TABLE Tickets;
go


-- Создать таблицу с автоинкрементным первичным ключом.
CREATE TABLE Tickets (
	flight_number int IDENTITY(1,1) PRIMARY KEY,
	departure_date date  NOT NULL, CHECK (departure_date>'2000-12-30' AND departure_date<'2070-12-30'),
	departure_time time NOT NULL,
	arrival_date date  NOT NULL, CHECK (arrival_date>'2000-12-30' AND arrival_date<'2070-12-30'),
	arrival_time time NOT NULL,
	departure_airport char(3) NOT NULL DEFAULT ('MSK'), 
	arrival_airport char(3) NOT NULL,
	gate int NOT NULL,
	CONSTRAINT checkTicket CHECK (departure_date<=arrival_date AND departure_date >= GETDATE())
);
go

INSERT INTO Tickets(departure_date,departure_time,arrival_date,arrival_time,arrival_airport,gate)
VALUES (CONVERT(date,'2025-05-14'), CONVERT(time,'13:12'), CONVERT(date,'2025-05-15'), CONVERT(time,'15:12'),'FRA', 2),
		(CONVERT(date,'2025-05-14'), CONVERT(time,'16:12'), CONVERT(date,'2025-05-15'), CONVERT(time,'19:12'),'FRA', 12)
	   -- ошибка
	  -- (CONVERT(date,'2021-05-14'), CONVERT(time,'13:12'), CONVERT(date,'2021-05-10'), CONVERT(time,'15:12'),'FRA', 2),
go

select * from Tickets
go

--Получение identity
/*
@@IDENTITY
Описание: Возвращает последнее значение идентификатора, сгенерированное для столбца с автоинкрементом в текущем сеансе и текущем контексте выполнения.
Область применения: Возвращает значение независимо от того, в каком объекте (таблице) это значение было сгенерировано.
SCOPE_IDENTITY()
Описание: Возвращает последнее значение идентификатора, сгенерированное для столбца с автоинкрементом в текущем сеансе и в текущем контексте выполнения (scope).
Область применения: В отличие от @@IDENTITY, SCOPE_IDENTITY() возвращает значение только для текущего объекта (таблицы). 
IDENT_CURRENT('table_name')
Описание: Возвращает последнее значение идентификатора, сгенерированное для указанной таблицы в любой сессии и в любой области видимости.
Область применения: Это значение не зависит от текущего сеанса или контекста выполнения. Таким образом, оно может возвращать значение, сгенерированное в другой сессии
*/
SELECT SCOPE_IDENTITY() AS TicketsID; --возвращает последнее значение IDENTITY, 
USE AirlineDB;
go
SELECT IDENT_CURRENT('Tickets') as Tickeid_2 --возвращает значение для таблицы, независимо от того, какой сеанс или контекст его создал.
go 
SELECT @@IDENTITY;

-- Создать таблицу с первичным ключом на основе глобального уникального идентификатора
if OBJECT_ID(N'Aircrafts') is NOT NULL
	DROP Table Aircrafts;
go

CREATE TABLE Aircrafts
(
    registration_number UNIQUEIDENTIFIER PRIMARY KEY NOT NULL DEFAULT (NEWID()),
    model NVARCHAR(40) NOT NULL,
    capacity int NOT NULL,
    aviacompany NVARCHAR(40) NOT NULL
);
go
-- example
INSERT INTO Aircrafts
    (model, capacity, aviacompany)
VALUES
    ('Bombardier', 300, 'Airflot')
go

select * from Aircrafts
go
DROP Table Aircrafts;

-- Создать таблицу с первичным ключом на основе последовательности
IF EXISTS (SELECT * FROM sys.sequences WHERE NAME = N'TownSequence' AND TYPE='SO') --"Sequence Object".
DROP SEQUENCE TownSequence
go

CREATE SEQUENCE TownSequence
	START WITH 0
	INCREMENT BY 1
	MAXVALUE 10;
go

if OBJECT_ID(N'TownList',N'U') is NOT NULL
	DROP TABLE TownList;
go

CREATE TABLE TownList (
	element_id int PRIMARY KEY NOT NULL,
	town nchar(50) DEFAULT (N'None'),
	);
go

INSERT INTO TownList(element_id,town)
VALUES (NEXT VALUE FOR DBO.TownSequence,N'Moscow'),
	   (NEXT VALUE FOR DBO.TownSequence,N'Paris'),
	   (NEXT VALUE FOR DBO.TownSequence,N'Madrid')
go

SELECT * From TownList
go
/*
NO ACTION: Это значение по умолчанию. Если родительская запись будет удалена или обновлена, SQL будет генерировать ошибку, если дочерняя запись зависит от нее.
CASCADE: Если родительская запись будет удалена или обновлена, SQL будет автоматически удалить или обновить соответствующие дочерние записи.
SET NULL: Если родительская запись будет удалена или обновлена, SQL будет установить значение внешнего ключа в дочерней записи в NULL.
SET DEFAULT: Если родительская запись будет удалена или обновлена, SQL будет установить значение внешнего ключа в дочерней записи в значение по умолчанию, которое было указано при создании таблицы.
*/
-- NO ACTION| CASCADE | SET NULL | SET DEFAULT

-- Тестирование вариантов действий для ограничений ссылочной целостности
if OBJECT_ID(N'AirCraft') is NOT NULL
	DROP TABLE AirCraft;
go

CREATE TABLE AirCraft
(
    registration_number int PRIMARY KEY NOT NULL,
    model NVARCHAR(40) NOT NULL,
    capacity int NOT NULL,
    aviacompany NVARCHAR(40) NOT NULL
);
go
if OBJECT_ID(N'Seats') is NOT NULL
	DROP TABLE Seats;
go
CREATE TABLE Seats
(
    seat_number nvarchar(3) PRIMARY KEY NOT NULL,
	class int NOT NULL DEFAULT 0,
	registration_number int NULL DEFAULT 2,
	FOREIGN KEY (registration_number) REFERENCES AirCraft (registration_number)
    --ON UPDATE CASCADE 
	--ON UPDATE SET DEFAULT 
	--ON UPDATE SET NULL 
	--ON DELETE SET NULL 
	--ON DELETE SET DEFAULT 
	ON DELETE CASCADE
	--ON DELETE NO ACTION
	--ON UPDATE NO ACTION
);
go
INSERT INTO AirCraft
    (registration_number,model, capacity, aviacompany)
VALUES
    (1,'Bombardier', 300, 'Airflot'),
	(2,'Bombardier1', 400, 'S7'),
	(3,'Bombardier2', 300, 'Airflot'),
	(4,'Bombardier3', 100, 'S7')
go

select * from AirCraft
go
INSERT INTO Seats
    (registration_number,class, seat_number)
VALUES
    (1,1, '9A'),
	(1,2,'17B'),
	(2,1, '10B'),
	(2,2, '7C')
go


--No action + comment all
--DELETE FROM AirCraft WHERE registration_number = 1;
--UPDATE AirCraft
--SET registration_number = 10 WHERE registration_number = 1;

--Cascade Delete + comment ON DELETE CASCADE,DEFAULT, NULL
DELETE FROM Aircraft WHERE registration_number = 1;

---Cascade UPDATE
--UPDATE AirCraft
--SET registration_number = 10 WHERE registration_number = 1;

---UPDATE set Default
--UPDATE AirCraft
--SET registration_number = 10 WHERE registration_number = 1;
---DELETE set Default
--DELETE FROM Aircraft WHERE registration_number = 1;

select * from AirCraft
go
select * from Seats
go
--DROP TABLE Seats;
--DROP TABLE AirCraft;