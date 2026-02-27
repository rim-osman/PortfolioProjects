***** DATA CLEANING ***** 

/*Definition: 
Data cleaning is basically where you get it in a more usable format so you fix a lot of the issues in the raw data that when you start using visualizations or using it in your products, the data is useful & there aren't a lot of issues with it. 
So in this project, we're gonna go through all the steps in order to clean the data*/

-- My SQL is going to automatically assign a data type based off of the data. 
-- We're importing 2361 records or rows. 
-- The data has: 
1-- The Company that did the layoffs (layoffs means a discharge of a worker or workers bcz of economic conditions). 
2 -- The location of where they are 
3 -- What industry they are part of 
4 -- How many they laid off 
5 -- The % that they laid off so the percentage of their company.
6 -- The date 
7 -- The stage which refers to the stage that the company is in whether it's a Series B, Post-IPO, ..
8 -- The country 
9 -- funds_raised_millions
-- So we have a lot of information. We're going to clean this data and next in the Data exploration, we're gonna dive into it and try to find trends & patterns. 

SELECT*
FROM layoffs;

-- We're going to go through multiple steps:
1) -- Step 1: Try to remove duplicates if there are any (this is the first thing that you'd typically do if there are uncessary duplicates)
2) -- Step 2: Standardize the data (Which means, if there are issues with the data, with spellings or things like that, we just want to standardize it to where it's all the same as it should be).
3) -- Step 3: Look at NULL Values or BLANK Values (If you see the data, you'll see Null and blank values) so we're gonna see if we can populate that (there are times where we should and times where you shouldn't) so we'll walk through that as well.
4) -- Step 4: Remove any columns or rows that aren't necessary (there's a few different ways to do that).
/* As we said, keep in mind that there are instances where you should do this & where you shouldn't do this: 
When you're working with massive datasets & you have a column that's completely irrelevant or blank, you don't have any ETL process that is required for it, you can get rid of it and it can save you time when you're querying your data.
In the real workplace, often times, you have processes that automatically import data from different data sources so if you remove a column from the raw dataset, that's a big big problem!!
So, what we're going to do is something that they usually do in their real work 
--> Create some type of staging or raw dataset so we're gonna create a table and call it layoffs_staging and we're literally copy all of the data from the raw table into the staging table as follows: */

-- The following works in MySQL:
CREATE TABLE layoffs_staging 
LIKE layoffs;

-- This version works in SQLite:
CREATE TABLE layoffs_staging AS
SELECT *
FROM layoffs
WHERE 0;  -- 0 ensures no rows are copied, only the structure

SELECT*
FROM layoffs_staging; -- Now, we have all of the columns and all we have to do is INSERT the data.

-- SQLite: 
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- MySQL: 
INSERT layoffs_staging
SELECT *
FROM layoffs;

/* Why do we do this? and have now 2 different tables? --> Because we're about to change the staging database a lot so if we make some type of mistake, we want to have the raw data available 
(this is something that you do in the real workplace, because you're not gonna work on the raw data and you shouldn't do it, it's not the best practice).
So now we're only gonna be working off this staging database*/

-- We're jumping into kind of more advanced things now! 
1) -- Step 1: Identifying and Removing duplicates: What we can do is to try and do something like a "row number" and we'll match it against all of these columns in the data and then we'll see if there are any duplicates. 

 -- So, what we can do is Row number and we'll do that Partition by basically every single one of these columns.
SELECT*, 
row_number() OVER (
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num  -- we added backticks to date because date is a keyword in SQL.
FROM layoffs_staging;

/* As result, we can see the row_num column that are mostly unique (1) so now, we want to be able to filter on this so we can filter where the row_number is greater than 2 
(If it has 2 or above, it means there's duplicates which means there's an issue)*/

-- First, we're gonna take the above query and put it into either a subquery or a CTE (I'll create a CTE which is easy) as follows: 

WITH duplicate_cte AS 
(
SELECT*, 
row_number() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num  -- we added backticks to date because date is a keyword in SQL.
FROM layoffs_staging
)
SELECT*
FROM duplicate_cte
WHERE row_num > 1;
-- Once, we run it, we'll see our duplicates that we want to get rid of these exact rows 

