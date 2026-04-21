********** GLOBAL GDP ANALYSIS **********
																																								
																																																																				
********** 1. DATA CLEANING ********** 

➤ -- Create staging tables from raw sources 
 
CREATE TABLE gdp_staging AS 
SELECT * FROM gdp_data; 

CREATE TABLE metadata_staging AS
SELECT * FROM metadata_countries; 
 
➤-- Data inspection 
  
SELECT* 
FROM gdp_staging; 

SELECT* 
FROM metadata_staging;

➤-- Remove duplicates using ROW_NUMBER ( )

 CREATE TABLE gdp_cleaned AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY CountryCode, Year
               ORDER BY Year
           ) AS rn
    FROM gdp_staging
) t
WHERE rn = 1;

********** 2. DATA STANDARDIZATION ********** 

 ➤-- Standardize GDP table

SELECT CountryName, (trim(CountryName)) 
FROM gdp_staging; 

SELECT CountryCode, (trim(CountryCode)) 
FROM gdp_staging; 

UPDATE gdp_staging 
SET 
		CountryName = UPPER (trim(CountryName)),
		CountryCode = UPPER (trim(CountryCode));
		
➤-- Validate uniqueness after standardization (gdp table) 

SELECT DISTINCT CountryName
FROM gdp_staging
ORDER BY 1;

SELECT DISTINCT CountryCode
FROM gdp_staging
ORDER BY 1;

➤-- Standardize metadata table

SELECT CountryName, (trim(CountryName)) 
FROM metadata_staging; 

SELECT CountryCode, (trim(CountryCode)) 
FROM metadata_staging

SELECT Region, (trim(Region)) 
FROM metadata_staging; 

SELECT IncomeGroup, (trim(IncomeGroup)) 
FROM metadata_staging; 


UPDATE metadata_staging 
SET 
		CountryName = UPPER (trim(CountryName)),
		CountryCode = UPPER (trim(CountryCode)),
		Region = UPPER (trim(Region)),
		IncomeGroup = UPPER (trim(IncomeGroup));

➤-- Validate metadata consistency

SELECT DISTINCT CountryName
FROM metadata_staging
ORDER BY 1;

SELECT DISTINCT CountryCode
FROM metadata_staging
ORDER BY 1;

SELECT DISTINCT Region
FROM metadata_staging
ORDER BY 1;

SELECT DISTINCT IncomeGroup
FROM metadata_staging
ORDER BY 1;


********** 3. DATA FILTERING  ********** 

➤-- ISO VALID COUNTRIES ONLY

SELECT *
FROM gdp_cleaned
WHERE CountryCode IN (
    SELECT CountryCode FROM iso_countries
);
   
   
********** 4. DATA MODELING ********** 

➤-- Create dimension table (only real countries)

CREATE TABLE country_dim AS
SELECT DISTINCT
			m.CountryCode, 
			m.CountryName, 
			m.Region, 
			m.IncomeGroup
FROM metadata_staging AS m 
JOIN iso_countries AS i 
			ON m.CountryCode = i.CountryCode;
			
➤-- Create fact table

CREATE TABLE gdp_fact AS 
SELECT
			g.CountryCode, 
			g.CountryName, 
			g.Year, 
			g.GDP
FROM gdp_cleaned AS g 
JOIN country_dim AS c 
			ON g.CountryCode = c.CountryCode;
			
			
********** 5. GDP GROWTH RATE ANALYSIS ********** 

➤-- Calculate Year-over-Year GDP growth per country

WITH gdp_growth AS (
    SELECT 
        CountryCode,
        CountryName,
        Year,
        GDP,
        LAG(GDP) OVER (
            PARTITION BY CountryCode 
            ORDER BY Year
        ) AS prev_gdp
    FROM gdp_fact
)

SELECT 
    CountryName,
    Year,
    GDP,
    prev_gdp,
	((GDP - prev_gdp) * 100.0 / prev_gdp) AS growth_rate
FROM gdp_growth
ORDER BY CountryName, Year;

➤-- Top 3 countries per year 

WITH ranked AS (
    SELECT 
        CountryName,
        Year,
        GDP,
        DENSE_RANK() OVER (
            PARTITION BY Year
            ORDER BY GDP DESC
        ) AS rank
    FROM gdp_fact
)

SELECT *
FROM ranked
WHERE rank <= 3;


********** 6. REGIONAL ANALYSIS ********** 

➤ -- Region with highest GDP per year

WITH regional_gdp AS (
    SELECT 
        c.Region,
        g.Year,
        SUM(g.GDP) AS total_gdp
    FROM gdp_cleaned g
    INNER JOIN country_dim c
        ON g.CountryCode = c.CountryCode
    GROUP BY c.Region, g.Year
),

ranked_region AS (
    SELECT 
        Region,
        Year,
        total_gdp,

        DENSE_RANK() OVER (
            PARTITION BY Year
            ORDER BY total_gdp DESC
        ) AS rank_region
    FROM regional_gdp
)

SELECT 
    Region,
    Year,
    total_gdp
FROM ranked_region
WHERE rank_region = 1
ORDER BY Year;

➤-- Top country per region 

WITH ranked AS (
    SELECT 
        c.Region,
        g.CountryName,
        g.Year,
        g.GDP,
        DENSE_RANK() OVER (
            PARTITION BY c.Region, g.Year
            ORDER BY g.GDP DESC
        ) AS rank
    FROM gdp_fact g
    JOIN country_dim c 
        ON g.CountryCode = c.CountryCode
)

SELECT *
FROM ranked
WHERE rank = 1;


********** 7. INCOME GROUP ANALYSIS **********

➤-- Growth rate by Income Group

WITH income_gdp AS (
    SELECT 
        c.IncomeGroup,
        g.Year,
        SUM(g.GDP) AS total_gdp
    FROM gdp_fact g
    JOIN country_dim c 
        ON g.CountryCode = c.CountryCode
    GROUP BY c.IncomeGroup, g.Year
),

growth_calc AS (
    SELECT 
        IncomeGroup,
        Year,
        total_gdp,
        LAG(total_gdp) OVER (
            PARTITION BY IncomeGroup 
            ORDER BY Year
        ) AS prev_gdp
    FROM income_gdp
)

SELECT 
    IncomeGroup,
    AVG((total_gdp - prev_gdp) * 100.0 / prev_gdp) AS avg_growth_rate
FROM growth_calc
WHERE prev_gdp IS NOT NULL
AND IncomeGroup IS NOT NULL
GROUP BY IncomeGroup
ORDER BY avg_growth_rate DESC;


********** 8. TOP 10 HIGHEST GDP IN THE MIDDLE EAST **********

➤-- Top 10 GDP countries in the Middle East (latest year)

WITH latest_year AS (
    SELECT MAX(Year) AS max_year
    FROM gdp_fact
),

middle_east_gdp AS (
    SELECT 
        g.CountryName,
        g.Year,
        g.GDP
    FROM gdp_fact g
    JOIN country_dim c 
        ON g.CountryCode = c.CountryCode
    WHERE c.Region = 'MIDDLE EAST & NORTH AFRICA'
      AND g.Year = (SELECT max_year FROM latest_year)
),

ranked AS (
    SELECT *,
        DENSE_RANK() OVER (
            ORDER BY GDP DESC
        ) AS ranking
    FROM middle_east_gdp
)

SELECT *
FROM ranked
WHERE ranking <= 10;
















