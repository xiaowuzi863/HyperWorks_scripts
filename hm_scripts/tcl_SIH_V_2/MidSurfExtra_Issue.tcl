proc MidSurfExtra {} {
    *createmarkpanel comps 1
	set compids [hm_getmark comps 1];
	*clearmark comps 1
	set erMsg {}
	foreach compid $compids {
	    if {[hm_entityinfo exist comps "Middle Surface" -byname]} {
		    *createmark comps 1 "by name only" "Middle Surface"
			*deletemark comps 1
		}
	    *createmark solids 1 "by comp id" $compid
		set compname [hm_getcollectorname comps $compid]
		set solidids [hm_getmark solids 1]
		*clearmark solids 1 
		if { [llength $solidids] == 0} {
		    lappend erMsg "The component $compname has no solid.\n"
			continue
		}
		set volum 0
		foreach solidid $solidids {
		    set tmp [hm_getvolumeofsolid solids $solidid]
			set volum [expr $volum + $tmp]
		}
		eval *createmark solids 1 $solidids
        if {[catch {*midsurface_extract_10 solids 1 3 0 1 1 0 0 20 0 \
		0 10 0 10 -2 undefined 0 0 1}]} {
		    lappend erMsg "The component $compname cant extra mid surface.\n"
			continue
		}
		if {[hm_entityinfo exist comps "$compname .ms" -byname] } {
		    lappend erMsg "The component $compname has been extra mid surface.\n"
			continue
	    } elseif {[hm_entityinfo exist comps "Middle Surface" -byname] == 0} {
		    lappend erMsg "The component $compname cant extra mid surface.\n"
			continue
		} else {
		    *renamecollector components "Middle Surface" "$compname .ms"
		}
		*createmark surfs 1 "by comp name" "$compname .ms"
        set surfids [hm_getmark surfs 1]
		*clearmark surfs 1
        if { [llength $surfids] == 0} {
		    lappend erMsg "The component $compname cant extra mid surface.\n"
			continue
		}
		set area 0
        foreach surfid $surfids {
		    set tmp [hm_getareaofsurface surfs $surfid]
			set area [expr $area + $tmp]
		}
		set area [expr $area * 1.0]
        set tmp [expr $volum / $area]
        set T [format %.1f $tmp]
        Prop_2D_Create "$compname .ms" " " $T
        *createmark components 1 "by name only" "$compname .ms"
        *propertyupdate components 1 "$compname .ms"
        *clearmark components 1		
	}
	set tmp [join $erMsg ""]
	if {[llength $erMsg] != 0} {
    	tk_messageBox -title "Done" -message "$tmp"
	} else {
	    tk_messageBox -title "Done" -message "All Done, All Done. Big Crown!"
	}
}

proc Prop_2D_Create {compname matname T} {
   if {[hm_entityinfo exist props $compname -byname] == 1} {
		*createmark props 1 "by name only" "$compname"
		*deletemark props 1
		#判断是否存在
   } 
	*collectorcreate properties "$compname" "$matname" 11
	*createmark properties 2 "$compname"
	set propid [hm_getmark properties 2]
	*dictionaryload properties 2 "[file normalize [hm_info exporttemplate]]" "PSHELL"
	*attributeupdatedouble properties $propid 95 1 1 0 $T
}

MidSurfExtra