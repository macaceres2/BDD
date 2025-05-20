

\set ON_ERROR_STOP off
\set errdir '/mnt/c/Users/Manuel/Desktop/U/BDD/BDD/E2/Sites/E2/descartados/'

\! mkdir -p '/mnt/c/Users/Manuel/Desktop/U/BDD/BDD/E2/Sites/E2/descartados/'

CREATE TEMP TABLE temp_personas_csv (
    nombre VARCHAR(255), correo VARCHAR(255), contrasena TEXT, username TEXT,
    telefono_contacto VARCHAR(20), run TEXT, puntos TEXT, jornada TEXT,
    isapre TEXT, contrato TEXT, dv CHAR(1)
);
\COPY temp_personas_csv FROM '/mnt/c/Users/Manuel/Desktop/U/BDD/BDD/E2/Sites/E2/csv/personas.csv' WITH CSV HEADER DELIMITER ',' NULL AS '';

CREATE TEMP TABLE err_personas_temp (LIKE temp_personas_csv INCLUDING DEFAULTS);
CREATE TEMP TABLE err_usuarios_temp (correo VARCHAR(255), puntos TEXT);
CREATE TEMP TABLE err_empleados_temp (correo VARCHAR(255), jornada TEXT, contrato TEXT, isapre TEXT);

DO $$
DECLARE
    r temp_personas_csv%ROWTYPE;
BEGIN
    FOR r IN SELECT * FROM temp_personas_csv LOOP
        BEGIN
            IF r.correo IS NULL OR TRIM(r.correo) = '' THEN RAISE EXCEPTION 'Correo vacío. Fila: %', r; END IF;
            IF r.nombre IS NULL OR TRIM(r.nombre) = '' THEN RAISE EXCEPTION 'Nombre vacío. Fila: %', r; END IF;
            IF r.run IS NULL OR TRIM(r.run) = '' THEN RAISE EXCEPTION 'RUN vacío. Fila: %', r; END IF;
            IF r.dv IS NULL OR TRIM(r.dv) = '' THEN RAISE EXCEPTION 'DV vacío. Fila: %', r; END IF;
            IF r.contrasena IS NULL OR r.contrasena = '' THEN RAISE EXCEPTION 'Contraseña vacía. Fila: %', r; END IF;
            IF r.username IS NULL OR TRIM(r.username) = '' THEN RAISE EXCEPTION 'Username vacío. Fila: %', r; END IF;
            IF r.telefono_contacto IS NULL OR TRIM(r.telefono_contacto) = '' THEN RAISE EXCEPTION 'Teléfono vacío. Fila: %', r; END IF;

            INSERT INTO personas (nombre, run, dv, correo, nombre_usuario, contrasena, telefono_contacto)
            VALUES (TRIM(r.nombre), CAST(TRIM(r.run) AS INT), TRIM(r.dv), TRIM(r.correo), TRIM(r.username), r.contrasena, TRIM(r.telefono_contacto));
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error insertando persona (correo: %): %. Fila: %', TRIM(r.correo), SQLERRM, r;
            INSERT INTO err_personas_temp VALUES (r.*);
        END;
    END LOOP;
END $$;

DO $$
DECLARE
    r temp_personas_csv%ROWTYPE;
    p_puntos INT;
BEGIN
    FOR r IN SELECT * FROM temp_personas_csv LOOP
        BEGIN
            IF EXISTS (SELECT 1 FROM personas p WHERE p.correo = TRIM(r.correo)) AND r.puntos IS NOT NULL AND TRIM(r.puntos) != '' THEN
                p_puntos := CAST(TRIM(r.puntos) AS INT);
                IF p_puntos < 0 THEN
                    RAISE EXCEPTION 'Puntos de usuario < 0: % para correo %', p_puntos, TRIM(r.correo);
                END IF;
                INSERT INTO usuarios (correo, puntos) VALUES (TRIM(r.correo), p_puntos)
                ON CONFLICT (correo) DO NOTHING;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error insertando usuario (correo: %): %. Datos: %, %', TRIM(r.correo), SQLERRM, TRIM(r.correo), r.puntos;
            INSERT INTO err_usuarios_temp VALUES (TRIM(r.correo), r.puntos);
        END;
    END LOOP;
END $$;

DO $$
DECLARE
    r temp_personas_csv%ROWTYPE;
    v_jornada_enum tipo_jornada;
BEGIN
    FOR r IN SELECT * FROM temp_personas_csv LOOP
        BEGIN
            IF EXISTS (SELECT 1 FROM personas p WHERE p.correo = TRIM(r.correo)) AND r.jornada IS NOT NULL AND TRIM(r.jornada) != '' THEN
                IF r.contrato IS NULL OR TRIM(r.contrato) = '' THEN RAISE EXCEPTION 'Contrato faltante empleado (correo: %)', TRIM(r.correo); END IF;
                IF r.isapre IS NULL OR TRIM(r.isapre) = '' THEN RAISE EXCEPTION 'Isapre faltante empleado (correo: %)', TRIM(r.correo); END IF;

                IF LOWER(TRIM(r.jornada)) = 'diurno' THEN v_jornada_enum := 'diurna';
                ELSIF LOWER(TRIM(r.jornada)) = 'nocturno' THEN v_jornada_enum := 'nocturna';
                ELSE RAISE EXCEPTION 'Valor de jornada inválido: "%" para empleado % (no es Diurno ni Nocturno)', r.jornada, TRIM(r.correo);
                END IF;

                INSERT INTO empleados (correo, jornada, contrato, isapre)
                VALUES (
                    TRIM(r.correo),
                    v_jornada_enum,
                    CAST(LOWER(TRIM(r.contrato)) AS tipo_contrato),
                    CAST(TRIM(r.isapre) AS tipo_isapre)
                )
                ON CONFLICT (correo) DO NOTHING;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error insertando empleado (correo: %): %. Datos: %, %, %, %', TRIM(r.correo), SQLERRM, TRIM(r.correo), r.jornada, r.contrato, r.isapre;
            INSERT INTO err_empleados_temp VALUES (TRIM(r.correo), r.jornada, r.contrato, r.isapre);
        END;
    END LOOP;
