-- ============================================================
-- 02_importar_dados.sql
-- Importa os tres CSVs usando BULK INSERT.
--
-- Estrategia:
--   DataDictionary -> BULK INSERT direto (sem colunas de data)
--   SupplyChain    -> staging (NVARCHAR) + INSERT com conversoes
--   AccessLogs     -> staging (NVARCHAR) + INSERT com conversoes
--
-- Motivo do staging: o BULK INSERT nao converte formatos de data
-- automaticamente. Importamos tudo como texto e depois fazemos
-- TRY_CONVERT com DATEFORMAT mdy para "M/DD/YYYY H:MM".
--
-- Requisitos:
--   - SQL Server 2017+ (opcao FORMAT = 'CSV')
--   - Permissao ADMINISTER BULK OPERATIONS ou sysadmin
--   - Arquivos CSV no caminho abaixo (ajuste se necessario)
--
-- Caminho base dos arquivos:
--   C:\Users\leona\OneDrive\Area de Trabalho\
--     Projetos - Analise de Dados\PROJETOS\Projeto 6 - DataCo\
--
-- ATENCAO: Caminhos com acentos podem exigir que o SQL Server
-- Agent ou o servico SQL Server tenha acesso ao OneDrive.
-- Se houver erro de caminho, copie os CSVs para C:\DataCo\
-- e ajuste as variaveis @path_* abaixo.
-- ============================================================

USE DataCo;
GO

-- ============================================================
-- VARIAVEIS DE CAMINHO
-- Ajuste aqui se os arquivos forem movidos.
-- ============================================================
DECLARE @path_supply   NVARCHAR(500) =
    N'C:\Users\leona\OneDrive\Área de Trabalho\Projetos - Analise de Dados\PROJETOS\Projeto 6 - DataCo\DataCoSupplyChainDataset.csv';

DECLARE @path_dict     NVARCHAR(500) =
    N'C:\Users\leona\OneDrive\Área de Trabalho\Projetos - Analise de Dados\PROJETOS\Projeto 6 - DataCo\DescriptionDataCoSupplyChain.csv';

DECLARE @path_logs     NVARCHAR(500) =
    N'C:\Users\leona\OneDrive\Área de Trabalho\Projetos - Analise de Dados\PROJETOS\Projeto 6 - DataCo\tokenized_access_logs.csv';

-- BULK INSERT nao aceita variaveis no FROM — use o path literal
-- nas secoes abaixo ou substitua manualmente.
-- As variaveis acima servem de referencia documentada.
GO


-- ============================================================
-- IMPORTACAO 1: DataDictionary
-- Sem colunas de data -> BULK INSERT direto, sem staging.
-- FORMAT='CSV' trata campos entre aspas (ex.: descricoes longas).
-- ============================================================
PRINT 'Iniciando importacao: DataDictionary...';

TRUNCATE TABLE dbo.DataDictionary;   -- limpa antes de reimportar

BULK INSERT dbo.DataDictionary
FROM N'C:\Users\leona\OneDrive\Área de Trabalho\Projetos - Analise de Dados\PROJETOS\Projeto 6 - DataCo\DescriptionDataCoSupplyChain.csv'
WITH (
    FORMAT          = 'CSV',        -- trata aspas duplas corretamente
    FIELDQUOTE      = '"',
    FIRSTROW        = 2,            -- pula o cabecalho
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0d0a',     -- CRLF (padrao Windows)
    CODEPAGE        = 'ACP',        -- pagina de codigo ANSI do sistema
    TABLOCK                         -- lock de tabela para performance
);

SELECT COUNT(*) AS linhas_DataDictionary FROM dbo.DataDictionary;
GO


-- ============================================================
-- IMPORTACAO 2: SupplyChain
-- Estrategia: staging table (tudo NVARCHAR) -> INSERT com
-- TRY_CAST / TRY_CONVERT para os tipos corretos.
-- ============================================================
PRINT 'Iniciando importacao: SupplyChain (pode demorar alguns minutos)...';

-- ------------------------------------------------------------
-- 2a. Staging table: todas as colunas como NVARCHAR(MAX)
--     para receber o CSV sem erros de conversao.
-- ------------------------------------------------------------
IF OBJECT_ID('tempdb..#SC_Stg', 'U') IS NOT NULL
    DROP TABLE #SC_Stg;

