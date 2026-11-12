# Coin_Market_Cap_ETL_end_to_end_Data_Pipeline

CoinMarketCap – End-to-End Cryptocurrency Data Engineering Pipeline

![Python](https://img.shields.io/badge/Python-3.x-blue)
![SQL Server](https://img.shields.io/badge/Database-Microsoft_SQL_Server-red)
![Pandas](https://img.shields.io/badge/Data_Processing-Pandas-150458)
![Selenium](https://img.shields.io/badge/Web_Automation-Selenium-green)
![ETL](https://img.shields.io/badge/Project-ETL_Pipeline-orange)

Project Overview

This project demonstrates an end-to-end ETL (Extract, Transform, Load) data engineering pipeline using cryptocurrency market data from [CoinMarketCap](https://coinmarketcap.com/).

The pipeline extracts cryptocurrency information from the CoinMarketCap website, processes the extracted information using Python and Pandas, stores the data in Microsoft SQL Server, performs data cleaning and transformation using T-SQL, and maintains historical cryptocurrency records through incremental loading.

It also incorporates data quality validation, ETL execution logging, error handling, and SQL indexing.

The primary objective is to demonstrate practical data engineering concepts through a real-world cryptocurrency data use case.

Project Objectives

- Extract real-world cryptocurrency market information.
- Automate browser-based data extraction using Selenium.
- Parse and structure HTML data using BeautifulSoup.
- Process extracted data using Pandas.
- Integrate Python with Microsoft SQL Server.
- Implement raw and cleaned data layers.
- Maintain historical cryptocurrency snapshots.
- Implement incremental data loading.
- Develop reusable SQL stored procedures.
- Implement data quality checks.
- Monitor ETL execution and handle errors.
- Improve database query performance using indexes.

Data Pipeline Architecture

The project follows the following ETL architecture:

```text
                 COINMARKETCAP
                       |
                       v
                DATA EXTRACTION
                       |
              Python + Selenium
                       |
              BeautifulSoup
                       |
                       v
                PANDAS DATAFRAME
                       |
                       v
                  CSV EXPORT
                       |
                       v
             PYTHON - SQL SERVER
                       |
             SQLAlchemy + PyODBC
                       |
                       v
                 CRYPTODB
                       |
                       v
                  CRYPTO_RAW
                       |
                       v
                 CRYPTO_CLEAN
                       |
              Data Cleaning
              Duplicate Removal
              NULL Validation
                       |
                       v
                CRYPTO_HISTORY
                       |
              Incremental Loading
              Historical Snapshots
              Stored Procedures
                       |
             +---------+---------+
             |                   |
             v                   v
          ETL_LOG          DATA_QUALITY_LOG
             |                   |
             v                   v
       PIPELINE STATUS       QUALITY CHECKS
```

Technology Stack

| Technology | Purpose |
|---|---|
| Python | ETL development |
| Selenium | Browser automation |
| BeautifulSoup | HTML parsing |
| Pandas | Data manipulation |
| CSV | Intermediate data storage |
| SQLAlchemy | Python-SQL integration |
| PyODBC | SQL Server connectivity |
| Microsoft SQL Server | Database storage |
| T-SQL | Data cleaning and transformation |
| SQL Stored Procedures | Reusable ETL execution |
| Python Logging | Error logging |
| SQL Indexes | Query performance optimization |

Project Structure

A suggested repository structure:

```text
CoinMarketCap-Data-Pipeline/
│
├── extraction/
│   └── extract_crypto.py
│
├── transformation/
│   └── clean_crypto.sql
│
├── loading/
│   └── load_crypto.py
│
├── sql/
│   ├── create_tables.sql
│   ├── stored_procedures.sql
│   ├── data_quality_checks.sql
│   └── indexes.sql
│
├── data/
│   └── coinmarketcap.csv
│
├── logs/
│   └── etl_error.log
│
├── screenshots/
│   └── pipeline_architecture.png
│
├── requirements.txt
│
└── README.md
```

*Note: This is the recommended organization for the repository. The original implementation was developed in Python notebook cells and SQL scripts; the files can be separated into this structure during repository preparation.*

ETL Process – Step by Step

1. Data Extraction

Cryptocurrency market information is extracted from the CoinMarketCap website.

Libraries used:

- Selenium
- BeautifulSoup
- Pandas

Main operations:

1. Launch Chrome browser using Selenium.
2. Open the CoinMarketCap website.
3. Wait for the website content to load.
4. Extract the HTML content.
5. Parse the HTML using BeautifulSoup.
6. Locate the cryptocurrency market table.
7. Convert the table into a Pandas DataFrame.
8. Export the extracted data into a CSV file.

Example:

```python
url = "https://coinmarketcap.com/"

driver = webdriver.Chrome()
driver.get(url)

body = driver.find_element(
    By.CLASS_NAME,
    "cmc-body-wrapper"
)

html = body.get_attribute("innerHTML")

soup = BeautifulSoup(html, "html.parser")

table = soup.find("table")

if table:
    df = pd.read_html(str(table))[0]

    df.to_csv(
        "coinmarketcap.csv",
        index=False
    )
```

### 2. Data Loading into SQL Server

The extracted CSV data is loaded into Microsoft SQL Server.

Database: `CryptoDB`

Raw table: `Crypto_Raw`

Libraries used:

- Pandas
- SQLAlchemy
- PyODBC

Example:

```python
from sqlalchemy import create_engine
from urllib.parse import quote_plus

conn = quote_plus(
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=YOUR_SERVER;"
    "DATABASE=CryptoDB;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

engine = create_engine(
    "mssql+pyodbc:///?odbc_connect=" + conn
)

df.to_sql(
    "Crypto_Raw",
    engine,
    if_exists="replace",
    index=False
)
```

The raw table serves as the initial database layer for the extracted cryptocurrency data.

Important: The original implementation uses `if_exists="replace"`. For recurring production ingestion, this should be replaced with an append or controlled staging-and-merge strategy to preserve existing raw records.

### 3. Data Cleaning and Transformation

A cleaned table is created from the raw data.

Table: `Crypto_Clean`

Implemented SQL operations:

- Raw data copying.
- Duplicate removal using `ROW_NUMBER()`.
- NULL value inspection.
- Whitespace removal using `LTRIM()` and `RTRIM()`.
- Record count verification.
- Column and data type inspection.

Example:

```sql
USE CryptoDB;
GO

SELECT *
INTO Crypto_Clean
FROM Crypto_Raw;

WITH CTE AS
(
    SELECT *,
        ROW_NUMBER() OVER
        (
            PARTITION BY [Name]
            ORDER BY [Name]
        ) AS rn
    FROM Crypto_Clean
)
DELETE FROM CTE
WHERE rn > 1;

UPDATE Crypto_Clean
SET [Name] = LTRIM(RTRIM([Name]));
```

4. Historical Data Management

A separate table is designed to maintain historical cryptocurrency market records.

Table: `Crypto_History`

| Column | Description |
|---|---|
| Snapshot_ID | Unique identity key |
| Snapshot_Date | Historical snapshot timestamp |
| Coin_Name | Cryptocurrency name |
| Price | Cryptocurrency price |
| Market_Cap | Market capitalization |
| Volume_24h | 24-hour trading volume |

Example:

```sql
CREATE TABLE Crypto_History
(
    Snapshot_ID INT IDENTITY(1,1) PRIMARY KEY,
    Snapshot_Date DATETIME DEFAULT GETDATE(),
    Coin_Name NVARCHAR(255),
    Price NVARCHAR(100),
    Market_Cap NVARCHAR(100),
    Volume_24h NVARCHAR(100)
);
```

The historical table is used to preserve cryptocurrency market snapshots.

5. Incremental Data Loading

Incremental loading logic is implemented using `NOT EXISTS`.

The purpose is to prevent the same cryptocurrency from being inserted more than once on the same calendar day.

Example:

```sql
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
      AND CAST(H.Snapshot_Date AS DATE)
          = CAST(GETDATE() AS DATE)
);
```

This implementation supports daily snapshots rather than multiple intraday snapshots.

6. SQL Stored Procedures

A reusable SQL Server stored procedure is created to execute the historical data loading process.

Procedure name:

`Load_Crypto_History`

The stored procedure:

- Reads data from `Crypto_Clean`.
- Checks for existing daily records.
- Inserts new cryptocurrency records.
- Prevents repeated daily insertion.

Execution:

```sql
EXEC Load_Crypto_History;
```

Python can execute the stored procedure using PyODBC:

```python
cursor.execute("EXEC Load_Crypto_History")

conn.commit()
```

7. Data Quality Validation

A dedicated table is created to record data quality check results.

Table: `Data_Quality_Log`

Implemented validation checks include:

NULL values

```sql
SELECT *
FROM Crypto_History
WHERE Coin_Name IS NULL
   OR Price IS NULL
   OR Market_Cap IS NULL
   OR Volume_24h IS NULL;
```

Duplicate records

```sql
SELECT
    Coin_Name,
    CAST(Snapshot_Date AS DATE),
    COUNT(*) AS Total
FROM Crypto_History
GROUP BY
    Coin_Name,
    CAST(Snapshot_Date AS DATE)
HAVING COUNT(*) > 1;
```

Empty cryptocurrency names

```sql
SELECT *
FROM Crypto_History
WHERE LTRIM(RTRIM(Coin_Name)) = '';
```

Negative prices

```sql
SELECT *
FROM Crypto_History
WHERE TRY_CONVERT(DECIMAL(18,8), Price) < 0;
```

Quality results can be recorded in `Data_Quality_Log` for monitoring.

8. ETL Logging and Monitoring

A dedicated SQL Server table is created to track pipeline execution.

Table: `ETL_Log`

| Column | Description |
|---|---|
| Log_ID | Unique log identifier |
| Pipeline_Name | Pipeline name |
| Execution_Date | Execution timestamp |
| Status | SUCCESS or FAILED |
| Message | Execution details |

Python logging is also implemented using the built-in `logging` module.

Example:

```python
import logging

logging.basicConfig(
    filename="etl_error.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

try:
    cursor.execute("EXEC Load_Crypto_History")
    conn.commit()

    logging.info(
        "ETL completed successfully"
    )

except Exception as e:
    logging.exception("ETL FAILED")
    raise
```

This provides an additional way to investigate pipeline execution failures.

9. SQL Performance Optimization

Nonclustered indexes are created on the historical table.

Example:

```sql
CREATE NONCLUSTERED INDEX
IX_Crypto_History_Coin_Name
ON Crypto_History(Coin_Name);
```

```sql
CREATE NONCLUSTERED INDEX
IX_Crypto_History_Snapshot_Date
ON Crypto_History(Snapshot_Date);
```

A composite index is also explored:

```sql
CREATE NONCLUSTERED INDEX
IX_Crypto_History_Coin_Date
ON Crypto_History(Coin_Name, Snapshot_Date);
```

Performance testing is performed using:

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT *
FROM Crypto_History
WHERE Coin_Name = 'Bitcoin';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
```

These statistics help evaluate logical reads and query execution time.

Database Design

Database: `CryptoDB`

Main database tables:

| Table | Purpose |
|---|---|
| Crypto_Raw | Stores extracted source data |
| Crypto_Clean | Stores cleaned cryptocurrency data |
| Crypto_History | Maintains historical snapshots |
| ETL_Log | Tracks pipeline execution |
| Data_Quality_Log | Records data quality results |

Installation and Setup

Prerequisites

- Python 3.x
- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- Microsoft ODBC Driver 18 for SQL Server
- Google Chrome
- Compatible ChromeDriver / Selenium Manager support

Step 1: Clone the Repository

```bash
git clone YOUR_GITHUB_REPOSITORY_URL

cd CoinMarketCap-Data-Pipeline
```

Step 2: Install Dependencies

```bash
pip install selenium beautifulsoup4 pandas lxml sqlalchemy pyodbc
```

Alternatively:

```bash
pip install -r requirements.txt
```

Step 3: Create the Database

```sql
CREATE DATABASE CryptoDB;
```

Step 4: Configure SQL Server

Update the server name and connection details in your Python configuration.

Example:

```python
SERVER=YOUR_SERVER_NAME
DATABASE=CryptoDB
DRIVER=ODBC Driver 18 for SQL Server
```

Use environment variables or a local configuration file for credentials. Never commit passwords or sensitive connection strings.

### Step 5: Execute SQL Scripts

Run the SQL scripts in SSMS in the following logical order:

1. Create database and raw table.
2. Create clean table and perform transformations.
3. Create historical table.
4. Create ETL logging tables.
5. Create data quality logging table.
6. Create stored procedures.
7. Create appropriate indexes.

### Step 6: Run Python Extraction

Execute the extraction script to collect the cryptocurrency data and save the CSV file.

### Step 7: Load Data into SQL Server

Run the Python loading script to transfer the extracted data into `Crypto_Raw`.

### Step 8: Execute Historical Loading

Execute:

```sql
EXEC Load_Crypto_History;
```

### Step 9: Verify the Pipeline

Check historical records:

```sql
SELECT *
FROM Crypto_History
ORDER BY Snapshot_Date DESC;
```

Check ETL logs:

```sql
SELECT *
FROM ETL_Log
ORDER BY Execution_Date DESC;
```

Check historical daily counts:

```sql
SELECT
    CAST(Snapshot_Date AS DATE) AS Snapshot_Date,
    COUNT(*) AS Total_Coins
FROM Crypto_History
GROUP BY CAST(Snapshot_Date AS DATE)
ORDER BY Snapshot_Date DESC;
```

Key Project Features

- Python-based web data extraction.
- Automated browser interaction.
- HTML parsing and tabular data extraction.
- CSV-based intermediate storage.
- SQL Server database integration.
- Raw and clean data layers.
- Duplicate record removal.
- Historical snapshot management.
- Incremental loading.
- SQL stored procedures.
- Data quality validation.
- ETL execution logging.
- Python exception handling.
- SQL indexing and performance testing.

Future Enhancements

The following features are potential future improvements and are not part of the current implementation:

- Replace website scraping with the official CoinMarketCap API.
- Introduce Apache Airflow for workflow orchestration and scheduling.
- Implement robust staging and idempotent ingestion.
- Use CoinMarketCap coin IDs as business keys.
- Convert numerical market fields to appropriate DECIMAL data types.
- Support hourly and real-time historical snapshots.
- Add comprehensive automated data quality tests.
- Build a Power BI cryptocurrency market dashboard.
- Implement centralized pipeline monitoring.
- Containerize the pipeline using Docker.

Learning Outcomes

This project provided practical experience with:

- Building an end-to-end ETL pipeline.
- Extracting structured data from dynamic websites.
- Working with Python data engineering libraries.
- Integrating Python and Microsoft SQL Server.
- Performing data transformation using T-SQL.
- Implementing incremental loading logic.
- Designing historical data storage.
- Developing SQL stored procedures.
- Implementing data validation and logging.
- Understanding database indexing and query performance.

Author

Hammad Afridi

Aspiring Data Engineer | Python | SQL | ETL | Data Pipelines

Contributions and Feedback

Suggestions, improvements, and feedback are welcome.

If you find this project useful, feel free to star the repository.

**Disclaimer:** This project is developed for educational and portfolio purposes. CoinMarketCap is the source of the website data. This project is not affiliated with or endorsed by CoinMarketCap. Website structure and data availability may change. Please respect the website's terms of use and consider the official API for reliable recurring data ingestion.
