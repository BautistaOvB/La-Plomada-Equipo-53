-- =======================================================
-- SCRIPT DML: INSERCIÓN DE DATOS DE PRUEBA (MOCK DATA)
-- =======================================================

USE La_Plomada_db;
GO

-- 1. Inserción de Usuarios (Debe ir ANTES que direcciones y carritos)
INSERT INTO usuario (email, rol, nombre, apellido, contrasena) VALUES
('cliente1@mail.com', 'cliente', 'Juan', 'Perez', 'hash123'),
('cliente2@mail.com', 'cliente', 'Maria', 'Gomez', 'hash123'),
('cliente3@mail.com', 'cliente', 'Luis', 'Fernandez', 'hash123'),
('cliente4@mail.com', 'cliente', 'Ana', 'Martinez', 'hash123'),
('cliente5@mail.com', 'cliente', 'Pedro', 'Sanchez', 'hash123'),
('cliente6@mail.com', 'cliente', 'Laura', 'Diaz', 'hash123'),
('cliente7@mail.com', 'cliente', 'Diego', 'Lopez', 'hash123'),
('admin1@mail.com', 'administrador', 'Carlos', 'Ruiz', 'hash123');

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

-- 3. Inserción de Direcciones (Ahora sí, usuarios ya existen)
INSERT INTO direccion (id_ciudad, id_usuario) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(1, 5);

-- 4. Inserción de 8 Categorías
INSERT INTO categoria (nombre) VALUES
('Calzado'),
('Ropa Superior'),
('Ropa Inferior'),
('Accesorios'),
('Deportes'),
('Tecnología'),
('Hogar'),
('Equipaje');

-- 5. Inserción de 8 Productos asociados a las categorías
INSERT INTO producto (nombre, id_categoria) VALUES
('Zapatillas Running Pro', 1),
('Camiseta Básica de Algodón', 2),
('Pantalón Jean Slim Fit', 3),
('Reloj Cronógrafo Deportivo', 4),
('Mat de Yoga Antideslizante', 5),
('Auriculares Inalámbricos Bluetooth', 6),
('Lámpara de Escritorio LED', 7),
('Mochila Urbana Impermeable', 8);

-- 6. Inserción de 8 Variantes de Producto
INSERT INTO var_producto (url_img, stock, descripcion, precio, id_producto) VALUES
('https://img.ejemplo.com/calzado/running-negro-42.jpg', 25, 'Talle 42 - Color Negro con suela blanca', 89.99, 1),
('https://img.ejemplo.com/ropa/camiseta-blanca-m.jpg', 60, 'Talle M - Color Blanco 100% algodón', 19.50, 2),
('https://img.ejemplo.com/ropa/jean-azul-32.jpg', 30, 'Talle 32 - Azul Clásico lavado suave', 49.00, 3),
('https://img.ejemplo.com/accesorios/reloj-cuero-marron.jpg', 15, 'Malla de cuero marrón, caja de acero', 120.00, 4),
('https://img.ejemplo.com/deportes/mat-yoga-morado.jpg', 40, 'Espesor 6mm - Color Morado con correa', 29.90, 5),
('https://img.ejemplo.com/tecno/auriculares-negro-anc.jpg', 50, 'Cancelación activa de ruido - Color Negro', 75.00, 6),
('https://img.ejemplo.com/hogar/lampara-led-blanca.jpg', 20, 'Luz cálida/fría regulable - Táctil', 34.80, 7),
('https://img.ejemplo.com/equipaje/mochila-gris-20l.jpg', 35, 'Capacidad 20L - Compartimento para notebook', 45.00, 8);

-- 7. Inserción de Carritos (Nombres corregidos al DDL)
INSERT INTO carrito (id_usuario) VALUES (1), (2), (3), (4), (5), (6), (7), (8);

-- 8. Inserción de Detalle de Carritos (Nombres corregidos al DDL)
INSERT INTO detalle_carrito (carrito_id, var_producto_id, cantidad) VALUES 
(1, 1, 2), 
(1, 2, 1), 
(2, 3, 1), 
(3, 4, 1), 
(4, 5, 3), 
(5, 6, 1), 
(6, 7, 2), 
(7, 8, 1);

-- 9. Inserción de Compras (Nombres corregidos al DDL)
INSERT INTO compra (id_usuario, id_direccion, metodo_pago, retiro_sucursal, total, estado, fecha_compra) VALUES 
(1, 1, 'TARJETA', 0, 45000.00, 'ENTREGADO', '2026-08-01'),
(2, 2, 'EFECTIVO', 0, 18500.00, 'ENVIADO', '2026-08-05'),
(3, 3, 'TRANSFERENCIA', 0, 92300.00, 'PAGADO', '2026-08-10'),
(4, 4, 'TARJETA', 0, 12000.00, 'PENDIENTE', '2026-08-12'),
(5, 5, 'TARJETA', 0, 67000.00, 'PENDIENTE', '2026-08-15'),
(6, NULL, 'EFECTIVO', 1, 8900.00, 'ENTREGADO', '2026-08-03'),
(7, NULL, 'TARJETA', 1, 34500.00, 'PAGADO', '2026-08-08'),
(1, NULL, 'TRANSFERENCIA', 1, 15800.00, 'ENVIADO', '2026-08-14');

-- 10. Inserción de Detalle de Compras (IDs válidos)
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

--edito productos

