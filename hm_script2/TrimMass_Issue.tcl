proc TrimmassMain { } {
	set w .trimmass;
	toplevel $w; 
	wm title $w "Create TrimMass";
	KeepOnTop $w
	
    set types {
	    {"CSV files"		{.csv}	}
		{"EXCEL files"		{.xlsx}	}
		{"All files"		*}
    }
	
	#createwindow
	frame $w.buttons
	pack $w.buttons -side bottom -fill x -padx 1c -pady 1
	hwtk::button $w.buttons.dismiss -text "Close" -command "destroy $w"
	hwtk::button $w.buttons.run -text "Run" -command "TrimMass $w.file.ent $w.ent.ent1 $w.ent.com"
	pack $w.buttons.run $w.buttons.dismiss -side left -expand 1

	frame $w.file
		hwtk::label $w.file.lab -text "Select a CSVfile to open: "
		hwtk::openfileentry  $w.file.ent -filetypes $types -width 50
		pack $w.file.lab -side left
		pack $w.file.ent -side left -expand yes -fill x
		pack $w.file -fill x -padx 1c -pady 3
		
	frame $w.ent
	hwtk::label $w.ent.lab -text "Input the tolerance of RBE2 : \n Input just like: 3.5"
	hwtk::entry $w.ent.ent1 -width 20
	hwtk::label $w.ent.lab2 -text "Unit:"
	hwtk::combobox $w.ent.com -width 6 -state readonly -values {T kg}
	pack $w.ent -fill x -padx 1c -pady 2
	pack $w.ent.lab -side left
	pack $w.ent.ent1 -side left -expand yes -fill x
	pack $w.ent.lab2 -side left -expand 1
	pack $w.ent.com -side left -expand yes -fill x
	$w.ent.ent1 insert 0 "3.5"
}

proc CreateRBE2withMount {nodeid wcha} {
	set Radius 50 ;
	set nwcha [expr $wcha*-1];
	set atxval [hm_getentityvalue nodes $nodeid "x" 0];
	set atyval [hm_getentityvalue nodes $nodeid "y" 0];
	set atzval [hm_getentityvalue nodes $nodeid "z" 0];
	*createmark nodes 2 "by sphere" $atxval $atyval $atzval $Radius inside 0 0 0;
	set nodeid2 [hm_getmark nodes 2]
	set numnode2 [llength $nodeid2]
	if {$numnode2 == 0} {
		return ;
	}
	*clearmark nodes 2;
	set kkk 0;
	for {set il 0} {$il < $numnode2} {incr il} {
		set nnid2 [lindex $nodeid2 $il]; 
		set flagdistance [ hm_getdistance nodes $nodeid $nnid2 0] ;
		set nodedistance [lindex $flagdistance 0];
		if {$nnid2 == $nodeid } {
			continue;
		}
		if {$kkk == 0} {
			set min $nodedistance
			set nnid3 $nnid2
			set kkk 1
		}
		if {($kkk == 1)&&($nodedistance < $min)} {
			set min $nodedistance ;
			set nnid3 $nnid2 ;
		}
	}
	if {$min > 0.1} {
		set labelnodedis2 [hm_getdistance nodes $nnid3 $nodeid 0];
		set labelnodedis [lindex $labelnodedis2 0];
		set kkk 0;
		set nodeid3 [list $nnid3];
		for {set il 0} {$il < $numnode2} {incr il} {
			set nnid2 [lindex $nodeid2 $il]; 
			set flagdistance [ hm_getdistance nodes $nodeid $nnid2 0] ;
			set nodedistance [lindex $flagdistance 0];
			set cha [expr $nodedistance-$labelnodedis];
			if {($nnid2 == $nnid3 )||($nnid2 == $nodeid)||($nnid3 == $nodeid)} {
				continue ;
			}
			if {($cha < $wcha)&&($cha > $nwcha)} {
				incr kkk;
				lappend nodeid3 $nnid2
			}
		}
		eval *createmark nodes 2 $nodeid3;
		*rigidlink $nodeid 2 123456 
		*clearmark nodes 2
	}
}

proc CreateRBE3withNode {gracenter nodeids} {
	set numnode [llength $nodeids]
	for {set il 0} {$il < $numnode} {incr il} {
		if {$il == 0} {
			set nodeflag123 [list 123]
			set nodeflag111 [list 1];
		} else {
			lappend nodeflag123 123
			lappend nodeflag111 1
		}
	}
	eval *createmark nodes 1 $nodeids;
	eval *createarray $numnode $nodeflag123;
	eval *createdoublearray $numnode $nodeflag111
	*rbe3 1 1 $numnode 1 $numnode $gracenter 123456 0 
	*clearmark nodes 1
}

proc DirectMass {mass nodeids} {
	set numnode [llength $nodeids]
	eval *createmark nodes 1 $nodeids;
	set mass2 [expr $mass/$numnode]
	*masselement 1 $mass2 "" 0
	*clearmark nodes 1
}

