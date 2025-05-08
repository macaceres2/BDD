-- 2b.sql
-- Hospedajes disponibles con más de una política registrada,
-- ordenados por estrellas descendente y precio ascendente en caso de empate

SELECT 
    h.nombre AS nombre_hospedaje,
    h.ubicacion,
    h.estrellas,
    h.precio_noche
FROM 
    hospedajes h
JOIN 
    reservas r ON h.codigo_reserva = r.codigo_reserva
JOIN 
    hoteles ht ON h.codigo_reserva = ht.codigo_reserva
WHERE 
    r.estado_disponibilidad = 'Disponible'
    AND array_length(ht.politicas, 1) > 1
ORDER BY 
    h.estrellas DESC,
    h.precio_noche ASC;