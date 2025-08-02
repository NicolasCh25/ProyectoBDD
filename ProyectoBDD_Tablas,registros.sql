-- PROYECTO
-- Chiguano Meza Nicolás Mauricio, Perugachi Toapanta Melany Brillith
-- HOSPITAL
create database hospital;
use hospital;

-- Tabla especialidades
CREATE TABLE especialidades (
    id_especialidad INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

-- Tabla tipos_consulta
CREATE TABLE tipos_consulta (
    id_tipo_consulta INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    tarifa DECIMAL(10, 2) NOT NULL CHECK (tarifa >= 0)
);

-- Tabla medicamentos
CREATE TABLE medicamentos (
    id_medicamento INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    unidad VARCHAR(20) NOT NULL
);

-- Tabla formas_pago
CREATE TABLE formas_pago (
    id_forma_pago INT AUTO_INCREMENT PRIMARY KEY,
    metodo VARCHAR(50) NOT NULL
);

-- Tabla pacientes
CREATE TABLE pacientes (
    id_paciente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero CHAR(1) NOT NULL CHECK (genero IN ('M', 'F')),
    telefono VARCHAR(20),
    direccion TEXT,
    correo VARCHAR(100) UNIQUE
);

-- Tabla medicos
CREATE TABLE medicos (
    id_medico INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    cedula VARCHAR(20) NOT NULL UNIQUE,
    especialidad_id INT,
    telefono VARCHAR(20),
    correo VARCHAR(100),
    FOREIGN KEY (especialidad_id) REFERENCES especialidades(id_especialidad)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Tabla citas
CREATE TABLE citas (
    id_cita INT AUTO_INCREMENT PRIMARY KEY,
    paciente_id INT NOT NULL,
    medico_id INT,
    tipo_consulta_id INT,
    fecha DATETIME NOT NULL,
    estado VARCHAR(20) DEFAULT 'pendiente',
    FOREIGN KEY (paciente_id) REFERENCES pacientes(id_paciente)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (medico_id) REFERENCES medicos(id_medico)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (tipo_consulta_id) REFERENCES tipos_consulta(id_tipo_consulta)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Tabla historial_clinico
CREATE TABLE historial_clinico (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    paciente_id INT NOT NULL,
    fecha_registro DATE NOT NULL,
    diagnostico TEXT NOT NULL,
    tratamiento TEXT,
    observaciones TEXT,
    FOREIGN KEY (paciente_id) REFERENCES pacientes(id_paciente)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Tabla recetas
CREATE TABLE recetas (
    id_receta INT AUTO_INCREMENT PRIMARY KEY,
    paciente_id INT NOT NULL,
    medico_id INT,
    fecha DATE NOT NULL,
    observacion TEXT,
    FOREIGN KEY (paciente_id) REFERENCES pacientes(id_paciente)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (medico_id) REFERENCES medicos(id_medico)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Tabla detalle_receta
CREATE TABLE detalle_receta (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    receta_id INT NOT NULL,
    medicamento_id INT,
    dosis VARCHAR(100) NOT NULL,
    FOREIGN KEY (receta_id) REFERENCES recetas(id_receta)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (medicamento_id) REFERENCES medicamentos(id_medicamento)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Tabla facturas
CREATE TABLE facturas (
    id_factura INT AUTO_INCREMENT PRIMARY KEY,
    cita_id INT NOT NULL,
    fecha DATETIME NOT NULL,
    total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
    forma_pago_id INT,
    FOREIGN KEY (cita_id) REFERENCES citas(id_cita)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (forma_pago_id) REFERENCES formas_pago(id_forma_pago)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Tabla detalle_factura
CREATE TABLE detalle_factura (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    factura_id INT NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    monto DECIMAL(10, 2) NOT NULL CHECK (monto >= 0),
    FOREIGN KEY (factura_id) REFERENCES facturas(id_factura)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- REGISTROS
-- especialidades
INSERT INTO especialidades (nombre) VALUES
('Cardiología'),
('Neurología'),
('Pediatría'),
('Dermatología'),
('Oncología'),
('Ginecología'),
('Psiquiatría'),
('Oftalmología'),
('Ortopedia'),
('Endocrinología');

-- tipos_consulta
INSERT INTO tipos_consulta (nombre, tarifa) VALUES
('Consulta General', 30.00),
('Consulta Especializada', 50.00),
('Consulta de Urgencia', 70.00),
('Chequeo Preventivo', 40.00),
('Consulta Pediátrica', 35.00),
('Consulta Ginecológica', 55.00),
('Consulta Neurológica', 60.00),
('Consulta Cardiológica', 65.00),
('Consulta Dermatológica', 45.00),
('Consulta Endocrinológica', 50.00);

-- medicamentos
INSERT INTO medicamentos (nombre, unidad) VALUES
('Paracetamol', 'mg'),
('Ibuprofeno', 'mg'),
('Amoxicilina', 'mg'),
('Metformina', 'mg'),
('Omeprazol', 'mg'),
('Loratadina', 'mg'),
('Aspirina', 'mg'),
('Enalapril', 'mg'),
('Simvastatina', 'mg'),
('Azitromicina', 'mg');

-- formas_pago
INSERT INTO formas_pago (metodo) VALUES
('Efectivo'),
('Tarjeta Crédito'),
('Tarjeta Débito'),
('Transferencia Bancaria'),
('Cheque'),
('Pago móvil'),
('PayPal'),
('Criptomonedas'),
('Débito automático'),
('Pago en cuotas');

-- pacientes
INSERT INTO pacientes (nombre, fecha_nacimiento, genero, telefono, direccion, correo) VALUES
('Juan Pérez', '1985-03-15', 'M', '0998765432', 'Av. Siempre Viva 123', 'juan.perez@mail.com'),
('María Gómez', '1990-07-22', 'F', '0987654321', 'Calle Falsa 456', 'maria.gomez@mail.com'),
('Carlos Sánchez', '1978-12-05', 'M', '0976543210', 'Av. Central 789', 'carlos.sanchez@mail.com'),
('Ana Martínez', '2000-01-30', 'F', '0965432109', 'Calle Real 101', 'ana.martinez@mail.com'),
('Luis Fernández', '1995-06-12', 'M', '0954321098', 'Av. Las Flores 202', 'luis.fernandez@mail.com'),
('Sofía Torres', '1988-09-25', 'F', '0943210987', 'Calle Luna 303', 'sofia.torres@mail.com'),
('Miguel Ruiz', '1975-11-17', 'M', '0932109876', 'Av. Sol 404', 'miguel.ruiz@mail.com'),
('Laura Castillo', '1992-04-08', 'F', '0921098765', 'Calle Estrella 505', 'laura.castillo@mail.com'),
('Pedro Morales', '1980-08-20', 'M', '0910987654', 'Av. Mar 606', 'pedro.morales@mail.com'),
('Camila Ríos', '1997-02-14', 'F', '0909876543', 'Calle Río 707', 'camila.rios@mail.com');

-- medicos
INSERT INTO medicos (nombre, cedula, especialidad_id, telefono, correo) VALUES
('Dr. Alberto Díaz', '1234567890', 1, '0999999991', 'alberto.diaz@hospital.com'),
('Dra. Patricia López', '2345678901', 2, '0999999992', 'patricia.lopez@hospital.com'),
('Dr. Ricardo Sánchez', '3456789012', 3, '0999999993', 'ricardo.sanchez@hospital.com'),
('Dra. Laura Pérez', '4567890123', 4, '0999999994', 'laura.perez@hospital.com'),
('Dr. Jorge Ramírez', '5678901234', 5, '0999999995', 'jorge.ramirez@hospital.com'),
('Dra. Marta Gutiérrez', '6789012345', 6, '0999999996', 'marta.gutierrez@hospital.com'),
('Dr. Luis Herrera', '7890123456', 7, '0999999997', 'luis.herrera@hospital.com'),
('Dra. Carmen Morales', '8901234567', 8, '0999999998', 'carmen.morales@hospital.com'),
('Dr. Felipe Vargas', '9012345678', 9, '0999999999', 'felipe.vargas@hospital.com'),
('Dra. Elena Castillo', '0123456789', 10, '0999999990', 'elena.castillo@hospital.com');

-- citas
INSERT INTO citas (paciente_id, medico_id, tipo_consulta_id, fecha, estado) VALUES
(1, 1, 1, '2025-07-01 09:00:00', 'pendiente'),
(2, 2, 2, '2025-07-02 10:00:00', 'pendiente'),
(3, 3, 3, '2025-07-03 11:00:00', 'confirmada'),
(4, 4, 4, '2025-07-04 12:00:00', 'cancelada'),
(5, 5, 5, '2025-07-05 13:00:00', 'pendiente'),
(6, 6, 6, '2025-07-06 14:00:00', 'confirmada'),
(7, 7, 7, '2025-07-07 15:00:00', 'pendiente'),
(8, 8, 8, '2025-07-08 16:00:00', 'pendiente'),
(9, 9, 9, '2025-07-09 17:00:00', 'pendiente'),
(10, 10, 10, '2025-07-10 18:00:00', 'pendiente');

-- historial_clinico
INSERT INTO historial_clinico (paciente_id, fecha_registro, diagnostico, tratamiento, observaciones) VALUES
(1, '2025-06-01', 'Hipertensión', 'Medicamentos antihipertensivos', 'Control mensual'),
(2, '2025-06-05', 'Diabetes tipo 2', 'Insulina', 'Revisión trimestral'),
(3, '2025-06-10', 'Asma', 'Inhaladores', 'Evitar alérgenos'),
(4, '2025-06-15', 'Dermatitis', 'Cremas tópicas', 'Evitar irritantes'),
(5, '2025-06-20', 'Gripe', 'Reposo y medicamentos', 'Control en 7 días'),
(6, '2025-06-25', 'Migraña', 'Analgésicos', 'Revisión neurológica'),
(7, '2025-06-30', 'Artritis', 'Anti-inflamatorios', 'Ejercicios recomendados'),
(8, '2025-07-02', 'Infección urinaria', 'Antibióticos', 'Hidratación adecuada'),
(9, '2025-07-05', 'Hipotiroidismo', 'Levotiroxina', 'Chequeo hormonal'),
(10, '2025-07-07', 'Anemia', 'Suplementos de hierro', 'Control mensual');

-- recetas
INSERT INTO recetas (paciente_id, medico_id, fecha, observacion) VALUES
(1, 1, '2025-07-01', 'Tomar medicamento después de comida'),
(2, 2, '2025-07-02', 'Evitar alimentos grasos'),
(3, 3, '2025-07-03', 'Aplicar crema dos veces al día'),
(4, 4, '2025-07-04', 'Reposo absoluto'),
(5, 5, '2025-07-05', 'Control en 7 días'),
(6, 6, '2025-07-06', 'No automedicarse'),
(7, 7, '2025-07-07', 'Hidratación constante'),
(8, 8, '2025-07-08', 'Evitar sol directo'),
(9, 9, '2025-07-09', 'Control endocrinológico'),
(10, 10, '2025-07-10', 'Seguir dieta recomendada');

-- detalle_receta
INSERT INTO detalle_receta (receta_id, medicamento_id, dosis) VALUES
(1, 1, '500 mg cada 8 horas'),
(1, 2, '200 mg cada 12 horas'),
(2, 3, '250 mg cada 8 horas'),
(3, 4, '850 mg cada 24 horas'),
(4, 5, '20 mg cada 12 horas'),
(5, 6, '10 mg cada 24 horas'),
(6, 7, '100 mg cada 8 horas'),
(7, 8, '5 mg cada 12 horas'),
(8, 9, '20 mg cada 24 horas'),
(9, 10, '500 mg cada 24 horas');

-- facturas
INSERT INTO facturas (cita_id, fecha, total, forma_pago_id) VALUES
(1, '2025-07-01 10:00:00', 80.00, 1),
(2, '2025-07-02 11:00:00', 100.00, 2),
(3, '2025-07-03 12:00:00', 120.00, 3),
(4, '2025-07-04 13:00:00', 70.00, 4),
(5, '2025-07-05 14:00:00', 90.00, 5),
(6, '2025-07-06 15:00:00', 110.00, 6),
(7, '2025-07-07 16:00:00', 130.00, 7),
(8, '2025-07-08 17:00:00', 85.00, 8),
(9, '2025-07-09 18:00:00', 95.00, 9),
(10, '2025-07-10 19:00:00', 105.00, 10);

-- detalle_factura
INSERT INTO detalle_factura (factura_id, descripcion, monto) VALUES
(1, 'Consulta General', 30.00),
(1, 'Medicamentos', 50.00),
(2, 'Consulta Especializada', 50.00),
(2, 'Medicamentos', 50.00),
(3, 'Consulta de Urgencia', 70.00),
(3, 'Medicamentos', 50.00),
(4, 'Chequeo Preventivo', 40.00),
(4, 'Medicamentos', 30.00),
(5, 'Consulta Pediátrica', 35.00),
(5, 'Medicamentos', 55.00);


