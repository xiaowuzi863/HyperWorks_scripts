namespace eval Mat_Data {
    proc ReadMat {} {
		set filepath [sys_control::get_resource_directory]
		set datas [Mat_Data::ReadCSV [file nativename "$filepath/Mats_Basic_Table.csv"]]
		set matdict {}
		foreach data $datas {
			set tmpdict1 [dict create E [lindex $data 1] NU [lindex $data 2] RHO [lindex $data 3]]
			set tmpdict [dict create [lindex $data 0] $tmpdict1]
			set matdict [dict merge $matdict $tmpdict]
		} 
		return $matdict
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

	
	proc ReadFromMat {matdict MatName} {
		set DMatName [dict key $matdict "*$MatName*"]
		if {[llength $DMatName] == 0} {
			dict for {key value} $matdict {
				set dictflag [regexp -nocase -- "$MatName" $key]
				if {$dictflag == 1} {
					lappend DMatName $key
				}
			} 
		}
		set none [dict create E 0 NU 0 RHO 0]
		if {[llength $DMatName] == 1} {
			set exits [dict get $matdict $DMatName]
			set out [dict create $DMatName $exits]
			return $out
		} elseif {[llength $DMatName] == 0} {
			set out [dict create "$MatName.unfound" $none]
			return $out
		} else {
			set out [dict create "$MatName.undetermine" $none]
			return $out
		}
    }
}

namespace eval Create_Entity {
    proc Mat_Create { name color E Nu Rho } {
        if {[hm_entityinfo exist mats $name -byname] != 1} {
		    #判断材料是否存在
		    *collectorcreate materials "$name" "" $color;#创建collector
	    }
	    *createmark materials 2 "$name";#创建mark
        #Retrieve material ID for use below;
		set mat_id [hm_getmark mats 2];#得到材料的id
		*dictionaryload materials 2 "[file normalize [hm_info exporttemplate]]" "MAT1";
		*attributeupdateint materials $mat_id 3240 1 2 0 1;
		*attributeupdatedouble materials $mat_id 1 1 1 0 $E;
		*attributeupdatedouble materials $mat_id 3 1 1 0 $Nu;
		*attributeupdatedouble materials $mat_id 4 1 1 0 $Rho;
	}
	
	proc Prop_3D_Create {compname matname} {
		if {[hm_entityinfo exist props $compname -byname] != 1} {
			*collectorcreate properties "$compname" "$matname" 11
			#判断是否存在
		} 
		*createmark properties 2 "$compname"
		*dictionaryload properties 2 "[file normalize [hm_info exporttemplate]]" "PSOLID"
	}
	
	proc Prop_2D_Create {compname matname T} {
	    if {[hm_entityinfo exist props $compname -byname] != 1} {
		 	*collectorcreate properties "$compname" "$matname" 11
	 		#判断是否存在
	    } 
		*createmark properties 2 "$compname"
		set propid [hm_getmark properties 2]
		*dictionaryload properties 2 "[file normalize [hm_info exporttemplate]]" "PSHELL"
		*attributeupdatedouble properties $propid 95 1 1 0 $T
	}

}

namespace eval Model_Check {
    variable Comp_ID
	variable Comp_Name
	variable Comp_Prop
	variable Comp_T
	variable Comp_Mat
	variable Seq_Num
	variable Comps
	variable Comp_FN
	variable FEM_Flag
	variable Edge_Flag
	variable Conect_Flag
	variable Attach_Flag
	variable Comp_Unit
		
	proc Window {} {	    
		set w .model_check
    	toplevel $w
	    wm title $w "Model Check"
    	KeepOnTop $w
	
		frame $w.msg
		hwtk::label $w.msg.lab1 -text "ID:"
		hwtk::entry $w.msg.ent1 -width 8 -state readonly -textvariable Model_Check::Comp_ID
		hwtk::label $w.msg.lab2 -text "Name:"
		hwtk::entry $w.msg.ent2 -width 30 -state readonly -textvariable Model_Check::Comp_Name
		hwtk::label $w.msg.lab3 -text "Figure Number:"
		hwtk::entry $w.msg.ent3 -width 12 -state normal -textvariable Model_Check::Comp_FN
		pack $w.msg -side top -fill x
		pack $w.msg.lab1 $w.msg.ent1 $w.msg.lab2 $w.msg.ent2 $w.msg.lab3 $w.msg.ent3 -side left -expand 1
	
		frame $w.dis
		hwtk::checkbutton $w.dis.cb1 -text "FEM" -variable Model_Check::FEM_Flag -command "Model_Check::View_Comp 0 0"
		hwtk::checkbutton $w.dis.cb2 -text "Edge" -variable Model_Check::Edge_Flag -command "Model_Check::View_Comp 0 0"
		hwtk::checkbutton $w.dis.cb3 -text "Connector" -variable Model_Check::Conect_Flag -command "Model_Check::View_Comp 0 0"
		hwtk::checkbutton $w.dis.cb4 -text "Attach" -variable Model_Check::Attach_Flag -command "Model_Check::View_Comp 0 0"
		pack $w.dis -side top -fill x
		pack $w.dis.cb1 $w.dis.cb2 $w.dis.cb3 $w.dis.cb4 -side left -expand 1
		
		frame $w.ctr
		hwtk::button $w.ctr.b -text "<<Back" -command "Model_Check::View_Comp -1 1"
		hwtk::button $w.ctr.n -text "Next>>" -command "Model_Check::View_Comp 1 1"
		hwtk::button $w.ctr.a -text "Show All" -command {*createmark comps 1 "all" ; *showentitybymark 1}
		hwtk::button $w.ctr.ha -text "Hide All" -command "Model_Check::View_Comp 0 0"
		pack $w.ctr -side top -fill x
		pack $w.ctr.b $w.ctr.n $w.ctr.a $w.ctr.ha -side left -expand 1
		
		frame $w.msg2
		hwtk::label $w.msg2.lab1 -text "Property:"
		hwtk::combobox $w.msg2.cb1 -width 8 -state readonly -textvariable Model_Check::Comp_Prop -values {PSHELL PSOLID}
		hwtk::label $w.msg2.lab2 -text "Thickness:"
		hwtk::entry $w.msg2.ent2 -width 8 -state normal -textvariable Model_Check::Comp_T
		hwtk::label $w.msg2.lab3 -text "Material:"
		hwtk::entry $w.msg2.ent3 -width 8 -state normal -textvariable Model_Check::Comp_Mat
		hwtk::label $w.msg2.lab4 -text "Unit:"
		hwtk::combobox $w.msg2.cb4 -width 8 -state readonly -textvariable Model_Check::Comp_Unit -values {T kg}
		pack $w.msg2 -side top -fill x
		pack $w.msg2.lab1 $w.msg2.cb1 $w.msg2.lab2 $w.msg2.ent2 $w.msg2.lab3 $w.msg2.ent3 $w.msg2.lab4 $w.msg2.cb4 -side left -expand 1
			
		frame $w.but
		hwtk::button $w.but.r -text "Modify" -command "Model_Check::Modify_Comp"
		hwtk::button $w.but.c -text "Close" -command "destroy $w"
		pack $w.but -side bottom -fill x
		pack $w.but.r $w.but.c -side left -expand 1
	}
	
	proc Modify_Comp {} {
	    if {[catch {set matsdata [Mat_Data::ReadMat]}]} {
	        tk_messageBox -title "Error" -message \
			"Error: There is something wrong with the material table of your computer!"
		    return
	    }
		switch $Model_Check::Comp_Unit {
			T {
				set WTM 1
			}
			kg {
				set WTM 1000
			}
		}
		set oldname $Model_Check::Comp_Name
		if {[string length $Model_Check::Comp_FN] == 0} {
		    tk_messageBox -title "Error" -message\
			"Please input the Figure Number.\n"
			return
		} else {
		    set basename $Model_Check::Comp_FN
		}
		if {[string length $Model_Check::Comp_Mat] == 0} {
			tk_messageBox -title "Error" -message\
			" The propertie or material dont be created.\n"
			return
		}
		if {[catch {set needmat [Mat_Data::ReadFromMat $matsdata $Model_Check::Comp_Mat]}] } {
			tk_messageBox -title "Error" -message \
			"Error: There is something wrong with the material table of your computer!"
			return
		}
		set E [dict get [lindex $needmat 1] E]
		set NU [dict get [lindex $needmat 1] NU]
		set RHO [expr [dict get [lindex $needmat 1] RHO] * $WTM]
		set matname [lindex $needmat 0]
		if { [catch { Create_Entity::Mat_Create $matname 11 $E $NU $RHO }] } {
			tk_messageBox -title "Error" -message \
			"The material message has some problems.\n"
			return
		}
		##
		if { $Model_Check::Comp_Prop == "PSHELL"} {
		    set T $Model_Check::Comp_T
			#set regflag [regsub -- \\. $T p tmp]
            #if {$regflag == 0} {
			#    set Thickness "T$tmp\p"
			#} elseif {[string index $tmp end] == 0} {
			#    set tmp2 [string range $tmp 0 end-1]
			#	set Thickness "T$tmp2"
			#} else {
			#    set Thickness "T$tmp"
			#}
		    set tmp [format %0.0f [expr $T * 100]]
			set Thickness "T$tmp"
			set tmp [split $basename "."]
		    set figID [string trim [lindex $tmp 0] " "]
		    set PropName "P$figID\_$Thickness\_$matname" 
		    if { [catch { Create_Entity::Prop_2D_Create $PropName $matname $T}] } {
		        tk_messageBox -title "Error" -message \
				"The propertie message has some problems.\n"
			    return
		    }
		    set newname $PropName		
		} elseif {$Model_Check::Comp_Prop == "PSOLID"} {
		    set tmp [split $basename "."]
		    set figID [string trim [lindex $tmp 0] " "]
		    set PropName "P$figID\_$matname"
		    if { [catch { Create_Entity::Prop_3D_Create $PropName $matname}] } {
			    tk_messageBox -title "Error" -message \
				"The propertie message has some problems.\n"
			    return
			}
		    set newname $PropName 	
		} else { 
		    tk_messageBox -title "Error" -message \
			"The propertie or material dont be created.\n"
			return
		}
		##
		if {"$oldname" != "$newname"} {
			if {[catch { *renamecollector components "$oldname" "$newname" } ] } {
			    tk_messageBox -title "Error" -message \
				"Error: The Comps has the same name witch is $newname in model.\n"
			    return
			}
		}
		*createmark props 1 "by name only" "$PropName"
		*createmark components 1 "$newname"
		*propertyupdate components 1 "$PropName"
		Model_Check::View_Comp 0 0
	}
	
	proc View_Comp {flag flag2} {
		set Model_Check::Seq_Num [expr $Model_Check::Seq_Num + $flag]
		if {$Model_Check::Seq_Num >= [llength $Model_Check::Comps]} {
			set Model_Check::Seq_Num 0
		} elseif {$Model_Check::Seq_Num < 0} {
			set Model_Check::Seq_Num [expr [llength $Model_Check::Comps] - 1]
		}
		set Model_Check::Comp_ID [lindex $Model_Check::Comps $Model_Check::Seq_Num]
		set Model_Check::Comp_Name [hm_getcollectorname comps $Model_Check::Comp_ID]
		*currentcollector components "$Model_Check::Comp_Name"
		*isolateonlyentity comps "by id" $Model_Check::Comp_ID 
		catch {*deleteedges }
		if {$Model_Check::Edge_Flag == 1} {
			*createmark components 1 "by name only" "$Model_Check::Comp_Name"
			catch {*findedges1 components 1 0 0 0 30}
			*clearmark comps 1
		} 
		if {$Model_Check::Attach_Flag == 1} {
		    *createmark elements 1 "by comp name" "$Model_Check::Comp_Name"
			*findmark elements 1 1 0 elements 0 2
			*clearmark elements 1
			*clearmark elements 2
		}
		if {$Model_Check::Conect_Flag == 1} {
		    *createmark comps 1 "by name only" "$Model_Check::Comp_Name"
            *displaycollectorsallbymark 1 "reverse" 0 1
			*clearmark comps 1
		    *createmark comps 1 "all"
            *displaycollectorsallbymark 1 "reverse" 0 1
			*clearmark comps 1
		    set ConIDs [Find_Connector $Model_Check::Comp_ID]
			eval *createmark connectors 1 $ConIDs 
			*maskmark connectors 1 
			*maskreverse connectors
			*clearmark connectors 1
			foreach geom_type {solids lines surfs} {
			    *createmark $geom_type 1 "all"
				*maskmark $geom_type 1
				*clearmark $geom_type 1
			}
		}
		if {$Model_Check::FEM_Flag == 0} {
		    *createmark comps 2 "by name only" "$Model_Check::Comp_Name" 
			*createstringarray 2 "elements_on" "geometry_on"
			*hideentitybymark 2 1 2
			*clearmark comps 2
		}
		if {$flag2 == 1} {
			*window 0 0 0 0 0
		}
		
		set PropID [hm_getentityvalue components "$Model_Check::Comp_Name" propertyid 0 -byname]
		if {$PropID == 0} {
			set Model_Check::Comp_Prop ""
			set Model_Check::Comp_T ""
			set Model_Check::Comp_Mat ""
		} else {
			set PropName [hm_getcollectorname props $PropID]
			set Model_Check::Comp_Prop [hm_getcardimagename props "$PropName" -byname]
			set Model_Check::Comp_T [hm_getthickness comps $Model_Check::Comp_ID]
			set MatID [hm_getentityvalue properties "$PropName" material 0 -byname]
			if {$MatID == 0} {
				set Model_Check::Comp_Mat ""
			} else {
				set Model_Check::Comp_Mat [hm_getcollectorname mats $MatID]
				set mat_rho [hm_getvalue mats id=$MatID dataname=Rho]
				if {[string index $mat_rho end] == 9} {
				    set Model_Check::Comp_Unit T
				} elseif {[string index $mat_rho end] == 6} {
				    set Model_Check::Comp_Unit kg
				} else {
				    set Model_Check::Comp_Unit Error
				}
			}
		} 
		
		set Model_Check::Comp_FN ""
	}
	
	proc Find_Connector {CompID} {
	    *createmark connectors 1 "all"
		set con_ids [hm_getmark connectors 1]
		*clearmark connectors 1
		set out_con_ids {}
		foreach con_id $con_ids {
		    set comp_list [ hm_ce_getlinkentities $con_id COMPONENTS ]
			set flag [lsearch $comp_list $CompID]
			if {$flag != -1} {
			    lappend out_con_ids $con_id 
			}
		}
		return $out_con_ids
	}
	 
	proc Start {} {
		set Model_Check::Seq_Num 0
		set Model_Check::FEM_Flag 1
		set Model_Check::Edge_Flag 0
		set Model_Check::Conect_Flag 0
		set Model_Check::Attach_Flag 0
		set Model_Check::Comp_Unit ""
		set Model_Check::Comp_FN ""
		catch {*deleteedges }
		*createmarkpanel comps 1 
		set Model_Check::Comps [hm_getmark comps 1]
		set Model_Check::Comp_ID [lindex $Model_Check::Comps $Model_Check::Seq_Num]
		set Model_Check::Comp_Name [hm_getcollectorname comps $Model_Check::Comp_ID]
		Model_Check::Window
		Model_Check::View_Comp 0 1
		*clearmark comps 1
		#*currentcollector components "$Comp_Name"
		#*isolateonlyentity comps "by id" $Comp_ID 
		#*window 0 0 0 0 0
		#*clearmark comps 1
		
		#set PropID [hm_getentityvalue components "$Comp_Name" propertyid 0 -byname]
		#if {[llength $PropID] == 0} {
		#	set Comp_Prop ""
		#	set Comp_T ""
		#	set Comp_Mat ""
		#} else {
		#	set PropName [hm_getcollectorname props $PropID]
		#	set Comp_Prop [hm_getcardimagename props "$PropName" -byname]
		#	set Comp_T [hm_getthickness comps $Comp_ID]
		#	set MatID [hm_getentityvalue properties "$PropName" material 0 -byname]
		#	if {[llength $MatID] == 0} {
		#		set Comp_Mat ""
		#	} else {
		#		set Comp_Mat [hm_getcollectorname mats $MatID]
		#	}
		#
		#}
		
		#Model_Check::Window
	}

}

namespace eval sys_control {
    variable my_location [file normalize [info script]]
    
	proc get_resource_directory {} {
        return [file dirname $sys_control::my_location]
    }
}
 
	

Model_Check::Start

