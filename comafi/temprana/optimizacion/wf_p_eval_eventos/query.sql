--[
--DELETE FROM acciones WHERE acc_fec_hora >= '20200427'
DECLARE @fec_ini DATETIME = GETDATE()
DECLARE	@v_fec_proceso DATETIME 
DECLARE	@v_usu_id_in   INT
DECLARE	@cat_id	       INT
DECLARE @v_cod_ret     INT 

--SELECT MAX(acc_id) FROM acciones
--DELETE FROM acciones WHERE acc_fec_hora >= '20200427'
SET @v_fec_proceso = '20200427'
SET @v_usu_id_in = 1
SET @cat_id = 2


CREATE TABLE #acciones(
	[acc_id] [int] NOT NULL,
	[acc_per] [int] NOT NULL,
	[acc_cta] [int] NOT NULL,
	[acc_fec_hora] [datetime] NOT NULL,
	[acc_tac] [int] NOT NULL,
	[acc_obs] [varchar](255) NOT NULL,
	[acc_estado] [varchar](1) NOT NULL,
	[acc_trp] [int] NOT NULL,
	[acc_res_fec_hora] [datetime] NULL,
	[acc_usu] [int] NOT NULL,
	[acc_obs_resp] [varchar](255) NOT NULL,
	[acc_fec_vto] [datetime] NULL,
	[acc_etg] [int] NOT NULL,
	[acc_esc] [int] NOT NULL,
	[acc_fec_esc] [datetime] NOT NULL,
	[acc_est] [int] NOT NULL,
	[acc_fec_est] [datetime] NOT NULL,
	[acc_usu_resp] [int] NOT NULL,
	[acc_deuda_a_venc] [numeric](16, 2) NOT NULL,
	[acc_deuda_venc] [numeric](16, 2) NOT NULL,
	[acc_eve] [int] NOT NULL,
	[acc_mov] [int] NOT NULL,
	[acc_costo] [numeric](9, 2) NOT NULL,
	[acc_alta_fecha] [datetime] NOT NULL,
	[acc_modi_fecha] [datetime] NULL,
	[acc_baja_fecha] [datetime] NULL,
	[acc_usu_id] [int] NOT NULL,
	[acc_filler] [varchar](255) NULL,
  [tac_tipo_vinculo] [VARCHAR](1) NULL,
  [evp_dias_min] [INTEGER] NULL,
  [v_fec_acc] [DATETIME] NULL
) 

DECLARE @v_usu_id INTEGER = 1
--SELECT @max_acc_id
INSERT INTO #acciones
SELECT DISTINCT
  0, -- ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + @max_acc_id AS acc_id,
  CASE WHEN tac_tipo_vinculo = 'P' THEN cta_per ELSE 0 END AS acc_per,
  CASE WHEN tac_tipo_vinculo <> 'P' THEN evp_sob ELSE 0 END AS acc_cta,
  @v_fec_proceso       AS acc_fec_hora,
  evp_evento           AS acc_tac,
  'Proceso Automatico' AS acc_obs,
  'P'                  AS acc_estado,
  0                    AS acc_trp,
  NULL                 AS acc_res_fec_hora,
	@v_usu_id            AS acc_usu,
	''                   AS acc_obs_resp,
	NULL          AS acc_fec_vto,
	0                    AS acc_etg,
	0                    AS acc_esc,
	GETDATE()            AS acc_fec_esc,
	0                    AS acc_est,
	GETDATE()            AS acc_fec_est,
	0                    AS acc_usu_resp,
	0                    AS acc_deuda_a_venc,
	0                    AS acc_deuda_venc,
	0                    AS acc_eve,
	0                    AS acc_mov,
	0            AS acc_costo,
	GETDATE()            AS acc_alta_fecha,
	NULL                 AS acc_modi_fecha,
	NULL                 AS acc_baja_fecha,
	1                    AS acc_usu_id,
	0                    AS acc_filler,
  tac_tipo_vinculo     AS tac_tipo_vinculo,
  evp_dias_min         AS evp_dias_min,
  NULL                 AS v_fec_acc
FROM
  wf_eventos_proceso
  INNER JOIN cuentas ON evp_sob = cta_id
  INNER JOIN tipos_acciones ON evp_evento = tac_id
WHERE
  cta_cat = @cat_id
  AND evp_evento BETWEEN 1 AND 300
  AND cta_baja_fecha IS NULL
  

CREATE index ind_tmp_acc_per ON #acciones (acc_per)
CREATE index ind_tmp_acc_cta ON #acciones (acc_cta)
CREATE index ind_tmp_acc_tac ON #acciones (acc_tac)
CREATE index ind_tmp_acc_tipo_vinculo ON #acciones (tac_tipo_vinculo)


/* actualiza campos a nivel de persona */
UPDATE
  a
SET
  a.acc_fec_vto = b.cta_fec_vto,
  a.acc_costo   = d.tac_costo,
  a.acc_eve     = evp_id
FROM
  #acciones a
  INNER JOIN cuentas b ON a.acc_per = b.cta_per
  INNER JOIN wf_eventos_proceso c ON b.cta_id = c.evp_sob
  INNER JOIN tipos_acciones d ON a.acc_tac = d.tac_id 
