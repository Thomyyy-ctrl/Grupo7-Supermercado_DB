use SUPERMERCADO_Grupo7
go

-------------------------- EMPLEADOS--------STORES MODIFICADOS PARA LA ENCRIPTACION
---------TABLA REFERENCIADA
-----Inserta los datos encriptados en la tabla
CREATE OR ALTER PROCEDURE esquema_Persona.insertarEmpleado(
    @legajo INT,
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @nroDoc INT,
    @calleYNum VARCHAR(50),
    @localidad VARCHAR(50),
    @provincia VARCHAR(50),
    @cuil INT,
    @cargo VARCHAR(50),
    @sucursal VARCHAR(50),
    @turno VARCHAR(50),
    @emailPersonal VARCHAR(100),
    @emailEmpresa VARCHAR(100),
    @idSucursal INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificar si la sucursal existe
        IF NOT EXISTS (SELECT 1 FROM esquema_Sucursal.sucursales WHERE id = @idSucursal)
        BEGIN
            RAISERROR('Error: la sucursal no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar si ya existe un empleado con el mismo legajo o número de documento
        IF EXISTS (
            SELECT 1 
            FROM esquema_Persona.empleado 
            WHERE 
                legajo = ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @legajo))
                OR nroDoc = ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @nroDoc))
        )
        BEGIN
            RAISERROR('Error: Ya existe un empleado con el mismo legajo o número de documento.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SET NOCOUNT ON; -- Evita mostrar la cantidad de filas afectadas.

        -- Inserta los valores encriptados en la tabla empleado
        INSERT INTO esquema_Persona.empleado (
            legajo, nombre, apellido, nroDoc, calleYNum, localidad, provincia, cuil, cargo, sucursal, turno, emailPersonal, emailEmpresa
        )
        VALUES (
            ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @legajo)),
            ENCRYPTBYPASSPHRASE('FraseSegura', @nombre),
            ENCRYPTBYPASSPHRASE('FraseSegura', @apellido),
            ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @nroDoc)),
            ENCRYPTBYPASSPHRASE('FraseSegura', @calleYNum),
            ENCRYPTBYPASSPHRASE('FraseSegura', @localidad),
            ENCRYPTBYPASSPHRASE('FraseSegura', @provincia),
            ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @cuil)),
            ENCRYPTBYPASSPHRASE('FraseSegura', @cargo),
            ENCRYPTBYPASSPHRASE('FraseSegura', @sucursal),
            ENCRYPTBYPASSPHRASE('FraseSegura', @turno),
            ENCRYPTBYPASSPHRASE('FraseSegura', @emailPersonal),
            ENCRYPTBYPASSPHRASE('FraseSegura', @emailEmpresa)
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Si el procedimiento falla, se captura el error y se lanza con RAISERROR.
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Obtener detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR
        RAISERROR (
            'No se pudo insertar el empleado %s, %s. Detalles: %s', 
            @ErrorSeverity, @ErrorState, @apellido, @nombre, @ErrorMessage
        );
    END CATCH
END;
GO

