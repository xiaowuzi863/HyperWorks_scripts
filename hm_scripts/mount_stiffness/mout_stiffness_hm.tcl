namespace eval mout_stiffness_hm {
    variable node0
	variable node1
	variable node2
	variable mt_name
	variable force_mag
	variable force_comp
	
	proc initialize {} {
	    hm_exitpanel
		set mout_stiffness_hm::node0 ""
	    set mout_stiffness_hm::node1 ""
		set mout_stiffness_hm::node2 ""
	    set mout_stiffness_hm::force_comp ALL
		set mout_stiffness_hm::mt_name "P1"
		set mout_stiffness_hm::force_mag "200"
	}
	
    proc window {} {
	    mout_stiffness_hm::initialize 
		
	    #package require hwt
		catch {destroy ".g_mt_stiffness_w"}
	    set title "Mount Stiffness"
		set recess [frame .g_mt_stiffness_w -padx 7 -pady 7]
		hm_framework addpanel $recess "$title"
		hm_framework drawpanel $recess
		
		set msg [frame $recess.msg]
		pack $msg -side left
		
		set frame1 [frame $msg.frame1]
		hwtk::label $frame1.lab1 -text "Node IDs:"
		hwtk::entry $frame1.ent1 -width 10 -state readonly \
		-textvariable mout_stiffness_hm::node0
		hwtk::entry $frame1.ent2 -width 10 -state readonly \
		-textvariable mout_stiffness_hm::node1
		hwtk::entry $frame1.ent3 -width 10 -state readonly \
		-textvariable mout_stiffness_hm::node2
        hwtk::button $frame1.but -text "Get Node IDs" \
		-command "mout_stiffness_hm::get_node_ids"
        pack $frame1 -side top
		pack $frame1.lab1 $frame1.ent1 $frame1.ent2 $frame1.ent3 $frame1.but\
		-side left -expand 1 -padx 38 -pady 20
		
		set frame2 [frame $msg.frame2]
		hwtk::label $frame2.lab1 -text "Mount Name:"
		hwtk::entry $frame2.ent1 -width 10 -state normal \
		-textvariable mout_stiffness_hm::mt_name
		hwtk::label $frame2.lab2 -text "Force Magnitude:"
		hwtk::entry $frame2.ent2 -width 10 -state normal \
		-textvariable mout_stiffness_hm::force_mag
		hwtk::label $frame2.lab3 -text "Force Component:"
		hwtk::combobox $frame2.ent3 -width 8 -state readonly -values {X Y Z ALL} \
		-textvariable mout_stiffness_hm::force_comp
		hwtk::button $frame2.but -text "Create Loadsteps" \
		-command "mout_stiffness_hm::create_loadstep"
		pack $frame2 -side top
		pack $frame2.lab1 $frame2.ent1 $frame2.lab2 $frame2.ent2 \
		$frame2.lab3 $frame2.ent3 $frame2.but\
		-side left -expand 1 -padx 8
		
		set closebut [frame $recess.cbut]
		hwtk::button $closebut.but -text "Close"\
		-command "hm_exitpanel $recess;destroy $recess"
		hwtk::button $closebut.but2 -text "Out Put Mount Message"\
		-command "mout_stiffness_hm::read_mount_msg"
		pack $closebut -side right
		pack $closebut.but $closebut.but2 -side bottom -pady 20
	}
	
	proc read_mount_msg {} {
	    set types {
			{"CSV Files"		{.csv} }
			{"All files"		*}
	    }
	    set msg_file [tk_getSaveFile -filetypes $types] 
	    *createmarkpanel nodes 1
		set nodeids [hm_getmark nodes 1]
		*clearmark nodes 1
		set msg_fid [open $msg_file w]
		puts -nonewline $msg_fid \
		"Node ID,Systerm ID,Component,Load Step,Load Step ID,Force Magnitude\n"
		foreach nodeid $nodeids {
		    set nodex [hm_getentityvalue nodes $nodeid globalx 0 -byid]
			set nodey [hm_getentityvalue nodes $nodeid globaly 0 -byid]
			set nodez [hm_getentityvalue nodes $nodeid globalz 0 -byid]
		    *createmark systs 1 "by sphere" $nodex $nodey $nodez 0.1 inside 1 1 0
			set syst_id [hm_getmark systs 1]
			*clearmark systs 1
			*createmark loadcols 1 \
			"by sphere" $nodex $nodey $nodez 0.1 inside 1 1 0
			set loadcolids [hm_getmark loadcols 1]
			*clearmark loadcols 1
			foreach loadcolid $loadcolids {
			    set load_name [hm_getcollectorname loadcols $loadcolid]
				set load_component [string index $load_name end]
			    *createmark loadsteps 1 "by name" "$load_name"
				set load_step_id [hm_getmark loadsteps 1]
				*clearmark loadsteps 1
				*createmark loads 1 "by collector id" $loadcolid
				set loadid [hm_getmark loads 1]
				*clearmark loads 1
				set force_magnitude \
				[hm_getentityvalue loads $loadid magnitude 0 -byid]
				puts -nonewline $msg_fid \
		        "$nodeid,$syst_id,$load_component,$load_name,$load_step_id,$force_magnitude\n"
			}
		}
		close $msg_fid
	}
	
	proc create_loadstep {} {
	    set nodeids [list $mout_stiffness_hm::node0 \
		$mout_stiffness_hm::node1 $mout_stiffness_hm::node2]
	    set syst_id [mout_stiffness_hm::create_syscol \
		$mout_stiffness_hm::mt_name $nodeids]
	    if {$mout_stiffness_hm::force_comp == "ALL"} {
		    set load_names [list "$mout_stiffness_hm::mt_name\_X" \
			"$mout_stiffness_hm::mt_name\_Y" "$mout_stiffness_hm::mt_name\_Z"]
			set comps {X Y Z}
			set loopi 0
			foreach load_name $load_names {
			    mout_stiffness_hm::create_load $syst_id\
				$mout_stiffness_hm::node0 $load_name \
				$mout_stiffness_hm::force_mag [lindex $comps $loopi]
				incr loopi
			}
		} else {
		    set load_name "$mout_stiffness_hm::mt_name\_$mout_stiffness_hm::force_comp"
		    mout_stiffness_hm::create_load $syst_id\
			$mout_stiffness_hm::node0 $load_name \
			$mout_stiffness_hm::force_mag $mout_stiffness_hm::force_comp
		}
	}
	
	proc create_load {syst_id nodeid load_name magnitude comp} {
		*collectorcreate loadcols "$load_name" "" 4
		*currentcollector loadcols "$load_name"
		*createmark nodes 1 $nodeid
		switch $comp {
		    X {
			    *loadcreatewithsystemonentity_curve nodes 1 1 1 \
				$magnitude 0 0 $magnitude 0 0 $syst_id 1 0 0 0 0 0	
			}
			Y {
			    *loadcreatewithsystemonentity_curve nodes 1 1 1 \
				0 $magnitude 0 0 $magnitude 0 $syst_id 1 0 0 0 0 0	
			}
			Z {
			    *loadcreatewithsystemonentity_curve nodes 1 1 1 \
				0 0 $magnitude 0 0 $magnitude $syst_id 1 0 0 0 0 0
			}
		}
		*createmark loadcols 1 "by name only" "$load_name"
		set loadcol_id [hm_getmark loadcols 1]
		*clearmark loadcols 1
		*loadstepscreate "$load_name" 1
		*createmark loadsteps 1 "by name only" "$load_name"
		set loadstep_id [hm_getmark loadsteps 1]
		*clearmark loadsteps 1
		*attributeupdateint loadsteps $loadstep_id 4143 1 1 0 1
		*attributeupdateint loadsteps $loadstep_id 4709 1 1 0 1
		*attributeupdateentity loadsteps $loadstep_id 4147 1 1 0 loadcols $loadcol_id
		*attributeupdateint loadsteps $loadstep_id 9224 1 1 0 0
		*attributeupdateint loadsteps $loadstep_id 3800 1 1 0 0
		*attributeupdateint loadsteps $loadstep_id 2396 1 1 0 0
		*attributeupdateint loadsteps $loadstep_id 4059 1 2 0 1
		*attributeupdatestring loadsteps $loadstep_id 4060 1 2 0 "STATICS"
    }
	
	proc create_syscol {name nodeids} {
	    if {[hm_entityinfo exist systcols "$name" -byname] != 1} {
		 	*collectorcreate systcols "$name" "" 11
	    } 
	    *createmark systs 1 "by collector name" "$name"
		set sysid [hm_getmark systs 1]
		*clearmark systs 1
		if {[string length $sysid] == 0} {
		    *currentcollector systcols "$name"
	 	    *createmark nodes 1 [lindex $nodeids 0]
            *systemcreate 1 0 [lindex $nodeids 0] "x" [lindex $nodeids 1] \
		    "xy" [lindex $nodeids 2]
		    *clearmark nodes 1
		    *createmark systs 1 "by collector name" "$name"
		    set sysid [hm_getmark systs 1]
		    *clearmark systs 1
		    *createmark nodes 2 [lindex $nodeids 0]
            *systemsetreference nodes 2 $sysid
            *systemsetanalysis nodes 2 $sysid
		    *clearmark nodes 2
		}
	    return $sysid
	}
	
	proc get_node_ids {} {
	    *createlistpanel nodes 1
		set node_list [hm_getlist nodes 1]
		set mout_stiffness_hm::node0 [lindex $node_list 0]
	    set mout_stiffness_hm::node1 [lindex $node_list 1]
		set mout_stiffness_hm::node2 [lindex $node_list 2]
		*clearlist nodes 1
	}
}

mout_stiffness_hm::window
