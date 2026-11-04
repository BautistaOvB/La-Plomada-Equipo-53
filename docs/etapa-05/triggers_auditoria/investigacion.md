# Etapa V: Mecanismos Avanzados -- Triggers de Auditoría

## 1. Definición y Objetivo

Los Triggers (Disparadores) son procedimientos almacenados especiales en SQL Server que se ejecutan automáticamente ("se disparan") como reacción a eventos que modifican los datos de una tabla (operaciones `INSERT`, `UPDATE` o `DELETE`).

**Características principales:**
- No pueden ser invocados manualmente con `EXECUTE`.
- Operan dentro de la misma transacción de la instrucción que los disparó.
- Utilizan dos tablas virtuales temporales alojadas en memoria: `inserted` (contiene los datos nuevos o actualizados) y `deleted` (contiene los datos originales antes del borrado o actualización).

**Objetivo principal:** Garantizar el cumplimiento automático de reglas de negocio restrictivas y proporcionar mecanismos de auditoría invisibles para el usuario, permitiendo trazabilidad y control de cambios sobre información sensible sin requerir código adicional en la aplicación.

## 2. Ventajas y Aplicaciones en Sistemas de Ventas

La implementación de Triggers en bases de datos comerciales aporta seguridad y trazabilidad:

- **Auditoría Transparente:** Registran qué usuario (login de red y base de datos) modificó o borró un registro, junto con la fecha/hora exacta y los valores originales. Esto responde a la pregunta de "quién cambió el precio" o "cuándo desapareció un producto".
- **Aplicación Restrictiva (Seguridad):** Los triggers de tipo `INSTEAD OF` pueden interceptar operaciones destructivas (`DELETE`) antes de que sucedan y reemplazarlas por otra acción o por una excepción.
- **Independencia de la Capa Lógica:** Como operan a nivel del SGBD, ninguna aplicación conectada, sin importar si es web, móvil o de escritorio, puede evadir estas reglas.

## 3. Implementación en SQL Server Express

La creación de triggers utiliza el comando `CREATE TRIGGER` y define sobre qué acciones actuar:

**A. Trigger AFTER (Auditoría)**

Se ejecuta después de la modificación, permitiendo capturar el antes y el después mediante las tablas `inserted` y `deleted`.

```sql
CREATE TRIGGER dbo.trg_Auditoria
AFTER UPDATE, DELETE
AS
BEGIN
    -- Lógica insertando datos de deleted e inserted en otra tabla
END;

```

**B. Trigger INSTEAD OF (Intercepción/Bloqueo)**

Reemplaza la acción original. Es ideal para impedir borrados físicos.

```sql
CREATE TRIGGER dbo.trg_Bloqueo
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR('Operación no permitida.', 16, 1);
END;
```

## 4. Caso Concreto Aplicado a "La Plomada"
En el e-commerce de artículos de pesca "La Plomada", se detectaron dos riesgos críticos de negocio que fueron mitigados:
- Riesgo 1 (Precios e Inventario sin trazabilidad): Cualquier empleado con permisos podía modificar precios o borrar un producto (tabla var_producto) sin dejar rastro.
  
  Solución implementada: Se creó la tabla histórica auditoria_var_producto (sin claves foráneas) y el trigger trg_auditoria_var_producto. Ante un UPDATE o DELETE, el trigger guarda automáticamente una copia completa de cómo estaba el artículo antes (stock, precio, descripción) y cómo quedó (en caso de UPDATE), junto con USER_NAME(), SUSER_SNAME() y GETDATE().
- Riesgo 2 (Eliminación de historial de ventas): Un borrado accidental sobre la tabla compra alteraría los balances y la contabilidad.
  
  Solución implementada: Se configuró el trigger trg_bloquear_delete_compra de tipo INSTEAD OF DELETE sobre la tabla compra. Cuando alguien intenta borrar una factura, el trigger descarta la operación, lanza un error de nivel 16 y sugiere modificar el estado a "CANCELADO".
5. Demostración y Resultados Obtenidos
Se ejecutaron diversos escenarios de prueba codificados en scripts.sql sobre la base de datos La_Plomada_db. A continuación, el registro de la actividad:
A. Pruebas de Auditoría sobre var_producto (AFTER UPDATE/DELETE)
- Operación 1: Se actualizó el precio del producto 1 aplicándole un 10% de aumento, y luego se restituyó a su valor original.
  
  Resultado: Se generaron dos registros en auditoria_var_producto. La tabla de auditoría capturó la fecha, el usuario responsable, el campo ant_precio y el nue_precio, garantizando trazabilidad ante cambios comerciales.
- Operación 2: Se ejecutó un DELETE sobre una variante de prueba recién creada.
  
  Resultado: El sistema eliminó la fila original, pero el trigger guardó una copia de la variante eliminada (stock 3, precio 100) en el registro histórico bajo la operación DELETE.
B. Prueba de Restricción sobre compra (INSTEAD OF DELETE)
- Operación evaluada: Intento de borrado físico (DELETE) de un registro histórico en la tabla compra.
- Comportamiento del SGBD: El trigger interceptó la orden antes de impactar el disco.
- Salida de consola (SQL Server):

Mensaje 50000, nivel 16, estado 1, procedimiento trg_bloquear_delete_compra

OPERACION DENEGADA: no se permite eliminar registros de la tabla compra.
Modifique su estado a CANCELADO.


Mensaje recibido:
OPERACION DENEGADA: no se permite eliminar registros de la tabla compra. Modifique su estado a CANCELADO.

Conclusiones de la demostración
El sistema cuenta con defensas activas comprobadas empíricamente.
1. Trazabilidad comercial: Opera correctamente; el aumento de precio quedó fotografiado por el trigger en la tabla de auditoría.
2. Protección contable: Es efectiva; el sistema atrapó el intento de borrar una venta, lanzó la excepción preconfigurada e interrumpió el proceso. Al validar mediante un conteo COUNT(*), se comprobó que la cantidad de registros en compra no varió, garantizando que el historial de ventas permanece intacto ante intervenciones maliciosas o accidentales.

