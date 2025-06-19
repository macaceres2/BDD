SELECT
    h.nombre AS nombre_hospedaje,
    h.ubicacion,
    h.estrellas,
    h.precio_noche
FROM
    hospedajes h
JOIN
    hoteles ho ON h.id = ho.id
JOIN
    reservas r ON h.id = r.id
WHERE
    r.estado_disponibilidad = 'Disponible'
    AND ARRAY_LENGTH(ho.politicas, 1) > 1
ORDER BY
    h.estrellas DESC,
    h.precio_noche ASC;