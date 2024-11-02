use master
go

use ALMACEN_Grupo7
go

---------------------medios de Pago

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
EXEC sp_configure;
go

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

-----------------EJECUTO
EXEC esquema_operaciones.importarMediosDePago @RutaArchivo = 'C:\Users\User\Desktop\Martina\Supermercado sql\TP_integrador_Archivos\TP_integrador_Archivos\Informacion_complementaria.xlsx',
@nombreHoja = 'medios de pago$'
go

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

