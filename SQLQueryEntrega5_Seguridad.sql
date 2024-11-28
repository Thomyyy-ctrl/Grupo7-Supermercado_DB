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

	--El supervisor tendría acceso a la mayoría de los procedimientos almacenados, especialmente aquellos que permiten consultar,
	--insertar, actualizar y eliminar datos administrativos importantes.

	-- Otorgar permisos al rol Supervisor
	--Gestión de ventas:
	GRANT INSERT ON esquema_operaciones.NotaDeCredito TO Supervisor;
	GRANT EXECUTE ON esquema_Ventas.insertarVentas TO Supervisor;
	GRANT EXECUTE ON esquema_Ventas.importarVentasRegistradas TO Supervisor;
	GRANT EXECUTE ON esquema_Ventas.eliminarVenta TO Supervisor;
	
	--Gestión de detalles de venta:
	GRANT EXECUTE ON esquema_operaciones.insertarDetalleDeVenta TO Supervisor;
	GRANT EXECUTE ON esquema_operaciones.registrarDetalleDeVenta TO Supervisor;
	GRANT EXECUTE ON esquema_operaciones.eliminarDetalleDeVenta TO Supervisor;
	
	-- Gestión de medios de pago:
	GRANT EXECUTE ON esquema_operaciones.insertarMedioDePago TO Supervisor;
	GRANT EXECUTE ON esquema_operaciones.modificarMedioDePago TO Supervisor;
	GRANT EXECUTE ON esquema_operaciones.eliminarMedioDePago TO Supervisor;

	--Gestión de empleados y tipos de clientes:
	GRANT EXECUTE ON esquema_Persona.insertarEmpleado TO Supervisor;
	GRANT EXECUTE ON esquema_Persona.modificarEmpleado TO Supervisor;
	GRANT EXECUTE ON esquema_Persona.eliminarEmpleado TO Supervisor;
	GRANT EXECUTE ON esquema_Persona.ObtenerEmpleadoDesencriptado TO Supervisor;
	GRANT EXECUTE ON esquema_Persona.insertarTipoDeCliente TO Supervisor;
	GRANT EXECUTE ON esquema_Persona.modificarTipoDeCliente TO Supervisor;
	GRANT EXECUTE ON esquema_Persona.eliminarTipoDeCliente TO Supervisor;

	--Gestión de productos:
	GRANT EXECUTE ON esquema_Producto.insertarProducto TO Supervisor;
	GRANT EXECUTE ON esquema_Producto.modificarProducto TO Supervisor;
	GRANT EXECUTE ON esquema_Producto.eliminarProducto TO Supervisor;
	GRANT EXECUTE ON esquema_Producto.importarCatalogo TO Supervisor;
	GRANT EXECUTE ON esquema_Producto.importarLineDeProducto TO Supervisor;
	GRANT EXECUTE ON esquema_Producto.importarElectronico TO Supervisor;
	GRANT EXECUTE ON esquema_Producto.importarImportados TO Supervisor;

	--Gestión de sucursales:
	GRANT EXECUTE ON esquema_Sucursal.insertarSucursal TO Supervisor;
	GRANT EXECUTE ON esquema_Sucursal.modificarSucursal TO Supervisor;
	GRANT EXECUTE ON esquema_Sucursal.eliminarSucursal TO Supervisor;

	--Facturación y comprobantes:
	GRANT EXECUTE ON esquema_operaciones.insertarFactura TO Supervisor;
	GRANT EXECUTE ON esquema_operaciones.insertarNotaDeCredito TO Supervisor;

	--Reportes de ventas
	GRANT EXECUTE ON esquema_Ventas.GenerarReporteMensualXML TO Supervisor;
	GRANT EXECUTE ON esquema_Ventas.GenerarReportePorRangoFechasXML TO Supervisor;
	GRANT EXECUTE ON esquema_Ventas.GenerarReporteTrimestralXML TO Supervisor;
	GRANT EXECUTE ON esquema_Ventas.GenerarReporteVentasExtendidoXML TO Supervisor;
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

	--El rol de cajero generalmente tendría acceso limitado a las operaciones que son directamente relevantes para su trabajo,
	--como registrar ventas, procesar pagos y generar comprobantes. Por lo tanto, el acceso debería restringirse a procedimientos 
	--específicos relacionados con esas tareas.
	-- Otorgar permisos al rol Supervisor
	--Gestión de ventas:


	--Gestión de detalles de venta, medios de pago y factura:
	GRANT EXECUTE ON esquema_Ventas.insertarVentas TO Cajero;
	GRANT EXECUTE ON esquema_Ventas.importarVentasRegistradas TO Cajero;
	GRANT EXECUTE ON esquema_operaciones.insertarDetalleDeVenta TO Cajero;
	GRANT EXECUTE ON esquema_operaciones.registrarDetalleDeVenta TO Cajero;
	GRANT EXECUTE ON esquema_operaciones.insertarMedioDePago TO Cajero;
	GRANT EXECUTE ON esquema_operaciones.insertarFactura TO Cajero;
	GRANT EXECUTE ON esquema_operaciones.insertarNotaDeCredito TO Cajero;

	---Denegar permisos al rol:
	----Gestión administrativa y eliminacion de datos:
	DENY EXECUTE ON esquema_Sucursal.insertarSucursal TO Cajero;
	DENY EXECUTE ON esquema_Sucursal.modificarSucursal TO Cajero;
	DENY EXECUTE ON esquema_Sucursal.eliminarSucursal TO Cajero;
	DENY EXECUTE ON esquema_Persona.insertarEmpleado TO Cajero;
	DENY EXECUTE ON esquema_Persona.eliminarEmpleado TO Cajero;
	DENY EXECUTE ON esquema_Persona.modificarEmpleado TO Cajero;
	DENY EXECUTE ON esquema_Producto.insertarProducto TO Cajero;
	DENY EXECUTE ON esquema_Producto.eliminarProducto TO Cajero;
	DENY EXECUTE ON esquema_Producto.modificarProducto TO Cajero;
	DENY EXECUTE ON esquema_Producto.importarCatalogo TO Cajero;
	DENY EXECUTE ON esquema_Persona.modificarTipoDeCliente TO Cajero;
	DENY EXECUTE ON esquema_operaciones.eliminarDetalleDeVenta TO Cajero;
	DENY EXECUTE ON esquema_operaciones.eliminarMedioDePago TO Cajero;
	DENY EXECUTE ON esquema_operaciones.importarMediosDePago TO Cajero;
	DENY EXECUTE ON esquema_Producto.importarElectronico TO Cajero;
	DENY EXECUTE ON esquema_Producto.importarImportados TO Cajero;
	DENY EXECUTE ON esquema_Producto.importarLineDeProducto TO Cajero;
	DENY EXECUTE ON esquema_Producto.importarCatalogo TO Cajero;
	
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
            CAST(CAST(DecryptByPassPhrase('FraseSegura',legajo) as varchar(500)) as int) as legajo,
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


CREATE OR ALTER PROCEDURE esquema_Persona.desencriptarTablaEmpleado
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar que la tabla de ventas no este vacia.
				IF EXISTS (SELECT 1 FROM esquema_Persona.empleado)
		BEGIN
			PRINT 'La tabla tiene registros.'
		END
		ELSE
		BEGIN
			PRINT 'La tabla Empleado está vacía.'
			RETURN;
		END;

				SELECT------cambiar varbinary legajo
				id,
				CAST(CAST(DECRYPTBYPASSPHRASE('FraseSegura',legajo) as varchar(500)) as int) as legajo,
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


        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- En caso de error, revertir la transacción
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Captura del mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanza el error con RAISERROR
        RAISERROR ('No se pudo mostrar la tabla de empleados', 
                    @ErrorSeverity, @ErrorMessage);
    END CATCH
END;
GO


















