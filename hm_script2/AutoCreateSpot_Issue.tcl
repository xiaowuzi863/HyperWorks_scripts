proc AutoCreateSpot_win {} {
    set w .autocreatespotw 
	toplevel $w
	wm title $w "Auto Create Spot"
	KeepOnTop $w
	
	set types {
	    {"CSV Files"		{.csv}		}
		{"Excel Files"		{.xlsx}		}
		{"All Files"		*}
    }
	
	frame $w.file
	hwtk::label $w.file.lab2 -text "The Split Mark:"
	hwtk::combobox $w.file.cb1 -width 5 -state normal -values {_ +}
	hwtk::label $w.file.lab1 -text "The SPOT Table:"
	hwtk::openfileentry $w.file.e1 -width 50 -filetypes $types
	pack $w.file -side top -fill x -padx 1c -pady 1
	pack $w.file.lab1 $w.file.e1 $w.file.lab2 $w.file.cb1 -side left -expand 1
	$w.file.cb1 insert 1 +
	
	frame $w.colum 
	hwtk::label $w.colum.lab1 -text "X:"
	hwtk::combobox $w.colum.cb1 -width 3 -state normal -values {A B C D E F G H}
    hwtk::label $w.colum.lab2 -text "Y:"
	hwtk::combobox $w.colum.cb2 -width 3 -state normal -values {A B C D E F G H}
	hwtk::label $w.colum.lab3 -text "Z:"
	hwtk::combobox $w.colum.cb3 -width 3 -state normal -values {A B C D E F G H}
	hwtk::label $w.colum.lab4 -text "ID:"
	hwtk::combobox $w.colum.cb4 -width 3 -state normal -values {A B C D E F G H}
	hwtk::label $w.colum.lab5 -text "Layer:"
	hwtk::combobox $w.colum.cb5 -width 3 -state normal -values {A B C D E F G H}
	pack $w.colum -side top -fill x -padx 1c -pady 1
	pack $w.colum.lab1 $w.colum.cb1 $w.colum.lab2 $w.colum.cb2 $w.colum.lab3 $w.colum.cb3 \
	$w.colum.lab4 $w.colum.cb4 $w.colum.lab5 $w.colum.cb5 -side left -expand 1
	$w.colum.cb1 insert 1 A
	$w.colum.cb2 insert 1 B
	$w.colum.cb3 insert 1 C
	$w.colum.cb4 insert 1 D
	$w.colum.cb5 insert 1 F
	
	frame $w.button
	hwtk::button $w.button.run -text "Run" \
	-command "AutoCreateSpot_Main $w.file.cb1 $w.file.e1 $w.colum.cb1 $w.colum.cb2 \
	$w.colum.cb3 $w.colum.cb4 $w.colum.cb5"
	hwtk::button $w.button.close -text "Close" -command "destroy $w"
	pack $w.button -side bottom -fill x -padx 1c -pady 1
	pack $w.button.run $w.button.close -side left -expand 1
}

proc Error_Window {ErrorType ErrorMessage} {
    tk_messageBox -title "$ErrorType" -message "$ErrorMessage"
}

proc SearchNumID {the_compids} {
    set out {}
	*createmark comps 1 all
	set compids [hm_getmark comps 1]
	foreach ID $the_compids {
        foreach compid $compids {
		    set compname [hm_getcollectorname comps $compid]
			set flag [string match "*$ID*" "$compname"]
			if {$flag == 1} {
			    lappend out $compid
				set tmp [lsearch $compids $compid]
				set compids [lreplace $compids $tmp $tmp]
			}
		}		
	}
	return $out
}

