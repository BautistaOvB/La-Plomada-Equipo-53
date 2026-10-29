/* =====================================================================
   La Plomada | Etapa V - Triggers   

   1) Auditoria de UPDATE y DELETE sobre var_producto (trg_auditoria_var_producto).
      Antes de modificar o borrar una fila se guardan en auditoria_var_producto los
      valores que tenia (TODAS las columnas), mas la fecha y hora y el usuario de la
      base de datos que hizo la operacion. En un UPDATE tambien se guardan los
      valores nuevos.
   2) Bloqueo de DELETE sobre compra (trg_bloquear_delete_compra): emite un error con
      un mensaje y no borra nada.
   ===================================================================== */
USE La_Plomada_db;
GO

-- 0. Limpieza de versiones anteriores
DROP TRIGGER IF EXISTS trg_aud_var_producto_update;
DROP TRIGGER IF EXISTS trg_aud_var_producto_delete;
DROP TRIGGER IF EXISTS trg_auditoria_var_producto;
DROP TABLE   IF EXISTS auditoria_var_producto;
GO

-- 1. Tabla auxiliar de auditoria
--    Sin claves foraneas: el historial tiene que sobrevivir a la fila original.
--    fecha_hora (DATETIME) guarda fecha y hora. usuario_bd es el usuario de la base
--    (USER_NAME()); login_sql es el login de SQL Server (SUSER_SNAME()).
CREATE TABLE auditoria_var_producto (
    id_auditoria     INT IDENTITY(1,1) PRIMARY KEY,
    fecha_hora       DATETIME      NOT NULL DEFAULT GETDATE(),
    usuario_bd       SYSNAME       NOT NULL DEFAULT USER_NAME(),
    login_sql        SYSNAME       NOT NULL DEFAULT SUSER_SNAME(),
    operacion        VARCHAR(10)   NOT NULL,          -- UPDATE o DELETE
    id_varProductos  INT           NOT NULL,
    -- valores ANTES de la operacion
    ant_url_img      VARCHAR(75)   NULL,
    ant_stock        INT           NULL,
    ant_precio       DECIMAL(10,2) NULL,
    ant_descripcion  VARCHAR(150)  NULL,
    ant_id_producto  INT           NULL,
    -- valores DESPUES (solo en UPDATE; en DELETE quedan en NULL)
    nue_url_img      VARCHAR(75)   NULL,
    nue_stock        INT           NULL,
    nue_precio       DECIMAL(10,2) NULL,
    nue_descripcion  VARCHAR(150)  NULL,
    nue_id_producto  INT           NULL
);
GO

-- 2. Trigger de auditoria (UPDATE y DELETE) sobre var_producto
CREATE OR ALTER TRIGGER trg_auditoria_var_producto
ON var_producto
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Caso A: UPDATE (hay filas en deleted y en inserted)
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO auditoria_var_producto
            (operacion, id_varProductos,
             ant_url_img, ant_stock, ant_precio, ant_descripcion, ant_id_producto,
             nue_url_img, nue_stock, nue_precio, nue_descripcion, nue_id_producto)
        SELECT 'UPDATE', d.id_varProductos,
               d.url_img, d.stock, d.precio, d.descripcion, d.id_producto,
               i.url_img, i.stock, i.precio, i.descripcion, i.id_producto
        FROM deleted d
        INNER JOIN inserted i ON i.id_varProductos = d.id_varProductos;
    END

    -- Caso B: DELETE (hay filas en deleted pero ninguna en inserted)
    IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO auditoria_var_producto
            (operacion, id_varProductos,
             ant_url_img, ant_stock, ant_precio, ant_descripcion, ant_id_producto)
        SELECT 'DELETE', d.id_varProductos,
               d.url_img, d.stock, d.precio, d.descripcion, d.id_producto
        FROM deleted d;
    END
END;
GO

