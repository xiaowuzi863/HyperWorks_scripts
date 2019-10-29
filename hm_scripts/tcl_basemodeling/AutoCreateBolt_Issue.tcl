proc AutoCreateBolt_win {} {
    set w .autocreatebolt
	toplevel $w
	wm title $w "Auto Create Bolts"
	KeepOnTop $w
	
	set types {
	    {"CSV Files"		{.csv}		}
		{"Excel Files"		{.xlsx}		}
		{"All Files"		*}
    }
	
	frame $w.file
	hwtk::label $w.file.lab2 -text "The Split Mark:"
	hwtk::combobox $w.file.cb1 -width 5 -state normal -values {_ +}
	hwtk::label $w.file.lab1 -text "The Bolt Table:"
	hwtk::openfileentry $w.file.e1 -width 50 -filetypes $types
	pack $w.file -side top -fill x -padx 1c -pady 1
	pack $w.file.lab1 $w.file.e1 $w.file.lab2 $w.file.cb1 -side left -expand 1
	$w.file.cb1 insert 1 +
	
	frame $w.button
	hwtk::button $w.button.run -text "Run" -command "AutoCreateBolt $w.file.cb1 $w.file.e1"
	hwtk::button $w.button.close -text "Close" -command "destroy $w"
	pack $w.button -side bottom -fill x -padx 1c -pady 1
	pack $w.button.run $w.button.close -side left -expand 1
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

proc AutoCreateBolt {S F} {
	set filename [$F get]
	set splitmark [$S get]
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
	    if { [ catch { set BoltMsgs [ReadCSV $filename] } ] } {
		    Error_Window "Error" "Error: The table cannot be used."
		    return
		}
	} else {
	    if { [ catch { set BoltMsgs [ReadExcel $filename] } ] } {
		    Error_Window "Error" "Error: The table cannot be used."
		    return
		}
	}
	*nodecleartempmark 
	*createmark components 1 "BOLT_Con"
	set temp [hm_getmark components 1]
	if {[llength $temp] != 0} {
		*currentcollector components "BOLT_Con"
	} else {
		*collectorcreateonly components "BOLT_Con" "" 11
		*currentcollector components "BOLT_Con"
	}
	set errorpath [file dirname [file nativename "$filename"]]
	set errorfile [file nativename "$errorpath/BoltCreateErrorWaring.log"]
	set errorFID [open $errorfile w]	
	set flag3 0
	foreach BoltMsg $BoltMsgs {
		set temp [lindex $BoltMsg 0]
		set flag [GetNumFromStr $temp]	
		if {($flag == "NONE")} {
			continue
		}
		set cord [lrange $BoltMsg 0 2]
		set temp1 [lindex $BoltMsg 3]
		set the_compids [split $temp1 "$splitmark"]
		if {[llength $the_compids] == [llength $temp1]} {
		    set temp [expr [lsearch $BoltMsgs $BoltMsg] + 1]
		    puts -nonewline $errorFID \
		    "Error: The Split Mark cannot split the row $temp column 4 components.\n"
		    incr flag3
		    continue			
		}
		if { [ catch { set boltlength [expr [lindex $BoltMsg 4] ] } ] } {
			set temp [expr [lsearch $BoltMsgs $BoltMsg] + 1]
			puts -nonewline $errorFID \
			"Error: The row $temp column 5 Bolt Length has some problems.\n"
			incr flag3
            continue			
		}
		if { [ catch { *createnode [lindex $cord 0] [lindex $cord 1] [lindex $cord 2] 0 0 0 } ] || \
		[ catch { set flag30 [expr [lindex $cord 0] + 0.01] } ] || [ catch { set flag30 [expr [lindex $cord 1] + 0.01] } ] || \
		[ catch { set flag30 [expr [lindex $cord 2] + 0.01] } ] || ([string length [lindex $cord 0]] == 0) || \
		([string length [lindex $cord 1]] == 0) || ([string length [lindex $cord 2]] == 0) } {
		    set temp [expr [lsearch $BoltMsgs $BoltMsg] + 1]
            puts -nonewline $errorFID \
			"Error: The row $temp Coordinate Node has some problems.\n"
			incr flag3 
			continue
		}
		*createmark elements 1 "by sphere" [lindex $cord 0] [lindex $cord 1] [lindex $cord 2] 5 inside 0 1 0
		set test_elemids [hm_getmark elements 1]
		set flag_type [JudgeElementType "RBE2" $test_elemids]
		if {$flag_type != 0} {
		    set temp [expr [lsearch $BoltMsgs $BoltMsg] + 1]
			puts -nonewline $errorFID \
			"Error: The row $temp bolt was existent.\n"
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
		if { [ catch { CreateBolt_WOLayer $nodeid $numid $boltlength } ] } {
		    set temp [expr [lsearch $BoltMsgs $BoltMsg] + 1]
			puts -nonewline $errorFID \
			"Error: The row $temp cannot create the bolt. Please check the model and the table.\n"
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

proc CreateBolt_WOLayer {nodeid the_compids boltlength} {
    *createmark nodes 1 $nodeid
	eval *createmark components 2 "by id only" $the_compids
    set boltlength [expr $boltlength * 1.0]
    *createstringarray 21 "link_elems_geom=elems" "link_rule=now" "relink_rule=none" \
    "tol_flag=1" "tol=$boltlength" "ce_dir_assign=0" "ce_prop_opt=1" "ce_propertyid=0" \
    "ce_notuseijk=1" "ce_boltmindiameter=0.000000" "ce_boltmaxdiameter=50.000000" \
    "ce_boltminfeatureangle=20.000000" "ce_boltmaxfeatureangle=80.000000" "ce_boltthread=1.000000" \
    "ce_cylinder_diameter_factor =1.500000" "ce_washer_num=0" "ce_washer_elem_num=-1" \
    "ce_hole_option=0" "ce_fill_hole=0" "ce_systems=0" "ce_nonnormal=1"
    *CE_ConnectorCreateByMarkAndRealizeWithDetails nodes 1 "bolt" 4294967295 components 2 "nastran" 1001 55 35 1 21	
}

proc CreateBolt {nodeid the_compids boltlength layer} {
	*createmark nodes 1 $nodeid
	eval *createmark components 2 "by id only" $the_compids
	*createstringarray 21 "link_elems_geom=elems" "link_rule=now" "relink_rule=none" \
	  "tol_flag=1" "tol=$boltlength" "ce_dir_assign=0" "ce_prop_opt=1" "ce_propertyid=0" \
	  "ce_notuseijk=1" "ce_boltmindiameter=0.000000" "ce_boltmaxdiameter=50.000000" \
	  "ce_boltminfeatureangle=20.000000" "ce_boltmaxfeatureangle=80.000000" "ce_boltthread=1.000000" \
	  "ce_cylinder_diameter_factor =1.500000" "ce_washer_num=0" "ce_washer_elem_num=-1" \
	  "ce_hole_option=0" "ce_fill_hole=0" "ce_systems=0" "ce_nonnormal=1"
	*CE_ConnectorCreateByMarkAndRealizeWithDetails nodes 1 "bolt" $layer components 2 "nastran" 1001 55 20 1 21
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

proc ReadExcel {FileName} {
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
		set temp [[$cell_1 Range A$il E$il] Value2]
		lappend value $temp
	}
	$workbook Save
	$app DisplayAlerts False
	$app Quit
	$app destroy
	return [lrange $value 0 end-1]
}

proc ReadCSV {csvfile} {
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

proc Error_Window {ErrorType ErrorMessage} {
    tk_messageBox -title "$ErrorType" -message "$ErrorMessage"
}

AutoCreateBolt_win