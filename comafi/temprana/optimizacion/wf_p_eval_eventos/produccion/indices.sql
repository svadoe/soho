
CREATE index ind_evp_sob ON wf_eventos_proceso (evp_sob)
CREATE index ind_evp_evento ON wf_eventos_proceso (evp_evento)
CREATE index ind_evp_sob_eve ON wf_eventos_proceso (evp_sob, evp_evento)
CREATE index ind_acc_cta_tac ON acciones (acc_cta, acc_tac)
CREATE index ind_acc_per_tac ON acciones (acc_per, acc_tac)

