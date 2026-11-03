# 🛒 La Plomada - Sistema de E-Commerce

**Universidad Nacional del Nordeste (UNNE)**  
**Facultad de Ciencias Exactas y Naturales y Agrimensura (FaCENA)**  
**Carrera:** Licenciatura en Sistemas de Información  
**Asignatura:** Bases de Datos I  
**Equipo:** 53  
**Integrante:** • Candia Ybarra, Andrés Marciano  
                • Larrazet, Tomás Ernesto  
                • Núñez, Ramiro Sebastián  
                • Ovalle Bravo, Bautista  
                • Quintana, Ricardo José Antonio  

---

## 📌 Descripción del Proyecto
**La Plomada** es un sistema de comercio electrónico (e-commerce) desarrollado para la gestión integral de un negocio de artículos de pesca y camping. El proyecto implementa un modelo de datos relacional robusto sobre **Microsoft SQL Server**, abarcando desde la definición estructural (DDL), la manipulación y consultas avanzadas (DML), hasta mecanismos avanzados de ingeniería de software en bases de datos como transacciones ACID, triggers de auditoría, seguridad por roles e índices para optimización.

---

## 📂 Estructura del Repositorio y Etapas

El proyecto se encuentra organizado de manera modular por etapas de desarrollo:
*   ### [📁 Etapa I: Requerimientos y Dominio del Negocio](./docs/etapa-01/)
    *  Descripción del caso: Breve introducción al rubro elegido y alcance del sistema.
    *  Reglas de Negocio: Redacción explícita de las reglas que rigen las operaciones.
    *  Alcance del sistema.
  
*   ### [📁 Etapa II: Modelado Conceptual y Lógico](./docs/etapa-02/)
    *  Diagrama Entidad-Relación (DER): Diagrama con entidades, atributos, relaciones y cardinalidades (1:1, 1:N, N:M) usando notación P. Chen.
    *  Transformación al Modelo Relacional: Notación de tablas con claves primarias (PK) y foráneas (FK).
    *  Proceso de Normalización: Documentación paso a paso de la evolución del modelo (1FN, 2FN y 3FN).

*   ### [📁 Etapa III: Implementación Física (DDL y DML)](./docs/etapa-03/)
    *   Diseño del modelo relacional del sistema en SQL Server.
    *   Scripts de creación de tablas (`usuario`, `provincia`, `ciudad`, `direccion`, `categoria`, `producto`, `var_producto`, `compra`, `detalle_compras`, `carrito`, `detalle_carrito`, `movimiento_stock`).
    *   Definición de claves primarias, foráneas, restricciones (`CHECK`, `UNIQUE`, `DEFAULT`) y datos iniciales de prueba (Mock Data).

*   ### [📁 Etapa IV: Consultas y Casos de Uso (DML)](./docs/etapa-04/)
    *   Desarrollo de consultas estructuradas de selección (`SELECT`).
    *   Generación de comprobantes y facturas consolidadas de ventas.
    *   Reportes agregados con funciones de grupo (`GROUP BY`, `SUM`, `COUNT`) y rangos de fechas (`BETWEEN`).
    *   Consultas avanzadas con múltiples tablas (`JOIN`, `LEFT JOIN`, `HAVING`) y subconsultas (tablas derivadas y operadores `IN`, `EXISTS`).

*   ### [📁 Etapa V: Mecanismos Avanzados](./docs/etapa-05/)
    *   **[Procedimientos y Funciones Almacenadas](./docs/etapa-05/procedimientos_funciones/)**: Centralización de la lógica de negocio (cálculo de descuentos y registro modular de ventas).
    *   **[Manejo de Transacciones](./docs/etapa-05/transacciones/)**: Implementación de transacciones simples y anidadas para garantizar la atomicidad, consistencia e integridad en el control de stock y registro de ventas mediante bloques `TRY...CATCH`.
    *   **[Triggers y Auditoría](./docs/etapa-05/triggers_auditoria/)**: Triggers de tipo `AFTER` para trazabilidad automática de cambios (historial de precios y modificaciones en productos) y triggers de tipo `INSTEAD OF` para el bloqueo de operaciones destructivas sobre registros históricos (protección de la tabla `compra`).
    *   **[Seguridad y Control de Acceso](./docs/etapa-05/seguridad/)**: Implementación del principio de menor privilegio mediante usuarios, roles personalizados y delegación controlada de ejecución de procedimientos almacenados.
    *   **[Optimización de Consultas e Índices](./docs/etapa-05/optimizacion_consultas/)**: Mejora de tiempos de respuesta y reducción de lecturas lógicas mediante índices agrupados y de cobertura sobre tablas de gran volumen.

---

## 🛠️ Tecnologías Utilizadas
*   **SGBD:** Microsoft SQL Server / T-SQL.
*   **Entorno de Gestión:** SQL Server Management Studio (SSMS) / Visual Studio Code (extensión mssql).
*   **Control de Versiones:** Git & GitHub.
