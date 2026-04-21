***** EXPLORATORY DATA ANALYSIS  ***** 

-- In the Cleaning Data, we've cleaned the entire thing and it set us up to explore the data and with all that clean data, we'll be able to look at our data much better to find better insights while we're using it

/*Normally, when you start the EDA process, you have some idea of what you're looking for (sometimes not always); 
and sometimes, when you're exploring the data, you also find issues with the data that you then have to clean so even though, we did clean the data and then we do explore it, sometimes those coincide together where you're exploring it 
and cleaning it at the same time. What we're going to do is to just look at everything and we'll kind of discover and will start off really simple with kind of the basics and work little bit more towards the tougher stuff 
and then at the end, we'll have some more advanced things*/

1) /* First, we're going to work most likely with the total_laid_off than the percentage_laid_off, the percentage_laid_off isn't super helpful because we don't know how large the company is 
(I mean, we don't have another column that says (How many total employees they had)*/

-- Let's start looking at the total_laid_off:
1* -- In SQLite, MAX() on TEXT does string comparison, not numeric, that's why I had to add the CAST it to INTEGER: 
SELECT max(CAST(total_laid_off AS INTEGER)), max(percentage_laid_off)
FROM layoffs_staging2;
-- The output is 12000 which says: On one day, there was somebody who had the max total_laid_off of 12000 people and the max percentage_laid_off is 1 which means 100% of the company was laid off (it means that the company lost all their employees)

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY CAST(total_laid_off AS INTEGER) DESC;   -- total_laid_off is still TEXT, so SQLite sorts it alphabetically (lexicographically) instead of numerically, that's why we should cast to INTEGER 
-- We can see that all these companies went under or lost all their employees and the company Katerra which is a Construction company had the largest laid off with 2434 people.

-- We can also look at the most company that has funding: 
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY CAST(funds_raised_millions AS  INTEGER) DESC; 
-- So, we can see that Britishvolt has $2.4 billion of funding 

SELECT company, sum(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
-- We can see that those are big companies like Philips, Uber, Dell, Microsoft,.... that they let go of a lot of people 

-- Let's take a look now at the date ranges in our dataset: (Here, I noticed a problem in our date format, in the output, I got Min(date): 0000-00-00 so gotta fix it below): 
SELECT Min(`date`), Max(`date`)
FROM layoffs_staging2;

-- **** SOLUTION**** -- 
1) -- Step1: Restore the date column from the clean table (add a clean_date column to layoffs_staging2) as follows: 
ALTER TABLE layoffs_staging2 ADD COLUMN clean_date TEXT;

2) -- Copy original dates from layoffs → layoffs_staging2
UPDATE layoffs_staging2
SET clean_date = (
    SELECT date
    FROM layoffs
    WHERE layoffs.rowid = layoffs_staging2.rowid
);

3) -- Continue date cleaning work on this new column (Convert clean_date to ISO format): 
UPDATE layoffs_staging2
SET clean_date =
    substr(clean_date, 7, 4) || '-' || 
    substr(clean_date, 1, 2) || '-' || 
    substr(clean_date, 4, 2);

4) -- Verify your restored + cleaned dates
SELECT date, clean_date
FROM layoffs_staging2
LIMIT 20;
/* My clean_date column did not produce the expected result — instead of full dates like 2022-08-04, I see 23-3/-/2.
This indicates the transformation I used for clean_date didn’t correctly parse the original date format*/

5) -- Here is a robust SQL approach: 

UPDATE layoffs_staging2
SET clean_date = CASE
  WHEN LENGTH(date) = 10 AND substr(date,5,1) = '-' THEN        -- LENGTH(date) = 10 AND substr(date,5,1) = '-' checks for YYYY-MM-DD.
      date
  WHEN date LIKE '%/%/%' THEN																-- date LIKE '%/%/%' checks for slashes pattern.
      -- assuming MM/DD/YYYY
      substr(date, 7, 4) || '-' ||  -- year
      printf('%02d', CAST(substr(date,1, INSTR(date,'/')-1) AS INTEGER)) || '-' ||       -- Use printf('%02d', CAST(... AS INTEGER)) to ensure two-digit month/day & I may need to adjust if my data has other formats like M/D/YYYY (one-digit month/day) or spaces.
      printf('%02d', CAST(substr(date, INSTR(date,'/')+1, INSTR(substr(date,INSTR(date,'/')+1),'/')-1) AS INTEGER))
  ELSE
      NULL  -- or some default/fallback value
END;

/* Both the date and clean_date columns already contain ISO format (YYYY-MM-DD) BUT❗ Some rows contain wrong years
The problem is no longer the format.
The problem is the YEAR has been corrupted earlier in my process.
The format conversion worked — but the source dates themselves were wrong.*/

6) -- ✔ Fix the corrupted years in clean_date
UPDATE layoffs_staging2   
SET clean_date = '20' || substr(clean_date, 3) -- substr(clean_date, 3) starts from the “22-08-04” ;  '20' || ... makes it: 2022-08-04
WHERE clean_date LIKE '00%%';

