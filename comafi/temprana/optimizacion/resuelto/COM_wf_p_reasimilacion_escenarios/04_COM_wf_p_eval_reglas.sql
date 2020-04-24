ALTER PROCEDURE [dbo].[COM_wf_p_eval_reglas] (   
	@v_fec_proceso_in  DATETIME,   
	@v_usu_id_in       INT,  
	@v_cat_nombre_corto VARCHAR(10),  
	@v_cod_ret         INT OUT  
)  
AS  
/*  
20200414 sergio vado espinoza: Se agrega sp calcular_deudas el cual llena las tablas auxiliares
                               cuenta_deuda y persona_deuda que almacenan las deudas a nivel
                               de cuentas y de personas respectivamente; el objetivo es optimizar
                               los tiempo de ejecución de las reglas que utilizan dichos cálculos.


CP 26/2/2007  
Se filtra reglas por kit  
*/  
SET NOCOUNT ON  
  
DECLARE @prc_nombre_corto varchar(10)  
DECLARE @v_fec_proceso       DATETIME  
DECLARE @v_usu_id            INT  
  
set @prc_nombre_corto='REG'  
  
--no core --------------------------------------------------------
DECLARE @v_hora		   DATETIME
DECLARE @v_fec_ejecucion                DATETIME
DECLARE @v_fec_ejecucion_inicio         DATETIME
DECLARE @v_fec_ejecucion_consulta       DATETIME
DECLARE @v_fec_ejecucion_open_cur       DATETIME
DECLARE @v_fec_ejecucion_fetch_cur       DATETIME
DECLARE @v_ctas_atrapadas	INT
DECLARE @v_rep_total_acc_x_reg          INT
DECLARE @v_rep_total_cta     INT  
SET @v_fec_ejecucion = getdate()
Set @v_ctas_atrapadas = 0
--no core --------------------------------------------------------  

  
IF @v_usu_id_in IS NULL  
 SET @v_usu_id = 1 --si viene nulo usamos usuario 1  
ELSE  
 SET @v_usu_id = @v_usu_id_in  
  
  
IF (@v_cat_nombre_corto is not null) and ((SELECT count(*)FROM carteras WHERE cat_baja_fecha IS NULL and cat_nombre_corto = @v_cat_nombre_corto) = 0)  
BEGIN  
 INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'I','PROCESO EVALUACION DE REGLAS - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113),@v_usu_id_in, Null,0  
 INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','PROCESO ABORTADO - No existe la cartera informada ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, Null,0  
 SELECT @v_cod_ret = -1000  
 RETURN  
END  
  
  
IF @v_fec_proceso_in IS NULL OR ISDATE(@v_fec_proceso_in)=0  
BEGIN  
 /* Obtencion del parámetro @v_fec_proceso */  
 SELECT @v_fec_proceso = prt_valor FROM wf_parametros where prt_baja_fecha is null and prt_nombre_corto='FECPRO'  
   
 IF @v_fec_proceso IS NULL OR ISDATE(@v_fec_proceso)=0  
 BEGIN  
  INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'I','PROCESO EVALUACION DE REGLAS - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113) , @v_usu_id, Null, (SELECT cat_id from carteras where cat_nombre_corto = @v_cat_nombre_corto)  
  INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','PROCESO ABORTADO - No existe fecha de proceso ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id, Null, (SELECT cat_id from carteras where cat_nombre_corto = @v_cat_nombre_corto)  
  SELECT @v_cod_ret = -1000  
  RETURN  
 END  
 /* Fin Obtencion del parámetro @v_fec_proceso */  
END  
ELSE  
 SET @v_fec_proceso = @v_fec_proceso_in  
  
