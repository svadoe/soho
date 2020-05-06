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

/*FIN*/

		         

