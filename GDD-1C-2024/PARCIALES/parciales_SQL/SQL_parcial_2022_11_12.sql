/* Realizar una consulta SQL que permita saber los clientes que
compraron por encima del promedio de compras (fact_total) de todos
los clientes del 2012.

De estos clientes mostrar para el 2012:
1.El código del cliente
2.La razón social del cliente
3.Código de producto que en cantidades más compro.
4,El nombre del producto del punto 3.
5,Cantidad de productos distintos comprados por el cliente,
6.Cantidad de productos con composición comprados por el cliente,

EI resultado deberá ser ordenado poniendo primero aquellos clientes
que compraron más de entre 5 y 10 productos distintos en el 2012 */







 SELECT 
 	cl.clie_codigo,
 	cl.clie_razon_social,
 	(
 		SELECT TOP 1 i3.item_producto
 		
 		FROM Factura f3
		JOIN Item_Factura i3 ON i3.item_tipo = f3.fact_tipo AND i3.item_sucursal = f3.fact_sucursal AND i3.item_numero = f3.fact_numero
		
		WHERE f3.fact_cliente = cl.clie_codigo AND YEAR(f3.fact_fecha) = 2012
		GROUP BY i3.item_producto
		ORDER BY SUM(i3.item_cantidad) DESC
 	) AS 'Código de producto que en cantidades más compro.',
 	
 	(
 		SELECT TOP 1 p2.prod_detalle
 		
 		FROM Factura f4
		JOIN Item_Factura i4 ON i4.item_tipo = f4.fact_tipo AND i4.item_sucursal = f4.fact_sucursal AND i4.item_numero = f4.fact_numero
		JOIN Producto p2 ON p2.prod_codigo = i4.item_producto 
		
		WHERE f4.fact_cliente = cl.clie_codigo AND YEAR(f4.fact_fecha) = 2012
		GROUP BY i4.item_producto, p2.prod_detalle
		ORDER BY SUM(i4.item_cantidad) DESC
 	) AS 'Nombre de producto que en cantidades más compro.',
 	
 	COUNT(DISTINCT i.item_producto) AS 'Cantidad de productos distintos comprados por el cliente',
 	
 	COUNT(DISTINCT c.comp_producto) AS 'Cantidad de productos con composición comprados por el cliente'
 	
 	
 	FROM Factura f
 	JOIN Cliente cl ON cl.clie_codigo = f.fact_cliente 
	JOIN Item_Factura i ON i.item_tipo = f.fact_tipo AND i.item_sucursal = f.fact_sucursal AND i.item_numero = f.fact_numero
--	JOIN Producto p ON p.prod_codigo = i.item_producto 
	LEFT JOIN Composicion c ON c.comp_producto = i.item_producto 
	
	WHERE YEAR(f.fact_fecha) = 2012
	AND 
			(SELECT SUM(f3.fact_total)
			FROM Factura f3
			WHERE f3.fact_cliente = cl.clie_codigo AND YEAR(f3.fact_fecha) = 2012)
	
	
			>  (SELECT AVG(f4.fact_total)
				FROM Factura f4
				WHERE f4.fact_cliente = cl.clie_codigo AND YEAR(f4.fact_fecha) = 2012)
				
	GROUP BY cl.clie_codigo, cl.clie_razon_social
		
	ORDER BY cl.clie_codigo
	
--En el de arriba joineo la tabla de producto en vez de hacer C2.comp_producto = I.item_producto
--en este me devuelve 64 y en el de abajo 63







