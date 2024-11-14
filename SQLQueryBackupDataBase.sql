use ALMACEN_Grupo7
go

use master
go
----------------Realizar Backup
-----------Realizo el backup cada dia de la semana

DECLARE @dest nvarchar(255)
set @dest =N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup\Backup_'+CAST(DATEPART(weekday,GETDATE())as nvarchar(1))+ '.bak'
PRINT CAST(GETDATE() AS nvarchar)+'- COPIA DE SEGURIDAD INICIADA AL ARCHIVO: '+ @dest
BACKUP DATABASE [ALMACEN_Grupo7] TO  DISK = @dest WITH NOFORMAT, INIT,  NAME = N'ALMACEN_Grupo7-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10, CHECKSUM
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'ALMACEN_Grupo7' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'ALMACEN_Grupo7' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''ALMACEN_Grupo7'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = @dest WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
go
  

-----------------Realizar la reestauracion de la base de datos
---------En caso de fallo o perdidad de datos, realizo restauracion de datos
USE [master]
DECLARE @dest nvarchar(255)
set @dest =N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup\Backup_'+CAST(DATEPART(weekday,GETDATE())as nvarchar(1))+ '.bak'
RESTORE DATABASE [ALMACEN_Grupo7] FROM  DISK = @dest
WITH  FILE = 1,  NOUNLOAD,  STATS = 5
go
