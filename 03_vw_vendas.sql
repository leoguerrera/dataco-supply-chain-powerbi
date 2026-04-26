USE [DataCo]
GO

/****** Object:  View [dbo].[vw_vendas]    Script Date: 26/04/2026 08:35:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [dbo].[vw_vendas] AS
SELECT
    -- Identificadores
    [Order Id]                                                      AS pedido_id,
    [Order Customer Id]                                             AS cliente_id,

    -- Datas
    CAST([order date (DateOrders)] AS DATE)                         AS data_pedido,
    CAST([shipping date (DateOrders)] AS DATE)                      AS data_envio,

    -- Produto
    [Product Name]                                                  AS produto,
    [Category Name]                                                 AS categoria,
    [Department Name]                                               AS departamento,

    -- Cliente e geografia
    [Customer Segment]                                              AS segmento,
    [Market]                                                        AS mercado,
    [Order Country]                                                 AS pais,
    [Order Region]                                                  AS regiao,
    [Latitude]                                                      AS latitude,
    [Longitude]                                                     AS longitude,

    -- Logística
    [Type]                                                          AS tipo_transacao,
    [Shipping Mode]                                                 AS modal_envio,
    [Delivery Status]                                               AS status_entrega,
    [Days for shipping (real)]                                      AS dias_envio_real,
    [Days for shipment (scheduled)]                                 AS dias_envio_previsto,

    -- Financeiro
    [Sales]                                                         AS valor_venda,
    [Sales per customer]                                            AS venda_por_cliente,
    [Benefit per order]                                             AS lucro_por_pedido,
    [Order Item Quantity]                                           AS quantidade,
    [Order Item Product Price]                                      AS preco_produto,
    [Order Item Profit Ratio]                                       AS margem_ratio,
    [Order Status]                                                  AS status_pedido,

    -- Colunas calculadas
    [Sales] * [Order Item Profit Ratio]                             AS lucro_item,
    [Days for shipping (real)] - [Days for shipment (scheduled)]    AS atraso_dias,
    CASE WHEN [Delivery Status] = 'Late delivery' THEN 1 ELSE 0 END AS flag_atraso

FROM dbo.SupplyChain;
GO


