-- ============================================================================
-- Step 2: Run on the LOCAL database (DB1 — the querying database)
-- ============================================================================
-- This script sets up DB1 to query the Customers table on DB2 using an
-- elastic query (external table).
-- ============================================================================

-- Connect to: eqry-db1 on SQL Server 1
-- ============================================================================

-- 2a. Create the database master key (required for credentials)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<MasterKeyP@ssword2>';
GO

-- 2b. Create a database-scoped credential using the login created on DB2
CREATE DATABASE SCOPED CREDENTIAL ElasticQueryCredential
WITH
    IDENTITY = 'elastic_query_login',
    SECRET   = '<ElasticQueryP@ssword1>';  -- must match the password in step 1a
GO

-- 2c. Create the external data source pointing to DB2
--     Replace <sql-server-2-fqdn> with the FQDN of SQL Server 2
--     e.g. eqry-sql2-xxxxxxx.database.windows.net
CREATE EXTERNAL DATA SOURCE RemoteDB2
WITH (
    TYPE     = RDBMS,
    LOCATION = '<sql-server-2-fqdn>.database.windows.net',
    DATABASE_NAME    = 'eqry-db2',
    CREDENTIAL       = ElasticQueryCredential
);
GO

-- 2d. Create the external table mapping to dbo.Customers on DB2
--     The column names and types must match the remote table exactly
CREATE EXTERNAL TABLE dbo.RemoteCustomers (
    CustomerID   INT,
    FirstName    NVARCHAR(50),
    LastName     NVARCHAR(50),
    Email        NVARCHAR(100),
    City         NVARCHAR(50),
    Country      NVARCHAR(50),
    CreatedDate  DATETIME2
)
WITH (
    DATA_SOURCE  = RemoteDB2,
    SCHEMA_NAME  = 'dbo',
    OBJECT_NAME  = 'Customers'
);
GO

SELECT '=== DB1 elastic query setup complete ===' AS Status;
GO