CREATE TABLE #SC_Stg (
    [Type]                          NVARCHAR(MAX),
    [Days for shipping (real)]      NVARCHAR(MAX),
    [Days for shipment (scheduled)] NVARCHAR(MAX),
    [Benefit per order]             NVARCHAR(MAX),
    [Sales per customer]            NVARCHAR(MAX),
    [Delivery Status]               NVARCHAR(MAX),
    [Late_delivery_risk]            NVARCHAR(MAX),
    [Category Id]                   NVARCHAR(MAX),
    [Category Name]                 NVARCHAR(MAX),
    [Customer City]                 NVARCHAR(MAX),
    [Customer Country]              NVARCHAR(MAX),
    [Customer Email]                NVARCHAR(MAX),
    [Customer Fname]                NVARCHAR(MAX),
    [Customer Id]                   NVARCHAR(MAX),
    [Customer Lname]                NVARCHAR(MAX),
    [Customer Password]             NVARCHAR(MAX),
    [Customer Segment]              NVARCHAR(MAX),
    [Customer State]                NVARCHAR(MAX),
    [Customer Street]               NVARCHAR(MAX),
    [Customer Zipcode]              NVARCHAR(MAX),
    [Department Id]                 NVARCHAR(MAX),
    [Department Name]               NVARCHAR(MAX),
    [Latitude]                      NVARCHAR(MAX),
    [Longitude]                     NVARCHAR(MAX),
    [Market]                        NVARCHAR(MAX),
    [Order City]                    NVARCHAR(MAX),
    [Order Country]                 NVARCHAR(MAX),
    [Order Customer Id]             NVARCHAR(MAX),
    [order date (DateOrders)]       NVARCHAR(MAX),
    [Order Id]                      NVARCHAR(MAX),
    [Order Item Cardprod Id]        NVARCHAR(MAX),
    [Order Item Discount]           NVARCHAR(MAX),
    [Order Item Discount Rate]      NVARCHAR(MAX),
    [Order Item Id]                 NVARCHAR(MAX),
    [Order Item Product Price]      NVARCHAR(MAX),
    [Order Item Profit Ratio]       NVARCHAR(MAX),
    [Order Item Quantity]           NVARCHAR(MAX),
    [Sales]                         NVARCHAR(MAX),
    [Order Item Total]              NVARCHAR(MAX),
    [Order Profit Per Order]        NVARCHAR(MAX),
    [Order Region]                  NVARCHAR(MAX),
    [Order State]                   NVARCHAR(MAX),
    [Order Status]                  NVARCHAR(MAX),
    [Order Zipcode]                 NVARCHAR(MAX),
    [Product Card Id]               NVARCHAR(MAX),
    [Product Category Id]           NVARCHAR(MAX),
    [Product Description]           NVARCHAR(MAX),
    [Product Image]                 NVARCHAR(MAX),
    [Product Name]                  NVARCHAR(MAX),
    [Product Price]                 NVARCHAR(MAX),
    [Product Status]                NVARCHAR(MAX),
    [shipping date (DateOrders)]    NVARCHAR(MAX),
    [Shipping Mode]                 NVARCHAR(MAX)
);

-- ------------------------------------------------------------
-- 2b. Carrega o CSV na staging table
-- ------------------------------------------------------------
BULK INSERT #SC_Stg
FROM N'C:\Users\leona\OneDrive\Área de Trabalho\Projetos - Analise de Dados\PROJETOS\Projeto 6 - DataCo\DataCoSupplyChainDataset.csv'
WITH (
    FORMAT          = 'CSV',
    FIELDQUOTE      = '"',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0d0a',     -- CRLF (padrao Windows)
    CODEPAGE        = 'ACP',        -- pagina de codigo ANSI do sistema
    TABLOCK
);

SELECT COUNT(*) AS linhas_staging_SupplyChain FROM #SC_Stg;

-- ------------------------------------------------------------
-- 2c. Insere na tabela final com conversoes de tipo.
--     SET DATEFORMAT mdy interpreta "M/DD/YYYY H:MM" corretamente.
-- ------------------------------------------------------------
TRUNCATE TABLE dbo.SupplyChain;

SET DATEFORMAT mdy;