7) -- FINAL FIX — Replace old date column with the clean one
-- SQLite cannot drop a column directly, so you recreate the table.

CREATE TABLE layoffs_staging2_new AS
SELECT
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    clean_date AS date,
    stage,
    country,
    funds_raised_millions
FROM layoffs_staging2;

-- Delete the old table
DROP TABLE layoffs_staging2;

-- Rename the new table 
ALTER TABLE layoffs_staging2_new
RENAME TO layoffs_staging2;

-- Verify the final result (Finally, it worked)
SELECT *
FROM layoffs_staging2
LIMIT 20;

-- Recheck the date range: 
SELECT Min(`date`), Max(`date`)
FROM layoffs_staging2;
-- It looks like it starts 2020-03-11 so right when I believe the pandemic or Covid-19 started and the max(date is 2023-03-06 so after 3 years. 

-- We can look also at what industry got hit the most during this tome or had the most layoffs! 
SELECT industry, sum(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
/*it looks like Consumer & Retail got hit really hard and that makes sense with shops closing down cuz people couldn't come in from the corona virus! 
and if we look at the industry that has the least number of laid off: Manufactoring, Fintech, Energy,..)*/

-- We looked at the company & industry, so let's know look at the country to see which country has the most laid off! 
SELECT country, sum(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
-- We can see that the United States had the most laid off with (256,559) people who lost their jobs within just 3 years. 

-- The following will show us the number of people who lost their jobs by each individual date
SELECT `date`, sum(total_laid_off)
FROM layoffs_staging2
GROUP BY `date`
ORDER BY 1 DESC;

--  Showing it by individual date is very useful so we will check it out by Year! The following supports only MySQL 
SELECT Year(`date`), sum(total_laid_off)
FROM layoffs_staging2
GROUP BY Year(`date`)
ORDER BY 1 DESC;

-- Since SQLite does not have a Year() function like some other SQL databases (e.g., MySQL or SQL Server). In SQLite, you need to extract the year using the substr() function (or strftime() if the column is a proper date).
SELECT 
    substr(`date`, 1, 4) AS year,  -- takes the first 4 characters of YYYY-MM-DD → the year.
    SUM(total_laid_off) AS total_laid_off -- aggregates the layoffs for that year.
FROM layoffs_staging2
GROUP BY year
ORDER BY year DESC; -- shows the most recent year first.
-- We can see that the worst year was 2022 with 160,661 but also we got 125,677 only in 3 months after the end of 2022 which is a lot higher than even 2022. 

-- Let's look at the stage column: 
SELECT stage, sum(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;
-- We can see that the most layoffs comes from The Post-IPO (this is Amazon, the google the most large companies that have initial public offering), and a lot of layoffs from Acquisitions, Series C & Series D.

-- If we look at the percentage_laid_off, we cannot interpret it properly since we don't know how large these companies are, so better to use the total_laid_off! 
SELECT company, sum(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- One thing we would be interesting in is the progression of the layoffs (you could call it a Rolling Sum) --> So start at the very earliest of layoffs and do a rolling sum until the very end of these layoffs. (So now, it's going to start getting a little tougher)

*** -- ROLLING TOTAL OF LAYOFFS-- *** 

-- Let's do it based off the month:
SELECT substr(date, 1,7) As MONTH, SUM(total_laid_off)
FROM layoffs_staging2
WHERE substr(date, 1,7) IS NOT NULL 
GROUP BY MONTH
ORDER BY 1 ASC;
-- We can see for example: all the layoffs (9628) from March 2020,... 

-- Now, we wanna take the data from our query before and do a Rolling Sum and we'll do it with a CTE! 

WITH Rolling_Total AS 
(
SELECT substr(date, 1,7) As MONTH, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE substr(date, 1,7) IS NOT NULL 
GROUP BY MONTH
ORDER BY 1 ASC
)
SELECT MONTH, total_off,
SUM(total_off) OVER													--  What we need to do is to Select the Month and we need to do a Rolling Total by adding SUM(total_off) & we don't wanna PARTITION BY anything cz we already did a GROUP BY so kind of like partitioning it 
(ORDER BY MONTH) AS rolling_total 	
FROM Rolling_Total;
/*So we have the month and as it goes down, we're having more laid off and we have our Rolling Total 
So it starts with 9 628 then it adds on the next month which is 26 710 which equals 36 338 (Rolling total)
This shows each month, how many were laid off and shows a month-by-month progression all the way down to the bottom. 
the result shows us that in 2020-03, we had 9 628 and by the end of 2020-12, we had about 81 000 (80 998)
In 2021-01, we had 87 811 and by the end of the year 2021-12, we had 96 821 So comparing to year 2020, it's like 9 000 people so nothing
So in this range of 383 159 from march 2023 all the way back to March 2020 lost their jobs (This is just the number that was reported, there might be much more than that)  SO ROLLING TOTAL are GREAT and it's good for Visualization*/


-- Now, we can look at the companies and see how much they were laying off per year so instead of just looking at it as a total, we'll break it out by the Year! 
SELECT company, substr(date, 1,4) AS Year,
sum(total_laid_off)
FROM layoffs_staging2
GROUP BY company, Year
ORDER BY company ASC;
-- We can see that 8x8 have multiple layoffs (in 2022, they let go of 200 people and in 2023, 155 people)

-- Let's say we want to use the information that we got in our previou query and rank which years they laid off the most employees 
SELECT company, 
substr(date, 1,4) AS Year,
sum(total_laid_off)
FROM layoffs_staging2
GROUP BY company, Year
ORDER BY 3 DESC; 
-- So companies like Microsoft & Amazon, they let go of multiple or thousands of people in different years so I want to rank those by saying (the highest one based off of the laid off should be ranked number 1) --> that's the year that they laid off the most people  

WITH Company_Year (company, years, total_laid_off) AS 
(
SELECT company, 
substr(date, 1,4) AS years,
sum(total_laid_off)
FROM layoffs_staging2
GROUP BY company, years
)
SELECT *, dense_rank() OVER (PARTITION BY  years ORDER BY  total_laid_off DESC) AS Ranking 																			 
FROM Company_Year
WHERE years IS NOT NULL
ORDER BY Ranking; 
/*We want to select everything but we want to PARTITION IT based off the Year so all of the 2021 layoffs will be in the same partition, and so on and then we wanna rank it based off how many they laid off in that year!
So, we'll get to see who laid off the most people per year cuz some companies like Amazon (they let off multiple people per year)*/
-- In the Result, it looks like Uber had the highest, so in 2020, this is biggest layoffs of the company Uber, For Meta, In 2022 it has teh biggest layoffs of 11,000.


-- Now, we can filter on the column Ranking to see the top 5 companies per year: 
WITH Company_Year (company, years, total_laid_off) AS 
(
SELECT company, 
substr(date, 1,4) AS years,
sum(total_laid_off)
FROM layoffs_staging2
GROUP BY company, years
), Company_Year_Rank AS
(SELECT *, 
dense_rank() OVER (PARTITION BY  years ORDER BY  total_laid_off DESC) AS Ranking 																			 
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT*
FROM Company_Year_Rank
WHERE Ranking <= 5;
-- In 2020, the top 5 companies who laid people off which are Uber, Booking.com, Groupon, Swiggy and Airbnb 
-- In 2021, the top 5 companies who laid people off are Bytedance, Katerra, Willow, Instacart & WhiteHat Jr
-- In 2022, the top 5 companies who laid people off which are Meta, Amazon, Cisco, Peloton, Carvana & Philips
-- In 2023, the top 5 companies who laid people off which are Google, Microsoft, Ericsson, Amazon, Salesforce & Dell.
-- This is Very very interesting as we're looking at a year-by-year snapchot, these are the total laid off for each company. 
-- OPTION: we can go back and change this for like industry or whatever you want but this is an interesting query in general  

*** RECAP ON THE LAST QUERY *** 

1) -- First, we created this query and we were looking at the company by the year & how many people they let off 
SELECT company, 
substr(date, 1,4) AS Year,
sum(total_laid_off)
FROM layoffs_staging2
GROUP BY company, Year
ORDER BY 3 DESC; 

2) -- Then , we created our first CTE which said WITH the Company_Year and we changed the name of the columns.... GROUP BY company, years.
WITH Company_Year (company, years, total_laid_off) AS 
(
SELECT company, 
substr(date, 1,4) AS years,
sum(total_laid_off)
FROM layoffs_staging2
GROUP BY company, years  						-- The end of our first CTE 
), Company_Year_Rank AS                      3) -- Then, We went and gave it a rank and we wanted to filter on that rank that's why we added this at the end: (FROM Company_Year_Rank WHERE Ranking <= 5;) 
(SELECT *, 														-- We did this rank as another CTE so we just added a comma and wrote our second CTE (, Company_Year_Rank AS (...... IS NOT NULL)) 
dense_rank() OVER (PARTITION BY  years ORDER BY  total_laid_off DESC) AS Ranking 																			 
FROM Company_Year                                     -- We hit off our first CTE to make our second CTE when we said (FROM Company_Year)
WHERE years IS NOT NULL
)
SELECT*
FROM Company_Year_Rank
WHERE Ranking <= 5;

-- In general, it's not an easy query to kind of think through but we tried to explain it step by step to be able to understand 

/* So, we were just exploring the data and we looked at: 
1)  laid off a lot, 
2)  The company, and when these dates actually started for these layoffs in the dataset
3) The country 
4) Then we went to more difficult things (we looked at it per month, how many layoffs they had and then we did a Rolling Total and this is a good one using that substring 
5) Then, we did multiple CTEs in the company*/

***** END ***** 



	


















