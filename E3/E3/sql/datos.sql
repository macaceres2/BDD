-- Insertar a las personas si no existen.
INSERT INTO public.persona (correo, nombre, username, run, dv) VALUES
('paulie.p@mafia.com', 'Paulie', 'paulie', 12345678, '9'),
('luca.brasi@mafia.com', 'Luca Brasi', 'lucabrasi', 98765432, '1')
ON CONFLICT (correo) DO NOTHING;

-- Convertirlos en empleados si no lo son.
INSERT INTO public.empleado (correo, jornada, contrato, isapre) VALUES
('paulie.p@mafia.com', 'Completa', 'Indefinido', 'Fonasa'),
('luca.brasi@mafia.com', 'Completa', 'Indefinido', 'Consalud')
ON CONFLICT (correo) DO NOTHING;

-- Asignar a Paulie a un transporte. Asumiremos que el primer transporte insertado por el script PHP tiene id=1.
UPDATE public.transporte SET correo_empleado = 'paulie.p@mafia.com' WHERE id = 1;

BEGIN;

UPDATE public.transporte
SET correo_empleado = 'luca.brasi@mafia.com'
WHERE id = 1 AND correo_empleado = 'paulie.p@mafia.com';

COMMIT;

BEGIN;

-- 1. Desasignar a Paulie de todos los transportes para evitar conflictos.
UPDATE public.transporte
SET correo_empleado = NULL
WHERE correo_empleado = 'paulie.p@mafia.com';

-- 2. Eliminar su registro de la tabla 'empleado'.
DELETE FROM public.empleado
WHERE correo = 'paulie.p@mafia.com';

-- 3. Eliminar su registro de la tabla 'usuario' (en caso de que también fuera un usuario).
DELETE FROM public.usuario
WHERE correo = 'paulie.p@mafia.com';

-- 4. Finalmente, eliminar su registro de la tabla 'persona', la tabla base.
DELETE FROM public.persona
WHERE correo = 'paulie.p@mafia.com';

COMMIT;