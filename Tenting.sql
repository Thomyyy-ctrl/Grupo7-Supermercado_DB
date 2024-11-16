use master
go

use SUPERMERCADO_Grupo7
go

-----------------TESTING ENTREGA N°3
------------SUCURSALES
---FUNCIONA
exec esquema_Sucursal.insertarSucursal 'AMBA','fam','Zapata 5664','La Matanza 1757','Buenos Aires','9 a 12','23434341'
go
select* from esquema_Sucursal.sucursales
go
exec esquema_Sucursal.modificarSucursal 6,'AMBA','fam','Zapata 5664','La Matanza 1757','Buenos Aires','12 a 16','23434341'
go
select* from esquema_Sucursal.sucursales
go
exec esquema_Sucursal.eliminarSucursal 6
go
select* from esquema_Sucursal.sucursales
go
------------EMPLEADOS
---FALLA PORQUE LA SUCURSAL CON ID 4 NO EXISTE
exec esquema_Persona.insertarEmpleado 2142,'Martin','Diaz',4542,'Zapata 5664', 'La Matanza','Buenos Aires',24215,'Cajero','fem','tarde','martin@gmail.com','trabajo@gmail.com',4
go
select* from esquema_Persona.empleado
GO
---FALLA PORQUE El empleado con el ID y legajo especificados no existe.
exec esquema_Persona.modificarEmpleado 1,2142,'Martin','Diaz',4542,'Zapata 5664', 'La Matanza','Buenos Aires',24215,'Repositor','fem','mañana','martin@gmail.com','trabajo@gmail.com',2
go
select* from esquema_Persona.empleado
GO
exec esquema_Persona.eliminarEmpleado  4, 2142
go
select* from esquema_Persona.empleado
go


------------TIPO DE CLIENTE
---FUNCIONA
exec esquema_Persona.insertarTipoDeCliente 'miembro','0000000.'
go
select* from esquema_Persona.cliente
go

exec esquema_Persona.modificarTipoDeCliente 2,'miembro','1111111.'
go
select* from esquema_Persona.cliente
go
---FALLA POR QUE EL ID DE TIPO DE CLIENTE NO EXISTE
exec esquema_Persona.eliminarTipoDeCliente 1
go
select* from esquema_Persona.cliente
go

-------------MEDIOS DE PAGO
---FUNCIONA
exec esquema_operaciones.insertarMedioDePago 'cash','Efectivo'
go
select* from esquema_operaciones.MediosDePago
go

exec esquema_operaciones.modificarMedioDePago 1,'Ewallet','Billetera Virtual'
go
select* from esquema_operaciones.MediosDePago
go

exec esquema_operaciones.eliminarMedioDePago 8
go
select* from esquema_operaciones.MediosDePago
go

----------------LINEA DE PRODUCTO
--NO FUNCIONA PORQUE El ID de linea producto proporcionado existe en la tabla
exec esquema_Producto.insertarLineaDeProducto  1, 'perfumria','jabon'
go
select* from esquema_Producto.LineaDeProducto
go
----FUNCIONA
exec esquema_Producto.modificarLineaDeProducto 2, 'almacen','jabon'
go
select* from esquema_Producto.LineaDeProducto
go

exec esquema_Producto.eliminarLineaDeProducto 2
go
select* from esquema_Producto.LineaDeProducto
go

----------------PRODUCTO

--PRUEBA TABLA PRODUCTOS
--NO FUNCIONA PORQUE Ya existe un producto con el idCatalogo 1. El id debe ser único.
EXEC esquema_Producto.insertarProducto 1, 'Electrónica', 'Smartphone XYZ', 699.99, 750.00, 'Unidad', '2024-11-13 10:30:00', 101, 'Smartphone XYZ Modelo 2024', 'ProveedorTech', 'Móviles', '1 unidad', 699.99, 'Smartphone XYZ', 699.99;
GO

EXEC esquema_Producto.insertarProducto 2, 'Alimentos', 'Café Premium', 12.50, 15.00, 'Paquete', '2024-11-13 08:00:00', 102, 'Café Premium Orgánico', 'CaféOrgánico S.A.', 'Bebidas', '500 g', 12.50, NULL,  0.00
GO

EXEC esquema_Producto.insertarProducto 3, 'Electrónica', 'Laptop XYZ 2024', 999.99, 1099.99, 'Unidad', '2024-11-14 09:00:00', 0, 'Laptop XYZ 2024', 'Proveedor ABC',  'Computadoras', '1', 999.99, 'Laptop XYZ 2024', 999.99;  
GO

select * from [esquema_Producto].[Producto]
GO

-- MODIFICAR PRODUCTO EXISTENTE 
--NO FUNCIANA Ya existe un producto con el idImportado 2000. El id debe ser único.
EXEC esquema_Producto.modificarProducto    3, 'Electrónica',  'Laptop XYZ 2024 - Actualizada', 899.99, 999.99,  'Unidad', '2024-11-14 09:00:00',   2000, 'Laptop XYZ 2024 - Actualizada', 'Proveedor ABC', 'Computadoras', '1', 899.99, 'Laptop XYZ 2024 - Actualizada',  899.99;
GO

SELECT * from [esquema_Producto].[Producto]
GO
----ELIMINAR PRODUCTOS
----FUNCIONA
EXEC esquema_Producto.eliminarProducto 9  
GO
SELECT * from [esquema_Producto].[Producto]
GO
----------------VENTA

