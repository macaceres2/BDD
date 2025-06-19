SELECT
    SUM(r.monto) AS costo_total_viaje
FROM
    reservas r
WHERE
    r.agenda_id = 66637;