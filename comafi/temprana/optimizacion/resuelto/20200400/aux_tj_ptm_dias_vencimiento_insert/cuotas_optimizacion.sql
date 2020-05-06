--[
SET statistics TIME ON
DECLARE @fecha_proceso DATETIME  
SELECT @fecha_proceso = prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'FECCIE'  

;
WITH cte AS (
  SELECT
    cta_per
    ,pcu_ptm
    ,cta_id
    ,MIN(pcu_venc_fecha) AS pcu_venc_fecha
    ,pcu_importe + pcu_intereses AS total 
    ,cta_cat
  FROM
    prestamos_cuotas  
    INNER JOIN prestamos ON pcu_ptm = ptm_id  
    INNER JOIN cuentas   ON ptm_cta = cta_id
  WHERE
    pcu_estado = 'A' 
    AND ptm_baja_fecha IS NULL 
    AND pcu_baja_fecha IS NULL 
    AND cta_baja_fecha IS NULL 
--    AND pcu_ptm = 1270622
  GROUP BY
    cta_per
    ,pcu_ptm
    ,cta_id
    ,pcu_importe + pcu_intereses
    ,cta_cat
  )
  SELECT
    b.cta_per
    ,b.cta_id
    ,a.pcu_ptm
    ,MIN(a.pcu_venc_fecha) AS pcu_venc_fecha
    ,b.total
  INTO
    #ultima_cuota
  FROM
    prestamos_cuotas a
    INNER JOIN cte b ON a.pcu_ptm = b.pcu_ptm
  WHERE
    b.pcu_venc_fecha >= @fecha_proceso
    AND a.pcu_estado = 'A' 
    AND a.pcu_baja_fecha IS NULL 
    AND b.cta_cat = 2
  GROUP BY
    b.cta_per
    ,b.cta_id
    ,a.pcu_ptm
    ,b.total
  HAVING
    MIN(a.pcu_venc_fecha) = MIN(b.pcu_venc_fecha)
   
  CREATE index ind_ultima_cuota_pcu_ptm ON #ultima_cuota (pcu_ptm)

SELECT
  cta_per
  ,cta_id
  ,'PTM'
  ,dbo.emx_f_cantidad_dias_habiles(@fecha_proceso,pcu_venc_fecha)
  ,total
FROM
  #ultima_cuota
ORDER BY 1,2
--]


--[
SET statistics TIME ON
DECLARE @fecha_proceso DATETIME  
SELECT @fecha_proceso = prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'FECCIE'  

    SELECT  
           cta_per,  
           cta_id,  
           'PTM',  
           dbo.emx_f_cantidad_dias_habiles(@fecha_proceso,MIN(pcu_venc_fecha)),  
     (SELECT top 1 pcu_importe + pcu_intereses  
    from prestamos_cuotas  
    inner join prestamos on  pcu_ptm = ptm_id  
    where ptm_baja_fecha is null and pcu_baja_fecha is null and pcu_estado = 'A' and  pcu_venc_fecha >= @fecha_proceso and ptm_cta=cta_id   
    order by pcu_venc_fecha)  
    FROM  
           prestamos_cuotas   
           INNER JOIN prestamos ON pcu_ptm = ptm_id  
           INNER JOIN cuentas   ON ptm_cta = cta_id  
    WHERE  
           pcu_baja_fecha IS NULL  
           AND ptm_baja_fecha IS NULL  
           AND cta_baja_fecha IS NULL  
           AND pcu_estado = 'A'  
AND ptm_cta IN ( 2422483, 2206598, 2313997, 2083263, 2421270, 2469720, 2033714, 2395655)
--  AND pcu_id = 6691079
     and cta_cat = 2 -- select * from carteras  
    GROUP BY cta_per, cta_id  
    HAVING MIN(pcu_venc_fecha) >= @fecha_proceso   
    ORDER BY 1,2
--]


DECLARE @fecha_proceso DATETIME  
SELECT @fecha_proceso = prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'FECCIE'  
SELECT
  cta_per
  ,cta_id
  ,MIN(pcu_venc_fecha)
