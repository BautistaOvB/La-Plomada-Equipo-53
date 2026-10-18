USE La_Plomada_db;
GO

-- 1. Alerta de productos con bajo stock (< 15 unidades)
SELECT 
    p.nombre AS Producto,
    vp.descripcion AS Detalle_Variante,
    vp.stock AS Stock_Actual,
    vp.precio AS Precio_Unitario
FROM producto p
INNER JOIN var_producto vp ON p.id_producto = vp.id_producto
WHERE vp.stock < 15
ORDER BY vp.stock ASC;
GO

-- 2. Reporte de ventas por categoría en un rango de fechas
SELECT 
    cat.nombre AS Categoria,
    COUNT(DISTINCT c.id_compra) AS Cantidad_Tickets,
    SUM(dc.cantidad) AS Unidades_Vendidas,
    SUM(dc.cantidad * dc.precio_unitario) AS Total_Recaudado
FROM compra c
INNER JOIN detalle_compras dc ON c.id_compra = dc.id_compra
INNER JOIN var_producto vp ON dc.id_varProductos = vp.id_varProductos
INNER JOIN producto p ON vp.id_producto = p.id_producto
INNER JOIN categoria cat ON p.id_categoria = cat.id_categoria
WHERE c.fecha_compra >= '2026-08-01' AND c.fecha_compra < '2026-11-01'
GROUP BY cat.nombre
ORDER BY Total_Recaudado DESC; 
GO

-- =====================================================================
-- [SUGERENCIA DE FIX - Consulta 2]
-- Motivo: Se agrega el filtro para excluir compras con estado 'CANCELADO'
-- evitando contabilizar ingresos y unidades de transacciones no concretadas.
-- Se agrupa también por cat.id_categoria para evitar posibles colisiones de nombres.
-- =====================================================================
SELECT 
    cat.id_categoria,
    cat.nombre AS Categoria,
    COUNT(DISTINCT c.id_compra) AS Cantidad_Tickets,
    SUM(dc.cantidad) AS Unidades_Vendidas,
    SUM(dc.cantidad * dc.precio_unitario) AS Total_Recaudado
FROM compra c
INNER JOIN detalle_compras dc ON c.id_compra = dc.id_compra
INNER JOIN var_producto vp ON dc.id_varProductos = vp.id_varProductos
INNER JOIN producto p ON vp.id_producto = p.id_producto
INNER JOIN categoria cat ON p.id_categoria = cat.id_categoria
WHERE c.fecha_compra >= '2026-08-01' 
  AND c.fecha_compra < '2026-11-01'
  AND c.estado <> 'CANCELADO'
GROUP BY cat.id_categoria, cat.nombre
ORDER BY Total_Recaudado DESC;
GO

-- 3. Generación de comprobante/factura de una venta

DECLARE @IdCompra INT = 1;

SELECT 
    c.id_compra AS Nro_Comprobante,
    CONVERT(VARCHAR(16), c.fecha_compra, 120) AS Fecha,
    u.nombre + ' ' + u.apellido AS Cliente,
    c.metodo_pago AS Metodo_Pago,
    c.estado AS Estado,
    p.nombre AS Producto,
    vp.descripcion AS Detalle_Variante,
    dc.cantidad AS Cantidad,
    dc.precio_unitario AS Precio_Unitario,
    (dc.cantidad * dc.precio_unitario) AS Subtotal_Renglon,
    c.total AS Total_Factura
FROM compra c
INNER JOIN usuario u ON c.id_usuario = u.id_usuario
INNER JOIN detalle_compras dc ON c.id_compra = dc.id_compra
INNER JOIN var_producto vp ON dc.id_varProductos = vp.id_varProductos
INNER JOIN producto p ON vp.id_producto = p.id_producto
WHERE c.id_compra = @IdCompra;
GO

-- =====================================================================
-- [SUGERENCIA DE MEJORA - Consulta 3]
-- Motivo: Mejorar el comprobante agregando la modalidad de entrega
-- (RN.21), distinguiendo 'Retiro en Sucursal' de envíos a domicilio 
-- con su respectiva Ciudad y Provincia.
-- =====================================================================
DECLARE @IdCompra INT = 1;

SELECT 
    c.id_compra AS Nro_Comprobante,
    CONVERT(VARCHAR(16), c.fecha_compra, 120) AS Fecha,
    u.nombre + ' ' + u.apellido AS Cliente,
    c.metodo_pago AS Metodo_Pago,
    c.estado AS Estado,
    CASE 
        WHEN c.retiro_sucursal = 1 THEN 'Retiro en Sucursal'
        ELSE ci.nombre + ' (' + pr.nombre + ')'
    END AS Forma_Entrega,
    p.nombre AS Producto,
    vp.descripcion AS Detalle_Variante,
    dc.cantidad AS Cantidad,
    dc.precio_unitario AS Precio_Unitario,
    (dc.cantidad * dc.precio_unitario) AS Subtotal_Renglon,
    c.total AS Total_Factura
