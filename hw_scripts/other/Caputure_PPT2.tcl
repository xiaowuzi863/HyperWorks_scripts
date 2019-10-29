namespace eval capture_powerpoint {
    variable model_file
	variable result_file
	variable ppt_file
	
	proc window {} {
	    set w .capture_ppt
		toplevel $w
		wm title $w "Capture"

		set types1 {
		    {"BDF Files"		{.bdf} }
			{"OP2 Files"		{.op2}		}
		}
		
		set types2 {
			{"PPT Files"		{.pptx} }
		}
		
		frame $w.f
		hwtk::label $w.f.lab1 -text "Model File:"
		hwtk::openfileentry $w.f.ent1 -filetypes $types1 \
		-textvariable capture_powerpoint::model_file -width 50
		hwtk::label $w.f.lab3 -text "PPT File:"
		hwtk::savefileentry $w.f.ent3 -filetypes $types2 \
		-textvariable capture_powerpoint::ppt_file -width 50
		pack $w.f -side top -fill x
		pack $w.f.lab1 $w.f.ent1 $w.f.lab3 $w.f.ent3 -side top -fill x
		
		frame $w.b
		hwtk::button $w.b.run -text "Run" -command "capture_powerpoint::main"
		hwtk::button $w.b.close -text "Close" -command "destroy $w"
		pack $w.b -side top -fill x
		pack $w.b.run $w.b.close -side left -expand 1
	}
	
	proc main {} {
	    set m_file [file nativename "$capture_powerpoint::model_file"]
		set p_file [file nativename "$capture_powerpoint::ppt_file"]
	    capture_ppt_hv_handle::read_model_nas_result $m_file
		set file_path [file dirname $p_file]
		
		package require twapi
		set ppt [::twapi::comobj PowerPoint.Application]
		$ppt DisplayAlerts [expr 0]
		$ppt Visible 1
		set presents [$ppt Presentations]
		$presents Add
		set active_presentation [$ppt ActivePresentation]; #get the cureently active presentaatin
		set slides [$active_presentation Slides]; #gte the slide list
		set subcase 1
		capture_ppt_hv_handle::capture_get "$file_path/$subcase.jpg"
		set slide_$subcase [$slides Add $subcase 12]
		set slide_$subcase\_shapes [[set slide_$subcase] Shapes]
		set slide_$subcase\_video \
		[[set slide_$subcase\_shapes] AddPicture\
		[file nativename "$file_path/$subcase.jpg"] -1 -1 20 100 650 300]	
		lappend object_list "slide_$subcase"
		lappend object_list "slide_$subcase\_shapes"
		lappend object_list "slide_$subcase\_video"
		$active_presentation SaveAs "$p_file"
		foreach object $object_list {
			puts $object
			[set $object] -destroy
		}
		$slides -destroy
		$active_presentation -destroy 
		$ppt -destroy
	}
}

namespace eval capture_ppt_hv_handle {
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
		hwi CloseStack
	}
	
	proc get_subcase_list {} {
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
		set s_list [result_$curtime GetSubcaseList]
		client_$curtime Draw
		hwi CloseStack
		return $s_list
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
		client_$curtime SetMeasureNumericFormat scientific
		measure_$curtime SetType "Nodal Contour"
		measure_$curtime AddNode $node_id
		measure_$curtime SetVisibility True
		client_$curtime SetDisplayOptions measure true
		client_$curtime Draw
		set value [measure_$curtime GetValueList scalar]
		hwi CloseStack
		return [lindex $value 0]
	}

	proc contour_plot {data_type component} {
		#使用handle必备语句
		hwi OpenStack 
		set curtime [clock seconds]
		#找寻Handle
		hwi GetSessionHandle Sess_$curtime
		Sess_$curtime GetProjectHandle Proj_$curtime
		Proj_$curtime GetPageHandle Page_$curtime \
		[Proj_$curtime GetActivePage]
		Page_$curtime GetWindowHandle Win_$curtime \
		[Page_$curtime GetActiveWindow]
		Win_$curtime GetClientHandle Client_$curtime
		Client_$curtime GetModelHandle Model_$curtime \
		[Client_$curtime GetActiveModel]
		Model_$curtime GetResultCtrlHandle Result_$curtime
		Result_$curtime GetContourCtrlHandle Con_$curtime
		
		#设置云图的显示内容
		Con_$curtime SetDataType "$data_type"
		Con_$curtime SetDataComponent comp "$component"
		Con_$curtime SetResultSystem -1
		Con_$curtime RestorePlotStyle "Deafault Contour"
		
		#设置云图的标签
		Con_$curtime GetLegendHandle Leg_$curtime
		Leg_$curtime SetType dynamic
		
		#显示云图
		#如下几句中的true换成false为关闭云图
		Con_$curtime SetEnableState true
		Client_$curtime SetDisplayOptions "contour" true
		Client_$curtime SetDisplayOptions "legend" true
		Client_$curtime Draw
		
		#使用handle必备语句，对应第一句
		hwi CloseStack
		
	}
	
	proc capture_get {filename} {
	    hwi OpenStack 
		set curtime [clock seconds]
		hwi GetSessionHandle Sess_$curtime
		Sess_$curtime CaptureActiveWindow JPEG $filename pixels 1280 960
		hwi CloseStack
	}
	
	proc read_model_nas_result {m_file} {
	    hwi OpenStack
        set curtime [clock seconds]
		hwi GetSessionHandle session_$curtime
		session_$curtime GetProjectHandle project_$curtime
		project_$curtime GetPageHandle page_$curtime [project_$curtime GetActivePage]
		page_$curtime GetWindowHandle window_$curtime [page_$curtime GetActiveWindow]
		window_$curtime GetClientHandle client_$curtime
		client_$curtime RemoveAllModels
		client_$curtime AddModel "$m_file" "NASTRAN Model Input Reader"
		client_$curtime Draw
        hwi CloseStack
	}
}

capture_powerpoint::window