END $$;

\set personas_descartados_path :errdir'personas_descartados.csv'
COPY (SELECT * FROM err_personas_temp WHERE correo IS NOT NULL) TO :'personas_descartados_path' WITH CSV HEADER;
\set usuarios_descartados_path :errdir'usuarios_descartados.csv'
COPY (SELECT * FROM err_usuarios_temp WHERE correo IS NOT NULL) TO :'usuarios_descartados_path' WITH CSV HEADER;
\set empleados_descartados_path :errdir'empleados_descartados.csv'
COPY (SELECT * FROM err_empleados_temp WHERE correo IS NOT NULL) TO :'empleados_descartados_path' WITH CSV HEADER;

CREATE TEMP TABLE temp_agenda_reserva_csv (
    agenda_id TEXT, etiqueta TEXT, id TEXT, fecha TEXT, monto TEXT, cantidad_personas TEXT,
    estado_disponibilidad TEXT, puntos TEXT, correo_empleado TEXT, lugar_origen TEXT,
    lugar_llegada TEXT, capacidad TEXT, tiempo_estimado TEXT, precio_asiento TEXT, empresa TEXT,
    fecha_salida TEXT, fecha_llegada TEXT, tipo_bus TEXT, comodidades TEXT, escalas TEXT,
    clase TEXT, paradas TEXT, nombre_hospedaje TEXT, ubicacion TEXT, precio_noche TEXT,
    estrellas TEXT, fecha_checkin TEXT, fecha_checkout TEXT, politicas TEXT, nombre_anfitrion TEXT,
    contacto_anfitrion TEXT, descripcion_airbnb TEXT, piezas TEXT, camas TEXT, banos TEXT,
    nombre_panorama TEXT, duracion TEXT, precio_persona TEXT, restricciones TEXT, fecha_panorama TEXT
);
\COPY temp_agenda_reserva_csv FROM '/mnt/c/Users/Manuel/Desktop/U/BDD/BDD/E2/Sites/E2/csv/agenda_reserva.csv' WITH CSV HEADER DELIMITER ',' NULL AS '' QUOTE '"';

CREATE TEMP TABLE err_agendas_temp (agenda_id TEXT, etiqueta TEXT);
CREATE TEMP TABLE err_reservas_temp (LIKE temp_agenda_reserva_csv INCLUDING DEFAULTS);
CREATE TEMP TABLE err_transportes_temp (LIKE temp_agenda_reserva_csv INCLUDING DEFAULTS);
CREATE TEMP TABLE err_buses_temp (LIKE temp_agenda_reserva_csv INCLUDING DEFAULTS);
CREATE TEMP TABLE err_trenes_temp (LIKE temp_agenda_reserva_csv INCLUDING DEFAULTS);
CREATE TEMP TABLE err_aviones_temp (LIKE temp_agenda_reserva_csv INCLUDING DEFAULTS);
CREATE TEMP TABLE err_hospedajes_temp (LIKE temp_agenda_reserva_csv INCLUDING DEFAULTS);
CREATE TEMP TABLE err_hoteles_temp (LIKE temp_agenda_reserva_csv INCLUDING DEFAULTS);
CREATE TEMP TABLE err_airbnb_temp (LIKE temp_agenda_reserva_csv INCLUDING DEFAULTS);
CREATE TEMP TABLE err_panoramas_temp (LIKE temp_agenda_reserva_csv INCLUDING DEFAULTS);

DO $$
DECLARE
    r temp_agenda_reserva_csv%ROWTYPE;
    v_codigo_reserva INT; v_codigo_agenda INT; v_monto DECIMAL(10,2);
    v_cantidad_personas INT; v_puntos_obtenidos INT;
    v_estado_disponibilidad estado_disponibilidad; v_fecha_reserva DATE;
    v_default_empleado_correo VARCHAR(255);
    v_default_usuario_correo VARCHAR(255);
    
    reserva_insertada BOOLEAN;
    transporte_insertado BOOLEAN;
    hospedaje_insertado BOOLEAN;

