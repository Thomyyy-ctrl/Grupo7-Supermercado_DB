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


---------------------MEDIOS DE PAGO--------
----------FUNCIONA-------TABLAS CON VARCHAR
CREATE OR ALTER PROCEDURE esquema_operaciones.importarMediosDePago(@RutaArchivo NVARCHAR(MAX), @nombreHoja NVARCHAR(50))
AS 
BEGIN 
    BEGIN TRY 
        BEGIN TRANSACTION 
        SET XACT_ABORT ON 
        SET NOCOUNT ON 
       
        DECLARE @Consulta NVARCHAR(MAX) 
        DECLARE @ExisteArchivo INT 
       
        -- Verificar si el archivo existe
        SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists(@RutaArchivo) AS T 
        IF @ExisteArchivo = 0 
        BEGIN
            RAISERROR ('El archivo XLSX no existe en la ruta especificada.', 16, 1);
            RETURN;
        END
        ELSE 
        BEGIN 
            PRINT 'Se encontró el archivo XLSX';
           
            -- Crear tabla temporal para importar los datos del Excel
            CREATE TABLE #MediosDePagoTemporal1 (
                Mediodepago VARCHAR(20),
                Nombre VARCHAR(50)
            );

            -- Probar la consulta SELECT desde OPENROWSET para verificar columnas
            SET @Consulta = N'
                SELECT TOP 1 *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
                    ''SELECT * FROM [' + @nombreHoja + ']''
                )';
          
            -- Ejecutar la consulta de prueba
            EXEC sp_executesql @Consulta;

            -- Cargar datos desde el archivo Excel
            SET @Consulta = N'
                INSERT INTO #MediosDePagoTemporal1 (Mediodepago, Nombre)
                SELECT Mediodepago, Nombre
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
                    ''SELECT * FROM [' + @nombreHoja + ']''
                );';
            EXEC sp_executesql @Consulta;

            -- Verificar datos en #MediosDePagoTemporal1
            SELECT * FROM #MediosDePagoTemporal1;

            -- Insertar los datos finales en la tabla destino
            INSERT INTO esquema_operaciones.mediosDePago (medioDePago, NombreES)
            SELECT Mediodepago, Nombre
            FROM #MediosDePagoTemporal1;

            PRINT 'Los datos se insertaron exitosamente';

            -- Limpiar tabla temporal
            DROP TABLE #MediosDePagoTemporal1;
        END 

        COMMIT TRANSACTION 
    END TRY 
    BEGIN CATCH 
        -- Imprimir mensaje de error y detalles del mismo
        PRINT 'No se pudieron importar los medios de pago de ' + @RutaArchivo;

        -- Obtener detalles del error
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Levantar el error con los detalles obtenidos
        RAISERROR ('Error al importar los medios de pago: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);

        -- Revertir la transacción
        ROLLBACK TRANSACTION;
    END CATCH 
END 
GO
EXEC esquema_operaciones.importarMediosDePago @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx',
@nombreHoja = 'medios de pago$'
go



------------------------------------EMPLEADOS-------------------------------------
-------FUNCIONA----------TABLAS TEMPORALES CON VARCHAR Y DESPUES SE CASTEA EL DATO

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
        BEGIN
            RAISERROR ('El archivo XLSX no existe en la ruta especificada.', 16, 1);
            RETURN;
		END
       ELSE 
       BEGIN 
           PRINT 'Se encontro el archivo XLSX'
           
           -- Crear tabla temporal para importar todos los datos del Excel
           CREATE TABLE #EmpleadoTemporal1 (
               Legajo VARCHAR(50),
               Nombre VARCHAR(50),
               Apellido VARCHAR(50),
               DNI VARCHAR(50),
               Direccion VARCHAR(200),
               emailpersonal VARCHAR(100),
               emailempresa VARCHAR(100),
               CUIL VARCHAR(50),
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
               Legajo VARCHAR(50),
               Nombre VARCHAR(50),
               Apellido VARCHAR(50),
               DNI VARCHAR(50),
               emailpersonal VARCHAR(100),
               emailempresa VARCHAR(100),
               CUIL VARCHAR(50),
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
               TRY_CAST(Legajo AS INT),
               Nombre,
               Apellido,
               TRY_CAST(DNI AS INT),
               TRY_CAST(CUIL AS INT),
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
      PRINT ERROR_MESSAGE();
	  DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        
        -- Obtener detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
	  -- Levantar el error con los detalles obtenidos
      RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
      ROLLBACK TRANSACTION 
  END CATCH 
END
GO
EXEC esquema_Persona.importarEmpleado @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx',
@nombreHoja = 'Empleados$'
go



----------------------------PRODUCTOS IMPORTADOS-----TABLA PRODUCTO
----------FUNCIONA------- TABLAS CON VARCHAR
CREATE OR ALTER PROCEDURE esquema_Producto.importarImportados
    @RutaArchivo NVARCHAR(MAX),
    @nombreHoja NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
            SET XACT_ABORT ON
            SET NOCOUNT ON

            DECLARE @Consulta NVARCHAR(MAX)
            DECLARE @ExisteArchivo INT

            -- Verificar si el archivo existe
            SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists(@RutaArchivo) AS T
            IF @ExisteArchivo = 0
            BEGIN
            RAISERROR ('El archivo XLSX no existe en la ruta especificada.', 16, 1);
            RETURN;
		END
       ELSE 
            BEGIN
                PRINT 'Se encontró el archivo XLSX'

                -- Crear tabla temporal para importar los datos del Excel
                CREATE TABLE #ImportadosTemporal1 (
                    IdProducto VARCHAR(50),
                    NombreProducto VARCHAR(150),
                    Proveedor VARCHAR(50),
                    Categoria VARCHAR(20),
                    CantidadPorUnidad VARCHAR(50),
                    PrecioUnidad VARCHAR(50)
                )

                -- Cargar datos desde el archivo Excel
                SET @Consulta = N'
                INSERT INTO #ImportadosTemporal1 (IdProducto, NombreProducto, Proveedor, Categoria, CantidadPorUnidad, PrecioUnidad)
                SELECT 
                    ISNULL(IdProducto, NULL) AS IdProducto, 
                    ISNULL(NombreProducto, NULL) AS NombreProducto,
                    ISNULL(Proveedor, NULL) AS Proveedor,
                    ISNULL(Categoría, NULL) AS Categoria,
                    ISNULL(CantidadPorUnidad, NULL) AS CantidadPorUnidad,
                    ISNULL(PrecioUnidad, NULL) AS PrecioUnidad
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
                    ''SELECT * FROM [' + @nombreHoja + ']''
                );'

                EXEC sp_executesql @Consulta;

                -- Verificar los datos importados en la tabla temporal
                SELECT * FROM #ImportadosTemporal1;

                -- Insertar los datos finales en la tabla esquema_Producto.Producto
                INSERT INTO esquema_Producto.Producto(idImportado, nombreproducto, Proveedor, categoria, CantidadxUnidad, PrecioUnidad)
                SELECT 
                    TRY_CAST(IdProducto AS INT),
                    NombreProducto,
                    Proveedor,
                    Categoria,
                    CantidadPorUnidad,
                    TRY_CAST(PrecioUnidad AS DECIMAL(5,2))
                FROM #ImportadosTemporal1
				  


                PRINT 'Los datos se insertaron exitosamente'

                -- Limpiar la tabla temporal
                DROP TABLE #ImportadosTemporal1;
            END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        PRINT 'No se pudieron importar los productos importados de ' + @RutaArchivo
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        
        -- Obtener detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
	  -- Levantar el error con los detalles obtenidos
      RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
      ROLLBACK TRANSACTION 
  END CATCH 
