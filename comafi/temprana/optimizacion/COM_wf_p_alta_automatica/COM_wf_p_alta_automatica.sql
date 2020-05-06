--LSG 2013
ALTER PROCEDURE [dbo].[COM_wf_p_alta_automatica] (
			@v_fec_proceso  DATETIME, 
			@v_usu_id_in	INT,
			@v_cat_nombre_corto	VARCHAR(10),
			@cod_ret        INT OUT 
)
AS 


SET NOCOUNT ON
--grac201903 se eliminan los controles de Personas de la siguiente manera
--		SELECT @cod_ret = 0 --grac201903
-- RETURN --grac201903
DECLARE @prc_nombre_corto varchar(10)
set @prc_nombre_corto='ALTA'

IF (@v_cat_nombre_corto is not null) and ((SELECT count(*)FROM carteras WHERE cat_baja_fecha IS NULL and cat_nombre_corto = @v_cat_nombre_corto) = 0)
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'I','PROCESO ALTA AUTOMATICA - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113),@v_usu_id_in, Null,0
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','PROCESO ABORTADO - No existe la cartera informada ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, Null,0
	SELECT @cod_ret = -1000
	RETURN
END

DECLARE @v_cat_id INT
set @v_cat_id = isnull((SELECT top 1 cat_id from carteras where cat_nombre_corto = @v_cat_nombre_corto),0)

IF (@v_cat_nombre_corto is null)
BEGIN
	SELECT @v_cat_nombre_corto = cat_nombre_corto from carteras where cat_id = 0
END

IF @v_fec_proceso IS NULL OR ISDATE(@v_fec_proceso)=0
BEGIN

	/* Obtencion del parámetro @v_fec_proceso */
	SELECT @v_fec_proceso = prt_valor FROM wf_parametros where prt_baja_fecha is null and prt_nombre_corto='FECCIE'
	
	IF @v_fec_proceso IS NULL OR ISDATE(@v_fec_proceso)=0
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'I','PROCESO ALTA AUTOMATICA - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113),@v_usu_id_in, Null, @v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),getdate(),'A','PROCESO ABORTADO - No existe fecha de proceso ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, Null, @v_cat_id
		SELECT @cod_ret = -1000
		RETURN
	END
	/* Fin Obtencion del parámetro @v_fec_proceso */

END

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'I','PROCESO ALTA AUTOMATICA - INICIADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113),@v_usu_id_in, Null,@v_cat_id
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Fecha Proceso: ' + CONVERT(CHAR(20),@v_fec_proceso,113),@v_usu_id_in, Null,@v_cat_id

DECLARE @v_tabla       VARCHAR(30)

DECLARE @cod_error     INT
DECLARE @Puntero       INT
DECLARE @v_usu_id      INT
DECLARE @v_temp        INT
DECLARE @v_regper      INT
DECLARE @v_regper_dom  INT
DECLARE @v_regper_doc  INT
DECLARE @v_regper_tel  INT
DECLARE @v_regcta      INT
DECLARE @v_regmov      INT
DECLARE @v_regmvv      INT
DECLARE @v_regsot      INT
DECLARE @v_regpea      INT
DECLARE @v_regcat      INT
DECLARE @v_regper_cta  INT
DECLARE @v_regptm      INT
DECLARE @v_regpcu      INT
DECLARE @v_regtaj      INT
DECLARE @v_regtcv      INT
DECLARE @v_regcca      INT
DECLARE @v_regchq      INT

DECLARE @v_count       INT

DECLARE @v_error       INT

DECLARE @error_tran    INT
DECLARE @error_aux     INT

DECLARE @#Enviados     INT
DECLARE @#Rechazados   INT
DECLARE @#Descartados  INT
DECLARE @#Ingresados   INT
DECLARE @#Actualizados INT

IF @v_usu_id_in IS NULL
	SET @v_usu_id = 1 --si viene nulo usamos usuario 1
ELSE
	SET @v_usu_id = @v_usu_id_in

-------------------------------------------------------------------------------------------------------------------------
--TABLA CONTROL  -  PENDIENTE DESARROLLO
-------------------------------------------------------------------------------------------------------------------------

--LV20200225 agrego para sumar los totales de credial a tablas normales

----declare @registros_cred bigint
---- select @registros_cred = convert(bigint,inctr_reg) from in_control where inctr_tab='in_cuentas_credial'

---- update in_Control set inctr_reg=right('0000000000' + convert(varchar,convert(bigint,inctr_reg)+@registros_cred),10)
---- where inctr_tab='in_cuentas'

----  select @registros_cred = convert(bigint,inctr_reg) from in_control where inctr_tab='in_tarjetas_venc_credial'

---- update in_Control set inctr_reg=right('0000000000' + convert(varchar,convert(bigint,inctr_reg)+@registros_cred),10)
---- where inctr_tab='in_tarjetas_venc'

----  select @registros_cred = convert(bigint,inctr_reg) from in_control where inctr_tab='in_tarjetas_credial'

---- update in_Control set inctr_reg=right('0000000000' + convert(varchar,convert(bigint,inctr_reg)+@registros_cred),10)
---- where inctr_tab='in_tarjetas'

----  select @registros_cred = convert(bigint,inctr_reg) from in_control where inctr_tab='in_movimientos_credial'

---- update in_Control set inctr_reg=right('0000000000' + convert(varchar,convert(bigint,inctr_reg)+@registros_cred),10)
---- where inctr_tab='in_movimientos'

---- delete from in_control where inctr_tab in ('in_cuentas_credial','in_movimientos_credial','in_tarjetas_credial','in_tarjetas_venc_credial')

 update in_cuentas set incta_suc='C874' where incta_cnl='121'
 update in_cuentas set incta_suc='C872' where incta_cnl='225'

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Procesamiento de Tabla de Control', @v_usu_id_in, Null,@v_cat_id

-- Chequeo de la existencia de registros en la tabla de control
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando la existencia de registros...', @v_usu_id_in, Null,@v_cat_id
IF not exists(SELECT 1 FROM in_control)
	BEGIN

		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! No hay registros en la tabla de control',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO'	,  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50000
		RETURN
	END
-- Chequeo de integridad del archivo
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando integridad del archivo...',  @v_usu_id_in, Null,@v_cat_id

-- Validacion nombre de archivos informados 
BEGIN
	SELECT @v_temp = 0

	SELECT @v_temp = 1
	WHERE Exists(	SELECT 	1 FROM in_control 
		WHERE inctr_tab NOT IN 
	(	'in_carteras', 
			'in_personas', 
			'in_per_dom', 
			'in_per_doc', 
			'in_per_tel', 
			'in_cuentas',		 
			'in_mov_x_mov',		 
			'in_movimientos',
			'in_wf_sob_atributos',
			'in_per_atributos',
			'in_per_cta',
			'in_per_x_cta', ----se agrego el 26/10 por PG para que no de error la interfaz dado que Comafi lo informa asi
			'in_prestamos',
			'in_prestamos_cuotas',
			'in_tarjetas',
			'in_tarjetas_venc',
			'in_corriente_ahorro',
			'in_cheques',
			'in_cca_ca'))



	IF @v_temp = 1 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! Nombre de Tabla no valido',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50001
		SELECT @cod_ret = 0 --grac202002
		--RETURN  --grac202002

 	END
END

-- Validacion dominio digitos fechas
BEGIN
	SELECT @v_temp = 0
	SELECT @v_temp = 1
	WHERE Exists(SELECT 1 FROM in_control WHERE LEN(LTRIM(inctr_fec_gen))<=0 OR LEN(LTRIM(inctr_fec_inf))<=0)

	IF @v_temp = 1 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! Fecha de generación o de informe no informada',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.', @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50002
		RETURN
	 END
END

-- Validacion dominio fechas
BEGIN
	SELECT @v_temp = 0
	SELECT @v_temp = 1
	WHERE 	EXISTS (SELECT 1 FROM in_control WHERE (ISDATE(inctr_fec_gen)= 0)	AND inctr_fec_gen<>'99999999') OR	-- Se acepta '99999999'
	       	EXISTS (SELECT 1 FROM in_control WHERE (ISDATE(inctr_fec_inf)= 0)	AND inctr_fec_inf<>'99999999')		-- Se acepta '99999999'

	IF @v_temp = 1 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! Fecha de generación o de informe no informada',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.', @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50003
	        RETURN
	 END
END

-- Validacion dominio totales
BEGIN
	SELECT @v_temp = 0
	SELECT @v_temp = 1
	WHERE Exists(SELECT 1 FROM in_control WHERE 	ISNUMERIC(inctr_fec_gen)=0 	OR 
							ISNUMERIC(inctr_fec_inf)=0 	OR 
							ISNUMERIC(inctr_reg) 	=0 	OR 
							ISNUMERIC(inctr_tot1)	=0 	OR 
							ISNUMERIC(inctr_tot2)	=0)

	IF @v_temp = 1 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! Campo numerico no valido.',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',  @v_usu_id_in, Null,@v_cat_id
	        SELECT @cod_ret = 50004
	        RETURN
	END
END

-------------------------------------------------------------------------------
--                           VALIDACION DE TOTALES            	    	     --
-------------------------------------------------------------------------------

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','VALIDACION DE TOTALES',  @v_usu_id_in, Null,@v_cat_id
-- Recuperacion totales de registros informados
BEGIN
	BEGIN	-- Carteras
	        SELECT @v_regcat = NULL
                SELECT @v_regcat = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_carteras'
	END

	BEGIN	-- Personas
	        SELECT @v_regper = NULL

                SELECT @v_regper = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_personas'
	END
	BEGIN	-- Personas Domicilios
	        SELECT @v_regper_dom = NULL
                SELECT @v_regper_dom = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_per_dom'
	END
	BEGIN	-- Personas Telefonos
	        SELECT @v_regper_tel = NULL
                SELECT @v_regper_tel = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_per_tel'
	END
	BEGIN	-- Personas Documentos
	        SELECT @v_regper_doc = NULL
                SELECT @v_regper_doc = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_per_doc'
	END
	BEGIN	-- Cuentas
	        SELECT @v_regcta = NULL
                SELECT @v_regcta = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_cuentas'
	END
	BEGIN	-- Movimientos
	        SELECT @v_regmov = NULL
                SELECT @v_regmov = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_movimientos'
	END
	BEGIN	-- Vinculacion de Movimientos
	        SELECT @v_regmvv = NULL
                SELECT @v_regmvv = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_mov_x_mov'
	END
	BEGIN	-- Atributos de Objetos
	        SELECT @v_regsot = NULL
                SELECT @v_regsot = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_wf_sob_atributos'
	END
	BEGIN	-- Atributos de Personas
	        SELECT @v_regpea = NULL
                SELECT @v_regpea = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_per_atributos'
	END
	BEGIN	-- Personas Vinculadas
		----        SELECT @v_regper_cta = NULL
			SET  @v_regper_cta = 0
		---         SELECT @v_regper_cta = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_per_x_cta'
	END
	BEGIN	-- Prestamos
	        SELECT @v_regptm = NULL
                SELECT @v_regptm = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_prestamos'
	END
	BEGIN	-- Prestamos Cuotas
	        SELECT @v_regpcu = NULL
                SELECT @v_regpcu = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_prestamos_cuotas'
	END
	BEGIN	-- Tarjetas
	        SELECT @v_regtaj = NULL
                SELECT @v_regtaj = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_tarjetas'
	END
	BEGIN	-- Tarjetas Vencimientos
	        SELECT @v_regtcv = NULL
                SELECT @v_regtcv = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_tarjetas_venc'
	END
	BEGIN	-- Cuentas Corrientes y Cajas de Ahorro
	        SELECT @v_regcca = NULL
                SELECT @v_regcca = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_corriente_ahorro'
	END
	BEGIN	-- Cheques
	        SELECT @v_regchq = NULL
                SELECT @v_regchq = CONVERT(INT,inctr_reg)  FROM in_control WHERE inctr_tab='in_cheques'
	END
	
END

BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de carteras...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_carteras
	IF (@v_regcat != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de carteras no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50005
		RETURN
	END

	SELECT @v_error = @@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de carteras. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		RETURN
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de carteras OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de personas
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de personas...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_personas

	IF (@v_regPer != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de personas no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO, pero lo hacemos seguir.',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50006
		SELECT @cod_ret = 0 --grac201903
		-- RETURN --grac201903
	END

	SELECT @v_error = @@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de personas. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de personas OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END


-- Validacion de totales de cuentas
BEGIN	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de cuentas...',  @v_usu_id_in, Null,@v_cat_id
	SELECT @v_count = COUNT(*) FROM in_cuentas
	IF (@v_regcta != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de cuentas no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50007
		SELECT @cod_ret = 0 --grac201903
		-- RETURN --grac20190
END
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de cuentas OK',  @v_usu_id_in, Null,@v_cat_id
END

-- Validacion de totales de teléfonos
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de teléfonos...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_per_tel
	IF (@v_regper_tel != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de teléfonos no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO., pero lo hacemos seguir',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50008
		SELECT @cod_ret = 0 --grac201903
		-- RETURN --grac201903
	END
	SELECT @v_error=@@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de teléfonos. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de teléfonos OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de domicilios
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de domicilios...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_per_dom
	IF (@v_regper_dom != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de domicilios no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO., pero lo hacemos seguir', @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50009
		SELECT @cod_ret = 0 --grac201903
		-- RETURN --grac201903
	END

	SELECT @v_error=@@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de domicilios. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de domicilios OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de documentos
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de documentos...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_per_doc
	IF (@v_regper_doc != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de documentos no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO., pero lo hacemos seguir', @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 0 --grac201903
		-- RETURN --grac201903
	END

	SELECT @v_error=@@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de documentos. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de documentos OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de movimientos
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de movimientos...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_movimientos
	IF (@v_regmov != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de movimientos no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.', @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50011
		SELECT @cod_ret = 0 --grac202002
		--RETURN --grac202002
	END

	SELECT @v_error=@@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de movimientos. PROCESO ABORTADO', @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de movimientos OK!', @v_usu_id_in, Null,@v_cat_id
	END
END


-- Validacion de totales de vinculaciones de movimientos
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de vinculaciones de movimientos...',@v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_mov_x_mov
	IF (@v_regmvv != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de vinculaciones de movimientos no se corresponde con la cantidad de registros enviados',@v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',@v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50012
		SELECT @cod_ret = 0 --grac202002
		--RETURN --grac202002
	END

	SELECT @v_error=@@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de movimientos. PROCESO ABORTADO',@v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de vinculaciones de movimientos OK!',@v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de atributos de objetos
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de atributos de objetos...',@v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_wf_sob_atributos
	IF (@v_regsot != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de atributos de objetos no se corresponde con la cantidad de registros enviados',@v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',@v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50013
		SELECT @cod_ret = 0 --grac202002
		--RETURN  --grac202002
	END

	SELECT @v_error=@@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de atributos de objetos. PROCESO ABORTADO',@v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de atributos de objetos OK!',@v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de atributos de personas
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de atributos de personas...',@v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_per_atributos
	IF (@v_regpea != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de atributos de personas no se corresponde con la cantidad de registros enviados',@v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',@v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50014
		SELECT @cod_ret = 0 --grac202002
		--RETURN --grac202002
	END

	SELECT @v_error=@@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de atributos de personas. PROCESO ABORTADO',@v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de atributos de personas OK!',@v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de personas vinculadas
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de personas vinculadas...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_per_x_cta
	IF (@v_regPer_cta != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de personas vinculadas no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO., pero lo hacemos seguir',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50015
		SELECT @cod_ret = 0 --grac201903
		-- RETURN --grac201903
	END

	SELECT @v_error = @@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de personas vinculadas. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de personas vinculadas OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de prestamos
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de prestamos...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_prestamos
	IF (@v_regptm != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de prestamos no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50016
		SELECT @cod_ret = 0 --grac202002
		--RETURN --grac202002
	END

	SELECT @v_error = @@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de prestamos. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de prestamos OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de prestamos cuotas
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de prestamos cuotas...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_prestamos_cuotas
	IF (@v_regpcu != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de prestamos cuotas no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50017
		SELECT @cod_ret = 0 --grac202002
		--RETURN --grac202002
	END

	SELECT @v_error = @@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de prestamos cuotas. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de prestamos cuotas OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de tarjetas
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de tarjetas...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_tarjetas
	IF (@v_regtaj != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de tarjetas no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50018
		SELECT @cod_ret = 0 --grac202002
		--RETURN --grac202002
	END

	SELECT @v_error = @@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de tarjetas. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de tarjetas OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de tarjetas vencimientos
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de tarjetas vencimientos...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_tarjetas_venc
	IF (@v_regtcv != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de tarjetas vencimientos no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50019
		SELECT @cod_ret = 0 --grac202002
		--RETURN --grac202002
	END

	SELECT @v_error = @@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de tarjetas vencimientos. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de tarjetas vencimientos OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de cuentas corrientes y cajas de ahorro
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de cuentas corrientes y cajas de ahorro...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_cca_ca
	IF (@v_regcca != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de cuentas corrientes y cajas de ahorro no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50020
		SELECT @cod_ret = 0 --grac202002
		--RETURN  --grac202002
	END

	SELECT @v_error = @@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de cuentas corrientes y cajas de ahorro. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de cuentas corrientes y cajas de ahorro OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de totales de cheques
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Chequeando totales de cheques...',  @v_usu_id_in, Null,@v_cat_id

	SELECT @v_count = COUNT(*) FROM in_cheques
	IF (@v_regchq != @v_count) BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! El total de control de registros de cheques no se corresponde con la cantidad de registros enviados',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50021
		SELECT @cod_ret = 0 --grac202002
		--RETURN  --grac202002
	END

	SELECT @v_error = @@Error
	IF @v_error <> 0 BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    ERROR en chequeo de totales de cheques. PROCESO ABORTADO',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = @v_error
		return
	END ELSE 
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Total de registros de cheques OK!',  @v_usu_id_in, Null,@v_cat_id
	END
END

-- Validacion de fecha a la que corresponde la informacion
SELECT 	@v_tabla = NULL
SELECT 	TOP 1 @v_tabla = inctr_tab
FROM	in_control
WHERE	(inctr_fec_inf <> '99999999') AND
	CONVERT(VARCHAR(8),@v_fec_proceso,112) <> CONVERT(VARCHAR(8),inctr_fec_inf,112)

IF @v_tabla IS NOT NULL
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! La fecha de proceso no coincide con la fecha a la que corresponde la informacion para la tabla ' + @v_tabla ,  @v_usu_id_in, Null,@v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.', @v_usu_id_in, Null,@v_cat_id
	SELECT @cod_ret = 50100
	SELECT @cod_ret = 0 --grac202003
	--RETURN  --grac202003
END
INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','    Fecha de proceso OK!',  @v_usu_id_in, Null,@v_cat_id




	--Se reemplaza el fin de registro del campo cartera por blanco --- Modificado por Pablo Gonzalia el 28/11/2007
	 
		update in_personas
		set inper_error_campo = replace(inper_error_campo,'*','')
		
		update in_wf_sob_atributos
		set insot_cat = replace(insot_cat,'*','')

		update in_cuentas
		set incta_cat = replace(incta_cat,'*','')

		update in_per_doc
		set inpdc_error_campo = replace(inpdc_error_campo,'*','')
		
		update in_per_tel
		set inpte_error_campo = replace(inpte_error_campo,'*','')

		update in_per_dom
		set inpdm_error_campo = replace(inpdm_error_campo,'*','')
		
		update in_movimientos
		set inmov_error_campo = replace(inmov_error_campo,'*','')

		update in_per_x_cta
		set inpxc_error_campo = replace(inpxc_error_campo,'*','')

		update in_prestamos
		set inptm_error_campo = replace(inptm_error_campo,'*','')

		update in_prestamos_cuotas
		set inpcu_error_campo = replace(inpcu_error_campo,'*','')

		update in_tarjetas
		set intaj_error_campo = replace(intaj_error_campo,'*','')

		update in_tarjetas_venc
		set intcv_error_campo = replace(intcv_error_campo,'*','')

		update in_cca_ca
		set incca_error_campo = replace(incca_error_campo,'*','')

		update in_cheques
		set inchq_error_campo = replace(inchq_error_campo,'*','')





-------------------------------------------------------------------------------
--                     VALIDACION DE DATOS Y TIPOS DE DATOS            	     --
-------------------------------------------------------------------------------
--VADIACION DE CARTERAS
IF (@v_regCat IS NOT NULL) AND @v_regCat > 0 
BEGIN
	--VALIDACIONES

	/* Rechaza registros con clave duplicada */
	UPDATE in_carteras SET incat_error='C', incat_error_campo='incat_clave' WHERE incat_clave IN (SELECT incat_clave FROM in_carteras GROUP BY incat_clave HAVING COUNT(1) > 1) AND (incat_error IS NULL OR RTRIM(incat_error) ='') 

	--Obligatorios
	UPDATE in_carteras SET incat_error='O', incat_error_campo='incat_clave' WHERE (LEN(LTRIM(incat_clave))=0) AND (incat_error IS NULL OR RTRIM(incat_error) ='') 
	UPDATE in_carteras SET incat_error='O', incat_error_campo='incat_codigo' WHERE (LEN(LTRIM(incat_codigo))=0) AND (incat_error IS NULL OR RTRIM(incat_error) ='') 
	UPDATE in_carteras SET incat_error='O', incat_error_campo='incat_nombre_corto' WHERE (LEN(LTRIM(incat_nombre_corto))=0) AND (incat_error IS NULL OR RTRIM(incat_error) ='') 
	UPDATE in_carteras SET incat_error='O', incat_error_campo='incat_nombre' WHERE (LEN(LTRIM(incat_nombre))=0) AND (incat_error IS NULL OR RTRIM(incat_error) ='') 
	UPDATE in_carteras SET incat_error='O', incat_error_campo='incat_kit' WHERE (LEN(LTRIM(incat_kit))=0) AND (incat_error IS NULL OR RTRIM(incat_error) ='') 
	UPDATE in_carteras SET incat_error='O', incat_error_campo='incat_ege' WHERE (LEN(LTRIM(incat_ege))=0) AND (incat_error IS NULL OR RTRIM(incat_error) ='') 

	--Tablas Relacionadas 
	UPDATE in_carteras SET incat_error='T', incat_error_campo='incat_kit' WHERE
	NOT EXISTS(SELECT kit_id FROM wf_kit WHERE kit_nombre_corto = incat_kit AND kit_baja_fecha IS NULL)
	AND (incat_error IS NULL OR RTRIM(incat_error) ='') 

	UPDATE in_carteras SET incat_error='T', incat_error_campo='incat_ege' WHERE
	NOT EXISTS(SELECT ege_id FROM wf_equipos_gestion WHERE ege_nombre_corto = incat_ege AND ege_baja_fecha IS NULL)
	AND (incat_error IS NULL OR RTRIM(incat_error) ='') 
END

--VALIDACION DE PERSONAS
IF (@v_regPer IS NOT NULL) AND @v_regPer > 0 
BEGIN
	/* Rechaza registros con clave duplicada  */
	UPDATE in_personas SET inper_error='C', inper_error_campo='inper_clave' WHERE inper_clave IN (SELECT inper_clave FROM in_personas GROUP BY inper_clave HAVING COUNT(1) > 1) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 

	--Obligatorios
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_clave' WHERE (LEN(LTRIM(inper_clave))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_acv' WHERE (LEN(LTRIM(inper_acv))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_cli' WHERE (LEN(LTRIM(inper_cli))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_slg' WHERE (LEN(LTRIM(inper_slg))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_gec' WHERE (LEN(LTRIM(inper_gec))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_ecv' WHERE (LEN(LTRIM(inper_ecv))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_apellido' WHERE (LEN(LTRIM(inper_apellido))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_civ' WHERE (LEN(LTRIM(inper_civ))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_fis_jur' WHERE (LEN(LTRIM(inper_fis_jur))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_ent' WHERE (LEN(LTRIM(inper_ent))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='O', inper_error_campo='inper_suc' WHERE (LEN(LTRIM(inper_suc))=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	
	--Fechas
	UPDATE in_personas SET inper_error='F', inper_error_campo='inper_fec_slg' WHERE (LEN(LTRIM(inper_fec_slg))>0) AND (ISDATE(inper_fec_slg)=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='F', inper_error_campo='inper_fec_nac' WHERE (LEN(LTRIM(inper_fec_nac))>0) AND (ISDATE(inper_fec_nac)=0) AND (inper_error IS NULL OR RTRIM(inper_error) ='') 

	--Numeros
	
	--Tablas Relacionadas 
	UPDATE in_personas SET inper_error='T', inper_error_campo='inper_acv' WHERE
	NOT EXISTS(SELECT acv_id FROM actividades WHERE acv_nombre_corto = inper_acv AND acv_baja_fecha IS NULL)
	AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	
	UPDATE in_personas SET inper_error='T', inper_error_campo='inper_slg' WHERE
	NOT EXISTS(SELECT slg_id FROM sit_legal WHERE slg_nombre_corto = inper_slg AND slg_baja_fecha IS NULL)
	AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	
	UPDATE in_personas SET inper_error='T', inper_error_campo='inper_gec' WHERE
	NOT EXISTS(SELECT gec_id FROM grupo_economico WHERE gec_nombre_corto = inper_gec AND gec_baja_fecha IS NULL)
	AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	
	UPDATE in_personas SET inper_error='T', inper_error_campo='inper_ecv' WHERE
	NOT EXISTS(SELECT ecv_id FROM estado_civil WHERE ecv_nombre_corto = inper_ecv AND ecv_baja_fecha IS NULL)
	AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	
	UPDATE in_personas SET inper_error='T', inper_error_campo='inper_civ' WHERE
	NOT EXISTS(SELECT civ_id FROM cond_iva WHERE civ_nombre_corto = inper_civ AND civ_baja_fecha IS NULL)
	AND (inper_error IS NULL OR RTRIM(inper_error) ='') 

	UPDATE in_personas SET inper_error='T', inper_error_campo='inper_ent' WHERE
	NOT EXISTS(SELECT ent_id FROM entidades WHERE ent_nombre_corto = inper_ent AND ent_baja_fecha IS NULL)
	AND (inper_error IS NULL OR RTRIM(inper_error) ='') 

	UPDATE in_personas SET inper_error='T', inper_error_campo='inper_suc' WHERE
	NOT EXISTS(SELECT suc_id FROM sucursales, entidades WHERE suc_ent = ent_id AND suc_nombre_corto = inper_suc AND ent_nombre_corto = inper_ent AND suc_baja_fecha IS NULL)
	AND (inper_error IS NULL OR RTRIM(inper_error) ='') 

	--Dominios
	UPDATE in_personas SET inper_error='D', inper_error_campo='inper_fis_jur' WHERE inper_fis_jur NOT IN ('F','J') AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
	UPDATE in_personas SET inper_error='D', inper_error_campo='inper_sexo' WHERE inper_sexo is not null AND inper_sexo NOT IN (' ','M','F') AND (inper_error IS NULL OR RTRIM(inper_error) ='') 
END
--VALIDACION DE DOMICILIOS
IF (@v_regPer_dom IS NOT NULL) AND @v_regPer_dom > 0 
BEGIN
	--VALIDACIONES
	/* Rechaza registros con clave duplicada  */
	UPDATE in_per_dom SET inpdm_error='C', inpdm_error_campo='inpdm_clave' WHERE inpdm_clave IN (SELECT inpdm_clave FROM in_per_dom GROUP BY inpdm_clave HAVING COUNT(1) > 1) AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 

	--Obligatorios
	UPDATE in_per_dom SET inpdm_error='O', inpdm_error_campo='inpdm_clave' WHERE (LEN(LTRIM(inpdm_clave))=0) AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 
	UPDATE in_per_dom SET inpdm_error='O', inpdm_error_campo='inpdm_per_clave' WHERE (LEN(LTRIM(inpdm_per_clave))=0) AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 	
	UPDATE in_per_dom SET inpdm_error='O', inpdm_error_campo='inpdm_default' WHERE (LEN(LTRIM(inpdm_default))=0) AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 
	UPDATE in_per_dom SET inpdm_error='O', inpdm_error_campo='inpdm_dti' WHERE (LEN(LTRIM(inpdm_dti))=0) AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 
	UPDATE in_per_dom SET inpdm_error='O', inpdm_error_campo='inpdm_calle' WHERE (LEN(LTRIM(inpdm_calle))=0) AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 

	--Validacion Default Repetido
	UPDATE in_per_dom SET inpdm_error='DR', inpdm_error_campo='inpdm_default' WHERE inpdm_per_clave in(
		select inpdm_per_clave
		from in_per_dom 
		where inpdm_default='S' 
		group by inpdm_per_clave
		having count(inpdm_default)>1)
	AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 	

	--Tablas Relacionadas 
	UPDATE in_per_dom SET inpdm_error='T', inpdm_error_campo='inpdm_dti' WHERE
	NOT EXISTS(SELECT dti_id FROM tipos_domicilios WHERE dti_nombre_corto = inpdm_dti AND dti_baja_fecha IS NULL)
	AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 

	UPDATE in_per_dom SET inpdm_error='T', inpdm_error_campo='inpdm_pai' WHERE
	NOT EXISTS(SELECT pai_id FROM paises WHERE pai_nombre_corto = inpdm_pai AND pai_baja_fecha IS NULL)
	AND LEN(LTRIM(inpdm_pai))>0 
	AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 

	UPDATE in_per_dom SET inpdm_error='T', inpdm_error_campo='inpdm_prv' WHERE
	NOT EXISTS(SELECT prv_id FROM provincias, paises WHERE pai_id = prv_pai AND pai_nombre_corto = inpdm_pai AND prv_nombre_corto = inpdm_prv AND prv_baja_fecha IS NULL)
	AND LEN(LTRIM(inpdm_prv))>0 
	AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 

	UPDATE in_per_dom SET inpdm_error='T', inpdm_error_campo='inpdm_loc' WHERE
	NOT EXISTS(SELECT loc_id FROM localidades, provincias, paises WHERE prv_id = loc_prv AND pai_id = prv_pai AND pai_nombre_corto = inpdm_pai AND prv_nombre_corto = inpdm_prv AND loc_nombre_corto = inpdm_loc AND loc_baja_fecha IS NULL)
	AND LEN(LTRIM(inpdm_loc))>0 
	AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 

	UPDATE in_per_dom SET inpdm_error='T', inpdm_error_campo='inpdm_cop' WHERE
	NOT EXISTS(SELECT cop_id FROM codigos_postales, localidades, provincias, paises WHERE cop_loc = loc_id and prv_id = loc_prv AND pai_id = prv_pai AND pai_nombre_corto = inpdm_pai AND prv_nombre_corto = inpdm_prv AND loc_nombre_corto = inpdm_loc AND cop_numero = inpdm_cop AND cop_baja_fecha IS NULL)
	AND LEN(LTRIM(inpdm_cop))>0 
	AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 

	--Dominios
	UPDATE in_per_dom SET inpdm_error='D', inpdm_error_campo='inpdm_default' WHERE inpdm_default NOT IN ('S','N') AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 

	--Default con Baja
	UPDATE in_per_dom SET inpdm_error='DB', inpdm_error_campo='inpdm_default' WHERE inpdm_default ='S' AND SUBSTRING(inpdm_filler, 1,1) = 'B' AND (inpdm_error IS NULL OR RTRIM(inpdm_error) ='') 
	
END 
--VALIDACION DE TELEFONOS
IF (@v_regper_tel IS NOT NULL) AND @v_regper_tel > 0 
BEGIN	
	--VALIDACIONES
	/* Rechaza registros con clave duplicada  */
	UPDATE in_per_tel SET inpte_error='C', inpte_error_campo='inpte_clave' WHERE inpte_clave IN (SELECT inpte_clave FROM in_per_tel GROUP BY inpte_clave HAVING COUNT(1) > 1) AND (inpte_error IS NULL OR RTRIM(inpte_error) ='') 

	--Obligatorios
	UPDATE in_per_tel SET inpte_error='O', inpte_error_campo='inpte_clave' WHERE (LEN(LTRIM(inpte_clave))=0) AND (inpte_error IS NULL OR RTRIM(inpte_error) ='') 
	UPDATE in_per_tel SET inpte_error='O', inpte_error_campo='inpte_per_clave' WHERE (LEN(LTRIM(inpte_per_clave))=0) AND (inpte_error IS NULL OR RTRIM(inpte_error) ='') 
	UPDATE in_per_tel SET inpte_error='O', inpte_error_campo='inpte_default' WHERE (LEN(LTRIM(inpte_default))=0) AND (inpte_error IS NULL OR RTRIM(inpte_error) ='') 
	UPDATE in_per_tel SET inpte_error='O', inpte_error_campo='inpte_tti' WHERE (LEN(LTRIM(inpte_tti))=0) AND (inpte_error IS NULL OR RTRIM(inpte_error) ='') 
	UPDATE in_per_tel SET inpte_error='O', inpte_error_campo='inpte_telefono' WHERE (LEN(LTRIM(inpte_telefono))=0) AND (inpte_error IS NULL OR RTRIM(inpte_error) ='') 

	--Validacion Default Repetido
	UPDATE in_per_tel SET inpte_error='DR', inpte_error_campo='inpte_default' WHERE inpte_per_clave in(
		select inpte_per_clave
		from in_per_tel 
		where inpte_default='S' 
		group by inpte_per_clave
		having count(inpte_default)>1)
	AND (inpte_error IS NULL OR RTRIM(inpte_error) ='') 			

	--Tablas Relacionadas 
	UPDATE in_per_tel SET inpte_error='T', inpte_error_campo='inpte_tti' WHERE
	NOT EXISTS(SELECT tti_id FROM tipos_telefonos WHERE tti_nombre_corto = inpte_tti AND tti_baja_fecha IS NULL)
	AND (inpte_error IS NULL OR RTRIM(inpte_error) ='') 		

	--Dominios
	UPDATE in_per_tel SET inpte_error='D', inpte_error_campo='inpte_default' WHERE inpte_default NOT IN ('S','N') AND (inpte_error IS NULL OR RTRIM(inpte_error) ='') 

	--Default con Baja
	UPDATE in_per_tel SET inpte_error='DB', inpte_error_campo='inpte_default' WHERE inpte_default ='S' AND SUBSTRING(inpte_filler, 1,1) = 'B' AND (inpte_error IS NULL OR RTRIM(inpte_error) ='') 

END
--VALIDACION DE DOCUMENTOS
IF (@v_regper_doc IS NOT NULL) AND @v_regper_doc > 0 
BEGIN
	
	--VALIDACIONES
	/* Rechaza registros con clave duplicada  */
	UPDATE in_per_doc SET inpdc_error='C', inpdc_error_campo='inpdc_clave' WHERE inpdc_clave IN (SELECT inpdc_clave FROM in_per_doc GROUP BY inpdc_clave HAVING COUNT(1) > 1) AND (inpdc_error IS NULL OR RTRIM(inpdc_error) ='') 

	--Obligatorios
	UPDATE in_per_doc SET inpdc_error='O', inpdc_error_campo='inpdc_clave' WHERE (LEN(LTRIM(inpdc_clave))=0) AND (inpdc_error IS NULL OR RTRIM(inpdc_error) ='') 
	UPDATE in_per_doc SET inpdc_error='O', inpdc_error_campo='inpdc_per_clave' WHERE (LEN(LTRIM(inpdc_per_clave))=0) AND (inpdc_error IS NULL OR RTRIM(inpdc_error) ='') 
	UPDATE in_per_doc SET inpdc_error='O', inpdc_error_campo='inpdc_default' WHERE (LEN(LTRIM(inpdc_default))=0) AND (inpdc_error IS NULL OR RTRIM(inpdc_error) ='') 
	UPDATE in_per_doc SET inpdc_error='O', inpdc_error_campo='inpdc_tdc' WHERE (LEN(LTRIM(inpdc_tdc))=0) AND (inpdc_error IS NULL OR RTRIM(inpdc_error) ='') 
	UPDATE in_per_doc SET inpdc_error='O', inpdc_error_campo='inpdc_nro' WHERE (LEN(LTRIM(inpdc_nro))=0) AND (inpdc_error IS NULL OR RTRIM(inpdc_error) ='') 
	
	--Validacion Default Repetido
	UPDATE in_per_doc SET inpdc_error='DR', inpdc_error_campo='inpdc_default' WHERE inpdc_per_clave in(
		select inpdc_per_clave
		from in_per_doc 
		where inpdc_default='S' 
		group by inpdc_per_clave
		having count(inpdc_default)>1)
	AND (inpdc_error IS NULL OR RTRIM(inpdc_error) ='') 	

	--Tablas Relacionadas 
	UPDATE in_per_doc SET inpdc_error='T', inpdc_error_campo='inpdc_tdc' WHERE
	NOT EXISTS(SELECT tdc_id FROM tipos_documentos WHERE tdc_nombre_corto = inpdc_tdc AND tdc_baja_fecha IS NULL)
	AND (inpdc_error IS NULL OR RTRIM(inpdc_error) ='') 

	--Dominios
	UPDATE in_per_doc SET inpdc_error='D', inpdc_error_campo='inpdc_default' WHERE inpdc_default NOT IN ('S','N') AND (inpdc_error IS NULL OR RTRIM(inpdc_error) ='') 

END
--VALIDACION DE CUENTAS
IF (@v_regcta IS NOT NULL) AND @v_regcta > 0 
BEGIN
	/* Rechaza registros con clave duplicada  */
	UPDATE in_cuentas SET incta_error='C', incta_error_campo='incta_clave' WHERE incta_clave IN (SELECT incta_clave FROM in_cuentas GROUP BY incta_clave HAVING COUNT(1) > 1) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 

	--Obligatorios

	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_clave' WHERE (LEN(LTRIM(incta_clave))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_cat' WHERE (LEN(LTRIM(incta_cat))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_per_clave' WHERE (LEN(LTRIM(incta_per_clave))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_pro' WHERE (LEN(LTRIM(incta_pro))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_cla' WHERE (LEN(LTRIM(incta_cla))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_num_oper' WHERE (LEN(LTRIM(incta_num_oper))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_cli' WHERE (LEN(LTRIM(incta_cli))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_suc' WHERE (LEN(LTRIM(incta_suc))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_mon' WHERE (LEN(LTRIM(incta_mon))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_cnl' WHERE (LEN(LTRIM(incta_cnl))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_cam' WHERE (LEN(LTRIM(incta_cam))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_bnc' WHERE (LEN(LTRIM(incta_bnc))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_ent' WHERE (LEN(LTRIM(incta_ent))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_civ' WHERE (LEN(LTRIM(incta_civ))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_fec_origen' WHERE (LEN(LTRIM(incta_fec_origen))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_monto_origen' WHERE (LEN(LTRIM(incta_monto_origen))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_monto_transf' WHERE (LEN(LTRIM(incta_monto_transf))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_deuda_venc' WHERE (LEN(LTRIM(incta_deuda_venc))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_deuda_a_venc' WHERE (LEN(LTRIM(incta_deuda_a_venc))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_fec_cla' WHERE (LEN(LTRIM(incta_fec_cla))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_age' WHERE (LEN(LTRIM(incta_age))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_age_fec_ini' WHERE (LEN(LTRIM(incta_age_fec_ini))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_age_fec_fin' WHERE (LEN(LTRIM(incta_age_fec_fin))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_age_respons' WHERE (LEN(LTRIM(incta_age_respons))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_tco' WHERE (LEN(LTRIM(incta_tco))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_gat' WHERE LEN(LTRIM(incta_gat))=0 AND (incta_error IS NULL OR RTRIM(incta_error) ='') 	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_gta_mon' WHERE (LEN(LTRIM(incta_gta_mon))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_tna' WHERE LEN(LTRIM(incta_tna))=0 AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_tpa' WHERE (LEN(LTRIM(incta_tpa))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_paq_nro' WHERE (LEN(LTRIM(incta_paq_nro))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_paq_pes' WHERE (LEN(LTRIM(incta_paq_pes))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='O', incta_error_campo='incta_filler' WHERE (LEN(LTRIM(incta_filler))=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	
	--Fechas
	UPDATE in_cuentas SET incta_error='F', incta_error_campo='incta_fec_origen' WHERE (ISDATE(incta_fec_origen)=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='F', incta_error_campo='incta_fec_vto' WHERE LEN(LTRIM(incta_fec_vto))>0 AND (ISDATE(incta_fec_vto)=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='F', incta_error_campo='incta_fec_ing' WHERE LEN(LTRIM(incta_fec_ing))>0 AND (ISDATE(incta_fec_ing)=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='F', incta_error_campo='incta_fec_cla' WHERE (ISDATE(incta_fec_cla)=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='F', incta_error_campo='incta_age_fec_ini' WHERE (ISDATE(incta_age_fec_ini)=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='F', incta_error_campo='incta_age_fec_fin' WHERE (ISDATE(incta_age_fec_fin)=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='F', incta_error_campo='incta_paq_precierre_fecha' WHERE LEN(LTRIM(incta_paq_precierre_fecha))>0 AND (ISDATE(incta_paq_precierre_fecha)=0) AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	
	--Numeros
	UPDATE in_cuentas SET incta_error='N', incta_error_campo='incta_monto_origen' WHERE ISNUMERIC(incta_monto_origen)=0 AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='N', incta_error_campo='incta_monto_transf' WHERE ISNUMERIC(incta_monto_transf)=0 AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='N', incta_error_campo='incta_deuda_venc' WHERE ISNUMERIC(incta_deuda_venc)=0 AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='N', incta_error_campo='incta_deuda_a_venc' WHERE ISNUMERIC(incta_deuda_a_venc)=0 AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='N', incta_error_campo='incta_gta_monto' WHERE LEN(LTRIM(incta_gta_monto))>0 AND ISNUMERIC(incta_gta_monto)=0 AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='N', incta_error_campo='incta_tna' WHERE ISNUMERIC(incta_tna)=0 AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='N', incta_error_campo='incta_paq_precierre_deuda' WHERE LEN(LTRIM(incta_paq_precierre_deuda))>0 AND ISNUMERIC(incta_paq_precierre_deuda)=0 AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	UPDATE in_cuentas SET incta_error='N', incta_error_campo='incta_paq_nro' WHERE LEN(LTRIM(incta_paq_nro))>0 AND ISNUMERIC(incta_paq_nro)=0 AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	
	--Tablas Relacionadas 

	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_cat' WHERE 
	NOT EXISTS(SELECT top 1 cat_id FROM carteras WHERE RTRIM(cat_nombre_corto) = RTRIM(incta_cat)AND cat_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_pro' WHERE 
	NOT EXISTS(SELECT top 1 pro_id FROM productos WHERE RTRIM(pro_nombre_corto) = RTRIM(incta_pro)AND pro_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_cla'WHERE 
	NOT EXISTS(SELECT cla_id FROM clasificaciones WHERE RTRIM(cla_nombre_corto) = RTRIM(in_cuentas.incta_cla) AND cla_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_suc' WHERE 
	NOT EXISTS(SELECT suc_id FROM sucursales, entidades WHERE suc_ent = ent_id and RTRIM(suc_nombre_corto) = RTRIM(incta_suc) AND RTRIM(ent_nombre_corto) = RTRIM(incta_ent) AND suc_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_mon' WHERE 
	NOT EXISTS(SELECT mon_id FROM monedas WHERE RTRIM(mon_cod) = RTRIM(incta_mon) AND mon_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_cnl' WHERE 
	NOT EXISTS(SELECT cnl_id FROM canales, entidades WHERE cnl_ent = ent_id and RTRIM(cnl_nombre_corto) = RTRIM(incta_cnl) AND RTRIM(ent_nombre_corto) = RTRIM(incta_ent) and cnl_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='') 
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_cam'
	WHERE NOT EXISTS(SELECT cam_id FROM camp_comer, entidades WHERE cam_ent = ent_id AND RTRIM(cam_nombre_corto) = RTRIM(incta_cam) AND RTRIM(ent_nombre_corto) = RTRIM(incta_ent) AND cam_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_bnc' WHERE 
	NOT EXISTS(SELECT bnc_id FROM banca WHERE RTRIM(bnc_nombre_corto) = RTRIM(incta_bnc) AND bnc_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_ent'WHERE 
	NOT EXISTS(SELECT ent_id FROM entidades WHERE ent_nombre_corto = RTRIM(incta_ent) AND ent_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_civ'WHERE 
	NOT EXISTS(SELECT civ_id FROM cond_iva WHERE civ_nombre_corto = RTRIM(incta_civ) AND civ_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_age' WHERE 
	NOT EXISTS(SELECT age_id FROM agencias WHERE RTRIM(age_cod) = RTRIM(incta_age) AND age_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_tco' WHERE 
	NOT EXISTS(SELECT tco_id FROM tipos_contratos WHERE RTRIM(tco_nombre_corto) = RTRIM(incta_tco) AND tco_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_gat' WHERE 
	NOT EXISTS(SELECT gat_id FROM tipos_garantias WHERE RTRIM(gat_nombre_corto) = RTRIM(incta_gat) AND gat_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_gta_mon' WHERE 
	NOT EXISTS(SELECT mon_id FROM monedas WHERE RTRIM(mon_cod) = RTRIM(incta_gta_mon) AND mon_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_tpa' WHERE 
	NOT EXISTS(SELECT tpa_id FROM tipos_paquetes WHERE RTRIM(tpa_nombre_corto) = RTRIM(incta_tpa) AND tpa_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')
	
	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_paq_pes' WHERE 
	NOT EXISTS(SELECT pes_id FROM tipos_estados_paquetes WHERE RTRIM(pes_nombre_corto) = RTRIM(incta_paq_pes) AND pes_baja_fecha IS NULL)
	AND (incta_error IS NULL OR RTRIM(incta_error) ='')	

	--Dominios
	UPDATE in_cuentas SET incta_error='D', incta_error_campo='incta_det_mov' WHERE incta_det_mov is not NULL AND incta_det_mov  NOT IN ('S','N') AND (incta_error IS NULL OR RTRIM(incta_error) ='') 


	--Agregado por DG 20100519
	declare @v_cuentas_error int
	Set @v_cuentas_error = 0
	select @v_cuentas_error = count(*) from in_cuentas where rtrim(incta_error)!=''
	--grac20110910---IF (@v_cuentas_error > 10000)
IF (@v_cuentas_error > 100000)
	BEGIN
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','ERROR!! Existen ' + convert(varchar,@v_cuentas_error) +  ' errores de cuentas, verifique la tabla in_cuentas y el archivo de entrada',  @v_usu_id_in, Null,@v_cat_id
		INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','PROCESO ABORTADO.',  @v_usu_id_in, Null,@v_cat_id
		SELECT @cod_ret = 50007
		RETURN
	END

END
--VALIDACION DE MOVIMIENTOS
IF (@v_regmov IS NOT NULL) AND @v_regmov > 0 
BEGIN
	DECLARE @con_nc_cobro  VARCHAR(10)
	SELECT @con_nc_cobro = cos_nombre_corto FROM conceptos WHERE cos_id = 3

	/* Rechaza registros con clave duplicada  */
	UPDATE in_movimientos SET inmov_error='C', inmov_error_campo='inmov_clave' WHERE inmov_clave IN (SELECT inmov_clave FROM in_movimientos GROUP BY inmov_clave HAVING COUNT(1) > 1) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 

	--Obligatorios
	UPDATE in_movimientos SET inmov_error='O', inmov_error_campo='inmov_clave' WHERE (LEN(LTRIM(inmov_clave))=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='O', inmov_error_campo='inmov_cta_clave' WHERE (LEN(LTRIM(inmov_cta_clave))=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='O', inmov_error_campo='inmov_mon' WHERE (LEN(LTRIM(inmov_mon))=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='O', inmov_error_campo='inmov_fec_carga' WHERE (LEN(LTRIM(inmov_fec_carga))=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 	UPDATE in_movimientos SET inmov_error='O', inmov_error_campo='inmov_fec_contab' WHERE (LEN(LTRIM(inmov_fec_contab))=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='O', inmov_error_campo='inmov_fec_oper' WHERE (LEN(LTRIM(inmov_fec_oper))=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='O', inmov_error_campo='inmov_cos' WHERE (LEN(LTRIM(inmov_cos))=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='O', inmov_error_campo='inmov_scn' WHERE (LEN(LTRIM(inmov_scn))=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	
	--Fechas
	UPDATE in_movimientos SET inmov_error='F', inmov_error_campo='inmov_fec_carga' WHERE (ISDATE(inmov_fec_carga)=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='F', inmov_error_campo='inmov_fec_contab' WHERE (ISDATE(inmov_fec_contab)=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='F', inmov_error_campo='inmov_fec_oper' WHERE (ISDATE(inmov_fec_oper)=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 	
	UPDATE in_movimientos SET inmov_error='F', inmov_error_campo='inmov_fec_vto' WHERE (LEN(LTRIM(inmov_fec_vto))>0) AND (ISDATE(inmov_fec_vto)=0) AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 	
	
	--Numeros
	UPDATE in_movimientos SET inmov_error='N', inmov_error_campo='inmov_importe' WHERE LEN(LTRIM(inmov_importe))> 0 AND ISNUMERIC(inmov_importe)=0 AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='N', inmov_error_campo='inmov_importe_ajc' WHERE LEN(LTRIM(inmov_importe_ajc))> 0 AND ISNUMERIC(inmov_importe_ajc)=0 AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='N', inmov_error_campo='inmov_importe_int' WHERE LEN(LTRIM(inmov_importe_int))> 0 AND ISNUMERIC(inmov_importe_int)=0 AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='N', inmov_error_campo='inmov_importe_imp' WHERE LEN(LTRIM(inmov_importe_imp))> 0 AND ISNUMERIC(inmov_importe_imp)=0 AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	UPDATE in_movimientos SET inmov_error='N', inmov_error_campo='inmov_importe_gastos' WHERE LEN(LTRIM(inmov_importe_gastos))> 0 AND ISNUMERIC(inmov_importe_gastos)=0 AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	
	--Tablas Relacionadas 
	UPDATE in_movimientos SET inmov_error='T', inmov_error_campo='inmov_mon' WHERE
	NOT EXISTS(SELECT mon_id FROM monedas WHERE mon_cod = inmov_mon AND mon_baja_fecha IS NULL)
	AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	
	UPDATE in_movimientos SET inmov_error='T', inmov_error_campo='inmov_cos' WHERE
	NOT EXISTS(SELECT cos_id FROM conceptos WHERE cos_nombre_corto = inmov_cos AND cos_baja_fecha IS NULL)
	AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	
	UPDATE in_movimientos SET inmov_error='T', inmov_error_campo='inmov_scn' WHERE
	NOT EXISTS(SELECT scn_id FROM sub_conceptos, conceptos WHERE scn_cos = cos_id AND scn_nombre_corto = inmov_scn AND cos_nombre_corto = inmov_cos AND scn_baja_fecha IS NULL)
	AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
		
	--Dominios
	UPDATE in_movimientos SET inmov_error='D', inmov_error_campo='inmov_signo' WHERE inmov_signo NOT IN ('D','H') AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 

	/* por ahora no vamos a validar esto.
	-- inmov_importe_ajc nunca va a ser null
	UPDATE in_movimientos SET inmov_error='D', inmov_error_campo='inmov_importe_ajc' WHERE 
	inmov_importe_ajc is not null  
	AND inmov_cos <> @con_nc_cobro
	AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 

	UPDATE in_movimientos SET inmov_error='D', inmov_error_campo='inmov_importe_ajc' WHERE 
	len(ltrim(inmov_importe_ajc)) > 0 
	AND inmov_cos <> @con_nc_cobro
	AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 

	UPDATE in_movimientos SET inmov_error='D', inmov_error_campo='inmov_importe_int' WHERE 
	len(ltrim(inmov_importe_int)) > 0 
	AND inmov_cos <> @con_nc_cobro 
	AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 

	UPDATE in_movimientos SET inmov_error='D', inmov_error_campo='inmov_importe_imp' WHERE 
	len(ltrim(inmov_importe_imp)) > 0 
	AND inmov_cos <> @con_nc_cobro
	AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 

	UPDATE in_movimientos SET inmov_error='D', inmov_error_campo='inmov_importe_gastos' WHERE 
	len(ltrim(inmov_importe_gastos)) > 0 
	AND inmov_cos <> @con_nc_cobro
	AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
	*/

	--CLAVE
	UPDATE in_movimientos SET inmov_error='C', inmov_error_campo='inmov_clave' WHERE 
	EXISTS(SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla = 'mov' AND alt_clave = inmov_clave)
	AND (inmov_error IS NULL OR RTRIM(inmov_error) ='') 
END

--VALIDACION DE VINCULACION DE MOVIMIENTOS
IF (@v_regmvv IS NOT NULL) AND @v_regmvv > 0 
BEGIN
	/* Rechaza registros con clave duplicada  */
	UPDATE in_mov_x_mov SET inmvv_error = 'C' WHERE (LEN(LTRIM(inmvv_mov_clave))=0) AND (inmvv_error IS NULL OR RTRIM(inmvv_error) ='') 
		AND EXISTS (SELECT 1 FROM (SELECT inmvv_mov_clave, inmvv_mov_clave_vinc, inmvv_vinc_desv
			FROM in_mov_x_mov GROUP BY inmvv_mov_clave, inmvv_mov_clave_vinc, inmvv_vinc_desv
			HAVING COUNT(1) > 1) AS m1
			WHERE in_mov_x_mov.inmvv_mov_clave = m1.inmvv_mov_clave 
			AND in_mov_x_mov.inmvv_mov_clave_vinc = m1.inmvv_mov_clave_vinc
			AND in_mov_x_mov.inmvv_vinc_desv = m1.inmvv_vinc_desv)

	--Obligatorios
	UPDATE in_mov_x_mov SET inmvv_error='O', inmvv_error_campo='inmvv_mov_clave' WHERE (LEN(LTRIM(inmvv_mov_clave))=0) AND (inmvv_error IS NULL OR RTRIM(inmvv_error) ='') 
	UPDATE in_mov_x_mov SET inmvv_error='O', inmvv_error_campo='inmvv_mov_clave_vinc' WHERE (LEN(LTRIM(inmvv_mov_clave_vinc))=0) AND (inmvv_error IS NULL OR RTRIM(inmvv_error) ='') 
	UPDATE in_mov_x_mov SET inmvv_error='O', inmvv_error_campo='inmvv_vinc_desv' WHERE (LEN(LTRIM(inmvv_vinc_desv))=0) AND (inmvv_error IS NULL OR RTRIM(inmvv_error) ='') 
	
	--Dominios
	UPDATE in_mov_x_mov SET inmvv_error='D', inmvv_error_campo='inmvv_vinc_desv' WHERE inmvv_vinc_desv NOT IN ('D','V') AND (inmvv_error IS NULL OR RTRIM(inmvv_error) ='') 

	-- Validar vinculaciones repetidas
	-- asumimos que si un comprobante A esta vinculado con uno B, B tambien esta vinculado a A
	-- entonces validamos sobre los campos (mvv_mov, mvv_mov_vinc) y tambien (mvv_mov_vinc, mvv_mov)
	UPDATE in_mov_x_mov SET inmvv_error='C', inmvv_error_campo='inmvv_vinculacion1' WHERE 
	inmvv_vinc_desv = 'V' and 
	EXISTS (select 1 from mov_x_mov where mvv_baja_fecha is null AND mvv_mov=(SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='mov' AND alt_clave=inmvv_mov_clave) and mvv_mov_vinc=(SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='mov' AND alt_clave=inmvv_mov_clave_vinc))
--	EXISTS (select 1 from mov_x_mov, wf_in_alta_aut MOV, wf_in_alta_aut VINC where mvv_baja_fecha is null AND mvv_mov=MOV.alt_id and mvv_mov_vinc=VINC.alt_id AND MOV.alt_tabla='mov' AND VINC.alt_tabla='mov' AND MOV.alt_clave=inmvv_mov_clave and VINC.alt_clave=inmvv_mov_clave_vinc)
-- los exists hacen los mismo 
	AND (inmvv_error IS NULL OR RTRIM(inmvv_error) ='') 



	UPDATE in_mov_x_mov SET inmvv_error='C', inmvv_error_campo='inmvv_vinculacion2' WHERE 
	inmvv_vinc_desv = 'V' and 
	EXISTS (select 1 from mov_x_mov where mvv_baja_fecha is null AND mvv_mov_vinc=(SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='mov' AND alt_clave=inmvv_mov_clave) and mvv_mov=(SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='mov' AND alt_clave=inmvv_mov_clave_vinc))
	AND (inmvv_error IS NULL OR RTRIM(inmvv_error) ='') 

END

--VALIDACION DE ATRIBUTOS DE OBJETOS
IF (@v_regsot IS NOT NULL) AND @v_regsot > 0 
BEGIN
	--Obligatorios
	UPDATE in_wf_sob_atributos SET insot_error='O', insot_error_campo='insot_clave' WHERE (LEN(LTRIM(insot_clave))=0) AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='O', insot_error_campo='insot_atr' WHERE (LEN(LTRIM(insot_atr))=0) AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='O', insot_error_campo='insot_cat' WHERE (LEN(LTRIM(insot_cat))=0) AND (insot_error IS NULL OR RTRIM(insot_error) ='') 

	--Fechas
	UPDATE in_wf_sob_atributos SET insot_error='F', insot_error_campo='insot_fecha1' WHERE (ISDATE(insot_fecha1)=0 AND ltrim(rtrim(insot_fecha1)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='F', insot_error_campo='insot_fecha2' WHERE (ISDATE(insot_fecha2)=0 AND ltrim(rtrim(insot_fecha2)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='F', insot_error_campo='insot_fecha3' WHERE (ISDATE(insot_fecha3)=0 AND ltrim(rtrim(insot_fecha3)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='F', insot_error_campo='insot_fecha4' WHERE (ISDATE(insot_fecha4)=0 AND ltrim(rtrim(insot_fecha4)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='F', insot_error_campo='insot_fecha5' WHERE (ISDATE(insot_fecha5)=0 AND ltrim(rtrim(insot_fecha5)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='F', insot_error_campo='insot_fecha6' WHERE (ISDATE(insot_fecha6)=0 AND ltrim(rtrim(insot_fecha6)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='F', insot_error_campo='insot_fecha7' WHERE (ISDATE(insot_fecha7)=0 AND ltrim(rtrim(insot_fecha7)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='F', insot_error_campo='insot_fecha8' WHERE (ISDATE(insot_fecha8)=0 AND ltrim(rtrim(insot_fecha8)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='F', insot_error_campo='insot_fecha9' WHERE (ISDATE(insot_fecha9)=0 AND ltrim(rtrim(insot_fecha9)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='F', insot_error_campo='insot_fecha10' WHERE (ISDATE(insot_fecha10)=0 AND ltrim(rtrim(insot_fecha10)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	
	--Numeros
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_numero1' WHERE (ISNUMERIC(insot_numero1)=0 AND ltrim(rtrim(insot_numero1)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_numero2' WHERE (ISNUMERIC(insot_numero2)=0 AND ltrim(rtrim(insot_numero2)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_numero3' WHERE (ISNUMERIC(insot_numero3)=0 AND ltrim(rtrim(insot_numero3)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_numero4' WHERE (ISNUMERIC(insot_numero4)=0 AND ltrim(rtrim(insot_numero4)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_numero5' WHERE (ISNUMERIC(insot_numero5)=0 AND ltrim(rtrim(insot_numero5)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_numero6' WHERE (ISNUMERIC(insot_numero6)=0 AND ltrim(rtrim(insot_numero6)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_numero7' WHERE (ISNUMERIC(insot_numero7)=0 AND ltrim(rtrim(insot_numero7)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_numero8' WHERE (ISNUMERIC(insot_numero8)=0 AND ltrim(rtrim(insot_numero8)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_numero9' WHERE (ISNUMERIC(insot_numero9)=0 AND ltrim(rtrim(insot_numero9)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_numero10' WHERE (ISNUMERIC(insot_numero10)=0 AND ltrim(rtrim(insot_numero10)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='')

	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_coeficiente1' WHERE (ISNUMERIC(insot_coeficiente1)=0 AND ltrim(rtrim(insot_coeficiente1)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_coeficiente2' WHERE (ISNUMERIC(insot_coeficiente2)=0 AND ltrim(rtrim(insot_coeficiente2)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_coeficiente3' WHERE (ISNUMERIC(insot_coeficiente3)=0 AND ltrim(rtrim(insot_coeficiente3)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_coeficiente4' WHERE (ISNUMERIC(insot_coeficiente4)=0 AND ltrim(rtrim(insot_coeficiente4)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_coeficiente5' WHERE (ISNUMERIC(insot_coeficiente5)=0 AND ltrim(rtrim(insot_coeficiente5)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_coeficiente6' WHERE (ISNUMERIC(insot_coeficiente6)=0 AND ltrim(rtrim(insot_coeficiente6)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_coeficiente7' WHERE (ISNUMERIC(insot_coeficiente7)=0 AND ltrim(rtrim(insot_coeficiente7)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_coeficiente8' WHERE (ISNUMERIC(insot_coeficiente8)=0 AND ltrim(rtrim(insot_coeficiente8)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_coeficiente9' WHERE (ISNUMERIC(insot_coeficiente9)=0 AND ltrim(rtrim(insot_coeficiente9)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 
	UPDATE in_wf_sob_atributos SET insot_error='N', insot_error_campo='insot_coeficiente10' WHERE (ISNUMERIC(insot_coeficiente10)=0 AND ltrim(rtrim(insot_coeficiente10)) <> '') AND (insot_error IS NULL OR RTRIM(insot_error) ='') 


	--Tablas Relacionadas 
	UPDATE in_wf_sob_atributos SET insot_error='T',insot_error_campo='insot_cat' WHERE 
	NOT EXISTS(SELECT top 1 cat_id FROM carteras WHERE cat_nombre_corto = insot_cat AND cat_baja_fecha IS NULL)
	AND (insot_error IS NULL OR RTRIM(insot_error) ='')

	UPDATE in_wf_sob_atributos SET insot_error='T', insot_error_campo='insot_atr' WHERE
		(insot_error IS NULL OR RTRIM(insot_error) ='') 
		AND NOT EXISTS(SELECT atr_id FROM wf_atributos, carteras
					WHERE atr_cat = cat_id 
					AND	atr_nombre_corto = insot_atr 
					AND cat_nombre_corto = insot_cat
					AND atr_baja_fecha IS NULL)

END

--VALIDACION DE ATRIBUTOS DE PERSONAS
IF (@v_regpea IS NOT NULL) AND @v_regpea > 0 
BEGIN
	--Obligatorios
	UPDATE in_per_atributos SET inpea_error='O', inpea_error_campo='inpea_clave' WHERE (LEN(LTRIM(inpea_clave))=0) AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='O', inpea_error_campo='inpea_atr' WHERE (LEN(LTRIM(inpea_atr))=0) AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='O', inpea_error_campo='inpea_cat' WHERE (LEN(LTRIM(inpea_cat))=0) AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 

	--Fechas
	UPDATE in_per_atributos SET inpea_error='F', inpea_error_campo='inpea_fecha1' WHERE (ISDATE(inpea_fecha1)=0 AND ltrim(rtrim(inpea_fecha1)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='F', inpea_error_campo='inpea_fecha2' WHERE (ISDATE(inpea_fecha2)=0 AND ltrim(rtrim(inpea_fecha2)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='F', inpea_error_campo='inpea_fecha3' WHERE (ISDATE(inpea_fecha3)=0 AND ltrim(rtrim(inpea_fecha3)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='F', inpea_error_campo='inpea_fecha4' WHERE (ISDATE(inpea_fecha4)=0 AND ltrim(rtrim(inpea_fecha4)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='F', inpea_error_campo='inpea_fecha5' WHERE (ISDATE(inpea_fecha5)=0 AND ltrim(rtrim(inpea_fecha5)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='F', inpea_error_campo='inpea_fecha6' WHERE (ISDATE(inpea_fecha6)=0 AND ltrim(rtrim(inpea_fecha6)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='F', inpea_error_campo='inpea_fecha7' WHERE (ISDATE(inpea_fecha7)=0 AND ltrim(rtrim(inpea_fecha7)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='F', inpea_error_campo='inpea_fecha8' WHERE (ISDATE(inpea_fecha8)=0 AND ltrim(rtrim(inpea_fecha8)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='F', inpea_error_campo='inpea_fecha9' WHERE (ISDATE(inpea_fecha9)=0 AND ltrim(rtrim(inpea_fecha9)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='F', inpea_error_campo='inpea_fecha10' WHERE (ISDATE(inpea_fecha10)=0 AND ltrim(rtrim(inpea_fecha10)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	
	--Numeros
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_numero1' WHERE (ISNUMERIC(inpea_numero1)=0 AND ltrim(rtrim(inpea_numero1)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_numero2' WHERE (ISNUMERIC(inpea_numero2)=0 AND ltrim(rtrim(inpea_numero2)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_numero3' WHERE (ISNUMERIC(inpea_numero3)=0 AND ltrim(rtrim(inpea_numero3)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_numero4' WHERE (ISNUMERIC(inpea_numero4)=0 AND ltrim(rtrim(inpea_numero4)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_numero5' WHERE (ISNUMERIC(inpea_numero5)=0 AND ltrim(rtrim(inpea_numero5)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_numero6' WHERE (ISNUMERIC(inpea_numero6)=0 AND ltrim(rtrim(inpea_numero6)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_numero7' WHERE (ISNUMERIC(inpea_numero7)=0 AND ltrim(rtrim(inpea_numero7)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_numero8' WHERE (ISNUMERIC(inpea_numero8)=0 AND ltrim(rtrim(inpea_numero8)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_numero9' WHERE (ISNUMERIC(inpea_numero9)=0 AND ltrim(rtrim(inpea_numero9)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_numero10' WHERE (ISNUMERIC(inpea_numero10)=0 AND ltrim(rtrim(inpea_numero10)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='')

	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_coeficiente1' WHERE (ISNUMERIC(inpea_coeficiente1)=0 AND ltrim(rtrim(inpea_coeficiente1)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_coeficiente2' WHERE (ISNUMERIC(inpea_coeficiente2)=0 AND ltrim(rtrim(inpea_coeficiente2)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_coeficiente3' WHERE (ISNUMERIC(inpea_coeficiente3)=0 AND ltrim(rtrim(inpea_coeficiente3)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_coeficiente4' WHERE (ISNUMERIC(inpea_coeficiente4)=0 AND ltrim(rtrim(inpea_coeficiente4)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_coeficiente5' WHERE (ISNUMERIC(inpea_coeficiente5)=0 AND ltrim(rtrim(inpea_coeficiente5)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_coeficiente6' WHERE (ISNUMERIC(inpea_coeficiente6)=0 AND ltrim(rtrim(inpea_coeficiente6)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_coeficiente7' WHERE (ISNUMERIC(inpea_coeficiente7)=0 AND ltrim(rtrim(inpea_coeficiente7)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_coeficiente8' WHERE (ISNUMERIC(inpea_coeficiente8)=0 AND ltrim(rtrim(inpea_coeficiente8)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_coeficiente9' WHERE (ISNUMERIC(inpea_coeficiente9)=0 AND ltrim(rtrim(inpea_coeficiente9)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 
	UPDATE in_per_atributos SET inpea_error='N', inpea_error_campo='inpea_coeficiente10' WHERE (ISNUMERIC(inpea_coeficiente10)=0 AND ltrim(rtrim(inpea_coeficiente10)) <> '') AND (inpea_error IS NULL OR RTRIM(inpea_error) ='') 


	--Tablas Relacionadas 
	UPDATE in_per_atributos SET inpea_error='T',inpea_error_campo='inpea_cat' WHERE 
	NOT EXISTS(SELECT top 1 cat_id FROM carteras WHERE cat_nombre_corto = inpea_cat AND cat_baja_fecha IS NULL)
	AND (inpea_error IS NULL OR RTRIM(inpea_error) ='')

	UPDATE in_per_atributos SET inpea_error='T', inpea_error_campo='inpea_atr' WHERE
		(inpea_error IS NULL OR RTRIM(inpea_error) ='') 
		AND NOT EXISTS(SELECT atr_id FROM wf_atributos, carteras
					WHERE atr_cat = cat_id 
					AND	atr_nombre_corto = inpea_atr 
					AND cat_nombre_corto = inpea_cat
					AND atr_baja_fecha IS NULL)
END

--VALIDACION DE PERSONAS VINCULADAS
IF (@v_regper_cta IS NOT NULL) AND @v_regper_cta > 0 
BEGIN
	--VALIDACIONES
	--Obligatorios
	UPDATE in_per_x_cta SET inpxc_error='O', inpxc_error_campo='inpxc_clave' WHERE (LEN(LTRIM(inpxc_clave))=0) AND (inpxc_error IS NULL OR RTRIM(inpxc_error) ='') 
	UPDATE in_per_x_cta SET inpxc_error='O', inpxc_error_campo='inpxc_per_clave' WHERE (LEN(LTRIM(inpxc_per_clave))=0) AND (inpxc_error IS NULL OR RTRIM(inpxc_error) ='') 
	UPDATE in_per_x_cta SET inpxc_error='O', inpxc_error_campo='inpxc_cta_calve' WHERE (LEN(LTRIM(inpxc_cta_clave))=0) AND (inpxc_error IS NULL OR RTRIM(inpxc_error) ='') 
	UPDATE in_per_x_cta SET inpxc_error='O', inpxc_error_campo='inpxc_ogc' WHERE (LEN(LTRIM(inpxc_ogc))=0) AND (inpxc_error IS NULL OR RTRIM(inpxc_error) ='') 
	
	--Tablas Relacionadas 
	UPDATE in_per_x_cta SET inpxc_error='T', inpxc_error_campo='inpxc_ogc' WHERE
	NOT EXISTS(select ogc_id from garantes_caracter where ogc_nombre_corto= inpxc_ogc and ogc_baja_fecha is null)
	AND (inpxc_error IS NULL OR RTRIM(inpxc_error) ='') 

	UPDATE in_per_x_cta SET inpxc_error='T',inpxc_error_campo='inpxc_per_clave' WHERE 
	NOT EXISTS (select 1 from wf_in_alta_aut where alt_tabla='per' and alt_clave = inpxc_per_clave)	

	UPDATE in_per_x_cta SET inpxc_error='T',inpxc_error_campo='inpxc_cta_clave' WHERE 
	NOT EXISTS (select 1 from wf_in_alta_aut where alt_tabla='cta' and alt_clave = inpxc_cta_clave)	

END

--VALIDACION DE PRESTAMOS
IF (@v_regptm IS NOT NULL) AND @v_regptm > 0 
BEGIN
	/* Rechaza registros con clave duplicada  */
	UPDATE in_prestamos SET inptm_error='C', inptm_error_campo='inptm_clave' WHERE inptm_clave IN (SELECT inptm_clave FROM in_prestamos GROUP BY inptm_clave HAVING COUNT(1) > 1) AND (inptm_error IS NULL OR RTRIM(inptm_error) ='') 

	--Obligatorios
	UPDATE in_prestamos SET inptm_error='O', inptm_error_campo='inptm_clave' WHERE (LEN(LTRIM(inptm_clave))=0) AND (inptm_error IS NULL OR RTRIM(inptm_error) ='') 
	UPDATE in_prestamos SET inptm_error='O', inptm_error_campo='inptm_cta_clave' WHERE (LEN(LTRIM(inptm_cta_clave))=0) AND (inptm_error IS NULL OR RTRIM(inptm_error) ='') 
	UPDATE in_prestamos SET inptm_error='O', inptm_error_campo='inptm_capital_inicial' WHERE (LEN(LTRIM(inptm_capital_inicial))=0) AND (inptm_error IS NULL OR RTRIM(inptm_error) ='') 
    	
	--Fechas
	UPDATE in_prestamos SET inptm_error='O', inptm_error_campo='inptm_fecha_fin' WHERE (LEN(LTRIM(inptm_fecha_fin)) = 0 or (ISDATE(inptm_fecha_fin)=0))and  (inptm_error IS NULL OR RTRIM(inptm_error) ='') 

	--Numeros
	UPDATE in_prestamos SET inptm_error='N', inptm_error_campo='inptm_capital_inicial' WHERE ISNUMERIC(inptm_capital_inicial)=0 AND (inptm_error IS NULL OR RTRIM(inptm_error) ='') 
	
	--Tablas Relacionadas 

	--Dominios

END

--VALIDACION DE PRESTAMOS CUOTAS
IF (@v_regpcu IS NOT NULL) AND @v_regpcu > 0 
BEGIN
	/* Rechaza registros con clave duplicada  */
	UPDATE in_prestamos_cuotas SET inpcu_error='C', inpcu_error_campo='inpcu_clave' WHERE inpcu_clave IN (SELECT inpcu_clave FROM in_prestamos_cuotas GROUP BY inpcu_clave HAVING COUNT(1) > 1) AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 

	--Obligatorios
	UPDATE in_prestamos_cuotas SET inpcu_error='O', inpcu_error_campo='inpcu_clave' WHERE (LEN(LTRIM(inpcu_clave))=0) AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 
	UPDATE in_prestamos_cuotas SET inpcu_error='O', inpcu_error_campo='inpcu_ptm_clave' WHERE (LEN(LTRIM(inpcu_ptm_clave))=0) AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 
	UPDATE in_prestamos_cuotas SET inpcu_error='O', inpcu_error_campo='inpcu_numero' WHERE (LEN(LTRIM(inpcu_numero))=0) AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 
	UPDATE in_prestamos_cuotas SET inpcu_error='O', inpcu_error_campo='inpcu_importe' WHERE (LEN(LTRIM(inpcu_importe))=0) AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 	
	UPDATE in_prestamos_cuotas SET inpcu_error='O', inpcu_error_campo='inpcu_venc_fecha' WHERE (LEN(LTRIM(Inpcu_venc_fecha))=0) AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 	
	UPDATE in_prestamos_cuotas SET inpcu_error='O', inpcu_error_campo='inpcu_estado' WHERE (LEN(LTRIM(Inpcu_estado))=0) AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 	
	
	--Fechas
	UPDATE in_prestamos_cuotas SET inpcu_error='F', inpcu_error_campo='inpcu_venc_fecha' WHERE (ISDATE(inpcu_venc_fecha)=0) AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 
	UPDATE in_prestamos_cuotas SET inpcu_error='F', inpcu_error_campo='inpcu_pago_fecha' WHERE LEN(LTRIM(inpcu_pago_fecha))>0 AND (ISDATE(inpcu_pago_fecha)=0) AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 

	--Numeros
	UPDATE in_prestamos_cuotas SET inpcu_error='N', inpcu_error_campo='inpcu_numero' WHERE ISNUMERIC(inpcu_numero)=0 AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 
	UPDATE in_prestamos_cuotas SET inpcu_error='N', inpcu_error_campo='inpcu_importe' WHERE ISNUMERIC(inpcu_importe)=0 AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 
	UPDATE in_prestamos_cuotas SET inpcu_error='N', inpcu_error_campo='inpcu_intereses' WHERE ISNUMERIC(inpcu_intereses)=0 AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 

	--Tablas Relacionadas 

	--Dominios, se agrega 'T'  20121227 
	UPDATE in_prestamos_cuotas SET inpcu_error='D', inpcu_error_campo='inpcu_estado' WHERE inpcu_estado NOT IN ('V','A','P','T') AND (inpcu_error IS NULL OR RTRIM(inpcu_error) ='') 	

END

--VALIDACION DE TARJETAS
IF (@v_regtaj IS NOT NULL) AND @v_regtaj > 0 
BEGIN
	/* Rechaza registros con clave duplicada  */
	UPDATE in_tarjetas SET intaj_error='C', intaj_error_campo='intaj_clave' WHERE intaj_clave IN (SELECT intaj_clave FROM in_tarjetas GROUP BY intaj_clave HAVING COUNT(1) > 1) AND (intaj_error IS NULL OR RTRIM(intaj_error) ='') 

	--Obligatorios
	UPDATE in_tarjetas SET intaj_error='O', intaj_error_campo='intaj_clave' WHERE (LEN(LTRIM(intaj_clave))=0) AND (intaj_error IS NULL OR RTRIM(intaj_error) ='') 
	UPDATE in_tarjetas SET intaj_error='O', intaj_error_campo='intaj_cta_clave' WHERE (LEN(LTRIM(intaj_cta_clave))=0) AND (intaj_error IS NULL OR RTRIM(intaj_error) ='') 
	UPDATE in_tarjetas SET intaj_error='O', intaj_error_campo='intaj_numero' WHERE (LEN(LTRIM(intaj_numero))=0) AND (intaj_error IS NULL OR RTRIM(intaj_error) ='') 
	UPDATE in_tarjetas SET intaj_error='O', intaj_error_campo='intaj_limite_compra' WHERE (LEN(LTRIM(intaj_limite_compra))=0) AND (intaj_error IS NULL OR RTRIM(intaj_error) ='') 
	UPDATE in_tarjetas SET intaj_error='O', intaj_error_campo='intaj_estado' WHERE (LEN(LTRIM(intaj_estado))=0) AND (intaj_error IS NULL OR RTRIM(intaj_error) ='') 	
	
	--Fechas

	--Numeros
	UPDATE in_tarjetas SET intaj_error='N', intaj_error_campo='intaj_limite_compra' WHERE ISNUMERIC(intaj_limite_compra)=0 AND (intaj_error IS NULL OR RTRIM(intaj_error) ='') 

	--Tablas Relacionadas 

	--Dominios
	--20130110--UPDATE in_tarjetas SET intaj_error='D', intaj_error_campo='intaj_estado' WHERE intaj_estado NOT IN ('N','I','B','X','M','P') AND (intaj_error IS NULL OR RTRIM(intaj_error) ='') 	
                UPDATE in_tarjetas SET intaj_error='D', intaj_error_campo='intaj_estado' WHERE intaj_estado NOT IN ('N','I','B','X','M','P','Q','R','C','T') AND (intaj_error IS NULL OR RTRIM(intaj_error) ='') 	

END

--VALIDACION DE TARJETAS VENCIMIENTOS
IF (@v_regtcv IS NOT NULL) AND @v_regtcv > 0 
BEGIN
	/* Rechaza registros con clave duplicada  */
	UPDATE in_tarjetas_venc SET intcv_error='C', intcv_error_campo='intcv_clave' WHERE intcv_clave IN (SELECT intcv_clave FROM in_tarjetas_venc GROUP BY intcv_clave HAVING COUNT(1) > 1) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 

	--Obligatorios
	UPDATE in_tarjetas_venc SET intcv_error='O', intcv_error_campo='intcv_clave' WHERE (LEN(LTRIM(intcv_clave))=0) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 
	UPDATE in_tarjetas_venc SET intcv_error='O', intcv_error_campo='intcv_taj_clave' WHERE (LEN(LTRIM(intcv_taj_clave))=0) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 	
	UPDATE in_tarjetas_venc SET intcv_error='O', intcv_error_campo='intcv_fecha' WHERE (LEN(LTRIM(intcv_fecha))=0) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 
	UPDATE in_tarjetas_venc SET intcv_error='O', intcv_error_campo='intcv_fecha_cierre' WHERE (LEN(LTRIM(intcv_fecha_cierre))=0) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 
	UPDATE in_tarjetas_venc SET intcv_error='O', intcv_error_campo='intcv_saldo_pesos' WHERE (LEN(LTRIM(intcv_saldo_pesos))=0) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 
	UPDATE in_tarjetas_venc SET intcv_error='O', intcv_error_campo='intcv_saldo_dolares' WHERE (LEN(LTRIM(intcv_saldo_dolares))=0) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 
	UPDATE in_tarjetas_venc SET intcv_error='O', intcv_error_campo='intcv_pago_min' WHERE (LEN(LTRIM(intcv_pago_min))=0) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 
	UPDATE in_tarjetas_venc SET intcv_error='O', intcv_error_campo='intcv_incluye_fec_cierre' WHERE (LEN(LTRIM(intcv_incluye_fec_cierre))=0) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 

	--Fechas
	UPDATE in_tarjetas_venc SET intcv_error='F', intcv_error_campo='intcv_fecha' WHERE (ISDATE(intcv_fecha)=0) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 
	UPDATE in_tarjetas_venc SET intcv_error='F', intcv_error_campo='intcv_fecha_cierre' WHERE (ISDATE(intcv_fecha_cierre)=0) AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 	

	--Numeros
	UPDATE in_tarjetas_venc SET intcv_error='N', intcv_error_campo='intcv_saldo_pesos' WHERE ISNUMERIC(intcv_saldo_pesos)=0 AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 
	UPDATE in_tarjetas_venc SET intcv_error='N', intcv_error_campo='intcv_saldo_dolares' WHERE ISNUMERIC(intcv_saldo_dolares)=0 AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 
	UPDATE in_tarjetas_venc SET intcv_error='N', intcv_error_campo='intcv_pago_min' WHERE ISNUMERIC(intcv_pago_min)=0 AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 

	--Tablas Relacionadas 

	--Dominios
	UPDATE in_tarjetas_venc SET intcv_error='D', intcv_error_campo='intcv_incluye_fec_cierre' WHERE intcv_incluye_fec_cierre NOT IN ('N','S') AND (intcv_error IS NULL OR RTRIM(intcv_error) ='') 	

END

--VALIDACION DE CUENTAS CORRIENTES
IF (@v_regcca IS NOT NULL) AND @v_regcca > 0
BEGIN
	--VALIDACIONES

	/* Rechaza registros con clave duplicada */
/*	UPDATE in_cca_ca SET incca_error='C', incca_error_campo='incca_clave' WHERE 
	EXISTS(SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla = 'cca' AND alt_clave = incca_clave)
	AND (incca_error IS NULL OR RTRIM(incca_error) ='') 
*/

     UPDATE in_cca_ca SET incca_error='C', incca_error_campo='incca_clave' WHERE incca_clave IN (SELECT incca_clave FROM in_cca_ca GROUP BY incca_clave HAVING COUNT(1) > 1) AND (incca_error IS NULL OR RTRIM(incca_error) ='') 


	--Obligatorios
	UPDATE in_cca_ca SET incca_error='O', incca_error_campo='incca_clave' WHERE (LEN(LTRIM(incca_clave))=0) AND (incca_error IS NULL OR RTRIM(incca_error) ='') 
	UPDATE in_cca_ca SET incca_error='O', incca_error_campo='incca_cta_clave' WHERE (LEN(LTRIM(incca_cta_clave))=0) AND (incca_error IS NULL OR RTRIM(incca_error) ='') 
	UPDATE in_cca_ca SET incca_error='O', incca_error_campo='incca_acuerdo' WHERE (LEN(LTRIM(incca_acuerdo))=0) AND (incca_error IS NULL OR RTRIM(incca_error) ='') 
	UPDATE in_cca_ca SET incca_error='O', incca_error_campo='incca_saldo' WHERE (LEN(LTRIM(incca_saldo))=0) AND (incca_error IS NULL OR RTRIM(incca_error) ='') 
	UPDATE in_cca_ca SET incca_error='O', incca_error_campo='incca_porfolio' WHERE (LEN(LTRIM(incca_porfolio))=0) AND (incca_error IS NULL OR RTRIM(incca_error) ='') 

	--Numeros
	UPDATE in_cca_ca SET incca_error='N', incca_error_campo='incca_acuerdo' WHERE ISNUMERIC(incca_acuerdo)=0 AND (incca_error IS NULL OR RTRIM(incca_error) ='')
	UPDATE in_cca_ca SET incca_error='N', incca_error_campo='incca_saldo' WHERE ISNUMERIC(incca_saldo)=0 AND (incca_error IS NULL OR RTRIM(incca_error) ='')
	UPDATE in_cca_ca SET incca_error='N', incca_error_campo='incca_porfolio' WHERE ISNUMERIC(incca_porfolio)=0 AND (incca_error IS NULL OR RTRIM(incca_error) ='')
	
	--Tablas Relacionadas 
	UPDATE in_cca_ca SET incca_error='T',incca_error_campo='incca_cta_clave' WHERE 
	NOT EXISTS (select 1 from wf_in_alta_aut where alt_tabla='cta' and alt_clave = incca_cta_clave)	
END

-------------------------------------------------------------------------------------------------------------------------
--TABLA CARTERAS	
-------------------------------------------------------------------------------------------------------------------------
IF (@v_regcat IS NOT NULL) AND @v_regcat > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Carteras', @v_usu_id_in, Null, @v_cat_id	
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	

	SET @error_tran = 0
	BEGIN TRAN CARTERAS
	----------------------------------------------------------------------
	--MODIFICACION DE REGISTROS
	UPDATE carteras
	SET	
		cat_cod = incat_codigo,
		cat_nombre_corto = incat_nombre_corto,
		cat_nombre = incat_nombre,
		cat_kit = (Select kit_id from wf_kit where kit_nombre_corto=incat_kit and kit_baja_fecha is null),
		cat_ege = (Select ege_id from wf_equipos_gestion where ege_nombre_corto=incat_ege and ege_baja_fecha is null),
		cat_obs = incat_obs, 
		cat_p_modi_fecha = @v_fec_proceso,
		cat_usu_id = @v_usu_id,
		cat_filler = incat_filler
	FROM in_carteras , wf_in_alta_aut
	WHERE
		(incat_error IS NULL OR RTRIM(incat_error)='') 
		AND cat_id = alt_id 
		AND alt_clave = incat_clave 
		AND alt_tabla='cat'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------	
	--ALTA REGISTROS NUEVOS

	TRUNCATE TABLE in_carteras_aux

	INSERT in_carteras_aux
		(cat_id, cat_cod,cat_nombre_corto,cat_nombre,cat_kit,cat_ege,cat_obs,cat_alta_fecha,cat_p_alta_fecha,cat_usu_id,cat_filler,cat_clave)
	SELECT 
		0, 			--cat_id
		incat_codigo,		--cat_cod
		incat_nombre_corto,	--cat_nombre_corto
		incat_nombre,		--cat_nombre
		(select kit_id from wf_kit where kit_nombre_corto=incat_kit and kit_baja_fecha is null),-- cat_kit
		(select ege_id from wf_equipos_gestion where ege_nombre_corto=incat_ege and ege_baja_fecha is null),-- cat_ege
		incat_obs, 		--cat_obs
		getdate(),		--cat_alta_fecha,
		@v_fec_proceso, --cat_p_alta_fecha
		@v_usu_id,		--cat_usu_id
		incat_filler,		--cat_filler
		incat_clave 		
	FROM
		in_carteras
	WHERE
		(incat_error IS NULL OR RTRIM(incat_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='cat' AND alt_clave=incat_clave)
		
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------	
	SELECT @Puntero = ISNULL(MAX(cat_id),0) FROM carteras
	UPDATE in_carteras_aux SET cat_id=@Puntero, @Puntero=@Puntero+1 
	
	SET @error_aux = @@error

	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------		
	INSERT carteras(cat_id, cat_cod,cat_nombre_corto,cat_nombre,cat_kit,cat_ege,cat_obs,cat_alta_fecha,cat_p_alta_fecha,cat_usu_id,cat_filler)
	SELECT
		cat_id, cat_cod,cat_nombre_corto,cat_nombre,cat_kit,cat_ege,cat_obs,cat_alta_fecha,cat_p_alta_fecha,cat_usu_id,cat_filler
	FROM in_carteras_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux	
	----------------------------------------------------------------------			
	SELECT @#Enviados = count(*) FROM in_carteras
	SELECT @#Rechazados = count(*) FROM in_carteras where incat_error IS NOT NULL AND RTRIM(incat_error) <> '' 
	SELECT @#Ingresados = count(*) FROM in_carteras_aux 
	SELECT @#Actualizados =  count(*) from in_carteras  join wf_in_alta_aut on alt_clave = incat_clave and alt_tabla = 'cat' where incat_error IS NULL OR RTRIM(incat_error)=''	
	----------------------------------------------------------------------		
	INSERT wf_in_alta_aut 
	SELECT 'cat',cat_clave,cat_id
	FROM in_carteras_aux
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------		
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN CARTERAS
		END
	ELSE
		BEGIN
		ROLLBACK TRAN CARTERAS

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END
	----------------------------------------------------------------------			
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Carteras  - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Carteras  - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Carteras  - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Carteras  - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END


-------------------------------------------------------------------------------------------------------------------------
--TABLA PERSONAS
-------------------------------------------------------------------------------------------------------------------------
IF (@v_regPer IS NOT NULL) AND @v_regPer > 0 
BEGIN	
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Personas',  @v_usu_id_in, Null, @v_cat_id

	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0

	SET @error_tran = 0
	BEGIN TRAN PERSONAS
	----------------------------------------------------------------------				
	--MODIFICACION DE REGISTROS
	
	UPDATE personas
	SET
		per_cli = RTRIM(in_personas.inper_cli),
		per_slg = ISNULL((select slg_id from sit_legal where slg_nombre_corto = inper_slg and slg_baja_fecha is null),0), 
		per_gec = ISNULL((select gec_id from grupo_economico where gec_nombre_corto = inper_gec and gec_baja_fecha is null),0), 
		per_nombre = RTRIM(in_personas.inper_nombre),
		per_apellido = RTRIM(in_personas.inper_apellido),
		per_civ = ISNULL((select civ_id from cond_iva where civ_nombre_corto = inper_civ and civ_baja_fecha is null),0), 
		per_email = RTRIM(in_personas.inper_email),--AGREGADO PARA LEASING
		per_nacionalidad = RTRIM(in_personas.inper_nacionalidad), 
		per_ent = ISNULL((select ent_id from entidades where ent_nombre_corto = inper_ent and ent_baja_fecha is null),0), 
		per_suc = ISNULL((select suc_id from sucursales, entidades where suc_ent = ent_id and ent_nombre_corto = inper_ent and suc_nombre_corto = inper_suc and suc_baja_fecha is null),0),
		per_filler = RTRIM(in_personas.inper_filler),
		per_p_modi_fecha = @v_fec_proceso
	FROM in_personas, wf_in_alta_aut
	WHERE
		(inper_error IS NULL OR RTRIM(inper_error)='') AND
		per_id = alt_id AND alt_clave = inper_clave AND alt_tabla='per'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------					
	--ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_personas_aux
	
	INSERT in_personas_aux
		(per_id,per_acv,per_cli,per_slg,per_fec_slg,per_gec,per_ecv,per_apellido,per_nombre,
		per_civ,per_fec_nac,per_email,per_obs,per_sexo,per_fis_jur,per_nacionalidad,per_notas,
		per_ent,per_suc,per_alta_fecha,per_modi_fecha,per_baja_fecha,
		per_p_alta_fecha, per_p_modi_fecha, per_usu_id,per_filler,per_clave)
	SELECT 
		0, --per_id
		ISNULL((select acv_id from actividades where acv_nombre_corto = inper_acv and acv_baja_fecha is null),0), --per_acv
		inper_cli, --per_cli
		ISNULL((select slg_id from sit_legal where slg_nombre_corto = inper_slg and slg_baja_fecha is null),0), --per_slg
		(CASE ISDATE(inper_fec_slg) 
			WHEN 0 THEN NULL
			ELSE CONVERT(DATETIME,inper_fec_slg)
		END), --per_fec_slg
		ISNULL((select gec_id from grupo_economico where gec_nombre_corto = inper_gec and gec_baja_fecha is null),0), --per_gec
		ISNULL((select ecv_id from estado_civil where ecv_nombre_corto = inper_ecv AND ecv_baja_fecha is null),0), --per_ecv
		inper_apellido, --per_apellido
		inper_nombre, --per_nombre
		ISNULL((select civ_id from cond_iva where civ_nombre_corto = inper_civ and civ_baja_fecha is null),0), --per_civ
		(CASE ISDATE(inper_fec_nac) 
			WHEN 0 THEN NULL
			ELSE CONVERT(DATETIME,inper_fec_nac)
		END)	, --per_fec_nac
		inper_email, --per_email
		inper_obs, --per_obs
		inper_sexo, --per_sexo
		inper_fis_jur, --per_fis_jur
		inper_nacionalidad, --per_nacionalidad
		'', --per_notas
		ISNULL((select ent_id from entidades where ent_nombre_corto = inper_ent and ent_baja_fecha is null),0), --per_ent
		ISNULL((select suc_id from sucursales, entidades where suc_ent = ent_id and ent_nombre_corto = inper_ent and suc_nombre_corto = inper_suc and suc_baja_fecha is null),0), --per_suc 
		GETDATE(), --per_alta_fecha
		NULL, --per_modi_fecha
		NULL, --per_baja_fecha
		@v_fec_proceso, --per_p_alta_fecha
		NULL, --per_p_modi_fecha
		@v_usu_id, --per_usu_id
		inper_filler, --per_filler
		inper_clave --per_clave
	FROM
		in_personas
	WHERE
		(inper_error IS NULL OR RTRIM(inper_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='per' AND alt_clave=inper_clave)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------			
	SELECT @Puntero = ISNULL(MAX(per_id),0) FROM personas
	UPDATE in_personas_aux SET per_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------							
	INSERT personas 
	SELECT
		per_id,per_acv,per_cli,per_slg,per_fec_slg,per_gec,per_ecv,per_apellido,per_nombre,
		per_civ,per_fec_nac,per_email,per_obs,per_sexo,per_fis_jur,per_nacionalidad,per_notas,
		per_ent,per_suc,per_alta_fecha,per_modi_fecha,per_baja_fecha,
		per_p_alta_fecha, per_p_modi_fecha, per_usu_id,per_filler
	FROM in_personas_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------					
	SELECT @#Enviados = count(*) FROM in_personas
	SELECT @#Rechazados = count(*) FROM in_personas WHERE inper_error IS NOT NULL AND RTRIM(inper_error) <> '' 
	SELECT @#Ingresados = count(*) FROM in_personas_aux 
	SELECT @#Actualizados =  count(*) FROM in_personas INNER JOIN wf_in_alta_aut ON alt_clave = inper_clave AND alt_tabla = 'per' WHERE inper_error IS NULL OR RTRIM(inper_error)=''
	----------------------------------------------------------------------					
	INSERT wf_in_alta_aut 
	SELECT 'per',per_clave,per_id
	FROM in_personas_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------					
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN PERSONAS
		END
	ELSE
		BEGIN
		ROLLBACK TRAN PERSONAS

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END
	----------------------------------------------------------------------							
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Personas - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados),  @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Personas - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados),  @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Personas - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados),  @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Personas - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados),  @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END
-------------------------------------------------------------------------------------------------------------------------
--TABLA PER_DOM
-------------------------------------------------------------------------------------------------------------------------
IF (@v_regPer_dom IS NOT NULL) AND @v_regPer_dom > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Domicilios',  @v_usu_id_in, Null, @v_cat_id
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------								
	UPDATE in_per_dom SET inpdm_error='T', inpdm_error_campo='inpdm_per_clave' WHERE 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='per' and alt_clave = inpdm_per_clave)
	----------------------------------------------------------------------							
	SET @error_tran = 0
	BEGIN TRAN PER_DOM
	----------------------------------------------------------------------								
	--BAJA DE REGISTROS
	UPDATE per_dom
	SET	
		pdm_baja_fecha = CASE 
				WHEN ISDATE(SUBSTRING(inpdm_filler, 2,8))=1 THEN CONVERT(DATETIME,SUBSTRING(inpdm_filler, 2,8))
				ELSE pdm_baja_fecha
				END		
	FROM in_per_dom , wf_in_alta_aut
	WHERE
		(inpdm_error IS NULL OR RTRIM(inpdm_error)='') AND
		SUBSTRING(inpdm_filler, 1,1) = 'B' AND
		pdm_id = alt_id AND alt_clave = inpdm_clave AND alt_tabla='pdm'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	
	----------------------------------------------------------------------	
	--MODIFICACION DE REGISTROS
	UPDATE per_dom
	SET	
		pdm_dti = ISNULL((select dti_id from tipos_domicilios where dti_nombre_corto = inpdm_dti and dti_baja_fecha is null),0),
		pdm_calle = inpdm_calle,
		pdm_numero = inpdm_numero,
		pdm_piso = inpdm_piso,
		pdm_dpto = inpdm_dpto,
		pdm_loc_texto = inpdm_loc_texto,
		pdm_loc = ISNULL((SELECT loc_id FROM localidades, provincias, paises WHERE prv_id = loc_prv AND pai_id = prv_pai AND pai_nombre_corto = inpdm_pai AND prv_nombre_corto = inpdm_prv AND loc_nombre_corto = inpdm_loc AND loc_baja_fecha IS NULL),0), --pdm_loc
		pdm_prv = ISNULL((SELECT prv_id FROM provincias, paises WHERE pai_id = prv_pai AND pai_nombre_corto = inpdm_pai AND prv_nombre_corto = inpdm_prv AND prv_baja_fecha IS NULL),0), 
		pdm_cop = ISNULL((SELECT cop_id FROM codigos_postales, localidades, provincias, paises WHERE cop_loc = loc_id and prv_id = loc_prv AND pai_id = prv_pai AND pai_nombre_corto = inpdm_pai AND prv_nombre_corto = inpdm_prv AND loc_nombre_corto = inpdm_loc AND cop_numero = inpdm_cop AND cop_baja_fecha IS NULL and loc_baja_fecha is null  and pai_baja_fecha is null and prv_baja_fecha is null),0), --pdm_cop
		pdm_cod_postal = inpdm_cod_postal,
		pdm_pai = ISNULL((select pai_id from paises where pai_nombre_corto = inpdm_pai and pai_baja_fecha is null),0), 
		pdm_obs = inpdm_obs,
		pdm_p_modi_fecha = @v_fec_proceso,
		pdm_usu_id = @v_usu_id,
		pdm_filler = inpdm_filler
	FROM in_per_dom, wf_in_alta_aut
	WHERE
		(inpdm_error IS NULL OR RTRIM(inpdm_error)='') AND
		pdm_id = alt_id AND alt_clave = inpdm_clave AND alt_tabla='pdm'
	----------------------------------------------------------------------									
	--ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_per_dom_aux
	
	INSERT in_per_dom_aux
		(pdm_id, pdm_per, pdm_default, pdm_dti, pdm_calle, pdm_numero, pdm_piso, pdm_dpto, pdm_loc_texto,
		pdm_loc, pdm_prv, pdm_cop, pdm_cod_postal, pdm_pai, pdm_obs, pdm_alta_fecha, pdm_modi_fecha,
		pdm_baja_fecha, pdm_p_alta_fecha, pdm_p_modi_fecha, pdm_usu_id, pdm_filler, pdm_clave)

	SELECT 
		0, --pdm_id 
		(select alt_id from wf_in_alta_aut where alt_tabla='per' and alt_clave=inpdm_per_clave), --pdm_per
		inpdm_default, --pdm_default
		ISNULL((select dti_id from tipos_domicilios where dti_nombre_corto = inpdm_dti and dti_baja_fecha is null),0), --pdm_dti
		inpdm_calle, --pdm_calle
		inpdm_numero, --pdm_numero
		inpdm_piso, --pdm_piso
		inpdm_dpto, --pdm_dpto
		inpdm_loc_texto, --pdm_loc_texto
		ISNULL((SELECT loc_id FROM localidades, provincias, paises WHERE prv_id = loc_prv AND pai_id = prv_pai AND pai_nombre_corto = inpdm_pai AND prv_nombre_corto = inpdm_prv AND loc_nombre_corto = inpdm_loc AND loc_baja_fecha IS NULL),0), --pdm_loc
		ISNULL((SELECT prv_id FROM provincias, paises WHERE pai_id = prv_pai AND pai_nombre_corto = inpdm_pai AND prv_nombre_corto = inpdm_prv AND prv_baja_fecha IS NULL),0), --pdm_prv
		ISNULL((SELECT cop_id FROM codigos_postales, localidades, provincias, paises WHERE cop_loc = loc_id and prv_id = loc_prv AND pai_id = prv_pai AND pai_nombre_corto = inpdm_pai AND prv_nombre_corto = inpdm_prv AND loc_nombre_corto = inpdm_loc AND cop_numero = inpdm_cop AND cop_baja_fecha IS NULL and loc_baja_fecha is null  and pai_baja_fecha is null and prv_baja_fecha is null),0), --pdm_cop
		inpdm_cod_postal, --pdm_cod_postal
		ISNULL((select pai_id from paises where pai_nombre_corto = inpdm_pai and pai_baja_fecha is null),0), --pdm_pai
		inpdm_obs, --pdm_obs
		GETDATE(), --pdm_alta_fecha
		null, --pdm_modi
		null, --pdm_baja_fecha
		@v_fec_proceso, --pdm_p_alta_fecha
		null, --pdm_p_modi_fecha
		@v_usu_id, --pdm_usu_id
		inpdm_filler, --pdm_filler
		inpdm_clave --pdm_clave
	
	FROM
		in_per_dom
	WHERE
		(inpdm_error IS NULL OR RTRIM(inpdm_error)='') and
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='pdm' AND alt_clave=inpdm_clave)
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------							
	SELECT @Puntero = ISNULL(MAX(pdm_id),0) FROM per_dom
	UPDATE in_per_dom_aux SET pdm_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------								
	UPDATE per_dom SET pdm_default='N' WHERE per_dom.pdm_per IN (SELECT pdm_per
							FROM in_per_dom_aux 
							WHERE in_per_dom_aux.pdm_default='S' AND
								in_per_dom_aux.pdm_per = per_dom.pdm_per)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux	
	----------------------------------------------------------------------										
	INSERT per_dom
	SELECT
		pdm_id, pdm_per, pdm_default, pdm_dti, pdm_calle, pdm_numero, pdm_piso, pdm_dpto, pdm_loc_texto,
		pdm_loc, pdm_prv, pdm_cop, pdm_cod_postal, pdm_pai, pdm_obs, pdm_alta_fecha, pdm_modi_fecha,
		pdm_baja_fecha, pdm_p_alta_fecha, pdm_p_modi_fecha, pdm_usu_id, pdm_filler
	FROM in_per_dom_aux
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------										
	SELECT @#Enviados = count(*) FROM in_per_dom
	SELECT @#Rechazados = count(*) FROM in_per_dom where inpdm_error IS NOT NULL AND RTRIM(inpdm_error) <> '' 
	SELECT @#Ingresados = count(*) FROM in_per_dom_aux 
	SELECT @#Actualizados =  count(*) from in_per_dom  join wf_in_alta_aut on alt_clave = inpdm_clave and alt_tabla = 'pdm' where inpdm_error IS NULL OR RTRIM(inpdm_error)=''
	----------------------------------------------------------------------											
	INSERT wf_in_alta_aut 
	SELECT 'pdm',pdm_clave,pdm_id
	FROM in_per_dom_aux
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------									
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN PER_DOM
		END
	ELSE
		BEGIN
		ROLLBACK TRAN PER_DOM

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END
	----------------------------------------------------------------------										
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Domicilios - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Domicilios - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Domicilios - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Domicilios - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END
-------------------------------------------------------------------------------------------------------------------------
--TABLA PER_TEL
-------------------------------------------------------------------------------------------------------------------------
IF (@v_regper_tel IS NOT NULL) AND @v_regper_tel > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Teléfonos', @v_usu_id_in, Null, @v_cat_id	
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------											
	UPDATE in_per_tel SET inpte_error='T', inpte_error_campo='inpte_per_clave' WHERE 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='per' and alt_clave = inpte_per_clave)	
	----------------------------------------------------------------------											
	UPDATE in_per_tel SET inpte_error='T', inpte_error_campo='inpte_pdm_clave' WHERE 
	ISNULL(inpte_pdm_clave, '') <> '' AND
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='pdm' and alt_clave = inpte_pdm_clave)
	----------------------------------------------------------------------											
	SET @error_tran = 0
	BEGIN TRAN PER_TEL
	----------------------------------------------------------------------										
	--BAJA DE REGISTROS
	UPDATE per_tel
	SET	
		pte_baja_fecha = CASE 
				WHEN ISDATE(SUBSTRING(inpte_filler, 2,8))=1 THEN CONVERT(DATETIME,SUBSTRING(inpte_filler, 2,8))
				ELSE pte_baja_fecha
				END		
	FROM in_per_tel , wf_in_alta_aut
	WHERE
		(inpte_error IS NULL OR RTRIM(inpte_error)='') AND
		SUBSTRING(inpte_filler, 1,1) = 'B' AND

		pte_id = alt_id AND alt_clave = inpte_clave AND alt_tabla='pte'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	
	----------------------------------------------------------------------										
	--MODIFICACION DE REGISTROS
	UPDATE per_tel
	SET	
		pte_tti = ISNULL((select tti_id from tipos_telefonos where tti_nombre_corto = inpte_tti and tti_baja_fecha is null),0),
		pte_cod_pais = inpte_cod_pais,
		pte_cod_area = inpte_cod_area,
		pte_telefono = inpte_telefono,
		pte_obs = inpte_obs, 
		pte_pdm = CASE 
				WHEN LEN(LTRIM(inpte_pdm_clave))=0 THEN 0
				ELSE (select alt_id FROM wf_in_alta_aut where alt_tabla='pdm' and alt_clave=inpte_pdm_clave)				
				END, 
		pte_p_modi_fecha = @v_fec_proceso,
		pte_usu_id = @v_usu_id,
		pte_filler = inpte_filler
	FROM in_per_tel , wf_in_alta_aut
	WHERE
		(inpte_error IS NULL OR RTRIM(inpte_error)='') AND
		pte_id = alt_id AND alt_clave = inpte_clave AND alt_tabla='pte'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------										
	--ALTA REGISTROS NUEVOS
	
	TRUNCATE TABLE in_per_tel_aux
	
	INSERT in_per_tel_aux
		(pte_id, pte_per, pte_default, pte_tti, pte_cod_pais, pte_cod_area, pte_telefono, pte_obs, pte_dia_pref1,
		pte_dia_pref2, pte_dia_pref3, pte_dia_pref4, pte_dia_pref5, pte_dia_pref6, pte_dia_pref7, pte_pdm,
		pte_alta_fecha, pte_modi_fecha, pte_baja_fecha, pte_p_alta_fecha, pte_p_modi_fecha, pte_usu_id, pte_filler, pte_clave)

	SELECT 
		0, --pte_id
		(select alt_id from wf_in_alta_aut where alt_tabla='per' and alt_clave=inpte_per_clave), --pte_per
		inpte_default, --pte_default
		ISNULL((select tti_id from tipos_telefonos where tti_nombre_corto = inpte_tti and tti_baja_fecha is null),0), --pte_tti
		inpte_cod_pais, --pte_cod_pais
		inpte_cod_area, --pte_cod_area
		inpte_telefono, --pte_telefono
		inpte_obs, --pte_obs
		'',--pte_dia_pref1
		'',--pte_dia_pref2
		'',--pte_dia_pref3
		'',--pte_dia_pref4
		'',--pte_dia_pref5
		'',--pte_dia_pref6
		'',--pte_dia_pref7
		CASE 
			WHEN LEN(LTRIM(inpte_pdm_clave))=0 THEN 0
			ELSE (select alt_id FROM wf_in_alta_aut where alt_tabla='pdm' and alt_clave=inpte_pdm_clave)
		END, --pte_pdm
		GETDATE(), --pte_alta_fecha
		NULL, --pte_modi_fecha
		NULL, --pte_baja_fecha
		@v_fec_proceso, --pte_p_alta_fecha
		NULL, --pte_p_modi_fecha
		@v_usu_id, --pte_usu_id
		inpte_filler, --pte_filler
		inpte_clave --pte_clave
	FROM
		in_per_tel
	WHERE
		(inpte_error IS NULL OR RTRIM(inpte_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='pte' AND alt_clave=inpte_clave)
		
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------											
	SELECT @Puntero = ISNULL(MAX(pte_id),0) FROM per_tel
	UPDATE in_per_tel_aux SET pte_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------												
	UPDATE per_tel SET pte_default='N' WHERE per_tel.pte_per IN(SELECT pte_per
							FROM in_per_tel_aux 
							WHERE in_per_tel_aux.pte_default='S' AND
							in_per_tel_aux.pte_per = per_tel.pte_per AND
							per_tel.pte_baja_fecha is null)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------											
	INSERT per_tel
	SELECT
		pte_id, pte_per, pte_default, pte_tti, pte_cod_pais, pte_cod_area, pte_telefono, pte_obs, pte_dia_pref1,
		pte_dia_pref2, pte_dia_pref3, pte_dia_pref4, pte_dia_pref5, pte_dia_pref6, pte_dia_pref7, pte_pdm,
		pte_alta_fecha, pte_modi_fecha, pte_baja_fecha, pte_p_alta_fecha, pte_p_modi_fecha, pte_usu_id, pte_filler
	FROM in_per_tel_aux
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------													
	SELECT @#Enviados = count(*) FROM in_per_tel
	SELECT @#Rechazados = count(*) FROM in_per_tel where inpte_error IS NOT NULL AND RTRIM(inpte_error) <> '' 
	SELECT @#Ingresados = count(*) FROM in_per_tel_aux 
	SELECT @#Actualizados =  count(*) from in_per_tel  join wf_in_alta_aut on alt_clave = inpte_clave and alt_tabla = 'pte' where inpte_error IS NULL OR RTRIM(inpte_error)=''
	----------------------------------------------------------------------													
	INSERT wf_in_alta_aut 
	SELECT 'pte',pte_clave,pte_id
	FROM in_per_tel_aux
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------													
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN PER_TEL
		END
	ELSE
		BEGIN
		ROLLBACK TRAN PER_TEL

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END
	----------------------------------------------------------------------														

	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Teléfonos - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Teléfonos - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Teléfonos - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Teléfonos - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END

-------------------------------------------------------------------------------------------------------------------------
--TABLA PER_DOC
-------------------------------------------------------------------------------------------------------------------------
IF (@v_regper_doc IS NOT NULL) AND @v_regper_doc > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Documentos', @v_usu_id_in, Null, @v_cat_id
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------														
	UPDATE in_per_doc SET inpdc_error='T', inpdc_error_campo='inpdc_per_clave' WHERE 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='per' and alt_clave = inpdc_per_clave)		
	----------------------------------------------------------------------														
	SET @error_tran = 0
	BEGIN TRAN PER_DOC
	----------------------------------------------------------------------														
	--MODIFICACION DE REGISTROS
	UPDATE per_doc
	SET		
		pdc_default =  inpdc_default,
		pdc_tdc = ISNULL((select tdc_id from tipos_documentos where tdc_nombre_corto = inpdc_tdc and tdc_baja_fecha is null),0), 
		pdc_nro = inpdc_nro,  
		pdc_obs = inpdc_obs, 
		pdc_p_modi_fecha = @v_fec_proceso, 
		pdc_usu_id = @v_usu_id,
		pdc_filler = inpdc_filler
	FROM in_per_doc , wf_in_alta_aut
	WHERE
		(inpdc_error IS NULL OR RTRIM(inpdc_error)='') AND
		pdc_id = alt_id AND alt_clave = inpdc_clave AND alt_tabla='pdc'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------															
	--ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_per_doc_aux
	
	INSERT in_per_doc_aux
		(pdc_id, pdc_per, pdc_default, pdc_tdc, pdc_nro, pdc_obs, pdc_alta_fecha,
		pdc_modi_fecha, pdc_baja_fecha, pdc_p_alta_fecha, pdc_p_modi_fecha, pdc_usu_id, pdc_filler, pdc_clave)
	SELECT 
		0, --pdc_id
		(select alt_id from wf_in_alta_aut where alt_tabla='per' and alt_clave=inpdc_per_clave), --pdc_per
		inpdc_default, --pdc_default
		ISNULL((select tdc_id from tipos_documentos where tdc_nombre_corto = inpdc_tdc and tdc_baja_fecha is null),0),	--pdc_tdc
		inpdc_nro, --pdc_nro
		inpdc_obs, --pdc_obs
		GETDATE(), --pdc_alta_fecha
		NULL, --pdc_modi_fecha
		NULL, --pdc_baja_fecha
		@v_fec_proceso, --pdc_p_alta_fecha
		NULL, --pdc_p_modi_fecha
		@v_usu_id, --pdc_usu_id
		inpdc_filler, --pdc_filler
		inpdc_clave --pdc_clave
	FROM
		in_per_doc
	WHERE
		(inpdc_error IS NULL OR RTRIM(inpdc_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='pdc' AND alt_clave=inpdc_clave)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------														
	SELECT @Puntero = ISNULL(MAX(PDC_id),0) FROM per_doc
	UPDATE in_per_doc_aux SET pdc_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------															
	UPDATE per_doc SET pdc_default='N' WHERE per_doc.pdc_per IN(SELECT pdc_per
						FROM in_per_doc_aux 
						WHERE in_per_doc_aux.pdc_default='S' AND
						in_per_doc_aux.pdc_per = per_doc.pdc_per)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------														
	INSERT per_doc
	SELECT
		pdc_id, pdc_per, pdc_default, pdc_tdc, pdc_nro, pdc_obs, pdc_alta_fecha,
		pdc_modi_fecha, pdc_baja_fecha, pdc_p_alta_fecha, pdc_p_modi_fecha, pdc_usu_id, pdc_filler 
	FROM in_per_doc_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	SELECT @#Enviados = count(*) FROM in_per_doc
	SELECT @#Rechazados = count(*) FROM in_per_doc WHERE inpdc_error IS NOT NULL AND RTRIM(inpdc_error) <> '' 
	SELECT @#Ingresados = count(*) FROM in_per_doc_aux 
	SELECT @#Actualizados =  count(*) FROM in_per_doc INNER JOIN wf_in_alta_aut ON alt_clave = inpdc_clave AND alt_tabla = 'pdc' WHERE inpdc_error IS NULL OR RTRIM(inpdc_error)=''
	----------------------------------------------------------------------																
	INSERT wf_in_alta_aut 
	SELECT 'pdc',pdc_clave,pdc_id
	FROM in_per_doc_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN PER_DOC
		END
	ELSE
		BEGIN
		ROLLBACK TRAN PER_DOC

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END	
	----------------------------------------------------------------------																	
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Documentos - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Documentos - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Documentos - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Documentos - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id

END



-------------------------------------------------------------------------------------------------------------------------
--TABLA CUENTAS
--------------------------------------------------------------------------------------------------------------------------
IF (@v_regcta IS NOT NULL) AND @v_regcta > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas', @v_usu_id_in, Null, @v_cat_id
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------																			
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas INICIO update T-incta_per_clave', @v_usu_id_in, Null, @v_cat_id

	UPDATE in_cuentas SET incta_error='T',incta_error_campo='incta_per_clave' WHERE 
	NOT EXISTS (select 1 from wf_in_alta_aut where alt_tabla='per' and alt_clave = incta_per_clave)	

	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas FIN update T-incta_per_clave', @v_usu_id_in, Null, @v_cat_id	
	----------------------------------------------------------------------																	
	SET @error_tran = 0
	BEGIN TRAN CUENTAS
	----------------------------------------------------------------------																	
-- /*20200508*/	DECLARE @cta_id int
-- /*20200508*/	DECLARE @pro_id int
-- /*20200508*/	DECLARE @cla_id int
-- /*20200508*/	DECLARE @suc_id int
-- /*20200508*/	DECLARE @mon_id int
-- /*20200508*/	DECLARE @cnl_id int
-- /*20200508*/	DECLARE @cam_id int
-- /*20200508*/	DECLARE @bnc_id int
-- /*20200508*/	DECLARE @ent_id int
-- /*20200508*/	DECLARE @civ_id int
-- /*20200508*/	DECLARE @age_id int
-- /*20200508*/	DECLARE @tco_id int
-- /*20200508*/	DECLARE @tpa_id int
-- /*20200508*/	DECLARE @cat_id int
-- /*20200508*/	Declare rsBitacora Cursor For	Select	alt_id,
-- /*20200508*/						cta_pro = ISNULL((select pro_id from productos where pro_nombre_corto = incta_pro and pro_baja_fecha is null),0), 
-- /*20200508*/						cta_cla = ISNULL((select cla_id from clasificaciones where cla_nombre_corto = incta_cla and cla_baja_fecha is null),0), 
-- /*20200508*/						cta_suc = ISNULL((select suc_id from sucursales, entidades where suc_ent = ent_id and ent_nombre_corto = incta_ent and suc_nombre_corto = incta_suc and suc_baja_fecha is null),0),
-- /*20200508*/						cta_mon = ISNULL((select mon_id from monedas where mon_cod = incta_mon and mon_baja_fecha is null),0), 
-- /*20200508*/						cta_cnl = ISNULL((select cnl_id from canales, entidades where cnl_ent = ent_id and cnl_nombre_corto = incta_cnl and RTRIM(ent_nombre_corto) = RTRIM(incta_ent) AND cnl_baja_fecha is null),0), 
-- /*20200508*/						cta_cam = ISNULL((select cam_id from camp_comer, entidades where cam_ent = ent_id AND cam_nombre_corto = incta_cam AND RTRIM(ent_nombre_corto) = RTRIM(incta_ent) and cam_baja_fecha is null),0), 
-- /*20200508*/						cta_bnc = ISNULL((select bnc_id from banca where bnc_nombre_corto = incta_bnc and bnc_baja_fecha is null),0), 
-- /*20200508*/						cta_ent = ISNULL((select ent_id from entidades where ent_nombre_corto = incta_ent and ent_baja_fecha is null),0), 
-- /*20200508*/						cta_civ = ISNULL((select civ_id from cond_iva where civ_nombre_corto = incta_civ and civ_baja_fecha is null),0), 
-- /*20200508*/						cta_age = ISNULL((select age_id from agencias where age_cod = incta_age and age_baja_fecha is null),0) ,
-- /*20200508*/						cta_tco = ISNULL((select tco_id from tipos_contratos where tco_nombre_corto = incta_tco and tco_baja_fecha is null),0), 
-- /*20200508*/						cta_tpa = ISNULL((select tpa_id from tipos_paquetes where tpa_nombre_corto = incta_tpa and tpa_baja_fecha is null),0) ,
-- /*20200508*/						cta_cat = ISNULL((select cat_id from carteras where cat_nombre_corto = incta_cat and cat_baja_fecha is null),0) 
-- /*20200508*/
-- /*20200508*/					FROM in_cuentas, wf_in_alta_aut
-- /*20200508*/					WHERE
-- /*20200508*/						(incta_error IS NULL OR RTRIM(incta_error)='') AND 
-- /*20200508*/						alt_clave = incta_clave AND 
-- /*20200508*/						alt_tabla='cta'
-- /*20200508*/	Open rsBitacora
-- /*20200508*/	Fetch Next From rsBitacora into @cta_id,@pro_id,@cla_id,@suc_id,@mon_id,@cnl_id,@cam_id,@bnc_id,@ent_id,@civ_id,@age_id,@tco_id,@tpa_id,@cat_id
-- /*20200508*/	While @@Fetch_Status = 0
-- /*20200508*/	BEGIN
-- /*20200508*/		--Print @cta_id
-- /*20200508*/		/* Se elimina el cambio de cartera ya que no existen casos con este comportamiento*/
-- /*20200508*/		/*EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_cat',  --@v_tipo		varchar(20),
-- /*20200508*/			@cat_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/		*/
-- /*20200508*/
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_pro',  --@v_tipo		varchar(20),
-- /*20200508*/			@pro_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_cla',  --@v_tipo		varchar(20),
-- /*20200508*/			@cla_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_suc',  --@v_tipo		varchar(20),
-- /*20200508*/			@suc_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_bnc',  --@v_tipo		varchar(20),
-- /*20200508*/			@bnc_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/	/* INI - se eliminan estos cambios ya que no son siginificativo el cambio y demora el batch - 20200408
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_mon',  --@v_tipo		varchar(20),
-- /*20200508*/			@mon_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_cnl',  --@v_tipo		varchar(20),
-- /*20200508*/			@cnl_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_cam',  --@v_tipo		varchar(20),
-- /*20200508*/			@cam_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_ent',  --@v_tipo		varchar(20),
-- /*20200508*/			@ent_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_civ',  --@v_tipo		varchar(20),
-- /*20200508*/			@civ_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/	/*	EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_age',  --@v_tipo		varchar(20),
-- /*20200508*/			@age_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT     SE ACTUALIZAN LAS AGENCIAS POR REGLAS   */
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_tco',  --@v_tipo		varchar(20),
-- /*20200508*/			@tco_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/		EXEC dbo.cmb_cta_auto
-- /*20200508*/			@cta_id,  --@v_cta_id	int,
-- /*20200508*/			'cta_tpa',  --@v_tipo		varchar(20),
-- /*20200508*/			@tpa_id, --@v_id_nuevo	int,
-- /*20200508*/			@v_usu_id,          --@v_usu_id	  	int,
-- /*20200508*/			'',
-- /*20200508*/			@error_aux  --@v_cod_ret	int OUT
-- /*20200508*/		*/ -- FIN - se eliminan estos cambios ya que no son siginificativo el cambio y demora el batch - 20200408
-- /*20200508*/		Fetch Next From rsBitacora into @cta_id,@pro_id,@cla_id,@suc_id,@mon_id,@cnl_id,@cam_id,@bnc_id,@ent_id,@civ_id,@age_id,@tco_id,@tpa_id,@cat_id
-- /*20200508*/	END
-- /*20200508*/	Close rsBitacora
-- /*20200508*/	Deallocate rsBitacora

	----------------------------------------------------------------------																	
	--MODIFICACION DE REGISTROS

--Invocar sp de log en bitacora de cambio de titular
exec dbo.[COM_wf_p_cambio_titular] @v_fec_proceso, @v_usu_id_in, @error_aux


UPDATE cuentas --modificado DG 20100826 se agrego actualizacion del cta_per
			   --modificado MMM 20130306 se agregó actualización de cta_baja_fecha
	SET
		cta_per =  isnull((select alt_id from wf_in_alta_aut where alt_tabla = 'per' and alt_clave = incta_per_clave), cta_per), 
		cta_pro = ISNULL((select pro_id from productos where pro_nombre_corto = incta_pro and pro_baja_fecha is null),0), 
		cta_cla = ISNULL((select cla_id from clasificaciones where cla_nombre_corto = incta_cla and cla_baja_fecha is null),0), 
		cta_num_oper = incta_num_oper,
		cta_suc = ISNULL((select suc_id from sucursales, entidades where suc_ent = ent_id and ent_nombre_corto = incta_ent and suc_nombre_corto = incta_suc and suc_baja_fecha is null),0), 
		cta_mon = ISNULL((select mon_id from monedas where mon_cod = incta_mon and mon_baja_fecha is null),0), 
		cta_cnl = ISNULL((select cnl_id from canales, entidades where cnl_ent = ent_id and cnl_nombre_corto = incta_cnl AND RTRIM(ent_nombre_corto) = RTRIM(incta_ent) and cnl_baja_fecha is null),0), 
		cta_cam = ISNULL((select cam_id from camp_comer, entidades where cam_ent = ent_id AND cam_nombre_corto = incta_cam AND RTRIM(ent_nombre_corto) = RTRIM(incta_ent) and cam_baja_fecha is null),0), 
		cta_bnc = ISNULL((select bnc_id from banca where bnc_nombre_corto = incta_bnc and bnc_baja_fecha is null),0), 
		cta_ent = ISNULL((select ent_id from entidades where ent_nombre_corto = incta_ent and ent_baja_fecha is null),0), 
		cta_civ = CASE 	WHEN (LTRIM(RTRIM(incta_civ)) <> '') 
			       	THEN (ISNULL((select civ_id from cond_iva where civ_nombre_corto = incta_civ and civ_baja_fecha is null),0))
			       	ELSE (select per_civ from personas where per_id = cta_per) END, 
		cta_fec_vto = (CASE ISDATE(incta_fec_vto) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,incta_fec_vto)	END),
		cta_deuda_venc = CONVERT(NUMERIC(16,2),incta_deuda_venc)/100,
		cta_deuda_a_venc = CONVERT(NUMERIC(16,2),incta_deuda_a_venc)/100, 
		cta_fec_cla = CASE 	WHEN(LTRIM(RTRIM(incta_fec_cla)) <> '99991231') 
					THEN CONVERT(DATETIME,incta_fec_cla)
				      	ELSE (select per_fec_slg from personas where per_id = cta_per) END, 				
--		cta_age = ISNULL((select age_id from agencias where age_cod = incta_age and age_baja_fecha is null),0) ,                    SE ACTUALIZAN LAS AGENCIAS POR REGLAS
--		cta_age_fec_ini = (CASE ISDATE(incta_age_fec_ini) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,incta_age_fec_ini) END),           SE ACTUALIZAN LAS AGENCIAS POR REGLAS
--		cta_age_fec_fin = (CASE ISDATE(incta_age_fec_fin) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,incta_age_fec_fin) END),           SE ACTUALIZAN LAS AGENCIAS POR REGLAS
--		cta_age_respons = incta_age_respons,                                                                                        SE ACTUALIZAN LAS AGENCIAS POR REGLAS
		cta_tco = ISNULL((select tco_id from tipos_contratos where tco_nombre_corto = incta_tco and tco_baja_fecha is null),0), 
		cta_res_com = incta_res_com,
		cta_contrato = incta_contrato,
		cta_gat = ISNULL((select gat_id from tipos_garantias where gat_nombre_corto = incta_gat and gat_baja_fecha is null),0), 
		cta_gta_numero = incta_gta_numero,
		cta_gta_mon = ISNULL((select mon_id from monedas where mon_cod = incta_gta_mon and mon_baja_fecha is null),0), 
		cta_gta_monto = case when incta_gta_monto <> '' then CONVERT(NUMERIC(16,2),isnull(incta_gta_monto,0))/100 else 0 end,		cta_centro = incta_centro,
		cta_linea = incta_linea,
		cta_tna = CONVERT(NUMERIC(12,4),incta_tna)/10000,
		cta_tpa = ISNULL((select tpa_id from tipos_paquetes where tpa_nombre_corto = incta_tpa and tpa_baja_fecha is null),0), 
		cta_paq_nro = CONVERT(INT,incta_paq_nro),
		cta_paq_pes = ISNULL((select pes_id from tipos_estados_paquetes where pes_nombre_corto = incta_paq_pes and pes_baja_fecha is null),0), 
		cta_paq_precierre_deuda = case when incta_paq_precierre_deuda <> '' then CONVERT(NUMERIC(16,2),isnull(incta_paq_precierre_deuda,0))/100 else 0 end,
		cta_paq_precierre_fecha = (CASE ISDATE(incta_paq_precierre_fecha) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,incta_paq_precierre_fecha) END),
		cta_cat = ISNULL((select cat_id from carteras where cat_nombre_corto = incta_cat and cat_baja_fecha is null),0),
		cta_p_modi_fecha = @v_fec_proceso,
		cta_baja_fecha=null
	FROM in_cuentas, wf_in_alta_aut 
	WHERE
		(incta_error IS NULL OR RTRIM(incta_error)='') AND
		cta_id = alt_id AND alt_clave = incta_clave AND alt_tabla='cta'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																	
	--ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_cuentas_aux

	INSERT in_cuentas_aux
		(cta_id,cta_per,cta_pro,cta_cla,cta_num_oper,cta_cli,cta_suc,cta_mon,cta_cnl,cta_cam,
		cta_bnc,cta_ent,cta_civ,cta_fec_origen,cta_fec_vto,cta_fec_ing,cta_monto_origen,cta_monto_transf,
		cta_deuda_venc,cta_deuda_a_venc,cta_det_mov,cta_fec_cla,cta_age,cta_age_fec_ini,cta_age_fec_fin,		cta_age_respons,cta_tco,cta_res_com,cta_contrato,cta_fec_ult_acc,cta_gat,cta_gta_numero,
		cta_gta_mon,cta_gta_monto,cta_gta_obs,cta_centro,cta_linea,cta_tna,cta_lockeo_usu,
		cta_lockeo_fec_hora,cta_lockeo_id_session,cta_cant_ing_mora,cta_fec_est_inac,cta_caj,
		cta_tpa,cta_paq_nro,cta_paq_pes,cta_paq_precierre_deuda,cta_paq_precierre_fecha,cta_obs,
		cta_alta_fecha,cta_modi_fecha,cta_baja_fecha,cta_p_alta_fecha,cta_p_modi_fecha,cta_usu_id,cta_filler,cta_clave,
		cta_cat)
	SELECT 
		0, --cta_id
		(select alt_id from wf_in_alta_aut where alt_tabla='per' and alt_clave=incta_per_clave), --cta_per
		ISNULL((select pro_id from productos where pro_nombre_corto = incta_pro and pro_baja_fecha is null),0), --cta_pro,
		ISNULL((select cla_id from clasificaciones where cla_nombre_corto = incta_cla and cla_baja_fecha is null),0), --cta_cla,
		incta_num_oper, --cta_num_oper
		incta_cli, --cta_cli
		ISNULL((select suc_id from sucursales, entidades where suc_ent = ent_id and ent_nombre_corto = incta_ent and suc_nombre_corto = incta_suc and suc_baja_fecha is null),0), --cta_suc
		ISNULL((select mon_id from monedas where mon_cod = incta_mon and mon_baja_fecha is null),0), --cta_mon
		ISNULL((select cnl_id from canales, entidades where cnl_ent = ent_id and cnl_nombre_corto = incta_cnl AND RTRIM(ent_nombre_corto) = RTRIM(incta_ent) and cnl_baja_fecha is null),0), --cta_cnl
		ISNULL((select cam_id from camp_comer, entidades where cam_ent = ent_id AND cam_nombre_corto = incta_cam AND RTRIM(ent_nombre_corto) = RTRIM(incta_ent) and cam_baja_fecha is null),0), --cta_cam
		ISNULL((select bnc_id from banca where bnc_nombre_corto = incta_bnc and bnc_baja_fecha is null),0), --cta_bnc
		ISNULL((select ent_id from entidades where ent_nombre_corto = incta_ent and ent_baja_fecha is null),0), --cta_ent
		(CASE 	WHEN (LTRIM(RTRIM(incta_civ)) <> '') 
			THEN (ISNULL((select civ_id from cond_iva where civ_nombre_corto = incta_civ and civ_baja_fecha is null),0))
			ELSE (select per_civ from personas,wf_in_alta_aut where alt_tabla='per' and alt_clave=incta_per_clave and per_id=alt_id) END), --cta_civ
		(CASE ISDATE(incta_fec_origen) 
			WHEN 0 THEN NULL
			ELSE CONVERT(DATETIME,incta_fec_origen)
		END), --cta_fec_origen
		(CASE ISDATE(incta_fec_vto) 
			WHEN 0 THEN NULL
			ELSE CONVERT(DATETIME,incta_fec_vto)
		END), --cta_fec_vto
		(CASE ISDATE(incta_fec_ing) 
			WHEN 0 THEN CONVERT(DATETIME,'19000101') ELSE CONVERT(DATETIME,incta_fec_ing)
		END), --cta_fec_ing
		CONVERT(NUMERIC(16,2),incta_monto_origen)/100, --cta_monto_origen
		CONVERT(NUMERIC(16,2),incta_monto_transf)/100, --cta_monto_transf
		CONVERT(NUMERIC(16,2),incta_deuda_venc)/100, --cta_deuda_venc
		CONVERT(NUMERIC(16,2),incta_deuda_a_venc)/100, --cta_deuda_a_venc
		ISNULL(incta_det_mov,'N'),--cta_det_mov
		(CASE 	WHEN(LTRIM(RTRIM(incta_fec_cla)) <> '99991231') 
			THEN CONVERT(DATETIME,incta_fec_cla)
			ELSE (select per_fec_slg from personas,wf_in_alta_aut where alt_tabla='per' and alt_clave=incta_per_clave and per_id=alt_id) END), --cta_fec_cla
		ISNULL((select age_id from agencias where age_cod = incta_age and age_baja_fecha is null),0), --cta_age
		(CASE ISDATE(incta_age_fec_ini) 
			WHEN 0 THEN NULL ELSE CONVERT(DATETIME,incta_age_fec_ini)
		END), --cta_age_fec_ini
		(CASE ISDATE(incta_age_fec_fin) 
			WHEN 0 THEN NULL
			ELSE CONVERT(DATETIME,incta_age_fec_fin)
		END), --cta_age_fec_fin
		incta_age_respons, --cta_age_respons
		ISNULL((select tco_id from tipos_contratos where tco_nombre_corto = incta_tco and tco_baja_fecha is null),0), --cta_tco
		incta_res_com, --cta_res_com
		incta_contrato, --cta_contrato
		NULL, --cta_fec_ult_acc
		ISNULL((select gat_id from tipos_garantias where gat_nombre_corto = incta_gat and gat_baja_fecha is null),0), --cta_gat
		incta_gta_numero, --cta_gta_numero
		ISNULL((select mon_id from monedas where mon_cod = incta_gta_mon and mon_baja_fecha is null),0), --cta_gta_mon
		case when incta_gta_monto <> '' then CONVERT(NUMERIC(16,2),isnull(incta_gta_monto,0))/100 else 0 end,		incta_gta_obs, --cta_gta_obs
		incta_centro, --cta_centro
		incta_linea, --cta_linea
		CONVERT(NUMERIC(12,4),incta_tna)/10000, --cta_tna
		0, --cta_lockeo_usu
		NULL, --cta_lockeo_fec_hora
		NULL, --cta_lockeo_id_session
		0, --cta_cant_ing_mora
		NULL, --cta_fec_est_inac
		ISNULL((select caj_id from criterios_ajuste where caj_nombre_corto = incta_caj and caj_baja_fecha is null),0), --cta_caj
		ISNULL((select tpa_id from tipos_paquetes where tpa_nombre_corto = incta_tpa and tpa_baja_fecha is null),0), --cta_tpa
		CONVERT(INT,incta_paq_nro), --cta_paq_nro
		ISNULL((select pes_id from tipos_estados_paquetes where pes_nombre_corto = incta_paq_pes and pes_baja_fecha is null),0), --cta_paq_pes
		case when incta_paq_precierre_deuda <> '' then CONVERT(NUMERIC(16,2),isnull(incta_paq_precierre_deuda,0))/100 else 0 end,


		(CASE ISDATE(incta_paq_precierre_fecha) 
			WHEN 0 THEN NULL
			ELSE CONVERT(DATETIME,incta_paq_precierre_fecha)
		END), --cta_paq_precierre_fecha
		incta_obs, --cta_obs
		GETDATE(), --cta_alta_fecha
		NULL, --cta_modi_fecha
		NULL ,--cta_baja_fecha
		@v_fec_proceso, --cta_p_alta_fecha
		NULL, --cta_p_modi_fecha
		@v_usu_id, --cta_usu_id
		incta_filler, --cta_filler
		incta_clave, --cta_clave
		ISNULL((select cat_id from carteras where cat_nombre_corto = incta_cat and cat_baja_fecha is null),0) --cta_cat
	FROM
		in_cuentas
	WHERE
		(incta_error IS NULL OR RTRIM(incta_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='cta' AND alt_clave=incta_clave)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																	
	SELECT @Puntero = ISNULL(MAX(cta_id),0) FROM cuentas
	UPDATE in_cuentas_aux SET cta_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																			
	INSERT cuentas
	SELECT
		cta_id,cta_per,cta_pro,cta_cla,cta_num_oper,cta_cli,cta_suc,cta_mon,cta_cnl,cta_cam,
		cta_bnc,cta_ent,cta_civ,cta_fec_origen,cta_fec_vto,cta_fec_ing,cta_monto_origen,
		cta_monto_transf,cta_deuda_venc,cta_deuda_a_venc,cta_det_mov,cta_fec_cla,cta_age,cta_age_fec_ini,
		cta_age_fec_fin,cta_age_respons,cta_tco,cta_res_com,cta_contrato,cta_fec_ult_acc,
		cta_gat,cta_gta_numero,cta_gta_mon,cta_gta_monto,cta_gta_obs,cta_centro,cta_linea,
		cta_tna,cta_lockeo_usu,cta_lockeo_fec_hora,cta_lockeo_id_session,cta_cant_ing_mora,
		cta_fec_est_inac,cta_caj,cta_tpa,cta_paq_nro,cta_paq_pes,cta_paq_precierre_deuda,
		cta_paq_precierre_fecha,cta_obs,cta_alta_fecha,cta_modi_fecha,cta_baja_fecha,cta_p_alta_fecha,cta_p_modi_fecha,
		cta_usu_id,cta_filler,cta_cat
	FROM in_cuentas_aux	
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																			
	INSERT wf_sit_objetos
	SELECT
		cta_id,
		0, 
		0, 
		0, 
		@v_fec_proceso,
		@v_fec_proceso,
		@v_fec_proceso,
		NULL,
		0,
		0,
		NULL,
		GETDATE(),
		NULL,
		NULL,
		@v_usu_id,
		'' 
	FROM in_cuentas_aux
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																			
	SELECT @#Enviados = count(*) FROM in_cuentas
	SELECT @#Rechazados = count(*) FROM in_cuentas where incta_error IS NOT NULL AND RTRIM(incta_error) <> '' 
	SELECT @#Ingresados = count(*) FROM in_cuentas_aux 
	SELECT @#Actualizados =  count(*) from in_cuentas  join wf_in_alta_aut on alt_clave = incta_clave and alt_tabla = 'cta' where incta_error IS NULL OR RTRIM(incta_error)=''
	----------------------------------------------------------------------																				
	INSERT wf_in_alta_aut 
	SELECT 'cta',cta_clave,cta_id
	FROM in_cuentas_aux
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																	
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN CUENTAS
		END
	ELSE
		BEGIN
		ROLLBACK TRAN CUENTAS

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END
	----------------------------------------------------------------------																		
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END



-------------------------------------------------------------------------------------------------------------------------
--TABLA MOVIMIENTOS
-------------------------------------------------------------------------------------------------------------------------
IF (@v_regmov IS NOT NULL) AND @v_regmov > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Movimientos', @v_usu_id_in, Null, @v_cat_id
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	----------------------------------------------------------------------																				
	UPDATE in_movimientos SET inmov_error='T', inmov_error_campo='inmov_cta_clave' WHERE 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='cta' and alt_clave = inmov_cta_clave)	
	----------------------------------------------------------------------																			
	SET @error_tran = 0
	BEGIN TRAN MOVIMIENTOS
	----------------------------------------------------------------------																			 
	-- ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_movimientos_aux
	
	INSERT in_movimientos_aux( mov_id, mov_cta, mov_mon, mov_mon_origen, mov_com, mov_fec_carga, mov_fec_contab, mov_fec_oper, mov_fec_vto, 
			mov_cos, mov_scn, mov_grupo, mov_importe, mov_importe_origen, mov_signo, mov_num, mov_comentario, mov_importe_ajc, mov_importe_int, 
			mov_importe_imp, mov_importe_gastos, mov_usu_res, mov_coh, mov_comprobante, mov_alta_fecha, mov_modi_fecha, mov_baja_fecha, 
			mov_p_alta_fecha, mov_p_modi_fecha, mov_usu_id, mov_filler, mov_clave)
	SELECT 
		0, --mov_id
		(select alt_id from wf_in_alta_aut where alt_tabla='cta' and alt_clave=inmov_cta_clave), --mov_cta
		ISNULL((select mon_id from monedas where mon_cod = inmov_mon and mon_baja_fecha is null),0), --mov_mon
		ISNULL((select mon_id from monedas where mon_cod = inmov_mon_origen and mon_baja_fecha is null),0), --mov_mon_origen
		ISNULL((select com_id from componentes where com_nombre_corto = inmov_com and com_baja_fecha is null),0), --mov_com
		CONVERT(datetime,inmov_fec_carga), --mov_fec_carga
		CONVERT(datetime,inmov_fec_contab), --mov_fec_contab
		CONVERT(datetime,inmov_fec_oper), --mov_fec_oper
		CONVERT(datetime,inmov_fec_vto), --mov_fec_vto
		ISNULL((select cos_id from conceptos where cos_nombre_corto = inmov_cos and cos_baja_fecha is null),0), --mov_cos
		ISNULL((SELECT scn_id FROM sub_conceptos, conceptos WHERE scn_cos = cos_id AND scn_nombre_corto = inmov_scn AND cos_nombre_corto = inmov_cos AND scn_baja_fecha IS NULL),0), --mov_scn
		0, --mov_grupo
		ISNULL(CONVERT(NUMERIC(16,2),inmov_importe)/100,0), --mov_importe
		0,--ISNULL(CONVERT(NUMERIC(16,2),inmov_importe_origen)/100,0), --mov_importe_origen
		inmov_signo, --mov_signo
		0, --mov_num
		inmov_comentario, --mov_comentario
		ISNULL(CONVERT(NUMERIC(16,2),inmov_importe_ajc)/100,0), --mov_importe_ajc
		ISNULL(CONVERT(NUMERIC(16,2),inmov_importe_int)/100,0), --mov_importe_int
		ISNULL(CONVERT(NUMERIC(16,2),inmov_importe_imp)/100,0), --mov_importe_imp
		ISNULL(CONVERT(NUMERIC(16,2),inmov_importe_gastos)/100,0), --mov_importe_gastos
		0, --mov_usu_res
		0, --mov_coh
		inmov_comprobante, 	
		GETDATE(), --mov_alta_fecha
		NULL, --mov_modi_fecha
	
		NULL, --mov_baja_fecha
		@v_fec_proceso, --mov_p_alta_fecha
		NULL, --mov_p_modi_fecha
		@v_usu_id, --mov_usu_id
		inmov_filler, --mov_filler
		inmov_clave --mov_clave
	FROM
		in_movimientos
	WHERE
		(inmov_error IS NULL OR RTRIM(inmov_error)='') 	

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 
	SELECT @Puntero = ISNULL(MAX(mov_id),0) FROM movimientos
	UPDATE in_movimientos_aux SET mov_id=@Puntero, @Puntero=@Puntero+1 
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 	
	INSERT movimientos
	
	SELECT
		mov_id, mov_cta, mov_mon, mov_mon_origen, mov_com, mov_fec_carga, mov_fec_contab, mov_fec_oper, mov_fec_vto, mov_cos,
		mov_scn, mov_grupo, mov_importe, mov_importe_origen, mov_signo, mov_num, mov_comentario, mov_importe_ajc, mov_importe_int, mov_importe_imp, mov_importe_gastos, 
		mov_usu_res, mov_coh, mov_comprobante, mov_alta_fecha, mov_modi_fecha, mov_baja_fecha, mov_p_alta_fecha, mov_p_modi_fecha, mov_usu_id, mov_filler 

	FROM in_movimientos_aux
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 		
	SELECT @#Enviados = count(*) FROM in_movimientos
	SELECT @#Rechazados = count(*) FROM in_movimientos where inmov_error IS NOT NULL AND RTRIM(inmov_error) <> '' AND RTRIM(inmov_error) <> 'C' 
	SELECT @#Descartados = count(*) FROM in_movimientos where inmov_error IS NOT NULL AND RTRIM(inmov_error) <> '' AND RTRIM(inmov_error) = 'C'
	SELECT @#Ingresados = count(*) FROM in_movimientos_aux 
	SELECT @#Actualizados =  count(*) from in_movimientos join wf_in_alta_aut on alt_clave = inmov_clave and alt_tabla = 'mov' WHERE inmov_error IS NULL OR RTRIM(inmov_error)='' 
	----------------------------------------------------------------------																					 			
	INSERT wf_in_alta_aut 
	SELECT 'mov',mov_clave,mov_id
	FROM in_movimientos_aux
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 		
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN MOVIMIENTOS
		END
	ELSE
		BEGIN
		ROLLBACK TRAN MOVIMIENTOS

		SET @#Rechazados = @#Enviados
		SET @#Descartados = 0
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END
	----------------------------------------------------------------------																					 			
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Movimientos - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Movimientos - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Movimientos - Descartados.: ' + CONVERT(VARCHAR(8),@#Descartados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Movimientos - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Movimientos - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
	
END

-------------------------------------------------------------------------------------------------------------------------
--TABLA MOVIMIENTOS VINCULADOS
-------------------------------------------------------------------------------------------------------------------------
IF (@v_regmvv IS NOT NULL) AND @v_regmvv > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Mov_x_mov', @v_usu_id_in, Null, @v_cat_id
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
		
	--- CUIDADO!! Si en un proceso aparecen 2 vinculaciones iguales van a entrar las 2!!!
	----------------------------------------------------------------------																					 			
	UPDATE in_mov_x_mov SET inmvv_error='T', inmvv_error_campo='inmvv_mov_clave' WHERE 
	(inmvv_error IS NULL OR RTRIM(inmvv_error)='') AND 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='mov' and alt_clave = inmvv_mov_clave)

	UPDATE in_mov_x_mov SET inmvv_error='T', inmvv_error_campo='inmvv_mov_clave_vinc' WHERE 
	(inmvv_error IS NULL OR RTRIM(inmvv_error)='') AND 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='mov' and alt_clave = inmvv_mov_clave_vinc)
	----------------------------------------------------------------------																					 			
	SET @error_tran = 0
	BEGIN TRAN VINCULADOS
	----------------------------------------------------------------------																					 			
	-- ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_mov_x_mov_aux

	INSERT in_mov_x_mov_aux( mvv_id, mvv_mov, mvv_mov_vinc, mvv_alta_fecha, mvv_modi_fecha, mvv_baja_fecha, mvv_p_alta_fecha, mvv_p_modi_fecha, mvv_usu_id, mvv_filler)
	SELECT 
		0, --mvv_id
		(select alt_id from wf_in_alta_aut where alt_tabla='mov' and alt_clave=inmvv_mov_clave), --mvv_mov
		(select alt_id from wf_in_alta_aut where alt_tabla='mov' and alt_clave=inmvv_mov_clave_vinc), --mvv_mov_vinc
		GETDATE(), --mvv_alta_fecha
		NULL, --mvv_modi_fecha
		NULL, --mvv_baja_fecha
		@v_fec_proceso, --mvv_p_alta_fecha
		NULL, --mvv_p_modi_fecha
		@v_usu_id, --mvv_usu_id
		inmvv_filler --mvv_filler
	FROM
		in_mov_x_mov
	WHERE
		inmvv_vinc_desv = 'V' and 
		(inmvv_error IS NULL OR RTRIM(inmvv_error)='') 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 		
	SELECT @Puntero = ISNULL(MAX(mvv_id),0) FROM mov_x_mov
	UPDATE in_mov_x_mov_aux SET mvv_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 			
	INSERT mov_x_mov

	SELECT
		mvv_id, mvv_mov, mvv_mov_vinc, mvv_alta_fecha, mvv_modi_fecha, mvv_baja_fecha, 
		mvv_p_alta_fecha, mvv_p_modi_fecha, mvv_usu_id, mvv_filler
	FROM in_mov_x_mov_aux
	
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 		

	-- UPDATES: Desvinculaciones
	-- Validamos que no haya una desvinculacion que no existe
	UPDATE in_mov_x_mov SET inmvv_error='C', inmvv_error_campo='inmvv_desvinculacion' WHERE 
	(inmvv_error IS NULL OR RTRIM(inmvv_error)='') and 
	inmvv_vinc_desv='D' and 
	NOT EXISTS (select 1 from mov_x_mov where mvv_baja_fecha is null AND 
	mvv_mov = (select alt_id from wf_in_alta_aut where alt_tabla='mov' and alt_clave=inmvv_mov_clave) and
	mvv_mov_vinc = (select alt_id from wf_in_alta_aut where alt_tabla='mov' and alt_clave=inmvv_mov_clave_vinc)) 
	and NOT EXISTS (select 1 from mov_x_mov where mvv_baja_fecha is null AND 
	mvv_mov_vinc = (select alt_id from wf_in_alta_aut where alt_tabla='mov' and alt_clave=inmvv_mov_clave) and
	mvv_mov = (select alt_id from wf_in_alta_aut where alt_tabla='mov' and alt_clave=inmvv_mov_clave_vinc)) 
/* antes:
NOT EXISTS (select 1 from mov_x_mov, wf_in_alta_aut MOV, wf_in_alta_aut VINC where mvv_baja_fecha is null AND mvv_mov=MOV.alt_id and mvv_mov_vinc=VINC.alt_id AND MOV.alt_tabla='mov' AND VINC.alt_tabla='mov' AND MOV.alt_clave=inmvv_mov_clave and VINC.alt_clave=inmvv_mov_clave_vinc)
and NOT EXISTS (select 1 from mov_x_mov, wf_in_alta_aut MOV, wf_in_alta_aut VINC where mvv_baja_fecha is null AND mvv_mov_vinc=MOV.alt_id and mvv_mov=VINC.alt_id AND MOV.alt_tabla='mov' AND VINC.alt_tabla='mov' AND MOV.alt_clave=inmvv_mov_clave and VINC.alt_clave=inmvv_mov_clave_vinc)
*/
	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 		
	UPDATE mov_x_mov 
	SET
		mvv_baja_fecha = @v_fec_proceso,
		mvv_p_modi_fecha = @v_fec_proceso
	FROM in_mov_x_mov 
	WHERE
		inmvv_vinc_desv = 'D' and 
		(inmvv_error IS NULL OR RTRIM(inmvv_error)='') AND
		mvv_mov = (select alt_id from wf_in_alta_aut where alt_tabla='mov' and alt_clave=inmvv_mov_clave) and 
		mvv_mov_vinc = (select alt_id from wf_in_alta_aut where alt_tabla='mov' and alt_clave=inmvv_mov_clave_vinc) AND
		mvv_baja_fecha IS NULL
/* antes:	mvv_mov=MOV.alt_id and 
		MOV.alt_tabla='mov' AND 
		MOV.alt_clave=inmvv_mov_clave and 
		mvv_mov_vinc=VINC.alt_id AND 
		VINC.alt_tabla='mov' AND 
		VINC.alt_clave=inmvv_mov_clave_vinc
*/

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 		
	UPDATE mov_x_mov 
	SET
		mvv_baja_fecha = @v_fec_proceso,
		mvv_p_modi_fecha = @v_fec_proceso 
	FROM in_mov_x_mov, wf_in_alta_aut MOV, wf_in_alta_aut VINC 
	WHERE
		inmvv_vinc_desv = 'D' and 
		(inmvv_error IS NULL OR RTRIM(inmvv_error)='') AND
		mvv_mov_vinc = (select alt_id from wf_in_alta_aut where alt_tabla='mov' and alt_clave=inmvv_mov_clave) and 
		mvv_mov = (select alt_id from wf_in_alta_aut where alt_tabla='mov' and alt_clave=inmvv_mov_clave_vinc)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 			
	SELECT @#Enviados = count(*) FROM in_mov_x_mov
	SELECT @#Rechazados = count(*) FROM in_mov_x_mov where inmvv_error IS NOT NULL AND RTRIM(inmvv_error) <> '' AND RTRIM(inmvv_error) <> 'C' 
	SELECT @#Descartados = count(*) FROM in_mov_x_mov where inmvv_error IS NOT NULL AND RTRIM(inmvv_error) <> '' AND RTRIM(inmvv_error) = 'C'
	SELECT @#Ingresados = count(*) FROM in_mov_x_mov_aux 
	SELECT @#Actualizados =  count(*) from in_mov_x_mov where inmvv_vinc_desv = 'D' and (inmvv_error IS NULL OR RTRIM(inmvv_error)='')
	
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN VINCULADOS
		END
	ELSE
		BEGIN
		ROLLBACK TRAN VINCULADOS

		SET @#Rechazados = @#Enviados
		SET @#Descartados = 0
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END
	----------------------------------------------------------------------																					 			
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Mov_x_mov - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Mov_x_mov - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Mov_x_mov - Descartados.: ' + CONVERT(VARCHAR(8),@#Descartados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Mov_x_mov - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Mov_x_mov - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
	
END

-------------------------------------------------------------------------------------------------------------------------
--TABLA WF_SOB_ATRIBUTOS
-------------------------------------------------------------------------------------------------------------------------
IF (@v_regsot IS NOT NULL) AND @v_regsot > 0
BEGIN

	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Atributos Objetos', @v_usu_id_in, Null, @v_cat_id	
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------																					 				
	UPDATE in_wf_sob_atributos SET insot_error='T', insot_error_campo='insot_clave' WHERE 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='cta' and alt_clave = insot_clave)	
	----------------------------------------------------------------------																					 				
	SET @error_tran = 0
	BEGIN TRAN WF_SOB_ATRIBUTOS
	----------------------------------------------------------------------																					 			
	--MODIFICACION DE REGISTROS
	UPDATE wf_sob_atributos
	SET	
		sot_atr	= ISNULL((select atr_id from wf_atributos, carteras where atr_cat = cat_id and cat_nombre_corto = insot_cat and atr_nombre_corto = insot_atr and cat_baja_fecha is null and atr_baja_fecha is null),0),
		sot_fecha1 = (CASE ISDATE(insot_fecha1) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha1) END),
		sot_fecha2 = (CASE ISDATE(insot_fecha2) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha2) END),
		sot_fecha3 = (CASE ISDATE(insot_fecha3) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha3) END),
		sot_fecha4 = (CASE ISDATE(insot_fecha4) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha4) END),
		sot_fecha5 = (CASE ISDATE(insot_fecha5) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha5) END),
		sot_fecha6 = (CASE ISDATE(insot_fecha6) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha6) END),
		sot_fecha7 = (CASE ISDATE(insot_fecha7) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha7) END),
		sot_fecha8 = (CASE ISDATE(insot_fecha8) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha8) END),
		sot_fecha9 = (CASE ISDATE(insot_fecha9) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha9) END),
		sot_fecha10 = (CASE ISDATE(insot_fecha10) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha10) END),
		sot_texto1 = insot_texto1,
		sot_texto2 = insot_texto2,
		sot_texto3 = insot_texto3,
		sot_texto4 = insot_texto4,
		sot_texto5 = insot_texto5,
		sot_texto6 = insot_texto6,
		sot_texto7 = insot_texto7,
		sot_texto8 = insot_texto8,
		sot_texto9 = insot_texto9,
		sot_texto10 = insot_texto10,
		sot_numero1 = (CASE WHEN RTRIM(LTRIM(insot_numero1)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero1/100) END) ,
		sot_numero2 = (CASE WHEN RTRIM(LTRIM(insot_numero2)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero2/100) END) ,
		sot_numero3 = (CASE WHEN RTRIM(LTRIM(insot_numero3)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero3/100) END) ,
		sot_numero4 = (CASE WHEN RTRIM(LTRIM(insot_numero4)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero4/100) END) ,
		sot_numero5 = (CASE WHEN RTRIM(LTRIM(insot_numero5)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero5/100) END) ,
		sot_numero6 = (CASE WHEN RTRIM(LTRIM(insot_numero6)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero6/100) END) ,
		sot_numero7 = (CASE WHEN RTRIM(LTRIM(insot_numero7)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero7/100) END) ,
		sot_numero8 = (CASE WHEN RTRIM(LTRIM(insot_numero8)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero8/100) END) ,
		sot_numero9 = (CASE WHEN RTRIM(LTRIM(insot_numero9)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero9/100) END) ,
		sot_numero10 = (CASE WHEN RTRIM(LTRIM(insot_numero10)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero10/100) END) ,
		sot_coeficiente1 = (CASE WHEN RTRIM(LTRIM(insot_coeficiente1)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente1/10000) END) ,
		sot_coeficiente2 = (CASE WHEN RTRIM(LTRIM(insot_coeficiente2)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente2/10000) END) ,
		sot_coeficiente3 = (CASE WHEN RTRIM(LTRIM(insot_coeficiente3)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente3/10000) END) ,
		sot_coeficiente4 = (CASE WHEN RTRIM(LTRIM(insot_coeficiente4)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente4/10000) END) ,
		sot_coeficiente5 = (CASE WHEN RTRIM(LTRIM(insot_coeficiente5)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente5/10000) END) ,
		sot_coeficiente6 = (CASE WHEN RTRIM(LTRIM(insot_coeficiente6)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente6/10000) END) ,
		sot_coeficiente7 = (CASE WHEN RTRIM(LTRIM(insot_coeficiente7)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente7/10000) END) ,
		sot_coeficiente8 = (CASE WHEN RTRIM(LTRIM(insot_coeficiente8)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente8/10000) END) ,
		sot_coeficiente9 = (CASE WHEN RTRIM(LTRIM(insot_coeficiente9)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente9/10000) END) ,
		sot_coeficiente10 = (CASE WHEN RTRIM(LTRIM(insot_coeficiente10)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente10/10000) END) ,
		sot_obs = ISNULL(insot_obs,''),
		sot_p_modi_fecha = @v_fec_proceso,
		sot_usu_id = @v_usu_id,
		sot_filler = ISNULL(insot_filler,'')
	FROM in_wf_sob_atributos , wf_in_alta_aut, wf_sob_atributos
	WHERE
		(insot_error IS NULL OR RTRIM(insot_error)='') AND		
		sot_id = alt_id AND 
		alt_id = sot_id AND 
		alt_clave = insot_clave AND 
		alt_tabla='cta'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 		
	--ALTA REGISTROS NUEVOS	
	TRUNCATE TABLE in_wf_sob_atributos_aux
	
	INSERT in_wf_sob_atributos_aux
		(sot_id, sot_atr,
		sot_fecha1, sot_fecha2, sot_fecha3, sot_fecha4, sot_fecha5, sot_fecha6, sot_fecha7, sot_fecha8, sot_fecha9, sot_fecha10,
		sot_texto1, sot_texto2, sot_texto3, sot_texto4, sot_texto5, sot_texto6, sot_texto7, sot_texto8, sot_texto9, sot_texto10,
		sot_numero1, sot_numero2, sot_numero3, sot_numero4, sot_numero5, sot_numero6, sot_numero7, sot_numero8, sot_numero9, sot_numero10,
		sot_coeficiente1, sot_coeficiente2, sot_coeficiente3, sot_coeficiente4, sot_coeficiente5, sot_coeficiente6, sot_coeficiente7, sot_coeficiente8, sot_coeficiente9, sot_coeficiente10,
		sot_obs, sot_usu_id, sot_alta_fecha, sot_filler, sot_clave, sot_p_alta_fecha, sot_p_modi_fecha)

	SELECT	0,
		ISNULL((select atr_id from wf_atributos inner join carteras on atr_cat = cat_id 
		where cat_nombre_corto = insot_cat and atr_nombre_corto = insot_atr 
		and cat_baja_fecha is null and atr_baja_fecha is null),0),
		(CASE ISDATE(insot_fecha1) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha1) END),
		(CASE ISDATE(insot_fecha2) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha2) END),
		(CASE ISDATE(insot_fecha3) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha3) END),
		(CASE ISDATE(insot_fecha4) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha4) END),
		(CASE ISDATE(insot_fecha5) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha5) END),
		(CASE ISDATE(insot_fecha6) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha6) END),
		(CASE ISDATE(insot_fecha7) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha7) END),

		(CASE ISDATE(insot_fecha8) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha8) END),
		(CASE ISDATE(insot_fecha9) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha9) END),
		(CASE ISDATE(insot_fecha10) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,insot_fecha10) END),
		insot_texto1,
		insot_texto2,
		insot_texto3,
		insot_texto4,
		insot_texto5,
		insot_texto6,
		insot_texto7,
		insot_texto8,
		insot_texto9,
		insot_texto10,
		(CASE WHEN RTRIM(LTRIM(insot_numero1)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero1/100) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_numero2)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero2/100) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_numero3)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero3/100) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_numero4)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero4/100) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_numero5)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero5/100) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_numero6)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero6/100) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_numero7)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero7/100) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_numero8)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero8/100) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_numero9)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero9/100) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_numero10)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2),insot_numero10/100) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_coeficiente1)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente1/10000) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_coeficiente2)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente2/10000) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_coeficiente3)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente3/10000) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_coeficiente4)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente4/10000) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_coeficiente5)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente5/10000) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_coeficiente6)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente6/10000) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_coeficiente7)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente7/10000) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_coeficiente8)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente8/10000) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_coeficiente9)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente9/10000) END) ,
		(CASE WHEN RTRIM(LTRIM(insot_coeficiente10)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4),insot_coeficiente10/10000) END) ,
		ISNULL(insot_obs,''),
		@v_usu_id_in,
		GETDATE(), 
		ISNULL(insot_filler,''),
		insot_clave,
		@v_fec_proceso, 
		NULL

	FROM
		in_wf_sob_atributos
	WHERE
		(insot_error IS NULL OR RTRIM(insot_error)='') AND
		 NOT EXISTS (	SELECT alt_id 
				FROM wf_in_alta_aut 
					INNER JOIN wf_sob_atributos on alt_id = sot_id
				WHERE 	alt_tabla='cta' AND 
					alt_clave=insot_clave)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 		
	UPDATE in_wf_sob_atributos_aux SET sot_id = alt_id
	FROM in_wf_sob_atributos_aux
		INNER JOIN wf_in_alta_aut on alt_clave = sot_clave AND alt_tabla = 'cta'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 		
	INSERT INTO wf_sob_atributos
	SELECT	sot_id, sot_atr, 
		sot_fecha1, sot_fecha2, sot_fecha3, sot_fecha4, sot_fecha5, sot_fecha6, sot_fecha7, sot_fecha8, sot_fecha9, sot_fecha10,
		sot_texto1, sot_texto2, sot_texto3, sot_texto4, sot_texto5, sot_texto6, sot_texto7, sot_texto8, sot_texto9, sot_texto10,
		sot_numero1, sot_numero2, sot_numero3, sot_numero4, sot_numero5, sot_numero6, sot_numero7, sot_numero8, sot_numero9, sot_numero10, 
		sot_coeficiente1, sot_coeficiente2, sot_coeficiente3, sot_coeficiente4, sot_coeficiente5, sot_coeficiente6, sot_coeficiente7, sot_coeficiente8, sot_coeficiente9, sot_coeficiente10,
		sot_obs, sot_alta_fecha, sot_modi_fecha, sot_baja_fecha, sot_p_alta_fecha, sot_p_modi_fecha, sot_usu_id, sot_filler
	FROM in_wf_sob_atributos_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 			
	SELECT @#Enviados = count(*) FROM in_wf_sob_atributos
	SELECT @#Rechazados = count(*) FROM in_wf_sob_atributos WHERE insot_error IS NOT NULL AND LTRIM(insot_error) <> '' 
	SELECT @#Ingresados = count(*) FROM in_wf_sob_atributos_aux 
	SELECT @#Actualizados =  count(*) FROM in_wf_sob_atributos  
			inner join wf_in_alta_aut on alt_clave = insot_clave and alt_tabla = 'cta' 
			where not exists(select 1 from in_wf_sob_atributos_aux where sot_clave = insot_clave) and
			(insot_error IS NULL OR LTRIM(insot_error)='')

	IF @error_tran = 0
		BEGIN
		COMMIT TRAN WF_SOB_ATRIBUTOS
		END
	ELSE
		BEGIN
		ROLLBACK TRAN WF_SOB_ATRIBUTOS

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END
	----------------------------------------------------------------------																					 			
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Atributos Objectos - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Atributos Objectos - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Atributos Objectos - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Atributos Objectos - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END

-------------------------------------------------------------------------------------------------------------------------
--TABLA PER_ATRIBUTOS
-------------------------------------------------------------------------------------------------------------------------
IF (@v_regpea IS NOT NULL) AND @v_regpea > 0
BEGIN

	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Atributos Personas', @v_usu_id_in, Null, @v_cat_id	
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------																					 				
	UPDATE in_per_atributos SET inpea_error='T', inpea_error_campo='inpea_clave' WHERE 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='per' and alt_clave = inpea_clave)	
	----------------------------------------------------------------------																					 				
	SET @error_tran = 0
	BEGIN TRAN per_atributos
	----------------------------------------------------------------------																					 			
	--MODIFICACION DE REGISTROS
	UPDATE per_atributos
	SET	
		pea_atr	= ISNULL((select atr_id from wf_atributos, carteras where cat_id = atr_cat and cat_nombre_corto = inpea_cat and atr_nombre_corto = inpea_atr and cat_baja_fecha is null and atr_baja_fecha is null),0),				
		pea_fecha1 = (CASE ISDATE(inpea_fecha1) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha1) END),
		pea_fecha2 = (CASE ISDATE(inpea_fecha2) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha2) END),
		pea_fecha3 = (CASE ISDATE(inpea_fecha3) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha3) END),
		pea_fecha4 = (CASE ISDATE(inpea_fecha4) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha4) END),
		pea_fecha5 = (CASE ISDATE(inpea_fecha5) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha5) END),
		pea_fecha6 = (CASE ISDATE(inpea_fecha6) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha6) END),
		pea_fecha7 = (CASE ISDATE(inpea_fecha7) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha7) END),
		pea_fecha8 = (CASE ISDATE(inpea_fecha8) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha8) END),
		pea_fecha9 = (CASE ISDATE(inpea_fecha9) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha9) END),
		pea_fecha10 = (CASE ISDATE(inpea_fecha10) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha10) END),
		pea_texto1 = inpea_texto1,
		pea_texto2 = inpea_texto2,
		pea_texto3 = inpea_texto3,
		pea_texto4 = inpea_texto4,
		pea_texto5 = inpea_texto5,
		pea_texto6 = inpea_texto6,
		pea_texto7 = inpea_texto7,
		pea_texto8 = inpea_texto8,
		pea_texto9 = inpea_texto9,
		pea_texto10 = inpea_texto10,
		pea_numero1 = (CASE WHEN RTRIM(LTRIM(inpea_numero1)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero1)/100 END) ,
		pea_numero2 = (CASE WHEN RTRIM(LTRIM(inpea_numero2)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero2)/100 END) ,
		pea_numero3 = (CASE WHEN RTRIM(LTRIM(inpea_numero3)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero3)/100 END) ,
		pea_numero4 = (CASE WHEN RTRIM(LTRIM(inpea_numero4)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero4)/100 END) ,
		pea_numero5 = (CASE WHEN RTRIM(LTRIM(inpea_numero5)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero5)/100 END) ,
		pea_numero6 = (CASE WHEN RTRIM(LTRIM(inpea_numero6)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero6)/100 END) ,
		pea_numero7 = (CASE WHEN RTRIM(LTRIM(inpea_numero7)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero7)/100 END) ,
		pea_numero8 = (CASE WHEN RTRIM(LTRIM(inpea_numero8)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero8)/100 END) ,
		pea_numero9 = (CASE WHEN RTRIM(LTRIM(inpea_numero9)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero9)/100 END) ,
		pea_numero10 = (CASE WHEN RTRIM(LTRIM(inpea_numero10)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero10/100) END) ,
		pea_coeficiente1 = (CASE WHEN RTRIM(LTRIM(inpea_coeficiente1)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente1/10000) END) ,
		pea_coeficiente2 = (CASE WHEN RTRIM(LTRIM(inpea_coeficiente2)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente2/10000)  END) ,
		pea_coeficiente3 = (CASE WHEN RTRIM(LTRIM(inpea_coeficiente3)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente3/10000)  END) ,
		pea_coeficiente4 = (CASE WHEN RTRIM(LTRIM(inpea_coeficiente4)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente4/10000)  END) ,
		pea_coeficiente5 = (CASE WHEN RTRIM(LTRIM(inpea_coeficiente5)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente5/10000)  END) ,
		pea_coeficiente6 = (CASE WHEN RTRIM(LTRIM(inpea_coeficiente6)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente6/10000)  END) ,
		pea_coeficiente7 = (CASE WHEN RTRIM(LTRIM(inpea_coeficiente7)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente7/10000)  END) ,
		pea_coeficiente8 = (CASE WHEN RTRIM(LTRIM(inpea_coeficiente8)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente8/10000)  END) ,
		pea_coeficiente9 = (CASE WHEN RTRIM(LTRIM(inpea_coeficiente9)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente9/10000)  END) ,
		pea_coeficiente10 = (CASE WHEN RTRIM(LTRIM(inpea_coeficiente10)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente10/10000)  END) ,
		pea_obs = ISNULL(inpea_obs,''),
		pea_p_modi_fecha = @v_fec_proceso,
		pea_usu_id = @v_usu_id,
		pea_filler = ISNULL(inpea_filler,'')
	FROM in_per_atributos , wf_in_alta_aut, per_atributos
	WHERE
		(inpea_error IS NULL OR RTRIM(inpea_error)='') AND		
		pea_id = alt_id AND 
		alt_id = pea_id AND 
		alt_clave = inpea_clave AND 
		alt_tabla='per'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 			
	--ALTA REGISTROS NUEVOS	
	TRUNCATE TABLE in_per_atributos_aux
	
	INSERT in_per_atributos_aux
		(pea_id, pea_atr,
		pea_fecha1, pea_fecha2, pea_fecha3, pea_fecha4, pea_fecha5, pea_fecha6, pea_fecha7, pea_fecha8, pea_fecha9, pea_fecha10,
		pea_texto1, pea_texto2, pea_texto3, pea_texto4, pea_texto5, pea_texto6, pea_texto7, pea_texto8, pea_texto9, pea_texto10,
		pea_numero1, pea_numero2, pea_numero3, pea_numero4, pea_numero5, pea_numero6, pea_numero7, pea_numero8, pea_numero9, pea_numero10,
		pea_coeficiente1, pea_coeficiente2, pea_coeficiente3, pea_coeficiente4, pea_coeficiente5, pea_coeficiente6, pea_coeficiente7, pea_coeficiente8, pea_coeficiente9, pea_coeficiente10,
		pea_obs, pea_usu_id, pea_alta_fecha, pea_p_alta_fecha, pea_filler, pea_clave)

	SELECT	0,		
		ISNULL((select atr_id from wf_atributos inner join carteras on atr_cat = cat_id 
		where cat_nombre_corto = inpea_cat and atr_nombre_corto = inpea_atr
		and cat_baja_fecha is null and atr_baja_fecha is null),0),
		(CASE ISDATE(inpea_fecha1) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha1) END),
		(CASE ISDATE(inpea_fecha2) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha2) END),
		(CASE ISDATE(inpea_fecha3) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha3) END),
		(CASE ISDATE(inpea_fecha4) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha4) END),
		(CASE ISDATE(inpea_fecha5) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha5) END),
		(CASE ISDATE(inpea_fecha6) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha6) END),
		(CASE ISDATE(inpea_fecha7) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha7) END),
		(CASE ISDATE(inpea_fecha8) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha8) END),
		(CASE ISDATE(inpea_fecha9) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha9) END),
		(CASE ISDATE(inpea_fecha10) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpea_fecha10) END),
		inpea_texto1,
		inpea_texto2,
		inpea_texto3,
		inpea_texto4,
		inpea_texto5,
		inpea_texto6,
		inpea_texto7,
		inpea_texto8,
		inpea_texto9,
		inpea_texto10,
		(CASE WHEN RTRIM(LTRIM(inpea_numero1)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero1)/100 END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_numero2)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero2/100) END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_numero3)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero3/100) END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_numero4)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero4/100) END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_numero5)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero5/100) END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_numero6)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero6/100) END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_numero7)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero7/100) END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_numero8)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero8/100) END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_numero9)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero9/100) END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_numero10)) = '' THEN NULL ELSE CONVERT(NUMERIC(16,2), inpea_numero10/100) END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_coeficiente1)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente1/10000) END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_coeficiente2)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente2/10000)  END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_coeficiente3)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente3/10000)  END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_coeficiente4)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente4/10000)  END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_coeficiente5)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente5/10000)  END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_coeficiente6)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente6/10000)  END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_coeficiente7)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente7/10000)  END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_coeficiente8)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente8/10000)  END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_coeficiente9)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente9/10000)  END) ,
		(CASE WHEN RTRIM(LTRIM(inpea_coeficiente10)) = '' THEN NULL ELSE CONVERT(NUMERIC(8,4), inpea_coeficiente10/10000)  END) ,
		ISNULL(inpea_obs,''),
		@v_usu_id_in,
		GETDATE(), 
		@v_fec_proceso,
		ISNULL(inpea_filler,''),
		inpea_clave

	FROM
		in_per_atributos
	WHERE
		(inpea_error IS NULL OR RTRIM(inpea_error)='') AND
		 NOT EXISTS (	SELECT alt_id 
				FROM wf_in_alta_aut 
					INNER JOIN per_atributos on alt_id = pea_id
				WHERE 	alt_tabla='per' AND 
					alt_clave=inpea_clave)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 			
	UPDATE in_per_atributos_aux SET pea_id = alt_id
	FROM in_per_atributos_aux
		INNER JOIN wf_in_alta_aut on alt_clave = pea_clave AND alt_tabla = 'per'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 			
--select * from per_atributos

	INSERT INTO per_atributos
	SELECT	pea_id, pea_atr, 
		pea_fecha1, pea_fecha2, pea_fecha3, pea_fecha4, pea_fecha5, pea_fecha6, pea_fecha7, pea_fecha8, pea_fecha9, pea_fecha10,
		pea_texto1, pea_texto2, pea_texto3, pea_texto4, pea_texto5, pea_texto6, pea_texto7, pea_texto8, pea_texto9, pea_texto10,
		pea_numero1, pea_numero2, pea_numero3, pea_numero4, pea_numero5, pea_numero6, pea_numero7, pea_numero8, pea_numero9, pea_numero10, 
		pea_coeficiente1, pea_coeficiente2, pea_coeficiente3, pea_coeficiente4, pea_coeficiente5, pea_coeficiente6, pea_coeficiente7, pea_coeficiente8, pea_coeficiente9, pea_coeficiente10,
		pea_obs, pea_alta_fecha, pea_modi_fecha, pea_baja_fecha, pea_p_alta_fecha, pea_p_modi_fecha, pea_usu_id, pea_filler
	FROM in_per_atributos_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																					 				
	SELECT @#Enviados = count(*) FROM in_per_atributos
	SELECT @#Rechazados = count(*) FROM in_per_atributos WHERE inpea_error IS NOT NULL AND RTRIM(inpea_error) <> '' 
	SELECT @#Ingresados = count(*) FROM in_per_atributos_aux 
	SELECT @#Actualizados =  count(*) FROM in_per_atributos  
			inner join wf_in_alta_aut on alt_clave = inpea_clave and alt_tabla = 'per' 
			where not exists(select 1 from in_per_atributos_aux where pea_clave = inpea_clave) and
			(inpea_error IS NULL OR RTRIM(inpea_error)='')

	IF @error_tran = 0
		BEGIN
		COMMIT TRAN per_atributos
		END
	ELSE
		BEGIN
		ROLLBACK TRAN per_atributos

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END
	----------------------------------------------------------------------																					 					
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Atributos de Personas - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Atributos de Personas - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Atributos de Personas - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Atributos de Personas - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END

/*
-------------------------------------------------------------------------------------------------------------------------
--TABLA PER_X_CTA
-------------------------------------------------------------------------------------------------------------------------
*/

IF (@v_regper_cta IS NOT NULL) AND @v_regper_cta > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Personas Vinculadas', @v_usu_id_in, Null, @v_cat_id
	
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0

	SET @error_tran = 0

	BEGIN TRAN PER_CTA
	--MODIFICACION DE REGISTROS

	UPDATE per_x_cta
	SET	
		pxc_cta = (select alt_id FROM wf_in_alta_aut where alt_tabla='cta' and alt_clave=inpxc_cta_clave),
		pxc_per = (select alt_id FROM wf_in_alta_aut where alt_tabla='per' and alt_clave=inpxc_per_clave),
		pxc_ogc= iSNULL((select ogc_id from garantes_caracter where ogc_nombre_corto = inpxc_ogc and ogc_baja_fecha is null),0),
		pxc_filler = inpxc_filler,
		pxc_usu_id = @v_usu_id_in	,
		pxc_modi_fecha=getdate()
	FROM in_per_x_cta 
		INNER JOIN wf_in_alta_aut ON alt_tabla='pxc' AND alt_clave = inpxc_clave
	WHERE
		(inpxc_error IS NULL OR RTRIM(inpxc_error)='') 
		 AND pxc_id = alt_id
	--ALTA REGISTROS NUEVOS

	TRUNCATE TABLE in_per_x_cta_aux

	INSERT in_per_x_cta_aux
		(pxc_id, pxc_cta,pxc_per, pxc_ogc, pxc_clave,pxc_filler)

	SELECT 
		0, --pxc_id
		(select alt_id from wf_in_alta_aut where alt_tabla='cta' and alt_clave=inpxc_cta_clave), 
		(select alt_id from wf_in_alta_aut where alt_tabla='per' and alt_clave=inpxc_per_clave), 
		iSNULL((select ogc_id from garantes_caracter where ogc_nombre_corto = inpxc_ogc and ogc_baja_fecha is null),0),
		inpxc_clave,
		inpxc_filler

	FROM
		in_per_x_cta
	WHERE
		(inpxc_error IS NULL OR RTRIM(inpxc_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='pxc' AND alt_clave=inpxc_clave)
		
	SELECT @Puntero = ISNULL(MAX(pxc_id),0) FROM per_x_cta
	UPDATE in_per_x_cta_aux SET pxc_id=@Puntero, @Puntero=@Puntero+1 

	INSERT per_x_cta (pxc_id, pxc_cta,pxc_per, pxc_ogc, pxc_filler,pxc_usu_id,pxc_alta_fecha)
	SELECT
		pxc_id, pxc_cta,pxc_per, pxc_ogc, pxc_filler,@v_usu_id_in,getdate()	
	FROM in_per_x_cta_aux

	

	SELECT @#Enviados = count(*) FROM in_per_x_cta
	SELECT @#Rechazados = count(*) FROM in_per_x_cta where inpxc_error IS NOT NULL AND RTRIM(inpxc_error) <> '' 
	SELECT @#Ingresados = count(*) FROM in_per_x_cta_aux 
	SELECT @#Actualizados =  count(*) FROM in_per_x_cta  
		INNER JOIN wf_in_alta_aut 
			ON alt_clave = inpxc_clave 
				AND alt_tabla = 'pxc' 
				WHERE NOT EXISTS(SELECT 1 FROM in_per_x_cta_aux where pxc_clave = inpxc_clave) and
				(inpxc_error IS NULL OR RTRIM(inpxc_error)='')

	INSERT wf_in_alta_aut 
	SELECT 'pxc',pxc_clave,pxc_id
	FROM in_per_x_cta_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux

	IF @error_tran = 0
		COMMIT TRAN PER_CTA
	ELSE
		ROLLBACK TRAN PER_CTA
	
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Personas Vinculadas - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Personas Vinculadas - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Personas Vinculadas - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Personas Vinculadas - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END


/*
-------------------------------------------------------------------------------------------------------------------------
--TABLA PRESTAMOS
-------------------------------------------------------------------------------------------------------------------------
*/

IF (@v_regptm IS NOT NULL) AND @v_regptm > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Prestamos', @v_usu_id_in, Null, @v_cat_id
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------														
	UPDATE in_prestamos SET inptm_error='T', inptm_error_campo='inptm_cta_clave' WHERE 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='cta' and alt_clave = inptm_cta_clave)		
	----------------------------------------------------------------------														
	SET @error_tran = 0
	BEGIN TRAN PRESTAMOS
	----------------------------------------------------------------------														
	--MODIFICACION DE REGISTROS

	----------------------------------------------------------------------															
	--ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_prestamos_aux
	
	INSERT in_prestamos_aux

		(ptm_id, ptm_cta, ptm_capital_inicial, ptm_fecha_fin, ptm_cta_debito, 
		ptm_alta_fecha, ptm_modi_fecha, ptm_baja_fecha, ptm_p_alta_fecha, ptm_p_modi_fecha, 
		ptm_usu_id, ptm_obs, ptm_filler, ptm_clave)
	SELECT
		0, --ptm_id
		(select alt_id from wf_in_alta_aut where alt_tabla='cta' and alt_clave=inptm_cta_clave), --ptm_cta
		CONVERT(NUMERIC(16,2),inptm_capital_inicial)/100, --ptm_capital_inicial, 		
		(CASE ISDATE(inptm_fecha_fin) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inptm_fecha_fin) END), --ptm_fecha_fin, 
		inptm_cta_debito, --ptm_cta_debito, 
		GETDATE(), --ptm_alta_fecha
		NULL, --ptm_modi_fecha
		NULL, --ptm_baja_fecha
		@v_fec_proceso, --ptm_p_alta_fecha
		NULL, --ptm_p_modi_fecha
		@v_usu_id, --ptm_usu_id
		inptm_obs, --ptm_obs
		inptm_filler, --ptm_filler
		inptm_clave --ptm_clave
	FROM
		in_prestamos
	WHERE
		(inptm_error IS NULL OR RTRIM(inptm_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='ptm' AND alt_clave=inptm_clave)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------														
	
	SELECT @Puntero = ISNULL(MAX(ptm_id),0) FROM prestamos
	UPDATE in_prestamos_aux SET ptm_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	
	----------------------------------------------------------------------															
	INSERT prestamos
	SELECT
		ptm_id, ptm_cta, ptm_capital_inicial, ptm_fecha_fin, ptm_cta_debito, ptm_obs,
		ptm_p_alta_fecha, ptm_p_modi_fecha, ptm_alta_fecha, ptm_modi_fecha, ptm_baja_fecha,  
		ptm_usu_id, ptm_filler

	FROM in_prestamos_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	SELECT @#Enviados 		= count(*) FROM in_prestamos
	SELECT @#Rechazados 	= count(*) FROM in_prestamos WHERE inptm_error IS NOT NULL AND RTRIM(inptm_error) <> '' 
	SELECT @#Ingresados 	= count(*) FROM in_prestamos_aux
	SELECT @#Actualizados 	= count(*) FROM in_prestamos INNER JOIN wf_in_alta_aut ON alt_clave = inptm_clave AND alt_tabla = 'ptm' WHERE inptm_error IS NULL OR RTRIM(inptm_error)=''
	----------------------------------------------------------------------																
	INSERT wf_in_alta_aut 
	SELECT 'ptm',ptm_clave,ptm_id
	FROM in_prestamos_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN PRESTAMOS
		END

	ELSE
		BEGIN
		ROLLBACK TRAN PRESTAMOS

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END	
	----------------------------------------------------------------------																	
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Prestamos - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Prestamos - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Prestamos - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Prestamos - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END


/*
-------------------------------------------------------------------------------------------------------------------------
--TABLA PRESTAMOS CUOTAS
-------------------------------------------------------------------------------------------------------------------------
*/

IF (@v_regpcu IS NOT NULL) AND @v_regpcu > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Prestamos Cuotas', @v_usu_id_in, Null, @v_cat_id
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------														
	UPDATE in_prestamos_cuotas SET inpcu_error='T', inpcu_error_campo='inpcu_ptm_clave' WHERE 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='ptm' and alt_clave = inpcu_ptm_clave)		
	----------------------------------------------------------------------														
	SET @error_tran = 0
	BEGIN TRAN PRESTAMOS_CUOTAS
	----------------------------------------------------------------------														
	--MODIFICACION DE REGISTROS
	UPDATE prestamos_cuotas
	SET		
		pcu_importe = CONVERT(NUMERIC(16,2),inpcu_importe)/100,
		pcu_pago_fecha = (CASE ISDATE(inpcu_pago_fecha) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpcu_pago_fecha) END),
		pcu_estado =inpcu_estado,
		pcu_intereses = CONVERT(NUMERIC(16,2),inpcu_intereses)/100,
		pcu_p_modi_fecha = @v_fec_proceso, 
		pcu_usu_id = @v_usu_id,
		pcu_obs = inpcu_obs,
		pcu_filler = inpcu_filler,
		pcu_baja_fecha = NULL --20140619 DIT Levanto la baja fecha de los prestamos cuotas que vuelven a informarse
	FROM in_prestamos_cuotas , wf_in_alta_aut
	WHERE
		(inpcu_error IS NULL OR RTRIM(inpcu_error)='') AND
		pcu_id = alt_id AND alt_clave = inpcu_clave AND alt_tabla='pcu'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------															
	--ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_prestamos_cuotas_aux
	
	INSERT in_prestamos_cuotas_aux
		(pcu_id, pcu_ptm, pcu_numero, pcu_importe, pcu_venc_fecha, pcu_pago_fecha, pcu_estado, pcu_intereses,
		pcu_alta_fecha,	pcu_modi_fecha, pcu_baja_fecha, pcu_p_alta_fecha, pcu_p_modi_fecha, pcu_usu_id, 
		pcu_obs, pcu_filler, pcu_clave)
	SELECT 
		0, --pcu_id
		(select alt_id from wf_in_alta_aut where alt_tabla='ptm' and alt_clave=inpcu_ptm_clave), --pcu_ptm
		CONVERT(INT,inpcu_numero),--pcu_numero
		CONVERT(NUMERIC(16,2),inpcu_importe)/100,--pcu_importe
		(CASE ISDATE(inpcu_venc_fecha) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpcu_venc_fecha)	END),--pcu_venc_fecha
		(CASE ISDATE(inpcu_pago_fecha) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,inpcu_pago_fecha)	END),--pcu_pago_fecha
		inpcu_estado, --pcu_estado
		CONVERT(NUMERIC(16,2),inpcu_intereses)/100,--pcu_intereses
		GETDATE(), --pcu_alta_fecha
		NULL, --pcu_modi_fecha
		NULL, --pcu_baja_fecha
		@v_fec_proceso, --pcu_p_alta_fecha
		NULL, --pcu_p_modi_fecha
		@v_usu_id, --pcu_usu_id
		inpcu_obs, --pcu_obs
		inpcu_filler, --pcu_filler
		inpcu_clave --pcu_clave
	FROM
		in_prestamos_cuotas
	WHERE
		(inpcu_error IS NULL OR RTRIM(inpcu_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='pcu' AND alt_clave=inpcu_clave)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------														
	SELECT @Puntero = ISNULL(MAX(pcu_id),0) FROM prestamos_cuotas
	UPDATE in_prestamos_cuotas_aux SET pcu_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------															
	INSERT 	prestamos_cuotas
	SELECT
		pcu_id, pcu_ptm, pcu_numero, pcu_importe, pcu_venc_fecha, pcu_pago_fecha, pcu_estado, pcu_intereses, pcu_obs,
		pcu_p_alta_fecha, pcu_p_modi_fecha, pcu_alta_fecha, pcu_modi_fecha, pcu_baja_fecha, pcu_usu_id, pcu_filler
	FROM in_prestamos_cuotas_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	SELECT @#Enviados 	= count(*) FROM in_prestamos_cuotas
	SELECT @#Rechazados 	= count(*) FROM in_prestamos_cuotas WHERE inpcu_error IS NOT NULL AND RTRIM(inpcu_error) <> '' 
	SELECT @#Ingresados 	= count(*) FROM in_prestamos_cuotas_aux 
	SELECT @#Actualizados 	= count(*) FROM in_prestamos_cuotas INNER JOIN wf_in_alta_aut ON alt_clave = inpcu_clave AND alt_tabla = 'pcu' WHERE inpcu_error IS NULL OR RTRIM(inpcu_error)=''
	----------------------------------------------------------------------																
	INSERT wf_in_alta_aut 
	SELECT 'pcu',pcu_clave,pcu_id
	FROM in_prestamos_cuotas_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN PRESTAMOS_CUOTAS
		END
	ELSE
		BEGIN
		ROLLBACK TRAN PRESTAMOS_CUOTAS

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END	
	----------------------------------------------------------------------																	
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Prestamos Cuotas - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Prestamos Cuotas - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Prestamos Cuotas - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Prestamos Cuotas - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END


/*
-------------------------------------------------------------------------------------------------------------------------
--TABLA TARJETAS
-------------------------------------------------------------------------------------------------------------------------
*/

IF (@v_regtaj IS NOT NULL) AND @v_regtaj > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Tarjetas', @v_usu_id_in, Null, @v_cat_id
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------														
	UPDATE in_tarjetas SET intaj_error='T', intaj_error_campo='intaj_cta_clave' WHERE 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='cta' and alt_clave = intaj_cta_clave)		
	----------------------------------------------------------------------														
	SET @error_tran = 0
	BEGIN TRAN TARJETAS
	----------------------------------------------------------------------														
	--MODIFICACION DE REGISTROS
	UPDATE tarjetas
	SET		
		taj_limite_compra = CONVERT(NUMERIC(16,2),intaj_limite_compra)/100,
		taj_estado = intaj_estado,
		taj_obs = intaj_obs,
		taj_filler = intaj_filler,
		taj_p_modi_fecha = @v_fec_proceso, 
		taj_usu_id = @v_usu_id		
	FROM in_tarjetas , wf_in_alta_aut
	WHERE
		(intaj_error IS NULL OR RTRIM(intaj_error)='') AND
		taj_id = alt_id AND alt_clave = intaj_clave AND alt_tabla='taj'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux

	----------------------------------------------------------------------															
	--ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_tarjetas_aux
	
	INSERT in_tarjetas_aux

		(taj_id, taj_cta, taj_numero, taj_limite_compra, taj_estado,
		taj_alta_fecha, taj_modi_fecha, taj_baja_fecha, taj_p_alta_fecha, taj_p_modi_fecha, 
		taj_usu_id, taj_obs, taj_filler, taj_clave)
	SELECT 
		0, --taj_id
		(select alt_id from wf_in_alta_aut where alt_tabla='cta' and alt_clave=intaj_cta_clave), --taj_cta
		intaj_numero, --taj_numero
		CONVERT(NUMERIC(16,2),intaj_limite_compra)/100,--taj_compra_lim
		intaj_estado,--taj_estado
		GETDATE(), --taj_alta_fecha
		NULL, --taj_modi_fecha
		NULL, --taj_baja_fecha
		@v_fec_proceso, --taj_p_alta_fecha
		NULL, --taj_p_modi_fecha
		@v_usu_id, --taj_usu_id
		intaj_obs, --taj_obs
		intaj_filler, --taj_filler
		intaj_clave --taj_clave
	FROM
		in_tarjetas
	WHERE
		(intaj_error IS NULL OR RTRIM(intaj_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='taj' AND alt_clave=intaj_clave)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------														
	
	SELECT @Puntero = ISNULL(MAX(taj_id),0) FROM tarjetas
	UPDATE in_tarjetas_aux SET taj_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	
	----------------------------------------------------------------------															
	INSERT tarjetas
	SELECT
		taj_id, taj_cta, taj_numero, taj_limite_compra, taj_estado, taj_obs,
		taj_p_alta_fecha, taj_p_modi_fecha, taj_alta_fecha, taj_modi_fecha, taj_baja_fecha, 
		taj_usu_id, taj_filler

	FROM in_tarjetas_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	SELECT @#Enviados 	= count(*) FROM in_tarjetas
	SELECT @#Rechazados 	= count(*) FROM in_tarjetas WHERE intaj_error IS NOT NULL AND RTRIM(intaj_error) <> '' 
	SELECT @#Ingresados 	= count(*) FROM in_tarjetas_aux
	SELECT @#Actualizados 	= count(*) FROM in_tarjetas INNER JOIN wf_in_alta_aut ON alt_clave = intaj_clave AND alt_tabla = 'taj' WHERE intaj_error IS NULL OR RTRIM(intaj_error)=''
	----------------------------------------------------------------------																
	INSERT wf_in_alta_aut 
	SELECT 'taj',taj_clave,taj_id
	FROM in_tarjetas_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN TARJETAS
		END
	ELSE
		BEGIN
		ROLLBACK TRAN TARJETAS

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END	
	----------------------------------------------------------------------																	
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Tarjetas - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Tarjetas - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Tarjetas - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Tarjetas - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END

/*
-------------------------------------------------------------------------------------------------------------------------
--TABLA TARJETAS VENCIMIENTOS
-------------------------------------------------------------------------------------------------------------------------
*/

IF (@v_regtcv IS NOT NULL) AND @v_regtcv > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Tarjetas Vencimientos', @v_usu_id_in, Null, @v_cat_id
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------														
	UPDATE in_tarjetas_venc SET intcv_error='T', intcv_error_campo='intcv_taj_clave' WHERE 
	NOT EXISTS  (select 1 from wf_in_alta_aut where alt_tabla='taj' and alt_clave = intcv_taj_clave)		
	----------------------------------------------------------------------														
	SET @error_tran = 0
	BEGIN TRAN TARJETAS_VENC
	----------------------------------------------------------------------														
	--MODIFICACION DE REGISTROS
	----------------------------------------------------------------------															
	--ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_tarjetas_venc_aux
	
	INSERT in_tarjetas_venc_aux
		(tcv_id, tcv_taj, tcv_fecha, tcv_fecha_cierre, tcv_saldo_pesos, tcv_saldo_dolares, tcv_pago_min, 
		tcv_incluye_fec_cierre, tcv_ult_forma_pago, 
		tcv_alta_fecha,	tcv_modi_fecha, tcv_baja_fecha, tcv_p_alta_fecha, tcv_p_modi_fecha, tcv_usu_id, 
		tcv_obs, tcv_filler, tcv_clave)
	SELECT 
		0, --tcv_id
		(select alt_id from wf_in_alta_aut where alt_tabla='taj' and alt_clave=intcv_taj_clave), --tcv_taj
		(CASE ISDATE(intcv_fecha) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,intcv_fecha)	END), --tcv_fecha, 
		(CASE ISDATE(intcv_fecha_cierre) WHEN 0 THEN NULL ELSE CONVERT(DATETIME,intcv_fecha_cierre)	END), --tcv_fecha_cierre, 
		CONVERT(NUMERIC(16,2),intcv_saldo_pesos)/100, --tcv_saldo_pesos, 
		CONVERT(NUMERIC(16,2),intcv_saldo_dolares)/100, --tcv_saldo_dolares, 
		CONVERT(NUMERIC(16,2),intcv_pago_min)/100, --tcv_pago_min, 
		intcv_incluye_fec_cierre, --tcv_incluye_fec_cierre, 
		intcv_ult_forma_pago, --tcv_ult_forma_pago,
		GETDATE(), --tcv_alta_fecha
		NULL, --tcv_modi_fecha
		NULL, --tcv_baja_fecha
		@v_fec_proceso, --tcv_p_alta_fecha
		NULL, --tcv_p_modi_fecha
		@v_usu_id, --tcv_usu_id
		intcv_obs, --tcv_obs
		intcv_filler, --tcv_filler
		intcv_clave --tcv_clave
	FROM
		in_tarjetas_venc
	WHERE
		(intcv_error IS NULL OR RTRIM(intcv_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='tcv' AND alt_clave=intcv_clave)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------														
	SELECT @Puntero = ISNULL(MAX(tcv_id),0) FROM tarjetas_venc
	UPDATE in_tarjetas_venc_aux SET tcv_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------															
	INSERT 	tarjetas_venc
	SELECT
		tcv_id, tcv_taj, tcv_fecha, tcv_fecha_cierre, tcv_saldo_pesos, tcv_saldo_dolares, tcv_pago_min, 
		tcv_incluye_fec_cierre, tcv_ult_forma_pago, tcv_obs, tcv_p_alta_fecha, tcv_p_modi_fecha,
		tcv_alta_fecha,	tcv_modi_fecha, tcv_baja_fecha, tcv_usu_id, tcv_filler
	FROM in_tarjetas_venc_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	SELECT @#Enviados 	= count(*) FROM in_tarjetas_venc
	SELECT @#Rechazados 	= count(*) FROM in_tarjetas_venc WHERE intcv_error IS NOT NULL AND RTRIM(intcv_error) <> '' 
	SELECT @#Ingresados 	= count(*) FROM in_tarjetas_venc_aux 
	SELECT @#Actualizados 	= count(*) FROM in_tarjetas_venc INNER JOIN wf_in_alta_aut ON alt_clave = intcv_clave AND alt_tabla = 'tcv' WHERE intcv_error IS NULL OR RTRIM(intcv_error)=''
	----------------------------------------------------------------------																
	INSERT wf_in_alta_aut 
	SELECT 'tcv',tcv_clave,tcv_id
	FROM in_tarjetas_venc_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN TARJETAS_VENC
		END
	ELSE
		BEGIN
		ROLLBACK TRAN TARJETAS_VENC

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END	
	----------------------------------------------------------------------																	
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Tarjetas Vencimientos - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Tarjetas Vencimientos - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Tarjetas Vencimientos - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Tarjetas Vencimientos - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END

/*
-------------------------------------------------------------------------------------------------------------------------
--TABLA CUENTAS CORRIENTES
-------------------------------------------------------------------------------------------------------------------------
*/

IF (@v_regcca IS NOT NULL) AND @v_regcca > 0 
BEGIN
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas Corrientes', @v_usu_id_in, Null, @v_cat_id
	SET @#Enviados = 0
	SET @#Rechazados = 0
	SET @#Descartados = 0
	SET @#Ingresados = 0
	SET @#Actualizados = 0
	----------------------------------------------------------------------
	SET @error_tran = 0
	BEGIN TRAN CTACTES
	----------------------------------------------------------------------														
	--MODIFICACION DE REGISTROS
	UPDATE cca_ca
	SET
		cca_acuerdo = CONVERT(NUMERIC(16,2),incca_acuerdo)/100,
		cca_saldo = CONVERT(NUMERIC(16,2),incca_saldo)/100,
		cca_porfolio = CONVERT(NUMERIC(16,2),incca_porfolio)/100,
		cca_obs = incca_obs,
		cca_filler = incca_filler,
		cca_modi_fecha = @v_fec_proceso, 
		cca_usu_id = @v_usu_id		
	FROM in_cca_ca, wf_in_alta_aut
	WHERE
		(incca_error IS NULL OR RTRIM(incca_error)='') AND
		cca_id = alt_id AND alt_clave = incca_clave AND alt_tabla='cca'

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux

	----------------------------------------------------------------------															
	--ALTA REGISTROS NUEVOS
	TRUNCATE TABLE in_cca_ca_aux
	
	INSERT in_cca_ca_aux
	SELECT 
		0,
		(select alt_id from wf_in_alta_aut where alt_tabla='cta' and alt_clave=incca_cta_clave),
		CONVERT(NUMERIC(16,2),incca_acuerdo)/100,
		CONVERT(NUMERIC(16,2),incca_saldo)/100,
		CONVERT(NUMERIC(16,2),incca_porfolio)/100,
		cca_obs = incca_obs,
		GETDATE(), --taj_alta_fecha
		NULL, --taj_modi_fecha
		NULL, --taj_baja_fecha
		@v_usu_id,
		incca_filler,
		incca_clave
	FROM
		in_cca_ca
	WHERE
		(incca_error IS NULL OR RTRIM(incca_error)='') AND
		 NOT EXISTS (SELECT alt_id FROM wf_in_alta_aut WHERE alt_tabla='cca' AND alt_clave=incca_clave)

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------														
	
	SELECT @Puntero = ISNULL(MAX(cca_id),0) FROM cca_ca
	UPDATE in_cca_ca_aux SET cca_id=@Puntero, @Puntero=@Puntero+1 

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	
	----------------------------------------------------------------------															
	INSERT cca_ca
	SELECT
		cca_id,
		cca_cta,
		cca_acuerdo,
		cca_saldo,
		cca_porfolio,
		cca_obs,
		getdate(),
		cca_modi_fecha,
		cca_alta_fecha,
		cca_modi_fecha,
		cca_baja_fecha,
		cca_usu_id,
		cca_filler
	FROM in_cca_ca_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	SELECT @#Enviados 	= count(*) FROM in_cca_ca
	SELECT @#Rechazados 	= count(*) FROM in_cca_ca WHERE incca_error IS NOT NULL AND RTRIM(incca_error) <> '' 
	SELECT @#Ingresados 	= count(*) FROM in_cca_ca_aux
	SELECT @#Actualizados 	= count(*) FROM in_cca_ca INNER JOIN wf_in_alta_aut ON alt_clave = incca_clave AND alt_tabla = 'cca' WHERE incca_error IS NULL OR RTRIM(incca_error)=''
	----------------------------------------------------------------------																
	INSERT wf_in_alta_aut 
	SELECT 'cca',cca_clave,cca_id
	FROM in_cca_ca_aux

	SET @error_aux = @@error
	IF @error_tran = 0 AND @error_aux <> 0 SET @error_tran = @error_aux
	----------------------------------------------------------------------																
	IF @error_tran = 0
		BEGIN
		COMMIT TRAN CTACTES
		END
	ELSE
		BEGIN
		ROLLBACK TRAN CTACTES

		SET @#Rechazados = @#Enviados
		SET @#Ingresados = 0
		SET @#Actualizados = 0
		END	
	----------------------------------------------------------------------																	
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas Corrientes - Enviados....: ' + CONVERT(VARCHAR(8),@#Enviados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas Corrientes - Rechazados..: ' + CONVERT(VARCHAR(8),@#Rechazados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas Corrientes - Ingresados..: ' + CONVERT(VARCHAR(8),@#Ingresados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','Entidad Cuentas Corrientes - Actualizados: ' + CONVERT(VARCHAR(8),@#Actualizados), @v_usu_id_in, Null, @v_cat_id
	INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'A','', @v_usu_id_in, Null, @v_cat_id
END

EXEC dbo.id_numeracion_update

INSERT wf_print_out SELECT @prc_nombre_corto,GETDATE(),@v_fec_proceso,'F','PROCESO ALTA AUTOMATICA - FINALIZADO. Cartera: ' + @v_cat_nombre_corto + '  ' + CONVERT(CHAR(20),GETDATE(),113), @v_usu_id_in, @cod_ret, @v_cat_id












