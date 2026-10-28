USE La_Plomada_db;
GO

-- TRANSACCIÓN SIMPLE: Venta con control de errores (Atomicidad)
BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Inserto encabezado en la tabla 'compra'
    INSERT INTO compra (estado, total, metodo_pago, id_usuario, fecha_compra)
    VALUES ('PENDIENTE', 15000, 'EFECTIVO', 1, GETDATE());

    -- Capturo el ID de la compra recién generada
    DECLARE @IdCompra INT = SCOPE_IDENTITY();

    -- Al dividir por cero, saltará automáticamente al bloque CATCH.
     DECLARE @Error INT = 1 / 0; 

    -- 2. Inserto renglón en 'detalle_compras'
    INSERT INTO detalle_compras (id_compra, id_varProductos, cantidad, precio_unitario)
    VALUES (@IdCompra, 1, 2, 7500);

    -- 3. Actualizo stock en 'var_producto'
    UPDATE var_producto
    SET stock = stock - 2
    WHERE id_varProductos = 1;

    
    COMMIT TRANSACTION;
    PRINT 'Transacción completada con éxito. Venta y stock guardados.';

END TRY
BEGIN CATCH
    -- Si ocurre cualquier error, se deshace todo
    ROLLBACK TRANSACTION;
    PRINT 'Error detectado. Se ejecutó ROLLBACK. Ningún dato fue guardado en la base de datos.';
END CATCH;
GO