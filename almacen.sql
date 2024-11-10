USE master 
go 

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ALMACEN_Grupo7')
BEGIN
    PRINT 'La base de datos ALMACEN_Grupo7 ya existe';
END
ELSE
BEGIN
	CREATE DATABASE NombreDeLaBaseDeDatos;
    PRINT 'La base de datos ALMACEN_Grupo7 creada.';
END;

USE ALMACEN_Grupo7
go

--Creacion de esquemas con verificacion si ya existe

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'esquema_Persona')
BEGIN
    PRINT 'Esquema_Persona ya existente';
END
ELSE
BEGIN
    EXEC('CREATE SCHEMA esquema_Persona');
    PRINT 'Esquema_Persona creado';
END;
go

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'esquema_Producto')
BEGIN
    PRINT 'Esquema_Producto ya existente';
END
ELSE
BEGIN
    EXEC('CREATE SCHEMA esquema_Producto');
    PRINT 'Esquema_Producto creado';
END;
go


IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'esquema_Sucursal')
BEGIN
    PRINT 'Esquema_Sucursal ya existente';
END
ELSE
BEGIN
    EXEC('CREATE SCHEMA esquema_Sucursal');
    PRINT 'Esquema_Sucursal creado';
END;
go

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'esquema_operaciones')
BEGIN
    PRINT 'Esquema_operaciones ya existente';
END
ELSE
BEGIN
    EXEC('CREATE SCHEMA esquema_operaciones');
    PRINT 'Esquema_operaciones creado';
END;
go


IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'esquema_Ventas')
BEGIN
    PRINT 'Esquema_Venta ya existente';
END
ELSE
BEGIN
    EXEC('CREATE SCHEMA esquema_Ventas');
    PRINT 'Esquema_Venta creado';
END;
go

--CREATE SCHEMA esquema_Persona go
--CREATE SCHEMA esquema_Producto go
--CREATE SCHEMA esquema_Sucursal go
--CREATE SCHEMA esquema_operaciones go
--CREATE SCHEMA esquema_Ventas go


--Creacion de tablas con verificacion si ya existe // Cada tabla tiene su propio identificador (PRIMARY KEY) sin suponer que viene de un archivo

--------------TABLAS EMPLEADOS Y TIPO DE CLIENTE

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'esquema_Persona' AND TABLE_NAME = 'empleado')
	BEGIN
        PRINT 'La tabla empleado ya existe.'
    END
    ELSE
    BEGIN
        -- Crea la tabla si no existe
CREATE TABLE esquema_Persona.empleado(
id int identity(1,1),
legajo int not null, 
nombre varchar(50), 
apellido varchar(50),  
nroDoc int, 
calleYNum varchar(50), 
localidad varchar(50), 
provincia varchar(50),  
cuil int,
cargo varchar (50),
sucursal varchar (50),
turno varchar (50),
emailPersonal varchar (100),
emailEmpresa varchar (100),
idSucursal int,
constraint pkId primary key(id),
constraint fkSucursal foreign key (idSucursal) references esquema_Sucursal.sucursales (id)
)
PRINT 'Tabla empleado creada.'
	END
go


IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'esquema_Persona' AND TABLE_NAME = 'cliente')
	BEGIN
        PRINT 'La tabla cliente ya existe.'
    END
    ELSE
    BEGIN
        -- Crea la tabla si no existe
CREATE TABLE esquema_Persona.cliente(
id int identity (1,1),
tipoCliente varchar (30),
genero varchar(10),
constraint pkClientes_ primary key(id)
)
PRINT 'Tabla cliente creada.'
	END
go

-------------TABLAS PRODUCTOS(CATALOGO, IMPORTADOS Y ELECTRONICOS) Y LINEA DE PRODUCTO (CLASIFICACION DE PRODUCTO)

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'esquema_Producto' AND TABLE_NAME = 'Producto')
	BEGIN
        PRINT 'La tabla producto ya existe.'
    END
    ELSE
    BEGIN
	 -- Crea la tabla si no existe
CREATE TABLE esquema_Producto.Producto(
id int identity(1,1),

idCatalogo int unique not null,
category varchar (10),
nombre varchar (150),
precio decimal(3,2), 
precio_Referencia decimal(3,2), 
unidad_Referencia varchar (2),
fechaYhorario datetime,

idImportado int unique not null,
nombreproducto varchar (150),
Proveedor varchar (50),
categoria varchar (20),
CantidadxUnidad varchar (50),
PrecioUnidad decimal(5,2),


productoElectronicoNombre varchar (150),
precioUniDolar decimal(7,2)

constraint pkId primary key(id)
)
PRINT 'Tabla producto creada.'
	END
go

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'esquema_Producto' AND TABLE_NAME = 'LineaDeProducto')
	BEGIN
        PRINT 'La tabla linea de producto ya existe.'
    END
    ELSE
    BEGIN
	 -- Crea la tabla si no existe
