BEGIN;

INSERT INTO personas (correo, nombre, run, dv, username, contrasena, telefono_contacto) VALUES
('luca@viajes.cl', 'Luca Brasi', 20321987, '6', 'lucabrasi', 'luca123', '+56 9 5678 9012'),
('lucas@edubus.cal', 'Lucas Viajero', 20987654, '3', 'lucasviajero', 'lucas123', '+56 9 3456 7890'),
('paulie@viajes.cl', 'Paulie Gatto', 20654321, '2', 'pauliegatto', 'piloto123', '+56 9 4567 8901'),
('cata.bienestar@viajes.cl', 'Cata Bienestar', 10000002, '2', 'catabienestar', 'viaje123', '+56 9 1111 2222'),
('jorge.bienestar@viajes.cl', 'Jorge Bienestar', 10000003, '3', 'jorgebienestar', 'viaje123', '+56 9 3333 4444')
ON CONFLICT (correo) DO NOTHING;

INSERT INTO usuarios (id, correo, puntos) VALUES
(876542, 'lucas@edubus.cal', 0),
(876543, 'paulie@viajes.cl', 0),
(876544, 'luca@viajes.cl', 0),
(876545, 'cata.bienestar@booked.com', 0),
(876546, 'jorge.bienestar@booked.com', 0)
ON CONFLICT (correo) DO NOTHING;

INSERT INTO empleados (correo, jornada, contrato, isapre) VALUES
('luca@viajes.cl', 'Día', 'Part', 'Colmena'),
('paulie@viajes.cl', 'Noche', 'Full', 'Fonasa')
ON CONFLICT (correo) DO NOTHING;

DO $$
DECLARE
    v_agenda_id INT := 66637;
    v_correo_usuario_agenda VARCHAR := 'lucas@edubus.cal';

    v_reserva_hospedaje_id INT := 200001;
    v_reserva_vuelo_ida_id INT := 200002;
    v_reserva_vuelo_vuelta_id INT := 200003;
    v_reserva_bus_palermo_corleone_id INT := 200004;
    v_reserva_bus_corleone_playa_id INT := 200005;
    v_reserva_panorama_cata_id INT := 200006;
    v_reserva_panorama_cena_id INT := 200007;
    v_reserva_panorama_godfather_id INT := 200008;
    v_reserva_panorama_cidma_id INT := 200009;
    
    v_cantidad_personas_global INT := 12;
    v_fecha_reserva_global DATE := '2025-04-22';

    v_iter_panorama_id INT; 
