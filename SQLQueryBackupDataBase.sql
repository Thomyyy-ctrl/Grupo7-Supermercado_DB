
USE [master]  
GO  
SET ANSI_NULLS ON  
GO  
SET QUOTED_IDENTIFIER ON  
GO  
----------------Realizar Backup
-----------Realizo el backup cada dia de la semana de la base de datos

CREATE or alter PROCEDURE [dbo].[sp_BackupDatabases]   
            @databaseName sysname = null, 
            @backupType CHAR(1), 
            @backupLocation nvarchar(200)  
AS  
       SET NOCOUNT ON;  
            DECLARE @DBs TABLE 
            ( 
                  ID int IDENTITY PRIMARY KEY, 
                  DBNAME nvarchar(500) 
            ) 
             -- Seleccione solo bases de datos que estén en línea en caso de que se elijan TODAS las bases de datos para realizar una copia de seguridad
			-- Si se elige una base de datos específica para realizar una copia de seguridad, selecciónela solo de @DBs
            INSERT INTO @DBs (DBNAME) 
            SELECT Name FROM master.sys.databases 
            where state=0 
            AND name= ISNULL(@databaseName ,name)
            ORDER BY Name
            --Filtrar bases de datos que no necesitan copia de seguridad 
            IF @backupType='F' 
                  BEGIN 
                  DELETE @DBs where DBNAME IN ('tempdb','Northwind','pubs','AdventureWorks') 
                  END 
            ELSE IF @backupType='D' 
                  BEGIN 
                  DELETE @DBs where DBNAME IN ('tempdb','Northwind','pubs','master','AdventureWorks') 
                  END 
            ELSE IF @backupType='L' 
                  BEGIN 
                  DELETE @DBs where DBNAME IN ('tempdb','Northwind','pubs','master','AdventureWorks') 
                  END 
            ELSE 
                  BEGIN 
                  RETURN 
                  END 
            -- Declarar variables
            DECLARE @BackupName nvarchar(100) 
            DECLARE @BackupFile nvarchar(300) 
            DECLARE @DBNAME nvarchar(300) 
            DECLARE @sqlCommand NVARCHAR(1000)  
	        DECLARE @dateTime NVARCHAR(20) 
            DECLARE @Loop int                   
			 -- Recorrer las bases de datos una por una
            SELECT @Loop = min(ID) FROM @DBs 
      WHILE @Loop IS NOT NULL 
      BEGIN 
	  -- Los nombres de las bases de datos deben estar en formato [dbname] ya que algunos tienen - o _ en su nombre
      SET @DBNAME = '['+(SELECT DBNAME FROM @DBs WHERE ID = @Loop)+']' 
	  SET @dateTime =CAST(DATEPART(weekday,GETDATE())as nvarchar(1))

-- Crear un nombre de archivo de respaldo en formato path\filename.extension para respaldos completos, de diferencias y de registro
      IF @backupType = 'F' 
            SET @BackupFile = @backupLocation+REPLACE(REPLACE(@DBNAME, '[',''),']','')+ '_FULL_Dia'+ @dateTime+ '.bak' 
      ELSE IF @backupType = 'D' 
            SET @BackupFile = @backupLocation+REPLACE(REPLACE(@DBNAME, '[',''),']','')+ '_DIFF_Dia'+ @dateTime+ '.bak' 
      ELSE IF @backupType = 'L' 
            SET @BackupFile = @backupLocation+REPLACE(REPLACE(@DBNAME, '[',''),']','')+ '_LOG_Dia'+ @dateTime+ '.bak' 
-- Proporcione a la copia de seguridad un nombre para almacenarla en el medio
      IF @backupType = 'F' 
            SET @BackupName = REPLACE(REPLACE(@DBNAME,'[',''),']','') +' full backup for '+ @dateTime 
      IF @backupType = 'D' 
            SET @BackupName = REPLACE(REPLACE(@DBNAME,'[',''),']','') +' differential backup for '+ @dateTime 
      IF @backupType = 'L' 
            SET @BackupName = REPLACE(REPLACE(@DBNAME,'[',''),']','') +' log backup for '+ @dateTime 
-- Generar el comando SQL dinámico a ejecutar
       IF @backupType = 'F'  
                  BEGIN 
			   SET @sqlCommand = 'BACKUP DATABASE ' +@DBNAME+  ' TO DISK = '''+@BackupFile+ ''' WITH INIT, NOFORMAT, NAME= ''' +@BackupName+''',SKIP, NOREWIND, NOUNLOAD, STATS = 10, CHECKSUM' 
                  END 
       IF @backupType = 'D' 
                  BEGIN 
               SET @sqlCommand = 'BACKUP DATABASE ' +@DBNAME+  ' TO DISK = '''+@BackupFile+ ''' WITH DIFFERENTIAL, INIT, NAME= ''' +@BackupName+''', NOSKIP, NOFORMAT'         
                  END 
       IF @backupType = 'L'  
                  BEGIN 
               SET @sqlCommand = 'BACKUP LOG ' +@DBNAME+  ' TO DISK = '''+@BackupFile+ ''' WITH INIT, NAME= ''' +@BackupName+''', NOSKIP, NOFORMAT'         
                  END 
--Ir a la siguiente base de datos
       EXEC(@sqlCommand) 

SELECT @Loop = min(ID) FROM @DBs where ID>@Loop 
END 

  
