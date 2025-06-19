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


CREATE TABLE personas (
    correo VARCHAR(255) PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    run INT NOT NULL,
    dv CHAR(1) NOT NULL CHECK (dv ~ '^[0-9Kk]$'),
    username VARCHAR(255) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    telefono_contacto VARCHAR(20) NOT NULL,
    UNIQUE(run, dv)
);

CREATE TABLE usuarios (
    correo VARCHAR(255) PRIMARY KEY,
    puntos INT DEFAULT 0 CHECK (puntos >= 0),
    FOREIGN KEY (correo) REFERENCES personas(correo) ON DELETE CASCADE
);

CREATE TABLE empleados (
    correo VARCHAR(255) PRIMARY KEY,
    jornada VARCHAR(255) NOT NULL,
    contrato VARCHAR(255) NOT NULL,
    isapre VARCHAR(255) NOT NULL,
    FOREIGN KEY (correo) REFERENCES personas(correo) ON DELETE CASCADE
);

CREATE TABLE agendas (
    id INT PRIMARY KEY,
    correo_usuario VARCHAR(255) NOT NULL,
    etiqueta VARCHAR(255) NOT NULL,
    FOREIGN KEY (correo_usuario) REFERENCES usuarios(correo) ON DELETE CASCADE
);

CREATE TABLE reservas (
    id INT PRIMARY KEY,
    agenda_id INT,
    fecha DATE NOT NULL,
    monto INT CHECK (monto > 0),
    cantidad_personas INT NOT NULL CHECK (cantidad_personas > 0),
    estado_disponibilidad VARCHAR(255) NOT NULL,
    puntos_booked INT NOT NULL,
    FOREIGN KEY (agenda_id) REFERENCES agendas(id) ON DELETE SET NULL
);

CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    reserva_id INT NOT NULL,
    estrellas INT NOT NULL,
    descripcion TEXT,
    FOREIGN KEY (reserva_id) REFERENCES reservas(id) ON DELETE CASCADE

);

CREATE TABLE seguros (
    id SERIAL PRIMARY KEY,
    reserva_id INT NOT NULL,
    tipo VARCHAR(255) NOT NULL,
    valor INT NOT NULL,
    clausula TEXT NOT NULL,
    empresa VARCHAR(255) NOT NULL,
    correo_usuario VARCHAR(255) NOT NULL,
    FOREIGN KEY (reserva_id) REFERENCES reservas(id) ON DELETE CASCADE
);

CREATE TABLE transportes (
    id INT PRIMARY KEY,
    correo_empleado VARCHAR(255) NOT NULL,
    lugar_origen VARCHAR(255) NOT NULL,
    lugar_llegada VARCHAR(255) NOT NULL,
    capacidad INT,
    tiempo_estimado VARCHAR(50),
    precio_asiento DECIMAL(10, 2) NOT NULL CHECK (precio_asiento > 0),
    empresa VARCHAR(255) NOT NULL,
    fecha_salida TIMESTAMP NOT NULL,
    fecha_llegada TIMESTAMP NOT NULL,
    FOREIGN KEY (id) REFERENCES reservas(id) ON DELETE CASCADE,
    FOREIGN KEY (correo_empleado) REFERENCES empleados(correo) ON DELETE RESTRICT
);

CREATE TABLE buses (
    id INT PRIMARY KEY,
    tipo VARCHAR(255) NOT NULL,
    comodidades TEXT[],
    FOREIGN KEY (id) REFERENCES transportes(id) ON DELETE CASCADE
);

CREATE TABLE trenes (
    id INT PRIMARY KEY,
    comodidades TEXT[],
    paradas TEXT[],
    FOREIGN KEY (id) REFERENCES transportes(id) ON DELETE CASCADE
);

CREATE TABLE aviones (
    id INT PRIMARY KEY,
    clase VARCHAR(50) NOT NULL,
    escalas TEXT[],
    FOREIGN KEY (id) REFERENCES transportes(id) ON DELETE CASCADE
);

CREATE TABLE panoramas (
    id INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    empresa VARCHAR(255) NOT NULL,
    descripcion TEXT,
    ubicacion VARCHAR(255) NOT NULL,
    duracion INT,
    precio_persona INT NOT NULL,
    capacidad INT,
    restricciones TEXT[],
    fecha_panorama TIMESTAMP NOT NULL,
    FOREIGN KEY (id) REFERENCES reservas(id) ON DELETE CASCADE
);


CREATE TABLE participantes (
    id INT NOT NULL,
    id_panorama INT NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    edad INT NOT NULL CHECK (edad >= 0),
    PRIMARY KEY (id, id_panorama, nombre),
    FOREIGN KEY (id_panorama) REFERENCES panoramas(id) ON DELETE CASCADE
);

CREATE TABLE hospedajes (
    id INT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    ubicacion VARCHAR(255) NOT NULL,
    precio_noche INT NOT NULL,
    estrellas INT NOT NULL,
    comodidades TEXT[],
    fecha_checkin DATE NOT NULL,
    fecha_checkout DATE NOT NULL,
    FOREIGN KEY (id) REFERENCES reservas(id) ON DELETE CASCADE,
    CONSTRAINT fechas_coherentes CHECK (fecha_checkout > fecha_checkin)
);

CREATE TABLE hoteles (
    id INT PRIMARY KEY,
    politicas TEXT[],
    FOREIGN KEY (id) REFERENCES hospedajes(id) ON DELETE CASCADE
);

CREATE TABLE habitaciones (
    id SERIAL PRIMARY KEY,
    hotel_id INT NOT NULL,
    numero_habitacion INT NOT NULL,
    tipo VARCHAR(255) NOT NULL,
    FOREIGN KEY (hotel_id) REFERENCES hoteles(id) ON DELETE CASCADE,
    UNIQUE(hotel_id, numero_habitacion)
);

CREATE TABLE airbnb (
    id INT PRIMARY KEY,
    nombre_anfitrion VARCHAR(255) NOT NULL,
    contacto_anfitrion VARCHAR(50) NOT NULL,
    descripcion TEXT NOT NULL,
    piezas INT NOT NULL,
    camas INT NOT NULL,
    banos INT NOT NULL,
    FOREIGN KEY (id) REFERENCES hospedajes(id) ON DELETE CASCADE
);