proc AutoCreateSpot_Main {S F xcol ycol zcol idcol layercol} {
    set LetterTmp {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z}
    set filename [$F get]
	set splitmark [$S get]
	set Xcol [$xcol get]
	set Ycol [$ycol get]
	set Zcol [$zcol get]
	set IDcol [$idcol get]
	set Layercol [$layercol get]
	set temp1 [split $filename "."]
	if {[string length $filename] == 0} {
	    Error_Window "Error" "Error: The file is not found!"
		return
	}
	if {[string length $splitmark] == 0} {
	    Error_Window "Error" "Error: The Split Mark is not inputed!"
		return
	}	
	if {([lindex $temp1 end] == "csv") || ([lindex $temp1 end] == "CSV")} {
	    if { [ catch { set SpotMsgs [ReadCSV_ACS $filename] } ] } {
		    Error_Window "Error" "Error: The table cannot be used."
			return
		}
	} else {
	    if { [ catch { set SpotMsgs [ReadExcel_ACS $filename] } ] } {
		    Error_Window "Error" "Error: The table cannot be used."
		    return
		}
	}
	*nodecleartempmark 
	*createmark components 1 "SPOT_Con"
	set temp [hm_getmark components 1]
	if {[llength $temp] != 0} {
		*currentcollector components "SPOT_Con"
	} else {
		*collectorcreateonly components "SPOT_Con" "" 11
		*currentcollector components "SPOT_Con"
	}
	set errorpath [file dirname [file nativename "$filename"]]
	set errorfile [file nativename "$errorpath/SpotCreateErrorWaring.log"]
	set errorFID [open $errorfile w]	
	set flag3 0	
	foreach SpotMsg $SpotMsgs {
		set temp [lindex $SpotMsg [lsearch $LetterTmp $Xcol]]
		set flag [GetNumFromStr $temp]
		set cord [lrange $SpotMsg [lsearch $LetterTmp $Xcol] [lsearch $LetterTmp $Zcol]]
		set temp1 [lindex $SpotMsg [lsearch $LetterTmp $IDcol]]
		set the_compids [split $temp1 "$splitmark"]
		set layer [lindex $SpotMsg [lsearch $LetterTmp $Layercol]]
		if { [ catch { *createnode [lindex $cord 0] [lindex $cord 1] [lindex $cord 2] 0 0 0 } ] || \
		[ catch { set flag30 [expr [lindex $cord 0] + 0.01] } ] || [ catch { set flag30 [expr [lindex $cord 1] + 0.01] } ] || \
		[ catch { set flag30 [expr [lindex $cord 2] + 0.01] } ] || ([string length [lindex $cord 0]] == 0) || \
		([string length [lindex $cord 1]] == 0) || ([string length [lindex $cord 2]] == 0) } {
		    set temp [expr [lsearch $SpotMsgs $SpotMsg] + 1]
		    puts -nonewline $errorFID \
			"Error: The row $temp Coordinate Node has some problems.\n"
			incr flag3
			continue
		}
		*createmark connectors 1 "by sphere" [lindex $cord 0] [lindex $cord 1] [lindex $cord 2] 1 inside 0 1 0
		set test_conids [hm_getmark connectors 1]
		set flag_type [llength $test_conids]
		if {$flag_type != 0} {
		    set temp [expr [lsearch $SpotMsgs $SpotMsg] + 1]
			puts -nonewline $errorFID \
			"Error: The row $temp spot was existent.\n"
			incr flag3
			continue
		}
		*createmark nodes 1 "by sphere" [lindex $cord 0] [lindex $cord 1] [lindex $cord 2] 0.01 inside 0 1 0
		set nodeid [hm_getmark nodes 1]
		if { [ catch {set numid [SearchNumID $the_compids] } ] } {
		    set temp [expr [lsearch $SpotMsgs $SpotMsg] + 1]
			puts -nonewline $errorFID \
			"Error: The row $temp cannot Search the component.\n"
			incr flag3
			continue		
		}
		if { [ catch { CreateSpot $nodeid $numid $layer } ] } {
		    set temp [expr [lsearch $SpotMsgs $SpotMsg] + 1]
			puts -nonewline $errorFID \
			"Error: The row $temp cannot create the spot. Please check the model and the table.\n"
			incr flag3
			continue		
		}
	}
	*nodecleartempmark 
	close $errorFID
	if {$flag3 != 0} {
	    Error_Window "Error" "Error: There are $flag3 errors in this work.\n Please open the file $errorfile"
	} else {
	    Error_Window "Done" "All Done All Done, Big Crown! "
	}	
}

