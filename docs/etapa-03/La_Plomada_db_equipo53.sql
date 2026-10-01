CREATE DATABASE La_Plomada_db;
GO
USE La_Plomada_db;
GO

------------ tabla usuario ------------------
CREATE TABLE usuario (
    id_usuario INT IDENTITY(1,1),
    email VARCHAR(100) NOT NULL,
    rol VARCHAR(15) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    contrasena VARCHAR(255) NOT NULL
);
----------constraints para usuario ------------
-- Clave Primaria
ALTER TABLE usuario 
ADD CONSTRAINT PK_usuario PRIMARY KEY (id_usuario);
-- RN.01: "correo electrnico ǧnico"
ALTER TABLE usuario 
ADD CONSTRAINT UQ_usuario_email UNIQUE (email);
-- RN.17: "diferenciado mediante un tipo o rol de usuario"
-- Obligamos a que el rol solo pueda ser 'cliente' o 'administrador'
ALTER TABLE usuario 
ADD CONSTRAINT CHK_usuario_rol CHECK (rol IN ('cliente', 'administrador'));

CREATE TABLE provincia(
	id_provincia int PRIMARY KEY IDENTITY(1,1),
	nombre varchar(50) not null
);

CREATE TABLE ciudad(
	id_ciudad int PRIMARY KEY IDENTITY(1,1),
	id_provincia int,
	codigo_postal varchar(10),
	nombre varchar(100) not null,
	
	CONSTRAINT FK_ciudad_provincia
	FOREIGN KEY (id_provincia) REFERENCES provincia(id_provincia)
);

CREATE TABLE direccion(
	id_direccion int PRIMARY KEY IDENTITY(1,1),
	id_ciudad int,
	id_usuario int,
	
	CONSTRAINT FK_direccion_ciudad
	FOREIGN KEY (id_ciudad) REFERENCES ciudad(id_ciudad),
	CONSTRAINT FK_direccion_usuario
	FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE categoria(
	id_categoria int PRIMARY KEY IDENTITY(1,1),
	nombre varchar(50) not null
);

CREATE TABLE producto(
	id_producto int PRIMARY KEY IDENTITY(1,1),
	nombre varchar(75),
	id_categoria int,

	CONSTRAINT FK_categoria_producto
	FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);

CREATE TABLE compra(
	id_compra int PRIMARY KEY IDENTITY(1,1),
	estado varchar(50),
	total DECIMAL(10,2),
	metodo_pago varchar(50),
	retiro_sucursal BIT DEFAULT 0, /* */
	id_direccion int,
	id_usuario int,
	CONSTRAINT FK_compra_direccion
	FOREIGN KEY (id_direccion) REFERENCES direccion(id_direccion),
	CONSTRAINT FK_compra_usuario 
	FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE carrito (
    id INT IDENTITY(1,1) PRIMARY KEY,
    id_usuario INT NOT NULL
);

ALTER TABLE carrito
ADD CONSTRAINT FK_usuario_carrito FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE;

CREATE TABLE var_producto(
	id_varProductos int PRIMARY KEY IDENTITY(1,1),
	url_img varchar(75),
	stock int,
	precio DECIMAL(10,2),
	id_producto int,
	
	CONSTRAINT FK_var_producto
	FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

CREATE TABLE detalle_carrito (
    id INT IDENTITY(1,1) PRIMARY KEY,
    carrito_id INT NOT NULL,
    var_producto_id INT NOT NULL,
    cantidad INT NOT NULL
);

ALTER TABLE detalle_carrito
ADD CONSTRAINT FK_detallecarrito_carrito FOREIGN KEY (carrito_id) REFERENCES carrito(id) ON DELETE CASCADE;

ALTER TABLE detalle_carrito
ADD CONSTRAINT fk_detallecarrito_varproducto FOREIGN KEY (var_producto_id) REFERENCES var_producto(id_varProductos) ON DELETE NO ACTION;

ALTER TABLE detalle_carrito
ADD CONSTRAINT ck_detallecarrito_cantidad CHECK (cantidad > 0);



CREATE TABLE detalle_compras(
	id_detalleCompra INT PRIMARY KEY IDENTITY(1,1),
	cantidad int,
	precio_unitario DECIMAL(10,2),
	id_compra int,
	id_varProductos int,

	CONSTRAINT FK_detalleCompra_compra
	FOREIGN KEY (id_compra) REFERENCES compra(id_compra),
	CONSTRAINT FK_varProducto_detalleCompra
	FOREIGN KEY (id_varProductos) REFERENCES var_producto(id_varProductos)
);

--------------tabla movimiento_stock ------------
CREATE TABLE movimiento_stock (
    id_movimiento INT IDENTITY(1,1),
    var_productos_id INT NOT NULL,
    admin_id INT NOT NULL,
    cantidad_modificada INT NOT NULL,
    fecha DATETIME NOT NULL
);
------------ constraints para movimiento_stock -----------
-- Clave Primaria
ALTER TABLE movimiento_stock 
ADD CONSTRAINT PK_movimiento_stock PRIMARY KEY (id_movimiento);
-- Claves Forǭneas
-- Relacionar con el admin que hizo el movimiento (RN.19)
ALTER TABLE movimiento_stock 
ADD CONSTRAINT FK_movimiento_admin FOREIGN KEY (admin_id) REFERENCES usuario(id_usuario);

-- Relacin con la variante del producto (RN.19)
ALTER TABLE movimiento_stock 
ADD CONSTRAINT FK_movimiento_var_producto FOREIGN KEY (var_productos_id) REFERENCES var_producto(id_varProductos);
-- Regla de integridad: La cantidad modificada no puede ser cero 
-- (Puede ser positiva si agregan stock, o negativa si quitan, pero un movimiento de '0' no tiene sentido)
ALTER TABLE movimiento_stock 
ADD CONSTRAINT CHK_movimiento_cantidad CHECK (cantidad_modificada <> 0);
-- Regla de integridad: Fecha automǭtica
-- Si no le pasan la fecha en el insert, guarda automǭticamente la fecha y hora actual del servidor
ALTER TABLE movimiento_stock 
ADD CONSTRAINT DF_movimiento_fecha DEFAULT GETDATE() FOR fecha;