BEGIN
    SELECT correo INTO v_default_empleado_correo FROM empleados LIMIT 1;
    IF v_default_empleado_correo IS NULL THEN
        RAISE WARNING 'No hay empleados para asignar por defecto a transportes. Esto puede causar fallos si el CSV no provee un correo_empleado válido.';
    END IF;
    SELECT correo INTO v_default_usuario_correo FROM usuarios LIMIT 1;
    IF v_default_usuario_correo IS NULL THEN
        RAISE WARNING 'No hay usuarios para asignar por defecto a agendas. Esto puede causar fallos si se requiere un correo_usuario para una agenda.';
    END IF;

    FOR r IN SELECT * FROM temp_agenda_reserva_csv LOOP
        reserva_insertada := FALSE;
        transporte_insertado := FALSE;
        hospedaje_insertado := FALSE;

        IF r.agenda_id IS NOT NULL AND TRIM(r.agenda_id) != '' THEN
            BEGIN
                v_codigo_agenda := CAST(TRIM(r.agenda_id) AS INT);
                IF r.etiqueta IS NULL OR TRIM(r.etiqueta) = '' THEN RAISE EXCEPTION 'Etiqueta de agenda vacía para ID %', v_codigo_agenda; END IF;
                IF v_default_usuario_correo IS NULL THEN 
                    RAISE EXCEPTION 'No existe usuario por defecto válido para asignar a agenda ID %', v_codigo_agenda; 
                END IF;

                INSERT INTO agendas (codigo_agenda, correo_usuario, etiqueta, fecha_creacion)
                VALUES (v_codigo_agenda, v_default_usuario_correo, TRIM(r.etiqueta), CURRENT_DATE)
                ON CONFLICT (codigo_agenda) DO NOTHING;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error insertando/verificando agenda ID % (Etiqueta: "%"): %', r.agenda_id, r.etiqueta, SQLERRM;
                INSERT INTO err_agendas_temp VALUES (r.agenda_id, r.etiqueta);
            END;
        END IF;

        IF r.id IS NULL OR TRIM(r.id) = '' THEN
            RAISE NOTICE 'Fila en temp_agenda_reserva_csv sin ID de reserva. Saltando. Fila: %', r;
            CONTINUE; 
        END IF;
        
        BEGIN 
            v_codigo_reserva := CAST(TRIM(r.id) AS INT);
            v_fecha_reserva := CASE WHEN TRIM(COALESCE(r.fecha,'')) = '' THEN CURRENT_DATE ELSE CAST(TRIM(r.fecha) AS DATE) END;
            
            IF TRIM(COALESCE(r.monto,'')) = '' THEN RAISE EXCEPTION 'Monto de reserva vacío para ID %', v_codigo_reserva; END IF;
            v_monto := CAST(TRIM(r.monto) AS DECIMAL(10,2));
            IF v_monto <= 0 THEN RAISE EXCEPTION 'Monto de reserva debe ser > 0 (valor: %) para ID %', r.monto, v_codigo_reserva; END IF;

            IF TRIM(COALESCE(r.cantidad_personas,'')) = '' THEN RAISE EXCEPTION 'Cantidad personas vacía para ID %', v_codigo_reserva; END IF;
            v_cantidad_personas := CAST(TRIM(r.cantidad_personas) AS INT);
            IF v_cantidad_personas <= 0 THEN RAISE EXCEPTION 'Cantidad personas debe ser > 0 (valor: %) para ID %', r.cantidad_personas, v_codigo_reserva; END IF;

            IF TRIM(COALESCE(r.puntos,'')) = '' THEN RAISE EXCEPTION 'Puntos "booked" obtenidos vacíos para reserva ID %', v_codigo_reserva; END IF;
            v_puntos_obtenidos := CAST(TRIM(r.puntos) AS INT);
            IF v_puntos_obtenidos <= 0 THEN RAISE EXCEPTION 'Puntos "booked" obtenidos deben ser > 0 (valor: %) para reserva ID %', r.puntos, v_codigo_reserva; END IF;
            
            v_estado_disponibilidad := CASE WHEN LOWER(TRIM(COALESCE(r.estado_disponibilidad,'Disponible'))) = 'no disponible' THEN 'No disponible'::estado_disponibilidad ELSE 'Disponible'::estado_disponibilidad END;
            v_codigo_agenda := CASE WHEN TRIM(COALESCE(r.agenda_id,'')) = '' THEN NULL ELSE CAST(TRIM(r.agenda_id) AS INT) END;

            IF v_codigo_agenda IS NOT NULL AND NOT EXISTS (SELECT 1 FROM agendas a WHERE a.codigo_agenda = v_codigo_agenda) THEN
                 RAISE EXCEPTION 'Agenda ID % para reserva % no existe en tabla agendas (puede haber sido descartada).', v_codigo_agenda, v_codigo_reserva;
            END IF;
             IF (v_codigo_agenda IS NULL AND v_estado_disponibilidad = 'No disponible'::estado_disponibilidad) OR
               (v_codigo_agenda IS NOT NULL AND v_estado_disponibilidad = 'Disponible'::estado_disponibilidad) THEN
                RAISE EXCEPTION 'Reserva ID % viola CHECK una_agenda_max. Estado CSV: "%", Agenda ID CSV: "%". Interpretado como Estado: %, Agenda ID: %', v_codigo_reserva, r.estado_disponibilidad, r.agenda_id, v_estado_disponibilidad, v_codigo_agenda;
            END IF;

            INSERT INTO reservas (codigo_reserva, codigo_agenda, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_obtenidos)
            VALUES (v_codigo_reserva, v_codigo_agenda, v_fecha_reserva, v_monto, v_cantidad_personas, v_estado_disponibilidad, v_puntos_obtenidos);
            reserva_insertada := TRUE;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error insertando RESERVA ID %: %. Fila CSV: %', v_codigo_reserva, SQLERRM, r;
            INSERT INTO err_reservas_temp VALUES (r.*);
            CONTINUE; 
        END; 

        IF reserva_insertada THEN
            -- TRANSPORTE
            IF  (r.lugar_origen IS NOT NULL AND TRIM(r.lugar_origen) != '') OR
                (r.lugar_llegada IS NOT NULL AND TRIM(r.lugar_llegada) != '') OR
                (r.empresa IS NOT NULL AND TRIM(r.empresa) != '') OR
                (r.precio_asiento IS NOT NULL AND TRIM(r.precio_asiento) != '')
            THEN -- Intenta procesar como transporte si al menos algún campo clave de transporte tiene valor
                BEGIN 
                    -- Validaciones estrictas para campos obligatorios de transporte
                    IF r.lugar_origen IS NULL OR TRIM(r.lugar_origen) = '' THEN RAISE EXCEPTION 'lugar_origen vacío para transporte de reserva %', v_codigo_reserva; END IF;
                    IF r.lugar_llegada IS NULL OR TRIM(r.lugar_llegada) = '' THEN RAISE EXCEPTION 'lugar_llegada vacío para transporte de reserva %', v_codigo_reserva; END IF;
                    IF r.empresa IS NULL OR TRIM(r.empresa) = '' THEN RAISE EXCEPTION 'empresa vacía para transporte de reserva %', v_codigo_reserva; END IF;
                    IF r.fecha_salida IS NULL OR TRIM(r.fecha_salida) = '' THEN RAISE EXCEPTION 'fecha_salida vacía para transporte de reserva %', v_codigo_reserva; END IF;
                    IF r.fecha_llegada IS NULL OR TRIM(r.fecha_llegada) = '' THEN RAISE EXCEPTION 'fecha_llegada vacía para transporte de reserva %', v_codigo_reserva; END IF;
                    IF r.precio_asiento IS NULL OR TRIM(r.precio_asiento) = '' THEN RAISE EXCEPTION 'precio_asiento vacío para transporte de reserva %', v_codigo_reserva; END IF;

                    DECLARE
                        v_trans_correo_empleado VARCHAR(255);
                        v_trans_precio_asiento NUMERIC(10,2);
                        v_trans_capacidad INT;
                        v_trans_fecha_salida TIMESTAMP;
                        v_trans_fecha_llegada TIMESTAMP;
                    BEGIN 
                        v_trans_precio_asiento := CAST(TRIM(r.precio_asiento) AS DECIMAL(10,2));
                        IF v_trans_precio_asiento <= 0 THEN RAISE EXCEPTION 'Precio asiento transporte debe ser > 0 (valor: %)', r.precio_asiento; END IF;
                        
                        IF r.correo_empleado IS NOT NULL AND TRIM(r.correo_empleado) != '' THEN v_trans_correo_empleado := TRIM(r.correo_empleado);
                        ELSE v_trans_correo_empleado := v_default_empleado_correo; END IF;

                        IF v_trans_correo_empleado IS NULL THEN RAISE EXCEPTION 'Correo empleado para transporte es NULL y no hay default disponible.'; END IF;
                        IF NOT EXISTS (SELECT 1 FROM empleados e WHERE e.correo = v_trans_correo_empleado) THEN 
                            RAISE EXCEPTION 'Empleado "%" para transporte no existe en tabla empleados.', v_trans_correo_empleado; 
                        END IF;
                        
                        v_trans_fecha_salida := CAST(TRIM(r.fecha_salida) AS TIMESTAMP);
                        v_trans_fecha_llegada := CAST(TRIM(r.fecha_llegada) AS TIMESTAMP);
                        IF v_trans_fecha_llegada <= v_trans_fecha_salida THEN RAISE EXCEPTION 'Fecha llegada transporte ("%") no es posterior a salida ("%")', r.fecha_llegada, r.fecha_salida; END IF;
                        
                        v_trans_capacidad := CASE WHEN TRIM(COALESCE(r.capacidad,'')) = '' THEN NULL ELSE CAST(TRIM(r.capacidad) AS INT) END;
                        IF v_trans_capacidad IS NOT NULL AND v_trans_capacidad < 0 THEN RAISE EXCEPTION 'Capacidad transporte negativa: %', r.capacidad; END IF;

                        INSERT INTO transportes (codigo_reserva, correo_empleado, lugar_origen, lugar_llegada, capacidad, tiempo_estimado, precio_asiento, empresa, fecha_salida, fecha_llegada)
                        VALUES (v_codigo_reserva, v_trans_correo_empleado, TRIM(r.lugar_origen), TRIM(r.lugar_llegada), v_trans_capacidad, TRIM(r.tiempo_estimado), v_trans_precio_asiento, TRIM(r.empresa), v_trans_fecha_salida, v_trans_fecha_llegada);
                        transporte_insertado := TRUE;
                    END;
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Error insertando TRANSPORTE para reserva ID %: %. Fila CSV: %', v_codigo_reserva, SQLERRM, r;
                    INSERT INTO err_transportes_temp VALUES (r.*);
                END; 

                IF transporte_insertado THEN
                    -- BUS
                    IF r.tipo_bus IS NOT NULL AND TRIM(r.tipo_bus) != '' THEN
                        BEGIN
                            INSERT INTO buses (codigo_reserva, tipo, comodidades)
                            VALUES (v_codigo_reserva, CAST(LOWER(TRIM(r.tipo_bus)) AS tipo_bus), string_to_array(regexp_replace(COALESCE(r.comodidades,'{}'), '[{}"\s]', '', 'g'), ','));
                        EXCEPTION WHEN OTHERS THEN
                            RAISE NOTICE 'Error insertando BUS para reserva ID % (Transporte OK): %. Fila CSV: %', v_codigo_reserva, SQLERRM, r;
                            INSERT INTO err_buses_temp VALUES (r.*);
                        END;
                    END IF;
                    -- TREN
                    IF r.paradas IS NOT NULL AND TRIM(r.paradas) != '{}' AND TRIM(r.paradas) != '' THEN
                         BEGIN
                            INSERT INTO trenes (codigo_reserva, comodidades, paradas)
                            VALUES (v_codigo_reserva, string_to_array(regexp_replace(COALESCE(r.comodidades,'{}'), '[{}"\s]', '', 'g'), ','), string_to_array(regexp_replace(TRIM(r.paradas), '[{}"\s]', '', 'g'), ','));
                        EXCEPTION WHEN OTHERS THEN
                            RAISE NOTICE 'Error insertando TREN para reserva ID % (Transporte OK): %. Fila CSV: %', v_codigo_reserva, SQLERRM, r;
                            INSERT INTO err_trenes_temp VALUES (r.*);
                        END;
                    END IF;
                    -- AVION
                    IF r.clase IS NOT NULL AND TRIM(r.clase) != '' THEN
                        BEGIN
                            INSERT INTO aviones (codigo_reserva, clase, escalas)
                            VALUES (v_codigo_reserva, TRIM(r.clase), string_to_array(regexp_replace(COALESCE(r.escalas,'{}'), '[{}"\s]', '', 'g'), ','));
                        EXCEPTION WHEN OTHERS THEN
                            RAISE NOTICE 'Error insertando AVION para reserva ID % (Transporte OK): %. Fila CSV: %', v_codigo_reserva, SQLERRM, r;
                            INSERT INTO err_aviones_temp VALUES (r.*);
                        END;
                    END IF;
                END IF; 
            END IF; 

            -- HOSPEDAJE
            IF r.nombre_hospedaje IS NOT NULL AND TRIM(r.nombre_hospedaje) != '' AND 
               r.precio_noche IS NOT NULL AND TRIM(r.precio_noche) != ''
            THEN
                 BEGIN 
                    -- Validaciones estrictas para campos obligatorios de hospedaje
                    IF r.ubicacion IS NULL OR TRIM(r.ubicacion) = '' THEN RAISE EXCEPTION 'ubicacion vacía para hospedaje de reserva %', v_codigo_reserva; END IF;
                    IF r.estrellas IS NULL OR TRIM(r.estrellas) = '' THEN RAISE EXCEPTION 'estrellas vacías para hospedaje de reserva %', v_codigo_reserva; END IF;
                    IF r.fecha_checkin IS NULL OR TRIM(r.fecha_checkin) = '' THEN RAISE EXCEPTION 'fecha_checkin vacía para hospedaje de reserva %', v_codigo_reserva; END IF;
                    IF r.fecha_checkout IS NULL OR TRIM(r.fecha_checkout) = '' THEN RAISE EXCEPTION 'fecha_checkout vacía para hospedaje de reserva %', v_codigo_reserva; END IF;
                    
                    DECLARE
                        v_hosp_precio_noche NUMERIC(10,2);
                        v_hosp_estrellas INT;
                        v_hosp_fecha_checkin DATE;
                        v_hosp_fecha_checkout DATE;
                    BEGIN 
                        v_hosp_precio_noche := CAST(TRIM(r.precio_noche) AS DECIMAL(10,2));
                        IF v_hosp_precio_noche <= 0 THEN RAISE EXCEPTION 'Precio noche hospedaje debe ser > 0 (valor: %)', r.precio_noche; END IF;
                        
                        v_hosp_estrellas := CAST(TRIM(r.estrellas) AS INT);
                        IF v_hosp_estrellas < 1 OR v_hosp_estrellas > 5 THEN RAISE EXCEPTION 'Estrellas hospedaje ("%") fuera de rango 1-5', r.estrellas; END IF;
                        
                        v_hosp_fecha_checkin := CAST(TRIM(r.fecha_checkin) AS DATE);
                        v_hosp_fecha_checkout := CAST(TRIM(r.fecha_checkout) AS DATE);
                        IF v_hosp_fecha_checkout <= v_hosp_fecha_checkin THEN RAISE EXCEPTION 'Fecha checkout hospedaje ("%") no es posterior a checkin ("%")',r.fecha_checkout,r.fecha_checkin; END IF;
                        
                        INSERT INTO hospedajes (codigo_reserva, nombre, ubicacion, precio_noche, estrellas, comodidades, fecha_checkin, fecha_checkout)
                        VALUES (v_codigo_reserva, TRIM(r.nombre_hospedaje), TRIM(r.ubicacion), v_hosp_precio_noche, v_hosp_estrellas, string_to_array(regexp_replace(COALESCE(r.comodidades,'{}'), '[{}"\s]', '', 'g'), ','), v_hosp_fecha_checkin, v_hosp_fecha_checkout);
                        hospedaje_insertado := TRUE;
                    END;
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Error insertando HOSPEDAJE para reserva ID %: %. Fila CSV: %', v_codigo_reserva, SQLERRM, r;
                    INSERT INTO err_hospedajes_temp VALUES (r.*);
                END; 

                IF hospedaje_insertado THEN
                    -- HOTEL
                    IF r.politicas IS NOT NULL AND TRIM(r.politicas) != '{}' AND TRIM(r.politicas) != '' THEN
                        BEGIN
                            INSERT INTO hoteles (codigo_reserva, politicas)
                            VALUES (v_codigo_reserva, string_to_array(regexp_replace(TRIM(r.politicas), '[{}"\s]', '', 'g'), ','));
                        EXCEPTION WHEN OTHERS THEN
                            RAISE NOTICE 'Error insertando HOTEL para reserva ID % (Hospedaje OK): %. Fila CSV: %', v_codigo_reserva, SQLERRM, r;
                            INSERT INTO err_hoteles_temp VALUES (r.*);
                        END;
                    END IF;
                    -- AIRBNB
                    IF r.nombre_anfitrion IS NOT NULL AND TRIM(r.nombre_anfitrion) != '' THEN
                        BEGIN
                            IF r.contacto_anfitrion IS NULL OR TRIM(r.contacto_anfitrion) = '' THEN RAISE EXCEPTION 'Contacto anfitrión Airbnb vacío'; END IF;
                            IF r.descripcion_airbnb IS NULL OR TRIM(r.descripcion_airbnb) = '' THEN RAISE EXCEPTION 'Descripción Airbnb vacía'; END IF;
                            IF r.piezas IS NULL OR TRIM(r.piezas) = '' THEN RAISE EXCEPTION 'Piezas Airbnb vacías'; END IF;
                            IF r.camas IS NULL OR TRIM(r.camas) = '' THEN RAISE EXCEPTION 'Camas Airbnb vacías'; END IF;
                            IF r.banos IS NULL OR TRIM(r.banos) = '' THEN RAISE EXCEPTION 'Baños Airbnb vacíos'; END IF;
                            
                            DECLARE
                                v_airbnb_piezas INT; v_airbnb_camas INT; v_airbnb_banos INT;
                            BEGIN
                                v_airbnb_piezas := CAST(TRIM(r.piezas) AS INT);
                                v_airbnb_camas  := CAST(TRIM(r.camas) AS INT);
                                v_airbnb_banos  := CAST(TRIM(r.banos) AS INT);
                                IF v_airbnb_piezas < 0 THEN RAISE EXCEPTION 'Piezas Airbnb negativas: %', r.piezas; END IF;
                                IF v_airbnb_camas < 0 THEN RAISE EXCEPTION 'Camas Airbnb negativas: %', r.camas; END IF;
                                IF v_airbnb_banos < 0 THEN RAISE EXCEPTION 'Baños Airbnb negativos: %', r.banos; END IF;

                                INSERT INTO airbnb (codigo_reserva, nombre_anfitrion, contacto_anfitrion, descripcion, cant_piezas, cant_camas, cant_banos)
                                VALUES (v_codigo_reserva, TRIM(r.nombre_anfitrion), TRIM(r.contacto_anfitrion), TRIM(r.descripcion_airbnb), v_airbnb_piezas, v_airbnb_camas, v_airbnb_banos);
                            END;
                        EXCEPTION WHEN OTHERS THEN
                            RAISE NOTICE 'Error insertando AIRBNB para reserva ID % (Hospedaje OK): %. Fila CSV: %', v_codigo_reserva, SQLERRM, r;
                            INSERT INTO err_airbnb_temp VALUES (r.*);
                        END;
                    END IF;
                END IF; 
            END IF; 

            -- PANORAMA
            IF r.nombre_panorama IS NOT NULL AND TRIM(r.nombre_panorama) != '' AND 
               r.precio_persona IS NOT NULL AND TRIM(r.precio_persona) != ''
            THEN
                BEGIN
                    -- Validaciones estrictas para campos obligatorios de panorama
                    IF r.empresa IS NULL OR TRIM(r.empresa) = '' THEN RAISE EXCEPTION 'empresa vacía para panorama de reserva %', v_codigo_reserva; END IF;
                    IF r.ubicacion IS NULL OR TRIM(r.ubicacion) = '' THEN RAISE EXCEPTION 'ubicacion vacía para panorama de reserva %', v_codigo_reserva; END IF;
                    IF r.fecha_panorama IS NULL OR TRIM(r.fecha_panorama) = '' THEN RAISE EXCEPTION 'fecha_panorama vacía para panorama de reserva %', v_codigo_reserva; END IF;

                    DECLARE
                        v_pano_precio_persona NUMERIC(10,2);
                        v_pano_duracion DECIMAL(5,2);
                        v_pano_capacidad INT;
                    BEGIN 
                        v_pano_precio_persona := CAST(TRIM(r.precio_persona) AS DECIMAL(10,2));
                        IF v_pano_precio_persona <= 0 THEN RAISE EXCEPTION 'Precio persona panorama debe ser > 0 (valor: %)', r.precio_persona; END IF;
                        
                        v_pano_duracion := CASE WHEN TRIM(COALESCE(r.duracion,'')) = '' THEN NULL ELSE CAST(TRIM(r.duracion) AS DECIMAL(5,2)) END;
                        IF v_pano_duracion IS NOT NULL AND v_pano_duracion < 0 THEN RAISE EXCEPTION 'Duración panorama negativa: %', r.duracion; END IF;
                        
                        v_pano_capacidad := CASE WHEN TRIM(COALESCE(r.capacidad,'')) = '' THEN NULL ELSE CAST(TRIM(r.capacidad) AS INT) END;
                        IF v_pano_capacidad IS NOT NULL AND v_pano_capacidad < 0 THEN RAISE EXCEPTION 'Capacidad panorama negativa: %', r.capacidad; END IF;

                        INSERT INTO panoramas (codigo_reserva, nombre, empresa, descripcion, ubicacion, duracion_horas, precio_persona, capacidad_maxima, restricciones, fecha_panorama)
                        VALUES (v_codigo_reserva, TRIM(r.nombre_panorama), TRIM(r.empresa), NULL, TRIM(r.ubicacion), v_pano_duracion, v_pano_precio_persona, v_pano_capacidad, string_to_array(regexp_replace(COALESCE(r.restricciones,'{}'), '[{}"\s]', '', 'g'), ','), CAST(TRIM(r.fecha_panorama) AS TIMESTAMP));
                    END;
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Error insertando PANORAMA para reserva ID %: %. Fila CSV: %', v_codigo_reserva, SQLERRM, r;
                    INSERT INTO err_panoramas_temp VALUES (r.*);
                END; 
            END IF; 
        END IF; 
    END LOOP; 