END
GO

EXEC esquema_Producto.importarImportado @RutaArchivo ='C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Productos\Productos_importados.xlsx',
@nombreHoja = 'Listado de Productos$'
go


--------------------------ELECTRONICOS------TABLA PRODUCTO
----------FUNCIONA------- TABLAS CON VARCHAR
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
     BEGIN
            RAISERROR ('El archivo XLSX no existe en la ruta especificada.', 16, 1);
            RETURN;
		END
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
	SELECT Product,[Precio Unitario en dolares] as PrecioUnitarioendolares
	FROM OPENROWSET(
	''Microsoft.ACE.OLEDB.12.0'',
	''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
    ''SELECT * FROM ['+@nombreHoja+']'');'
	
	EXEC sp_executesql @Consulta;

	SELECT *FROM #ElectronicoTemporal1;

	INSERT INTO esquema_Producto.Producto(productoElectronicoNombre,precioUniDolar)
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
  DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        
        -- Obtener detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
	  -- Levantar el error con los detalles obtenidos
      RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
      ROLLBACK TRANSACTION 
  END CATCH 
END 	
GO

EXEC esquema_Producto.importarElectronico   @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Productos\Electronic accessories.xlsx', 
@nombreHoja ='Sheet1$' 
go






-------------------------LINEA DE PRODUCTO--------
-----FUNCIONA-----TABLAS TEMPORALES CON VARCHAR

