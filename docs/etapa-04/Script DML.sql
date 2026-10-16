USE La_Plomada_db;
GO

SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM usuario WHERE email = 'admin.plomada@example.com')
    THROW 50000, 'Este script ya se ejecuto: los datos ya existen.', 1;

BEGIN TRANSACTION;

------------------------------------------------------------------------
-- 1. Provincias y ciudades
------------------------------------------------------------------------
INSERT INTO provincia (nombre)
SELECT v.nombre
FROM (VALUES
    ('Corrientes'),
    ('Misiones'),
    ('Chaco'),
    ('Entre Ríos'),
    ('Santa Fe')
) v(nombre)
WHERE NOT EXISTS (SELECT 1 FROM provincia p WHERE p.nombre = v.nombre);

INSERT INTO ciudad (id_provincia, codigo_postal, nombre)
SELECT (SELECT MIN(id_provincia) FROM provincia WHERE nombre = v.provincia),
       v.codigo_postal, v.nombre
FROM (VALUES
    ('Corrientes', '3400', 'Corrientes'),
    ('Corrientes', '3450', 'Goya'),
    ('Misiones', '3300', 'Posadas'),
    ('Misiones', '3360', 'Oberá'),
    ('Chaco', '3500', 'Resistencia'),
    ('Entre Ríos', '3100', 'Paraná'),
    ('Entre Ríos', '3200', 'Concordia'),
    ('Santa Fe', '3000', 'Santa Fe')
) v(provincia, codigo_postal, nombre)
WHERE NOT EXISTS (SELECT 1 FROM ciudad c WHERE c.nombre = v.nombre);

------------------------------------------------------------------------
-- 2. Usuarios (1 administrador y 11 clientes) y sus direcciones
--    La contrasena es un texto de ejemplo: con estos usuarios no se puede
--    iniciar sesion en la aplicacion.
------------------------------------------------------------------------
INSERT INTO usuario (email, rol, nombre, apellido, contrasena)
SELECT v.email, v.rol, v.nombre, v.apellido, '$2y$10$ejemplo.solo.para.pruebas'
FROM (VALUES
    ('admin.plomada@example.com', 'administrador', 'Marcos', 'Benítez'),
    ('lucia.fernandez@example.com', 'cliente', 'Lucía', 'Fernández'),
    ('martin.gomez@example.com', 'cliente', 'Martín', 'Gómez'),
    ('sofia.ramirez@example.com', 'cliente', 'Sofía', 'Ramírez'),
    ('diego.acosta@example.com', 'cliente', 'Diego', 'Acosta'),
    ('valentina.rojas@example.com', 'cliente', 'Valentina', 'Rojas'),
    ('federico.molina@example.com', 'cliente', 'Federico', 'Molina'),
    ('camila.suarez@example.com', 'cliente', 'Camila', 'Suárez'),
    ('julieta.paz@example.com', 'cliente', 'Julieta', 'Paz'),
    ('emiliano.cabrera@example.com', 'cliente', 'Emiliano', 'Cabrera'),
    ('agustina.silva@example.com', 'cliente', 'Agustina', 'Silva'),
    ('ramon.duarte@example.com', 'cliente', 'Ramón', 'Duarte')
) v(email, rol, nombre, apellido);

INSERT INTO direccion (id_ciudad, id_usuario)
SELECT (SELECT MIN(id_ciudad) FROM ciudad WHERE nombre = v.ciudad),
       u.id_usuario
FROM (VALUES
    ('lucia.fernandez@example.com', 'Corrientes'),
    ('martin.gomez@example.com', 'Goya'),
    ('martin.gomez@example.com', 'Corrientes'),
    ('sofia.ramirez@example.com', 'Posadas'),
    ('diego.acosta@example.com', 'Resistencia'),
    ('valentina.rojas@example.com', 'Paraná'),
    ('federico.molina@example.com', 'Oberá'),
    ('camila.suarez@example.com', 'Santa Fe'),
    ('julieta.paz@example.com', 'Concordia'),
    ('emiliano.cabrera@example.com', 'Corrientes'),
    ('agustina.silva@example.com', 'Posadas'),
    ('ramon.duarte@example.com', 'Goya')
) v(email, ciudad)
JOIN usuario u ON u.email = v.email;

