
ALTER PROCEDURE [dbo].[cmb_cta_auto]	@v_cta_id	int,
					@v_tipo		varchar(20),
					@v_id_nuevo	int,
					@v_usu_id	int,
					@v_obs		varchar(255),
					@v_cod_ret	int OUT
AS

/* 20200408 sergio vado espinoza se mueve de lugar el código para clasificar la banca */
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
--Identificar el producto-----------------------
IF @v_tipo = 'cta_pro'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_pro
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(pro_nombre_corto) + '-' + pro_nombre
		From productos
		Where	pro_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(pro_nombre_corto) + '-' + pro_nombre
		From productos
		Where	pro_id = @v_id_nuevo
	END
END
ELSE
--Identificar la clasificacion -----------------------
IF @v_tipo = 'cta_cla'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_cla
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(cla_nombre_corto) + '-' + cla_nombre
		From clasificaciones
		Where	cla_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(cla_nombre_corto) + '-' + cla_nombre
		From clasificaciones
		Where	cla_id = @v_id_nuevo
	END
END
ELSE
--Identificar la Sucursal-----------------------
IF @v_tipo = 'cta_suc'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_suc
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(suc_nombre_corto) + '-' + suc_nombre
		From sucursales
		Where	suc_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(suc_nombre_corto) + '-' + suc_nombre
		From sucursales
		Where	suc_id = @v_id_nuevo
	END
END
ELSE

/* INICIO */
/* 20200408 sergio vado espinoza */
--Identificar la banca -----------------------
IF @v_tipo = 'cta_bnc'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_bnc
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(bnc_nombre_corto) + '-' + bnc_nombre
		From banca
		Where	bnc_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(bnc_nombre_corto) + '-' + bnc_nombre
		From banca
		Where	bnc_id = @v_id_nuevo
	END
END
ELSE
/* FIN */
/* 20200408 sergio vado espinoza */

--Identificar la Moneda-----------------------
IF @v_tipo = 'cta_mon'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_mon
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(mon_nombre_corto) + '-' + mon_nombre
		From monedas
		Where	mon_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(mon_nombre_corto) + '-' + mon_nombre
		From monedas
		Where	mon_id = @v_id_nuevo
	END
END
ELSE
--Identificar el canal -----------------------
IF @v_tipo = 'cta_cnl'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_cnl
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(cnl_nombre_corto) + '-' + cnl_nombre
		From canales
		Where	cnl_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(cnl_nombre_corto) + '-' + cnl_nombre
		From canales
		Where	cnl_id = @v_id_nuevo
	END
END
ELSE
--Identificar la campaña comercial -----------------------
IF @v_tipo = 'cta_cam'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_cam
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(cam_nombre_corto) + '-' + cam_nombre
		From camp_comer
		Where	cam_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(cam_nombre_corto) + '-' + cam_nombre
		From camp_comer
		Where	cam_id = @v_id_nuevo
	END
END
ELSE
  
/* 20200408 sergio vado espinoza
--Identificar la banca -----------------------
IF @v_tipo = 'cta_bnc'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_bnc
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(bnc_nombre_corto) + '-' + bnc_nombre
		From banca
		Where	bnc_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(bnc_nombre_corto) + '-' + bnc_nombre
		From banca
		Where	bnc_id = @v_id_nuevo
	END
END
ELSE
20200408 sergio vado espinoza
*/

--Identificar la entidad -----------------------
IF @v_tipo = 'cta_ent'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_ent
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(ent_nombre_corto) + '-' + ent_nombre
		From entidades
		Where	ent_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(ent_nombre_corto) + '-' + ent_nombre
		From entidades
		Where	ent_id = @v_id_nuevo
	END
END
ELSE
--Identificar la condicion de IVA-----------------------
IF @v_tipo = 'cta_civ'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_civ
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(civ_nombre_corto) + '-' + civ_nombre
		From cond_iva
		Where	civ_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(civ_nombre_corto) + '-' + civ_nombre
		From cond_iva
		Where	civ_id = @v_id_nuevo
	END
END
ELSE
--Identificar la agencia -----------------------
IF @v_tipo = 'cta_age'
BEGIN

	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_age
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN

		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(age_cod) + '-' + age_nombre
		From agencias
		Where	age_id = @v_id_actual

		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(age_cod) + '-' + age_nombre
		From agencias
		Where	age_id = @v_id_nuevo
	END
END
ELSE
--Identificar el tipo de contrato -----------------------
IF @v_tipo = 'cta_tco'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_tco
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(tco_nombre_corto) + '-' + tco_nombre
		From tipos_contratos
		Where	tco_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(tco_nombre_corto) + '-' + tco_nombre
		From tipos_contratos
		Where	tco_id = @v_id_nuevo
	END
END
ELSE
--Identificar el tipo de paquete -----------------------
IF @v_tipo = 'cta_tpa'
BEGIN
	--Obtener el valor actual---------------------
	Select	@v_id_actual = cta_tpa
	From cuentas
	Where cta_id = @v_cta_id

	--Verificar que cambio------------------------
	IF @v_id_actual <> @v_id_nuevo
	BEGIN
		--Obtener los datos viejos------------
		Select 	@v_nombre_actual = rtrim(tpa_nombre_corto) + '-' + tpa_nombre
		From tipos_paquetes
		Where	tpa_id = @v_id_actual
		
		--Obtener los datos nuevos------------
		Select 	@v_nombre_nuevo = rtrim(tpa_nombre_corto) + '-' + tpa_nombre
		From tipos_paquetes
		Where	tpa_id = @v_id_nuevo
	END
END
--ELSE

	--raise error porque no esta contemplado el tipo

--Insertar en tabla-----------------------------
IF @v_nombre_nuevo is not NULL
BEGIN
	Exec cmb_cta_insert_2	@v_cct_cta = @v_cta_id,
				@v_cct_cambio_fecha = @v_fecha,
				@v_cct_tipo = @v_tipo,
				@v_cct_dato_ant = @v_id_actual,
				@v_cct_dato_nue = @v_id_nuevo,
				@v_cct_nombre_ant = @v_nombre_actual,
				@v_cct_nombre_nue = @v_nombre_nuevo,
				@v_cct_obs = @v_obs,
				@v_cct_usu_id = @v_usu_id,
				@v_cct_filler = '',
				@v_cod_ret = @v_cod_ret OUT
END

-------------------------------------------------
Select @v_cod_ret = @@error
-------------------------------------------------

GO
