-- =================================================================
-- LÓGICA DE PUNTOS (SP1 + TRIGGER2)
-- =================================================================
CREATE OR REPLACE FUNCTION sp1_calcular_puntos_booked()
RETURNS TRIGGER AS $$
DECLARE
    v_correo_organizador TEXT;
    v_puntos_a_sumar INT;
BEGIN
    -- Calcular los puntos para el monto de la reserva recién insertada
    v_puntos_a_sumar := FLOOR(NEW.monto / 1000);

    -- Si no se generan puntos, terminar
    IF v_puntos_a_sumar <= 0 THEN
        RETURN NEW;
    END IF;

    -- Encontrar el correo del organizador de la agenda asociada a la reserva
    SELECT correo_usuario INTO v_correo_organizador
    FROM public.agenda
    WHERE id = NEW.agenda_id;

    -- Si se encontró un organizador, actualizar sus puntos
    IF v_correo_organizador IS NOT NULL THEN
        UPDATE public.usuario
        SET puntos = puntos + v_puntos_a_sumar
        WHERE correo = v_correo_organizador;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar el trigger si ya existe para evitar errores
DROP TRIGGER IF EXISTS trigger2_despues_de_reserva ON public.reserva;

-- Crear el trigger que ejecuta el SP1 después de cada inserción en 'reserva'
CREATE TRIGGER trigger2_despues_de_reserva
AFTER INSERT ON public.reserva
FOR EACH ROW
EXECUTE FUNCTION sp1_calcular_puntos_booked();