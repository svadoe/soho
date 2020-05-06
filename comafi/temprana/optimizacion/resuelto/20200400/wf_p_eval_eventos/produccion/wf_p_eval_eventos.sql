ALTER PROCEDURE [dbo].[wf_p_eval_eventos] (
	@v_fec_proceso DATETIME, 
	@v_usu_id_in   INT,
	@cat_id	       INT,
	@v_cod_ret     INT OUT
)
AS

/* 20200430 sergio vado espinoza: proyecto optimización proceso batch
                                  optimiza la inserción de acciones acc_tac entre 1 y 300 
                                  reemplaza cursores por operaciones de conjunto */
                                   
/* 20200420 sergio vado espinoza: controla los valores valores del campo evp_id de la tabla wf_eventos_proceso para que no haga conflicto al
                                  insertar los registros a la tabla wf_eventos*/

/* VAK: modificado el 2006-09-06 */


SET NOCOUNT ON

DECLARE @prc_nombre_corto varchar(10)
set @prc_nombre_corto='EVE'

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'I','PROCESO EVALUACION DE EVENTOS - INICIADO ' + CONVERT(CHAR(20),GETDATE(),113) , @v_usu_id_in, Null,@cat_id
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Fecha Proceso: ' + CONVERT(CHAR(20),@v_fec_proceso,113), @v_usu_id_in, Null,@cat_id

DECLARE @evp_id             INT
DECLARE @evp_sob            INT
DECLARE @evp_evento         INT
DECLARE @evp_param          VARCHAR(30)
DECLARE @evp_dias_min       INT
DECLARE @total_evp_proc     INT
DECLARE @total_acc_gener    INT
DECLARE @v_rep_total_err    INT
DECLARE @v_cons_total_err int
Declare @sql nvarchar(2000)

DECLARE @v_tac_tipo_vinculo VARCHAR(1)
DECLARE @v_fec_acc          DATETIME
DECLARE @v_per_id           INT
DECLARE @v_cta_per          INT
DECLARE @v_cta_id           INT
DECLARE @v_excep            INT
DECLARE @v_acc_fec_vto      DATETIME
DECLARE @v_acc_etg          INT
DECLARE @v_acc_esc          INT
DECLARE @v_acc_fec_esc      DATETIME
DECLARE @v_acc_est          INT
DECLARE @v_acc_fec_est      DATETIME
DECLARE @v_acc_deuda_a_venc NUMERIC(16,2)
DECLARE @v_acc_deuda_venc   NUMERIC(16,2) 
DECLARE @v_usu_id           INT
DECLARE @v_tac_costo		NUMERIC(9,2)

DECLARE @error_tran         INT
DECLARE @error_aux          INT

SET @total_evp_proc  = 0
SET @total_acc_gener = 0
SET @v_rep_total_err = 0

IF @v_usu_id_in IS NULL
	SET @v_usu_id = 1 --si viene nulo usamos usuario 1
ELSE
	SET @v_usu_id = @v_usu_id_in

-- OJO, VER SI GUARDAMOS LOS EVENTOS EN OTRA TABLA??

/*************INICIO**************/
/* 20200420 sergio vado espinoza */
/*********************************/
DECLARE @max_eve_id INT = (SELECT MAX(eve_id) FROM wf_eventos)
DECLARE @min_evp_id INT = (SELECT COALESCE(MIN(evp_id),0) FROM wf_eventos_proceso)

/* Si la condición se cumple significa que hay id duplicado y por lo tanto se corrige   */
/* actualizando los evp_id de la tabla wf_eventos_proceso de tal manera que no duplique */
/* con los evp_id de la tabla wf_eventos                                                */
IF (@min_evp_id <= @max_eve_id)
  BEGIN
    INSERT wf_print_out SELECT 'EVE',GETDATE(),GETDATE(),'A','Actualiza evp_id', 1,NULL, 1--, @v_usu_id_in, Null,@cat_id
    DECLARE @diff INT = (@max_eve_id - @min_evp_id) + 1
    UPDATE wf_eventos_proceso SET evp_id = evp_id + @diff
  END
/***********  FIN  ****************/
/*20200420 sergio vado espinoza  */
/*********************************/


--Copia los registros por FK
INSERT INTO wf_eventos SELECT * FROM wf_eventos_proceso 

