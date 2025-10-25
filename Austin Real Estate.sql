

Select *
From home_values;

Select *
From rentals;

Select *
From homevalues_forecast;

-- Cleaning the data: 
-- Removing null values from all tables 


Select *
From home_values
Where HomeValues is Null or HomeValues = ''
;

Select *
From rentals
Where Rent is Null or Rent = ''
;

-- Since we don't have nulls or blanks in the tables let's check the data type 
-- to avoid any mismatch in any calculations that require joins  

DESC home_values;

DESC rentals;

Desc homevalues_forecast;

-- After checking data type, the date columns are identified as text
-- Let's change those to date with a proper format 

Alter table home_values
Add column Date_Converted Date; 

Select * 
from home_values;

Update home_values 
Set Date_Converted = str_to_date (Date, '%m/%d/%Y');

Alter table home_values
Drop column Date;

Alter table home_values
Change Date_Converted Date DATE;


-- Now for the rentals table -------------------------------

Alter table rentals
Add column Converted_Date Date ;

Select * 
from Rentals;

Update rentals 
Set Converted_Date = str_to_date (Date, '%m/%d/%Y');

Alter table rentals
Drop column Date; 

Alter table rentals
Change Converted_Date Date DATE; 

Desc rentals;

Desc home_values;


-- Now that we have the data cleaned let's start the analysis 
-- Starting with the Growth percentage % in home values between the years 2015, 2020,2024, and 2025 

Select *
from home_values;

-- checking if home values on the last day of the year exist 

Select distinct RegionID
from home_values;

-- Since we have 39 zip codes in Austin, we need to have 156 dates for the specified years 

Select distinct RegionID, date  
From home_values
Where Date  in ('2015-12-31', '2020-12-31', '2024-12-31', '2025-8-31');

-- The above are the dates in which homevalues exist for all zip codes in those years 
-- Growth % = ( new - old )/ old *100 

Select distinct base.RegionID, base.city, base.Metro, 
Round((hv_2025.HomeValues  - hv_2015.HomeValues)/ hv_2015.HomeValues *100 ,2) As Last10_Years_Growth, 
Round((hv_2025.HomeValues  - hv_2020.HomeValues)/ hv_2020.HomeValues *100 ,2) As Last5_Years_Growth, 
Round((hv_2025.HomeValues  - hv_2024.HomeValues)/ hv_2024.HomeValues *100 ,2) As Last1_Year_Growth

From home_values As base 
Join home_values As hv_2025
on base.RegionID = hv_2025.RegionID
And hv_2025.Date = '2025-8-31'
Join home_values As hv_2024
on hv_2025.RegionID = hv_2024.RegionID
And hv_2024.Date = '2024-12-31'
Join home_values As hv_2020
on hv_2020.RegionID = hv_2024.RegionID
And hv_2020.Date = '2020-12-31'
Join home_values As hv_2015
on hv_2015.RegionID = hv_2020.RegionID
And hv_2015.Date = '2015-12-31'
ORDER BY 4 DESC

;

-- Now calculating the rental yeild for the same years in the previous step 
-- Rental Yild or ROI = annual rent/ Homevalue (price) *100 
-- Annual rent = monthly rent *12 



    
    
    SELECT 
    r_2025.RegionID,
    r_2025.Metro,
    r_2025.City,
    -- 2025 Data

    r_2025.Rent * 12 AS Annual_Rent_2025,
    h_2025.HomeValues AS HomeValue_2025,
    (r_2025.Rent * 12 / h_2025.HomeValues) * 100 AS Yield_2025,

    -- 2024 Data
    
    r_2024.Rent * 12 AS Annual_Rent_2024,
    h_2024.HomeValues AS HomeValue_2024,
    (r_2024.Rent * 12 / h_2024.HomeValues) * 100 AS Yield_2024,

    -- 2020 Data
    
    r_2020.Rent * 12 AS Annual_Rent_2020,
    h_2020.HomeValues AS HomeValue_2020,
    (r_2020.Rent * 12 / h_2020.HomeValues) * 100 AS Yield_2020,

    -- 2015 Data
    
    r_2015.Rent * 12 AS Annual_Rent_2015,
    h_2015.HomeValues AS HomeValue_2015,
    (r_2015.Rent * 12 / h_2015.HomeValues) * 100 AS Yield_2015

