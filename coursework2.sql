-- 1. Выбираем автора и его библиографию. 

USE home_library;

SELECT a.name AS 'Автор', b.name AS 'Произведение', b.`year` AS 'Год выпуска' 
FROM bibliography b 
JOIN bibliography_author ba  ON b.id  = ba.bibliography_id 
JOIN author a ON a.id = ba.author_id 
WHERE a.id = 7
ORDER BY b.`year`;

-- 2. Выбираем ТОП-3 автора, произведений которого больше всего в библиотеке.

SELECT a.name AS 'Автор', COUNT(*) AS 'Количество произведений'
FROM bibliography b 
JOIN bibliography_author ba  ON b.id  = ba.bibliography_id 
JOIN author a ON a.id = ba.author_id 
GROUP BY a.name
ORDER BY COUNT(*) DESC
LIMIT 4;

-- 3. Выбираем самую популярную серию книг в библиотеке.
-- a)
SELECT bs.name AS 'Серия', COUNT(*) AS 'Количество книг'
FROM books b 
JOIN book_series bs ON bs.id = b.book_series_id 
GROUP BY bs.name
ORDER BY COUNT(*) DESC
LIMIT 6;

-- б)
SELECT (SELECT name FROM book_series WHERE book_series_id = book_series.id) AS 'Серия', COUNT(*) AS 'Количество книг'
FROM books 
GROUP BY book_series_id
ORDER BY COUNT(*) DESC
LIMIT 3;

-- 4. Определяем сумму затраченных средств на библиотеку.
SELECT SUM(price) AS 'Потрачено'
FROM books b;

-- 5. Опрделяем книг какого издательства больше всего в библиотеке.

SELECT ph.name AS 'Издательство', COUNT(*) AS 'Количество книг'
FROM books b 
JOIN publishing_house ph ON ph.id = b.publishing_house_id
GROUP BY ph.name
ORDER BY COUNT(*) DESC
LIMIT 3;

-- 6. Определяем книги, которые написаны в сооавторстве.

SELECT b.title AS 'Книга', COUNT(*) AS 'Количество авторов'
FROM books b 
JOIN author_books ab  ON b.id = ab.books_id 
JOIN author a ON a.id = ab.author_id 
GROUP BY b.title
HAVING COUNT(*)> 1
ORDER BY COUNT(*) DESC;

-- 7. Ищем произведение и в какой книге оно находится.

SELECT b.name AS 'Произведение',  b2.title AS 'Книга'
FROM bibliography b 
JOIN bibliography_books bb ON bb.bibliography_id = b.id
JOIN books b2 ON b2.id = bb.books_id 
WHERE b.name REGEXP 'скара';

-- Можно предположить, что название произведений может повторяться у разных авторов. 
-- Джойним авторов для исключения данной ситуации.

SELECT a.name AS 'Автор', b.name AS 'Произведение',  b2.title AS 'Книга'
FROM bibliography b 
JOIN bibliography_books bb ON bb.bibliography_id = b.id
JOIN books b2 ON b2.id = bb.books_id 
JOIN author_books ab ON ab.books_id = b2.id
JOIN author a ON ab.author_id = a.id 
WHERE b.name REGEXP '^скара';

-- 8. Должник.
SELECT CONCAT (o.name,'  ' ,o.lastname) AS 'Должник'
FROM leasing l 
JOIN owner o ON o.id = l.who_read 
WHERE rental_finish_date > NOW();

-- Представление №1

DROP VIEW IF EXISTS composition;
CREATE VIEW composition AS
	SELECT id, title 
	FROM books;

SELECT title
FROM composition c 
WHERE id BETWEEN 10 AND 19;

-- Представление №2
-- 7 задание переделываем с упрощением.

DROP VIEW IF EXISTS mybook;
CREATE VIEW mybook AS
SELECT a.name AS 'Автор', b.name AS 'Произведение',  b2.title AS 'Книга'
FROM bibliography b 
JOIN bibliography_books bb ON bb.bibliography_id = b.id
JOIN books b2 ON b2.id = bb.books_id 
JOIN author_books ab ON ab.books_id = b2.id
JOIN author a ON ab.author_id = a.id;

SELECT Автор, Произведение, Книга
FROM mybook
WHERE Произведение REGEXP 'Остров';

-- Хранимая Процедура №1. Процедура для выбора книги на выходные.

DROP PROCEDURE IF EXISTS home_library.page;

DELIMITER $$
$$
CREATE PROCEDURE home_library.page (a INT)
BEGIN
	SELECT title AS 'Что почитать?'
		FROM books 
		WHERE pages < a;
END$$
DELIMITER ;


CALL page(300);

-- Процедура №2. Переделываем первый скрипт.

DROP PROCEDURE IF EXISTS home_library.select_author;

DELIMITER $$
$$
CREATE PROCEDURE home_library.select_author(a BIGINT)
BEGIN
	SELECT a.name AS 'Автор', b.name AS 'Произведение', b.`year` AS 'Год выпуска' 
	FROM bibliography b 
	JOIN bibliography_author ba  ON b.id  = ba.bibliography_id 
	JOIN author a ON a.id = ba.author_id 
	WHERE a.id = a
	ORDER BY b.`year`;
END$$
DELIMITER ;

CALL home_library.select_author (2);

-- Триггер №1. Обязательное заполнение года выпуска книги.

USE home_library;

DELIMITER $$
$$
CREATE TRIGGER check_year
BEFORE INSERT
ON bibliography FOR EACH ROW
BEGIN 
	IF NEW.year is NULL THEN
		SIGNAL SQLSTATE  '45000' SET message_text = 'Заполните год выпуска произведения';
	END IF;
END
$$
DELIMITER ;

INSERT INTO bibliography (name)
VALUES ('Золотая корона' );

-- Триггер №2. На изменение поля year.

DELIMITER $$
$$
CREATE TRIGGER year_update
BEFORE UPDATE
ON bibliography FOR EACH ROW
BEGIN 
	IF NEW.year is NULL THEN
		SIGNAL SQLSTATE  '45000' SET message_text = 'Заполните год выпуска произведения';
	END IF;
END$$
DELIMITER ;