BEGIN

    INSERT INTO agendas (id, correo_usuario, etiqueta) VALUES
    (v_agenda_id, v_correo_usuario_agenda, 'Fin de semestre')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO reservas (id, agenda_id, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_booked) VALUES
    (v_reserva_hospedaje_id, v_agenda_id, v_fecha_reserva_global, (1000 * 4), v_cantidad_personas_global, 'No disponible', 0)
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO hospedajes (id, nombre, ubicacion, precio_noche, estrellas, comodidades, fecha_checkin, fecha_checkout) VALUES
    (v_reserva_hospedaje_id, 'La familia', 'Corleone, Sicilia', 1000, 5, ARRAY['Wi-Fi', 'Cocina', 'A/C'], '2025-08-02', '2025-08-06')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO airbnb (id, nombre_anfitrion, contacto_anfitrion, descripcion, piezas, camas, banos) VALUES
    (v_reserva_hospedaje_id, 'Connie Corleone', '+56945327890', 'Clásica villa siciliana con vista al viñedo', 6, 12, 4)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO reservas (id, agenda_id, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_booked) VALUES
    (v_reserva_vuelo_ida_id, v_agenda_id, v_fecha_reserva_global, (375000 * v_cantidad_personas_global), v_cantidad_personas_global, 'No disponible', 0)
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO transportes (id, correo_empleado, lugar_origen, lugar_llegada, capacidad, tiempo_estimado, precio_asiento, empresa, fecha_salida, fecha_llegada) VALUES
    (v_reserva_vuelo_ida_id, 'paulie@viajes.cl', 'Santiago', 'Palermo', 200, '20h', 375000, 'AeroPeor', '2025-08-01 03:00:00', '2025-08-01 23:00:00')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO aviones (id, clase, escalas) VALUES
    (v_reserva_vuelo_ida_id, 'Clase económica', ARRAY['Río', 'Casablanca'])
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO reservas (id, agenda_id, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_booked) VALUES
    (v_reserva_vuelo_vuelta_id, v_agenda_id, v_fecha_reserva_global, (322000 * v_cantidad_personas_global), v_cantidad_personas_global, 'No disponible', 0)
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO transportes (id, correo_empleado, lugar_origen, lugar_llegada, capacidad, tiempo_estimado, precio_asiento, empresa, fecha_salida, fecha_llegada) VALUES
    (v_reserva_vuelo_vuelta_id, 'paulie@viajes.cl', 'Palermo', 'Santiago', 200, '20h', 322000, 'AeroPeor', '2025-08-06 03:00:00', '2025-08-06 23:00:00')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO aviones (id, clase, escalas) VALUES
    (v_reserva_vuelo_vuelta_id, 'Clase económica', ARRAY['Casablanca', 'Río'])
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO reservas (id, agenda_id, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_booked) VALUES
    (v_reserva_bus_palermo_corleone_id, v_agenda_id, v_fecha_reserva_global, (21000 * v_cantidad_personas_global), v_cantidad_personas_global, 'No disponible', 0)
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO transportes (id, correo_empleado, lugar_origen, lugar_llegada, capacidad, tiempo_estimado, precio_asiento, empresa, fecha_salida, fecha_llegada) VALUES
    (v_reserva_bus_palermo_corleone_id, 'luca@viajes.cl', 'Palermo', 'Corleone', 15, '2h', 21000, 'Viaja con respeto', '2025-08-02 06:00:00', '2025-08-02 08:00:00')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO buses (id, tipo, comodidades) VALUES
    (v_reserva_bus_palermo_corleone_id, 'Semi-cama', ARRAY['Aire acondicionado','Wi-Fi','Reclinables','Baño','Cargador USB'])
    ON CONFLICT (id) DO NOTHING;
    
    INSERT INTO reservas (id, agenda_id, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_booked) VALUES
    (v_reserva_bus_corleone_playa_id, v_agenda_id, v_fecha_reserva_global, (27000 * v_cantidad_personas_global), v_cantidad_personas_global, 'No disponible', 0)
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO transportes (id, correo_empleado, lugar_origen, lugar_llegada, capacidad, tiempo_estimado, precio_asiento, empresa, fecha_salida, fecha_llegada) VALUES
    (v_reserva_bus_corleone_playa_id, 'luca@viajes.cl', 'Corleone', 'Palermo', 15, '2h', 27000, 'Viaja con respeto', '2025-08-05 22:00:00', '2025-08-06 00:00:00')
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO buses (id, tipo, comodidades) VALUES
    (v_reserva_bus_corleone_playa_id, 'Semi-cama', ARRAY['Aire acondicionado','Wi-Fi','Reclinables','Baño','Cargador USB'])
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO reservas (id, agenda_id, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_booked) VALUES
    (v_reserva_panorama_cata_id, v_agenda_id, v_fecha_reserva_global, (30000 * v_cantidad_personas_global), v_cantidad_personas_global, 'No disponible', 0)
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO panoramas (id, nombre, empresa, descripcion, ubicacion, duracion, precio_persona, capacidad, restricciones, fecha_panorama) VALUES
    (v_reserva_panorama_cata_id, 'Vino de Mesa Italiano', 'WineCo', 'Cata de vinos', 'Corleone', 2, 30000, 20, ARRAY['18+'], '2025-08-02 17:00:00')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO reservas (id, agenda_id, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_booked) VALUES
    (v_reserva_panorama_cena_id, v_agenda_id, v_fecha_reserva_global, (25000 * v_cantidad_personas_global), v_cantidad_personas_global, 'No disponible', 0)
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO panoramas (id, nombre, empresa, descripcion, ubicacion, duracion, precio_persona, capacidad, restricciones, fecha_panorama) VALUES
    (v_reserva_panorama_cena_id, 'El príncipe di Corleone', 'Ristorante', 'Cena tradicional', 'Corleone', 2, 25000, 20, ARRAY['No fumar'], '2025-08-03 20:00:00')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO reservas (id, agenda_id, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_booked) VALUES
    (v_reserva_panorama_godfather_id, v_agenda_id, v_fecha_reserva_global, (12000 * v_cantidad_personas_global), v_cantidad_personas_global, 'No disponible', 0)
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO panoramas (id, nombre, empresa, descripcion, ubicacion, duracion, precio_persona, capacidad, restricciones, fecha_panorama) VALUES
    (v_reserva_panorama_godfather_id, 'The Godfather''s House', 'Cultura', 'Tour casa Don Corleone', 'Via Candelora, 25, Corleone', 1.5, 12000, 20, ARRAY[]::TEXT[], '2025-08-04 10:00:00')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO reservas (id, agenda_id, fecha, monto, cantidad_personas, estado_disponibilidad, puntos_booked) VALUES
    (v_reserva_panorama_cidma_id, v_agenda_id, v_fecha_reserva_global, (10000 * v_cantidad_personas_global), v_cantidad_personas_global, 'No disponible', 0)
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO panoramas (id, nombre, empresa, descripcion, ubicacion, duracion, precio_persona, capacidad, restricciones, fecha_panorama) VALUES
    (v_reserva_panorama_cidma_id, 'Movimiento Antimafia CIDMA', 'CIDMA', 'Museo antimafia', 'Corleone', 2, 10000, 20, ARRAY[]::TEXT[], '2025-08-05 11:00:00')
    ON CONFLICT (id) DO NOTHING;



    FOR v_iter_panorama_id IN 
        SELECT id FROM panoramas WHERE id IN (
            v_reserva_panorama_cata_id, v_reserva_panorama_cena_id, 
            v_reserva_panorama_godfather_id, v_reserva_panorama_cidma_id)
    LOOP
        INSERT INTO participantes (id, id_panorama, nombre, edad) VALUES
        (1, v_iter_panorama_id, 'Cata Bienestar', 23),
        (2, v_iter_panorama_id, 'Jorge Bienestar', 22),
        (3, v_iter_panorama_id, 'Lucas Viajero', 23),
        (4, v_iter_panorama_id, 'Martina Tattaglia', 22),
        (5, v_iter_panorama_id, 'Tomás Barzini', 22),
        (6, v_iter_panorama_id, 'Vincenzo Martino', 22),
        (7, v_iter_panorama_id, 'Agustino Beckerini', 23),
        (8, v_iter_panorama_id, 'Consuelo Inostrozini', 22),
        (9, v_iter_panorama_id, 'Ignacio Garridelli', 23),
        (10, v_iter_panorama_id, 'Olivia Llanini', 22),
        (11, v_iter_panorama_id, 'Paula Contessa', 23),
        (12, v_iter_panorama_id, 'Sofia Retamalini', 23)
        ON CONFLICT (id, id_panorama, nombre) DO NOTHING;
    END LOOP;
END $$;

COMMIT;