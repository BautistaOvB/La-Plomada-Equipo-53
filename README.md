# 🛒 La Plomada - Sistema de E-Commerce

**Universidad Nacional del Nordeste (UNNE)**  
**Facultad de Ciencias Exactas y Naturales y Agrimensura (FaCENA)**  
**Carrera:** Licenciatura en Sistemas de Información  
**Asignatura:** Bases de Datos I  
**Equipo:** 53  
**Integrante:** •Candia Ybarra, Andrés Marciano 
                • Larrazet, Tomás Ernesto 
                • Núñez, Ramiro Sebastián 
                • Ovalle Bravo, Bautista 
                • Quintana, Ricardo José Antonio   

---

## 📌 Descripción del Proyecto
**La Plomada** es un sistema de comercio electrónico (e-commerce) desarrollado para la gestión integral de un negocio de artículos de pesca y camping. El proyecto implementa un modelo de datos relacional robusto sobre **Microsoft SQL Server**, abriendo desde la definición estructural (DDL), la manipulación y consultas avanzadas (DML), hasta mecanismos avanzados de ingeniería de software en bases de datos como transacciones ACID y triggers de auditoría y seguridad.

---

## 📂 Estructura del Repositorio y Etapas

El proyecto se encuentra organizado de manera modular por etapas de desarrollo:

*   ### [📁 Etapa III: Modelo Relacional y DDL](./docs/etapa-03/)
    *   Diseño del modelo entidad-relación y relacional del sistema.
    *   Scripts de creación de tablas (`usuario`, `provincia`, `ciudad`, `direccion`, `categoria`, `producto`, `var_producto`, `compra`, `detalle_compras`, `carrito`, `detalle_carrito`, `movimiento_stock`).
    *   Definición de claves primarias, foráneas, restricciones (`CHECK`, `UNIQUE`, `DEFAULT`) y datos iniciales de prueba (Mock Data).

*   ### [📁 Etapa IV: Consultas y Casos de Uso (DML)](./docs/etapa-04/)
    *   Desarrollo de consultas estructuradas de selección (`SELECT`).
    *   Generación de comprobantes y facturas consolidadas de ventas.
    *   Reportes agregados con funciones de grupo (`GROUP BY`, `SUM`, `COUNT`) y rangos de fechas (`BETWEEN`).
    *   Consultas avanzadas con múltiples tablas (`JOIN`, `LEFT OUTER JOIN`, `HAVING`) y subconsultas (tablas derivadas en el `FROM`, operadores `IN` y correlacionadas con `EXISTS`).

*   ### [📁 Etapa V: Mecanismos Avanzados](./etapa_v/)
    *   **[Procedimientos y Funciones Almacenadas](./etapa_v/procedimientos_funciones/)**: Centralización de la lógica de negocio (cálculo de descuentos y registro modular de ventas).
    *   **[Manejo de Transacciones](./etapa_v/transacciones/)**: Implementación de transacciones simples y anidadas para garantizar la atomicidad, consistencia e integridad en el control de stock y registro de ventas mediante bloques `TRY...CATCH`.
    *   **[Triggers y Auditoría](./etapa_v/triggers_auditoria/)**: Triggers de tipo `AFTER` para trazabilidad automática de cambios (historial de precios y modificaciones en productos) y triggers de tipo `INSTEAD OF` para el bloqueo de operaciones destructivas sobre registros históricos (protección de la tabla `compra`).

---

## 🛠️ Tecnologías Utilizadas
*   **SGBD:** Microsoft SQL Server / T-SQL.
*   **Entorno de Gestión:** SQL Server Management Studio (SSMS) / Visual Studio Code (extensión mssql).
*   **Control de Versiones:** Git & GitHub.
