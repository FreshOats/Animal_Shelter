--RANK FUNCTIONS
--Show the top 3 from each species by number of checkups
-- This includes species from our reference table with no checkups

SELECT  s.species, rc.name, 
        COUNT(rc.checkup_time) AS number_of_checkups
FROM    routine_checkups AS rc
        RIGHT OUTER JOIN
        reference.species AS s
            ON s.species = rc.species
GROUP BY s.species, rc.NAME
ORDER BY s.species ASC, number_of_checkups DESC;

--The long ugly version for rank that includes a tie-breaker for multiples

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
add_count_of_more_checked_animals AS
(   SELECT  *, 
            (   SELECT  COUNT(*)
                FROM    animal_checkups AS ac2
                WHERE   ac2.species = ac1.species
                        AND 
                        (   ac2.number_of_checkups > ac1.number_of_checkups
                            OR
                            ac2.number_of_checkups = ac1.number_of_checkups
                            AND ac2.name > ac1.name
                        )
            ) AS number_of_more_checked_animals
    FROM    animal_checkups AS ac1
)
SELECT  *
FROM    add_count_of_more_checked_animals
WHERE   number_of_more_checked_animals < 3
ORDER BY species ASC, number_of_checkups DESC;


-- The WINDOW FUNCTION version, -- much better performance
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


-- RANK and DENSE_RANK

WITH all_ranks AS
(   SELECT  species, name, 
            COUNT(*) AS number_of_checkups, 
            ROW_NUMBER () OVER W AS row_number, 
            RANK () OVER W AS rank, 
            DENSE_RANK () OVER W as dense_rank
    FROM    routine_checkups
    GROUP BY species, name 
    WINDOW W AS (PARTITION BY species ORDER BY COUNT(*) DESC)
)
SELECT  *
FROM    all_ranks
ORDER BY species ASC, number_of_checkups DESC;


-- Weight analysis statistics

WITH average_weights AS
(   SELECT  species, name, 
            CAST (AVG(weight) AS DECIMAL (5, 2)) AS average_weight
    FROM    routine_checkups
    GROUP BY    species, name
    ORDER BY    species DESC, average_weight DESC
)
SELECT  *, 
        PERCENT_RANK ()  OVER W AS percent_rank, 
        CUME_DIST () OVER W AS cumulative_distribution
FROM average_weights
WINDOW      W AS (PARTITION BY species ORDER BY average_weight)
ORDER BY    species DESC, average_weight DESC;

--CHALLENGE
-- Write a query that returns 
-- TOP 25% of animals per species
-- with the fewest temperature exceptions
-- Temp exceptions are deviations of 0.5% +/- of the average per species
-- If 2+ animals of the same species have the same # of temperature exceptions, the more recent should be returned
-- No need to return animals tied over the 25% mark
-- Segment into 4 equally sized groups per species
-- If # of animals per species does not divide by 4 with remainder, may return 1 more animal, but not 1 less 

-- PLAN 
-- 1. Get average temperature per species
-- 2. Find the % difference per animal per species
-- 3. Determine whether the temp is an exceptions
-- 4. Count exceptions per animal per species
-- 5. Rank using dense rank ascending
-- 6. Keep only the top 25% 
-- 7. Remove duplicate ranks, keeping only the most recent based on checkout_time

WITH species_average_temp AS
(   SELECT  species, 
            CAST( AVG(temperature) AS DECIMAL (6, 2)) AS average_temp_per_species
    FROM    routine_checkups
    GROUP BY species
), 
acceptable_temps AS
(   SELECT  *, 
            CAST ( average_temp_per_species * 1.005 AS DECIMAL (5, 2)) AS upper_temp_limit,
            CAST ( average_temp_per_species * 0.995 AS DECIMAL (5, 2)) AS lower_temp_limit 
    FROM    species_average_temp
    GROUP BY species, average_temp_per_species
), --SELECT  *   FROM    acceptable_temps    ORDER BY species ASC;    
temperatures_with_limits AS
(   SELECT  rc.name, 
            rc.species,
            a.upper_temp_limit, 
            a.lower_temp_limit, 
            CAST (rc.temperature AS DECIMAL (5,2)) AS temperature
    FROM    acceptable_temps AS a
            RIGHT OUTER JOIN 
            routine_checkups AS rc
                ON a.species = rc.species
)  --SELECT * FROM temperatures_with_limits ORDER BY species ASC    
SELECT  name, 
        species, 
        upper_temp_limit, 
        lower_temp_limit, 
        temperature, 
        (   SELECT  CASE WHEN 
                    (temperature >= upper_temp_limit) 
                    OR 
                    (temperature <= lower_temp_limit)
                    THEN 1
                    ELSE 0
                    END
            FROM temperatures_with_limits
            GROUP BY species
        ) AS Exceptions