FROM rentals AS r_2025
JOIN home_values AS h_2025 
    ON r_2025.RegionID = h_2025.RegionID
    AND r_2025.Date = '2025-08-31'
    AND h_2025.Date = '2025-08-31'

LEFT JOIN rentals AS r_2024
    ON r_2025.RegionID = r_2024.RegionID
    AND r_2024.Date = '2024-08-31'
LEFT JOIN home_values AS h_2024
    ON r_2025.RegionID = h_2024.RegionID
    AND h_2024.Date = '2024-08-31'

LEFT JOIN rentals AS r_2020
    ON r_2025.RegionID = r_2020.RegionID
    AND r_2020.Date = '2020-08-31'
LEFT JOIN home_values AS h_2020
    ON r_2025.RegionID = h_2020.RegionID
    AND h_2020.Date = '2020-08-31'

LEFT JOIN rentals AS r_2015
    ON r_2025.RegionID = r_2015.RegionID
    AND r_2015.Date = '2015-08-31'
LEFT JOIN home_values AS h_2015
    ON r_2025.RegionID = h_2015.RegionID
    AND h_2015.Date = '2015-08-31';


-- Now I am going to classify ZIP codes by investment type
-- | Category                   | Characteristics              | Example Metric Rule       |
-- | -------------------------- | ---------------------------- | ------------------------- |
-- | Growth Markets             | High appreciation, low yield | Growth > avg, Yield < avg |
-- | Cash Flow Markets          | High yield, slow growth      | Yield > avg, Growth < avg |
-- | Prime Balanced Markets     | Above average in both        | Growth > avg, Yield > avg |
-- | Risky/Flat Markets         | Below average in both        | Growth < avg, Yield < avg |

-- First I am going to store my previous findings in separate tables 
-- A table for Growth percentage 

DROP TABLE IF EXISTS Growth_Percentage;

CREATE TABLE Growth_Percentage AS
Select distinct base.RegionID, base.city, base.Metro, 
Round((hv_2025.HomeValues  - hv_2015.HomeValues)/ hv_2015.HomeValues *100 ,2) As Last10_Years_Growth, 
Round((hv_2025.HomeValues  - hv_2020.HomeValues)/ hv_2020.HomeValues *100 ,2) As Last5_Years_Growth, 
Round((hv_2025.HomeValues  - hv_2024.HomeValues)/ hv_2024.HomeValues *100 ,2) As Last1_Year_Growth

From home_values As base 
Join home_values As hv_2025
on base.RegionID = hv_2025.RegionID
And hv_2025.Date = '2025-8-31'
Join home_values As hv_2024
on hv_2025.RegionID = hv_2024.RegionID
And hv_2024.Date = '2024-12-31'
Join home_values As hv_2020
on hv_2020.RegionID = hv_2024.RegionID
And hv_2020.Date = '2020-12-31'
Join home_values As hv_2015
on hv_2015.RegionID = hv_2020.RegionID
And hv_2015.Date = '2015-12-31'
ORDER BY 4 DESC
;
-- A table for rental yield --------------

DROP TABLE IF EXISTS Rental_Yield;

CREATE TABLE Rental_Yield AS
 SELECT 
    r_2025.RegionID,
    -- 2025 Data

    r_2025.Rent * 12 AS Annual_Rent_2025,
    h_2025.HomeValues AS HomeValue_2025,
    (r_2025.Rent * 12 / h_2025.HomeValues) * 100 AS Yield_2025,

    -- 2024 Data
    
    r_2024.Rent * 12 AS Annual_Rent_2024,
    h_2024.HomeValues AS HomeValue_2024,
    (r_2024.Rent * 12 / h_2024.HomeValues) * 100 AS Yield_2024,

    -- 2020 Data
    
    r_2020.Rent * 12 AS Annual_Rent_2020,
    h_2020.HomeValues AS HomeValue_2020,
    (r_2020.Rent * 12 / h_2020.HomeValues) * 100 AS Yield_2020,

    -- 2015 Data
    
    r_2015.Rent * 12 AS Annual_Rent_2015,
    h_2015.HomeValues AS HomeValue_2015,
    (r_2015.Rent * 12 / h_2015.HomeValues) * 100 AS Yield_2015

