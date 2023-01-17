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