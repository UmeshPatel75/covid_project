SELECT * 
FROM Covid_Project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * 
--FROM Covid_Project..CovidVaccination
-- WHERE continent IS NOT NULL
--ORDER BY 3,4 i.e 3rd & 4th col

-- Select the data that we are going to use 
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM Covid_Project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- looking at total death vs total cases
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM Covid_Project..CovidDeaths
WHERE location LIKE 'INDIA'
ORDER BY 1,2
-- FOR USA as many cases and deaths were happended there
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM Covid_Project..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- looking at total cases vs population
-- shows what % of population got infected by covid

SELECT location,date,total_cases,population,(total_cases/population)*100 AS CovidInfectedPercentage
FROM Covid_Project..CovidDeaths
-- WHERE location LIKE '%states%'
ORDER BY 1,2

-- looking at countries with highes % of infection compare to population

SELECT location,population,MAX(total_cases) AS HighestInfectionCount,MAX(total_cases/population)*100 AS 
PercentPopulationInfection
FROM Covid_Project..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY PercentPopulationInfection DESC

-- SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

SELECT location,MAX(total_deaths) AS TotalDeathCount
FROM Covid_Project..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
-- total death count showing as 9...... for all location because total_deaths is nvarchar not int,look at col folder

SELECT location,MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Covid_Project..CovidDeaths
-- WHERE location LIKE '%states%'
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Rresult showing country and continent both as well e.g. Europe and UK,POLAND etc...
SELECT location,MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Covid_Project..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- lets break thing down by continent

SELECT continent,MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Covid_Project..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- global numbers

SELECT SUM(new_cases) AS total_cases,SUM(CAST(new_deaths AS INT)) AS total_deaths,
SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM Covid_Project..CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY 
ORDER BY 1,2

-- looking at total population vs vaccination

SELECT  CD.continent, CD.location,CD.date,CD.population,CV.new_vaccinations
FROM Covid_Project..CovidDeaths CD
JOIN Covid_Project..CovidVaccination CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3

-- lets find rolling sum of people vaccinated instead daily vaccinated 

--SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
--SUM(CONVERT(INT,CV.new_vaccinations)) OVER(PARTITION BY CD.location) 
--FROM Covid_Project..CovidDeaths CD
--JOIN Covid_Project..CovidVaccination CV
--ON CD.location = CV.location AND CD.date = CV.date
--WHERE CD.continent IS NOT NULL
--ORDER BY 2,3
-- Above query shown en error and changed INT to BIGINT as follows.

SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS BIGINT)) OVER(PARTITION BY CD.location ORDER BY CD.location,CD.date) AS RollingPeopleVaccinated
FROM Covid_Project..CovidDeaths CD
JOIN Covid_Project..CovidVaccination CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3

SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS BIGINT)) OVER(PARTITION BY CD.location ORDER BY CD.location,CD.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM Covid_Project..CovidDeaths CD
JOIN Covid_Project..CovidVaccination CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3

-- in above we can't use RollingPeopleVaccinated, so have to use CTE as follows.

WITH VacVsPop
AS
(
SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS BIGINT)) OVER(PARTITION BY CD.location ORDER BY CD.location,CD.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM Covid_Project..CovidDeaths CD
JOIN Covid_Project..CovidVaccination CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM VacVsPop

-- (continent,location,date,new_vaccination,population,RollingPeopleVaccinated)

WITH VacVsPop(continent,location,date,new_vaccination,population,RollingPeopleVaccinated)
AS
(
SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS BIGINT)) OVER(PARTITION BY CD.location ORDER BY CD.location,CD.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM Covid_Project..CovidDeaths CD
JOIN Covid_Project..CovidVaccination CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM VacVsPop

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated

SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS BIGINT)) OVER(PARTITION BY CD.location ORDER BY CD.location,CD.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM Covid_Project..CovidDeaths CD
JOIN Covid_Project..CovidVaccination CV
ON CD.location = CV.location AND CD.date = CV.date
--WHERE CD.continent IS NOT NULL
--ORDER BY 2,3
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM #PercentPopulationVaccinated

-- creating view to store data for later visualisation

CREATE VIEW PercentPopulationVaccinated 
AS
SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS BIGINT)) OVER(PARTITION BY CD.location ORDER BY CD.location,CD.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM Covid_Project..CovidDeaths CD
JOIN Covid_Project..CovidVaccination CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3


ALTER VIEW PercentPopulationVaccinated 
AS
SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS BIGINT)) OVER(PARTITION BY CD.location ORDER BY CD.location,CD.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM Covid_Project..CovidDeaths CD
JOIN Covid_Project..CovidVaccination CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
--ORDER BY 2,

CREATE VIEW vPercentPopulationVaccinated 
AS
SELECT CD.continent,CD.location,CD.date,CD.population,CV.new_vaccinations,
SUM(CAST(CV.new_vaccinations AS BIGINT)) OVER(PARTITION BY CD.location ORDER BY CD.location,CD.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM Covid_Project..CovidDeaths CD
JOIN Covid_Project..CovidVaccination CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
-- ORDER BY 2,3

SELECT * FROM vPercentPopulationVaccinated

