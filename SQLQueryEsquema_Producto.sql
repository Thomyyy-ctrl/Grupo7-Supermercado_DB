USE master
go

USE ALMACEN_Grupo7
go

----------------------------IMPORTADOS

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_configure;
go


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
		PrecioUnidad decimal(5,2)
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
	SELECT NombreProducto,Proveedor,Categoría,CantidadPorUnidad,PrecioUnidad
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

----------------EJECUTO

EXEC esquema_Producto.importarImportado @RutaArchivo ='C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Productos\Productos_importados.xlsx', 
@nombreHoja = 'Listado de Productos$'
go


CREATE OR ALTER PROCEDURE esquema_Producto.insertarImportado (@nombreproducto varchar (100),@Proveedor varchar (50),
                                                             @categoria varchar (20),@CantidadxUnidad varchar (50),@PrecioUnidad decimal(5,2))
as
begin
	begin try
		begin transaction
				set nocount on ---no muestro la cantidad de filas insertadas por consola.
				insert into esquema_Producto.importado(nombreproducto,Proveedor,categoria ,CantidadxUnidad,PrecioUnidad)
				values (@nombreproducto,@Proveedor,@categoria,@CantidadxUnidad,@PrecioUnidad)
commit transaction 
	end try
	begin catch
			print 'No se pudo insertar el producto importado ' + @nombreproducto
			print ERROR_MESSAGE()
			rollback transaction
	end catch
end
go

CREATE OR ALTER PROCEDURE esquema_Producto.modificarImportado (@id int,@nombreproducto varchar (100),@Proveedor varchar (50),
                                                             @categoria varchar (20),@CantidadxUnidad varchar (50),@PrecioUnidad decimal(5,2))
as
begin
	begin try
		begin transaction
		  if(@id is NULL)
				throw 51000,'Se debe enviar el id del producto importado',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Producto.importado where id = @id)
					begin
							UPDATE esquema_Producto.importado
							set
								nombreproducto= COALESCE(@nombreproducto,nombreproducto), ---- si @ es nulo devuelve el dato de la comlumna, sino igual el dato de la variable
								Proveedor= COALESCE(@Proveedor,Proveedor),
								categoria= COALESCE (@categoria,categoria),
								CantidadxUnidad= COALESCE (@CantidadxUnidad,CantidadxUnidad),
								PrecioUnidad= COALESCE (@PrecioUnidad,PrecioUnidad)
							where id = @id
					end
					else 
							print 'No existe el producto importado '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo actualizar el producto importado ' + CAST(@id as varchar)
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go

CREATE OR ALTER PROCEDURE esquema_Producto.eliminarImportado (@id int)
as
begin
	begin try
		begin transaction
			if(@id is NULL)
				throw 51000,'Se debe enviar el id del producto importado',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Producto.importado where id = @id)
					begin
							set nocount on
							delete from esquema_Producto.importado where id = @id;
					end
					else 
							print 'No existe el id '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo eliminar el producto importado ' + CAST(@id as varchar)   
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
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
		PrecioUnitarioendolares decimal(7,2)
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
	SELECT Product,PrecioUnitarioendolares
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

---------------EJECUTO 

EXEC esquema_Producto.importarElectronico   @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Productos\Electronic accessories.xlsx', 
@nombreHoja ='Sheet1$' 
go

CREATE OR ALTER PROCEDURE esquema_Producto.insertarElectronico (@productoNombre varchar (100),@precioUniDolar decimal(7,2) )
as
begin
	begin try
		begin transaction
				set nocount on ---no muestro la cantidad de filas insertadas por consola.
				insert into esquema_Producto.electronicos(productoNombre,precioUniDolar )
				values (@productoNombre, @precioUniDolar)
commit transaction 
	end try
	begin catch
			print 'No se pudo insertar el producto electronico ' + @productoNombre
			print ERROR_MESSAGE()
			rollback transaction
	end catch
end
go

