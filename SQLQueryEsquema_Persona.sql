use master
go

use ALMACEN_Grupo7
go


------------------------------------EMPLEADOS

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_configure;
go

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
-----------------EJECUTO
EXEC esquema_Persona.importarEmpleado @RutaArchivo = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\TP_integrador_Archivos\Informacion_complementaria.xlsx',
@nombreHoja = 'Empleados$'
go

create or alter procedure esquema_Persona.insertarEmpleado(@legajo int, @nombre varchar(50), @apellido varchar(50), @nroDoc int,@calleYNum varchar(50),@localidad varchar(50),@provincia varchar(50),
															@cuil int,@cargo varchar (50),@sucursal varchar (50),@turno varchar (50),@emailPersonal varchar (100),@emailEmpresa varchar (100))
as
begin
	begin try
		begin transaction
				set nocount on ---no muestro la cantidad de filas insertadas por consola.
				insert into esquema_Persona.empleado (legajo, nombre, apellido ,  nroDoc , calleYNum , localidad , provincia ,  cuil ,cargo ,sucursal ,turno ,emailPersonal,emailEmpresa)
				values (@legajo, @nombre, @apellido ,  @nroDoc ,@calleYNum , @localidad , @provincia ,  @cuil, @cargo ,@sucursal ,@turno ,@emailPersonal, @emailEmpresa)
		commit transaction 
	end try
	begin catch
			print 'No se pudo insertar el empleado ' + @Apellido + ', ' + @Nombre
			print ERROR_MESSAGE()
			rollback transaction
	end catch
end
go

create or alter procedure esquema_Persona.modificarEmpleado(@legajo int, @nombre varchar(50), @apellido varchar(50), @nroDoc int,@calleYNum varchar(50),@localidad varchar(50),@provincia varchar(50),
															@cuil int,@cargo varchar (50),@sucursal varchar (50),@turno varchar (50),@emailPersonal varchar (100),@emailEmpresa varchar (100))
as
begin
	begin try
		begin transaction
			if(@legajo is NULL)
				throw 51000,'Se debe enviar el legajo del empleado',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Persona.empleado where legajo = @legajo)
					begin
							UPDATE esquema_Persona.empleado
							set
								nombre= COALESCE(@nombre,nombre), ---- si @ es nulo devuelve el dato de la comlumna, sino igual el dato de la variable
								apellido= COALESCE(@apellido,apellido),
								nroDoc= COALESCE(@nroDoc,nroDoc) ,
								calleYNum = COALESCE(@calleYNum,calleYNum),
								localidad= COALESCE(@localidad,localidad) ,
								provincia= COALESCE(@provincia,provincia) , 
								cuil = COALESCE(@cuil,cuil),
								cargo= COALESCE(@cargo,cargo) ,
								sucursal= COALESCE(@sucursal,sucursal) ,
								turno= COALESCE(@turno,turno) ,
								emailPersonal= COALESCE(@emailPersonal,emailPersonal),
								emailEmpresa= COALESCE(@emailEmpresa,emailEmpresa)
							where legajo = @legajo
					end
					else 
							print 'No existe empleado con legajo '+ CAST(@legajo as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo actualizar el empleado ' + @Apellido + ', ' + @Nombre
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go

CREATE OR ALTER PROCEDURE esquema_Persona.eliminarEmpleado (@legajo INT)
as
begin
	begin try
		begin transaction
			if(@legajo is NULL)
				throw 51000,'Se debe enviar el legajo del empleado',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Persona.empleado where legajo = @legajo)
					begin
							set nocount on
							delete from esquema_Persona.empleado where legajo = @legajo;
					end
					else 
							print 'No existe empleado con legajo '+ CAST(@legajo as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo eliminar el empleado ' + CAST(@legajo as varchar)   
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go-----------------------------------CLIENTES:create or alter procedure esquema_Persona.insertarCliente(@tipoCliente varchar (30), @genero varchar(10))
as
begin
	begin try
		begin transaction
				set nocount on ---no muestro la cantidad de filas insertadas por consola.
				insert into esquema_Persona.cliente (tipoCliente, genero)
				values (@tipoCliente,@genero)
		commit transaction 
	end try
	begin catch
			print 'No se pudo insertar cliente '
			print ERROR_MESSAGE()
			rollback transaction
	end catch
end
go

create or alter procedure esquema_Persona.modificarCliente(@id int, @tipoCliente varchar (30), @genero varchar(10))
as
begin
	begin try
		begin transaction
			if(@id is NULL)
				throw 51000,'Se debe enviar el legajo del empleado',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Persona.cliente where id = @id)
					begin
							UPDATE esquema_Persona.cliente
							set
								tipoCliente= COALESCE(@tipoCliente,tipoCliente), ---- si @ es nulo devuelve el dato de la comlumna, sino igual el dato de la variable
								genero = COALESCE(@genero,genero)
							where id = @id
					end
					else 
							print 'No existe el cliente '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo actualizar el cliente ' + CAST(@id as varchar)
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go

CREATE OR ALTER PROCEDURE esquema_Persona.eliminarCliente (@id INT)
as
begin
	begin try
		begin transaction
			if(@id is NULL)
				throw 51000,'Se debe enviar el id del cliente',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_Persona.cliente where id = @id)
					begin
							set nocount on
							delete from esquema_Persona.cliente where id = @id;
					end
					else 
							print 'No existe cliente id '+ CAST(@id as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo eliminar el cliente ' + CAST(@id as varchar)   
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go