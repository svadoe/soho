SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[wf_cmb_objetos_insert_2] ( 
                                            @v_cob_sob                       int,
                                            @v_cob_cambio_fecha              datetime,
                                            @v_cob_tipo                      varchar(30),
                                            @v_cob_dato_ant                  int,
                                            @v_cob_dato_nue                  int,
                                            @v_cob_nombre_ant                varchar(100),
                                            @v_cob_nombre_nue                varchar(100),
                                            @v_cob_reg                       int,
                                            @v_cob_obs                       varchar(100),
                                            @v_cob_usu_id                    int,
                                            @v_cob_filler                    varchar(255),
                                            @v_cod_ret                    int out
                                            ) AS

DECLARE @v_id int

SET NOCOUNT ON

/*INICIO 20200418 sergio vado espinoza: se obtiene el idn_ultimo_id directo de la tabla wf_cmb_objetos*/

SELECT @v_id = max(cob_id) + 1 FROM wf_cmb_objetos
UPDATE id_numeracion SET idn_ultimo_id = @v_id WHERE idn_tabla = 'wf_cmb_objetos'

--20200418 UPDATE id_numeracion SET idn_ultimo_id = idn_ultimo_id + 1 WHERE idn_tabla = 'wf_cmb_objetos'

/*FIN 20200418 sergio vado espinoza*/

IF @@error <> 0
BEGIN 
	SELECT @v_cod_ret = @@error
	Return
End

SELECT @v_id = idn_ultimo_id FROM id_numeracion WHERE idn_tabla = 'wf_cmb_objetos'

IF @@error <> 0
BEGIN 
	SELECT @v_cod_ret = @@error
	Return
End

INSERT INTO wf_cmb_objetos
(
cob_id,
cob_sob,
cob_cambio_fecha,
cob_tipo,
cob_dato_ant,
cob_dato_nue,
cob_nombre_ant,
cob_nombre_nue,
cob_reg,
cob_obs,
cob_alta_fecha,
cob_modi_fecha,
cob_baja_fecha,
cob_usu_id,
cob_filler
)
VALUES 
(
@v_id,
@v_cob_sob,
@v_cob_cambio_fecha,
@v_cob_tipo,
@v_cob_dato_ant,
@v_cob_dato_nue,
@v_cob_nombre_ant,
@v_cob_nombre_nue,
@v_cob_reg,
@v_cob_obs,
getdate(),
NULL,
NULL,
@v_cob_usu_id,
@v_cob_filler
)


  SELECT @v_cod_ret = @@error

GO
