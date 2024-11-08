use master
go

use ALMACEN_Grupo7
go


EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_configure;
go


---------------------MEDIOS DE PAGO

CREATE OR ALTER PROCEDURE esquema_operaciones.importarMediosDePago(@RutaArchivo NVARCHAR(MAX),@nombreHoja NVARCHAR(50))
AS 
BEGIN 
  BEGIN TRY 
     BEGIN TRANSACTION 
      SET XACT_ABORT ON 
       SET NOCOUNT ON 
       DECLARE @Consulta NVARCHAR(MAX) 
       DECLARE @ExisteArchivo INT 
        SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists 
(@RutaArchivo) AS T 
   IF @ExisteArchivo = 0 
    THROW 51000, 'El archivo XLSX no existe en la ruta especificada.', 1 
   ELSE 
   BEGIN 
    PRINT 'Se encontro el archivo XLSX'
	    CREATE TABLE #MediosDePagoTemporal1(
		Mediodepago varchar (20),
		Nombre varchar (50)
		)
-- Probar la consulta SELECT desde OPENROWSET para verificar columnas

SET @Consulta = N'
                SELECT TOP 1 *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
                    ''SELECT * FROM [' + @nombreHoja + ']''
                )'

            

           
-- Ejecutar la consulta de prueba
         
EXEC sp_executesql @Consulta;


	SET @Consulta = N'
	INSERT INTO #MediosDePagoTemporal1(Mediodepago,Nombre)
	SELECT Mediodepago, Nombre
	FROM OPENROWSET(
	''Microsoft.ACE.OLEDB.12.0'',
	''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
    ''SELECT * FROM ['+@nombreHoja+']'');'
	
	EXEC sp_executesql @Consulta;

	SELECT *FROM #MediosDePagoTemporal1;

	INSERT INTO esquema_operaciones.mediosDePago(medioDePago,NombreES)
	SELECT Mediodepago,Nombre
	FROM #MediosDePagoTemporal1

	PRINT 'Los datos se insertaron exitosamente' 
	DROP TABLE #MediosDePagoTemporal1
   END 
  COMMIT TRANSACTION 
 END TRY 
 BEGIN CATCH 
  PRINT 'No se pudieron importar los medios de pago de ' + @RutaArchivo 
  PRINT ERROR_MESSAGE() 
  ROLLBACK TRANSACTION 
 END CATCH 
END 
go
EXEC esquema_operaciones.importarMediosDePago @RutaArchivo = 'C:\Users\PC\Desktop\Grupo7-Supermecado\Archivos\Informacion_complementaria.xlsx',
@nombreHoja = 'medios de pago$'
go



------------------------------------EMPLEADOS

