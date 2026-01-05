/* =========================================================
   PROYECTO: Limpieza y normalización de ventas (SQL)
   BASE: MySQL 8+
   =========================================================
   Supuesto:
   - La tabla ventas_raw ya fue importada desde Excel
   - Columnas existentes:
     nro_operacion, fecha_operacion, cliente, provincia_cliente,
     producto, categoria_producto, cantidad_vendida,
     precio_unitario, canal_venta
   ========================================================= */


/* =========================================================
   PASO 1: Limpieza inicial y normalización de datos
   ========================================================= */

CREATE TABLE ventas_operativas_clean AS
SELECT
    UPPER(TRIM(nro_operacion)) AS nro_operacion,

    STR_TO_DATE(
        CASE
            WHEN fecha_operacion REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            THEN fecha_operacion
            ELSE NULL
        END,
        '%d/%m/%Y'
    ) AS fecha_operacion,

    LOWER(TRIM(cliente)) AS cliente,
    LOWER(TRIM(producto)) AS producto,
    LOWER(TRIM(categoria_producto)) AS categoria_producto,
    LOWER(TRIM(canal_venta)) AS canal_venta,

    CASE
        WHEN LOWER(TRIM(provincia_cliente)) IN ('baires', 'b aires', 'ba.', 'bs as')
        THEN 'buenos aires'
        ELSE LOWER(TRIM(provincia_cliente))
    END AS provincia_cliente,

    CASE
        WHEN cantidad_vendida > 0 THEN cantidad_vendida
        ELSE NULL
    END AS cantidad_vendida,

    CASE
        WHEN precio_unitario REGEXP '^[0-9]+(\\.[0-9]+)?$'
        THEN CAST(precio_unitario AS DECIMAL(10,2))
        ELSE NULL
    END AS precio_unitario

FROM ventas_raw
WHERE nro_operacion LIKE 'OP-%';


/* =========================================================
   PASO 2: Eliminación de duplicados
   Se conserva la fila con mayor cantidad de datos válidos
   ========================================================= */

CREATE TABLE ventas_operativas_final AS
SELECT *
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY nro_operacion
            ORDER BY
                (cantidad_vendida IS NOT NULL) +
                (precio_unitario IS NOT NULL) +
                (cliente IS NOT NULL) +
                (producto IS NOT NULL) +
                (categoria_producto IS NOT NULL) +
                (canal_venta IS NOT NULL) +
                (provincia_cliente IS NOT NULL) DESC
        ) AS fila_rank
    FROM ventas_operativas_clean
) t
WHERE fila_rank = 1;


/* =========================================================
   PASO 3: Normalización de campos vacíos a NULL
   ========================================================= */

/*
   Nota:
   Este UPDATE requiere que Safe Update Mode esté deshabilitado
   (SET SQL_SAFE_UPDATES = 0), ya que no utiliza cláusula WHERE.
*/


UPDATE ventas_operativas_final
SET
    cliente = NULLIF(TRIM(cliente), ''),
    producto = NULLIF(TRIM(producto), ''),
    categoria_producto = NULLIF(TRIM(categoria_producto), ''),
    canal_venta = NULLIF(TRIM(canal_venta), ''),
    provincia_cliente = NULLIF(TRIM(provincia_cliente), ''),
    nro_operacion = NULLIF(TRIM(nro_operacion), '');


/* =========================================================
   PASO 4: Valores estándar para NULL (lista para BI)
   ========================================================= */

UPDATE ventas_operativas_final
SET
    fecha_operacion = COALESCE(fecha_operacion, '1900-01-01'),
    cantidad_vendida = COALESCE(cantidad_vendida, 0),
    precio_unitario = COALESCE(precio_unitario, 0),
    cliente = COALESCE(cliente, 'Desconocido'),
    categoria_producto = COALESCE(categoria_producto, 'Desconocida');
