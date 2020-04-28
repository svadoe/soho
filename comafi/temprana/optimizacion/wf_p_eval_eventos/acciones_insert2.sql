SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[acciones_insert2] ( 
                                   @v_acc_per                       int,
                                   @v_acc_cta                       int,
                                   @v_acc_fec_hora                  datetime,
                                   @v_acc_tac                       int,
                                   @v_acc_obs                       varchar(255),
                                   @v_acc_estado                    varchar(1),
                                   @v_acc_trp                       int,
                                   @v_acc_res_fec_hora              datetime,
                                   @v_acc_usu                       int,
                                   @v_acc_obs_resp                  varchar(255),
                                   @v_acc_fec_vto                   datetime,
                                   @v_acc_etg                       int,
                                   @v_acc_esc                       int,
                                   @v_acc_fec_esc                   datetime,
                                   @v_acc_est                       int,
                                   @v_acc_fec_est                   datetime,
                                   @v_acc_usu_resp                  int,
                                   @v_acc_deuda_a_venc              numeric(16,2),
                                   @v_acc_deuda_venc                numeric(16,2),
                                   @v_acc_eve                       int,
									@v_acc_mov						int,
									@v_acc_costo					numeric(9,2),
                                   @v_acc_usu_id                    int,
                                   @v_acc_filler                    varchar(255),
                                   @v_cod_ret                    int out
                                   ) AS

/* VAK: modificado el 2006-09-06 */

DECLARE @v_id int

UPDATE id_numeracion SET idn_ultimo_id = idn_ultimo_id + 1 WHERE idn_tabla = 'acciones'

SELECT @v_cod_ret = @@error
IF @v_cod_ret <> 0
    Return

SELECT @v_id = idn_ultimo_id FROM id_numeracion WHERE idn_tabla = 'acciones'

SELECT @v_cod_ret = @@error
IF @v_cod_ret <> 0
    Return


INSERT INTO acciones
(
	acc_id,
	acc_per,
	acc_cta,
	acc_fec_hora,
	acc_tac,
	acc_obs,
	acc_estado,
	acc_trp,
	acc_res_fec_hora,
	acc_usu,
	acc_obs_resp,
	acc_fec_vto,
	acc_etg,
	acc_esc,
	acc_fec_esc,
	acc_est,
	acc_fec_est,
	acc_usu_resp,
	acc_deuda_a_venc,
	acc_deuda_venc,
	acc_eve,
	acc_mov,
	acc_costo,
	acc_alta_fecha,
	acc_modi_fecha,
	acc_baja_fecha,
	acc_usu_id,
	acc_filler
)
VALUES 
(
	@v_id,
	@v_acc_per,
	@v_acc_cta,
	@v_acc_fec_hora,
	@v_acc_tac,
	@v_acc_obs,
	@v_acc_estado,
	@v_acc_trp,
	@v_acc_res_fec_hora,
	@v_acc_usu,
	@v_acc_obs_resp,
	@v_acc_fec_vto,
	@v_acc_etg,
	@v_acc_esc,
	@v_acc_fec_esc,
	@v_acc_est,
	@v_acc_fec_est,
	@v_acc_usu_resp,
	@v_acc_deuda_a_venc,
	@v_acc_deuda_venc,
	@v_acc_eve,
	@v_acc_mov,
	@v_acc_costo,
	GETDATE(),
	NULL,
	NULL,
	@v_acc_usu_id,
	@v_acc_filler
)

SELECT @v_cod_ret = @@error

GO
