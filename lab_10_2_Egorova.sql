USE AirlineDB; 
if OBJECT_ID(N'PassengersView',N'V') is NOT NULL
	DROP VIEW PassengersView;
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
INSERT INTO Passengers (passport_number, first_name, last_name, phone, email)
VALUES
    (1, 'Andrew','Right','1234567891' ,'user1@mail.com'),
    (2, 'John','Owen','1564567891' ,'user2@mail.com')
GO
select * from Passengers
go
-- ВТОРАЯ ТРАНЗАКЦИЯ
/*
1. READ UNCOMMITTED:
	Это самый слабый уровень изоляции, когда транзакция может видеть результаты других транзакций, даже если они ещё не закоммичены.
*/
-- Set isolation level
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--Dirty Read - когда данные, которые я прочитала, кто-то может откатить ещё до того, как я завершу свою транзакцию.

-- При старте у Andrew фамилия Right
--BEGIN TRANSACTION;

--Вторая транзакция
BEGIN TRANSACTION;
--Меняем фамилию Andrew => Leavis
UPDATE Passengers SET last_name = 'Leavis' WHERE passport_number = 1;

--SELECT * FROM Passengers WHERE passport_number = 1; --Вернет с новой фамилией (даже без коммита)
--Здесь все еще фамилия Leavis
--COMMIT TRANSACTION;
ROLLBACK;

--Non‑repeatable Read - данные, которые я прочитала, кто‑то может изменить до того, как я завершу транзакцию
--можно прочитать одни данные в одной транзакции в разное время и получить разный результат, потому что кто-то параллельно изменил данные.
-- При старте у Andrew фамилия Right
--BEGIN TRANSACTION;

--SELECT * FROM Passengers WHERE passport_number = 1; --Вернет со старой фамилией
-- Тут можем что-то делать со старым хначением
--Вторая транзакция
BEGIN TRANSACTION;
--Меняем фамилию Andrew => Leavis
UPDATE Passengers SET last_name = 'Leavis' WHERE passport_number = 1;
COMMIT TRANSACTION;
--COMMIT TRANSACTION; 

--Phantom Read — когда ряд данных, которые прочитаны, кто‑то может изменить до того, как завершена транзакция

--BEGIN TRANSACTION;

--SELECT COUNT(*) FROM Passengers WHERE first_name = 'Andrew'; --Вернет 1
-- Тут можем что-то делать c информацией что Andrew только один
--Вторая транзакция
BEGIN TRANSACTION;
--Добавляем еще одного Andrew
INSERT INTO Passengers (passport_number, first_name, last_name, phone, email)
VALUES
    (3, 'Andrew','Watson','356789876' ,'user3@mail.com');
  
COMMIT TRANSACTION;
--COMMIT TRANSACTION; 
--К моменту заыершения транзакции уже 2 Andrew, а все операции только с 1



--READ COMMITTED
/*
транзакция может читать только те изменения в других параллельных транзакциях,
которые уже были закоммичены. Помогает от грязного чтения, но не от неповторяющегося чтения и от фантомного чтения
*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- При старте transaction1 у Andrew фамилия Leavis
--BEGIN TRANSACTION;

--Вторая транзакция
BEGIN TRANSACTION;
--Меняем фамилию Andrew => Jason
UPDATE Passengers SET last_name = 'Menson' WHERE passport_number = 1;
WAITFOR DELAY '00:00:03';
SELECT * FROM Passengers; 
COMMIT TRANSACTION; 

SELECT * FROM Passengers; -- с новой фамилией
--COMMIT TRANSACTION;

--Non‑repeatable Read - данные, которые я прочитала, кто‑то может изменить до того, как я завершу транзакцию
--можно прочитать одни данные в одной транзакции в разное время и получить разный результат, потому что кто-то параллельно изменил данные.
-- При старте у Andrew фамилия Right
--BEGIN TRANSACTION;

--SELECT * FROM Passengers WHERE passport_number = 1; --Вернет со старой фамилией
-- Тут можем что-то делать со старым хначением
--Вторая транзакция
BEGIN TRANSACTION;
--Меняем фамилию Andrew => Travis
UPDATE Passengers SET last_name = 'Travis' WHERE passport_number = 1;
COMMIT TRANSACTION;
--COMMIT TRANSACTION; 


--Phantom Read — когда ряд данных, которые прочитаны, кто‑то может изменить до того, как завершена транзакция

--BEGIN TRANSACTION;

--SELECT COUNT(*) FROM Passengers WHERE first_name = 'Andrew'; --Вернет 1
-- Тут можем что-то делать c информацией что Andrew только один
--Вторая транзакция
BEGIN TRANSACTION;
--Добавляем еще одного Andrew
INSERT INTO Passengers (passport_number, first_name, last_name, phone, email)
VALUES
    (5, 'Andrew','Harper','356789876' ,'user5@mail.com');
  
COMMIT TRANSACTION;
--COMMIT TRANSACTION; 
--К моменту заыершения транзакции уже 2 Andrew, а все операции только с 1

--REPEATABLE READ
/*
Этот уровень означает, что пока транзакция не завершится, никто параллельно не может изменять или удалять строки,
которые транзакция уже прочитала. 
Cпасает и от грязного чтения, и от неповторяющегося чтения, но всё ещё мы не решаем проблему фантомного чтения.
*/
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