CREATE OR ALTER PROCEDURE esquema_Persona.importarEmpleado(@RutaArchivo NVARCHAR(MAX), @nombreHoja NVARCHAR(50))
AS 
BEGIN 
  BEGIN TRY 
     BEGIN TRANSACTION 
      SET XACT_ABORT ON 
       SET NOCOUNT ON 
       DECLARE @Consulta NVARCHAR(MAX) 
       DECLARE @ExisteArchivo INT 
       
       SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists(@RutaArchivo) AS T 
       IF @ExisteArchivo = 0 
           THROW 51000, 'El archivo XLSX no existe en la ruta especificada.', 1 
       ELSE 
       BEGIN 
           PRINT 'Se encontro el archivo XLSX'
           
           -- Crear tabla temporal para importar todos los datos del Excel
           CREATE TABLE #EmpleadoTemporal1 (
               Legajo INT,
               Nombre VARCHAR(50),
               Apellido VARCHAR(50),
               DNI INT,
               Direccion VARCHAR(200),
               emailpersonal VARCHAR(100),
               emailempresa VARCHAR(100),
               CUIL INT,
               Cargo VARCHAR(50),
               Sucursal VARCHAR(50),
               Turno VARCHAR(50)
           );

           -- Cargar datos desde el archivo Excel
           SET @Consulta = N'
           INSERT INTO #EmpleadoTemporal1 (Legajo, Nombre, Apellido, DNI, Direccion, emailpersonal, emailempresa, CUIL, Cargo, Sucursal, Turno)
           SELECT Legajo, Nombre, Apellido, DNI, Direccion, LEFT(emailpersonal, 100), LEFT(emailempresa, 100), CUIL, Cargo, Sucursal, Turno
           FROM OPENROWSET(
               ''Microsoft.ACE.OLEDB.12.0'',
               ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
               ''SELECT * FROM [' + @nombreHoja + ']''
           );';

           EXEC sp_executesql @Consulta;

           -- Crear tabla temporal para separar la dirección
           CREATE TABLE #EmpleadoCompleto (
               Legajo INT,
               Nombre VARCHAR(50),
               Apellido VARCHAR(50),
               DNI INT,
               emailpersonal VARCHAR(100),
               emailempresa VARCHAR(100),
               CUIL INT,
               Cargo VARCHAR(50),
               Sucursal VARCHAR(50),
               Turno VARCHAR(50),
               calleYNum VARCHAR(50),
               localidad VARCHAR(50),
               provincia VARCHAR(50)
           );

           -- Insertar datos en la tabla temporal de dirección separada
           INSERT INTO #EmpleadoCompleto (Legajo, Nombre, Apellido, DNI, emailpersonal, emailempresa, CUIL, Cargo, Sucursal, Turno, calleYNum, localidad, provincia)
           SELECT 
               Legajo,
               Nombre,
               Apellido,
               DNI,
               emailpersonal,
               emailempresa,
               CUIL,
               Cargo,
               Sucursal,
               Turno,
               PARSENAME(REPLACE(Direccion, ',', '.'), 3) AS calleYNum,
               PARSENAME(REPLACE(Direccion, ',', '.'), 2) AS localidad,
               PARSENAME(REPLACE(Direccion, ',', '.'), 1) AS provincia
           FROM #EmpleadoTemporal1;

           -- Verificar datos en #EmpleadoCompleto
           SELECT * FROM #EmpleadoCompleto;

           -- Insertar los datos finales en esquema_Persona.empleado
           INSERT INTO esquema_Persona.empleado (legajo, nombre, apellido, nroDoc, cuil, cargo, sucursal, turno, emailEmpresa, emailPersonal, calleYNum, localidad, provincia)
           SELECT 
               Legajo,
               Nombre,
               Apellido,
               DNI,
               CUIL,
               Cargo,
               Sucursal,
               Turno,
               emailempresa,
               emailpersonal,
               calleYNum,
               localidad,
               provincia
           FROM #EmpleadoCompleto
		   WHERE Legajo IS NOT NULL;

           PRINT 'Los datos se insertaron exitosamente' 
           
           -- Limpiar tablas temporales
           DROP TABLE #EmpleadoTemporal1;
           DROP TABLE #EmpleadoCompleto;
       END 
      COMMIT TRANSACTION 
  END TRY 
  BEGIN CATCH 
      PRINT 'No se pudieron importar los empleados de ' + @RutaArchivo 
      PRINT ERROR_MESSAGE() 
      ROLLBACK TRANSACTION 
  END CATCH 
END
GO
EXEC esquema_Persona.importarEmpleado @RutaArchivo = 'C:\Users\PC\Desktop\Grupo7-Supermecado\Archivos\Informacion_complementaria.xlsx',
@nombreHoja = 'Empleados$'
go



----------------------------IMPORTADOS

CREATE OR ALTER PROCEDURE esquema_Producto.importarImportado(@RutaArchivo NVARCHAR(MAX),@nombreHoja NVARCHAR(50))
AS 
BEGIN 
  BEGIN TRY 
     BEGIN TRANSACTION 
      SET XACT_ABORT ON 
       SET NOCOUNT ON 
       DECLARE @Consulta NVARCHAR(MAX) 
       DECLARE @ExisteArchivo INT 
        SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists 
(@RutaArchivo) AS T 
   IF @ExisteArchivo = 0 
    THROW 51000, 'El archivo XLSX no existe en la ruta especificada.', 1 
   ELSE 
   BEGIN 
    PRINT 'Se encontro el archivo XLSX'
	    CREATE TABLE #ImportadosTemporal1(
		NombreProducto varchar (100),
		Proveedor varchar (50),
		Categoría varchar (20),
		CantidadPorUnidad varchar (50),
		PrecioUnidad varchar(100)
		)
