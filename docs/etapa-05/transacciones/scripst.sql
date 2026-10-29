/* =====================================================================
   La Plomada | Etapa V - Transacciones 

   Transaccion: INSERT en compra, INSERT en detalle_compras y UPDATE del stock en
   var_producto. Los datos quedan SOLO si toda la operacion termina bien.

   PARTE 1 - Transaccion simple
     Prueba 1: todo bien                        -> COMMIT
     Prueba 2: error provocado tras el INSERT   -> ROLLBACK, no queda ningun insert
   PARTE 2 - Transacciones anidadas (casos A, B y C)

   Cada prueba muestra la cantidad de compras, de renglones y el stock ANTES y
   DESPUES, para poder comprobar que los datos quedan consistentes.
   Usa los datos de la Etapa III: usuario 1, su direccion 1 y la variante 1.
   ===================================================================== */
USE La_Plomada_db;
GO

-- #####################################################################
-- PARTE 1 - TRANSACCION SIMPLE
-- #####################################################################

-- PRUEBA 1 - SIN ERROR.
-- Esperado: "Transaccion completada con exito". compras + 1, renglones + 1, stock - 2.
SET XACT_ABORT ON;

DECLARE @provocar_error  BIT = 0;     -- 0 = todo bien | 1 = error provocado despues del primer INSERT
DECLARE @id_varProductos INT = 1;
DECLARE @cantidad        INT = 2;
DECLARE @precio          DECIMAL(10,2) = (SELECT precio FROM var_producto WHERE id_varProductos = @id_varProductos);
DECLARE @IdCompra        INT;

SELECT 'ANTES' AS momento,
       (SELECT stock FROM var_producto WHERE id_varProductos = @id_varProductos) AS stock,
       (SELECT COUNT(*) FROM compra)          AS compras,
       (SELECT COUNT(*) FROM detalle_compras) AS renglones;

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Inserto encabezado en la tabla 'compra'
    INSERT INTO compra (estado, total, metodo_pago, id_usuario, id_direccion, fecha_compra)
    VALUES ('PENDIENTE', @cantidad * @precio, 'EFECTIVO', 1, 1, GETDATE());

    -- Capturo el ID de la compra recien generada
    SET @IdCompra = SCOPE_IDENTITY();

    -- ERROR PROVOCADO despues del primer INSERT: al dividir por cero salta al bloque CATCH.
    IF @provocar_error = 1
    BEGIN
        DECLARE @Error INT = 1 / 0;
    END

    -- 2. Inserto renglon en 'detalle_compras' (el precio sale de var_producto)
    INSERT INTO detalle_compras (id_compra, id_varProductos, cantidad, precio_unitario)
    VALUES (@IdCompra, @id_varProductos, @cantidad, @precio);

    -- 3. Actualizo stock en 'var_producto'
    UPDATE var_producto
    SET stock = stock - @cantidad
    WHERE id_varProductos = @id_varProductos;

    COMMIT TRANSACTION;
    PRINT 'Transaccion completada con exito. Venta y stock guardados.';
END TRY
BEGIN CATCH
    -- XACT_STATE() evita un ROLLBACK si ya no hay transaccion abierta
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
    PRINT 'Se ejecuto ROLLBACK. Ningun dato fue guardado en la base de datos.';
END CATCH;

SELECT 'DESPUES' AS momento,
       (SELECT stock FROM var_producto WHERE id_varProductos = @id_varProductos) AS stock,
       (SELECT COUNT(*) FROM compra)          AS compras,
       (SELECT COUNT(*) FROM detalle_compras) AS renglones;
GO

-- PRUEBA 2 - ERROR PROVOCADO despues del primer INSERT.
-- Esperado: error 8134 (division por cero) y ROLLBACK. DESPUES es igual a ANTES:
-- no quedo la compra, ni el renglon, ni cambio el stock.
SET XACT_ABORT ON;

DECLARE @provocar_error  BIT = 1;     -- 0 = todo bien | 1 = error provocado despues del primer INSERT
DECLARE @id_varProductos INT = 1;
DECLARE @cantidad        INT = 2;
DECLARE @precio          DECIMAL(10,2) = (SELECT precio FROM var_producto WHERE id_varProductos = @id_varProductos);
DECLARE @IdCompra        INT;

