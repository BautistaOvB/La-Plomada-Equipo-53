USE La_Plomada_db
GO

SET NOCOUNT ON;
GO

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
	RAND(CHECKSUM(NEWID())) * 10000  FROM Numeros;
GO 
-- Insertamos registros

SELECT COUNT(*) AS CantidadRegistros
FROM compra;
-- Verificamos su cantidad

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO 

SELECT id_compra, fecha_compra, total
FROM compra 
WHERE fecha_compra BETWEEN '2023-01-01' AND '2023-03-31'; 
-- Hasta este momento SQL Server utiliza Table Scan (analiza toda la tabla sin índices)

CREATE CLUSTERED INDEX IX_CompraHistorica_Fecha ON compra(fecha_compra); 
GO 
-- Creamos un índice agrupado IX_CompraHistorica_Fecha a partir del campo fecha_compra

SELECT id_compra, fecha_compra, total
FROM compra 
WHERE fecha_compra BETWEEN '2023-01-01' AND '2023-03-31'; 
-- Aquí ya se realizó mediante Clustered Index Seek y verificamos el tiempo de respuesta del índice agrupado

DROP INDEX IX_CompraHistorica_Fecha ON compra;
-- Hacemos un DROP al índice IX_CompraHistorica_Fecha

CREATE NONCLUSTERED INDEX IX_CompraHistorica_Fecha ON compra(fecha_compra) INCLUDE (total); 
GO 
-- Creamos un índice agrupado IX_CompraHistorica_Fecha a partir del campo fecha_compra y total

SELECT fecha_compra, total
FROM compra 
WHERE fecha_compra BETWEEN '2023-01-01' AND '2023-03-31'; 
-- Verificamos el tiempo de respuesta del índice agrupado por dos campos

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO 
