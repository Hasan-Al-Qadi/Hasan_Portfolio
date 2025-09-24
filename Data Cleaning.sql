
-- Data Cleaning 


-- In this project I will :

-- 1. Remove Duplicates. 
-- 2. Standarize the Data. 
-- 3. Remove Null Values or Blanks. 
-- 4. Remove any irrelevant Columns. 


-- Creating a copy of the table to preserve the data source 


Select *
From new_layoffs;

Create Table new_layoffs_staging
Like new_layoffs;

Insert new_layoffs_staging 
Select *
From new_layoffs;

Select *
From new_layoffs_staging;
---------------------------------------------------------------------

-- 1. Removing Duplicates 

With duplicate_cte as (
Select *,
ROW_NUMBER() OVER( PARTITION BY company,location, industry, total_laid_off, 
percentage_laid_off, `date`,stage, country,funds_raised_millions ) AS row_num
FROM new_layoffs_staging
)


SELECT *
FROM duplicate_cte
WHERE row_num> 1 ; 

CREATE TABLE `new_layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT *
FROM new_layoffs_staging2;


INSERT INTO new_layoffs_staging2
Select *,
ROW_NUMBER() OVER( PARTITION BY company,location, industry, total_laid_off, 
percentage_laid_off, `date`,stage, country,funds_raised_millions ) AS row_num
FROM new_layoffs_staging;

SELECT *
FROM new_layoffs_staging2
WHERE row_num > 1;



DELETE 
FROM new_layoffs_staging2
WHERE row_num > 1;

---------------------------------------------------------------------


-- Standarizing the Data.



SELECT company, TRIM(company)
FROM new_layoffs_staging2;

UPDATE new_layoffs_staging2
SET company= TRIM(company);


SELECT DISTINCT(industry)
FROM new_layoffs_staging2
ORDER BY 1;


SELECT *
FROM new_layoffs_staging2
WHERE industry like 'Crypto%';

UPDATE new_layoffs_staging2
SET industry= 'Crypto'
WHERE industry like 'crypto%';


SELECT DISTINCT(country), TRIM(TRAILING '.' FROM country)
FROM new_layoffs_staging2
ORDER BY 1;

UPDATE new_layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT `date`
FROM new_layoffs_staging2;


UPDATE new_layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE new_layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM new_layoffs_staging2;


---------------------------------------------------------------------

-- 3. Removing Null Values or Blanks. 

SELECT *
FROM new_layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


-- We are going to work on the industry column 
-- First find the null or blank values in the industry column 


SELECT *
FROM new_layoffs_staging2
WHERE industry IS NULL 
OR industry = '';

-- Let's check the Airbnb company and see if we can find its industry 

SELECT *
FROM new_layoffs_staging2
WHERE company = 'Airbnb';

-- So we know that Airbnb is in the travel industry 
-- Now we will populate all the blank industry cells with the right value 


UPDATE new_layoffs_staging2
SET industry = null
WHERE industry = ' ';   





SELECT * 
FROM new_layoffs_staging2
WHERE industry IS NULL 
or industry = '';

SELECT company, industry
FROM new_layoffs_staging2
WHERE company LIKE 'Airbnb';


SELECT t1.company, t1.industry,t2.industry
FROM new_layoffs_staging2 t1 
JOIN new_layoffs_staging2 t2 
   ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = ' ');
   
   
UPDATE new_layoffs_staging2 t1
JOIN new_layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

Select *
FROM new_layoffs_staging2
WHERE industry IS NULL
OR industry = ' ';
 
 -- The only company that still have a Null value for the industry column is Bally's, 
 -- And the reason is that the industry is not mentioned in any other row 
 
 
Select *
FROM new_layoffs_staging2;


---------------------------------------------------------------------
-- 4. Remove any irrelevant Columns. 

ALTER TABLE new_layoffs_staging2
DROP column row_num;

SELECT *
FROM new_layoffs_staging2;

---------------------------------------------------------------------

-- Exploratory Data Analysis 


SELECT YEAR(date) , SUM(total_laid_off)
FROM new_layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 ASC
 ;

Select SUBSTRING( `date`, 1,7) as `month` , sum(total_laid_off)
from new_layoffs_staging2
where SUBSTRING( `date`, 1,7) is not null
group by `month` 
order by 1 asc;



with Rolling_Total as
(
Select SUBSTRING( `date`, 1,7) as `month` , sum(total_laid_off) total_off 
from new_layoffs_staging2
where SUBSTRING( `date`, 1,7) is not null
group by `month` 
order by 1 asc
)
Select `month`, total_off,
 sum(total_off) over( order by `month`) As rolling_total 
from Rolling_Total;


-- Now we are going to look at total_laid_off in terms of companies as a rolling total 

SELECT company, YEAR(`date`), sum(total_laid_off) total_off
FROM new_layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- Now creating a cte to sort them by company and rank them by total laid off. 

WITH  Company_Year (Company, Years, Total_Laid_Off) AS (

SELECT company, YEAR(`date`), sum(total_laid_off) total_off
FROM new_layoffs_staging2
GROUP BY company, YEAR(`date`)

), Company_Year_Rank As (
SELECT *, 
DENSE_RANK() OVER( PARTITION BY Years ORDER BY Total_Laid_off DESC) As Ranking 
FROM Company_Year


)
Select * 
from Company_Year_Rank 
WHERE Ranking <=5
AND Years IS NOT NULL
ORDER BY Years ASC,Total_Laid_off DESC ;







