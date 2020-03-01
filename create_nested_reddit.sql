--------------------------------------------------------------------
--------- M2 STATS ECO 2019-2020 : Reddit project (part 1) ----------
---------------------------------------------------------------------
-- AUTHORS : Sandra FERRIERES & Aicha SAAD
-- DADELINE : March, 3rd 2020
-- LAST MODIFICATION : February, 28th 2020
---------------------------------------------------------------------
-- NOTE: The goal of this script is to created a new Data bases which contains
-- only a part of the initial reddit DB
-- Also it contains some indexes.The complete list of indexes 
-- will be created once we start the analyses part
---------------------------------------------------------------------

-- 1) First we clone the reddit DB : new DB nested_reddit.db
--in the prompt command or the terminal execute : .\sqlite3 reddit.db 
-- (to connect to the intial DB), then .clone nested_reddit.db 
-- (to create the new database which we are going to modify)

-- 2) First selection criterion: delete all the rows with distinguished value missing 
-- in the prompt command execute: .\sqlite3 nested_reddit.db

SELECT count(*)
FROM is_distinguished
WHERE distinguished is NULL OR trim(distinguished)='';
--we can notice that most of the comments have a missing vale
-- for distinguised

BEGIN;
DELETE FROM distinguished
WHERE distinguished is NULL OR trim(distinguished)='';
DELETE FROM  is_distinguished
WHERE distinguished is NULL OR trim(distinguished)='';
COMMIT;

--check suppression correctly executed:
SELECT count(*)
FROM is_distinguished
WHERE distinguished is NULL OR trim(distinguished)=''; --count should be=0

--- 3) 2nd criterion: select only controversial comments 
SELECT controversiality
FROM controversy;

BEGIN;
DELETE FROM controversy
WHERE controversiality=0;
DELETE FROM comment
WHERE controversiality=0;
COMMIT;

--check the suppression done correctly
SELECT id FROM comment
WHERE controversiality=0; -- o result should be found 

--- 4) 3rd criterion: select  comments with the 20 highest scores
BEGIN;
DELETE  FROM score 
WHERE id NOT IN (
SELECT id FROM(
   SELECT id,sum(score) AS agg_score --this score is directly equal
   -- to  the score of the comment (because the id is the primary key)
   -- of score. We just need the group_by because we are introducing
   -- a numeric function in order to do the order by
   FROM score 
   GROUP BY id
   ORDER BY agg_score DESC) 
   LIMIT 20)
;
DELETE FROM comment
WHERE id NOT IN (
    SELECT id FROM score
);
COMMIT;

--check that the query above correctly executed
SELECT count(id) FROM score;
SELECT count(id) FROM comment; -- the 2 counts should be equal

---- 5) 4th selection criterion: select the top 20  most popular 
---- authors (with the highest number of comments) who had written controversial
---- comments

SELECT count(*)
FROM author; --- 579735 authors in total

BEGIN;
DELETE  FROM comment 
WHERE author NOT IN (
SELECT author FROM(
   SELECT author,count(id) AS nb_comments
   FROM comment 
   GROUP BY author
   ORDER BY nb_comments DESC) 
   LIMIT 20)
;
DELETE FROM author
WHERE author NOT IN (
    SELECT author FROM comment
);
DELETE FROM is_distinguished
WHERE id NOT IN (
    SELECT id FROM comment
);
DELETE FROM score 
WHERE id NOT IN (
    SELECT id FROM comment
);

DELETE FROM removed 
WHERE id NOT IN (
    SELECT id FROM comment
);

DELETE FROM depends 
WHERE id NOT IN (
    SELECT id FROM comment
);

COMMIT;

SELECT count(*) FROM author ; --should be 20
SELECT count(id) FROM score;
SELECT count(id) FROM comment;
SELECT count(id) FROM is_distinguished;
SELECT count(id) FROM depends; -- the 4 latest counts should be equal

--then execute in the termina: VACUUM;