-- ============================================================================
-- Step 1: Run on the REMOTE database (DB2 — the data source)
-- ============================================================================
-- This script creates a sample Customers table and a login/user that the
-- elastic query on DB1 will use to connect.
-- ============================================================================

-- Connect to: master database on SQL Server 2
-- ============================================================================

-- 1a. Create a login for the elastic query to authenticate with
CREATE LOGIN elastic_query_login WITH PASSWORD = '<ElasticQueryP@ssword1>';
GO

-- ============================================================================
-- Now connect to: eqry-db2 on SQL Server 2
-- ============================================================================

-- 1b. Create the database master key (required for elastic query)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<MasterKeyP@ssword1>';
GO

-- 1c. Create a user mapped to the login
CREATE USER elastic_query_user FOR LOGIN elastic_query_login;
GO

-- 1d. Grant SELECT permission so the elastic query can read data
GRANT SELECT TO elastic_query_user;
GO

-- 1e. Create the sample Customers table
CREATE TABLE dbo.Customers (
    CustomerID   INT           PRIMARY KEY,
    FirstName    NVARCHAR(50)  NOT NULL,
    LastName     NVARCHAR(50)  NOT NULL,
    Email        NVARCHAR(100) NOT NULL,
    City         NVARCHAR(50)  NULL,
    Country      NVARCHAR(50)  NULL,
    CreatedDate  DATETIME2     NOT NULL DEFAULT GETUTCDATE()
);
GO

-- 1f. Insert sample data
INSERT INTO dbo.Customers (CustomerID, FirstName, LastName, Email, City, Country)
VALUES
    (1, 'Alice',   'Smith',    'alice.smith@example.com',    'London',    'UK'),
    (2, 'Bob',     'Jones',    'bob.jones@example.com',      'Manchester','UK'),
    (3, 'Charlie', 'Brown',    'charlie.brown@example.com',  'Edinburgh', 'UK'),
    (4, 'Diana',   'Williams', 'diana.williams@example.com', 'Cardiff',   'UK'),
    (5, 'Edward',  'Taylor',   'edward.taylor@example.com',  'Belfast',   'UK');
GO

SELECT '=== DB2 setup complete ===' AS Status;
SELECT * FROM dbo.Customers;
GO