------------------------------------------------------------------------
-- 3. Categorias, productos y variantes
--    La url_img de cada variante se usa como clave para buscarla despues.
------------------------------------------------------------------------
INSERT INTO categoria (nombre)
SELECT v.nombre
FROM (VALUES
    ('Cañas'),
    ('Reeles'),
    ('Señuelos'),
    ('Líneas y anzuelos'),
    ('Accesorios'),
    ('Indumentaria')
) v(nombre)
WHERE NOT EXISTS (SELECT 1 FROM categoria c WHERE c.nombre = v.nombre);

INSERT INTO producto (nombre, id_categoria)
SELECT v.nombre,
       (SELECT MIN(id_categoria) FROM categoria WHERE nombre = v.categoria)
FROM (VALUES
    ('Caña Spinning Titanium', 'Cañas'),
    ('Caña Telescópica Río', 'Cañas'),
    ('Reel Frontal Pro', 'Reeles'),
    ('Reel Rotativo Baitcast', 'Reeles'),
    ('Señuelo Cuchara Plateada', 'Señuelos'),
    ('Señuelo Minnow Flotante', 'Señuelos'),
    ('Pack de Vinilos', 'Señuelos'),
    ('Línea Multifilamento', 'Líneas y anzuelos'),
    ('Anzuelos Pack x10', 'Líneas y anzuelos'),
    ('Caja de Pesca', 'Accesorios'),
    ('Pinza Multiuso', 'Accesorios'),
    ('Soporte de Caña', 'Accesorios'),
    ('Campera Impermeable', 'Indumentaria'),
    ('Gorra con Visera UV', 'Indumentaria')
) v(nombre, categoria)
WHERE NOT EXISTS (SELECT 1 FROM producto p WHERE p.nombre = v.nombre);

INSERT INTO var_producto (url_img, stock, precio, descripcion, id_producto)
SELECT v.url_img, v.stock, v.precio, v.descripcion,
       (SELECT MIN(id_producto) FROM producto WHERE nombre = v.producto)
FROM (VALUES
    ('cana_spin_180.jpg', 25, 42000.00, 'Caña spinning fibra de carbono 1,80 m', 'Caña Spinning Titanium'),
    ('cana_spin_210.jpg', 30, 48500.00, 'Caña spinning fibra de carbono 2,10 m', 'Caña Spinning Titanium'),
    ('cana_tele_270.jpg', 20, 36000.00, 'Caña telescópica 2,70 m', 'Caña Telescópica Río'),
    ('reel_4000.jpg', 18, 62000.00, 'Reel frontal 4000, 5 rulemanes', 'Reel Frontal Pro'),
    ('reel_6000.jpg', 12, 79000.00, 'Reel frontal 6000, 7 rulemanes', 'Reel Frontal Pro'),
    ('reel_baitcast.jpg', 10, 95000.00, 'Reel rotativo baitcast, 8 rulemanes', 'Reel Rotativo Baitcast'),
    ('sen_cuchara_15.jpg', 80, 6500.00, 'Cuchara plateada 15 g', 'Señuelo Cuchara Plateada'),
    ('sen_cuchara_25.jpg', 60, 7800.00, 'Cuchara plateada 25 g', 'Señuelo Cuchara Plateada'),
    ('sen_minnow_9.jpg', 50, 9200.00, 'Minnow flotante 9 cm', 'Señuelo Minnow Flotante'),
    ('sen_vinilo_pack.jpg', 90, 5400.00, 'Pack de 6 vinilos de colores', 'Pack de Vinilos'),
    ('lin_multi_020.jpg', 40, 18500.00, 'Multifilamento 0,20 mm x 150 m', 'Línea Multifilamento'),
    ('lin_multi_030.jpg', 35, 22900.00, 'Multifilamento 0,30 mm x 150 m', 'Línea Multifilamento'),
    ('anz_pack_6.jpg', 120, 3500.00, 'Pack de 10 anzuelos nº 6', 'Anzuelos Pack x10'),
    ('anz_pack_2.jpg', 100, 3900.00, 'Pack de 10 anzuelos nº 2', 'Anzuelos Pack x10'),
    ('acc_caja.jpg', 22, 24500.00, 'Caja de pesca de 3 bandejas', 'Caja de Pesca'),
    ('acc_pinza.jpg', 45, 11800.00, 'Pinza multiuso de acero inoxidable', 'Pinza Multiuso'),
    ('acc_soporte.jpg', 15, 15500.00, 'Soporte para caña de apoyo en tierra', 'Soporte de Caña'),
    ('ind_campera_m.jpg', 14, 78000.00, 'Campera impermeable talle M', 'Campera Impermeable'),
    ('ind_campera_l.jpg', 14, 78000.00, 'Campera impermeable talle L', 'Campera Impermeable'),
    ('ind_gorra.jpg', 60, 9800.00, 'Gorra con visera y protección UV', 'Gorra con Visera UV')
) v(url_img, stock, precio, descripcion, producto)
WHERE NOT EXISTS (SELECT 1 FROM var_producto x WHERE x.url_img = v.url_img);

