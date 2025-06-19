CREATE TEMP TABLE temp_personas (
    nombre VARCHAR(255),
    correo VARCHAR(255),
    contrasena VARCHAR(255),
    username VARCHAR(255),
    telefono_contacto VARCHAR(20),
    run TEXT,
    puntos TEXT,
    jornada VARCHAR(255),
    isapre VARCHAR(255),
    contrato VARCHAR(255),
    dv VARCHAR(10)
);

CREATE TEMP TABLE temp_agenda_reserva (
    agenda_id TEXT,
    etiqueta VARCHAR(255),
    id TEXT,
    fecha TEXT,
    monto TEXT,
    cantidad_personas TEXT,
    estado_disponibilidad VARCHAR(255),
    puntos TEXT,
    correo_empleado VARCHAR(255),
    lugar_origen VARCHAR(255),
    lugar_llegada VARCHAR(255),
    capacidad TEXT,
    tiempo_estimado VARCHAR(50),
    precio_asiento TEXT,
    empresa VARCHAR(255),
    fecha_salida TEXT,
    fecha_llegada TEXT,
    tipo_bus VARCHAR(255),
    comodidades TEXT,
    escalas TEXT,
    clase VARCHAR(50),
    paradas TEXT,
    nombre_hospedaje VARCHAR(255),
    ubicacion VARCHAR(255),
    precio_noche TEXT,
    estrellas TEXT,
    fecha_checkin TEXT,
    fecha_checkout TEXT,
    politicas TEXT,
    nombre_anfitrion VARCHAR(255),
    contacto_anfitrion VARCHAR(50),
    descripcion_airbnb TEXT,
    piezas TEXT,
    camas TEXT,
    banos TEXT,
    nombre_panorama VARCHAR(255),
    duracion TEXT,
    precio_persona TEXT,
    restricciones TEXT,
    fecha_panorama TEXT
);

CREATE TEMP TABLE temp_habitaciones (
    hotel_id TEXT,
    numero_habitacion TEXT,
    tipo VARCHAR(255)
);

CREATE TEMP TABLE temp_participantes (
    id_panorama TEXT,
    nombre VARCHAR(255),
    edad TEXT
);

CREATE TEMP TABLE temp_review_seguro (
    correo_usuario VARCHAR(255),
    puntos TEXT,
    reserva_id TEXT,
    tipo_seguro VARCHAR(255),
    valor_seguro TEXT,
    clausula TEXT,
    empresa_seguro VARCHAR(255),
    estrellas TEXT,
    descripcion TEXT
);

\COPY temp_personas FROM '../csv/personas.csv' WITH CSV HEADER;
\COPY temp_agenda_reserva FROM '../csv/agenda_reserva.csv' WITH CSV HEADER;
\COPY temp_habitaciones FROM '../csv/habitaciones.csv' WITH CSV HEADER;
\COPY temp_participantes FROM '../csv/participantes.csv' WITH CSV HEADER;
\COPY temp_review_seguro FROM '../csv/review_seguro.csv' WITH CSV HEADER;

CREATE TEMP TABLE personas_descartados AS SELECT * FROM temp_personas LIMIT 0;
CREATE TEMP TABLE usuarios_descartados (
    correo TEXT,
    puntos TEXT,
    razon_descarte TEXT
);
CREATE TEMP TABLE empleados_descartados AS SELECT * FROM temp_personas LIMIT 0;
CREATE TEMP TABLE agenda_reserva_descartados AS SELECT * FROM temp_agenda_reserva LIMIT 0;
CREATE TEMP TABLE reservas_descartados AS SELECT * FROM temp_agenda_reserva LIMIT 0;
CREATE TEMP TABLE reviews_descartados AS SELECT * FROM temp_review_seguro LIMIT 0;
CREATE TEMP TABLE seguros_descartados AS SELECT * FROM temp_review_seguro LIMIT 0;
CREATE TEMP TABLE transportes_descartados AS SELECT * FROM temp_agenda_reserva LIMIT 0;
CREATE TEMP TABLE buses_descartados AS SELECT * FROM temp_agenda_reserva LIMIT 0;
CREATE TEMP TABLE trenes_descartados AS SELECT * FROM temp_agenda_reserva LIMIT 0;
CREATE TEMP TABLE aviones_descartados AS SELECT * FROM temp_agenda_reserva LIMIT 0;
CREATE TEMP TABLE panoramas_descartados AS SELECT * FROM temp_agenda_reserva LIMIT 0;
CREATE TEMP TABLE participantes_descartados AS SELECT * FROM temp_participantes LIMIT 0;
CREATE TEMP TABLE hospedajes_descartados AS SELECT * FROM temp_agenda_reserva LIMIT 0;
CREATE TEMP TABLE hoteles_descartados AS SELECT * FROM temp_agenda_reserva LIMIT 0;
CREATE TEMP TABLE habitaciones_descartados AS SELECT * FROM temp_habitaciones LIMIT 0;
CREATE TEMP TABLE airbnb_descartados AS SELECT * FROM temp_agenda_reserva LIMIT 0;

INSERT INTO personas (correo, nombre, run, dv, username, contrasena, telefono_contacto)
SELECT
    TRIM(tp.correo),
    TRIM(tp.nombre),
    CAST(TRIM(tp.run) AS INT),
    UPPER(TRIM(tp.dv)),
    TRIM(tp.username),
    tp.contrasena,
    TRIM(tp.telefono_contacto)
