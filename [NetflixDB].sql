
/* =====================================================
   NETFLIX MOVIES & TV SHOWS TREND HUB
   SQL SERVER ANALYSIS
   Main Table: dbo.Netflix
   ===================================================== */


/* 1. TOTAL NUMBER OF RECORDS */
SELECT COUNT(*) AS Total_Titles
FROM dbo.Netflix;


/* 2. CHECK DUPLICATE SHOW IDs */
SELECT    show_id,
    COUNT(*) AS Duplicate_Count
FROM dbo.Netflix
GROUP BY show_id
HAVING COUNT(*) > 1;


/* 3. CHECK MISSING VALUES */
SELECT
    SUM(CASE WHEN show_id IS NULL OR LTRIM(RTRIM(show_id)) = '' THEN 1 ELSE 0 END) AS Missing_Show_ID,
    SUM(CASE WHEN title IS NULL OR LTRIM(RTRIM(title)) = '' THEN 1 ELSE 0 END) AS Missing_Title,
    SUM(CASE WHEN type IS NULL OR LTRIM(RTRIM(type)) = '' THEN 1 ELSE 0 END) AS Missing_Type,
    SUM(CASE WHEN country IS NULL OR LTRIM(RTRIM(country)) = '' THEN 1 ELSE 0 END) AS Missing_Country,
    SUM(CASE WHEN date_added IS NULL OR LTRIM(RTRIM(date_added)) = '' THEN 1 ELSE 0 END) AS Missing_Date_Added,
    SUM(CASE WHEN rating IS NULL OR LTRIM(RTRIM(rating)) = '' THEN 1 ELSE 0 END) AS Missing_Rating
FROM dbo.Netflix;


/* 4. CONTENT TYPE DISTRIBUTION */
SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(type)), ''), 'Unknown') AS Content_Type,
    COUNT(*) AS Total_Titles,
    CAST(
        COUNT(*) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM dbo.Netflix), 0)
        AS DECIMAL(5,2)
    ) AS Percentage
FROM dbo.Netflix
GROUP BY COALESCE(NULLIF(LTRIM(RTRIM(type)), ''), 'Unknown')
ORDER BY Total_Titles DESC;


/* 5. TITLES BY RELEASE YEAR */
SELECT
    TRY_CONVERT(INT, release_year) AS Release_Year,
    COUNT(*) AS Total_Titles
FROM dbo.Netflix
WHERE TRY_CONVERT(INT, release_year) IS NOT NULL
GROUP BY TRY_CONVERT(INT, release_year)
ORDER BY Release_Year;


/* 6. TOP 10 RELEASE YEARS */
SELECT TOP 10
    TRY_CONVERT(INT, release_year) AS Release_Year,
    COUNT(*) AS Total_Titles
FROM dbo.Netflix
WHERE TRY_CONVERT(INT, release_year) IS NOT NULL
GROUP BY TRY_CONVERT(INT, release_year)
ORDER BY Total_Titles DESC, Release_Year DESC;


/* 7. CONTENT RATING DISTRIBUTION */
SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(rating)), ''), 'Unknown') AS Rating,
    COUNT(*) AS Total_Titles
FROM dbo.Netflix
GROUP BY COALESCE(NULLIF(LTRIM(RTRIM(rating)), ''), 'Unknown')
ORDER BY Total_Titles DESC;


/* 8. RATINGS BY CONTENT TYPE */
SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(type)), ''), 'Unknown') AS Content_Type,
    COALESCE(NULLIF(LTRIM(RTRIM(rating)), ''), 'Unknown') AS Rating,
    COUNT(*) AS Total_Titles
FROM dbo.Netflix
GROUP BY
    COALESCE(NULLIF(LTRIM(RTRIM(type)), ''), 'Unknown'),
    COALESCE(NULLIF(LTRIM(RTRIM(rating)), ''), 'Unknown')
ORDER BY Content_Type, Total_Titles DESC;


/* 9. TITLES ADDED BY YEAR
   Supports common Netflix CSV date formats */
WITH ParsedDates AS (
    SELECT
        COALESCE(
            TRY_CONVERT(DATE, date_added, 106),
            TRY_CONVERT(DATE, date_added, 6),
            TRY_CONVERT(DATE, date_added, 23),
            TRY_CONVERT(DATE, date_added, 101),
            TRY_CONVERT(DATE, date_added)
        ) AS Added_Date
    FROM dbo.Netflix
)
SELECT
    YEAR(Added_Date) AS Added_Year,
    COUNT(*) AS Total_Titles
FROM ParsedDates
WHERE Added_Date IS NOT NULL
GROUP BY YEAR(Added_Date)
ORDER BY Added_Year;


/* 10. TITLES ADDED BY MONTH */
WITH ParsedDates AS (
    SELECT
        COALESCE(
            TRY_CONVERT(DATE, date_added, 106),
            TRY_CONVERT(DATE, date_added, 6),
            TRY_CONVERT(DATE, date_added, 23),
            TRY_CONVERT(DATE, date_added, 101),
            TRY_CONVERT(DATE, date_added)
        ) AS Added_Date
    FROM dbo.Netflix
)
SELECT
    MONTH(Added_Date) AS Added_Month,
    DATENAME(MONTH, Added_Date) AS Month_Name,
    COUNT(*) AS Total_Titles
