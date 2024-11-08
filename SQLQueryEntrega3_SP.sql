use master 
go

use ALMACEN_Grupo7
go

-------------------------- EMPLEADOS
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
go


--------------------------------------Clientes:

create or alter procedure esquema_Persona.insertarCliente(@tipoCliente varchar (30), @genero varchar(10))
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


------------------------------------MEDIOS DE PAGO

create or alter procedure esquema_Operaciones.insertarMedioDePago(@identificadorDePago int, @medioDePago varchar (20))
as
begin
	begin try
		begin transaction
				set nocount on ---no muestro la cantidad de filas insertadas por consola.
				insert into esquema_operaciones.mediosDePago (identificadorDePago, medioDePago)
				values(@identificadorDePago,@medioDePago)
		commit transaction 
	end try
	begin catch
			print 'No se pudo insertar el medio de pago ' + CAST(@identificadorDePago as varchar)
			print ERROR_MESSAGE()
			rollback transaction
	end catch
end
go

CREATE OR ALTER PROCEDURE esquema_Operaciones.eliminarMedioDePago (@identificadorDePago INT)
as
begin
	begin try
		begin transaction
			if(@identificadorDePago is NULL)
				throw 51000,'Se debe enviar el identificador de pago',1
			else 
			begin
					set nocount on 
					if exists(select 1 from esquema_operaciones.mediosDePago where identificadorDePago = @identificadorDePago)
					begin
							set nocount on
							delete from esquema_operaciones.mediosDePago where identificadorDePago = @identificadorDePago;
					end
					else 
							print 'No existe el identificador de pago '+ CAST(@identificadorDePago as varchar)
			end
		commit transaction 
	end try
	begin catch
		print 'No se pudo eliminar el identificador de pago ' + CAST(@identificadorDePago as varchar)   
		print ERROR_MESSAGE()
		rollback transaction
	end catch
end
go

-----------------------------------IMPORTADOS

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


--------------------------------ELECTRONICOS


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

-------------------------------CLASIFICACION

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


--------------------------------CATALOGO


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



------------------------------SUCURSAL

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

-----------------------------Ventas Registradas
create or alter procedure esquema_Ventas.insertarVenta(@idFactura int ,@tipoDeFactura varchar (20),@ciudad varchar(15),@tipoDeCliente varchar (30),@producto varchar (50),
@cantidad int, @fecha date,@hora time,@medioDePago varchar (20), @precioUnitario decimal (3,2), @genero varchar(20),@empleado int, @idIndentificador int)
as
begin
	begin try
		begin transaction
				set nocount on ---no muestro la cantidad de filas insertadas por consola.
				insert into esquema_Ventas.ventasRegistradas(idFactura,tipoDeFactura,ciudad ,tipoDeCliente,producto,cantidad, fecha ,hora ,
				medioDePago , precioUnitario , genero ,empleado ,idIdentificador)
				values (@idFactura,@tipoDeFactura,@ciudad ,@tipoDeCliente ,@producto ,@cantidad , @fecha ,@hora ,@medioDePago , @precioUnitario, @genero ,@empleado , @idIndentificador )
		commit transaction 
	end try
	begin catch
			print 'No se pudo insertar la nueva venta'
			print ERROR_MESSAGE()
			rollback transaction
	end catch
end
go
