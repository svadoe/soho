
EXEC calcular_deudas 'COM', 0
SELECT * FROM wf_print_out WHERE pto_proceso = 'calcdeuda' ORDER BY 2 
DELETE FROM wf_print_out WHERE pto_proceso = 'calcdeuda' ORDER BY 2 
SELECT * FROM sys.procedures
GO

[--
EXEC calcular_deudas 'COM', 0

CREATE PROCEDURE calcular_deudas (
  @cat_nombre_corto VARCHAR(20),
  @v_cod_ret        INT OUT
) AS

  /*
    20200413 sergio vado espinoza: Proyecto de optimización de procesos
                   
    calcular_deudas: - calcula deudas a nivel de cuentas y de personas.
                     - recibe como parametro el nombre corto de la catera y un código de error 

    Procedure que calcula las deudas de los clientes a nivel de producto y de persona.
    Los resultados se guardan en dos tablas que se llenan cada vez que se ejecuta este
    procedure.  Las tablas son: cueta_deuda para las deudas a nivel de cuenta y
    persona_deuda para la deuda a nivel de persona.

    Las deudas calculadas se pasan e insertan en las tablas en moneda peso.
  */


  /* Inicia drop de tablas e indices */ 
  IF EXISTS(SELECT * FROM sys.indexes WHERE name='idx_cuenta_deuda_per' AND object_id = OBJECT_ID('dbo.cuenta_deuda'))
    DROP INDEX idx_cuenta_deuda_per ON cuenta_deuda
  
  IF EXISTS(SELECT * FROM sys.tables WHERE name='cuenta_deuda' AND object_id = OBJECT_ID('dbo.cuenta_deuda'))
    DROP TABLE cuenta_deuda
  
  IF EXISTS(SELECT * FROM sys.tables WHERE name='persona_deuda' AND object_id = OBJECT_ID('dbo.persona_deuda'))
    DROP TABLE persona_deuda
  /* Fin drop de tablas e indices */ 
  

  /* Inicia calculo de deuda a nivel de cuentas */
  CREATE TABLE cuenta_deuda (
    cta_id           INTEGER PRIMARY KEY,
    cta_per          INTEGER NOT NULL,
    cta_deuda_total  NUMERIC (16, 2),
    cta_deuda_venc   NUMERIC (16,2),
    cta_deuda_a_venc NUMERIC (16,2)
  )
  
  DECLARE @cat_id INTEGER = (SELECT cat_id FROM carteras WHERE cat_nombre_corto = @cat_nombre_corto AND cat_baja_fecha IS NULL)
  
  INSERT INTO
    cuenta_deuda
  SELECT
    cta_id,
    cta_per,
    COALESCE(dbo.emx_f_pasar_a_moneda_pais(cta_deuda_venc + CASE WHEN cta_deuda_a_venc > 0 THEN cta_deuda_a_venc ELSE 0 END, cta_mon),0),
    COALESCE(dbo.emx_f_pasar_a_moneda_pais(cta_deuda_venc,cta_mon),0),
    COALESCE(dbo.emx_f_pasar_a_moneda_pais((CASE WHEN cta_deuda_a_venc > 0 THEN cta_deuda_a_venc ELSE 0 END),cta_mon),0)
  FROM
    cuentas
  WHERE 
    cta_cat = @cat_id AND cta_baja_fecha IS NULL
  
  CREATE INDEX idx_cuenta_deuda_per ON cuenta_deuda (cta_per)
  /* Fin calculo de deuda a nivel de cuentas */


  /* Inicia calculo de deuda a nivel de personas */
  CREATE TABLE persona_deuda (
    per_id           INTEGER PRIMARY KEY,
    per_deuda_total  NUMERIC (16, 2),
    per_deuda_venc   NUMERIC (16,2),
    per_deuda_a_venc NUMERIC (16,2)
  )
  
  INSERT INTO
    persona_deuda
  SELECT
    cta_per,
    SUM(cta_deuda_total)  AS cta_deuda_total,
    SUM(cta_deuda_venc)   AS cta_deuda_venc,
    SUM(cta_deuda_a_venc) AS cta_deuda_a_venc
  FROM
    cuenta_deuda
  GROUP BY
    cta_per
  /* Fin calculo de deuda a nivel de personas */


  SELECT @v_cod_ret = @@error
  /* Fin */
GO

--]

sp_helptext acc_cartas_insert

SELECT COUNT(*) FROM persona_deuda
INSERT INTO
  persona_deuda