END $$;

\set agendas_descartados_path :errdir'agendas_descartados.csv'
COPY (SELECT DISTINCT agenda_id, etiqueta FROM err_agendas_temp WHERE agenda_id IS NOT NULL OR etiqueta IS NOT NULL) TO :'agendas_descartados_path' WITH CSV HEADER;
\set reservas_descartados_path :errdir'reservas_descartados.csv'
COPY (SELECT * FROM err_reservas_temp) TO :'reservas_descartados_path' WITH CSV HEADER;
\set transportes_descartados_path :errdir'transportes_descartados.csv'
COPY (SELECT * FROM err_transportes_temp) TO :'transportes_descartados_path' WITH CSV HEADER;
\set buses_descartados_path :errdir'buses_descartados.csv'
COPY (SELECT * FROM err_buses_temp) TO :'buses_descartados_path' WITH CSV HEADER;
\set trenes_descartados_path :errdir'trenes_descartados.csv'
COPY (SELECT * FROM err_trenes_temp) TO :'trenes_descartados_path' WITH CSV HEADER;
\set aviones_descartados_path :errdir'aviones_descartados.csv'
COPY (SELECT * FROM err_aviones_temp) TO :'aviones_descartados_path' WITH CSV HEADER;
\set hospedajes_descartados_path :errdir'hospedajes_descartados.csv'
COPY (SELECT * FROM err_hospedajes_temp) TO :'hospedajes_descartados_path' WITH CSV HEADER;
\set hoteles_descartados_path :errdir'hoteles_descartados.csv'
COPY (SELECT * FROM err_hoteles_temp) TO :'hoteles_descartados_path' WITH CSV HEADER;
\set airbnb_descartados_path :errdir'airbnb_descartados.csv'
COPY (SELECT * FROM err_airbnb_temp) TO :'airbnb_descartados_path' WITH CSV HEADER;
\set panoramas_descartados_path :errdir'panoramas_descartados.csv'
COPY (SELECT * FROM err_panoramas_temp) TO :'panoramas_descartados_path' WITH CSV HEADER;