/*************INICIO**************/
/* 20200420 sergio vado espinoza */
/*********************************/
SELECT @max_eve_id = MAX(eve_id) FROM wf_eventos
UPDATE id_numeracion SET idn_ultimo_id = @max_eve_id WHERE idn_tabla = 'wf_eventos'
/***********  FIN  ****************/
/*20200420 sergio vado espinoza  */
/*********************************/


Select @v_cod_ret = @@error
IF @v_cod_ret <> 0 RETURN -1


--[ 20200430 sergio vado espinoza: proyecto optimización proceso batch
/* INICIO código de inserción de eventos eve_evento del 1 al 300 */

IF OBJECT_ID('tempdb..#cuentas') IS NOT NULL DROP TABLE #cuentas
IF OBJECT_ID('tempdb..#ultima_accion_x_tipo') IS NOT NULL DROP TABLE #cuentas
IF OBJECT_ID('tempdb..#acciones') IS NOT NULL DROP TABLE #cuentas

DECLARE @fec_ini DATETIME = GETDATE()

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'I','  Inicia inserción de eventos tac_id 1 al 300.', @v_usu_id, Null, @cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Creación de tabla temporal #cuentas.', @v_usu_id, Null, @cat_id  

/* Creación tabla #cuentas */
SELECT
  cta_id,
  cta_per,
  cta_fec_vto,
  cta_baja_fecha,
  cta_cat
INTO
  #cuentas 
FROM 
  cuentas
  INNER JOIN wf_eventos_proceso ON cta_id = evp_sob
WHERE 
  evp_evento BETWEEN 1 AND 300
GROUP BY
  cta_id,
  cta_per,
  cta_fec_vto,
  cta_baja_fecha,
  cta_cat
  
CREATE index ind_aux_cta_id ON #cuentas (cta_id)
CREATE index ind_aux_cta_per ON #cuentas (cta_per)
CREATE index ind_aux_cta_fec_vto ON #cuentas (cta_fec_vto)
CREATE index ind_aux_cta_per_id ON #cuentas (cta_per, cta_id, cta_fec_vto)
--SELECT COUNT(1) FROM #cuentas


INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Creación de tabla temporal #ultima_accion_x_tipo.', @v_usu_id, Null, @cat_id  

/* Creación tabla #ultima_accion_x_tipo */
CREATE TABLE #ultima_accion_x_tipo (
  acc_per INTEGER,
  acc_cta INTEGER,
  acc_tac INTEGER,
  tac_tipo_vinculo VARCHAR(1),
  acc_fec_hora DATETIME
) 

INSERT INTO #ultima_accion_x_tipo (acc_per,acc_cta,acc_tac,tac_tipo_vinculo, acc_fec_hora)
SELECT
  0 [acc_per],
  acc_cta,
  acc_tac,
  tac_tipo_vinculo,
  MAX(acc_fec_hora)
FROM
  acciones
  INNER JOIN #cuentas ON acc_cta = cta_id
  INNER JOIN tipos_acciones ON acc_tac = tac_id
WHERE
  cta_cat = @cat_id 
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
  INNER JOIN #cuentas ON acc_per = cta_per
  INNER JOIN tipos_acciones ON acc_tac = tac_id
WHERE
  cta_cat = @cat_id
  AND acc_cta = 0
  AND acc_per > 0
  AND cta_baja_fecha IS NULL
  AND acc_baja_fecha IS NULL
GROUP BY
  acc_per,
  acc_cta,
  acc_tac,
  tac_tipo_vinculo

CREATE index ind_acc_ult_per ON #ultima_accion_x_tipo (acc_per)
CREATE index ind_acc_ult_cta ON #ultima_accion_x_tipo (acc_cta)


INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Creación de tabla temporal #acciones.', @v_usu_id, Null, @cat_id  

/* Creación tabla #acciones */
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


INSERT INTO #acciones
SELECT DISTINCT
  0,
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
	1                    AS acc_usu_id,
	0                    AS acc_filler,
  tac_tipo_vinculo     AS tac_tipo_vinculo,
  evp_dias_min         AS evp_dias_min,
  NULL                 AS v_fec_acc
FROM
  wf_eventos_proceso
  INNER JOIN #cuentas ON evp_sob = cta_id
  INNER JOIN tipos_acciones ON evp_evento = tac_id
WHERE
  cta_cat = @cat_id
  AND evp_evento BETWEEN 1 AND 300
  AND cta_baja_fecha IS NULL
  