CREATE OR ALTER PROCEDURE esquema_Producto.modificarElectronico (@id int, @productoNombre varchar (100),@precioUniDolar decimal(7,2))
as
begin
	begin try
		begin transaction
		   if(@id is NULL)
				throw 51000,'Se debe enviar el id del producto electronico',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Producto.electronicos where id = @id)
					begin
							UPDATE esquema_Producto.electronicos
							set
								productoNombre= COALESCE(@productoNombre,productoNombre), ---- si @ es nulo devuelve el dato de la comlumna, sino igual el dato de la variable
								precioUniDolar= COALESCE(@precioUniDolar,precioUniDolar)
							where id = @id
					end
					else 
							print 'No existe el producto importado '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo actualizar el producto electronico ' + CAST(@id as varchar)
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go

CREATE OR ALTER PROCEDURE esquema_Producto.eliminarElectronico (@id int)
as
begin
	begin try
		begin transaction
		   if(@id is NULL)
				throw 51000,'Se debe enviar el id del producto electronico',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Producto.electronicos where id = @id)
					begin
							set nocount on
							delete from esquema_Producto.electronicos where id = @id;
					end
					else 
							print 'No existe el id '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo eliminar el producto electronico ' + CAST(@id as varchar)   
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go

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

--------------EJECTUTO
EXEC esquema_Producto.importarClasificacion @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx', 
@nombreHoja = 'Clasificacion productos$'
go


CREATE OR ALTER PROCEDURE esquema_Producto.insertarClasificacion (@idImportados int,@lineaDeProducto varchar (20), @productoDescrip varchar (50))
as
begin
	begin try
		begin transaction
				IF (@idImportados IS NULL) 
    THROW 51000, 'Se debe enviar ID del producto importado', 1 
   ELSE 
   BEGIN 
    INSERT INTO esquema_Producto.clasificacion (lineaProducto,productoDescrip) 
    VALUES (@lineaDeProducto,@productoDescrip) 
   END 
  COMMIT TRANSACTION 
    END TRY 
    BEGIN CATCH 
        PRINT 'No se pudo insertar la clasicacion' 
        PRINT ERROR_MESSAGE() 
        ROLLBACK TRANSACTION 
    END CATCH 
END 
go 

CREATE OR ALTER PROCEDURE esquema_Producto.modificarClasificacion (@id int,@idImportados int,@lineaProducto varchar (20), @productoDescrip varchar (50))
as
begin
	begin try
		begin transaction
		  if(@id is NULL OR @idImportados is NULL)
				throw 51000,'Se debe enviar el id de la clasificacion y del producto importado',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Producto.clasificacion where id = @id AND idImportados = @idImportados)
					begin
							UPDATE esquema_Producto.clasificacion
							set
								lineaProducto= COALESCE(@lineaProducto,lineaProducto), ---- si @ es nulo devuelve el dato de la comlumna, sino igual el dato de la variable
								productoDescrip= COALESCE(@productoDescrip,productoDescrip)
							where id = @id AND idImportados = idImportados
					end
					else 
							print 'No existe la clasificacion '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo actualizar la clasificacion ' + CAST(@id as varchar)
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go

CREATE OR ALTER PROCEDURE esquema_Producto.eliminarClasificacion (@id int,@idImportado int)
as
begin
	begin try
		begin transaction
		   if(@id is NULL OR @idImportado is NULL)
				throw 51000,'Se debe enviar el id de clasificacion y id del producto importado',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Producto.clasificacion where id = @id AND idImportados = @idImportado)
					begin
							set nocount on
							delete from esquema_Producto.clasificacion where id = @id AND idImportados = @idImportado  ;
					end
					else 
							print 'No existe el id '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo eliminar la clasificacion ' + CAST(@id as varchar)   
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go

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
                 categoria varchar (10),
                 nombre varchar (100),
                 precio decimal(3,2) , --CAMBIAR A DECIMAL
                 precio_Referencia decimal(3,2) , ---CAMBIAR A DECIMAL
                 unidad_Referencia varchar (2),
                 horario time 
    ) 
    SET @Consulta = N' 
     BULK INSERT #CatalogoTemporal 
     FROM ''' + @RutaArchivo + ''' 
     WITH ( 
      FIELDTERMINATOR = '';'', 
      ROWTERMINATOR = ''\n'', 
      CODEPAGE = ''UTF-8'',  
      FIRSTROW = 2  
     );'  
 
    EXEC sp_executesql @Consulta 
    INSERT INTO esquema_Producto.catalogo (categoria,nombre,precio,precio_Referencia,unidad_Referencia,horario)SELECT * FROM #CatalogoTemporal 
    PRINT 'Los datos se insertaron exitosamente' 
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