CREATE TEMP TABLE temp_habitaciones_csv (hotel_id TEXT, numero_habitacion TEXT, tipo TEXT);
\COPY temp_habitaciones_csv FROM '/mnt/c/Users/Manuel/Desktop/U/BDD/BDD/E2/Sites/E2/csv/habitaciones.csv' WITH CSV HEADER DELIMITER ',' NULL AS '';
CREATE TEMP TABLE err_habitaciones_temp (LIKE temp_habitaciones_csv INCLUDING DEFAULTS);

DO $$
DECLARE
    r temp_habitaciones_csv%ROWTYPE;
    v_codigo_reserva_hotel_int INT; v_numero_habitacion_int INT;
    v_tipo_enum tipo_habitacion;
BEGIN
    FOR r IN SELECT * FROM temp_habitaciones_csv LOOP
        BEGIN
            IF r.hotel_id IS NULL OR TRIM(r.hotel_id) = '' THEN RAISE EXCEPTION 'hotel_id vacío. Fila CSV: %', r; END IF;
            v_codigo_reserva_hotel_int := CAST(TRIM(r.hotel_id) AS INT);
            
            IF NOT EXISTS (SELECT 1 FROM hoteles h WHERE h.codigo_reserva = v_codigo_reserva_hotel_int) THEN
                RAISE EXCEPTION 'Hotel con codigo_reserva % no existe en tabla hoteles (puede haber sido descartado o no es un hotel). Fila CSV: %', v_codigo_reserva_hotel_int, r;
            END IF;
            
            IF r.numero_habitacion IS NULL OR TRIM(r.numero_habitacion) = '' THEN RAISE EXCEPTION 'numero_habitacion vacío. Fila CSV: %', r; END IF;
            v_numero_habitacion_int := CAST(TRIM(r.numero_habitacion) AS INT);
            
            IF r.tipo IS NULL OR TRIM(r.tipo) = '' THEN RAISE EXCEPTION 'tipo habitación vacío. Fila CSV: %', r; END IF;
            
            CASE LOWER(TRIM(r.tipo))
                WHEN 'sencilla' THEN v_tipo_enum := 'Sencilla';
                WHEN 'doble' THEN v_tipo_enum := 'Doble';
                WHEN 'matrimonial' THEN v_tipo_enum := 'Matrimonial';
                WHEN 'triple' THEN v_tipo_enum := 'Triple';
                WHEN 'cuadruple' THEN v_tipo_enum := 'Cuádruple'; 
                WHEN 'cuádruple' THEN v_tipo_enum := 'Cuádruple';
                WHEN 'suite' THEN v_tipo_enum := 'Suite';
                ELSE RAISE EXCEPTION 'Valor de tipo habitación inválido: "%" no mapea a ENUM tipo_habitacion. Fila CSV: %', r.tipo, r;
            END CASE;

             INSERT INTO habitaciones (codigo_reserva_hotel, numero_habitacion, tipo)
             VALUES (v_codigo_reserva_hotel_int, v_numero_habitacion_int, v_tipo_enum);
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error insertando HABITACION (Hotel ID CSV: %, Num: %, Tipo CSV: %): %', r.hotel_id, r.numero_habitacion, r.tipo, SQLERRM;
            INSERT INTO err_habitaciones_temp VALUES (r.*);
        END;
    END LOOP;
