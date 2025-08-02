-- Procedimientos Almacenados

-- 1. Registrar una cita con validación de paciente y médico
DELIMITER $$
CREATE PROCEDURE sp_registrar_cita (
    IN p_id_paciente INT,
    IN p_id_medico INT,
    IN p_id_tipo_consulta INT,
    IN p_fecha DATETIME
)
BEGIN
    DECLARE existe_paciente INT DEFAULT 0;
    DECLARE existe_medico INT DEFAULT 0;

    SELECT COUNT(*) INTO existe_paciente FROM pacientes WHERE id_paciente = p_id_paciente;
    IF existe_paciente = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El paciente no existe.';
    END IF;

    SELECT COUNT(*) INTO existe_medico FROM medicos WHERE id_medico = p_id_medico;
    IF existe_medico = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El médico no existe.';
    END IF;

    INSERT INTO citas (paciente_id, medico_id, tipo_consulta_id, fecha, estado)
    VALUES (p_id_paciente, p_id_medico, p_id_tipo_consulta, p_fecha, 'pendiente');
END $$
DELIMITER ;
CALL sp_registrar_cita(1, 1, 1, '2025-08-01 09:00:00');
select * from citas;

-- 2. Actualizar estado de citas pendientes antes de una fecha dada.
DELIMITER $$
CREATE PROCEDURE sp_actualizar_citas_pendientes (
    IN p_fecha_limite DATETIME,
    IN p_nuevo_estado VARCHAR(20)
)
BEGIN
    UPDATE citas
    SET estado = p_nuevo_estado
    WHERE id_cita IN (
        SELECT id_cita
        FROM (
            SELECT id_cita
            FROM citas
            WHERE estado = 'pendiente' AND fecha < p_fecha_limite
        ) AS subconsulta_segura
    );
END $$
DELIMITER ;

CALL sp_actualizar_citas_pendientes('2025-07-05 00:00:00', 'cancelada');
select * from citas;

-- 3. Eliminación segura de un paciente, solo si no tiene citas pendientes.
DELIMITER $$
CREATE PROCEDURE sp_eliminar_paciente_seguro (
    IN p_id_paciente INT
)
BEGIN
    DECLARE citas_pendientes INT DEFAULT 0;

    SELECT COUNT(*) INTO citas_pendientes
    FROM citas
    WHERE paciente_id = p_id_paciente AND estado = 'pendiente';

    IF citas_pendientes > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar paciente con citas pendientes.';
    ELSE
        DELETE FROM pacientes WHERE id_paciente = p_id_paciente;
    END IF;
END $$
DELIMITER ;

CALL sp_eliminar_paciente_seguro(2);
select * from pacientes;



-- 4. Generar reporte de facturas por período cantidad y total.
DELIMITER $$
CREATE PROCEDURE sp_reporte_facturas_por_periodo (
    IN p_fecha_inicio DATETIME,
    IN p_fecha_fin DATETIME
)
BEGIN
    SELECT 
        COUNT(*) AS total_facturas,
        SUM(total) AS monto_total
    FROM facturas
    WHERE fecha BETWEEN p_fecha_inicio AND p_fecha_fin;
END $$
DELIMITER ;

CALL sp_reporte_facturas_por_periodo('2025-07-01 00:00:00', '2025-07-10 23:59:59');

-- 5. Facturación automática para una cita transacción con manejo de errores
DELIMITER $$
CREATE PROCEDURE sp_facturar_cita (
    IN p_id_cita INT,
    IN p_id_forma_pago INT
)
BEGIN
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error durante facturación, se deshizo la transacción.';
    END;
    START TRANSACTION;
    SELECT tc.tarifa INTO v_total
    FROM citas c
    JOIN tipos_consulta tc ON c.tipo_consulta_id = tc.id_tipo_consulta
    WHERE c.id_cita = p_id_cita;
    INSERT INTO facturas (cita_id, fecha, total, forma_pago_id)
    VALUES (p_id_cita, NOW(), v_total, p_id_forma_pago);
    INSERT INTO detalle_factura (factura_id, descripcion, monto)
    VALUES (LAST_INSERT_ID(), 'Tarifa consulta', v_total);
    COMMIT;
END $$
DELIMITER ;
CALL sp_facturar_cita(3, 1);
select * from facturas;
select * from detalle_factura;

