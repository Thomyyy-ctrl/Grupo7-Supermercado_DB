use master
go


use ALMACEN_Grupo7
go

-----------------Sucursal

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_configure;
go

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

--------------EJECUTO -----NO LO IMPORTO
EXEC esquema_Sucursal.importarSucursal @RutaArchivo = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\TP_integrador_Archivos\Informacion_complementaria.xlsx', @nombreHoja = 'sucursal$'
GO



create or alter procedure esquema_Sucursal.insertarSucursal(@ciudad varchar (15),@reemplazadaX varchar (50),@calleYNum varchar(50),
@localidadYCodPostal varchar(50),@provincia varchar(50),@horario time(7),@telefono int)
as
begin
	begin try
		begin transaction
				set nocount on ---no muestro la cantidad de filas insertadas por consola.
				insert into esquema_Sucursal.sucursales(ciudad ,reemplazadaX ,horario ,telefono)
				values (@ciudad ,@reemplazadaX ,@calleYNum,@localidadYCodPostal,@provincia,@horario ,@telefono)
		commit transaction 
	end try
	begin catch
			print 'No se pudo insertar la nueva sucursal'
			print ERROR_MESSAGE()
			rollback transaction
	end catch
end
go

create or alter procedure esquema_Sucursal.modificarSucursal(@id int,@ciudad varchar (15),@reemplazadaX varchar (50),@calleYNum varchar(50),
@localidadYCodPostal varchar(50),@provincia varchar(50),@horario time(7),@telefono int)
as
begin
	begin try
		begin transaction
			if(@id is NULL)
				throw 51000,'Se debe enviar el id de la sucursal',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Sucursal.sucursales where id = @id)
					begin
							UPDATE esquema_Sucursal.sucursales
							set
								ciudad= COALESCE(@ciudad,ciudad), ---- si @ es nulo devuelve el dato de la comlumna, sino igual el dato de la variable
								reemplazadaX = COALESCE(@reemplazadaX,reemplazadaX),
								calleYNum = COALESCE(@calleYNum,calleYNum),
								localidadYCodPostal = COALESCE(@localidadYCodPostal,localidadYCodPostal),
								provincia = COALESCE(@provincia,provincia),
								horario = COALESCE(@horario,horario),
								telefono = COALESCE(@telefono,telefono)
							where id = @id
					end
					else 
							print 'No existe la sucursal '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo actualizar la sucursal ' + CAST(@id as varchar)
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go


CREATE OR ALTER PROCEDURE esquema_Sucursal.eliminarSucursal (@id INT)
as
begin
	begin try
		begin transaction
			if(@id is NULL)
				throw 51000,'Se debe enviar el id de la sucursal',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Sucursal.sucursales where id = @id)
					begin
							set nocount on
							delete from esquema_Sucursal.sucursales where id = @id;
					end
					else 
							print 'No existe la sucursal '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo eliminar la sucursal ' + CAST(@id as varchar)   
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go