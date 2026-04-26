USE [DataCo]
GO

/****** Object:  View [dbo].[vw_acessos]    Script Date: 26/04/2026 08:34:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [dbo].[vw_acessos] AS
SELECT
    CAST([date] AS DATE) AS date,
    department,
    category,
    product
FROM dbo.AccessLogs;
GO


