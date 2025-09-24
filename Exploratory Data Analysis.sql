


-- Exploratory Data Analysis 


   -- 1. Finding the total layoffs in each year and ordering them beased on that.

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
-------------------------------------------------------------------------


-- 2. Now I am going to sort them by company and rank them by total laid off. 

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

