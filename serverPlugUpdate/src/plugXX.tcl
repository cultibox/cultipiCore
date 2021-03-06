
proc plugXX_load {confPath} {
    set i 1
    while {1} {

        set plugXXFilename [file join $confPath plg "plug[string map {" " "0"} [format %2.f $i]]"]
        
        set plugXXConfFileName [file join $confPath plg "plug[string map {" " "0"} [format %2.f $i]].xml"]
        
        # On v�rifie la pr�sence du fichier
        if {[file exists $plugXXFilename] != 1} {
            ::piLog::log [clock milliseconds] "info" "File $plugXXFilename does not exists, so stop reading plugXX files"
            break;
        } else {
            ::piLog::log [clock milliseconds] "info" "reading $i plugXX $plugXXFilename"
            
            # On initialise les constantes de chaque prise
            set ::plug($i,value) "NA"
            set ::plug($i,inRegulation) "NONE"
            set ::plug($i,updateStatus) ""
            set ::plug($i,updateStatusComment) ""
            set ::plug($i,source) "plugv"
            set ::plug($i,force,value) ""
            set ::plug($i,force,idAfterProc) ""
            set ::plug($i,REG,type) "N"
            set ::plug($i,REG,sens) "+"
            set ::plug($i,REG,precision) "0.1"
            set ::plug($i,SEC,type) "N"
            set ::plug($i,SEC,sens) "+"
            set ::plug($i,SEC,precision) "0.1"
            set ::plug($i,SEC,etat_prise) "1"
            set ::plug($i,SEC,value) "1"
            set ::plug($i,calcul,type) "M"
            set ::plug($i,calcul,capteur_1) "1"
            set ::plug($i,calcul,capteur_2) "0"
            set ::plug($i,calcul,capteur_3) "0"
            set ::plug($i,calcul,capteur_4) "0"
            set ::plug($i,calcul,capteur_5) "0"
            set ::plug($i,calcul,capteur_6) "0"
            
            # On ajoute les variables permettant de faire de la r�gulation
            set ::plug($i,regulation,erreurNmoins1) 0
            set ::plug($i,regulation,commandeNmoins1) 0
            set ::plug($i,regulation,kp) 0.1
            set ::plug($i,regulation,ki) 0.01
            set ::plug($i,regulation,pourcentMin) 20
            set ::plug($i,regulation,pourcentMax) 100
            
            set fid [open $plugXXFilename r]
            while {[eof $fid] != 1} {
                gets $fid OneLine
                switch [string range $OneLine 0 3] {
                    "REG:" {
                        set ::plug($i,REG,type) [string index $OneLine 4] 
                        set ::plug($i,REG,sens) [string index $OneLine 5]
                        # Pour le calcul, on enl�ve les z�ro � gauche  et si c'est vide c'est que c'est 0
                        set precision [string trimleft [string range $OneLine 6 8] "0"]
                        if {$precision == ""} {set precision 0}
                        if {$::plug($i,REG,type) == "C"} {
                            set ::plug($i,REG,precision) [expr $precision / 1000.0]
                        } else {
                            set ::plug($i,REG,precision) [expr $precision / 10.0]
                        }
                        
                    }
                    "SEC:" {
                        
                        set ::plug($i,SEC,type) [string index $OneLine 4] 
                        set ::plug($i,SEC,sens) [string index $OneLine 5]
                        set ::plug($i,SEC,etat_prise) [string index $OneLine 6]
                        # Pour le calcul, on enl�ve les z�ro � gauche  et si c'est vide c'est que c'est 0
                        set value [string trimleft [string range $OneLine 7 9] "0"]
                        if {$value == ""} {set value 0}
                        set ::plug($i,SEC,value) [expr $value / 10.0]
                    }
                    "SEN:" {
                        set type  [string index $OneLine 4] 
                        if {$type != "M" && $type != "I" && $type != "A"} {
                            ::piLog::log [clock milliseconds] "error" "Plug $i : type of compute -$type- doesnot exist (replaced by M)"
                            set type "M"
                        }
                        set ::plug($i,calcul,type) $type
                        set ::plug($i,calcul,capteur_1) [string index $OneLine 5]
                        set ::plug($i,calcul,capteur_2) [string index $OneLine 6]
                        set ::plug($i,calcul,capteur_3) [string index $OneLine 7] 
                        set ::plug($i,calcul,capteur_4) [string index $OneLine 8]
                        set ::plug($i,calcul,capteur_5) [string index $OneLine 9]
                        set ::plug($i,calcul,capteur_6) [string index $OneLine 10]
                    }
                    "STOL" {
                        # Pour le calcul, on enl�ve les z�ro � gauche  et si c'est vide c'est que c'est 0
                        set precision [string trimleft [string range $OneLine 5 7] "0"]
                        if {$precision == ""} {set precision 0}
                        set ::plug($i,SEC,precision) [expr $precision / 10.0]
                    }
                    default {
                    }
                }
            }
            close $fid

            if {[file exists $plugXXConfFileName]} {
                array set module_bulcky [::piXML::convertXMLToArray $plugXXConfFileName]
            } else {
                ::piLog::log [clock milliseconds] "info" "::plugXX_load  No XML conf file named [file tail $plugXXConfFileName]"
            }
            
            
            # On affiche les caract�ristiques des prises
            ::piLog::log [clock milliseconds] "info" "Plug $i - REG,type: $::plug($i,REG,type) - REG,sens: $::plug($i,REG,sens) - REG,precision: $::plug($i,REG,precision)"
            ::piLog::log [clock milliseconds] "info" "Plug $i - SEC,type: $::plug($i,SEC,type) - SEC,sens: $::plug($i,SEC,sens) - SEC,etat_prise: $::plug($i,SEC,etat_prise) - SEC,value: $::plug($i,SEC,value) - SEC,precision: $::plug($i,SEC,precision)"
            
        }
        
        incr i

    }
}