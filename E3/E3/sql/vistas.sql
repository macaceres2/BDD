-- Vista para la información principal de la agenda y su organizador
DROP VIEW IF EXISTS vista_info_agenda;
CREATE OR REPLACE VIEW vista_info_agenda AS
SELECT
    a.id AS agenda_id,
    a.etiqueta AS nombre_viaje,
    p.nombre AS nombre_organizador,
    p.correo AS correo_organizador
FROM
    agenda a
JOIN
    persona p ON a.correo_usuario = p.correo;

-- Vista para mostrar todos los participantes de todos los panoramas
DROP VIEW IF EXISTS vista_todos_los_participantes;
CREATE OR REPLACE VIEW vista_todos_los_participantes AS
SELECT
    p.nombre AS panorama_asociado,
    participante.nombre AS nombre_participante,
    participante.edad
FROM
    participante
JOIN
    panorama p ON participante.panorama_id = p.id;

-- Vistas simples para desplegar todos los servicios disponibles
DROP VIEW IF EXISTS vista_todos_los_transportes;
CREATE OR REPLACE VIEW vista_todos_los_transportes AS
SELECT empresa, lugar_origen, lugar_llegada, precio_asiento FROM transporte;

DROP VIEW IF EXISTS vista_todos_los_panoramas;
CREATE OR REPLACE VIEW vista_todos_los_panoramas AS
SELECT nombre, ubicacion, precio_persona FROM panorama;

DROP VIEW IF EXISTS vista_todos_los_hospedajes;
CREATE OR REPLACE VIEW vista_todos_los_hospedajes AS
SELECT nombre_hospedaje, ubicacion, precio_noche, estrellas FROM hospedaje;