CREATE OR ALTER PROCEDURE esquema_Producto.importarLineDeProducto
    @RutaArchivo NVARCHAR(MAX),
    @nombreHoja NVARCHAR(80)
AS 
BEGIN 
    BEGIN TRY 
        BEGIN TRANSACTION 
            SET XACT_ABORT ON 
            SET NOCOUNT ON 
            
            DECLARE @Consulta NVARCHAR(MAX) 
            DECLARE @ExisteArchivo INT 
            
            -- Verificar si el archivo existe
            SELECT @ExisteArchivo = T.file_exists 
            FROM sys.dm_os_file_exists(@RutaArchivo) AS T 
            
            IF @ExisteArchivo = 0 
            BEGIN
                RAISERROR ('El archivo XLSX no existe en la ruta especificada.', 16, 1);
                RETURN;
            END
            ELSE 
            BEGIN 
                PRINT 'Se encontró el archivo XLSX';
                
                -- Crear tabla temporal para importar los datos del Excel
                    CREATE TABLE #ClasificacionTemporal1(
                    Lineadeproducto VARCHAR(20),
                    Producto VARCHAR(200)
                )

                -- Probar la consulta SELECT desde OPENROWSET para verificar columnas
                SET @Consulta = N'
                    SELECT TOP 1 *
                    FROM OPENROWSET(
                        ''Microsoft.ACE.OLEDB.12.0'',
                        ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
                        ''SELECT * FROM [' + @nombreHoja + '$]'')'
                    
                -- Ejecutar la consulta de prueba
                EXEC sp_executesql @Consulta;
                
                -- Insertar datos desde el archivo Excel en la tabla temporal
                SET @Consulta = N'
                    INSERT INTO #ClasificacionTemporal1(Lineadeproducto, Producto)
                    SELECT [Línea de producto] AS Lineadeproducto, [Producto] AS Producto
                    FROM OPENROWSET(
                        ''Microsoft.ACE.OLEDB.12.0'',
                        ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
                        ''SELECT * FROM [' + @nombreHoja + '$]''
                    );'
                EXEC sp_executesql @Consulta;
                
                -- Verificar los datos en la tabla temporal
                SELECT * FROM #ClasificacionTemporal1;
                
                -- Insertar los datos finales en la tabla destino
                INSERT INTO esquema_Producto.LineaDeProducto(lineaProducto, productoDescrip)
                SELECT Lineadeproducto, Producto
                FROM #ClasificacionTemporal1
                
                PRINT 'Los datos se insertaron exitosamente'; 
                
                -- Limpiar la tabla temporal
                DROP TABLE #ClasificacionTemporal1; 
            END 
        COMMIT TRANSACTION 
    END TRY 
    BEGIN CATCH 
        -- Imprimir mensaje de error
        PRINT 'No se pudieron importar las clasificaciones de ' + @RutaArchivo;
        PRINT ERROR_MESSAGE(); 
        
        DECLARE @ErrorMessage NVARCHAR(4000), 
                @ErrorSeverity INT, 
                @ErrorState INT;
        
        -- Obtener detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        -- Levantar el error con los detalles obtenidos
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
        
        -- Revertir la transacción en caso de error
        ROLLBACK TRANSACTION;
    END CATCH 
END 
GO
EXEC esquema_Producto.importarLineDeProducto @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx', 
@nombreHoja = 'Clasificacion productos'
go