------------------------------------------------------------------------
-- 4. Compras
--    - Retiro en sucursal (retiro = 1): id_direccion queda en NULL (RN.21).
--    - Con envio (retiro = 0): se usa una direccion del propio cliente.
--    - El total queda en NULL por ahora: se calcula en el paso 6.
------------------------------------------------------------------------
INSERT INTO compra (estado, total, metodo_pago, retiro_sucursal, id_direccion, id_usuario, fecha_compra)
SELECT v.estado,
       NULL,
       v.metodo_pago,
       v.retiro,
       CASE WHEN v.retiro = 1 THEN NULL
            ELSE (SELECT MIN(d.id_direccion) FROM direccion d WHERE d.id_usuario = u.id_usuario)
       END,
       u.id_usuario,
       CONVERT(datetime, v.fecha, 126)
FROM (VALUES
    ('2026-08-04T10:15:00', 'lucia.fernandez@example.com', 'ENTREGADO', 'TARJETA', 0),
    ('2026-08-06T16:40:00', 'martin.gomez@example.com', 'ENTREGADO', 'EFECTIVO', 1),
    ('2026-08-11T09:25:00', 'sofia.ramirez@example.com', 'ENTREGADO', 'TRANSFERENCIA', 0),
    ('2026-08-19T18:05:00', 'lucia.fernandez@example.com', 'ENTREGADO', 'TARJETA', 0),
    ('2026-08-22T11:30:00', 'diego.acosta@example.com', 'ENTREGADO', 'TARJETA', 1),
    ('2026-08-27T20:10:00', 'valentina.rojas@example.com', 'CANCELADO', 'TRANSFERENCIA', 0),
    ('2026-09-02T17:42:00', 'martin.gomez@example.com', 'ENTREGADO', 'TARJETA', 0),
    ('2026-09-05T12:20:00', 'federico.molina@example.com', 'ENTREGADO', 'EFECTIVO', 1),
    ('2026-09-09T15:55:00', 'camila.suarez@example.com', 'ENTREGADO', 'TRANSFERENCIA', 0),
    ('2026-09-12T10:05:00', 'sofia.ramirez@example.com', 'ENTREGADO', 'TARJETA', 0),
    ('2026-09-16T19:15:00', 'diego.acosta@example.com', 'ENTREGADO', 'TARJETA', 0),
    ('2026-09-18T13:35:00', 'julieta.paz@example.com', 'ENTREGADO', 'EFECTIVO', 1),
    ('2026-09-21T08:50:00', 'emiliano.cabrera@example.com', 'ENTREGADO', 'TARJETA', 0),
    ('2026-09-25T21:00:00', 'martin.gomez@example.com', 'ENTREGADO', 'TARJETA', 0),
    ('2026-09-28T14:12:00', 'camila.suarez@example.com', 'CANCELADO', 'TARJETA', 0),
    ('2026-10-02T10:45:00', 'valentina.rojas@example.com', 'ENVIADO', 'TARJETA', 0),
    ('2026-10-03T16:25:00', 'federico.molina@example.com', 'ENTREGADO', 'TRANSFERENCIA', 0),
    ('2026-10-07T11:10:00', 'lucia.fernandez@example.com', 'EN_PREPARACION', 'TARJETA', 0),
    ('2026-10-09T09:40:00', 'sofia.ramirez@example.com', 'PAGADO', 'TRANSFERENCIA', 0),
    ('2026-10-10T17:20:00', 'martin.gomez@example.com', 'PAGADO', 'TARJETA', 1),
    ('2026-10-12T12:05:00', 'emiliano.cabrera@example.com', 'PENDIENTE', 'EFECTIVO', 1),
    ('2026-10-13T18:30:00', 'agustina.silva@example.com', 'PENDIENTE', 'TARJETA', 0)
) v(fecha, email, estado, metodo_pago, retiro)
JOIN usuario u ON u.email = v.email;

