---------------------------------- Data Exploration -------------------------------

Select *
from [Portfolio Project]..CovidDeaths
where continent is not null
order by 3,4

Select *
from [Portfolio Project]..CovidVaccination
where continent is not null
order by 3,4

--Select Data to look at
Select location, date, total_cases, total_deaths, population
from [Portfolio Project]..CovidDeaths
order by 1,2

--Look at Total Cases vs Population in % form (Infection Rate)
Select location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
from [Portfolio Project]..CovidDeaths
order by 1,2

--Look at Total Cases vs Tatal Deaths in % form (Death Rate)
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
from [Portfolio Project]..CovidDeaths
order by 1,2

--Look at Total Cases vs Population in % form (Infection Rate) in HK
Select location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
from [Portfolio Project]..CovidDeaths
where location like 'Hong Kong'
order by 1,2

--Look at Total Cases vs Tatal Deaths in % form (Death Rate) in HK
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
from [Portfolio Project]..CovidDeaths
where location like 'Hong Kong'
order by 1,2

--Look at countrires with Highest Infection Rate
Select location, population, max(total_cases)as HighestInfectionCount, max((total_cases/population))*100 as HighestInfectionPercentage
from [Portfolio Project]..CovidDeaths
Group by location, population
order by HighestInfectionPercentage desc

--Look at Continents with Highest Death Count per population
Select continent, max(cast(total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount desc

--Global numbers by date
Select date, sum(new_cases) as DailyTotalCases, sum(cast(new_deaths as int)) as DailyTotalDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DailyDeathRate
from [Portfolio Project]..CovidDeaths
Where continent is not null
Group by date
order by date

--Global Total cases and total deaths up-to-date
Select sum(new_cases) as DailyTotalCases, sum(cast(new_deaths as int)) as DailyTotalDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DailyDeathRate
from [Portfolio Project]..CovidDeaths
Where continent is not null

--USE Common Table Expression (CTE)
With PopVsVac (continent, location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
--Joining tables to see vacination status
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as PeopleVaccinatedbyDate
From [Portfolio Project]..CovidDeaths as dea
Join [Portfolio Project]..CovidVaccination as vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--Order by 2,3
)
Select *, (PeopleVaccinatedbyDate/Population)*100 as VacPer
From PopVsVac

--TEMP Table
DROP Table if exists #PercentPeopleVaccinated
Create Table #PercentPeopleVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
PeopleVaccinatedbyDate numeric
)
Insert into #PercentPeopleVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as PeopleVaccinatedbyDate
From [Portfolio Project]..CovidDeaths as dea
Join [Portfolio Project]..CovidVaccination as vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (PeopleVaccinatedbyDate/Population)*100 as VacPer
From #PercentPeopleVaccinated

---------------------------------- Exporting Data -------------------------------

--Creating Views for data visulization
--'Order by' cannot be used in creating views


--1. PercentPeopleVaccinated
use [Portfolio Project];
GO
Create View PercentPeopleVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as PeopleVaccinatedbyDate
From [Portfolio Project]..CovidDeaths as dea
Join [Portfolio Project]..CovidVaccination as vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

--2. GlobalNumbersbyDate
use [Portfolio Project];
GO
Create View GlobalNumbersbyDate as
Select date, sum(new_cases) as DailyTotalCases, sum(cast(new_deaths as int)) as DailyTotalDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DailyDeathRate
from [Portfolio Project]..CovidDeaths
Where continent is not null
Group by date
--order by date


--3. GlobalTotalNumber
use [Portfolio Project];
GO
Create View GlobalTotalNumber as
--Global Total cases and total deaths up-to-date
Select sum(new_cases) as DailyTotalCases, sum(cast(new_deaths as int)) as DailyTotalDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DailyDeathRate
from [Portfolio Project]..CovidDeaths
Where continent is not null


--4. ContinentDeathCount
use [Portfolio Project];
GO
Create View ContinentDeathCount as
--Look at Continents with Highest Death Count per population
Select continent, max(cast(total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..CovidDeaths
where continent is not null
Group by continent
--order by TotalDeathCount desc


--5. CountryInfectionRate
use [Portfolio Project];
GO
Create View CountryInfectionRate as
--Look at countrires with Highest Infection Rate
Select location, population, max(total_cases)as HighestInfectionCount, max((total_cases/population))*100 as HighestInfectionPercentage
from [Portfolio Project]..CovidDeaths
Group by location, population
--order by HighestInfectionPercentage desc


--6. GlobalInfectionRate
use [Portfolio Project];
GO
Create View GlobalInfectionRate as
--Look at Total Cases vs Population in % form (Infection Rate)
Select location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
from [Portfolio Project]..CovidDeaths
--order by 1,2

--7. GlobalDeathRate
use [Portfolio Project];
GO
Create View GlobalDeathRate as
--Look at Total Cases vs Tatal Deaths in % form (Death Rate)
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
from [Portfolio Project]..CovidDeaths
--order by 1,2


--8. HKInfectionRate
use [Portfolio Project];
GO
Create View HKInfectionRate as
--Look at Total Cases vs Population in % form (Infection Rate) in HK
Select location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
from [Portfolio Project]..CovidDeaths
where location like 'Hong Kong'
--order by 1,2


--9. HKDeathRate
use [Portfolio Project];
GO
Create View HKDeathRate as
--Look at Total Cases vs Tatal Deaths in % form (Death Rate) in HK
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
from [Portfolio Project]..CovidDeaths
where location like 'Hong Kong'
--order by 1,2
