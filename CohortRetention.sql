-- Cleaning Data

-- Total Records = 541909
-- 135080 Records have no CustomerID
-- 406829 Records have CustomerID

;with online_retail as 
(
	SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [PortfiolioDB].[dbo].[online_retail]
	  WHERE CustomerID IS NOT NULL
)
, quantity_unit_price as 
(
	-- 397884 records with quantity and unit price
	SELECT * 
	FROM online_retail
	WHERE Quantity > 0 AND UnitPrice > 0
)
, dup_check as
(
-- duplicate check 
SELECT *, ROW_NUMBER() OVER (PARTITION BY InvoiceNo, StockCode, Quantity ORDER BY InvoiceDate) dup_flag
FROM quantity_unit_price
)
-- 392669 clean data
-- 5215 duplicates
SELECT *
INTO #online_retail_main
FROM dup_check
WHERE dup_flag = 1

-- Clean Data
-- BEGIN COHORT ANALYSIS
SELECT * FROM #online_retail_main

-- Unique Identifier (CustomerID)
-- Initial Start Date (First Invoice Date)
-- Revenue Data

SELECT 
	CustomerID, 
	MIN(InvoiceDate) first_purchase_date, 
	DATEFROMPARTS(YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)), 1) Cohort_Date
INTO #cohort
FROM #online_retail_main
GROUP BY CustomerID

SELECT *
FROM #cohort

-- Create Cohort Index
SELECT
	mmm.*,
	cohort_index = year_diff * 12 + month_diff + 1 -- number of months since first purchase
INTO #cohort_retention
FROM
	(
		SELECT
			mm.*,
			year_diff = invoice_year - cohort_year,
			month_diff = invoice_month - cohort_month
		FROM
			(
				SELECT 
					m.*,
					c.Cohort_Date,
					YEAR(m.InvoiceDate) invoice_year,
					MONTH(m.InvoiceDate) invoice_month,
					YEAR(c.Cohort_Date) cohort_year,
					MONTH(c.Cohort_Date) cohort_month
				FROM #online_retail_main m
				LEFT JOIN #cohort c
					ON m.CustomerID = c.CustomerID
			)mm
	)mmm


-- Pivot Data to see the cohort table
SELECT *
INTO #cohort_pivot
FROM(
	SELECT 
		DISTINCT CustomerID,
		Cohort_Date,
		cohort_index
	FROM #cohort_retention
)tbl
PIVOT(
	COUNT(CustomerID)
	FOR Cohort_Index IN	
		([1],
		[2],
		[3],
		[4],
		[5],
		[6],
		[7],
		[8],
		[9],
		[10],
		[11],
		[12],
		[13])

) as pivot_table


SELECT *
FROM #cohort_pivot
ORDER BY Cohort_Date

SELECT Cohort_Date, 
	1.0 * [1]/[1] * 100 AS [1], 
	1.0 * [2]/[1] * 100 AS [2], 
	1.0 * [3]/[1] * 100 AS [3], 
	1.0 * [4]/[1] * 100 AS [4],
	1.0 * [5]/[1] * 100 AS [5], 
	1.0 * [6]/[1] * 100 AS [6], 
	1.0 * [7]/[1] * 100 AS [7], 
	1.0 * [8]/[1] * 100 AS [8], 
	1.0 * [9]/[1] * 100 AS [9], 
	1.0 * [10]/[1] * 100 AS [10], 
	1.0 * [11]/[1] * 100 AS [11], 
	1.0 * [12]/[1] * 100 AS [12], 
	1.0 * [13]/[1] * 100 AS [13]
FROM #cohort_pivot
ORDER BY Cohort_Date
