
 Tiempos de ejecución de SQL Server:
   Tiempo de CPU = 25739 ms, tiempo transcurrido = 10596 ms.
(561677 rows affected)
--[
SET statistics TIME ON
Select
  alt_id AS cta_id,
	cta_pro = ISNULL((SELECT pro_id FROM productos WHERE pro_nombre_corto = incta_pro AND pro_baja_fecha IS NULL),0), 
	cta_cla = ISNULL((SELECT cla_id FROM clasificaciones WHERE cla_nombre_corto = incta_cla AND cla_baja_fecha IS NULL),0), 
	cta_suc = ISNULL((SELECT suc_id FROM sucursales, entidades WHERE suc_ent = ent_id AND ent_nombre_corto = incta_ent AND suc_nombre_corto = incta_suc AND suc_baja_fecha IS NULL),0),
	cta_bnc = ISNULL((SELECT bnc_id FROM banca WHERE bnc_nombre_corto = incta_bnc AND bnc_baja_fecha IS NULL),0)
INTO
  #cuentas
FROM
  in_cuentas, wf_in_alta_aut
WHERE
  (incta_error IS NULL OR RTRIM(incta_error)='') AND 
  alt_clave = incta_clave AND 
  alt_tabla='cta'
  SELECT * FROM #cuentas ORDER BY 1,2,3,4,5
--]
CREATE index ind_incta_clave ON in_cuentas(incta_clave)
--[
SET statistics TIME ON
Select
  alt_id AS cta_id,
	cta_pro = COALESCE(pro_id,0),
	cta_cla = COALESCE(cla_id,0),
	cta_suc = COALESCE(suc_id,0),
	cta_bnc = COALESCE(bnc_id,0)
INTO
  #cuentas
FROM
  in_cuentas
  INNER JOIN wf_in_alta_aut ON alt_clave = incta_clave
  LEFT JOIN productos       ON incta_pro = pro_nombre_corto
  LEFT JOIN clasificaciones ON incta_cla = cla_nombre_corto
  LEFT JOIN entidades       ON incta_ent = ent_nombre_corto
  LEFT JOIN sucursales      ON incta_suc = suc_nombre_corto
  LEFT JOIN banca           ON incta_bnc = bnc_nombre_corto
WHERE
  (incta_error IS NULL OR RTRIM(incta_error)='') AND 
  alt_tabla='cta'
  AND pro_baja_fecha IS NULL
  AND cla_baja_fecha IS NULL
  AND suc_baja_fecha IS NULL
  AND suc_ent = ent_id
  AND bnc_baja_fecha IS NULL
--]



--[
SET statistics TIME ON
SELECT * INTO #cuentas FROM a_view
--]
--[
SET statistics TIME ON
CREATE VIEW a_view AS
Select
  alt_id AS cta_id,
	cta_pro = COALESCE(pro_id,0),--ISNULL((SELECT pro_id FROM productos WHERE pro_nombre_corto = incta_pro AND pro_baja_fecha IS NULL),0), 
	cta_cla = COALESCE(cla_id,0),--ISNULL((SELECT cla_id FROM clasificaciones WHERE cla_nombre_corto = incta_cla AND cla_baja_fecha IS NULL),0), 
	cta_suc = COALESCE(suc_id,0),--ISNULL((SELECT suc_id FROM sucursales, entidades WHERE suc_ent = ent_id AND ent_nombre_corto = incta_ent AND suc_nombre_corto = incta_suc AND suc_baja_fecha IS NULL),0),
	cta_bnc = COALESCE(bnc_id,0)--ISNULL((SELECT bnc_id FROM banca WHERE bnc_nombre_corto = incta_bnc AND bnc_baja_fecha IS NULL),0)
FROM
  in_cuentas
  INNER JOIN wf_in_alta_aut ON alt_clave = incta_clave
  LEFT JOIN productos       ON incta_pro = pro_nombre_corto
  LEFT JOIN clasificaciones ON incta_cla = cla_nombre_corto
  LEFT JOIN entidades       ON incta_ent = ent_nombre_corto
  LEFT JOIN sucursales      ON incta_suc = suc_nombre_corto
  LEFT JOIN banca           ON incta_bnc = bnc_nombre_corto
WHERE
  (incta_error IS NULL OR RTRIM(incta_error)='') AND 
  alt_tabla='cta'
  AND pro_baja_fecha IS NULL
  AND cla_baja_fecha IS NULL
  AND suc_baja_fecha IS NULL
  AND suc_ent = ent_id
  AND bnc_baja_fecha IS NULL
--
--]
