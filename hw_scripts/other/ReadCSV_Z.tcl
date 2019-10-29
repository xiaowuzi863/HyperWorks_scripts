proc ReadCSV_Z {} {
    set csvfilename [tk_getOpenFile]
	set FileChanelID [open [file nativename $csvfilename] r]
	set csvlists {}
	set fid [open [file nativename "D:/temp/ZYT/hhh.csv"] w]
	while {![eof $FileChanelID]} {
	    set line [gets $FileChanelID]
		set lines [split $line ,]
		lappend csvlists $lines
	}
	set num [llength $csvlists]
	set il 0
	while {$il < $num} {
	    set out {}
		set csvlist [lindex $csvlists $il]
		lappend out [join $csvlist ,]
		for {set jl [expr $il + 1]} {$jl < $num} {incr jl} {
		    set bijiao [lindex $csvlists $jl] 
			if {[lindex $csvlist 1] == [lindex $bijiao 1]} {
			    set tmp [join $bijiao ,]
				lappend out $tmp
			} else {
				break
			}
		}
		set out [join $out ,]
		set il $jl
		puts -nonewline $fid  "$out \n"
	}
    close $fid
}
ReadCSV_Z