WHERE
  a.acc_tac = c.evp_evento
  AND a.acc_per > 0
  AND a.acc_cta = 0


/* actualiza campos a nivel de cuentas */
UPDATE
  a
SET
  a.acc_fec_vto = b.cta_fec_vto,
  a.acc_costo   = d.tac_costo,
  a.acc_eve     = evp_id
FROM
  #acciones a
  INNER JOIN cuentas b ON a.acc_cta = b.cta_id
  INNER JOIN wf_eventos_proceso c ON b.cta_id = c.evp_sob
  INNER JOIN tipos_acciones d ON a.acc_tac = d.tac_id 
WHERE
  a.acc_tac = c.evp_evento
  AND a.acc_per = 0
  AND a.acc_cta > 0


/* actualiza el tipo de vinculo si es difernte de P */
UPDATE
  #acciones
SET
  tac_tipo_vinculo = 'C'
WHERE
  tac_tipo_vinculo <> 'P'

/* excluye a los exceptuados a nivel de persona */
DELETE
  a
FROM
  #acciones a
  INNER JOIN excepciones_x_cuenta b ON a.acc_per = b.exc_per
WHERE
  a.acc_tac = b.exc_tac
  AND b.exc_fec_desde <= @v_fec_proceso
  AND b.exc_fec_hasta >= @v_fec_proceso
  AND b.exc_baja_fecha IS NULL
  
/* excluye a los exceptuados a nivel de cuenta */
DELETE
  a
FROM
  #acciones a
  INNER JOIN excepciones_x_cuenta b ON a.acc_cta = b.exc_cta
WHERE
  a.acc_tac = b.exc_tac
  AND b.exc_fec_desde <= @v_fec_proceso
  AND b.exc_fec_hasta >= @v_fec_proceso
  AND b.exc_baja_fecha IS NULL

--  
/* actualiza fecha de accion a nivel de persona */
UPDATE
  a
SET
  a.v_fec_acc = b.acc_fec_hora
FROM
  #acciones a
  INNER JOIN ultima_accion_x_tipo b ON a.acc_per = b.acc_per
WHERE
  a.acc_per > 0
  AND a.acc_cta = 0
  AND a.evp_dias_min > 0 
  AND a.acc_tac = b.acc_tac
  AND a.tac_tipo_vinculo = 'P'


/* actualiza fecha de accion a nivel de cuenta */
UPDATE
  a
SET
  a.v_fec_acc = b.acc_fec_hora
FROM
  #acciones a
  INNER JOIN ultima_accion_x_tipo b ON a.acc_cta = b.acc_cta
WHERE
  a.acc_cta > 0
  AND a.acc_per = 0
  AND a.evp_dias_min > 0 
  AND a.acc_tac = b.acc_tac
  AND a.tac_tipo_vinculo = 'C'


/* elimina los registros cuya fecha de acción sea mayor que la fecha de proceso */
DELETE FROM
  #acciones
WHERE
  v_fec_acc IS NOT NULL
  AND CONVERT(DATETIME,CONVERT(VARCHAR,v_fec_acc,112)) + evp_dias_min > @v_fec_proceso


/* se establecen las fechas, escenarios, estrategias y estados a nivel de persona */
UPDATE
  a
SET
  a.acc_fec_vto = b.cta_fec_vto,
  a.acc_esc     = c.sob_esc,
  a.acc_etg     = c.sob_etg,
  a.acc_est     = c.sob_est,
  a.acc_fec_esc = c.sob_fec_esc,
  a.acc_fec_est = c.sob_fec_est
FROM
  #acciones a
  INNER JOIN cuentas b ON a.acc_per = b.cta_per
  INNER JOIN wf_sit_objetos c ON b.cta_id = c.sob_id
WHERE
  a.acc_per > 0
  AND a.acc_cta = 0
  AND b.cta_fec_vto IS NOT NULL

/* se establecen las fechas, escenarios, estrategias y estados a nivel de cuenta */
UPDATE
  a
SET
  a.acc_fec_vto = b.cta_fec_vto,
  a.acc_esc     = c.sob_esc,
  a.acc_etg     = c.sob_etg,
  a.acc_est     = c.sob_est,
  a.acc_fec_esc = c.sob_fec_esc,
  a.acc_fec_est = c.sob_fec_est
FROM
  #acciones a
  INNER JOIN cuentas b ON a.acc_cta = b.cta_id
  INNER JOIN wf_sit_objetos c ON b.cta_id = c.sob_id
WHERE
  a.acc_per = 0
  AND a.acc_cta > 0
--  AND b.cta_fec_vto IS NOT NULL

/* se establece deuda vencida y deuda a vencer a nivel de persona*/
UPDATE
  a
SET
  a.acc_deuda_venc   = b.per_deuda_venc,
  a.acc_deuda_a_venc = b.per_deuda_a_venc
FROM
  #acciones a
  INNER JOIN persona_deuda b ON a.acc_per = b.per_id
