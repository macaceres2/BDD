SELECT
    p.nombre AS nombre_panorama,
    COALESCE(AVG(rev.estrellas), 0) AS prom_estrellas,
    COUNT(rev.id) AS cant_reviews
FROM
    panoramas p
LEFT JOIN
    reservas r ON p.id = r.id
LEFT JOIN
    reviews rev ON r.id = rev.reserva_id
GROUP BY
    p.nombre
ORDER BY
    p.nombre;