-- Encripta los datos de ID y legajo y despues compara con los datos encriptados en la tabla
CREATE OR ALTER PROCEDURE esquema_Persona.modificarEmpleado(
    @id INT,
    @legajo INT,
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @nroDoc INT,
    @calleYNum VARCHAR(50),
    @localidad VARCHAR(50),
    @provincia VARCHAR(50),
    @cuil INT,
    @cargo VARCHAR(50),
    @sucursal VARCHAR(50),
    @turno VARCHAR(50),
    @emailPersonal VARCHAR(100),
    @emailEmpresa VARCHAR(100),
    @idSucursal INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar si el legajo y el ID están presentes
        IF @legajo IS NULL OR @id IS NULL
        BEGIN
            RAISERROR ('Se debe enviar el legajo y el ID del empleado.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SET NOCOUNT ON;

        -- Encriptar el legajo y el ID proporcionados como parámetros
        DECLARE @legajoEncriptado VARBINARY(MAX);
        DECLARE @idEncriptado VARBINARY(MAX);

        SET @legajoEncriptado = ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @legajo));
        SET @idEncriptado = ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @id));

        -- Verificar si el empleado existe (comparando los valores encriptados)
        IF NOT EXISTS (SELECT 1 FROM esquema_Persona.empleado WHERE legajo = @legajoEncriptado AND id = @idEncriptado)
        BEGIN
            RAISERROR('Error: El empleado con el ID y legajo especificados no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Verificar si la sucursal existe
        IF NOT EXISTS (SELECT 1 FROM esquema_Sucursal.sucursales WHERE id = @idSucursal)
        BEGIN
            RAISERROR('Error: la sucursal no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Realizar la actualización con encriptación
        UPDATE esquema_Persona.empleado
        SET
            nombre = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', @nombre), nombre),
            apellido = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', @apellido), apellido),
            nroDoc = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @nroDoc)), nroDoc),
            calleYNum = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', @calleYNum), calleYNum),
            localidad = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', @localidad), localidad),
            provincia = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', @provincia), provincia),
            cuil = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @cuil)), cuil),
            cargo = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', @cargo), cargo),
            sucursal = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', @sucursal), sucursal),
            turno = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', @turno), turno),
            emailPersonal = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', @emailPersonal), emailPersonal),
            emailEmpresa = COALESCE(ENCRYPTBYPASSPHRASE('FraseSegura', @emailEmpresa), emailEmpresa)
        WHERE legajo = @legajoEncriptado AND id = @idEncriptado;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- En caso de error, revertir la transacción y capturar el error
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Captura del mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanza el error con RAISERROR
        RAISERROR ('No se pudo actualizar el empleado %s, %s. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @apellido, @nombre, @ErrorMessage);
    END CATCH
END;
GO

-- Encripta los datos de ID y legajo y despues compara con los datos encriptados en la tabla
CREATE OR ALTER PROCEDURE esquema_Persona.eliminarEmpleado( 
    @id INT,
    @legajo INT)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar que los parámetros no sean NULL
        IF @legajo IS NULL OR @id IS NULL
        BEGIN
            RAISERROR ('Se debe enviar el legajo y el ID del empleado', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON;

        -- Encriptar los parámetros legajo y id
        DECLARE @legajoEncriptado VARBINARY(MAX);
        DECLARE @idEncriptado VARBINARY(MAX);

        SET @legajoEncriptado = ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @legajo));
        SET @idEncriptado = ENCRYPTBYPASSPHRASE('FraseSegura', CONVERT(VARCHAR(50), @id));

        -- Verificar si el empleado existe en la base de datos (comparando los valores encriptados)
        IF EXISTS (SELECT 1 FROM esquema_Persona.empleado WHERE legajo = @legajoEncriptado AND id = @idEncriptado)
        BEGIN
            -- Eliminar el empleado si existe
            DELETE FROM esquema_Persona.empleado WHERE legajo = @legajoEncriptado AND id = @idEncriptado;
        END
        ELSE
        BEGIN
            -- Si el empleado no existe, lanzar un error
            RAISERROR ('No existe empleado con legajo %d y ID %d', 16, 1, @legajo, @id);
            RETURN;
        END

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
        RAISERROR ('No se pudo eliminar el empleado con legajo %d y ID %d. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @legajo, @id, @ErrorMessage);
    END CATCH
END;
GO


--------------------------------------TIPO DE CLIENTES:
-------TABLA NO REFERENCIADA
CREATE OR ALTER PROCEDURE esquema_Persona.insertarTipoDeCliente
    @tipoCliente VARCHAR(30),
    @Descripcion VARCHAR(100)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        SET NOCOUNT ON; -- No mostrar la cantidad de filas afectadas.
        
        -- Verificar si ya existe un tipo de cliente con el mismo nombre
        IF EXISTS (
            SELECT 1 
            FROM esquema_Persona.cliente 
            WHERE tipoCliente = @tipoCliente
        )
        BEGIN
            RAISERROR('Error: Ya existe un tipo de cliente con el nombre especificado.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insertar nuevo tipo de cliente
        INSERT INTO esquema_Persona.cliente (tipoCliente, Descripcion)
        VALUES (@tipoCliente, @Descripcion);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Captura del mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR
        RAISERROR ('No se pudo insertar el tipo de cliente. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE esquema_Persona.modificarTipoDeCliente
    @id INT,
    @tipoCliente VARCHAR(30),
    @Descripcion VARCHAR(10)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @id IS NULL
        BEGIN
            RAISERROR ('Se debe enviar el ID del cliente', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON;

        -- Verificar si el cliente existe
        IF EXISTS (SELECT 1 FROM esquema_Persona.cliente WHERE id = @id)
        BEGIN
            -- Actualizar los datos del cliente
            UPDATE esquema_Persona.cliente
            SET
                tipoCliente = COALESCE(@tipoCliente, tipoCliente),
                Descripcion = COALESCE(@Descripcion, Descripcion)
            WHERE id = @id;
        END
        ELSE
        BEGIN
            RAISERROR ('No existe el cliente con ID %d', 16, 1, @id);
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Captura del mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR
        RAISERROR ('No se pudo actualizar el cliente con ID %d. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @id, @ErrorMessage);
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE esquema_Persona.eliminarTipoDeCliente 
    @id INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @id IS NULL
        BEGIN
            RAISERROR ('Se debe enviar el ID del cliente', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON;

        -- Verificar si el cliente existe
        IF EXISTS (SELECT 1 FROM esquema_Persona.cliente WHERE id = @id)
        BEGIN
            -- Eliminar el tipo de cliente
            DELETE FROM esquema_Persona.cliente WHERE id = @id;
        END
        ELSE
        BEGIN
            RAISERROR ('No existe cliente con ID %d', 16, 1, @id);
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Captura del mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR
        RAISERROR ('No se pudo eliminar el cliente con ID %d. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @id, @ErrorMessage);
    END CATCH
END;
GO


------------------------------------MEDIOS DE PAGO
-------TABLA NO REFERNCIADA
CREATE OR ALTER PROCEDURE esquema_operaciones.insertarMedioDePago(
    @MedioDePago VARCHAR(50),
    @NombreEs VARCHAR(50)
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        SET NOCOUNT ON;  -- No mostrar la cantidad de filas insertadas por consola.

        -- Verificar si ya existe el medio de pago
        IF EXISTS (
            SELECT 1 
            FROM esquema_operaciones.mediosDePago 
            WHERE MedioDePago = @MedioDePago
        )
        BEGIN
            RAISERROR('Error: El medio de pago ya existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insertar el medio de pago
        INSERT INTO esquema_operaciones.mediosDePago (MedioDePago, NombreEs)
        VALUES (@MedioDePago, @NombreEs);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Captura del mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR
        RAISERROR('No se pudo insertar el medio de pago. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE esquema_operaciones.modificarMedioDePago
    @id INT,
    @MedioDePago VARCHAR(50),
    @NombreEs VARCHAR(50)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificación de que el ID no sea NULL
        IF @id IS NULL
        BEGIN
            RAISERROR ('Se debe enviar el id DE Medios de pago', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON;

        -- Verificar si el medio de pago existe
        IF EXISTS (SELECT 1 FROM esquema_operaciones.mediosDePago WHERE id = @id)
        BEGIN
            -- Actualizar los datos del medio de pago usando COALESCE para conservar valores existentes si el parámetro es NULL
            UPDATE esquema_operaciones.mediosDePago
            SET
                MedioDePago = COALESCE(@MedioDePago, MedioDePago),
                NombreEs = COALESCE(@NombreEs, NombreEs)
            WHERE id = @id;
        END
        ELSE
        BEGIN
            RAISERROR ('No existe el id de medios de pago con ID %d', 16, 1, @id);
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Captura del mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR
        RAISERROR ('No se pudo modificar el medios de pago con ID %d. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @id, @ErrorMessage);
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE esquema_operaciones.eliminarMedioDePago (@id INT)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @id IS NULL
        BEGIN
            RAISERROR ('Se debe enviar el id de medios de pago', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON;

        -- Verificar si el medio de pago existe
        IF EXISTS (SELECT 1 FROM esquema_operaciones.mediosDePago WHERE id = @id)
        BEGIN
            -- Eliminar el medio de pago
            DELETE FROM esquema_operaciones.mediosDePago WHERE id = @id;
        END
        ELSE
        BEGIN
            RAISERROR ('No existe el id de medios de pago con ID %d', 16, 1, @id);
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Captura del mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR
        RAISERROR ('No se pudo eliminar el identificador de pago con ID %d. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @id, @ErrorMessage);
    END CATCH
END;
GO


-------------------------------LINEA DE PRODUCTO
-------TABLA REFERENCIADA
CREATE OR ALTER PROCEDURE esquema_Producto.insertarLineaDeProducto
    @idProducto INT,
    @lineaDeProducto VARCHAR(20), 
    @productoDescrip VARCHAR(200)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificación de que el ID de Producto no sea NULL
        IF @idProducto IS NULL
        BEGIN
            RAISERROR('Se debe enviar el ID del producto', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON; -- No mostrar la cantidad de filas insertadas en consola

        -- Verificación de existencia de idProducto en la tabla Producto
        IF NOT EXISTS (SELECT 1 FROM esquema_Producto.Producto WHERE id = @idProducto)
        BEGIN
            RAISERROR('El ID de producto proporcionado no existe en la tabla Producto', 16, 1);
            RETURN;
        END

        -- Verificar si ya existe la línea de producto para el idProducto
        IF EXISTS (SELECT 1 
                   FROM esquema_Producto.LineaDeProducto 
                   WHERE idProducto = @idProducto AND lineaProducto = @lineaDeProducto)
        BEGIN
            RAISERROR('La línea de producto ya existe para el producto con ID %d', 16, 1, @idProducto);
            RETURN;
        END

        -- Insertar la línea de producto
        INSERT INTO esquema_Producto.LineaDeProducto (lineaProducto, productoDescrip, idProducto)
        VALUES (@lineaDeProducto, @productoDescrip, @idProducto);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Captura del mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR
        RAISERROR('No se pudo insertar la línea de producto. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE esquema_Producto.modificarLineaDeProducto
    @id INT,
    @lineaProducto VARCHAR(20),
    @productoDescrip VARCHAR(200)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificación de que el ID no sea NULL
        IF @id IS NULL
        BEGIN
            RAISERROR('Se debe enviar el ID de la línea de producto', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON; -- No mostrar la cantidad de filas afectadas en consola

        -- Verificación de existencia de la línea de producto
        IF EXISTS (SELECT 1 FROM esquema_Producto.LineaDeProducto WHERE id = @id)
        BEGIN
            -- Actualizar la línea de producto con los valores proporcionados o mantener los actuales si son NULL
            UPDATE esquema_Producto.LineaDeProducto
            SET
                lineaProducto = COALESCE(@lineaProducto, lineaProducto),
                productoDescrip = COALESCE(@productoDescrip, productoDescrip)
            WHERE id = @id;
        END
        ELSE
        BEGIN
            -- Lanzar un error con RAISERROR si no existe la línea de producto con el @id proporcionado
            RAISERROR('No existe la línea de producto con ID %d', 16, 1, @id);
            RETURN; -- Evita continuar si no existe la línea de producto
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Captura del mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR con detalles del error original
        RAISERROR('No se pudo actualizar la linea de producto. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE esquema_Producto.eliminarLineaDeProducto (@id INT)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificación de que el @id no sea NULL
        IF @id IS NULL
        BEGIN
            RAISERROR('Se debe enviar el id de la línea de producto', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON; -- No mostrar la cantidad de filas afectadas en consola

        -- Verificación de existencia del id en la tabla
        IF EXISTS (SELECT 1 FROM esquema_Producto.LineaDeProducto WHERE id = @id)
        BEGIN
            -- Eliminar la línea de producto
            DELETE FROM esquema_Producto.LineaDeProducto WHERE id = @id;
        END
        ELSE
        BEGIN
            -- Lanzar un error si no se encuentra el id
            RAISERROR('No existe el id de línea de producto %d', 16, 1, @id);
            RETURN; -- Evitar que se continúe la ejecución si no se encuentra el id
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Si ocurre un error, revertir la transacción
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Capturar los detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR
        RAISERROR('No se pudo eliminar la línea de producto. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO


------------------------------SUCURSAL
-------TABLA NO REFERNCIADA
CREATE OR ALTER PROCEDURE esquema_Sucursal.insertarSucursal (
    @ciudad VARCHAR(15),
    @reemplazadaX VARCHAR(50),
    @calleYNum VARCHAR(50),
    @localidadYCodPostal VARCHAR(50),
    @provincia VARCHAR(150),
    @horario VARCHAR(50),
    @telefono INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        SET NOCOUNT ON; -- No mostrar la cantidad de filas insertadas en consola

        -- Verificar si ya existe una sucursal con el mismo calleYNum
        IF EXISTS (SELECT 1 FROM esquema_Sucursal.sucursales WHERE calleYNum = @calleYNum)
        BEGIN
            RAISERROR('Ya existe una sucursal con el mismo calle y número: %s', 16, 1, @calleYNum);
            RETURN;
        END

        -- Inserción de la nueva sucursal
        INSERT INTO esquema_Sucursal.sucursales (
            ciudad,
            reemplazadaX,
            calleYNum,
            localidadYCodPostal,
            provincia,
            horario,
            telefono
        )
        VALUES (
            @ciudad,
            @reemplazadaX,
            @calleYNum,
            @localidadYCodPostal,
            @provincia,
            @horario,
            @telefono
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Revertir la transacción en caso de error
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Capturar detalles del error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error con RAISERROR
        RAISERROR('No se pudo insertar la nueva sucursal. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE esquema_Sucursal.modificarSucursal (
    @id INT,
    @ciudad VARCHAR(15),
    @reemplazadaX VARCHAR(50),
    @calleYNum VARCHAR(50),
    @localidadYCodPostal VARCHAR(50),
    @provincia VARCHAR(150),
    @horario VARCHAR(50),
    @telefono INT
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificar si se proporciona el ID
        IF (@id IS NULL)
        BEGIN
            RAISERROR('Se debe enviar el ID de la sucursal', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON;

        -- Verificar si la sucursal con el ID existe
        IF EXISTS (SELECT 1 FROM esquema_Sucursal.sucursales WHERE id = @id)
        BEGIN
            -- Actualizar los valores de la sucursal
            UPDATE esquema_Sucursal.sucursales
            SET
                ciudad = COALESCE(@ciudad, ciudad),
                reemplazadaX = COALESCE(@reemplazadaX, reemplazadaX),
                calleYNum = COALESCE(@calleYNum, calleYNum),
                localidadYCodPostal = COALESCE(@localidadYCodPostal, localidadYCodPostal),
                provincia = COALESCE(@provincia, provincia),
                horario = COALESCE(@horario, horario),
                telefono = COALESCE(@telefono, telefono)
            WHERE id = @id;
        END
        ELSE
        BEGIN
            RAISERROR('No existe la sucursal con ID %d', 16, 1, @id);
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Capturar el error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error
        RAISERROR('No se pudo actualizar la sucursal. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE esquema_Sucursal.eliminarSucursal (@id INT)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificar si el ID fue proporcionado
        IF (@id IS NULL)
        BEGIN
            RAISERROR('Se debe enviar el ID de la sucursal', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON;

        -- Verificar si la sucursal con el ID existe
        IF EXISTS (SELECT 1 FROM esquema_Sucursal.sucursales WHERE id = @id)
        BEGIN
            -- Eliminar la sucursal
            DELETE FROM esquema_Sucursal.sucursales WHERE id = @id;
        END
        ELSE
        BEGIN
            -- Si la sucursal no existe, lanzar un error
            RAISERROR('No existe la sucursal con ID %d', 16, 1, @id);
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- En caso de error, hacer rollback de la transacción
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Capturar el mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error
        RAISERROR('No se pudo eliminar la sucursal. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO


-----------------------------PRODUCTOS
--------TABLA NO REFERENCIADA

CREATE OR ALTER PROCEDURE esquema_Producto.insertarProducto
(
    @idCatalogo INT, 
    @category VARCHAR(100), 
    @nombre VARCHAR(150), 
    @precio DECIMAL(10,2), 
    @precio_Referencia DECIMAL(10,2), 
    @unidad_Referencia VARCHAR(10), 
    @fechaYhorario DATETIME,
    @idImportado INT, 
    @nombreproducto VARCHAR(150), 
    @Proveedor VARCHAR(50), 
    @categoria VARCHAR(20), 
    @CantidadxUnidad VARCHAR(50), 
    @PrecioUnidad DECIMAL(5,2),
    @productoElectronicoNombre VARCHAR(150),
    @precioUniElectronico DECIMAL(38,2)
)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificar si ya existe un producto con el idCatalogo
        IF EXISTS (SELECT 1 FROM esquema_Producto.Producto WHERE idCatalogo = @idCatalogo)
        BEGIN
            RAISERROR('Ya existe un producto con el idCatalogo %d. El id debe ser único.', 16, 1, @idCatalogo);
            RETURN;
        END

        -- Verificar si ya existe un producto con el idImportado
        IF EXISTS (SELECT 1 FROM esquema_Producto.Producto WHERE idImportado = @idImportado)
        BEGIN
            RAISERROR('Ya existe un producto con el idImportado %d. El id debe ser único.', 16, 1, @idImportado);
            RETURN;
        END

        -- Verificar si ya existe un producto electrónico con el mismo nombre y precio
        IF EXISTS (SELECT 1 FROM esquema_Producto.Producto 
                   WHERE productoElectronicoNombre = @productoElectronicoNombre 
                     AND precioUniElectronico = @precioUniElectronico)
        BEGIN
            RAISERROR('Ya existe un producto electrónico con el mismo nombre y precio. Nombre: %s, Precio: %f.', 
                        16, 1, @productoElectronicoNombre, @precioUniElectronico);
            RETURN;
        END

        -- Insertar el nuevo producto con los valores proporcionados
        INSERT INTO esquema_Producto.Producto
        (
            idCatalogo, 
            category, 
            nombre, 
            precio, 
            precio_Referencia, 
            unidad_Referencia, 
            fechaYhorario, 
            idImportado, 
            nombreproducto, 
            Proveedor, 
            categoria, 
            CantidadxUnidad, 
            PrecioUnidad, 
            productoElectronicoNombre, 
            precioUniElectronico
        )
        VALUES
        (
            @idCatalogo, 
            @category, 
            @nombre, 
            @precio, 
            @precio_Referencia, 
            @unidad_Referencia, 
            @fechaYhorario, 
            @idImportado, 
            @nombreproducto, 
            @Proveedor, 
            @categoria, 
            @CantidadxUnidad, 
            @PrecioUnidad, 
            @productoElectronicoNombre, 
            @precioUniElectronico
        );

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- Captura del mensaje de error y lanzamiento del error con RAISERROR
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        RAISERROR('Error al insertar el producto. Detalles: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE esquema_Producto.modificarProducto
(
    @idCatalogo INT, 
    @category VARCHAR(100), 
    @nombre VARCHAR(150), 
    @precio DECIMAL(10,2), 
    @precio_Referencia DECIMAL(10,2), 
    @unidad_Referencia VARCHAR(10), 
    @fechaYhorario DATETIME,
    @idImportado INT, 
    @nombreproducto VARCHAR(150), 
    @Proveedor VARCHAR(50), 
    @categoria VARCHAR(20), 
    @CantidadxUnidad VARCHAR(50), 
    @PrecioUnidad DECIMAL(5,2),
    @productoElectronicoNombre VARCHAR(150),
    @precioUniElectronico decimal(38,2)
)
AS
BEGIN
	BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificar si ya existe un producto con el idCatalogo
        IF NOT EXISTS (SELECT 1 FROM esquema_Producto.Producto WHERE idCatalogo = @idCatalogo)
        BEGIN
            RAISERROR('Ya existe un producto con el idCatalogo %d. El id debe ser único.', 16, 1, @idCatalogo);
            RETURN;
        END

        -- Verificar si ya existe un producto con el idImportado
        IF NOT EXISTS (SELECT 1 FROM esquema_Producto.Producto WHERE idImportado = @idImportado)
        BEGIN
            RAISERROR('Ya existe un producto con el idImportado %d. El id debe ser único.', 16, 1, @idImportado);
            RETURN;
        END
        -- Modificar el producto con valores nulos utilizando COALESCE para mantener el valor actual si el parámetro es nulo
        UPDATE esquema_Producto.Producto
        SET
		    idCatalogo = COALESCE(@idCatalogo,idCatalogo), 
            category = COALESCE(@category, category),
            nombre = COALESCE(@nombre, nombre),
            precio = COALESCE(@precio, precio),
            precio_Referencia = COALESCE(@precio_Referencia, precio_Referencia),
            unidad_Referencia = COALESCE(@unidad_Referencia, unidad_Referencia),
            fechaYhorario = COALESCE(@fechaYhorario, fechaYhorario),
            idImportado = COALESCE(@idImportado, idImportado),
            nombreproducto = COALESCE(@nombreproducto, nombreproducto),
            Proveedor = COALESCE(@Proveedor, Proveedor),
            categoria = COALESCE(@categoria, categoria),
            CantidadxUnidad = COALESCE(@CantidadxUnidad, CantidadxUnidad),
            PrecioUnidad = COALESCE(@PrecioUnidad, PrecioUnidad),
            productoElectronicoNombre = COALESCE(@productoElectronicoNombre, productoElectronicoNombre),
            precioUniElectronico = COALESCE(@precioUniElectronico ,precioUniElectronico )
        WHERE idCatalogo = @idCatalogo

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        -- Manejo del error, se captura el mensaje de error y se lanza un RAISERROR
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        RAISERROR('Error al modificar el producto. Detalles: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE esquema_Producto.eliminarProducto (@id INT)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificar si el ID fue proporcionado
        IF (@id IS NULL)
        BEGIN
            RAISERROR('Se debe enviar el ID del producto', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON;

        -- Verificar si el producto con el ID existe
        IF EXISTS (SELECT 1 FROM esquema_Producto.Producto WHERE id = @id)
        BEGIN
            -- Eliminar el producto
            DELETE FROM esquema_Producto.Producto WHERE id = @id;
        END
        ELSE
        BEGIN
            -- Si el producto no existe, lanzar un error
            RAISERROR('No existe el producto con ID %d', 16, 1, @id);
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- En caso de error, hacer rollback de la transacción
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;

        -- Capturar el mensaje de error
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Lanzar el error
        RAISERROR('No se pudo eliminar el Producto. Detalles: %s', 
                    @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO

-- Procedimiento para insertar una nueva venta
CREATE OR ALTER PROCEDURE esquema_Ventas.insertarVentas(
    @idFactura bigint,
    @TipoDeFactura VARCHAR(1),  -- 'A', 'B' o 'C'
    @Ciudad VARCHAR(15),
    @TipoDeCliente VARCHAR(30),
    @Genero VARCHAR(20),
    @Producto VARCHAR(150),
    @PrecioUnitario DECIMAL(3,2),
    @Cantidad INT,
    @Fecha DATE,
    @Hora TIME,
    @MedioDePago VARCHAR(20),
    @Empleado INT,
    @IdIdentificador VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificar si el idFactura ya existe en la tabla ventasRegistradas
        IF EXISTS (SELECT 1 FROM esquema_Ventas.ventasRegistradas WHERE idFactura = @idFactura)
        BEGIN
            RAISERROR('Ya existe una venta con el idFactura %d. El idFactura debe ser único.', 16, 1, @idFactura);
            RETURN;  -- Si existe, sale del procedimiento sin continuar con la inserción
        END

        -- Insertar la venta
        INSERT INTO esquema_Ventas.ventasRegistradas(idFactura, tipoDeFactura, ciudad, tipoDeCliente, genero, producto, precioUnitario, cantidad, fecha, hora, medioDePago, idIdentificador)
        VALUES (@idFactura, @TipoDeFactura, @Ciudad, @TipoDeCliente, @Genero, @Producto, @PrecioUnitario, @Cantidad, @Fecha, @Hora, @MedioDePago, @IdIdentificador);

        -- Obtener el ID de la venta insertada
        DECLARE @NuevoVentaID INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Retornar el ID de la venta insertada
        SELECT @NuevoVentaID AS VentaID;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- Captura del mensaje de error y lanzamiento del error con RAISERROR
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        RAISERROR('Error al insertar la venta. Detalles: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO


-- Procedimiento para insertar los detalles de la venta
CREATE OR ALTER PROCEDURE esquema_operaciones.insertarDetalleDeVenta(
    @VentaID INT,  -- ID de la venta a la que se asociarán los detalles
    @Codigo INT,  -- Código del producto
    @Descripcion VARCHAR(30),  -- Descripción del producto
    @PrecioUnitario DECIMAL(4,2),  -- Precio unitario
    @Cantidad INT,  -- Cantidad del producto
    @Subtotal DECIMAL(5,2),-- Subtotal de la venta
	@idProducto int)
AS
BEGIN
BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificación de que el ID de venta y ID de Producto no sean NULL
        IF @VentaID IS NULL OR @idProducto IS NULL 
        BEGIN
            RAISERROR ('Se debe enviar EL id de venta y el id del producto', 16, 1);
            RETURN;
        END

        SET NOCOUNT ON; -- No mostrar la cantidad de filas insertadas en consola

        -- Verificación de existencia de idProducto en la tabla Producto
        IF NOT EXISTS (SELECT 1 FROM esquema_Producto.Producto WHERE id = @idProducto)
        BEGIN
            RAISERROR ('El ID de producto proporcionado no existe en la tabla Producto', 16, 1);
            RETURN;
        END
       -- Verificación de existencia de idVenta en la tabla Ventas
        IF NOT EXISTS (SELECT 1 FROM esquema_Ventas.ventasRegistradas where id = @VentaID)
        BEGIN
            RAISERROR ('El ID de Ventas no existe', 16, 1);
            RETURN;
        END
        -- Insertar los detalles de la venta
        INSERT INTO esquema_operaciones.DetalleDeVenta (Código, Descripción, PrecioUnitario, Cantidad, Subtotal)
        VALUES (@Codigo, @Descripcion, @PrecioUnitario, @Cantidad, @Subtotal)
		

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- Captura del mensaje de error y lanzamiento del error con RAISERROR
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        RAISERROR('Error al insertar el detalle de venta. Detalles: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO

-- Procedimiento para insertar la Factura
CREATE OR ALTER PROCEDURE esquema_operaciones.insertarFactura( 
    @VentaID INT,  -- ID de la venta para asociarla con la factura
    @idFactura INT,  -- Número de factura
    @FechaEmision DATE,  -- Fecha de emisión de la factura
    @HoraEmision TIME,  -- Hora de emisión de la factura
    @IdEmpleado INT,  -- ID del empleado que realiza la factura
    @Total DECIMAL(38,2),  -- Total de la factura
    @TipoDeFactura VARCHAR(1),  -- Tipo de factura ('A', 'B', 'C')
    @CiudadDeSucursal VARCHAR(20),  -- Ciudad de la sucursal
    @MedioDePago VARCHAR(30),  -- Medio de pago
    @Estado VARCHAR(30),  -- Estado de la factura
    @IdMedioDePago INT  -- ID del medio de pago
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
		
        -- Verificación de existencia de idMedioDePago en la tabla MediosDePago
        IF NOT EXISTS (SELECT 1 FROM esquema_operaciones.MediosDePago WHERE id = @IdMedioDePago)
        BEGIN
            RAISERROR ('El ID del medio de pago no existe', 16, 1);
            RETURN;
        END

        -- Verificación de existencia de idVenta en la tabla Ventas
        IF NOT EXISTS (SELECT 1 FROM esquema_Ventas.ventasRegistradas WHERE id = @VentaID)
        BEGIN
            RAISERROR ('El ID de Ventas no existe', 16, 1);
            RETURN;
        END
        
        -- Verificación de existencia de idFactura en la tabla Factura
        IF EXISTS (SELECT 1 FROM esquema_operaciones.Factura WHERE NroFactura = @idFactura)
        BEGIN
            RAISERROR ('El número de factura %d ya existe. El número de factura debe ser único.', 16, 1, @idFactura);
            RETURN;
        END

        -- Insertar la factura
        INSERT INTO esquema_operaciones.Factura 
            (NroFactura, FechaEmision, HoraEmision, IdEmpleado, Total, TipoDeFactura, CiudadDeSucursal, MedioDePago, Estado)
        VALUES 
            (@idFactura, @FechaEmision, @HoraEmision, @IdEmpleado, @Total, @TipoDeFactura, @CiudadDeSucursal, @MedioDePago, @Estado);

        -- Obtener el ID de la factura insertada
        DECLARE @NuevoIdFactura INT = SCOPE_IDENTITY();

        -- Actualizar la venta con la factura asociada
        UPDATE esquema_Ventas.ventasRegistradas
        SET idDeFactura = @NuevoIdFactura
        WHERE id = @VentaID;

        COMMIT TRANSACTION;

        -- Retornar el ID de la factura insertada
        SELECT @NuevoIdFactura AS FacturaID;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- Captura del mensaje de error y lanzamiento del error con RAISERROR
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        RAISERROR('Error al insertar el detalle de venta. Detalles: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO


-- Procedimiento para eliminar un detalle de venta
CREATE OR ALTER PROCEDURE esquema_operaciones.eliminarDetalleDeVenta
    @VentaID INT  -- ID de la venta cuyos detalles se desean eliminar
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Eliminar los detalles de la venta en la tabla DetalleVenta
        DELETE FROM esquema_operaciones.DetalleDeVenta
        WHERE idVenta = @VentaID;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- Levantar un error detallado en caso de fallo
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR('Error al eliminar los detalles de la venta con ID %d: %s', 
                  @ErrorSeverity, 
                  @ErrorState, 
                  @VentaID, 
                  @ErrorMessage);
    END CATCH
END
GO
-- Procedimiento para eliminar una venta con su factura y su detalle de venta
CREATE OR ALTER PROCEDURE esquema_Ventas.eliminarVenta
    @VentaID INT  -- ID de la venta que se desea eliminar
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
    
        -- 1. Eliminar la factura asociada a la venta, si existe
        DECLARE @FacturaID INT;
        SELECT @FacturaID = idDeFactura FROM esquema_Ventas.ventasRegistradas WHERE id = @VentaID;
        
        IF @FacturaID IS NOT NULL
        BEGIN
            DELETE FROM esquema_operaciones.Factura 
            WHERE id = @FacturaID;
        END
		-- 2. Eliminar el detalle de venta asociada a la venta, si existe
		IF @VentaID IS NOT NULL
        BEGIN
		DELETE FROM esquema_operaciones.DetalleDeVenta
        WHERE idVenta = @VentaID;
		END
        -- 3. Eliminar la venta
		IF @VentaID IS NOT NULL
        BEGIN
        DELETE FROM esquema_Ventas.ventasRegistradas
        WHERE id = @VentaID;
		END

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        -- Captura del mensaje de error y lanzamiento del error con RAISERROR
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        RAISERROR('Error al insertar el detalle de venta. Detalles: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO
