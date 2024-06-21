--CONSEJOS


------------------------------            1                    -----------------

el @ en los cursores casi siempre se usa cuando haces el select en el if y el from y el join
por ejemplo where it.item_producto = @prod_codigo
asi sabes cual es cual





------------------------------            2                    -----------------
acordarse del exists, ehemplo

ORDER BY (
		CASE WHEN EXISTS (SELECT * FROM Composicion c
						 WHERE c.comp_producto = p.prod_codigo)

		THEN 1
		ELSE 2
		END
) DESC


desc el mas alto arriba
asc el mas bajo arriba

------------------------------            3                    -----------------

si dice maximo precio de venta, usar MAX(i.item_precio), NO HACER TOP 1



------------------------------            4                    -----------------

si haces if exists (select * from ...), y solo se debe cumplir 1 vez, usar select 1 
para mejorar rendimiento


------------------------------            5                    -----------------

en vez de hacer un JOIN item_factura, en TSQL, puedo hacer el WHERE:

SELECT fact_cliente
						FROM Factura
						WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
						

------------------------------            6                    -----------------
--acordarse del GROUP BY, porq sino salen repetidos por ejemplo aca: van a salir solo

select c.comp_componente 
FROM Composicion c
JOIN Item_Factura if2 ON if2.item_producto = c.comp_componente
WHERE c.comp_producto <> if2.item_producto
group by c.comp_componente 


--resultados:
00001420
00001491
00001516
00005703
00006404
00006411
00014003

--en cambio si NO PONGO EL GROUP BY, salen todos repetidos varias veces, y si tengo q contarlos van a salir repetidos

--capaz para algunos casos no hace falta, por ejemplo:



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
		
		
	END
	
END
