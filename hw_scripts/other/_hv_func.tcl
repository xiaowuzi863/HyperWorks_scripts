proc set_cur_subcase {case_id} {
    set curtime [clock seconds]
	hwi OpenStack
	hwi GetSessionHandle sess_$curtime
	sess_$curtime GetProjectHandle proj_$curtime
	proj_$curtime GetPageHandle page_$curtime \
	[proj_$curtime GetActivePage]
	page_$curtime GetWindowHandle win_$curtime \
	[page_$curtime GetActiveWindow]
	win_$curtime GetClientHandle client_$curtime
	client_$curtime GetModelHandle model_$curtime \
	[client_$curtime GetActiveModel]
	model_$curtime GetResultCtrlHandle result_$curtime
	result_$curtime SetCurrentSubcase $case_id
	client_$curtime Draw
	hwi CloseStack
}

proc get_measure_from_contour {node_id} {
    set curtime [clock seconds]
	hwi OpenStack
	hwi GetSessionHandle sess_$curtime
	sess_$curtime GetProjectHandle proj_$curtime
	proj_$curtime GetPageHandle page_$curtime \
	[proj_$curtime GetActivePage]
	page_$curtime GetWindowHandle win_$curtime \
	[page_$curtime GetActiveWindow]
	win_$curtime GetClientHandle client_$curtime
	client_$curtime GetMeasureHandle measure_$curtime \
	[client_$curtime AddMeasure]
	measure_$curtime SetType "Nodal Contour"
	measure_$curtime AddNode $node_id
	measure_$curtime SetVisibility True
	client_$curtime SetDisplayOptions measure true
	client_$curtime Draw
	set value [measure_$curtime GetValueList scalar]
	hwi CloseStack
	return [lindex $value 0]
}