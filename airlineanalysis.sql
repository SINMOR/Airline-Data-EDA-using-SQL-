SELECT *
FROM customerflightactivity
ORDER BY [Loyalty Number] DESC

SELECT *
FROM customerloyaltyhistory
ORDER BY [Loyalty Number] DESC

--|DATA CLEANING|--
--checking and removing duplicates 
SELECT DISTINCT *
FROM customerflightactivity
SELECT DISTINCT *
FROM customerloyaltyhistory
---TABLE 1 
SELECT [Loyalty Number],Year,[Month] ,COUNT(*) as Duplicates
FROM customerflightactivity
GROUP BY [Loyalty Number],Year,[Month],[Flights Booked]
HAVING COUNT(*) > 1
ORDER BY [Year] ASC

WITH Duplicates AS (
    SELECT [Loyalty Number],Year,[Month],ROW_NUMBER() OVER (PARTITION BY [Loyalty Number],Year,[Month],[Flights Booked] ORDER BY [Year] ASC ) as RowNum
    FROM customerflightactivity
)
SELECT [Loyalty Number],Year,[Month],RowNum
FROM Duplicates
WHERE RowNum > 1
--we grouped the dataset by loyalty Number,year,month ,flights booked and found 1932 duplicates 
WITH Duplicates AS (
    SELECT [Loyalty Number],Year,[Month],ROW_NUMBER() OVER (PARTITION BY [Loyalty Number],Year,[Month],[Flights Booked] ORDER BY [Year] ASC ) as RowNum
    FROM customerflightactivity
)
DELETE FROM Duplicates 
WHERE RowNum > 1

SELECT [Loyalty Number],Year,[Month],[Flights Booked],[Flights with Companions]
FROM customerflightactivity
WHERE [Loyalty Number]=678205
ORDER BY [Year] ASC
--TABLE 2 
SELECT [Loyalty Number],Country,[Province],City ,COUNT(*)
FROM customerloyaltyhistory
GROUP BY [Loyalty Number],Country,[Province],City
HAVING COUNT(*) > 1
ORDER BY [Loyalty Number] ASC
---NO DUPLICATES 

--CHECKING FOR NULL VALUES 
--TABLE 1 
SELECT
    COUNT(*) AS TotalRows,
    COUNT(CASE WHEN [Loyalty Number] IS NULL THEN 1 END) AS NullsInColumn1,
    COUNT(CASE WHEN [Year] IS NULL THEN 1 END) AS NullsInColumn2,
    COUNT(CASE WHEN [Month] IS NULL THEN 1 END) AS NullsInColumn2,
    COUNT(CASE WHEN [Flights Booked] IS NULL THEN 1 END) AS NullsInColumn2,
    COUNT(CASE WHEN [Flights with Companions] IS NULL THEN 1 END) AS NullsInColumn2,
    COUNT(CASE WHEN [Total Flights] IS NULL THEN 1 END) AS NullsInColumn2,
    COUNT(CASE WHEN Distance IS  NULL THEN 1 END) AS NullsInColumn2,
    COUNT(CASE WHEN [Points Accumulated] IS NULL THEN 1 END) AS NullsInColumn2,
    COUNT(CASE WHEN [Points Redeemed]IS  NULL THEN 1 END) AS NullsInColumn2,
    COUNT(CASE WHEN [Dollar Cost Points Redeemed] IS  NULL THEN 1 END) AS NullsInColumn2
   FROM 
    customerflightactivity
--NO NULL VALUES 

--TABLE 2 
SELECT
    COUNT(*) AS TotalRows,
    COUNT(CASE WHEN  [Loyalty Number] IS NULL THEN 1 END) AS Loyalty,
    COUNT(CASE WHEN [country] IS NULL THEN 1 END) AS country,
    COUNT(CASE WHEN [Province] IS NULL THEN 1 END) AS Province,
    COUNT(CASE WHEN [City] IS NULL THEN 1 END) AS City,
    COUNT(CASE WHEN [Postal Code] IS NULL THEN 1 END) AS Postal,
    COUNT(CASE WHEN [Gender] IS NULL THEN 1 END) AS Gender,
    COUNT(CASE WHEN Salary IS  NULL THEN 1 END) AS Salary,
    COUNT(CASE WHEN [Marital Status] IS NULL THEN 1 END) AS Marital,
    COUNT(CASE WHEN [CLV] IS  NULL THEN 1 END) AS CLV,
    COUNT(CASE WHEN [LCard] IS  NULL THEN 1 END) AS LCard,
     COUNT(CASE WHEN [EType] IS NULL THEN 1 END) AS EType,
    COUNT(CASE WHEN [ETMonth] IS NULL THEN 1 END) ETMonth,
    COUNT(CASE WHEN ETYear IS  NULL THEN 1 END) AS ETYear,
    COUNT(CASE WHEN [CanMonth] IS NULL THEN 1 END) AS CanMonth,
    COUNT(CASE WHEN [CanYear] IS  NULL THEN 1 END) AS CanYear
   FROM 
    customerloyaltyhistory 

    --salary - 4238
    --canMonth -14670
    --canYear-14670

    --we are going to drop CanMonth and CanYear because its irrelevant in our analysis 

ALTER TABLE customerloyaltyhistory 
DROP COLUMN CanMonth
    
ALTER TABLE customerloyaltyhistory 
DROP COLUMN CanYear

--Replacing null values in salary column with UNDISCLOSED 

SELECT [Loyalty Number],COALESCE(salary,[Loyalty Number] )AS Firstnonnullvalue
FROM customerloyaltyhistory

SELECT [Loyalty Number],ISNULL(salary,[Loyalty Number] )AS Firstnonnullvalue
FROM customerloyaltyhistory

