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

------------------------------------------------------------------------------------
-- Starting with quarters, since the quarter function will cross years ending the last quarter on Jan 15
WITH adoption_quarters
AS
(
SELECT 	Species,
		MAKE_DATE (	CAST (DATE_PART ('year', adoption_date) AS INT),
					CASE 
						WHEN DATE_PART ('month', adoption_date) < 4
							THEN 1
						WHEN DATE_PART ('month', adoption_date) BETWEEN 4 AND 6
							THEN 4
						WHEN DATE_PART ('month', adoption_date) BETWEEN 7 AND 9
							THEN 7
						WHEN DATE_PART ('month', adoption_date) > 9
							THEN 10
					END,
					1
				 ) AS quarter_start
FROM 	adoptions
)
-- SELECT * FROM adoption_quarters ORDER BY species, quarter_start;
,quarterly_adoptions
AS
(
SELECT 	COALESCE (species, 'All species') AS species,
		quarter_start,
		COUNT (*) AS quarterly_adoptions,
		COUNT (*) - COALESCE (
					-- For quarters with no previous adoptions use 0, not NULL 
							 	FIRST_VALUE (COUNT (*))
							 	OVER    (PARTITION BY species
							 		  ORDER BY quarter_start ASC
								   	  RANGE BETWEEN 	INTERVAL '3 months' PRECEDING 
												AND 
												INTERVAL '3 months' PRECEDING
						 		        )
							, 0)
		AS adoption_difference_from_previous_quarter,
		CASE 	
			WHEN	quarter_start =	FIRST_VALUE (quarter_start) 
									OVER (PARTITION BY species
										  ORDER BY quarter_start ASC
										  RANGE BETWEEN 	UNBOUNDED PRECEDING
															AND
															UNBOUNDED FOLLOWING
										 )
			THEN 	0
			ELSE 	NULL
		END 	AS zero_for_first_quarter
FROM 	adoption_quarters
GROUP BY	GROUPING SETS 	((quarter_start, species), 
							 (quarter_start)
							)
)
-- SELECT * FROM quarterly_adoptions ORDER BY species, quarter_start;
,quarterly_adoptions_with_rank
AS
(
SELECT 	*,
		RANK ()
		OVER (	PARTITION BY species
				ORDER BY 	COALESCE (zero_for_first_quarter, adoption_difference_from_previous_quarter) DESC,
							-- First quarters are 0, all others NULL
							quarter_start DESC)
		AS quarter_rank
FROM 	quarterly_adoptions
)
-- SELECT * FROM quarterly_adoptions_with_rank ORDER BY species, quarter_rank, quarter_start;
SELECT 	species,
		CAST (DATE_PART ('year', quarter_start) AS INT) AS year,
		CAST (DATE_PART ('quarter', quarter_start) AS INT) AS quarter,
		adoption_difference_from_previous_quarter,
		quarterly_adoptions
FROM 	quarterly_adoptions_with_rank
WHERE 	quarter_rank <= 5
ORDER BY 	species ASC,
			adoption_difference_from_previous_quarter DESC,
			quarter_start ASC;




SELECT * FROM adoption_quarters ORDER BY species, quarter_start



SELECT LAG(admission_date) OVER (ORDER BY admission_date ASC) = LEAD(admission_date) OVER (ORDER BY admission_date DESC)
FROM animals