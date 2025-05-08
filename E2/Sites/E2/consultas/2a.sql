-- 2a.sql
-- Hospedajes disponibles, mostrando nombre, ubicación, precio por noche y calificación en estrellas
-- ordenados por número de estrellas de forma descendente.

SELECT 
    h.nombre AS nombre_hospedaje,
    h.ubicacion,
    h.estrellas,
    h.precio_noche
FROM 
    hospedajes h
JOIN 
    reservas r ON h.codigo_reserva = r.codigo_reserva
WHERE 
    r.estado_disponibilidad = 'Disponible'
ORDER BY 
    h.estrellas DESC;