-- 6. Insertar medicamento con validación de nombre único
DELIMITER $$
CREATE PROCEDURE sp_insertar_medicamento (
    IN p_nombre VARCHAR(100),
    IN p_unidad VARCHAR(20)
)
BEGIN
    DECLARE existe_medicamento INT DEFAULT 0;

    SELECT COUNT(*) INTO existe_medicamento FROM medicamentos WHERE nombre = p_nombre;
    IF existe_medicamento > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El medicamento ya existe.';
    ELSE
        INSERT INTO medicamentos(nombre, unidad) VALUES (p_nombre, p_unidad);
    END IF;
END $$
DELIMITER ;

CALL sp_insertar_medicamento('Diclofenaco', 'mg');
select * from medicamentos;



-- 7. Actualizar tarifas de tipos de consulta por porcentaje
DELIMITER $$
CREATE PROCEDURE actualizar_tarifa(
    IN p_id_tipo INT,
    IN p_porcentaje DECIMAL(5,2)
)
BEGIN
    UPDATE tipos_consulta
    SET tarifa = tarifa + (tarifa * p_porcentaje / 100)
    WHERE id_tipo_consulta = p_id_tipo;
END $$
DELIMITER ;

CALL actualizar_tarifa(2, 10);
select * from tipos_consulta;

-- 8. Eliminación segura de médico sin citas pendientes
DELIMITER $$
CREATE PROCEDURE sp_eliminar_medico_seguro (
    IN p_id_medico INT
)
BEGIN
    DECLARE citas_pendientes INT DEFAULT 0;

    SELECT COUNT(*) INTO citas_pendientes FROM citas
    WHERE medico_id = p_id_medico AND estado = 'pendiente';

    IF citas_pendientes > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar médico con citas pendientes.';
    ELSE
        DELETE FROM medicos WHERE id_medico = p_id_medico;
    END IF;
END $$
DELIMITER ;

CALL sp_eliminar_medico_seguro(4);
select * from medicos;



-- 9. Reporte de pacientes registrados por fecha de nacimiento
DELIMITER $$
CREATE PROCEDURE sp_reporte_pacientes_por_fecha (
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    SELECT id_paciente, nombre, fecha_nacimiento, genero, telefono, correo
    FROM pacientes
    WHERE fecha_nacimiento BETWEEN p_fecha_inicio AND p_fecha_fin
    ORDER BY fecha_nacimiento;
END $$
DELIMITER ;

CALL sp_reporte_pacientes_por_fecha('1980-01-01', '2000-12-31');

-- 10. Facturación múltiple de varias citas con transacción
DELIMITER $$
CREATE PROCEDURE sp_facturar_multiples_citas (
    IN p_lista_citas TEXT, 
    IN p_id_forma_pago INT
)
BEGIN
    DECLARE v_pos INT DEFAULT 1;
    DECLARE v_longitud INT;
    DECLARE v_id_cita INT;
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_factura_id INT;
    START TRANSACTION;
    SET v_longitud = LENGTH(p_lista_citas) - LENGTH(REPLACE(p_lista_citas, ',', '')) + 1;

    WHILE v_pos <= v_longitud DO
        SET v_id_cita = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(p_lista_citas, ',', v_pos), ',', -1) AS UNSIGNED);
        SELECT tc.tarifa INTO v_total
        FROM citas c
        JOIN tipos_consulta tc ON c.tipo_consulta_id = tc.id_tipo_consulta
        WHERE c.id_cita = v_id_cita;
        INSERT INTO facturas (cita_id, fecha, total, forma_pago_id)
        VALUES (v_id_cita, NOW(), v_total, p_id_forma_pago);
        SET v_factura_id = LAST_INSERT_ID();
        INSERT INTO detalle_factura (factura_id, descripcion, monto)
        VALUES (v_factura_id, 'Tarifa consulta', v_total);
        SET v_pos = v_pos + 1;
    END WHILE;
    COMMIT;
END $$
DELIMITER ;

CALL sp_facturar_multiples_citas('1,3', 1);
select * from detalle_factura;


-- FUNCIONES
-- 1. Función que calcula la edad de un paciente a partir de su fecha de nacimiento
DELIMITER $$
CREATE FUNCTION fn_calcular_edad(fecha_nacimiento DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE edad INT;
    SET edad = TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE());
    RETURN edad;
END $$
DELIMITER ;

SELECT nombre, fn_calcular_edad(fecha_nacimiento) AS edad
FROM pacientes
LIMIT 5;

