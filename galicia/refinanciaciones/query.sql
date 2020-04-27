SELECT * FROM wf_parametros WHERE prt_nombre_corto = 'FECCIE'
SELECT top 10 * FROM wf_llog ORDER BY 1 DESC
SELECT * FROM wf_usuarios WHERE usu_id = 2

Pantalla con parámetros de



DECLARE @p18 BIGINT
SET @p18=NULL
EXEC ma_propuestas_validar_permisos @v_npr_id=120,
@v_ope_list=N', 612455, ',
@v_the_id=1,
@v_sistema=N'F',
@v_neto_refinanciar=27.07,
@v_saldo_ajustado=0,
@v_cuotas=4,
@v_int_comp_tasa_fija=5,
@v_quita=0,
@v_quita_porcen=8,
@v_quita_puni=0,
@v_quita_puni_porcen=0,
@v_quita_comp=0,
@v_quita_comp_porcen=0,
@v_anticipo=0,
@v_anticipo_porcen=0,
@v_usu_id=2,
@v_cod_ret=@p18 OUTPUT
SELECT @p18

SELECT * FROM wf_print_out
EXEC sp_helptext ma_propuestas_validar_permisos
