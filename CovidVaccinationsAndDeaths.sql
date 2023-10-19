-- Queries for Tableau Project




-- 1.
--Total Cases, Total Deahts, Death Percentage Worldwide

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_cases)*100 as DeathPercentage
FROM PortfolioProjects..CovidDeaths
WHERE continent is not null
order by 1,2


-- 2.

-- We take these out as they are not included in the above queries and want to stay consistent
-- European Union is part of Europe
-- Total Death Count Per Continent

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
WHERE continent is null
AND location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- 3.
-- Percent of Population Infected with COVID by Location

Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProjects..CovidDeaths
Group by Location, Population
ORDER BY PercentPopulationInfected desc


-- 4.
--Percent of Population Infected per day by Location


Select location, population, date, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProjects..CovidDeaths
Group by location, population, date
ORDER BY PercentPopulationInfected desc


-- 5.

-- Percentage of people fully vaccinated per country

SELECT location, population, MAX(cast(people_fully_vaccinated as int)) as HighestVaccinationCount, MAX((cast(people_fully_vaccinated as int)/population))*100 as PercentPopulationFullyVaccinated
FROM PortfolioProjects..CovidVaccinations
WHERE continent is not null
GROUP BY location, population
order by PercentPopulationFullyVaccinated desc


-- 6.

--Percentage of people partially vaccinated per country

SELECT location, MAX(cast(people_vaccinated as int)) as HighestVaccinationCount, MAX(cast(people_fully_vaccinated as int)) as HighestFullVaccinationCount
FROM PortfolioProjects..CovidVaccinations
WHERE continent is not null
GROUP BY location
ORDER BY HighestFullVaccinationCount desc

-- Creat Temp Table to perform Calculation on New Columns
-- Percentage of People Partially Vaccinated by Location

DROP Table if exists #PercentagePartiallyVaccinated
Create Table #PercentagePartiallyVaccinated
(
location nvarchar(255),
population numeric,
HighestVaccinationCount numeric,
HighestFullVaccinationCount numeric
)

Insert into #PercentagePartiallyVaccinated
SELECT location, population, MAX(cast(people_vaccinated as int)) as HighestVaccinationCount, MAX(cast(people_fully_vaccinated as int)) as HighestFullVaccinationCount
FROM PortfolioProjects..CovidVaccinations
WHERE continent is not null
GROUP BY location, population
ORDER BY HighestFullVaccinationCount desc

SELECT *, (HighestFullVaccinationCount/HighestVaccinationCount)*100 as PercentagePartiallyVaccinated
FROM #PercentagePartiallyVaccinated
ORDER BY PercentagePartiallyVaccinated desc




-- 7
-- GDP per Capita vs COVID Deaths/Population
-- JOIN necessary

SELECT dea.continent, dea.location, dea.date, dea.population, vac.gdp_per_capita, 
SUM(CAST(dea.new_deaths as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingDeaths
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

-- Create temp table for RollingDeaths vs GDP

WITH GDPvsDeaths (Continent, location, date, population, gdp_per_capita, RollingDeaths)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.gdp_per_capita, 
SUM(CAST(dea.new_deaths as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingDeaths
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
SELECT location, MAX(RollingDeaths) as TotalDeathsPerCountry
FROM GDPvsDeaths
GROUP BY location
ORDER BY TotalDeathsPerCountry DESC