FROM ParsedDates
WHERE Added_Date IS NOT NULL
GROUP BY MONTH(Added_Date), DATENAME(MONTH, Added_Date)
ORDER BY Added_Month;


/* 11. TOP GENRES
   Splits multiple genres in listed_in */
SELECT TOP 15
    LTRIM(RTRIM(s.value)) AS Genre,
    COUNT(*) AS Total_Titles
FROM dbo.Netflix AS n
CROSS APPLY STRING_SPLIT(n.listed_in, ',') AS s
WHERE n.listed_in IS NOT NULL
  AND LTRIM(RTRIM(s.value)) <> ''
GROUP BY LTRIM(RTRIM(s.value))
ORDER BY Total_Titles DESC;


/* 12. TOP COUNTRIES
   A title listing multiple countries counts once for each country */
SELECT TOP 15
    LTRIM(RTRIM(s.value)) AS Country,
    COUNT(*) AS Total_Titles
FROM dbo.Netflix AS n
CROSS APPLY STRING_SPLIT(n.country, ',') AS s
WHERE n.country IS NOT NULL
  AND LTRIM(RTRIM(s.value)) <> ''
GROUP BY LTRIM(RTRIM(s.value))
ORDER BY Total_Titles DESC;


/* 13. AVERAGE MOVIE DURATION IN MINUTES */
SELECT
    AVG(
        TRY_CONVERT(
            INT,
            LEFT(duration, CHARINDEX(' ', duration + ' ') - 1)
        )
    ) AS Average_Movie_Minutes
FROM dbo.Netflix
WHERE type = 'Movie'
  AND duration LIKE '%min%';


/* 14. TV SHOWS BY NUMBER OF SEASONS */
WITH SeasonData AS (
    SELECT
        TRY_CONVERT(
            INT,
            LEFT(duration, CHARINDEX(' ', duration + ' ') - 1)
        ) AS Number_Of_Seasons
    FROM dbo.Netflix
    WHERE type = 'TV Show'
      AND duration LIKE '%Season%'
)
SELECT
    Number_Of_Seasons,
    COUNT(*) AS Total_Shows
FROM SeasonData
WHERE Number_Of_Seasons IS NOT NULL
GROUP BY Number_Of_Seasons
ORDER BY Number_Of_Seasons;


/* 15. TOP DIRECTORS */
SELECT TOP 10
    LTRIM(RTRIM(s.value)) AS Director,
    COUNT(*) AS Total_Titles
FROM dbo.Netflix AS n
CROSS APPLY STRING_SPLIT(n.director, ',') AS s
WHERE n.director IS NOT NULL
  AND LTRIM(RTRIM(s.value)) <> ''
GROUP BY LTRIM(RTRIM(s.value))
ORDER BY Total_Titles DESC;


/* 16. CONTENT SUMMARY BY TYPE */
SELECT
    COALESCE(NULLIF(LTRIM(RTRIM(type)), ''), 'Unknown') AS Content_Type,
    COUNT(*) AS Total_Titles,
    COUNT(DISTINCT rating) AS Distinct_Ratings,
    MIN(TRY_CONVERT(INT, release_year)) AS Earliest_Release_Year,
    MAX(TRY_CONVERT(INT, release_year)) AS Latest_Release_Year
FROM dbo.Netflix
GROUP BY COALESCE(NULLIF(LTRIM(RTRIM(type)), ''), 'Unknown')
ORDER BY Total_Titles DESC;


/* 17. TITLES BY RELEASE YEAR AND CONTENT TYPE */
SELECT
    TRY_CONVERT(INT, release_year) AS Release_Year,
    type AS Content_Type,
    COUNT(*) AS Total_Titles
FROM dbo.Netflix
WHERE TRY_CONVERT(INT, release_year) IS NOT NULL
GROUP BY TRY_CONVERT(INT, release_year), type
ORDER BY Release_Year, Content_Type;


/* 18. MOST RECENTLY ADDED TITLES */
WITH ParsedDates AS (    SELECT        show_id, title,type,
        COALESCE(
            TRY_CONVERT(DATE, date_added, 106),
            TRY_CONVERT(DATE, date_added, 6),
            TRY_CONVERT(DATE, date_added, 23),
            TRY_CONVERT(DATE, date_added, 101),
            TRY_CONVERT(DATE, date_added)
        ) AS Added_Date
    FROM dbo.Netflix
)
SELECT TOP 20    show_id, title,type,
    Added_Date
FROM ParsedDates
WHERE Added_Date IS NOT NULL
ORDER BY Added_Date DESC;


/* 19. TITLES WITH MISSING COUNTRY */
SELECT    show_id, title, type,country
FROM dbo.Netflix
WHERE country IS NULL
   OR LTRIM(RTRIM(country)) = '';


/* 20. TITLES WITH MISSING DATE ADDED */
SELECT    show_id, title,type,
    date_added
FROM dbo.Netflix
WHERE date_added IS NULL
   OR LTRIM(RTRIM(date_added)) = '';
