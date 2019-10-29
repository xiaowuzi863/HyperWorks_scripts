proc CreateCompFromSolids {} {
    *createmarkpanel comps 1
    set compids [hm_getmark comps 1]
	*clearmark comps 1
	foreach compid $compids {
	    *createmark solids 1 "by comp id" $compid
        set solidids [hm_getmark solids 1]
        *clearmark solids 1
		set tmp [llength $solidids]
        if {$tmp > 1} {
		    set compname [hm_getcollectorname comps $compid]
			set il 1
 		    foreach solidid $solidids {
			    catch {*collectorcreateonly components "$compname-$il" "" [format %.0f [expr 2+rand()*62]]}
				*currentcollector components "$compname-$il"
				*createmark solids 1 $solidid
                *movemark solids 1 "$compname-$il"
				incr il
			}
		}		
	}
}
CreateCompFromSolids