FROM rentals AS r_2025
JOIN home_values AS h_2025 
    ON r_2025.RegionID = h_2025.RegionID
    AND r_2025.Date = '2025-08-31'
    AND h_2025.Date = '2025-08-31'

LEFT JOIN rentals AS r_2024
    ON r_2025.RegionID = r_2024.RegionID
    AND r_2024.Date = '2024-08-31'
LEFT JOIN home_values AS h_2024
    ON r_2025.RegionID = h_2024.RegionID
    AND h_2024.Date = '2024-08-31'

LEFT JOIN rentals AS r_2020
    ON r_2025.RegionID = r_2020.RegionID
    AND r_2020.Date = '2020-08-31'
LEFT JOIN home_values AS h_2020
    ON r_2025.RegionID = h_2020.RegionID
    AND h_2020.Date = '2020-08-31'

LEFT JOIN rentals AS r_2015
    ON r_2025.RegionID = r_2015.RegionID
    AND r_2015.Date = '2015-08-31'
LEFT JOIN home_values AS h_2015
    ON r_2025.RegionID = h_2015.RegionID
    AND h_2015.Date = '2015-08-31';

SELECT * FROM Growth_Percentage ;
SELECT * FROM Rental_Yield ;

CREATE OR REPLACE VIEW zip_investment_metrics AS
SELECT 
    g.RegionID,
    g.City,
    g.Metro,
    g.Last10_Years_Growth,
    g.Last5_Years_Growth,
    g.Last1_Year_Growth,
    y.Annual_Rent_2025,
    y.HomeValue_2025,
    y.Yield_2025,
    y.Annual_Rent_2024,
    y.HomeValue_2024,
    y.Yield_2024,
    y.Annual_Rent_2020,
    y.HomeValue_2020,
    y.Yield_2020,
    y.Annual_Rent_2015,
    y.HomeValue_2015,
    y.Yield_2015
FROM growth_percentage AS g
JOIN rental_yield AS y 
    ON g.RegionID = y.RegionID;


SELECT 
    AVG(Last5_Years_Growth) AS avg_growth,
    AVG(Yield_2025) AS avg_yield
FROM zip_investment_metrics;


SELECT 
    RegionID,
    City,
    Last5_Years_Growth,
    Yield_2025,
    CASE
        WHEN Last5_Years_Growth > 16.54 AND Yield_2025 < 4.15 THEN 'Growth Market'
        WHEN Last5_Years_Growth < 16.54 AND Yield_2025 > 4.15 THEN 'Cash Flow Market'
        WHEN Last5_Years_Growth > 16.54 AND Yield_2025 > 4.15 THEN 'Prime Balanced Market'
        ELSE 'Risky/Flat Market'
    END AS Investment_Type
FROM zip_investment_metrics
ORDER BY Investment_Type, Last5_Years_Growth DESC;


CREATE OR REPLACE VIEW zip_investment_categories AS
SELECT 
    RegionID,
    City,
    Metro,
    Last5_Years_Growth,
    Yield_2025,
    CASE
        WHEN Last5_Years_Growth > (SELECT AVG(Last5_Years_Growth) FROM zip_investment_metrics)
             AND Yield_2025 < (SELECT AVG(Yield_2025) FROM zip_investment_metrics)
            THEN 'Growth Market'
        WHEN Last5_Years_Growth < (SELECT AVG(Last5_Years_Growth) FROM zip_investment_metrics)
             AND Yield_2025 > (SELECT AVG(Yield_2025) FROM zip_investment_metrics)
            THEN 'Cash Flow Market'
        WHEN Last5_Years_Growth > (SELECT AVG(Last5_Years_Growth) FROM zip_investment_metrics)
             AND Yield_2025 > (SELECT AVG(Yield_2025) FROM zip_investment_metrics)
            THEN 'Prime Balanced Market'
        ELSE 'Risky/Flat Market'
    END AS Investment_Type
FROM zip_investment_metrics
ORDER BY Investment_Type, Last5_Years_Growth DESC;

select *
from zip_investment_categories;




