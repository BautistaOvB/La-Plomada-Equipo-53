USE La_Plomada_db;
GO

-- 1. Creación de la tabla auxiliar de auditoría
IF OBJECT_ID('auditoria_var_producto', 'U') IS NULL
BEGIN
    CREATE TABLE auditoria_var_producto (
        id_auditoria INT IDENTITY(1,1) PRIMARY KEY,
        fecha_hora DATETIME DEFAULT GETDATE(),
        usuario VARCHAR(50) DEFAULT SYSTEM_USER,
        operacion VARCHAR(20),
        id_varProductos INT,
        precio_anterior DECIMAL(10,2),
        precio_nuevo DECIMAL(10,2)
    );
END
GO

-- 2. Trigger de Auditoría (UPDATE y DELETE) sobre var_producto
CREATE OR ALTER TRIGGER trg_auditoria_var_producto
ON var_producto
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Caso A: Registro de UPDATE (Existen datos en deleted y en inserted)
    IF EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO auditoria_var_producto (operacion, id_varProductos, precio_anterior, precio_nuevo)
        SELECT 'UPDATE', d.id_varProductos, d.precio, i.precio
        FROM deleted d
        JOIN inserted i ON d.id_varProductos = i.id_varProductos;
    END

    -- Caso B: Registro de DELETE (Existen datos en deleted pero no en inserted)
    IF NOT EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO auditoria_var_producto (operacion, id_varProductos, precio_anterior, precio_nuevo)
        SELECT 'DELETE', d.id_varProductos, d.precio, NULL
        FROM deleted d;
    END
END;
GO

-- 3. Trigger para evitar el DELETE sobre la tabla compra
CREATE OR ALTER TRIGGER trg_bloquear_delete_compra
ON compra
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'OPERACIÓN DENEGADA: No se permite eliminar registros de la tabla compra. Modifique su estado a "CANCELADO".';
END;
GO