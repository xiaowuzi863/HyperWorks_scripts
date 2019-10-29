proc BatchCreateBush {} {
	*nodecleartempmark 
    set FileName [MF_fileopen]
	if { [string length $FileName] == 0 } {
	    Error_Window "Error" "Error: The file is not found!"
		return
	}
	set temp1 [split $FileName "."]
	if {([lindex $temp1 end] == "csv") || ([lindex $temp1 end] == "CSV")} {
		if { [ catch { set BushMsgs [ReadCSV $FileName] } ] } {
		    Error_Window "Error" "Error: The table cannot be used."
			return
		}
	} else {
		if { [ catch { set BushMsgs [ReadExcel $FileName] } ] } {
		    Error_Window "Error" "Error: The table cannot be used."
			return
		}
	}
	set errorpath [file dirname [file nativename "$FileName"]]
	set errorfile [file nativename "$errorpath/BushCreateErrorWaring.log"]
	set errorFID [open $errorfile w]	
	set flag3 0		
	foreach BushMsg $BushMsgs {
		set BushName [lindex [lindex $BushMsg 0] 0]
		set BushCord [lrange [lindex $BushMsg 0] 1 3]
		if { [ catch { eval *createnode $BushCord 0 0 0 } ] || \
		[ catch { set flag30 [expr [lindex $BushCord 0] + 0.01] } ] || \
		[ catch { set flag30 [expr [lindex $BushCord 1] + 0.01] } ] || \
		[ catch { set flag30 [expr [lindex $BushCord 2] + 0.01] } ] || \
		([string length [lindex $BushCord 0]] == 0) || \
		([string length [lindex $BushCord 1]] == 0) || \
		([string length [lindex $BushCord 2]] == 0) } {
		    puts -nonewline $errorFID \
			"Error: The Name $BushName LOCK Coordinate Node(column 2 3 4) has some problems.\n"
			incr flag3
			continue
		}
		eval *createnode $BushCord 0 0 0
		*createmark nodes 1 "by sphere" [lindex $BushCord 0] [lindex $BushCord 1] [lindex $BushCord 2]  0.001 inside 0 1 0;
		set BushNodes [hm_getmark nodes 1]
		set ClosureMts {}
		set BodyMts {}
		foreach BushMount $BushMsg {
			set temp [lrange $BushMount 4 6]
			if {[llength [lindex $temp 0]] != 0} {
				if { [ catch { eval *createnode $temp 0 0 0 } ] || \
				[ catch { set flag30 [expr [lindex $temp 0] + 0.01] } ] || \
				[ catch { set flag30 [expr [lindex $temp 1] + 0.01] } ] || \
				[ catch { set flag30 [expr [lindex $temp 2] + 0.01] } ] || \
				([string length [lindex $temp 0]] == 0) || \
				([string length [lindex $temp 1]] == 0) || \
				([string length [lindex $temp 2]] == 0) } {
				    set temp_err [expr [lsearch $BushMsg $BushMount] + 1]
				    puts -nonewline $errorFID \
					"Error: The Name $BushName row $temp_err Closure Coordinate Node(column 5 6 7) has some problems.\n"
					incr flag3
					continue
				}
				*createmark nodes 1 "by sphere" [lindex $temp 0] [lindex $temp 1] [lindex $temp 2] 0.001 inside 0 1 0;
				lappend ClosureMts [hm_getmark nodes 1]
			}
			set temp [lrange $BushMount 7 9]
			if {[llength [lindex $temp 0] ] != 0} {
				if { [ catch { eval *createnode $temp 0 0 0 } ] || \
				[ catch { set flag30 [expr [lindex $temp 0] + 0.01] } ] || \
				[ catch { set flag30 [expr [lindex $temp 1] + 0.01] } ] || \
				[ catch { set flag30 [expr [lindex $temp 2] + 0.01] } ] || \
				([string length [lindex $temp 0]] == 0) || \
				([string length [lindex $temp 1]] == 0) || \
				([string length [lindex $temp 2]] == 0) } {
				    set temp_err [expr [lsearch $BushMsg $BushMount] + 1]
				    puts -nonewline $errorFID \
					"Error: The Name $BushName row $temp_err BODY Coordinate Node(column 8 9 10) has some problems.\n"
					incr flag3
					continue
				}
				*createmark nodes 1 "by sphere" [lindex $temp 0] [lindex $temp 1] [lindex $temp 2] 0.001 inside 0 1 0;
				lappend BodyMts [hm_getmark nodes 1]
			}
		}
		set temp "$BushName\_RBE2"
		if { [ catch { *collectorcreateonly components "$temp" "" 11 } ] } {
		    puts -nonewline $errorFID \
			"Error: The Name $BushName was existent.\n"
			incr flag3
			continue
		}
		*currentcollector components "$temp"
		if {[llength $ClosureMts] != 0} {
			foreach ClosureMt $ClosureMts {
				if { [ catch { CreateRBE2withMount $ClosureMt $BushNodes 6 } ] } {
					set temp_err [expr [lsearch $ClosureMts $ClosureMt] + 1]
					puts -nonewline $errorFID \
					"Error: The Name $BushName row $temp_err Closure Coordinate Node(column 5 6 7) cannot create the RBE2. \n Please check the model and the table.\n"
					incr flag3
					continue		
				}
			}
			eval *createmark nodes 2 $ClosureMts;
			if { [ catch { *rigidlink [lindex $BushNodes 0] 2 123456 } ] } {
			    puts -nonewline $errorFID \
				"Error: The Name $BushName LOCK Coordinate Node(column 2 3 4) cannot conect the Closure Node(colum 5 6 7).\n"
				incr flag3
				continue
			}
		} else {
			if { [ catch { CreateRBE2withMount [lindex $BushNodes 0] $BushNodes 6 } ] } {
			    puts -nonewline $errorFID \
				"Error: The Name $BushName LOCK Coordinate Node(column 2 3 4) cannot create RBE2.\n"
				incr flag3
				continue
			}
		}
		if {[llength $BodyMts] != 0} {
			foreach BodyMt $BodyMts {
				if { [ catch { CreateRBE2withMount $BodyMt $BushNodes 6 } ] } {
					set temp_err [expr [lsearch $BodyMts $BodyMt] + 1]
					puts -nonewline $errorFID \
					"Error: The Name $BushName row $temp_err BODY Node(column 8 9 10) cannot create the RBE2. Please check the model and the table.\n"
					incr flag3
					continue		
				}
			}
			eval *createmark nodes 2 $BodyMts;
			if { [ catch { *rigidlink [lindex $BushNodes 1] 2 123456 } ] } {
			    puts -nonewline $errorFID \
				"Error: The Name $BushName LOCK Node(column 2 3 4) cannot conect the BODY Node(colum 8 9 10).\n"
				incr flag3
				continue
			}
		} else {
			
			if { [ catch { CreateRBE2withMount [lindex $BushNodes 1] $BushNodes 6 } ] } {
			    puts -nonewline $errorFID \
				"Error: The Name $BushName LOCK Node(column 2 3 4) cannot create RBE2.\n"
				incr flag3
				continue
			}
		}
		set BushComp "$BushName\_BUSH"
		if { [ catch { *collectorcreateonly components "$BushComp" "" 11 } ] } {
		    puts -nonewline $errorFID \
			"Error: The Name $BushName was existent.\n"
			incr flag3
			continue
		}
		*currentcollector components "$BushComp"
		set name [split $BushName "_"]
		set PropData {Latch Bumper Gas}
		set KK {Latch {60 60 60} {620 3000 3000}}
		for {set il 0} {$il < [llength $PropData]} {incr il} {
			set PropD [lindex $PropData $il]
			set K [lindex $KK $il]
			if {[lsearch $name $PropD] != -1} {
				if {$K == "Latch"} {
					set Leter [string index $BushName 0]
					switch $Leter {
						H -
						L {
							if { [ catch { CreateBush_One {1e4 1e4 1e4} $BushNodes $BushComp } ] } {
							    puts -nonewline $errorFID \ 
								"Error: The Name $BushName Bush element cannot be created , please check the table and model.\n"
								incr flag3
								continue					
							}
						}
						F -
						R {
							if { [ catch {CreateBush_One {670 9e4 670} $BushNodes $BushComp } ] } {
							    puts -nonewline $errorFID \ 
								"Error: The Name $BushName Bush element cannot be created , please check the table and model.\n"
								incr flag3
								continue	
							}
						}
					} 
				} else {
					if { [ catch { CreateBush_One $K $BushNodes $BushComp } ] } {
					    puts -nonewline $errorFID \ 
						"Error: The Name $BushName Bush element cannot be created , please check the table and model.\n"
						incr flag3
						continue	
					}
				}
			}
		}
		eval *replacenodes $BushNodes 0 1
	} 
	*nodecleartempmark 
	close $errorFID
	if {$flag3 != 0} {
	    Error_Window "Error" "Error: There are $flag3 errors in this work.\n Please open the file $errorfile"
	} else {
	    Error_Window "Done" "All Done All Done, Big Crown! "
	}		
}

