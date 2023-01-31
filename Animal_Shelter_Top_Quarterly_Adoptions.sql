-- Write a query that returns the top 5 most improved quarters in terms of the number of adoptions, both per species, and overall.
-- Improvement means the increase in number of adoptions compared to the previous calendar quarter.
-- The first quarter in which animals were adopted for each species and for all species, does not constitute an improvement from zero, and should be treated as no improvement.
-- In case there are quarters that are tied in terms of adoption improvement, return the most recent ones.

WITH 
animal_checkups AS 
(   
    SELECT  s.species, rc.name, 
            COUNT(rc.checkup_time) AS number_of_checkups
    FROM    routine_checkups AS rc
            RIGHT OUTER JOIN
            reference.species AS s
                ON s.species = rc.species
    GROUP BY s.species, rc.NAME
), 
include_row_number_by_number_of_checkups AS
(
    SELECT  *, 
            ROW_NUMBER ()
            OVER    (   PARTITION BY species
                        ORDER BY number_of_checkups DESC, name ASC
                    ) AS row_number
    FROM animal_checkups
)
SELECT  *
FROM    include_row_number_by_number_of_checkups
WHERE   row_number <=3
ORDER BY species ASC, number_of_checkups DESC; 


--NTILE breaks things up into equal groups

SELECT  species, name, admission_date,
        NTILE(8) OVER (ORDER BY admission_date ASC) AS ten_segments
FROM    Animals 
ORDER BY admission_date ASC;





SELECT  s.species, rc.name, 
            COUNT(rc.checkup_time) AS number_of_checkups
    FROM    routine_checkups AS rc
            RIGHT OUTER JOIN
            reference.species AS s
                ON s.species = rc.species
    GROUP BY s.species, rc.NAME

-----------------



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


------------------------


-- First, get all adoptions

SELECT  CASE 
            WHEN    GROUPING(species) = 1
            THEN    'All Species'
            ELSE    species
        END AS Species, 
        COUNT(adoption_date) AS number_of_adoptions
FROM    adoptions
GROUP BY    GROUPING SETS
            (   species, 
                ()
            )
ORDER BY    species;



-- Next, get adoptions by year

SELECT  CASE 
            WHEN    GROUPING(species) = 1
            THEN    'All Species'
            ELSE    species
        END AS Species, 
        CAST( DATE_PART('year', adoption_date) AS INT) AS year, 
        COUNT(adoption_date) AS number_of_adoptions
FROM    adoptions
GROUP BY    GROUPING SETS
            (   species, 
                ()
            ),
            DATE_PART('year', adoption_date)
ORDER BY    species;


-- Next, get adoptions by quarter

SELECT  CASE 
            WHEN    GROUPING(species) = 1
            THEN    'All Species'
            ELSE    species
        END AS Species, 
        CAST( DATE_PART('year', adoption_date) AS INT) AS year,
        CAST( DATE_PART('quarter', adoption_date) AS INT) AS quarter, 
        COUNT(adoption_date) AS number_of_adoptions
FROM    adoptions
GROUP BY    GROUPING SETS
            (   species, 
                ()
            ),
            DATE_PART('year', adoption_date),
            DATE_PART('quarter', adoption_date)

ORDER BY    species ASC, year ASC, quarter ASC;