/*  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'I','PROCESO EVALUACION DE REGLAS - INICIADO ' + CONVERT(CHAR(20),GETDATE(),113) , @v_usu_id, Null  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Fecha Proceso: ' + CONVERT(CHAR(20),@v_fec_proceso,113), @v_usu_id, Null  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A',' ' , @v_usu_id, Null  
*/  
  
  
--DECLARE @v_cons              NVARCHAR(4000)  JAD 22/9
DECLARE @v_cons              VARCHAR(8000)  
--DECLARE @sql                 NVARCHAR(4000)  JAD 22/9 
DECLARE @sql                 VARCHAR(8000)  
--DECLARE @v_cur_sql           NVARCHAR(4000)  JAD 22/9
DECLARE @v_cur_sql           VARCHAR(8000)  
DECLARE @v_cta_id            INT  
DECLARE @c_cta_id            INT  
DECLARE @c_cta_esc           INT  
DECLARE @c_cta_etg           INT  
DECLARE @c_cta_est           INT  
DECLARE @c_cta_scr           INT  
DECLARE @c_cta_usu_res       INT  
DECLARE @c_reg_id            INT  
DECLARE @c_reg_kit           INT --cp 26/2/2007  
DECLARE @c_reg_tipo          VARCHAR(1)  
DECLARE @c_reg_orden         NUMERIC(3,0)  
DECLARE @c_reg_esc_res       INT  
DECLARE @c_reg_est_res       INT  
DECLARE @c_reg_scr           INT  
DECLARE @c_reg_susp          NUMERIC(4,0)  
--DECLARE @c_reg_query         VARCHAR(4096)  JAD 22/9
DECLARE @c_reg_query         VARCHAR(8000)  
DECLARE @c_reg_escala        INT  
DECLARE @c_reg_res_obj       INT  
DECLARE @c_reg_usu_res       INT  
DECLARE @c_reg_reval_esc     INT  
DECLARE @c_reg_ges           INT  
DECLARE @c_reg_esc           INT  
DECLARE @c_reg_etg           INT  
DECLARE @c_reg_est           INT  
DECLARE @c_reg_eval_susp     CHAR(1)  
DECLARE @c_reg_cont_eval     CHAR(1)  
DECLARE @c_exr_evento        INT  
DECLARE @c_exr_dias_min      NUMERIC(4,0)  
DECLARE @c_exr_param         VARCHAR(30)  
DECLARE @c_esc_id            INT  
DECLARE @v_rep_total_err     INT  
DECLARE @v_rep_total_reg     INT  
DECLARE @v_rep_total_cum     INT  
DECLARE @v_rep_total_eventos INT  
DECLARE @v_rep_total_cmb_esc INT  
DECLARE @v_rep_total_cmb_est INT  
DECLARE @v_rep_total_cmb_etg INT  
DECLARE @v_rep_total_cmb_scr INT  
DECLARE @v_rep_total_susp    INT  
DECLARE @v_rep_total_escala  INT  
DECLARE @v_rep_total_res_obj INT  
DECLARE @v_id                INT  
DECLARE @v_nombre_ant        VARCHAR(40)  
DECLARE @v_nombre_nue        VARCHAR(40)  
DECLARE @v_usu_res_nue       INT  
DECLARE @v_esc_etg           INT  
DECLARE @v_esc_etg_desaf     INT  
DECLARE @v_esc_porcen_desaf  INT  
DECLARE @v_etg_est           INT  
DECLARE @v_fec_aux           DATETIME  
DECLARE @v_re_evaluar        INT  
  
DECLARE @error_tran          INT  
DECLARE @error_aux           INT  
  
DECLARE @cat_id      INT,  
 @cat_kit     INT  
  
  
--MPR 20070422 Inicio  
  
IF (@v_cat_nombre_corto is null)  
 begin  
  DECLARE #cur_cat CURSOR FOR  
   SELECT  cat_id,cat_kit,cat_nombre_corto  
   FROM  carteras   
   WHERE  cat_baja_fecha IS NULL  
 end  
else  
 begin  
  DECLARE #cur_cat CURSOR FOR  
   SELECT  cat_id,cat_kit,cat_nombre_corto  
   FROM  carteras   
   WHERE  cat_baja_fecha IS NULL and cat_nombre_corto = @v_cat_nombre_corto  
 end  
  
  
  
   
OPEN #cur_cat  
FETCH NEXT FROM #cur_cat INTO @cat_id,@cat_kit,@v_cat_nombre_corto  
  
WHILE @@FETCH_STATUS = 0  
begin  
  
  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'I','PROCESO EVALUACION DE REGLAS - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113) , @v_usu_id, Null, @cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Fecha Proceso: ' + CONVERT(CHAR(20),@v_fec_proceso,113), @v_usu_id, Null, @cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A',' ' , @v_usu_id, Null,@cat_id  
  
  
/*20200414 sergio vado espinoza*/
  EXEC calcular_deudas @v_cat_nombre_corto, 1  
/*20200414 sergio vado espinoza*/


