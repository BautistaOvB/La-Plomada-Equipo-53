/* =====================================================================
   LA PLOMADA | ETAPA V - SEGURIDAD Y MANEJO DE PERMISOS
   
   Dominio: E-Commerce de Pesca y Camping
   Base de Datos: La_Plomada_db
   
   Contenido:
     0. Limpieza previa de roles, usuarios y logins.
     1. Parte 1 - Permisos a nivel de usuario y principio de menor privilegio.
        - Asignación de db_owner a usuario_admin.
        - Asignación de SELECT restringido a usuario_lector.
        - Asignación de EXECUTE sobre procedimiento almacenado.
        - Demostración de INSERT directo (denegado) vs. EXEC SP (permitido).
     2. Parte 2 - Permisos a nivel de roles.
        - Creación de rol personalizado 'rol_consulta_productos'.
        - Asignación de permisos al rol.
        - Incorporación de usuarios y prueba de acceso (con rol vs. sin rol).
   ===================================================================== */

USE La_Plomada_db;
GO

-- =====================================================================
-- 0. PROCEDIMIENTO AUXILIAR PARA DEMOSTRACIÓN DE VENTAS
--    (Permite registrar ventas encapsulando la lógica sin dar acceso directo)
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarVentaSimple
    @Total DECIMAL(10,2),
    @MetodoPago VARCHAR(50) = 'EFECTIVO'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Inserta en compra utilizando valores por defecto coherentes para la prueba
    INSERT INTO compra (estado, total, metodo_pago, retiro_sucursal, id_direccion, id_usuario, fecha_compra)
    VALUES ('PENDIENTE', @Total, @MetodoPago, 1, NULL, 1, GETDATE());
    
    PRINT '>> Venta registrada exitosamente a través del procedimiento dbo.sp_RegistrarVentaSimple.';
END;
GO

-- =====================================================================
-- 1. LIMPIEZA PREVIA (Para permitir re-ejecución limpia del script)
-- =====================================================================
-- Quitar usuarios de roles si existen
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_con_rol')
    ALTER ROLE rol_consulta_productos DROP MEMBER usuario_con_rol;

-- Eliminar roles
DROP ROLE IF EXISTS rol_consulta_productos;

-- Eliminar usuarios de la base de datos
DROP USER IF EXISTS usuario_admin;
DROP USER IF EXISTS usuario_lector;
DROP USER IF EXISTS usuario_con_rol;
DROP USER IF EXISTS usuario_sin_rol;

-- Eliminar logins del servidor (a nivel master)
USE master;
GO
DROP LOGIN usuario_admin;
DROP LOGIN usuario_lector;
DROP LOGIN usuario_con_rol;
DROP LOGIN usuario_sin_rol;
GO

USE La_Plomada_db;
GO

-- =====================================================================
-- PARTE 1 - PERMISOS A NIVEL DE USUARIOS
-- =====================================================================

-- 1.1 Creación de Logins a nivel servidor SQL Server
CREATE LOGIN usuario_admin WITH PASSWORD = 'Admin123*#Plomada';
CREATE LOGIN usuario_lector WITH PASSWORD = 'Lector123*#Plomada';
GO

-- 1.2 Creación de Usuarios a nivel de la base de datos La_Plomada_db
CREATE USER usuario_admin FOR LOGIN usuario_admin;
CREATE USER usuario_lector FOR LOGIN usuario_lector;
GO

-- 1.3 Asignación de permisos: Usuario Administrador (db_owner)
ALTER ROLE db_owner ADD MEMBER usuario_admin;
GO

-- 1.4 Asignación de permisos: Usuario Lector (Mínimo privilegio)
-- Solo se otorga permiso de consulta (SELECT) sobre compras
GRANT SELECT ON dbo.compra TO usuario_lector;
GO

-- 1.5 Permiso de ejecución sobre el Procedimiento Almacenado
-- Aunque usuario_lector NO tiene permisos de INSERT en la tabla compra,
-- sí se le concede permiso para ejecutar el procedimiento autorizado.
GRANT EXECUTE ON dbo.sp_RegistrarVentaSimple TO usuario_lector;
GO

-- =====================================================================
-- DEMOSTRACIÓN PARTE 1: PRUEBAS DE SEGURIDAD A NIVEL DE USUARIO
-- =====================================================================

-- PRUEBA 1.A: INSERT directo sobre compra con 'usuario_admin'
-- Resultado esperado: Operación exitosa (es db_owner).
PRINT '------------------------------------------------------------';
PRINT '>> PRUEBA 1.A: INSERT directo sobre compra como usuario_admin';
EXECUTE AS USER = 'usuario_admin';
    INSERT INTO compra (estado, total, metodo_pago, retiro_sucursal, id_direccion, id_usuario, fecha_compra)
    VALUES ('ENTREGADO', 25000.00, 'TARJETA', 1, NULL, 1, GETDATE());
    PRINT '>> [CORRECTO] usuario_admin pudo insertar directamente.';
