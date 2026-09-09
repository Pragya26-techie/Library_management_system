CREATE DATABASE library_details;
USE library_details;
-- Library Management System
DROP TABLE IF exists branch;
CREATE TABLE branch(branch_id VARCHAR(10) PRIMARY KEY,manager_id VARCHAR(10),branch_address	VARCHAR(60),contact_no VARCHAR(10));
ALTER TABLE branch
MODIFY COLUMN contact_no VARCHAR(20);
DROP TABLE IF exists employees;
CREATE TABLE employees(emp_id VARCHAR(10) PRIMARY KEY,emp_name VARCHAR(50),position VARCHAR(50),salary INT,branch_id VARCHAR(10));
CREATE TABLE books(isbn VARCHAR(20) PRIMARY KEY,book_title VARCHAR(75),category VARCHAR(10),rental_price FLOAT,status VARCHAR(15),author VARCHAR(35),publisher VARCHAR(55));
CREATE TABLE members(member_id VARCHAR(10) PRIMARY KEY,member_name VARCHAR(25),member_address VARCHAR(75),reg_date DATE);
CREATE TABLE issued_status(issued_id VARCHAR(10) PRIMARY KEY,issued_member_id VARCHAR(10),issued_book_name VARCHAR(75),issued_date DATE,issued_book_isbn VARCHAR(25),issued_emp_id VARCHAR(10));
CREATE TABLE return_status
(
            return_id VARCHAR(10) PRIMARY KEY,
            issued_id VARCHAR(30),
            return_book_name VARCHAR(80),
            return_date DATE,
            return_book_isbn VARCHAR(50)
);

-- Foreign key
ALTER TABLE issued_status
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_books
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employees
FOREIGN KEY(issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE employees
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

ALTER TABLE return_status
ADD constraint fk_issued_status
FOREIGN KEY(issued_id)
references issued_status(issued_id);

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM members;
SELECT * FROM issued_status;
SELECT * FROM return_status;

-- Project Task
-- CRUD OPERATION
-- Q1.CREATE A NEW BOOK RECORD--"978-1-60129-456-2",'To Kill a Mockingbird','Classic',6.00,'yes','Harper Lee','J.B Lippincott &Co')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher) VALUE(978-1-60129-456-2,'To Kill a Mockingbird','Classic',6.00,'yes','Harper Lee','J.B Lippincott &Co');

-- Q2.UPDATE an Existing Member's address
UPDATE members
SET member_address="125 orianto,toranto"
WHERE member_id = 'C103';

-- Q3.DELETE A RECORD FROM The issued Status Table --DELETE THE RECORD WITH ISSUED_ID='IS121' FROM the issued_status_table.
DELETE FROM issued_status
WHERE ISSUED_ID='IS121';

-- Q4.Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Q5.List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT issued_member_id,COUNT(issued_id) FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(issued_id) > 1;

-- 3.CTAS(CREATE TABLE AS SELECT)
-- Q6:CREATE SUMAARY TABLES:Use CTAS to generate new tables based on query result - each book and total book_issued_cnt**
CREATE TABLE book_issued_cnt AS
SELECT b.isbn,b.book_title,COUNT(ist.issued_id) AS issue_count
FROM issued_status as ist
JOIN books as b
ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn,b.book_title;

-- 4.DATA ANALYSIS & FINDINGS
-- Q7.Retrieve All Books in a specific Category:
SELECT * FROM books
WHERE category = 'Classic';

-- Q8.Find Total Rental Income by Category:
SELECT SUM(rental_price),category
FROM books
GROUP BY category;

SELECT 
    b.category,
    SUM(b.rental_price),
    COUNT(*)
FROM 
issued_status as ist
JOIN
books as b
ON b.isbn = ist.issued_book_isbn
GROUP BY 1;

SELECT * FROM issued_status;
-- Q9.List Members Who Registered in the Last 180 Days:
SELECT * FROM members
WHERE reg_date >= CURDATE() - INTERVAL 180 DAY;

-- Q10.List Employees with Their Branch Manager's Name and their branch details:
SELECT e1.emp_id,e1.emp_name,e1.position,e1.salary 
FROM employees as e1 
JOIN branch b
ON e1.branch_id = b.branch_id;

-- Q11.Create a Table of Books with Rental Price Above a Certain Threshold:
CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;

-- Q12. Retrieve the List of Books Not Yet Returned
SELECT * FROM issued_status as ist
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;

-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.
SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    -- rs.return_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1;

-- Q4.Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
DELIMITER $$
DROP PROCEDURE IF EXISTS add_return_records $$
CREATE PROCEDURE add_return_records(
IN p_return_id VARCHAR(10),
IN p_issued_id VARCHAR(30)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);
    
    -- Find the book details from issued_status
    SELECT 
      issued_book_isbn,
      issued_book_name
	INTO 
       v_isbn,
       v_book_name
	FROM issued_status
    WHERE issued_id = p_issued_id;
    IF v_isbn IS NULL THEN
       SELECT 'Issued ID not found' AS message;
	ELSE
    -- Insert return record
    INSERT INTO return_status(
        return_id,
        issued_id,
        return_book_name,
        return_date,
        return_book_isbn
    )
	VALUES(
        p_return_id,
        p_issued_id,
        v_book_name,
        CURDATE(),
        v_isbn
    );
   -- Update book status
    UPDATE books
    SET status = 'Yes'
    WHERE isbn = v_isbn;
    SELECT 
        'Book returned succesfully' AS message,
        v_book_name AS book_name,
        v_isbn AS isbn;
   END IF;
END $$
DELIMITER ;
CALL add_return_records('RS138', 'IS135');

