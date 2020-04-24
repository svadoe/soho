ALTER PROCEDURE [dbo].[COM_wf_p_reasimilacion_escenarios] (
	@v_fec_proceso DATETIME, 
	@v_usu_id_in   INT,
	@v_reg_id   INT,
	@cat_id	INT,
	@v_cod_ret     INT OUT
)
AS
/*
20200417 sergio vado espinoza: optimización de proceso de reasimilación
VAK 2007-07-04: faltaba setear el KIT de la cartera para filtrar los escenarios a reasimilar 

CP 21/2/2007
Se filtra escenarios, reglas y estrategias, según kit. 
*/

DECLARE @prc_nombre_corto varchar(10)
/* set @prc_nombre_corto='REASI' */


SELECT @prc_nombre_corto = pcs_nombre_corto FROM procesos_bd WHERE pcs_procedimiento = 'dbo.wf_p_reasimilacion_escenarios' AND pcs_baja_fecha IS NULL
IF ISNULL(@prc_nombre_corto,'') = '' 
BEGIN
	INSERT wf_print_out SELECT ISNULL(@prc_nombre_corto,'REASI'),GETDATE(),getdate(),'I','PROCESO REASIMILACION ESCENARIOS - INICIADO ' + CONVERT(CHAR(20),GETDATE(),113),@v_usu_id_in, Null,@cat_id
	INSERT wf_print_out SELECT ISNULL(@prc_nombre_corto,'REASI'),GETDATE(),getdate(),'F','PROCESO ABORTADO - No existe el proceso en la tabla de procesos ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, Null,@cat_id
	SELECT @v_cod_ret = -1000
	RETURN
END

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'I','PROCESO REASIMILACION ESCENARIOS - INICIADO ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, Null, @cat_id
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Fecha Proceso: ' + CONVERT(CHAR(20),@v_fec_proceso,113), @v_usu_id_in, Null,@cat_id

DECLARE @v_usu_id           INT
DECLARE @v_esc_id           INT
DECLARE @v_eval_ok          INT
DECLARE @v_sob_esc          INT
DECLARE @v_sob_etg          INT
DECLARE @v_sob_est          INT
DECLARE @v_sob_scr          INT
DECLARE @v_rep_total_sob    INT
DECLARE @v_rep_total_asi    INT
DECLARE @v_rep_total_err    INT
DECLARE @v_rnd              INT
--DECLARE @v_cons             NVARCHAR(4000)
DECLARE @v_cons             VARCHAR(8000)
--DECLARE @v_cur_sql          NVARCHAR(4000)
DECLARE @v_cur_sql          VARCHAR(8000)
DECLARE @v_chk              INT
DECLARE @v_esc_etg          INT
DECLARE @v_esc_etg_desaf    INT
DECLARE @v_esc_porcen_desaf NUMERIC(6,2)
DECLARE @v_sob_id           INT
DECLARE @c_esc_id           INT
DECLARE @c_reg_id           INT
--DECLARE @c_reg_query        VARCHAR(4096)
DECLARE @c_reg_query        VARCHAR(8000)
DECLARE @v_id               INT
DECLARE @v_nombre_nue       VARCHAR(40)

DECLARE @error_tran         INT
DECLARE @error_aux          INT

--DECLARE @cat_id		    INT, /*cp 21/2/2007*/
DECLARE @cat_kit	    INT	

SELECT @cat_kit = cat_kit FROM carteras WHERE cat_id = @cat_id

SET @v_rep_total_sob = 0
SET @v_rep_total_asi = 0
SET @v_rep_total_err = 0

IF @v_usu_id_in IS NULL
	SET @v_usu_id = 1 --si viene nulo usamos usuario 1
ELSE
	SET @v_usu_id = @v_usu_id_in

/*cp por cada cartera*/
/* no haría falta porque el eval reglas está sobre una cartera
DECLARE #cur_cat CURSOR FOR
	SELECT 
		cat_id,cat_kit
	FROM 	carteras 
	WHERE 
		cat_baja_fecha IS NULL
		
OPEN #cur_cat
FETCH NEXT FROM #cur_cat INTO @cat_id,@cat_kit
	SELECT 
		esc_id
	FROM 
		wf_escenarios
	WHERE 
		esc_susp <> 'S' 
		AND esc_kit=3
		AND esc_baja_fecha IS NULL
	ORDER BY 
		esc_orden


WHILE @@FETCH_STATUS = 0
BEGIN
*/
DECLARE #cur_esc CURSOR FOR
	SELECT 
		esc_id
	FROM 
		wf_escenarios
	WHERE 
		esc_susp <> 'S' 
		AND esc_kit=@cat_kit
		AND esc_baja_fecha IS NULL
	ORDER BY 
		esc_orden

