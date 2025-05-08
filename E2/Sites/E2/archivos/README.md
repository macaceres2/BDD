# Entrega 0 - Bases de datos IIC2413

**Nombre:** Manuel Antonio Cáceres Morales
**Número de Alumno:** 19205597
### Credenciales de acceso
**Usuario Uc** macaceres2@bdd1.ing.puc.cl
**Contraseña** 19205597


## Contenido del Informe

### 1. Análisis de los datos entregados en los archivos
Estos se encuentran en la carpeta CSV_sucios

- Archivo `usuarios_rescatados.csv`
Contiene datos personales de los usuarios, las cuales son: `nombre`, `run`, `dv`, `correo`, `nombre_usuario`, `contrasena`, `telefono_contacto`, `puntos`, `codigo_agenda`, `etiqueta`, `codigo_reserva`, `fecha`, `monto`, `cantidad_personas`

Son los archivos entregados desde el enunciado, los cuales son:
- Archivo `empleados_rescatados.csv`
Contiene datos de los empleados, con información personal e información laboral, las cuales son: `nombre`, `run`, `dv`, `correo`, `nombre_usuario`, `contrasena`, `telefono_contacto`, `jornada`, `isapre`, `contrato`, `codigo_reserva`, `codigo_agenda`, `fecha`, `monto`, `cantidad_personas`, `estado_disponibilidad`, `numero_viaje`, `lugar_origen`, `lugar_llegada`, `fecha_salida`, `fecha_llegada`, `capacidad`, `tiempo_estimado`, `precio_asiento`, `empresa`, `tipo_de_bus`, `comodidades`, `escalas`, `clase`, `paradas`

### 2. Tipos de errores de datos detectados por el programa y forma de solución utilizada
Aquí se deben describir los errores de datos encontrados y cómo se solucionaron. Por ejemplo:

Archivo `usuarios_rescatados.csv`:
- Correo inválido: Correos sin `@` o con doble `@@`.
    - Solución: Se descartan estos usuarios y fueron enviados a `datos_descartados.csv`.
- RUN inválido: RUN con valores no numericos o RUN vacío.
    - Solución: Se descartan los RUN no válidos

Archivo `empleados_rescatados.csv`:
- id_transaccion nulo: Ya que un registro debe tener su identificador, se debe eliminar el registro.
    - Solución: Se eliminó el registro de la tabla y se envió a la tabla `transacciones_erroneas.csv`.

- 
    - Solución: 


Archivo `agendasOK.csv`:
- Correos asociados a agendas incorrectas: Existían correos los cuales debían asociarse a agendas inexistentes o incorrectas.
    - Solución: Se descartan y se envían a `datos_descartados.csv`

Archivo `reservasOK.csv`:
- Problema en fechas: Existían distintos formatos en las fechas indicadas
    - Solución: Se normaliza al formato YYYY-MM-DD. Se utiliza este formato por comodidad de archivos sucios.
- Montos negativos: Existían montos en las reservas negativos.
    - Solución: Se descartan y se envían a `datos_descartados.csv`


### 3. Nombre de los archivos de salida y explicación de su contenido

Carpeta archivos
- Archivo `funciones.php` tiene todas las funciones necesarias para ejecutar el programa correctamente, las cuales son `Cargar`, `Encabezado`, `Validar`, `Limpiar`, `NormalizarFecha`, `ManejoDatos`, `GuardarCSV` y `GuardarDatosDescartados`
- Archivo `main.php` es donde se corre el programa. Contiene todas las solicitudes de guardar los CSV creados en la carpeta correspondiente.

Carpeta CSV_limpios
- Archivo `agendasOK.csv` tiene la siguiente forma: `correo_usuario`, `codigo_agenda`, `etiqueta`, `fecha_creacion`
- Archivo `avionesOK.csv` tiene la siguiente forma: `correo_empleado`, `codigo_reserva`, `numero_viaje`, `lugar_origen`, `lugar_llegada`, `capacidad`, `tiempo_estimado`, `precio_asiento`, `empresa`, `escalas`, `clase`
- Archivo `busesOK.csv` tiene la siguiente forma: `correo_empleado`, `codigo_reserva`, `numero_viaje`, `lugar_origen`, `lugar_llegada`, `capacidad`, `tiempo_estimado`, `precio_asiento`, `empresa`, `tipo`, `comodidades`
- Archivo `empleadosOK.csv` tiene la siguiente forma: `nombre`, `run`, `dv`, `correo`, `nombre_usuario`, `contrasena`, `telefono_contacto`, `jornada`, `isapre`, `contrato`
- Archivo `personasOK.csv` tiene la siguiente forma: `nombre`, `run`, `dv`, `correo`, `nombre_usuario`, `contrasena`, `telefono_contacto`
- Archivo `reservasOK.csv` tiene la siguiente forma: `codigo_agenda`, `codigo_reserva`, `fecha`, `monto`, `cantidad_personas`
- Archivo `transportesOK.csv` tiene la siguiente forma: `correo_empleado`, `codigo_reserva`, `numero_viaje`, `lugar_origen`, `lugar_llegada`, `capacidad`, `tiempo_estimado`, `precio_asiento`, `empresa`
- Archivo `trenesOK.csv` tiene la siguiente forma: `correo_empleado`, `codigo_reserva`, `numero_viaje`, `lugar_origen`, `lugar_llegada`, `capacidad`, `tiempo_estimado`, `precio_asiento`, `empresa`, `comodidades`, `paradas`
- Archivo `usuariosOK.csv` tiene la siguiente forma: `nombre`, `run`, `dv`, `correo`, `nombre_usuario`, `contrasena`, `telefono_contacto`, `puntos`
- Archivo `datos_descartados.csv` tiene la siguiente forma: `nombre`, `run`, `dv`, `correo`, `nombre_usuario`, `contrasena`, `telefono_contacto`, `puntos`, `codigo_agenda`, `etiqueta`, `codigo_reserva`, `fecha`, `monto`, `cantidad_personas` 

- personasOK: nombre, run y dv no pueden estar vacío
- usuariosOK: nombre, run y dv no pueden estar vacíos 
- empleadosOK: nombre, run y dv, contrato y jornada no pueden estar vacíos 
- agendaOK: nada puede estar vacío 
- reservasOK: codigo_agenda, codigo_reserva y cantidad_personas no pueden estar vacíos 
- transportesOK: codigo_reserva, numero_viaje, lugar_origen y lugar_llegada no pueden estar vacíos 
- busesOK: codigo_reserva, numero_viaje, lugar_origen y lugar_llegada no pueden estar vacíos 
- trenesOK: codigo_reserva, numero_viaje, lugar_origen y lugar_llegada no pueden estar vacíos 
- avionesOK: codigo_reserva, numero_viaje, lugar_origen, lugar_llegada y escalas, no pueden estar vacíos

### 4. Instrucciones para ejecutar el programa
Es fundamental proporcionar instrucciones claras para ejecutar el programa (absolutamente todos los pasos necesarios, como si fueras a ejecutarlo de cero). Por ejemplo:

1. Credenciales para conectar al servidor:
    usuario: macaceres2
    contraseña: 19205597
2. Conexión al servidor mediante ssh:
    ejecutar el comando ssh macaceres2@bdd1.ing.puc.cl
    colocar contraseña 19205597
3. Ejecutar el archivo main.php
    dirigirse a ./Sites/E0/archivos/
    ejecutar el comando: php main.php
    esperar a que termine el proceso