proc Error_Window {ErrorType ErrorMessage} {
    tk_messageBox -title "$ErrorType" -message "$ErrorMessage"
}

proc CreateBush_One {K nodeids CompName} {
	set k1 [lindex $K 0]
	set k2 [lindex $K 1]
	set k3 [lindex $K 2]
	set node1 [lindex $nodeids 0]
	set node2 [lindex $nodeids 1]
	if {[hm_entityinfo exist properties $CompName]==0} {
		*collectorcreateonly properties "$CompName" "" 11
		*createmark properties 2 "$CompName"
		*dictionaryload properties 2 [hm_info templatefilename] "PBUSH"
		set propid [hm_getmark properties 2]
		*startnotehistorystate {Attached attributes to property "$CompName"}
		*attributeupdateint properties $propid 872 1 2 0 1
		*attributeupdatedouble properties $propid 845 1 1 0 $k1
		*attributeupdatedouble properties $propid 846 1 1 0 $k2
		*attributeupdatedouble properties $propid 847 1 1 0 $k3
	} 
	*elementtype 21 6
	*springos $node1 $node2 "" 0 0 0 0 0 0 0
	*createmark components 1 "$CompName"
	*propertyupdate components 1 "$CompName"
}

proc MF_fileopen { } {
    #   Type names		Extension(s)	Mac File Type(s)
    #
    #---------------------------------------------------------
    set types {
	    {"CSV Files"		{.csv}		}
		{"Excel Files"		{.xlsx}		}
		{"All files"		*}
    }
	set file [tk_getOpenFile -filetypes $types ]
	return $file
}