FROM compra c
INNER JOIN usuario u ON c.id_usuario = u.id_usuario
LEFT JOIN direccion d ON c.id_direccion = d.id_direccion
LEFT JOIN ciudad ci ON d.id_ciudad = ci.id_ciudad
LEFT JOIN provincia pr ON ci.id_provincia = pr.id_provincia
INNER JOIN detalle_compras dc ON c.id_compra = dc.id_compra
INNER JOIN var_producto vp ON dc.id_varProductos = vp.id_varProductos
INNER JOIN producto p ON vp.id_producto = p.id_producto
WHERE c.id_compra = @IdCompra;
GO

-- 4. Cálculo de promedio gastado por cliente

SELECT 
    AVG(resumen.Total_Gastado) AS Promedio_Gasto_Por_Cliente,
    MAX(resumen.Total_Gastado) AS Gasto_Maximo_Cliente,
    MIN(resumen.Total_Gastado) AS Gasto_Minimo_Cliente
FROM (
    SELECT 
        id_usuario,
        SUM(total) AS Total_Gastado
    FROM compra
    GROUP BY id_usuario
) AS resumen;
GO

-- 5. Lista el producto más vendido por categoría además de su cantidad vendida--
SELECT 
    c.nombre AS nombre_categoria,
    p.nombre AS nombre_producto,
    SUM(dc.cantidad) AS cantidad_total_vendida
FROM 
    categoria c
INNER JOIN 
    producto p ON c.id_categoria = p.id_categoria
INNER JOIN 
    var_producto vp ON p.id_producto = vp.id_producto
INNER JOIN 
    detalle_compras dc ON vp.id_varProductos = dc.id_varProductos
GROUP BY 
    c.id_categoria,
    c.nombre,
    p.id_producto,
    p.nombre
HAVING 
    SUM(dc.cantidad) = (
        -- Subconsulta para encontrar el número máximo de ventas de un producto en esa misma categoría
        SELECT TOP 1 SUM(dc_sub.cantidad)
        FROM producto p_sub
        INNER JOIN var_producto vp_sub ON p_sub.id_producto = vp_sub.id_producto
        INNER JOIN detalle_compras dc_sub ON vp_sub.id_varProductos = dc_sub.id_varProductos
        WHERE p_sub.id_categoria = c.id_categoria
        GROUP BY p_sub.id_producto
        ORDER BY SUM(dc_sub.cantidad) DESC
    );
GO

-- =====================================================================
-- [SUGERENCIA DE FIX - Consulta 5]
-- Motivo: Se agrega INNER JOIN con la tabla compra (comp / comp_sub) para 
-- validar que comp.estado <> 'CANCELADO', evitando que unidades de pedidos
-- cancelados se computen erróneamente en el total vendido por producto.
-- =====================================================================
SELECT 
    c.nombre AS nombre_categoria,
    p.nombre AS nombre_producto,
    SUM(dc.cantidad) AS cantidad_total_vendida
FROM 
    categoria c
INNER JOIN 
    producto p ON c.id_categoria = p.id_categoria
INNER JOIN 
    var_producto vp ON p.id_producto = vp.id_producto
INNER JOIN 
    detalle_compras dc ON vp.id_varProductos = dc.id_varProductos
INNER JOIN 
    compra comp ON dc.id_compra = comp.id_compra
WHERE 
    comp.estado <> 'CANCELADO'
GROUP BY 
    c.id_categoria,
    c.nombre,
    p.id_producto,
    p.nombre
HAVING 
    SUM(dc.cantidad) = (
        SELECT TOP 1 SUM(dc_sub.cantidad)
        FROM producto p_sub
        INNER JOIN var_producto vp_sub ON p_sub.id_producto = vp_sub.id_producto
        INNER JOIN detalle_compras dc_sub ON vp_sub.id_varProductos = dc_sub.id_varProductos
        INNER JOIN compra comp_sub ON dc_sub.id_compra = comp_sub.id_compra
        WHERE p_sub.id_categoria = c.id_categoria
          AND comp_sub.estado <> 'CANCELADO'
        GROUP BY p_sub.id_producto
        ORDER BY SUM(dc_sub.cantidad) DESC
    );
GO


-- 6. Lista todos los clientes que hayan gastado más de $100.000 en la tienda --
SELECT 
    u.id_usuario,
    u.nombre,
    u.apellido,
    u.email,
    SUM(c.total) AS total_gastado_historico
FROM 
    usuario u
INNER JOIN 
    compra c ON u.id_usuario = c.id_usuario
WHERE 
    u.rol = 'cliente'
GROUP BY 
    u.id_usuario,
    u.nombre,
    u.apellido,
    u.email
HAVING 
    MAX(c.total) > 100000;
GO

-- =====================================================================
-- [SUGERENCIA DE FIX - Consulta 6]
-- Motivo: MAX(c.total) evalúa si hubo una compra individual > $100.000.
-- Para evaluar el gasto histórico acumulado del cliente corresponde SUM(c.total).
-- Además, se excluyen compras canceladas para no distorsionar el total real.
-- =====================================================================
SELECT 
    u.id_usuario,
    u.nombre,
    u.apellido,
    u.email,
    SUM(c.total) AS total_gastado_historico
