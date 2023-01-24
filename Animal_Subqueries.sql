--Show adoption rows including fees. Max Fee ever paid, and discount from Max in percent.

SELECT	MAX(Adoption_Fee) -- finds the maximum fee
FROM	Adoptions;

SELECT *,	(SELECT	MAX(Adoption_Fee) FROM	Adoptions) AS Max_Fee, 
			(((SELECT MAX(Adoption_Fee) 
				FROM	Adoptions) - Adoption_Fee)*100)/(SELECT	MAX(Adoption_Fee) 
														FROM	Adoptions) AS Discount_Percent
FROM Adoptions;

-- Now do this for species
-- Can do this dynamically

--Dogs... cats and rabbits would change the where condition... but can use a reference from outer query
SELECT *, 
		(	SELECT	MAX(Adoption_Fee)
			FROM Adoptions
			WHERE Species = 'Dog'
		) AS Max_Fee
FROM Adoptions;

-- Both refer to the same table adoptions
SELECT *, 
		(	SELECT	MAX(Adoption_Fee)
			FROM Adoptions AS A2
			WHERE A2.Species = A1.Species
		) AS Max_Fee
FROM Adoptions A1; -- We start here, looking at table A1, then process * rows, next pull data from table A2 
-- only looking at the species if it matches the species from the current row in A1

-- Show all attributes for each person who adopted at least one animal
SELECT COUNT(*) 
FROM Persons; -- 120

SELECT COUNT(*) 
FROM Adoptions; -- 70

SELECT	DISTINCT P.* -- if not distinct, will get duplicates if adopted more than 1 pet
FROM	Persons AS P
		INNER JOIN 
		Adoptions AS A
		ON A.Adopter_Email = P.Email; -- Produces 49 rows, which means some people adopted more than 1 pet

-- could also do... 
SELECT	*
FROM	Persons
WHERE	Email IN (SELECT Email FROM Adoptions); -- It produces 120 results, we were expecting 49

--Fix this with
SELECT	*
FROM	Persons
WHERE	Email IN (SELECT Adopter_Email FROM Adoptions); -- Returns 49 correctly

-- Using the EXISTS verb
SELECT	* 
FROM	Persons P
WHERE	EXISTS (
				SELECT	NULL -- doesn't actually return anything. We can use NULL or * or anything
				FROM	Adoptions AS A
				WHERE	A.Adopter_Email = P.Email
				);
									-- Once again shows up as 49


-- Find animals that were never adopted
--WHERE
-- This can use a where clause looking for names that are null after a join...
SELECT	DISTINCT	AN.Name, AN.Species
FROM	Animals AS AN
		LEFT OUTER JOIN
		Adoptions AS AD
		ON	AD.Name = AN.Name
			AND 
			AD.Species = AN.Species
WHERE	AD.Name IS NULL;



--NOT EXISTS
SELECT	Name, Species
FROM	Animals AS An
WHERE	NOT EXISTS	(
					SELECT NULL
					FROM	Adoptions AS Ad
					WHERE	Ad.Name = An.Name 
							AND 
							Ad.Species = An.Species
					);


-- EXCEPT set operator FTW!!!
SELECT	Name, Species
FROM	Animals
EXCEPT
SELECT	Name, Species
FROM	Adoptions;


--CHALLENGE: Show breeds that were never adopted
SELECT		DISTINCT (Breed)
FROM		Animals
GROUP BY	Breed

EXCEPT

SELECT		DISTINCT (Breed)
FROM		Animals AS An
			RIGHT OUTER JOIN
			Adoptions AS Ad ON Ad.Name = An.Name
							AND 
							Ad.Species = An.Species
GROUP  BY	Breed	
;

-- COURSE SOLUTIONS: 

SELECT	Species, Breed
FROM	Animals
EXCEPT
SELECT	An.Species, An.Breed
FROM	Animals AS An
		INNER JOIN 
		Adoptions AS Ad
		ON	An.Species = Ad.Species
			AND 
			An.Name = Ad.Name;



USE Animal_Shelter;


-- Show adopters who adopted 2 animals in 1 day
SELECT	A1.Adopter_email, A1.Adoption_date,
		A1.name AS Name1, A2.Name AS Name2, 
		A1.species AS Species1, A2.Species AS Species2
