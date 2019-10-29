proc GetWrongComponents_BoltMsg {} {
	set filename [tk_getOpenFile]
	if {[string length $filename] == 0} {
	    return
	}
	set filepath [file dirname [file nativename "$filename"]]
	set outfile [file nativename "$filepath/out.csv"]
	set outwf [file nativename "$filepath/wrong.csv"]
	set ofid1 [open [file nativename "$outfile"] w]
	set ofid2 [open [file nativename "$outwf"] w]
    set arrs [ReadCSV_ACS $filename]
	foreach arr $arrs {
	    set IDs [lindex $arr 3]
		if {[regexp {9.{4}[[:alpha:]].{6}-.+[[:alpha:]]} $IDs] == 1} {
		    regsub -all -- {(\+*)(9.{4}[[:alpha:]].{6}-[[:digit:]]{2}[[:alpha:]]{1})(\+*)} $IDs {\1} new
			if {[string index $new end] == "+"} {
			    set new [string range $new 0 end-1]
			}
			set tmp [join $arr ","]
			puts -nonewline $ofid2 "$tmp,[lsearch $arrs $arr]\n"
		    set arr [lreplace $arr 3 3 $new]
			set tmp [join $arr ","]
			puts -nonewline $ofid1 "$tmp\n"
		} else {
		    set tmp [join $arr ","]
			puts -nonewline $ofid1 "$tmp\n"
		}
	}
	close $ofid1
	close $ofid2
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

catch {GetWrongComponents_BoltMsg}

