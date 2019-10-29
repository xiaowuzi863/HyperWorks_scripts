proc CAE_Base_Modeling_Win {} {
    package require hwt
	set title BaseModeling
	set alltabs [hm_framework getalltabs]
    if {[lsearch $alltabs $title] != -1} {
        hm_framework activatetab "$title"
		CAE_BaseModeling_TearDownWin $title $recess 
    } 
	catch {destroy $recess}
	set recess [frame .g_CAEBaseModeling -padx 7 -pady 7];
	hm_framework addtab "$title" "$recess"
	
	set frame1 [frame $recess.frame1]
	hwt::AddPadding $frame1 -side left height [hwt::DluHeight 0] width [hwt::DluWidth 4]
    hwt::AddPadding $frame1 -side top height [hwt::DluHeight 4] width [hwt::DluWidth 0]
	set lab1 [hwtk::label $frame1.label -text "Blue Book & Standard Name:"]
	set but11 [hwtk::button $frame1.but1 -text "Blue Book" -command "CAE_Base_Modeling_Run CBM_BB"]
	set but12 [hwtk::button $frame1.but2 -text "Change the Comps Name" -command "CAE_Base_Modeling_Run CBM_CTCN"]
	set but13 [hwtk::button $frame1.but3 -text "Create Comps From Solids" -command "CAE_Base_Modeling_Run CBM_CCFS"]
	set but14 [hwtk::button $frame1.but4 -text "Mid Surf Extra" -command "CAE_Base_Modeling_Run CBM_MS"]
    pack $frame1 -side top -anchor nw -fill x
	pack $lab1 -side top -anchor nw
	pack $but11 $but12 $but13 $but14 -side top -fill x -padx 1c -pady 1
	
	set frame2 [frame $recess.frame2]
	hwt::AddPadding $frame2 -side left height [hwt::DluHeight 0] width [hwt::DluWidth 4]
    hwt::AddPadding $frame2 -side top height [hwt::DluHeight 4] width [hwt::DluWidth 0]
	set lab21 [hwtk::label $frame2.label -text "Batch Spots:"]
	set but21 [hwtk::button $frame2.but1 -text "Auto Create Spots" -command "CAE_Base_Modeling_Run CBM_ACS"]
	set but22 [hwtk::button $frame2.but2 -text "Check the Comps in Table" -command "CAE_Base_Modeling_Run CBM_GWC"]
	set but23 [hwtk::button $frame2.but3 -text "Get the Fail Connectors" -command "CAE_Base_Modeling_Run CBM_GTF"]
    pack $frame2 -side top -anchor nw -fill x
	pack $lab21 -side top -anchor nw
	pack $but21 $but22 $but23 -side top -fill x -padx 1c -pady 1
	
	set frame3 [frame $recess.frame3]
	hwt::AddPadding $frame3 -side left height [hwt::DluHeight 0] width [hwt::DluWidth 4]
    hwt::AddPadding $frame3 -side top height [hwt::DluHeight 4] width [hwt::DluWidth 0]
	set lab31 [hwtk::label $frame3.label -text "Batch Bolts:"]
	set but31 [hwtk::button $frame3.but1 -text "Auto Create Bolts" -command "CAE_Base_Modeling_Run CBM_ACB"]
	set but34 [hwtk::button $frame3.but4 -text "Clear Bolts Table" -command "CAE_Base_Modeling_Run CBM_CBT"]
	set but32 [hwtk::button $frame3.but2 -text "Check the Comps in Table" -command "CAE_Base_Modeling_Run CBM_GWC"]
	set but33 [hwtk::button $frame3.but3 -text "Get the Fail Connectors" -command "CAE_Base_Modeling_Run CBM_GTF"]
    pack $frame3 -side top -anchor nw -fill x
	pack $lab31 -side top -anchor nw
	pack $but31 $but34 $but32 $but33 -side top -fill x -padx 1c -pady 1
	
	set frame4 [frame $recess.frame4]
	hwt::AddPadding $frame4 -side left height [hwt::DluHeight 0] width [hwt::DluWidth 4]
    hwt::AddPadding $frame4 -side top height [hwt::DluHeight 4] width [hwt::DluWidth 0]
	set lab41 [hwtk::label $frame4.label -text "Batch Spring Elems:"]
	set but41 [hwtk::button $frame4.but1 -text "Batch Bumper & Latch" -command "CAE_Base_Modeling_Run CBM_BCB"]
    pack $frame4 -side top -anchor nw -fill x
	pack $lab41 -side top -anchor nw
	pack $but41 -side top -fill x -padx 1c -pady 1
	
	set frame5 [frame $recess.frame5]
	hwt::AddPadding $frame5 -side left height [hwt::DluHeight 0] width [hwt::DluWidth 4]
    hwt::AddPadding $frame5 -side top height [hwt::DluHeight 4] width [hwt::DluWidth 0]
	set lab51 [hwtk::label $frame5.label -text "NVH Nodes:"]
	set but51 [hwtk::button $frame5.but1 -text "Create NVH Nodes" -command "CAE_Base_Modeling_Run CBM_CNN"]
    pack $frame5 -side top -anchor nw -fill x
	pack $lab51 -side top -anchor nw
	pack $but51 -side top -fill x -padx 1c -pady 1
	
	set frame6 [frame $recess.frame6]
	hwt::AddPadding $frame6 -side left height [hwt::DluHeight 0] width [hwt::DluWidth 4]
    hwt::AddPadding $frame6 -side top height [hwt::DluHeight 4] width [hwt::DluWidth 0]
	set lab61 [hwtk::label $frame6.label -text "Trim Mass:"]
	set but61 [hwtk::button $frame6.but1 -text "Create Trimmed Mass" -command "CAE_Base_Modeling_Run CBM_TM"]
    pack $frame6 -side top -anchor nw -fill x
	pack $lab61 -side top -anchor nw
	pack $but61 -side top -fill x -padx 1c -pady 1
	
	set frame7 [frame $recess.frame7]
	hwt::AddPadding $frame7 -side left height [hwt::DluHeight 0] width [hwt::DluWidth 4]
    hwt::AddPadding $frame7 -side top height [hwt::DluHeight 4] width [hwt::DluWidth 0]
	set but71 [hwtk::button $frame7.but1 -text "Close" -command "CAE_BaseModeling_TearDownWin $title $recess"]
    pack $frame7 -side top -anchor nw -fill x
	pack $but71 -side right -fill x -padx 1c -pady 1
}

proc CAE_BaseModeling_TearDownWin {title recess} {
    catch {hm_framework removetab "$title"}
    catch {destroy $recess}
}

proc CAE_Base_Modeling_Run {str} {
    set filepath "E:/tcl/tcl_batch/Issue"
    switch $str {
	    CBM_BB {
		    *evaltclscript [file nativename "$filepath/bluebook_Issue.tcl"]
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

if { [ catch {CAE_Base_Modeling_Win} ] } {
    catch {
        CAE_BaseModeling_TearDownWin BaseModeling .g_CAEBaseModeling
	    CAE_Base_Modeling_Win
    }
}