SELECT
  cta_per,
  COALESCE(SUM(dbo.emx_f_pasar_a_moneda_pais(cta_deuda_venc + CASE WHEN cta_deuda_a_venc > 0 THEN cta_deuda_a_venc ELSE 0 END, cta_mon)),0),
  COALESCE(SUM(dbo.emx_f_pasar_a_moneda_pais(cta_deuda_venc,cuentas.cta_mon)),0),
  COALESCE(SUM(dbo.emx_f_pasar_a_moneda_pais(CASE WHEN cta_deuda_a_venc > 0 THEN cta_deuda_a_venc ELSE 0 END,cuentas.cta_mon)),0)
FROM
  cuentas
WHERE 
  cta_cat = 2 AND cta_baja_fecha IS NULL
GROUP BY
  cta_per

SELECT * FROM persona_deuda ORDER BY 1,2





  SELECT * FROM carteras

SELECT * FROM persona_deuda
SELECT * FROM persona_deuda

SET STATISTICS TIME ON
SELECT 
  cta_per,
  SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc+case when cuentas.cta_deuda_a_venc>0 then cuentas.cta_deuda_a_venc else 0 end,cuentas.cta_mon))
FROM
  cuentas
WHERE cuentas.cta_baja_fecha IS NULL
GROUP BY cta_per

cuentas
SELECT cta_per, SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc+case when cuentas.cta_deuda_a_venc>0 then cuentas.cta_deuda_a_venc else 0 end,cuentas.cta_mon)) FROM cuentas WHERE cta_id IN (37181,84740,203829,1808732) GROUP BY cta_per

SELECT * FROM persona_deuda WHERE per_id IN (120723, 480658)
SELECT * FROM persona_deuda WHERE per_id IN (40392, 161254)

SELECT cta_per FROM cuentas WHERE cta_id IN (1841, 2612)


SELECT * FROM wf_dic_datos

SET STATISTICS TIME ON
SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =2 AND sob_etg = 2     AND sob_est = 4     AND (sob_fec_susp IS NULL OR sob_fec_susp <= '20200401') AND (cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  '20200401') AND esc_susp = 'N' AND est_inactivo = 'N' AND (isnull((datediff(dd,ISNULL((SELECT MIN(a.cta_fec_vto) FROM cuentas a WHERE a.cta_per=wf_vw_dic_datos.cta_per AND a.cta_fec_vto IS NOT NULL AND a.cta_baja_fecha IS NULL),par_fec_proceso),par_fec_proceso)), 0))  >  10 AND (SELECT per_deuda FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per)  >  CONVERT(Decimal(9,2),'500.00') AND (isnull((select case count (*) when 0 then 'NO' else 'SI' end from personas a inner join per_tel b on a.per_id = b.pte_per where b.pte_baja_fecha is null and wf_vw_dic_datos.cta_per = a.per_id), 'N'))  =  'SI' AND  (SELECT per_deuda FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per) >  CONVERT(Decimal(9,2),'50.00')                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      

SET STATISTICS TIME ON
SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =2 AND sob_etg = 2     AND sob_est = 4     AND (sob_fec_susp IS NULL OR sob_fec_susp <= '20200401') AND (cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  '20200401') AND esc_susp = 'N' AND est_inactivo = 'N' AND (isnull((datediff(dd,ISNULL((SELECT MIN(a.cta_fec_vto) FROM cuentas a WHERE a.cta_per=wf_vw_dic_datos.cta_per AND a.cta_fec_vto IS NOT NULL AND a.cta_baja_fecha IS NULL),par_fec_proceso),par_fec_proceso)), 0))  >  10 AND (SELECT SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc+case when cuentas.cta_deuda_a_venc>0 then cuentas.cta_deuda_a_venc else 0 end,cuentas.cta_mon)) FROM cuentas WHERE cuentas.cta_per = wf_vw_dic_datos.cta_per AND cuentas.cta_baja_fecha IS NULL)  >  CONVERT(Decimal(9,2),'500.00') AND (isnull((select case count (*) when 0 then 'NO' else 'SI' end from personas a inner join per_tel b on a.per_id = b.pte_per where b.pte_baja_fecha is null and wf_vw_dic_datos.cta_per = a.per_id), 'N'))  =  'SI' AND (isnull((SELECT SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc,cuentas.cta_mon)) FROM cuentas WHERE cuentas.cta_per = wf_vw_dic_datos.cta_per AND cuentas.cta_baja_fecha IS NULL), 0))  >  CONVERT(Decimal(9,2),'50.00')                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      

