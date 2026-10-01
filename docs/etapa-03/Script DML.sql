USE La_Plomada_db;
GO
-- 1. Inserción de 8 Categorías
INSERT INTO Categoria (nombre_categoria) VALUES
('Calzado'),
('Ropa Superior'),
('Ropa Inferior'),
('Accesorios'),
('Deportes'),
('Tecnología'),
('Hogar'),
('Equipaje');

-- 2. Inserción de 8 Productos asociados a las categorías
INSERT INTO Producto (nombre_producto, id_Categoria) VALUES
('Zapatillas Running Pro', 1),
('Camiseta Básica de Algodón', 2),
('Pantalón Jean Slim Fit', 3),
('Reloj Cronógrafo Deportivo', 4),
('Mat de Yoga Antideslizante', 5),
('Auriculares Inalámbricos Bluetooth', 6),
('Lámpara de Escritorio LED', 7),
('Mochila Urbana Impermeable', 8);

-- 3. Inserción de 8 Variantes de Producto asociadas a los productos
INSERT INTO Var_Producto (url_image, stock, descripcion, precio, id_Producto) VALUES
('https://img.ejemplo.com/calzado/running-negro-42.jpg', 25, 'Talle 42 - Color Negro con suela blanca', 89.99, 1),
('https://img.ejemplo.com/ropa/camiseta-blanca-m.jpg', 60, 'Talle M - Color Blanco 100% algodón', 19.50, 2),
('https://img.ejemplo.com/ropa/jean-azul-32.jpg', 30, 'Talle 32 - Azul Clásico lavado suave', 49.00, 3),
('https://img.ejemplo.com/accesorios/reloj-cuero-marron.jpg', 15, 'Malla de cuero marrón, caja de acero', 120.00, 4),
('https://img.ejemplo.com/deportes/mat-yoga-morado.jpg', 40, 'Espesor 6mm - Color Morado con correa', 29.90, 5),
('https://img.ejemplo.com/tecno/auriculares-negro-anc.jpg', 50, 'Cancelación activa de ruido - Color Negro', 75.00, 6),
('https://img.ejemplo.com/hogar/lampara-led-blanca.jpg', 20, 'Luz cálida/fría regulable - Táctil', 34.80, 7),
('https://img.ejemplo.com/equipaje/mochila-gris-20l.jpg', 35, 'Capacidad 20L - Compartimento para notebook', 45.00, 8);
-- 2. Inserción de Provincias y Ciudades (Requerido para las direcciones)
INSERT INTO provincia (nombre) VALUES 
('Buenos Aires'), 
('Córdoba'), 
('Santa Fe');

INSERT INTO ciudad (id_provincia, codigo_postal, nombre) VALUES
(1, '1000', 'CABA'),
(1, '7600', 'Mar del Plata'),
(2, '5000', 'Córdoba Capital'),
(3, '2000', 'Rosario');

-- 3. Inserción de Direcciones
INSERT INTO direccion (id_ciudad, id_usuario) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(1, 5);

-- 1. Inserción de Usuarios (Requerido para poder hacer compras y carritos)
INSERT INTO usuario (email, rol, nombre, apellido, contrasena) VALUES
('cliente1@mail.com', 'cliente', 'Juan', 'Perez', 'hash123'),
('cliente2@mail.com', 'cliente', 'Maria', 'Gomez', 'hash123'),
('cliente3@mail.com', 'cliente', 'Luis', 'Fernandez', 'hash123'),
('cliente4@mail.com', 'cliente', 'Ana', 'Martinez', 'hash123'),
('cliente5@mail.com', 'cliente', 'Pedro', 'Sanchez', 'hash123'),
('cliente6@mail.com', 'cliente', 'Laura', 'Diaz', 'hash123'),
('cliente7@mail.com', 'cliente', 'Diego', 'Lopez', 'hash123'),
('admin1@mail.com', 'administrador', 'Carlos', 'Ruiz', 'hash123');

-- Carga de datos de carritos
INSERT INTO carritos (user_id) VALUES (1), (2), (3), (4), (5), (6), (7), (8);
-- Carga de datos de  detalle carritos
INSERT INTO detalle_carritos (carrito_id, var_productos_id, cantidad) 
VALUES 
    (1, 1, 2), 
    (1, 2, 1), 
    (2, 3, 1), 
    (3, 4, 1), 
    (4, 5, 3), 
    (5, 6, 1), 
    (6, 7, 2), 
    (7, 8, 1);

INSERT INTO compras (user_id, direccion_id, metodo_pago, retiro_sucursal, total, estado, fecha_compra)
VALUES (1, 1, 'TARJETA', 0, 45000.00, 'ENTREGADO', '2026-08-01'),
        (2, 2, 'EFECTIVO', 0, 18500.00, 'ENVIADO', '2026-08-05'),
        (3, 3, 'TRANSFERENCIA', 0, 92300.00, 'PAGADO', '2026-08-10'),
        (4, 4, 'TARJETA', 0, 12000.00, 'EN_PREPARACION', '2026-08-12'),
        (5, 5, 'TARJETA', 0, 67000.00, 'PENDIENTE', '2026-08-15'),
        (6, NULL, 'EFECTIVO', 1, 8900.00, 'ENTREGADO', '2026-08-03'),
        (7, NULL, 'TARJETA', 1, 34500.00, 'PAGADO', '2026-08-08'),
        (1, NULL, 'TRANSFERENCIA', 1, 15800.00, 'ENVIADO', '2026-08-14');

-- 8. Inserción de Detalle de Compras (Ajustado para usar IDs existentes)
INSERT INTO detalle_compras (id_compra, id_varProductos, cantidad, precio_unitario) VALUES 
(1, 1, 2, 15000.00),
(1, 2, 1, 15000.00),
(2, 3, 5, 3700.00),
(3, 4, 1, 85000.00),
(3, 5, 1, 7300.00),
(4, 6, 3, 4000.00),
(5, 7, 1, 62000.00),
(5, 8, 1, 5000.00),
(6, 1, 1, 8900.00), 
(7, 2, 3, 11500.00), 
(8, 1, 2, 7900.00);


