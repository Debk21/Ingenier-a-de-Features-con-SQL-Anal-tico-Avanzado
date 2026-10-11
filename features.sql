

-- Preparar las transacciones validas. 
-- Se excluyen clientes sin identificador, facturas canceladas y operaciones con cantidades o precios no positivos.
;WITH TransaccionesValidas AS (
SELECT
InvoiceNo,
InvoiceDate,
CustomerID,
Quantity,
UnitPrice,
Quantity * UnitPrice AS Importe
FROM dbo.RetailTransactions
WHERE CustomerID IS NOT NULL
AND InvoiceNo NOT LIKE 'C%'
AND Quantity > 0
AND UnitPrice > 0
),

-- Calcular las metricas RFM para cada cliente.
-- Recency: dias desde la ultima compra hasta la fecha de referencia.
-- Frequency: cantidad de facturas distintas.
-- Monetary: importe total de las compras validas.
MetricasRFM AS (
SELECT
CustomerID,
DATEDIFF(
DAY,
MAX(InvoiceDate),
(SELECT MAX(InvoiceDate) FROM TransaccionesValidas)
) AS Recency,
COUNT(DISTINCT InvoiceNo) AS Frequency,
SUM(Importe) AS Monetary
FROM TransaccionesValidas
GROUP BY CustomerID
),

-- Agrupar el importe de las compras por cliente y mes. Esto permite analizar la evolucion del gasto en el tiempo.
GastoMensual AS (
SELECT
CustomerID,
DATEFROMPARTS(
YEAR(InvoiceDate),
MONTH(InvoiceDate),
1
) AS Mes,
SUM(Importe) AS GastoMensual
FROM TransaccionesValidas
GROUP BY
CustomerID,
DATEFROMPARTS(
YEAR(InvoiceDate),
MONTH(InvoiceDate),
1
)
),

-- Aplicar funciones de ventana al gasto mensual.
-- LAG obtiene el gasto del mes anterior registrado para el cliente.
-- MAX OVER identifica el ultimo mes presente en los datos.
-- AVG OVER calcula el promedio de los meses anteriores registrados.
AnalisisMensual AS (
SELECT
CustomerID,
Mes,
GastoMensual,


    LAG(GastoMensual) OVER (
        PARTITION BY CustomerID
        ORDER BY Mes
    ) AS GastoMesAnterior,

    MAX(Mes) OVER () AS UltimoMesDisponible,

    AVG(GastoMensual) OVER (
        PARTITION BY CustomerID
        ORDER BY Mes
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS PromedioHistorico

FROM GastoMensual


),

-- Obtener el gasto del ultimo mes y su promedio historico.
-- Si un cliente no compro en el ultimo mes global, su gasto se completara con cero en el resultado final.
TendenciaCliente AS (
SELECT
CustomerID,


    MAX(
        CASE
            WHEN Mes = UltimoMesDisponible
            THEN GastoMensual
        END
    ) AS GastoUltimoMes,

    MAX(
        CASE
            WHEN Mes = UltimoMesDisponible
            THEN PromedioHistorico
        END
    ) AS PromedioHistorico

FROM AnalisisMensual
GROUP BY CustomerID


)

-- Unir las metricas RFM con el analisis de tendencia.
-- Trend = gasto del ultimo mes - promedio historico.
-- Un valor positivo indica un gasto superior al promedio; uno negativo indica un gasto inferior al promedio.
SELECT
r.CustomerID,
r.Recency,
r.Frequency,
r.Monetary,
COALESCE(t.GastoUltimoMes, 0) AS GastoUltimoMes,
t.PromedioHistorico,


COALESCE(t.GastoUltimoMes, 0)
    - COALESCE(t.PromedioHistorico, 0) AS Trend


FROM MetricasRFM AS r
LEFT JOIN TendenciaCliente AS t
ON r.CustomerID = t.CustomerID
ORDER BY r.Monetary DESC;