-- 2. Función que calcula el porcentaje de citas canceladas de un paciente por su ID
DELIMITER $$
CREATE FUNCTION fn_porcentaje_citas_canceladas(p_id_paciente INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE total_citas INT DEFAULT 0;
    DECLARE citas_canceladas INT DEFAULT 0;
    DECLARE porcentaje DECIMAL(5,2) DEFAULT 0;

    SELECT COUNT(*) INTO total_citas
    FROM citas
    WHERE paciente_id = p_id_paciente;

    IF total_citas = 0 THEN
        RETURN 0;
    END IF;
    SELECT COUNT(*) INTO citas_canceladas
    FROM citas
    WHERE paciente_id = p_id_paciente AND estado = 'cancelada';
    SET porcentaje = (citas_canceladas / total_citas) * 100;
    
    RETURN ROUND(porcentaje, 2);
END $$
DELIMITER ;

SELECT nombre, fn_porcentaje_citas_canceladas(id_paciente) AS porcentaje_canceladas
FROM pacientes
LIMIT 5;

-- 3. Función que devuelve el estado de riesgo del paciente basado en 
-- la cantidad de citas con diagnóstico grave ejemplo simple
DELIMITER $$
CREATE FUNCTION fn_estado_riesgo(p_id_paciente INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE cantidad_graves INT DEFAULT 0;

    SELECT COUNT(*) INTO cantidad_graves
    FROM historial_clinico
    WHERE paciente_id = p_id_paciente AND diagnostico LIKE '%grave%';

    IF cantidad_graves >= 3 THEN
        RETURN 'Alto riesgo';
    ELSEIF cantidad_graves BETWEEN 1 AND 2 THEN
        RETURN 'Riesgo moderado';
    ELSE
        RETURN 'Sin riesgo';
    END IF;
END $$
DELIMITER ;

SELECT nombre, fn_estado_riesgo(id_paciente) AS estado_riesgo
FROM pacientes
LIMIT 5;

-- TRIGGERS
-- Tabla y trigger para eliminar paciente
CREATE TABLE log_acciones (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(50),
    ip_cliente VARCHAR(45),
    terminal VARCHAR(50),
    rol_activo VARCHAR(50),
    accion VARCHAR(100),
    tabla VARCHAR(50),
    id_afectado INT,
    transaccion TEXT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER tr_auditoria_delete_paciente
AFTER DELETE ON pacientes
FOR EACH ROW
BEGIN
    INSERT INTO log_acciones (
        usuario, ip_cliente, terminal, rol_activo,
        accion, tabla, id_afectado, transaccion
    ) VALUES (
        CURRENT_USER(),
        '192.168.0.10',
        'PC-ADMIN',
        'admin',
        'AUDITORÍA: Eliminación de paciente',
        'pacientes',
        OLD.id_paciente,
        CONCAT('DELETE paciente ID=', OLD.id_paciente)
    );
END $$
DELIMITER ;

--  PRUEBA:
 DELETE FROM pacientes WHERE id_paciente = 8;
select * from pacientes;

-- 2. Disminución de stock de medicamentos
ALTER TABLE medicamentos ADD COLUMN stock INT DEFAULT 100;
DELIMITER $$
CREATE TRIGGER tr_control_baja_stock
AFTER INSERT ON detalle_receta
FOR EACH ROW
BEGIN
    UPDATE medicamentos
    SET stock = GREATEST(stock - 1, 0)
    WHERE id_medicamento = NEW.medicamento_id;

    INSERT INTO log_acciones (
        usuario, ip_cliente, terminal, rol_activo,
        accion, tabla, id_afectado, transaccion
    ) VALUES (
        CURRENT_USER(),
        '192.168.0.10',
        'PC-ADMIN',
        'admin',
        'CONTROL: Baja de stock automática',
        'detalle_receta',
        NEW.id_detalle,
        CONCAT('Medicamento ', NEW.medicamento_id, ' -1 stock')
    );
END $$
DELIMITER ;
-- PRUEBA:
INSERT INTO detalle_receta (receta_id, medicamento_id, dosis) 
VALUES (1, 2, '500mg cada 8h');
select * from detalle_receta;
-- 3. Registrar una cita
CREATE TABLE  r_notificaciones (
    id_notificacion INT AUTO_INCREMENT PRIMARY KEY,
    mensaje TEXT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
);
DELIMITER $$
CREATE TRIGGER tr_notificacion_cita
AFTER INSERT ON citas
FOR EACH ROW
BEGIN
    INSERT INTO r_notificaciones (mensaje)
    VALUES (CONCAT(CHAR(240), CHAR(159), CHAR(147), CHAR(133), ' Nueva cita registrada: paciente ',
    NEW.paciente_id, ', médico ', NEW.medico_id, ', fecha ', NEW.fecha));
    INSERT INTO log_acciones (
        usuario, ip_cliente, terminal, rol_activo,accion, tabla, id_afectado, transaccion
    ) VALUES (
        CURRENT_USER(),
        '192.168.0.10',
        'PC-ADMIN',
        'admin',
        'NOTIFICACIÓN: Nueva cita registrada',
        'citas',
        NEW.id_cita,
        CONCAT('INSERT cita ID=', NEW.id_cita)
    );
END $$
DELIMITER ;
--  PRUEBA:
INSERT INTO citas (paciente_id, medico_id, tipo_consulta_id, fecha) 
VALUES (1, 2, 1, NOW());
select * from citas;

-- 4. Registro de cambios en diagnóstico
CREATE TABLE historial_cambios (
    id_cambio INT AUTO_INCREMENT PRIMARY KEY,
    id_historial INT,
    diagnostico_anterior TEXT,
    diagnostico_nuevo TEXT,
    hash_previo CHAR(64),
    hash_nuevo CHAR(64),
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP
);
DELIMITER $$
CREATE TRIGGER tr_historial_diagnostico
BEFORE UPDATE ON historial_clinico
FOR EACH ROW
BEGIN
    IF OLD.diagnostico <> NEW.diagnostico THEN
        INSERT INTO historial_cambios (
            id_historial, diagnostico_anterior, diagnostico_nuevo, hash_previo, hash_nuevo
        ) VALUES (
            OLD.id_historial,
            OLD.diagnostico,
            NEW.diagnostico,
            SHA2(OLD.diagnostico, 256),
            SHA2(NEW.diagnostico, 256)
        );

        INSERT INTO log_acciones (
            usuario, ip_cliente, terminal, rol_activo,
            accion, tabla, id_afectado, transaccion
        ) VALUES (
            CURRENT_USER(),
            '192.168.0.10',
            'PC-ADMIN',
            'admin',
            'HISTÓRICO: Cambio de diagnóstico',
            'historial_clinico',
            OLD.id_historial,
            CONCAT('UPDATE diagnóstico historial ID=', OLD.id_historial)
        );
    END IF;
END $$
DELIMITER ;
-- PRUEBA:
UPDATE historial_clinico SET diagnostico = 'Nuevo diagnóstico' WHERE id_historial = 1;
select * from historial_clinico;
SELECT * FROM log_acciones ORDER BY fecha DESC;

SELECT * FROM r_notificaciones ORDER BY fecha DESC;

SELECT * FROM historial_cambios ORDER BY fecha_cambio DESC;

-- INDICES Y OPTIMIZACIÓN
-- ÍNDICES 
-- Marcar tiempo inicio

SET @start_time = NOW();
SELECT * FROM citas WHERE paciente_id = 5 ORDER BY fecha DESC;
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_consulta_citas_antes;
CREATE INDEX idx_pacientes_nombre ON pacientes(nombre);

SET @start_time = NOW();
SELECT * FROM citas WHERE paciente_id = 5 ORDER BY fecha DESC;
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_consulta_citas_despues;

SET @start_time = NOW();
SELECT * FROM pacientes ORDER BY nombre;
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_consulta_pacientes_antes;

CREATE INDEX idx_medicos_especialidad ON medicos(especialidad_id);

SET @start_time = NOW();
SELECT * FROM medicos WHERE especialidad_id = 3;
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_consulta_medicos;

CREATE INDEX idx_citas_fecha ON citas(fecha);

SET @start_time = NOW();
SELECT * FROM citas ORDER BY fecha DESC;
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_consulta_citas_fecha;

CREATE INDEX idx_citas_paciente ON citas(paciente_id);
SET @start_time = NOW();
SELECT * FROM citas WHERE paciente_id = 5;
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_consulta_citas_final;


-- ÍNDICES COMPUESTOS
-- 1. Índice compuesto en citas(paciente_id, fecha)
-- Mejora consultas que buscan citas de un paciente ordenadas o filtradas por fecha.
CREATE INDEX idx_citas_paciente_fecha ON citas(paciente_id, fecha);
SET @start_time = NOW();
SELECT * FROM citas
WHERE paciente_id = 5 AND fecha >= CURDATE();
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_citas_paciente_fecha;
EXPLAIN SELECT * FROM citas
WHERE paciente_id = 5 AND fecha >= CURDATE();

-- 2. Índice compuesto en historial_clinico(paciente_id, fecha_registro)
-- Mejora consultas que buscan el historial clínico de un paciente en orden cronológico.
CREATE INDEX idx_historial_paciente_fecha ON historial_clinico(paciente_id, fecha_registro);

SET @start_time = NOW();
SELECT * FROM historial_clinico
WHERE paciente_id = 2 AND fecha_registro > '2024-01-01';
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_historial_paciente_fecha;

EXPLAIN SELECT * FROM historial_clinico
WHERE paciente_id = 2 AND fecha_registro > '2024-01-01';

-- 3. Índice compuesto en detalle_receta(receta_id, medicamento_id)
-- Mejora consultas que buscan medicamentos dentro de una receta específica.
-- Tiempo antes de crear el índice
SET @start_time = NOW();
SELECT * FROM detalle_receta 
WHERE receta_id = 10 AND medicamento_id = 5;
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_antes;
CREATE INDEX idx_detalle_receta ON detalle_receta(receta_id, medicamento_id);
SET @start_time = NOW();
SELECT * FROM detalle_receta 
WHERE receta_id = 10 AND medicamento_id = 5;
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_despues;

EXPLAIN SELECT * FROM detalle_receta 
WHERE receta_id = 10 AND medicamento_id = 5;


-- 4. Índice compuesto en log_acciones(usuario, fecha)
-- Mejora consultas que buscan acciones de un usuario ordenadas por fecha.
-- Tiempo antes de crear el índice
SET @start_time = NOW();
SELECT * FROM log_acciones 
WHERE usuario = 'admin' 
ORDER BY fecha DESC;
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_antes;

CREATE INDEX idx_log_usuario_fecha ON log_acciones(usuario, fecha);

SET @start_time = NOW();
SELECT * FROM log_acciones 
WHERE usuario = 'admin' 
ORDER BY fecha DESC;
SELECT TIMEDIFF(NOW(), @start_time) AS tiempo_despues;

EXPLAIN SELECT * FROM log_acciones 
WHERE usuario = 'admin' 
ORDER BY fecha DESC;


-- Simular carga con 500+ registros y medir tiempos antes/después de los índices.
-- 1. Insertar 100 pacientes
DELIMITER $$
CREATE PROCEDURE insertar_pacientes_masivos()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 100 DO
        INSERT INTO pacientes (nombre, fecha_nacimiento, genero)
        VALUES (
            CONCAT('Paciente', i),
            DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 20000) DAY),
            IF(RAND() > 0.5, 'M', 'F')
        );
        SET i = i + 1;
    END WHILE;
END $$
DELIMITER ;
-- Ejecutar el procedimiento:
CALL insertar_pacientes_masivos();
SELECT * FROM pacientes ORDER BY id_paciente ;



--  2. Insertar 20 médicos2. Insertar 20 médicos
DELIMITER $$

CREATE PROCEDURE insertar_medicos_masivos()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 20 DO
        INSERT INTO medicos (nombre, cedula, especialidad_id, telefono, correo)
        VALUES (
            CONCAT('Medico', i),
            LPAD(i, 10, '0'), 
            FLOOR(1 + RAND()*5), 
            CONCAT('09', FLOOR(10000000 + RAND()*89999999)), 
            CONCAT('medico', i, '@hospital.com') 
        );
        SET i = i + 1;
    END WHILE;
END $$
DELIMITER ;
CALL insertar_medicos_masivos();
select * from medicos ;



-- Insertar 500 citas
DELIMITER $$
CREATE PROCEDURE insertar_pacientes_masivos()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 100 DO
        INSERT INTO pacientes (nombre, fecha_nacimiento, genero, telefono, direccion, correo)
        VALUES (
            CONCAT('Paciente', i),
            DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*20000) DAY),
            IF(RAND() > 0.5, 'M', 'F'),
            CONCAT('09', FLOOR(10000000 + RAND()*89999999)),
            CONCAT('Dirección del paciente ', i),
            CONCAT('paciente', i, '@correo.com')
        );
        SET i = i + 1;
    END WHILE;
