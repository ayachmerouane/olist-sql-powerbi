/* =====================================================================
   01_create_database.sql
   Crée la base OlistDB et ses deux schémas :
     - stg : données brutes importées depuis les CSV
     - dw  : vues nettoyées et modélisées pour Power BI
   ===================================================================== */

USE master;
GO

IF DB_ID('OlistDB') IS NULL
    CREATE DATABASE OlistDB;
GO

USE OlistDB;
GO

IF SCHEMA_ID('stg') IS NULL EXEC('CREATE SCHEMA stg');
GO
IF SCHEMA_ID('dw') IS NULL EXEC('CREATE SCHEMA dw');
GO