SELECT
	c.clie_codigo,
	c.clie_razon_social,

	ISNULL(
	(
		SELECT TOP 1 i3.item_producto
		FROM Item_Factura i3
			 JOIN Factura f3 
			 ON i3.item_tipo = f3.fact_tipo AND i3.item_sucursal = f3.fact_sucursal AND i3.item_numero = f3.fact_numero
		WHERE YEAR(f3.fact_fecha) = 2012 AND f3.fact_cliente = c.clie_codigo
		GROUP BY i3.item_producto
		ORDER BY SUM(i3.item_cantidad) DESC
	),'NO HAY PRODUCTO') AS codigo_producto_mas_comprado,


	ISNULL((
	SELECT TOP 1 p5.prod_detalle
	FROM Item_Factura i5
	 JOIN Factura f5 ON
		i5.item_tipo = f5.fact_tipo
		AND i5.item_sucursal = f5.fact_sucursal
		AND i5.item_numero = f5.fact_numero
	 JOIN Producto p5 ON
		i5.item_producto = p5.prod_codigo
	WHERE
		YEAR(f5.fact_fecha) = 2012
		AND f5.fact_cliente = c.clie_codigo
	GROUP BY
		i5.item_producto,
		p5.prod_detalle
	ORDER BY
		SUM(i5.item_cantidad) DESC),
	'NO HAY PRODUCTO') AS detalle_producto_mas_comprado,

	COUNT(DISTINCT i.item_producto) AS productos_distintos,

	COUNT(DISTINCT C2.comp_producto) AS productos_compuestos

FROM Cliente c
INNER JOIN Factura f 
	ON c.clie_codigo = f.fact_cliente
INNER JOIN Item_Factura i 
	ON f.fact_tipo = i.item_tipo AND f.fact_sucursal = i.item_sucursal AND f.fact_numero = i.item_numero
LEFT JOIN Composicion C2 ON
    C2.comp_producto = I.item_producto
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY c.clie_codigo, c.clie_razon_social
HAVING
	(
	SELECT SUM(f.fact_total)
	FROM Factura f
	WHERE f.fact_cliente = c.clie_codigo
		AND YEAR(f.fact_fecha) = 2012) > 
		(
			SELECT AVG(f2.fact_total)
			FROM Factura f2
			WHERE YEAR(f2.fact_fecha) = 2012 
		)
ORDER BY c.clie_codigo
	--CASE
	--	WHEN COUNT(DISTINCT i.item_producto) BETWEEN 5 AND 10 THEN 1
	--	ELSE 2
	--END ASC



	SELECT 
     cl.clie_codigo,
    cl.clie_razon_social,
    (SELECT TOP 1 p2.prod_codigo 
        FROM Producto p2
        JOIN Item_Factura it2 ON it2.item_producto = p2.prod_codigo
        JOIN Factura f2 ON f2.fact_numero + f2.fact_tipo + f2.fact_sucursal = it2.item_numero + it2.item_tipo + it2.item_sucursal 
        WHERE cl.clie_codigo = f2.fact_cliente AND YEAR(f2.fact_fecha) = 2012
        GROUP BY p2.prod_codigo
        ORDER BY SUM(it2.item_cantidad) DESC
     ) AS 'Codigo del producto mas comprado',
    (SELECT TOP 1 p3.prod_detalle 
        FROM Producto p3
        JOIN Item_Factura it3 ON it3.item_producto = p3.prod_codigo
        JOIN Factura f3 ON f3.fact_numero + f3.fact_tipo + f3.fact_sucursal = it3.item_numero + it3.item_tipo + it3.item_sucursal 
        WHERE cl.clie_codigo = f3.fact_cliente AND YEAR(f3.fact_fecha) = 2012
        GROUP BY p3.prod_detalle
        ORDER BY SUM(it3.item_cantidad) DESC
    ) AS 'Nombre del producto mas comprado',
    COUNT(DISTINCT it.item_producto) AS CantidadProductosDistintosComprados,
    COUNT(DISTINCT cmp.comp_producto) AS 'Cantidad de productos con composición comprados por el cliente'
FROM Cliente cl
    JOIN Factura F ON cl.clie_codigo = f.fact_cliente
    JOIN Item_Factura it ON f.fact_numero + f.fact_tipo + f.fact_sucursal = it.item_numero + it.item_tipo + it.item_sucursal 
    LEFT JOIN Composicion cmp ON cmp.comp_producto = it.item_producto
WHERE YEAR(f.fact_fecha) = 2012 
    AND (SELECT AVG(f5.fact_total)
        FROM Factura f5
        WHERE YEAR(f5.fact_fecha) = 2012
        )
        <
        (SELECT SUM(f4.fact_total)
        FROM Factura f4 
        WHERE YEAR(f4.fact_fecha) = 2012
        ) 
GROUP BY clie_codigo, clie_razon_social
ORDER BY 
    CASE
        WHEN COUNT(DISTINCT it.item_producto) BETWEEN 5 AND 10 THEN 1
        ELSE 2
    END DESC