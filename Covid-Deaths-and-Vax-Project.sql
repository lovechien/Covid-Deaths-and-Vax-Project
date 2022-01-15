SELECT *
FROM CovidPortfolioProject..coviddeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

--Data to be used
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolioProject..coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


--Total Cases vs Total Deaths
--Likelihood of dying to Covid in the US
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidPortfolioProject..coviddeaths
WHERE Location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY 1,2;

--Total Cases vs Population
--Percentage of population infected by Covid in the US
SELECT Location, date, total_cases, Population, (total_cases/population)*100 AS InfectedPercentage
FROM CovidPortfolioProject..coviddeaths
WHERE Location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY 1,2;

--Countries with Highest Infection Rate compared to Population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS InfectedPopPercentage
FROM CovidPortfolioProject..coviddeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY InfectedPopPercentage DESC

--Continent with Highest Death Count per Population
SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidPortfolioProject..coviddeaths
WHERE continent IS NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

--Countries with Highest Death Count per Population
SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidPortfolioProject..coviddeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

--Continents with the Highest Death Count
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidPortfolioProject..coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global Numbers
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM CovidPortfolioProject..coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


--Joining death table and vaccination table together
SELECT *
FROM CovidPortfolioProject..coviddeaths dea
JOIN CovidPortfolioProject..covidvaccinations vac
ON dea.location = vac.location AND dea.date = vac.date;

-- Total Population vs. Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidPortfolioProject..coviddeaths dea
JOIN CovidPortfolioProject..covidvaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--Creating new column of cumulative vaccinations per country (recreating total_vaccinations)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidPortfolioProject..coviddeaths dea
JOIN CovidPortfolioProject..covidvaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--CTE to calculate percentage of Population is vaccinated per country over time
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, CumulativeVaccinations)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidPortfolioProject..coviddeaths dea
JOIN CovidPortfolioProject..covidvaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (CumulativeVaccinations/Population)*100
FROM PopvsVac;

--TEMP TABLE to calculate percentage of Population is vaccinated per country over time
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
CumulativeVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidPortfolioProject..coviddeaths dea
JOIN CovidPortfolioProject..covidvaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (CumulativeVaccinations/Population)*100
FROM #PercentPopulationVaccinated;


--Creating View to store data for future visualitzations
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
FROM CovidPortfolioProject..coviddeaths dea
JOIN CovidPortfolioProject..covidvaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
;