-- HW4: Books that will change your life
-- Instructions: Run the script "hw4_library_setup.sql" in a ROOT connection
-- This will create a new schema called "library"
-- Write a query that answers each question below.
-- Save this file as HW4_YourFullName.sql and submit

-- Questions 1-12 are 8 points each. Question 13 is worth 4 points.


use library;

-- 1. Which book(s) are Science Fiction books written in the 1960's?
-- List title, author, and year of publication

SELECT b.title, b.author, b.year
FROM book b
JOIN genre g ON b.genre_id = g.genre_id
WHERE g.genre_name = 'Science Fiction' AND b.year BETWEEN 1960 AND 1969
ORDER BY b.title;


-- 2. Which users have borrowed no books?
-- Give name and city they live in
-- Write the query in two ways, once by selecting from only one table
-- and using a subquery, and again by joining two tables together.


-- Method using subquery (4 points)
SELECT u.user_name, u.city
FROM user u
WHERE u.user_id NOT IN (
  SELECT b.user_id
  FROM borrow b
);




-- Method using a join (4 points)
SELECT u.user_name, u.city
FROM user u
LEFT JOIN borrow b ON u.user_id = b.user_id
WHERE b.book_id IS NULL;




-- 3. How many books were borrowed by each user in each month?
-- Your table should have three columns: user_name, month, num_borrowed
-- You may ignore users that didn't borrow any books and months in which no books were borrowed.
-- Sort by name, then month
-- The month(date) function returns the month number (1,2,3,...12) of a given date. This is adequate for output.

SELECT u.user_name, 
       MONTH(b.borrow_dt) AS month, 
       COUNT(b.book_id) AS num_borrowed
FROM borrow b
JOIN user u ON b.user_id = u.user_id
GROUP BY u.user_name, MONTH(b.borrow_dt)
ORDER BY u.user_name, MONTH(b.borrow_dt);




-- 4. How many times was each book checked out?
-- Output the book's title, genre name, and the number of times it was checked out, and whether the book is still in circulation
-- Include books never borrowed
-- Order from most borrowed to least borrowed

SELECT 
    b.title,
    g.genre_name,
    COUNT(br.book_id) AS times_checked_out,
    b.in_circulation
FROM 
    book b
LEFT JOIN genre g ON b.genre_id = g.genre_id
LEFT JOIN borrow br ON b.book_id = br.book_id
GROUP BY 
    b.title,
    g.genre_name,
    b.in_circulation
ORDER BY 
    times_checked_out DESC, 
    b.title;


-- 5. How many times did each user return a book late?
-- Include users that never returned a book late or never even borrowed a book
-- Sort by most number of late returns to least number of late returns (regardless of HOW late the returns were.)


SELECT 
    u.user_name,
    COUNT(CASE WHEN b.return_dt > b.due_dt THEN 1 END) AS late_returns
FROM 
    user u
LEFT JOIN borrow b ON u.user_id = b.user_id AND b.return_dt > b.due_dt
GROUP BY 
    u.user_name
ORDER BY 
    late_returns DESC, 
    u.user_name;


-- 6. How many books of each genre where published after 1950?
-- Include genres that are not represented by any book in our catalog
-- as well as genres for which there are books but none published after 1950.
-- Sort output by number of titles in each genre (most to least)

SELECT 
    g.genre_name,
    COUNT(CASE WHEN b.year > 1950 THEN 1 END) AS num_books_post_1950
FROM 
    genre g
LEFT JOIN book b ON g.genre_id = b.genre_id AND b.year > 1950
GROUP BY 
    g.genre_name
ORDER BY 
    num_books_post_1950 DESC,
    g.genre_name;


-- 7. For each genre, compute a) the number of books borrowed and b) the average
-- number of days borrowed.
-- Includes books never borrowed and genres with no books
-- and in these cases, show zeros instead of null values.
-- Round the averages to one decimal point
-- Sort output in descending order by average
-- Helpful functions: ROUND, IFNULL, DATEDIFF

SELECT 
    g.genre_name,
    COUNT(br.book_id) AS num_books_borrowed,
    ROUND(IFNULL(AVG(DATEDIFF(br.return_dt, br.borrow_dt)), 0), 1) AS avg_days_borrowed
FROM 
    genre g
LEFT JOIN book b ON g.genre_id = b.genre_id
LEFT JOIN borrow br ON b.book_id = br.book_id
GROUP BY 
    g.genre_name
ORDER BY 
    avg_days_borrowed DESC,
    g.genre_name;


-- 8. List all pairs of books published within 10 years of each other
-- Don't include the book with itself
-- Only list (X,Y) pairs where X was published earlier
-- Output the two titles, and the years they were published, the number of years apart they were published
-- Order pairs from those published closest together to farthest

SELECT 
    b1.title AS book1_title,
    b1.year AS book1_year,
    b2.title AS book2_title,
    b2.year AS book2_year,
    ABS(b1.year - b2.year) AS years_apart
FROM 
    book b1
INNER JOIN book b2 ON b1.book_id <> b2.book_id 
    AND ABS(b1.year - b2.year) <= 10
WHERE 
    b1.year < b2.year
ORDER BY 
    years_apart ASC,
    book1_year ASC,
    book1_title ASC;



-- 9. Assuming books are returned completely read,
-- Rank the users from fastest to slowest readers (pages per day)
-- include users that borrowed no books (report reading rate as 0.0)

SELECT
  u.user_name,
  IFNULL(SUM(b.pages) / SUM(DATEDIFF(IFNULL(br.return_dt, CURRENT_DATE), br.borrow_dt)), 0.0) AS reading_rate
FROM
  user u
LEFT JOIN borrow br ON u.user_id = br.user_id
LEFT JOIN book b ON br.book_id = b.book_id
GROUP BY
  u.user_name
ORDER BY
  reading_rate DESC;




-- 10. How many books of each genre were checked out by John?
-- Sort descending by number of books checked out in each genre category.
-- Only include genres where at least two books of that genre were checked out.
-- (Count each time the book was checked out even if the same book was checked out
-- by John more than once.)

SELECT 
  gn.genre_name,
  COUNT(br.book_id) AS num_books_checked_out
FROM 
  user u
JOIN borrow br ON u.user_id = br.user_id
JOIN book b ON br.book_id = b.book_id
JOIN genre gn ON b.genre_id = gn.genre_id
WHERE 
  u.user_name = 'John'
GROUP BY 
  gn.genre_name
HAVING 
  COUNT(br.book_id) >= 2
ORDER BY 
  num_books_checked_out DESC;


-- 11. On average how many books are borrowed per user?
-- Output two averages in one row: one average that includes users that
-- borrowed no books, and one average that excludes users that borrowed no books


SELECT 
  -- Average including users that borrowed no books
  (SELECT COUNT(*) FROM borrow) / (SELECT COUNT(*) FROM user) AS avg_including_no_borrows,
  
  -- Average excluding users that borrowed no books
  (SELECT COUNT(*) FROM borrow) / (SELECT COUNT(DISTINCT user_id) FROM borrow) AS avg_excluding_no_borrows
FROM 
  dual;




-- 12. How much does each user owe the library. Include users owing nothing
-- Factor in the 10 cents per day fine for late returns and how much they have already paid the library
-- HINTS:
--     The DATEDIFF function takes two dates and counts the number of dates between them
--     The IF function, used in a SELECT clause, might also be helpful.  IF(condition, result_if_true, result_if_false)
--     IF functions can be used inside aggregation functions!

SELECT 
  u.user_id,
  u.user_name,
  IFNULL(SUM(IF(DATEDIFF(b.return_dt, b.due_dt) > 0, DATEDIFF(b.return_dt, b.due_dt) * 0.10, 0)) - SUM(p.amount), 0) AS total_owed
FROM 
  user u
LEFT JOIN borrow b ON u.user_id = b.user_id
LEFT JOIN payment p ON u.user_id = p.user_id
GROUP BY 
  u.user_id, 
  u.user_name;




-- 13. (4 points) Which books will change your life?
-- Answer: All books.
-- Select all books.

SELECT * FROM book;

