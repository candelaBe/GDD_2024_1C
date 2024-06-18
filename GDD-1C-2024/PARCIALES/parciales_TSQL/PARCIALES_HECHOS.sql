-- Parcial 1/7/23
SELECT 
	c.clie_codigo, 
	c.clie_razon_social, 
	COUNT(DISTINCT p.prod_rubro) AS 'Cantidad Rubros por Cliente',
	(SELECT COUNT(DISTINCT co.comp_producto)
		FROM Factura F2 
		JOIN Item_Factura it2 ON F2.fact_tipo+F2.fact_sucursal+F2.fact_numero = it2.item_tipo+it2.item_sucursal+it2.item_numero		
		JOIN Composicion co ON co.comp_producto = it2.item_producto
		WHERE YEAR(F2.fact_fecha) = 2012 AND F2.FACT_CLIENTE = c.clie_codigo
	) AS 'Cantidad productos compuestos'
	
FROM Cliente c
	JOIN Factura f ON c.clie_codigo = f.fact_cliente
	JOIN Item_Factura i ON f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
	JOIN Producto p ON p.prod_codigo = i.item_producto
WHERE EXISTS (SELECT 1
	FROM Item_Factura it3
	JOIN Factura F3 ON f3.fact_tipo+f3.fact_sucursal+f3.fact_numero = it3.item_tipo+it3.item_sucursal+it3.item_numero
	WHERE YEAR(F3.fact_fecha) = YEAR(f.fact_fecha) AND F3.fact_cliente = c.clie_codigo 
)
AND EXISTS (SELECT 1
	FROM Item_Factura it4
	JOIN Factura F4 ON F4.fact_tipo+F4.fact_sucursal+F4.fact_numero = it4.item_tipo+it4.item_sucursal+it4.item_numero
	WHERE YEAR(F4.fact_fecha) = YEAR(f.fact_fecha) + 1 AND F4.fact_cliente = c.clie_codigo
) 

GROUP BY c.clie_codigo, c.clie_razon_social
ORDER BY COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) ASC


-- Parcial 4/7/23
SELECT
    fa.fami_id,
    fa.fami_detalle,
    COUNT (DISTINCT f.fact_tipo+ f.fact_sucursal+ f.fact_numero) AS 'Cantidad de facturas',
    (SELECT SUM(it2.item_cantidad) 
        FROM Composicion c
        JOIN Item_Factura it2 ON it2.item_producto = c.comp_producto
        JOIN Producto p2 ON p2.prod_codigo = it2.item_producto
        JOIN Factura f2 ON f2.fact_tipo+ f2.fact_sucursal+ f2.fact_numero = it2.item_tipo+ it2.item_sucursal+ it2.item_numero
        WHERE fa.fami_id = p2.prod_familia AND YEAR(f.fact_fecha) = YEAR(f2.fact_fecha) 
    ) AS 'Cant de productos con composicion vendidos',
    SUM(i.item_precio*i.item_cantidad) AS 'Monto total vendido'   
FROM factura f
    JOIN Item_Factura i ON f.fact_tipo+ f.fact_sucursal+ f.fact_numero = i.item_tipo+ i.item_sucursal+ i.item_numero
    JOIN Producto p ON p.prod_codigo = i.item_producto
    JOIN Familia fa ON p.prod_familia = fa.fami_id
WHERE fa.fami_id IN 
    (SELECT fa2.fami_id FROM Composicion C
    JOIN ProductO p2 ON p2.prod_codigo = c.comp_producto
    JOIN Familia fa2  ON p2.prod_familia = fa2.fami_id
    JOIN Item_Factura it3 ON p2.prod_codigo = it3.item_producto
    --JOIN Factura f3 ON f3.fact_tipo+ f3.fact_sucursal+ f3.fact_numero = it3.item_tipo+ it3.item_sucursal+ it3.item_numero
    )
AND fami_id IN 
    (SELECT p2.prod_familia FROM Producto p2
    JOIN Item_Factura it4 ON p2.prod_codigo = it4.item_producto
    JOIN Item_Factura it5 ON it5.item_tipo + it5.item_sucursal+ it5.item_numero = it4.item_tipo+ it4.item_sucursal+ it4.item_numero
    JOIN producto p3 ON p3.prod_codigo = it5.item_producto

    WHERE p2.prod_familia = p3.prod_familia
    )


GROUP BY YEAR(f.fact_fecha), fa.fami_id, fa.fami_detalle


-- Parcial 15/11/22

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
	JOIN Producto P ON it.item_producto = p.prod_codigo
	LEFT JOIN Composicion C ON c.comp_producto = it.item_producto
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY cl.clie_codigo, cl.clie_razon_social
having count(distinct p.prod_rubro) = (select count(distinct rubr_id)
                                     from Rubro)
ORDER BY clie_razon_social ASC, 
	(case when sum(F.fact_total)
				 BETWEEN ((SELECT SUM(FT.fact_total) 
						FROM Factura FT
						WHERE YEAR(FT.fact_fecha) = 2012) * 0.2) and ((SELECT SUM(FT.fact_total) 
						FROM Factura FT
						WHERE YEAR(FT.fact_fecha) = 2012) * 0.3)   then 1 
						ELSE 0
	end) ASC


-- Parcial 29-6-23

SELECT 
	c.clie_codigo,
	(
		SELECT SUM(f2.fact_total) 
		FROM Factura f2 
			WHERE c.clie_codigo = f2.fact_cliente AND YEAR(f2.fact_fecha) = 2012
	) AS 'monto total comprado en 2012',
	(
		SELECT SUM(it2.item_cantidad)
		FROM Item_Factura it2
			JOIN Factura f3 ON f3.fact_tipo+ f3.fact_sucursal+ f3.fact_numero = it2.item_tipo+ it2.item_sucursal+ it2.item_numero
		WHERE c.clie_codigo = f3.fact_cliente AND YEAR(f3.fact_fecha) = 2012
	) AS 'cantidad de unidades compradas en 2012'	
FROM Cliente c	
JOIN Factura f ON
	f.fact_cliente = c.clie_codigo
WHERE 		5 <=  (SELECT COUNT(DISTINCT it3.item_producto)
			FROM Item_Factura it3
			JOIN Factura f4 ON f4.fact_tipo+ f4.fact_sucursal+ f4.fact_numero = it3.item_tipo+ it3.item_sucursal+ it3.item_numero
			WHERE YEAR(f4.fact_fecha) = YEAR(f.fact_fecha) AND f4.fact_cliente = c.clie_codigo
			)
			AND
			5 <=  (SELECT COUNT(DISTINCT it4.item_producto)
			FROM Item_Factura it4
			JOIN Factura f5 ON f5.fact_tipo+ f5.fact_sucursal+ f5.fact_numero = it4.item_tipo+ it4.item_sucursal+ it4.item_numero
			WHERE YEAR(f5.fact_fecha) = YEAR(f.fact_fecha) + 1 AND f5.fact_cliente = c.clie_codigo
			)
GROUP BY c.clie_codigo, c.clie_razon_social
ORDER BY 	
		CASE WHEN (
			SELECT COUNT(it5.item_producto)
			FROM Item_Factura it5
			JOIN Factura f6 ON f6.fact_tipo+ f6.fact_sucursal+ f6.fact_numero = it5.item_tipo+ it5.item_sucursal+ it5.item_numero
			WHERE f6.fact_cliente = c.clie_codigo AND it5.item_producto NOT IN (SELECT comp_producto FROM Composicion)
		) = 0 THEN 1 ELSE 0 END DESC


-- 27-6-23
SELECT TOP 10 
	c.clie_razon_social AS 'Apellido y Nombre del Cliente',
	COUNT(DISTINCT it.item_producto) AS 'Cantidad de Productos Distintos comprados en 2012',
	(
		SELECT SUM(it2.item_cantidad)
		FROM Item_Factura it2
		JOIN Factura f2 ON f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = it2.item_tipo + it2.item_sucursal + it2.item_numero
		WHERE f2.fact_cliente = c.clie_codigo AND YEAR(f2.fact_fecha) = 2012 AND MONTH(f2.fact_fecha) <= 6
	) AS 'Cantidad de unidades compradas dentro del primer semestre de 2012'

FROM Cliente c
JOIN Factura f ON f.fact_cliente = c.clie_codigo
JOIN Item_Factura it ON f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero
WHERE YEAR(f.fact_fecha) = 2012 
	AND 3 < (
		SELECT COUNT(DISTINCT f3.fact_vendedor)
		FROM Factura f3 
		WHERE YEAR(f3.fact_fecha) = YEAR(f.fact_fecha) AND f3.fact_cliente = c.clie_codigo
	) 