SELECT 'ANTES' AS momento,
       (SELECT stock FROM var_producto WHERE id_varProductos = @id_varProductos) AS stock,
       (SELECT COUNT(*) FROM compra)          AS compras,
       (SELECT COUNT(*) FROM detalle_compras) AS renglones;

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Inserto encabezado en la tabla 'compra'
    INSERT INTO compra (estado, total, metodo_pago, id_usuario, id_direccion, fecha_compra)
    VALUES ('PENDIENTE', @cantidad * @precio, 'EFECTIVO', 1, 1, GETDATE());

    -- Capturo el ID de la compra recien generada
    SET @IdCompra = SCOPE_IDENTITY();

    -- ERROR PROVOCADO despues del primer INSERT: al dividir por cero salta al bloque CATCH.
    IF @provocar_error = 1
    BEGIN
        DECLARE @Error INT = 1 / 0;
    END

    -- 2. Inserto renglon en 'detalle_compras' (el precio sale de var_producto)
    INSERT INTO detalle_compras (id_compra, id_varProductos, cantidad, precio_unitario)
    VALUES (@IdCompra, @id_varProductos, @cantidad, @precio);

    -- 3. Actualizo stock en 'var_producto'
    UPDATE var_producto
    SET stock = stock - @cantidad
    WHERE id_varProductos = @id_varProductos;

    COMMIT TRANSACTION;
    PRINT 'Transaccion completada con exito. Venta y stock guardados.';
END TRY
BEGIN CATCH
    -- XACT_STATE() evita un ROLLBACK si ya no hay transaccion abierta
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
    PRINT 'Se ejecuto ROLLBACK. Ningun dato fue guardado en la base de datos.';
END CATCH;

SELECT 'DESPUES' AS momento,
       (SELECT stock FROM var_producto WHERE id_varProductos = @id_varProductos) AS stock,
       (SELECT COUNT(*) FROM compra)          AS compras,
       (SELECT COUNT(*) FROM detalle_compras) AS renglones;
GO

-- #####################################################################
-- PARTE 2 - TRANSACCIONES ANIDADAS
-- Solo el COMMIT mas externo confirma de verdad: un COMMIT interno apenas baja
-- @@TRANCOUNT. Un ROLLBACK sin nombre deshace TODO, aunque este en la interna.
-- #####################################################################

-- CASO A - COMMIT interno + COMMIT externo.
-- Esperado: @@TRANCOUNT 1, 2, 1, 0. Los datos quedan: compras + 1, renglones + 1, stock - 1.
SET XACT_ABORT ON;

DECLARE @id_varProductos INT = 1;
DECLARE @cantidad        INT = 1;
DECLARE @accion_externa  VARCHAR(10) = 'COMMIT';   -- COMMIT o ROLLBACK de la transaccion EXTERNA
DECLARE @precio          DECIMAL(10,2) = (SELECT precio FROM var_producto WHERE id_varProductos = @id_varProductos);
DECLARE @IdCompra        INT;

SELECT 'ANTES' AS momento,
       (SELECT stock FROM var_producto WHERE id_varProductos = @id_varProductos) AS stock,
       (SELECT COUNT(*) FROM compra)          AS compras,
       (SELECT COUNT(*) FROM detalle_compras) AS renglones;

BEGIN TRY
    BEGIN TRANSACTION;                                   -- EXTERNA
    PRINT '1) BEGIN externa     -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5));

    INSERT INTO compra (estado, total, metodo_pago, id_usuario, id_direccion, fecha_compra)
    VALUES ('PENDIENTE', @cantidad * @precio, 'EFECTIVO', 1, 1, GETDATE());
    SET @IdCompra = SCOPE_IDENTITY();

        BEGIN TRANSACTION;                               -- INTERNA
        PRINT '2) BEGIN interna     -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5));

        INSERT INTO detalle_compras (id_compra, id_varProductos, cantidad, precio_unitario)
        VALUES (@IdCompra, @id_varProductos, @cantidad, @precio);

        UPDATE var_producto SET stock = stock - @cantidad WHERE id_varProductos = @id_varProductos;

        COMMIT TRANSACTION;                              -- INTERNA: solo baja @@TRANCOUNT
        PRINT '3) COMMIT interna    -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5)) + '  (todavia no se confirmo nada)';

    IF @accion_externa = 'COMMIT'
    BEGIN
        COMMIT TRANSACTION;                              -- EXTERNA: aca se confirma de verdad
        PRINT '4) COMMIT externa    -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5)) + '  (se confirmo todo)';
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION;                            -- EXTERNA: deshace tambien lo de la interna
        PRINT '4) ROLLBACK externa  -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5)) + '  (se deshizo todo)';
    END
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE() + ' -> Se hizo ROLLBACK.';
END CATCH;

