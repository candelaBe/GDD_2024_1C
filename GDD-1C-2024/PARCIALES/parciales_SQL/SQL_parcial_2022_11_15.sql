/*█:DONE

I, Realizar una consulta SQL que permita saber 

	los clientes que compraron todos los rubros disponibles del sistema en el 2012.

█De estos clientes mostrar, siempre para el 2012: 

	█1.El código del cliente
	█2.Código de producto que en cantidades más compro.
	█3.El nombre del producto del punto 2.

	█4,Cantidad de productos distintos comprados por el cliente.

	█5.Cantidad de productos con composición comprados por el cliente.

El resultado deberá ser ordenado por razón social del cliente
alfabéticamente primero y luego, los clientes que compraron entre un
20 % y 30% del total facturado en el 2012 primero, luego, los restantes,
*/


SELECT cl.clie_codigo, 
	(SELECT TOP 1 it2.item_producto 
	FROM Item_Factura it2 
	JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=it2.item_tipo+it2.item_sucursal+it2.item_numero AND f2.fact_cliente = cl.clie_codigo
	WHERE YEAR(f2.fact_fecha) = 2012
	GROUP BY it2.item_producto
	ORDER BY SUM(it2.item_cantidad) DESC
	),
	(SELECT TOP 1 p2.prod_detalle
	FROM Producto p2 
	JOIN Item_Factura it3 ON it3.item_producto = p2.prod_codigo
	JOIN Factura f3 ON f3.fact_tipo+f3.fact_sucursal+f3.fact_numero=it3.item_tipo+it3.item_sucursal+it3.item_numero AND f3.fact_cliente = cl.clie_codigo
	WHERE YEAR(f3.fact_fecha) = 2012
	GROUP BY it3.item_producto, p2.prod_detalle
	ORDER BY SUM(it3.item_cantidad) DESC),
	COUNT (DISTINCT it.item_producto),
	COUNT (DISTINCT c.comp_producto)
FROM Cliente cl
	JOIN Factura f ON f.fact_cliente = cl.clie_codigo
	JOIN Item_Factura it ON f.fact_tipo+f.fact_sucursal+f.fact_numero=it.item_tipo+it.item_sucursal+it.item_numero
	LEFT JOIN Composicion C ON c.comp_producto = it.item_producto
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY cl.clie_codigo, cl.clie_razon_social
ORDER BY clie_razon_social ASC, 
	(case when sum(F.fact_total)
				 BETWEEN ((SELECT SUM(FT.fact_total) 
						FROM Factura FT
						WHERE YEAR(FT.fact_fecha) = 2012) * 0.2) and ((SELECT SUM(FT.fact_total) 
						FROM Factura FT
						WHERE YEAR(FT.fact_fecha) = 2012) * 0.3)   then 1 
						ELSE 0
	end) ASC




























SELECT 
	CL.clie_codigo,
	(
		select top 1 I1.item_producto
		from Factura F1
			inner join Item_Factura I1
				on F1.fact_tipo+F1.fact_sucursal+F1.fact_numero=I1.item_tipo+I1.item_sucursal+I1.item_numero
			where F1.fact_cliente = CL.clie_codigo AND YEAR(F1.fact_fecha) = 2012
		GROUP BY I1.item_producto
		ORDER BY SUM(I1.item_cantidad) DESC
	) AS CODIGO_PRODUCTO_MAS_COMPRADO,
	(
		select top 1 P2.prod_detalle
		from Factura F2
			inner join Item_Factura I2
				on F2.fact_tipo+F2.fact_sucursal+F2.fact_numero=I2.item_tipo+I2.item_sucursal+I2.item_numero
			inner join Producto P2 
				on P2.prod_codigo = I2.item_producto
			where F2.fact_cliente = CL.clie_codigo AND YEAR(F2.fact_fecha) = 2012
			
		GROUP BY I2.item_producto,P2.prod_detalle
		ORDER BY SUM(I2.item_cantidad) DESC
	) AS DETALLE_PRODUCTO_MAS_COMPRADO,
	COUNT(DISTINCT I.item_producto) AS [Cantidad de productos distintos comprados por el cliente],
	COUNT(DISTINCT CC.comp_producto)  AS [5.Cantidad de productos con composición comprados por el cliente.]

FROM Cliente CL
	INNER JOIN Factura F 
		ON F.fact_cliente = CL.clie_codigo
	INNER JOIN Item_Factura I
		ON F.fact_tipo+F.fact_sucursal+F.fact_numero=I.item_tipo+I.item_sucursal+I.item_numero
	INNER JOIN Producto PD
		ON PD.prod_codigo = I.item_producto
	LEFT JOIN Composicion CC 
		ON CC.comp_producto = I.item_producto
WHERE YEAR(F.fact_fecha) = 2012
GROUP BY CL.clie_codigo, CL.clie_razon_social
ORDER BY CL.clie_razon_social ASC , 
	( case when sum(F.fact_total)
				 BETWEEN ((SELECT SUM(FT.fact_total) 
						FROM Factura FT
						WHERE YEAR(FT.fact_fecha) = 2012) * 0.2) and ((SELECT SUM(FT.fact_total) 
						FROM Factura FT
						WHERE YEAR(FT.fact_fecha) = 2012) * 0.3)   then 1 
						ELSE 0
	end) ASC

    