--MPR 20070422 fin  
  
  
SET @v_rep_total_err     = 0  
SET @v_rep_total_reg     = 0  
SET @v_rep_total_cum     = 0  
SET @v_rep_total_eventos = 0  
SET @v_rep_total_cmb_esc = 0  
SET @v_rep_total_cmb_est = 0  
SET @v_rep_total_cmb_etg = 0  
SET @v_rep_total_cmb_scr = 0  
SET @v_rep_total_susp    = 0  
SET @v_rep_total_escala  = 0  
SET @v_rep_total_res_obj = 0  
  
  
  
  
  
  
CREATE TABLE #tmp_asimil (sob_id INT)   
DECLARE #cur_reg CURSOR FOR  
 SELECT reg_id,reg_tipo,reg_orden,reg_esc_res,reg_est_res,reg_scr,reg_susp,reg_query,reg_escala,reg_res_obj,reg_usu_res,reg_ges,reg_esc,reg_etg,reg_est,reg_eval_susp,reg_cont_eval, reg_reval_esc,reg_kit   
 FROM  
  (  
  SELECT  
   CASE reg_tipo WHEN 'R' THEN 11 WHEN 'G' THEN 12 WHEN 'E' THEN 13 WHEN 'D' THEN 14 ELSE 19 END reg_seccion,  
   reg_id,reg_tipo,reg_orden,reg_esc_res,reg_est_res,reg_scr,reg_susp,reg_query,reg_escala,reg_res_obj,reg_usu_res,reg_ges,reg_esc,reg_etg,reg_est,reg_eval_susp,reg_cont_eval, reg_reval_esc,  
   est_orden,reg_kit  
  FROM  
   wf_reglas  
   INNER JOIN wf_estados ON reg_est = est_id  
  WHERE  
   reg_clase = 'E'  
   AND reg_obs = 'APERTURA'  
   AND reg_baja_fecha IS NULL  
   AND reg_kit=@cat_kit --MPR 20070422  
  UNION  
  SELECT  
   CASE reg_tipo WHEN 'R' THEN 21 WHEN 'G' THEN 22 WHEN 'E' THEN 23 WHEN 'D' THEN 24 ELSE 29 END reg_seccion,  
   reg_id,reg_tipo,reg_orden,reg_esc_res,reg_est_res,reg_scr,reg_susp,reg_query,reg_escala,reg_res_obj,reg_usu_res,reg_ges,reg_esc,reg_etg,reg_est,reg_eval_susp,reg_cont_eval, reg_reval_esc,  
   est_orden,reg_kit  
  FROM  
   wf_reglas  
   INNER JOIN wf_estados ON reg_est = est_id  
  WHERE  
   reg_clase = 'E'  
   AND reg_obs <> 'APERTURA'  
   AND reg_obs <> 'CIERRE'  
   AND reg_baja_fecha IS NULL  
   AND reg_kit=@cat_kit --MPR 20070422  
  UNION  
  SELECT  
   CASE reg_tipo WHEN 'D' THEN 31 WHEN 'E' THEN 32 WHEN 'G' THEN 33 WHEN 'R' THEN 34 ELSE 39 END reg_seccion,  
   reg_id,reg_tipo,reg_orden,reg_esc_res,reg_est_res,reg_scr,reg_susp,reg_query,reg_escala,reg_res_obj,reg_usu_res,reg_ges,reg_esc,reg_etg,reg_est,reg_eval_susp,reg_cont_eval, reg_reval_esc,  
   est_orden,reg_kit  
  FROM  
   wf_reglas  
   INNER JOIN wf_estados ON reg_est = est_id  
  WHERE  
   reg_clase = 'E'  
   AND reg_obs = 'CIERRE'  
   AND reg_baja_fecha IS NULL  
   AND reg_kit = @cat_kit --MPR 20070422  
  ) tmp_reg  
 where not tmp_reg.reg_kit is null  
 ORDER BY  
  reg_seccion,  
  reg_ges,  
  reg_esc,  
  reg_etg,  
  --reg_est,  
  est_orden,  
  reg_orden  
  
OPEN #cur_reg  
  
FETCH NEXT FROM #cur_reg INTO   
 @c_reg_id,@c_reg_tipo, @c_reg_orden, @c_reg_esc_res, @c_reg_est_res,   
 @c_reg_scr, @c_reg_susp, @c_reg_query, @c_reg_escala, @c_reg_res_obj,   
 @c_reg_usu_res, @c_reg_ges, @c_reg_esc, @c_reg_etg, @c_reg_est,   
 @c_reg_eval_susp, @c_reg_cont_eval, @c_reg_reval_esc,@c_reg_kit /*CP 26/2/2007*/  
  
  
