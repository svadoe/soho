
--[
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
DECLARE @max_acc_id INTEGER = (SELECT MAX(acc_id) FROM acciones)
--SELECT @max_acc_id
INSERT INTO #acciones
SELECT
  ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + @max_acc_id AS acc_id,
  cta_per              AS acc_per,
  evp_sob              AS acc_cta,
  GETDATE()            AS acc_fec_hora,
  evp_evento           AS acc_tac,
  'Proceso Automatico' AS acc_obs,
  'P'                  AS acc_estado,
  0                    AS acc_trp,
  NULL                 AS acc_res_fec_hora,
	@v_usu_id            AS acc_usu,
	''                   AS acc_obs_resp,
	NULL                 AS acc_fec_vto,
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
	0                    AS acc_costo,
	GETDATE()            AS acc_alta_fecha,
	NULL                 AS acc_modi_fecha,
	NULL                 AS acc_baja_fecha,
	0                    AS acc_usu_id,
	0                    AS acc_filler,
  0                    AS tac_tipo_vinculo,
  evp_dias_min         AS evp_dias_min,
  NULL                 AS v_fec_acc
FROM
  wf_eventos_proceso
  INNER JOIN cuentas ON evp_sob = cta_id
WHERE
  cta_cat = 2
  AND cta_baja_fecha IS NULL
  
CREATE index ind_tmp_acc_per ON #acciones (acc_per)
CREATE index ind_tmp_acc_cta ON #acciones (acc_cta)
CREATE index ind_tmp_acc_tac ON #acciones (acc_tac)
CREATE index ind_tmp_acc_tipo_vinculo ON #acciones (tac_tipo_vinculo)

DECLARE @v_fec_proceso VARCHAR(10)='20091210'
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


/* se establecen las fechas, escenarios, estrategias y estados */
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
  INNER JOIN wf_sit_objetos c ON a.acc_cta = c.sob_id


/* se establece el tipo de vínculo según el tipo de acción */
UPDATE
  a
SET
  a.tac_tipo_vinculo = b.tac_tipo_vinculo
FROM
  #acciones a
  INNER JOIN tipos_acciones b ON a.acc_tac = b.tac_id

/* si el tipo de vinculo es P (persona)*/
UPDATE
  #acciones
SET
  acc_cta = 0
WHERE
  tac_tipo_vinculo = 'P'

/* si el tipo de vinculo es diferente de P (persona) */
UPDATE
  #acciones
SET
  acc_per = 0,
  tac_tipo_vinculo = 'C'
WHERE
  tac_tipo_vinculo <> 'P'


UPDATE
  a
SET
  a.v_fec_acc = b.acc_fec_hora
FROM
  #acciones a
  INNER JOIN ultima_accion_x_tipo b ON a.acc_per = b.acc_per
WHERE
  a.acc_tac = b.acc_tac
  AND a.tac_tipo_vinculo = 'P'
  AND a.evp_dias_min > 0

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
UPDATE
  a
SET
  a.acc_deuda_venc   = b.cta_deuda_venc,
  a.acc_deuda_a_venc = b.cta_deuda_a_venc
FROM
  #acciones a
  INNER JOIN cuenta_deuda b ON a.acc_cta = b.cta_id
WHERE
  a.acc_per     = 0
  AND a.acc_cta > 0

--SELECT * FROM persona_deuda
--SELECT * FROM cuenta_deuda

SELECT acc_deuda_venc, acc_deuda_a_venc, evp_dias_min, v_fec_acc, acc_per, acc_cta, acc_fec_vto, acc_etg, acc_esc, acc_fec_esc, acc_est, acc_fec_est FROM #acciones --WHERE acc_tac BETWEEN 1 AND 300

--]


--[-- máxima acción por tipo
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
  INNER JOIN cuentas ON acc_cta = cta_id
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
--ORDER BY 1,2 
CREATE index ind_acc_ult_per ON ultima_accion_x_tipo (acc_per)
CREATE index ind_acc_ult_cta ON ultima_accion_x_tipo (acc_cta)
--]--


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


