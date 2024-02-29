

DROP TABLE IF EXISTS likes;
DROP TABLE IF EXISTS tweet_hashtags;
DROP TABLE IF EXISTS follows;
DROP TABLE IF EXISTS tweets;
DROP TABLE IF EXISTS hashtags;
DROP TABLE IF EXISTS users;

-- PART B. Logical Modeling

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    handle VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    profile VARCHAR(255),
    profile_status ENUM('Visible', 'Hidden') NOT NULL
);

CREATE TABLE tweets (
    tweet_id INT AUTO_INCREMENT PRIMARY KEY,
    content VARCHAR(160) NOT NULL,
    timestamp DATETIME NOT NULL,
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE hashtags (
    tag_id INT AUTO_INCREMENT PRIMARY KEY,
    tag_name VARCHAR(50) UNIQUE NOT NULL
);


CREATE TABLE tweet_hashtags (
    tweet_id INT,
    tag_id INT,
    PRIMARY KEY (tweet_id, tag_id),
    FOREIGN KEY (tweet_id) REFERENCES tweets(tweet_id),
    FOREIGN KEY (tag_id) REFERENCES hashtags(tag_id)
);

CREATE TABLE follows (
    follower_id INT,
    followed_id INT,
    PRIMARY KEY (follower_id, followed_id),
    FOREIGN KEY (follower_id) REFERENCES users(user_id),
    FOREIGN KEY (followed_id) REFERENCES users(user_id)
);

CREATE TABLE likes (
    user_id INT,
    tweet_id INT,
    PRIMARY KEY (user_id, tweet_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (tweet_id) REFERENCES tweets(tweet_id)
);

INSERT INTO users (user_name, handle, email, password, profile, profile_status)
VALUES 
('John Doe', '@JohnDoe', 'johndoe@northeastern.edu', 'password123', 'Hello, I am John.', 'Visible'),
('Alice Smith', '@AliceSmith', 'alice@northeastern.edu', 'alicepass', 'I love tweeting!', 'Visible'),
('Bob Martin', '@BobMartin', 'bob@northeastern.edu', 'bobpassword', 'Food lover.', 'Hidden'),
('Eva Green', '@EvaGreen', 'eva@northeastern.edu', 'evapassword', 'Travel enthusiast.', 'Visible'),
('Tom White', '@TomWhite', 'tom@northeastern.edu', 'tomspass', 'Coffee addict.', 'Visible');

INSERT INTO tweets (content, timestamp, user_id)
VALUES 
('My first tweet! #FirstTweet', NOW(), 1),
('What a lovely day in NEU! #NEU', NOW(), 2),
('Trying out this Twitter thing. #GoodMorning', NOW(), 3),
('Just had a great lunch! #Lunch', NOW(), 4),
('Good morning everyone! #GoodMorning', NOW(), 5);

INSERT INTO hashtags (tag_name)
VALUES 
('#FirstTweet'),
('#NEU'),
('#Lunch'),
('#GoodMorning'),
('#CoffeeLover');

INSERT INTO tweet_hashtags (tweet_id, tag_id)
VALUES 
(1, 1),
(2, 2),
(3, 4),
(4, 3),
(5, 4);

INSERT INTO follows (follower_id, followed_id)
VALUES 
(1, 2),
(1, 3),
(2, 3),
(2, 1),
(3, 4),
(4, 1),
(5, 1),
(5, 2),
(5, 3),
(5, 4);

INSERT INTO likes (user_id, tweet_id)
VALUES 
(1, 2),
(2, 1),
(3, 1),
(3, 2),
(3, 5),
(4, 2),
(4, 3),
(5, 2),
(5, 4);

-- PART C. Database Validation

-- a) Which user has the most followers? Output just the user_id of that user, and the number of followers.
SELECT followed_id AS user_id, COUNT(follower_id) AS follower_count 
FROM follows 
GROUP BY followed_id 
ORDER BY follower_count DESC 
LIMIT 1;

-- b) For one user, list the five most recent tweets by that user, from newest to oldest. Include only tweets
-- containing the hashtag “#NEU”
SELECT * 
FROM tweets 
WHERE content LIKE '%#NEU%' AND user_id = 2
ORDER BY timestamp DESC 
LIMIT 5;

-- c) What are the most popular hashtags? Sort from most popular to least popular. Output the hashtag_id,
-- and the number of times that hashtag was used in a tweet. (It is not necessary to display the hashtag
-- name. Doing so without join syntax is possible but requires a subquery and an implicit join.) Rank your
-- output by number of times each hashtag is used in descending order.
SELECT tag_id, COUNT(tweet_id) AS usage_count 
FROM tweet_hashtags 
GROUP BY tag_id 
ORDER BY usage_count DESC;

-- d) How many tweets have exactly 1 hashtag? Your query output should be a single number
SELECT COUNT(*) 
FROM (SELECT tweet_id, COUNT(tag_id) AS tag_count 
      FROM tweet_hashtags 
      GROUP BY tweet_id 
      HAVING tag_count = 1) AS OneTagTweets;

-- e) What is the most liked tweet? Output the tweet attributes
SELECT t.*
FROM tweets t
WHERE t.tweet_id = (
    SELECT tweet_id 
    FROM likes 
    GROUP BY tweet_id 
    ORDER BY COUNT(user_id) DESC 
    LIMIT 1
);

-- f) Use a subquery or subqueries to display a particular user’s home timeline. That is, list tweets posted by
-- users that a selected user follows. (This would be easier with joins but using subqueries is an alternative
-- approach.)
SELECT * 
FROM tweets 
WHERE user_id IN (
    SELECT followed_id 
    FROM follows 
    WHERE follower_id = 3
) 
ORDER BY timestamp DESC;

