CREATE index ind_tmp_acc_per ON #acciones (acc_per)
CREATE index ind_tmp_acc_cta ON #acciones (acc_cta)
CREATE index ind_tmp_acc_tac ON #acciones (acc_tac)
CREATE index ind_tmp_acc_tipo_vinculo ON #acciones (tac_tipo_vinculo)

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Fin creación tablas temporales.', @v_usu_id, Null, @cat_id  

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'I','    Inicia actualización de campos de tabla #acciones.', @v_usu_id, Null, @cat_id  

/* actualiza campos a nivel de persona */
UPDATE
  a
SET
  a.acc_fec_vto = b.cta_fec_vto,
  a.acc_costo   = d.tac_costo,
  a.acc_eve     = evp_id
FROM
  #acciones a
  INNER JOIN #cuentas b ON a.acc_per = b.cta_per
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
  INNER JOIN #cuentas b ON a.acc_cta = b.cta_id
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

/* actualiza fecha de accion a nivel de persona */
UPDATE
  a
SET
  a.v_fec_acc = b.acc_fec_hora
FROM
  #acciones a
  INNER JOIN #ultima_accion_x_tipo b ON a.acc_per = b.acc_per
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
  INNER JOIN #ultima_accion_x_tipo b ON a.acc_cta = b.acc_cta
WHERE
  a.acc_cta > 0
  AND a.acc_per = 0
  AND a.evp_dias_min > 0 
  AND a.acc_tac = b.acc_tac
  AND a.tac_tipo_vinculo = 'C'


/* excluye los registros cuya fecha de acción sea mayor que la fecha de proceso */
DELETE FROM
  #acciones
WHERE
  v_fec_acc IS NOT NULL
  AND CONVERT(DATETIME,CONVERT(VARCHAR,v_fec_acc,112)) + evp_dias_min > @v_fec_proceso

/* se establecen las fechas, escenarios, estrategias y estados a nivel de persona */
;
WITH cte AS (
SELECT
  a.acc_per          AS acc_per,
  a.acc_tac          AS acc_tac,
  MIN(b.cta_fec_vto) AS cta_fec_vto,
  c.sob_esc          AS sob_esc,
  c.sob_etg          AS sob_etg,
  c.sob_est          AS sob_est,
  c.sob_fec_esc      AS sob_fec_esc,
  c.sob_fec_est      AS sob_fec_est
FROM
  #acciones a
  INNER JOIN #cuentas b ON a.acc_per = b.cta_per
  INNER JOIN wf_sit_objetos c ON b.cta_id = c.sob_id
WHERE
  a.acc_per > 0
  AND a.acc_cta = 0
  AND b.cta_fec_vto IS NOT NULL
GROUP BY
  a.acc_per,
  a.acc_tac,
  c.sob_esc,
  c.sob_etg,
  c.sob_est,
  c.sob_fec_esc,
  c.sob_fec_est
)
UPDATE
  a
SET
  a.acc_fec_vto = cte.cta_fec_vto,
  a.acc_esc     = cte.sob_esc,
  a.acc_etg     = cte.sob_etg,
  a.acc_est     = cte.sob_est,
  a.acc_fec_esc = cte.sob_fec_esc,
  a.acc_fec_est = cte.sob_fec_est
FROM
  #acciones a
  INNER JOIN cte ON a.acc_per = cte.acc_per AND a.acc_tac = cte.acc_tac

/* se establecen las fechas, escenarios, estrategias y estados a nivel de cuenta */
;
WITH cte AS (
SELECT
  a.acc_cta          AS acc_cta,
  a.acc_tac          AS acc_tac,
  b.cta_fec_vto      AS cta_fec_vto,
  c.sob_esc          AS sob_esc,
  c.sob_etg          AS sob_etg,
  c.sob_est          AS sob_est,
  c.sob_fec_esc      AS sob_fec_esc,
  c.sob_fec_est      AS sob_fec_est
FROM
  #acciones a
  INNER JOIN #cuentas b ON a.acc_cta = b.cta_id
  INNER JOIN wf_sit_objetos c ON b.cta_id = c.sob_id
WHERE
  a.acc_per = 0
  AND a.acc_cta > 0
  AND b.cta_fec_vto IS NULL
GROUP BY
  a.acc_cta,
  a.acc_tac,
  b.cta_fec_vto,
  c.sob_esc,
  c.sob_etg,
  c.sob_est,
  c.sob_fec_esc,
  c.sob_fec_est
)
UPDATE
  a