-- Probar la consulta SELECT desde OPENROWSET para verificar columnas

SET @Consulta = N'
                SELECT TOP 1 *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
                    ''SELECT * FROM [' + @nombreHoja + ']''
                )'

            

           
-- Ejecutar la consulta de prueba
         
EXEC sp_executesql @Consulta;


	SET @Consulta = N'
	INSERT INTO #ImportadosTemporal1(NombreProducto,Proveedor,Categoría,CantidadPorUnidad,PrecioUnidad)
	SELECT NombreProducto,Proveedor,Categoría,CantidadPorUnidad,PrecioUnidad
	FROM OPENROWSET(
	''Microsoft.ACE.OLEDB.12.0'',
	''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
    ''SELECT * FROM ['+@nombreHoja+']'');'
	
	EXEC sp_executesql @Consulta;

	SELECT *FROM #ImportadosTemporal1;

	INSERT INTO esquema_Producto.importado(nombreproducto,Proveedor,categoria,CantidadxUnidad,PrecioUnidad)
	SELECT NombreProducto,Proveedor,Categoría,CantidadPorUnidad,cast(PrecioUnidad as decimal(12,2)) 
	FROM #ImportadosTemporal1

	PRINT 'Los datos se insertaron exitosamente' 
	DROP TABLE #ImportadosTemporal1 
   END 
  COMMIT TRANSACTION 
 END TRY 
 BEGIN CATCH 
  PRINT 'No se pudieron importar los poductos importados de ' + @RutaArchivo 
  PRINT ERROR_MESSAGE() 
  ROLLBACK TRANSACTION 
 END CATCH 
END 
	
go

EXEC esquema_Producto.importarImportado @RutaArchivo ='C:\Users\PC\Desktop\Grupo7-Supermecado\Archivos\Productos\Productos_importados.xlsx', 
@nombreHoja = 'Listado de Productos$'
go




--------------------------ELECTRONICOS

CREATE OR ALTER PROCEDURE esquema_Producto.importarElectronico(@RutaArchivo NVARCHAR(MAX),@nombreHoja NVARCHAR(50))
AS 
BEGIN 
  BEGIN TRY 
     BEGIN TRANSACTION 
      SET XACT_ABORT ON 
       SET NOCOUNT ON 
       DECLARE @Consulta NVARCHAR(MAX) 
       DECLARE @ExisteArchivo INT 
        SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists 
(@RutaArchivo) AS T 
   IF @ExisteArchivo = 0 
    THROW 51000, 'El archivo XLSX no existe en la ruta especificada.', 1 
   ELSE 
   BEGIN 
    PRINT 'Se encontro el archivo XLSX'
	    CREATE TABLE #ElectronicoTemporal1(
		Product varchar(100),
		PrecioUnitarioendolares varchar(100)
		)
-- Probar la consulta SELECT desde OPENROWSET para verificar columnas

SET @Consulta = N'
                SELECT TOP 1 *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
                    ''SELECT * FROM [' + @nombreHoja + ']''
                )'

            

           
-- Ejecutar la consulta de prueba
         
EXEC sp_executesql @Consulta;


	SET @Consulta = N'
	INSERT INTO #ElectronicoTemporal1(Product,PrecioUnitarioendolares)
	SELECT Product,PrecioUnitarioendolares
	FROM OPENROWSET(
	''Microsoft.ACE.OLEDB.12.0'',
	''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
    ''SELECT * FROM ['+@nombreHoja+']'');'
	
	EXEC sp_executesql @Consulta;

	SELECT *FROM #ElectronicoTemporal1;

	INSERT INTO esquema_Producto.electronicos(productoNombre,precioUniDolar)
	SELECT Product,cast (PrecioUnitarioendolares as decimal(10,2))  
	FROM #ElectronicoTemporal1

	PRINT 'Los datos se insertaron exitosamente' 
	DROP TABLE #ElectronicoTemporal1 
   END 
  COMMIT TRANSACTION 
 END TRY 
 BEGIN CATCH 
  PRINT 'No se pudieron importar los poductos electronicos de ' + @RutaArchivo 
  PRINT ERROR_MESSAGE() 
  ROLLBACK TRANSACTION 
 END CATCH 
