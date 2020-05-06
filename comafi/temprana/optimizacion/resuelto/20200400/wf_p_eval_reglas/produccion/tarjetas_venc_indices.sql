/*20200420 sergio vado espinoza creación de índices tabla tarjetas_venc*/
CREATE INDEX idn_tcv_fecha ON dbo.tarjetas_venc (tcv_fecha)
CREATE INDEX idn_tcv_taj ON dbo.tarjetas_venc (tcv_taj, tcv_fecha)

