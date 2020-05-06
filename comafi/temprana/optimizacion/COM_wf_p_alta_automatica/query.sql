SELECT incta_clave,incta_pro, incta_cla, incta_suc, incta_bnc FROM in_cuentas WHERE incta_clave IN ( 
SELECT alt_clave FROM wf_in_alta_aut WHERE alt_id IN (3238371 , 2295616) AND alt_tabla = 'cta')

incta_clave                                   incta_pro  incta_cla  incta_suc  incta_bnc 
--------------------------------------------- ---------- ---------- ---------- ----------
COM022990762150685                            COMTCVG    S/I        C119       S/I       
COM000750000000000121510001                   COM4046    S/I        C75        28        


UPDATE
  in_cuentas 
SET 
  incta_pro = 'COM4046',
  incta_cla = 'COB',
  incta_suc = 'C75',
  incta_bnc = 'S/I'
WHERE
  incta_clave ='COM022990762150685'

UPDATE
  in_cuentas 
SET 
  incta_pro = 'COMTCVG',
  incta_cla = 'QUI',
  incta_suc = 'C119',
  incta_bnc = 'S/I'
WHERE
  incta_clave ='COM000750000000000121510001'

--[ indices
CREATE index ind_incta_clave ON in_cuentas (incta_clave)
DROP index ind_incta_clave ON in_cuentas
--]
--[

    DECLARE @prc_nombre_corto varchar(10)
    set @prc_nombre_corto='ALTA'
    DECLARE @v_usu_id_in INTEGER = 2
    
    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'I','Inicia alta en bitácora de cuentas cmb_cta',@v_usu_id_in, Null,0
    
    DECLARE @fecha_actual DATETIME
    SET @fecha_actual = getdate()
    
    IF OBJECT_ID('tempdb..#cuentas') IS NOT NULL DROP TABLE #cuentas
    IF OBJECT_ID('tempdb..#cmb_cta') IS NOT NULL DROP TABLE #cmb_cta
      
    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','Inserta registros en tabla temporal #cuentas',@v_usu_id_in, Null,0
Select
  alt_id AS cta_id,
	cta_pro = COALESCE(pro_id,0),
	cta_cla = COALESCE(cla_id,0),
	cta_suc = COALESCE(suc_id,0),
	cta_bnc = COALESCE(bnc_id,0)
INTO
  #cuentas
FROM
  in_cuentas
  INNER JOIN wf_in_alta_aut ON alt_clave = incta_clave
  LEFT JOIN productos       ON incta_pro = pro_nombre_corto
  LEFT JOIN clasificaciones ON incta_cla = cla_nombre_corto
  LEFT JOIN entidades       ON incta_ent = ent_nombre_corto
  LEFT JOIN sucursales      ON incta_suc = suc_nombre_corto
  LEFT JOIN banca           ON incta_bnc = bnc_nombre_corto
WHERE
  (incta_error IS NULL OR RTRIM(incta_error)='') AND 
  alt_tabla='cta'
  AND pro_baja_fecha IS NULL
  AND cla_baja_fecha IS NULL
  AND suc_baja_fecha IS NULL
  AND suc_ent = ent_id
  AND bnc_baja_fecha IS NULL

    DECLARE @num_records VARCHAR(10)

    SELECT @num_records = CAST(COUNT(*) AS VARCHAR(10)) FROM #cuentas

    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','Registros insertados en #cuentas: ' + @num_records,@v_usu_id_in, Null,0
--    Select
--      alt_id AS cta_id,
--    	cta_pro = ISNULL((SELECT pro_id FROM productos WHERE pro_nombre_corto = incta_pro AND pro_baja_fecha IS NULL),0), 
--    	cta_cla = ISNULL((SELECT cla_id FROM clasificaciones WHERE cla_nombre_corto = incta_cla AND cla_baja_fecha IS NULL),0), 
--    	cta_suc = ISNULL((SELECT suc_id FROM sucursales, entidades WHERE suc_ent = ent_id AND ent_nombre_corto = incta_ent AND suc_nombre_corto = incta_suc AND suc_baja_fecha IS NULL),0),
--    	cta_bnc = ISNULL((SELECT bnc_id FROM banca WHERE bnc_nombre_corto = incta_bnc AND bnc_baja_fecha IS NULL),0)
--    INTO
--      #cuentas
--    FROM
--      in_cuentas, wf_in_alta_aut
--    WHERE
--      (incta_error IS NULL OR RTRIM(incta_error)='') AND 
--      alt_clave = incta_clave AND 
--      alt_tabla='cta'
    
    CREATE INDEX ind_cta_id_pro_tmp ON #cuentas (cta_id, cta_pro)
    CREATE INDEX ind_cta_id_cla_tmp ON #cuentas (cta_id, cta_cla)
    CREATE INDEX ind_cta_id_suc_tmp ON #cuentas (cta_id, cta_suc)
    CREATE INDEX ind_cta_id_bnc_tmp ON #cuentas (cta_id, cta_bnc)
    
    
    CREATE TABLE #cmb_cta(
    	[cct_id] [int] NOT NULL,
    	[cct_cta] [int] NOT NULL,
    	[cct_cambio_fecha] [datetime] NOT NULL,
    	[cct_tipo] [varchar](30) NOT NULL,
    	[cct_dato_ant] [int] NOT NULL,
    	[cct_dato_nue] [int] NOT NULL,
    	[cct_nombre_ant] [varchar](100) NOT NULL,
    	[cct_nombre_nue] [varchar](100) NOT NULL,
    	[cct_obs] [varchar](100) NOT NULL,
    	[cct_alta_fecha] [datetime] NOT NULL,
    	[cct_modi_fecha] [datetime] NULL,
    	[cct_baja_fecha] [datetime] NULL,
    	[cct_usu_id] [int] NOT NULL,
    	[cct_filler] [varchar](255) NULL)
    
    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','Inserta registros en tabla temporal #cmb_cta',@v_usu_id_in, Null,0

    INSERT INTO #cmb_cta
    SELECT
      0, a.cta_id, @fecha_actual, 'cta_pro', a.cta_pro, b.cta_pro,
      RTRIM(c.pro_nombre_corto) +'-'+c.pro_nombre,
      RTRIM(d.pro_nombre_corto) +'-'+d.pro_nombre,
      'proceso alta automática', @fecha_actual, NULL, NULL, 1, ''
    FROM
      cuentas a
      INNER JOIN #cuentas b ON a.cta_id = b.cta_id
      INNER JOIN productos c ON a.cta_pro = c.pro_id
      INNER JOIN productos d ON b.cta_pro = d.pro_id
    WHERE
      a.cta_pro <> b.cta_pro
    
    UNION
    
    SELECT
      0, a.cta_id, @fecha_actual, 'cta_cla', a.cta_cla, b.cta_cla,
      RTRIM(c.cla_nombre_corto) +'-'+c.cla_nombre,
      RTRIM(d.cla_nombre_corto) +'-'+d.cla_nombre,
      'proceso alta automática', @fecha_actual, NULL, NULL, 1, ''
    FROM
      cuentas a
      INNER JOIN #cuentas b ON a.cta_id = b.cta_id
      INNER JOIN clasificaciones c ON a.cta_cla = c.cla_id
      INNER JOIN clasificaciones d ON b.cta_cla = d.cla_id
    WHERE
      a.cta_cla <> b.cta_cla
    
    UNION
    
    SELECT
      0, a.cta_id, @fecha_actual, 'cta_suc', a.cta_suc, b.cta_suc,
      RTRIM(c.suc_nombre_corto) +'-'+c.suc_nombre,
      RTRIM(d.suc_nombre_corto) +'-'+d.suc_nombre,
      'proceso alta automática', @fecha_actual, NULL, NULL, 1, ''
    FROM
      cuentas a
      INNER JOIN #cuentas b ON a.cta_id = b.cta_id
      INNER JOIN sucursales c ON a.cta_suc = c.suc_id
      INNER JOIN sucursales d ON b.cta_suc = d.suc_id
    WHERE
      a.cta_suc <> b.cta_suc
    
    UNION
    
    SELECT
      0, a.cta_id, @fecha_actual, 'cta_bnc', a.cta_bnc, b.cta_bnc,
      RTRIM(c.bnc_nombre_corto) +'-'+c.bnc_nombre,
      RTRIM(d.bnc_nombre_corto) +'-'+d.bnc_nombre,
      'proceso alta automática', @fecha_actual, NULL, NULL, 1, ''
    FROM
      cuentas a
      INNER JOIN #cuentas b ON a.cta_id = b.cta_id
      INNER JOIN banca c ON a.cta_bnc = c.bnc_id
      INNER JOIN banca d ON b.cta_bnc = d.bnc_id
    WHERE
      a.cta_bnc <> b.cta_bnc
    
    SELECT @num_records = CAST(COUNT(*) AS VARCHAR(10)) FROM #cmb_cta 
    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','Registros insertados en #cmb_cta: ' + @num_records,@v_usu_id_in, Null,0

    /* actualiza cct_id */
    DECLARE @max_cct_id INTEGER = (SELECT MAX(cct_id) FROM cmb_cta)
    
    UPDATE #cmb_cta
     SET @max_cct_id = cct_id = @max_cct_id + 1
    WHERE  cct_id = 0--IS NULL


    DECLARE @num_cta_pro VARCHAR(10) = (SELECT CAST(COUNT(*) AS VARCHAR(10)) FROM #cmb_cta WHERE cct_tipo = 'cta_pro')
    DECLARE @num_cta_cla VARCHAR(10) = (SELECT CAST(COUNT(*) AS VARCHAR(10)) FROM #cmb_cta WHERE cct_tipo = 'cta_cla')
    DECLARE @num_cta_suc VARCHAR(10) = (SELECT CAST(COUNT(*) AS VARCHAR(10)) FROM #cmb_cta WHERE cct_tipo = 'cta_suc')
    DECLARE @num_cta_bnc VARCHAR(10) = (SELECT CAST(COUNT(*) AS VARCHAR(10)) FROM #cmb_cta WHERE cct_tipo = 'cta_bnc')
    DECLARE @cmb_cta_total VARCHAR(10) = (SELECT CAST(COUNT(*) AS VARCHAR(10)) FROM #cmb_cta)
    

    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','Inserta registros en tabla destino cmb_cta',@v_usu_id_in, Null,0

    -- inserta a cmb_cta
    INSERT INTO cmb_cta
    SELECT
      cct_id         , cct_cta        , cct_cambio_fecha , cct_tipo   , cct_dato_ant , 
      cct_dato_nue   , cct_nombre_ant , cct_nombre_nue   , cct_obs    , 
      cct_alta_fecha , cct_modi_fecha , cct_baja_fecha   , cct_usu_id , cct_filler
    FROM
      #cmb_cta
    
    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','  Registros insertados tipo cta_pro: '+ @num_cta_pro, @v_usu_id_in, Null,0
    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','  Registros insertados tipo cta_cla: '+ @num_cta_cla, @v_usu_id_in, Null,0
    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','  Registros insertados tipo cta_suc: '+ @num_cta_suc, @v_usu_id_in, Null,0
    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','  Registros insertados tipo cta_bnc: '+ @num_cta_bnc, @v_usu_id_in, Null,0

    DECLARE @fecha_final DATETIME
    DECLARE @total_time_in_seconds VARCHAR(10)

    SET @fecha_final = getdate()
    SET @total_time_in_seconds = CAST(DATEDIFF(SECOND, @fecha_actual, @fecha_final) AS VARCHAR(10))

    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'I','  Total de Registros procesados: '+ @cmb_cta_total + ' en ' + @total_time_in_seconds + ' segundos', @v_usu_id_in, Null,0
    
    /* actualiza tabla id_numeracion para el campo idn_tabla = 'cmb_cta' */
    SELECT @max_cct_id = MAX(cct_id) FROM cmb_cta 
    UPDATE id_numeracion SET idn_ultimo_id = @max_cct_id WHERE idn_tabla = 'cmb_cta'

    IF OBJECT_ID('tempdb..#cuentas') IS NOT NULL DROP TABLE #cuentas
    IF OBJECT_ID('tempdb..#cmb_cta') IS NOT NULL DROP TABLE #cmb_cta
  

    INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'I','Finaliza alta en bitácora de cuentas cmb_cta',@v_usu_id_in, Null,0

--]

SELECT * FROM wf_print_out WHERE pto_fec_hora >='20200505'
DELETE FROM wf_print_out WHERE pto_fec_hora >='20200505'
