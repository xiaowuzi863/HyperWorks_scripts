namespace eval sys_control {
    variable my_location [file normalize [info script]]
    
	proc get_resource_directory {} {
        return [file dirname $sys_control::my_location]
    }
	
}
	

proc CAE_Base_Modeling_Run {str} {
    set filepath [sys_control::get_resource_directory]
    switch $str {
	    CBM_MC {
		    *evaltclscript [file nativename "$filepath/Model_Check_SIH.tcl"]
		}
	    CBM_BB {
		    *evaltclscript [file nativename "$filepath/bluebook_SIH.tcl"]
		}
		CBM_CTCN {
		    *evaltclscript [file nativename "$filepath/ChangeTheCompName_Issue.tcl"]
		}
		CBM_CCFS {
		    *evaltclscript [file nativename "$filepath/CreateCompFromSolids_Issue.tcl"]
		}
		CBM_ACB {
		    *evaltclscript [file nativename "$filepath/AutoCreateBolt_Issue.tcl"]
		}
		CBM_GWC {
		    *evaltclscript [file nativename "$filepath/GetWrongComponents_Issue.tcl"]
		}
		CBM_GTF {
		    *evaltclscript [file nativename "$filepath/GetTheFailCon_Issue.tcl"]
		}
		CBM_ACS {
		    *evaltclscript [file nativename "$filepath/AutoCreateSpot_Issue.tcl"]
		}
		CBM_BCB {
		    *evaltclscript [file nativename "$filepath/BatchCreateBush_Issue.tcl"]
		}
		CBM_CNN {
		    *evaltclscript [file nativename "$filepath/CreateNVHNode_Issue.tcl"]
		}
		CBM_TM {
		    *evaltclscript [file nativename "$filepath/TrimMass_Issue.tcl"]
		}
		CBM_MS {
		    *evaltclscript [file nativename "$filepath/MidSurfExtra_Issue.tcl"]
		}
		CBM_CBT {
		    *evaltclscript [file nativename "$filepath/ClearBoltTable_Issue.tcl"]
		}
	}
}

proc CAE_Base_Modeling_Win {} {
    package require hwt
	set title "SIH CAE Systerm"
	set alltabs [hm_framework getalltabs]
    if {[lsearch $alltabs "$title"] != -1} {
        hm_framework activatetab "$title"
		CAE_BaseModeling_TearDownWin "$title" $recess 
    } 
	catch {destroy $recess}
	set recess [frame .g_CAEBaseModeling -padx 7 -pady 7];
	hm_framework addtab "$title" "$recess"
	
	set frame1 [frame $recess.frame1]
	hwt::AddPadding $frame1 -side left height [hwt::DluHeight 0] width [hwt::DluWidth 4]
    hwt::AddPadding $frame1 -side top height [hwt::DluHeight 4] width [hwt::DluWidth 0]
	set lab1 [hwtk::label $frame1.label -text "FEA Basic Modeling:"]
	set but11 [hwtk::button $frame1.but1 -text "Create Comps From Solids" -command "CAE_Base_Modeling_Run CBM_CCFS"]
	set but12 [hwtk::button $frame1.but2 -text "Mid Surf Extra" -command "CAE_Base_Modeling_Run CBM_MS"]
	set but13 [hwtk::button $frame1.but3 -text "Blue Book" -command "CAE_Base_Modeling_Run CBM_BB"]
	set but14 [hwtk::button $frame1.but4 -text "Change the Comps Name" -command "CAE_Base_Modeling_Run CBM_CTCN"]
	set but15 [hwtk::button $frame1.but5 -text "Model Check and Modify" -command "CAE_Base_Modeling_Run CBM_MC"]
    pack $frame1 -side top -anchor nw -fill x
	pack $lab1 -side top -anchor nw
	pack $but11 $but12 $but13 $but14 $but15 -side top -fill x -padx 1c -pady 1
	
	set frame7 [frame $recess.frame7]
	hwt::AddPadding $frame7 -side left height [hwt::DluHeight 0] width [hwt::DluWidth 4]
    hwt::AddPadding $frame7 -side top height [hwt::DluHeight 4] width [hwt::DluWidth 0]
	set but71 [hwtk::button $frame7.but1 -text "Close" -command "CAE_BaseModeling_TearDownWin \"$title\" $recess"]
    pack $frame7 -side top -anchor nw -fill x
	pack $but71 -side right -fill x -padx 1c -pady 1
	
}



proc CAE_BaseModeling_TearDownWin {title recess} {
    catch {hm_framework removetab "$title"}
    catch {destroy $recess}
}



if { [ catch {CAE_Base_Modeling_Win} ] } {
    catch {
        CAE_BaseModeling_TearDownWin  "SIH CAE Systerm" .g_CAEBaseModeling
	    CAE_Base_Modeling_Win
    }
}


