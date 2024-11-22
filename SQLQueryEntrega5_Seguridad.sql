use master
go
USE SUPERMERCADO_Grupo7
go

--------ENTREGA 5
--------Cree la tabla Notas De Credito
--------Solo los supervisores pueden generar Notas de Credito entonces es importante restringir la insercion 
--      de registros en la tabla Notas de Credito unicamente  a los usuarios con el rol de "Supervisor"



----------------------------Insertar notas de credito

CREATE OR ALTER PROCEDURE esquema_operaciones.insertarNotaDeCredito(
    @nroFactura INT,
    @tipoDeFactura VARCHAR(20),
    @TipoDeCliente VARCHAR(30),
    @Fecha DATETIME = NULL,  -- Valor predeterminado
    @Valor DECIMAL(38,2),
    @Motivo VARCHAR(150),
    @idFactura INT,
    @idCliente INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION

        -- Establece un valor predeterminado para la fecha si no se proporciona
        SET @Fecha = ISNULL(@Fecha, GETDATE());

        -- Evitar mostrar la cantidad de filas afectadas en la consola
        SET NOCOUNT ON;

        -- Verificar si la factura existe
        IF NOT EXISTS (SELECT 1 FROM esquema_operaciones.Factura WHERE id = @idFactura)
        BEGIN
            RAISERROR('Error: El idFactura especificado no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar si el cliente existe
        IF NOT EXISTS (SELECT 1 FROM esquema_Persona.Cliente WHERE id = @idCliente)
        BEGIN
            RAISERROR('Error: El idCliente especificado no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Inserta los valores en la tabla NotaDeCredito
        INSERT INTO esquema_operaciones.NotaDeCredito (nroFactura, tipoDeFactura, TipoDeCliente, Fecha, Valor, Motivo)
        VALUES (@nroFactura, @tipoDeFactura, @TipoDeCliente, @Fecha, @Valor, @Motivo);

        -- Confirmar la transacción
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        -- Si ocurre un error, revertir la transacción y lanzar el error
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        
        -- Obtener detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        -- Lanzar el error con RAISERROR
        RAISERROR ('No se pudo insertar la nota de crédito. Detalles: %s', 
                   @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO

-----------------------Logins
---------login del supervisor

CREATE LOGIN LogMartina WITH PASSWORD = '123456789';
go
----------login de cajero

CREATE LOGIN LogThomas WITH PASSWORD = '111';
go


----------------------Users:

---------User del supervisor
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'MartinaGarcia')
BEGIN
    PRINT 'El Usuario MartinaGarcia ya existe.';
END
ELSE
BEGIN
    CREATE USER MartinaGarcia FOR LOGIN LogMartina;
    PRINT 'El Usuario MartinaGarcia ha sido creado';
END
go
---------User del Cajero
IF EXISTS (SELECT 1FROM sys.database_principals WHERE name = 'ThomasPerez')
BEGIN
    PRINT 'El Usuario ThomasPerez ya existe.';
END
ELSE
BEGIN
    CREATE USER ThomasPerez FOR LOGIN LogThomas;
    PRINT 'El Usuario ThomasPerez ha sido creado';
END
go

------------------------------Creacion del rol Supervisor

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Supervisor' AND type = 'R')
BEGIN
    PRINT 'El rol Supervisor ya existe.';
END
ELSE
BEGIN
	-- Revocar permisos de INSERT para todos los usuarios en la tabla NotasDeCredito
	REVOKE INSERT ON esquema_operaciones.NotaDeCredito FROM PUBLIC;
	CREATE ROLE Supervisor;
	-- Otorgar permisos de INSERT solo al rol Supervisor
	GRANT INSERT ON esquema_operaciones.NotaDeCredito TO Supervisor;
    PRINT 'El rol Supervisor ha sido creado.';
END
go
-- Asigna el rol Supervisor a los usuarios autorizados
ALTER ROLE Supervisor ADD MEMBER MartinaGarcia;
--Asignar permiso para ejecutar la el SP
GRANT EXECUTE ON esquema_operaciones.insertarNotaDeCredito TO MartinaGarcia;
go


--------------------------------creacion del rol Cajero

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Cajero' AND type = 'R')
BEGIN
    PRINT 'El rol Cajero ya existe.';
END
ELSE
BEGIN
	CREATE ROLE Cajero;
    PRINT 'El rol Cajero ha sido creado.';
END
go
-- Asigna el rol Supervisor a los usuarios autorizados
ALTER ROLE Cajero ADD MEMBER ThomasPerez;
--Denegar permiso para ejecutar la el SP
DENY EXECUTE ON esquema_operaciones.insertarNotaDeCredito TO ThomasPerez;
go


----El trigger valida que sea el rol Supervisor quien genere una Nota de Credito

CREATE  OR ALTER TRIGGER ValidarInsercionDeSupervisor ON esquema_operaciones.NotaDeCredito 
INSTEAD OF INSERT
AS
BEGIN
	BEGIN TRY
		-- Verificar si el usuario actual pertenece al rol 'Supervisor'
		IF IS_MEMBER('Supervisor') = 0
		BEGIN
			-- Si el usuario no es miembro del rol 'Supervisor', se genera un error y se cancela la operación
			RAISERROR ('Error: Solo los supervisores pueden insertar en la tabla NotasDeCredito.', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN;
		END

		-- Si el usuario pertenece al rol 'Supervisor', no se realiza ninguna acción y se permite la inserción desde el procedimiento almacenado.
    
	END TRY
	BEGIN CATCH
		-- Manejo de errores: captura detalles del error y lanza un mensaje personalizado
		DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

		-- Obtener detalles del error
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();

		-- Lanzar el error capturado
		RAISERROR ('Se produjo un error en el trigger ValidarInsercionDeSupervisor. Detalles: %s', 
					@ErrorSeverity, @ErrorState, @ErrorMessage);
        
		-- Revertir la transacción en caso de error
		ROLLBACK TRANSACTION;
	END CATCH
END;
go


-- Desencripta los datos del empleado enviando como parametro su ID
-- Tanto para encriptar como desencriptar se utiliza una "Frase Segura"
CREATE OR ALTER PROCEDURE esquema_Persona.ObtenerEmpleadoDesencriptado (@id INT)
AS
BEGIN
    BEGIN TRY
        -- Selección de los datos con desencriptación
        SELECT
            id,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), legajo))) AS legajo,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', nombre)) AS nombre,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', apellido)) AS apellido,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', nroDoc)) AS nroDoc,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', calleYNum)) AS calleYNum,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', localidad)) AS localidad,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', provincia)) AS provincia,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', cuil)) AS cuil,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', cargo)) AS cargo,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', sucursal)) AS sucursal,
            CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('FraseSegura', turno)) AS turno,
            CONVERT(VARCHAR(100), DECRYPTBYPASSPHRASE('FraseSegura', emailPersonal)) AS emailPersonal,
            CONVERT(VARCHAR(100), DECRYPTBYPASSPHRASE('FraseSegura', emailEmpresa)) AS emailEmpresa,
            idSucursal
        FROM esquema_Persona.empleado
        WHERE id = @id;

        -- Si no se encuentra ningún registro con el id proporcionado
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR ('No se encontró ningún empleado con el ID proporcionado.', 16, 1);
        END
    END TRY
    BEGIN CATCH
        -- Declarar variables para capturar detalles del error
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Obtener los detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error capturado con un mensaje personalizado
        RAISERROR ('Se produjo un error al intentar obtener los datos desencriptados del empleado. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO
















