SELECT
    p.username AS nombre_usuario,
    u.puntos,
    COUNT(CASE WHEN r.fecha >= '2025-05-27' THEN r.id ELSE NULL END) AS cantidad_reservas_futuras
FROM
    usuarios u
JOIN
    personas p ON u.correo = p.correo
LEFT JOIN
    agendas ag ON u.correo = ag.correo_usuario
LEFT JOIN
    reservas r ON ag.id = r.agenda_id
GROUP BY
    p.username, u.puntos, u.correo
ORDER BY
    u.puntos DESC
LIMIT 5;