-- PARCIAL 1------------------------------------------------------------------------------------------------------------------------------------------------
/*Implementar una regla de negocio en línea donde
nunca una factura nueva tenga un precio de producto distinto al que figura en la tabla PRODUCTO.
Registrar en una estructura adicional todos los casos donde se intenta guardar un precio distinto.
*/

/*
CREATE TABLE item_con_precio_distinto(
    ir_tipo char(1),
    ir_sucursal char(4),
    ir_numero char(8),
    ir_producto varchar(8), 
    ir_cantidad int,
    ir_precio decimal(12,2)
);


CREATE TRIGGER parcial_1 ON Item_Factura INSTEAD OF INSERT
AS
BEGIN
    
    IF(SELECT *
       FROM inserted i
       JOIN PRODUCTO p on p.prod_codigo = i.item_producto
       WHERE p.prod_precio != i.item_precio)
        BEGIN
            INSERT INTO item_con_precio_distinto FROM (SELECT * FROM inserted) 
        END
    ELSE
        BEGIN
            INSERT INTO Item_Factura FROM (SELECT * FROM inserted)
        END
END
GO*/

-----------------------------------------------------PARCIAL 4/7/23 TM-------------------------------------------------------------------------------------------------------------------------
/*
2. Actualmente el campo fact_vendedor representa al empleado que vendió
la factura. Implementar el/los objetos necesarios para respetar la
integridad referenciales de dicho campo suponiendo que no existe una
foreign key entre ambos.

NOTA: No se puede usar una foreign key para el ejercicio, deberá buscar otro método*/
/*
CREATE TRIGGER vendedor ON Factura AFTER INSERT
AS
BEGIN

    DECLARE @vendedor varchar(8)
    SELECT @vendedor = i.fact_vendedor from inserted i
    
    IF NOT EXISTS (SELECT * FROM Empleado e WHERE e.empl_codigo = @vendedor)
        BEGIN
        
            PRINT 'EL VENDEDOR NO ES EMPLEADO, PAPU, MEDIA PILA GORDI'
            ROLLBACK TRANSACTION 
        END
    
END

--PARA PROBAR
INSERT INTO Factura (fact_tipo,fact_sucursal,fact_numero,fact_fecha,fact_vendedor,fact_total,fact_total_impuestos,fact_cliente)
	VALUES ('A','003','0006489','2010-01-23 00:00:00',NULL,'105.73','18.33','01634') 

*/

-- me saltee 4/7/23 TT y 15/11/22 (RE LARGOS)


-----------------------------------------------------PARCIAL 8/7/23-------------------------------------------------------------------------------------------------------------------------
/*2.) Por un error de programación la tabla item factura le ejecutaron DROP a la primary key y a sus foreign key.
Este evento permitió la inserción de filas duplicadas (exactas e iguales) y también inconsistencias debido a la falta de FK.
Realizar un algoritmo que resuelva este inconveniente depurando los datos de manera coherente y lógica y que deje la estructura de 
la tabla item factura de manera correcta.*/

