--Window Functions, Advanced SQL Course
-- Window function alternatives

--Show the total number of animals in our shelter ever
SELECT  species, 
        name, 
        primary_color, 
        admission_date, 
        COUNT (*)
        OVER () AS number_of_animals
FROM    animals
ORDER BY admission_date ASC; 

--Now, total number of animals since 2017
SELECT  species, 
        name, 
        primary_color, 
        admission_date, 
        COUNT (*)
        -- We don't need to use the filter, becuase this is evaluated after the where clause in the parent function
        OVER () AS number_of_animals
FROM    animals
WHERE   admission_date >= '2017-01-01'
ORDER BY admission_date ASC; 


--New: Total number of species animals instead of total animals
-- Only need to add a partition by clause

SELECT  species, 
        name, 
        primary_color, 
        admission_date, 
        COUNT(*)
        OVER (PARTITION BY species) AS number_of_species_animals
FROM    animals
ORDER BY    species ASC,
            admission_date ASC;


            
-- Only show the number of animals of the same species admitted on the prior date
SELECT  species, 
        name, 
        primary_color, 
        admission_date, 
        COUNT(*)
        OVER (  PARTITION BY    species
                ORDER BY        admission_date ASC
                ROWS BETWEEN    UNBOUNDED PRECEDING
                                AND
                                1 PRECEDING
        ) AS up_to_previous_day_species_animals
FROM    animals
ORDER BY    species ASC,
            admission_date ASC;


--This is problematic, because it's not looking at the previous date, only the last date of admission
SELECT  species, 
        name, 
        primary_color, 
        admission_date, 
        COUNT(*)
        OVER (  PARTITION BY    species
                ORDER BY        admission_date ASC
                ROWS BETWEEN    UNBOUNDED PRECEDING
                                AND
                                1 PRECEDING
        ) AS up_to_previous_day_species_animals
FROM    animals
WHERE   species = 'Dog'
        AND 
        admission_date > '2017-08-01'
ORDER BY    species ASC,
            admission_date ASC;

-- this returned an error, as 2 dogs were adopted on the same day, so it should not have returned a 1 in row 2
-- Can be fixed by using other than the ROWS frame - using RANGE instead

SELECT  species, 
        name, 
        primary_color, 
        admission_date, 
        COUNT(*)
        OVER (  PARTITION BY    species
                ORDER BY        admission_date ASC
                RANGE BETWEEN    UNBOUNDED PRECEDING -- RANGE instead of ROWS
                                AND
                                '1 day' PRECEDING
        ) AS up_to_previous_day_species_animals
FROM    animals
WHERE   species = 'Dog'
        AND 
        admission_date > '2017-08-01'
ORDER BY    species ASC,
            admission_date ASC;


-- DEFAULTS, SHORTCUTS, EXCLUSIONS, and NULL HANDLING
SELECT  * 
FROM    routine_checkups
ORDER BY        species ASC, checkup_time ASC;


-- Return an animal's species, name, checkup time, heart rate and a Boolean column that is TRUE only for 
-- animals whose heart rate measurements are ALL either equal to or larger than the average heart rate
-- for their species. 

SELECT  species, 
        name, 
        checkup_time, 
        heart_rate, 
        CAST    (AVG(heart_rate)
                OVER (PARTITION BY species)
                AS DECIMAL (5, 2) 
                ) AS species_average_heart_rate
FROM    routine_checkups
ORDER BY species ASC, checkup_time ASC;

--Use the Boolean EVERY to only show those meeting the condition
SELECT  species, 
        name, 
        checkup_time, 
        heart_rate, 
        EVERY   (       heart_rate
                        >= AVG(heart_rate)
                        OVER (PARTITION BY species)
                ) 
        OVER (PARTITION BY species, name) AS consistently_at_or_above_average -- this FAILS because window functions cannot be nested
FROM    routine_checkups
ORDER BY species ASC, checkup_time ASC;

--Use a WITH clause (CTE), but to actually filter out all of the values that are false, will need to insert another WITH clause for access by the WHERE clause (below)
WITH species_average_heart_rates AS
(       SELECT  species, 
                name, 
                checkup_time, 
                heart_rate, 
                CAST    (AVG(heart_rate)
                        OVER (PARTITION BY species)
                        AS DECIMAL (5, 2) 
                        ) AS species_average_heart_rate
        FROM    routine_checkups
)
SELECT  species, 
        name, 
        checkup_time, 
        heart_rate, 
        EVERY   (heart_rate >= species_average_heart_rate)
                OVER (PARTITION BY species) AS consistently_at_or_above_average