GROUP BY c.clie_codigo, c.clie_razon_social
ORDER BY COUNT(f.fact_cliente) DESC, c.clie_codigo DESC;


-- 22-11-2022


SELECT 
    p.prod_codigo,
    p.prod_detalle,
    (SELECT COUNT(DISTINCT f2.fact_numero + f2.fact_sucursal + f2.fact_tipo)
	FROM Factura f2 
	JOIN Item_Factura it2 ON f2.fact_numero + f2.fact_sucursal + f2.fact_tipo = it2.item_numero + it2.item_sucursal + it2.item_tipo
	JOIN Composicion c2 ON p.prod_codigo = c2.comp_producto
	WHERE YEAR(f2.fact_fecha) = 2012 AND it2.item_producto = c2.comp_componente
	) AS CantidadVecesVendidosComponentes2012,
    (SELECT SUM(it3.item_precio * it3.item_cantidad)
	 FROM Item_Factura it3 
	 WHERE p.prod_codigo = it3.item_producto
	 ) AS MontoTotalVendido
FROM 
    Producto p
    JOIN Composicion c ON p.prod_codigo = c.comp_producto

   WHERE (
        SELECT COUNT(DISTINCT c3.comp_componente)
        FROM Composicion c3
        WHERE c3.comp_producto = p.prod_codigo
    ) = 3
    AND (
        SELECT COUNT(DISTINCT p3.prod_rubro)
        FROM Composicion c4
        JOIN Producto p3 ON c4.comp_componente = p3.prod_codigo
        WHERE c4.comp_producto = p.prod_codigo
    ) = 2
GROUP BY 
    p.prod_codigo, 
    p.prod_detalle
ORDER BY 
    CantidadVecesVendidosComponentes2012 DESC;


-- 12/11/22


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
	COUNT(DISTINCT cmp.comp_producto) AS 'Cantidad de productos con composici�n comprados por el cliente'
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
GROUP BY cl.clie_codigo, cl.clie_razon_social
ORDER BY 
	CASE
        WHEN (SELECT COUNT(DISTINCT it5.item_producto) FROM Item_Factura it5
		JOIN Factura f5 ON  f5.fact_numero + f5.fact_tipo + f5.fact_sucursal = it5.item_numero + it5.item_tipo + it5.item_sucursal WHERE YEAR(f5.fact_fecha)=2012) BETWEEN 5 AND 10 THEN 1
        ELSE 2
    END DESC



-- Parcial en clase 15/6/24

SELECT
    p.prod_detalle,
    (CASE WHEN
        (SELECT COUNT(DISTINCT p2.prod_rubro)
        FROM Producto p2 
        JOIN Composicion c2 ON c2.comp_componente = p2.prod_codigo
        WHERE c2.comp_producto = cmp.comp_producto
        ) = 1
        THEN 'Mismo rubro nivel 1' ELSE 'Distinto rubro nivel 1'
        END )
    ,
    (
        SELECT SUM(it2.item_precio * it2.item_cantidad)
        FROM Item_Factura it2
        WHERE it2.item_producto = p.prod_codigo 
    ) AS 'Total facturado del producto'
FROM Composicion cmp 
JOIN Producto p ON p.prod_codigo = cmp.comp_producto
WHERE 
    (SELECT COUNT(cmp2.comp_componente)
     FROM Composicion cmp2
     WHERE cmp2.comp_producto = p.prod_codigo
    ) > 1 
GROUP BY p.prod_detalle, cmp.comp_producto, p.prod_codigo
ORDER BY 
    (SELECT SUM(f5.fact_total) 
    FROM Factura f5 
    JOIN Item_Factura it5 ON f5.fact_tipo+f5.fact_sucursal+f5.fact_numero = it5.item_tipo+it5.item_sucursal+it5.item_numero
    WHERE (SELECT COUNT(cmp5.comp_componente)
           FROM Composicion cmp5
           WHERE cmp5.comp_producto = p.prod_codigo
          ) > 1 
    AND it5.item_producto = p.prod_codigo AND YEAR(f5.fact_fecha) = 2012) DESC


SELECT
    p.prod_detalle,
    (CASE WHEN
        (SELECT COUNT(DISTINCT p2.prod_rubro)
        FROM Producto p2 
        JOIN Composicion c2 ON c2.comp_componente = p2.prod_codigo
        WHERE c2.comp_producto = cmp.comp_producto
        ) = 1
        THEN 'Mismo rubro nivel 1' ELSE 'Distinto rubro nivel 1'
        END )
    ,
    (
        SELECT SUM(it2.item_precio * it2.item_cantidad)
        FROM Item_Factura it2
        WHERE it2.item_producto = p.prod_codigo 
    ) AS 'Total facturado del producto'
