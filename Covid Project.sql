
-- Select the data that we're going to be using --

SELECT  location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is NOT NULL

/*Looking at Total Cases Vs Total Deaths 
Shows Likelyhood of dying if you contract covid in your country*/ 

SELECT location, date, total_cases, total_deaths, (total_deaths*100.0/total_cases) as DeathsPercentage
FROM CovidDeaths
WHERE location like 'Lebanon' and continent is NOT NULL
ORDER BY 1,2


/*Looking at Total Cases Vs Population
Shows what Percentage of Population Got Covid*/ 

SELECT location, date, population, total_cases, (total_cases*100.0/population) as PercentPopulationInfected
FROM CovidDeaths
Order by 1,2

-- Looking at Countries with Highest Infection Rate Compared to Population -- 

SELECT location, population, max(total_cases) as HighestInfectionCount, max(total_cases*100.0/population) as PercentPopulationInfected
FROM CovidDeaths
Group By location, population
Order by PercentPopulationInfected DESC


-- Showing Countries with Highest Death Count per Population --

SELECT location, max(cast(total_deaths as INT)) as TotalDeathCount 
FROM CovidDeaths
Where continent is not Null 
Group By location
Order by TotalDeathCount DESC


/*LET'S BREAK THINGS DOWN BY CONTINENT

Showing Continents with the Highest Death Count per Population*/

SELECT continent, max(cast(total_deaths as INT)) as TotalDeathCount 
FROM CovidDeaths
Where continent is not Null 
Group By continent
Order by TotalDeathCount DESC

-- GLOBAL NUMBERS -- 

SELECT sum(new_cases) as total_cases, sum(cast(new_deaths as INT)) as total_deaths, sum(cast(new_deaths as INT))*100.0/sum(new_cases) as DeathPercentage
FROM CovidDeaths
WHERE continent is not null 
ORDER By 1,2;

-- Looking at Total population Vs Vaccinations --

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(CAST(vac.new_vaccinations as INT)) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths as Dea 
JOIN CovidVaccinations as Vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is Not NULL
ORDER BY 2,3;
	
-- USE CTE -- 

With PopvsVac
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(CAST(vac.new_vaccinations as INT)) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths as Dea 
JOIN CovidVaccinations as Vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is Not NULL)
SELECT*, (RollingPeopleVaccinated*100.0/population)
FROM popvsVac


-- CREATE TEMP TABLE -- 

DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMP TABLE PercentPopulationVaccinated AS 
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS INTEGER)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea 
JOIN CovidVaccinations AS vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT 
    *, 
    (RollingPeopleVaccinated * 100.0 / NULLIF(population, 0)) AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;



-- Creating view to store data for later visualizations -- 
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS INTEGER)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths AS dea 
JOIN CovidVaccinations AS vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