END $$;
\set habitaciones_descartados_path :errdir'habitaciones_descartados.csv'
COPY (SELECT * FROM err_habitaciones_temp WHERE hotel_id IS NOT NULL) TO :'habitaciones_descartados_path' WITH CSV HEADER;

CREATE TEMP TABLE temp_participantes_csv (panorama_id TEXT, nombre TEXT, edad TEXT);
\COPY temp_participantes_csv FROM '/mnt/c/Users/Manuel/Desktop/U/BDD/BDD/E2/Sites/E2/csv/participantes.csv' WITH CSV HEADER DELIMITER ',' NULL AS '';
CREATE TEMP TABLE err_participantes_temp (LIKE temp_participantes_csv INCLUDING DEFAULTS);

DO $$
DECLARE
    r temp_participantes_csv%ROWTYPE;
    v_panorama_id_int INT; v_edad_int INT;
BEGIN
    FOR r IN SELECT * FROM temp_participantes_csv LOOP
        BEGIN
            IF r.panorama_id IS NULL OR TRIM(r.panorama_id) = '' THEN RAISE EXCEPTION 'panorama_id vacío. Fila CSV: %',r; END IF;
            v_panorama_id_int := CAST(TRIM(r.panorama_id) AS INT);
            
            IF NOT EXISTS (SELECT 1 FROM panoramas p WHERE p.codigo_reserva = v_panorama_id_int) THEN
                RAISE EXCEPTION 'Panorama con codigo_reserva % no existe en tabla panoramas (puede haber sido descartado). Fila CSV: %', v_panorama_id_int, r;
            END IF;
            
            IF r.nombre IS NULL OR TRIM(r.nombre) = '' THEN RAISE EXCEPTION 'nombre participante vacío. Fila CSV: %',r; END IF;
            IF r.edad IS NULL OR TRIM(r.edad) = '' THEN RAISE EXCEPTION 'edad participante vacía. Fila CSV: %',r; END IF;
            v_edad_int := CAST(TRIM(r.edad) AS INT);
            IF v_edad_int < 0 THEN RAISE EXCEPTION 'edad participante < 0: %. Fila CSV: %', r.edad,r; END IF;

            INSERT INTO participantes (codigo_reserva_panorama, nombre, edad)
            VALUES (v_panorama_id_int, TRIM(r.nombre), v_edad_int);
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error insertando PARTICIPANTE (Panorama ID CSV: %, Nombre: %): %', r.panorama_id, r.nombre, SQLERRM;
            INSERT INTO err_participantes_temp VALUES (r.*);
        END;
    END LOOP;