WHERE
  a.acc_per     > 0
  AND a.acc_cta = 0

/* se establece deuda vencida y deuda a vencer a nivel de cuenta*/
/* las deudas a nivel de cuenta se calculan como a nivel de persona */
UPDATE
  a
SET
  a.acc_deuda_venc   = c.per_deuda_venc,
  a.acc_deuda_a_venc = c.per_deuda_a_venc
FROM
  #acciones a
  INNER JOIN cuentas b ON a.acc_cta = b.cta_id
  INNER JOIN persona_deuda c ON b.cta_per = c.per_id
WHERE
  a.acc_per     = 0
  AND a.acc_cta > 0

/* actualiza acc_id */

DECLARE @max_acc_id INTEGER = (SELECT MAX(acc_id) FROM acciones)

UPDATE #acciones
 SET @max_acc_id = acc_id = @max_acc_id + 1
WHERE  acc_id = 0--IS NULL

--SELECT acc_deuda_venc, acc_deuda_a_venc, evp_dias_min, v_fec_acc, acc_per, acc_cta, acc_fec_vto, acc_etg, acc_esc, acc_fec_esc, acc_est, acc_fec_est FROM #acciones --WHERE acc_tac BETWEEN 1 AND 300 ORDER BY acc_cta
--SELECT * FROM #acciones WHERE acc_per = 1509
--SELECT acc_per, acc_tac FROM #acciones WHERE acc_per > 0 GROUP BY acc_per,acc_tac ORDER BY 2
--SELECT acc_per, acc_tac FROM acciones WHERE acc_per > 0 AND acc_fec_hora >= '20200427' GROUP BY acc_per,acc_tac ORDER BY 2
--SELECT acc_cta, acc_tac FROM #acciones WHERE acc_cta > 0 GROUP BY acc_cta,acc_tac ORDER BY 2
--SELECT acc_cta, acc_tac FROM acciones WHERE acc_cta > 0 AND acc_fec_hora >= '20200427' GROUP BY acc_cta,acc_tac ORDER BY 2


select acc_per, acc_cta, acc_tac, acc_estado, acc_etg, acc_esc, acc_est, acc_fec_esc, acc_fec_est, acc_deuda_venc, acc_deuda_a_venc, acc_eve from #acciones where acc_fec_hora >= '20200427' order by acc_per, acc_cta, acc_tac, acc_estado, acc_etg, acc_esc, acc_est, acc_fec_esc, acc_fec_est, acc_deuda_venc, acc_deuda_a_venc, acc_eve

DROP TABLE #acciones
--]


--[-- máxima acción por tipo
--CREATE index ind_acc_fec_hora ON acciones (acc_fec_hora)
INSERT INTO ultima_accion_x_tipo (acc_per,acc_cta,acc_tac,tac_tipo_vinculo, acc_fec_hora)
SELECT
  0 [acc_per],
  acc_cta,
  acc_tac,
  tac_tipo_vinculo,
  MAX(acc_fec_hora)
FROM
  acciones
  INNER JOIN cuentas ON acc_cta = cta_id
  INNER JOIN tipos_acciones ON acc_tac = tac_id
WHERE
  cta_cat = 2
  AND acc_cta > 0
  AND acc_per = 0
  AND cta_baja_fecha IS NULL
  AND acc_baja_fecha IS NULL
GROUP BY
  acc_per,
  acc_cta,
  acc_tac,
  tac_tipo_vinculo
UNION
SELECT
  acc_per,
  0 [acc_cta],
  acc_tac,
  tac_tipo_vinculo,
  MAX(acc_fec_hora)
FROM
  acciones
  INNER JOIN cuentas ON acc_per = cta_per
  INNER JOIN tipos_acciones ON acc_tac = tac_id
WHERE
  cta_cat = 2
  AND acc_cta = 0
  AND acc_per > 0
  AND cta_baja_fecha IS NULL
  AND acc_baja_fecha IS NULL
GROUP BY
  acc_per,
  acc_cta,
  acc_tac,
  tac_tipo_vinculo

CREATE index ind_acc_ult_per ON ultima_accion_x_tipo (acc_per)
CREATE index ind_acc_ult_cta ON ultima_accion_x_tipo (acc_cta)
--]--
--SELECT cta_cat,* FROM cuentas WHERE cta_per = 9400
--SELECT * FROM acciones WHERE acc_per = 9400 AND acc_tac = 46

SELECT * FROM ultima_accion_x_tipo WHERE acc_fec_hora ='20200427' AND tac_tipo_vinculo = 'C'
DROP TABLE ultima_accion_x_tipo
CREATE TABLE ultima_accion_x_tipo (
  acc_per INTEGER,
  acc_cta INTEGER,
  acc_tac INTEGER,
  tac_tipo_vinculo VARCHAR(1),
  acc_fec_hora DATETIME
) 

SELECT top 10 * FROM acciones WHERE acc_per >0
SELECT * FROM tipos_acciones WHERE tac_tipo_vinculo = 'P' AND tac_baja_fecha IS NULL



SELECT * FROM acciones WHERE acc_cta = 3119