FROM	Adoptions AS A1
		INNER JOIN 
		Adoptions AS A2
		ON	A1.adopter_email = A2.adopter_email
			AND
			A1.adoption_date = A2.adoption_date
			AND (
				(A1.Name = A2.Name AND A1.Species > A2.Species)
				OR 
				(A1.Name > A2.Name AND A1.Species = A2.Species)
				OR 
				(A1.Name > A2.Name AND A1.Species <> A2.Species)
				)
ORDER BY A1.adopter_email, A1.adoption_date;



-- The Top End Per Group Challenge
-- Show animals with their most recent vaccination

SELECT	A.Name, A.Species, A.Primary_Color, A.Breed, 
		(	SELECT	Vaccine
			FROM	Vaccinations AS V
			WHERE	V.Name = A.Name
					AND 
					V.Species = A.Species
			ORDER BY V.Vaccination_Time DESC
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS Last_Vaccine
FROM	Animals AS A;



--Alternative approach to this using a LATERAL JOIN (CROSS APPLY in Server)
SELECT	A.Name, A.Species, A.Primary_color, A.Breed, 
		Last_Vaccination.*
FROM	Animals A
		CROSS APPLY -- OUTER APPLY will return the NULL vaccinations
		(	SELECT V.Vaccine, V.Vaccination_Time
			FROM	Vaccinations AS V
			WHERE	V.Name = A.Name 
					AND 
					V.Species = A.Species
			ORDER BY V.Vaccination_Time DESC
			OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY
		) AS Last_Vaccination;






-- Find Purebred candidates of the same species and breed
-- breed is not null
-- MY SOLUTION
SELECT	A1.Species, A1.Breed, A1.Name AS Male, A2.Name AS Female
FROM	Animals AS A1
		INNER JOIN 
		Animals AS A2
		ON	A1.species = A2.species
			AND 
			A1.breed = A2.breed
WHERE	A1.Gender = 'M' -- No need to as the IS NOT NULL because of the equality of a1.breed = a2.breed 
		AND 
		A2.Gender = 'F'
ORDER BY A1.Species, A1.Breed
;

--COURSE SOLUTION 1
SELECT	A1.Species, A1.Breed, A1.Name AS Male, A2.Name AS Female
FROM	Animals AS A1
		INNER JOIN 
		Animals AS A2
		ON	A1.species = A2.species
			AND 
			A1.breed = A2.breed
			AND 
			A1.Gender > A2.Gender
ORDER BY A1.Species, A1.Breed
;

USE Animal_Shelter;


-- This will find the sum of adoption fees on a particular date, but cannot find the names of animals, as they are not aggregates
SELECT	Adoption_Date, 
		SUM(Adoption_Fee) AS Total_Fee
FROM Adoptions
GROUP BY Adoption_Date
HAVING COUNT(*) >1;

-- If we want to show all anuimals adopted on a particular day, we can use the STRING_AGG funciton on Server (GROUP_CONCAT on MySQL and SQLite)
SELECT	Adoption_Date, 
		SUM(Adoption_Fee) AS Total_Fee, 
		STRING_AGG(CONCAT(Name, ' the ', Species), ', ')
		WITHIN GROUP(ORDER BY Species, Name) AS Adopted_Animals
FROM Adoptions
GROUP BY Adoption_Date
HAVING COUNT(*) >1;

-- IF we add breeds, where there are null values, the CONCAT will work returning a blank for the null, but addition will cancel the whole row
SELECT	AD.Adoption_Date, 
		SUM(AD.Adoption_Fee) AS Total_Fee, 
		STRING_AGG(CONCAT(AN.Name, ' the ', AN.Breed, ' ', AN.Species), ', ')
		WITHIN GROUP(ORDER BY AN.Species, AN.Breed, AN.Name) AS Using_Concat, 
		STRING_AGG(AN.Name + ' the ' + AN.Breed + ' ' +  AN.Species, ', ')
		WITHIN GROUP(ORDER BY AN.Species, AN.Breed, AN.Name) AS Using_Plus -- those using plus lose the whole row of animals without breeds
FROM	Adoptions AS AD
		INNER JOIN
		Animals AS AN ON AN.Species = AD.Species AND AN.Name = AD.Name
GROUP BY Adoption_Date
HAVING COUNT(*) >1;

-- WE not want to rank the animals in order of most to fewest vaccinations
SELECT	Name, 
		Species, 
		COUNT(*) AS Num_Vax
FROM	Vaccinations
GROUP BY Name, Species
ORDER BY Species, Num_Vax DESC;

-- THIS IS POSTGRES CODE... it returns something different with the AVG on Server
WITH Vaccination_Ranking AS
(	SELECT	Name, Species, COUNT(*) AS Num_Vax
	FROM	Vaccinations
	GROUP BY Name, Species)
SELECT	Species, MAX(Num_Vax) AS Max_Vax, MIN(Num_Vax) AS Min_Vax, 
		CAST(AVG(Num_Vax) AS DECIMAL(9, 2)) AS Avg_Vax
FROM	Vaccination_Ranking
GROUP BY Species;

--POSTGRES
--What would be the rank of a hypothetical animal that received X vaccinations?
WITH Vaccination_Ranking AS
(	SELECT	Name, Species, COUNT(*) AS Num_Vax
	FROM	Vaccinations
	GROUP BY Name, Species)
SELECT	Species, MAX(Num_Vax) AS Max_Vax, MIN(Num_Vax) AS Min_Vax, 
		CAST(AVG(Num_Vax) AS DECIMAL(9, 2)) AS Avg_Vax, 
		DENSE_RANK(5)	WITHIN GROUP (ORDER BY Num_Vax DESC) AS How_Would_X_Rank
FROM	Vaccination_Ranking
GROUP BY Species;


--Write the number of annual, monthly, and overall adoptions
-- Year
SELECT YEAR(Adoption_Date) AS Year, COUNT(*) AS Annual_Adoptions
FROM Adoptions
GROUP BY	YEAR(Adoption_date);

SELECT YEAR(Adoption_Date) AS Year, MONTH(Adoption_Date) AS Month, COUNT(*) AS Monthly_Adoptions
FROM	Adoptions
GROUP BY	YEAR(Adoption_date), MONTH(Adoption_Date);

SELECT COUNT(*) AS Total_Adoptions
FROM Adoptions
GROUP BY ();

-- TO Union these together, need to have matching numbers of columns
SELECT YEAR(Adoption_Date) AS Year, MONTH(Adoption_Date) AS Month, COUNT(*) AS Monthly_Adoptions
FROM	Adoptions
GROUP BY	YEAR(Adoption_date), MONTH(Adoption_Date)
UNION ALL
SELECT YEAR(Adoption_Date) AS Year, NULL AS Month, COUNT(*) AS Annual_Adoptions
FROM Adoptions
GROUP BY	YEAR(Adoption_date)
UNION ALL
SELECT NULL AS Year, NULL AS Month, COUNT(*) AS Total_Adoptions
FROM Adoptions
GROUP BY ();

--Using Grouiping Sets
SELECT YEAR(Adoption_Date) AS Year, MONTH(Adoption_Date) AS Month, COUNT(*) AS Monthly_Adoptions
FROM	Adoptions
GROUP BY	GROUPING SETS ((YEAR(Adoption_date), MONTH(Adoption_Date))); --needs a second set of parentheses to group them by both year and month simultaneously
--Without the second set of parentheses, it act like a union, and executes the query per grouping set. 

SELECT YEAR(Adoption_Date) AS Year, COUNT(*) AS Annual_Adoptions
FROM Adoptions
GROUP BY	GROUPING SETS(	YEAR(Adoption_date));

SELECT COUNT(*) AS Total_Adoptions
FROM Adoptions
GROUP BY GROUPING SETS(());


--Using Grouiping Sets to do this all at once
SELECT YEAR(Adoption_Date) AS Year, MONTH(Adoption_Date) AS Month, COUNT(*) AS Monthly_Adoptions
FROM	Adoptions
GROUP BY	GROUPING SETS	(	(YEAR(Adoption_date), MONTH(Adoption_Date)), 
								YEAR(Adoption_Date), 
								() 
							)
ORDER BY	Year, Month;  


--Show how many total adoptions, adoptions per species, and adoptions per breed
SELECT	Species, 
		Breed, 
		COUNT(*) AS Number_Animals
FROM	Animals
GROUP BY GROUPING SETS
		(	
			Species, 
			Breed, 
			()
		)
ORDER BY Species, Breed; -- returns an issue with the count for NULL as a breed, and the total amount


--To alleviate this issue, we can use COALESCE To add a string in place of the NULL, then add a CASE statement with GROUPING
SELECT	COALESCE(Species, 'All') AS Species, -- Coalesce will change all NULL values into ALL 
		CASE
			WHEN GROUPING(Breed) = 1 -- produces a binary T/F, where 1 is TRUE if the grouping is Breed
			THEN 'All'
			ELSE Breed
		END AS Breed,
		COUNT(*) AS Number_Animals
FROM	Animals
GROUP BY GROUPING SETS
		(	
			Species, 
			Breed, 
			()
		)
ORDER BY Species, Breed; 



-- ORDERED SETS CHALLENGE 
--MY SOLUTION
-- Count the number of vaccinations per:
-- Year, Species, Species and Year, Staff Member, Staff Member and Species, Latest Vaccination year for each group
SELECT	YEAR(V.Vaccination_Time) AS Year, 
		COALESCE(Species, 'All') AS Species,
		V.Email,
		CONCAT(P.First_Name, ' ', P.Last_name) AS Staff_Member, 
		COUNT(V.Vaccination_Time) AS Number_Vaccines, 
		MAX(YEAR(V.Vaccination_Time)) AS Latest_Vaccine
FROM	Vaccinations AS V
		INNER JOIN
		Persons AS P ON P.email = V.email
GROUP BY GROUPING SETS
		(	
			YEAR(V.Vaccination_Time), 
			Species, 
			(	YEAR(V.Vaccination_Time), Species), 
			(V.Email),
			(V.Email, V.Species)
		)
ORDER BY Year DESC


--COURSE SOLUTION
SELECT	COALESCE(CAST(YEAR(V.Vaccination_Time) AS VARCHAR(10)), 'All Years') AS Year, -- Cast the year (int) as a varchar to add string for NULLS
		COALESCE(V.Species, 'All Species') AS Species,
		COALESCE(V.Email, 'All Staff') AS Email,
		CASE WHEN GROUPING(V.Email) = 0
			THEN MAX(P.First_Name) 
			ELSE '' 
			END AS First_Name, -- Dummy aggregate 
		CASE WHEN GROUPING(V.Email) = 0
			THEN MAX(P.Last_Name) 
			ELSE ''
			END AS Last_Name, -- Dummy Aggregate
		COUNT(*) AS Number_of_Vaccinations, 
		MAX(YEAR(V.Vaccination_Time)) AS Latest_Vaccination_Year
FROM	Vaccinations AS V
		INNER JOIN 
		Persons AS P ON P.Email = V.Email
GROUP BY GROUPING SETS (
							(),
							YEAR(V.Vaccination_Time), 
							V.Species, 
							(YEAR(V.Vaccination_Time), V.Species), 
							V.Email, 
							(V.Email, V.Species)
						)
ORDER BY Species, Year, First_Name, Last_Name;





------RECURSION
-- Web link crawler
DROP TABLE IF EXISTS Weblinks;

CREATE TABLE Weblinks 
(
	URL		CHAR(3) NOT NULL,
	Points_To_URL CHAR(3) NOT NULL,
	PRIMARY KEY (URL, Points_To_URL),
	CHECK (URL <> Points_To_URL)
);

INSERT INTO weblinks (URL, Points_To_URL)
VALUES	('U1', 'U9'), ('U1', 'U3'), 
		('U2', 'U8'), ('U2', 'U6'),
		('U3', 'U2') ,('U3', 'U4') ,('U3', 'U5') ,('U3', 'U9') ,
		('U4', 'U2') ,('U5', 'U4') ,('U5', 'U6')

SELECT	* 
FROM	Weblinks
ORDER BY URL, Points_To_URL;

-- Crawl the web starting with URL U4
WITH Crawler (From_URL, To_URL, Level)
AS
(
	SELECT	CAST('>' AS CHAR(3)), 
			CAST('U4' AS CHAR(3)),
			CAST(0 AS INT)
	UNION ALL
	SELECT	c.To_URL, 
			W.Points_To_URL,
			level + 1
	FROM	Weblinks AS W 
			INNER JOIN 
			Crawler AS C
			ON W.URL = C.To_URL
)
SELECT	CONCAT(REPLICATE('-', Level), ' ', from_URL, ' -> ',  to_URL) AS URL_Path -- This replicator adds dashes for each replication 
FROM	Crawler
ORDER BY Level, From_URL, To_URL;

-- Cleanup
DROP TABLE weblinks;