-- Data Cleaning

CREATE DATABASE eda;

USE eda;

WITH duplicate_cte AS
(
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off,
 percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs
)
SELECT*
FROM duplicate_cte
WHERE row_num > 1;

CREATE TABLE `layoffs2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs2
WHERE row_num > 1;

INSERT INTO layoffs2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off,
 percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs;

DELETE FROM layoffs2
WHERE row_num > 1;

SELECT * FROM layoffs2;

-- Standardizing data

SELECT company, trim(company)
FROM layoffs2;

UPDATE layoffs2
SET company = trim(company);

SELECT DISTINCT industry
FROM layoffs2;

SELECT * FROM layoffs2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country, trim(TRAILING '.' FROM country)
FROM layoffs2
ORDER BY 1;

UPDATE layoffs2
SET country = trim(TRAILING '.' FROM country)
WHERE country LIKE 'uNITED States%';

SELECT `date`,
STR_TO_DATE(`DATE`, '%m/%d/%Y') FROM layoffs2;

UPDATE layoffs2
set `date` = STR_TO_DATE(`DATE`, '%m/%d/%Y');

ALTER TABLE layoffs2
MODIFY COLUMN `date` DATE;

SELECT * FROM layoffs
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

UPDATE layoffs2 
SET industry = null
WHERE industry = '';

SELECT * FROM layoffs2 t1
JOIN layoffs2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs2 t1
JOIN layoffs2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT * FROM layoffs2
WHERE company = 'Airbnb';

DELETE FROM layoffs2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * FROM layoffs2;

ALTER TABLE layoffs2
DROP COLUMN row_num;

-- Exploratory Data Analysis


SELECT max(total_laid_off), max(percentage_laid_off)
FROM layoffs;
-- exploring with percentage laid off to see the size of the lay offs
SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM layoffs
WHERE  percentage_laid_off IS NOT NULL;


SELECT * FROM layoffs
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

SELECT company, sum(total_laid_off)
FROM layoffs
GROUP BY company
ORDER BY 2 DESC;

-- Checking when these layoffs started and ended.
SELECT min(`date`), max(`date`)
FROM layoffs;

-- Which industry was affected the most with layoffs?
SELECT industry, sum(total_laid_off)
FROM layoffs
GROUP BY industry
ORDER BY 2 DESC;

-- Which countries laid off the most people during this period?
SELECT country, sum(total_laid_off)
FROM layoffs
GROUP BY country
ORDER BY 2 DESC;

-- If we check by year over the period at which the layoffs happened
SELECT YEAR(`date`), sum(total_laid_off)
FROM layoffs
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Stage is the level of funding by particular government
SELECT stage, sum(total_laid_off)
FROM layoffs
GROUP BY stage
ORDER BY 2 DESC;

-- Checking the progression of the lay offs
-- A Rolling sum per month
WITH rolling_total AS (
SELECT substring(`date`, 1, 7) AS `MONTH`, sum(total_laid_off) AS total_lay
FROM layoffs
WHERE substring(`date`,1 ,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_lay,
sum(total_lay) OVER(ORDER BY `MONTH`) AS Rolling_Total
FROM rolling_total;

-- Finding the company that laid off the most people year-by-year
SELECT company, sum(total_laid_off)
FROM layoffs
GROUP BY company
ORDER BY 2 DESC;

-- using nested function to find top 5 every year
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), sum(total_laid_off)
FROM layoffs
GROUP BY company, YEAR(`date`)
), company_year_rank AS
(SELECT *, 
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM Company_Year 
WHERE years IS NOT NULL
)
SELECT * 
FROM company_year_rank
WHERE ranking <= 5;