SET
  a.acc_fec_vto = cte.cta_fec_vto,
  a.acc_esc     = cte.sob_esc,
  a.acc_etg     = cte.sob_etg,
  a.acc_est     = cte.sob_est,
  a.acc_fec_esc = cte.sob_fec_esc,
  a.acc_fec_est = cte.sob_fec_est
FROM
  #acciones a
  INNER JOIN cte ON a.acc_cta = cte.acc_cta AND a.acc_tac = cte.acc_tac


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
  INNER JOIN #cuentas b ON a.acc_cta = b.cta_id
  INNER JOIN persona_deuda c ON b.cta_per = c.per_id
WHERE
  a.acc_per     = 0
  AND a.acc_cta > 0

/* actualiza acc_id */
DECLARE @max_acc_id INTEGER = (SELECT MAX(acc_id) FROM acciones)

UPDATE #acciones
 SET @max_acc_id = acc_id = @max_acc_id + 1
WHERE  acc_id = 0--IS NULL

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'F','    Finaliza actualización de campos de tabla #acciones.', @v_usu_id, Null, @cat_id  


INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'I','    Inicia inserción de registros en tabla #acciones.', @v_usu_id, Null, @cat_id  
BEGIN TRY
  BEGIN TRANSACTION

    
    /* inserta los datos en la tabla acciones */
    INSERT INTO
      acciones (
        acc_id         , acc_per     , acc_cta      , acc_fec_hora     , acc_tac        , 
        acc_obs        , acc_estado  , acc_trp      , acc_res_fec_hora , acc_usu        , 
        acc_obs_resp   , acc_fec_vto , acc_etg      , acc_esc          , acc_fec_esc    , 
        acc_est        , acc_fec_est , acc_usu_resp , acc_deuda_a_venc , acc_deuda_venc , 
        acc_eve        , acc_mov     , acc_costo    , acc_alta_fecha   , acc_modi_fecha , 
        acc_baja_fecha , acc_usu_id  , acc_filler
      )
    SELECT
      acc_id         , acc_per     , acc_cta      , acc_fec_hora     , acc_tac        , 
      acc_obs        , acc_estado  , acc_trp      , acc_res_fec_hora , acc_usu        , 
      acc_obs_resp   , acc_fec_vto , acc_etg      , acc_esc          , acc_fec_esc    , 
      acc_est        , acc_fec_est , acc_usu_resp , acc_deuda_a_venc , acc_deuda_venc , 
      acc_eve        , acc_mov     , acc_costo    , acc_alta_fecha   , acc_modi_fecha , 
      acc_baja_fecha , acc_usu_id  , acc_filler
    FROM
      #acciones
    ORDER BY acc_id

    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'F','    Finaliza inserción de registros en tabla #acciones.', @v_usu_id, Null, @cat_id  
    
    /* actualiza tabla id_numeracion para el campo idn_tabla = 'acciones' */
    SELECT @max_acc_id = MAX(acc_id) FROM acciones 
    UPDATE id_numeracion SET idn_ultimo_id = @max_acc_id WHERE idn_tabla = 'acciones'
    
    DECLARE @num_acciones INTEGER = (SELECT COUNT(1) FROM #acciones)
    
    DECLARE @fec_fin DATETIME = GETDATE()
    DECLARE @total_time_in_seconds INTEGER = (SELECT datediff(second, @fec_ini, @fec_fin))
    
    DECLARE @info_str VARCHAR(255) = (SELECT '  Ingresaron ' + CAST(@num_acciones AS VARCHAR) + ' registros de acciones en ' + CAST(@total_time_in_seconds AS VARCHAR) + " segundos")
    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A', @info_str, @v_usu_id, Null, @cat_id  
  COMMIT TRAN -- Transaction Success!
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN --RollBack in case of Error

        DECLARE @info_err VARCHAR(255) = (SELECT '    Error: Ingresaron 0 registros en tabla acciones')
        INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'E', @info_err, @v_usu_id, Null, @cat_id  

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
        DECLARE @ErrorState INT = ERROR_STATE()

        INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'E','    Error: ' + @ErrorMessage, @v_usu_id, Null, @cat_id  

    -- Use RAISERROR inside the CATCH block to return error  
    -- information about the original error that caused  
    -- execution to jump to the CATCH block.  
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

END CATCH


/* elimina tablas temporales */
DROP TABLE #cuentas
DROP TABLE #ultima_accion_x_tipo
DROP TABLE #acciones

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'F','  Finaliza inserción de eventos tac_id 1 al 300.', @v_usu_id, Null, @cat_id  

/* FIN código de inserción de eventos eve_evento del 1 al 300 */
-- 20200430 sergio vado espinoza]
 