------------------------------------------------------------------------
-- 5. Detalle de compras
--    El precio_unitario se toma del precio vigente de la variante (RN.11).
------------------------------------------------------------------------
INSERT INTO detalle_compras (id_compra, id_varProductos, cantidad, precio_unitario)
SELECT c.id_compra, vp.id_varProductos, v.cantidad, vp.precio
FROM (VALUES
    ('2026-08-04T10:15:00', 'cana_spin_210.jpg', 1),
    ('2026-08-04T10:15:00', 'reel_4000.jpg', 1),
    ('2026-08-04T10:15:00', 'lin_multi_020.jpg', 1),
    ('2026-08-06T16:40:00', 'sen_cuchara_15.jpg', 3),
    ('2026-08-06T16:40:00', 'anz_pack_6.jpg', 2),
    ('2026-08-11T09:25:00', 'cana_tele_270.jpg', 1),
    ('2026-08-11T09:25:00', 'sen_minnow_9.jpg', 2),
    ('2026-08-19T18:05:00', 'ind_gorra.jpg', 2),
    ('2026-08-19T18:05:00', 'acc_pinza.jpg', 1),
    ('2026-08-22T11:30:00', 'reel_6000.jpg', 1),
    ('2026-08-22T11:30:00', 'lin_multi_030.jpg', 1),
    ('2026-08-27T20:10:00', 'ind_campera_m.jpg', 1),
    ('2026-09-02T17:42:00', 'cana_spin_180.jpg', 1),
    ('2026-09-02T17:42:00', 'sen_vinilo_pack.jpg', 2),
    ('2026-09-02T17:42:00', 'anz_pack_2.jpg', 1),
    ('2026-09-05T12:20:00', 'acc_caja.jpg', 1),
    ('2026-09-05T12:20:00', 'sen_cuchara_25.jpg', 2),
    ('2026-09-09T15:55:00', 'reel_baitcast.jpg', 1),
    ('2026-09-09T15:55:00', 'lin_multi_030.jpg', 1),
    ('2026-09-09T15:55:00', 'acc_pinza.jpg', 1),
    ('2026-09-12T10:05:00', 'sen_minnow_9.jpg', 4),
    ('2026-09-12T10:05:00', 'sen_vinilo_pack.jpg', 1),
    ('2026-09-16T19:15:00', 'ind_campera_l.jpg', 1),
    ('2026-09-16T19:15:00', 'ind_gorra.jpg', 1),
    ('2026-09-18T13:35:00', 'anz_pack_6.jpg', 3),
    ('2026-09-18T13:35:00', 'sen_cuchara_15.jpg', 2),
    ('2026-09-21T08:50:00', 'cana_spin_210.jpg', 2),
    ('2026-09-21T08:50:00', 'reel_4000.jpg', 2),
    ('2026-09-25T21:00:00', 'acc_soporte.jpg', 1),
    ('2026-09-25T21:00:00', 'lin_multi_020.jpg', 2),
    ('2026-09-28T14:12:00', 'reel_6000.jpg', 1),
    ('2026-10-02T10:45:00', 'cana_tele_270.jpg', 1),
    ('2026-10-02T10:45:00', 'reel_4000.jpg', 1),
    ('2026-10-02T10:45:00', 'sen_cuchara_25.jpg', 1),
    ('2026-10-02T10:45:00', 'anz_pack_2.jpg', 2),
    ('2026-10-03T16:25:00', 'ind_campera_m.jpg', 1),
    ('2026-10-03T16:25:00', 'acc_caja.jpg', 1),
    ('2026-10-07T11:10:00', 'sen_minnow_9.jpg', 2),
    ('2026-10-07T11:10:00', 'sen_cuchara_15.jpg', 2),
    ('2026-10-07T11:10:00', 'lin_multi_020.jpg', 1),
    ('2026-10-09T09:40:00', 'reel_baitcast.jpg', 1),
    ('2026-10-10T17:20:00', 'cana_spin_180.jpg', 1),
    ('2026-10-10T17:20:00', 'sen_vinilo_pack.jpg', 3),
    ('2026-10-12T12:05:00', 'acc_pinza.jpg', 2),
    ('2026-10-12T12:05:00', 'ind_gorra.jpg', 1),
    ('2026-10-13T18:30:00', 'cana_spin_210.jpg', 1),
    ('2026-10-13T18:30:00', 'lin_multi_030.jpg', 1)
) v(fecha, url_img, cantidad)
JOIN compra c         ON c.fecha_compra = CONVERT(datetime, v.fecha, 126)
JOIN var_producto vp  ON vp.url_img = v.url_img;

