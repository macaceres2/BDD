SELECT
    p.username AS nombre_usuario,
    COUNT(DISTINCT r.id) AS cantidad_reservas,
    u.puntos
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
HAVING
    COUNT(DISTINCT r.id) > 70 OR u.puntos > 1000
ORDER BY
    u.puntos DESC;