--[ 20200430 sergio vado espinoza: proyecto optimización proceso batch
/* INICIO código de inserción de eventos eve_evento > 300 */
/*        se excluyen los eventos masivos  522,520,521,522,523,530,531,532,533,604,605 */

DECLARE #cur_eve CURSOR FOR
	SELECT 
		evp_id, 
		evp_sob, 
		evp_evento, 
		evp_param, 
		evp_dias_min    
	FROM 
		wf_eventos_proceso
	WHERE 
		evp_id <> 0 
    AND evp_evento > 300  -- 20200430 se excluyen los eventos tac_id < 300
		AND evp_evento NOT IN (522,520,521,522,523,530,531,532,533,604,605) --20181008 - Modificacion para ejecucion de procedimientos de eventos masivos

OPEN #cur_eve

FETCH NEXT FROM #cur_eve INTO @evp_id, @evp_sob, @evp_evento, @evp_param, @evp_dias_min

WHILE @@FETCH_STATUS = 0 
BEGIN
	SET @total_evp_proc = @total_evp_proc + 1	

	Select @sql = 'Exec wf_p_eval_eventos_' + convert(varchar,@evp_evento) + ' @evp_sob, @evp_param, @v_usu_id , @v_cod_ret OUT'
  Exec sp_executesql @sql, N'@evp_sob int OUT, @evp_param varchar(255) OUT,@v_usu_id int OUT, @v_cod_ret int OUT', @evp_sob OUT, @evp_param OUT, @v_usu_id OUT, @v_cod_ret OUT

	FETCH NEXT FROM #cur_eve INTO @evp_id, @evp_sob, @evp_evento, @evp_param, @evp_dias_min
END

CLOSE #cur_eve
DEALLOCATE #cur_eve

/* FIN código de inserción de eventos eve_evento > 300 */
-- 20200430 sergio vado espinoza]
  

--20181008 - Modificacion para ejecucion de procedimientos de eventos masivos

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Recorriendo consecuentes Masivos.', @v_usu_id, Null, @cat_id  
DECLARE #cur_eve CURSOR FOR  
	SELECT   
		cse_id  
	FROM wf_consecuentes     
	WHERE     
		cse_id IN (SELECT evp_evento FROM wf_eventos_proceso)  
		AND cse_filer = 'M'  
OPEN #cur_eve  
FETCH NEXT FROM #cur_eve INTO  @evp_evento  
WHILE @@FETCH_STATUS = 0   
BEGIN   
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Ejecutando wf_p_eval_eventos_masivos_' + convert(varchar,@evp_evento) + '', @v_usu_id, Null, @cat_id  
	BEGIN TRY
		SET @sql = 'EXEC wf_p_eval_eventos_masivos_' + convert(varchar,@evp_evento) + ' @v_usu_id, @cat_id, @v_cod_ret OUT'  
		EXEC sp_executesql @sql, N'@v_usu_id INT,@cat_id INT, @v_cod_ret INT OUT', @v_usu_id , @cat_id,  @v_cod_ret OUT  
	END TRY
	BEGIN CATCH
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A',LEFT('ERROR:'+ CAST(ERROR_LINE() AS VARCHAR) + ERROR_MESSAGE(),255), @v_usu_id, Null, @cat_id  
		SET @v_cons_total_err = @v_cons_total_err + 1
	END CATCH
	SET @total_evp_proc = @total_evp_proc + 1  
  
	FETCH NEXT FROM #cur_eve INTO  @evp_evento  
END  
CLOSE #cur_eve  
DEALLOCATE #cur_eve  

TRUNCATE TABLE wf_eventos_proceso

SET @v_cod_ret = 0
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Eventos generados.....: ' + CONVERT(VARCHAR(8),@total_acc_gener), @v_usu_id_in, Null,@cat_id
IF @v_rep_total_err > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Eventos con error.....: ' + CONVERT(VARCHAR(8),@v_rep_total_err), @v_usu_id_in, Null,@cat_id
	SET @v_cod_ret = 50000
END

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'F','PROCESO EVALUACION DE EVENTOS - FINALIZADO ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, @v_cod_ret,@cat_id

GO