FROM    species_average_heart_rates
ORDER BY species ASC, checkup_time ASC;


--To filter the False values with an additional WITH clause
WITH 
species_average_heart_rates AS
(       SELECT  species, 
                name, 
                checkup_time, 
                heart_rate, 
                CAST    (AVG(heart_rate)
                        OVER (PARTITION BY species)
                        AS DECIMAL (5, 2) 
                        ) AS species_average_heart_rate
        FROM    routine_checkups
), 
consistently_at_or_above_indicator AS
(       SELECT species, 
                name, 
                checkup_time, 
                heart_rate, 
                species_average_heart_rate, 
                EVERY (heart_rate >= species_average_heart_rate)
                OVER (PARTITION BY species, name) AS consistently_at_or_above_average
        FROM    species_average_heart_rates
)
SELECT  DISTINCT species, 
        name, 
        checkup_time, 
        heart_rate, 
        species_average_heart_rate
FROM    consistently_at_or_above_indicator
WHERE   consistently_at_or_above_average
ORDER BY species ASC, checkup_time ASC;


-- SHOW year, month, monthly revenue, and percent of current year
-- The sum aggregations are hard to understand - use a WITH clause instead (below)
SELECT  DATE_PART ('year', adoption_date) AS year,
        DATE_PART ('month', adoption_date) AS month,
        SUM (adoption_fee) AS month_total, 
        CAST    (100 * SUM(adoption_fee) 
                /       SUM (SUM(adoption_fee)) -- this is an aggregate error prior to adding the second SUM, which is a Window aggregate sum of the group aggregate sum
                        OVER (PARTITION BY DATE_PART ('year', adoption_date))
                AS DECIMAL (5,2)
                ) AS annual_percent      
FROM Adoptions
GROUP BY        DATE_PART ('year', adoption_date),
                DATE_PART ('month', adoption_date)
ORDER BY        year ASC, 
                month ASC;

-- Previous query, only replacing the SUM(SUM(X)) with a WITH clause
WITH monthly_grouped_adoptions AS
(       SELECT  DATE_PART ('year', adoption_date) AS year,
                DATE_PART ('month', adoption_date) AS month,
                SUM (adoption_fee) AS month_total
        FROM    Adoptions
        GROUP BY DATE_PART ('year', adoption_date),
                DATE_PART ('month', adoption_date)
 )
SELECT  *, -- because the FROM statement here is pulling from the monthly_grouped_adoptions, we only need to refer to the aliases defined there
        CAST    (100 * month_total 
                /       SUM (month_total)
                        OVER (PARTITION BY year)
                AS DECIMAL (5,2)
                ) AS annual_percent      
FROM monthly_grouped_adoptions
ORDER BY        year ASC, 
                month ASC;


-- CHALLENGE -- Annual Vaccinations Report
-- Write a query that returns all years in which animals were vaccinated, and the total number of vaccinations given that year
-- Return the following columns: 
-- 1. The average number of vaccinations given in the previous two calendar years
-- 2. The percent difference between the current year's number of vaccinations and the average of the previous two years
-- For the first year, return a NULL for both additional columns

WITH    
Yearly_Vaccination_Counts AS
(       SELECT CAST( DATE_PART('year', vaccination_time) AS INT) AS Year, 
                COUNT(*) AS Yearly_Vaccination_Count 
        FROM Vaccinations
        GROUP BY DATE_PART('year', vaccination_time)
) --SELECT  * FROM    Yearly_Vaccination_Counts ORDER BY Year ASC;
, 
Annual_vaccinations_with_previous_2_year_average AS
(
        SELECT  *, 
                CAST(   AVG( Yearly_Vaccination_Count)
                        OVER (  ORDER BY Year ASC 
                                RANGE BETWEEN 2 PRECEDING AND 1 PRECEDING) -- Range is better than rows because we want to specify by year, but if a year was skipped, this will still be correct
                        AS DECIMAL (5, 2)) AS Previous_2_Year_Average
        FROM    Yearly_Vaccination_Counts
)
SELECT  *, 
        CAST ((100 * Yearly_Vaccination_Count / Previous_2_Year_Average)
        AS DECIMAL (5, 2)
        ) AS Percent_change
FROM Annual_vaccinations_with_previous_2_year_average
ORDER BY Year ASC;