SELECT * 
FROM Staff
	INNER JOIN
	Staff_Roles ON 1=1;

-- Select all animal adoption records with ID and Breed: The inner join will only accept those animals that have been adopted
SELECT	AD.*, A.Implant_Chip_ID, A.Breed 
FROM	Animals AS A
		INNER JOIN
		Adoptions AS AD
		ON	AD.Name = A.Name
			AND
			AD.Species = A.Species;

-- change the inner join to a left outer and the Animals pulled from non-adopted will be included
SELECT	AD.*, A.Implant_Chip_ID, A.Breed 
FROM	Animals AS A
		LEFT OUTER JOIN
		Adoptions AS AD
		ON	AD.Name = A.Name
			AND
			AD.Species = A.Species;

SELECT * 
FROM Animals;


SELECT * 
FROM	Animals A
		LEFT OUTER JOIN
		Adoptions AD
		ON AD.Name = A.Name AND AD.Species = A.Species
		INNER JOIN -- This inner join will eliminate all that don't contain an adopter email, it removes existing values that doing match this condition
		Persons P
		ON P.email = AD.Adopter_Email;

SELECT * 
FROM	Animals A
		LEFT OUTER JOIN
		(Adoptions AD
		INNER JOIN -- This inner join will work before the Animals is joined, so the elimination won't occur
		Persons P
		ON P.email = AD.Adopter_Email) -- The parentheses are not actually necessary
		ON AD.Name = A.Name AND AD.Species = A.Species;

-- This is the same as above
SELECT * 
FROM	Animals A
		LEFT OUTER JOIN
			Adoptions AD
			INNER JOIN
			Persons P
			ON P.email = AD.Adopter_Email -- The parentheses are not actually necessary
		ON AD.Name = A.Name AND AD.Species = A.Species;


-- CHALLENGE - Write an query to report animals and their vaccinations. Include animals that have not been vaccinated.
-- The report should show Animal's name, species, breed, primary color, vaccination time, vaccine name, staff member's first name, last name, and role.

SELECT A.Name, A.Species, A.Breed, A.Primary_Color, V.Vaccination_Time, V.Vaccine, P.First_Name, P.Last_Name, SA.Role
FROM Vaccinations V
	INNER JOIN Persons P ON P.email = V.email
	INNER JOIN Staff_Assignments SA ON SA.email = V.email
	RIGHT OUTER JOIN Animals A ON A.Name = V.Name and A.Species = V.Species;