------------------------------------------------------------------------
-- 6. Total de cada compra nueva = suma de (cantidad x precio_unitario) (RN.15)
------------------------------------------------------------------------
UPDATE c
SET c.total = t.subtotal
FROM compra c
JOIN (SELECT id_compra, SUM(cantidad * precio_unitario) AS subtotal
      FROM detalle_compras
      GROUP BY id_compra) t ON t.id_compra = c.id_compra
WHERE c.total IS NULL;

COMMIT TRANSACTION;

------------------------------------------------------------------------
-- Verificaciones (correr despues de la carga)
------------------------------------------------------------------------
-- a) Cantidad de filas por tabla
SELECT 'usuario' AS tabla, COUNT(*) AS filas FROM usuario
UNION ALL SELECT 'provincia',       COUNT(*) FROM provincia
UNION ALL SELECT 'ciudad',          COUNT(*) FROM ciudad
UNION ALL SELECT 'direccion',       COUNT(*) FROM direccion
UNION ALL SELECT 'categoria',       COUNT(*) FROM categoria
UNION ALL SELECT 'producto',        COUNT(*) FROM producto
UNION ALL SELECT 'var_producto',    COUNT(*) FROM var_producto
UNION ALL SELECT 'compra',          COUNT(*) FROM compra
UNION ALL SELECT 'detalle_compras', COUNT(*) FROM detalle_compras;

-- b) El total de cada compra debe coincidir con la suma de sus renglones.
--    Tiene que devolver 0 filas.
SELECT c.id_compra, c.total, t.subtotal
FROM compra c
JOIN (SELECT id_compra, SUM(cantidad * precio_unitario) AS subtotal
      FROM detalle_compras GROUP BY id_compra) t ON t.id_compra = c.id_compra
WHERE c.total <> t.subtotal;

-- c) Compras sin ningun renglon. Tiene que devolver 0 filas
--    (si aparecen, son compras cargadas por otro script).
SELECT c.id_compra, c.fecha_compra
FROM compra c
WHERE NOT EXISTS (SELECT 1 FROM detalle_compras d WHERE d.id_compra = c.id_compra);