OPEN #cur_esc
FETCH NEXT FROM #cur_esc INTO @c_esc_id
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @v_cons = 'SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat=' + convert(varchar,@cat_id) + ' and cta_id IN (SELECT sob_id FROM #tmp_asimil) AND ('
    ---SET @v_cons = 'SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat=' + convert(varchar,@cat_id) + ' AND ('
	SET @v_chk = 0
	
	DECLARE #cur_reg_asi CURSOR FOR
		SELECT 
			reg_id, 
			reg_query
		FROM 
			wf_reglas
		WHERE 
			reg_clase = 'A' 
			AND reg_esc = @c_esc_id 
			AND reg_kit=@cat_kit --cp 21/2/2007
			AND reg_baja_fecha IS NULL
		ORDER BY  
			reg_orden	      

	OPEN #cur_reg_asi
	FETCH NEXT FROM #cur_reg_asi INTO @c_reg_id, @c_reg_query

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @v_cons = @v_cons + '(' + @c_reg_query + ') OR '
		SET @v_chk = 1
		      
		FETCH NEXT FROM #cur_reg_asi INTO @c_reg_id, @c_reg_query      
	END

	SELECT @v_cons = SUBSTRING(@v_cons,1,LEN(@v_cons)-3) + ')'
	
	CLOSE #cur_reg_asi
	DEALLOCATE #cur_reg_asi
	
	IF @v_chk = 1
	BEGIN
		SELECT
			@v_esc_etg          = esc_etg,
			@v_esc_etg_desaf    = COALESCE(esc_etg_desaf,0),
			@v_esc_porcen_desaf = esc_porc_desaf
		FROM 
			wf_escenarios
		WHERE 
			esc_id = @c_esc_id
			
