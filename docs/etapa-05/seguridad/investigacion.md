# Etapa V: Mecanismos Avanzados -- Seguridad y Control de Acceso

## 1. Definición y Objetivo
La **seguridad en un motor de base de datos relacional (SGBD)** comprende el conjunto de directivas, mecanismos y controles implementados para garantizar que únicamente los usuarios e identidades autorizadas puedan acceder a la información y ejecutar acciones específicas sobre los objetos del sistema.

En **Microsoft SQL Server**, la seguridad opera mediante un modelo jerárquico de dos niveles:
1. **Autenticación (Logins a nivel Servidor):** Valida *quién* es el usuario y si tiene permiso para conectarse a la instancia del motor de base de datos.
2. **Autorización (Usuarios y Roles a nivel Base de Datos):** Determina *qué operaciones* (`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `EXECUTE`) puede realizar dicho usuario dentro de una base de datos particular (`La_Plomada_db`).

**Objetivo principal:** Aplicar de forma estricta el **Principio de Mínimo Privilegio (PoLP)**, garantizando que cada usuario, servicio o subsistema cuente únicamente con los permisos mínimos e indispensables para llevar a cabo su función operativa, impidiendo modificaciones accidentales, accesos indebidos o manipulación directa de tablas críticas.

---

## 2. Ventajas y Aplicaciones en Sistemas de Ventas
La implementación de directivas de seguridad basadas en usuarios y roles aporta valor crítico en sistemas de e-commerce y gestión comercial:
* **Protección de Datos Sensibles y Transaccionales:** Previene que usuarios sin privilegios administrativos consulten o alteren registros financieros, balances de ventas o información sensible de clientes.
* **Encapsulamiento y Protección de Reglas de Negocio:** Permite denegar la inserción o actualización directa sobre tablas (`compra`, `var_producto`), canalizando las operaciones exclusivamente a través de **Procedimientos Almacenados autorizados**. De esta forma, el motor garantiza que nunca se guarde una venta sin validar stock o aplicar descuentos.
* **Mantenibilidad y Escalabilidad mediante Roles:** En lugar de gestionar permisos usuario por usuario de forma manual, los privilegios se asignan a **Roles personalizados** (`rol_consulta_productos`). Al ingresar un nuevo empleado o servicio, basta con agregarlo como miembro del rol.
* **Mitigación de Inyección SQL e Incidentes de Seguridad:** Al restringir permisos a nivel de tabla y usar procedimientos con parámetros tipados, se reduce drásticamente la superficie de ataque del sistema.

---

## 3. Implementación en SQL Server Express
Para configurar la seguridad en SQL Server se utilizan sentencias DDL y DCL (*Data Control Language*):

### A. Autenticación y Cuentas de Acceso
```sql
-- Creación del inicio de sesión (servidor)
CREATE LOGIN usuario_lector WITH PASSWORD = 'Lector123*#Plomada';

-- Creación del usuario mapeado dentro de la base de datos
CREATE USER usuario_lector FOR LOGIN usuario_lector;
```

### B. Gestión de Roles
```sql
-- Creación de un rol de base de datos personalizado
CREATE ROLE rol_consulta_productos;

-- Asignación de permisos al rol
GRANT SELECT ON dbo.producto TO rol_consulta_productos;
GRANT SELECT ON dbo.var_producto TO rol_consulta_productos;

-- Incorporación de miembros al rol
ALTER ROLE rol_consulta_productos ADD MEMBER usuario_con_rol;
```

### C. Delegación Controlada de Ejecución (Ownership Chaining)
SQL Server permite conceder permisos de ejecución (`GRANT EXECUTE`) sobre un procedimiento almacenado a un usuario que **carece de permisos directos de inserción (`INSERT`)** en las tablas subyacentes. Gracias al mecanismo de *Ownership Chaining* (cadena de propiedad), el usuario ejecuta exitosamente la operación siempre que el procedimiento y las tablas compartan el mismo esquema (`dbo`), protegiendo la integridad de la base.

---

## 4. Caso Concreto Aplicado a "La Plomada"
En el e-commerce de artículos de pesca y camping, se definieron dos escenarios de aplicación directa:

### Escenario 1: Control de Emisión de Compras
* **`usuario_admin`:** Miembro del rol fijo de base de datos `db_owner`. Dispone de control total para administrar la plataforma y auditar operaciones.
* **`usuario_lector`:** Representa a un perfil restringido (vendedor de salón o aplicación externa). 
  * Se le otorga `GRANT SELECT ON dbo.compra`.
  * Se le **deniega o no se le concede `INSERT`** directo en `dbo.compra`.
  * Se le concede `GRANT EXECUTE ON dbo.sp_RegistrarVentaSimple` (o `dbo.sp_RegistrarCompraCompleta`).
  * **Resultado de negocio:** El usuario puede procesar ventas cumpliendo la lógica del sistema, pero no puede insertar registros arbitrarios en la tabla ni falsear estados.

### Escenario 2: Consulta del Catálogo de Productos
* **`rol_consulta_productos`:** Rol diseñado para perfiles que únicamente consultan stock y precios del catálogo de pesca (cañas, reeles, señuelos).
* **`usuario_con_rol`:** Empleado asignado al rol; puede consultar libremente el catálogo.
* **`usuario_sin_rol`:** Cuenta sin membresía; cualquier intento de lectura sobre `dbo.producto` es bloqueado por el motor (Error 229).

---

## 5. Demostración y Resultados Esperados
Las pruebas se encuentran codificadas en el archivo `scripts.sql` mediante el uso de `EXECUTE AS USER = ...` y `REVERT`, permitiendo simular las diferentes identidades desde una misma sesión:

1. **Inserción directa como Administrador (`usuario_admin`):** Concluye exitosamente.
2. **Inserción directa como Lector (`usuario_lector`):** Falla con mensaje de excepción: *`Permiso INSERT denegado en el objeto 'compra'`* (Error 229).
3. **Ejecución de Procedimiento Almacenado como Lector (`usuario_lector`):** Concluye exitosamente, confirmando la venta de forma controlada.
4. **Consulta de Catálogo con Rol (`usuario_con_rol`):** Recupera correctamente los artículos de pesca.
5. **Consulta de Catálogo sin Rol (`usuario_sin_rol`):** Falla con mensaje de excepción: *`Permiso SELECT denegado en el objeto 'producto'`* (Error 229).