FROM temp_personas tp
WHERE tp.correo IS NOT NULL AND TRIM(tp.correo) <> ''
    AND tp.nombre IS NOT NULL AND TRIM(tp.nombre) <> ''
    AND tp.run IS NOT NULL AND TRIM(tp.run) ~ '^[0-9]+$'
    AND tp.dv IS NOT NULL AND TRIM(tp.dv) ~ '^[0-9Kk]$'
    AND tp.username IS NOT NULL AND TRIM(tp.username) <> ''
    AND tp.contrasena IS NOT NULL AND tp.contrasena <> ''
    AND tp.telefono_contacto IS NOT NULL AND TRIM(tp.telefono_contacto) <> ''
ON CONFLICT (correo) DO NOTHING;

INSERT INTO personas_descartados
SELECT tp.*
FROM temp_personas tp
WHERE NOT (
    tp.correo IS NOT NULL AND TRIM(tp.correo) <> ''
    AND tp.nombre IS NOT NULL AND TRIM(tp.nombre) <> ''
    AND tp.run IS NOT NULL AND TRIM(tp.run) ~ '^[0-9]+$'
    AND tp.dv IS NOT NULL AND TRIM(tp.dv) ~ '^[0-9Kk]$'
    AND tp.username IS NOT NULL AND TRIM(tp.username) <> ''
    AND tp.contrasena IS NOT NULL AND tp.contrasena <> ''
    AND tp.telefono_contacto IS NOT NULL AND TRIM(tp.telefono_contacto) <> ''
);


CREATE TEMP TABLE temp_usuarios_consolidados AS
SELECT
    TRIM(tp.correo) AS correo,
    MAX(CASE
            WHEN tp.puntos IS NOT NULL AND TRIM(tp.puntos) ~ '^[0-9]+$' AND CAST(TRIM(tp.puntos) AS INT) >= 0 THEN CAST(TRIM(tp.puntos) AS INT)
            ELSE 0
        END) AS puntos_consolidados
FROM temp_personas tp
WHERE tp.correo IS NOT NULL AND TRIM(tp.correo) <> ''
  AND tp.correo IN (SELECT p.correo FROM personas p)
GROUP BY TRIM(tp.correo);







INSERT INTO usuarios (correo, puntos)
SELECT
    tuc.correo,
    tuc.puntos_consolidados
FROM temp_usuarios_consolidados tuc
ON CONFLICT (correo) DO UPDATE SET
    puntos = usuarios.puntos + EXCLUDED.puntos;

INSERT INTO usuarios_descartados (correo, puntos, razon_descarte)
SELECT tp.correo, tp.puntos, 'No es una persona válida o correo inválido'
FROM temp_personas tp
WHERE tp.correo IS NULL OR TRIM(tp.correo) = '' OR TRIM(tp.correo) NOT IN (SELECT p.correo FROM personas p);

INSERT INTO usuarios_descartados (correo, puntos, razon_descarte)
SELECT tp.correo, tp.puntos, 'Puntos inválidos y no se pudo consolidar (aunque la persona exista)'
FROM temp_personas tp
WHERE tp.correo IN (SELECT p.correo FROM personas p)
  AND NOT (tp.puntos IS NOT NULL AND TRIM(tp.puntos) ~ '^[0-9]+$' AND CAST(TRIM(tp.puntos) AS INT) >=0)
  AND tp.correo NOT IN (SELECT tu.correo FROM usuarios tu);

DROP TABLE temp_usuarios_consolidados;







INSERT INTO empleados (correo, jornada, contrato, isapre)
SELECT
    TRIM(tp.correo),
    TRIM(tp.jornada),
    TRIM(tp.contrato),
    TRIM(tp.isapre)
FROM temp_personas tp
WHERE tp.correo IN (SELECT p.correo FROM personas p)
    AND tp.jornada IS NOT NULL AND TRIM(tp.jornada) <> ''
    AND tp.contrato IS NOT NULL AND TRIM(tp.contrato) <> ''
    AND tp.isapre IS NOT NULL AND TRIM(tp.isapre) <> ''
ON CONFLICT (correo) DO NOTHING;

INSERT INTO empleados_descartados
SELECT tp.*
FROM temp_personas tp
WHERE tp.correo NOT IN (SELECT p.correo FROM personas p)
    OR NOT (
        tp.jornada IS NOT NULL AND TRIM(tp.jornada) <> ''
        AND tp.contrato IS NOT NULL AND TRIM(tp.contrato) <> ''
        AND tp.isapre IS NOT NULL AND TRIM(tp.isapre) <> ''
    );




DO $$ BEGIN
    RAISE NOTICE 'DEBUG: Iniciando la inserción en agendas... (Nueva Lógica)';
END $$;

DO $$ BEGIN
    RAISE NOTICE 'DEBUG: Iniciando la inserción en agendas... (Lógica Optimizada)';
END $$;

