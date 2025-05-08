-- crear_tablas.sql
-- Script para crear las tablas del esquema de la base de datos Booked.com

-- Eliminar tablas si existen para evitar errores
DROP TABLE IF EXISTS habitaciones CASCADE;
DROP TABLE IF EXISTS hoteles CASCADE;
DROP TABLE IF EXISTS airbnb CASCADE;
DROP TABLE IF EXISTS hospedajes CASCADE;
DROP TABLE IF EXISTS participantes CASCADE;
DROP TABLE IF EXISTS panoramas CASCADE;
DROP TABLE IF EXISTS aviones CASCADE;
DROP TABLE IF EXISTS trenes CASCADE;
DROP TABLE IF EXISTS buses CASCADE;
DROP TABLE IF EXISTS transportes CASCADE;
DROP TABLE IF EXISTS seguros CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS reservas CASCADE;
DROP TABLE IF EXISTS agendas CASCADE;
DROP TABLE IF EXISTS empleados CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS personas CASCADE;

-- Creación de tipos de datos personalizados
CREATE TYPE tipo_jornada AS ENUM ('diurna', 'nocturna');
CREATE TYPE tipo_contrato AS ENUM ('full time', 'part time');
CREATE TYPE tipo_isapre AS ENUM ('Más vida', 'Colmena', 'Consalud', 'Banmédica', 'Fonasa');
CREATE TYPE estado_disponibilidad AS ENUM ('Disponible', 'No disponible');
CREATE TYPE tipo_habitacion AS ENUM ('Sencilla', 'Doble', 'Matrimonial', 'Triple', 'Cuádruple', 'Suite');
CREATE TYPE tipo_bus AS ENUM ('cama', 'normal', 'semi-cama');

-- Creación de tablas según el modelo E/R

-- Tabla Personas
CREATE TABLE personas (
    correo VARCHAR(255) PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    run INT NOT NULL,
    dv CHAR(1) NOT NULL CHECK (dv ~ '^[0-9Kk]$'),
    nombre_usuario VARCHAR(255) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    telefono_contacto VARCHAR(20) NOT NULL,
    UNIQUE(run, dv)
);

-- Tabla Usuarios
CREATE TABLE usuarios (
    correo VARCHAR(255) PRIMARY KEY,
    puntos INT DEFAULT 0 CHECK (puntos >= 0),
    FOREIGN KEY (correo) REFERENCES personas(correo) ON DELETE CASCADE
);

-- Tabla Empleados
CREATE TABLE empleados (
    correo VARCHAR(255) PRIMARY KEY,
    jornada tipo_jornada NOT NULL,
    contrato tipo_contrato NOT NULL,
    isapre tipo_isapre NOT NULL,
    FOREIGN KEY (correo) REFERENCES personas(correo) ON DELETE CASCADE
);

-- Tabla Agendas
CREATE TABLE agendas (
    codigo_agenda SERIAL PRIMARY KEY,
    correo_usuario VARCHAR(255) NOT NULL,
    etiqueta VARCHAR(255) NOT NULL,
    fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (correo_usuario) REFERENCES usuarios(correo) ON DELETE CASCADE
);

-- Tabla Reservas
CREATE TABLE reservas (
    codigo_reserva SERIAL PRIMARY KEY,
    codigo_agenda INT,
    fecha DATE NOT NULL,
    monto DECIMAL(10, 2) CHECK (monto > 0),
    cantidad_personas INT NOT NULL CHECK (cantidad_personas > 0),
    estado_disponibilidad estado_disponibilidad NOT NULL DEFAULT 'Disponible',
    puntos_obtenidos INT NOT NULL CHECK (puntos_obtenidos > 0),
    FOREIGN KEY (codigo_agenda) REFERENCES agendas(codigo_agenda) ON DELETE SET NULL,
    CONSTRAINT una_agenda_max CHECK (
        (codigo_agenda IS NULL AND estado_disponibilidad = 'Disponible') OR
        (codigo_agenda IS NOT NULL AND estado_disponibilidad = 'No disponible')
    )
);

-- Tabla Reviews
CREATE TABLE reviews (
    codigo_review SERIAL PRIMARY KEY,
    codigo_reserva INT NOT NULL,
    estrellas INT NOT NULL CHECK (estrellas BETWEEN 1 AND 5),
    comentario TEXT,
    fecha_review DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (codigo_reserva) REFERENCES reservas(codigo_reserva) ON DELETE CASCADE,
    UNIQUE(codigo_reserva)
);

-- Tabla Seguros
CREATE TABLE seguros (
    codigo_seguro SERIAL PRIMARY KEY,
    codigo_reserva INT NOT NULL,
    tipo VARCHAR(255) NOT NULL,
    valor DECIMAL(10, 2) NOT NULL CHECK (valor > 0),
    clausula TEXT NOT NULL,
    empresa VARCHAR(255) NOT NULL,
    FOREIGN KEY (codigo_reserva) REFERENCES reservas(codigo_reserva) ON DELETE CASCADE
);

