EXEC COM_wf_p_eval_eventos '20200406',1,2,0
ALTER PROCEDURE [dbo].[COM_wf_p_eval_eventos] (
	@v_fec_proceso DATETIME, 
	@v_usu_id_in   INT,
	@cat_id	       INT,
	@v_cod_ret     INT OUT
)
AS

/* 20200406 sergio vado espinoza: se valida que el valor de evp_id de la tabla wf_eventos_proceso no cause
                                  cancelanción con respecto al valor de eve_id de la tabla wf_eventos

    VAK: modificado el 2007-07-02 */


DECLARE @prc_nombre_corto varchar(10)
DECLARE @v_cat_nombre_corto varchar(10)
--DECLARE @cat_id INT

select @v_cat_nombre_corto = cat_nombre_corto from carteras where cat_id=@cat_id AND cat_baja_fecha IS NULL

SET NOCOUNT ON




/* SET @prc_nombre_corto = 'EVE' */
SELECT @prc_nombre_corto = pcs_nombre_corto FROM procesos_bd WHERE pcs_procedimiento = 'dbo.wf_p_eval_eventos' AND pcs_baja_fecha IS NULL
IF ISNULL(@prc_nombre_corto,'') = '' 
BEGIN
	INSERT wf_print_out SELECT ISNULL(@prc_nombre_corto,'EVE'),GETDATE(),getdate(),'I','PROCESO EVALUACION DE EVENTOS - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113),@v_usu_id_in, Null,0
	INSERT wf_print_out SELECT ISNULL(@prc_nombre_corto,'EVE'),GETDATE(),getdate(),'F','PROCESO ABORTADO - No existe el proceso en la tabla de procesos ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, Null,0
	SELECT @v_cod_ret = -1000
	RETURN
END

--SELECT @cat_id = cat_id FROM carteras where cat_nombre_corto=@v_cat_nombre_corto AND cat_baja_fecha IS NULL
--IF ISNULL(@cat_id,0)=0
--BEGIN
--	INSERT wf_print_out SELECT ISNULL(@prc_nombre_corto,'EVE'),GETDATE(),getdate(),'I','PROCESO EVALUACION DE EVENTOS - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113),@v_usu_id_in, Null,0
--	INSERT wf_print_out SELECT ISNULL(@prc_nombre_corto,'EVE'),GETDATE(),getdate(),'F','PROCESO ABORTADO - No se encontro la cartera ' + @v_cat_nombre_corto + ' ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, Null,0
--	SELECT @v_cod_ret = -1000
--	RETURN
--END


INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'I','PROCESO EVALUACION DE EVENTOS - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113) , @v_usu_id_in, Null,@cat_id
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Fecha Proceso: ' + CONVERT(CHAR(20),@v_fec_proceso,113), @v_usu_id_in, Null,@cat_id

DECLARE @evp_id             INT
DECLARE @evp_sob            INT
DECLARE @evp_evento         INT
DECLARE @evp_param          VARCHAR(30)
DECLARE @evp_dias_min       INT
DECLARE @total_evp_proc     INT
DECLARE @total_acc_gener    INT
DECLARE @v_rep_total_err    INT

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

/*************INICIO**************/
/* 20200406 sergio vado espinoza */
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
/*20200406 sergio vado espinoza  */
/*********************************/



-- OJO, VER SI GUARDAMOS LOS EVENTOS EN OTRA TABLA??

--Copia los registros por FK
INSERT INTO wf_eventos SELECT * FROM wf_eventos_proceso
Select @v_cod_ret = @@error
IF @v_cod_ret <> 0 RETURN -1

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

OPEN #cur_eve

FETCH NEXT FROM #cur_eve INTO @evp_id, @evp_sob, @evp_evento, @evp_param, @evp_dias_min

WHILE @@FETCH_STATUS = 0 
BEGIN
	SET @total_evp_proc = @total_evp_proc + 1	

-- Inicio Generación de Acciones 
	IF @evp_evento BETWEEN 1 AND 200
	BEGIN