/*
DOMINIO: ITEM_FACTURA
OBJET: PROCEDURE ??
CONDICION:
*//*
CREATE TABLE AUX(
    item_tipo_aux char(1),
    item_sucursal_aux char(4),
    item_numero_aux char(8),
    item_producto_aux varchar(8), 
    item_cantidad_aux int,
    item_precio_aux decimal(12,2)
);

CREATE PROCEDURE depurar_item_factura
AS
BEGIN
    
        -- Inserción de los datos únicos en la tabla auxiliar
        INSERT INTO AUX (item_tipo_aux, item_sucursal_aux, item_numero_aux, item_producto_aux, item_cantidad_aux, item_precio_aux)
        SELECT DISTINCT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio
        FROM Item_Factura;

        -- Truncar la tabla original
        TRUNCATE TABLE Item_Factura;

        -- Restaurar los datos únicos desde la tabla auxiliar a la tabla original
        INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
        SELECT item_tipo_aux, item_sucursal_aux, item_numero_aux, item_producto_aux, item_cantidad_aux, item_precio_aux
        FROM AUX;

        -- Eliminar la tabla auxiliar
        DROP TABLE AUX;

        -- Restaurar las restricciones de clave primaria y foráneas
        ALTER TABLE Item_Factura
        ADD CONSTRAINT PK_ItemFactura PRIMARY KEY (item_tipo, item_sucursal, item_numero, item_producto);

        ALTER TABLE Item_Factura
        ADD CONSTRAINT FK_ItemFactura_Producto FOREIGN KEY (item_producto) REFERENCES Producto (prod_codigo);

        ALTER TABLE Item_Factura
        ADD CONSTRAINT FK_ItemFactura_Factura FOREIGN KEY (item_numero, item_tipo, item_sucursal) REFERENCES Factura (fact_numero, fact_tipo, fact_sucursal);

     
END;


---------------------------------- Parcial 29/6/23 ----------------------------------------------------------------------------------------------------------
/*Suponiendo que se aplican los siguientes cambios en el modelo de
datos:

Cambio 1) create table provincia (id 'int primary key, nómbre char(100)) ;
Cambio 2) alter table cliente add pcia_id int null:

Crear el/los objetos necesarios para implementar el concepto de foreign
key entre 2 cliente y provincia,

Nota: No se permite agregar una constraint de tipo FOREIGN KEY entre la
tabla y el campo agregado*/

/*
DOMINIO:
OBJETO:
CONDICION:
*/

create table provincia (id int primary key, nómbre char(100)) ;
alter table cliente add pcia_id int null;

CREATE TRIGGER ClienteProvinciaInsert ON Cliente FOR INSERT
AS
BEGIN

    IF EXISTS (SELECT * FROM inserted i JOIN Provincia p ON i.pcia_id = p.id)
        BEGIN
            UPDATE Cliente SET pcia_id = i.pcia_id FROM Inserted i WHERE Cliente.clie_codigo = i.clie_codigo
        END
    ELSE 
        BEGIN  
            PRINT ('ERROR')
        END

END
GO

CREATE TRIGGER ClienteProvinciaUpdate ON Cliente INSTEAD OF UPDATE

AS

BEGIN
	SET NOCOUNT ON;

	
		BEGIN
			IF EXISTS ( SELECT * FROM Provincia A INNER JOIN Inserted B ON A.id = B.pcia_id ) 
				BEGIN
					UPDATE
						Cliente 
					SET
						pcia_id = i.pcia_id
					FROM
						Inserted i 
					WHERE
						Cliente.clie_codigo = i.clie_codigo
				END;
			ELSE
				BEGIN
					PRINT ('No existe la provincia')
					ROLLBACK TRANSACTION
				END;
		END

END*/

--PARCIAL 2023/07/01
/*2.) Implementar una regla de negocio para mantener siempre consistente
(actualizada bajo cualquier circunstancia) INSERT UPDATE DELETE una nueva tabla llamada PRODUCTOS_VENDIDOS. 
    En esta tabla debe registrar el periodo (YYYYMM),
    el código de producto,
    el precio máximo de venta 
    y las unidades vendidas. 
  
  Toda esta información debe estar por periodo (YYYYMM).*/
/*
DOMINIO: 
OBJETO: trigger??
CONDICION: la tabla llamada PRODUCTOS_VENDIDOS este actualizada bajo cualquier circunstancia
*/
/*
  CREATE TABLE PRODUCTOS_VENDIDOS(
    periodo smalldatetime,
    cod_prod varchar(8),
    precio_max decimal(12,2),
    unidades_vendidas int
  );*/