-----------------------CATALOGO----------------TABLA PRODUCTO
-----FUNCIONO-----TABLAS TEMPORALES CON VARCHAR
CREATE OR ALTER PROCEDURE esquema_Producto.importarCatalogo (@RutaArchivo NVARCHAR(MAX))  
AS 
BEGIN 
    BEGIN TRY 
        BEGIN TRANSACTION 
            SET XACT_ABORT ON 
            SET NOCOUNT ON 

            DECLARE @Consulta NVARCHAR(MAX) 
            DECLARE @ExisteArchivo INT 

            -- Verifica si el archivo existe en la ruta especificada
            SELECT @ExisteArchivo = T.file_exists 
            FROM sys.dm_os_file_exists(@RutaArchivo) AS T 
            
            IF @ExisteArchivo = 0 
            BEGIN
                RAISERROR ('El archivo CSV no existe en la ruta especificada.', 16, 1);
                RETURN;
            END
            ELSE 
            BEGIN 
                PRINT 'Se encontró el archivo CSV'; 
                
                -- Crea la tabla temporal con los campos correspondientes
                CREATE TABLE #CatalogoTemporal (
                    id VARCHAR(100),
                    categoria VARCHAR(100),
                    nombre VARCHAR(100),
                    precio VARCHAR(100), 
                    precio_Referencia VARCHAR(100), 
                    unidad_Referencia VARCHAR(100),
                    horario VARCHAR(100) 
                ); 

                -- Construye la consulta BULK INSERT con la codificación UTF-8
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

                -- Ejecuta la carga BULK INSERT
                EXEC sp_executesql @Consulta;

                -- Convierte y verifica los datos antes de insertarlos en la tabla final
                INSERT INTO esquema_Producto.Producto (idCatalogo, category, nombre, precio, precio_Referencia, unidad_Referencia, fechaYhorario)
                SELECT 
                    TRY_CAST(id AS INT),
                    categoria,
                    nombre,
                    TRY_CAST(precio AS DECIMAL(10,2)),
                    TRY_CAST(precio_Referencia AS DECIMAL(10,2)),
                    unidad_Referencia,
                    TRY_CAST(horario AS DATETIME)
                FROM #CatalogoTemporal;

                PRINT 'Los datos se insertaron exitosamente'; 
                
                -- Limpia la tabla temporal
                DROP TABLE #CatalogoTemporal; 
            END 
        COMMIT TRANSACTION 
    END TRY 
    BEGIN CATCH 
        PRINT 'No se pudieron importar los catálogos de ' + @RutaArchivo; 
        PRINT ERROR_MESSAGE(); 
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        
        -- Obtener detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
	  -- Levantar el error con los detalles obtenidos
      RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
      ROLLBACK TRANSACTION 
  END CATCH 
END;
GO
EXEC esquema_Producto.importarCatalogo 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Productos\catalogo.csv'
go