END $$
DELIMITER ;
CALL insertar_pacientes_masivos();
SELECT * FROM pacientes ORDER BY id_paciente DESC LIMIT 10;

-- Insertar 500 registros en historial clínico
DELIMITER $$
CREATE PROCEDURE insertar_historial_clinico()
BEGIN
    DECLARE i INT DEFAULT 1;DECLARE total_pacientes INT;
    DECLARE paciente_valido INT;
    SELECT COUNT(*) INTO total_pacientes FROM pacientes;
    WHILE i <= 500 DO
        SELECT id_paciente
        INTO paciente_valido
        FROM pacientes
        ORDER BY RAND()
        LIMIT 1;
        INSERT INTO historial_clinico (paciente_id,
            fecha_registro,diagnostico,
            tratamiento,observaciones
        ) VALUES (
            paciente_valido,
            DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*365) DAY),
            CONCAT('Diagnóstico prueba ', i),
            CONCAT('Tratamiento prueba ', i),
            CONCAT('Observación prueba ', i));SET i = i + 1;
    END WHILE;
END $$
DELIMITER ;
CALL insertar_historial_clinico();
SELECT * FROM historial_clinico ORDER BY id_historial DESC LIMIT 10;

-- SEGURIDAD Y ROLES 
-- 1. CREACIÓN DE ROLES PERSONALIZADOS
CREATE ROLE administrador;
CREATE ROLE auditor;
CREATE ROLE operador;
CREATE ROLE cliente;
CREATE ROLE proveedor;
CREATE ROLE usuario_final;