INSERT INTO dbo.SupplyChain (
    [Type],
    [Days for shipping (real)],
    [Days for shipment (scheduled)],
    [Benefit per order],
    [Sales per customer],
    [Delivery Status],
    [Late_delivery_risk],
    [Category Id],
    [Category Name],
    [Customer City],
    [Customer Country],
    [Customer Email],
    [Customer Fname],
    [Customer Id],
    [Customer Lname],
    [Customer Password],
    [Customer Segment],
    [Customer State],
    [Customer Street],
    [Customer Zipcode],
    [Department Id],
    [Department Name],
    [Latitude],
    [Longitude],
    [Market],
    [Order City],
    [Order Country],
    [Order Customer Id],
    [order date (DateOrders)],
    [Order Id],
    [Order Item Cardprod Id],
    [Order Item Discount],
    [Order Item Discount Rate],
    [Order Item Id],
    [Order Item Product Price],
    [Order Item Profit Ratio],
    [Order Item Quantity],
    [Sales],
    [Order Item Total],
    [Order Profit Per Order],
    [Order Region],
    [Order State],
    [Order Status],
    [Order Zipcode],
    [Product Card Id],
    [Product Category Id],
    [Product Description],
    [Product Image],
    [Product Name],
    [Product Price],
    [Product Status],
    [shipping date (DateOrders)],
    [Shipping Mode]
)
SELECT
    -- textos: trim para remover espacos residuais do CSV
    LTRIM(RTRIM([Type])),
    TRY_CAST([Days for shipping (real)]      AS INT),
    TRY_CAST([Days for shipment (scheduled)] AS INT),
    TRY_CAST([Benefit per order]             AS FLOAT),
    TRY_CAST([Sales per customer]            AS FLOAT),
    LTRIM(RTRIM([Delivery Status])),
    TRY_CAST([Late_delivery_risk]            AS TINYINT),
    TRY_CAST([Category Id]                   AS INT),
    LTRIM(RTRIM([Category Name])),
    LTRIM(RTRIM([Customer City])),
    LTRIM(RTRIM([Customer Country])),
    LTRIM(RTRIM([Customer Email])),
    LTRIM(RTRIM([Customer Fname])),
    TRY_CAST([Customer Id]                   AS INT),
    LTRIM(RTRIM([Customer Lname])),
    LTRIM(RTRIM([Customer Password])),
    LTRIM(RTRIM([Customer Segment])),
    LTRIM(RTRIM([Customer State])),
    LTRIM(RTRIM([Customer Street])),
    LTRIM(RTRIM([Customer Zipcode])),         -- mantido como texto
    TRY_CAST([Department Id]                 AS INT),
    LTRIM(RTRIM([Department Name])),
    TRY_CAST([Latitude]                      AS FLOAT),
    TRY_CAST([Longitude]                     AS FLOAT),
    LTRIM(RTRIM([Market])),
    LTRIM(RTRIM([Order City])),
    LTRIM(RTRIM([Order Country])),
    TRY_CAST([Order Customer Id]             AS INT),
    -- data formato "M/DD/YYYY H:MM" -> DATETIME2
    TRY_CONVERT(DATETIME2, LTRIM(RTRIM([order date (DateOrders)]))),
    TRY_CAST([Order Id]                      AS INT),
    TRY_CAST([Order Item Cardprod Id]        AS INT),
    TRY_CAST([Order Item Discount]           AS FLOAT),
    TRY_CAST([Order Item Discount Rate]      AS FLOAT),
    TRY_CAST([Order Item Id]                 AS INT),
    TRY_CAST([Order Item Product Price]      AS FLOAT),
    TRY_CAST([Order Item Profit Ratio]       AS FLOAT),
    TRY_CAST([Order Item Quantity]           AS INT),
    TRY_CAST([Sales]                         AS FLOAT),
    TRY_CAST([Order Item Total]              AS FLOAT),
    TRY_CAST([Order Profit Per Order]        AS FLOAT),
    LTRIM(RTRIM([Order Region])),
    LTRIM(RTRIM([Order State])),
    LTRIM(RTRIM([Order Status])),
    LTRIM(RTRIM([Order Zipcode])),
    TRY_CAST([Product Card Id]               AS INT),
    TRY_CAST([Product Category Id]           AS INT),
    LTRIM(RTRIM([Product Description])),
    LTRIM(RTRIM([Product Image])),
    LTRIM(RTRIM([Product Name])),
    TRY_CAST([Product Price]                 AS FLOAT),
    TRY_CAST([Product Status]                AS TINYINT),
    -- data formato "M/DD/YYYY H:MM" -> DATETIME2
    TRY_CONVERT(DATETIME2, LTRIM(RTRIM([shipping date (DateOrders)]))),
    LTRIM(RTRIM([Shipping Mode]))
