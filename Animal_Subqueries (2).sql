--Window Functions, Advanced SQL Course
-- Subqueries 

--Show the total number of animals in our shelter ever
SELECT  species, 
        name, 
        primary_color, 
        admission_date, 
        (   SELECT COUNT(*)
            FROM    animals
        ) AS number_of_animals
FROM    animals
ORDER BY admission_date ASC; 

--Now, total number of animals since 2017
SELECT  species, 
        name, 
        primary_color, 
        admission_date, 
        (   SELECT COUNT(*)
            FROM    animals
            WHERE   admission_date >= '2017-01-01'
        ) AS number_of_animals
FROM    animals
WHERE   admission_date >= '2017-01-01' -- this must be duplicated because
--while the count will only return the correct number, it won't filter out
--the rows from the parent function
ORDER BY admission_date ASC; 



--New: Total number of species animals instead of total animals
-- The subquery requires a self relation to maintain species

SELECT  a1.species, 
        a1.name, 
        a1.primary_color, 
        a1.admission_date, 
        (   SELECT  COUNT(*)
            FROM    animals AS a2
            WHERE   a2.species = a1.species
        )   AS number_of_species_animals
FROM    animals AS a1
ORDER BY    a1.species ASC, 
            a1.admission_date ASC;

-- This code can be improved by using an inner join
SELECT  a1.species, 
        a1.name, 
        a1.primary_color, 
        a1.admission_date, 
        species_counts.number_of_species_animals
FROM    animals AS a1
        INNER JOIN
        (   SELECT  species, 
                    COUNT(*) AS number_of_species_animals
            FROM    animals
            GROUP BY species
        )   AS species_counts
        ON a1.species = species_counts.species
ORDER BY    a1.species ASC, 
            a1.admission_date ASC;



-- Only show the number of animals of the same species admitted on the prior date
SELECT  a1.species, 
        a1.name, 
        a1.primary_color, 
        a1.admission_date, 
        (   SELECT  COUNT(*)
            FROM    animals AS a2
            WHERE   a2.species = a1.species
                    AND
                    a2.admission_date < a1.admission_date
        )   AS up_to_previous_day_species_animals
FROM    animals AS a1
ORDER BY    a1.species ASC, 
            a1.admission_date ASC;


--This is problematic, because it's not looking at the previous date, only the last date of admission
--The duplicity of the subquery can be avoided using a WITH clause

WITH filtered_animals AS
(   SELECT *
    FROM    animals
    WHERE   species = 'Dog'
            AND 
            admission_date > '2017-08-01')
SELECT  fa1.species, 
        fa1.name, 
        fa1.primary_color, 
        fa1.admission_date, 
        (   SELECT  COUNT(*)
            FROM    filtered_animals AS fa2
            WHERE   fa2.species = fa1.species
                    AND
                    fa2.admission_date < fa1.admission_date
        )   AS up_to_previous_day_species_animals
FROM    filtered_animals AS fa1
ORDER BY    fa1.species ASC, 
            fa1.admission_date ASC;