END $$;
\set participantes_descartados_path :errdir'participantes_descartados.csv'
COPY (SELECT * FROM err_participantes_temp WHERE panorama_id IS NOT NULL) TO :'participantes_descartados_path' WITH CSV HEADER;

CREATE TEMP TABLE temp_review_seguro_csv (
    correo_usuario TEXT, puntos TEXT, reserva_id TEXT, tipo_seguro TEXT, valor_seguro TEXT,
    clausula TEXT, empresa_seguro TEXT, estrellas TEXT, descripcion TEXT
);
\COPY temp_review_seguro_csv FROM '/mnt/c/Users/Manuel/Desktop/U/BDD/BDD/E2/Sites/E2/csv/review_seguro.csv' WITH CSV HEADER DELIMITER ',' NULL AS '';

CREATE TEMP TABLE err_reviews_temp (LIKE temp_review_seguro_csv INCLUDING DEFAULTS);
CREATE TEMP TABLE err_seguros_temp (LIKE temp_review_seguro_csv INCLUDING DEFAULTS);

DO $$
DECLARE
    r temp_review_seguro_csv%ROWTYPE;
    v_reserva_id_int INT; v_estrellas_int INT; v_valor_seguro_dec DECIMAL(10,2);
    v_puntos_csv INT;
BEGIN
    FOR r IN SELECT * FROM temp_review_seguro_csv LOOP
        IF r.reserva_id IS NULL OR TRIM(r.reserva_id) = '' THEN
            RAISE NOTICE 'Fila en review_seguro.csv con reserva_id faltante, saltando. Fila: %', r;
            INSERT INTO err_reviews_temp VALUES (r.*); 
            INSERT INTO err_seguros_temp VALUES (r.*);
            CONTINUE;
        END IF;
        v_reserva_id_int := CAST(TRIM(r.reserva_id) AS INT);

        IF NOT EXISTS (SELECT 1 FROM reservas res WHERE res.codigo_reserva = v_reserva_id_int) THEN
            RAISE NOTICE 'Reserva ID % de review_seguro.csv no existe en tabla reservas, saltando. Fila: %', v_reserva_id_int, r;
            INSERT INTO err_reviews_temp VALUES (r.*);
            INSERT INTO err_seguros_temp VALUES (r.*);
            CONTINUE;
        END IF;

        IF r.estrellas IS NOT NULL AND TRIM(r.estrellas) != '' THEN
            BEGIN
                v_estrellas_int := CAST(TRIM(r.estrellas) AS INT);
                IF v_estrellas_int < 1 OR v_estrellas_int > 5 THEN RAISE EXCEPTION 'Estrellas review ("%") fuera de rango 1-5', r.estrellas; END IF;
                INSERT INTO reviews (codigo_reserva, estrellas, comentario, fecha_review)
                VALUES (v_reserva_id_int, v_estrellas_int, TRIM(r.descripcion), CURRENT_DATE);
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error insertando REVIEW para reserva ID %: %. Fila CSV: %', v_reserva_id_int, SQLERRM, r;
                INSERT INTO err_reviews_temp VALUES (r.*);
            END;
        END IF;

        IF r.tipo_seguro IS NOT NULL AND TRIM(r.tipo_seguro) != '' AND 
           r.valor_seguro IS NOT NULL AND TRIM(r.valor_seguro) != '' 
        THEN
            BEGIN
                v_valor_seguro_dec := CAST(TRIM(r.valor_seguro) AS DECIMAL(10,2));
                IF v_valor_seguro_dec <= 0 THEN RAISE EXCEPTION 'Valor seguro debe ser > 0 (valor: %)', r.valor_seguro; END IF;
                IF r.clausula IS NULL OR TRIM(r.clausula) = '' THEN RAISE EXCEPTION 'Clausula seguro vacía'; END IF;
                IF r.empresa_seguro IS NULL OR TRIM(r.empresa_seguro) = '' THEN RAISE EXCEPTION 'Empresa seguro vacía'; END IF;
                
                INSERT INTO seguros (codigo_reserva, tipo, valor, clausula, empresa)
                VALUES (v_reserva_id_int, TRIM(r.tipo_seguro), v_valor_seguro_dec, TRIM(r.clausula), TRIM(r.empresa_seguro));
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error insertando SEGURO para reserva ID %: %. Fila CSV: %', v_reserva_id_int, SQLERRM, r;
                INSERT INTO err_seguros_temp VALUES (r.*);
            END;
        END IF;
        
        IF r.correo_usuario IS NOT NULL AND TRIM(r.correo_usuario) != '' AND 
           r.puntos IS NOT NULL AND TRIM(r.puntos) != '' 
        THEN
            BEGIN
                v_puntos_csv := CAST(TRIM(r.puntos) AS INT);
                IF EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = TRIM(r.correo_usuario)) THEN
                    UPDATE usuarios SET puntos = GREATEST(0, usuarios.puntos + v_puntos_csv) 
                    WHERE correo = TRIM(r.correo_usuario);
                ELSE
                    RAISE NOTICE 'Usuario % (de review_seguro.csv) no encontrado para actualizar puntos. Reserva ID %', TRIM(r.correo_usuario), v_reserva_id_int;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                 RAISE NOTICE 'Error actualizando puntos para usuario % (de review_seguro.csv): %', TRIM(r.correo_usuario), SQLERRM;
            END;
        END IF;

    END LOOP;