/* INICIO */
/*20200416 sergio vado espinoza - optimizacion utilizando operaciones de conjunto*/

  /* INICIO llenado de tabla temporal #asimilar */

  -- tabla temporal que almacena los registros a asimilar con los valores actuales
  -- y los nuevos valores para los campos de escenario, estrategia y estado.
  IF OBJECT_ID('tempdb..#asimilar') IS NOT NULL
    Truncate TABLE #asimilar
  else
    CREATE TABLE #asimilar
    (
      sob_id INTEGER PRIMARY KEY,
      sob_esc_new INTEGER DEFAULT 0 NOT NULL,
      sob_etg_new INTEGER DEFAULT 0 NOT NULL,
      sob_est_new INTEGER DEFAULT 0 NOT NULL,
      sob_esc_old INTEGER DEFAULT 0 NOT NULL,
      sob_etg_old INTEGER DEFAULT 0 NOT NULL,
      sob_est_old INTEGER DEFAULT 0 NOT NULL
    )

  -- instrucción sql que inserta los registros a asimilar.
  DECLARE @sqlstr VARCHAR(8000) = 'INSERT INTO #asimilar (sob_id) ' + @v_cons
  EXEC (@sqlstr)

  --print @v_reg_id
  --print @sqlstr
  --print @v_cons

	SET @v_rep_total_sob = @v_rep_total_sob + (SELECT COUNT(*) FROM #asimilar)
  -- actualiza los valores de escenario, estrategia y estado de la tabla #asimilar con
  -- los valores actuales del registro correspondiente de la tabla wf_sit_objetos.
  UPDATE
    a 
  SET
    a.sob_esc_old = b.sob_esc,
    a.sob_etg_old = b.sob_etg,
    a.sob_est_old = b.sob_est
  FROM 
    #asimilar a
    INNER JOIN wf_sit_objetos b ON a.sob_id = b.sob_id


  -- actualiza el nuevo escenario en la tabla #asimilar
  UPDATE
    #asimilar
  SET
    sob_esc_new = @c_esc_id
    
  -- actualiza la nueva estrategia en la tabla #asimilar.
  -- para cada registro define la nueva estrategia a utilizar dependiendo
  -- de la definición de la estrategia desafiante.
  UPDATE
    #asimilar
  SET 
    sob_etg_new = CASE
                    WHEN @v_esc_etg_desaf = 0 THEN @v_esc_etg
                    WHEN abs(checksum(newid()))%100 < @v_esc_porcen_desaf THEN @v_esc_etg_desaf
                    ELSE @v_esc_etg
                  END
  FROM
    #asimilar

  -- actualiza el nuevo estado en la tabla #asimilar.
  -- el nuevo estado depende de la estrategia definida para cada registro.
  UPDATE
    a
  SET
    a.sob_est_new = b.etg_est
  FROM
    #asimilar a
    INNER JOIN wf_estrategias b ON a.sob_etg_new = b.etg_id AND etg_kit = @cat_kit
    
  -- elimina los registros que donde los nuevos datos de escenarios, estrategia y
  -- estados son iguales a los escenarios, estrategias y estados antiguos 
  DELETE FROM
    #asimilar 
  WHERE
    sob_esc_new = sob_esc_old AND
    sob_etg_new = sob_etg_old AND
    sob_est_new = sob_est_old

	SET @v_rep_total_asi = @v_rep_total_asi + (SELECT COUNT(*) FROM #asimilar)
  /* FIN llenado de tabla temporal #asimilar */

  /* INICIO de actualización de registros de la tabla wf_sit_objetos e
     inserción de registros en la tabla de bitácora wf_cmb_objetos */
  BEGIN TRY
    BEGIN TRANSACTION

      -- actualiza escenarios
      UPDATE
        a
      SET
        a.sob_esc        = b.sob_esc_new,
        sob_fec_esc      = @v_fec_proceso,
        a.sob_modi_fecha = GETDATE()
      FROM
        wf_sit_objetos a
        INNER JOIN #asimilar b ON a.sob_id = b.sob_id
      WHERE
        b.sob_esc_new <> b.sob_esc_old
      
      -- actualiza estrategias
      UPDATE
        a
      SET
        a.sob_etg        = b.sob_etg_new,
        sob_fec_etg      = @v_fec_proceso,
        a.sob_modi_fecha = GETDATE()
      FROM
        wf_sit_objetos a
        INNER JOIN #asimilar b ON a.sob_id = b.sob_id
      WHERE
        b.sob_etg_new <> b.sob_etg_old
      
      -- actualiza estados
      UPDATE
        a
      SET
        a.sob_est        = b.sob_est_new,
        sob_fec_est      = @v_fec_proceso,
        a.sob_modi_fecha = GETDATE()
      FROM
        wf_sit_objetos a
        INNER JOIN #asimilar b ON a.sob_id = b.sob_id
      WHERE
        b.sob_est_new <> b.sob_est_old
      
      /* FIN de actualización de registros de la tabla wf_sit_objetos */
      
      
      /* INICIO de inserción de registros de la tabla de bitácora wf_cmb_objetos */
      
      DECLARE @max_cob_id INTEGER = (SELECT MAX(cob_id) FROM wf_cmb_objetos)
      
      -- cambios de escenarios 
      INSERT INTO wf_cmb_objetos
      SELECT
        (row_number() OVER (ORDER BY (SELECT NULL))) + @max_cob_id,  --cob_id          
        sob_id,                                                      --cob_sob         
        getdate(),                                                   --cob_cambio_fecha
        'sob_esc',                                                   --cob_tipo        
        sob_esc_old,                                                 --cob_dato_ant    
        sob_esc_new,                                                 --cob_dato_nue    
        a.esc_nombre,                                                --cob_nombre_ant  
        b.esc_nombre,                                                --cob_nombre_nue  
        @v_reg_id,                                                   --cob_reg         
        '',                                                          --cob_obs         
        getdate(),                                                   --cob_alta_fecha  
        NULL,                                                        --cob_modi_fecha  
        NULL,                                                        --cob_baja_fecha  
        @v_usu_id,                                                   --cob_usu_id      
        ''                                                           --cob_filler      
      FROM
        #asimilar
        INNER JOIN wf_escenarios a ON sob_esc_old = a.esc_id 
        INNER JOIN wf_escenarios b ON sob_esc_new = b.esc_id 
      WHERE
        sob_esc_new <> sob_esc_old
      
      
      --cambios de estrategias
      SELECT @max_cob_id = MAX(cob_id) FROM wf_cmb_objetos
      
      INSERT INTO wf_cmb_objetos
      SELECT
        (row_number() OVER (ORDER BY (SELECT NULL))) + @max_cob_id,  --cob_id          
        sob_id,                                                      --cob_sob         
        getdate(),                                                   --cob_cambio_fecha
        'sob_etg',                                                   --cob_tipo        
        sob_etg_old,                                                 --cob_dato_ant    
        sob_etg_new,                                                 --cob_dato_nue    
        a.etg_nombre,                                                --cob_nombre_ant  
        b.etg_nombre,                                                --cob_nombre_nue  
        @v_reg_id,                                                   --cob_reg         
        '',                                                          --cob_obs         
        getdate(),                                                   --cob_alta_fecha  
        NULL,                                                        --cob_modi_fecha  
        NULL,                                                        --cob_baja_fecha  
        @v_usu_id,                                                   --cob_usu_id      
        ''                                                           --cob_filler      
      FROM
        #asimilar
        INNER JOIN wf_estrategias a ON sob_etg_old = a.etg_id 
        INNER JOIN wf_estrategias b ON sob_etg_new = b.etg_id 
      WHERE
        sob_etg_new <> sob_etg_old
      
      
      --cambios de estados
      SELECT @max_cob_id = MAX(cob_id) FROM wf_cmb_objetos
      
      INSERT INTO wf_cmb_objetos
      SELECT
        (row_number() OVER (ORDER BY (SELECT NULL))) + @max_cob_id,  --cob_id          
        sob_id,                                                      --cob_sob         
        getdate(),                                                   --cob_cambio_fecha
        'sob_est',                                                   --cob_tipo        
        sob_est_old,                                                 --cob_dato_ant    
        sob_est_new,                                                 --cob_dato_nue    
        a.est_nombre,                                                --cob_nombre_ant  
        b.est_nombre,                                                --cob_nombre_nue  
        @v_reg_id,                                                   --cob_reg         
        '',                                                          --cob_obs         
        getdate(),                                                   --cob_alta_fecha  
        NULL,                                                        --cob_modi_fecha  
        NULL,                                                        --cob_baja_fecha  
        @v_usu_id,                                                   --cob_usu_id      
        ''                                                           --cob_filler      
      FROM
        #asimilar
        INNER JOIN wf_estados a ON sob_est_old = a.est_id 
        INNER JOIN wf_estados b ON sob_est_new = b.est_id 
      WHERE
        sob_est_new <> sob_est_old
      
      /* FIN de inserción de registros de la tabla de bitácora wf_cmb_objetos */
    COMMIT TRAN
  END TRY
  BEGIN CATCH
  
    IF @@TRANCOUNT > 0 ROLLBACK TRAN --RollBack in case of Error
     
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
    DECLARE @ErrorState INT = ERROR_STATE()
  
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
  
  END CATCH
  /* FIN de actualización de registros de la tabla wf_sit_objetos e
     inserción de registros en la tabla de bitácora wf_cmb_objetos */

	-- elimina los objetos que ya fueron asimilados para que no caigan en nuevas reglas
	DELETE FROM  #tmp_asimil Where sob_id IN (SELECT sob_id FROM #asimilar)

/*20200416 sergio vado espinoza - optimizacion utilizando operaciones de conjunto*/
/*FIN*/


/*((((((((*************/
/*20200416 sergio vado espinoza - optimizacion utilizando operaciones de conjunto*/
--		SELECT @v_cur_sql = 'DECLARE #cur_sob_asi CURSOR FOR ' + @v_cons
--    EXEC (@v_cur_sql)
--
--		OPEN #cur_sob_asi
--		FETCH #cur_sob_asi INTO @v_sob_id
--		WHILE @@FETCH_STATUS = 0
--		BEGIN
--			SET @v_rep_total_sob = @v_rep_total_sob + 1
--			
--			-- Asigna escenario
--			SET @v_sob_esc = @c_esc_id
--			
--			-- Si no hay estrategia desafiante, asigna la estrategia estandar, sino, analiza cual corresponde asignar
--			IF @v_esc_etg_desaf IS NULL OR @v_esc_etg_desaf = 0
--				SET @v_sob_etg = @v_esc_etg
--			ELSE 
--			BEGIN
--				SET @v_rnd = RAND() * 100
--				IF @v_rnd <= @v_esc_porcen_desaf 
--					SET @v_sob_etg = @v_esc_etg_desaf
--				ELSE
--					SET @v_sob_etg = @v_esc_etg
--			END
--
--			-- Asigna estado y script en función de la estrategia decidida
--			SELECT
--				@v_sob_est = wf_estrategias.etg_est,
--				@v_sob_scr = wf_estrategias.etg_scr
--			FROM 
--				wf_estrategias
--			WHERE 
--				wf_estrategias.etg_id = @v_sob_etg
--				AND etg_kit=@cat_kit --cp 21/2/2007
--
--			-- Actualiza escenario, estrategia, estado y script
--			SET @error_tran = 0
--			BEGIN TRANSACTION
--
--			EXEC dbo.wf_cmb_objetos_auto	
--				@v_sob_id,  --@v_sob_id		int,
--				'sob_esc',  --@v_tipo		varchar(20),
--				@v_sob_esc, --@v_id_nuevo	int,
--				@v_reg_id, --@v_reg_id
--				@v_usu_id,          --@v_usu_id		int,
--				'reasimilacion',
--				@error_aux  --@v_cod_ret	int OUT
--			IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
--
--			EXEC dbo.wf_cmb_objetos_auto	
--				@v_sob_id,  --@v_sob_id		int,
--				'sob_est',  --@v_tipo		varchar(20),
--				@v_sob_est, --@v_id_nuevo	int,
--				@v_reg_id, --@v_reg_id
--				@v_usu_id,          --@v_usu_id		int,
--				'reasimilacion',
--				@error_aux  --@v_cod_ret	int OUT
--			IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
--
--			EXEC dbo.wf_cmb_objetos_auto	
--				@v_sob_id,  --@v_sob_id		int,
--				'sob_scr',  --@v_tipo		varchar(20),
--				@v_sob_scr, --@v_id_nuevo	int,
--				@v_reg_id, --@v_reg_id
--				@v_usu_id,          --@v_usu_id		int,
--				'reasimilacion',
--				@error_aux  --@v_cod_ret	int OUT
--			IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
--
--			EXEC dbo.wf_cmb_objetos_auto	
--				@v_sob_id,  --@v_sob_id		int,
--				'sob_etg',  --@v_tipo		varchar(20),
--				@v_sob_etg, --@v_id_nuevo	int,
--				@v_reg_id, --@v_reg_id
--				@v_usu_id,          --@v_usu_id		int,
--				'reasimilacion',
--				@error_aux  --@v_cod_ret	int OUT
--			IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
--
--			UPDATE
--				wf_sit_objetos
--			SET
--				sob_esc        = @v_sob_esc,
--				sob_etg        = @v_sob_etg,
--				sob_est        = @v_sob_est,
--				sob_scr        = @v_sob_scr,
--				sob_fec_esc    = @v_fec_proceso,
--				sob_fec_etg    = @v_fec_proceso,
--				sob_fec_est    = @v_fec_proceso,
--				sob_modi_fecha = getdate(),
--				sob_usu_id     = @v_usu_id
--			WHERE
--				sob_id = @v_sob_id
--
--			SET @error_aux = @@error
--			IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
--
--			IF @error_tran = 0
--			BEGIN
--				SET @v_rep_total_asi = @v_rep_total_asi + 1
--				COMMIT TRANSACTION
--			END
--			ELSE
--			BEGIN
--				SET @v_rep_total_err = @v_rep_total_err + 1
--				ROLLBACK TRANSACTION
--			END			
--
--			/*Elimina los objetos que ya fueron asimilados para que no caigan en nuevas reglas*/	
--			Delete #tmp_asimil Where sob_id = @v_sob_id
--				
--			FETCH #cur_sob_asi INTO @v_sob_id 
--
--		END    
--		CLOSE #cur_sob_asi
--		DEALLOCATE #cur_sob_asi
--
/*20200416 sergio vado espinoza - optimizacion utilizando operaciones de conjunto*/
/*((((((((*************/
	END

	FETCH NEXT FROM #cur_esc INTO @c_esc_id
END

CLOSE #cur_esc
DEALLOCATE #cur_esc

/* MPR - no hace falta cursor de carteras, cat_id viene por parámetro
FETCH NEXT FROM #cur_cat INTO @cat_id,@cat_kit
END

CLOSE #cur_cat
DEALLOCATE #cur_cat
*/

SET @v_cod_ret = 0
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Cuentas procesadas....: ' + CONVERT(VARCHAR(8),@v_rep_total_sob), @v_usu_id_in, Null, @cat_id
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Cuentas reasimiladas....: ' + CONVERT(VARCHAR(8),@v_rep_total_asi), @v_usu_id_in, Null, @cat_id
IF @v_rep_total_err > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Cuentas con error.....: ' + CONVERT(VARCHAR(8),@v_rep_total_err), @v_usu_id_in, Null, @cat_id
	SET @v_cod_ret = 50000
END

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'F','PROCESO REASIMILACION ESCENARIOS - FINALIZADO ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, @v_cod_ret, @cat_id

SELECT @v_cod_ret = @@Error

GO