FROM Composicion cmp 
JOIN Producto p ON p.prod_codigo = cmp.comp_producto
WHERE 
    EXISTS (SELECT 1
     FROM Composicion cmp2
     WHERE cmp2.comp_producto = p.prod_codigo
    ) 
GROUP BY p.prod_detalle, cmp.comp_producto, p.prod_codigo
ORDER BY 
    (SELECT SUM(f5.fact_total) 
    FROM Factura f5 
    JOIN Item_Factura it5 ON f5.fact_tipo+f5.fact_sucursal+f5.fact_numero = it5.item_tipo+it5.item_sucursal+it5.item_numero
    WHERE (SELECT COUNT(cmp5.comp_componente)
           FROM Composicion cmp5
           WHERE cmp5.comp_producto = p.prod_codigo
          ) > 1 
    AND it5.item_producto = p.prod_codigo AND YEAR(f5.fact_fecha) = 2012) DESC



--------------------------- PARCIAL 28/07/2023 ---------------------------
/*1) 
Realizar una consulta SQL que devuelva todos los clientes que durante
2 años consecutivos compraron al menos 5 productos distintos. 

De esos clientes mostrar:
• El codigo de cliente
• El monto total comprado en el 2012
• La cantidad de unidades de productos compradas en el 2012

El resultado debe ser ordenado primero por aquellos clientes que compraron
solo productos compuestos en algun momento, luego el resto.

Nota: No se permiten select en el from, es decir, select from (select ...) as T ... */


SELECT  
	f.fact_cliente,
	(select sum(f2.fact_total)
	  from Factura f2
	  where f2.fact_cliente = f.fact_cliente and year(f2.fact_fecha) = 2012
	),
	(SELECT sum(it.item_cantidad) FROM item_factura it JOIN Factura f2 ON f2.item_numero+f2.item_sucursal+f2.item_tipo = it.item_numero+it.item_sucursal+it.item_tipo 
	WHERE f2.fact_cliente = f.fact_cliente AND year(f2.fact_fecha) = 2012)

FROM Factura f
where 5 >= (SELECT TOP 1 COUNT(DISTINCT IT2.ITEM_PRODUCTO) + COUNT(DISTINCT IT3.ITEM_PRODUCTO)
			FROM Factura f3
			JOIN Item_Factura it2 ON f3.item_numero+f3.item_sucursal+f3.item_tipo = it2.item_numero+it2.item_sucursal+IT2.item_tipo
			JOIN Factura f4 ON f4.fact_cliente = f3.fact_cliente
			JOIN Item_Factura it3 ON f4.item_numero+f4.item_sucursal+f4.item_tipo = it3.item_numero+it3.item_sucursal+IT3.item_tipo
			WHERE f3.fact_cliente = f.fact_cliente AND DATEDIFF(YEAR,F3.FACT_FECHA,F4.FACT_FECHA) = 1 AND it2.item_producto != it3.item_producto
			GROUP BY YEAR(F3.FACT_FECHA), YEAR(F4.FACT_FECHA)
			ORDER BY COUNT(DISTINCT IT2.ITEM_PRODUCTO) + COUNT(DISTINCT IT3.ITEM_PRODUCTO) DESC
           )
order by case when  (select f5.fact_cliente
					 from Factura f5
					 join Item_Factura it5 on f5.item_numero+f5.item_sucursal+f5.item_tipo = it5.item_numero+it5.item_sucursal+it5.item_tipo
					 join Producto p5 on it5.item_producto = p5.prod_codigo
					 join Composicion c5 on p5.prod_codigo = c5.comp_producto
					 )then 1 else 2

	


/*
SQL
Primer Parcial – Parte práctica – Profesor: Lacquaniti.

	•	Realizar una consulta SQL que retorne, para cada producto que no fue vendido en el 2012, la siguiente información:
	•	Detalle del producto.
	•	Rubro del producto.
	•	Cantidad de productos que tiene el rubro.
	•	Precio máximo de venta en toda la historia, sino tiene ventas en la historia, mostrar 0.
El resultado deberá mostrar primero aquellos productos que tienen composición.
Nota: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.*/






