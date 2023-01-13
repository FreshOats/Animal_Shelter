--This query will fail
SELECT COUNT(*) AS CT, Name
FROM Adoptions
WHERE Species='cat';

-- This will count group outputs
SELECT COUNT(*) AS Count, Species
FROM animals
GROUP BY Species;

--Report the number of vaccinations each animal has received, include animals never vaccinated. 
-- Exclude rabbites, rabies vaccines, and animals that were last vaccinated on or after october 1, 2019
-- Show name, species, primary color, breed, number of vaccinations

SELECT	a.Name, 
		a.Species, 
		MAX(a.primary_color) AS Primary_Color, -- dummy aggregate
		MAX(a.Breed) AS Breed, -- dummy aggregate
		COUNT(v.Vaccine) AS Vaccine_Count
		--, COUNT(*)   this didn't work, as it only counted those with vaccines 
FROM	Animals a
		LEFT OUTER JOIN 
		Vaccinations v 
		ON v.Name=a.Name AND v.Species = a.Species
WHERE	a.Species <> 'Rabbit' -- we can't eliminate rabies here, because it removes the nulls :-( 
		AND 
		(v.Vaccine <> 'Rabies' OR v.Vaccine IS NULL) -- when run prior to adding the IS null, it again removes all non-vaccinated beasts
GROUP BY a.Name, 
		a.Species
HAVING	MAX(v.Vaccination_Time) < '20191001' 
		OR
		MAX(v.Vaccination_Time) IS NULL
ORDER BY a.Name, 
		a.Species;		
