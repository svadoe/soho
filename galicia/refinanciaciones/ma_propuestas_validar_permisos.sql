CREATE procedure [dbo].[ma_propuestas_validar_permisos](
													@v_npr_id									int,

													@v_ope_list									VARCHAR(8000),
													@v_the_id									int,
													@v_sistema									varchar(1),
													@v_neto_refinanciar							numeric(20,6),
													@v_saldo_ajustado							numeric(20,6),
													@v_cuotas									int,
													@v_int_comp_tasa_fija						NUMERIC(20,6),

													@v_quita									NUMERIC(20,6),
													@v_quita_porcen								NUMERIC(20,6),
													@v_quita_puni								NUMERIC(20,6),
													@v_quita_puni_porcen						NUMERIC(20,6),
													@v_quita_comp								NUMERIC(20,6),
													@v_quita_comp_porcen						NUMERIC(20,6),
													@v_anticipo									NUMERIC(20,6),
													@v_anticipo_porcen							NUMERIC(20,6),

													@v_usu_id									int,
													@v_cod_ret									int out)
as

begin try

		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_npr_id: ' + CAST(ISNULL(@v_npr_id,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_ope_list: ' + ISNULL(@v_ope_list,'null'), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_the_id: ' + CAST(ISNULL(@v_the_id,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_sistema: ' + ISNULL(@v_sistema,'null'), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_neto_refinanciar ' + CAST(ISNULL(@v_neto_refinanciar,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_saldo_ajustado ' + CAST(ISNULL(@v_saldo_ajustado,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_cuotas ' + CAST(ISNULL(@v_cuotas,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_int_comp_tasa_fija ' + CAST(ISNULL(@v_int_comp_tasa_fija,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_quita ' + CAST(ISNULL(@v_quita,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_quita_porcen ' + CAST(ISNULL(@v_quita_porcen,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_quita_puni ' + CAST(ISNULL(@v_quita_puni,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_quita_puni_porcen ' + CAST(ISNULL(@v_quita_puni_porcen,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_quita_comp ' + CAST(ISNULL(@v_quita_comp,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_quita_comp_porcen ' + CAST(ISNULL(@v_quita_comp_porcen,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_anticipo ' + CAST(ISNULL(@v_anticipo,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_anticipo_porcen ' + CAST(ISNULL(@v_anticipo_porcen,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_usu_id ' + CAST(ISNULL(@v_usu_id,-1) AS VARCHAR), 1, NULL, 0  
		INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'I', '@v_cod_ret ' + CAST(ISNULL(@v_cod_ret,-1) AS VARCHAR), 1, NULL, 0  

        --sergio vado espinoza SELECT * FROM wf_print_out WHERE pto_proceso = 'TESTP' and pto_texto like '%tiene_permisos%'
	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity BIGINT;
	DECLARE @ErrorState BIGINT; 
	-------------------------------------------------------
	declare @cant_operaciones int
	declare @c_cantidad int
	declare @v_sql  NVARCHAR(MAX)


	declare @tiene_permisos int
	set @tiene_permisos=0
	-------------------------------------------------------

	--si el porcentaje de quita total es -1 lo calculo
	if @v_quita_porcen=-1
	set @v_quita_porcen= (@v_quita * 100)/ @v_saldo_ajustado

	--si el porcentaje de quita puni es -1 lo calculo
	if @v_quita_puni_porcen=-1
	set @v_quita_puni_porcen= (@v_quita_puni * 100)/ @v_saldo_ajustado

	--si el porcentaje de quita comp es -1 lo calculo
	if @v_quita_comp_porcen=-1
	set @v_quita_comp_porcen= (@v_quita_comp * 100)/ @v_saldo_ajustado

	--busco las cuentas de la refi
	if OBJECT_ID('tempdb..#tmp_ng_prop_ope') is not null DROP TABLE #tmp_ng_prop_ope 
	create table #tmp_ng_prop_ope (tmp_ope_id INT ) 

	insert into #tmp_ng_prop_ope
	select item from dbo.Split(@v_ope_list,',') where Item <>''

	select @cant_operaciones= COUNT(1) from #tmp_ng_prop_ope


	--busco las credenciales y las guardo en una tabla
	if OBJECT_ID('tempdb..#tmp_credenciales') is not null DROP TABLE #tmp_credenciales 
	create table #tmp_credenciales (tmp_peo_id INT ) 

	insert into #tmp_credenciales
	select distinct peo_id
	FROM	ma_prop_permisos 
			inner join ma_prop_perm_perf on ppp_peo=peo_id
	where peo_baja_fecha is null	
	and ppp_baja_fecha is null
	and peo_the=@v_the_id	
	and peo_sistema=@v_sistema
	AND @v_neto_refinanciar between peo_monto_desde and peo_monto_hasta
	AND @v_cuotas between peo_cuotas_desde and peo_cuotas_hasta
	and peo_tasa_interes_min <= @v_int_comp_tasa_fija 
	--anticipo
	and (peo_anticipo_monto <= @v_anticipo
		 and peo_anticipo_porc <= @v_anticipo_porcen)
	--quitas 
	and (peo_quita_tot_monto >= @v_quita
		 and peo_quita_tot_porc >= @v_quita_porcen )
	and (peo_quita_puni_monto >= @v_quita_puni
		 and peo_quita_puni_porc >= @v_quita_puni_porcen )
	and (peo_quita_comp_monto >= @v_quita_comp
		 and peo_quita_comp_porc >= @v_quita_comp_porcen )
	and (ppp_usu = @v_usu_id 
		 or ppp_equ IN (SELECT 
							mie_equ
						FROM 
							wf_miembros
						WHERE 
							mie_usu = @v_usu_id AND
							mie_baja_fecha IS NULL)
		 or ppp_age = (select top 1 age_id from agencias inner join wf_usuarios on usu_age=age_id where age_baja_fecha is null and usu_baja_fecha is null and usu_id=@v_usu_id)						
		 )	
	     


	--cursor de filtros por universo
	DECLARE @tif_tabla_db VARCHAR(100)  
	DECLARE @tif_campo_label VARCHAR(100)  
	DECLARE @tif_campo_pk VARCHAR(100)  
	DECLARE @tif_campo_fk VARCHAR(100)  
	DECLARE @tif_from NVARCHAR(MAX)  
	DECLARE @tif_where NVARCHAR(MAX)       
	declare @peo_id int
	declare @hxf_id int
	DECLARE @v_select_plantillas NVARCHAR(MAX)
	DECLARE @v_from_plantillas NVARCHAR(MAX)
	DECLARE @v_where_plantillas NVARCHAR(MAX)  
	declare @tmp_peo_id int


	 SET @v_select_plantillas= 'DECLARE #cur_operaciones CURSOR FOR SELECT count(distinct cta_id) '
	 
	 SET @v_from_plantillas = ' FROM  #tmp_ng_prop_ope  inner join cuentas on tmp_ope_id=cta_id  '   
	 set @v_where_plantillas= ' WHERE cta_baja_fecha is null '

	DECLARE #cur_plantillas CURSOR FAST_FORWARD  for  
	select  tmp_peo_id from   #tmp_credenciales 


	OPEN #cur_plantillas  
	FETCH NEXT FROM #cur_plantillas INTO @tmp_peo_id
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		set @v_sql=''

		DECLARE #cur_filtros CURSOR FAST_FORWARD FOR  
		SELECT DISTINCT  
				tif_tabla_db ,  
				tif_campo_label ,  
				tif_campo_pk ,  
				tif_campo_fk ,  
				tif_from ,  
				tif_where,
				peo_id,
				hxf_id   
		FROM    ma_prop_permisos 
				INNER JOIN ma_tipos_herramientas ON the_id = peo_the 
				INNER JOIN ma_the_x_tif on hxf_the = the_id 
				INNER JOIN tipos_filtros ON hxf_tif = tif_id  
	            
		WHERE   peo_id = @tmp_peo_id
				and hxf_baja_fecha IS NULL  
				AND tif_baja_fecha IS NULL  
		  
		OPEN #cur_filtros  
		FETCH NEXT FROM #cur_filtros INTO @tif_tabla_db, @tif_campo_label,@tif_campo_pk, @tif_campo_fk, @tif_from, @tif_where,@peo_id,@hxf_id
		             
		WHILE @@FETCH_STATUS = 0  
		BEGIN         
			SET @v_from_plantillas = @v_from_plantillas + ' ' + CHAR(13) + CHAR(10) + @tif_from  

			IF LEN(LTRIM(@tif_campo_pk)) <> 0  
				SET @v_where_plantillas = @v_where_plantillas + CHAR(13) + CHAR(10)  
					+ ' AND ' + @tif_campo_pk + ' IN  (SELECT vaf_valor FROM ma_valores_filtros
														WHERE vaf_baja_fecha IS NULL AND vaf_peo = ' + CONVERT(VARCHAR, @peo_id)   
													 + ' AND vaf_hxf = ' + CONVERT(VARCHAR, @hxf_id) + ' ) '  
		         
			FETCH NEXT FROM #cur_filtros INTO @tif_tabla_db,@tif_campo_label, @tif_campo_pk, @tif_campo_fk,@tif_from, @tif_where,@peo_id,@hxf_id
		END  
		  
		 
		CLOSE #cur_filtros  
		DEALLOCATE #cur_filtros  

		select @v_sql = @v_select_plantillas + @v_from_plantillas  + @v_where_plantillas

		BEGIN TRY   
			PRINT @v_sql  
			EXEC sp_executesql @v_sql
			
			
			SELECT @c_cantidad = 0      

			-- Recorro el cursor de operaciones que tiene las operaciones atrapadas por la regla (las que cumplen)
			OPEN #cur_operaciones 

			FETCH #cur_operaciones INTO  @c_cantidad 

			WHILE @@FETCH_STATUS = 0   
			BEGIN     
				IF @c_cantidad = @cant_operaciones 
					set @tiene_permisos=1 			

				FETCH #cur_operaciones INTO  @c_cantidad 
			END 
			
			CLOSE #cur_operaciones 
			DEALLOCATE #cur_operaciones 
			
			

		END TRY  
		BEGIN CATCH  
		   --select ERROR_MESSAGE()
		   --select ERROR_LINE()
		   	INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'F', 'CATCH ', 1, NULL, 0  
		   select @v_cod_ret=ERROR_NUMBER()
		END CATCH   



		FETCH NEXT FROM #cur_plantillas INTO @tmp_peo_id

	END  
	  
		  
	CLOSE #cur_plantillas  
	DEALLOCATE #cur_plantillas  
	   
	  

	drop table #tmp_credenciales
	INSERT INTO wf_print_out  SELECT 'TESTP', GETDATE(), GETDATE(), 'F', '@tiene_permisos ' + CAST(ISNULL(@tiene_permisos,-1) AS VARCHAR), 1, NULL, 0  
	select @tiene_permisos as tiene_permisos

END TRY  
BEGIN CATCH  
   --select ERROR_MESSAGE()
   --select ERROR_LINE()
   --select @v_cod_ret=ERROR_NUMBER()
   		SET @v_cod_ret=ERROR_NUMBER()    			
		SELECT     @ErrorMessage = ERROR_MESSAGE(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(); 					
		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState); 
END CATCH   



TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_npr_id: 121                                                                                                                                                                                                                                                            1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_ope_list: ,590884,3580239,                                                                                                                                                                                                                                             1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_the_id: 1                                                                                                                                                                                                                                                              1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_sistema: F                                                                                                                                                                                                                                                             1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_neto_refinanciar 2429.850000                                                                                                                                                                                                                                           1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_saldo_ajustado 2479.440000                                                                                                                                                                                                                                             1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_cuotas 5                                                                                                                                                                                                                                                               1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_int_comp_tasa_fija 0.000000                                                                                                                                                                                                                                            1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_quita 49.590000                                                                                                                                                                                                                                                        1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_quita_porcen 2.000000                                                                                                                                                                                                                                                  1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_quita_puni 0.000000                                                                                                                                                                                                                                                    1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_quita_puni_porcen 0.000000                                                                                                                                                                                                                                             1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_quita_comp 0.000000                                                                                                                                                                                                                                                    1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_quita_comp_porcen 0.000000                                                                                                                                                                                                                                             1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_anticipo 0.000000                                                                                                                                                                                                                                                      1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_anticipo_porcen 0.000000                                                                                                                                                                                                                                               1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_usu_id 2                                                                                                                                                                                                                                                               1        NULL           0
TESTP       2018-11-21 12:08:48.640 2018-11-21 12:08:48.640 I             @v_cod_ret 0                                                                                                                                                                                                                                                              1        NULL           0
TESTP       2018-11-21 12:08:48.700 2018-11-21 12:08:48.700 F             @tiene_permisos 1                                                                                                                                                                                                                                                         1        NULL           0




TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_npr_id: 120                                                                                                                                                                                                                                                            1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_ope_list: ,612455,                                                                                                                                                                                                                                                     1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_the_id: 1                                                                                                                                                                                                                                                              1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_sistema: F                                                                                                                                                                                                                                                             1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_neto_refinanciar 0.000000                                                                                                                                                                                                                                              1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_saldo_ajustado 0.000000                                                                                                                                                                                                                                                1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_cuotas 4                                                                                                                                                                                                                                                               1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_int_comp_tasa_fija 5.000000                                                                                                                                                                                                                                            1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_quita 0.000000                                                                                                                                                                                                                                                         1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_quita_porcen 8.000000                                                                                                                                                                                                                                                  1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_quita_puni 0.000000                                                                                                                                                                                                                                                    1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_quita_puni_porcen 0.000000                                                                                                                                                                                                                                             1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_quita_comp 0.000000                                                                                                                                                                                                                                                    1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_quita_comp_porcen 0.000000                                                                                                                                                                                                                                             1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_anticipo 0.000000                                                                                                                                                                                                                                                      1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_anticipo_porcen 0.000000                                                                                                                                                                                                                                               1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_usu_id 2                                                                                                                                                                                                                                                               1        NULL           0
TESTP       2020-04-24 08:52:39.533 2020-04-24 08:52:39.533 I             @v_cod_ret -1                                                                                                                                                                                                                                                             1        NULL           0
TESTP       2020-04-24 08:52:39.550 2020-04-24 08:52:39.550 F             @tiene_permisos 0                                                                                                                                                                                                                                                         1        NULL           0
