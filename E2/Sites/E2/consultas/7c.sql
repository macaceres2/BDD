BEGIN;

UPDATE transportes
SET correo_empleado = 'luca@viajes.cl'
WHERE id IN (200002, 200003)
  AND empresa = 'AeroPeor';

DELETE FROM empleados
WHERE correo = 'paulie@viajes.cl';

COMMIT;