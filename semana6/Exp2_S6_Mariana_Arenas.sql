-- ============================================================
-- PRY2205 - Semana 6: Consulta de Bases de Datos
-- Estudiante: Mariana Arenas
-- ============================================================


-- #####################################################
-- CASO 1: RECAUDACIONES

CREATE TABLE RECAUDACION_BONOS_MEDICOS (
    RUT_MEDICO      VARCHAR2(15),
    NOMBRE_MEDICO   VARCHAR2(60),
    TOTAL_RECAUDADO NUMBER(10),
    UNIDAD_MEDICA   VARCHAR2(40)
);

-- Insertar datos en la tabla
INSERT INTO RECAUDACION_BONOS_MEDICOS (RUT_MEDICO, NOMBRE_MEDICO, TOTAL_RECAUDADO, UNIDAD_MEDICA)
SELECT
    TO_CHAR(m.rut_med, '99G999G999') || '-' || m.dv_run        "RUT_MÉDICO",
    INITCAP(m.pnombre) || ' ' ||
        INITCAP(m.apaterno) || ' ' ||
        INITCAP(m.amaterno)                                     "NOMBRE_MÉDICO",
    NVL(ROUND(SUM(bc.costo)), 0)                                "TOTAL_RECAUDADO",
    INITCAP(uc.nombre)                                          "UNIDAD_MEDICA"
FROM MEDICO m
JOIN BONO_CONSULTA bc
    ON bc.rut_med = m.rut_med
JOIN UNIDAD_CONSULTA uc
    ON uc.uni_id = m.uni_id
WHERE EXTRACT(YEAR FROM bc.fecha_bono) = EXTRACT(YEAR FROM SYSDATE) - 1
  AND m.car_id NOT IN (100, 500, 600)
GROUP BY
    m.rut_med,
    m.dv_run,
    m.pnombre,
    m.apaterno,
    m.amaterno,
    uc.nombre
ORDER BY "TOTAL_RECAUDADO" ASC;

COMMIT;

SELECT
    RUT_MEDICO,
    NOMBRE_MEDICO,
    TO_CHAR(TOTAL_RECAUDADO, '$999G999') "TOTAL_RECAUDADO",
    UNIDAD_MEDICA
FROM RECAUDACION_BONOS_MEDICOS;


-- #####################################################
-- CASO 2: PÉRDIDAS POR ESPECIALIDAD

SELECT
    UPPER(em.nombre)                                            "ESPECIALIDAD MEDICA",
    COUNT(bc.id_bono)                                           "CANTIDAD BONOS",
    TO_CHAR(ROUND(SUM(bc.costo)), '$999G999')                   "MONTO PÉRDIDA",
    TO_CHAR(MIN(bc.fecha_bono), 'DD-MM-YYYY')                   "FECHA BONO",
    CASE
        WHEN EXTRACT(YEAR FROM MIN(bc.fecha_bono)) >= EXTRACT(YEAR FROM SYSDATE) - 1
        THEN 'COBRABLE'
        ELSE 'INCOBRABLE'
    END                                                         "ESTADO DE COBRO"
FROM BONO_CONSULTA bc
JOIN DET_ESPECIALIDAD_MED dem
    ON dem.rut_med = bc.rut_med
JOIN ESPECIALIDAD_MEDICA em
    ON em.esp_id = dem.esp_id
WHERE bc.id_bono IN (
    SELECT id_bono FROM BONO_CONSULTA
    MINUS
    SELECT id_bono FROM PAGOS
)
GROUP BY
    em.nombre
ORDER BY
    COUNT(bc.id_bono) ASC,
    ROUND(SUM(bc.costo)) DESC;


-- #####################################################
-- CASO 3: PROYECCIÓN PRESUPUESTARIA

INSERT INTO CANT_BONOS_PACIENTES_ANNIO (
    ANNIO_CALCULO,
    PAC_RUN,
    DV_RUN,
    EDAD,
    CANTIDAD_BONOS,
    MONTO_TOTAL_BONOS,
    SISTEMA_SALUD
)

SELECT
    EXTRACT(YEAR FROM SYSDATE)                                          "ANNIO_CALCULO",
    p.pac_run                                                           "PAC_RUN",
    p.dv_run                                                            "DV_RUN",
    ROUND(MONTHS_BETWEEN(SYSDATE, p.fecha_nacimiento) / 12)             "EDAD",
    NVL(COUNT(bc.id_bono), 0)                                           "CANTIDAD_BONOS",
    NVL(ROUND(SUM(bc.costo)), 0)                                        "MONTO_TOTAL_BONOS",
    UPPER(ss.descripcion)                                               "SISTEMA_SALUD"
FROM PACIENTE p
JOIN SALUD sal
    ON sal.sal_id = p.sal_id
JOIN SISTEMA_SALUD ss
    ON ss.tipo_sal_id = sal.tipo_sal_id
LEFT JOIN BONO_CONSULTA bc
    ON  bc.pac_run = p.pac_run
    AND EXTRACT(YEAR FROM bc.fecha_bono) = EXTRACT(YEAR FROM SYSDATE) - 1
WHERE ss.tipo_sal_id IN ('FON', 'PAR', 'FAR')
GROUP BY
    p.pac_run,
    p.dv_run,
    p.fecha_nacimiento,
    ss.descripcion
HAVING
    NVL(COUNT(bc.id_bono), 0) <= (
        SELECT ROUND(AVG(total_bonos_paciente))
        FROM (
            SELECT COUNT(id_bono) AS total_bonos_paciente
            FROM BONO_CONSULTA
            WHERE EXTRACT(YEAR FROM fecha_bono) = EXTRACT(YEAR FROM SYSDATE) - 1
            GROUP BY pac_run
        )
    );

COMMIT;

-- Verificar resultado final
SELECT
    ANNIO_CALCULO,
    PAC_RUN || '-' || DV_RUN                                     "RUN_PACIENTE",
    EDAD,
    CANTIDAD_BONOS,
    TO_CHAR(MONTO_TOTAL_BONOS, '$999G999G999')                   "MONTO_TOTAL_BONOS",
    SISTEMA_SALUD
FROM CANT_BONOS_PACIENTES_ANNIO
ORDER BY
    MONTO_TOTAL_BONOS ASC,
    EDAD DESC;