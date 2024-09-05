CREATE DATABASE eda;

SELECT * FROM LAYOFFS;

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