END 
	
go

EXEC esquema_Producto.importarElectronico   @RutaArchivo = 'C:\Users\PC\Desktop\Grupo7-Supermecado\Archivos\Productos\Electronic accessories.xlsx', 
@nombreHoja ='Sheet1$' 
go
select*from esquema_Producto.electronicos





-------------------------CLASIFICACION

CREATE OR ALTER PROCEDURE esquema_Producto.importarClasificacion(@RutaArchivo NVARCHAR(MAX),@nombreHoja NVARCHAR(50))
AS 
BEGIN 
  BEGIN TRY 
     BEGIN TRANSACTION 
      SET XACT_ABORT ON 
       SET NOCOUNT ON 
       DECLARE @Consulta NVARCHAR(MAX) 
       DECLARE @ExisteArchivo INT 
        SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists 
(@RutaArchivo) AS T 
   IF @ExisteArchivo = 0 
    THROW 51000, 'El archivo XLSX no existe en la ruta especificada.', 1 
   ELSE 
   BEGIN 
    PRINT 'Se encontro el archivo XLSX'
	    CREATE TABLE #ClasificacionTemporal1(
		Líneadeproducto varchar (20),
		Producto varchar (50)
		)
-- Probar la consulta SELECT desde OPENROWSET para verificar columnas

SET @Consulta = N'
                SELECT TOP 1 *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
                    ''SELECT * FROM [' + @nombreHoja + ']''
                )'

            

           
-- Ejecutar la consulta de prueba
         
EXEC sp_executesql @Consulta;


	SET @Consulta = N'
	INSERT INTO #ClasificacionTemporal1(Líneadeproducto,Producto)
	SELECT Líneadeproducto,Producto
	FROM OPENROWSET(
	''Microsoft.ACE.OLEDB.12.0'',
	''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
    ''SELECT * FROM ['+@nombreHoja+']'');'
	
	EXEC sp_executesql @Consulta;

	SELECT *FROM #ClasificacionTemporal1;

	INSERT INTO esquema_Producto.clasificacion(lineaProducto,productoDescrip)
	SELECT Líneadeproducto,Producto
	FROM #ClasificacionTemporal1

	PRINT 'Los datos se insertaron exitosamente' 
	DROP TABLE #ClasificacionTemporal1 
   END 
  COMMIT TRANSACTION 
 END TRY 
		 BEGIN CATCH 
			  PRINT 'No se pudieron importar las clasificaciones de ' + @RutaArchivo 
			  PRINT ERROR_MESSAGE() 
			  ROLLBACK TRANSACTION 
		 END CATCH 
END 
go

EXEC esquema_Producto.importarClasificacion @RutaArchivo = 'C:\Users\PC\Desktop\Grupo7-Supermecado\Archivos\Informacion_complementaria.xlsx', 
@nombreHoja = 'Clasificacion productos$'
go
select * from esquema_Producto.clasificacion



-----------------------CATALOGO

CREATE OR ALTER PROCEDURE esquema_Producto.importarCatalogo (@RutaArchivo NVARCHAR(MAX))  
AS 
BEGIN 
		BEGIN TRY 
				BEGIN TRANSACTION 
					SET XACT_ABORT ON 
					SET NOCOUNT ON 
					DECLARE @Consulta NVARCHAR(MAX) 
					DECLARE @ExisteArchivo INT 
					SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists 
						(@RutaArchivo) AS T 
					IF @ExisteArchivo = 0 
						THROW 51000, 'El archivo CSV no existe en la ruta especificada.', 1 
					ELSE 
					  BEGIN 
						PRINT 'Se encontro el archivo CSV' 
						CREATE TABLE #CatalogoTemporal (
									 id varchar(100),
									 categoria varchar (100),
									 nombre varchar (100),
									 precio varchar (100) , --CAMBIAR A DECIMAL
									 precio_Referencia varchar (100) , ---CAMBIAR A DECIMAL
									 unidad_Referencia varchar (100),
									 horario varchar (100) 
						) 
						SET @Consulta = N' 
						 BULK INSERT #CatalogoTemporal 
						 FROM ''' + @RutaArchivo + ''' 
						 WITH ( 
						  FORMAT=''CSV'',
						  FIELDTERMINATOR = '','', 
						  ROWTERMINATOR = ''0x0a'', 
						  CODEPAGE = ''65001'',
						  FIRSTROW = 2
						 );';  
 
						exec sp_executesql @consulta 
						select * from #CatalogoTemporal
