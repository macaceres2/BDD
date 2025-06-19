SELECT
    TO_CHAR(fecha, 'MM-YYYY') AS mes,
    COUNT(*) AS cantidad_reservas,
    SUM(monto) AS monto_total
FROM
    reservas
GROUP BY
    TO_CHAR(fecha, 'MM-YYYY')
ORDER BY
    MIN(fecha);