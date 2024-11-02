USE master 
go 

CREATE DATABASE ALMACEN_Grupo7
go

USE ALMACEN_Grupo7
go

--Creacion de esquemas

CREATE SCHEMA esquema_Persona
go
CREATE SCHEMA esquema_Producto
go
CREATE SCHEMA esquema_Sucursal
go
CREATE SCHEMA esquema_operaciones
go
CREATE SCHEMA esquema_Ventas
go


--Creacion de tablas

CREATE TABLE esquema_Persona.empleado(
legajo int, 
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
constraint pkEmpleado_ primary key(legajo)
)
go



CREATE TABLE esquema_Persona.cliente(
id int identity (1,1),
tipoCliente varchar (30),
genero varchar(10),
constraint pkClientes_ primary key(id)
)
go



CREATE TABLE esquema_Producto.importado(
id int identity(1,1),
nombreproducto varchar (100),
Proveedor varchar (50),
categoria varchar (20),
CantidadxUnidad varchar (50),
PrecioUnidad decimal(5,2),
constraint pkImportados_ primary key(id)
)
go


CREATE TABLE esquema_Producto.catalogo(
id int identity(1,1),
idImportados int,
categoria varchar (10),
nombre varchar (100),
precio decimal(3,2), 
precio_Referencia decimal(3,2), 
unidad_Referencia varchar (2),
horario time,
constraint pkCatalogos_ primary key(id),
constraint fkCatalogo_Importados foreign key (idImportados) 
references esquema_Producto.importado(id)

)
go


CREATE TABLE esquema_Producto.electronicos(
id int identity(1,1),
productoNombre varchar (100),
precioUniDolar decimal(7,2), 
constraint pkElectronicos_ primary key(id)
)
go




CREATE TABLE esquema_Producto.clasificacion(
id int identity (1,1),
idImportados int,
lineaProducto varchar (20),
productoDescrip varchar (50),
constraint pkClasificacion_Importados primary key(id),
constraint fkClasificacion foreign key(idImportados)
references esquema_Producto.importado(id)
)
go

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
go

alter table esquema_Sucursal.sucursales alter column horario varchar (50)
go


CREATE TABLE esquema_operaciones.mediosDePago(
identificadorDePago int identity (1,1),
NombreES varchar (50),
TarjetaDeCredito varchar (20),
constraint pkMediosDePago primary key (identificadorDePago)
)
go



CREATE TABLE esquema_Ventas.ventasRegistradas(
idFactura int not null, 
tipoDeFactura varchar (20) CHECK (tipoDeFactura LIKE 'A' OR tipoDeFactura LIKE 'B' OR tipoDeFactura LIKE 'C'),
ciudad varchar(15),
tipoDeCliente varchar(30),
genero varchar (20),
producto varchar(50),
precioUnitario decimal(3,2), ---CAMBIAR A DECIMAL
cantidad int,
fecha date,
hora time,
medioDePago varchar(20),
empleado int,
idIdentificador int,


--Foreign key de las tablas
idIdentificadorDePago int, ----MEDIO DE PAGO
idSucursales int,
idCliente int,
idEmpleado int,
idImportado int,
idElectronicos int,

constraint pkId primary key (idFactura), 


constraint fkPago_Ventas foreign key (idIdentificadorDePago)
references esquema_operaciones.MediosDePago (identificadorDePago),

constraint fkSucursales_Ventas foreign key (idSucursales)
references esquema_Sucursal.sucursales (id),

constraint fkCliente_Ventas foreign key (idCliente)
references esquema_Persona.cliente (id),

constraint fkEmpleado_Ventas foreign key (idEmpleado)
references esquema_Persona.empleado (legajo),

constraint fkImportado_Ventas foreign key (idImportado)
references esquema_Producto.importado (id),

constraint fkElectronicos_Ventas foreign key (idElectronicos) 
references esquema_Producto.electronicos
)
go









