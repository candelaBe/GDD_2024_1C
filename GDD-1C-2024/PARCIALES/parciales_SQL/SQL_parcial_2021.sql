/*1Armar una consulta Sql que retorne: █:DONE

	█Razón social del cliente
	█Límite de crédito del cliente
	█Producto más comprado en la historia (en unidades)     -- Yo interpreto que es el producto mas comprado en la historia del cliente

	█Solamente deberá mostrar aquellos clientes que tuvieron mayor cantidad de ventas en el 2012 que
    en el 2011 en cantidades y cuyos montos de ventas en dichos años sean un 30 % mayor el 2012 con
    respecto al 2011. 

	█El resultado deberá ser ordenado por código de cliente ascendente

NOTA: No se permite el uso de sub-selects en el FROM.
*/

SELECT 
	cl.clie_razon_social,
	cl.clie_limite_credito,
	
	(
		SELECT TOP 1 I2.item_producto
		
		FROM Item_Factura I2
		JOIN Factura F2 ON F2.fact_tipo+F2.fact_sucursal+F2.fact_numero=I2.item_tipo+I2.item_sucursal+I2.item_numero
		
		WHERE F2.fact_cliente = cl.clie_codigo 
		GROUP BY I2.item_producto
		ORDER BY ISNULL(SUM(I2.item_cantidad),0) DESC
	) AS 'producto mas comprado en la historia'
	
	FROM Cliente cl 
	
	WHERE (SELECT COUNT (f.fact_tipo + f.fact_sucursal + f.fact_numero)
			
			FROM Factura f 
			JOIN Item_Factura if2 ON f.fact_tipo+f.fact_sucursal+f.fact_numero=if2.item_tipo+if2.item_sucursal+if2.item_numero
			WHERE f.fact_cliente = cl.clie_codigo AND YEAR(f.fact_fecha) = 2012
		  ) >
		  (SELECT COUNT (f2.fact_tipo + f2.fact_sucursal + f2.fact_numero)
			
			FROM Factura f2
			JOIN Item_Factura if3 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=if3.item_tipo+if3.item_sucursal+if3.item_numero
			
			WHERE f2.fact_cliente = cl.clie_codigo AND YEAR(f2.fact_fecha) = 2011
		  )
		  AND 
		  
		  (SELECT SUM (f.fact_total)
			
			FROM Factura f 
			WHERE f.fact_cliente = cl.clie_codigo AND YEAR(f.fact_fecha) = 2012
		  )  >
		  (SELECT SUM (f2.fact_total)
			
			FROM Factura f2
			
			WHERE f2.fact_cliente = cl.clie_codigo AND YEAR(f2.fact_fecha) = 2011
		  ) *1.3
		  
	
	
	GROUP BY cl.clie_razon_social, cl.clie_limite_credito, cl.clie_codigo
	
	ORDER BY cl.clie_codigo ASC
	
	
	






SELECT 
	CL.clie_razon_social,
	CL.clie_limite_credito,
	ISNULL((
		SELECT TOP 1 I2.item_producto
		FROM Factura F2 
			INNER JOIN Item_Factura I2
				ON F2.fact_tipo+F2.fact_sucursal+F2.fact_numero=I2.item_tipo+I2.item_sucursal+I2.item_numero

		WHERE F2.fact_cliente = CL.clie_codigo
		GROUP BY I2.item_producto
		ORDER BY ISNULL(SUM(I2.item_cantidad),0) DESC
	),0) AS PRODUCTO_MAS_COMPRADO_HISTORIA_CLIENTE
FROM Cliente CL
GROUP BY CL.clie_razon_social,CL.clie_limite_credito,CL.clie_codigo
HAVING 
		--y cuyos montos de ventas en dichos años sean un 30 % mayor el 2012 con respecto al 2011. 
		(
		SELECT SUM(F3.fact_total) 
		FROM Factura F3 
		WHERE F3.fact_cliente = CL.clie_codigo AND YEAR(F3.fact_fecha) = 2012
	   )  > (
		SELECT SUM(F3.fact_total) 
		FROM Factura F3 
		WHERE F3.fact_cliente = CL.clie_codigo AND YEAR(F3.fact_fecha) = 2011
	   ) * 1.3

	   AND -- que tuvieron mayor cantidad de ventas en el 2012 que en el 2011 en cantidades 

	   (
		SELECT ISNULL(SUM(I4.item_cantidad),0)
		FROM Factura F4 
			INNER JOIN Item_Factura I4
				ON F4.fact_tipo+F4.fact_sucursal+F4.fact_numero=I4.item_tipo+I4.item_sucursal+I4.item_numero
		WHERE F4.fact_cliente = CL.clie_codigo 
		AND YEAR(F4.fact_fecha) = 2012
	   ) >
		 (
		SELECT ISNULL(SUM(I5.item_cantidad),0)
		FROM Factura F5 
			INNER JOIN Item_Factura I5
				ON F5.fact_tipo+F5.fact_sucursal+F5.fact_numero=I5.item_tipo+I5.item_sucursal+I5.item_numero
		WHERE YEAR(F5.fact_fecha) = 2011 AND F5.fact_cliente = CL.clie_codigo
	   )
ORDER BY CL.clie_codigo ASC
