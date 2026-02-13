-- ============================================================================
-- Step 3: Run on DB1 to verify the elastic query works
-- ============================================================================

-- Connect to: eqry-db1 on SQL Server 1
-- ============================================================================

-- 3a. Query all remote customers via the external table
SELECT * FROM dbo.RemoteCustomers;
GO

-- 3b. Filter remote data — query executes on DB2, results returned to DB1
SELECT CustomerID, FirstName, LastName, City
FROM dbo.RemoteCustomers
WHERE Country = 'UK'
ORDER BY LastName;
GO

-- 3c. Join local and remote data (if you have a local Orders table)
--     This demonstrates the power of elastic query — cross-database joins
/*
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    o.OrderID,
    o.OrderTotal
FROM dbo.RemoteCustomers c
INNER JOIN dbo.Orders o ON o.CustomerID = c.CustomerID
ORDER BY o.OrderTotal DESC;
*/
GO

-- 3d. Check external data source and table metadata
SELECT name, type_desc, location, database_name
FROM sys.external_data_sources;
GO

SELECT name, type_desc
FROM sys.external_tables;
GO