-------------EJECUTO
EXEC esquema_Producto.importarCatalogo 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Productos\catalogo.csv'
go



CREATE OR ALTER PROCEDURE esquema_Producto.insertarCatalogo (@idImportados int,@categoria varchar (10),@nombre varchar (100),@precio decimal(3,2),
                                                            @precio_Referencia decimal(3,2),@unidad_Referencia varchar (2),@horario time)
as
begin
	begin try
		begin transaction
				IF (@idImportados IS NULL) 
    THROW 51000, 'Se debe enviar ID del producto importado', 1 
   ELSE 
   BEGIN 
    INSERT INTO esquema_Producto.catalogo (categoria,nombre,precio,precio_Referencia,unidad_Referencia,horario) 
    VALUES (@categoria,@nombre,@precio,@precio_Referencia,@unidad_Referencia,@horario) 
   END 
  COMMIT TRANSACTION 
    END TRY 
    BEGIN CATCH 
        PRINT 'No se pudo insertar el catalogo' 
        PRINT ERROR_MESSAGE() 
        ROLLBACK TRANSACTION 
    END CATCH 
END 
go 

CREATE OR ALTER PROCEDURE esquema_Producto.modificarCatalogo (@id int,@idImportados int,@categoria varchar (10),@nombre varchar (100),@precio decimal(3,2),
                                                            @precio_Referencia decimal(3,2),@unidad_Referencia varchar (2),@horario time)
as
begin
	begin try
		begin transaction
		  if(@id is NULL OR @idImportados is NULL)
				throw 51000,'Se debe enviar el id del catalogo y del producto importado',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Producto.catalogo where id = @id AND idImportados = @idImportados)
					begin
							UPDATE esquema_Producto.catalogo
							set
								categoria = COALESCE(@categoria,categoria), ---- si @ es nulo devuelve el dato de la comlumna, sino igual el dato de la variable
								nombre = COALESCE(@nombre,nombre),
								precio = COALESCE(@precio,precio),
								precio_Referencia = COALESCE(@precio_Referencia,precio_Referencia),
								unidad_Referencia = COALESCE(@unidad_Referencia,unidad_Referencia),
								horario = COALESCE(@horario,horario)
							where id = @id AND idImportados = idImportados
					end
					else 
							print 'No existe el catalogo '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo actualizar el catalogo ' + CAST(@id as varchar)
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go

CREATE OR ALTER PROCEDURE esquema_Producto.eliminarCatalogo (@id int,@idImportado int,@categoria varchar (10),@nombre varchar (100),@precio decimal(3,2),
                                                            @precio_Referencia decimal(3,2),@unidad_Referencia varchar (2),@horario time)
as
begin
	begin try
		begin transaction
		   if(@id is NULL OR @idImportado is NULL)
				throw 51000,'Se debe enviar el id del catalogo y id del producto importado',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Producto.catalogo where id = @id AND idImportados = @idImportado)
					begin
							set nocount on
							delete from esquema_Producto.catalogo where id = @id AND idImportados = @idImportado  ;
					end
					else 
							print 'No existe el id '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo eliminar el catalogo ' + CAST(@id as varchar)   
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go