-- ============================================================
-- 01_criar_banco.sql
-- Cria o banco DataCo e as tres tabelas do projeto.
--
-- Tabelas:
--   dbo.SupplyChain    -> 53 colunas, 180.519 linhas esperadas
--   dbo.DataDictionary ->  2 colunas,     52 linhas esperadas
--   dbo.AccessLogs     ->  8 colunas, 469.977 linhas esperadas
--
-- Compatibilidade: SQL Server 2017+
-- ============================================================

-- ------------------------------------------------------------
-- BANCO DE DADOS
-- Cria o banco DataCo caso nao exista.
-- ------------------------------------------------------------
IF NOT EXISTS (
    SELECT name FROM sys.databases WHERE name = N'DataCo'
)
BEGIN
    CREATE DATABASE DataCo
        COLLATE Latin1_General_CI_AI;   -- suporte a acentos
    PRINT 'Banco DataCo criado.';
END
ELSE
    PRINT 'Banco DataCo ja existe. Nenhuma acao necessaria.';
GO

USE DataCo;
GO

-- ============================================================
-- TABELA 1: dbo.SupplyChain
-- Transacoes de supply chain: pedidos, clientes, produtos,
-- logistica e entregas.
--
-- Convencoes de tipo:
--   INT        -> IDs e contagens inteiras
--   TINYINT    -> flags binarios (0/1) e horas (0-23)
--   FLOAT      -> metricas financeiras e coordenadas
--   NVARCHAR   -> textos, categorias, emails, URLs
--   DATETIME2  -> datas com horario (precisao de minutos no CSV)
--   NVARCHAR(20) nos campos Zipcode -> preserva zeros a esquerda
--                                      e suporta valores vazios
-- ============================================================
IF OBJECT_ID('dbo.SupplyChain', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.SupplyChain;
    PRINT 'Tabela SupplyChain removida para recriacao.';
END
GO

CREATE TABLE dbo.SupplyChain (
    -- ---- Tipo de transacao e logistica de entrega ----
    [Type]                          NVARCHAR(50)    NULL,   -- DEBIT, TRANSFER, CASH, PAYMENT
    [Days for shipping (real)]      INT             NULL,   -- dias reais de envio
    [Days for shipment (scheduled)] INT             NULL,   -- dias previstos de envio
    [Benefit per order]             FLOAT           NULL,   -- lucro por pedido
    [Sales per customer]            FLOAT           NULL,   -- total de vendas por cliente

    -- ---- Status e risco de entrega ----
    [Delivery Status]               NVARCHAR(50)    NULL,   -- Advance shipping, Late delivery...
    [Late_delivery_risk]            TINYINT         NULL,   -- 1 = atraso provavel, 0 = no prazo

    -- ---- Categoria do produto ----
    [Category Id]                   INT             NULL,
    [Category Name]                 NVARCHAR(100)   NULL,

    -- ---- Dados do cliente ----
    [Customer City]                 NVARCHAR(100)   NULL,
    [Customer Country]              NVARCHAR(100)   NULL,
    [Customer Email]                NVARCHAR(100)   NULL,   -- mascarado (XXXXXXXXX)
    [Customer Fname]                NVARCHAR(100)   NULL,
    [Customer Id]                   INT             NULL,
    [Customer Lname]                NVARCHAR(100)   NULL,
    [Customer Password]             NVARCHAR(100)   NULL,   -- mascarado (XXXXXXXXX)
    [Customer Segment]              NVARCHAR(50)    NULL,   -- Consumer, Corporate, Home Office
    [Customer State]                NVARCHAR(100)   NULL,
    [Customer Street]               NVARCHAR(200)   NULL,
    [Customer Zipcode]              NVARCHAR(20)    NULL,   -- NVARCHAR para zeros a esquerda

    -- ---- Departamento da loja ----
    [Department Id]                 INT             NULL,
    [Department Name]               NVARCHAR(100)   NULL,

    -- ---- Localizacao geografica da loja ----
    [Latitude]                      FLOAT           NULL,
    [Longitude]                     FLOAT           NULL,

    -- ---- Mercado e destino do pedido ----
    [Market]                        NVARCHAR(50)    NULL,   -- Africa, Europe, LATAM...
    [Order City]                    NVARCHAR(100)   NULL,
    [Order Country]                 NVARCHAR(100)   NULL,
    [Order Customer Id]             INT             NULL,

    -- ---- Datas do pedido ----
    [order date (DateOrders)]       DATETIME2       NULL,   -- data de criacao do pedido

    -- ---- Identificadores do pedido ----
    [Order Id]                      INT             NULL,
    [Order Item Cardprod Id]        INT             NULL,   -- codigo RFID do produto

    -- ---- Metricas do item do pedido ----
    [Order Item Discount]           FLOAT           NULL,   -- valor do desconto
    [Order Item Discount Rate]      FLOAT           NULL,   -- percentual de desconto
    [Order Item Id]                 INT             NULL,
    [Order Item Product Price]      FLOAT           NULL,   -- preco sem desconto
    [Order Item Profit Ratio]       FLOAT           NULL,   -- margem de lucro
    [Order Item Quantity]           INT             NULL,
    [Sales]                         FLOAT           NULL,   -- valor de venda
    [Order Item Total]              FLOAT           NULL,   -- total do item
    [Order Profit Per Order]        FLOAT           NULL,   -- lucro total do pedido

    -- ---- Regiao e status do pedido ----
    [Order Region]                  NVARCHAR(100)   NULL,
    [Order State]                   NVARCHAR(100)   NULL,
    [Order Status]                  NVARCHAR(50)    NULL,   -- COMPLETE, PENDING, CLOSED...
    [Order Zipcode]                 NVARCHAR(20)    NULL,   -- pode ser vazio

    -- ---- Produto ----
    [Product Card Id]               INT             NULL,
    [Product Category Id]           INT             NULL,
    [Product Description]           NVARCHAR(MAX)   NULL,   -- geralmente vazio no dataset
    [Product Image]                 NVARCHAR(500)   NULL,   -- URL da imagem
    [Product Name]                  NVARCHAR(200)   NULL,
    [Product Price]                 FLOAT           NULL,
    [Product Status]                TINYINT         NULL,   -- 0 = disponivel, 1 = indisponivel

    -- ---- Data de envio ----
    [shipping date (DateOrders)]    DATETIME2       NULL    -- data real de despacho
,
    -- ---- Modalidade de envio ----
    [Shipping Mode]                 NVARCHAR(50)    NULL    -- Standard Class, First Class...
);
GO

PRINT 'Tabela dbo.SupplyChain criada (53 colunas).';
GO

-- ============================================================
-- TABELA 2: dbo.DataDictionary
-- Dicionario de dados: descreve cada coluna da SupplyChain.
-- ============================================================
IF OBJECT_ID('dbo.DataDictionary', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.DataDictionary;
    PRINT 'Tabela DataDictionary removida para recriacao.';
END
GO

CREATE TABLE dbo.DataDictionary (
    [FIELDS]        NVARCHAR(200)   NULL,   -- nome da coluna na tabela SupplyChain
    [DESCRIPTION]   NVARCHAR(500)   NULL    -- descricao do campo
);
GO

PRINT 'Tabela dbo.DataDictionary criada (2 colunas).';
GO

-- ============================================================
-- TABELA 3: dbo.AccessLogs
-- Logs de acesso anonimizados ao e-commerce: qual produto/
-- categoria foi acessado, por qual IP, em qual horario.
-- ============================================================
IF OBJECT_ID('dbo.AccessLogs', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.AccessLogs;
    PRINT 'Tabela AccessLogs removida para recriacao.';
END
GO

CREATE TABLE dbo.AccessLogs (
    [Product]       NVARCHAR(200)   NULL,   -- nome do produto visitado
    [Category]      NVARCHAR(100)   NULL,   -- categoria do produto
    [Date]          DATETIME2       NULL,   -- data e hora do acesso
    [Month]         NVARCHAR(10)    NULL,   -- mes abreviado (Sep, Oct...)
    [Hour]          TINYINT         NULL,   -- hora do acesso (0-23)
    [Department]    NVARCHAR(100)   NULL,   -- departamento da loja
    [ip]            NVARCHAR(50)    NULL,   -- endereco IP anonimizado
    [url]           NVARCHAR(500)   NULL    -- caminho da URL acessada
);
GO

PRINT 'Tabela dbo.AccessLogs criada (8 colunas).';
GO

PRINT '============================================================';
PRINT 'Script 01 concluido. Banco DataCo e 3 tabelas prontos.';
PRINT '============================================================';
GO