REVERT;
GO

-- PRUEBA 1.B: INSERT directo sobre compra con 'usuario_lector'
-- Resultado esperado: SQL Server rechaza la operación por falta de permisos (Error 229).
PRINT '------------------------------------------------------------';
PRINT '>> PRUEBA 1.B: INSERT directo sobre compra como usuario_lector';
EXECUTE AS USER = 'usuario_lector';
BEGIN TRY
    INSERT INTO compra (estado, total, metodo_pago, retiro_sucursal, id_direccion, id_usuario, fecha_compra)
    VALUES ('PENDIENTE', 15000.00, 'EFECTIVO', 1, NULL, 1, GETDATE());
    PRINT '>> [ERROR] No debió tener permisos para insertar directamente.';
END TRY
BEGIN CATCH
    PRINT '>> [ACCESO DENEGADO ESPERADO] ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

-- PRUEBA 1.C: INSERT mediante Procedimiento Almacenado con 'usuario_lector'
-- Resultado esperado: Operación exitosa porque posee permiso EXECUTE sobre el SP.
-- Se demuestra que no toca la tabla directamente pero sí ejecuta la lógica controlada.
PRINT '------------------------------------------------------------';
PRINT '>> PRUEBA 1.C: Ejecución de SP como usuario_lector';
EXECUTE AS USER = 'usuario_lector';
BEGIN TRY
    EXEC dbo.sp_RegistrarVentaSimple @Total = 15000.00, @MetodoPago = 'EFECTIVO';
    PRINT '>> [CORRECTO] usuario_lector pudo operar a través del Procedimiento Almacenado.';
END TRY
BEGIN CATCH
    PRINT '>> [FALLO INESPERADO] ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO


-- =====================================================================
-- PARTE 2 - PERMISOS A NIVEL DE ROLES
-- =====================================================================

-- 2.1 Creación de Logins y Usuarios para pruebas de roles
CREATE LOGIN usuario_con_rol WITH PASSWORD = 'Rol123*#Plomada';
CREATE LOGIN usuario_sin_rol WITH PASSWORD = 'Rol456*#Plomada';
GO

CREATE USER usuario_con_rol FOR LOGIN usuario_con_rol;
CREATE USER usuario_sin_rol FOR LOGIN usuario_sin_rol;
GO

-- 2.2 Creación de Rol personalizado para consulta de catálogo
CREATE ROLE rol_consulta_productos;
GO

-- 2.3 Asignación de permisos al Rol sobre las tablas del catálogo
GRANT SELECT ON dbo.producto TO rol_consulta_productos;
GRANT SELECT ON dbo.var_producto TO rol_consulta_productos;
GO

-- 2.4 Incorporación del usuario al Rol
ALTER ROLE rol_consulta_productos ADD MEMBER usuario_con_rol;
GO

-- =====================================================================
-- DEMOSTRACIÓN PARTE 2: PRUEBAS DE ACCESO MEDIANTE ROLES
-- =====================================================================

-- PRUEBA 2.A: SELECT sobre producto con 'usuario_con_rol'
-- Resultado esperado: Consulta exitosa (hereda permisos del rol).
PRINT '------------------------------------------------------------';
PRINT '>> PRUEBA 2.A: SELECT sobre producto como usuario_con_rol';
EXECUTE AS USER = 'usuario_con_rol';
    SELECT TOP 3 id_producto, nombre, id_categoria FROM dbo.producto;
    PRINT '>> [CORRECTO] usuario_con_rol consultó productos exitosamente.';
REVERT;
GO

-- PRUEBA 2.B: SELECT sobre producto con 'usuario_sin_rol'
-- Resultado esperado: SQL Server deniega el acceso (Error 229).
PRINT '------------------------------------------------------------';
PRINT '>> PRUEBA 2.B: SELECT sobre producto como usuario_sin_rol';
EXECUTE AS USER = 'usuario_sin_rol';
BEGIN TRY
    SELECT TOP 3 id_producto, nombre, id_categoria FROM dbo.producto;
    PRINT '>> [ERROR] No debió tener permisos de lectura.';
END TRY
BEGIN CATCH
    PRINT '>> [ACCESO DENEGADO ESPERADO] ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

PRINT '============================================================';
PRINT '>> TODAS LAS PRUEBAS DE SEGURIDAD FINALIZADAS.';
PRINT '============================================================';
GO