------------------------------------------------------------------------
-- 1. Categorias de pesca (solo las que todavia no existen)
------------------------------------------------------------------------
INSERT INTO categoria (nombre)
SELECT v.nombre
FROM (VALUES
    ('Cañas'),
    ('Reeles'),
    ('Señuelos'),
    ('Líneas y anzuelos'),
    ('Accesorios'),
    ('Indumentaria'),
    ('Plomadas y boyas'),
    ('Camping y conservación')
) v(nombre)
WHERE NOT EXISTS (SELECT 1 FROM categoria c WHERE c.nombre = v.nombre);

------------------------------------------------------------------------
-- 2. Productos: nuevo nombre y nueva categoria
------------------------------------------------------------------------
UPDATE p
SET p.nombre       = v.nombre_nuevo,
    p.id_categoria = (SELECT MIN(id_categoria) FROM categoria WHERE nombre = v.categoria)
FROM producto p
JOIN (VALUES
    ('Zapatillas Running Pro', 'Señuelo Popper de Superficie 7 cm', 'Señuelos'),
    ('Camiseta Básica de Algodón', 'Conservadora Térmica 12 L', 'Camping y conservación'),
    ('Pantalón Jean Slim Fit', 'Plomadas Pack x6 (30 g)', 'Plomadas y boyas'),
    ('Reloj Cronógrafo Deportivo', 'Botas de Vadeo Impermeables', 'Indumentaria'),
    ('Mat de Yoga Antideslizante', 'Línea Fluorocarbono 0,25 mm', 'Líneas y anzuelos'),
    ('Auriculares Inalámbricos Bluetooth', 'Boyas Pack x5', 'Plomadas y boyas'),
    ('Lámpara de Escritorio LED', 'Caña Surfcasting 4,20 m', 'Cañas'),
    ('Mochila Urbana Impermeable', 'Giratorios Pack x20', 'Líneas y anzuelos')
) v(nombre_viejo, nombre_nuevo, categoria) ON p.nombre = v.nombre_viejo;

------------------------------------------------------------------------
-- 3. Variantes: nueva imagen, descripcion y precio vigente
------------------------------------------------------------------------
UPDATE vp
SET vp.url_img     = v.url_nueva,
    vp.descripcion = v.descripcion,
    vp.precio      = v.precio
FROM var_producto vp
JOIN (VALUES
    ('https://img.ejemplo.com/calzado/running-negro-42.jpg', 'https://img.ejemplo.com/senuelos/popper-7cm.jpg', 'Popper de superficie 7 cm, color plateado', 7900.00),
    ('https://img.ejemplo.com/ropa/camiseta-blanca-m.jpg', 'https://img.ejemplo.com/camping/conservadora-12l.jpg', 'Conservadora térmica de 12 litros, color azul', 11500.00),
    ('https://img.ejemplo.com/ropa/jean-azul-32.jpg', 'https://img.ejemplo.com/plomadas-boyas/plomadas-30g.jpg', 'Pack de 6 plomadas de 30 g', 3700.00),
    ('https://img.ejemplo.com/accesorios/reloj-cuero-marron.jpg', 'https://img.ejemplo.com/indumentaria/botas-vadeo.jpg', 'Botas de vadeo impermeables, suela antideslizante', 85000.00),
    ('https://img.ejemplo.com/deportes/mat-yoga-morado.jpg', 'https://img.ejemplo.com/lineas/fluoro-025.jpg', 'Fluorocarbono 0,25 mm x 100 m', 7300.00),
    ('https://img.ejemplo.com/tecno/auriculares-negro-anc.jpg', 'https://img.ejemplo.com/plomadas-boyas/boyas-pack-5.jpg', 'Pack de 5 boyas de colores', 4000.00),
    ('https://img.ejemplo.com/hogar/lampara-led-blanca.jpg', 'https://img.ejemplo.com/canas/surfcasting-420.jpg', 'Caña surfcasting 4,20 m, 3 tramos', 62000.00),
    ('https://img.ejemplo.com/equipaje/mochila-gris-20l.jpg', 'https://img.ejemplo.com/lineas/giratorios-x20.jpg', 'Pack de 20 giratorios con mosquetón', 5000.00)
) v(url_vieja, url_nueva, descripcion, precio) ON vp.url_img = v.url_vieja;

------------------------------------------------------------------------
-- 4. Control: tienen que estar los 8 productos convertidos
------------------------------------------------------------------------
IF (SELECT COUNT(*) FROM producto WHERE nombre IN ('Señuelo Popper de Superficie 7 cm', 'Conservadora Térmica 12 L', 'Plomadas Pack x6 (30 g)', 'Botas de Vadeo Impermeables', 'Línea Fluorocarbono 0,25 mm', 'Boyas Pack x5', 'Caña Surfcasting 4,20 m', 'Giratorios Pack x20')) <> 8
    THROW 50001, 'No se encontraron los 8 productos originales: no se convirtio nada. Revisar nombres en la tabla producto.', 1;

------------------------------------------------------------------------
-- 5. Borrar las categorias viejas que quedaron sin productos
------------------------------------------------------------------------
DELETE c
FROM categoria c
WHERE c.nombre IN ('Calzado', 'Ropa Superior', 'Ropa Inferior', 'Deportes', 'Tecnología', 'Hogar', 'Equipaje')
  AND NOT EXISTS (SELECT 1 FROM producto p WHERE p.id_categoria = c.id_categoria);