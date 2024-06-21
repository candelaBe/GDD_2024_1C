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
*/
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


-- salteamos 1/7/23

---------------------------------- Parcial 29/6/23 ----------------------------------------------------------------------------------------------------------
/*Suponiendo que se aplican los siguientes cambios en el modelo de
datos:

Cambio 1) create table provincia (id 'int primary key, nómbre char(100)) ;
Cambio 2) alter table cliente add pcia_id int null:

Crear el/los objetos necesarios para implementar el concepto de foreign
key entre 2 cliente y provincia,

Nota: No se permite agregar una constraint de tipo FOREIGN KEY entre la
tabla y el campo agregado*/



create table provincia (id int primary key, nómbre char(100)) ;
alter table cliente add pcia_id int null

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

END

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

  CREATE TABLE PRODUCTOS_VENDIDOS(
    periodo smalldatetime,
    cod_prod varchar(8)
    precio_max decimal(12,2),
    unidades_vendidas int
  );


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

-- PARCIAL 19/11/22

CREATE TABLE item_Factura_Precio_Distinto(
    PM_tipo char(1),
    PM_sucursal char(4),
    PM_numero char(8),
    PM_producto char(8),
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

DECLARE cursor_pm CURSOR FOR (SELECT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio FROM inserted )

OPEN cursor_pm 
FETCH cursor_pm INTO @tipo, @sucursal, @numero_fact, @producto, @cantidad, @precio

WHILE @@FETCH_STATUS = 0
BEGIN
    
    SET @precio_real = (SELECT prod_precio FROM Producto P JOIN inserted i ON p.prod_codigo = i.item_producto)

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
dicha regla.
*/

CREATE TRIGGER tgr_control_precios ON Item_Factura 
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
                           AND CONCAT(YEAR(f.fact_fecha) , MONTH(f.fact_fecha)) = CONCAT(YEAR(@FechaFactura),(MONTH(@FechaFactura)-1))
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
DEALLOCATE cursor_rp
GO


CREATE FUNCTION total_vendido_mes(@fact_cliente char(6))
RETURNS DECIMAL(12,2)
AS
	BEGIN
		
		RETURN(select sum(f.fact_total) FROM Factura f 
			WHERE f.fact_cliente = @fact_cliente
			AND MONTH(CURRENT_TIMESTAMP) = MONTH(f.fact_fecha)
			AND YEAR(CURRENT_TIMESTAMP) = YEAR(f.fact_fecha)

	END
GO


CREATE TRIGGER tr_chequear_limite_credito ON Factura
instead of INSERT 
AS
	BEGIN
		
		IF(EXISTS(SELECT * FROM inserted i WHERE MONTH(i.fact_fecha) != month(CURRENT_TIMESTAMP)))
			BEGIN 
				RAISERROR (15599,10,1, 'No se puede facturar un mes distinto del actual');
			END			
		
		ELSE
			BEGIN
				
				IF(EXISTS(SELECT * FROM inserted i 
					JOIN Cliente c 
					ON c.clie_codigo = i.fact_cliente
					WHERE c.clie_limite_credito < (i.fact_total + total_vendido_mes(i.fact_cliente))
				
					))
					
					BEGIN
						RAISERROR(15600,10,1, 'la venta supera el limite de credito del cliente');
					END
					
				ELSE 
					BEGIN
						INSERT INTO Factura (fact_tipo,fact_sucursal,fact_numero,fact_fecha,fact_vendedor,fact_total,fact_total_impuestos,fact_cliente)
						SELECT fact_tipo,fact_sucursal,fact_numero,fact_fecha,fact_vendedor,fact_total,fact_total_impuestos,fact_cliente
						FROM inserted
					END
			END	
			
	END
	

 --para un cliente dado retorna el total vendido en el mes y año actual para el cliente
CREATE FUNCTION total_vendido_mes(@fact_cliente char(6))
RETURNS DECIMAL(12,2)
AS
	BEGIN

		RETURN (select sum(f.fact_total) from Factura f 
				where f.fact_cliente = @fact_cliente 
				and MONTH(CURRENT_TIMESTAMP) = MONTH(f.fact_fecha) 
				and YEAR(CURRENT_TIMESTAMP) = YEAR(f.fact_fecha))
	END
GO

--se considera que el fact_total una vez insertado no se vuelve a modificar
CREATE TRIGGER tr_check_limite_credito on Factura
instead of INSERT
AS
	BEGIN
		IF(exists(select * from inserted i where month(i.fact_fecha) != month(CURRENT_TIMESTAMP)))
			BEGIN
				RAISERROR (15599,10,1, 'No se puede facturar un mes distinto del actual'); 
			END
		ELSE
			BEGIN
				IF(exists(select * from inserted i join Cliente c 
							on c.clie_codigo = i.fact_cliente			--total_vendido_mes esta definido arriba
							where c.clie_limite_credito < (i.fact_total + total_vendido_mes(i.fact_cliente)) ) )
					BEGIN
						RAISERROR (15600,10,1, 'La venta no puede superar el limite de credito para el cliente'); 
					END
				ELSE
					BEGIN
						INSERT INTO Factura (fact_tipo,fact_sucursal,fact_numero,fact_fecha,fact_vendedor,fact_total,fact_total_impuestos,fact_cliente)
						SELECT fact_tipo,fact_sucursal,fact_numero,fact_fecha,fact_vendedor,fact_total,fact_total_impuestos,fact_cliente from inserted 
					END
			END
	END
GO





/*
Implementar el/los objetos necesarios para controlar que nunca se pueda facturar un producto si no hay stock 
suficiente del producto en el deposito ‘00’.

Nota: En caso de que se facture un producto compuesto, por ejemplo, combo1, deberá controlar que exista stock en el deposito ‘00’ 
de cada uno de sus componentes
*/

CREATE FUNCTION hayStockSuficiente (@Producto char(8), @Cantidad decimal(12,2))
RETURNS BIT
AS 
BEGIN

DECLARE @Bit BIT

IF NOT EXISTS (SELECT * FROM Composicion WHERE comp_producto = @Producto)
    BEGIN
        IF (SELECT stoc_cantidad FROM STOCK WHERE stoc_producto = @Producto AND stoc_deposito = '00') > @Cantidad
            BEGIN
            SET @Bit = 1
            END
        ELSE 
            BEGIN
            SET @Bit = 0
            END
    END
ELSE
    IF EXISTS (SELECT * FROM STOCK 
               JOIN Composicion C ON stoc_producto = comp_componente
               WHERE comp_producto = @Producto AND stoc_deposito = '00' AND comp_cantidad*@Cantidad > stoc_cantidad)
        BEGIN
            SET @Bit = 1
        END
    ELSE SET @Bit = 0

RETURN @Bit
END

CREATE TRIGGER noVenderSiNoHayStock ON Item_Factura
INSTEAD OF INSERT
AS
BEGIN

    DECLARE @Producto char(8), @Cantidad decimal(12,2)

    DECLARE cursor_ns CURSOR FOR (SELECT item_producto, item_cantidad FROM inserted)

    OPEN cursor_ns 
    FETCH cursor_ns INTO @Producto, @Cantidad

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF (hayStockSuficiente(@Producto,@Cantidad)) = 1
            BEGIN
             INSERT INTO Item_Factura SELECT * FROM inserted i WHERE i.item_producto = @Producto AND i.item_cantidad = @Cantidad 
            END
    ELSE 
        BEGIN
        PRINT('No hay Stock suficiente')
        ROLLBACK TRANSACTION
        END
    FETCH NEXT FROM cursor_ns INTO @Producto, @Cantidad
    END
END


/*
Implementar el/los objetos necesarios para implementar la siguiente restricción en línea:
Cuando se inserta en una venta un COMBO, nunca se deberá guardar el producto COMBO, sino, la descomposición de sus componentes.
Nota: Se sabe que actualmente todos los artículos guardados de ventas están descompuestos en sus componentes.
*/

CREATE TRIGGER tgr_sin_combos ON Item_Factura INSTEAD OF INSERT 
AS
BEGIN

    DECLARE @Producto CHAR(8)

    DECLARE cursor_sc CURSOR FOR (SELECT item_producto FROM inserted )

    OPEN cursor_sc 
    FETCH NEXT FROM cursor_sc INTO @Producto
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (SELECT * FROM Composicion C WHERE C.comp_producto = @Producto)
            BEGIN
                INSERT INTO Item_Factura
                SELECT (i.item_tipo, i.item_sucursal, i.item_numero, C.comp_componente, C.comp_cantidad, (C.comp_cantidad * p.prod_precio))
                FROM inserted i
                    JOIN Composicion C ON c.comp_producto = @Producto
                    JOIN Producto p ON p.prod_codigo = c.comp_componente
            END
        ELSE
            BEGIN
                INSERT INTO Item_Factura SELECT * FROM inserted WHERE item_producto = @Producto
            END
    FETCH NEXT FROM cursor_sc INTO @Producto
    END

    CLOSE cursor_sc
    DEALLOCATE cursor_sc

END

/*
15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.
*//*
CREATE FUNCTION PrecioAcumulado (@Producto char(8))
RETURNS DECIMAL(12,2)
AS
BEGIN

DECLARE @PrecioTotal DECIMAL(12,2) = 0

	IF EXISTS  (SELECT * FROM Composicion WHERE comp_producto = @Producto)
		BEGIN
		
		DECLARE @Componente char(8),@Cantidad_Componente DECIMAL(12,2), @PrecioComponente DECIMAL(12,2) 
		DECLARE cursor_pa CURSOR FOR (SELECT comp_componente, comp_cantidad, prod_precio 
									  FROM Composicion 
										JOIN PRODUCTO ON prod_codigo = comp_producto 
									  WHERE prod_codigo = @Producto)
		
		OPEN cursor_pa 

		FETCH cursor_pa INTO @Componente, @Cantidad_Componente, @Precio_Componente
			
			WHILE @@FETCH_STATUS = 0
				BEGIN

					IF EXISTS (SELECT * FROM Composicion WHERE comp_producto=@Componente) 
						BEGIN
							SET @PrecioTotal = @PrecioTotal + dbo.PrecioAcumulado(@Componente)
						END
					ELSE
						BEGIN
							SET @PrecioTotal = @PrecioTotal + (@Cantidad_Componente * @PrecioComponente)
						END
				END
		FETCH NEXT FROM cursor_pa INTO @Componente, @Cantidad_Componente, @Precio_Componente
		
		CLOSE cursor_pa
		DEALLOCATE cursor_pa

		RETURN @PrecioTotal
		END
	ELSE
		BEGIN 
			SET @PrecioTotal = @PrecioTotal + (SELECT ISNULL(prod_precio,0) FROM Producto WHERE prod_codigo = @Producto)
		END
		
RETURN @PrecioTotal
END*/

/*2) Se requiere recategorizar los encargados asignados a los depositos. 
Para ello cree el o los objetos de bases de datos necesarios que lo resuelva, 
teniendo en cuenta que un deposito no puede tener como encargado un empleado que 
pertenezca a un departamente que no sea de la misma zona que el deposito, si esto 
ocurrea dicho deposito debera asignarsele el empleado con menos depositos asignados
que pertenezca a un departamento de esa zona.*/

--tipo de objeto: procedure

--recategorizar encargados asignados a depositos

--Un deposito no puede tener como encargado un empleado que pertenezca a un departamento
--que no sea de la misma zona que el deposito

--si se cumple eso el deposito debera asignarsele el empleado con menos depositos asignados
--que pertenezca a un departamento de esa zona


CREATE PROCEDURE RecategorizarEncargados
AS
BEGIN
	DECLARE @Deposito char(2), @Encargado NUMERIC(6), @Zona char(3)
	DECLARE cursor_rd CURSOR FOR (SELECT depo_codigo, depo_zona FROM Deposito
									JOIN Empleado ON empl_codigo = depo_encargado
									JOIN Departamento ON depa_codigo = empl_departamento
								  WHERE depa_zona != depo_zona)

	OPEN cursor_rd 
	FETCH NEXT FROM cursor_rd INTO @Deposito, @Zona
		WHILE @@FETCH_STATUS = 0
			BEGIN
			SET @Encargado = (SELECT TOP 1 empl_codigo
							  FROM Empleado 
							  JOIN Departamento D ON d.depa_codigo = empl_departamento 
							  JOIN Deposito Dep ON empl_codigo = depa_encargado
							  WHERE depa_zona = @Zona
							  GROUP BY empl_codigo
							  ORDER BY COUNT(Depo_codigo) ASC
							 )

			UPDATE DEPOSITO SET depo_encargado = @Encargado WHERE depo_codigo = @Deposito

			FETCH NEXT FROM cursor_rd INTO Deposito, @Zona
			END
	CLOSE cursor_rd
	DEALLOCATE cursor_rd
	

END
GO

/*
Implementar el/los objetos necesarios para poder registrar cuáles son los productos que requieren reponer su stock. 
Como tarea preventiva, semanalmente se analizará esta información para que la falta de stock no sea una traba al momento 
de realizar una venta.

Esto se calcula teniendo en cuenta el stoc_punto_reposicion, es decir, si éste supera en un 10% al stoc_cantidad 
deberá registrarse el producto y la cantidad a reponer.

Considerar que la cantidad a reponer no debe ser mayor a stoc_stock_maximo (cant_reponer= stoc_stock_maximo - stoc_cantidad)
*/

CREATE TABLE productos_poco_stock(
    producto CHAR(8),
    cantidad_a_reponer decimal(12,2),
    deposito_producto char(2)
)

CREATE PROCEDURE pr_parcial 
AS
BEGIN


    DECLARE @Producto CHAR(8), @CantidadAReponer decimal(12,2)

    DECLARE cursor_ps CURSOR FOR (SELECT stoc_producto FROM STOCK)

    OPEN cursor_ps
    FETCH NEXT FROM cursor_ps INTO @Producto --@Producto es el prod_codigo, por eso va recorriendo el stock d c/u

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF (SELECT (stoc_cantidad/stoc_punto_reposicion) FROM STOCK WHERE stoc_producto = @Producto) > 1.1
            BEGIN
            SET @CantidadAReponer = SELECT stoc_stock_maximo - stoc_cantidad 
                FROM STOCK 
                WHERE stoc_producto = @Producto

            INSERT INTO productos_poco_stock SELECT stoc_producto,@CantidadAReponer,stoc_deposito 
            FROM STOCK WHERE stoc_producto = @Producto AND stoc_stock_maximo IS NOT NULL
            END
            ELSE 
                BEGIN
                PRINT('No hace falta reponer stock!!! (a lo cande con los signitos)')
                END
        
        FETCH NEXT FROM cursor_ps INTO @Producto
        END
    
    CLOSE cursor_ps 
    DEALLOCATE cursor_ps

END








/*26. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de otros productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.*/


CREATE TRIGGER tr_prodc ON Item_Factura 
INSTEAD OF INSERT 

AS
BEGIN
	
	DECLARE @item_producto char(8),
	DECLARE @item_tipo char(1),
	DECLARE @item_sucursal char(4) 
	DECLARE @item_numero cahar(8)
	
	
	DECLARE cursor_fact CURSOR FOR (SELECT i.item_tipo, i.item_sucursal, i.item_numero. i.item_producto 
									FROM inserted i)
									
	OPEN cursor_fact
	
	FETCH NEXT FROM cursor_fact INTO @item_tipo, @item_sucursal, @item_numero, @item_producto
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		IF EXISTS (SELECT *
					FROM Composicion c
					WHERE c.comp_producto <> @item_producto
					AND c.comp_componente = @item_producto)
				
			begin
			RAISERROR('EL producto a insertar es componente de otro producto, no se puede insertar en la factura',1,1)
			end
					
	
	FETCH NEXT cursor_fact INTO @item_tipo, @item_sucursal, @item_numero, @item_producto
		
	END
	
	CLOSE cursor_fact
	DEALLOCATE cursor_fact
END






/*30. Agregar el/los objetos necesarios para crear una regla por la cual un cliente no
pueda comprar m�s de 100 unidades en el mes de ning�n producto, si esto
ocurre no se deber� ingresar la operaci�n y se deber� emitir un mensaje �Se ha
superado el l�mite m�ximo de compra de un producto�. Se sabe que esta regla se
cumple y que las facturas no pueden ser modificadas.*/


CREATE TRIGGER Ejercicio30 ON item_factura FOR INSERT
AS
BEGIN
	DECLARE @tipo char(1)
	DECLARE @sucursal char(4)
	DECLARE @numero char(8)
	DECLARE @producto char(8)
	DECLARE @cantProducto decimal(12,2)
	DECLARE @itemsVendidosEnELMes int
	DECLARE @excedente int
	DECLARE cursor_ifact CURSOR FOR SELECT item_tipo,item_sucursal,item_numero,item_cantidad
									FROM inserted
	OPEN cursor_ifact
	FETCH NEXT FROM cursor_ifact
	INTO @tipo,@sucursal,@numero,@cantProducto
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @itemsVendidosEnELMes = (
								SELECT sum(item_cantidad)
								FROM Item_Factura
									 JOIN Factura
										ON fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
								WHERE item_producto = @producto
									AND fact_fecha = (SELECT MONTH(GETDATE()))
								)
								
								
		IF (@itemsVendidosEnELMes + @cantProducto) > 100
		
		BEGIN
			SET @excedente = (@itemsVendidosEnELMes + @cantProducto)-100
			DELETE FROM Item_Factura WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
			DELETE FROM Factura WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
			RAISERROR('No se puede comprar mas del producto %s, se superaron las unidades por %i',1,1,@producto,@excedente)
			ROLLBACK TRANSACTION
		END
		FETCH NEXT FROM cursor_ifact
		INTO @tipo,@sucursal,@numero,@cantProducto
	END
	CLOSE cursor_ifact
	DEALLOCATE cursor_ifact
END





/*24. Se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asignársele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.*/

CREATE PROC pr_depo 
AS
BEGIN
	
	DECLARE @depo_zona char(3),
	DECLARE @depo_codigo char(2),
	DECLARE @depo_encargado numeric(6),
	DECLARE @EncargadoNuevo numeric(6)
	
	DECLARE cDepo CURSOR FOR SELECT i.depo_codigo, i.depo_zona, i.depo_encargado FROM inserted i
	
	OPEN cDepo 
	
	FETCH NEXT FROM cDepo
	INTO @depo_codigo, @depo_zona, @depo_encargado
	
	IF EXISTS(@depo_zona <> select de.depa_zona 
							FROM Empleado e2
							JOIN Departamento de ON de.depa_codigo = e2.empl_departamento
							WHERE e2.empl_codigo = @depo_encargado
							)
	BEGIN
		
		SET @EncargadoNuevo = SELECT TOP 1 e.empl_codigo
								FROM Empleado e 
								JOIN DEPOSITO d4 ON d4.depo_encargado = e.empl_codigo
								JOIN Departamento d ON d.depa_codigo = e.empl_departamento
								WHERE d.depa_zona = @depo_zona
								GROUP BY e.empl_codigo
								ORDER BY (select COUNT(e2.empl_codigo)
											FROM Empleado e2
											JOIN Deposito d2 ON d2.depo_encargado = e2.empl_codigo
											WHERE e2.empl_codigo = e.empl_codigo 
											)ASC
								
								--lo de arriba lo hice yo, el de abajo es el resuelto, en vez del subselect en order by
								--puedo hacer esto:
											
											
								SELECT TOP 1 empl_codigo
										FROM Empleado
											INNER JOIN DEPOSITO
												ON depo_encargado = empl_codigo
											INNER JOIN Departamento
												ON depa_codigo = empl_departamento
										WHERE depa_zona = @depoZona
										GROUP BY empl_codigo
										ORDER BY COUNT(*) ASC
										)			
										
		UPDATE DEPOSITO SET depo_encargado = @EncargadoNuevo WHERE depo_codigo = @depo_codigo

		
	END
	
	FETCH NEXT FROM cDepo
	INTO @depo_codigo, @depo_zona, @depo_encargado
	
	CLOSE cDepo
	DEALLOCATE cDepo
	
END




	
/*14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qu� precio se realiz� la
compra. No se deber� permitir que dicho precio sea menor a la mitad de la suma
de los componentes.*/



CREATE FUNCTION sumaComponentesProductoCompuesto(@item_producto char(8))
RETURNS DECIMAL(12,2)
AS
BEGIN
	
	RETURN  SUM(SELECT p.prod_precio
				FROM Producto p
				JOIN Composicion c2 ON p.prod_codigo = c2.comp_componente 
				WHERE c2.comp_producto = @item_producto
				)
END



CREATE TRIGGER tr_item ON Item_Factura FOR INSERT
AS
BEGIN
	
	
	--declarar todas las variables
		
	DECLARE cursor_item CURSOR FOR SELECT item_tipo, item_sucursal, item_numero, item_producto,item_precio
									FROM inserted
	
	OPEN cursor_item
	FETCH cursor_item INTO @item_tipo, @item_sucursal, @item_numero,@item_producto, @item_precio, 
	
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
	IF EXISTS (SELECT 1 FROM Composicion c 
				WHERE c.comp_producto = @item_producto
				AND @item_precio < (sumaComponentesProductoCompuesto(@item_producto))/2
				 )
		BEGIN
				
			SET @fecha_fact = (SELECT fact_fecha
								FROM Factura 
								JOIN Item_Factura ON fact_tipo + fact_sucursal + fact_numero = @item_tipo + @item_sucursal + @item_numero
								)
			
			SET @cliente_fact = (SELECT fact_cliente
								FROM Factura 
								JOIN Item_Factura ON fact_tipo + fact_sucursal + fact_numero = @item_tipo + @item_sucursal + @item_numero
								)
			
			PRINT @fecha_fact, @cliente_fact
			
		END
		
	END
	
END





/*21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.*/



CREATE TRIGGER tr_fact ON Item_Factura
INSTEAD OF INSERT
AS
BEGIN
	
	DECLARE cFact CURSOR FOR SELECT item_tipo, item_sucursal, item_numero, item_producto
									FROM inserted
	
	OPEN cFact
	
	FETCH NEXT FROM cFact
	INTO @familia,  @item_tipo, @item_sucursal, @item_numero, @item_producto
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
	SET @familia = (SELECT p.prod_familia FROM Producto p WHERE p.prod_codigo = @item_producto)
	
	IF EXISTS(SELECT * FROM Item_Factura it
				JOIN Producto p2
				WHERE it.item_tipo + it.item_sucursal + it.item_numero = @item_tipo + @item_sucursal + @item_numero
				AND p2.prod_familia <> @familia
				
				)
		
		BEGIN
			PRINT 'ERROR'
			ROLLBACK TRANSACTION
		END
	
	else
	BEGIN
		INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
        SELECT @item_tipo, @item_sucursal, @item_numero, @item_producto, @item_cantidad, @item_precio
		
	END
	
	FETCH NEXT FROM cFact
	INTO 
	
	CLOSE cFact
	DEALLOCATE cFact
	
	
END