-- ============================================================
-- HOTEL DATABASE - DDL COMPLETO
-- Usuario: HOTEL
-- Generado para Oracle Database
-- ============================================================

-- ============================================================
-- TABLAS
-- ============================================================

CREATE TABLE TIPO_HABITACION (
    id_tipo         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR2(50)    NOT NULL,
    descripcion     VARCHAR2(200),
    precio_noche    NUMBER(10,2)    NOT NULL
);

CREATE TABLE HABITACION (
    id_habitacion       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero_habitacion   NUMBER(5)       NOT NULL UNIQUE,
    id_tipo             NUMBER          NOT NULL,
    estado              VARCHAR2(20)    DEFAULT 'DISPONIBLE'
                            CHECK (estado IN ('DISPONIBLE','OCUPADA','MANTENIMIENTO')),
    piso                NUMBER(2)       NOT NULL,
    CONSTRAINT fk_hab_tipo FOREIGN KEY (id_tipo) REFERENCES TIPO_HABITACION(id_tipo)
);

CREATE TABLE HUESPED (
    id_huesped      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR2(100)   NOT NULL,
    apellido        VARCHAR2(100)   NOT NULL,
    dni             VARCHAR2(20)    NOT NULL UNIQUE,
    email           VARCHAR2(150),
    telefono        VARCHAR2(20),
    fecha_registro  DATE            DEFAULT SYSDATE
);

CREATE TABLE EMPLEADO (
    id_empleado     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR2(100)   NOT NULL,
    apellido        VARCHAR2(100)   NOT NULL,
    cargo           VARCHAR2(80)    NOT NULL,
    email           VARCHAR2(150),
    salario         NUMBER(10,2)
);

CREATE TABLE RESERVA (
    id_reserva      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_huesped      NUMBER          NOT NULL,
    id_habitacion   NUMBER          NOT NULL,
    id_empleado     NUMBER,
    fecha_entrada   DATE            NOT NULL,
    fecha_salida    DATE            NOT NULL,
    estado          VARCHAR2(20)    DEFAULT 'PENDIENTE'
                        CHECK (estado IN ('PENDIENTE','ACTIVA','COMPLETADA','CANCELADA')),
    fecha_reserva   DATE            DEFAULT SYSDATE,
    CONSTRAINT fk_res_huesped  FOREIGN KEY (id_huesped)    REFERENCES HUESPED(id_huesped),
    CONSTRAINT fk_res_hab      FOREIGN KEY (id_habitacion) REFERENCES HABITACION(id_habitacion),
    CONSTRAINT fk_res_emp      FOREIGN KEY (id_empleado)   REFERENCES EMPLEADO(id_empleado),
    CONSTRAINT chk_fechas      CHECK (fecha_salida > fecha_entrada)
);

CREATE TABLE SERVICIO (
    id_servicio     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR2(100)   NOT NULL,
    descripcion     VARCHAR2(200),
    precio          NUMBER(10,2)    NOT NULL
);

CREATE TABLE RESERVA_SERVICIO (
    id_res_serv     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_reserva      NUMBER          NOT NULL,
    id_servicio     NUMBER          NOT NULL,
    cantidad        NUMBER(3)       DEFAULT 1,
    fecha_uso       DATE            DEFAULT SYSDATE,
    CONSTRAINT fk_rs_reserva  FOREIGN KEY (id_reserva)  REFERENCES RESERVA(id_reserva),
    CONSTRAINT fk_rs_servicio FOREIGN KEY (id_servicio) REFERENCES SERVICIO(id_servicio)
);