--					    insert into esquema_producto.catalogo (id ,categoria,nombre,precio ,precio_referencia,unidad_referencia,horario)
						select cast(id as int),categoria,nombre,cast(precio as decimal(10,2)),cast(precio_referencia as decimal(10,2)),unidad_referencia,cast(horario as datetime) from #CatalogoTemporal 
						print 'los datos se insertaron exitosamente' 
						DROP TABLE #CatalogoTemporal 
					  END 
				COMMIT TRANSACTION 
		END TRY 
		BEGIN CATCH 
			PRINT 'No se pudieron importar los catalogos de ' + @RutaArchivo 
			PRINT ERROR_MESSAGE() 
			ROLLBACK TRANSACTION 
		END CATCH 
END 
go 
EXEC esquema_Producto.importarCatalogo 'C:\Users\PC\Desktop\Grupo7-Supermecado\Archivos\Productos\catalogo.csv'
go
select *from esquema_Producto.importado



-----------------Sucursal
CREATE OR ALTER PROCEDURE esquema_Sucursal.importarSucursal(@RutaArchivo NVARCHAR(MAX), @nombreHoja NVARCHAR(50))
AS 
BEGIN 
  BEGIN TRY 
     BEGIN TRANSACTION 
      SET XACT_ABORT ON 
       SET NOCOUNT ON 
       DECLARE @Consulta NVARCHAR(MAX) 
       DECLARE @ExisteArchivo INT 
       
       SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists(@RutaArchivo) AS T 
       IF @ExisteArchivo = 0 
           THROW 51000, 'El archivo XLSX no existe en la ruta especificada.', 1 
       ELSE 
       BEGIN 
           PRINT 'Se encontro el archivo XLSX'
           
           -- Crear tabla temporal para importar todos los datos del Excel
           CREATE TABLE #SucursalTemporal1 (
               Ciudad varchar (15),
			   Reemplazarpor VARCHAR (50),
               Direccion VARCHAR(200),
			   Horario time,
			   Telefono int,
               
           );

           -- Cargar datos desde el archivo Excel
           SET @Consulta = N'
           INSERT INTO #SucursalTemporal1 (Ciudad,Reemplazarpor,Direccion,Horario,Telefono)
           SELECT Ciudad,Reemplazarpor,Direccion,Horario,Telefono
           FROM OPENROWSET(
               ''Microsoft.ACE.OLEDB.12.0'',
               ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
               ''SELECT * FROM [' + @nombreHoja + ']''
           );';

           EXEC sp_executesql @Consulta;

-- Crear tabla temporal para separar la dirección
           CREATE TABLE #SucursalCompleto (
               Ciudad varchar (15),
			   Reemplazarpor VARCHAR (50),
			   calleYNum varchar(50),
			   localidadYCodPostal varchar(50),
			   provincia varchar(50),
			   Horario varchar(50),
			   Telefono int,
           );

           -- Insertar datos en la tabla temporal de dirección separada
           INSERT INTO #SucursalCompleto (Ciudad,Reemplazarpor,calleYNum,localidadYCodPostal,provincia,Horario,Telefono)
           SELECT 
               Ciudad, 
			   Reemplazarpor, 
			   Horario ,
			   Telefono,
               PARSENAME(REPLACE(Direccion, ',', '.'), 3) AS calleYNum,
               PARSENAME(REPLACE(Direccion, ',', '.'), 2) AS localidadYCodPostal,
               PARSENAME(REPLACE(Direccion, ',', '.'), 1) AS provincia
           FROM #SucursalTemporal1;

           -- Verificar datos en #SucursalCompleto
           SELECT * FROM #SucursalCompleto;

		    -- Insertar los datos finales en esquema_Sucursal
           INSERT INTO esquema_Sucursal.sucursales(ciudad,reemplazadaX,horario,telefono,calleYNum,localidadYCodPostal,provincia)
           SELECT 
		       Ciudad,
			   Reemplazarpor,
			   calleYNum ,
			   localidadYCodPostal,
			   provincia,
			   Horario ,
			   Telefono    
           FROM #SucursalCompleto;

           PRINT 'Los datos se insertaron exitosamente' 
           
           -- Limpiar tablas temporales
           DROP TABLE #SucursalTemporal1;
           DROP TABLE #SucursalCompleto;
       END 
      COMMIT TRANSACTION 
  END TRY 
  BEGIN CATCH 
      PRINT 'No se pudieron importar las sucursales de ' + @RutaArchivo 
      PRINT ERROR_MESSAGE() 
      ROLLBACK TRANSACTION 
  END CATCH 
