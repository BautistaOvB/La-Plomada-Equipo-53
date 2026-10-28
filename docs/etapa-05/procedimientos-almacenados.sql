-- ==========================================
-- PROYECTO: La_Plomada_db - ETAPA V
-- TEMA 1: PROCEDIMIENTOS Y FUNCIONES ALMACENADAS
-- TEMA 2: MANEJO DE TRANSACCIONES
-- ==========================================

USE La_Plomada_db;
GO

-- ==========================================
-- 1. FUNCIÓN ALMACENADA (ESCALAR)
-- OBJETIVO: Calcular el monto acumulado total de compras
--           realizadas por un usuario específico.
-- ==========================================
CREATE OR ALTER FUNCTION dbo.fn_CalcularTotalGastadoUsuario (@id_usuario INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @total_acumulado DECIMAL(12,2);
    
    -- Calcula el total acumulado de compras para el usuario dado.
    -- ISNULL previene valores NULL si el usuario aún no registró compras.
    SELECT @total_acumulado = ISNULL(SUM(total), 0)
    FROM compra
    WHERE id_usuario = @id_usuario;
    
    RETURN @total_acumulado;
END;
GO

-- ==========================================
-- DEMOSTRACIÓN DE USO DE LA FUNCIÓN
-- Consulta general de usuarios con su gasto total acumulado.
-- ==========================================
SELECT 
    id_usuario,
    nombre,
    apellido,
    email,
    dbo.fn_CalcularTotalGastadoUsuario(id_usuario) AS total_gastado_historico
FROM usuario;
GO

-- ==========================================
-- 2. PROCEDIMIENTO ALMACENADO CON TRANSACCIÓN
-- OBJETIVO: Registrar una venta completa asegurando la atomicidad (ACID).
-- ==========================================
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarCompraCompleta
    @id_usuario INT,
    @id_direccion INT,
    @metodo_pago VARCHAR(50),
    @retiro_sucursal INT,
    @id_varProductos INT,
    @cantidad INT,
    @precio_unitario DECIMAL(12,2)
AS
BEGIN
    -- Suprime el mensaje que indica el número de filas afectadas por cada instrucción
    SET NOCOUNT ON; 
    
    -- Inicio de la transacción para asegurar que todas las operaciones se completen o ninguna
    BEGIN TRANSACTION; 

    BEGIN TRY
        -- A. Calcular importe total e insertar la cabecera en la tabla 'compra'
        DECLARE @total_compra DECIMAL(12,2) = @cantidad * @precio_unitario;
        
        INSERT INTO compra (estado, total, metodo_pago, retiro_sucursal, id_direccion, id_usuario, fecha_compra)
        VALUES ('Completada', @total_compra, @metodo_pago, @retiro_sucursal, @id_direccion, @id_usuario, GETDATE());
        
        -- Obtener la clave primaria autonumerada generada para la compra recién insertada
        DECLARE @id_nueva_compra INT = SCOPE_IDENTITY();
        
        -- B. Insertar el ítem vendido en 'detalle_compras'
        INSERT INTO detalle_compras (cantidad, precio_unitario, id_compra, id_varProductos)
        VALUES (@cantidad, @precio_unitario, @id_nueva_compra, @id_varProductos);
        
        -- C. Consultar y verificar el stock disponible en 'var_producto'
        DECLARE @stock_actual INT;
        SELECT @stock_actual = stock 
        FROM var_producto 
        WHERE id_varProductos = @id_varProductos;
        
        -- Validación de regla de negocio: ¿Hay stock suficiente?
        IF @stock_actual < @cantidad
        BEGIN
            -- Se lanza una excepción personalizada si el stock no es suficiente
            RAISERROR('Stock insuficiente para completar la operación.', 16, 1);
            
            -- Se revierten todas las operaciones anteriores (compra y detalle)
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- D. Descontar la cantidad vendida del inventario
        UPDATE var_producto
        SET stock = stock - @cantidad
        WHERE id_varProductos = @id_varProductos;
        
        -- E. Si todas las acciones finalizaron sin fallos, se confirman los cambios en la BD
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Si ocurre un error no controlado o una excepción previa en el bloque TRY, 
        -- se verifica si existe una transacción activa pendiente y se cancela.
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Vuelve a lanzar el error capturado para que sea notificado a la aplicación consumidora
        THROW;
    END CATCH;
END;
GO

-- ==========================================
-- DEMOSTRACIÓN DE EJECUCIÓN DEL PROCEDIMIENTO
-- Simulación del proceso de compra desde la capa de presentación / backend
-- ==========================================
EXEC dbo.sp_RegistrarCompraCompleta 
    @id_usuario = 1, 
    @id_direccion = 1, 
    @metodo_pago = 'Efectivo', 
    @retiro_sucursal = 1, 
    @id_varProductos = 2, 
    @cantidad = 3, 
    @precio_unitario = 5000.00;
GO