proc CreateRBE2withMount {nodeid specialnode wcha} {
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
		if {($nnid2 == $nodeid) || [lsearch $specialnode $nnid2] != -1} {
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
		set labelnodedis2 [hm_getdistance nodes $nnid3 $nodeid 0];
		set labelnodedis [lindex $labelnodedis2 0];
		set kkk 0;
		set nodeid3 [list $nnid3];
		for {set il 0} {$il < $numnode2} {incr il} {
			set nnid2 [lindex $nodeid2 $il]; 
			set flagdistance [ hm_getdistance nodes $nodeid $nnid2 0] ;
			set nodedistance [lindex $flagdistance 0];
			set cha [expr $nodedistance-$labelnodedis];
			if {($nnid2 == $nnid3 )||($nnid2 == $nodeid)||($nnid3 == $nodeid)||([lsearch $specialnode $nnid2] != -1)} {
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
	while {($il == 0) || ([llength [lindex $temp2 4]] > 0) || ([llength [lindex $temp2 7]] > 0)} {
		incr il
		set temp [[$cell_1 Range A$il J$il] Value2]
		lappend value $temp 
		set kl [expr $il + 1]
		set temp2 [[$cell_1 Range A$kl J$kl] Value2]
		if {([llength [lindex $temp2 0]] > 0) || (([llength [lindex $temp2 4]] == 0) && ([llength [lindex $temp2 7]] == 0))} {
			lappend otvalue $value
			set value {}	
		}
	}
	$workbook Save
	$app DisplayAlerts False
	$app Quit
	$app destroy
	return $otvalue
}

proc ReadCSV {csvfile} {
	set values {} 
	set FileChannelID [open [file nativename $csvfile] r]
	while {![eof $FileChannelID]} {
		set line [gets $FileChannelID];
		set temp [split $line ","];
		if {([llength [lindex $temp 4]] <= 0) && ([llength [lindex $temp 7]] <= 0)} {
			break;
		}
		lappend values $temp
	}
	set otvalue {}
	set values2 {}
	for {set il 0} {$il < [llength $values]} {incr il} {
		set value [lindex $values $il]
		lappend values2 $value
		set temp2 [lindex $values [expr $il + 1]]
		if {([llength [lindex $temp2 0]] > 0) || ($il >= [expr [llength $values] - 1])} {
			lappend otvalue $values2
			set values2 {}
		}
	}
	return $otvalue
}

BatchCreateBush