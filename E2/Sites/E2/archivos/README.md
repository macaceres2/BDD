# Entrega 2 - Bases de datos IIC2413

**Nombre:** Manuel Antonio Cáceres Morales
**Número de Alumno:** 19205597
### Credenciales de acceso
**Usuario Uc** macaceres2@bdd1.ing.puc.cl
**Contraseña** 19205597


## Contenido del Informe
### Restricciones de Llaves Primarias y Foráneas
¡Hola Manuel! Has hecho un gran trabajo con tu README.md. Está bien estructurado y la sección de restricciones es bastante detallada. Basándome en tus archivos crear_tablas.sql y poblar_tablas.sql, y el enunciado del proyecto, he hecho algunas revisiones y sugerencias para que sea aún más preciso y completo.

Aquí tienes una propuesta para tu README.md final:

Markdown

# Entrega 2 - Bases de datos IIC2413

**Nombre:** Manuel Antonio Cáceres Morales
**Número de Alumno:** 19205597

## Credenciales de Acceso al Servidor del Curso y Base de Datos

* **Servidor SSH:** `bdd1.ing.puc.cl`
* **Usuario SSH:** `macaceres2`
* **Contraseña SSH:** (Tu contraseña UC)
* **Nombre de la Base de Datos PostgreSQL:** `mi_proyecto_bdd` (según tus comandos) o `macaceres2` (si ese es el nombre por defecto en el servidor del curso)
* **Usuario PostgreSQL:** `macaceres2` (o `postgres` si así lo estás usando localmente y para la corrección, como en tus ejemplos de `psql`)
* **Contraseña PostgreSQL:** (Tu contraseña UC o la contraseña del usuario `postgres` si aplica)

*(Nota para el corrector: Por favor, confirmar el nombre de la base de datos y el usuario a utilizar para la corrección. El estudiante ha usado `mi_proyecto_bdd` como nombre de BDD y `postgres` o `macaceres2` como usuario en los ejemplos.)*

## Contenido del Informe

Este proyecto implementa un esquema de base de datos para una plataforma similar a "Booked.com", carga datos desde archivos CSV proporcionados y ejecuta consultas SQL para extraer información relevante, de acuerdo con los requisitos de la Etapa 2 del proyecto semestral IIC2413.

### Restricciones Implementadas

Las siguientes restricciones de integridad han sido definidas en el archivo `archivos/crear_tablas.sql` para asegurar la validez y consistencia de los datos.

**1. Llaves Primarias (PK):**
    * `personas.correo`: Identificador único para cada persona.
    * `usuarios.correo`: PK, identifica unívocamente a los usuarios.
    * `empleados.correo`: PK, identifica unívocamente a los empleados.
    * `agendas.id`: PK, identifica cada agenda.
    * `reservas.id`: PK, identifica cada reserva.
    * `reviews.id`: PK (SERIAL), autoincremental para cada reseña.
    * `seguros.id`: PK (SERIAL), autoincremental para cada seguro.
    * `transportes.id`, `hospedajes.id`, `panoramas.id`: PKs que también son FKs a `reservas.id`, especializando una reserva.
    * `buses.id`, `trenes.id`, `aviones.id`: PKs que también son FKs a `transportes.id`.
    * `hoteles.id`, `airbnb.id`: PKs que también son FKs a `hospedajes.id`.
    * `habitaciones.id`: PK (SERIAL), autoincremental para cada habitación.
    * `participantes.id, participantes.id_panorama, participantes.nombre`: Llave primaria compuesta.

**2. Llaves Foráneas (FK) y Políticas de Integridad Referencial:**
    * `usuarios.correo` -> `personas.correo` (ON DELETE CASCADE): Si se elimina una persona, se elimina su rol de usuario.
    * `empleados.correo` -> `personas.correo` (ON DELETE CASCADE): Si se elimina una persona, se elimina su rol de empleado.
    * `agendas.correo_usuario` -> `usuarios.correo` (ON DELETE CASCADE): Si se elimina un usuario, se eliminan sus agendas.
    * `reservas.agenda_id` -> `agendas.id` (ON DELETE SET NULL): Si se elimina una agenda, las reservas asociadas no se eliminan, sino que su `agenda_id` se establece a `NULL`, permitiendo que la reserva exista como "disponible" o para mantener un historial.
    * `reviews.reserva_id` -> `reservas.id` (ON DELETE CASCADE): Si se elimina una reserva, se eliminan sus reseñas.
    * `seguros.reserva_id` -> `reservas.id` (ON DELETE CASCADE): Si se elimina una reserva, se eliminan sus seguros.
    * `transportes.id` -> `reservas.id` (ON DELETE CASCADE): Un transporte es un tipo de reserva; si la reserva base se elimina, el transporte también.
    * `transportes.correo_empleado` -> `empleados.correo` (ON DELETE RESTRICT): Impide eliminar un empleado si está asignado como conductor a un transporte. Se debe reasignar o eliminar el transporte primero.
    * `panoramas.id` -> `reservas.id` (ON DELETE CASCADE).
    * `participantes.id_panorama` -> `panoramas.id` (ON DELETE CASCADE).
    * `hospedajes.id` -> `reservas.id` (ON DELETE CASCADE).
    * `hoteles.id` -> `hospedajes.id` (ON DELETE CASCADE).
    * `airbnb.id` -> `hospedajes.id` (ON DELETE CASCADE).
    * `habitaciones.hotel_id` -> `hoteles.id` (ON DELETE CASCADE).

