-- Отображаем базы данных
SELECT name AS DatabaseName FROM sys.databases;

-- Если база данных существует, удаляем её
IF DB_ID(N'AirlineDB') IS NOT NULL 
    DROP DATABASE AirlineDB;
GO

-- Создаем новую базу данных
CREATE DATABASE AirlineDB ON (
    NAME = AirlineDB, 
    FILENAME = 'C:\DB\AirlineDB.mdf',
    SIZE = 10, 
    MAXSIZE = 30,
    FILEGROWTH = 5
) LOG ON (
    NAME = AirlineDB_log,  
    FILENAME = 'C:\DB\AirlineDB_log.log', 
    SIZE = 5,
    MAXSIZE = 20,
    FILEGROWTH = 5
);
GO
use AirlineDB
go
if OBJECT_ID(N'Aircrafts') is NOT NULL
	DROP Table Aircrafts;
go

CREATE TABLE Aircrafts
(
    registration_number NVARCHAR(7) PRIMARY KEY NOT NULL,
    model NVARCHAR(40) NOT NULL,
    capacity int NOT NULL,
    aviacompany NVARCHAR(40) NOT NULL
);
go
-- example
INSERT INTO Aircrafts
    (registration_number, model, capacity, aviacompany)
VALUES
    ('VPBVS', 'Bombardier', 300, 'Airflot')
go

select * from Aircrafts
go

-- Добавление файловой группы и файла данных --
use master;
go

alter database AirlineDB
add filegroup AirlineDB_fg
go

alter database AirlineDB
add file
(
	NAME = AirlineDB_file,
	FILENAME = 'C:\DB\AirlineDB_file.ndf',
	SIZE = 10MB,
	MAXSIZE = 100MB,
	FILEGROWTH = 5MB
)
to filegroup AirlineDB_fg
go

alter database AirlineDB
	modify filegroup AirlineDB_fg default;-- Назначение группой по умолчанию
go

-- Новая таблица

use AirlineDB;
go 
if OBJECT_ID(N'Passengers',N'U') is NOT NULL
	DROP TABLE Passengers;
go

CREATE TABLE Passengers (
	passport_number int PRIMARY KEY NOT NULL,
	first_name VARCHAR(40) NOT NULL,
	last_name VARCHAR(40) NOT NULL,
	phone CHAR(11) NULL,
	email VARCHAR(256) NOT NULL,
);
go
select * from Passengers
go
alter database AirlineDB
	modify filegroup [primary] default;
go

-- удаление

use AirlineDB;
go

drop table Passengers
go

alter database AirlineDB
remove file AirlineDB_file
go

alter database AirlineDB
remove filegroup AirlineDB_fg;
go

-- Создание схемы
use AirlineDB;
go

CREATE SCHEMA airline_schema
go

ALTER SCHEMA airline_schema TRANSFER dbo.Aircrafts
go
DROP TABLE airline_schema.Aircrafts
DROP SCHEMA airline_schema
go