--PRUEBA TABLA VENTAS
--- Caso de prueba 1: Venta de Smartphone XYZ
EXEC esquema_Ventas.insertarVentas  1001, 'A', 'Madrid', 'Particular', 'Male', 'Smartphone XYZ Modelo 2024', 9.9, 1, '2024-11-13', '10:45:00', 'Billetera Virtual', 1, 'FACT-XYZ-1001';
GO
--- Caso de prueba 2: Venta de Café Premium
EXEC esquema_Ventas.insertarVentas  1002, 'B', 'Barcelona', 'Empresa', 'Female', 'Café Premium Orgánico', 2.5, 10, '2024-11-13', '09:15:00', 'Billetera Virtual', 1, 'FACT-CAFE-1002';
GO
SELECT * FROM [esquema_Ventas].[ventasRegistradas]
GO

--PRUEBA TABLA DETALLE VENTAS
--- Caso de prueba 1: Venta de Café Premium
EXEC esquema_operaciones.insertarDetalleDeVenta  1001, 102, 'Café Premium', 12.50, 10, 125.00, 1;
GO

--- Caso de prueba 2: Venta de Smartphone XYZ
EXEC esquema_operaciones.insertarDetalleDeVenta  1002, 101, 'Smartphone XYZ Modelo 2024', 9.9, 1, 9.9, 2;
GO

SELECT * FROM [esquema_operaciones].[DetalleDeVenta]
GO

--PRUEBA TABLA INSERTAR FACTURA
--- Caso de prueba 1: Venta de Café Premium
EXEC esquema_operaciones.insertarFactura    1001,  2001, '2024-11-14', '10:30:00', 1, 125.00,  'A',  'Ciudad A','Tarjeta de Crédito',  1;
GO

-- Caso de prueba 2: Venta de Smartphone XYZ  
EXEC esquema_operaciones.insertarFactura    1002, 2002,  '2024-11-14',  '11:00:00',   1, 9.90,  'B',  'Ciudad B', 'Efectivo', 1;
GO

SELECT * FROM [esquema_operaciones].[Factura]
GO

---ELIMINAR VENTA

exec esquema_Ventas.eliminarVenta 6
GO

SELECT * from [esquema_Ventas].[ventasRegistradas]
GO

---TESTING DE ENTREGA NRO 4

--IMPORTAR MEDIOS DE PAGO
EXEC esquema_operaciones.importarMediosDePago @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx',
@nombreHoja = 'medios de pago$'
go

--IMPORTAR EMPLEADOS
EXEC esquema_Persona.importarEmpleado @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx',
@nombreHoja = 'Empleados$'
go

--IMPORTAR IMPORTADOS
EXEC esquema_Producto.importarImportados @RutaArchivo ='C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Productos\Productos_importados.xlsx',
@nombreHoja = 'Listado de Productos$'
go

--IMPORTAR ELECTRICO
EXEC esquema_Producto.importarElectronico   @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Productos\Electronic accessories.xlsx', 
@nombreHoja ='Sheet1$' 
go

--IMPORTAR LINEA PRODUCTO
EXEC esquema_Producto.importarLineDeProducto @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx', 
@nombreHoja = 'Clasificacion productos'
go

--IMPORTAR CATALOGO
EXEC esquema_Producto.importarCatalogo 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Productos\catalogo.csv'
go

--IMPORTAR SUCURSAL
EXEC esquema_Sucursal.importarSucursal @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx',
@nombreHoja = 'sucursal$'
GO

--IMPORTAR VENTAS REGISTRADAS
EXEC esquema_Ventas.importarVentasRegistradas @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Ventas_registradas.csv'
go

---TESTING ENTREGA NRO 5

--Seguridad
execute as user = 'ThomasPerez'---ejecuto el usuario cajero
go

execute as user = 'MartinaGarcia'--ejecuto el usuario supervisor
go


select USER_NAME();--Verifico el usuario

EXEC esquema_operaciones.insertarNotaDeCredito--pruebo si el rol puede ejecutar el SP de nota de credito
    @nroFactura = 12345,
    @tipoDeFactura = 'Factura A',
    @TipoDeCliente = 'Minorista',
    @Fecha = '2024-11-15',  -- Valor especificado para la fecha
    @Valor = 1000.50,
    @Motivo = 'Devolución de productos',
    @idFactura = 5678,
    @idCliente = 91011;
go


revert--Vuelo al rol de dbo
go


--OBTENER EMPLEADO
exec esquema_Persona.ObtenerEmpleadoDesencriptado 1
GO

--INSERTAR NOTA DE CREDITO
exec esquema_operaciones.insertarNotaDeCredito 2001, 'A', 'miembro', '2024-11-14', 125.00, 'Consecuencia', 1, 1 --No se ejecutara porque necesita permisos de supervisor
GO

---PRUEBA DE EJECUCION REPORTES
--Llamada reporte mensual
EXEC esquema_Ventas.GenerarReporteMensualXML @Mes = 3, @Año = 2019;
GO
--Llamada reporte trimestral
EXEC esquema_Ventas.GenerarReporteTrimestralXML @Trimestre = 1, @Año = 2019;
GO
--Llamada reporte por rango fecha
EXEC esquema_Ventas.GenerarReportePorRangoFechasXML '2019-01-01', '2019-03-20';
GO

--Llamada al procedimiento almacenado pasando los valores directamente
EXEC esquema_Ventas.GenerarReporteVentasExtendidoXML 
    '2019-01-01',         -- FechaInicio
    '2019-03-01',         -- FechaFin
    '2019-01-01',         -- MesAño (aquí pasas un valor de fecha)
    '2019-02-01',         -- FechaEspecifica
    'Yangon';             -- SucursalCiudad
GO