-- Tabla Transportes
CREATE TABLE transportes (
    codigo_reserva INT PRIMARY KEY,
    correo_empleado VARCHAR(255) NOT NULL,
    numero_viaje INT NOT NULL,
    lugar_origen VARCHAR(255) NOT NULL,
    lugar_llegada VARCHAR(255) NOT NULL,
    capacidad INT,
    tiempo_estimado VARCHAR(50),
    precio_asiento DECIMAL(10, 2) NOT NULL CHECK (precio_asiento > 0),
    empresa VARCHAR(255) NOT NULL,
    fecha_salida TIMESTAMP NOT NULL,
    fecha_llegada TIMESTAMP NOT NULL,
    FOREIGN KEY (codigo_reserva) REFERENCES reservas(codigo_reserva) ON DELETE CASCADE,
    FOREIGN KEY (correo_empleado) REFERENCES empleados(correo) ON DELETE RESTRICT
);

-- Tabla Buses
CREATE TABLE buses (
    codigo_reserva INT PRIMARY KEY,
    tipo tipo_bus NOT NULL,
    comodidades TEXT[], -- Usando un array para almacenar múltiples comodidades
    FOREIGN KEY (codigo_reserva) REFERENCES transportes(codigo_reserva) ON DELETE CASCADE
);

-- Tabla Trenes
CREATE TABLE trenes (
    codigo_reserva INT PRIMARY KEY,
    comodidades TEXT[], -- Usando un array para almacenar múltiples comodidades
    paradas TEXT[], -- Usando un array para almacenar múltiples paradas
    FOREIGN KEY (codigo_reserva) REFERENCES transportes(codigo_reserva) ON DELETE CASCADE
);

-- Tabla Aviones
CREATE TABLE aviones (
    codigo_reserva INT PRIMARY KEY,
    clase VARCHAR(50) NOT NULL,
    escalas TEXT[], -- Usando un array para almacenar múltiples escalas
    FOREIGN KEY (codigo_reserva) REFERENCES transportes(codigo_reserva) ON DELETE CASCADE
);

-- Tabla Panoramas
CREATE TABLE panoramas (
    codigo_reserva INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    empresa VARCHAR(255) NOT NULL,
    descripcion TEXT,
    ubicacion VARCHAR(255) NOT NULL,
    duracion_horas DECIMAL(5, 2) NOT NULL,
    precio_persona DECIMAL(10, 2) NOT NULL CHECK (precio_persona > 0),
    capacidad_maxima INT NOT NULL,
    restricciones TEXT[],
    fecha_panorama TIMESTAMP NOT NULL,
    FOREIGN KEY (codigo_reserva) REFERENCES reservas(codigo_reserva) ON DELETE CASCADE
);

-- Tabla Participantes
CREATE TABLE participantes (
    id_participante SERIAL PRIMARY KEY,
    codigo_reserva INT NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    edad INT NOT NULL CHECK (edad > 0),
    FOREIGN KEY (codigo_reserva) REFERENCES panoramas(codigo_reserva) ON DELETE CASCADE
);

-- Tabla Hospedajes
CREATE TABLE hospedajes (
    codigo_reserva INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    ubicacion VARCHAR(255) NOT NULL,
    precio_noche DECIMAL(10, 2) NOT NULL CHECK (precio_noche > 0),
    estrellas INT NOT NULL CHECK (estrellas BETWEEN 1 AND 5),
    comodidades TEXT[],
    fecha_checkin DATE NOT NULL,
    fecha_checkout DATE NOT NULL,
    FOREIGN KEY (codigo_reserva) REFERENCES reservas(codigo_reserva) ON DELETE CASCADE,
    CONSTRAINT fechas_coherentes CHECK (fecha_checkout > fecha_checkin)
);

-- Tabla Hoteles
CREATE TABLE hoteles (
    codigo_reserva INT PRIMARY KEY,
    politicas TEXT[],
    FOREIGN KEY (codigo_reserva) REFERENCES hospedajes(codigo_reserva) ON DELETE CASCADE
);

-- Tabla Habitaciones
CREATE TABLE habitaciones (
    id_habitacion SERIAL PRIMARY KEY,
    codigo_reserva INT NOT NULL,
    numero INT NOT NULL,
    tipo tipo_habitacion NOT NULL,
    FOREIGN KEY (codigo_reserva) REFERENCES hoteles(codigo_reserva) ON DELETE CASCADE,
    UNIQUE(codigo_reserva, numero)
);

-- Tabla Airbnb
CREATE TABLE airbnb (
    codigo_reserva INT PRIMARY KEY,
    nombre_anfitrion VARCHAR(255) NOT NULL,
    contacto_anfitrion VARCHAR(50) NOT NULL,
    descripcion TEXT NOT NULL,
    cant_piezas INT NOT NULL CHECK (cant_piezas > 0),
    cant_camas INT NOT NULL CHECK (cant_camas > 0),
    cant_banos INT NOT NULL CHECK (cant_banos > 0),
    FOREIGN KEY (codigo_reserva) REFERENCES hospedajes(codigo_reserva) ON DELETE CASCADE
);