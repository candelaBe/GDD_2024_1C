/*1. Se solicita estadística por Año y familia, para ello se deberá mostrar.
Año,
 Código de familia, 
 Detalle de familia, 
 cantidad de facturas, 
 cantidad de productos con COmposición vendidOs, 
 monto total vendido.
 Solo se deberán considerar las familias que tengan al menos un producto con
composición y que se hayan vendido conjuntamente (en la misma factura)
con otra familia distinta.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones
definidas por el usuario para este punto,*/












SELECT 
	YEAR(f.fact_fecha),
	fa.fami_id,
	fa.fami_detalle,
	
	COUNT(DISTINCT f.fact_tipo + f.fact_sucursal + f.fact_numero) AS 'cantidad de facturas por familia',
	
	
	
	(
		SELECT COUNT(DISTINCT c.comp_producto + c.comp_componente)
		FROM Factura f2
		JOIN Item_Factura if2 
			on f2.fact_tipo+ f2.fact_sucursal+ f2.fact_numero = if2.item_tipo+ if2.item_sucursal+ if2.item_numero
		JOIN Producto p2
			ON p2.prod_codigo = if2.item_producto
		JOIN Composicion c 
			ON c.comp_producto = p2.prod_codigo
		
		
		WHERE fa.fami_id = p2.prod_familia AND YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)  --IMPORTANTE
		--EN VEZ DE HACER UN JOIN CON FAMILIA, PONER WHERE FAMI_ID=PROD_FAMILIA
	) AS'Cantidad de productos con composicion vendidos',
	
	
	/*
	(
		SELECT SUM(if3.item_cantidad * if3.item_precio)
		
		FROM Factura f3
		JOIN Item_Factura if3 ON f3.fact_tipo+ f3.fact_sucursal+ f3.fact_numero = if3.item_tipo+ if3.item_sucursal+ if3.item_numero
		JOIN Producto p2
			ON p2.prod_codigo = if3.item_producto
		
		
		WHERE fa.fami_id = p2.prod_familia AND YEAR(f.fact_fecha) = YEAR(f3.fact_fecha)  

	) AS'Monto total'--VER SI DA LO MISMO ESTO
	
	 ESTO ES LO MISMO Q ESTO DE ABAJO: NO HACE FALTA EL SUBSELECT*/
	    SUM(if3.item_precio*if3.item_cantidad) AS 'Monto total vendido'   

	
	FROM Factura f
	JOIN Item_Factura if3 ON f.fact_tipo+ f.fact_sucursal+ f.fact_numero = if3.item_tipo+ if3.item_sucursal+ if3.item_numero
	JOIN Producto p ON p.prod_codigo  = if3.item_producto  
	JOIN Familia fa ON fa.fami_id =p.prod_familia 
	
	WHERE fa.fami_id IN 
    (
    	SELECT fa2.fami_id 
    	 FROM Composicion c2
   		 JOIN Producto p3 ON p3.prod_codigo = c2.comp_producto
   		 JOIN Familia fa2  ON p3.prod_familia = fa2.fami_id
   		 JOIN Item_Factura it4 ON p3.prod_codigo = it4.item_producto
    )
    	AND fa.fami_id IN 
    (SELECT p4.prod_familia FROM Producto p4
    JOIN Item_Factura it6 ON p4.prod_codigo = it6.item_producto
    JOIN Item_Factura it5 ON it5.item_tipo + it5.item_sucursal+ it5.item_numero = it6.item_tipo+ it6.item_sucursal+ it6.item_numero
    JOIN producto p5 ON p5.prod_codigo = it5.item_producto

    WHERE p4.prod_familia = p5.prod_familia
    )
	
	GROUP BY YEAR(f.fact_fecha), fa.fami_id, fa.fami_detalle
	
	
	





























SELECT year(f.fact_fecha),fa.fami_id,fa.fami_detalle [ANIO]
,COUNT(distinct f.fact_numero+f.fact_sucursal+f.fact_tipo) [CANTIDAD DE FACTURAS]
,(SELECT SUM(i1.item_cantidad) FROM Composicion c1
join Item_Factura i1 on i1.item_producto = c1.comp_producto
join Producto p1 on p1.prod_codigo = i1.item_producto
join Factura f1 on f1.fact_numero+f1.fact_sucursal+f1.fact_tipo=i1.item_numero+i1.item_sucursal+i1.item_tipo
where p1.prod_familia =fa.fami_id and year(f1.fact_fecha) =YEAR(f.fact_fecha )) [CANTIDAD DE PROD COMPOSICION VENDIDOS]
,SUM(i.item_cantidad*i.item_precio) [MONTO TOTAL]
FROM Factura f
join Item_Factura i on f.fact_numero+f.fact_sucursal+f.fact_tipo=i.item_numero+i.item_sucursal+i.item_tipo
join Producto p on p.prod_codigo = i.item_producto
join Familia fa on fa.fami_id = p.prod_familia
where fa.fami_id 
    in 
(   select fa1.fami_id 
    from Composicion c1
    join Producto p1 on p1.prod_codigo = c1.comp_producto
    join Familia fa1 on fa1.fami_id = p1.prod_familia
    join Item_Factura i1 on i1.item_producto=p1.prod_codigo
    join Factura f1 on f1.fact_numero+f1.fact_sucursal+f1.fact_tipo=i1.item_numero+i1.item_sucursal+i1.item_tipo
    group by fa1.fami_id)
    and fa.fami_id 
    in 
(   select p1.prod_familia 
    from Producto p1 
    join Item_Factura i1 on i1.item_producto = p1.prod_codigo
    join Item_Factura i2 on i1.item_numero+i1.item_sucursal+i1.item_tipo = i2.item_numero+i2.item_sucursal+i2.item_tipo
    join Producto p2 on p2.prod_codigo = i2.item_producto
    
    where p2.prod_familia <> p1.prod_familia

    group by p1.prod_familia)
    
group by year(f.fact_fecha),fa.fami_id,fa.fami_detalle