SELECT top 100 * FROM persona_deuda

SELECT * FROM wf_dic_datos 

SET statistics TIME ON
TRUNCATE TABLE persona_deuda
INSERT INTO
  persona_deuda
SELECT
  cta_per,
  COALESCE(SUM(dbo.emx_f_pasar_a_moneda_pais(cta_deuda_venc + CASE WHEN cta_deuda_a_venc > 0 THEN cta_deuda_a_venc ELSE 0 END, cta_mon)),0),
  COALESCE(SUM(dbo.emx_f_pasar_a_moneda_pais(cta_deuda_venc,cta_mon)),0),
  COALESCE(SUM(dbo.emx_f_pasar_a_moneda_pais(cta_deuda_a_venc,cta_mon)),0)
FROM
  cuentas
WHERE 
  cta_cat = 2 AND cta_baja_fecha IS NULL
GROUP BY cta_per


SET STATISTICS TIME ON
SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =2 AND sob_etg = 2     AND sob_est = 4 /*AND cta_per IN (40392, 161254)   */ AND (sob_fec_susp IS NULL OR sob_fec_susp <= '20200327') AND (cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  '20200327') AND esc_susp = 'N' AND est_inactivo = 'N' AND (isnull((datediff(dd,ISNULL((SELECT MIN(a.cta_fec_vto) FROM cuentas a WHERE a.cta_per=wf_vw_dic_datos.cta_per AND a.cta_fec_vto IS NOT NULL AND a.cta_baja_fecha IS NULL),par_fec_proceso),par_fec_proceso)), 0))  >  10 AND (SELECT per_deuda_total FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per)  >  CONVERT(Decimal(9,2),'500.00') AND (isnull((select case count (*) when 0 then 'NO' else 'SI' end from personas a inner join per_tel b on a.per_id = b.pte_per where b.pte_baja_fecha is null and wf_vw_dic_datos.cta_per = a.per_id), 'N'))  =  'SI' AND  (SELECT per_deuda_venc FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per) >  CONVERT(Decimal(9,2),'50.00')

SET STATISTICS TIME ON
SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =2 AND sob_etg = 2     AND sob_est = 4 /*AND cta_per IN (40392, 161254)   */ AND (sob_fec_susp IS NULL OR sob_fec_susp <= '20200327') AND (cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  '20200327') AND esc_susp = 'N' AND est_inactivo = 'N' AND (isnull((datediff(dd,ISNULL((SELECT MIN(a.cta_fec_vto) FROM cuentas a WHERE a.cta_per=wf_vw_dic_datos.cta_per AND a.cta_fec_vto IS NOT NULL AND a.cta_baja_fecha IS NULL),par_fec_proceso),par_fec_proceso)), 0))  >  10 AND (SELECT SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc+case when cuentas.cta_deuda_a_venc>0 then cuentas.cta_deuda_a_venc else 0 end,cuentas.cta_mon)) FROM cuentas WHERE cuentas.cta_per = wf_vw_dic_datos.cta_per AND cuentas.cta_baja_fecha IS NULL)  >  CONVERT(Decimal(9,2),'500.00') AND (isnull((select case count (*) when 0 then 'NO' else 'SI' end from personas a inner join per_tel b on a.per_id = b.pte_per where b.pte_baja_fecha is null and wf_vw_dic_datos.cta_per = a.per_id), 'N'))  =  'SI' AND (isnull((SELECT SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc,cuentas.cta_mon)) FROM cuentas WHERE cuentas.cta_per = wf_vw_dic_datos.cta_per AND cuentas.cta_baja_fecha IS NULL), 0))  >  CONVERT(Decimal(9,2),'50.00')                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      

SET STATISTICS TIME ON
SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =2 AND sob_etg = 2     AND sob_est = 4 /*AND cta_per IN (40392, 161254)   */ AND (sob_fec_susp IS NULL OR sob_fec_susp <= '20200401') AND (cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  '20200401') AND esc_susp = 'N' AND est_inactivo = 'N' AND (isnull((datediff(dd,ISNULL((SELECT MIN(a.cta_fec_vto) FROM cuentas a WHERE a.cta_per=wf_vw_dic_datos.cta_per AND a.cta_fec_vto IS NOT NULL AND a.cta_baja_fecha IS NULL),par_fec_proceso),par_fec_proceso)), 0))  >  10 AND (SELECT per_deuda_total FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per)  >  CONVERT(Decimal(9,2),'500.00') AND (isnull((select case count (*) when 0 then 'NO' else 'SI' end from personas a inner join per_tel b on a.per_id = b.pte_per where b.pte_baja_fecha is null and wf_vw_dic_datos.cta_per = a.per_id), 'N'))  =  'SI' AND  (SELECT per_deuda_venc FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per) >  CONVERT(Decimal(9,2),'50.00')