END
GO
EXEC esquema_Sucursal.importarSucursal @RutaArchivo = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\TP_integrador_Archivos\Informacion_complementaria.xlsx', @nombreHoja = 'sucursal$'
GO



-------------------VENTAS

CREATE OR ALTER PROCEDURE esquema_Ventas.importarVentasRegistradas (@RutaArchivo NVARCHAR(MAX)) 
AS 
BEGIN 
		BEGIN TRY 
				BEGIN TRANSACTION 
						  SET XACT_ABORT ON 
						  SET NOCOUNT ON 
						  DECLARE @Consulta NVARCHAR(MAX) 
						  DECLARE @ExisteArchivo INT 
						  SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists (@RutaArchivo) AS T 
						  IF @ExisteArchivo = 0 
								THROW 51000, 'El archivo CSV no existe en la ruta especificada.', 1 
						  ELSE 
						  BEGIN 
								PRINT 'Se encontro el archivo CSV' 
								CREATE TABLE #VentasRegisTemp ( 
								idFactura varchar (100), 
								tipoDeFactura varchar (100),
								ciudad varchar(100),
								tipoDeCliente varchar(100),
								genero varchar (100),
								producto varchar(100),
								precioUnitario varchar (100), 
								cantidad varchar (100),
								fecha varchar (100),
								hora varchar (100),
								medioDePago varchar(100),
								empleado varchar (100),
								idIdentificador varchar (100) 
								) 
 
								SET @Consulta = N' 
								 BULK INSERT #VentasRegisTemp 
								 FROM ''' + @RutaArchivo + ''' 
								 WITH ( 
								  FORMAT=''CSV'',
								  FIELDTERMINATOR = '';'', 
								  ROWTERMINATOR = ''0x0a'', 
								  CODEPAGE =''65001'',  
								  FIRSTROW = 2 
								 );' 

								EXEC sp_executesql @consulta
								SELECT * FROM #VentasRegisTemp;
								
--								INSERT INTO esquema_Ventas.ventasRegistradas(idFactura, tipoDeFactura, ciudad, tipoDeCliente, producto,
--								cantidad, precioUnitario, fecha, hora, medioDePago, genero, empleado, idIdentificador)
--								SELECT idFactura, tipoDeFactura, ciudad, tipoDeCliente, producto, cantidad, precioUnitario, 
--								TRY_CAST(fecha AS date) AS fecha,  -- Usa TRY_CAST para convertir a fecha y manejar errores
--								hora, medioDePago, genero, empleado, idIdentificador FROM #VentasRegisTemp
--								WHERE idFactura IS NOT NULL AND TRY_CAST(fecha AS date) IS NOT NULL;
     
								PRINT 'Los datos se insertaron exitosamente' 
								DROP TABLE #VentasRegisTemp 
					 END 
				COMMIT TRANSACTION 
		END TRY 
		BEGIN CATCH 
    PRINT 'No se pudieron importar los datos de ' + @RutaArchivo; 
    PRINT ERROR_MESSAGE(); 
    PRINT 'Error en el procedimiento: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
    ROLLBACK TRANSACTION; 
END CATCH;
 END 
go
EXEC esquema_Ventas.importarVentasRegistradas @RutaArchivo = 'C:\Users\PC\Desktop\Grupo7-Supermecado\Archivos\Ventas_registradas.csv'
go