-----------------SUCURSAL---------------------
-------FUNCIONA PERO LA PROVINCIA NO APARECE EN LA TABLA-------TABLAS TEMPORALES CON VARCHAR
CREATE OR ALTER PROCEDURE esquema_Sucursal.importarSucursal(@RutaArchivo NVARCHAR(MAX), @nombreHoja NVARCHAR(50))
AS 
BEGIN 
  BEGIN TRY 
     BEGIN TRANSACTION 
      SET XACT_ABORT ON 
       SET NOCOUNT ON 
       DECLARE @Consulta NVARCHAR(MAX) 
       DECLARE @ExisteArchivo INT 
       
       -- Verificar si el archivo existe
       SELECT @ExisteArchivo = T.file_exists FROM sys.dm_os_file_exists(@RutaArchivo) AS T 
       IF @ExisteArchivo = 0 
       BEGIN
           RAISERROR ('El archivo XLSX no existe en la ruta especificada.', 16, 1);
           RETURN;
       END 
       ELSE 
       BEGIN 
           PRINT 'Se encontro el archivo XLSX'
           
           -- Crear tabla temporal para importar todos los datos del Excel
           CREATE TABLE #SucursalTemporal1 (
               Ciudad VARCHAR(150),  -- Ampliado a 150 caracteres
               Reemplazarpor VARCHAR(150),
               Direccion VARCHAR(200),  -- Direccion ampliada
               Horario VARCHAR(50),
               Telefono VARCHAR(50)
           );

           -- Cargar datos desde el archivo Excel
           SET @Consulta = N'
           INSERT INTO #SucursalTemporal1 (Ciudad, Reemplazarpor, Direccion, Horario, Telefono)
           SELECT Ciudad, [Reemplazar por] AS Reemplazarpor, [direccion] AS Direccion, Horario, Telefono
           FROM OPENROWSET(
               ''Microsoft.ACE.OLEDB.12.0'',
               ''Excel 12.0; Database=' + @RutaArchivo + '; HDR=YES;'',
               ''SELECT * FROM [' + @nombreHoja + ']''
           );';

           EXEC sp_executesql @Consulta;

           -- Crear tabla temporal para separar la dirección
           CREATE TABLE #SucursalCompleto (
               Ciudad VARCHAR(150),  -- Ampliado a 150 caracteres
               Reemplazarpor VARCHAR(150),
               calleYNum VARCHAR(150),  -- Ampliado a 150 caracteres
               localidadYCodPostal VARCHAR(150),  -- Ampliado a 150 caracteres
               provincia VARCHAR(150),  -- Ampliado a 150 caracteres
               Horario VARCHAR(50),
               Telefono VARCHAR(50)
           );

           -- Insertar datos en la tabla temporal de dirección separada
           INSERT INTO #SucursalCompleto (Ciudad, Reemplazarpor, calleYNum, localidadYCodPostal, provincia, Horario, Telefono)
           SELECT 
               Ciudad, 
               Reemplazarpor,					
               -- Separar la dirección en partes
               LEFT(Direccion, CHARINDEX(',', Direccion) - 1) AS calleYNum,  -- Parte de la calle y número
               
               -- Obtener la parte de localidad y código postal (segunda parte de la dirección)
               CASE 
                   WHEN CHARINDEX(',', Direccion, CHARINDEX(',', Direccion) + 1) > 0 
                   THEN LTRIM(RTRIM(SUBSTRING(Direccion, CHARINDEX(',', Direccion) + 1, CHARINDEX(',', Direccion, CHARINDEX(',', Direccion) + 1) - CHARINDEX(',', Direccion) - 1)))
                   ELSE '' -- Si no hay coma extra, no hay localidad
               END AS localidadYCodPostal,
               
               -- Obtener la provincia, que es la parte posterior a la última coma
               CASE 
                   WHEN CHARINDEX(',', Direccion, CHARINDEX(',', Direccion, CHARINDEX(',', Direccion) + 1) + 1) > 0 
                   THEN LTRIM(RTRIM(SUBSTRING(Direccion, CHARINDEX(',', Direccion, CHARINDEX(',', Direccion, CHARINDEX(',', Direccion) + 1) + 1) + 1, LEN(Direccion))))
                   ELSE '' -- Si no hay coma extra, no hay provincia
               END AS provincia,
               
               Horario,
               
               -- Limpiar el teléfono de caracteres no numéricos y convertirlo a INT
               TRY_CAST(REPLACE(Telefono, '-', '') AS INT) AS Telefono
           FROM #SucursalTemporal1;

           -- Verificar los datos en #SucursalCompleto
           SELECT * FROM #SucursalCompleto;

           -- Insertar los datos finales en esquema_Sucursal
           INSERT INTO esquema_Sucursal.sucursales(ciudad, reemplazadaX, horario, telefono, calleYNum, localidadYCodPostal, provincia)
           SELECT 
               Ciudad,
               Reemplazarpor,
               Horario,
               Telefono,
               calleYNum,
               localidadYCodPostal,
               provincia
           FROM #SucursalCompleto;

           PRINT 'Los datos se insertaron exitosamente'; 
           
           -- Limpiar tablas temporales
           DROP TABLE #SucursalTemporal1;
           DROP TABLE #SucursalCompleto;
       END 
  COMMIT TRANSACTION 
  END TRY 
  BEGIN CATCH 
       DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        
        -- Obtener detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
	  -- Levantar el error con los detalles obtenidos
      RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
  END CATCH 
END
GO
EXEC esquema_Sucursal.importarSucursal @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx',
@nombreHoja = 'sucursal$'
GO



-------------------VENTAS
------CREO QUE FUNCIONA------TABLAS TEMPORALES CON VARCHAR

