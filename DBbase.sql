-- ============================================================
-- HOTEL DB - Creación de tablas en MySQL
-- ============================================================

CREATE TABLE TIPO_HABITACION (
    id_tipo INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(200),
    precio_noche DECIMAL(10,2) NOT NULL
);

CREATE TABLE HABITACION (
    id_habitacion INT AUTO_INCREMENT PRIMARY KEY,
    numero_habitacion INT NOT NULL UNIQUE,
    id_tipo INT NOT NULL,
    estado ENUM('DISPONIBLE','OCUPADA','MANTENIMIENTO') DEFAULT 'DISPONIBLE',
    piso INT NOT NULL,

    CONSTRAINT fk_hab_tipo
        FOREIGN KEY (id_tipo)
        REFERENCES TIPO_HABITACION(id_tipo)
);

CREATE TABLE HUESPED (
    id_huesped INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    dni VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(150),
    telefono VARCHAR(20),
    fecha_registro DATE DEFAULT (CURRENT_DATE)
);

CREATE TABLE EMPLEADO (
    id_empleado INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    cargo VARCHAR(80) NOT NULL,
    email VARCHAR(150),
    salario DECIMAL(10,2)
);

CREATE TABLE RESERVA (
    id_reserva INT AUTO_INCREMENT PRIMARY KEY,
    id_huesped INT NOT NULL,
    id_habitacion INT NOT NULL,
    id_empleado INT,

    fecha_entrada DATE NOT NULL,
    fecha_salida DATE NOT NULL,

    estado ENUM('PENDIENTE','ACTIVA','COMPLETADA','CANCELADA')
        DEFAULT 'PENDIENTE',

    fecha_reserva DATE DEFAULT (CURRENT_DATE),

    CONSTRAINT fk_res_huesped
        FOREIGN KEY (id_huesped)
        REFERENCES HUESPED(id_huesped),

    CONSTRAINT fk_res_hab
        FOREIGN KEY (id_habitacion)
        REFERENCES HABITACION(id_habitacion),

    CONSTRAINT fk_res_emp
        FOREIGN KEY (id_empleado)
        REFERENCES EMPLEADO(id_empleado),

    CONSTRAINT chk_fechas
        CHECK (fecha_salida > fecha_entrada)
);

CREATE TABLE SERVICIO (
    id_servicio INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(200),
    precio DECIMAL(10,2) NOT NULL
);

CREATE TABLE RESERVA_SERVICIO (
    id_res_serv INT AUTO_INCREMENT PRIMARY KEY,
    id_reserva INT NOT NULL,
    id_servicio INT NOT NULL,

    cantidad INT DEFAULT 1,
    fecha_uso DATE DEFAULT (CURRENT_DATE),

    CONSTRAINT fk_rs_reserva
        FOREIGN KEY (id_reserva)
        REFERENCES RESERVA(id_reserva),

    CONSTRAINT fk_rs_servicio
        FOREIGN KEY (id_servicio)
        REFERENCES SERVICIO(id_servicio)
);

CREATE TABLE PAGO (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_reserva INT NOT NULL UNIQUE,

    fecha_pago DATE DEFAULT (CURRENT_DATE),

    monto_total DECIMAL(12,2) NOT NULL,

    metodo_pago ENUM('EFECTIVO','TARJETA','TRANSFERENCIA'),

    estado ENUM('PENDIENTE','PAGADO','ANULADO')
        DEFAULT 'PENDIENTE',

    CONSTRAINT fk_pago_reserva
        FOREIGN KEY (id_reserva)
        REFERENCES RESERVA(id_reserva)
);
