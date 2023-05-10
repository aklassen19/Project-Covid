Select*
From PortfolioProject..CovidDeaths$
Where continent is not null
order by 3, 4

--Select*
--From PortfolioProject..CovidVaccs$
--order by 3, 4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths$
order by 1,2

-- Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, CAST(total_deaths AS float) / CAST(total_cases AS float)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
Where location like '%Canada%'
order by 1,2

--this bottom one will not work since they are text fields instead of numerical

--Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100, NULLIF(total_deaths, 0), NullIF(total_cases, 0) as DeathPercentage
--From PortfolioProject..CovidDeaths$
--order by 1,2


--Looking at Total Cases vs Population Density

SELECT Location, date, total_cases, Population, CAST(total_cases AS float) / CAST(population AS float)*100 AS PopulationInfected
FROM PortfolioProject..CovidDeaths$
Where location like '%Canada%'
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to population

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PopulationInfected
FROM PortfolioProject..CovidDeaths$
--Where location like '%Canada%'
Group by Location, Population
order by PopulationInfected desc

-- Showing Countries with the Highest Death Count per Population
-- Need cast to turn it into an Integer since the field is nvarchar(255) you can look at this by opening the Columns folder withing the table dbo.CovidDeaths$

SELECT Location, Max(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--Where location like '%Canada%'
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- LETS BREAK THINGS DOWN BY CONTINENT

SELECT continent, Max(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--Where location like '%Canada%'
Where continent is not null
Group by continent
order by TotalDeathCount desc


-- by location this include income and world

SELECT location, Max(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--Where location like '%Canada%'
Where continent is null
Group by location
order by TotalDeathCount desc


--Global Numbers Alex's example but it errors out

--SELECT date, SUM(new_cases), SUM(new_deaths), SUM(new_deaths)/Sum(new_cases)*100 as DeathPercentage   --, total_deaths, CAST(total_deaths AS float) / CAST(total_cases AS float)*100 AS DeathPercentage
--FROM PortfolioProject..CovidDeaths$
--where continent is not null
--and new_cases is not null
--group by date
--order by 1,2


--Global Numbers fixed by chatgpt

SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
       SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null AND new_cases is not null
GROUP BY date
ORDER BY 1,2


--JOINs 

-- Looking at Total Population vs Vaccinations




SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       CAST(SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location Order by dea.location, dea.date) AS BIGINT) AS RollingPeopleVaccinated
	   
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccs$ vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3




--Use CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       CAST(SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location Order by dea.location, dea.date) AS BIGINT) AS RollingPeopleVaccinated
	   
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccs$ vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)

Select*, (RollingPeopleVaccinated/Population)*100 as TotalVaccinated
From PopvsVac



--Temp Table

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       CAST(SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location Order by dea.location, dea.date) AS BIGINT) AS RollingPeopleVaccinated
	   
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccs$ vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


--Creating View to store data for later visualizations.

Create View PercentPopulationVaccinated as


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       CAST(SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location Order by dea.location, dea.date) AS BIGINT) AS RollingPeopleVaccinated
	   
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccs$ vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3



-- We can now see the table created above. You can see it in the Views folder to the right
Select *
From #PercentPopulationVaccinated