-------------------------------------------------------------------
		SET @v_tac_tipo_vinculo = ''
		SET @v_fec_acc          = NULL
		SET @v_per_id           = NULL
		SET @v_cta_per          = NULL
		SET @v_excep            = NULL 
		SET @v_acc_etg          = NULL 
		SET @v_acc_esc          = NULL 
		SET @v_acc_fec_esc      = NULL 
		SET @v_acc_est          = NULL 
		SET @v_acc_deuda_a_venc = 0
		SET @v_acc_deuda_venc   = 0
		SET @v_tac_costo		= 0

		SELECT @v_cta_per = cta_per FROM cuentas WHERE cta_id = @evp_sob
		
		SELECT @v_tac_tipo_vinculo = tac_tipo_vinculo,
				@v_tac_costo = tac_costo
		FROM   tipos_acciones
		WHERE  tac_id = @evp_evento

		IF @v_tac_tipo_vinculo = 'P'
		BEGIN
			IF @evp_dias_min > 0
				SELECT @v_fec_acc = MAX(acc_fec_hora)
				FROM acciones
				WHERE acc_per = @v_cta_per
				AND acc_tac = @evp_evento
				AND acc_baja_fecha IS NULL
			ELSE
				SET @v_fec_acc = NULL

			SET @v_per_id = @v_cta_per
			SET @v_cta_id = 0
		END 
		ELSE 
		BEGIN -- Si el vínculo es 'C' o 'A' se genera acción a nivel cuenta

			IF @evp_dias_min > 0
				SELECT @v_fec_acc = MAX(acc_fec_hora)
				FROM acciones
				WHERE acc_cta = @evp_sob AND acc_tac = @evp_evento AND acc_baja_fecha IS NULL
			ELSE
				SET @v_fec_acc = NULL

			SET @v_per_id = 0
			SET @v_cta_id = @evp_sob
			SET @v_tac_tipo_vinculo = 'C'
		END

	        --IF @v_fec_acc IS NULL OR (CONVERT(DATETIME,CONVERT(DATETIME,(@v_fec_acc),112) + @evp_dias_min,112) <= @v_fec_proceso)
	        IF @v_fec_acc IS NULL OR (CONVERT(DATETIME,CONVERT(VARCHAR,@v_fec_acc,112)) + @evp_dias_min <= @v_fec_proceso)
		BEGIN
	
			-- Verificación que no haya una excepción para la cuenta/persona
			IF @v_tac_tipo_vinculo = 'P'
			BEGIN
				SELECT @v_excep = exc_id
				FROM excepciones_x_cuenta
				WHERE  exc_per = @v_per_id AND exc_tac = @evp_evento 
						AND exc_fec_desde <= @v_fec_proceso AND exc_fec_hasta >= @v_fec_proceso
			END
			ELSE
			BEGIN
				SELECT @v_excep = exc_id
				FROM excepciones_x_cuenta
				WHERE exc_cta = @v_cta_id AND exc_tac = @evp_evento 
						AND exc_fec_desde <= @v_fec_proceso AND exc_fec_hasta >= @v_fec_proceso
			END

			IF @v_excep IS NULL
			BEGIN
				-- Inserta Acción correspondiente
				SELECT TOP 1
					@v_acc_fec_vto  = cta_fec_vto,
					@v_acc_etg      = sob_etg,
					@v_acc_esc      = sob_esc,
					@v_acc_fec_esc  = sob_fec_esc,
					@v_acc_est      = sob_est,
					@v_acc_fec_est  = sob_fec_est
				FROM 
					cuentas, 
					wf_sit_objetos 
				WHERE 	
					cta_per = @v_cta_per 
					AND cta_fec_vto IS NOT NULL 
					AND sob_id = cta_id 
					AND cta_baja_fecha is NULL
				ORDER BY 
					cta_fec_vto
	
				IF @v_acc_etg IS NULL 
				BEGIN
					SELECT TOP 1
						@v_acc_fec_vto  = cta_fec_vto,
						@v_acc_etg      = sob_etg,
						@v_acc_esc      = sob_esc,
						@v_acc_fec_esc  = sob_fec_esc,
						@v_acc_est      = sob_est,
						@v_acc_fec_est  = sob_fec_est
					FROM 
						cuentas, 
						wf_sit_objetos 
					WHERE 
						cta_per = @v_cta_per 
						AND sob_id = cta_id 
						AND cta_baja_fecha IS NULL
				END
	
				SELECT 
					@v_acc_deuda_venc = ISNULL(SUM(dbo.emx_f_pasar_a_moneda_pais (cta_deuda_venc,cta_mon)),0),
					@v_acc_deuda_a_venc = ISNULL(SUM(dbo.emx_f_pasar_a_moneda_pais (cta_deuda_a_venc,cta_mon)),0)
				FROM 
					cuentas 
				WHERE 
					cta_per = @v_cta_per AND 
					cta_deuda_a_venc >= 0 
					AND cta_baja_fecha IS NULL
	
				
				SET @error_tran = 0
				BEGIN TRANSACTION

				EXEC dbo.acciones_insert2 
	                                @v_per_id,
		                        @v_cta_id,
					@v_fec_proceso,
					@evp_evento,
					'Proceso Automático',
					'P',
					0,
					NULL,
					@v_usu_id, --1
					'',
					@v_acc_fec_vto,
					@v_acc_etg,
					@v_acc_esc,
					@v_acc_fec_esc,
					@v_acc_est,
					@v_acc_fec_est,
					0,
					@v_acc_deuda_a_venc,
					@v_acc_deuda_venc,
					@evp_id,
					0, /* acc_mov */
					@v_tac_costo,
					1,
					'',
					@error_aux OUT
				IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
		
				IF @error_tran = 0
				BEGIN
					SET @total_acc_gener = @total_acc_gener + 1
					COMMIT TRANSACTION
				END
				ELSE
				BEGIN
					SET @v_rep_total_err = @v_rep_total_err + 1
					ROLLBACK TRANSACTION
				END			
			END
		END
	END 
	-- Fin Generación de Acciones 
	ELSE
	BEGIN
		Declare @sql nvarchar(2000)
		Select @sql = 'Exec wf_p_eval_eventos_' + convert(varchar,@evp_evento) + ' @evp_sob, @evp_param, @v_usu_id_in, @v_cod_ret OUT'
		Exec sp_executesql @sql, N'@evp_sob int OUT, @evp_param varchar(255) OUT, @v_usu_id_in int OUT, @v_cod_ret int OUT', @evp_sob OUT, @evp_param OUT, @v_usu_id_in OUT, @v_cod_ret OUT
	END



	SET @total_evp_proc = @total_evp_proc + 1
	FETCH NEXT FROM #cur_eve INTO @evp_id, @evp_sob, @evp_evento, @evp_param, @evp_dias_min
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

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'F','PROCESO EVALUACION DE EVENTOS - FINALIZADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, @v_cod_ret,@cat_id



GO

