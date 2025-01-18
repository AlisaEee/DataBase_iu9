-- 1. Создать две базы данных на одном экземпляре СУБД SQL Server 2012.
use master;
go
if DB_ID (N'LAB13_1') is not null
drop database LAB13_1;
go
create database LAB13_1
on (
NAME = LAB13_1dat,
FILENAME = 'C:\DB\LAB13_1dat.mdf',
SIZE = 5,
MAXSIZE = 20,
FILEGROWTH = 5
)
log on (
NAME = LAB13_1log,
FILENAME = 'C:\DB\LAB13_1log.ldf',
SIZE = 5,
MAXSIZE = 20,
FILEGROWTH = 5
);
go 

use master;
go
if DB_ID (N'LAB13_2') is not null
drop database LAB13_2;
go
create database LAB13_2
on (
NAME = LAB13_2dat,
FILENAME = 'C:\DB\LAB13_2dat.mdf',
SIZE = 5,
MAXSIZE = 20,
FILEGROWTH = 5
)
log on (
NAME = LAB13_2log,
FILENAME = 'C:\DB\LAB13_2log.ldf',
SIZE = 5,
MAXSIZE = 20,
FILEGROWTH = 5
);
go 

-- 2. Создать в базах данных п.1. горизонтально фрагментированные таблицы.

use LAB13_1;
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
	CONSTRAINT Seq_users_more CHECK (passport_number <= 5)
);
go


use LAB13_2;
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
	CONSTRAINT Seq_users_more CHECK (passport_number > 5)
);
go

-- 3. Создать секционированные представления, 
-- обеспечивающие работу с данными таблиц
-- (выборку, вставку, изменение, удаление).

use LAB13_1;
go

if OBJECT_ID(N'PassengersView',N'V') is NOT NULL
	DROP VIEW PassengersView;
go

CREATE VIEW PassengersView AS
	SELECT * FROM LAB13_1.dbo.Passengers
	UNION ALL
	SELECT * FROM LAB13_2.dbo.Passengers
go

use LAB13_2;
go

if OBJECT_ID(N'PassengersView',N'V') is NOT NULL
	DROP VIEW PassengersView;
go

CREATE VIEW PassengersView AS
	SELECT * FROM LAB13_1.dbo.Passengers
	UNION ALL
	SELECT * FROM LAB13_2.dbo.Passengers
go

INSERT INTO PassengersView VALUES 
	(1, 'Andrew','Right','1234567891' ,'user1@mail.com'),
    (2, 'John','Owen','46456456' ,'user2@mail.com'),
	(3, 'Eric','Right','456456456' ,'user3@mail.com'),
    (4, 'Ithan','Owen','2354546' ,'user4@mail.com'),
	(5, 'Fill','Right','87856544' ,'user5@mail.com'),
    (6, 'Owen','Tomson','25675875' ,'user6@mail.com'),
	(7, 'Jack','Prame','46456456352' ,'user7@mail.com'),
    (8, 'Jane','Lincy','456456642' ,'user8@mail.com')


SELECT * FROM PassengersView;

SELECT * from LAB13_1.dbo.Passengers;
SELECT * from LAB13_2.dbo.Passengers;


DELETE FROM PassengersView WHERE passport_number = 3

SELECT * from LAB13_1.dbo.Passengers;
SELECT * from LAB13_2.dbo.Passengers;


UPDATE PassengersView SET email = 'anotheremail5@gmail.com' WHERE passport_number = 5

 
SELECT * from LAB13_1.dbo.Passengers;
SELECT * from LAB13_2.dbo.Passengers;