CREATE TABLE PAGO (
    id_pago         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_reserva      NUMBER          NOT NULL UNIQUE,
    fecha_pago      DATE            DEFAULT SYSDATE,
    monto_total     NUMBER(12,2)    NOT NULL,
    metodo_pago     VARCHAR2(30)    CHECK (metodo_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA')),
    estado          VARCHAR2(20)    DEFAULT 'PENDIENTE'
                        CHECK (estado IN ('PENDIENTE','PAGADO','ANULADO')),
    CONSTRAINT fk_pago_reserva FOREIGN KEY (id_reserva) REFERENCES RESERVA(id_reserva)
);

-- ============================================================
-- PAQUETE: PKG_HUESPED
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_huesped AS
    PROCEDURE insertar(p_nombre VARCHAR2, p_apellido VARCHAR2, p_dni VARCHAR2,
                       p_email VARCHAR2, p_telefono VARCHAR2);
    PROCEDURE actualizar(p_id NUMBER, p_nombre VARCHAR2, p_apellido VARCHAR2,
                         p_email VARCHAR2, p_telefono VARCHAR2);
    PROCEDURE eliminar(p_id NUMBER);
    FUNCTION obtener(p_id NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION listar_todos RETURN SYS_REFCURSOR;
END pkg_huesped;
/

CREATE OR REPLACE PACKAGE BODY pkg_huesped AS

    PROCEDURE insertar(p_nombre VARCHAR2, p_apellido VARCHAR2, p_dni VARCHAR2,
                       p_email VARCHAR2, p_telefono VARCHAR2) IS
    BEGIN
        INSERT INTO HUESPED (nombre, apellido, dni, email, telefono)
        VALUES (p_nombre, p_apellido, p_dni, p_email, p_telefono);
        COMMIT;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20010, 'El DNI ya existe: ' || p_dni);
        WHEN OTHERS THEN
            ROLLBACK; RAISE;
    END insertar;

    PROCEDURE actualizar(p_id NUMBER, p_nombre VARCHAR2, p_apellido VARCHAR2,
                         p_email VARCHAR2, p_telefono VARCHAR2) IS
    BEGIN
        UPDATE HUESPED
        SET nombre = p_nombre, apellido = p_apellido,
            email = p_email, telefono = p_telefono
        WHERE id_huesped = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Huesped no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END actualizar;

    PROCEDURE eliminar(p_id NUMBER) IS
    BEGIN
        DELETE FROM HUESPED WHERE id_huesped = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Huesped no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END eliminar;

    FUNCTION obtener(p_id NUMBER) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT id_huesped, nombre, apellido, dni, email, telefono, fecha_registro
            FROM HUESPED WHERE id_huesped = p_id;
        RETURN v_cur;
    END obtener;

    FUNCTION listar_todos RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT id_huesped, nombre, apellido, dni, email, telefono, fecha_registro
            FROM HUESPED ORDER BY apellido, nombre;
        RETURN v_cur;
    END listar_todos;

END pkg_huesped;
/

-- ============================================================
-- PAQUETE: PKG_HABITACION
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_habitacion AS
    PROCEDURE insertar(p_numero NUMBER, p_id_tipo NUMBER, p_piso NUMBER);
    PROCEDURE actualizar_estado(p_id NUMBER, p_estado VARCHAR2);
    PROCEDURE eliminar(p_id NUMBER);
    FUNCTION obtener(p_id NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION listar_todas RETURN SYS_REFCURSOR;
    FUNCTION listar_disponibles RETURN SYS_REFCURSOR;
END pkg_habitacion;
/

CREATE OR REPLACE PACKAGE BODY pkg_habitacion AS

    PROCEDURE insertar(p_numero NUMBER, p_id_tipo NUMBER, p_piso NUMBER) IS
    BEGIN
        INSERT INTO HABITACION (numero_habitacion, id_tipo, piso)
        VALUES (p_numero, p_id_tipo, p_piso);
        COMMIT;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20011, 'Numero de habitacion ya existe: ' || p_numero);
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END insertar;

    PROCEDURE actualizar_estado(p_id NUMBER, p_estado VARCHAR2) IS
    BEGIN
        UPDATE HABITACION SET estado = p_estado WHERE id_habitacion = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Habitacion no encontrada: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END actualizar_estado;

    PROCEDURE eliminar(p_id NUMBER) IS
    BEGIN
        DELETE FROM HABITACION WHERE id_habitacion = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Habitacion no encontrada: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END eliminar;

    FUNCTION obtener(p_id NUMBER) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT h.id_habitacion, h.numero_habitacion, h.piso, h.estado,
                   t.id_tipo, t.nombre AS tipo, t.precio_noche
            FROM HABITACION h
            JOIN TIPO_HABITACION t ON h.id_tipo = t.id_tipo
            WHERE h.id_habitacion = p_id;
        RETURN v_cur;
    END obtener;

    FUNCTION listar_todas RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT h.id_habitacion, h.numero_habitacion, h.piso, h.estado,
                   t.nombre AS tipo, t.precio_noche
            FROM HABITACION h
            JOIN TIPO_HABITACION t ON h.id_tipo = t.id_tipo
            ORDER BY h.numero_habitacion;
        RETURN v_cur;
    END listar_todas;

    FUNCTION listar_disponibles RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT h.id_habitacion, h.numero_habitacion, h.piso,
                   t.nombre AS tipo, t.precio_noche
            FROM HABITACION h
            JOIN TIPO_HABITACION t ON h.id_tipo = t.id_tipo
            WHERE h.estado = 'DISPONIBLE'
            ORDER BY h.numero_habitacion;
        RETURN v_cur;
    END listar_disponibles;

END pkg_habitacion;
/

-- ============================================================
-- PAQUETE: PKG_EMPLEADO
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_empleado AS
    PROCEDURE insertar(p_nombre VARCHAR2, p_apellido VARCHAR2,
                       p_cargo VARCHAR2, p_email VARCHAR2, p_salario NUMBER);
    PROCEDURE actualizar(p_id NUMBER, p_nombre VARCHAR2, p_apellido VARCHAR2,
                         p_cargo VARCHAR2, p_email VARCHAR2, p_salario NUMBER);
    PROCEDURE eliminar(p_id NUMBER);
    FUNCTION obtener(p_id NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION listar RETURN SYS_REFCURSOR;
END pkg_empleado;
/

CREATE OR REPLACE PACKAGE BODY pkg_empleado AS

    PROCEDURE insertar(p_nombre VARCHAR2, p_apellido VARCHAR2,
                       p_cargo VARCHAR2, p_email VARCHAR2, p_salario NUMBER) IS
    BEGIN
        INSERT INTO EMPLEADO (nombre, apellido, cargo, email, salario)
        VALUES (p_nombre, p_apellido, p_cargo, p_email, p_salario);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END insertar;

    PROCEDURE actualizar(p_id NUMBER, p_nombre VARCHAR2, p_apellido VARCHAR2,
                         p_cargo VARCHAR2, p_email VARCHAR2, p_salario NUMBER) IS
    BEGIN
        UPDATE EMPLEADO
        SET nombre = p_nombre, apellido = p_apellido,
            cargo = p_cargo, email = p_email, salario = p_salario
        WHERE id_empleado = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Empleado no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END actualizar;

    PROCEDURE eliminar(p_id NUMBER) IS
    BEGIN
        DELETE FROM EMPLEADO WHERE id_empleado = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Empleado no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END eliminar;

    FUNCTION obtener(p_id NUMBER) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT id_empleado, nombre, apellido, cargo, email, salario
            FROM EMPLEADO WHERE id_empleado = p_id;
        RETURN v_cur;
    END obtener;

    FUNCTION listar RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT id_empleado, nombre, apellido, cargo, email, salario
            FROM EMPLEADO ORDER BY apellido;
        RETURN v_cur;
    END listar;

END pkg_empleado;
/

-- ============================================================
-- PAQUETE: PKG_RESERVA
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_reserva AS
    PROCEDURE crear(p_id_huesped NUMBER, p_id_habitacion NUMBER,
                    p_id_empleado NUMBER, p_entrada DATE, p_salida DATE);
    PROCEDURE cancelar(p_id_reserva NUMBER);
    PROCEDURE completar(p_id_reserva NUMBER);
    PROCEDURE eliminar(p_id NUMBER);
    FUNCTION obtener(p_id_reserva NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION listar_todas RETURN SYS_REFCURSOR;
    FUNCTION listar_activas RETURN SYS_REFCURSOR;
END pkg_reserva;
/

CREATE OR REPLACE PACKAGE BODY pkg_reserva AS

    PROCEDURE crear(p_id_huesped NUMBER, p_id_habitacion NUMBER,
                    p_id_empleado NUMBER, p_entrada DATE, p_salida DATE) IS
        v_estado VARCHAR2(20);
    BEGIN
        SELECT estado INTO v_estado FROM HABITACION
        WHERE id_habitacion = p_id_habitacion;

        IF v_estado != 'DISPONIBLE' THEN
            RAISE_APPLICATION_ERROR(-20012, 'La habitacion no esta disponible');
        END IF;

        INSERT INTO RESERVA (id_huesped, id_habitacion, id_empleado, fecha_entrada, fecha_salida, estado)
        VALUES (p_id_huesped, p_id_habitacion, p_id_empleado, p_entrada, p_salida, 'ACTIVA');

        UPDATE HABITACION SET estado = 'OCUPADA' WHERE id_habitacion = p_id_habitacion;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END crear;

    PROCEDURE cancelar(p_id_reserva NUMBER) IS
        v_id_hab NUMBER;
        v_estado VARCHAR2(20);
    BEGIN
        SELECT id_habitacion, estado INTO v_id_hab, v_estado
        FROM RESERVA WHERE id_reserva = p_id_reserva;

        IF v_estado NOT IN ('PENDIENTE','ACTIVA') THEN
            RAISE_APPLICATION_ERROR(-20012, 'Solo se pueden cancelar reservas PENDIENTES o ACTIVAS');
        END IF;

        UPDATE RESERVA SET estado = 'CANCELADA' WHERE id_reserva = p_id_reserva;
        UPDATE HABITACION SET estado = 'DISPONIBLE' WHERE id_habitacion = v_id_hab;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Reserva no encontrada: ' || p_id_reserva);
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END cancelar;

    PROCEDURE completar(p_id_reserva NUMBER) IS
        v_id_hab NUMBER;
    BEGIN
        SELECT id_habitacion INTO v_id_hab FROM RESERVA WHERE id_reserva = p_id_reserva;
        UPDATE RESERVA SET estado = 'COMPLETADA' WHERE id_reserva = p_id_reserva;
        UPDATE HABITACION SET estado = 'DISPONIBLE' WHERE id_habitacion = v_id_hab;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Reserva no encontrada: ' || p_id_reserva);
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END completar;

    PROCEDURE eliminar(p_id NUMBER) IS
    BEGIN
        DELETE FROM RESERVA WHERE id_reserva = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 'Reserva no encontrada: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END eliminar;

    FUNCTION obtener(p_id_reserva NUMBER) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT r.id_reserva,
                   h.nombre || ' ' || h.apellido AS huesped,
                   h.dni,
                   hab.numero_habitacion,
                   t.nombre AS tipo_habitacion,
                   t.precio_noche,
                   r.fecha_entrada,
                   r.fecha_salida,
                   (r.fecha_salida - r.fecha_entrada) AS noches,
                   r.estado,
                   r.fecha_reserva,
                   e.nombre || ' ' || e.apellido AS empleado
            FROM RESERVA r
            JOIN HUESPED h       ON r.id_huesped    = h.id_huesped
            JOIN HABITACION hab  ON r.id_habitacion = hab.id_habitacion
            JOIN TIPO_HABITACION t ON hab.id_tipo   = t.id_tipo
            LEFT JOIN EMPLEADO e ON r.id_empleado   = e.id_empleado
            WHERE r.id_reserva = p_id_reserva;
        RETURN v_cur;
    END obtener;

    FUNCTION listar_todas RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT r.id_reserva,
                   h.nombre || ' ' || h.apellido AS huesped,
                   hab.numero_habitacion,
                   r.fecha_entrada,
                   r.fecha_salida,
                   r.estado
            FROM RESERVA r
            JOIN HUESPED h      ON r.id_huesped    = h.id_huesped
            JOIN HABITACION hab ON r.id_habitacion = hab.id_habitacion
            ORDER BY r.fecha_reserva DESC;
        RETURN v_cur;
    END listar_todas;

    FUNCTION listar_activas RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT r.id_reserva,
                   h.nombre || ' ' || h.apellido AS huesped,
                   hab.numero_habitacion,
                   r.fecha_entrada,
                   r.fecha_salida,
                   r.estado
            FROM RESERVA r
            JOIN HUESPED h      ON r.id_huesped    = h.id_huesped
            JOIN HABITACION hab ON r.id_habitacion = hab.id_habitacion
            WHERE r.estado = 'ACTIVA'
            ORDER BY r.fecha_entrada;
        RETURN v_cur;
    END listar_activas;

END pkg_reserva;
/

-- ============================================================
-- PAQUETE: PKG_SERVICIO
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_servicio AS
    PROCEDURE insertar(p_nombre VARCHAR2, p_descripcion VARCHAR2, p_precio NUMBER);
    PROCEDURE actualizar(p_id NUMBER, p_nombre VARCHAR2,
                         p_descripcion VARCHAR2, p_precio NUMBER);
    PROCEDURE eliminar(p_id NUMBER);
    FUNCTION obtener(p_id NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION listar RETURN SYS_REFCURSOR;
END pkg_servicio;
/

CREATE OR REPLACE PACKAGE BODY pkg_servicio AS

    PROCEDURE insertar(p_nombre VARCHAR2, p_descripcion VARCHAR2, p_precio NUMBER) IS
    BEGIN
        INSERT INTO SERVICIO (nombre, descripcion, precio)
        VALUES (p_nombre, p_descripcion, p_precio);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END insertar;

    PROCEDURE actualizar(p_id NUMBER, p_nombre VARCHAR2,
                         p_descripcion VARCHAR2, p_precio NUMBER) IS
    BEGIN
        UPDATE SERVICIO
        SET nombre = p_nombre, descripcion = p_descripcion, precio = p_precio
        WHERE id_servicio = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Servicio no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END actualizar;

    PROCEDURE eliminar(p_id NUMBER) IS
    BEGIN
        DELETE FROM SERVICIO WHERE id_servicio = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Servicio no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END eliminar;

    FUNCTION obtener(p_id NUMBER) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT id_servicio, nombre, descripcion, precio
            FROM SERVICIO WHERE id_servicio = p_id;
        RETURN v_cur;
    END obtener;

    FUNCTION listar RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT id_servicio, nombre, descripcion, precio
            FROM SERVICIO ORDER BY nombre;
        RETURN v_cur;
    END listar;

END pkg_servicio;
/

-- ============================================================
-- PAQUETE: PKG_RESERVA_SERVICIO
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_reserva_servicio AS
    PROCEDURE insertar(p_id_reserva NUMBER, p_id_servicio NUMBER,
                       p_cantidad NUMBER, p_fecha_uso DATE);
    PROCEDURE actualizar(p_id NUMBER, p_cantidad NUMBER, p_fecha_uso DATE);
    PROCEDURE eliminar(p_id NUMBER);
    FUNCTION obtener(p_id NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION listar_por_reserva(p_id_reserva NUMBER) RETURN SYS_REFCURSOR;
END pkg_reserva_servicio;
/

CREATE OR REPLACE PACKAGE BODY pkg_reserva_servicio AS

    PROCEDURE insertar(p_id_reserva NUMBER, p_id_servicio NUMBER,
                       p_cantidad NUMBER, p_fecha_uso DATE) IS
    BEGIN
        INSERT INTO RESERVA_SERVICIO (id_reserva, id_servicio, cantidad, fecha_uso)
        VALUES (p_id_reserva, p_id_servicio, p_cantidad, NVL(p_fecha_uso, SYSDATE));
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END insertar;

    PROCEDURE actualizar(p_id NUMBER, p_cantidad NUMBER, p_fecha_uso DATE) IS
    BEGIN
        UPDATE RESERVA_SERVICIO
        SET cantidad = p_cantidad, fecha_uso = p_fecha_uso
        WHERE id_res_serv = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Registro no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END actualizar;

    PROCEDURE eliminar(p_id NUMBER) IS
    BEGIN
        DELETE FROM RESERVA_SERVICIO WHERE id_res_serv = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Registro no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END eliminar;

    FUNCTION obtener(p_id NUMBER) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT rs.id_res_serv, rs.id_reserva, rs.id_servicio,
                   s.nombre AS servicio, rs.cantidad,
                   rs.cantidad * s.precio AS subtotal,
                   rs.fecha_uso
            FROM RESERVA_SERVICIO rs
            JOIN SERVICIO s ON rs.id_servicio = s.id_servicio
            WHERE rs.id_res_serv = p_id;
        RETURN v_cur;
    END obtener;

    FUNCTION listar_por_reserva(p_id_reserva NUMBER) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT rs.id_res_serv, rs.id_servicio,
                   s.nombre AS servicio, s.precio,
                   rs.cantidad,
                   rs.cantidad * s.precio AS subtotal,
                   rs.fecha_uso
            FROM RESERVA_SERVICIO rs
            JOIN SERVICIO s ON rs.id_servicio = s.id_servicio
            WHERE rs.id_reserva = p_id_reserva
            ORDER BY rs.fecha_uso;
        RETURN v_cur;
    END listar_por_reserva;

END pkg_reserva_servicio;
/

-- ============================================================
-- PAQUETE: PKG_PAGO
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_pago AS
    PROCEDURE registrar(p_id_reserva NUMBER, p_metodo VARCHAR2);
    PROCEDURE anular(p_id_pago NUMBER);
    FUNCTION obtener(p_id_pago NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION obtener_por_reserva(p_id_reserva NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION listar_todos RETURN SYS_REFCURSOR;
END pkg_pago;
/

CREATE OR REPLACE PACKAGE BODY pkg_pago AS

    PROCEDURE registrar(p_id_reserva NUMBER, p_metodo VARCHAR2) IS
        v_noches    NUMBER;
        v_precio    NUMBER;
        v_servicios NUMBER := 0;
        v_total     NUMBER;
    BEGIN
        SELECT (r.fecha_salida - r.fecha_entrada), t.precio_noche
        INTO v_noches, v_precio
        FROM RESERVA r
        JOIN HABITACION h       ON r.id_habitacion = h.id_habitacion
        JOIN TIPO_HABITACION t  ON h.id_tipo       = t.id_tipo
        WHERE r.id_reserva = p_id_reserva;

        SELECT NVL(SUM(s.precio * rs.cantidad), 0)
        INTO v_servicios
        FROM RESERVA_SERVICIO rs
        JOIN SERVICIO s ON rs.id_servicio = s.id_servicio
        WHERE rs.id_reserva = p_id_reserva;

        v_total := (v_noches * v_precio) + v_servicios;

        INSERT INTO PAGO (id_reserva, monto_total, metodo_pago, estado)
        VALUES (p_id_reserva, v_total, p_metodo, 'PAGADO');

        UPDATE RESERVA SET estado = 'COMPLETADA' WHERE id_reserva = p_id_reserva;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20013, 'Reserva no encontrada: ' || p_id_reserva);
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END registrar;

    PROCEDURE anular(p_id_pago NUMBER) IS
    BEGIN
        UPDATE PAGO SET estado = 'ANULADO' WHERE id_pago = p_id_pago;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Pago no encontrado: ' || p_id_pago);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END anular;

    FUNCTION obtener(p_id_pago NUMBER) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT p.id_pago, p.id_reserva, p.fecha_pago,
                   p.monto_total, p.metodo_pago, p.estado,
                   h.nombre || ' ' || h.apellido AS huesped
            FROM PAGO p
            JOIN RESERVA r  ON p.id_reserva = r.id_reserva
            JOIN HUESPED h  ON r.id_huesped = h.id_huesped
            WHERE p.id_pago = p_id_pago;
        RETURN v_cur;
    END obtener;

    FUNCTION obtener_por_reserva(p_id_reserva NUMBER) RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT p.id_pago, p.id_reserva, p.fecha_pago,
                   p.monto_total, p.metodo_pago, p.estado,
                   h.nombre || ' ' || h.apellido AS huesped
            FROM PAGO p
            JOIN RESERVA r ON p.id_reserva = r.id_reserva
            JOIN HUESPED h ON r.id_huesped = h.id_huesped
            WHERE p.id_reserva = p_id_reserva;
        RETURN v_cur;
    END obtener_por_reserva;

    FUNCTION listar_todos RETURN SYS_REFCURSOR IS
        v_cur SYS_REFCURSOR;
    BEGIN
        OPEN v_cur FOR
            SELECT p.id_pago, p.id_reserva, p.fecha_pago,
                   p.monto_total, p.metodo_pago, p.estado,
                   h.nombre || ' ' || h.apellido AS huesped
            FROM PAGO p
            JOIN RESERVA r ON p.id_reserva = r.id_reserva
            JOIN HUESPED h ON r.id_huesped = h.id_huesped
            ORDER BY p.fecha_pago DESC;
        RETURN v_cur;
    END listar_todos;

END pkg_pago;
/

-- ============================================================
-- DATOS DE PRUEBA
-- ============================================================

INSERT INTO TIPO_HABITACION (nombre, descripcion, precio_noche)
VALUES ('Simple', 'Habitacion individual con bano privado', 50);

INSERT INTO TIPO_HABITACION (nombre, descripcion, precio_noche)
VALUES ('Doble', 'Habitacion doble con vista al jardin', 90);

INSERT INTO TIPO_HABITACION (nombre, descripcion, precio_noche)
VALUES ('Suite', 'Suite de lujo con jacuzzi y sala', 200);

BEGIN pkg_habitacion.insertar(101, 1, 1); END;
/
BEGIN pkg_habitacion.insertar(102, 1, 1); END;
/
BEGIN pkg_habitacion.insertar(201, 2, 2); END;
/
BEGIN pkg_habitacion.insertar(202, 2, 2); END;
/
BEGIN pkg_habitacion.insertar(301, 3, 3); END;
/

BEGIN pkg_huesped.insertar('Juan','Perez','1234567890','juan@mail.com','0991234567'); END;
/
BEGIN pkg_huesped.insertar('Maria','Lopez','0987654321','maria@mail.com','0997654321'); END;
/
BEGIN pkg_huesped.insertar('Carlos','Ramirez','1122334455','carlos@mail.com','0993344556'); END;
/

BEGIN pkg_empleado.insertar('Ana','Torres','Recepcionista','ana@hotel.com', 800); END;
/
BEGIN pkg_empleado.insertar('Luis','Mora','Gerente','luis@hotel.com', 1500); END;
/

BEGIN pkg_servicio.insertar('Desayuno','Desayuno buffet completo', 15); END;
/
BEGIN pkg_servicio.insertar('Spa','Sesion de spa 1 hora', 40); END;
/
BEGIN pkg_servicio.insertar('Lavanderia','Servicio de lavanderia por prenda', 5); END;
/
BEGIN pkg_servicio.insertar('Parqueadero','Parqueadero cubierto por dia', 8); END;
/

COMMIT;