**3. Restricciones de Unicidad (UNIQUE):**
    * `personas.username`: Los nombres de usuario deben ser únicos.
    * `personas(run, dv)`: La combinación de RUN y DV debe ser única.
    * `habitaciones(hotel_id, numero_habitacion)`: El número de habitación debe ser único dentro de un mismo hotel.

**4. Restricciones de No Nulidad (NOT NULL):**
    * Se han aplicado a campos esenciales para garantizar la completitud de los datos, por ejemplo:
        * `personas`: `nombre`, `run`, `dv`, `username`, `contrasena`, `telefono_contacto`.
        * `reservas`: `fecha`, `cantidad_personas`, `estado_disponibilidad`, `puntos_booked`.
        * `agendas`: `correo_usuario`, `etiqueta`.
        * Muchos otros campos específicos por tabla según el modelo y la lógica de negocio.

**5. Restricciones de Dominio:**
    * **Valores Numéricos:**
        * `usuarios.puntos >= 0`.
        * `reservas.monto > 0`.
        * `reservas.cantidad_personas > 0`.
        * `transportes.precio_asiento > 0`.
        * `participantes.edad >= 0`.
        * Nota: `reservas.puntos_booked` es `NOT NULL` pero no tiene `CHECK (>0)` en `crear_tablas.sql`, permitiendo `0`.
        * Nota: `seguros.valor` es `NOT NULL` pero no tiene `CHECK (>0)` explícito en `crear_tablas.sql` (aunque se valida en `poblar_tablas.sql`).
    * **Coherencia de Fechas:**
        * `hospedajes.fecha_checkout > hospedajes.fecha_checkin`.
        * En `transportes`, `fecha_llegada > fecha_salida` se valida durante la inserción en `poblar_tablas.sql`.
    * **Formatos y Rangos Específicos:**
        * `personas.dv ~ '^[0-9Kk]$'`: DV del RUT es un número o 'K' (mayúscula o minúscula).
        * En `reviews`, `estrellas` se valida como `~ '^[1-5]$'` durante la inserción en `poblar_tablas.sql`. (La tabla `reviews` en `crear_tablas.sql` tiene `estrellas INT NOT NULL` sin un `CHECK` explícito de rango).
        * En `hospedajes`, `estrellas INT NOT NULL` sin `CHECK` de rango en `crear_tablas.sql`, pero validado como `~ '^[0-7]$'` en `poblar_tablas.sql`.

**Justificación General de las Restricciones:**
Las llaves primarias y `UNIQUE` aseguran la identificación única y evitan duplicados. Las llaves foráneas mantienen la integridad referencial, y las políticas `ON DELETE` manejan la propagación de eliminaciones según las reglas de negocio. `NOT NULL` garantiza datos esenciales. `CHECK` y validaciones en la carga de datos (`poblar_tablas.sql`) imponen reglas de negocio sobre los valores permitidos, manteniendo la calidad de los datos.

## Instrucciones de Ejecución

### Prerrequisitos
* Acceso al servidor `bdd1.ing.puc.cl` mediante SSH.
* Cliente `psql` para interactuar con la base de datos PostgreSQL.
* Los archivos CSV (`personas.csv`, `agenda_reserva.csv`, etc.) deben estar ubicados en la ruta especificada dentro del script `poblar_tablas.sql`



### Estructura de Archivos

La estructura de directorios y archivos para la entrega debe ser la siguiente dentro de `Sites/E2/`:
.
├── archivos/
│   ├── crear_tablas.sql
│   ├── poblar_tablas.sql
│   └── README.md
├── consultas/
│   ├── 1a.sql
│   ├── 2a.sql
│   ├── 2b.sql
│   ├── 3a.sql
│   ├── 3b.sql
│   ├── 4a.sql
│   ├── 5a.sql
│   ├── 6a.sql
│   ├── 7a.sql
│   ├── 7b.sql
│   ├── 7c.sql
│   └── 7d.sql
├── csv/
│   ├── agenda_reserva.csv
│   ├── habitaciones.csv
│   ├── participantes.csv
│   ├── personas.csv
│   └── review_seguro.csv
└── descartados/
    └── (Archivos .csv para datos descartados, ej. personas_descartados.csv, etc.)




### 6. Instrucciones para ejecutar el programa
Es fundamental proporcionar instrucciones claras para ejecutar el programa (absolutamente todos los pasos necesarios, como si fueras a ejecutarlo de cero). Por ejemplo:

1. Credenciales para conectar al servidor:
    usuario: macaceres2
    contraseña: 19205597
2. Conexión al servidor mediante ssh:
    ejecutar el comando ssh macaceres2@bdd1.ing.puc.cl
    colocar contraseña 19205597
3.  Crear BDD
    dirigirse a ./Sites/E2/archivos/
    ejecutar el comando: createdb mi_proyecto_bdd
    esperar a que termine el proceso
4. Ejecutar script para crear tablas
    Este script (`crear_tablas.sql`) eliminará las tablas existentes (si las hay) y las creará con el esquema definido.
    ```bash
    psql -U macaceres2 -d mi_proyecto_bdd -f archivos/crear_tablas.sql
    ```
5. Ejecutar script de poblar tablas
    Este script (`poblar_tablas.sql`) cargará los datos desde los archivos CSV a las tablas recién creadas.
    ```bash
    psql -U macaceres2 -d mi_proyecto_bdd -f archivos/poblar_tablas.sql
    ```
6.  Ejecutar consultas SQL
    Las consultas deben ejecutarse individualmente.
    ```bash
    psql -U macaceres2 -d mi_proyecto_bdd -f consultas/1a.sql
    ```
    Repita este comando para cada archivo de consulta que desee ejecutar (ej. `1a.sql`, `2b.sql`, etc.).