SET STATISTICS TIME ON
SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =2 AND sob_etg = 2     AND sob_est = 4 /*AND cta_per IN (40392, 161254)   */ AND (sob_fec_susp IS NULL OR sob_fec_susp <= '20200401') AND (cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  '20200401') AND esc_susp = 'N' AND est_inactivo = 'N' AND (isnull((datediff(dd,ISNULL((SELECT MIN(a.cta_fec_vto) FROM cuentas a WHERE a.cta_per=wf_vw_dic_datos.cta_per AND a.cta_fec_vto IS NOT NULL AND a.cta_baja_fecha IS NULL),par_fec_proceso),par_fec_proceso)), 0))  >  10 AND (SELECT SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc+case when cuentas.cta_deuda_a_venc>0 then cuentas.cta_deuda_a_venc else 0 end,cuentas.cta_mon)) FROM cuentas WHERE cuentas.cta_per = wf_vw_dic_datos.cta_per AND cuentas.cta_baja_fecha IS NULL)  >  CONVERT(Decimal(9,2),'500.00') AND (isnull((select case count (*) when 0 then 'NO' else 'SI' end from personas a inner join per_tel b on a.per_id = b.pte_per where b.pte_baja_fecha is null and wf_vw_dic_datos.cta_per = a.per_id), 'N'))  =  'SI' AND (isnull((SELECT SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc,cuentas.cta_mon)) FROM cuentas WHERE cuentas.cta_per = wf_vw_dic_datos.cta_per AND cuentas.cta_baja_fecha IS NULL), 0))  >  CONVERT(Decimal(9,2),'50.00')                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      



SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =2 AND sob_etg = 2     AND sob_est = 4  AND
(sob_fec_susp IS NULL OR sob_fec_susp <= '20200327') AND
(cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  '20200327') AND esc_susp = 'N' AND est_inactivo = 'N' AND
(isnull((datediff(dd,ISNULL((SELECT MIN(a.cta_fec_vto) FROM cuentas a WHERE a.cta_per=wf_vw_dic_datos.cta_per AND a.cta_fec_vto IS NOT NULL AND a.cta_baja_fecha IS NULL),par_fec_proceso),par_fec_proceso)), 0))  >  10 AND
(SELECT per_deuda_total FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per)  >  CONVERT(Decimal(9,2),'500.00') AND
(isnull((select case count (*) when 0 then 'NO' else 'SI' end from personas a inner join per_tel b on a.per_id = b.pte_per where b.pte_baja_fecha is null and wf_vw_dic_datos.cta_per = a.per_id), 'N'))  =  'SI' AND 
(SELECT per_deuda_venc FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per) >  CONVERT(Decimal(9,2),'50.00')


SELECT * FROM wf_condiciones WHERE con_reg = 13148 AND con_baja_fecha IS NULL
SELECT * FROM wf_dic_datos WHERE dda_id IN (1,79)

dda_id      dda_nombre                     dda_expresion                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    dda_tipo dda_obs                                                                                              dda_default                                                                                                                                                                                                                                                     dda_alta_fecha          dda_modi_fecha          dda_baja_fecha          dda_usu_id  dda_filler                                                                                                                                                                                                                                                     
----------- ------------------------------ -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -------- ---------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------- ----------------------- ----------------------- ----------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
          1 Cliente-Monto Deuda Vencida    (isnull((SELECT SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc,cuentas.cta_mon)) FROM cuentas WHERE cuentas.cta_per = wf_vw_dic_datos.cta_per AND cuentas.cta_baja_fecha IS NULL), 0))                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 N                                                                                                             10                                                                                                                                                                                                                                                              2005-08-29 00:00:00.000 2009-10-05 19:19:58.283                    NULL           1 NULL                                                                                                                                                                                                                                                           
         79 Cliente-Monto Deuda Total      (SELECT SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc+case when cuentas.cta_deuda_a_venc>0 then cuentas.cta_deuda_a_venc else 0 end,cuentas.cta_mon)) FROM cuentas WHERE cuentas.cta_per = wf_vw_dic_datos.cta_per AND cuentas.cta_baja_fecha IS NULL)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                N        Deuda Total del Cliente                                                                              0                                                                                                                                                                                                                                                               2007-01-16 00:00:00.000                    NULL                    NULL           1 NULL                                                                                                                                                                                                                                                           
