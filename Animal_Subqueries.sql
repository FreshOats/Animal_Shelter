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
