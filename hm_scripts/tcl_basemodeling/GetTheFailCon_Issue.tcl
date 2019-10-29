proc GetTheFailCon {} {
    set types {
	    {"CSV Files"		{.csv}		}
		{"All Files"		*}
    }
    set filename [tk_getSaveFile -filetypes $types]
	if {[string length $filename] == 0} {
	    return
	}
	set fid [open [file nativename $filename] w]
    *createmarkpanel connectors 1
	set conids [hm_getmark connectors 1]
	puts -nonewline $fid "Connector ID,X,Y,Z,Components\n"
	foreach conid $conids {
	    set tmp [hm_ce_info $conid state]
		if {"$tmp" != "failed"} {
	        continue
	    }
	    set cord [hm_ce_getcords $conid]
		set linknum [hm_ce_info $conid numlinks]
		set compnames {}
		for {set il 0} {$il < $linknum} {incr il} {
		    set tmp [hm_ce_getlinkinfo $conid $il]
			set compid [lindex $tmp 1]
			set compname [hm_getcollectorname comps $compid];
			lappend compnames $compname
		}
		set outcomp [join $compnames ","]
		puts -nonewline $fid "$conid,[lindex $cord 0],[lindex $cord 1],[lindex $cord 2],$outcomp\n"
	}
	close $fid
	*clearmark connectors 1
}
catch {GetTheFailCon}

