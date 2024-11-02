use master
go

use ALMACEN_Grupo7
go

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
								idFactura int not null, 
								tipoDeFactura varchar (20) CHECK (tipoDeFactura LIKE 'A' OR tipoDeFactura LIKE 'B' OR tipoDeFactura LIKE 'C'),
								ciudad varchar(15),
								tipoDeCliente varchar(30),
								genero varchar (20),
								producto varchar(50),
								precioUnitario decimal(3,2), 
								cantidad int,
								fecha date,
								hora time,
								medioDePago varchar(20),
								empleado int,
								idIdentificador int 
								) 
 
								SET @Consulta = N' 
								 BULK INSERT #VentasRegisTemp 
								 FROM ''' + @RutaArchivo + ''' 
								 WITH ( 
								  FIELDTERMINATOR = ''\t'', 
								  ROWTERMINATOR = ''\n'', 
								  CODEPAGE =''UTF-8'',  
								  FIRSTROW = 2 
								 );' 
 
								EXEC sp_executesql @Consulta
								SELECT * FROM #VentasRegisTemp;
								
								INSERT INTO esquema_Ventas.ventasRegistradas(idFactura, tipoDeFactura, ciudad, tipoDeCliente, producto,
								cantidad, precioUnitario, fecha, hora, medioDePago, genero, empleado, idIdentificador)
								SELECT idFactura, tipoDeFactura, ciudad, tipoDeCliente, producto, cantidad, precioUnitario, 
								TRY_CAST(fecha AS date) AS fecha,  -- Usa TRY_CAST para convertir a fecha y manejar errores
								hora, medioDePago, genero, empleado, idIdentificador FROM #VentasRegisTemp
								WHERE idFactura IS NOT NULL AND TRY_CAST(fecha AS date) IS NOT NULL;
     
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

---------------EJECUTO
EXEC esquema_Ventas.importarVentasRegistradas @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Ventas_registradas.csv'
go



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