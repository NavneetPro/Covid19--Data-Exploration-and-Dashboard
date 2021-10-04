/*
Covid 19 Data Exploration - avec AlexTheAnalyst (YouTube)
Compétences apprises: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
From PortfolioProject..CovidDeaths
Where continent is not null -- removing values where continent columns has NULL values.
Order by 3,4



SELECT location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order By 1, 2


-- Looking at total cases vs total deaths
-- shows likelihood of dying if you contract covid in your contry

SELECT location, date, total_cases, total_deaths, cast(total_deaths as float) / cast(total_cases as float)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%India%'
Order By 1, 2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid


SELECT location, date, total_cases, population, cast(total_cases as float) / cast(population as float)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%India%'
Order By 1, 2

-- Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, Max(cast(total_cases as float) / cast(population as float))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by location,population
Order By PercentPopulationInfected desc


-- Showing Countries with highest death count

SELECT location, MAX(cast(Total_deaths as float)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order By TotalDeathCount desc


-- Let's break things down by continent

-- Showing continents with the highest death count

SELECT continent, MAX(cast(Total_deaths as float)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
Order By TotalDeathCount desc



-- GLOBAL Numbers (on sait qu'il y a 2% de mortalité)

SELECT SUM(cast(new_cases as float)) AS total_cases, SUM(cast(new_deaths as float)) AS total_deaths, SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 as DeathPercentage

From PortfolioProject..CovidDeaths
--Where continent is not null AND location like '%India%'
where continent is not null
--Group by date
Order By 1, 2

-- Global number (By date)

SELECT date, SUM(cast(new_cases as float)) AS total_cases, SUM(cast(new_deaths as float)) AS total_deaths, SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 as DeathPercentage
-- Where location like '%India%'
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by date --having SUM(cast(new_cases as float)) >100000
Order By DeathPercentage desc


-- Looking at Total population vs Vaccinations 

Select dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations,
	   SUM(convert(float,vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.continent
			 ORDER BY dea.location, dea.date) as RollingPeopleVaccinated -- the number of vaccinated cases added over the dates
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY RollingPeopleVaccinated desc

-- USE CTE

With PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations,
	   SUM(convert(float,vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.location 
			 ORDER BY dea.location, dea.date) as RollingPeopleVaccinated -- the number of vaccinated cases added over the dates
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac




-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated -- allows you to delete the existing table and modify the table
Create table  #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vacccinations numeric, 
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations,
	   SUM(convert(float,vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.location 
			 ORDER BY dea.location, dea.date) as RollingPeopleVaccinated -- the number of vaccinated cases added over the dates
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3


SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations,
	   SUM(convert(float,vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.location 
			 ORDER BY dea.location, dea.date) as RollingPeopleVaccinated -- the number of vaccinated cases added over the dates
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3