WHILE @@FETCH_STATUS = 0   
BEGIN  
 INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','  Procesa regla: ' + CAST(@c_reg_id AS VARCHAR(10)), @v_usu_id, Null, @cat_id  
  
 SELECT @v_rep_total_reg = @v_rep_total_reg + 1  
     SELECT @v_re_evaluar = 0  
   
 TRUNCATE TABLE #tmp_asimil   
 IF  @c_reg_tipo = 'R'   
 BEGIN  
  
  --SELECT @v_cons = 'SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat in (select CAT_ID from carteras where cat_baja_fecha is null and cat_kit=' + CONVERT(varchar,@c_reg_kit)+ ')' + ' AND '  
    SELECT @v_cons = 'SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =' + convert(varchar,@cat_id) + ' AND '  
  IF @c_reg_eval_susp <> 'S'   
  BEGIN  
   SELECT @v_cons = @v_cons + '(sob_fec_susp IS NULL OR sob_fec_susp <=  ''' +   LTRIM(RTRIM( CONVERT(char, @v_fec_proceso,112)))   + ''' ) AND '  
  END  
  SELECT @v_cons = @v_cons + '(cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  ''' +   LTRIM(RTRIM( CONVERT(char, @v_fec_proceso,112)))   + ''') AND esc_susp = ''N'' AND est_inactivo = ''N'' AND '  + @c_reg_query  
 END   
 ELSE IF @c_reg_tipo = 'G'   
 BEGIN  
  --SELECT @v_cons = 'SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat in (select CAT_ID from carteras where cat_baja_fecha is null and cat_kit=' + CONVERT(varchar,@c_reg_kit)+ ')' + ' AND esc_ges = ' + CONVERT(char(5),@c_reg_ges)  
  SELECT @v_cons = 'SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =' + convert(varchar,@cat_id) + ' AND esc_ges = ' + CONVERT(char(5),@c_reg_ges)  
  IF @c_reg_eval_susp <> 'S'   
  BEGIN    -- SELECT @v_cons = @v_cons + ' AND (cta_fec_susp IS NULL OR cta_fec_susp <=  ''' +   LTRIM(RTRIM( CONVERT(char, @v_fec_proceso,112)))   + ''')'  
   SELECT @v_cons = @v_cons + ' AND (sob_fec_susp IS NULL OR sob_fec_susp <=  ''' +   LTRIM(RTRIM( CONVERT(char, @v_fec_proceso,112)))   + ''')'  
  END  
  SELECT @v_cons = @v_cons + ' AND (cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  ''' +   LTRIM(RTRIM( CONVERT(char, @v_fec_proceso,112)))   + ''') AND esc_susp = ''N'' AND est_inactivo = ''N'' AND ' + @c_reg_query  
 END   
 ELSE IF @c_reg_tipo = 'E'   
 BEGIN  
         --SELECT @v_cons = 'SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat in (select CAT_ID from carteras where cat_baja_fecha is null and cat_kit=' + CONVERT(varchar,@c_reg_kit)+ ')' + ' AND sob_esc = ' + CONVERT(char(5),@c_reg_esc)  
  SELECT @v_cons = 'SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =' + convert(varchar,@cat_id) + ' AND sob_esc = ' + CONVERT(char(5),@c_reg_esc)  
         IF @c_reg_eval_susp <> 'S'   
  BEGIN  
   SELECT @v_cons = @v_cons + ' AND (sob_fec_susp IS NULL OR sob_fec_susp <=  ''' +   LTRIM(RTRIM( CONVERT(char, @v_fec_proceso,112)))   + ''')'  
  END  
  SELECT @v_cons = @v_cons + ' AND (cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  ''' +   LTRIM(RTRIM( CONVERT(char, @v_fec_proceso,112)))   + ''') AND esc_susp = ''N'' AND est_inactivo = ''N'' AND ' + @c_reg_query  
 END   
 ELSE IF @c_reg_tipo = 'D'   
 BEGIN  
--  SELECT @v_cons = 'SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat in (select CAT_ID from carteras where cat_baja_fecha is null and cat_kit=' + CONVERT(varchar,@c_reg_kit) + ')' + ' and sob_etg = ' + CONVERT(char(5),@c_reg_etg) + ' AND sob_est = ' + CONVERT(char(5),@c_reg_est)  
  SELECT @v_cons = 'SELECT cta_id FROM wf_vw_dic_datos WHERE cta_cat =' + convert(varchar,@cat_id) + ' AND sob_etg = ' + CONVERT(char(5),@c_reg_etg) + ' AND sob_est = ' + CONVERT(char(5),@c_reg_est)  
  IF @c_reg_eval_susp <> 'S'   
  BEGIN  
   SELECT @v_cons = @v_cons + ' AND (sob_fec_susp IS NULL OR sob_fec_susp <= ''' +   LTRIM(RTRIM( CONVERT(char, @v_fec_proceso,112)))   + ''')'  
  END  
  SELECT @v_cons = @v_cons + ' AND (cta_lockeo_fec_hora IS NULL OR cta_lockeo_fec_hora <  ''' +  LTRIM(RTRIM( CONVERT(char, @v_fec_proceso,112)))   + ''') AND esc_susp = ''N'' AND est_inactivo = ''N'' AND ' + @c_reg_query  
 END  
  

SELECT @sql = 'DECLARE #cur_cta CURSOR FAST_FORWARD FOR ' + @v_cons  

--no core --------------------------------------------------------
 SET @v_fec_ejecucion_inicio=getdate()
 SET @v_hora = getdate()
 SET @v_rep_total_cta = 0
--no core -------------------------------------------------

--exec  (@v_cons)
 
 EXEC (@sql)
 --EXEC sp_executesql @sql  JAD 22/9

 SELECT @v_cod_ret = @@error  
 SELECT  @@error  as error

--no core --------------------------------------------------------
 SET @v_fec_ejecucion_consulta=getdate()
--no core --------------------------------------------------------
  
 OPEN #cur_cta  
--no core --------------------------------------------------------
 SET @v_fec_ejecucion_open_cur=getdate()
 SET @v_ctas_atrapadas=@@CURSOR_ROWS
--no core -------------------------------------------------------- 
 FETCH #cur_cta INTO @c_cta_id  
--no core --------------------------------------------------------
 SET @v_fec_ejecucion_fetch_cur=getdate()
--no core --------------------------------------------------------

 WHILE @@FETCH_STATUS = 0   
 BEGIN
  SET @error_tran = 0  
  BEGIN TRANSACTION  
--no core --------------------------------------------------------
  SET @v_rep_total_cta = @v_rep_total_cta + 1
--no core --------------------------------------------------------

  SELECT @v_rep_total_cum = @v_rep_total_cum + 1  
    
  SELECT  
   @c_cta_esc     = sob_esc,  
   @c_cta_etg     = sob_etg,  
   @c_cta_est     = sob_est,  
   @c_cta_scr     = sob_scr,  
   @c_cta_usu_res = sob_usu_res  
  FROM   
   wf_sit_objetos   
  WHERE   
   sob_id = @c_cta_id  

  -- Inicio Recorre eventos consecuentes de la regla  
  DECLARE #cur_exr CURSOR FOR  
   SELECT   
    exr_evento,   
    exr_dias_min,   
    exr_param  
   FROM   
    wf_eventos_x_reg  
   WHERE   
    exr_reg = @c_reg_id   
    AND exr_baja_fecha IS NULL  
    
  OPEN #cur_exr  
  FETCH NEXT FROM #cur_exr INTO @c_exr_evento, @c_exr_dias_min, @c_exr_param  
  WHILE @@FETCH_STATUS = 0   
  BEGIN  
  
   SELECT @v_fec_aux = GETDATE()  
  
   EXEC dbo.wf_eventos_proceso_insert_2    
    @c_cta_id,       --@v_evp_sob                       int,  
    @c_exr_evento,   --@v_evp_evento                    varchar(10),  
    @c_exr_param,    --@v_evp_param                     varchar(30),  
    @c_exr_dias_min, --@v_evp_dias_min                  int,  
    @c_reg_id,       --@v_evp_reg                       int,  
    @v_fec_aux,      --@v_evp_alta_fecha                datetime,  
    @v_usu_id,   --@v_evp_usu_id                    int,  
    '',              --@v_evp_filler                    varchar(255),  
    @error_aux       --@v_cod_ret                    int out  
  
   IF @error_tran = 0 AND @error_aux <> 0   
    SET @error_tran = @error_aux  
   ELSE  
    SELECT @v_rep_total_eventos = @v_rep_total_eventos + 1  
   
   FETCH NEXT FROM #cur_exr INTO @c_exr_evento, @c_exr_dias_min, @c_exr_param  
  END      
  CLOSE #cur_exr  
  DEALLOCATE #cur_exr  
  -- Fin Recorre eventos consecuentes de la regla  
  
  -- La regla tiene como consecuente la re-evaluación del escenario  
  IF @c_reg_reval_esc <> 0  
  BEGIN  
   INSERT #tmp_asimil SELECT @c_cta_id  -- Deja la cuenta preparada para una re-asimilación  
   SET @error_aux = @@error  
   IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux  
  
   SELECT @v_re_evaluar = 1  
  END -- Fin re-evaluación del escenario  

  -- La regla tiene como consecuente un cambio de escenario  
  IF @c_reg_esc_res <> 0 AND @c_reg_esc_res <> @c_cta_esc   
  BEGIN  
   -- Cambia el escenario de la cuenta  
   EXEC dbo.wf_cmb_objetos_auto   
    @c_cta_id,      --@v_sob_id int,  
    'sob_esc',      --@v_tipo varchar(20),  
    @c_reg_esc_res, --@v_id_nuevo int,  
    @c_reg_id, --@v_reg_id int,  
    @v_usu_id,  --@v_usu_id int,  
    '',  
    @error_aux      --@v_cod_ret int OUT  
   IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux  

   UPDATE  
    wf_sit_objetos  
   SET  
    sob_esc        = @c_reg_esc_res,  
    sob_fec_esc    = @v_fec_proceso,  
    sob_modi_fecha = GETDATE(),  
    sob_usu_id     = @v_usu_id  
   WHERE  
    sob_id = @c_cta_id  
  
   SET @error_aux = @@error  
   IF @error_tran = 0 AND @error_aux <> 0   
    SET @error_tran = @error_aux  
   ELSE  
    SELECT @v_rep_total_cmb_esc = @v_rep_total_cmb_esc + 1  
  
   SELECT @v_esc_etg = esc_etg FROM wf_escenarios WHERE esc_id = @c_reg_esc_res  
   -- Si la estrategia default del nuevo escenario es distinta a la que tenía antes  
  
   IF @v_esc_etg <> @c_cta_etg   
   BEGIN  
   -- Cambia la estrategia de la cuenta a la estrategia estandar del escenario  
    EXEC dbo.wf_cmb_objetos_auto   
     @c_cta_id,     --@v_sob_id int,  
     'sob_etg',     --@v_tipo  varchar(20),  
     @v_esc_etg,    --@v_id_nuevo int,  
     @c_reg_id, --@v_reg_id int,  
     @v_usu_id, --@v_usu_id int,  
     '',  
     @error_aux     --@v_cod_ret int OUT  
    IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux  
      
    UPDATE  
     wf_sit_objetos  
    SET  
     sob_etg        = @v_esc_etg,  
     sob_fec_etg    = @v_fec_proceso,  
     sob_modi_fecha = GETDATE(),  
     sob_usu_id     = @v_usu_id  
    WHERE  
     sob_id = @c_cta_id  
  
    SET @error_aux = @@error  
    IF @error_tran = 0 AND @error_aux <> 0   
     SET @error_tran = @error_aux  
    ELSE  
     SET @v_rep_total_cmb_etg = @v_rep_total_cmb_etg + 1  
   END    -- Fin cambio estrategia  
  
   -- Si el cambio de escenario no trae un cambio de estado explícito hay que cambiar el estado al estado por default de la estrategia  
   IF @c_reg_est_res = 0 AND @c_reg_est_res <> @c_cta_est  
   BEGIN  
    SELECT @v_etg_est = etg_est FROM wf_estrategias WHERE etg_id = @v_esc_etg  
      
    -- Cambia el estado de la cuenta al estado default de la estrategia  
    EXEC dbo.wf_cmb_objetos_auto   
     @c_cta_id,     --@v_sob_id int,  
     'sob_est',     --@v_tipo varchar(20),  
     @v_etg_est,    --@v_id_nuevo int,  
     @c_reg_id, --@v_reg_id int,  
     @v_usu_id, --@v_usu_id int,  
     '',  
     @error_aux     --@v_cod_ret int OUT  
    IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux  
  
    UPDATE  
     wf_sit_objetos  
    SET  
     sob_est        = @v_etg_est,  
     sob_fec_est    = @v_fec_proceso,  
     sob_modi_fecha = GETDATE(),  
     sob_usu_id     = @v_usu_id  
    WHERE  
     sob_id = @c_cta_id  
  
    SET @error_aux = @@error  
    IF @error_tran = 0 AND @error_aux <> 0   
     SET @error_tran = @error_aux  
    ELSE  
     SET @v_rep_total_cmb_est = @v_rep_total_cmb_est + 1  
   END   -- Fin cambio de estado  
  END   -- Fin cambio escenario  
  
  -- La regla tiene como consecuente un cambio de estado  
  IF @c_reg_est_res <> 0 AND @c_reg_est_res <> @c_cta_est  
  BEGIN  
   EXEC dbo.wf_cmb_objetos_auto   
    @c_cta_id,      --@v_sob_id int,  
    'sob_est',      --@v_tipo varchar(20),  
    @c_reg_est_res, --@v_id_nuevo int,  
    @c_reg_id, --@v_reg_id int,  
    @v_usu_id,  --@v_usu_id int,  
    '',  
    @error_aux      --@v_cod_ret int OUT  
   IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux  
  
                 UPDATE  
    wf_sit_objetos  
                 SET  
    sob_est        = @c_reg_est_res,  
    sob_fec_est    = @v_fec_proceso,  
    sob_modi_fecha = GETDATE(),  
    sob_usu_id     = @v_usu_id  
                 WHERE  
    sob_id = @c_cta_id  
  
   SET @error_aux = @@error  
   IF @error_tran = 0 AND @error_aux <> 0   
    SET @error_tran = @error_aux  
   ELSE  
                  SET @v_rep_total_cmb_est = @v_rep_total_cmb_est + 1  
   
  END -- Fin cambio de estado  
  -- La regla tiene como consecuente un cambio de script  
  IF @c_reg_scr <> 0 AND @c_reg_scr <> @c_cta_scr  
  BEGIN  
   EXEC dbo.wf_cmb_objetos_auto   
    @c_cta_id,     --@v_sob_id int,  
    'sob_scr',     --@v_tipo varchar(20),  
    @c_reg_scr,    --@v_id_nuevo int,  
    @c_reg_id, --@v_reg_id int,  
    @v_usu_id, --@v_usu_id int,  
    '',  
    @error_aux     --@v_cod_ret int OUT    SET @error_aux = @@error  
   IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux  
   
   UPDATE  
    wf_sit_objetos  
   SET  
    sob_scr        = @c_reg_scr,  
    sob_modi_fecha = GETDATE(),  
    sob_usu_id     = @v_usu_id  
   WHERE  
    sob_id = @c_cta_id  
  
   SET @error_aux = @@error  
   IF @error_tran = 0 AND @error_aux <> 0   
    SET @error_tran = @error_aux  
   ELSE  
    SET @v_rep_total_cmb_scr = @v_rep_total_cmb_scr + 1  
   
  END -- Fin cambio de script  
 
  -- La regla tiene como consecuente la suspensión de la cuenta  
  IF @c_reg_susp <> 0  
  BEGIN  
   UPDATE  
    wf_sit_objetos  
   SET  
    sob_fec_susp   = dbo.emx_f_habiles(@v_fec_proceso,@c_reg_susp),  
    sob_modi_fecha = GETDATE(),  
    sob_usu_id     = @v_usu_id  
   WHERE  
    sob_id = @c_cta_id  
  
   SET @error_aux = @@error  
   IF @error_tran = 0 AND @error_aux <> 0   
    SET @error_tran = @error_aux  
   ELSE  
    SET @v_rep_total_susp = @v_rep_total_susp + 1  
  END   -- Fin suspension de la cuenta  
  
  -- La regla tiene como consecuente el escalamiento del responsable  
  IF @c_reg_escala <> 0  
  BEGIN  
   -- Jefe del rsponsable actual  
   SET @v_usu_res_nue = 0  
   SELECT @v_usu_res_nue = usu_jefe FROM wf_usuarios WHERE usu_id = @c_cta_usu_res  
       IF @v_usu_res_nue <> 0  
   BEGIN  
    EXEC dbo.wf_cmb_objetos_auto   
     @c_cta_id,      --@v_sob_id int,  
     'sob_usu_res',  --@v_tipo varchar(20),  
     @v_usu_res_nue, --@v_id_nuevo int,  
     @c_reg_id, --@v_reg_id int,  
     @v_usu_id,  --@v_usu_id int,  
     '',  
     @error_aux      --@v_cod_ret int OUT  
    IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux  
  
    UPDATE  
     wf_sit_objetos  
    SET  
     sob_usu_res    = @v_usu_res_nue,  
     sob_modi_fecha = GETDATE(),  
     sob_usu_id     = @v_usu_id  
    WHERE  
     sob_id = @c_cta_id  
  
    SET @error_aux = @@error  
    IF @error_tran = 0 AND @error_aux <> 0   
     SET @error_tran = @error_aux  
    ELSE  
     SET @v_rep_total_escala = @v_rep_total_escala + 1  
   END -- Fin nuevo responsable  
  END  -- Fin del bloque de escalamiento  
  -- La regla tiene como consecuente la asignación del responsable  
  -- Lucas: tambien desasigna responsable, en realidad asigna 0  
  IF @c_reg_res_obj <> 0 AND @c_reg_usu_res <> @c_cta_usu_res  
  BEGIN  
   EXEC dbo.wf_cmb_objetos_auto   
    @c_cta_id,      --@v_sob_id int,  
    'sob_usu_res',  --@v_tipo varchar(20),  
    @c_reg_usu_res, --@v_id_nuevo int,  
    @c_reg_id, --@v_reg_id int,  
    @v_usu_id,  --@v_usu_id int,  
    '',  
    @error_aux      --@v_cod_ret int OUT  
   IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux  
  
   UPDATE  
    wf_sit_objetos            
   SET  
    sob_usu_res    = @c_reg_usu_res,  
    sob_modi_fecha = GETDATE(),  
    sob_usu_id     = @v_usu_id  
   WHERE  
    sob_id = @c_cta_id  
  
   SET @error_aux = @@error  
   IF @error_tran = 0 AND @error_aux <> 0   
    SET @error_tran = @error_aux  
   ELSE  
    SET @v_rep_total_res_obj = @v_rep_total_res_obj + 1  
  END  -- Fin cambio de responsable  
  
  IF @c_reg_cont_eval <> 'S'   
  BEGIN  
   UPDATE   
    cuentas   
   SET   
    cta_lockeo_fec_hora =  @v_fec_proceso   
   WHERE   
    cta_id = @c_cta_id  
  
   SET @error_aux = @@error  
   IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux  
  END  
  
  IF @error_tran = 0  
  BEGIN  
   COMMIT TRANSACTION  
  END  
  ELSE  
  BEGIN  
   SET @v_rep_total_err = @v_rep_total_err + 1  
   ROLLBACK TRANSACTION  
  END     
  
  FETCH NEXT FROM #cur_cta INTO @c_cta_id   
  
 END    -- Fin Cursor de Cuentas  
  
 CLOSE #cur_cta  
 DEALLOCATE #cur_cta  
  
--no core --------------------------------------------------------
  INSERT INTO add_reglas_performance
  VALUES ( @v_fec_proceso, @v_fec_ejecucion_inicio,@v_fec_ejecucion_consulta, 
	   @v_fec_ejecucion_open_cur, @v_fec_ejecucion_fetch_cur, GETDATE(),
           @c_reg_id, datediff(ss, @v_fec_ejecucion_inicio,@v_fec_ejecucion_consulta)
           , datediff(ss, @v_fec_ejecucion_consulta,@v_fec_ejecucion_open_cur)
           , datediff(ss, @v_fec_ejecucion_open_cur,@v_fec_ejecucion_fetch_cur) 
           , datediff(ss, @v_fec_ejecucion_fetch_cur,getdate())
           , @v_ctas_atrapadas , @v_rep_total_cta , @v_cons)
--no core --------------------------------------------------------


 IF @v_re_evaluar = 1  
 BEGIN  
  INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'I','Inicia regla de reasimilación: '+ STR(@c_reg_id), @v_usu_id, Null,@cat_id  
  EXEC dbo.COM_wf_p_reasimilacion_escenarios   
   @v_fec_proceso,   
   @v_usu_id,  
   @c_reg_id,  
   @cat_id,  
  @v_cod_ret  
  INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'F','Finaliza regla de reasimilación: '+ STR(@c_reg_id), @v_usu_id, Null,@cat_id  
 END  
  

 UPDATE wf_reglas SET reg_filler='* ' + CONVERT(CHAR(20),GETDATE(),113) WHERE reg_id = @c_reg_id  
   
 FETCH NEXT FROM #cur_reg INTO   
  @c_reg_id,@c_reg_tipo, @c_reg_orden, @c_reg_esc_res, @c_reg_est_res,   
  @c_reg_scr, @c_reg_susp, @c_reg_query, @c_reg_escala, @c_reg_res_obj,   
  @c_reg_usu_res, @c_reg_ges, @c_reg_esc, @c_reg_etg, @c_reg_est,   
  @c_reg_eval_susp, @c_reg_cont_eval, @c_reg_reval_esc,@c_reg_kit /*CP 26/2/2007*/  
  
END -- Fin Cursor Reglas  
  
CLOSE #cur_reg  
DEALLOCATE #cur_reg  
  
DROP TABLE #tmp_asimil   
  
--Deslockear todo lo lockeado para esta cartera
UPDATE	
	cuentas 
SET	
	cta_lockeo_usu=0, 
	cta_lockeo_fec_hora=null, 
	cta_lockeo_id_session=null
WHERE	
	cta_baja_fecha is null 
	AND cta_cat=@cat_id

  
  
-- Reporte de totales procesados  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','      Reglas evaluadas......: '+STR(@v_rep_total_reg,12), @v_usu_id, Null,@cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','      Eventos insertadas....: '+STR(@v_rep_total_eventos,12), @v_usu_id, Null,@cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','      Cambios de escenario..: '+STR(@v_rep_total_cmb_esc,12), @v_usu_id, Null,@cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','      Cambios de estrategia.: '+STR(@v_rep_total_cmb_etg,12), @v_usu_id, Null,@cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','      Cambios de estado.....: '+STR(@v_rep_total_cmb_est,12), @v_usu_id, Null,@cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','      Cambios de script.....: '+STR(@v_rep_total_cmb_scr,12), @v_usu_id, Null,@cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','      Cuentas suspendidas...: '+STR(@v_rep_total_susp,12), @v_usu_id, Null,@cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','      Escalamientos.........: '+STR(@v_rep_total_escala,12), @v_usu_id, Null,@cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','      Cambios de Responsable: '+STR(@v_rep_total_res_obj,12), @v_usu_id, Null,@cat_id  
  
SELECT @v_cod_ret = 0  
IF @v_rep_total_err > 0   
BEGIN  
 INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','      Cuentas con error.....: ' + CONVERT(VARCHAR(8),@v_rep_total_err), @v_usu_id, Null,@cat_id  
 SET @v_cod_ret = 50000  
END  
  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A',' ', @v_usu_id, Null,@cat_id  
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'F','PROCESO EVALUACION DE REGLAS - FINALIZADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id, @v_cod_ret,@cat_id  
  
/*===========================================*/  
Exec wf_p_eval_eventos @v_fec_proceso,  
   @v_usu_id,  
   @cat_id,  
   @v_cod_ret OUT  
/*===========================================*/  
  
-- MPR 20070422 Inicio  
FETCH NEXT FROM #cur_cat INTO @cat_id,@cat_kit,@v_cat_nombre_corto  
END  
CLOSE #cur_cat  
DEALLOCATE #cur_cat  
  
-- MPR 20070422 Fin  
  
SET NOCOUNT OFF

GO
