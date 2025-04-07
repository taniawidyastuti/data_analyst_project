SELECT * FROM covid_deaths
SELECT * FROM covid_vacc

-- 10 countries with the highest infection rate (case/population) at 5th August 2020
SELECT location, date, total_cases, population, 
ROUND((total_cases::numeric/population::numeric*100)::numeric, 2) AS case_percentage_on_population
FROM covid_deaths
WHERE date = '2020-08-05' AND continent IS NOT NULL
ORDER BY case_percentage_on_population DESC
LIMIT 10;

-- 10 countries with the highest death rate (deaths/cases) at 5th August 2020
SELECT location, date, total_deaths, total_cases, 
ROUND((total_deaths::numeric/total_cases::numeric*100)::numeric, 2) AS death_percentage_on_case
FROM covid_deaths
WHERE date = '2020-08-05' AND continent IS NOT NULL
ORDER BY death_percentage_on_case DESC NULLS LAST
LIMIT 10;

-- Looking at Total Cases vs. Total Deaths
SELECT location, date, total_cases, total_deaths, 
		(total_deaths/total_cases::float*100) AS death_percentage_on_cases
FROM covid_deaths;

-- Looking at Total Cases and Total Deaths on the latest day of each country on the record
-- fl = filter, dc = death_case
WITH fl AS (
SELECT location, MAX(date) AS max_date FROM covid_deaths
GROUP BY location
ORDER BY location),

dc AS (
SELECT location, date, total_cases, total_deaths
FROM covid_deaths
)

SELECT dc.location, dc.date, dc.total_cases, dc.total_deaths,
ROUND((dc.total_deaths::numeric/dc.total_cases*100)::numeric, 2) AS death_percentage

FROM fl JOIN dc
ON fl.location = dc.location AND fl.max_date = dc.date;

-- Looking at Total Cases vs. Population
-- Show what percentage of population got Covid
SELECT location, date, total_cases, population, (total_cases::float/population*100) AS case_percentage
FROM covid_deaths;

-- Looking at countries with the highets infection rate compared to population
-- FROM ME
SELECT location, MAX(case_percentage) AS top_case FROM (
		SELECT location, date, total_cases, population, 
				(total_cases::float/population*100) AS case_percentage_on_population
		FROM covid_deaths) AS sub
GROUP BY location
HAVING MAX(case_percentage) IS NOT NULL
ORDER BY top_case DESC
LIMIT 10;
-- FROM TUTORIAL
SELECT location, population, MAX(total_cases), 
MAX(total_cases::float/population*100) AS case_percentage_on_population
FROM covid_deaths
GROUP BY location, population
ORDER BY case_percentage DESC NULLS LAST;

-- Showing countries with highest death count per population
SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC NULLS LAST

-- Global death number daily
SELECT date, SUM(new_cases) AS total_case, SUM(new_deaths) AS total_death,
ROUND((SUM(new_deaths)::numeric/NULLIF(SUM(new_cases)::numeric,0)*100),3) AS death_percentage_on_cases
FROM covid_deaths
GROUP BY date
ORDER BY date;

-- Vaccination rate depend on countries
SELECT location, total_vaccinations, people_vaccinated, people_fully_vaccinated, 
new_vaccinations FROM covid_vacc
WHERE location = 'Afghanistan'

-- Correlation between vaccination's rate and hospital patient number
-- Using this, we could see that there was negative trend line between hospitalized patients and fully vaccinated poeple
SELECT d.location, d.date, d.icu_patients, d.hosp_patients, v.people_fully_vaccinated, 
(d.hosp_patients::float)/(v.people_fully_vaccinated::float) AS hospital_patients_per_vaccination

FROM covid_deaths AS d
JOIN covid_vacc AS v 
ON d.date =v.date AND d.location = v.location

WHERE hosp_patients IS NOT NULL AND people_fully_vaccinated IS NOT NULL

ORDER BY d.location, d.date

-- Looiking at total population vs. vaccination
WITH CTE AS(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vac_num
	FROM covid_deaths AS dea
		JOIN covid_vacc AS vac
		ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.location IS NOT NULL
	ORDER BY 2,3)

SELECT *,(rolling_vac_num::numeric/population::numeric)*100 AS vacc_per_on_population FROM CTE);