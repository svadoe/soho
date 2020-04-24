--[
SET NOCOUNT ON
DECLARE @per_cli VARCHAR(20) ='96000000092037621'

/* Datos de la persona */
SELECT * INTO #personas FROM personas WHERE per_cli = @per_cli AND per_baja_fecha IS NULL

/* Datos de documentos de la persona */
SELECT * INTO #per_doc FROM per_doc WHERE pdc_per IN (SELECT per_id FROM #personas)

/* Datos de domicilio de la persona */
SELECT * INTO #per_tel FROM per_tel WHERE pte_per IN (SELECT per_id FROM #personas)

/* Datos de domicilio de la persona */
SELECT * INTO #per_dom FROM per_dom WHERE pdm_per IN (SELECT per_id FROM #personas)

/* Datos de domicilio de la persona */
SELECT * INTO #per_atributos FROM per_atributos WHERE pea_id IN (SELECT per_id FROM #personas)

/* Datos de los productos */
SELECT * INTO #cuentas FROM cuentas WHERE cta_per IN (SELECT per_id FROM #personas) AND cta_baja_fecha IS NULL

/* Datos de los productos */
SELECT * INTO #cmb_cta FROM cmb_cta WHERE cct_cta IN (SELECT cta_id FROM #cuentas)

/* Datos de los productos (escenario, estado, estrategias) */
SELECT * INTO #wf_sit_objetos FROM wf_sit_objetos WHERE sob_id IN (SELECT cta_id FROM #cuentas)

/* Bitacora de cambios de los objetos (escenario, estado, estrategias) */
SELECT * INTO #wf_cmb_objetos FROM wf_cmb_objetos WHERE cob_sob IN (SELECT cta_id FROM #cuentas)

/* movimientos */
SELECT * INTO #movimientos FROM movimientos WHERE mov_cta IN (SELECT cta_id FROM #cuentas)

/* Acciones */
SELECT * INTO #acciones FROM acciones WHERE acc_cta IN (SELECT cta_id FROM #cuentas)
INSERT INTO #acciones SELECT * FROM acciones WHERE acc_per IN  (SELECT per_id FROM #personas)

/* Eventos */
SELECT * INTO #wf_eventos FROM wf_eventos WHERE eve_sob IN (SELECT cta_id FROM #cuentas)

/*
declare @table_name varchar(20) = 'prestamos'
declare @table_schema varchar(20) = 'dbo'
IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @table_schema AND TABLE_NAME = @table_name))
  BEGIN
  END
*/


/* prestamos */
SELECT * INTO #prestamos FROM prestamos WHERE ptm_cta IN (SELECT cta_id FROM #cuentas)

/* datos de cuotas de prestamos */
SELECT * INTO #prestamos_cuotas FROM prestamos_cuotas WHERE pcu_ptm IN (SELECT ptm_id FROM #prestamos)

/* tarjetas */
SELECT * INTO #tarjetas FROM tarjetas WHERE taj_cta IN (SELECT cta_id FROM #cuentas)

/* vencimiento de tarjetas */
SELECT * INTO #tarjetas_venc FROM tarjetas_venc WHERE tcv_taj IN (SELECT taj_id FROM #tarjetas)

;
WITH cte AS (
  SELECT cob_sob [cta_id], cob_reg [reg_id], cob_alta_fecha [alta_fecha], cob_tipo [tipo], 'wf_cmb_objetos' AS [tabla] FROM #wf_cmb_objetos
  UNION                   
  SELECT eve_sob, eve_reg, eve_alta_fecha, '', 'wf_eventos' AS [tabla] FROM #wf_eventos
)
SELECT * INTO #reglas_x_cuentas FROM cte WHERE reg_id > 0

SELECT * INTO #wf_reglas FROM wf_reglas WHERE reg_id IN (SELECT DISTINCT reg_id FROM #reglas_x_cuentas) AND reg_baja_fecha IS NULL

/*
SELECT
  *
INTO #add_reglas_performance
FROM
  add_reglas_performance a
  INNER JOIN #wf_reglas ON a.arp_reg = reg_id
WHERE
  arp_fec_regla_ini = (SELECT
                         MAX(b.arp_fec_regla_ini)
                       FROM
                          add_reglas_performance b
                       WHERE
                           a.arp_reg = b.arp_reg)
*/
SELECT * FROM #personas
SELECT * FROM #cuentas
SELECT * FROM #wf_sit_objetos
SELECT * FROM #wf_cmb_objetos
SELECT * FROM #movimientos
SELECT * FROM #acciones
SELECT * FROM #wf_eventos
SELECT * FROM #prestamos
SELECT * FROM #prestamos_cuotas
SELECT * FROM #tarjetas
SELECT * FROM #tarjetas_venc

SELECT * FROM #reglas_x_cuentas
SELECT * FROM #wf_reglas
--SELECT * FROM #add_reglas_performance



--]



--[
reg_x_coh

SELECT
  tac_nombre 
FROM
  wf_eventos_x_reg
  INNER JOIN tipos_acciones ON tac_id = exr_evento
WHERE
  exr_reg = 13148
  AND exr_baja_fecha IS NULL
UNION
SELECT
  cse_nombre 
FROM
  wf_eventos_x_reg
  INNER JOIN wf_consecuentes ON cse_id = exr_evento
WHERE
  exr_reg = 13148
  AND exr_baja_fecha IS NULL

select * from wf_reglas where reg_id = 13148
select * from wf_condiciones where con_reg = 13148 and con_baja_fecha is null
select * from wf_condiciones INNER JOIN wf_reglas ON con_reg = reg_id where con_op1_dda = 79 and con_baja_fecha is null AND reg_baja_fecha IS NULL AND reg_kit = 3
SELECT * FROM wf_kit
select * from wf_dic_datos where dda_id = 79
select top 1 arp_query from add_reglas_performance where arp_reg = 13148 order by 1 desc
SELECT 
SET STATISTICS TIME ON
SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =2 AND sob_etg = 2 AND sob_est = 4     AND 
(SELECT SUM(dbo.emx_f_pasar_a_moneda_pais(cuentas.cta_deuda_venc+case when cuentas.cta_deuda_a_venc>0 then cuentas.cta_deuda_a_venc else 0 end,cuentas.cta_mon)) FROM cuentas WHERE cuentas.cta_per = wf_vw_dic_datos.cta_per AND cuentas.cta_baja_fecha IS NULL) >  CONVERT(Decimal(9,2),'500.00') 

SET STATISTICS TIME ON
SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =2 AND sob_etg = 2 AND sob_est = 4     AND 
(SELECT per_deuda FROM persona_deuda WHERE per_id = wf_vw_dic_datos.cta_per) >  CONVERT(Decimal(9,2),'500.00') 

SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =2 AND sob_etg = 2 AND sob_est = 4     AND 
--]