CREATE OR ALTER PROCEDURE esquema_Ventas.importarVentasRegistradas (@RutaArchivo NVARCHAR(MAX)) 
AS 
BEGIN 
    BEGIN TRY 
        BEGIN TRANSACTION 
            SET XACT_ABORT ON 
            SET NOCOUNT ON 
            
            DECLARE @Consulta NVARCHAR(MAX) 
            DECLARE @ExisteArchivo INT 
            
            -- Verificar existencia del archivo
            SELECT @ExisteArchivo = T.file_exists 
            FROM sys.dm_os_file_exists (@RutaArchivo) AS T 
            
            IF @ExisteArchivo = 0 
            BEGIN
                RAISERROR ('El archivo XLSX no existe en la ruta especificada.', 16, 1);
                RETURN;
            END 
            ELSE 
            BEGIN 
                PRINT 'Se encontró el archivo CSV' 
                
                -- Crear tabla temporal
                CREATE TABLE #VentasRegisTemp ( 
                    idFactura varchar (100), 
                    tipoDeFactura varchar (100),
                    ciudad varchar(100),
                    tipoDeCliente varchar(100),
                    genero varchar (100),
                    producto varchar(100),
                    precioUnitario varchar(100), 
                    cantidad varchar(100),
                    fecha varchar(100),
                    hora varchar(100),
                    medioDePago varchar(100),
                    empleado varchar(100),
                    idIdentificador varchar(100) 
                )

                -- Cargar datos desde el archivo CSV
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

                EXEC sp_executesql @Consulta
                -- Verificar los datos antes de la inserción
                SELECT idFactura, idIdentificador, cantidad, precioUnitario FROM #VentasRegisTemp;

                -- Insertar datos en la tabla final después de validaciones y conversiones
                INSERT INTO esquema_Ventas.ventasRegistradas (
                    idFactura, tipoDeFactura, ciudad, tipoDeCliente, producto, cantidad, precioUnitario, 
                    fecha, hora, medioDePago, genero, empleado, idIdentificador)
                SELECT 
                    -- Validar y convertir idFactura, eliminando guion
                    CASE 
                        WHEN ISNUMERIC(REPLACE(idFactura, '-', '')) = 1 
                        THEN TRY_CAST(REPLACE(idFactura, '-', '') AS BIGINT)
                        ELSE NULL
                    END,
                    tipoDeFactura, 
                    ciudad, 
                    tipoDeCliente, 
                    producto, 
                    TRY_CAST(cantidad AS INT), 
                    TRY_CAST(precioUnitario AS DECIMAL(10,2)), 
                    TRY_CAST(fecha AS DATE), 
                    hora, 
                    medioDePago, 
                    genero, 
                    empleado, 
                    idIdentificador  -- idIdentificador sigue siendo VARCHAR
                FROM #VentasRegisTemp
                WHERE ISNUMERIC(cantidad) = 1 AND ISNUMERIC(precioUnitario) = 1
                  AND TRY_CAST(REPLACE(idFactura, '-', '') AS BIGINT) IS NOT NULL;  -- Evitar NULL en idFactura

                -- Reemplazar caracteres especiales en la columna producto
                UPDATE esquema_Ventas.ventasRegistradas
                SET producto = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(producto,
                    'Ã¡', 'a'), 'Ã©', 'e'), 'Ã­', 'i'), 'Ã³', 'o'), 'Ãº', 'u'), 'Ã‘', 'Ñ'), 'Ã±', 'ñ')
                WHERE producto LIKE '%Ã¡%' OR producto LIKE '%Ã©%' OR producto LIKE '%Ã­%' 
                OR producto LIKE '%Ã³%' OR producto LIKE '%Ãº%' OR producto LIKE '%Ã‘%' OR producto LIKE '%Ã±%';

                PRINT 'Los datos se insertaron y los caracteres especiales fueron reemplazados exitosamente' 
                
                -- Limpiar tabla temporal
                DROP TABLE #VentasRegisTemp 
            END 
        COMMIT TRANSACTION 
    END TRY 
    BEGIN CATCH 
        PRINT 'No se pudieron importar los datos de ' + @RutaArchivo; 
        PRINT ERROR_MESSAGE(); 
        PRINT 'Error en el procedimiento: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        
        -- Obtener detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        -- Levantar el error con los detalles obtenidos
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH 
END
GO
EXEC esquema_Ventas.importarVentasRegistradas @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Ventas_registradas.csv'
go