-- 2. CREACIÓN DE USUARIOS Y ASIGNACIÓN DE ROLES CON NOMBRES PERSONALIZADOS
CREATE USER 'nicolas_chiguano'@'localhost' IDENTIFIED BY 'Nicolas123';
CREATE USER 'melany_perugachi'@'localhost' IDENTIFIED BY 'Melany123';
CREATE USER 'usuario_1'@'localhost' IDENTIFIED BY '1234';

GRANT administrador TO 'nicolas_chiguano'@'localhost';
GRANT auditor TO 'melany_perugachi'@'localhost';
GRANT operador TO 'usuario_1'@'localhost';

-- Activar rol por defecto
SET DEFAULT ROLE ALL TO 'nicolas_chiguano'@'localhost';

-- 3. ASIGNACIÓN DE PRIVILEGIOS CON GRANT
GRANT ALL PRIVILEGES ON hospital.* TO administrador;
GRANT SELECT ON hospital.* TO auditor;
GRANT SELECT, INSERT, UPDATE ON hospital.* TO operador;

-- 4. REVOCACIÓN DE PRIVILEGIOS CON REVOKE
REVOKE INSERT ON hospital.* FROM operador;

-- 5. ENCRIPTACIÓN DEMOSTRATIVA
-- Hash con SHA2 y MD5
SELECT SHA2('contrasena_segura', 256) AS sha256;
SELECT MD5('contrasena_segura') AS md5;

