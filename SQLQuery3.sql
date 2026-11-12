USE CryptoDB;
GO
SELECT *
INTO Crypto_Clean
FROM Crypto_Raw;

WITH CTE AS
(
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY [Name]
        ORDER BY [Name]
    ) AS rn
    FROM Crypto_Clean
)
DELETE FROM CTE
WHERE rn > 1;

SELECT *
FROM Crypto_Clean
WHERE [Name] IS NULL;

UPDATE Crypto_Clean
SET [Name] = LTRIM(RTRIM([Name]));

SELECT *
FROM Crypto_Clean;

SELECT COUNT(*) AS Total_Records
FROM Crypto_Clean;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Crypto_Raw'
ORDER BY ORDINAL_POSITION;

select * from Crypto_Raw

USE CryptoDB;
GO

CREATE TABLE Crypto_History
(
    Snapshot_ID INT IDENTITY(1,1) PRIMARY KEY,
    Snapshot_Date DATETIME DEFAULT GETDATE(),
    Coin_Name NVARCHAR(255),
    Price NVARCHAR(100),
    Market_Cap NVARCHAR(100),
    Volume_24h NVARCHAR(100)
);

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Crypto_Clean';

#Verify_data

INSERT INTO Crypto_History
(
    Coin_Name,
    Price,
    Market_Cap,
    Volume_24h
)
SELECT
    [Name],
    [Price],
    [Market Cap],
    [Volume(24h)]
FROM Crypto_Clean;

SELECT * FROM Crypto_History;

SELECT COUNT(*) AS Total_Records
FROM Crypto_History;

#Check existing duplicates

SELECT
    CAST(Snapshot_Date AS DATE) AS Snapshot_Day,
    Coin_Name,
    COUNT(*) AS Total
FROM Crypto_History
GROUP BY CAST(Snapshot_Date AS DATE), Coin_Name
HAVING COUNT(*) > 1;

#Incremental Loading Query

INSERT INTO Crypto_History
(
    Coin_Name,
    Price,
    Market_Cap,
    Volume_24h
)
SELECT
    C.[Name],
    C.[Price],
    C.[Market Cap],
    C.[Volume(24h)]
FROM Crypto_Clean C
WHERE NOT EXISTS
(
    SELECT 1
    FROM Crypto_History H
    WHERE H.Coin_Name = C.[Name]
    AND CAST(H.Snapshot_Date AS DATE) = CAST(GETDATE() AS DATE)
);

#Verify Incremental Loading

SELECT
    CAST(Snapshot_Date AS DATE) AS Snapshot_Date,
    COUNT(*) AS Total_Coins
FROM Crypto_History
GROUP BY CAST(Snapshot_Date AS DATE)
ORDER BY Snapshot_Date DESC;

#SQL Stored_Procedure

USE CryptoDB;
GO

CREATE OR ALTER PROCEDURE Load_Crypto_History
AS
BEGIN

    INSERT INTO Crypto_History
    (
        Coin_Name,
        Price,
        Market_Cap,
        Volume_24h
    )
    SELECT
        C.[Name],
        C.[Price],
        C.[Market Cap],
        C.[Volume(24h)]
    FROM Crypto_Clean C
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM Crypto_History H
        WHERE H.Coin_Name = C.[Name]
        AND CAST(H.Snapshot_Date AS DATE) = CAST(GETDATE() AS DATE)
    );

END;
GO

#Stored_Procedure_execution

EXEC Load_Crypto_History;

#Check records

SELECT *
FROM Crypto_History
ORDER BY Snapshot_Date DESC;

#ETL_LOG_TABLE

CREATE TABLE ETL_Log
(
    Log_ID INT IDENTITY(1,1) PRIMARY KEY,
    Pipeline_Name VARCHAR(100),
    Execution_Date DATETIME DEFAULT GETDATE(),
    Status VARCHAR(30),
    Message VARCHAR(500)
);

#Now_Log_Check

SELECT *
FROM ETL_Log
ORDER BY Execution_Date DESC;

SELECT *
FROM ETL_Log
ORDER BY Execution_Date DESC;

SELECT
    CAST(Snapshot_Date AS DATE) AS Snapshot_Date,
    COUNT(*) AS Total_Coins
FROM Crypto_History
GROUP BY CAST(Snapshot_Date AS DATE)
ORDER BY Snapshot_Date DESC;

#Duplicate records_check

SELECT Coin_Name, COUNT(*) AS Total
FROM Crypto_History
GROUP BY Coin_Name, CAST(Snapshot_Date AS DATE)
HAVING COUNT(*) > 1;

#NULL values_check

SELECT *
FROM Crypto_History
WHERE Coin_Name IS NULL
   OR Price IS NULL
   OR Market_Cap IS NULL
   OR Volume_24h IS NULL;

   #Empty cryptocurrency names

   SELECT *
FROM Crypto_History
WHERE LTRIM(RTRIM(Coin_Name)) = '';

# Invalid or negative prices

SELECT *
FROM Crypto_History
WHERE TRY_CONVERT(DECIMAL(18,8), Price) < 0;

# Total records

SELECT COUNT(*) AS TOTAL_RECORDS
FROM Crypto_History;

# Data_Quality_Log

CREATE TABLE Data_Quality_Log
(
    Check_ID INT IDENTITY(1,1) PRIMARY KEY,
    Check_Name VARCHAR(100),
    Failed_Records INT,
    Check_Date DATETIME DEFAULT GETDATE()
);

# example check_insert

INSERT INTO Data_Quality_Log
(Check_Name, Failed_Records)
SELECT
    'NULL Coin Names',
    COUNT(*)
FROM Crypto_History
WHERE Coin_Name IS NULL;

#Now checking results

SELECT *
FROM Data_Quality_Log
ORDER BY Check_Date DESC;

#Check existing indexes

EXEC sp_helpindex 'Crypto_History';

#Create_index on CoinName

CREATE NONCLUSTERED INDEX IX_Crypto_History_Coin_Name
ON Crypto_History (Coin_Name);

#Create index_on Snapshot_Date

CREATE NONCLUSTERED INDEX IX_Crypto_History_Snapshot_Date
ON Crypto_History (Snapshot_Date);

#Create composite_index

CREATE NONCLUSTERED INDEX IX_Crypto_History_Coin_Date
ON Crypto_History (Coin_Name, Snapshot_Date);

# Test performance

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT *
FROM Crypto_History
WHERE Coin_Name = 'Bitcoin';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

#PipeLine Monitoring

SELECT
    Pipeline_Name,
    Status,
    Execution_Date,
    Message
FROM ETL_Log
ORDER BY Execution_Date DESC;

#SQL Indexing

EXEC sp_helpindex 'Crypto_History';

CREATE NONCLUSTERED INDEX IX_Crypto_Coin
ON Crypto_History(Coin_Name);

CREATE NONCLUSTERED INDEX IX_Crypto_Date
ON Crypto_History(Snapshot_Date);

CREATE NONCLUSTERED INDEX IX_Crypto_Coin_Date
ON Crypto_History(Coin_Name, Snapshot_Date);

#Verify

EXEC sp_helpindex 'Crypto_History';

#End_to_End Pipeline Monitoring

SELECT
    Pipeline_Name,
    Status,
    Execution_Date,
    Message
FROM ETL_Log
ORDER BY Execution_Date DESC;

#Historical Records

SELECT
    CAST(Snapshot_Date AS DATE) AS Load_Date,
    COUNT(*) AS Total_Coins
FROM Crypto_History
GROUP BY CAST(Snapshot_Date AS DATE)
ORDER BY Load_Date DESC;