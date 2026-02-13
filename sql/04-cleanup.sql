-- ============================================================================
-- Cleanup: Remove elastic query objects and sample data
-- ============================================================================

-- ============================================================================
-- Run on DB1 (local / querying database)
-- ============================================================================

-- Remove external table
DROP EXTERNAL TABLE IF EXISTS dbo.RemoteCustomers;
GO

-- Remove external data source
DROP EXTERNAL DATA SOURCE IF EXISTS RemoteDB2;
GO

-- Remove credential
DROP DATABASE SCOPED CREDENTIAL IF EXISTS ElasticQueryCredential;
GO

-- Remove master key
DROP MASTER KEY;
GO

-- ============================================================================
-- Run on DB2 (remote / data source database)
-- ============================================================================

-- Remove sample data
DROP TABLE IF EXISTS dbo.Customers;
GO

-- Remove elastic query user
DROP USER IF EXISTS elastic_query_user;
GO

-- Remove master key
DROP MASTER KEY;
GO

-- ============================================================================
-- Run on master database of SQL Server 2
-- ============================================================================

-- Remove login
-- DROP LOGIN elastic_query_login;
-- GO
