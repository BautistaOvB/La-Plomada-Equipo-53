USE La_Plomada_db;
GO

SET NOCOUNT ON;
GO

-- 0. Limpieza previa de índices de prueba
DROP INDEX IF EXISTS IX_CompraHistorica_Fecha ON compra;
DROP INDEX IF EXISTS IX_CompraHistorica_Fecha_Cobertura ON compra;
GO

-- 1. Inserción de 1.000.000 de registros para pruebas de volumen (solo si no se cargaron antes)
IF (SELECT COUNT(*) FROM compra) < 1000000
BEGIN
    PRINT '>> Generando 1.000.000 de registros masivos para pruebas de rendimiento...';
    WITH Numeros AS
    (      
        SELECT TOP (1000000)             
        ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n    
        FROM sys.objects a       
        CROSS JOIN sys.objects b       
        CROSS JOIN sys.objects c   
    )  
    INSERT INTO compra(fecha_compra, total)   
    SELECT      
        DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 1825, '2020-01-01'),      
        RAND(CHECKSUM(NEWID())) * 10000  
    FROM Numeros;
END
GO

-- Verificamos la cantidad de registros en la tabla
SELECT COUNT(*) AS CantidadRegistros FROM compra;
GO

-- =====================================================================
-- MEDICIÓN DE RENDIMIENTO: COMPARACIÓN DE ÍNDICES
-- =====================================================================
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO 

-- ESCENARIO 1: Consulta sin índice sobre la fecha
-- Como la tabla ya tiene un Clustered Index en la PK (id_compra), pero la consulta
-- filtra por fecha_compra, el motor debe escanear TODA la tabla (Clustered Index Scan).
PRINT '>> ESCENARIO 1: Consulta sin índice sobre fecha (Escaneo completo)';
SELECT id_compra, fecha_compra, total
FROM compra 
WHERE fecha_compra BETWEEN '2023-01-01' AND '2023-03-31'; 
GO

-- ESCENARIO 2: Crear índice no agrupado simple sobre el campo fecha_compra
-- Nota: La tabla ya posee un índice agrupado (la PK id_compra). Como en SQL Server
-- solo puede existir UN índice agrupado por tabla, creamos un índice No Agrupado.
PRINT '>> ESCENARIO 2: Creando índice no agrupado simple sobre fecha_compra...';
CREATE NONCLUSTERED INDEX IX_CompraHistorica_Fecha ON compra(fecha_compra); 
GO 

PRINT '>> ESCENARIO 2: Consulta con índice no agrupado (Index Seek + Key Lookup)';
SELECT id_compra, fecha_compra, total
FROM compra 
WHERE fecha_compra BETWEEN '2023-01-01' AND '2023-03-31'; 
GO

-- Eliminamos el índice simple para probar el índice de cobertura
DROP INDEX IF EXISTS IX_CompraHistorica_Fecha ON compra;
GO

-- ESCENARIO 3: Crear índice no agrupado con cobertura (INCLUDE)
-- Al incluir la columna 'total' en las hojas del índice, el motor resuelve la consulta
-- al 100% leyendo únicamente el índice, sin necesidad de ir a buscar datos a la tabla.
PRINT '>> ESCENARIO 3: Creando índice con cobertura (INCLUDE total)...';
CREATE NONCLUSTERED INDEX IX_CompraHistorica_Fecha_Cobertura 
ON compra(fecha_compra) INCLUDE (total); 
GO 

PRINT '>> ESCENARIO 3: Consulta con índice de cobertura (Index Seek puro)';
SELECT fecha_compra, total
FROM compra 
WHERE fecha_compra BETWEEN '2023-01-01' AND '2023-03-31'; 
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO
