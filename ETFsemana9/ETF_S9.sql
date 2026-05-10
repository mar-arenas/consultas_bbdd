-- ============================================================
-- PRY2205 - EVALUACIÓN FINAL TRANSVERSAL (EFT)
-- SEMANA 9: CONSULTA DE BASES DE DATOS
-- Estudiante: Mariana Arenas
-- Fecha: 10/05/2026
--
-- INSTRUCCIONES DE EJECUCIÓN:
-- 1. Ejecutar CASO 1 como ADMIN/SYS
-- 2. Ejecutar SINÓNIMOS como PRY2205_EFT
-- 3. Ejecutar CASO 2 como PRY2205_EFT_DES
-- 4. Ejecutar CASO 3.1 y 3.2 como PRY2205_EFT
-- ============================================================

ALTER SESSION SET NLS_DATE_FORMAT='DD/MM/YYYY';

-- ############################################################
-- CASO 1: ESTRATEGIA DE SEGURIDAD - USUARIOS Y ROLES
-- USUARIO: ADMIN (Oracle Cloud) o SYS/SYSTEM (Oracle XE)
-- ############################################################

-- ---- Paso 1.1: Crear Roles ----
CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_C;

-- ---- Paso 1.2: Crear Usuarios con Contraseñas Seguras ----
-- Contraseñas cumplen: 12+ chars, 1 minúscula, 2 mayúsculas, 2 números, SIN nombre usuario

CREATE USER PRY2205_EFT IDENTIFIED BY "MarianaN123EFT2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA 10M ON USERS;

CREATE USER PRY2205_EFT_DES IDENTIFIED BY "DesarrolloE456FT2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA 10M ON USERS;

CREATE USER PRY2205_EFT_CON IDENTIFIED BY "ConsultorA789FT2026"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA 10M ON USERS;

-- ---- Paso 1.3: Asignar Privilegios de Sistema ----

-- Privilegios para PRY2205_EFT (owner del esquema)
GRANT CREATE SESSION TO PRY2205_EFT;
GRANT CREATE TABLE TO PRY2205_EFT;
GRANT CREATE VIEW TO PRY2205_EFT;
GRANT CREATE SEQUENCE TO PRY2205_EFT;
GRANT CREATE PUBLIC SYNONYM TO PRY2205_EFT;
GRANT ALTER SESSION TO PRY2205_EFT;

-- Privilegios para PRY2205_EFT_DES (via rol PRY2205_ROL_D)
GRANT CREATE SESSION TO PRY2205_EFT_DES;
GRANT CREATE VIEW TO PRY2205_EFT_DES;
GRANT CREATE SEQUENCE TO PRY2205_ROL_D;
GRANT CREATE PROCEDURE TO PRY2205_ROL_D;
GRANT CREATE VIEW TO PRY2205_ROL_D;

-- Privilegios para PRY2205_EFT_CON (via rol PRY2205_ROL_C)
GRANT CREATE SESSION TO PRY2205_EFT_CON;

-- Asignar roles a usuarios
GRANT PRY2205_ROL_D TO PRY2205_EFT_DES;
GRANT PRY2205_ROL_C TO PRY2205_EFT_CON;

ALTER USER PRY2205_EFT_DES DEFAULT ROLE ALL;
ALTER USER PRY2205_EFT_CON DEFAULT ROLE ALL;

COMMIT;

-- ############################################################
-- CASO 1: SINÓNIMOS PÚBLICOS
-- USUARIO: PRY2205_EFT
-- ############################################################

-- Crear sinónimos públicos para tablas principales
CREATE OR REPLACE PUBLIC SYNONYM SYN_DEUDOR FOR DEUDOR;
CREATE OR REPLACE PUBLIC SYNONYM SYN_TARJETA_DEUDOR FOR TARJETA_DEUDOR;
CREATE OR REPLACE PUBLIC SYNONYM SYN_CUOTA_TARJETAS FOR CUOTA_TARJETAS;
CREATE OR REPLACE PUBLIC SYNONYM SYN_OCUPACION FOR OCUPACION;
CREATE OR REPLACE PUBLIC SYNONYM SYN_SUCURSAL FOR SUCURSAL;
CREATE OR REPLACE PUBLIC SYNONYM SYN_TRANSACCION_TARJETA FOR TRANSACCION_TARJETA_DEUDOR;
CREATE OR REPLACE PUBLIC SYNONYM SYN_PAGOS_DEUDA FOR PAGOS_DEUDA;
CREATE OR REPLACE PUBLIC SYNONYM SYN_FORMA_PAGO FOR FORMA_PAGO;
CREATE OR REPLACE PUBLIC SYNONYM SYN_REGION FOR REGION;
CREATE OR REPLACE PUBLIC SYNONYM SYN_PROVINCIA FOR PROVINCIA;
CREATE OR REPLACE PUBLIC SYNONYM SYN_COMUNA FOR COMUNA;

-- ---- Paso 1.5: Asignar Privilegios de Objetos a Roles ----

-- Privilegios para PRY2205_ROL_D (PRY2205_EFT_DES)
-- Permitir SELECT en tablas principales para análisis
GRANT SELECT ON DEUDOR TO PRY2205_ROL_D;
GRANT SELECT ON TARJETA_DEUDOR TO PRY2205_ROL_D;
GRANT SELECT ON CUOTA_TARJETAS TO PRY2205_ROL_D;
GRANT SELECT ON OCUPACION TO PRY2205_ROL_D;
GRANT SELECT ON PAGOS_DEUDA TO PRY2205_ROL_D;
GRANT SELECT ON SUCURSAL TO PRY2205_ROL_D;
GRANT SELECT ON TRANSACCION_TARJETA_DEUDOR TO PRY2205_ROL_D;

-- Privilegios para PRY2205_ROL_C (PRY2205_EFT_CON)
GRANT SELECT ON DEUDOR TO PRY2205_ROL_C;
GRANT SELECT ON TARJETA_DEUDOR TO PRY2205_ROL_C;
GRANT SELECT ON CUOTA_TARJETAS TO PRY2205_ROL_C;
GRANT SELECT ON OCUPACION TO PRY2205_ROL_C;
GRANT SELECT ON PAGOS_DEUDA TO PRY2205_ROL_C;

-- Privilegios para objetos específicos
GRANT SELECT ON DEUDOR TO PRY2205_EFT_DES WITH GRANT OPTION;
GRANT SELECT ON TARJETA_DEUDOR TO PRY2205_EFT_DES WITH GRANT OPTION;
GRANT SELECT ON CUOTA_TARJETAS TO PRY2205_EFT_DES WITH GRANT OPTION;
GRANT SELECT ON OCUPACION TO PRY2205_EFT_DES WITH GRANT OPTION;

COMMIT;

-- ############################################################
-- CASO 2: CREACIÓN DE VISTA ANALÍTICA
-- USUARIO: PRY2205_EFT_DES
-- ############################################################

CREATE OR REPLACE VIEW VW_ANALISIS_DEUDORES_PERIODO AS
SELECT
    LPAD(d.numrun, 8, '0') || '-' || d.dvrun AS RUT_DEUDOR,
    INITCAP(d.pnombre) || ' ' || INITCAP(d.appaterno) || ' ' || 
    CASE WHEN d.apmaterno IS NOT NULL THEN INITCAP(d.apmaterno) ELSE '' END AS NOMBRE_DEUDOR,
    COUNT(c.nro_cuota) AS TOTAL_CUOTAS,
    ROUND(AVG(c.valor_cuota)) AS PROMEDIO_VALOR_CUOTAS,
    TO_CHAR(MIN(c.fecha_venc_cuota), 'DD/MM/YYYY') AS FECHA_MAS_ANTIGUA,
    NVL(TO_CHAR(d.fono_contacto), 'Sin Información') AS TELEFONO,
    UPPER(o.nombre_prof_ofic) AS OCUPACION,
    t.cupo_disp_compra AS CUPO_DISP_COMPRA

FROM SYN_DEUDOR d
JOIN SYN_TARJETA_DEUDOR t ON d.numrun = t.numrun
JOIN SYN_CUOTA_TARJETAS c ON t.nro_tarjeta = c.nro_tarjeta
JOIN SYN_OCUPACION o ON d.cod_ocupacion = o.cod_ocupacion

WHERE
    UPPER(o.nombre_prof_ofic) NOT LIKE 'INGENIERO%'
    AND EXTRACT(YEAR FROM c.fecha_venc_cuota) = EXTRACT(YEAR FROM SYSDATE) - 1

GROUP BY
    d.numrun, d.dvrun, d.pnombre, d.appaterno, d.apmaterno, 
    d.fono_contacto, o.nombre_prof_ofic, t.cupo_disp_compra

HAVING
    AVG(c.valor_cuota) < (
        SELECT MAX(promedio_tarjeta)
        FROM (
            SELECT AVG(valor_cuota) AS promedio_tarjeta
            FROM SYN_CUOTA_TARJETAS
            GROUP BY nro_tarjeta
        )
    );
    

-- OTORGAR PERMISOS SOBRE LA VISTA
GRANT SELECT ON VW_ANALISIS_DEUDORES_PERIODO TO PRY2205_EFT_CON;

COMMIT;

-- Consultar datos con usuario PRY2205_EFT_CON

SELECT *
FROM VW_ANALISIS_DEUDORES_PERIODO
ORDER BY TOTAL_CUOTAS ASC, CUPO_DISP_COMPRA ASC;

-- ############################################################
-- CASO 3.1: POPULATE TABLE T_ANALISIS_TARJETAS
-- USUARIO: PRY2205_EFT
-- ############################################################

