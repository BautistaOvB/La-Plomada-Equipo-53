# Etapa V: Procedimientos y Funciones Almacenadas

## 1. Definición y Objetivo

Los **procedimientos almacenados (Stored Procedures)** son programas SQL compilados que se guardan directamente dentro de la base de datos y tienen la capacidad de ejecutar múltiples operaciones complejas. Por su parte, las **funciones almacenadas (Functions)** son rutinas programadas que reciben parámetros de entrada y devuelven un valor escalar o una tabla como resultado.

En **Microsoft SQL Server**, ambos mecanismos forman parte de la programación Transact-SQL (T-SQL) en el lado del servidor, permitiendo encapsular lógica operativa y de consulta de manera estructurada.

**Objetivo principal:** Optimizar el desarrollo, la robustez y la gestión de la base de datos centralizando la lógica operativa, garantizando la consistencia transaccional y minimizando la exposición directa de las estructuras de las tablas a las aplicaciones clientes.

---

## 2. Ventajas y Aplicaciones en Sistemas de Ventas

La utilización de procedimientos y funciones almacenadas aporta beneficios fundamentales en arquitecturas de sistemas comerciales y e-commerce:

* **Reutilización de Lógica de Negocio:** Evitan tener que reescribir consultas o bloques de código complejos cada vez que se necesita realizar una acción recurrente en el sistema.


* **Reducción de Código Repetido:** Centralizan operaciones comunes, simplificando el mantenimiento del código fuente tanto en la base de datos como en el backend.


* **Mejora de la Mantenibilidad:** Si una regla de negocio cambia (por ejemplo, la manera de calcular un acumulado o validar un stock), solo se modifica el objeto en el motor de base de datos sin necesidad de recompilar o actualizar la aplicación cliente.


* **Centralización de Reglas de Negocio:** Mantienen la integridad y consistencia de los datos, asegurando que las operaciones críticas se ejecuten siempre bajo los mismos criterios de validación.


* **Facilidad de Seguridad sobre los Datos:** Permiten otorgar permisos de ejecución específicos a los usuarios sobre estos componentes sin necesidad de otorgarles privilegios directos de lectura, modificación o escritura sobre las tablas transaccionales subyacentes.



---

## 3. Implementación en SQL Server Express

Para estructurar la lógica avanzada en el sistema de ventas, se implementan rutinas tipadas mediante T-SQL:

### A. Función Almacenada Escalar

Permite calcular de forma dinámica y reutilizable métricas sobre los usuarios:

```sql
CREATE OR ALTER FUNCTION dbo.fn_CalcularTotalGastadoUsuario (@id_usuario INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @total_acumulado DECIMAL(12,2);
    
    SELECT @total_acumulado = ISNULL(SUM(total), 0)
    FROM compra
    WHERE id_usuario = @id_usuario;
    
    RETURN @total_acumulado;
END;
GO

```

### B. Procedimiento Almacenado con Transacción

Permite registrar operaciones complejas (cabecera de compra, detalle e inventario) asegurando la atomicidad bajo el estándar ACID:

```sql
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
    SET NOCOUNT ON; 
    BEGIN TRANSACTION; 

    BEGIN TRY
        DECLARE @total_compra DECIMAL(12,2) = @cantidad * @precio_unitario;
        
        INSERT INTO compra (estado, total, metodo_pago, retiro_sucursal, id_direccion, id_usuario, fecha_compra)
        VALUES ('Completada', @total_compra, @metodo_pago, @retiro_sucursal, @id_direccion, @id_usuario, GETDATE());
        
        DECLARE @id_nueva_compra INT = SCOPE_IDENTITY();
        
        INSERT INTO detalle_compras (cantidad, precio_unitario, id_compra, id_varProductos)
        VALUES (@cantidad, @precio_unitario, @id_nueva_compra, @id_varProductos);
        
        DECLARE @stock_actual INT;
        SELECT @stock_actual = stock FROM var_producto WHERE id_varProductos = @id_varProductos;
        
        IF @stock_actual < @cantidad
        BEGIN
            RAISERROR('Stock insuficiente para completar la operación.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        UPDATE var_producto SET stock = stock - @cantidad WHERE id_varProductos = @id_varProductos;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

```

---

## 4. Caso Concreto Aplicado a "La Plomada"

En el e-commerce de artículos de pesca y camping, la implementación de estos objetos resuelve requerimientos operativos clave:

### Escenario 1: Auditoría de Historial de Clientes (`fn_CalcularTotalGastadoUsuario`)

* El sistema requiere mostrar en listados generales el monto histórico consumido por cada cliente sin sobrecargar la capa de presentación con subconsultas de agregación complejas.
* La función evalúa dinámicamente la tabla `compra` por cada registro de usuario, aplicando `ISNULL` para retornar `0.00` en cuentas nuevas o administrativas sin historial.



### Escenario 2: Procesamiento Transaccional de Ventas (`sp_RegistrarCompraCompleta`)

* Una venta en el sistema involucra múltiples acciones: registrar la cabecera de la compra, insertar el detalle del ítem, verificar el stock disponible en la variante del producto (`var_producto`) y descontar las unidades correspondientes del inventario.


* El procedimiento centraliza estas tareas garantizando que si falta stock, la operación completa se desmorona mediante un `ROLLBACK`, evitando estados inconsistentes (por ejemplo, registrar una venta de un producto agotado).



---

## 5. Demostración y Resultados Esperados

Las pruebas de ejecución sobre los objetos creados evidencian el comportamiento esperado del sistema:

1. **Consulta con Función Escalar:** Al invocar `dbo.fn_CalcularTotalGastadoUsuario` junto a la tabla de usuarios, el motor retorna el gasto acumulado por cliente de forma limpia y transparente.
2. **Ejecución Exitosa del Procedimiento (Stock Suficiente):** La transacción procesa la inserción de la compra, el detalle y actualiza el stock, finalizando con `COMMIT`.


3. **Reversión del Procedimiento (Stock Insuficiente):** Al intentar adquirir una cantidad mayor al stock actual, el procedimiento intercepta la regla de negocio, lanza la excepción personalizada y ejecuta `ROLLBACK TRANSACTION`, dejando la base de datos intacta sin registros parciales.