-- Very important thing to do is to look at one row for example let's take the company 'Casper' to check it: 

SELECT*
FROM layoffs_staging
WHERE company = 'Casper'; 

-- If we notice in the result, these are 2 duplicates rows so we're going to remove only one of those not all of them! 

/*Second thing, we need to identify these exact rows, we do not want to delete both of them as we said.
In MySQL, there have different ways that they can delete rows, you cannot update a CTE (DELETE) as shown in the query below, like we usually can do it in Microsoft SQL Server.
Also, SQLite does not allow deleting from a CTE so the following query will not work*/

WITH duplicate_cte AS 
(
SELECT*, 
row_number() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num  -- we added backticks to date because date is a keyword in SQL.
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

/*So, for that reason, we're going to do something a bit different; we're going to put the one between the parantheses into a staging 2 database and then we can delete it bcz we can filter on these row_nums. 
-- So, We're just creating another table that has this extra row and then deleting it where that row is equal to 2*/
-- Here,  I created a table called layoffs_staging2 with the same field names, then insert the data into the new table: 

DROP TABLE IF EXISTS layoffs_staging2;

CREATE TABLE layoffs_staging2 AS
SELECT *,
       row_number() OVER (
           PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,
           "date", stage, country, funds_raised_millions
       ) AS row_num
FROM layoffs_staging;


INSERT INTO layoffs_staging2
SELECT *,
row_number() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Check that the data is inserted:
SELECT *
FROM layoffs_staging2; 

-- Try always to write SELECT to check what you're deleating from the table then replace it by DELETE:
DELETE
FROM layoffs_staging2
WHERE row_num  > 1;

-- Check that the row_num that equal to 2 are removed! 
SELECT*
FROM layoffs_staging2
WHERE row_num  > 1;

-- Now, we can get rid off the row_num column bcz we no longer need it anymore (it's a redundant column & it adds up extra space in memory and storage)

-- *** THAT'S HOW WE REMOVE DUPLICATES*** -- 
-- Keep in mind that there are different ways to do it when you have different columns like if you hava a unique column before the company field name (it's so much easier). 

-- Let's look at Standardizing data:

-- *** Standardizing Data *** -- 
-- Definition: Standardizing data is finding issues in your data and then fixing it. 

-- First, we're gonna take off the white space before the word (if there's blank spacing) and also after the work (on the right hand side) and we can do that by mentioning the keyword "trim" like follows:
SELECT company, (trim(company))
FROM layoffs_staging2; 
-- First, if you notice 

-- UPDATE the column: 
UPDATE layoffs_staging2
SET company = (trim(company)); 

-- The next thing we're gonna take a look at is the industry: 

SELECT DISTINCT industry
FROM layoffs_staging2 
ORDER BY 1; 
/*If you see, we have blank row which can we fix it later, and we can also notice that we have 3 rows (Crypto, Crypto Currency, Crypto Currency) and those should be labeled exactly the same name! 
Spo we need to change it because in exploratory data analysis and visualizing it later, these 3 would all be their own unique rows but we don't want that, in the visualization, we want all to be grouped together so we can accuretely look at the data*/

-- Here, is to check what the majority name looks like: 
SELECT* 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';
-- So, we can see that 95% of them are Crypto so we want to update all of them to Crypto! 

UPDATE layoffs_staging2
SET industry = 'Crypto' 
WHERE industry LIKE 'Crypto%';

-- We can check that all the industry names are updated to only Crypto! 
SELECT* 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- We can also check that Crypto is the only thing appearing in the column now: 
SELECT DISTINCT industry
FROM layoffs_staging2; 

-- It's good to look at all the fields one by one to see if there's any small issue that you might not see:
SELECT DISTINCT location
FROM layoffs_staging2; 
-- No problem in this 

-- Check the country column 
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; 
-- Here, there is a problem, we can see that there's 2 rows called (Unites States, United States.) the second name written with a dot at the end which must be fixed!! 

-- Just doing the Trim will not gonna fix the problem but there's a trick we can do is to add the keyword "TRAILING" explained below:
SELECT DISTINCT country, trim(country)
FROM layoffs_staging2
ORDER BY 1;

-- In MySQL, there is something called TRAILING which is more advanced one to fix the dot in the Unites States. but SQLite does not support this Keyword, We can see how this could be written in MySQL and not SQLite: 

-- MYSQL: 
SELECT DISTINCT country, trim(TRAILING '.' FROM country) -- after TRAILING, we're specifying what we're looking for to fix at the end! 
FROM layoffs_staging2
ORDER BY 1;
-- It should work then we need to update it: 

UPDATE layoffs_staging2
SET country = trim(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- THIS IS HOW IT WORKS IN SQLITE because it supports: RTRIM(country, '.') & not TRIM(TRAILING … FROM …)
SELECT DISTINCT country,
       RTRIM(country, '.') AS cleaned_country
FROM layoffs_staging2
ORDER BY country;
-- It worked! 

-- After we clean the value, we should UPDATE the table to remove the trailing dot: 

UPDATE layoffs_staging2
SET country = RTRIM(country, '.')
WHERE country LIKE 'United States%';

-- We can check it now to be sure that we only have one row called Unites States! 
SELECT DISTINCT country,
       RTRIM(country, '.') AS cleaned_country
FROM layoffs_staging2
ORDER BY country;


-- The next thing we shoud look at is date! 
-- N.B: if we're trying to do time series exploratory data analysis visualizations later on, the date needs to be changed because if we go and check its data type, it's assigned by default to "TEXT" so we need to change it to "DATE". 

/*We're gonna format it as Month, Day, Year so there's something that very helpful and works in this situation called "string to date" which helps us go from a String which is a TEXT to a date, 
All we need to do is pass through 2 parameters (the column name which is date and the format that we went to set in. 
In order to format this properly, we need to use a percent sign (%) before each like follows:*/
SELECT `date`
STR_TO_DATE(`date`, '%m/%d/%Y')  -- So, here it converts it to a standard date format so instead 1/27/2023, it converts it to a new date column:  2023-01-27
FROM layoffs_staging2;
-- N.B: the m & d should be lower case and the Y should be capital in our case so it depends how the original date column is look like! 

-- SQLite doesn’t have a built-in STR_TO_DATE function like MySQL: 
UPDATE layoffs_staging2
SET date = trim(date);

-- The simplest method for a column like 1/27/2023 in SQLite is to use printf to pad month/day with zeros:
SELECT
    printf('%04d-%02d-%02d',
           cast(substr(`date`, instr(`date`, '/')+4, 4) as int),          -- year
           cast(substr(`date`, 1, instr(`date`, '/')-1) as int),          -- month
           cast(substr(`date`, instr(`date`, '/')+1, instr(substr(`date`, instr(`date`, '/')+1), '/')-1) as int) -- day
    ) AS formatted_date
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = printf('%04d-%02d-%02d',
           cast(substr(`date`, instr(`date`, '/')+4, 4) as int),          -- year
           cast(substr(`date`, 1, instr(`date`, '/')-1) as int),          -- month
           cast(substr(`date`, instr(`date`, '/')+1, instr(substr(`date`, instr(`date`, '/')+1), '/')-1) as int) -- day
    );
	
-- Now, if we check it, it look like it worked perfectly with the right format! 
SELECT date 
FROM layoffs_staging2;

-- N.B: If we go and check the data type of Date, we notice that it's still TEXT but now it's in the date format, bcz if we try to convery TEXT to DATE, it wouldn't work so we should change the formatting as we did before!

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE; -- In MySQL, ALTER TABLE ... MODIFY COLUMN ... DATE changes the column type to a proper DATE, while In SQLite, you cannot directly change the type of an existing column.

SELECT*
FROM layoffs_staging2;
-- So, we fixed issues in the company column, the industry and the country. 


-- **** The next thing which is Step 3 is to deal with blank and NULL values! **** -- 

-- In a situation where we have null or blank values, we need to think about what we're going to do with this information so whether we want to make them all nulls, blanks! 

-- Let's start off with the total_laid_off and in order to see if there are NULL values, we just have to say (IS NULL) as follows: 

SELECT *
FROM layoffs_staging2
WHERE total_laid_off  IS NULL;

-- Here, I went through an issue, the output that I got is 0 rows (I checked ChatGPT and here's what he suggested me to do):
 
 1) -- check to verify the column and types:
PRAGMA table_info(layoffs_staging2);
/* From the PRAGMA table_info output:
total_laid_off is of type TEXT.
This means your “NULL” values are probably the string 'NULL' rather than true SQL NULLs.
In SQLite, IS NULL does not match the string 'NULL' — only actual SQL NULL values
In SQLite:
IS NULL only matches true SQL NULLs.
'NULL' (text) or '' (empty string) are not considered NULL.*/

-- check what’s really in the column:
SELECT total_laid_off, LENGTH(total_laid_off) AS len
FROM layoffs_staging2
WHERE total_laid_off = 'NULL' OR total_laid_off IS NULL;

-- To convert all text 'NULL' or empty strings to real SQL NULLs
UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE total_laid_off = 'NULL'
   OR TRIM(total_laid_off) = '';
   
 -- This will now returns the rows I expect and it worked perfectly now:
 SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;

-- N.B: If we have the total_laid_off & the percentage_laid_off, both have Null values at the same row, then they'll be useless that's why we're gonna check where both of them are NULL: 

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;
-- So, here I also went through the same issue then I fixed it like I did with the total_laid_off column but this time for the percentage_laid_off as follows:

UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 'NULL'
   OR TRIM(percentage_laid_off) = '';
 
 -- Now, we can check the NULL values in the both columns:
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
 -- So these might be ones that we remove which we'll look at it in Step 4 (Deleting rows or columns) 
 
 -- If we take a look at the industry column as well, we can see that it has both one NULL value and one missing value:
SELECT DISTINCT industry 
FROM layoffs_staging2;

-- I made this step because I run the queries twice so I inserted the data twice so instead of having 2000 rows, I have 4000 which creates duplicates so to remove duplicates, I should do the following:
-- Create a temporary table with only unique rows:
CREATE TABLE layoffs_staging2_unique AS
SELECT DISTINCT *
FROM layoffs_staging2;

-- Drop the original table:
DROP TABLE layoffs_staging2;

-- Rename the unique table back:
ALTER TABLE layoffs_staging2_unique RENAME TO layoffs_staging2;

-- To check the exact row numbers (2361 rows)
SELECT COUNT(*) 
FROM layoffs_staging2;

-- Now, going back to our NULL & Blank values in the industry column: 
SELECT *
FROM layoffs_staging2 
WHERE industry IS NULL; 

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = 'NULL'
   OR TRIM(industry) = '';
   
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR TRIM(industry) = '';
 -- We can only see 4 ROWS 

 -- What I want to do is to see if any of these have one that's populated, so let's take for example the row 'Airbnb' (something that is very helpful to really be able to populate data)
 
 -- “Populate data” simply means filling a table, database, or data structure with data; So basically: “populate” = put data into a place where it was empty before -- 
 
 -- So if we look at Airbnb: 
 SELECT *
 FROM layoffs_staging2
 WHERE company = 'Airbnb';
 /* We can see that Airbnb has Travel so we know this is the travel industry so we can populate this with Travel again because if we want to see for example what industry were impacted the most, 
 if we keep it blank, it won't be in our output bcz it's blank! So we wanna update it below*/
 
 -- In order to update it, we need to JOIN the table with itself because we want to check one table that have the row blank and the other table that has no blank row, then update it with the nonblank one as follows:
 
 SELECT *
 FROM layoffs_staging2 t1 -- t1: table 1
 JOIN layoffs_staging2 t2 -- t2: table 2
	ON t1.company = t2.company 
	AND t1.location = t2.location 
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
/* It's very important to make sure that the location also are the same as well because if Airbnb have a location in South America or wherever, we're gonna have an issue so it should be both have a location "SF Bay Area", 
You have to think about different scenarios or use cases so we don't wanna change the ones that have different location!*/

/*The output shows us that there's Juul, Carvana, and Airbnb, these ones all have industries where it's NULL or blank AND industries where it's not NULL (which filled by travel, transportation and consumer).
So this worked as exactly as we had hoped*/

-- Here, we can also make it more visible by selecting t1.industry & t2.industry
 SELECT t1.industry, t2.industry
 FROM layoffs_staging2 t1 -- t1: table 1
 JOIN layoffs_staging2 t2 -- t2: table 2
	ON t1.company = t2.company 
	AND t1.location = t2.location 
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
-- So if it's blank, they should be populated with the ones that are not blank! 

-- N.B; the thing that we're gonna do is supported by MySQL and not SQLite!! 
-- Now, we have to translate the query above into an update statement as follows: 

UPDATE layoffs_staging2 t1  								-- We're Updating this t1 
JOIN layoffs_staging2 t2           							-- We're joining on t2 where the company and location are the exact same
	ON t1.company = t2.company 
	AND t1.location = t2.location 
SET t1.industry = t2.industry          						-- We're setting t1.industry = t2.industry so t1.industry should be the blank one Where t1.industry IS NULL AND t2.industry IS NOT NULL! 
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- SQLite does not support JOIN in an UPDATE statement` the same way MySQL does, You need to rewrite it using a correlated subquery or a FROM clause with UPDATE (SQLite supports a limited form of FROM).
UPDATE layoffs_staging2
SET industry = (
    SELECT t2.industry
    FROM layoffs_staging2 t2
    WHERE t2.company = layoffs_staging2.company  -- The subquery finds a row (t2) with the same company and location that has a non-NULL industry.
      AND t2.location = layoffs_staging2.location
      AND t2.industry IS NOT NULL
    LIMIT 1																				-- LIMIT 1 ensures SQLite doesn’t complain if multiple matches exist.
)
WHERE industry IS NULL OR TRIM(industry) = ''; -- WHERE industry IS NULL OR TRIM(industry) = '' ensures we only update rows where industry is blank or NULL.

-- Now, if we check it we can see that it works and we have no longer missing values or Blank 
 SELECT *
 FROM layoffs_staging2
 WHERE company = 'Airbnb';
 
 -- We can check if we still have NULL or Blank values 
 SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR TRIM(industry) = '';
 -- It seems here that Bally's Interactive is the only one that still has a Null but if we can see below:
 
 -- This one don't have another populated row where it's not NULL to actually populate the NULL row so that's all we're going to do for populating null values! 
 SELECT *
 FROM layoffs_staging2
 WHERE company LIKE 'Bally%';
 
 SELECT*
 FROM layoffs_staging2;
 
 SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
 /*In the future, we might looking at the companies or location that had layoffs but the data output shows us that these companies have no layoffs in the column (total_laid_off) and no percentage in the column (percentage_laid_off), 
 So I don't know if these laid off any at all, that's why we believe that we can get rid of these and deleting data is an interesting thing to do so you have to be confident!
 To be totally right, we're not sure if we should DELETE these bcz we're not 100% sure that those companies that has NULL values in the total_laid_off & percentage_laid_off had never laid off, 
 but the point is that we don't need these informations*/
 
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
 AND percentage_laid_off IS NULL;
 -- Now, we deleted them because I can't really trust that data that has NULL values 
 
 -- Now, we want to drop the row_num from the table bcz we don't need it anymore! 
 ALTER TABLE layoffs_staging2
 DROP COLUMN row_num;
 
 -- *** THIS IS OUR FINALIZED CLEAN DATA *** --
 -- *** NEXT, WE'RE GOING TO DO EXPLORATORY DATA ANALYSIS ON THIS CLEAN DATA*** -- 
 
 -- *** ONE THING TO KNOW IS CLEANING DATA IS NOT ALWAYS A STRAIGHTFORWARD THING, YOU HAVE TO FIGURE IT OUT AND THAT'S WHAT WE DID AND THE QUERY THAT WE WROTE ARE NOT SUPER BEGINNER STUFF*** -- 
 
 
 
 

 
 

 











































