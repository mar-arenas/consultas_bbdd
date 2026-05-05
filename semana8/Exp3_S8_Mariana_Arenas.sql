-- ============================================================
-- PRY2205 - Semana 8: Consulta de Bases de Datos
-- Estudiante: Mariana Arenas
-- ============================================================

-- ############################################################
-- CASO 1: ESTRATEGIA DE SEGURIDAD
-- Ejecutar como ADMIN (Oracle Cloud)
-- ############################################################

-- Crear roles
CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_P;

-- Crear usuarios 
CREATE USER PRY2205_USER1 IDENTIFIED BY "C0ntrasenaUser1#2026"
    DEFAULT TABLESPACE DATA
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON DATA;

CREATE USER PRY2205_USER2 IDENTIFIED BY "C0ntrasenaUser2#2026"
    DEFAULT TABLESPACE DATA
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON DATA;

-- Privilegios de sistema para USER1 a traves de rol
GRANT CREATE TABLE, CREATE INDEX, CREATE VIEW, CREATE SYNONYM
TO PRY2205_ROL_D;

-- Privilegios de sistema directos para USER1
GRANT CREATE SESSION TO PRY2205_USER1;
GRANT CREATE PUBLIC SYNONYM TO PRY2205_USER1;

-- Privilegios de sistema directos para USER2
GRANT CREATE SESSION, CREATE VIEW, CREATE PROFILE, CREATE USER
TO PRY2205_USER2;

-- Privilegios de sistema para USER2 a traves de rol
GRANT CREATE SYNONYM TO PRY2205_ROL_P;

-- Asignar roles por defecto
GRANT PRY2205_ROL_D TO PRY2205_USER1;
ALTER USER PRY2205_USER1 DEFAULT ROLE ALL;

GRANT PRY2205_ROL_P TO PRY2205_USER2;
ALTER USER PRY2205_USER2 DEFAULT ROLE ALL;

-- Otorgar privilegios de objetos necesarios al rol PRY2205_ROL_P
-- (tablas del esquema PRY2205_USER1 usadas por la vista del CASO 2)
GRANT SELECT ON PRY2205_USER1.BONO_CONSULTA TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.PACIENTE TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.SALUD TO PRY2205_ROL_P;
GRANT SELECT ON PRY2205_USER1.SISTEMA_SALUD TO PRY2205_ROL_P;

-- ############################################################
-- CASO 1: SINONIMOS
-- Ejecutar como PRY2205_USER1
-- ############################################################

-- Sinonimos privados para uso interno (USER1)
CREATE SYNONYM MED FOR MEDICO;
CREATE SYNONYM CAR FOR CARGO;
CREATE SYNONYM UNI_CONS FOR UNIDAD_CONSULTA;

-- Sinonimos publicos para consumo de USER2 (requerido en la definición del caso)
-- Nota: en Autonomous Database este privilegio puede estar restringido, tuve problemas al ejecutarlo,
-- y tuve que usar synonymos privados para el caso 2, pero dejo la sintaxis correcta para crear sinonimos publicos
CREATE PUBLIC SYNONYM BN_CONS FOR PRY2205_USER1.BONO_CONSULTA;
CREATE PUBLIC SYNONYM PAC FOR PRY2205_USER1.PACIENTE;
CREATE PUBLIC SYNONYM SAL FOR PRY2205_USER1.SALUD;
CREATE PUBLIC SYNONYM SIS_SAL FOR PRY2205_USER1.SISTEMA_SALUD;


-- ############################################################
-- CASO 2: CREACION DE VISTA (VW_RECALCULO_COSTOS)
-- Ejecutar como PRY2205_USER2
-- ############################################################