FROM
  prestamos_cuotas
  INNER JOIN prestamos ON pcu_ptm = ptm_id
  INNER JOIN cuentas   ON ptm_cta = cta_id
WHERE
  pcu_baja_fecha IS NULL  
  AND ptm_baja_fecha IS NULL  
  AND cta_baja_fecha IS NULL  
  AND pcu_estado = 'A'  
  AND ptm_cta = 2422483
GROUP BY
  cta_per
  ,cta_id
 HAVING
  MIN(pcu_venc_fecha) >= @fecha_proceso   
  --ptm_cta IN ( 2422483, 2206598, 2313997, 2083263, 2421270, 2469720, 2033714, 2395655)


SELECT * FROM cuentas WHERE cta_id IN( 2422483, 2206598, 2313997, 2083263, 2421270, 2469720, 2033714, 2395655)

SELECT * FROM prestamos WHERE ptm_cta IN ( 2422483, 2206598, 2313997, 2083263, 2421270, 2469720, 2033714, 2395655)

SELECT * FROM prestamos_cuotas WHERE pcu_ptm = 1270622 ORDER by 5

DECLARE @fecha_proceso DATETIME  
SELECT @fecha_proceso = prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'FECCIE'  
SELECT * FROM prestamos_cuotas WHERE pcu_ptm = ( SELECT ptm_id FROM prestamos WHERE ptm_cta IN (2422483)) AND pcu_venc_fecha >= @fecha_proceso ORDER BY pcu_venc_fecha
/*
pcu_id      pcu_ptm     pcu_numero  pcu_importe        pcu_venc_fecha          pcu_pago_fecha          pcu_estado pcu_intereses      pcu_obs                                                                                                                                                                                                                                                         pcu_p_alta_fecha        pcu_p_modi_fecha        pcu_alta_fecha          pcu_modi_fecha          pcu_baja_fecha          pcu_usu_id  pcu_filler                                                                                                                                                                                                                                                     
----------- ----------- ----------- ------------------ ----------------------- ----------------------- ---------- ------------------ --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------- ----------------------- ----------------------- ----------------------- ----------------------- ----------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    6691079     1270622          34             899.10 2020-04-28 00:00:00.000                    NULL A                     1625.00                                                                                                                                                                                                                                                                 2017-06-27 00:00:00.000 2017-11-07 00:00:00.000 2017-06-28 06:19:29.387                    NULL                    NULL         232 000000000008991000000000000341250000000000162500                                                                                                                                                                                                               
    6690932     1270622          35             923.12 2020-05-28 00:00:00.000                    NULL A                     1601.26                                                                                                                                                                                                                                                                 2017-06-27 00:00:00.000 2017-11-07 00:00:00.000 2017-06-28 06:19:29.387                    NULL                    NULL         232 000000000009231200000000000336260000000000160126                                                                                                                                                                                                               
    6690922     1270622          36             947.78 2020-06-28 00:00:00.000                    NULL A                     1578.57                                                                                                                                                                                                                                                                 2017-06-27 00:00:00.000 2017-11-07 00:00:00.000 2017-06-28 06:19:29.387                    NULL                    NULL         232 000000000009477800000000000331500000000000157857                                                                                                                                                                                                               
    6690927     1270622          37             973.10 2020-07-28 00:00:00.000                    NULL A                     1551.85                                                                                                                                                                                                                                                                 2017-06-27 00:00:00.000 2017-11-07 00:00:00.000 2017-06-28 06:19:29.387                    NULL                    NULL         232 000000000009731000000000000325890000000000155185                                                                                                                                                                                                               
*/

DECLARE @fecha_proceso DATETIME  
SELECT @fecha_proceso = prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'FECCIE'  
SELECT
  TOP 1 pcu_importe + pcu_intereses  
FROM
  prestamos_cuotas  
  INNER JOIN prestamos ON pcu_ptm = ptm_id  
WHERE
  ptm_baja_fecha IS NULL 
  AND pcu_baja_fecha IS NULL 
  AND pcu_estado = 'A' 
  AND pcu_venc_fecha >= @fecha_proceso-- and ptm_cta=cta_id   
  AND pcu_id = 6691079
--    order by pcu_venc_fecha

