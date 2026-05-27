-- ============================================================
-- HOTEL DATABASE - DDL COMPLETO CORREGIDO
-- Usuario: HOTEL
-- Oracle Database
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
        IF p_nombre IS NULL OR TRIM(p_nombre) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 'El nombre del huesped es obligatorio');
        END IF;
        IF p_apellido IS NULL OR TRIM(p_apellido) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 'El apellido del huesped es obligatorio');
        END IF;
        IF p_dni IS NULL OR TRIM(p_dni) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 'El DNI del huesped es obligatorio');
        END IF;

        INSERT INTO HUESPED (nombre, apellido, dni, email, telefono)
        VALUES (TRIM(p_nombre), TRIM(p_apellido), TRIM(p_dni), TRIM(p_email), TRIM(p_telefono));
        COMMIT;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20010, 'El DNI ya existe: ' || p_dni);
        WHEN OTHERS THEN
            ROLLBACK; RAISE;
    END insertar;

    PROCEDURE actualizar(p_id NUMBER, p_nombre VARCHAR2, p_apellido VARCHAR2,
                         p_email VARCHAR2, p_telefono VARCHAR2) IS
    BEGIN
        IF p_nombre IS NULL OR TRIM(p_nombre) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 'El nombre del huesped es obligatorio');
        END IF;
        IF p_apellido IS NULL OR TRIM(p_apellido) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 'El apellido del huesped es obligatorio');
        END IF;

        UPDATE HUESPED
           SET nombre   = TRIM(p_nombre),
               apellido = TRIM(p_apellido),
               email    = TRIM(p_email),
               telefono = TRIM(p_telefono)
         WHERE id_huesped = p_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Huesped no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END actualizar;

    PROCEDURE eliminar(p_id NUMBER) IS
        e_hijo_encontrado EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_hijo_encontrado, -2292);
    BEGIN
        DELETE FROM HUESPED WHERE id_huesped = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Huesped no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN e_hijo_encontrado THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20010,
                'No se puede eliminar el huesped porque tiene reservas asociadas: ' || p_id);
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
        v_dummy NUMBER;
    BEGIN
        IF p_numero IS NULL OR p_numero <= 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'El numero de habitacion debe ser mayor a 0');
        END IF;
        IF p_piso IS NULL OR p_piso <= 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'El piso debe ser mayor a 0');
        END IF;

        SELECT 1 INTO v_dummy FROM TIPO_HABITACION WHERE id_tipo = p_id_tipo;

        INSERT INTO HABITACION (numero_habitacion, id_tipo, piso)
        VALUES (p_numero, p_id_tipo, p_piso);
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20011, 'Tipo de habitacion no encontrado: ' || p_id_tipo);
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20011, 'Numero de habitacion ya existe: ' || p_numero);
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END insertar;

    PROCEDURE actualizar_estado(p_id NUMBER, p_estado VARCHAR2) IS
        v_estado VARCHAR2(20);
        v_reservas_activas NUMBER;
    BEGIN
        v_estado := UPPER(TRIM(p_estado));

        IF v_estado NOT IN ('DISPONIBLE','OCUPADA','MANTENIMIENTO') THEN
            RAISE_APPLICATION_ERROR(-20011, 'Estado de habitacion invalido: ' || p_estado);
        END IF;

        IF v_estado IN ('DISPONIBLE','MANTENIMIENTO') THEN
            SELECT COUNT(*) INTO v_reservas_activas
              FROM RESERVA
             WHERE id_habitacion = p_id AND estado = 'ACTIVA';

            IF v_reservas_activas > 0 THEN
                RAISE_APPLICATION_ERROR(-20011,
                    'No se puede cambiar el estado: la habitacion tiene una reserva ACTIVA');
            END IF;
        END IF;

        UPDATE HABITACION SET estado = v_estado WHERE id_habitacion = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Habitacion no encontrada: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END actualizar_estado;

    PROCEDURE eliminar(p_id NUMBER) IS
        e_hijo_encontrado EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_hijo_encontrado, -2292);
    BEGIN
        DELETE FROM HABITACION WHERE id_habitacion = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Habitacion no encontrada: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN e_hijo_encontrado THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20011,
                'No se puede eliminar la habitacion porque tiene reservas asociadas: ' || p_id);
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
    FUNCTION listar_todos RETURN SYS_REFCURSOR;
END pkg_empleado;
/

CREATE OR REPLACE PACKAGE BODY pkg_empleado AS

    PROCEDURE insertar(p_nombre VARCHAR2, p_apellido VARCHAR2,
                       p_cargo VARCHAR2, p_email VARCHAR2, p_salario NUMBER) IS
    BEGIN
        IF p_nombre IS NULL OR TRIM(p_nombre) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'El nombre del empleado es obligatorio');
        END IF;
        IF p_apellido IS NULL OR TRIM(p_apellido) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'El apellido del empleado es obligatorio');
        END IF;
        IF p_cargo IS NULL OR TRIM(p_cargo) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'El cargo del empleado es obligatorio');
        END IF;
        IF p_salario IS NOT NULL AND p_salario < 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'El salario no puede ser negativo');
        END IF;

        INSERT INTO EMPLEADO (nombre, apellido, cargo, email, salario)
        VALUES (TRIM(p_nombre), TRIM(p_apellido), TRIM(p_cargo), TRIM(p_email), p_salario);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END insertar;

    PROCEDURE actualizar(p_id NUMBER, p_nombre VARCHAR2, p_apellido VARCHAR2,
                         p_cargo VARCHAR2, p_email VARCHAR2, p_salario NUMBER) IS
    BEGIN
        IF p_nombre IS NULL OR TRIM(p_nombre) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'El nombre del empleado es obligatorio');
        END IF;
        IF p_apellido IS NULL OR TRIM(p_apellido) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'El apellido del empleado es obligatorio');
        END IF;
        IF p_cargo IS NULL OR TRIM(p_cargo) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'El cargo del empleado es obligatorio');
        END IF;
        IF p_salario IS NOT NULL AND p_salario < 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'El salario no puede ser negativo');
        END IF;

        UPDATE EMPLEADO
           SET nombre   = TRIM(p_nombre),
               apellido = TRIM(p_apellido),
               cargo    = TRIM(p_cargo),
               email    = TRIM(p_email),
               salario  = p_salario
         WHERE id_empleado = p_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Empleado no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END actualizar;

    PROCEDURE eliminar(p_id NUMBER) IS
        e_hijo_encontrado EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_hijo_encontrado, -2292);
    BEGIN
        DELETE FROM EMPLEADO WHERE id_empleado = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Empleado no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN e_hijo_encontrado THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001,
                'No se puede eliminar el empleado porque tiene reservas asociadas: ' || p_id);
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

    FUNCTION listar_todos RETURN SYS_REFCURSOR IS
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
                    p_id_empleado NUMBER DEFAULT NULL,
                    p_entrada DATE, p_salida DATE);
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
                    p_id_empleado NUMBER DEFAULT NULL,
                    p_entrada DATE, p_salida DATE) IS
        v_dummy              NUMBER;
        v_estado_habitacion  HABITACION.estado%TYPE;
        v_solapadas          NUMBER;
        v_estado_reserva     RESERVA.estado%TYPE;
    BEGIN
        IF p_entrada IS NULL OR p_salida IS NULL THEN
            RAISE_APPLICATION_ERROR(-20012, 'Las fechas de entrada y salida son obligatorias');
        END IF;
        IF p_salida <= p_entrada THEN
            RAISE_APPLICATION_ERROR(-20012, 'La fecha de salida debe ser mayor a la fecha de entrada');
        END IF;

        SELECT 1 INTO v_dummy FROM HUESPED WHERE id_huesped = p_id_huesped;

        IF p_id_empleado IS NOT NULL THEN
            SELECT 1 INTO v_dummy FROM EMPLEADO WHERE id_empleado = p_id_empleado;
        END IF;

        SELECT estado INTO v_estado_habitacion
          FROM HABITACION
         WHERE id_habitacion = p_id_habitacion
         FOR UPDATE;

        IF v_estado_habitacion = 'MANTENIMIENTO' THEN
            RAISE_APPLICATION_ERROR(-20012, 'La habitacion esta en mantenimiento');
        END IF;

        SELECT COUNT(*) INTO v_solapadas
          FROM RESERVA
         WHERE id_habitacion = p_id_habitacion
           AND estado IN ('PENDIENTE','ACTIVA')
           AND p_entrada < fecha_salida
           AND p_salida  > fecha_entrada;

        IF v_solapadas > 0 THEN
            RAISE_APPLICATION_ERROR(-20012,
                'La habitacion ya tiene una reserva en el rango de fechas solicitado');
        END IF;

        IF TRUNC(p_entrada) <= TRUNC(SYSDATE) AND TRUNC(p_salida) > TRUNC(SYSDATE) THEN
            v_estado_reserva := 'ACTIVA';
        ELSE
            v_estado_reserva := 'PENDIENTE';
        END IF;

        INSERT INTO RESERVA (id_huesped, id_habitacion, id_empleado,
                             fecha_entrada, fecha_salida, estado)
        VALUES (p_id_huesped, p_id_habitacion, p_id_empleado,
                p_entrada, p_salida, v_estado_reserva);

        IF v_estado_reserva = 'ACTIVA' THEN
            UPDATE HABITACION SET estado = 'OCUPADA'
             WHERE id_habitacion = p_id_habitacion;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20012,
                'No existe el huesped, empleado o habitacion especificado');
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END crear;

    PROCEDURE cancelar(p_id_reserva NUMBER) IS
        v_id_hab  RESERVA.id_habitacion%TYPE;
        v_estado  RESERVA.estado%TYPE;
    BEGIN
        SELECT id_habitacion, estado INTO v_id_hab, v_estado
          FROM RESERVA
         WHERE id_reserva = p_id_reserva
         FOR UPDATE;

        IF v_estado NOT IN ('PENDIENTE','ACTIVA') THEN
            RAISE_APPLICATION_ERROR(-20012,
                'Solo se pueden cancelar reservas en estado PENDIENTE o ACTIVA');
        END IF;

        UPDATE RESERVA SET estado = 'CANCELADA' WHERE id_reserva = p_id_reserva;

        IF v_estado = 'ACTIVA' THEN
            UPDATE HABITACION SET estado = 'DISPONIBLE'
             WHERE id_habitacion = v_id_hab;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20012, 'Reserva no encontrada: ' || p_id_reserva);
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END cancelar;

    PROCEDURE completar(p_id_reserva NUMBER) IS
        v_id_hab  RESERVA.id_habitacion%TYPE;
        v_estado  RESERVA.estado%TYPE;
    BEGIN
        SELECT id_habitacion, estado INTO v_id_hab, v_estado
          FROM RESERVA
         WHERE id_reserva = p_id_reserva
         FOR UPDATE;

        IF v_estado <> 'ACTIVA' THEN
            RAISE_APPLICATION_ERROR(-20012,
                'Solo se puede completar una reserva en estado ACTIVA');
        END IF;

        UPDATE RESERVA SET estado = 'COMPLETADA' WHERE id_reserva = p_id_reserva;
        UPDATE HABITACION SET estado = 'DISPONIBLE' WHERE id_habitacion = v_id_hab;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20012, 'Reserva no encontrada: ' || p_id_reserva);
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END completar;

    PROCEDURE eliminar(p_id NUMBER) IS
        v_estado              RESERVA.estado%TYPE;
        e_hijo_encontrado     EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_hijo_encontrado, -2292);
    BEGIN
        SELECT estado INTO v_estado
          FROM RESERVA
         WHERE id_reserva = p_id
         FOR UPDATE;

        IF v_estado IN ('PENDIENTE','ACTIVA') THEN
            RAISE_APPLICATION_ERROR(-20012,
                'No se puede eliminar una reserva PENDIENTE o ACTIVA. Primero cancelela o completela');
        END IF;

        DELETE FROM RESERVA WHERE id_reserva = p_id;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20012, 'Reserva no encontrada: ' || p_id);
        WHEN e_hijo_encontrado THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20012,
                'No se puede eliminar la reserva porque tiene servicios o pagos asociados: ' || p_id);
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
                   CEIL(r.fecha_salida - r.fecha_entrada) AS noches,
                   r.estado,
                   r.fecha_reserva,
                   e.nombre || ' ' || e.apellido AS empleado
              FROM RESERVA r
              JOIN HUESPED h          ON r.id_huesped    = h.id_huesped
              JOIN HABITACION hab     ON r.id_habitacion = hab.id_habitacion
              JOIN TIPO_HABITACION t  ON hab.id_tipo     = t.id_tipo
              LEFT JOIN EMPLEADO e    ON r.id_empleado   = e.id_empleado
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
        IF p_nombre IS NULL OR TRIM(p_nombre) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20002, 'El nombre del servicio es obligatorio');
        END IF;
        IF p_precio IS NULL OR p_precio < 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'El precio del servicio debe ser mayor o igual a 0');
        END IF;

        INSERT INTO SERVICIO (nombre, descripcion, precio)
        VALUES (TRIM(p_nombre), TRIM(p_descripcion), p_precio);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END insertar;

    PROCEDURE actualizar(p_id NUMBER, p_nombre VARCHAR2,
                         p_descripcion VARCHAR2, p_precio NUMBER) IS
    BEGIN
        IF p_nombre IS NULL OR TRIM(p_nombre) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20002, 'El nombre del servicio es obligatorio');
        END IF;
        IF p_precio IS NULL OR p_precio < 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'El precio del servicio debe ser mayor o igual a 0');
        END IF;

        UPDATE SERVICIO
           SET nombre      = TRIM(p_nombre),
               descripcion = TRIM(p_descripcion),
               precio      = p_precio
         WHERE id_servicio = p_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Servicio no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END actualizar;

    PROCEDURE eliminar(p_id NUMBER) IS
        e_hijo_encontrado EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_hijo_encontrado, -2292);
    BEGIN
        DELETE FROM SERVICIO WHERE id_servicio = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Servicio no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN e_hijo_encontrado THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002,
                'No se puede eliminar el servicio porque esta asociado a reservas: ' || p_id);
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
        v_estado_reserva  RESERVA.estado%TYPE;
        v_fecha_entrada   RESERVA.fecha_entrada%TYPE;
        v_fecha_salida    RESERVA.fecha_salida%TYPE;
        v_fecha_real      DATE;
        v_dummy           NUMBER;
    BEGIN
        IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'La cantidad debe ser mayor a 0');
        END IF;

        v_fecha_real := NVL(p_fecha_uso, SYSDATE);

        SELECT estado, fecha_entrada, fecha_salida
          INTO v_estado_reserva, v_fecha_entrada, v_fecha_salida
          FROM RESERVA WHERE id_reserva = p_id_reserva;

        IF v_estado_reserva = 'CANCELADA' THEN
            RAISE_APPLICATION_ERROR(-20003,
                'No se pueden agregar servicios a una reserva CANCELADA');
        END IF;

        IF TRUNC(v_fecha_real) < TRUNC(v_fecha_entrada)
           OR TRUNC(v_fecha_real) > TRUNC(v_fecha_salida) THEN
            RAISE_APPLICATION_ERROR(-20003,
                'La fecha de uso del servicio esta fuera del rango de la reserva');
        END IF;

        SELECT 1 INTO v_dummy FROM SERVICIO WHERE id_servicio = p_id_servicio;

        INSERT INTO RESERVA_SERVICIO (id_reserva, id_servicio, cantidad, fecha_uso)
        VALUES (p_id_reserva, p_id_servicio, p_cantidad, v_fecha_real);
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20003,
                'No existe la reserva o el servicio especificado');
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END insertar;

    PROCEDURE actualizar(p_id NUMBER, p_cantidad NUMBER, p_fecha_uso DATE) IS
        v_estado_reserva  RESERVA.estado%TYPE;
        v_fecha_entrada   RESERVA.fecha_entrada%TYPE;
        v_fecha_salida    RESERVA.fecha_salida%TYPE;
        v_fecha_real      DATE;
    BEGIN
        IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'La cantidad debe ser mayor a 0');
        END IF;

        SELECT r.estado, r.fecha_entrada, r.fecha_salida,
               NVL(p_fecha_uso, rs.fecha_uso)
          INTO v_estado_reserva, v_fecha_entrada, v_fecha_salida, v_fecha_real
          FROM RESERVA_SERVICIO rs
          JOIN RESERVA r ON rs.id_reserva = r.id_reserva
         WHERE rs.id_res_serv = p_id;

        IF v_estado_reserva = 'CANCELADA' THEN
            RAISE_APPLICATION_ERROR(-20003,
                'No se pueden modificar servicios de una reserva CANCELADA');
        END IF;

        IF TRUNC(v_fecha_real) < TRUNC(v_fecha_entrada)
           OR TRUNC(v_fecha_real) > TRUNC(v_fecha_salida) THEN
            RAISE_APPLICATION_ERROR(-20003,
                'La fecha de uso del servicio esta fuera del rango de la reserva');
        END IF;

        UPDATE RESERVA_SERVICIO
           SET cantidad  = p_cantidad,
               fecha_uso = v_fecha_real
         WHERE id_res_serv = p_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Registro no encontrado: ' || p_id);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20003, 'Registro no encontrado: ' || p_id);
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
        v_noches          NUMBER;
        v_precio          NUMBER;
        v_servicios       NUMBER := 0;
        v_total           NUMBER;
        v_estado_reserva  RESERVA.estado%TYPE;
        v_id_habitacion   RESERVA.id_habitacion%TYPE;
        v_metodo          VARCHAR2(30);
        v_existe          NUMBER;
    BEGIN
        v_metodo := UPPER(TRIM(p_metodo));

        IF v_metodo NOT IN ('EFECTIVO','TARJETA','TRANSFERENCIA') THEN
            RAISE_APPLICATION_ERROR(-20013, 'Metodo de pago invalido: ' || p_metodo);
        END IF;

        SELECT COUNT(*) INTO v_existe
          FROM PAGO WHERE id_reserva = p_id_reserva;

        IF v_existe > 0 THEN
            RAISE_APPLICATION_ERROR(-20013,
                'La reserva ya tiene un pago registrado: ' || p_id_reserva);
        END IF;

        SELECT CEIL(r.fecha_salida - r.fecha_entrada),
               t.precio_noche,
               r.estado,
               r.id_habitacion
          INTO v_noches, v_precio, v_estado_reserva, v_id_habitacion
          FROM RESERVA r
          JOIN HABITACION h       ON r.id_habitacion = h.id_habitacion
          JOIN TIPO_HABITACION t  ON h.id_tipo       = t.id_tipo
         WHERE r.id_reserva = p_id_reserva
         FOR UPDATE;

        IF v_estado_reserva = 'CANCELADA' THEN
            RAISE_APPLICATION_ERROR(-20013,
                'No se puede registrar un pago para una reserva CANCELADA');
        END IF;

        IF v_estado_reserva = 'PENDIENTE' THEN
            RAISE_APPLICATION_ERROR(-20013,
                'No se puede registrar el pago de una reserva en estado PENDIENTE');
        END IF;

        IF v_noches < 1 THEN
            v_noches := 1;
        END IF;

        SELECT NVL(SUM(s.precio * rs.cantidad), 0)
          INTO v_servicios
          FROM RESERVA_SERVICIO rs
          JOIN SERVICIO s ON rs.id_servicio = s.id_servicio
         WHERE rs.id_reserva = p_id_reserva;

        v_total := (v_noches * v_precio) + v_servicios;

        INSERT INTO PAGO (id_reserva, monto_total, metodo_pago, estado)
        VALUES (p_id_reserva, v_total, v_metodo, 'PAGADO');

        UPDATE RESERVA SET estado = 'COMPLETADA' WHERE id_reserva = p_id_reserva;
        UPDATE HABITACION SET estado = 'DISPONIBLE' WHERE id_habitacion = v_id_habitacion;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20013, 'Reserva no encontrada: ' || p_id_reserva);
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20013,
                'La reserva ya tiene un pago registrado: ' || p_id_reserva);
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END registrar;

    PROCEDURE anular(p_id_pago NUMBER) IS
        v_estado PAGO.estado%TYPE;
    BEGIN
        SELECT estado INTO v_estado
          FROM PAGO WHERE id_pago = p_id_pago
         FOR UPDATE;

        IF v_estado = 'ANULADO' THEN
            RAISE_APPLICATION_ERROR(-20013,
                'El pago ya se encuentra ANULADO: ' || p_id_pago);
        END IF;

        UPDATE PAGO SET estado = 'ANULADO' WHERE id_pago = p_id_pago;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20013, 'Pago no encontrado: ' || p_id_pago);
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
              JOIN RESERVA r ON p.id_reserva = r.id_reserva
              JOIN HUESPED h ON r.id_huesped  = h.id_huesped
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
              JOIN HUESPED h ON r.id_huesped  = h.id_huesped
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
              JOIN HUESPED h ON r.id_huesped  = h.id_huesped
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