proc Error_Window {ErrorType ErrorMessage} {
    tk_messageBox -title "$ErrorType" -message "$ErrorMessage"
}

proc TrimMass {fileway wwcha U} {
	*nodecleartempmark 
	set csvfile [$fileway get];
	set wcha [$wwcha get];
	set Unit [$U get];
	if {[string length "$wcha"] ==0} {
		set wcha 3.5
	}
	set csvfilelength [string length "$csvfile"];
	if {$csvfilelength ==0} {
		Error_Window "Error" "Error: The file is not found!"
		return ;
	}
	set temp1 [split $csvfile "."]
	if {([lindex $temp1 end] == "csv") || ([lindex $temp1 end] == "CSV")} {
		if {[catch { set ArrFromCSV [ReadCSV $csvfile] } ]} {
		    Error_Window "Error" "Error: The table can not be used!"
			return
		}
	} else {
	    if { [ catch { set ArrFromCSV [ReadExcel $csvfile] } ] } {
            Error_Window "Error" "Error: The table can not be used!"
		    return
		}
	}
	if {[string length $Unit] == 0} {
		Error_Window "Error" "Error: The Unit is not inputed!"
	    return 
	}	
	switch $Unit {
		T {
			set wtmass 0.001
		}
		kg {
			set wtmass 1
		}
	}
	set flag1 0
	set errorpath [file dirname [file nativename "$csvfile"]]
	set errorfile [file nativename "$errorpath/TrimMassErrorWaring.log"]
	set errorFID [open $errorfile w]
	set flag_er_comps {}
	set flag3 0
	set Compids    {}
	set Granodeids {}
	set masses     {}
	set attypes    {}
	for {set il 0} {$il < [llength $ArrFromCSV]} {incr il} {
		set Compname [lindex $ArrFromCSV $il 0]
		*createmark comps 1 "$Compname"
		set Compid [hm_getmark comps 1]
		set numComp [llength $Compid]
		if {(($numComp == 0) || ([lsearch $Compids $Compid] == -1) )&& ([lsearch $flag_er_comps $Compname] == -1)} {
			if { [catch {*collectorcreateonly components "$Compname" "" 5 } ] } {
			    puts -nonewline $errorFID \
				"Error: The Comps Name $Compname was exist in the model.\n"
				incr flag3 
				continue
			}
			*createmark comps 1 "$Compname"
			set Compid [hm_getmark comps 1]
			*clearmark comps 1
			set mass [lindex $ArrFromCSV $il 1]
			set attachtype [lindex $ArrFromCSV $il 2]
			set CGX [lindex $ArrFromCSV $il 3]
			set CGY [lindex $ArrFromCSV $il 4]
			set CGZ [lindex $ArrFromCSV $il 5]
			if { ( [ catch { *createnode $CGX $CGY $CGZ 0 0 0 } ] || [ catch { set flag30 [expr $CGX + 0.01] } ] || \
			[ catch { set flag30 [expr $CGY + 0.01] } ] || [ catch { set flag30 [expr $CGZ + 0.01] } ] || \
			([string length [lindex $ArrFromCSV $il 3]] == 0) || ([string length [lindex $ArrFromCSV $il 4]] == 0) || \
			([string length [lindex $ArrFromCSV $il 5]] == 0)) && ([lsearch $flag_er_comps $Compname] == -1) } {
                puts -nonewline $errorFID \
				"Error: The Comps Name $Compname Gravity Node has something wrong in TrimMass table.\n"
				lappend flag_er_comps $Compname 
				incr flag3 
				continue
			}
			*createmark nodes 1 "by sphere" $CGX $CGY $CGZ 0.001 inside 0 0 0;
			set Granodeid [hm_getmark nodes 1];
			*clearmark nodes 1
			lappend Compids $Compid
			lappend Granodeids $Granodeid
			lappend masses $mass
			lappend attypes $attachtype
		} 
	}
	set NumTrim [llength $Compids ]
	for {set jl 0} {$jl < $NumTrim} {incr jl} {
		set Compid [lindex $Compids $jl]
		set Compname [hm_getcollectorname comps $Compid]
		if {[lsearch $flag_er_comps $Compname] != -1} {
		    continue
		}
		*retainmarkselections 1 ;
		*currentcollector components "$Compname" ;
		*retainmarkselections 0 ;
		set flag2 0
		for {set il 0} {$il < [llength $ArrFromCSV]} {incr il} {
			set Compname2 [lindex $ArrFromCSV $il 0] 
			if {"$Compname2" =="$Compname"} {
				if { [ catch { set atx [expr [lindex $ArrFromCSV $il 6] + 0.005] } ] } {
				    puts -nonewline $errorFID \
					"Error: The Comps Name $Compname Attach Node has something wrong in TrimMass table.\n"
				    incr flag3 
				    continue
				}
				if { [ catch { set aty [expr [lindex $ArrFromCSV $il 7] + 0.005] } ] } {
				    puts -nonewline $errorFID \
					"Error: The Comps Name $Compname Attach Node has something wrong in TrimMass table.\n"
				    incr flag3 
				    continue
				}
				if { [ catch { set atz [expr [lindex $ArrFromCSV $il 8] + 0.005] } ] } {
				    puts -nonewline $errorFID \
					"Error: The Comps Name $Compname Attach Node has something wrong in TrimMass table.\n"
				    incr flag3 
				    continue
				}
				*createnode $atx $aty $atz 0 0 0;
				*createmark nodes 1 "by sphere" $atx $aty $atz 0.001 inside 0 0 0;
				set nid [hm_getmark nodes 1];
				*clearmark nodes 1
				if { [ catch { CreateRBE2withMount $nid $wcha } ] } {
				    puts -nonewline $errorFID \
					"Error: The Comps Name $Compname Attach Node ([lindex $ArrFromCSV $il 6] , [lindex $ArrFromCSV $il 7] , [lindex $ArrFromCSV $il 8]) can not create RBE2.\n"
				    incr flag3 
				    continue
				}
				if {$flag2 == 0} {
					set nodeids [list $nid];
					incr flag2;
				} else {
					lappend nodeids $nid
				}
			}
		}
		set mass [lindex $masses $jl]
		if {[ catch { set mass [expr $mass * $wtmass] } ] } {
		    puts -nonewline $errorFID \
			"Error: The Comps Name $Compname Mass has something wrong in TrimMass table.\n"
			incr flag3 
			continue
		}
		set Granodeid [lindex $Granodeids $jl]
		set attachtype [lindex $attypes $jl];
		if {"$attachtype" == "direct"} {
			DirectMass $mass $nodeids 
		} elseif {"$attachtype" == "loose"} {
			CreateRBE3withNode $Granodeid $nodeids
			*createmark nodes 1 $Granodeid
			*masselement 1 $mass "" 0
			*clearmark nodes 1
		} else {
		    puts -nonewline $errorFID \
			"Error: The Comps Name $Compname Attach Type has something wrong in TrimMass table.\n"
			incr flag3 
			continue
		}
	}
	*nodecleartempmark 
	*createmark components 1  "displayed"
	*equivalence components 1 0.01 1 0 0 
	*clearmark components 1;
	close $errorFID
	if {$flag3 != 0} {
	    Error_Window "Error" "Error: There are $flag3 errors in this work.\n Please open the file $errorfile"
	} else {
	    Error_Window "Done" "All Done All Done, Big Crown! "
	}
}

