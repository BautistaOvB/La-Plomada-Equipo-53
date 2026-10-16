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