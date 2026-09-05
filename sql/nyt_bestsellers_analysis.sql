-- ROW COUNT
SELECT COUNT(*) FROM nyt_bestsellers_final;

-- PERCENTAGE OF NULLS FOR EACH COLUMN
SELECT
	AVG(CASE WHEN `date` IS NULL OR `date` = '' THEN 1.0 ELSE 0.0 END) * 100 AS date_null_pct,
    AVG(CASE WHEN `list_name` IS NULL OR `list_name` = '' THEN 1.0 ELSE 0.0 END) * 100 AS list_name_null_pct,
    AVG(CASE WHEN `rank` IS NULL OR `rank` = '' THEN 1.0 ELSE 0.0 END) * 100 AS rank_null_pct,
    AVG(CASE WHEN `title` IS NULL OR `title` = '' THEN 1.0 ELSE 0.0 END) * 100 AS title_null_pct,
    AVG(CASE WHEN `author` IS NULL OR `author` = '' THEN 1.0 ELSE 0.0 END) * 100 AS author_null_pct,
    AVG(CASE WHEN `publisher` IS NULL OR `publisher` = '' THEN 1.0 ELSE 0.0 END) * 100 AS publisher_null_pct,
    AVG(CASE WHEN `weeks_on_list` IS NULL OR `weeks_on_list` = '' THEN 1.0 ELSE 0.0 END) * 100 AS weeks_on_list_null_pct,
    AVG(CASE WHEN `isbn13` IS NULL OR `isbn13` = '' THEN 1.0 ELSE 0.0 END) * 100 AS isbn13_null_pct,
    AVG(CASE WHEN `publishing_group` IS NULL OR `publishing_group` = '' THEN 1.0 ELSE 0.0 END) * 100 AS publishing_group_null_pct
FROM nyt_bestsellers_final;

-- ALL THE `list_name` FROM THE DATASET
SELECT DISTINCT list_name
FROM nyt_bestsellers_final;

-- TOP 1 PUBLISHING GROUPS WITH MOST DIFFERENT BOOKS ON LIST
-- (ADDED WHERE CLAUSE TO ONLY SHOW THOSE DIFFERENT THAN PENGUIN RANDOM HOUSE,
-- AS THIS GROUP IS THE DOMINANT ONE)
WITH book_counts AS (
	SELECT publishing_group, list_name, COUNT(DISTINCT isbn13) AS book_count
	FROM nyt_bestsellers_final
	GROUP BY publishing_group, list_name
),
ranks AS (
	SELECT publishing_group, book_count, list_name,
		RANK() OVER (PARTITION BY list_name ORDER BY book_count DESC) AS pub_group_rank
	FROM book_counts
)
SELECT list_name, publishing_group, book_count
FROM ranks
WHERE pub_group_rank = 1
AND publishing_group != 'PENGUIN RANDOM HOUSE'
ORDER BY list_name;

-- TOP AUTHOR WITH MOST DISTINCT BOOKS FOR EACH CATEGORY
-- EXCLUDING THOSE THAT ONLY HAVE 1 `book_count` AND
-- 'OTHERS' IN `author`
WITH book_counts AS (
	SELECT author, list_name, COUNT(DISTINCT isbn13) AS book_count
    FROM nyt_bestsellers_final
    GROUP BY author, list_name
),
ranks AS (
	SELECT author, book_count, list_name,
    RANK() OVER (PARTITION BY list_name ORDER BY book_count DESC) AS author_rank
    FROM book_counts
)
SELECT list_name, author, book_count
FROM ranks
WHERE author_rank = 1
	AND book_count > 1
    AND author != 'OTHERS'
ORDER BY list_name;

-- TOP AUTHORS WITH THE MOST WEEKS AT RANK 1
-- IN EACH CATEGORY
WITH authors_ranked1 AS (
	SELECT DISTINCT author, list_name, COUNT(*) AS weeks_at_1
    FROM nyt_bestsellers_final
    WHERE `rank` = 1
    GROUP BY author, list_name
),
top_authors_in_1 AS (
	SELECT author, list_name, weeks_at_1,
		RANK() OVER(PARTITION BY list_name ORDER BY weeks_at_1 DESC) AS author_rank
	FROM authors_ranked1
)
SELECT list_name, author, weeks_at_1
FROM top_authors_in_1
WHERE author_rank = 1
ORDER BY list_name;

-- AVERAGE NUMBER OF WEEKS A BOOK REMAINS RANKED 1
-- FOR EACH CATEGORY
WITH books_ranked1 AS (
	SELECT DISTINCT isbn13, list_name, COUNT(*) AS weeks_at_1
    FROM nyt_bestsellers_final
    WHERE `rank` = 1
    GROUP BY isbn13, list_name
)
SELECT list_name, AVG(weeks_at_1) AS avg_weeks_at_1
FROM books_ranked1
GROUP BY list_name
ORDER BY avg_weeks_at_1 DESC;

-- AVERAGE NUMBER OF WEEKS IN LIST FOR
WITH books_in_list AS (
	SELECT DISTINCT isbn13, list_name, COUNT(*) AS weeks_in_list
    FROM nyt_bestsellers_final
    GROUP BY isbn13, list_name
)
SELECT list_name, AVG(weeks_in_list) AS avg_weeks_in_list
FROM books_in_list
GROUP BY list_name
ORDER BY avg_weeks_in_list DESC;

-- TITLES WITH MOST TIME ON THE LIST FOR EACH CATEGORY THAT AT SOME POINT REACHED RANK 1,
-- WITH THE NUMBER OF WEEKS ON THE LIST AND THE AVERAGE RANK THEY HAD
WITH books_reached_rank1 AS (
	SELECT DISTINCT isbn13
    FROM nyt_bestsellers_final
    WHERE `rank` = 1
),
week_count AS (
	SELECT nyt.list_name, 
		nyt.title,
        nyt.author,
		br1.isbn13, 
		COUNT(*) AS weeks,
        AVG(`rank`) AS avg_rank
    FROM books_reached_rank1 AS br1
		JOIN nyt_bestsellers_final AS nyt ON br1.isbn13=nyt.isbn13
	GROUP BY isbn13, nyt.list_name, nyt.title, nyt.author
),
time_rank AS (
	SELECT list_name, author, title, weeks, avg_rank,
		RANK() OVER(PARTITION BY list_name ORDER BY weeks DESC) AS book_week_rank
	FROM week_count
)
SELECT list_name, author, title, weeks, avg_rank
FROM time_rank
WHERE book_week_rank = 1
ORDER BY list_name;

-- AUTHORS WITH MOST TIME ON THE LIST
-- BUT NEVER ON THE RANK 1 FOR EACH CATEGORY
WITH number_one_authors AS (
	SELECT DISTINCT author, list_name
    FROM nyt_bestsellers_final
    WHERE `rank` = 1
),
not_one_authors AS (
	SELECT n.author, n.list_name, COUNT(*) AS weeks
    FROM nyt_bestsellers_final AS n
	WHERE `rank` > 1
		AND NOT EXISTS (
			SELECT 1 FROM number_one_authors AS noa
            WHERE noa.author=n.author
        )
	GROUP BY n.author, n.list_name
),
author_ranks AS (
	SELECT list_name, author, weeks,
		RANK() OVER(PARTITION BY list_name ORDER BY weeks DESC) AS a_ranks
	FROM not_one_authors
)
SELECT list_name, author, weeks
FROM author_ranks
WHERE a_ranks = 1
ORDER BY list_name;