(2 rows affected)

UPDATE
  wf_dic_datos
SET
  dda_expresion = '(SELECT per_deuda_venc FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per)'
WHERE
  dda_nombre = 'Cliente-Monto Deuda Vencida' AND
  dda_baja_fecha IS NULL

UPDATE
  wf_dic_datos
SET
  dda_expresion = '(SELECT per_deuda_total FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per)'
WHERE
  dda_nombre = 'Cliente-Monto Deuda Total' AND
  dda_baja_fecha IS NULL

--SELECT * FROM wf_dic_datos WHERE dda_nombre = 'Cliente-Monto Deuda Vencida' AND dda_baja_fecha IS NULL
--SELECT * FROM wf_dic_datos WHERE dda_nombre = 'Cliente-Monto Deuda Total' AND dda_baja_fecha IS NULL

SELECT
  DATEDIFF(SECOND,arp_fec_regla_ini,arp_fec_regla_fin) AS tiempo_segundos,
  DATEDIFF(MINUTE,arp_fec_regla_ini,arp_fec_regla_fin) AS tiempo_minutos,
  arp_fec_proceso,
  arp_fec_regla_ini,
  arp_fec_regla_fin,
  arp_cant_ctas,
  arp_reg,
  reg_kit,
  kit_nombre
FROM
  add_reglas_performance
  inner join wf_reglas on arp_reg = reg_id
  inner join wf_kit on reg_kit = kit_id
--WHERE
  --arp_fec_proceso >= '20200210'
  --and reg_kit = 6
--  arp_reg = 13148
ORDER BY 3,2 DEsc

k

per_id      per_deuda_total    per_deuda_venc     per_deuda_a_venc  
----------- ------------------ ------------------ ------------------
       1509          112176.24            6555.85          105619.74


cta_id      cta_per     cta_pro      cta_mon      cta_deuda_venc     cta_deuda_a_venc    cta_filler                                                                                                                                                                                                                                                      cta_cat    
----------- ----------- -----------  -----------  ------------------ ------------------  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -----------
    2792504        1509         140            2                 .00                .31  000000000000000000000000000000000000000000000000  094429442 Visa Gold                                                                                                                                                                                                     2
    2791939        1509          36            2             6555.85          103917.64  000000001300000000000000006953050000000000045945                                                                                                                                                                                                                          2
    2791372        1509           2            2                 .00            1702.44  0000000000000000                                                                                                                                                                                                                                                          2
      82842        1509         132            2                 .00               -.65  000000000000000000000000000000000000000000000000                                                                                                                                                                                                                          2


DECLARE @reg_id INTEGER = 13148
SELECT * INTO #wf_reglas  FROM wf_reglas WHERE reg_id = @reg_id AND reg_baja_fecha IS NULL

SELECT * INTO #wf_condiciones FROM wf_condiciones WHERE con_reg IN (SELECT reg_id FROM #wf_reglas) AND con_baja_fecha IS NULL

SELECT * INTO #wf_dic_datos FROM wf_dic_datos WHERE dda_id IN (SELECT con_op1_dda FROM #wf_condiciones)

SELECT * FROM #wf_reglas
SELECT * FROM #wf_condiciones
SELECT * FROM #wf_dic_datos



SELECT * FROM carteras WHERE cat_kit IN (SELECT kit_id FROM wf_kit WHERE kit_id IN ( (SELECT DISTINCT reg_kit FROM wf_reglas WHERE reg_baja_fecha IS NULL)))
SELECT * FROM wf_kit WHERE kit_id IN ( (SELECT DISTINCT reg_kit FROM wf_reglas WHERE reg_baja_fecha IS NULL))

--SELECT top 20 * from ref_reg_x_tre
SELECT * from wf_eventos_x_reg WHERE exr_baja_fecha IS NULL
SELECT * from wf_reg_x_pam WHERE rxp_baja_fecha IS NULL


SELECT COUNT(1) FROM wf_eventos_x_reg WHERE exr_baja_fecha IS NULL
SELECT COUNT(1) FROM wf_reg_x_pam WHERE rxp_baja_fecha IS NULL

