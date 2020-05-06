SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  
  [dbo].[aux_tj_ptm_dias_vencimiento_insert] (  
    @v_cod_ret INT OUT  
  )  
AS  
  -- 20200320 sergio vado espinoza se agrega:  or substring(per_filler, 140,3) = 'DIA'
  -- 20200303 sergio vado espinoza: muestra tarjetas cuyo estado es 'N','I','B', 'M','T'
  -- 20190924 sergio vado espinoza  
  -- aux_tj_ptm_dias_vencimiento_insert puebla la tabla aux_tj_ptm_dias_vencimiento la cual   
  -- almacena los días de vencimienot de las tarjetad de crédito y de los préstamos.  
  -- Para las tarjetas de crédito se inserta la cantindad de días de vencimiento para la   
  -- próxima cuota a vencer.  
  -- Para los prestamos se inserta la cantidad de días desde la fecha de proceso a la   
  -- 20200108 se agrega el campo pago minimo a vencer.  
  
  DECLARE @fecha_proceso DATETIME  
  SELECT @fecha_proceso = prt_valor FROM wf_parametros WHERE prt_nombre_corto = 'FECCIE'  
    
  INSERT INTO wf_print_out(pto_proceso, pto_fec_hora, pto_fec_proceso, pto_indicador, pto_texto, pto_usu_id)  
  SELECT  
         'TJPTMVENC'                                        AS pto_proceso,  
         getdate()                                          AS pto_fec_hora,  
         @fecha_proceso                                     AS pto_fec_proceso,  
         'I'                                                AS pto_indicador,  
         'INICIO llenado tabla aux_tj_ptm_dias_vencimiento' AS pto_texto,  
         0                                                  AS usu_id  
  
  TRUNCATE TABLE aux_tj_ptm_dias_vencimiento;  
  
  INSERT INTO aux_tj_ptm_dias_vencimiento(tpv_per, tpv_cta, tpv_producto, tpv_dias, tpv_pago_minimo)  
    SELECT  
           cta_per,  
           cta_id,  
           'TJ',  
           dbo.emx_f_cantidad_dias_habiles(@fecha_proceso,MAX(tcv_fecha)),  
     tcv_pago_min  
    FROM  
           tarjetas_venc  
           INNER JOIN tarjetas ON tcv_taj = taj_id  
           INNER JOIN cuentas  ON taj_cta = cta_id  
    WHERE  
           tcv_baja_fecha IS NULL  
           AND taj_baja_fecha IS NULL  
           AND cta_baja_fecha IS NULL  
           AND taj_estado IN ('N','I','B', 'M','T') --20200303 sergio vado espinoza
     and cta_cat = 2  
    GROUP BY cta_per, cta_id, tcv_pago_min  
    HAVING MAX(tcv_fecha) >= @fecha_proceso   
    UNION  
    SELECT  
           cta_per,  
           cta_id,  
           'PTM',  
           dbo.emx_f_cantidad_dias_habiles(@fecha_proceso,MIN(pcu_venc_fecha)),  
     (SELECT top 1 pcu_importe + pcu_intereses  
    from prestamos_cuotas  
    inner join prestamos on  pcu_ptm = ptm_id  
    where ptm_baja_fecha is null and pcu_baja_fecha is null and pcu_estado = 'A' and  pcu_venc_fecha >= @fecha_proceso and ptm_cta=cta_id   
    order by pcu_venc_fecha)  
    FROM  
           prestamos_cuotas   
           INNER JOIN prestamos ON pcu_ptm = ptm_id  
           INNER JOIN cuentas   ON ptm_cta = cta_id  
    WHERE  
           pcu_baja_fecha IS NULL  
           AND ptm_baja_fecha IS NULL  
           AND cta_baja_fecha IS NULL  
           AND pcu_estado = 'A'  
     and cta_cat = 2 -- select * from carteras  
    GROUP BY cta_per, cta_id  
    HAVING MIN(pcu_venc_fecha) >= @fecha_proceso   

 INSERT INTO wf_print_out(pto_proceso, pto_fec_hora, pto_fec_proceso, pto_indicador, pto_texto, pto_usu_id)  
 SELECT  
         'TJPTMVENC'                                      AS pto_proceso,  
         getdate()                                        AS pto_fec_hora,  
         @fecha_proceso                                   AS pto_fec_proceso,  
         'A'                                              AS pto_indicador,  
         'Inserto cuentas RB no insertadas antes'    AS pto_texto,  
         0                                                AS usu_id  


   insert into aux_tj_ptm_dias_vencimiento(tpv_per, tpv_cta) 
   select cta_per, cta_id
   from cuentas inner join personas on cta_per=per_id
   where (substring(per_filler, 132,4) = 'PROV' or substring(per_filler, 136,4) = 'CRED' or substring(per_filler, 140,3) = 'DIA') and per_baja_fecha is null and cta_baja_fecha is null and cta_cat=2 --20200320
   and cta_id not in (select tpv_Cta from aux_tj_ptm_dias_vencimiento)
  
 INSERT INTO wf_print_out(pto_proceso, pto_fec_hora, pto_fec_proceso, pto_indicador, pto_texto, pto_usu_id)  
 SELECT  
         'TJPTMVENC'                                      AS pto_proceso,  
         getdate()                                        AS pto_fec_hora,  
         @fecha_proceso                                   AS pto_fec_proceso,  
         'A'                                              AS pto_indicador,  
         'Actualización del Ámbito de Cuentas'    AS pto_texto,  
         0                                                AS usu_id  
  
 --actualización ámbito nicho/benchmark para Cuentas RB  
 update aux_tj_ptm_dias_vencimiento   
  set tpv_amb= (case when  
  --la cuenta es un prestamo y tiene su primer cuota del prestamo vencida  
  (select top 1 1 from prestamos  
  inner join prestamos_cuotas on ptm_id = pcu_ptm             
  where ptm_cta = tpv_cta and pcu_numero=1 and pcu_Estado = 'V' and ptm_baja_fecha is null and pcu_baja_fecha is null) = 1  
  or  
  --la cuenta es un prestamo y tiene su segunda cuota del prestamo vencida  
  (select top 1 1 from prestamos  
  inner join prestamos_cuotas on ptm_id = pcu_ptm             
  where ptm_cta = tpv_cta and pcu_numero=2 and pcu_Estado = 'V' and ptm_baja_fecha is null and pcu_baja_fecha is null) = 1  
  or  
  --la cuenta es una tarjeta y el cliente debe > $4000   
  ((select top 1 1 from tarjetas where taj_cta = tpv_cta and taj_baja_fecha is null AND taj_estado IN ('N','I','B', 'M','T')) = 1 and   --202003 sergio vado espinoza
  (select sum(cta_deuda_venc) from cuentas  
  where cta_per =tpv_per and cta_baja_fecha is null) > 4000)  
  then 1 else 2 end)  
 where tpv_cta in (select cta_id from cuentas  
   where cta_baja_fecha IS NULL and cta_cat = 2   
   and ISNULL((select case count (*) when 0 then 'N' ELSE 'S' END from personas where per_id=cta_per and (substring(per_filler, 132,4) = 'PROV' or substring(per_filler, 136,4) = 'CRED' or substring(per_filler, 140,3) = 'DIA') and per_baja_fecha is null),'N') = 'S' --Cliente RB --20200320
   )  
  
  
  DECLARE @num_tj  VARCHAR(10) = (SELECT CONVERT(VARCHAR(10),COUNT(*)) FROM aux_tj_ptm_dias_vencimiento WHERE tpv_producto = 'TJ')  
  DECLARE @num_ptm VARCHAR(10) = (SELECT CONVERT(VARCHAR(10),COUNT(*)) FROM aux_tj_ptm_dias_vencimiento WHERE tpv_producto = 'PTM')  
  
  INSERT INTO wf_print_out(pto_proceso, pto_fec_hora, pto_fec_proceso, pto_indicador, pto_texto, pto_usu_id)  
  SELECT  
         'TJPTMVENC'                                      AS pto_proceso,  
         getdate()                                        AS pto_fec_hora,  
         @fecha_proceso                                   AS pto_fec_proceso,  
         'A'                                              AS pto_indicador,  
         @num_tj + ' registros de tarjetas insertados'    AS pto_texto,  
         0                                                AS usu_id  
  
  INSERT INTO wf_print_out(pto_proceso, pto_fec_hora, pto_fec_proceso, pto_indicador, pto_texto, pto_usu_id)  
  SELECT  
         'TJPTMVENC'                                      AS pto_proceso,  
         getdate()                                        AS pto_fec_hora,  
         @fecha_proceso                                   AS pto_fec_proceso,  
         'A'                                              AS pto_indicador,  
         @num_ptm + ' registros de prestamos insertados'  AS pto_texto,  
         0                                                AS usu_id  
    
  INSERT INTO wf_print_out(pto_proceso, pto_fec_hora, pto_fec_proceso, pto_indicador, pto_texto, pto_usu_id)  
  SELECT  
         'TJPTMVENC'                                      AS pto_proceso,  
         getdate()                                        AS pto_fec_hora,  
         @fecha_proceso                                   AS pto_fec_proceso,  
         'F'                                              AS pto_indicador,  
         'FIN llenado tabla aux_tj_ptm_dias_vencimiento'  AS pto_texto,  
         0                                                AS usu_id  
  
    
    SELECT @v_cod_ret = @@error  


GO
