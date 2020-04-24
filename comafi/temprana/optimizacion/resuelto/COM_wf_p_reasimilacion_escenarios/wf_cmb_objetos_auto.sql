SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[wf_cmb_objetos_auto]	@v_sob_id	int,
						@v_tipo		varchar(20),
						@v_id_nuevo	int,
						@v_reg_id	int,
						@v_usu_id	int,
						@v_obs		varchar(255),
						@v_cod_ret	int OUT
AS
------------------------------------------------------
Declare @v_id_actual int
Declare @v_nombre_actual varchar(100)
Declare @v_nombre_nuevo varchar(100)
Declare @v_fecha datetime
------------------------------------------------------
--SET NOCOUNT ON
------------------------------------------------------
Select @v_fecha = getdate()
------------------------------------------------------
--Identificar el Tipo de cambio-----------------------
IF @v_tipo = 'sob_esc'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = sob_esc
	From wf_sit_objetos
	Where sob_id = @v_sob_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(esc_nombre_corto) + '-' + esc_nombre
		From wf_escenarios
		Where	esc_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(esc_nombre_corto) + '-' + esc_nombre
		From wf_escenarios
		Where	esc_id = @v_id_nuevo
	END
END
--Identificar el Tipo de cambio-----------------------
IF @v_tipo = 'sob_etg'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = sob_etg
	From wf_sit_objetos
	Where sob_id = @v_sob_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(etg_nombre_corto) + '-' + etg_nombre
		From wf_estrategias
		Where	etg_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(etg_nombre_corto) + '-' + etg_nombre
		From wf_estrategias
		Where	etg_id = @v_id_nuevo
	END
END
--Identificar el Tipo de cambio-----------------------
IF @v_tipo = 'sob_est'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = sob_est
	From wf_sit_objetos
	Where sob_id = @v_sob_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(est_nombre_corto) + '-' + est_nombre
		From wf_estados
		Where	est_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(est_nombre_corto) + '-' + est_nombre
		From wf_estados
		Where	est_id = @v_id_nuevo
	END
END
--Identificar el Tipo de cambio-----------------------
IF @v_tipo = 'sob_scr'
BEGIN

	--Obtener el valor actual---------------------
	Select	@v_id_actual = sob_scr
	From wf_sit_objetos
	Where sob_id = @v_sob_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------

		Select 	@v_nombre_actual = rtrim(scr_nombre_corto) + '-' + scr_nombre
		From wf_scripts
		Where	scr_id = @v_id_actual


		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(scr_nombre_corto) + '-' + scr_nombre
		From wf_scripts
		Where	scr_id = @v_id_nuevo
	END
END
--Identificar el Tipo de cambio-----------------------
IF @v_tipo = 'sob_usu_res'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = sob_usu_res
	From wf_sit_objetos
	Where sob_id = @v_sob_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(usu_apellido) + ',' + usu_nombre
		From wf_usuarios
		Where	usu_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(usu_apellido) + ',' + usu_nombre
		From wf_usuarios
		Where	usu_id = @v_id_nuevo
	END
END
--Insertar en tabla-----------------------------
IF @v_nombre_nuevo is not NULL
BEGIN
	Exec wf_cmb_objetos_insert_2	@v_cob_sob = @v_sob_id,
					@v_cob_cambio_fecha = @v_fecha,
					@v_cob_tipo = @v_tipo,
					@v_cob_dato_ant = @v_id_actual,
					@v_cob_dato_nue = @v_id_nuevo,
					@v_cob_nombre_ant = @v_nombre_actual,
					@v_cob_nombre_nue = @v_nombre_nuevo,
					@v_cob_obs = @v_obs,
					@v_cob_reg = @v_reg_id,
					@v_cob_usu_id = @v_usu_id,
					@v_cob_filler = '',
					@v_cod_ret = @v_cod_ret OUT
END
-------------------------------------------------
Select @v_cod_ret = @@error
-------------------------------------------------

GO
