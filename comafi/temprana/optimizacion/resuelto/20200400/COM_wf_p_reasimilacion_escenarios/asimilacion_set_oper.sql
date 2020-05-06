/*20200416 sergio vado espinoza - optimizacion utilizando operaciones de conjunto*/
  DECLARE @v_fec_proceso VARCHAR(10) = '20200417'
  
  SELECT top 15000 sob_id INTO #tmp_asimil FROM wf_sit_objetos INNER JOIN cuentas ON sob_id = cta_id 
  WHERE cta_baja_fecha IS NULL AND cta_cat = 2 ORDER BY 1 DESC

  


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

  --DECLARE @v_cons VARCHAR(8000) = 'SELECT top 15000 cta_id FROM cuentas WHERE cta_cat = 2'
  DECLARE @v_cons VARCHAR(8000) = 'SELECT sob_id FROM #tmp_asimil'
  DECLARE @sqlstr VARCHAR(8000) = 'INSERT INTO #asimilar (sob_id) ' + @v_cons
  EXEC (@sqlstr)

  UPDATE
    a 
  SET
    a.sob_esc_old = b.sob_esc,
    a.sob_etg_old = b.sob_etg,
    a.sob_est_old = b.sob_est
  FROM 
    #asimilar a
    INNER JOIN wf_sit_objetos b ON a.sob_id = b.sob_id


  DECLARE @v_esc_etg_desaf INTEGER = 9
  DECLARE @v_esc_etg INTEGER = 25
  DECLARE @v_esc_porcen_desaf INTEGER = 50

  --estrategias nuevas
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


  DECLARE @cat_kit INTEGER = 3

  --estados
  UPDATE
    a
  SET
    a.sob_est_new = b.etg_est
  FROM
    #asimilar a
    INNER JOIN wf_estrategias b ON a.sob_etg_new = b.etg_id AND etg_kit = @cat_kit
    
  DECLARE @c_esc_id INTEGER = 7
  --escenarios
  UPDATE
    #asimilar
  SET
    sob_esc_new = @c_esc_id
    
  --elimina los registros que no tienen cambio
  DELETE FROM
    #asimilar 
  WHERE
    sob_esc_new = sob_esc_old AND
    sob_etg_new = sob_etg_old AND
    sob_est_new = sob_est_old

  SELECT * INTO #wf_sit_objetos FROM wf_sit_objetos WHERE sob_id IN (SELECT sob_id FROM #tmp_asimil)
  --SELECT * FROM #wf_sit_objetos
  
  --actualiza wf_sit_objetos

  -- escenarios
  UPDATE
    a
  SET
    a.sob_esc        = b.sob_esc_new,
    sob_fec_esc      = @v_fec_proceso,
    a.sob_modi_fecha = GETDATE()
  FROM
    #wf_sit_objetos a
    INNER JOIN #asimilar b ON a.sob_id = b.sob_id
  WHERE
    b.sob_esc_new <> b.sob_esc_old

  -- estrategias
  UPDATE
    a
  SET
    a.sob_etg        = b.sob_etg_new,
    sob_fec_etg      = @v_fec_proceso,
    a.sob_modi_fecha = GETDATE()
  FROM
    #wf_sit_objetos a
    INNER JOIN #asimilar b ON a.sob_id = b.sob_id
  WHERE
    b.sob_etg_new <> b.sob_etg_old

  -- estados
  UPDATE
    a
  SET
    a.sob_est        = b.sob_est_new,
    sob_fec_est      = @v_fec_proceso,
    a.sob_modi_fecha = GETDATE()
  FROM
    #wf_sit_objetos a
    INNER JOIN #asimilar b ON a.sob_id = b.sob_id
  WHERE
    b.sob_est_new <> b.sob_est_old

  --inserta cambios en la bitácora wf_cmb_objetos
  DECLARE @max_cob_id INTEGER = (SELECT MAX(cob_id) FROM wf_cmb_objetos)
  DECLARE @v_reg_id INTEGER = 1788
  DECLARE @v_usu_id INTEGER = 18


  --cambios de escenarios 
  SELECT * INTO #wf_cmb_objetos FROM wf_cmb_objetos WHERE cob_id = -10
  INSERT INTO #wf_cmb_objetos
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

  SELECT @max_cob_id = MAX(cob_id) FROM wf_cmb_objetos
  --cambios de estrategias
  INSERT INTO #wf_cmb_objetos
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


  SELECT @max_cob_id = MAX(cob_id) FROM wf_cmb_objetos
  --cambios de estados
  INSERT INTO #wf_cmb_objetos
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


	/*Elimina los objetos que ya fueron asimilados para que no caigan en nuevas reglas*/	
	DELETE FROM  #tmp_asimil Where sob_id IN (SELECT sob_id FROM #asimilar)
--  SELECT * FROM #wf_sit_objetos
--  SELECT * FROM #wf_cmb_objetos

/*FIN*/
		         
