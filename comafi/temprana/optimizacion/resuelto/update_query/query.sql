BEGIN TRY
  BEGIN TRANSACTION

    UPDATE
      a
    SET
      a.sob_esc = 11,
      a.sob_etg= 11,
      a.sob_est= 22 ,
      a.sob_fec_esc= '2020-04-21 00:00:00.000',
      a.sob_fec_etg= '2020-04-21 00:00:00.000',
      a.sob_fec_est= '2020-04-21 00:00:00.000',
      a.sob_filler = 'Pedido del usuario Jose Arias'  
    FROM 
      wf_sit_objetos a
      INNER JOIN cuentas b ON a.sob_id = b.cta_id
    WHERE
      b.cta_cat = 2
      AND b.cta_cnl = 1012
      AND b.cta_p_modi_fecha >= '20200420'
      AND b.cta_fec_vto IS NOT NULL 
      AND (DATEDIFF(day, b.cta_fec_vto, CONVERT(DATE, CONVERT(VARCHAR(10),'20200421',112))))  >= 120
      AND b.cta_baja_fecha IS NULL        
      AND b.cta_linea NOT IN ('00888', '00777', '00666')

  COMMIT TRAN
END TRY
BEGIN CATCH

  IF @@TRANCOUNT > 0 ROLLBACK TRAN --RollBack in case of Error
   
  DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
  DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
  DECLARE @ErrorState INT = ERROR_STATE()

  RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

END CATCH

      SELECT CONVERT(DATE, CONVERT(VARCHAR(10),'20200421',112))

SELECT top 10 * FROM cuentas WHERE (DATEDIFF(day, cta_fec_vto, CONVERT(DATE, CONVERT(VARCHAR(10),'20200421',112))))  >= 120