SELECT 'DESPUES' AS momento,
       (SELECT stock FROM var_producto WHERE id_varProductos = @id_varProductos) AS stock,
       (SELECT COUNT(*) FROM compra)          AS compras,
       (SELECT COUNT(*) FROM detalle_compras) AS renglones;
GO

-- CASO B - COMMIT interno + ROLLBACK externo.
-- Esperado: @@TRANCOUNT 1, 2, 1, 0. DESPUES igual a ANTES: el COMMIT interno no era
-- definitivo y el ROLLBACK externo lo deshizo.
SET XACT_ABORT ON;

DECLARE @id_varProductos INT = 1;
DECLARE @cantidad        INT = 1;
DECLARE @accion_externa  VARCHAR(10) = 'ROLLBACK';   -- COMMIT o ROLLBACK de la transaccion EXTERNA
DECLARE @precio          DECIMAL(10,2) = (SELECT precio FROM var_producto WHERE id_varProductos = @id_varProductos);
DECLARE @IdCompra        INT;

SELECT 'ANTES' AS momento,
       (SELECT stock FROM var_producto WHERE id_varProductos = @id_varProductos) AS stock,
       (SELECT COUNT(*) FROM compra)          AS compras,
       (SELECT COUNT(*) FROM detalle_compras) AS renglones;

BEGIN TRY
    BEGIN TRANSACTION;                                   -- EXTERNA
    PRINT '1) BEGIN externa     -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5));

    INSERT INTO compra (estado, total, metodo_pago, id_usuario, id_direccion, fecha_compra)
    VALUES ('PENDIENTE', @cantidad * @precio, 'EFECTIVO', 1, 1, GETDATE());
    SET @IdCompra = SCOPE_IDENTITY();

        BEGIN TRANSACTION;                               -- INTERNA
        PRINT '2) BEGIN interna     -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5));

        INSERT INTO detalle_compras (id_compra, id_varProductos, cantidad, precio_unitario)
        VALUES (@IdCompra, @id_varProductos, @cantidad, @precio);

        UPDATE var_producto SET stock = stock - @cantidad WHERE id_varProductos = @id_varProductos;

        COMMIT TRANSACTION;                              -- INTERNA: solo baja @@TRANCOUNT
        PRINT '3) COMMIT interna    -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5)) + '  (todavia no se confirmo nada)';

    IF @accion_externa = 'COMMIT'
    BEGIN
        COMMIT TRANSACTION;                              -- EXTERNA: aca se confirma de verdad
        PRINT '4) COMMIT externa    -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5)) + '  (se confirmo todo)';
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION;                            -- EXTERNA: deshace tambien lo de la interna
        PRINT '4) ROLLBACK externa  -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5)) + '  (se deshizo todo)';
    END
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE() + ' -> Se hizo ROLLBACK.';
END CATCH;

SELECT 'DESPUES' AS momento,
       (SELECT stock FROM var_producto WHERE id_varProductos = @id_varProductos) AS stock,
       (SELECT COUNT(*) FROM compra)          AS compras,
       (SELECT COUNT(*) FROM detalle_compras) AS renglones;
GO

-- CASO C - ROLLBACK sin nombre dentro de la transaccion interna.
-- Esperado: @@TRANCOUNT 1, 2 y 0: el ROLLBACK deshace todas las transacciones abiertas.
BEGIN TRANSACTION;
PRINT 'externa abierta    -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5));
    BEGIN TRANSACTION;
    PRINT 'interna abierta    -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5));
    ROLLBACK TRANSACTION;
PRINT 'tras el ROLLBACK   -> @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(5));
GO