-- 3. Trigger que impide el DELETE sobre compra.
--    INSTEAD OF reemplaza a la operacion: como no se ejecuta el borrado, no se elimina nada.
--    RAISERROR devuelve un error real (nivel 16) y solo se emite si habia filas por borrar.
CREATE OR ALTER TRIGGER trg_bloquear_delete_compra
ON compra
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted)
        RAISERROR('OPERACION DENEGADA: no se permite eliminar registros de la tabla compra. Modifique su estado a CANCELADO.', 16, 1);
END;
GO

-- =====================================================================
-- PRUEBAS
-- =====================================================================

-- ---- A) UPDATE del precio ---------------------------------------------
DECLARE @precio_original DECIMAL(10,2) = (SELECT precio FROM var_producto WHERE id_varProductos = 1);

UPDATE var_producto
SET precio = ROUND(precio * 1.10, 2)                  -- aumento del 10%
WHERE id_varProductos = 1;

SELECT TOP 1 * FROM auditoria_var_producto ORDER BY id_auditoria DESC;
-- Esperado: operacion UPDATE, ant_precio = precio original, nue_precio = +10%,
--           y fecha_hora, usuario_bd y login_sql completos.

UPDATE var_producto SET precio = @precio_original WHERE id_varProductos = 1;   -- vuelve al original (tambien queda auditado)
GO

-- ---- B) UPDATE de otras columnas: se audita cualquier dato -------------
UPDATE var_producto
SET stock = stock + 10, descripcion = descripcion + ' (revisado)'
WHERE id_varProductos = 2;

SELECT TOP 1 * FROM auditoria_var_producto ORDER BY id_auditoria DESC;
-- Esperado: cambian ant_/nue_stock y ant_/nue_descripcion; el precio es igual en ambos lados.

UPDATE var_producto
SET stock = stock - 10, descripcion = REPLACE(descripcion, ' (revisado)', '')
WHERE id_varProductos = 2;                             -- vuelve al original
GO

-- ---- C) Un UPDATE sobre varias filas registra una fila por cada una ----
DECLARE @antes INT = (SELECT COUNT(*) FROM auditoria_var_producto);

UPDATE var_producto SET stock = stock WHERE id_varProductos IN (1, 2, 3);

SELECT @antes AS filas_antes, (SELECT COUNT(*) FROM auditoria_var_producto) AS filas_despues;
-- Esperado: filas_despues = filas_antes + 3.
GO

-- ---- D) DELETE: se guarda la fila completa --------------------------------
DECLARE @id_producto INT = (SELECT TOP 1 id_producto FROM producto ORDER BY id_producto);

INSERT INTO var_producto (url_img, stock, precio, descripcion, id_producto)
VALUES ('test_auditoria.jpg', 3, 100.00, 'Variante de prueba (auditoria)', @id_producto);

DECLARE @id_test INT = SCOPE_IDENTITY();

DELETE FROM var_producto WHERE id_varProductos = @id_test;

SELECT * FROM auditoria_var_producto WHERE id_varProductos = @id_test AND operacion = 'DELETE';
-- Esperado: una fila DELETE con la variante tal como estaba (stock 3, precio 100,00); los nue_ en NULL.
GO

-- ---- E) Trigger que impide el DELETE sobre compra -----------------------
-- E1: el intento. Esperado: mensaje en rojo "OPERACION DENEGADA..." (Mens. 50000, nivel 16).
DELETE FROM compra WHERE id_compra = (SELECT MIN(id_compra) FROM compra);
GO

-- E2: comprobar que no se borro nada (compras_antes = compras_despues).
DECLARE @antes_compras INT = (SELECT COUNT(*) FROM compra);
BEGIN TRY
    DELETE FROM compra WHERE id_compra = (SELECT MIN(id_compra) FROM compra);
END TRY
BEGIN CATCH
    PRINT 'Mensaje recibido: ' + ERROR_MESSAGE();
END CATCH;
SELECT @antes_compras AS compras_antes, (SELECT COUNT(*) FROM compra) AS compras_despues;
GO

-- ---- Historial completo ------------------------------------------------
SELECT * FROM auditoria_var_producto ORDER BY id_auditoria;
GO