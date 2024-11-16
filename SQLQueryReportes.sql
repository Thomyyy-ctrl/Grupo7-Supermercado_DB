USE SUPERMERCADO_Grupo7
GO



---------------------------REPORTE MENSUAL---------------------------------------
CREATE OR ALTER PROCEDURE esquema_Ventas.GenerarReporteMensualXML
    @Mes INT,         -- Mes que quieres reportar
    @Año INT          -- Año que quieres reportar
AS
BEGIN
    BEGIN TRY
        -- Verifica que el mes esté en el rango de 1 a 12
        IF (@Mes < 1 OR @Mes > 12)
        BEGIN
            -- Si el mes no es válido, genera un error y termina la ejecución
            RAISERROR('El mes debe estar entre 1 y 12.', 16, 1);
            RETURN;
        END

        -- Verifica que el año esté en un rango válido, desde 1900 hasta el año actual
        IF (@Año < 1900 OR @Año > YEAR(GETDATE()))
        BEGIN
            -- Si el año no es válido, genera un error y termina la ejecución
            RAISERROR('El año debe estar entre 1900 y el año actual.', 16, 1);
            RETURN;
        END

        -- Declaramos la variable XML para almacenar el reporte
        DECLARE @ReporteMensual XML;

        -- Consulta para generar el reporte mensual en formato XML
        SET @ReporteMensual = (SELECT 
                                    DATENAME(WEEKDAY, fecha) AS DiaSemana,
                                    SUM(precioUnitario * cantidad) AS TotalFacturado,
                                    CASE DATENAME(WEEKDAY, fecha)
                                        WHEN 'Lunes' THEN 1
                                        WHEN 'Martes' THEN 2
                                        WHEN 'Miércoles' THEN 3
                                        WHEN 'Jueves' THEN 4
                                        WHEN 'Viernes' THEN 5
                                        WHEN 'Sábado' THEN 6
                                        WHEN 'Domingo' THEN 7
                                    END AS OrdenDia
                               FROM esquema_Ventas.ventasRegistradas
                               WHERE MONTH(fecha) = @Mes AND YEAR(fecha) = @Año
                               GROUP BY DATENAME(WEEKDAY, fecha),
                                        CASE DATENAME(WEEKDAY, fecha)
                                            WHEN 'Lunes' THEN 1
                                            WHEN 'Martes' THEN 2
                                            WHEN 'Miércoles' THEN 3
                                            WHEN 'Jueves' THEN 4
                                            WHEN 'Viernes' THEN 5
                                            WHEN 'Sábado' THEN 6
                                            WHEN 'Domingo' THEN 7
                                        END
                               ORDER BY OrdenDia
                               FOR XML PATH('Dia'), ROOT('ReporteMensual'));

        -- Devolvemos la variable XML con el reporte mensual
        SELECT @ReporteMensual AS ReporteMensual;

    END TRY
    BEGIN CATCH
        -- Manejo de errores en caso de que ocurra un problema en la consulta o en las validaciones anteriores
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();     -- Obtiene el mensaje de error
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();          -- Obtiene la severidad del error
        DECLARE @ErrorState INT = ERROR_STATE();                -- Obtiene el estado del error

        -- Muestra el mensaje de error capturado utilizando RAISERROR para notificar el problema al usuario
        RAISERROR(@ErrorMsg, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO


----------------------REPORTE TRIMESTRAL------------------------------------
CREATE OR ALTER PROCEDURE esquema_Ventas.GenerarReporteTrimestralXML
    @Trimestre INT,   -- Trimestre para el reporte (1 = Enero-Marzo, 2 = Abril-Junio, etc.)
    @Año INT           -- Año que quieres reportar
AS
BEGIN
    BEGIN TRY
        -- Verifica que el trimestre esté en el rango de 1 a 4
        IF (@Trimestre < 1 OR @Trimestre > 4)
        BEGIN
            RAISERROR('El trimestre debe estar entre 1 y 4.', 16, 1);
            RETURN;
        END

        -- Definir el rango de fechas para el trimestre
        DECLARE @FechaInicio DATE;
        DECLARE @FechaFin DATE;

        -- Establece las fechas de inicio y fin según el trimestre
        IF (@Trimestre = 1)
        BEGIN
            SET @FechaInicio = DATEFROMPARTS(@Año, 1, 1);
            SET @FechaFin = DATEFROMPARTS(@Año, 3, 31);
        END
        ELSE IF (@Trimestre = 2)
        BEGIN
            SET @FechaInicio = DATEFROMPARTS(@Año, 4, 1);
            SET @FechaFin = DATEFROMPARTS(@Año, 6, 30);
        END
        ELSE IF (@Trimestre = 3)
        BEGIN
            SET @FechaInicio = DATEFROMPARTS(@Año, 7, 1);
            SET @FechaFin = DATEFROMPARTS(@Año, 9, 30);
        END
        ELSE IF (@Trimestre = 4)
        BEGIN
            SET @FechaInicio = DATEFROMPARTS(@Año, 10, 1);
            SET @FechaFin = DATEFROMPARTS(@Año, 12, 31);
        END

        -- Declarar una variable XML para guardar el resultado
        DECLARE @XMLResult XML;

        -- Consulta para el reporte trimestral
        SET @XMLResult = 
        (
            SELECT 
                Mes,
                Turno,
                SUM(precioUnitario * cantidad) AS TotalFacturado
            FROM 
            (
                SELECT 
                    DATENAME(MONTH, fecha) AS Mes,  -- Mes de la venta
                    CASE 
                        WHEN DATEPART(HOUR, hora) BETWEEN 6 AND 13 THEN 'Mañana'
                        WHEN DATEPART(HOUR, hora) BETWEEN 14 AND 21 THEN 'Tarde'
                        ELSE 'Noche'
                    END AS Turno,  -- Determina el turno basado en la hora
                    precioUnitario,
                    cantidad,
                    MONTH(fecha) AS MesNumerico  -- Extrae el mes numérico para el orden
                FROM 
                    esquema_Ventas.ventasRegistradas
                WHERE 
                    fecha BETWEEN @FechaInicio AND @FechaFin  -- Filtra por el trimestre especificado
            ) AS SubConsulta
            GROUP BY 
                Mes, Turno  -- Agrupa por mes y turno
            ORDER BY 
                CASE Mes
                    WHEN 'Enero' THEN 1
                    WHEN 'Febrero' THEN 2
                    WHEN 'Marzo' THEN 3
                    WHEN 'Abril' THEN 4
                    WHEN 'Mayo' THEN 5
                    WHEN 'Junio' THEN 6
                    WHEN 'Julio' THEN 7
                    WHEN 'Agosto' THEN 8
                    WHEN 'Septiembre' THEN 9
                    WHEN 'Octubre' THEN 10
                    WHEN 'Noviembre' THEN 11
                    WHEN 'Diciembre' THEN 12
                END,  -- Ordena por el número del mes
                CASE 
                    WHEN Turno = 'Mañana' THEN 1
                    WHEN Turno = 'Tarde' THEN 2
                    ELSE 3
                END  -- Ordena por el turno (1=mañana, 2=tarde, 3=noche)
            FOR XML PATH('Dia'), ROOT('ReporteTrimestral')  -- Genera el reporte XML
        );

        -- Devolver el resultado XML
        SELECT @XMLResult AS ReporteTrimestralXML;

    END TRY
    BEGIN CATCH
        -- Manejo de errores
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();  -- Obtiene el mensaje de error
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();       -- Obtiene la severidad del error
        DECLARE @ErrorState INT = ERROR_STATE();             -- Obtiene el estado del error
        RAISERROR(@ErrorMsg, @ErrorSeverity, @ErrorState);    -- Muestra el error
    END CATCH;
END;
GO



----------------------REPORTE POR RANGO DE FECHAS---------------------------
CREATE OR ALTER PROCEDURE esquema_Ventas.GenerarReportePorRangoFechasXML
    @FechaInicio DATE,   -- Fecha de inicio del rango
    @FechaFin DATE       -- Fecha de fin del rango
AS
BEGIN
    BEGIN TRY
        -- Verifica que la fecha de inicio no sea posterior a la fecha de fin
        IF (@FechaInicio > @FechaFin)
        BEGIN
            RAISERROR('La fecha de inicio no puede ser posterior a la fecha de fin.', 16, 1);
            RETURN;
        END

        -- Declaración de la variable XML para almacenar el resultado
        DECLARE @ReporteXML XML;

        -- Consulta para generar el reporte XML con la cantidad de productos vendidos en el rango de fechas
        SELECT 
            producto AS NombreProducto,                    -- Nombre del producto
            SUM(cantidad) AS CantidadVendida              -- Total de cantidad vendida para el producto
        FROM 
            esquema_Ventas.ventasRegistradas
        WHERE 
            fecha BETWEEN @FechaInicio AND @FechaFin      -- Filtra las ventas en el rango de fechas especificado
        GROUP BY 
            producto                                      -- Agrupa por producto para calcular la cantidad total
        ORDER BY 
            SUM(cantidad) DESC,                           -- Ordena de mayor a menor cantidad vendida
            producto ASC                                  -- En caso de empate, ordena alfabéticamente por nombre del producto
        FOR XML PATH('Producto'), ROOT('ReportePorRangoFechas'); -- Genera el XML

        -- Asignar el resultado del XML directamente a la variable
        SET @ReporteXML = (
            SELECT 
                producto AS NombreProducto,                    -- Nombre del producto
                SUM(cantidad) AS CantidadVendida              -- Total de cantidad vendida para el producto
            FROM 
                esquema_Ventas.ventasRegistradas
            WHERE 
                fecha BETWEEN @FechaInicio AND @FechaFin      -- Filtra las ventas en el rango de fechas especificado
            GROUP BY 
                producto                                      -- Agrupa por producto para calcular la cantidad total
            ORDER BY 
                SUM(cantidad) DESC,                           -- Ordena de mayor a menor cantidad vendida
                producto ASC                                  -- En caso de empate, ordena alfabéticamente por nombre del producto
            FOR XML PATH('Producto'), ROOT('ReportePorRangoFechas') -- Genera el XML
        );

        -- Devuelve el resultado XML directamente
        SELECT @ReporteXML AS ReportePorRangoDeFechasXML;

    END TRY
    BEGIN CATCH
        -- Manejo de errores
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();  -- Obtiene el mensaje de error
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();       -- Obtiene la severidad del error
        DECLARE @ErrorState INT = ERROR_STATE();             -- Obtiene el estado del error
        RAISERROR(@ErrorMsg, @ErrorSeverity, @ErrorState);    -- Muestra el error
    END CATCH;
END;
GO


----------------------REPORTE POR RANGO DE FECHAS EXTENDIDO---------------------------
CREATE OR ALTER PROCEDURE esquema_Ventas.GenerarReporteVentasExtendidoXML
    @FechaInicio DATE,
    @FechaFin DATE,
    @MesAño DATE,         -- Fecha para el reporte de más y menos vendidos (en formato 'YYYY-MM-DD')
    @FechaEspecifica DATE,  -- Fecha específica para reporte detallado
    @SucursalCiudad VARCHAR(15)   -- Ciudad específica para reporte detallado
AS
BEGIN
    BEGIN TRY
        -- Verificar que las fechas de inicio y fin sean correctas
        IF (@FechaInicio > @FechaFin)
        BEGIN
            RAISERROR('La fecha de inicio no puede ser mayor que la fecha de fin.', 16, 1);
            RETURN;
        END
        
        -- Extraemos el mes y el año del parámetro @MesAño
        DECLARE @Mes INT = MONTH(@MesAño);
        DECLARE @Año INT = YEAR(@MesAño);

        -- 1. Productos vendidos por sucursal en un rango de fechas, ordenado de mayor a menor
        DECLARE @ReporteSucursal XML;
        SET @ReporteSucursal = (
            SELECT 
                ciudad AS Sucursal,
                producto AS Producto,
                SUM(cantidad) AS CantidadVendida
            FROM 
                esquema_Ventas.ventasRegistradas
            WHERE 
                fecha BETWEEN @FechaInicio AND @FechaFin
            GROUP BY 
                ciudad, producto
            ORDER BY 
                CantidadVendida DESC
            FOR XML PATH('Producto'), ROOT('ReporteSucursal')
        );
        
        -- 2. Top 5 productos más vendidos en un mes, agrupados por semana
        DECLARE @Top5MasVendidosPorSemanaEnUnMes XML;
        SET @Top5MasVendidosPorSemanaEnUnMes = (
            SELECT 
                DATEPART(WEEK, fecha) AS Semana,
                producto AS Producto,
                SUM(cantidad) AS CantidadVendida
            FROM 
                esquema_Ventas.ventasRegistradas
            WHERE 
                MONTH(fecha) = @Mes AND YEAR(fecha) = @Año
            GROUP BY 
                DATEPART(WEEK, fecha), producto
            ORDER BY 
                Semana, CantidadVendida DESC
            OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
            FOR XML PATH('Producto'), ROOT('Top5MasVendidosPorSemanaEnUnMes')
        );

        -- 3. Top 5 productos menos vendidos en el mes
        DECLARE @Top5MenosVendidosEnElMes XML;
        SET @Top5MenosVendidosEnElMes = (
            SELECT 
                producto AS Producto,
                SUM(cantidad) AS CantidadVendida
            FROM 
                esquema_Ventas.ventasRegistradas
            WHERE 
                MONTH(fecha) = @Mes AND YEAR(fecha) = @Año
            GROUP BY 
                producto
            ORDER BY 
                CantidadVendida ASC
            OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
            FOR XML PATH('Producto'), ROOT('Top5MenosVendidosEnElMes')
        );

        -- 4. Total acumulado y detalle para una fecha y sucursal específicas
        DECLARE @DetalleVentasEspecifica XML;
        SET @DetalleVentasEspecifica = (
            SELECT 
                ciudad AS Sucursal,
                fecha AS Fecha,
                producto AS Producto,
                cantidad AS Cantidad,
                (precioUnitario * cantidad) AS Total
            FROM 
                esquema_Ventas.ventasRegistradas
            WHERE 
                (@FechaEspecifica IS NULL OR fecha = @FechaEspecifica) 
                AND (@SucursalCiudad IS NULL OR ciudad = @SucursalCiudad)
            FOR XML PATH('Venta'), ROOT('DetalleVentasEspecifica')
        );

        -- Devolvemos el XML generado en el reporte
        SELECT @ReporteSucursal AS ReporteSucursal,
               @Top5MasVendidosPorSemanaEnUnMes AS Top5MasVendidosPorSemanaEnUnMes,
               @Top5MenosVendidosEnElMes AS Top5MenosVendidosEnElMes,
               @DetalleVentasEspecifica AS DetalleVentasEspecifica;

    END TRY
    BEGIN CATCH
        -- Captura de errores
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMsg, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO


