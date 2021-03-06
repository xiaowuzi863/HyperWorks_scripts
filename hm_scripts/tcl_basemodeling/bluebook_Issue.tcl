proc bluebook_Main {F U} {
	set FileName [$F get]
	if {[string length $FileName] == 0} {
    	Error_Window "Error" "Error: The file is not found!"
	    return 
	}
	set Unit [$U get]
	if {[string length $Unit] == 0} {
		Error_Window "Error" "Error: The Unit is not inputed!"
	    return 
	}	
	set temp1 [split $FileName "."]
	if {([lindex $temp1 end] == "csv") || ([lindex $temp1 end] == "CSV")} {
        if {[catch {set blueb [ReadCSV $FileName]}]} {
		    Error_Window "Error" "Error: The table can not be used!"
			return 
		}
	} else {
		if {[catch {set blueb [ReadExcel $FileName]}]} {
		    Error_Window "Error" "Error: The table can not be used!"
			return 
		}
	}
	switch $Unit {
		T {
			set RHO 7.85e-9
		}
		kg {
			set RHO 7.85e-6
		}
	}
	set errorpath [file dirname [file nativename "$FileName"]]
	set errorfile [file nativename "$errorpath/BluebookErrorWaring.log"]
	set errorFID [open $errorfile w]
	set flag 0
	foreach bb $blueb {
		if {[lindex $bb 0] == "Comp Id"} {
			continue
		}
		if {[catch {set ID [format %.0f [lindex $bb 0]]}]} {   
			set oldname [SearchComp [lindex $bb 0]]
			if {[string length $oldname] == 0} {
			    puts -nonewline $errorFID "Error: The Comps ID $ID was not found.\n"
				incr flag
				continue				
			}
		} elseif { [catch {set oldname [hm_getcollectorname comps $ID]}] } {
		    puts -nonewline $errorFID "Error: The Comps ID $ID was not found.\n"
		    incr flag
		    continue
		}
		set newname [lindex $bb 1]
		if {"$oldname" != "$newname"} {
			if {[catch { *renamecollector components "$oldname" "$newname" } ] } {
			    puts -nonewline $errorFID "Error: The Comps ID $ID has the same name with $newname in table.\n"
			    incr flag
			    continue
			}
		}
		if {[string length [lindex $bb end]] == 0} {
			puts -nonewline $errorFID "Error: The Comps ID $ID propertie or material dont be created.\n"
			incr flag
			continue
		}
		if { [catch { mat_create [lindex $bb end] 11 2.1e5 0.3 $RHO }] } {
		    puts -nonewline $errorFID "Error: The Comps ID $ID material message has some problems.\n"
			incr flag
			continue
		}
		if {[lindex $bb 2] == "PSHELL"} {
		    if { [catch { Prop_2D_Create $newname [lindex $bb end] [lindex $bb 3] }] } {
		        puts -nonewline $errorFID "Error: The Comps ID $ID propertie message has some problems.\n"
			    incr flag
			    continue
		    }			
		} elseif {[lindex $bb 2] == "PSOLID"} {
		    if { [catch { Prop_3D_Create $newname [lindex $bb end] }] } {
			    puts -nonewline $errorFID "Error: The Comps ID $ID propertie message has some problems.\n"
			    incr flag
			    continue
			}
		} else { 
		    puts -nonewline $errorFID "Error: The Comps ID $ID propertie or material dont be created.\n"
			incr flag
			continue
		}
		*createmark props 1 "by name only" "$newname"
		*createmark components 1 "$newname"
		*propertyupdate components 1 "$newname"
	}
	close $errorFID
	if {$flag != 0} {
	    Error_Window "Error" "Error: There are $flag errors in this work.\n Please open the file $errorfile"
	} else {
	    Error_Window "Done" "All Done All Done, Big Crown! "
	}
    
}

proc SearchComp {ID} {
    set out {}
    *createmark comps 1 all
	set compids [hm_getmark comps 1]
	foreach compid $compids {
	    set compname [hm_getcollectorname comps $compid]
		set flag [string match "*$ID*" "$compname"]
		if {$flag == 1} {
		    set out $compname
			break
		}
	}
	return $out
} 

proc Error_Window {ErrorType ErrorMessage} {
    tk_messageBox -title "$ErrorType" -message "$ErrorMessage"
}

proc Prop_3D_Create {compname matname} {
   if {[hm_entityinfo exist props $compname -byname] == 1} {
		*createmark props 1 "by name only" "$compname"
		*deletemark props 1
		#判断是否存在
	} 	
	*collectorcreate properties "$compname" "$matname" 11
	*createmark properties 2 "$compname"
	*dictionaryload properties 2 "[file normalize [hm_info exporttemplate]]" "PSOLID"
}

proc mat_create { name color E Nu Rho } {
   if {[hm_entityinfo exist mats $name -byname] == 1} {
		*createmark materials 2 "$name";#创建mark
		#Retrieve material ID for use below;
		set mat_id [hm_getmark mats 2];#得到材料的id
		*attributeupdatedouble materials $mat_id 4 1 1 0 $Rho;
		return; #判断材料是否存在
   } else {
       *collectorcreate materials "$name" "" $color;#创建collector
       *createmark materials 2 "$name";#创建mark
       #Retrieve material ID for use below;
       set mat_id [hm_getmark mats 2];#得到材料的id
       *dictionaryload materials 2 "[file normalize [hm_info exporttemplate]]" "MAT1";
       *attributeupdateint materials $mat_id 3240 1 2 0 1;
       *attributeupdatedouble materials $mat_id 1 1 1 0 $E;
       *attributeupdatedouble materials $mat_id 3 1 1 0 $Nu;
       *attributeupdatedouble materials $mat_id 4 1 1 0 $Rho;
       return;
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
	close $FileChannelID 
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

proc xiugaiid {} {
    *createmarkpanel comps 1 "Select comps to change id";
    set CompIds [hm_getmark comps 1];
    set NumComps [llength $CompIds];
    *clearmark comps 1;
    for {set i 0} { $i < $NumComps } {incr i} {
        set Compid [lindex $CompIds $i];
        set Compname [hm_getcollectorname comps $Compid];
		set numid [GetNumFromStr $Compname]
		if {$numid == "NONE"} {
		    continue
		}
        *retainmarkselections 1 ;
        *createmark comps 2 "by id" $Compid
        *renumbersolverid comps 2 $numid 1 0 0 0 0 0 ;
        *retainmarkselections 0 ;
    }
    *clearmark comps 2;
}
    
proc bluebook_window {} {
	set w .bluebook
	toplevel $w
	wm title $w "BlueBook"
	KeepOnTop $w

	set types {
	    {"CSV Files"		{.csv} }
		{"Excel Files"		{.xlsx}		}
		{"All files"		*}
	}
	
	frame $w.f
	hwtk::label $w.f.lab -text "File:"
	hwtk::openfileentry $w.f.ent -filetypes $types -width 50
	hwtk::label $w.f.lab2 -text "Unit:"
	hwtk::combobox $w.f.com -width 3 -state readonly -values {T kg}
	pack $w.f -side top -fill x
	pack $w.f.lab $w.f.ent $w.f.lab2 $w.f.com -side left -expand 1
	
	frame $w.b
	hwtk::button $w.b.run0 -text "Change ID" -command "xiugaiid"
	hwtk::button $w.b.run -text "Blue Book" -command "bluebook_Main $w.f.ent $w.f.com"
	hwtk::button $w.b.close -text "Close" -command "destroy $w"
	pack $w.b -side top -fill x
	pack $w.b.run0 $w.b.run $w.b.close -side left -expand 1
}

 bluebook_window