FROM #SC_Stg;

SELECT COUNT(*) AS linhas_SupplyChain FROM dbo.SupplyChain;

-- Diagnostico: linhas com data nula (conversao falhou)
SELECT
    COUNT(*) AS linhas_com_order_date_nula
FROM dbo.SupplyChain
WHERE [order date (DateOrders)] IS NULL;

DROP TABLE #SC_Stg;
GO


-- ============================================================
-- IMPORTACAO 3: AccessLogs
-- Mesma estrategia: staging NVARCHAR -> INSERT com conversao
-- de data (coluna [Date]: "M/DD/YYYY H:MM").
-- ============================================================
PRINT 'Iniciando importacao: AccessLogs (pode demorar alguns minutos)...';

-- ------------------------------------------------------------
-- 3a. Staging table
-- ------------------------------------------------------------
IF OBJECT_ID('tempdb..#AL_Stg', 'U') IS NOT NULL
    DROP TABLE #AL_Stg;

CREATE TABLE #AL_Stg (
    [Product]       NVARCHAR(MAX),
    [Category]      NVARCHAR(MAX),
    [Date]          NVARCHAR(MAX),   -- sera convertido para DATETIME2
    [Month]         NVARCHAR(MAX),
    [Hour]          NVARCHAR(MAX),
    [Department]    NVARCHAR(MAX),
    [ip]            NVARCHAR(MAX),
    [url]           NVARCHAR(MAX)
);

-- ------------------------------------------------------------
-- 3b. Carrega o CSV na staging table
-- ------------------------------------------------------------
BULK INSERT #AL_Stg
FROM N'C:\Users\leona\OneDrive\Área de Trabalho\Projetos - Analise de Dados\PROJETOS\Projeto 6 - DataCo\tokenized_access_logs.csv'
WITH (
    FORMAT          = 'CSV',
    FIELDQUOTE      = '"',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0d0a',     -- CRLF (padrao Windows)
    CODEPAGE        = 'ACP',        -- pagina de codigo ANSI do sistema
    TABLOCK
);

SELECT COUNT(*) AS linhas_staging_AccessLogs FROM #AL_Stg;

-- ------------------------------------------------------------
-- 3c. Insere na tabela final com conversoes
-- ------------------------------------------------------------
TRUNCATE TABLE dbo.AccessLogs;

SET DATEFORMAT mdy;

INSERT INTO dbo.AccessLogs (
    [Product], [Category], [Date], [Month], [Hour],
    [Department], [ip], [url]
)
SELECT
    LTRIM(RTRIM([Product])),
    LTRIM(RTRIM([Category])),
    TRY_CONVERT(DATETIME2, LTRIM(RTRIM([Date]))),   -- "M/DD/YYYY H:MM"
    LTRIM(RTRIM([Month])),
    TRY_CAST([Hour] AS TINYINT),
    LTRIM(RTRIM([Department])),
    LTRIM(RTRIM([ip])),
    LTRIM(RTRIM([url]))
FROM #AL_Stg;

SELECT COUNT(*) AS linhas_AccessLogs FROM dbo.AccessLogs;

DROP TABLE #AL_Stg;
GO


-- ============================================================
-- RESUMO FINAL
-- ============================================================
SELECT
    'SupplyChain'    AS tabela, COUNT(*) AS total_linhas FROM dbo.SupplyChain
UNION ALL SELECT
    'DataDictionary'           , COUNT(*)                FROM dbo.DataDictionary
UNION ALL SELECT
    'AccessLogs'               , COUNT(*)                FROM dbo.AccessLogs;
GO

PRINT '============================================================';
PRINT 'Script 02 concluido. Tres tabelas importadas.';
PRINT '============================================================';
GO