CREATE TABLE esquema_Producto.LineaDeProducto(
id int identity (1,1),
lineaProducto varchar (20),
productoDescrip varchar (150),
idProducto int,

constraint pkLinea primary key(id),

constraint fkProducto foreign key (idProducto) 
references esquema_Producto.Producto (id)
)
PRINT 'Tabla linea de producto creada.'
	END
go

-------------TABLA SUCURSALES

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'esquema_Sucursal' AND TABLE_NAME = 'sucursales')
	BEGIN
        PRINT 'La tabla sucursales ya existe.'
    END
    ELSE
    BEGIN
	 -- Crea la tabla si no existe
CREATE TABLE esquema_Sucursal.sucursales(
id int identity (1,1),
ciudad varchar (15),
reemplazadaX varchar (50),
calleYNum varchar(50),
localidadYCodPostal varchar(50),
provincia varchar(50),
horario varchar(50),
telefono int,
constraint pkSucursal_ primary key(id) 
)
PRINT 'Tabla sucursales creada.'
	END
go

------------TABLAS DE MEDIOS DE PAGO, FACTURA Y DETALLE DE FACTURA

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'esquema_operaciones' AND TABLE_NAME = 'MediosDePago')
	BEGIN
        PRINT 'La tabla medios de pago ya existe.'
    END
    ELSE
    BEGIN
	 -- Crea la tabla si no existe
CREATE TABLE esquema_operaciones.MediosDePago(
id int identity (1,1),
MedioDePago varchar (50),
NombreEs varchar (50),
constraint pkMediosDePago primary key (id)
)
PRINT 'Tabla medios de pago creada.'
	END
go

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'esquema_operaciones' AND TABLE_NAME = 'Factura')
	BEGIN
        PRINT 'La tabla factura ya existe.'
    END
    ELSE
    BEGIN
	 -- Crea la tabla si no existe
CREATE TABLE esquema_operaciones.Factura(
id int identity(1,1),
NroFactura int,
FechaEmision date,
HoraEmision time,
IdEmpleado int,
Total decimal(38,2),
TipoDeFactura varchar(1),
CiudadDeSucursal varchar(20),
MedioDePago varchar(30),
idMedioDePago int,

constraint pkId primary key (id),
constraint fkMedioDePago foreign key (idMedioDePago) 
references esquema_operaciones.MediosDePago(id)
)
PRINT 'Tabla factura creada.'
	END
go

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'esquema_operaciones' AND TABLE_NAME = 'DetalleDeFactura')
	BEGIN
        PRINT 'La tabla detalle de factura ya existe.'
    END
    ELSE
    BEGIN
	 -- Crea la tabla si no existe
CREATE TABLE esquema_operaciones.DetalleDeFactura(
id int identity(1,1),
Código int not null,
Descripción varchar(30),
PrecioUnitario decimal(4,2),
Cantidad int,
Subtotal decimal(5,2),
idFactura int,
idVenta int,
idProducto int,
constraint pkidDetalle primary key (id),
constraint fkFactura foreign key (idFactura) references esquema_operaciones.Factura (id),
constraint fkVenta foreign key (idVenta) references esquema_Ventas.ventasRegistradas (id),
constraint pkProducto foreign key (idProducto) references esquema_Producto.Producto (id)
)
PRINT 'Tabla detalle de factura creada.'
	END
go

---------------TABLA DE VENTAS REGISTRADAS

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'esquema_Ventas' AND TABLE_NAME = 'ventasRegistradas')
	BEGIN
        PRINT 'La tabla ventas registradas ya existe.'
    END
    ELSE
    BEGIN
	 -- Crea la tabla si no existe
CREATE TABLE esquema_Ventas.ventasRegistradas(
id int identity(1,1), ----ID de la Venta
idFactura int not null, 
tipoDeFactura varchar (20) CHECK (tipoDeFactura LIKE 'A' OR tipoDeFactura LIKE 'B' OR tipoDeFactura LIKE 'C'),
ciudad varchar(15),
tipoDeCliente varchar(30),
genero varchar (20),
producto varchar(150),
precioUnitario decimal(3,2), ---CAMBIAR A DECIMAL
cantidad int,
fecha date,
hora time,
medioDePago varchar(20),
empleado int,
idIdentificador int,


--Foreign key de las tablas

idSucursales int,
idCliente int,
idEmpleado int,


constraint pkId primary key (id), 



constraint fkSucursales_Ventas foreign key (idSucursales)
references esquema_Sucursal.sucursales (id),

constraint fkCliente_Ventas foreign key (idCliente)
references esquema_Persona.cliente (id),

constraint fkEmpleado_Ventas foreign key (idEmpleado)
references esquema_Persona.empleado (id)
)
PRINT 'Tabla ventas registradas creada.'
	END
go








