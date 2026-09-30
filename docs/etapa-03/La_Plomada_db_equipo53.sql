CREATE DATABASE La_Plomada_db;
GO
USE La_Plomada_db;
GO

CREATE TABLE usuario(
	id_usuario int PRIMARY KEY IDENTITY(1,1),
	mail varchar(75) unique,
	rol varchar(50) DEFAULT 'cliente',
	nombre varchar(25),
	apellido varchar(25),
	contrasena varchar(255) NOT NULL
);

CREATE TABLE ciudad(
	id_ciudad int PRIMARY KEY,
	codigo_postal varchar(10),
	nombre varchar(100) not null
);

CREATE TABLE provincia(
	id_provincia int PRIMARY KEY,
	nombre varchar(50) not null
);

CREATE TABLE direcciones(
	id_direccion int PRIMARY KEY,
	id_ciudad int,
	id_provincia int,
	id_usuario int,
	
	CONSTRAINT FK_direccion_ciudad
	FOREIGN KEY (id_ciudad) REFERENCES ciudad(id_ciudad),
	CONSTRAINT FK_provincia_direccion
	FOREIGN KEY (id_provincia) REFERENCES provincia(id_provincia),
	CONSTRAINT FK_direccion_usuario
	FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)

);

CREATE TABLE categoria(
	id_categoria int PRIMARY KEY,
	nombre varchar(50) not null
);

CREATE TABLE productos(
	id_productos int PRIMARY KEY IDENTITY(1,1),
	nombre varchar(75),
	id_categoria int,

	CONSTRAINT FK_categoria_productos
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
	FOREIGN KEY (id_direccion) REFERENCES direcciones(id_direccion),
	CONSTRAINT FK_compra_usuario 
	FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE carrito(
	id_carrito int PRIMARY KEY IDENTITY(1,1), 
	id_usuario int,

	CONSTRAINT FK_carrito_usuario
	FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE var_productos(
	id_varProductos int PRIMARY KEY IDENTITY(1,1),
	url_img varchar(75),
	stock int,
	precio DECIMAL(10,2),
	id_productos int,
	
	CONSTRAINT FK_var_productos
	FOREIGN KEY (id_productos) REFERENCES productos(id_productos)
);

CREATE TABLE detalle_carrito(
	id_detalleCarrito int PRIMARY KEY IDENTITY(1,1),
	cantidad int,
	id_carrito int, 
	id_varProductos int,

	CONSTRAINT FK_detalleCarrito_carrito
	FOREIGN KEY (id_carrito) REFERENCES carrito(id_carrito)
);

CREATE TABLE movimientos_stock(
	id_movimientosStock int PRIMARY KEY IDENTITY(1,1),
	cantidad_modificada int,
	fecha DATETIME DEFAULT GETDATE(),
	id_varProductos int,
	id_usuario int

	CONSTRAINT FK_movimientos_varProductos
	FOREIGN KEY (id_varProductos) REFERENCES var_productos(id_varProductos),
	CONSTRAINT FK_movimientos_usuarios
	FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE detalle_compras(
	id_detalleCompra INT PRIMARY KEY IDENTITY(1,1),
	estado varchar(35),
	cantidad int,
	id_compra int,
	id_varProductos int,

	CONSTRAINT FK_detalleCompras_compras
	FOREIGN KEY (id_compra) REFERENCES compra(id_compra),
	CONSTRAINT FK_varProducto_detalleCompra
	FOREIGN KEY (id_varProductos) REFERENCES var_productos(id_varProductos)
);