FROM usuario u
INNER JOIN compra c ON u.id_usuario = c.id_usuario
WHERE u.rol = 'cliente'
  AND c.estado <> 'CANCELADO'
GROUP BY 
    u.id_usuario,
    u.nombre,
    u.apellido,
    u.email
HAVING 
    SUM(c.total) > 100000;
GO


-- 7. Lista los 3 Productos que mas ingresos generan por Categoria --
SELECT 
    c.nombre AS nombre_categoria,
    top_prod.nombre_producto,
    top_prod.ingresos_totales
FROM 
    categoria c
CROSS APPLY (
    -- Esta subconsulta se ejecuta una vez por cada categoría encontrada
    SELECT TOP 3 
        p.nombre AS nombre_producto,
        SUM(dc.cantidad * dc.precio_unitario) AS ingresos_totales
    FROM 
        producto p
    INNER JOIN 
        var_producto vp ON p.id_producto = vp.id_producto
    INNER JOIN 
        detalle_compras dc ON vp.id_varProductos = dc.id_varProductos
    WHERE 
        p.id_categoria = c.id_categoria
    GROUP BY 
        p.id_producto,
        p.nombre
    ORDER BY 
        SUM(dc.cantidad * dc.precio_unitario) DESC
) AS top_prod;


-- 8. Consulta sobre ventas con envío por provincia y ciudad.
SELECT
    pr.nombre AS Provincia,
    ci.nombre AS Ciudad,
    COUNT(DISTINCT c.id_compra) AS Cantidad_Compras,
    SUM(dc.cantidad * dc.precio_unitario) AS Total_Facturado
FROM compra c
INNER JOIN direccion d ON c.id_direccion = d.id_direccion
INNER JOIN ciudad ci ON d.id_ciudad = ci.id_ciudad
INNER JOIN provincia pr ON ci.id_provincia = pr.id_provincia
INNER JOIN detalle_compras dc ON c.id_compra = dc.id_compra
WHERE c.retiro_sucursal = 0
  AND c.estado <> 'CANCELADO'
GROUP BY pr.nombre, ci.nombre
HAVING COUNT(DISTINCT c.id_compra) >= 2
ORDER BY Total_Facturado DESC;
GO

--Consulta de Variantes con stock que nunca se vendieron 
SELECT
    cat.nombre AS Categoria,
    p.nombre AS Producto,
    vp.descripcion AS Detalle_Variante,
    vp.stock AS Stock_Actual,
    vp.precio AS Precio_Unitario,
    vp.stock * vp.precio AS Capital_Inmovilizado
FROM var_producto vp
INNER JOIN producto p ON vp.id_producto = p.id_producto
INNER JOIN categoria cat ON p.id_categoria = cat.id_categoria
WHERE vp.stock > 0
  AND NOT EXISTS (
        SELECT 1
        FROM detalle_compras dc
        INNER JOIN compra c ON dc.id_compra = c.id_compra
        WHERE dc.id_varProductos = vp.id_varProductos
          AND c.estado <> 'CANCELADO'
  )
ORDER BY Capital_Inmovilizado DESC;
GO

-- 10. Auditoría de modificaciones manuales de stock por administrador (RN.19)
SELECT 
    m.id_movimiento,
    CONVERT(VARCHAR(16), m.fecha, 120) AS Fecha_Ajuste,
    u.nombre + ' ' + u.apellido AS Administrador,
    p.nombre AS Producto,
    vp.descripcion AS Detalle_Variante,
    m.cantidad_modificada AS Ajuste_Unidades,
    vp.stock AS Stock_Actual_Disponible
FROM movimiento_stock m
INNER JOIN usuario u ON m.admin_id = u.id_usuario
INNER JOIN var_producto vp ON m.var_productos_id = vp.id_varProductos
INNER JOIN producto p ON vp.id_producto = p.id_producto
ORDER BY m.fecha DESC;
GO

-- 11. Monitoreo de carritos activos y recaudación potencial
SELECT 
    u.id_usuario,
    u.nombre + ' ' + u.apellido AS Cliente,
    u.email,
    COUNT(dc.var_producto_id) AS Variantes_En_Carrito,
    SUM(dc.cantidad) AS Unidades_Totales,
    SUM(dc.cantidad * vp.precio) AS Valor_Estimado_Carrito
FROM carrito car
INNER JOIN usuario u ON car.id_usuario = u.id_usuario
INNER JOIN detalle_carrito dc ON car.id = dc.carrito_id
INNER JOIN var_producto vp ON dc.var_producto_id = vp.id_varProductos
GROUP BY u.id_usuario, u.nombre, u.apellido, u.email
HAVING SUM(dc.cantidad) > 0
ORDER BY Valor_Estimado_Carrito DESC;
GO

-- 12. Análisis de rendimiento y ticket promedio por método de pago
SELECT 
    c.metodo_pago AS Metodo_Pago,
    COUNT(c.id_compra) AS Total_Operaciones,
    SUM(c.total) AS Facturacion_Total,
    AVG(c.total) AS Ticket_Promedio
FROM compra c
WHERE c.estado <> 'CANCELADO'
GROUP BY c.metodo_pago
ORDER BY Facturacion_Total DESC;
GO
