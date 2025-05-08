-- 1a.sql
-- Consulta para obtener la cantidad de reservas por mes y el monto total acumulado en el mes

SELECT 
    TO_CHAR(fecha, 'MM-YYYY') AS mes,
    COUNT(*) AS cantidad_reservas,
    SUM(monto) AS monto_total
FROM 
    reservas
GROUP BY 
    TO_CHAR(fecha, 'MM-YYYY')
ORDER BY 
    TO_DATE(TO_CHAR(fecha, 'MM-YYYY'), 'MM-YYYY');