proc ClearBoltTable_win {} {
    set w .cbt
	toplevel $w
	wm title $w "Clear Table to Get TB Bolts"
	KeepOnTop $w
	
	set types {
	    {"CSV Files"		{.csv}		}
		{"All Files"		*}
    }
	
	frame $w.biw
	hwtk::label $w.biw.lab1 -text "The Bolts of BIP:"
	hwtk::openfileentry $w.biw.f1 -width 52 -filetypes $types
	pack $w.biw -side top -fill x -padx 1c -pady 1
	pack $w.biw.lab1 $w.biw.f1 -side left -expand 1
	
	frame $w.all
	hwtk::label $w.all.lab1 -text "The Bolts of ALL:"
	hwtk::openfileentry $w.all.f1 -width 52 -filetypes $types
	pack $w.all -side top -fill x -padx 1c -pady 1
	pack $w.all.lab1 $w.all.f1 -side left -expand 1
	
	frame $w.tb
	hwtk::label $w.tb.lab1 -text "The Need TB Bolts:"
	hwtk::savefileentry $w.tb.f1 -width 50 -filetypes $types
	pack $w.tb -side top -fill x -padx 1c -pady 1
	pack $w.tb.lab1 $w.tb.f1 -side left -expand 1
	
	frame $w.r
	hwtk::button $w.r.run -text "Run" -command "ClearBoltTable $w.biw.f1 $w.all.f1 $w.tb.f1"
	hwtk::button $w.r.close -text "Close" -command "destroy $w"
	pack $w.r -side bottom -fill x -padx 1c -pady 1
	pack $w.r.run $w.r.close -side left -expand 1
}

proc ClearBoltTable {A B C} {
    set biwf [$A get]
	set allf [$B get]
	set tbf [$C get]
	if { [catch {set biw_bmsgs [ReadCSV $biwf] } ] } {
	    tk_messageBox -title "Error" -message "Error: The file is not found!" 
		return
	}
    if { [catch {set all_bmsgs [ReadCSV $allf] } ] } {
	    tk_messageBox -title "Error" -message "Error: The file is not found!" 
	    return
	}
	if { [catch {set tbfid [open [file nativename $tbf] w] } ] } {
	    tk_messageBox -title "Error" -message "Error: The file is not found!"
	    return
	}
    foreach all_bmsg $all_bmsgs {
	    set x1 [lindex $all_bmsg 0]
		set y1 [lindex $all_bmsg 1]
		set z1 [lindex $all_bmsg 2]
		set flag 0
		foreach biw_bmsg $biw_bmsgs {
		    set x2 [lindex $biw_bmsg 0]
		    set y2 [lindex $biw_bmsg 1]
		    set z2 [lindex $biw_bmsg 2]
            if { [ catch {set dis [expr sqrt(($x1 - $x2) ** 2 + ($y1 - $y2) ** 2 + \
			($z1 - $z2) ** 2)] } ] } {
			   continue
			}
			if {$dis <= 2} {
			    set flag 1
                break				
			}
		}
		if {$flag == 0} {
		    set tmp [join $all_bmsg ","]
		    puts -nonewline $tbfid "$tmp\n"
		}
	}
    close $tbfid	
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

ClearBoltTable_win