FROM temperatures_with_limits









SELECT  name, species,  
        COUNT(temperature), 
        (   SELECT  COUNT(temperature)
            FROM    routine_checkups
            WHERE   (temperature >= upper_temp_limit) 
                    OR 
                    (temperature <= lower_temp_limit)
        ) AS Exceptions
FROM temperatures_with_limits
GROUP BY species, name
ORDER BY Species ASC, Name ASC;





SELECT  species, 
        name, 
        COUNT(temperature) AS temperature_readings
FROM    routine_checkups
-- WHERE   (species = 'Rabbit' AND (temperature >= 102.37) OR (temperature <= 101.35))
--         OR 
--         (species = 'Dog' AND (temperature >= 101.55) OR (temperature <= 100.53))
--         OR 
--         (species = 'Cat' AND (temperature >= 101.60) OR (temperature <= 100.58))
GROUP BY species, name
ORDER BY species DESC, Exceptions DESC


--- SOLUTION
WITH checkups_with_temperature_differences
AS 
(   SELECT  species, name, temperature, checkup_time, 
            CAST(   AVG(temperature)
                    OVER (PARTITION BY species)
                AS DECIMAL (5,2)
                ) AS species_average_temperature, 
            CAST(   temperature - AVG(temperature)
                    OVER (PARTITION BY species)
                AS DECIMAL (5,2)
                ) AS difference_from_average
    FROM routine_checkups
), --SELECT * FROM checkups_with_temperature_differences ORDER BY species, difference_from_average;
temperature_differences_with_exception_indicator
AS 
(   SELECT  *,
            CASE
            WHEN ABS(difference_from_average / species_average_temperature) >= 0.005
                THEN 1
                ELSE 0
            END AS is_temperature_exception
    FROM    checkups_with_temperature_differences
), --  SELECT * FROM temperature_differences_with_exception_indicator ORDER BY species, difference_from_average;
grouped_animals_with_exceptions
AS
(   SELECT  species, name, 
            SUM(is_temperature_exception) AS number_of_exceptions, 
            MAX(    CASE
                    WHEN is_temperature_exception = 1
                        THEN checkup_time
                        ELSE NULL
                    END
            ) AS latest_exception
    FROM temperature_differences_with_exception_indicator
    GROUP BY    species, name
), --  SELECT * FROM grouped_animals_with_exceptions ORDER BY species, number_of_exceptions;
animal_exceptions_with_ntile
AS 
(   SELECT  *, 
            NTILE(4) 
            OVER    (PARTITION BY species
                    ORDER BY number_of_exceptions ASC, latest_exception DESC
                    ) AS ntile
    FROM grouped_animals_with_exceptions
) 
SELECT  * 
FROM animal_exceptions_with_ntile 
WHERE ntile=1  -- this is the first quartile (top 25%)
ORDER BY species ASC, number_of_exceptions ASC, latest_exception DESC;



-- OFFSET FUNCTIONS


SELECT  species, name, checkup_time, Weight
FROM    routine_checkups
ORDER BY species ASC, name ASC, checkup_time ASC;

-- show animal checkups and how much weight they have gained since the last checkup
SELECT  species, name, checkup_time, weight, 
        weight - LAG (weight)
                OVER ( PARTITION BY species, NAME
                        ORDER BY checkup_time ASC) AS weight_gain
FROM    routine_checkups
ORDER BY species ASC, name ASC, checkup_time ASC;


-- show animal checkups and how much weight they have gained in the Last 3 Months
WITH weight_gains AS
(       SELECT  species, name, checkup_time, weight, 
                (weight -       FIRST_VALUE (weight)
                                OVER ( PARTITION BY species, NAME
                                ORDER BY CAST(checkup_time AS DATE) ASC 
                                RANGE BETWEEN   '3 months' PRECEDING
                                                AND 
                                                '1 day' PRECEDING)
                ) AS weight_gain_in_3_months
        FROM    routine_checkups
)
SELECT  * 
FROM    weight_gains
ORDER BY ABS(   weight_gain_in_3_months) DESC NULLS LAST;