proc ReadExcel {FileName} {
	set otvalue {}
	set value {}
	set temp {}
	set temp2 {}
	package require twapi
	set app [twapi::comobj "Excel.Application"]
	$app DisplayAlerts True
	set Workbooks [$app Workbooks]
	set workbook [$Workbooks Open [file nativename $FileName]]
	set sheets [$workbook Sheets]
	set sheet [$sheets Item 1]
	set cell_1 [$sheet Cells]
	set il 0
	while {($il == 0) || ([llength [lindex $temp2 6]] > 0)} {
		incr il
		set temp [[$cell_1 Range A$il I$il] Value2]
		lappend value $temp 
		set temp3 [llength $value]
		if {$temp3 != 1} {
		    for {set cl 0} {$cl <= 5} {incr cl} {
			    lset value end $cl [lindex $labb $cl]
			}
		} else {
			set labb $value
		}
		set kl [expr $il + 1]
		set temp2 [[$cell_1 Range A$kl I$kl] Value2]
		if {([llength [lindex $temp2 0]] > 0) || ([llength [lindex $temp2 6]] == 0)} {
			set labb $temp2	
		}
	}
	$workbook Save
	$app DisplayAlerts False
	$app Quit
	$app destroy
	return $value
}

proc ReadCSV {csvfile} {
	set values {} 
	set FileChannelID [open [file nativename $csvfile] r]
	while {![eof $FileChannelID]} {
		set line [gets $FileChannelID];
		set temp [split $line ","];
		if {[llength [lindex $temp 6]] <= 0} {
			break;
		}
		lappend values $temp
	}
	set otvalue {}
	set values2 {}
	set flag 0
	for {set il 0} {$il < [llength $values]} {incr il} {
		set value [lindex $values $il]
		lappend values2 $value
		set temp3 [llength $values2]
		if {$temp3 != 1} {
		    for {set cl 0} {$cl <= 5} {incr cl} {
			    switch $flag {
				0 {
					lset values2 end $cl [lindex $labb 0 $cl]
				}
				1 {
					lset values2 end $cl [lindex $labb $cl]
				}
				}
			    
			}
		} else {
			set labb $values2
		}
		set temp2 [lindex $values [expr $il + 1]]
		if {([llength [lindex $temp2 0]] > 0) || ($il >= [expr [llength $values] - 1])} {
			set flag 1
			set labb $temp2
		}
	}
	close $FileChannelID
	return $values2
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

TrimmassMain;