proc JudgeElementType { Type elemids } {
    set flag 0
	foreach elemid $elemids {
	    if { [ hm_getentityvalue elements $elemid typename 1 -byid ] == "$Type" } {
		    incr flag
		}
	}
	return $flag
}

proc ReadExcel_ACS {FileName} {
	set value {}
	set temp {}
	package require twapi
	set app [twapi::comobj "Excel.Application"]
	$app DisplayAlerts True
	set Workbooks [$app Workbooks]
	set workbook [$Workbooks Open [file nativename $FileName]]
	set sheets [$workbook Sheets]
	set sheet [$sheets Item 1]
	set cell_1 [$sheet Cells]
	set il 0
	while {($il == 0)||([llength [lindex $temp 0]] > 0)} {
		incr il
		set temp [[$cell_1 Range A$il F$il] Value2]
		lappend value $temp
	}
	$workbook Save
	$app DisplayAlerts False
	$app Quit
	$app destroy
	return [lrange $value 0 end-1]
}

proc ReadCSV_ACS {csvfile} {
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
	return $values
}

proc GetNumFromStr {str} {
	set strlength [string length $str]
	set flag1 0
	set flag2 0
	set star 0
	set endd 0
	for {set il 0} {$il < $strlength} {incr il} {
		set a [string index $str $il]
		if {($a >= 0) && ($a <= 9) && ($flag1 == 0)} {
			set star $il
			incr flag1
		} 
		if {(($a < 0) || ($a > 9)) && ($flag1 == 0)} {
			continue 
		} 
		if {(($a < 0) || ($a > 9)) && ($flag1 > 0)} {
			set endd [expr $il - 1]
			incr flag2
			break 
		}
	}
	if {($flag2 == 0)&&($flag1 == 0)} {
		return NONE
	} elseif {($flag2 == 0)&&($flag1 != 0)} {
	    return [string range $str $star end]
	} else {
		return [string range $str $star $endd]
	}
}

proc CreateSpot {nodeid compids layer} {
	*CE_GlobalSetInt "g_ce_spotvis" 1
	*CE_GlobalSetInt "g_ce_seamvis" 0
	*CE_GlobalSetInt "g_ce_areavis" 0
	*CE_GlobalSetInt "g_ce_boltvis" 0
	*CE_GlobalSetInt "g_ce_applymassvis" 0
	*plot 
	*createmark nodes 1 $nodeid 
	eval *createmark components 2 "by id only" $compids	 
	*createstringarray 28 "link_elems_geom=elems" "link_rule=now" "link_rule=now" \
	  "relink_rule=none" "tol_flag=1" "tol=20.000000" "ce_normal_link=0" "ce_nonnormal=0" \
	  "ce_fedepth=1.000000" "ce_fewidth=1.000000" "ce_systems=0" "num_node_flag=0" \
	  "num_node=3" "ce_fe_vector=0" "ce_coarse_mesh=3" "ce_connectivity=2" "ce_dir_assign=0" \
	  "ce_prop_opt=0" "ce_fe_density=1" "ce_fe_thck_flag=3" "ce_fe_acm_numhexa=1" \
	  "ce_fe_proj_hexa_face=0" "ce_diameter=6.000000" "ce_quad_size=0.000000" "ce_extralinknum=0" \
	  "ce_hexaoffsetcheck=1" "ce_bl_connection_ang=10.000000" "ce_lt_connection_ang=60.000000"
	*CE_ConnectorCreateByMarkAndRealizeWithDetails nodes 1 "spot" $layer components 2 "nastran" 1001 71 20 1 28
}

AutoCreateSpot_win