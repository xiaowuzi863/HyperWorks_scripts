namespace eval mount_stiffness_hv_main {
    proc window {} {
	    		
		set w .mount_stiffness_hv
		toplevel $w
		wm title $w "Mount Stiffness in HyperView"
		catch {KeepOnTop $w}

		set types {
			{"CSV Files"		{.csv} }
			{"All files"		*}
		}
		
		frame $w.f1
		hwtk::label $w.f1.lab -text "Mount Message File:"
		hwtk::openfileentry $w.f1.ent -filetypes $types -width 50 
		pack $w.f1 -side top -fill x
		pack $w.f1.lab $w.f1.ent -side left -expand 1
		
		frame $w.f2
		hwtk::label $w.f2.lab -text "Save Mount Stiffness File:"
		hwtk::savefileentry $w.f2.ent -filetypes $types -width 50
		pack $w.f2 -side top -fill x
	    pack $w.f2.lab $w.f2.ent -side left -expand 1
		
		frame $w.b
		hwtk::button $w.b.run -text "Apply" -command \
		"mount_stiffness_hv_main::read_mount_stiffness $w.f1.ent $w.f2.ent"
		hwtk::button $w.b.close -text "Close" -command "destroy $w"
		pack $w.b -side top -fill x
		pack $w.b.run $w.b.close -side left -expand 1
	} 
	
	proc read_mount_stiffness {f1 f2} {
	    set input_file [$f1 get]
		set output_file [$f2 get]
	    set mount_msgs [read_csv $input_file]
		set out_fid [open $output_file w]
		puts -nonewline $out_fid \
		"Mount Name,Component,Displacement,Mount Stiffness\n"
		foreach mount_msg $mount_msgs {
		    set node_id [lindex $mount_msg 0]
			if {$node_id == "Node ID"} {
			    continue
			}
			set tmp [lindex $mount_msg 3]
			set mount_name [string range $tmp 0 end-2]
			set comp [lindex $mount_msg 2]
			set load_step_id [lindex $mount_msg 4]
			mount_stiffness_hv_handle::set_cur_subcase \
			$load_step_id
			mount_stiffness_hv_handle::contour_plot \
			Displacement $comp
			set disp \
			[mount_stiffness_hv_handle::get_measure_from_contour \
			$node_id]
			set magnitude [lindex $mount_msg end]
			set mount_stiffness [expr $magnitude / $disp]
			puts -nonewline $out_fid \
			"$mount_name,$comp,$disp,$mount_stiffness\n"
		}
		close $out_fid
	}
	
	proc read_csv {csvfile} {
		set values {} 
		set FileChannelID [open [file nativename $csvfile] r]
		while {![eof $FileChannelID]} {
			set line [gets $FileChannelID];
			set temp [split $line ","];
			if {[llength [lindex $temp 0]] <= 0} {
				break;
			}
			lappend values $temp
		}
		close $FileChannelID 
		return $values
    }
}

namespace eval mount_stiffness_hv_handle {
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
}

mount_stiffness_hv_main::window

