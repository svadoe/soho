/*20200418 sergio vado espinoza creación de índices tabla tarjetas_venc*/
CREATE INDEX idn_tcv_fecha ON tarjetas_venc (tcv_fecha)
CREATE INDEX idn_tcv_taj ON tarjetas_venc (tcv_taj, tcv_fecha)