END $$;

\set reviews_descartados_path :errdir'reviews_descartados.csv'
COPY (SELECT * FROM err_reviews_temp WHERE reserva_id IS NOT NULL) TO :'reviews_descartados_path' WITH CSV HEADER;
\set seguros_descartados_path :errdir'seguros_descartados.csv'
COPY (SELECT * FROM err_seguros_temp WHERE reserva_id IS NOT NULL) TO :'seguros_descartados_path' WITH CSV HEADER;

DROP TABLE IF EXISTS temp_personas_csv;
DROP TABLE IF EXISTS temp_agenda_reserva_csv;
DROP TABLE IF EXISTS temp_habitaciones_csv;
DROP TABLE IF EXISTS temp_participantes_csv;
DROP TABLE IF EXISTS temp_review_seguro_csv;

DROP TABLE IF EXISTS err_personas_temp;
DROP TABLE IF EXISTS err_usuarios_temp;
DROP TABLE IF EXISTS err_empleados_temp;
DROP TABLE IF EXISTS err_agendas_temp;
DROP TABLE IF EXISTS err_reservas_temp;
DROP TABLE IF EXISTS err_transportes_temp;
DROP TABLE IF EXISTS err_buses_temp;
DROP TABLE IF EXISTS err_trenes_temp;
DROP TABLE IF EXISTS err_aviones_temp;
DROP TABLE IF EXISTS err_hospedajes_temp;
DROP TABLE IF EXISTS err_hoteles_temp;
DROP TABLE IF EXISTS err_airbnb_temp;
DROP TABLE IF EXISTS err_panoramas_temp;
DROP TABLE IF EXISTS err_habitaciones_temp;
DROP TABLE IF EXISTS err_participantes_temp;
DROP TABLE IF EXISTS err_reviews_temp;
DROP TABLE IF EXISTS err_seguros_temp;