--Dirty Read - когда данные, которые я прочитала, кто-то может откатить ещё до того, как я завершу свою транзакцию.

-- При старте у Andrew фамилия Right
--BEGIN TRANSACTION;
--SELECT * FROM Passengers;
--Вторая транзакция
BEGIN TRANSACTION;
--Меняем фамилию Andrew => Scot
UPDATE Passengers SET last_name = 'Scot' WHERE passport_number = 1; --Ждем коммита

--SELECT * FROM Passengers WHERE passport_number = 1; --Вернет с новой фамилией (даже без коммита)
--Здесь все еще фамилия Leavis
--COMMIT TRANSACTION; -- Сначала должны закончить первую транзакцию
COMMIT TRANSACTION;

--Non‑repeatable Read - данные, которые я прочитала, кто‑то может изменить до того, как я завершу транзакцию
--можно прочитать одни данные в одной транзакции в разное время и получить разный результат, потому что кто-то параллельно изменил данные.
-- При старте у Andrew фамилия Right
--BEGIN TRANSACTION;

--SELECT * FROM Passengers WHERE passport_number = 1; --Вернет со старой фамилией
-- Тут можем что-то делать со старым хначением
--Вторая транзакция
BEGIN TRANSACTION;
--Меняем фамилию Andrew => Orson
UPDATE Passengers SET last_name = 'Orson' WHERE passport_number = 1; -- Не выполниться пока не завршится транзакция 1
COMMIT TRANSACTION;
--COMMIT TRANSACTION; 


--Phantom Read — когда ряд данных, которые прочитаны, кто‑то может изменить до того, как завершена транзакция

--BEGIN TRANSACTION;

--SELECT COUNT(*) FROM Passengers WHERE first_name = 'Andrew'; --Вернет 1
-- Тут можем что-то делать c информацией что Andrew только один
--Вторая транзакция
BEGIN TRANSACTION;
--Добавляем еще одного Andrew
INSERT INTO Passengers (passport_number, first_name, last_name, phone, email)
VALUES
    (6, 'Andrew','Stenson','356789876' ,'user6@mail.com');
  
COMMIT TRANSACTION;



--SERIALIZABLE
/*
Он блокирует любые действия, пока запущена транзакция — получается, транзакции идут строго одна за другой 
*/
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
--Dirty Read - когда данные, которые я прочитала, кто-то может откатить ещё до того, как я завершу свою транзакцию.

-- При старте у Andrew фамилия Right
--BEGIN TRANSACTION;
--SELECT * FROM Passengers;
--Вторая транзакция
BEGIN TRANSACTION;
--Меняем фамилию Andrew => Stivenson
UPDATE Passengers SET last_name = 'Stivenson' WHERE passport_number = 1; --Ждем коммита

--SELECT * FROM Passengers WHERE passport_number = 1; --Вернет с новой фамилией (даже без коммита)
--Здесь все еще фамилия Leavis
--COMMIT TRANSACTION; -- Сначала должны закончить первую транзакцию
COMMIT TRANSACTION;

--Non‑repeatable Read - данные, которые я прочитала, кто‑то может изменить до того, как я завершу транзакцию
--можно прочитать одни данные в одной транзакции в разное время и получить разный результат, потому что кто-то параллельно изменил данные.
-- При старте у Andrew фамилия Right
--BEGIN TRANSACTION;

--SELECT * FROM Passengers WHERE passport_number = 1; --Вернет со старой фамилией
-- Тут можем что-то делать со старым хначением
--Вторая транзакция
BEGIN TRANSACTION;
--Меняем фамилию Andrew => Orson
UPDATE Passengers SET last_name = 'Peterson' WHERE passport_number = 1; -- Не выполниться пока не завршится транзакция 1
COMMIT TRANSACTION;
--COMMIT TRANSACTION; 


--Phantom Read — когда ряд данных, которые прочитаны, кто‑то может изменить до того, как завершена транзакция

--BEGIN TRANSACTION;

--SELECT COUNT(*) FROM Passengers WHERE first_name = 'Andrew'; --Вернет 1
-- Тут можем что-то делать c информацией что Andrew только один
--Вторая транзакция
BEGIN TRANSACTION;
--Добавляем еще одного Andrew (Пока первая транзакция не закончится не добавится)
INSERT INTO Passengers (passport_number, first_name, last_name, phone, email)
VALUES
    (10, 'Andrew','Ingarden','4567689876' ,'user10@mail.com');
  
COMMIT TRANSACTION;


