WITH RankedReviews AS (
    SELECT
        r.id AS reserva_id,
        rev.descripcion,
        rev.estrellas,
        ROW_NUMBER() OVER (PARTITION BY r.id ORDER BY rev.id DESC) as rn
    FROM
        reviews rev
    JOIN
        reservas r ON rev.reserva_id = r.id
)
SELECT
    p.nombre AS nombre_panorama,
    COALESCE(AVG(rr.estrellas), 0) AS prom_estrellas,
    COUNT(rr.reserva_id) AS cant_reviews,
    (SELECT rr_last.descripcion
     FROM RankedReviews rr_last
     WHERE rr_last.reserva_id = p.id AND rr_last.rn = 1
     LIMIT 1) AS ult_comentario
FROM
    panoramas p
INNER JOIN
    RankedReviews rr ON p.id = rr.reserva_id
GROUP BY
    p.id, p.nombre
ORDER BY
    p.nombre;