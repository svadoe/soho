--[
CREATE PROCEDURE [dbo].[calcular_deudas] (
  @cat_nombre_corto VARCHAR(20),
  @v_cod_ret        INT OUT
) AS

  /*
    20200413 sergio vado espinoza: Proyecto de optimización de procesos
                   
    calcular_deudas: - calcula deudas a nivel de cuentas y de personas.
                     - recibe como parametro el nombre corto de la catera y un código de error 

    Procedure que calcula las deudas de los clientes a nivel de producto y de persona.
    Los resultados se guardan en dos tablas que se llenan cada vez que se ejecuta este
    procedure.  Las tablas son: cueta_deuda para las deudas a nivel de cuenta y
    persona_deuda para la deuda a nivel de persona.

    Las deudas calculadas se pasan e insertan en las tablas en moneda peso.
  */

  INSERT wf_print_out SELECT 'CALCDEUDA',GETDATE(),GETDATE(),'I','PROCESO CALCULO DUEUDAS - INICIADO. Cartera: ' + @cat_nombre_corto, 1, Null, 0  


  /* Inicia drop de tablas e indices */ 
  IF EXISTS(SELECT * FROM sys.indexes WHERE name='idx_cuenta_deuda_per' AND object_id = OBJECT_ID('dbo.cuenta_deuda'))
    DROP INDEX idx_cuenta_deuda_per ON cuenta_deuda
  
  IF EXISTS(SELECT * FROM sys.tables WHERE name='cuenta_deuda' AND object_id = OBJECT_ID('dbo.cuenta_deuda'))
    DROP TABLE cuenta_deuda
  
  IF EXISTS(SELECT * FROM sys.tables WHERE name='persona_deuda' AND object_id = OBJECT_ID('dbo.persona_deuda'))
    DROP TABLE persona_deuda
  /* Fin drop de tablas e indices */ 



  /* Inicia calculo de deuda a nivel de cuentas */
  INSERT wf_print_out SELECT 'CALCDEUDA',GETDATE(),GETDATE(),'I','  CALCULO DUEUDAS NIVEL CUENTAS - INICIADO.', 1, Null, 0  
  CREATE TABLE [dbo].[cuenta_deuda] (
    cta_id           INTEGER PRIMARY KEY,
    cta_per          INTEGER NOT NULL,
    cta_deuda_total  NUMERIC (16, 2),
    cta_deuda_venc   NUMERIC (16,2),
    cta_deuda_a_venc NUMERIC (16,2)
  )
  
  DECLARE @cat_id INTEGER = (SELECT cat_id FROM carteras WHERE cat_nombre_corto = @cat_nombre_corto AND cat_baja_fecha IS NULL)
  
  INSERT INTO
    cuenta_deuda
  SELECT
    cta_id,
    cta_per,
    COALESCE(dbo.emx_f_pasar_a_moneda_pais(cta_deuda_venc + CASE WHEN cta_deuda_a_venc > 0 THEN cta_deuda_a_venc ELSE 0 END, cta_mon),0),
    COALESCE(dbo.emx_f_pasar_a_moneda_pais(cta_deuda_venc,cta_mon),0),
    COALESCE(dbo.emx_f_pasar_a_moneda_pais((CASE WHEN cta_deuda_a_venc > 0 THEN cta_deuda_a_venc ELSE 0 END),cta_mon),0)
  FROM
    cuentas
  WHERE 
    cta_cat = @cat_id AND cta_baja_fecha IS NULL
  
  CREATE INDEX idx_cuenta_deuda_per ON cuenta_deuda (cta_per)

  DECLARE @num_records VARCHAR(16) = (SELECT CAST(COUNT(*) AS VARCHAR(16)) FROM cuenta_deuda)
  INSERT wf_print_out SELECT 'CALCDEUDA',GETDATE(),GETDATE(),'F','  CALCULO DUEUDAS NIVEL CUENTAS - FINALIZADO. Registros: ' + @num_records, 1, Null, 0  

  /* Fin calculo de deuda a nivel de cuentas */


  /* Inicia calculo de deuda a nivel de personas */
  INSERT wf_print_out SELECT 'CALCDEUDA',GETDATE(),GETDATE(),'I','  CALCULO DUEUDAS NIVEL PERSONA - INICIADO.', 1, Null, 0  

  CREATE TABLE [dbo].[persona_deuda] (
    per_id           INTEGER PRIMARY KEY,
    per_deuda_total  NUMERIC (16, 2),
    per_deuda_venc   NUMERIC (16,2),
    per_deuda_a_venc NUMERIC (16,2)
  )
  
  INSERT INTO
    persona_deuda
  SELECT
    cta_per,
    SUM(cta_deuda_total)  AS cta_deuda_total,
    SUM(cta_deuda_venc)   AS cta_deuda_venc,
    SUM(cta_deuda_a_venc) AS cta_deuda_a_venc
  FROM
    cuenta_deuda
  GROUP BY
    cta_per

  SELECT @num_records = CAST(COUNT(*) AS VARCHAR(16)) FROM persona_deuda
  INSERT wf_print_out SELECT 'CALCDEUDA',GETDATE(),GETDATE(),'F','  CALCULO DUEUDAS NIVEL PERSONA - FINALIZADO. Registros: ' + @num_records, 1, Null, 0  

  /* Fin calculo de deuda a nivel de personas */
  
  INSERT wf_print_out SELECT 'CALCDEUDA',GETDATE(),GETDATE(),'F','PROCESO CALCULO DUEUDAS - FINALIZADO. Cartera: ' + @cat_nombre_corto, 1, Null, 0  
  
  SELECT @v_cod_ret = @@error
  /* Fin */
GO

--]

