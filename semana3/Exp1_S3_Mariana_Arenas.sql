-- CASO 1: ANÁLISIS DE PROPIEDADES
-- Se muestra un informe comercial que analiza el valor de arriendo y los gastos comunes.
SELECT
    p.nro_propiedad AS "NRO PROPIEDAD",
    p.direccion_propiedad AS "DIRECCION",
    c.nombre_comuna AS "COMUNA",
    p.nro_dormitorios AS "NRO DORMITORIOS",
    TO_CHAR(p.valor_arriendo, 'L9G999G999') AS "VALOR ARRIENDO",
    TO_CHAR(p.valor_gasto_comun, 'L9G999G999') AS "VALOR GASTO COMUN",
    TO_CHAR(ROUND(p.valor_gasto_comun * 1.1), 'L9G999G999') AS "NUEVO GASTO COMUN"
FROM
    propiedad p
JOIN
    comuna c ON p.id_comuna = c.id_comuna
WHERE
    p.valor_arriendo < &VALOR_MAXIMO
    AND p.nro_dormitorios IS NOT NULL
    AND p.id_comuna IN (82, 84, 87)
ORDER BY
    p.valor_gasto_comun ASC NULLS LAST,
    p.valor_arriendo DESC;

-- CASO 2: ANÁLISIS DE ANTIGÜEDAD DE ARRIENDO
-- Informe para identificar propiedades arrendadas durante un período, mostrando la antigüedad y una clasificación.
SELECT
    p.nro_propiedad AS "NRO PROPIEDAD",
    p.direccion_propiedad AS "DIRECCION",
    TO_CHAR(ap.fecini_arriendo, 'DD "de" Month "de" YYYY') AS "FECHA INICIO",
    NVL(TO_CHAR(ap.fecter_arriendo, 'DD "de" Month "de" YYYY'), 'Propiedad Actualmente Arrendada') AS "FECHA TERMINO",
    ROUND(NVL(ap.fecter_arriendo, SYSDATE) - ap.fecini_arriendo) AS "DIAS ARRENDADOS",
    TRUNC(MONTHS_BETWEEN(NVL(ap.fecter_arriendo, SYSDATE), ap.fecini_arriendo) / 12) AS "AÑOS ARRIENDO",
    CASE
        WHEN TRUNC(MONTHS_BETWEEN(NVL(ap.fecter_arriendo, SYSDATE), ap.fecini_arriendo) / 12) >= 10 THEN 'COMPROMISO DE VENTA'
        WHEN TRUNC(MONTHS_BETWEEN(NVL(ap.fecter_arriendo, SYSDATE), ap.fecini_arriendo) / 12) BETWEEN 5 AND 9 THEN 'CLIENTE ANTIGUO'
        ELSE 'CLIENTE NUEVO'
    END AS "CLASIFICACION"
FROM
    arriendo_propiedad ap
JOIN
    propiedad p ON ap.nro_propiedad = p.nro_propiedad
WHERE
    ROUND(NVL(ap.fecter_arriendo, SYSDATE) - ap.fecini_arriendo) > &DIAS_ARRIENDO
ORDER BY
    "DIAS ARRENDADOS" DESC;

-- CASO 3: ARRIENDO PROMEDIO POR TIPO DE PROPIEDAD
-- Informe que muestra el promedio de valores de arriendo y gastos comunes, agrupados por tipo de propiedad.
SELECT
    tp.desc_tipo_propiedad AS "TIPO PROPIEDAD",
    TO_CHAR(ROUND(AVG(p.valor_gasto_comun)), 'L9G999G999') AS "PROMEDIO GASTO COMUN",
    TO_CHAR(ROUND(AVG(p.valor_arriendo)), 'L9G999G999') AS "PROMEDIO ARRIENDO",
    COUNT(p.nro_propiedad) AS "CANTIDAD PROPIEDADES"
FROM
    propiedad p
JOIN
    tipo_propiedad tp ON p.id_tipo_propiedad = tp.id_tipo_propiedad
GROUP BY
    tp.desc_tipo_propiedad
HAVING
    AVG(p.valor_arriendo) > &PROMEDIO_ARRIENDO_MINIMO
ORDER BY
    "TIPO PROPIEDAD" ASC,
    "PROMEDIO ARRIENDO" DESC;