/*
CREATE PROCEDURE completar_tabla 
AS
BEGIN

    INSERT INTO PRODUCTOS_VENDIDOS (periodo, cod_prod, precio_max, unidades_vendidas)
    SELECT CONCAT(YEAR(fact_fecha)+MONTH(fact_fecha)), item_producto, max(item_precio), sum(item_cantidad)
    FROM Factura
    JOIN  Item_Factura on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
    GROUP BY item_producto, CONCAT(YEAR(fact_fecha)+MONTH(fact_fecha)) 

END

CREATE TRIGGER actualizar_productos_vendidos ON Item_Factura AFTER INSERT, UPDATE, DELETE
AS
BEGIN

    DECLARE @periodo SMALLDATETIME, @Producto varchar(8), @MaxPrecio decimal(12,2), @Vendido int
    DECLARE cursor_tv CURSOR FOR (SELECT CONCAT(YEAR(fact_fecha)+MONTH(fact_fecha)), item_producto, max(item_precio), sum(item_cantidad)
                                  FROM inserted JOIN Factura ON item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
                                  GROUP BY item_producto, CONCAT(YEAR(fact_fecha)+MONTH(fact_fecha)))
    

    OPEN cursor_tv
    FETCH NEXT FROM cursor_tv INTO @periodo, @Producto, @MaxPrecio, @Vendido

    WHILE @@FETCH_STATUS = 0
    BEGIN 
        IF NOT EXISTS (SELECT 1 FROM PRODUCTOS_VENDIDOS WHERE periodo = @periodo AND cod_prod = @Producto)
            BEGIN
                INSERT INTO PRODUCTOS_VENDIDOS VALUES (@Periodo, @Producto, @MaxPrecio, @Vendido)
            END
        IF EXISTS (SELECT 1 FROM PRODUCTOS_VENDIDOS WHERE periodo = @periodo AND cod_prod = @Producto)  
            BEGIN 
                UPDATE PRODUCTOS_VENDIDOS SET unidades_vendidas = unidades_vendidas + @Vendido,
                                              precio_max = CASE WHEN (@MaxPrecio > precio_max) then @MaxPrecio ELSE precio_max WHERE periodo = @periodo AND cod_prod = @Producto
            END
        IF NOT EXISTS (SELECT 1 FROM inserted WHERE CONCAT(YEAR(fact_fecha)+MONTH(fact_fecha)) = @Periodo AND item_producto = @Producto 
                        AND max(item_precio) = @MaxPrecio AND sum(item_cantidad) = @Vendido)
            BEGIN 
                DELETE FROM PRODUCTOS_VENDIDOS WHERE periodo = @periodo AND cod_prod = @Producto AND precio_max = @MaxPrecio AND unidades_vendidas = @Vendido
            END
    END

CLOSE cursor_tv
DEALLOCATE cursor_tv
END
GO

-- 19/11/22
/*
1. Implementar una regla de negocio en línea donde nunca una factura
nueva tenga un precio de producto distinto al que figura en la tabla
PRODUCTO. Registrar en una estructura adicional todos los casos
donde se intenta guardar un precio distinto.
*/
/* TSQL */

CREATE TABLE item_Factura_Precio_Distinto(
    PM_tipo varchar(1),
    PM_sucursal varchar(8),
    PM_numero varchar(8),
    PM_producto varchar(8),
    PM_cantidad decimal(12,2),
    PM_precio decimal(12,2),
    CONSTRAINT FK_PM_PRODUCTO FOREIGN KEY (PM_producto) REFERENCES Producto(prod_codigo),
    CONSTRAINT FK_PM_FACTURA FOREIGN KEY(PM_tipo, PM_sucursal, PM_numero) REFERENCES Factura(fact_tipo, fact_sucursal, fact_numero)
);
GO

CREATE TRIGGER precio_correcto ON Item_Factura INSTEAD OF INSERT 
AS

DECLARE @tipo varchar(1), 
        @sucursal varchar(8),
        @numero_fact varchar(8),
        @producto varchar(8),
        @cantidad decimal(12,2),
        @precio decimal(12,2),
        @precio_real decimal(12,2)

DECLARE cursor_pm CURSOR FOR (SELECT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio FROM inserted i)