CREATE OR REPLACE VIEW VW_RECALCULO_COSTOS AS
SELECT
    bc.id_bono                                                        AS "ID_BONO",
    TO_CHAR(p.pac_run, '99G999G999') || '-' || p.dv_run               AS "RUT_PACIENTE",
    INITCAP(p.pnombre) || ' ' || INITCAP(p.apaterno) || ' ' ||
        INITCAP(p.amaterno)                                           AS "NOMBRE_PACIENTE",
    UPPER(ss.descripcion)                                             AS "SISTEMA_SALUD",
    TO_CHAR(ROUND(NVL(bc.costo, 0)), '999G999G999')                   AS "COSTO",
    TO_CHAR(TO_DATE(bc.hr_consulta, 'HH24:MI'), 'HH24:MI')            AS "HORARIO_ATENCION",
    TO_CHAR(bc.fecha_bono, 'DD-MM-YYYY')                              AS "FECHA_CONSULTA",
    TO_CHAR(
        CASE
            WHEN bc.costo BETWEEN 15000 AND 25000
                THEN ROUND(bc.costo * 1.15)
            WHEN bc.costo > 25000
                THEN ROUND(bc.costo * 1.20)
            ELSE ROUND(bc.costo)
        END,
        '999G999G999'
    )                                                                 AS "REAJUSTE"
FROM BN_CONS bc
JOIN PAC p
    ON p.pac_run = bc.pac_run
JOIN SAL sal
    ON sal.sal_id = p.sal_id
JOIN SIS_SAL ss
    ON ss.tipo_sal_id = sal.tipo_sal_id
WHERE EXTRACT(YEAR FROM bc.fecha_bono) = EXTRACT(YEAR FROM SYSDATE) - 1
  AND TO_DATE(bc.hr_consulta, 'HH24:MI') > TO_DATE('17:15', 'HH24:MI')
  AND sal.tipo_sal_id IN (
      SELECT tipo_sal_id
      FROM SIS_SAL
      WHERE descripcion IN ('ISAPRE', 'FONASA')
    );

-- Consulta del informe con el orden requerido
SELECT *
FROM VW_RECALCULO_COSTOS
ORDER BY
        "FECHA_CONSULTA" ASC,
        "RUT_PACIENTE" ASC;

-- ############################################################
-- CASO 3.1: CREACION DE VISTA (VW_AUM_MEDICO_X_CARGO)
-- Ejecutar como PRY2205_USER1
-- ############################################################

CREATE OR REPLACE VIEW VW_AUM_MEDICO_X_CARGO AS
SELECT
    TO_CHAR(m.rut_med, '99G999G999') || '-' || m.dv_run               AS "RUT_MEDICO",
    INITCAP(c.nombre)                                                 AS "CARGO",
    ROUND(m.sueldo_base)                                              AS "SUELDO_ACTUAL",
    ROUND(m.sueldo_base * 1.15)                                       AS "SUELDO_AUMENTADO",
    CASE
        WHEN ROUND(MONTHS_BETWEEN(SYSDATE, m.fecha_contrato) / 12) >= 10
            THEN 'ALTA'
        WHEN ROUND(MONTHS_BETWEEN(SYSDATE, m.fecha_contrato) / 12) BETWEEN 5 AND 9
            THEN 'MEDIA'
        ELSE 'BAJA'
    END                                                               AS "ANTIGUEDAD"
FROM MED m
JOIN CAR c
    ON c.car_id = m.car_id
JOIN UNI_CONS u
    ON u.uni_id = m.uni_id
WHERE UPPER(c.nombre) LIKE '%ATENC%'
;

-- Consulta de verificacion con orden requerido
SELECT *
FROM VW_AUM_MEDICO_X_CARGO
ORDER BY
    "SUELDO_AUMENTADO" DESC;

-- ############################################################
-- CASO 3.2: PLAN E INDICES PARA OPTIMIZACION
-- Ejecutar como PRY2205_USER1
-- ############################################################

-- Plan de ejecucion (antes)
EXPLAIN PLAN FOR
SELECT * FROM VW_AUM_MEDICO_X_CARGO;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Indices propuestos para mejorar accesos y joins
CREATE INDEX IDX_MEDICO_CAR_ID ON MEDICO (car_id);
CREATE INDEX IDX_CARGO_NOMBRE_UP ON CARGO (UPPER(nombre));

-- Plan de ejecucion (despues)
EXPLAIN PLAN FOR
SELECT * FROM VW_AUM_MEDICO_X_CARGO;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
