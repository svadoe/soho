DECLARE @cat_kit INTEGER = 3
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
   AND reg_reval_esc >0  --borrar borrar borrar borrar
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
   AND reg_reval_esc >0  --borrar borrar borrar borrar
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
   AND reg_kit=@cat_kit --MPR 20070422  
   AND reg_reval_esc >0  --borrar borrar borrar borrar
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
 
