proc Error_Window {ErrorType ErrorMessage} {
    tk_messageBox -title "$ErrorType" -message "$ErrorMessage"
}

proc CreateNVHNode {} {
	set types {
	    {"CSV Files"		{.csv}		}
		{"Excel Files"		{.xlsx}		}    
		{"All files"		*}
    }
	set filename [tk_getOpenFile -filetypes $types]
	set tmp [string length $filename]
	if { $tmp == 0 } {
	    Error_Window "Error" "Error: The file is not found!"
		return
	}
	set tmp [split $filename "."]
	if { ( [ lindex $tmp end ] == "csv" ) || ( [ lindex $tmp end] == "CSV" ) } {
	   if { [ catch { set NodeMsgs [ ReadCSV $filename ] } ] } {
	       Error_Window "Error" "Error: The table cannot be used."
           return
	   }
	} else {
	    if { [ catch { set NodeMsgs [ReadExcel $filename] } ] } {
		    Error_Window "Error" "Error: The table cannot be used."
		    return
		}
	}
	*nodecleartempmark 
	set errorpath [file dirname [file nativename "$filename"]]
	set errorfile [file nativename "$errorpath/NVHNodeCreateErrorWaring.log"]
	set errorFID [open $errorfile w]	
	set flag3 0	
	foreach NodeMsg $NodeMsgs {
		set cord [lrange $NodeMsg 0 2]
		set the_id [lindex $NodeMsg 3]
		if { [ catch { set the_id [format %.0f $the_id] } ] || ( $the_id <= 0 )} {
		    set temp [expr [lsearch $NodeMsgs $NodeMsg] + 1]
			puts -nonewline $errorFID \
			"Error: The row $temp Node ID has some problems.\n"
			incr flag3
			continue
		}	
        *createmark nodes 1 "by id only" $the_id 
        set tmp [hm_getmark nodes 1]
        if { [llength $tmp] != 0} {
		    *renumbersolverid nodes 1 6000000 1 0 0 0 0 0
		} 		
		set name [lindex $NodeMsg 4]
		*createmark nodes 1 "by sphere" [lindex $cord 0] [lindex $cord 1] [lindex $cord 2] 0.01 inside 0 1 0
		set nodeid [hm_getmark nodes 1]
		*clearmark nodes 1
		if {[string length $nodeid] != 0} {
			*createmark nodes 1 $nodeid
			*renumbersolverid nodes 1 $the_id 1 0 0 0 0 0
		} else {
            if { [ catch { *createnode [lindex $cord 0] [lindex $cord 1] [lindex $cord 2] 0 0 0 } ] || \
			[ catch { set flag30 [expr [lindex $cord 0] + 0.01] } ] || \
			[ catch { set flag30 [expr [lindex $cord 1] + 0.01] } ] || \
			[ catch { set flag30 [expr [lindex $cord 2] + 0.01] } ] || \
			([string length [lindex $cord 0]] == 0) || \
			([string length [lindex $cord 1]] == 0) || \
			([string length [lindex $cord 2]] == 0) } {
			    set temp [expr [lsearch $NodeMsgs $NodeMsg] + 1]
			    puts -nonewline $errorFID \
            	"Error: The row $temp Coordinate Node has some problems.\n"		    
            	incr flag3 
            	continue
            }
			*createmark nodes 1 "by sphere" [lindex $cord 0] [lindex $cord 1] [lindex $cord 2] 0.01 inside 0 1 0
			*renumbersolverid nodes 1 $the_id 1 0 0 0 0 0
		}
		*clearmark nodes 1
		if { [ catch {*tagcreate nodes $the_id "$the_id<>$name>$the_id" "" 4} ] } {
		    set temp [expr [lsearch $NodeMsgs $NodeMsg] + 1]
			puts -nonewline $errorFID \
			"Error: The row $temp cannot create the tag.\n"		
			incr flag3 
			continue
		}
	}
	close $errorFID
	if {$flag3 != 0} {
	    Error_Window "Error" "Error: There are $flag3 errors in this work.\n Please open the file $errorfile"
	} else {
	    Error_Window "Done" "All Done All Done, Big Crown! "
	}
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
	if {($star > $endd) || ($flag2 == 0)} {
		return NONE
	} else {
		return [string range $str $star $endd]
	}
}

proc ReadCSV {FileName} {
    set values {}
	set temp {}
	set FileChannelID [open [file nativename $FileName] r]
	while {![eof $FileChannelID]} {
	    set line [gets $FileChannelID]
		set temp [split $line ","]
		if {[llength [lindex $temp 0]] <= 0} {
			break;
		}
		lappend values $temp		
	}
	return $values
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

CreateNVHNode