-- Cifrado y descifrado simétrico con AES
SET @clave = 'mi_clave_secreta';
SET @texto = 'diagnostico confidencial';

SET @cifrado = AES_ENCRYPT(@texto, @clave);
SELECT @cifrado;
SELECT AES_DECRYPT(@cifrado, @clave);


-- 6. VALIDACIÓN DE ENTRADAS CON REGEXP
-- Solo nombres con letras y espacios
SELECT 'Juan Perez' REGEXP '^[A-Za-z ]+$' AS valido;
SELECT 'Juan123' REGEXP '^[A-Za-z ]+$' AS invalido;

-- 7. SIMULACIÓN DE INTENTOS FALLIDOS 
CREATE TABLE log_intentos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(50),
    ip_origen VARCHAR(45),
    fecha DATETIME DEFAULT NOW(),
    exito BOOLEAN,
    mensaje TEXT
);

INSERT INTO log_intentos (usuario, ip_origen, exito, mensaje)
VALUES ('usuario_falso', '192.168.1.100', FALSE, 'Contraseña incorrecta');

-- 8. AUDITORÍA DE ROLES Y PRIVILEGIOS
SELECT * FROM information_schema.APPLICABLE_ROLES;
SELECT * FROM information_schema.user_privileges
WHERE grantee LIKE '%nicolas_chiguano%';