INSERT INTO agendas (id, correo_usuario, etiqueta)
WITH DistinctAgendasFromCSV AS (
    SELECT DISTINCT
        TRIM(agenda_id) AS agenda_id_str,
        TRIM(etiqueta) AS etiqueta_str
    FROM temp_agenda_reserva
    WHERE agenda_id IS NOT NULL AND TRIM(agenda_id) ~ '^[0-9]+$'
      AND etiqueta IS NOT NULL AND TRIM(etiqueta) <> ''
),
PotentialAgendaUsers AS (
    SELECT
        TRIM(tar_link.agenda_id) AS agenda_id_str,
        TRIM(trs.correo_usuario) AS correo_usuario,
        ROW_NUMBER() OVER (PARTITION BY TRIM(tar_link.agenda_id) ORDER BY TRIM(trs.correo_usuario)) as rn
    FROM temp_review_seguro trs
    JOIN temp_agenda_reserva tar_link ON TRIM(trs.reserva_id) = TRIM(tar_link.id)
    WHERE trs.correo_usuario IS NOT NULL AND TRIM(trs.correo_usuario) <> ''
      AND trs.correo_usuario IN (SELECT u_sub.correo FROM usuarios u_sub)
      AND tar_link.agenda_id IS NOT NULL AND TRIM(tar_link.agenda_id) ~ '^[0-9]+$'
),
FinalUserPerAgenda AS (
    SELECT
        agenda_id_str,
        correo_usuario AS inferred_correo_usuario
    FROM PotentialAgendaUsers
    WHERE rn = 1
)
SELECT
    CAST(da.agenda_id_str AS INT),
    COALESCE(fupa.inferred_correo_usuario, (SELECT u_fallback.correo FROM usuarios u_fallback ORDER BY RANDOM() LIMIT 1)),
    da.etiqueta_str
FROM DistinctAgendasFromCSV da
LEFT JOIN FinalUserPerAgenda fupa ON da.agenda_id_str = fupa.agenda_id_str
WHERE EXISTS (SELECT 1 FROM usuarios LIMIT 1)
ON CONFLICT (id) DO NOTHING;

DO $$ BEGIN
    RAISE NOTICE 'DEBUG: Finalizada la inserción en agendas. (Lógica Optimizada)';
END $$;

INSERT INTO agenda_reserva_descartados
SELECT tar.*
FROM temp_agenda_reserva tar
WHERE NOT (
    tar.agenda_id IS NOT NULL AND TRIM(tar.agenda_id) ~ '^[0-9]+$'
    AND tar.etiqueta IS NOT NULL AND TRIM(tar.etiqueta) <> ''
    AND EXISTS (SELECT 1 FROM usuarios LIMIT 1)
);




INSERT INTO agenda_reserva_descartados
SELECT tar.*
FROM temp_agenda_reserva tar
WHERE NOT (
    tar.agenda_id IS NOT NULL AND TRIM(tar.agenda_id) ~ '^[0-9]+$'
    AND tar.etiqueta IS NOT NULL AND TRIM(tar.etiqueta) <> ''
    AND EXISTS (SELECT 1 FROM usuarios LIMIT 1)
);


DO $$ BEGIN
    RAISE NOTICE 'DEBUG: Iniciando la inserción en reservas... (Nueva Lógica)';
END $$;




INSERT INTO reservas (id, agenda_id, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_booked)
SELECT
    CAST(TRIM(tar.id) AS INT),
    CASE
        WHEN tar.agenda_id IS NOT NULL AND TRIM(tar.agenda_id) ~ '^[0-9]+$' AND CAST(TRIM(tar.agenda_id) AS INT) IN (SELECT ag.id FROM agendas ag)
        THEN CAST(TRIM(tar.agenda_id) AS INT)
        ELSE NULL
    END,
    CAST(TRIM(tar.fecha) AS DATE),
    CAST(TRIM(tar.monto) AS INT),
    CAST(TRIM(tar.cantidad_personas) AS INT),
    CASE
        WHEN tar.estado_disponibilidad IS NULL OR TRIM(tar.estado_disponibilidad) = '' THEN 'Disponible'
        ELSE TRIM(tar.estado_disponibilidad)
    END,
    CAST(TRIM(tar.puntos) AS INT)
FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND TRIM(tar.id) ~ '^[0-9]+$'
    AND tar.fecha IS NOT NULL AND TRIM(tar.fecha) <> ''
    AND tar.monto IS NOT NULL AND TRIM(tar.monto) ~ '^[0-9]+$' AND CAST(TRIM(tar.monto) AS INT) > 0
    AND tar.cantidad_personas IS NOT NULL AND TRIM(tar.cantidad_personas) ~ '^[0-9]+$' AND CAST(TRIM(tar.cantidad_personas) AS INT) > 0
    AND tar.puntos IS NOT NULL AND TRIM(tar.puntos) ~ '^[0-9]+$' AND CAST(TRIM(tar.puntos) AS INT) >= 0
ON CONFLICT (id) DO NOTHING;

DO $$ BEGIN
    RAISE NOTICE 'DEBUG: Finalizada la inserción en reservas. (Nueva Lógica)';
END $$;




INSERT INTO agenda_reserva_descartados
SELECT tar.*
FROM temp_agenda_reserva tar
WHERE NOT (
    tar.agenda_id IS NOT NULL AND TRIM(tar.agenda_id) ~ '^[0-9]+$'
    AND tar.etiqueta IS NOT NULL AND TRIM(tar.etiqueta) <> ''
    AND EXISTS (SELECT 1 FROM usuarios LIMIT 1)
);





INSERT INTO reservas_descartados
SELECT tar.* FROM temp_agenda_reserva tar
WHERE NOT (
    tar.id IS NOT NULL AND TRIM(tar.id) ~ '^[0-9]+$'
    AND tar.fecha IS NOT NULL AND TRIM(tar.fecha) <> ''
    AND tar.monto IS NOT NULL AND TRIM(tar.monto) ~ '^[0-9]+$' AND CAST(TRIM(tar.monto) AS INT) > 0
    AND tar.cantidad_personas IS NOT NULL AND TRIM(tar.cantidad_personas) ~ '^[0-9]+$' AND CAST(TRIM(tar.cantidad_personas) AS INT) > 0
    AND tar.puntos IS NOT NULL AND TRIM(tar.puntos) ~ '^[0-9]+$' AND CAST(TRIM(tar.puntos) AS INT) >= 0
    AND (
            (tar.agenda_id IS NULL OR TRIM(tar.agenda_id) = '') OR
            (
                TRIM(tar.agenda_id) ~ '^[0-9]+$' AND
                CAST(TRIM(tar.agenda_id) AS INT) IN (SELECT ag.id FROM agendas ag)
            )
        )
);


INSERT INTO transportes (id, correo_empleado, lugar_origen, lugar_llegada, capacidad, tiempo_estimado, precio_asiento, empresa, fecha_salida, fecha_llegada)
SELECT
    CAST(TRIM(tar.id) AS INT),
    TRIM(tar.correo_empleado),
    TRIM(tar.lugar_origen),
    TRIM(tar.lugar_llegada),
    CASE WHEN tar.capacidad IS NOT NULL AND TRIM(tar.capacidad) ~ '^[0-9]+$' THEN CAST(TRIM(tar.capacidad) AS INT) ELSE NULL END,
    TRIM(tar.tiempo_estimado),
    CAST(TRIM(tar.precio_asiento) AS DECIMAL(10,2)),
    TRIM(tar.empresa),
    CAST(TRIM(tar.fecha_salida) AS TIMESTAMP),
    CAST(TRIM(tar.fecha_llegada) AS TIMESTAMP)
FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND TRIM(tar.id) ~ '^[0-9]+$' AND CAST(TRIM(tar.id) AS INT) IN (SELECT r.id FROM reservas r)
    AND tar.correo_empleado IN (SELECT e.correo FROM empleados e)
    AND tar.lugar_origen IS NOT NULL AND TRIM(tar.lugar_origen) <> ''
    AND tar.lugar_llegada IS NOT NULL AND TRIM(tar.lugar_llegada) <> ''
    AND tar.precio_asiento IS NOT NULL AND TRIM(tar.precio_asiento) ~ '^[0-9]+(\.[0-9]{1,2})?$' AND CAST(TRIM(tar.precio_asiento) AS DECIMAL(10,2)) > 0
    AND tar.empresa IS NOT NULL AND TRIM(tar.empresa) <> ''
    AND tar.fecha_salida IS NOT NULL AND TRIM(tar.fecha_salida) <> ''
    AND tar.fecha_llegada IS NOT NULL AND TRIM(tar.fecha_llegada) <> ''
    AND CAST(TRIM(tar.fecha_llegada) AS TIMESTAMP) > CAST(TRIM(tar.fecha_salida) AS TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

INSERT INTO transportes_descartados
SELECT tar.* FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND tar.id ~ '^[0-9]+$'
  AND (tar.lugar_origen IS NOT NULL OR tar.lugar_llegada IS NOT NULL OR tar.precio_asiento IS NOT NULL OR tar.empresa IS NOT NULL)
  AND NOT (
    CAST(TRIM(tar.id) AS INT) IN (SELECT r.id FROM reservas r)
    AND tar.correo_empleado IN (SELECT e.correo FROM empleados e)
    AND tar.lugar_origen IS NOT NULL AND TRIM(tar.lugar_origen) <> ''
    AND tar.lugar_llegada IS NOT NULL AND TRIM(tar.lugar_llegada) <> ''
    AND tar.precio_asiento IS NOT NULL AND TRIM(tar.precio_asiento) ~ '^[0-9]+(\.[0-9]{1,2})?$' AND CAST(TRIM(tar.precio_asiento) AS DECIMAL(10,2)) > 0
    AND tar.empresa IS NOT NULL AND TRIM(tar.empresa) <> ''
    AND tar.fecha_salida IS NOT NULL AND TRIM(tar.fecha_salida) <> ''
    AND tar.fecha_llegada IS NOT NULL AND TRIM(tar.fecha_llegada) <> ''
    AND CAST(TRIM(tar.fecha_llegada) AS TIMESTAMP) > CAST(TRIM(tar.fecha_salida) AS TIMESTAMP)
);






INSERT INTO buses (id, tipo, comodidades)
SELECT
    CAST(TRIM(tar.id) AS INT),
    TRIM(tar.tipo_bus),
    string_to_array(regexp_replace(COALESCE(TRIM(tar.comodidades),''), E'[\\{\\}\"\\s]', '', 'g'), ',')
FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND TRIM(tar.id) ~ '^[0-9]+$' AND CAST(TRIM(tar.id) AS INT) IN (SELECT t.id FROM transportes t)
    AND tar.tipo_bus IS NOT NULL AND TRIM(tar.tipo_bus) <> ''
ON CONFLICT (id) DO NOTHING;

INSERT INTO buses_descartados
SELECT tar.* FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND tar.id ~ '^[0-9]+$' AND tar.tipo_bus IS NOT NULL AND TRIM(tar.tipo_bus) <> ''
  AND NOT (CAST(TRIM(tar.id) AS INT) IN (SELECT t.id FROM transportes t));







INSERT INTO trenes (id, comodidades, paradas)
SELECT
    CAST(TRIM(tar.id) AS INT),
    string_to_array(regexp_replace(COALESCE(TRIM(tar.comodidades),''), E'[\\{\\}\"\\s]', '', 'g'), ','),
    string_to_array(regexp_replace(COALESCE(TRIM(tar.paradas),''), E'[\\{\\}\"\\s]', '', 'g'), ',')
FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND TRIM(tar.id) ~ '^[0-9]+$' AND CAST(TRIM(tar.id) AS INT) IN (SELECT t.id FROM transportes t)
    AND tar.paradas IS NOT NULL AND TRIM(tar.paradas) <> '' AND TRIM(tar.paradas) <> '{}'
ON CONFLICT (id) DO NOTHING;

INSERT INTO trenes_descartados
SELECT tar.* FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND tar.id ~ '^[0-9]+$' AND tar.paradas IS NOT NULL AND TRIM(tar.paradas) <> '' AND TRIM(tar.paradas) <> '{}'
  AND NOT (CAST(TRIM(tar.id) AS INT) IN (SELECT t.id FROM transportes t));





INSERT INTO aviones (id, clase, escalas)
SELECT
    CAST(TRIM(tar.id) AS INT),
    TRIM(tar.clase),
    string_to_array(regexp_replace(COALESCE(TRIM(tar.escalas),''), E'[\\{\\}\"\\s]', '', 'g'), ',')
FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND TRIM(tar.id) ~ '^[0-9]+$' AND CAST(TRIM(tar.id) AS INT) IN (SELECT t.id FROM transportes t)
    AND tar.clase IS NOT NULL AND TRIM(tar.clase) <> ''
ON CONFLICT (id) DO NOTHING;

INSERT INTO aviones_descartados
SELECT tar.* FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND tar.id ~ '^[0-9]+$' AND tar.clase IS NOT NULL AND TRIM(tar.clase) <> ''
  AND NOT (CAST(TRIM(tar.id) AS INT) IN (SELECT t.id FROM transportes t));





INSERT INTO hospedajes (id, nombre, ubicacion, precio_noche, estrellas, comodidades, fecha_checkin, fecha_checkout)
SELECT
    CAST(TRIM(tar.id) AS INT),
    TRIM(tar.nombre_hospedaje),
    TRIM(tar.ubicacion),
    CAST(TRIM(tar.precio_noche) AS INT),
    CAST(TRIM(tar.estrellas) AS INT),
    string_to_array(regexp_replace(COALESCE(TRIM(tar.comodidades),''), E'[\\{\\}\"\\s]', '', 'g'), ','),
    CAST(TRIM(tar.fecha_checkin) AS DATE),
    CAST(TRIM(tar.fecha_checkout) AS DATE)
FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND TRIM(tar.id) ~ '^[0-9]+$' AND CAST(TRIM(tar.id) AS INT) IN (SELECT r.id FROM reservas r)
    AND tar.nombre_hospedaje IS NOT NULL AND TRIM(tar.nombre_hospedaje) <> ''
    AND tar.ubicacion IS NOT NULL AND TRIM(tar.ubicacion) <> ''
    AND tar.precio_noche IS NOT NULL AND TRIM(tar.precio_noche) ~ '^[0-9]+$' AND CAST(TRIM(tar.precio_noche) AS INT) > 0
    AND tar.estrellas IS NOT NULL AND TRIM(tar.estrellas) ~ '^[0-7]$'
    AND tar.fecha_checkin IS NOT NULL AND TRIM(tar.fecha_checkin) <> ''
    AND tar.fecha_checkout IS NOT NULL AND TRIM(tar.fecha_checkout) <> ''
    AND CAST(TRIM(tar.fecha_checkout) AS DATE) > CAST(TRIM(tar.fecha_checkin) AS DATE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO hospedajes_descartados
SELECT tar.* FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND tar.id ~ '^[0-9]+$' AND tar.nombre_hospedaje IS NOT NULL AND TRIM(tar.nombre_hospedaje) <> ''
  AND NOT (
    CAST(TRIM(tar.id) AS INT) IN (SELECT r.id FROM reservas r)
    AND tar.ubicacion IS NOT NULL AND TRIM(tar.ubicacion) <> ''
    AND tar.precio_noche IS NOT NULL AND TRIM(tar.precio_noche) ~ '^[0-9]+$' AND CAST(TRIM(tar.precio_noche) AS INT) > 0
    AND tar.estrellas IS NOT NULL AND TRIM(tar.estrellas) ~ '^[0-7]$'
    AND tar.fecha_checkin IS NOT NULL AND TRIM(tar.fecha_checkin) <> ''
    AND tar.fecha_checkout IS NOT NULL AND TRIM(tar.fecha_checkout) <> ''
    AND CAST(TRIM(tar.fecha_checkout) AS DATE) > CAST(TRIM(tar.fecha_checkin) AS DATE)
  );


INSERT INTO hoteles (id, politicas)
SELECT
    CAST(TRIM(tar.id) AS INT),
    string_to_array(regexp_replace(COALESCE(TRIM(tar.politicas),''), E'[\\{\\}\"\\s]', '', 'g'), ',')
FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND TRIM(tar.id) ~ '^[0-9]+$' AND CAST(TRIM(tar.id) AS INT) IN (SELECT h.id FROM hospedajes h)
    AND tar.politicas IS NOT NULL AND TRIM(tar.politicas) <> '' AND TRIM(tar.politicas) <> '{}'
ON CONFLICT (id) DO NOTHING;

INSERT INTO hoteles_descartados
SELECT tar.* FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND tar.id ~ '^[0-9]+$' AND tar.politicas IS NOT NULL AND TRIM(tar.politicas) <> '' AND TRIM(tar.politicas) <> '{}'
  AND NOT (CAST(TRIM(tar.id) AS INT) IN (SELECT h.id FROM hospedajes h));




INSERT INTO airbnb (id, nombre_anfitrion, contacto_anfitrion, descripcion, piezas, camas, banos)
SELECT
    CAST(TRIM(tar.id) AS INT),
    TRIM(tar.nombre_anfitrion),
    TRIM(tar.contacto_anfitrion),
    TRIM(tar.descripcion_airbnb),
    CAST(TRIM(tar.piezas) AS INT),
    CAST(TRIM(tar.camas) AS INT),
    CAST(TRIM(tar.banos) AS INT)
FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND TRIM(tar.id) ~ '^[0-9]+$' AND CAST(TRIM(tar.id) AS INT) IN (SELECT h.id FROM hospedajes h)
    AND tar.nombre_anfitrion IS NOT NULL AND TRIM(tar.nombre_anfitrion) <> ''
    AND tar.contacto_anfitrion IS NOT NULL AND TRIM(tar.contacto_anfitrion) <> ''
    AND tar.descripcion_airbnb IS NOT NULL AND TRIM(tar.descripcion_airbnb) <> ''
    AND tar.piezas IS NOT NULL AND TRIM(tar.piezas) ~ '^[0-9]+$' AND CAST(TRIM(tar.piezas) AS INT) >= 0
    AND tar.camas IS NOT NULL AND TRIM(tar.camas) ~ '^[0-9]+$' AND CAST(TRIM(tar.camas) AS INT) >= 0
    AND tar.banos IS NOT NULL AND TRIM(tar.banos) ~ '^[0-9]+$' AND CAST(TRIM(tar.banos) AS INT) >= 0
ON CONFLICT (id) DO NOTHING;

INSERT INTO airbnb_descartados
SELECT tar.* FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND tar.id ~ '^[0-9]+$' AND tar.nombre_anfitrion IS NOT NULL AND TRIM(tar.nombre_anfitrion) <> ''
  AND NOT (
    CAST(TRIM(tar.id) AS INT) IN (SELECT h.id FROM hospedajes h)
    AND tar.contacto_anfitrion IS NOT NULL AND TRIM(tar.contacto_anfitrion) <> ''
    AND tar.descripcion_airbnb IS NOT NULL AND TRIM(tar.descripcion_airbnb) <> ''
    AND tar.piezas IS NOT NULL AND TRIM(tar.piezas) ~ '^[0-9]+$' AND CAST(TRIM(tar.piezas) AS INT) >= 0
    AND tar.camas IS NOT NULL AND TRIM(tar.camas) ~ '^[0-9]+$' AND CAST(TRIM(tar.camas) AS INT) >= 0
    AND tar.banos IS NOT NULL AND TRIM(tar.banos) ~ '^[0-9]+$' AND CAST(TRIM(tar.banos) AS INT) >= 0
  );

INSERT INTO habitaciones (hotel_id, numero_habitacion, tipo)
SELECT
    CAST(TRIM(th.hotel_id) AS INT),
    CAST(TRIM(th.numero_habitacion) AS INT),
    TRIM(th.tipo)
FROM temp_habitaciones th
WHERE th.hotel_id IS NOT NULL AND TRIM(th.hotel_id) ~ '^[0-9]+$' AND CAST(TRIM(th.hotel_id) AS INT) IN (SELECT h.id FROM hoteles h)
    AND th.numero_habitacion IS NOT NULL AND TRIM(th.numero_habitacion) ~ '^[0-9]+$'
    AND th.tipo IS NOT NULL AND TRIM(th.tipo) <> ''
ON CONFLICT (hotel_id, numero_habitacion) DO NOTHING;

INSERT INTO habitaciones_descartados
SELECT th.* FROM temp_habitaciones th
WHERE NOT (
    th.hotel_id IS NOT NULL AND TRIM(th.hotel_id) ~ '^[0-9]+$' AND CAST(TRIM(th.hotel_id) AS INT) IN (SELECT h.id FROM hoteles h)
    AND th.numero_habitacion IS NOT NULL AND TRIM(th.numero_habitacion) ~ '^[0-9]+$'
    AND th.tipo IS NOT NULL AND TRIM(th.tipo) <> ''
);


INSERT INTO panoramas (id, nombre, empresa, descripcion, ubicacion, duracion, precio_persona, capacidad, restricciones, fecha_panorama)
SELECT
    CAST(TRIM(tar.id) AS INT),
    TRIM(tar.nombre_panorama),
    TRIM(tar.empresa),
    NULL,
    TRIM(tar.ubicacion),
    CASE WHEN tar.duracion IS NOT NULL AND TRIM(tar.duracion) ~ '^[0-9]+$' THEN CAST(TRIM(tar.duracion) AS INT) ELSE NULL END,
    CAST(TRIM(tar.precio_persona) AS INT),
    CASE WHEN tar.capacidad IS NOT NULL AND TRIM(tar.capacidad) ~ '^[0-9]+$' THEN CAST(TRIM(tar.capacidad) AS INT) ELSE NULL END,
    string_to_array(regexp_replace(COALESCE(TRIM(tar.restricciones),''), E'[\\{\\}\"\\s]', '', 'g'), ','),
    CAST(TRIM(tar.fecha_panorama) AS TIMESTAMP)
FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND TRIM(tar.id) ~ '^[0-9]+$' AND CAST(TRIM(tar.id) AS INT) IN (SELECT r.id FROM reservas r)
    AND tar.nombre_panorama IS NOT NULL AND TRIM(tar.nombre_panorama) <> ''
    AND tar.empresa IS NOT NULL AND TRIM(tar.empresa) <> ''
    AND tar.ubicacion IS NOT NULL AND TRIM(tar.ubicacion) <> ''
    AND tar.precio_persona IS NOT NULL AND TRIM(tar.precio_persona) ~ '^[0-9]+$' AND CAST(TRIM(tar.precio_persona) AS INT) > 0
    AND tar.fecha_panorama IS NOT NULL AND TRIM(tar.fecha_panorama) <> ''
ON CONFLICT (id) DO NOTHING;

INSERT INTO panoramas_descartados
SELECT tar.* FROM temp_agenda_reserva tar
WHERE tar.id IS NOT NULL AND tar.id ~ '^[0-9]+$' AND tar.nombre_panorama IS NOT NULL AND TRIM(tar.nombre_panorama) <> ''
  AND NOT (
    CAST(TRIM(tar.id) AS INT) IN (SELECT r.id FROM reservas r)
    AND tar.empresa IS NOT NULL AND TRIM(tar.empresa) <> ''
    AND tar.ubicacion IS NOT NULL AND TRIM(tar.ubicacion) <> ''
    AND tar.precio_persona IS NOT NULL AND TRIM(tar.precio_persona) ~ '^[0-9]+$' AND CAST(TRIM(tar.precio_persona) AS INT) > 0
    AND tar.fecha_panorama IS NOT NULL AND TRIM(tar.fecha_panorama) <> ''
  );





INSERT INTO participantes (id, id_panorama, nombre, edad)
SELECT
    ROW_NUMBER() OVER (ORDER BY CAST(TRIM(tp.id_panorama) AS INT), TRIM(tp.nombre)) AS generated_id,
    CAST(TRIM(tp.id_panorama) AS INT),
    TRIM(tp.nombre),
    CAST(TRIM(tp.edad) AS INT)
FROM temp_participantes tp
WHERE tp.id_panorama IS NOT NULL AND TRIM(tp.id_panorama) ~ '^[0-9]+$' AND CAST(TRIM(tp.id_panorama) AS INT) IN (SELECT p.id FROM panoramas p)
    AND tp.nombre IS NOT NULL AND TRIM(tp.nombre) <> ''
    AND tp.edad IS NOT NULL AND TRIM(tp.edad) ~ '^[0-9]+$' AND CAST(TRIM(tp.edad) AS INT) >= 0
ON CONFLICT (id, id_panorama, nombre) DO NOTHING;

INSERT INTO participantes_descartados
SELECT tp.* FROM temp_participantes tp
WHERE NOT (
    tp.id_panorama IS NOT NULL AND TRIM(tp.id_panorama) ~ '^[0-9]+$' AND CAST(TRIM(tp.id_panorama) AS INT) IN (SELECT p.id FROM panoramas p)
    AND tp.nombre IS NOT NULL AND TRIM(tp.nombre) <> ''
    AND tp.edad IS NOT NULL AND TRIM(tp.edad) ~ '^[0-9]+$' AND CAST(TRIM(tp.edad) AS INT) >= 0
);

DELETE FROM reviews;
INSERT INTO reviews (reserva_id, estrellas, descripcion)
SELECT
    CAST(TRIM(trs.reserva_id) AS INT),
    CAST(TRIM(trs.estrellas) AS INT),
    TRIM(trs.descripcion)
FROM temp_review_seguro trs
WHERE trs.reserva_id IS NOT NULL AND TRIM(trs.reserva_id) ~ '^[0-9]+$' AND CAST(TRIM(trs.reserva_id) AS INT) IN (SELECT r.id FROM reservas r)
    AND trs.estrellas IS NOT NULL AND TRIM(trs.estrellas) ~ '^[1-5]$';

INSERT INTO reviews_descartados
SELECT trs.* FROM temp_review_seguro trs
WHERE NOT (
    trs.reserva_id IS NOT NULL AND TRIM(trs.reserva_id) ~ '^[0-9]+$' AND CAST(TRIM(trs.reserva_id) AS INT) IN (SELECT r.id FROM reservas r)
    AND trs.estrellas IS NOT NULL AND TRIM(trs.estrellas) ~ '^[1-5]$'
);

DELETE FROM seguros;
INSERT INTO seguros (reserva_id, tipo, valor, clausula, empresa, correo_usuario)
SELECT
    CAST(TRIM(trs.reserva_id) AS INT),
    TRIM(trs.tipo_seguro),
    CAST(TRIM(trs.valor_seguro) AS INT),
    TRIM(trs.clausula),
    TRIM(trs.empresa_seguro),
    TRIM(trs.correo_usuario)
FROM temp_review_seguro trs
WHERE trs.reserva_id IS NOT NULL AND TRIM(trs.reserva_id) ~ '^[0-9]+$' AND CAST(TRIM(trs.reserva_id) AS INT) IN (SELECT r.id FROM reservas r)
    AND trs.tipo_seguro IS NOT NULL AND TRIM(trs.tipo_seguro) <> ''
    AND trs.valor_seguro IS NOT NULL AND TRIM(trs.valor_seguro) ~ '^[0-9]+$' AND CAST(TRIM(trs.valor_seguro) AS INT) > 0
    AND trs.clausula IS NOT NULL AND TRIM(trs.clausula) <> ''
    AND trs.empresa_seguro IS NOT NULL AND TRIM(trs.empresa_seguro) <> ''
    AND trs.correo_usuario IN (SELECT u.correo FROM usuarios u);

INSERT INTO seguros_descartados
SELECT trs.* FROM temp_review_seguro trs
WHERE NOT (
    trs.reserva_id IS NOT NULL AND TRIM(trs.reserva_id) ~ '^[0-9]+$' AND CAST(TRIM(trs.reserva_id) AS INT) IN (SELECT r.id FROM reservas r)
    AND trs.tipo_seguro IS NOT NULL AND TRIM(trs.tipo_seguro) <> ''
    AND trs.valor_seguro IS NOT NULL AND TRIM(trs.valor_seguro) ~ '^[0-9]+$' AND CAST(TRIM(trs.valor_seguro) AS INT) > 0
    AND trs.clausula IS NOT NULL AND TRIM(trs.clausula) <> ''
    AND trs.empresa_seguro IS NOT NULL AND TRIM(trs.empresa_seguro) <> ''
    AND trs.correo_usuario IN (SELECT u.correo FROM usuarios u)
);

\COPY personas_descartados TO '../descartados/personas_descartados.csv' WITH CSV HEADER;
\COPY usuarios_descartados TO '../descartados/usuarios_descartados.csv' WITH CSV HEADER;
\COPY empleados_descartados TO '../descartados/empleados_descartados.csv' WITH CSV HEADER;
\COPY agenda_reserva_descartados TO '../descartados/agenda_reserva_descartados.csv' WITH CSV HEADER;
\COPY reservas_descartados TO '../descartados/reservas_descartados.csv' WITH CSV HEADER;
\COPY reviews_descartados TO '../descartados/reviews_descartados.csv' WITH CSV HEADER;
\COPY seguros_descartados TO '../descartados/seguros_descartados.csv' WITH CSV HEADER;
\COPY transportes_descartados TO '../descartados/transportes_descartados.csv' WITH CSV HEADER;
\COPY buses_descartados TO '../descartados/buses_descartados.csv' WITH CSV HEADER;
\COPY trenes_descartados TO '../descartados/trenes_descartados.csv' WITH CSV HEADER;
\COPY aviones_descartados TO '../descartados/aviones_descartados.csv' WITH CSV HEADER;
\COPY panoramas_descartados TO '../descartados/panoramas_descartados.csv' WITH CSV HEADER;
\COPY participantes_descartados TO '../descartados/participantes_descartados.csv' WITH CSV HEADER;
\COPY hospedajes_descartados TO '../descartados/hospedajes_descartados.csv' WITH CSV HEADER;
\COPY hoteles_descartados TO '../descartados/hoteles_descartados.csv' WITH CSV HEADER;
\COPY habitaciones_descartados TO '../descartados/habitaciones_descartados.csv' WITH CSV HEADER;
\COPY airbnb_descartados TO '../descartados/airbnb_descartados.csv' WITH CSV HEADER;

SELECT 'personas' as tabla, COUNT(*) as registros_cargados FROM personas
UNION ALL
SELECT 'usuarios', COUNT(*) FROM usuarios
UNION ALL
SELECT 'empleados', COUNT(*) FROM empleados
UNION ALL
SELECT 'agendas', COUNT(*) FROM agendas
UNION ALL
SELECT 'reservas', COUNT(*) FROM reservas
UNION ALL
SELECT 'transportes', COUNT(*) FROM transportes
UNION ALL
SELECT 'buses', COUNT(*) FROM buses
UNION ALL
SELECT 'trenes', COUNT(*) FROM trenes
UNION ALL
SELECT 'aviones', COUNT(*) FROM aviones
UNION ALL
SELECT 'hospedajes', COUNT(*) FROM hospedajes
UNION ALL
SELECT 'hoteles', COUNT(*) FROM hoteles
UNION ALL
SELECT 'airbnb', COUNT(*) FROM airbnb
UNION ALL
SELECT 'habitaciones', COUNT(*) FROM habitaciones
UNION ALL
SELECT 'panoramas', COUNT(*) FROM panoramas
UNION ALL
SELECT 'participantes', COUNT(*) FROM participantes
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'seguros', COUNT(*) FROM seguros;


DROP TABLE IF EXISTS temp_personas;
DROP TABLE IF EXISTS temp_agenda_reserva;
DROP TABLE IF EXISTS temp_habitaciones;
DROP TABLE IF EXISTS temp_participantes;
DROP TABLE IF EXISTS temp_review_seguro;

DROP TABLE IF EXISTS personas_descartados;
DROP TABLE IF EXISTS usuarios_descartados;
DROP TABLE IF EXISTS empleados_descartados;
DROP TABLE IF EXISTS agenda_reserva_descartados;
DROP TABLE IF EXISTS reservas_descartados;
DROP TABLE IF EXISTS reviews_descartados;
DROP TABLE IF EXISTS seguros_descartados;
DROP TABLE IF EXISTS transportes_descartados;
DROP TABLE IF EXISTS buses_descartados;
DROP TABLE IF EXISTS trenes_descartados;
DROP TABLE IF EXISTS aviones_descartados;
DROP TABLE IF EXISTS panoramas_descartados;
DROP TABLE IF EXISTS participantes_descartados;
DROP TABLE IF EXISTS hospedajes_descartados;
DROP TABLE IF EXISTS hoteles_descartados;
DROP TABLE IF EXISTS habitaciones_descartados;
DROP TABLE IF EXISTS airbnb_descartados;
