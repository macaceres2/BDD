BEGIN;

UPDATE personas
SET nombre = 'Sofía Retamalini'
WHERE correo = 'sofia.retamalini@participante.com' AND nombre = 'Sofia Retamalini';

UPDATE participantes
SET nombre = 'Sofía Retamalini'
WHERE id = 20000009 AND nombre = 'Sofia Retamalini';

COMMIT;