SELECT COALESCE(salary,'UNDISCLOSED')
FROM customerloyaltyhistory
WHERE salary IS NULL

ALTER TABLE customerloyaltyhistory 
DROP COLUMN salaryconv
ALTER TABLE customerloyaltyhistory
ADD salaryconv VARCHAR(200)
UPDATE customerloyaltyhistory
SET salaryconv=CONVERT(VARCHAR(200),salary)
UPDATE customerloyaltyhistory
SET salaryconv=COALESCE(salaryconv,'UNDISCLOSED')
WHERE salaryconv IS NULL 
--created a new column salaryconv and replaced the null values with a default value 

SELECT *
FROM customerloyaltyhistory
ORDER BY [Loyalty Number] DESC
SELECT *
FROM customerflightactivity
ORDER BY [Loyalty Number] DESC

--|DATA ANALYSIS|--
--1. Monthly Loyalty Card Level Distribution and Average CLV:
WITH MonthlyCardCLV AS (
    SELECT
        cl.LCard,
        cf.Year,
        cf.Month,
        AVG(cl.CLV) AS AvgCLV
    FROM customerflightactivity cf
    JOIN customerloyaltyhistory cl ON cf.[Loyalty Number] = cl.[Loyalty Number]
    GROUP BY cf.Year, cf.Month,cl.LCard
)
SELECT
    m.Year,
    m. Month,
    m. LCard,
    m.AvgCLV,
    COUNT(DISTINCT cf.[Loyalty Number]) AS UniqueCustomers
FROM MonthlyCardCLV m
JOIN customerflightactivity cf ON m.Year = cf.Year AND m.Month = cf.Month
GROUP BY m.Year, m.Month,m. LCard,m.AvgCLV
ORDER BY m.Year,   m. Month
 
--more accurate 
  SELECT
        cl.LCard,
        cf.Year,
        cf.Month,
        AVG(cl.CLV) AS AvgCLV,COUNT(DISTINCT cf.[Loyalty Number]) AS UniqueCustomers
    FROM customerflightactivity cf
    JOIN customerloyaltyhistory cl ON cf.[Loyalty Number] = cl.[Loyalty Number]
    GROUP BY cf.Year, cf.Month,cl.LCard
    ORDER BY cf.Year, cf.Month, UniqueCustomers DESC

--2. Monthly Flights and Points Analysis:
WITH ReedemenRate AS (
SELECT [Year] ,[Month], SUM( [Flights Booked] ) AS Totalflights ,SUM([Points Accumulated]) AS Totalpointsaccumulated,SUM([Points Redeemed]) AS TotalpointsRedeemed,COUNT(DISTINCT [Loyalty Number]) AS UniqueCustomers
FROM customerflightactivity
GROUP BY [Year] ,[Month]

)
SELECT [Year], [Month], Totalflights,Totalpointsaccumulated,UniqueCustomers,TotalpointsRedeemed,ROUND((TotalPointsRedeemed / NULLIF(TotalPointsAccumulated, 0)), 4) AS RedemptionRate
FROM ReedemenRate
ORDER BY Year, Month

--3. Customer Demographics Analysis:
SELECT Country,Province,City,Gender,AVG(Salary),MAX(Salary),MIN(Salary), COUNT(DISTINCT [Loyalty Number]) AS UniqueCustomers
FROM customerloyaltyhistory
GROUP BY Country,Province,City,Gender

SELECT *
FROM customerloyaltyhistory
ORDER BY [Loyalty Number] DESC


SELECT *
FROM customerflightactivity
ORDER BY [Loyalty Number] DESC

--5. Flight Distance and Cost Analysis:
SELECT
    [Year],
    [Month],
    AVG(Distance) AS AvgDistance,
    SUM([Dollar Cost Points Redeemed]) AS TotalDollarCostRedeemed
FROM customerflightactivity
GROUP BY Year, Month
ORDER BY  Year, Month 

--6.Monthly Average distance travelled by Gender 
SELECT cf.[Year],cf.Month,cl.Gender,AVG(cf.Distance)
FROM customerflightactivity cf
JOIN customerloyaltyhistory cl ON cf.[Loyalty Number] = cl.[Loyalty Number]
GROUP BY cf.[Year], cf.Month,cl.Gender
ORDER BY cf.[Year], cf.Month

--7. Monthly Flights Booked and Points Redeemed by Marital Status
SELECT cf.[Year],cf.Month,SUM(cf.[Points Redeemed]) AS TotalPointsRedeemed,SUM(cf.[Flights Booked]) AS Totalflights,cl.[Marital Status]
FROM customerflightactivity cf
JOIN customerloyaltyhistory cl ON cf.[Loyalty Number] = cl.[Loyalty Number]
GROUP BY cf.[Year], cf.Month,cl.[Marital Status]
ORDER BY Totalflights DESC

--8. Average CLV by Loyalty Card Level:
SELECT
    clh.LCard,
    AVG(clh."CLV") AS AvgCLV
FROM customerloyaltyhistory clh
GROUP BY  clh.LCard
ORDER BY AvgCLV DESC

--9. Monthly Average Points Accumulated and Redeemed by Enrollment Type:
SELECT cf.[Year],cf.[Month],cl.EType,ROUND(AVG([Points Accumulated]), 4) AS Averagepointsacc,ROUND(AVG([Points Redeemed]),4 ) AS Averagepointsredee
FROM customerflightactivity cf
JOIN customerloyaltyhistory cl ON cf.[Loyalty Number]= cl.[Loyalty Number]
GROUP BY cf.[Year],cf.[Month],cl.EType
ORDER BY cf.[Year],cf.[Month]