OPEN cursor_pm 
FETCH cursor_pm INTO @tipo, @sucursal, @numero_fact, @producto, @cantidad, @precio

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SET @precio_real = (SELECT prod_precio FROM Producto WHERE prod_codigo = i.item_producto)

    IF(@precio != @precio_real)
        BEGIN  
            INSERT INTO item_Factura_Precio_Distinto (PM_tipo, PM_sucursal, PM_numero, PM_producto, PM_cantidad, PM_precio)
            VALUES (@tipo, @sucursal, @numero_fact, @producto, @cantidad, @precio)

            INSERT Item_Factura(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
            VALUES (@tipo, @sucursal, @numero_fact, @producto, @cantidad, @precio_real)
        
        END
    ELSE 
        BEGIN 
            INSERT Item_Factura(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
            VALUES (@tipo, @sucursal, @numero_fact, @producto, @cantidad, @precio)
        END

    UPDATE Factura SET fact_total =
        (SELECT SUM(it.item_precio * it.item_cantidad)
         FROM item_factura it 
         WHERE it.item_tipo = @tipo AND it.item_sucursal = @sucursal AND it.item_numero = @numero_fact
         GROUP BY it.item_tipo, it.item_sucursal, it.item_numero)

        WHERE fact_tipo = @tipo AND fact_sucursal = @sucursal AND fact_numero = @numero_fact
    
    FETCH cursor_pm INTO @tipo, @sucursal, @numero_fact, @producto, @cantidad, @precio

END

CLOSE cursor_pm
DEALLOCATE cursor_pm

GO

--PARCIAL 8/11/22
/*
2. Implementar una regla de negocio de validación en línea que permita
implementar una lógica de control de precios en las ventas. Se deberá
poder seleccionar una lista de rubros y aquellos productos de los rubros
que sean los seleccionados no podrán aumentar por mes más de un 2
%. En caso que no se tenga referencia del mes anterior no validar
dicha regla.*/

CREATE TRIGGER ON Item_Factura 
INSTEAD OF UPDATE 
AS

DECLARE @Producto char(8), @Rubro char(4), @PrecioAnterior decimal(12,2), @FechaFactura SMALLDATETIME, @NuevoPrecio decimal(12,2);

DECLARE cursor_rp CURSOR FOR (SELECT i.item_producto, p.prod_rubro, f.fact_fecha, p.prod_precio 
                                FROM inserted i 
                                JOIN Producto P on i.item_producto = p.prod_codigo
                                JOIN Factura f ON f.fact_tipo + f.fact_numero + f.fact_sucursal = i.item_tipo + i.item_numero + i.item_sucursal)

OPEN cursor_rp 

FETCH NEXT FROM cursor_rp INTO @Producto, @Rubro, @FechaFactura, @NuevoPrecio

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @PrecioAnterior = (SELECT p.prod_precio FROM inserted i 
                            JOIN Producto P on i.item_producto = p.prod_codigo
                            JOIN Factura f ON f.fact_tipo + f.fact_numero + f.fact_sucursal = i.item_tipo + i.item_numero + i.item_sucursal
                           WHERE i.item_producto = @Producto 
                           AND CONCAT(YEAR(f.fact_fecha)+ MONTH(f.fact_fecha)) = CONCAT(YEAR(@FechaFactura)+(MONTH(@FechaFactura)-1))
                          )
    
    IF (@PrecioAnterior IS NOT NULL)
        BEGIN 
            IF (@PrecioAnterior * 1.02) < @NuevoPrecio
                BEGIN
                    RAISERROR('NO AUMENTAR MAS DEL 2% DEL PRECIO ANTERIOR',16,10, @Producto)
                    ROLLBACK TRANSACTION
                END
            ELSE 
                BEGIN
                UPDATE Producto SET prod_precio = @NuevoPrecio
                WHERE prod_codigo = @Producto AND prod_rubro = @Rubro AND 
                (SELECT f2.fact_fecha FROM factura f2 
                JOIN Item_Factura it ON f2.fact_tipo + f2.fact_numero + f2.fact_sucursal = it.item_tipo + it.item_numero + it.item_sucursal
                WHERE it.item_producto = prod_codigo) = @FechaFactura
                END
            END
    ELSE
        BEGIN
        UPDATE Producto SET prod_precio = @NuevoPrecio
                WHERE prod_codigo = @Producto AND prod_rubro = @Rubro AND 
                (SELECT f3.fact_fecha FROM factura f3 
                JOIN Item_Factura it2 ON f3.fact_tipo + f3.fact_numero + f3.fact_sucursal = it2.item_tipo + it2.item_numero + it2.item_sucursal
                WHERE it2.item_producto = prod_codigo) = @FechaFactura
        END



    FETCH NEXT FROM cursor_rp INTO @Producto, @Rubro, @FechaFactura, @NuevoPrecio

END 

CLOSE cursor_rp
DEALLOCATE cursor_rp*/

-- PARCIAL 2021 XX XX

/*Realizar un stored procedure que reciba un código de producto y una fecha y devuelva la mayor cantidad de
días consecutivos a partir de esa fecha que el producto tuvo al menos la venta de una unidad en el día, el
sistema de ventas on line está habilitado 24-7 por lo que se deben evaluar todos los días incluyendo domingos y feriados.*/

/*

CREATE PROCEDURE Maxima_Cantidad_de_Dias_Consecutivos (@CodigoProducto char(8), @Fecha SMALLDATETIME, @max_dias_consecutivos int output)
as
BEGIN
    DECLARE @dias_consecutivos INT, @fecha_cursor smalldatetime 

    SET @fecha_cursor = NULL
    SET @dias_consecutivos = 0
    SET @max_dias_consecutivos = 0
    
    DECLARE cursorDiasConsecutivos CURSOR FOR SELECT fact_fecha
    FROM Factura f
    JOIN item_producto it ON f.fact_tipo + f.fact_numero + f.fact_sucursal = it.item_tipo + it.item_numero + it.item_sucursal
    WHERE item_producto = @CodigoProducto AND @Fecha < fact_fecha
    GROUP BY f.fact_fecha
    ORDER BY f.fact_fecha ASC


    OPEN cursorDiasConsecutivos
        FETCH NEXT FROM cursorDiasConsecutivos INTO @fecha_cursor
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @fecha_cursor = NULL OR @Fecha = DATEADD(day,1,@fecha_cursor)
                BEGIN
                    SET @dias_consecutivos = @dias_consecutivos + 1
                END
            ELSE
                BEGIN
                    IF @max_dias_consecutivos < @dias_consecutivos
                        BEGIN
                            SET @max_dias_consecutivos = @dias_consecutivos
                            SET @dias_consecutivos = 0
                        END
                END

        FETCH NEXT FROM cursorDiasConsecutivos INTO @fecha_cursor

        END
        
        SET @fecha_cursor = @Fecha 


        CLOSE cursorDiasConsecutivos
        DEALLOCATE cursorDiasConsecutivos

RETURN @max_dias_consecutivos
END


*/
/*
TSQL
	•	El atributo clie_limite_credito, representa el monto máximo que puede venderse a un 
	cliente en el mes en curso. Implementar el/los objetos necesarios para que no se permita realizar 
	una venta si el monto total facturado en el mes supera el atributo clie_limite_credito. 
	Considerar que esta restricción debe cumplirse siempre y validar también que no se pueda hacer 
	una factura de un mes anterior.
*/



CREATE TRIGGER limite_credito ON Factura
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @cliente_limite decimal(12,2)
    DECLARE @cliente char(6)
    DECLARE @monto_total decimal(12,2)
    DECLARE @FechaFactura SMALLDATETIME

    SET @cliente_limite = (SELECT clie_limite_credito FROM Cliente 
                          JOIN inserted i ON  i.fact_cliente = clie_codigo)

    DECLARE cursor_lc CURSOR FOR (SELECT fact_cliente, fact_total, fact_fecha  FROM inserted)
    
    OPEN cursor_lc

    FETCH cursor_lc INTO @cliente, @monto_total, @FechaFactura
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF (@monto_total <= @cliente_limite AND CONCAT(YEAR(@FechaFactura),MONTH(@FechaFactura)) = CONCAT(YEAR(CURRENT_TIMESTAMP),MONTH(CURRENT_TIMESTAMP)))
            BEGIN
                INSERT INTO Factura (fact_tipo, fact_sucursal, fact_numero, fact_fecha, fact_vendedor, fact_total, fact_total_impuestos, fact_cliente)
                SELECT fact_tipo, fact_sucursal, fact_numero, fact_fecha, fact_vendedor, @monto_total, fact_total_impuestos, fact_cliente
                FROM inserted
            END
        ELSE
            BEGIN
            PRINT('PUTO NO!!')
            ROLLBACK TRANSACTION
            END
    END
    
    CLOSE cursor_lc 
    DEALLOCATE cursor_lc

END


