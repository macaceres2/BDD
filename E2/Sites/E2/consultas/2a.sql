SELECT
    h.nombre AS nombre_hospedaje,
    h.ubicacion,
    h.estrellas,
    h.precio_noche
FROM
    hospedajes h
JOIN
    reservas r ON h.id = r.id
WHERE
    (r.estado_disponibilidad = 'Disponible' OR r.estado_disponibilidad IS NULL OR TRIM(r.estado_disponibilidad) = '')
    h.estrellas DESC;