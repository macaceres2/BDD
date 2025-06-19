WITH PanoramaMonthlyStats AS (
    SELECT
        TO_CHAR(p.fecha_panorama, 'MM-YYYY') AS mes,
        p.id AS panorama_id,
        r.monto AS monto_reserva_panorama,
        (SELECT SUM(pa.edad) FROM participantes pa WHERE pa.id_panorama = p.id) AS suma_edades_para_contar_participantes,
        (SELECT COUNT(*) FROM participantes pa WHERE pa.id_panorama = p.id) AS num_participantes_en_panorama
    FROM
        panoramas p
    JOIN
        reservas r ON p.id = r.id
),
MonthlyAggregates AS (
    SELECT
        mes,
        COUNT(DISTINCT panorama_id) AS cantidad_panoramas,
        SUM(num_participantes_en_panorama) AS cantidad_total_participantes,
        SUM(monto_reserva_panorama) AS monto_total_ganado_panoramas
    FROM
        PanoramaMonthlyStats
    GROUP BY
        mes
)
SELECT
    mes,
    cantidad_panoramas,
    COALESCE(cantidad_total_participantes, 0) AS cantidad_participantes,
    COALESCE(monto_total_ganado_panoramas, 0) AS monto_ganado
FROM
    MonthlyAggregates
ORDER BY
    cantidad_panoramas DESC,
    monto_total_ganado_panoramas DESC,
    cantidad_total_participantes DESC
LIMIT 3;