/* pensar en un big mac : buger papa coca
Realizar una consulta SQL que muestre aquellos productos que 

	  █tengan 3 componentes a nivel producto y 
	  █cuyos componentes tengan 2 rubros distintos.
 
De estos productos mostrar:
	 █i.El código de producto.
	 █ii.El nombre del producto.
	 █iii.La cantidad de veces que fueron vendidos sus componentes en el 2012.
	 █iv.Monto total vendido del producto.

El resultado ser ordenado por cantidad de facturas del 2012 en las cuales se vendieron los componentes.

Nota: No se permiten select en el from, es decir, select from (select as T....
*/
--resuelto por mi 
SELECT 
	p.prod_codigo,
	p.prod_detalle,
	(
		SELECT COUNT(f2.fact_numero + f2.fact_tipo + f2.fact_sucursal)
		
		FROM Factura f2
		JOIN Item_Factura it2 ON f2.fact_numero + f2.fact_sucursal + f2.fact_tipo = it2.item_numero + it2.item_sucursal + it2.item_tipo 
		JOIN Composicion c2 ON c2.comp_producto = it2.item_producto 
		
		WHERE it2.item_producto = p.prod_codigo AND YEAR(f2.fact_fecha) = 2012
		 
	) AS 'La cantidad de veces que fueron vendidos sus componentes en el 2012.', 
		
	(
		SELECT SUM(it3.item_cantidad)
		
		FROM Item_Factura it3  
		JOIN Factura f3 ON f3.fact_numero + f3.fact_sucursal + f3.fact_tipo = it3.item_numero + it3.item_sucursal + it3.item_tipo
		
		WHERE it3.item_producto = p.prod_codigo AND YEAR(f3.fact_fecha) = 2012
	
	) AS 'Monto total vendido del producto.'
	
	FROM Producto p
	
	WHERE (SELECT COUNT(DISTINCT c3.comp_componente + c3.comp_producto)
			FROM Producto p2
			JOIN Composicion c3 ON c3.comp_producto = p2.prod_codigo
			WHERE p2.prod_codigo = p.prod_codigo
			) >= 3 
			
			AND
			
			(SELECT COUNT(DISTINCT r2.rubr_id)
			FROM Producto p3
			JOIN Rubro r2 ON r2.rubr_id = p3.prod_rubro
			WHERE p3.prod_codigo = p.prod_codigo
			
			) >=2
	
	GROUP BY p.prod_codigo, p.prod_detalle
	
	ORDER BY (SELECT COUNT(DISTINCT f3.fact_tipo + f3.fact_sucursal + f3.fact_numero)
			FROM Factura f3
			JOIN Item_Factura it4 ON f3.fact_numero + f3.fact_sucursal + f3.fact_tipo = it4.item_numero + it4.item_sucursal + it4.item_tipo 
			JOIN Composicion c4 ON c4.comp_producto = it4.item_producto
	)
	
	
	
	
	

    



SELECT 
    p.prod_codigo,
    p.prod_detalle,
    -- Subconsulta para contar la cantidad de veces que se vendieron los componentes del producto en 2012
    (
        SELECT COUNT(DISTINCT f.fact_numero + f.fact_sucursal + f.fact_tipo)
        FROM Factura f
        JOIN Item_Factura it ON f.fact_tipo = it.item_tipo AND f.fact_sucursal = it.item_sucursal AND f.fact_numero = it.item_numero
        JOIN Composicion c ON it.item_producto = c.comp_componente
        WHERE c.comp_producto = p.prod_codigo AND YEAR(f.fact_fecha) = 2012
    ) AS 'Cantidad de veces que fueron vendidos sus componentes en 2012',
    -- Subconsulta para calcular el monto total vendido del producto
    (
        SELECT SUM(it.item_precio * it.item_cantidad)
        FROM Item_Factura it
        JOIN Composicion c ON it.item_producto = c.comp_componente
        WHERE c.comp_producto = p.prod_codigo
    ) AS 'Monto total vendido del producto'
FROM 
    Producto p
WHERE 
    -- Subconsulta para filtrar productos con al menos 3 componentes distintos
    (SELECT COUNT(DISTINCT c1.comp_componente)
     FROM Composicion c1
     WHERE c1.comp_producto = p.prod_codigo
    ) >= 3
    AND
    -- Subconsulta para filtrar productos con al menos 2 rubros distintos
    (SELECT COUNT(DISTINCT p2.prod_rubro)
     FROM Composicion c2
     JOIN Producto p2 ON c2.comp_componente = p2.prod_codigo
     WHERE c2.comp_producto = p.prod_codigo
    ) >= 2
ORDER BY 
    -- Ordenar por la cantidad de veces que fueron vendidos sus componentes en 2012
    (
        SELECT COUNT(DISTINCT f2.fact_numero + f2.fact_sucursal + f2.fact_tipo)
        FROM Factura f2
        JOIN Item_Factura it2 ON f2.fact_tipo = it2.item_tipo AND f2.fact_sucursal = it2.item_sucursal AND f2.fact_numero = it2.item_numero
        JOIN Composicion c3 ON it2.item_producto = c3.comp_componente
        WHERE c3.comp_producto = p.prod_codigo AND YEAR(f2.fact_fecha) = 2012
    ) DESC;






















SELECT
	P.prod_codigo as [Codigo de Producto],
	P.prod_detalle as [Nombre de Producto],
	ISNULL(
		(
			SELECT count(F.fact_numero + F.fact_sucursal + F.fact_tipo ) 
			FROM Item_Factura IT2 
				INNER JOIN Factura F 
					ON F.fact_numero + F.fact_sucursal + F.fact_tipo = IT2.item_numero + IT2.item_sucursal + IT2.item_tipo 
				INNER JOIN Composicion C3 
					ON C3.comp_producto = P.prod_codigo
			WHERE IT2.item_producto = C3.comp_componente AND YEAR(F.fact_fecha) = 2012
			) ,0) as [Cantidad de Componentes vendida en 2012],

	ISNULL((
		SELECT SUM(IT.item_precio + IT.item_cantidad)  
		FROM Item_Factura IT 
		WHERE IT.item_producto = P.prod_codigo
		),0 ) AS [Monto Vendido Producto]

FROM Producto P 
    INNER JOIN Composicion C 
		ON C.comp_producto = P.prod_codigo

GROUP BY P.prod_codigo,P.prod_detalle

HAVING (--cuyos componentes tengan 2 rubros distintos.
			SELECT COUNT(DISTINCT P6.prod_rubro)
			FROM Producto P6
			INNER JOIN Composicion C6 ON P6.prod_codigo = C6.comp_componente
			WHERE C6.comp_producto = P.prod_codigo
	   ) > 1
	   and
	    (
		SELECT COUNT(DISTINCT C2.comp_componente) 
		FROM Composicion C2 
		WHERE C2.comp_producto = P.prod_codigo
	   ) > 1 -- ACA VA UN 2 PORQUE EN LA BASE DE DATOS NO HAY NINGUNO DE 3 COMPONENTES.

ORDER BY (
			select count( f8.fact_numero + f8.fact_sucursal + f8.fact_tipo ) from Factura f8
				inner join Item_Factura i8
					ON f8.fact_numero + f8.fact_sucursal + f8.fact_tipo = i8.item_numero + i8.item_sucursal + i8.item_tipo
				inner join Composicion C8 
					ON C8.comp_producto = P.prod_codigo
				where i8.item_producto = C8.comp_componente 

		 ) DESC

--El resultado ser ordenado por cantidad de facturas del 2012 en las cuales se vendieron los componentes. 