INSERT INTO T_ANALISIS_TARJETAS
SELECT
    SEQ_T_ANALISIS.NEXTVAL AS NUM_ANALISIS,
    trd.nro_tarjeta,
    (SELECT COUNT(*) FROM SYN_CUOTA_TARJETAS WHERE nro_tarjeta = trd.nro_tarjeta) AS TOTAL_CUOTAS,
    trd.monto_total_transaccion,
    trd.fecha_transaccion,
    INITCAP(s.direccion) AS DIRECCION,
    CASE
        WHEN trd.monto_total_transaccion BETWEEN 200000 AND 300000
            THEN ROUND(trd.monto_total_transaccion * 1.05)
        WHEN trd.monto_total_transaccion BETWEEN 300001 AND 500000
            THEN ROUND(trd.monto_total_transaccion * 1.07)
        ELSE ROUND(trd.monto_total_transaccion)
    END AS MONTO_REAJUSTADO

FROM SYN_TRANSACCION_TARJETA trd
JOIN SYN_TARJETA_DEUDOR t ON trd.nro_tarjeta = t.nro_tarjeta
JOIN SYN_SUCURSAL s ON trd.id_sucursal = s.id_sucursal

WHERE
    SUBSTR(s.direccion, 1, 1) = 'A'
    AND trd.monto_total_transaccion >= 200000;

GRANT SELECT ON T_ANALISIS_TARJETAS TO PRY2205_EFT_CON;

COMMIT;
-- Consultar datos con usuario PRY2205_EFT_CON

SELECT *
FROM PRY2205_EFT.T_ANALISIS_TARJETAS
ORDER BY nro_tarjeta ASC, monto_reajustado DESC;

-- ############################################################
-- CASO 3.2: OPTIMIZACIÓN - ANÁLISIS DE PLAN DE EJECUCIÓN
-- USUARIO: PRY2205_EFT
-- ############################################################

-- ---- EXPLICAR PLAN ANTES DE CREAR ÍNDICES ----

EXPLAIN PLAN FOR
SELECT
    trd.nro_tarjeta,
    (SELECT COUNT(*) FROM SYN_CUOTA_TARJETAS WHERE nro_tarjeta = trd.nro_tarjeta) AS TOTAL_CUOTAS,
    trd.monto_total_transaccion,
    trd.fecha_transaccion,
    INITCAP(s.direccion) AS DIRECCION,
    CASE
        WHEN trd.monto_total_transaccion BETWEEN 200000 AND 300000
            THEN ROUND(trd.monto_total_transaccion * 1.05)
        WHEN trd.monto_total_transaccion BETWEEN 300001 AND 500000
            THEN ROUND(trd.monto_total_transaccion * 1.07)
        ELSE ROUND(trd.monto_total_transaccion)
    END AS MONTO_REAJUSTADO
FROM SYN_TRANSACCION_TARJETA trd
JOIN SYN_TARJETA_DEUDOR t ON trd.nro_tarjeta = t.nro_tarjeta
JOIN SYN_SUCURSAL s ON trd.id_sucursal = s.id_sucursal
WHERE
    SUBSTR(s.direccion, 1, 1) = 'A'
    AND trd.monto_total_transaccion >= 200000
ORDER BY
    trd.nro_tarjeta ASC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- ---- CREAR ÍNDICES PARA OPTIMIZACIÓN ----

CREATE INDEX IDX_TTD_NRO_TARJETA 
    ON TRANSACCION_TARJETA_DEUDOR(nro_tarjeta);

CREATE INDEX IDX_TTD_ID_SUCURSAL 
    ON TRANSACCION_TARJETA_DEUDOR(id_sucursal);

CREATE INDEX IDX_TTD_MONTO_TOTAL 
    ON TRANSACCION_TARJETA_DEUDOR(monto_total_transaccion);

COMMIT;
-- ---- EXPLICAR PLAN DESPUÉS DE CREAR ÍNDICES ----

EXPLAIN PLAN FOR
SELECT
    trd.nro_tarjeta,
    (SELECT COUNT(*) FROM SYN_CUOTA_TARJETAS WHERE nro_tarjeta = trd.nro_tarjeta) AS total_cuotas,
    trd.monto_total_transaccion,
    trd.fecha_transaccion,
    INITCAP(s.direccion) AS direccion,
    CASE
        WHEN trd.monto_total_transaccion BETWEEN 200000 AND 300000
            THEN ROUND(trd.monto_total_transaccion * 1.05)
        WHEN trd.monto_total_transaccion BETWEEN 300001 AND 500000
            THEN ROUND(trd.monto_total_transaccion * 1.07)
        ELSE ROUND(trd.monto_total_transaccion)
    END AS monto_reajustado
FROM SYN_TRANSACCION_TARJETA trd
JOIN SYN_TARJETA_DEUDOR t ON trd.nro_tarjeta = t.nro_tarjeta
JOIN SYN_SUCURSAL s ON trd.id_sucursal = s.id_sucursal
WHERE
    SUBSTR(s.direccion, 1, 1) = 'A'
    AND trd.monto_total_transaccion >= 200000
ORDER BY
    trd.nro_tarjeta ASC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

COMMIT;

-- ############################################################
-- FIN DEL SCRIPT
-- ############################################################