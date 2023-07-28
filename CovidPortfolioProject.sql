
--Check if the table and data have been imported correctly
SELECT *
FROM CovidDeaths
WHERE Continent is not null
ORDER BY 3, 4

--Deaths Rate vs Reproduction Rate during Covid
SELECT Country, LogDate, TotalDeaths, PopulationVal, ( TotalDeaths* 100.0 /PopulationVal) as DeathRate, ReproductionRate
FROM CovidDeaths
WHERE Continent is not null
ORDER BY 1, 2

--Checking to see if a higher vaccination rate in a country equates a lower infection rate
SELECT Country, LogDate, PopulationVal, PeopleFullyVaccinated, (PeopleFullyVaccinated / PopulationVal)*100 as VaccinationRate, PositiveRate
FROM CovidDeaths
WHERE Continent is not null
ORDER BY 1, 2

--select data that we are going to be using
SELECT Country, LogDate, TotalCases, NewCases, TotalDeaths, PopulationVal
FROM CovidDeaths
WHERE Continent is not null
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths in the United States
--Shows likelihood of dying if you contract covid in your country
SELECT Country, LogDate, TotalCases, TotalDeaths,(TotalDeaths * 100.0 /TotalCases) as DeathPercentage
FROM CovidDeaths
WHERE Country LIKE '%states%' AND Continent is not null
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
SELECT Country, LogDate, TotalCases, PopulationVal,(TotalCases * 100.0 /PopulationVal) as InfectionPercentage
FROM CovidDeaths
WHERE Country LIKE '%states%' AND Continent is not null
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population
SELECT Country, PopulationVal, MAX(TotalCases) as HighestInfectionCount, MAX(TotalCases * 100.0 /PopulationVal) as InfectionPercentage
FROM CovidDeaths
--WHERE Country LIKE '%states%'
GROUP BY Country, PopulationVal
ORDER BY InfectionPercentage desc

--Showing Countries with Highest Death Count per Population
SELECT Country,MAX(cast(TotalDeaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE Country LIKE '%states%'
GROUP BY Country
ORDER BY TotalDeathCount desc

--Let's Break things down by continent
--Showing Continents with the highest death count per population
SELECT Continent,MAX(cast(TotalDeaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE Country LIKE '%states%'
WHERE Continent is not null
GROUP BY Continent
ORDER BY TotalDeathCount desc

-- Global Numbers
SELECT SUM(NewCases) as TotalCases, 
SUM(cast(NewDeaths as int)) as TotalDeaths, 
SUM(cast(NewDeaths as int)) * 100.0 /NULLIF(SUM(NewCases), 0) AS DeathPercentage
FROM CovidDeaths
--WHERE Country LIKE '%states%' 
WHERE Continent is not null
--GROUP BY logDate
ORDER BY 1,2

--Continental Vaccination vs Infection Rate
SELECT Continent, 
(SUM(PeopleFullyVaccinated))/ (SUM(PopulationVal)) * 100 as VaccinationRate, 
AVG(PositiveRate) as AvgPositiveRate
FROM CovidDeaths
GROUP BY Continent
ORDER BY 2 desc,3 


--Looking at Total Population vs Vaccinations

SELECT dea.Continent, dea.Country, dea.LogDate, dea.PopulationVal, vac.NewVaccinations
, SUM(CONVERT(bigint, vac.NewVaccinations)) OVER (PARTITION BY dea.Country ORDER BY dea.Country, dea.LogDate) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/PopulationVal) * 100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.Country = vac.Country
	AND dea.LogDate = vac.LogDate
WHERE dea.Continent is not null
ORDER BY 2,3

-- USE CTE

WITH PopvsVac (Continent, Country, LogDate, PopulationVal, NewVaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.Continent, dea.Country, dea.LogDate, dea.PopulationVal, vac.NewVaccinations
, SUM(CONVERT(bigint, vac.NewVaccinations)) OVER (PARTITION BY dea.Country ORDER BY dea.Country, dea.LogDate) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/PopulationVal) * 100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.Country = vac.Country
	AND dea.LogDate = vac.LogDate
WHERE dea.Continent is not null
--ORDER BY 2,3
)
SELECT *,( RollingPeopleVaccinated/PopulationVal) *100
FROM PopvsVac


-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Country nvarchar(255),
LogDate datetime,
PopulationVal numeric,
NewVaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.Continent, dea.Country, dea.LogDate, dea.PopulationVal, vac.NewVaccinations
, SUM(CONVERT(bigint, vac.NewVaccinations)) OVER (PARTITION BY dea.Country ORDER BY dea.Country, dea.LogDate) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/PopulationVal) * 100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.Country = vac.Country
	AND dea.LogDate = vac.LogDate
WHERE dea.Continent is not null
--ORDER BY 2,3

SELECT *,( RollingPeopleVaccinated/PopulationVal) *100
FROM #PercentPopulationVaccinated

--Creating View to store data for later visualizations
Create view PercentPopulationVaccinated as
SELECT dea.Continent, dea.Country, dea.LogDate, dea.PopulationVal, vac.NewVaccinations
, SUM(CONVERT(bigint, vac.NewVaccinations)) OVER (PARTITION BY dea.Country ORDER BY dea.Country, dea.LogDate) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/PopulationVal) * 100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.Country = vac.Country
	AND dea.LogDate = vac.LogDate
WHERE dea.Continent is not null
--ORDER BY 2,3


SELECT *
FROM PercentPopulationVaccinated

--Creating a view of cases, deaths, and death percentage throughout the world
Create view GlobalView as
SELECT SUM(NewCases) as TotalCases, 
SUM(cast(NewDeaths as int)) as TotalDeaths, 
SUM(cast(NewDeaths as int)) * 100.0 /NULLIF(SUM(NewCases), 0) AS DeathPercentage
FROM CovidDeaths
--WHERE Country LIKE '%states%' 
WHERE Continent is not null
--GROUP BY logDate

SELECT *
FROM GlobalView

--Creating view of continental vaccination vs infection rate

Create view GlobalRates as
SELECT Continent, 
(SUM(PeopleFullyVaccinated))/ (SUM(PopulationVal)) * 100 as VaccinationRate, 
AVG(PositiveRate) as AvgPositiveRate
FROM CovidDeaths
GROUP BY Continent

SELECT *
FROM GlobalRates
