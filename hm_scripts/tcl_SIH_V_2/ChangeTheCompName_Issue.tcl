proc ChangeTheCompName {} {
    set w .ctcn
	toplevel $w
	wm title $w "Change the Comps Name"
	KeepOnTop $w
	
	frame $w.sel
	hwtk::label $w.sel.lab1 -text "Replace "
	hwtk::combobox $w.sel.cb1 -width 6 -state readonly -values {props comps mats}
	hwtk::label $w.sel.lab2 -text "' separator "
	hwtk::combobox $w.sel.cb2 -width 2 -state normal -values {- . _ +}
	hwtk::label $w.sel.lab3 -text " with "
	hwtk::combobox $w.sel.cb3 -width 2 -state normal -values {- . _ +}
	pack $w.sel -side top -fill x
	pack $w.sel.lab1 $w.sel.cb1 $w.sel.lab2 $w.sel.cb2 $w.sel.lab3 $w.sel.cb3 \
    -side left -expand 1
	
	frame $w.b
	hwtk::button $w.b.b1 -text "Run" -command "CTCN_Run $w.sel.cb1 $w.sel.cb2 $w.sel.cb3"
	hwtk::button $w.b.b2 -text "Close" -command "destroy $w"
	pack $w.b -side top -fill x
	pack $w.b.b1 $w.b.b2 -side left -expand 1
}

proc CTCN_Run {cb1 cb2 cb3} {
    set entitytype [$cb1 get]
	set ormark [$cb2 get]
	set newmark [$cb3 get]
    *createmarkpanel $entitytype 1 
	set compids [hm_getmark $entitytype 1]
	*clearmark $entitytype 1
	foreach compid $compids {
	    set compname [hm_getcollectorname $entitytype $compid]  
		if {[regexp -- "\\$ormark" $compname] == 1} {
		    regsub -all -- "\\$ormark" $compname "$newmark" newname
			*renamecollector $entitytype "$compname" "$newname"
		}
	}
}

ChangeTheCompName 
