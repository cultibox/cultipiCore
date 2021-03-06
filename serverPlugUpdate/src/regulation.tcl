

proc emeteur_regulation {nbPlug plgPrgm} {

    set errorFind 0

    set programmeToSend $::actualProgramm
    
    # On v�rifie si l'�tat de la derni�re commande envoy�e existe
    if {[array name ::plug -exact $nbPlug,value] == ""} {
        set ::plug($nbPlug,value) ""
    }
    if {[array name ::plug -exact $nbPlug,inRegulation] == ""} {
        set ::plug($nbPlug,inRegulation) "NONE"
    }
    # On cherche le nom du module
    set module $::plug($nbPlug,module)
    
    if {$module == "NA"} {
    
        # Si le nom du module n'est pas d�finit
        ::piLog::log [clock milliseconds] "error" "Plug $nbPlug module is not defined"
        set errorFind 1
        
    } elseif {$plgPrgm == ""} {
    
        # Si le programme n'est pas d�finit
        ::piLog::log [clock milliseconds] "error" "Plug $nbPlug programme is empty"
        set errorFind 1
        
    } elseif {$::sensor(firsReadDone) == 0} {
    
        # Si la premi�re lecture des capteurs n'est pas faite, on inhibe la r�gulation
        ::piLog::log [clock milliseconds] "info" "First read of sensor is not done, regulation of plug $nbPlug inhibited (programme $plgPrgm)"
        set errorFind 1
        
    } elseif {$plgPrgm == "off" || $plgPrgm == "on"} {

        # Si l'�tat � piloter et on ou off, ce n'est vraiment pas normal !
        ::piLog::log [clock milliseconds] "error" "couldnt make regulation with programm $plgPrgm"
        set errorFind 1

    } else {

        # En fonction de la conf la prise doit �tre allum�e ou �teinte en r�gulation secondaire
        set etatSecondaire "off"
        if {$::plug($nbPlug,SEC,etat_prise) == "1"} {
            set etatSecondaire "on"
        }
        
        set valeurToPilot ""
        
        # On v�rifie d'abord si la r�gulations secondaire doit �tre activ�e
        if {$::plug($nbPlug,SEC,type) != "N"} {
        
            # Le calcul de la r�gulation du secondaire est toujours r�alis�e sur la moyenne
            set valueSecondaire [computeValueForRegulation $nbPlug $::plug($nbPlug,SEC,type) "M"]
            set consigneSupSec [expr $::plug($nbPlug,SEC,value) + $::plug($nbPlug,SEC,precision)]
            set consigneInfSec [expr $::plug($nbPlug,SEC,value) - $::plug($nbPlug,SEC,precision)]
        
            # On v�rifie qu'il n'y a pas eu d'erreur lors du calcul 
            if {$valueSecondaire == "ERROR"} {
            
            
            } elseif {$valueSecondaire != ""} {
                # On v�rifie qu'il y a bien une valeur
                
                # Si le sens de la r�gulation est +
                if {$::plug($nbPlug,SEC,sens) == "+"} {
                    # Si la valeur du capteur est sup�rieur � la consigne
                    if {$valueSecondaire > $consigneSupSec} {
                    
                        # On force la prise dans l'�tat d�fini dans la conf
                        set valeurToPilot $etatSecondaire
                        
                        ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regSec+ Sup progr:-$plgPrgm- value:-$valueSecondaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupSec- trigLow:-$consigneInfSec-"
                        
                        # On sauvegarde le fait qu'on est en r�gulation secondaire
                        set ::plug($nbPlug,inRegulation) "SEC"
                        
                    } elseif {$valueSecondaire > $consigneInfSec  && $::plug($nbPlug,inRegulation) == "SEC"} {
                    
                        # Sensor is not upper than consigne but between two marges, keep the last consigne
                        set valeurToPilot $etatSecondaire
                        
                        ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regSec+ Between progr:-$plgPrgm- value:-$valueSecondaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupSec- trigLow:-$consigneInfSec-"
                        
                        # On sauvegarde le fait qu'on est en r�gulation secondaire
                        set ::plug($nbPlug,inRegulation) "SEC"
                        
                    }
                } else {
                    # Sinon le sens de la r�gulation est "-"
                    if {$valueSecondaire < $consigneInfSec}  {
                    
                        # On force la prise dans l'�tat d�fini dans la conf
                        set valeurToPilot $etatSecondaire

                        ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regSec- Inf progr:-$plgPrgm- value:-$valueSecondaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupSec- trigLow:-$consigneInfSec-"

                        # On sauvegarde le fait qu'on est en r�gulation secondaire
                        set ::plug($nbPlug,inRegulation) "SEC"
                        
                    } elseif {$valueSecondaire < $consigneSupSec && $::plug($nbPlug,inRegulation) == "SEC"} {
                    
                        # Sensor is not upper than consigne but between two marges, keep the last consigne
                        # Keep the last consigne only if it was ON
                        set valeurToPilot $etatSecondaire

                        ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regSec- Between progr:-$plgPrgm- value:-$valueSecondaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupSec- trigLow:-$consigneInfSec-"

                        # On sauvegarde le fait qu'on est en r�gulation secondaire
                        set ::plug($nbPlug,inRegulation) "SEC"
                        
                    }
                }
            }        
        }
        
        # Si la r�gulation secondaire n'a pas d�finie de valeur, on applique la r�gulation primaire
        if {$valeurToPilot == ""} {
        
            set valuePrimaire [computeValueForRegulation $nbPlug $::plug($nbPlug,REG,type) $::plug($nbPlug,calcul,type)]
            set consigneSupPri [expr $plgPrgm + $::plug($nbPlug,REG,precision)]
            set consigneInfPri [expr $plgPrgm - $::plug($nbPlug,REG,precision)]
        
            # On v�rifie qu'il n'y a pas eu d'erreur lors du calcul 
            if {$valuePrimaire == "ERROR"} {
            
            
            } elseif {$::plug($nbPlug,REG,sens) == "+"} {
                # Search sens
                # If sens is +, effecteur will be on if temp is upper than consigne
                # ie: ventilator, dehumidificator
                
                # Pas de donn�e des capteurs
                if {$valuePrimaire == ""} {
                    
                    # Par defaut, si on a pas de valeur, on coupe l'effecteur
                    set valeurToPilot "off"
                    
                    # Si c'est un ventilateur, on le met en route
                    if {$::plug($nbPlug,REG,type) == "T"} {
                        set valeurToPilot "on"
                    }

                    ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regPri+ NoSensor progr:-$plgPrgm- value:-$valuePrimaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupPri- trigLow:-$consigneInfPri-"

                    # On sauvegarde le fait qu'on a pas de r�gulation
                    set ::plug($nbPlug,inRegulation) "NONE"
                    
                } elseif {$::plug($nbPlug,module) == "dimmer" || $::plug($nbPlug,module) == "BULCKY"} {
                
                    # On calcul l'erreur entre la consigne et la valeur mesur�e
                    set erreurN     [expr $valuePrimaire - $plgPrgm]
                    set erreurN1    $::plug($nbPlug,regulation,erreurNmoins1)
                    set commandeN1  $::plug($nbPlug,regulation,commandeNmoins1)
                    set Kp          $::plug($nbPlug,regulation,kp)
                    set Ki          $::plug($nbPlug,regulation,ki)
                    set SeuilMin    [format %.2f [expr $::plug($nbPlug,regulation,pourcentMin) / 100.0]]
                    set SeuilMax    [format %.2f [expr $::plug($nbPlug,regulation,pourcentMax) / 100.0]]
                    
                    # On calcul la r�gulation a appliquer :
                    # U = Un-1 + Kp * (erreurN - erreurN-1) + Ki * erreurN 
                    
                    set commande [ expr $commandeN1 + $Kp * ($erreurN - $erreurN1) + $Ki * $erreurN]
                    
                    # On format la commande 
                    set commande [format %.2f $commande]
                    
                    # On seuil la valeur 
                    if {$commande > [expr $SeuilMax / 100.0]} {set valeurToPilot [expr $SeuilMax / 100.0]}
                    if {$commande < [expr $SeuilMin / 100.0]} {set valeurToPilot [expr $SeuilMin / 100.0]}
                
                    # On sauvegarde les valeurs
                    set ::plug($nbPlug,regulation,erreurNmoins1) $erreurN
                    set ::plug($nbPlug,regulation,commandeNmoins1) $commande
                    
                    # on transforme la commande 
                    set valeurToPilot [expr int($commande * 100)]
                
                    # Dimmer case
                    # $valeurToPilot < 0
                    # ie : 0100 < 2800 -  2600
                    # ie $valeurToPilot = -200 = 0100 + ( 2600 - 2800)
                    # if {(int)emeteur_regulation_previous_value[uc8_plug] < ((int)emeteur_regulation_value[uc8_plug] - ($valuePrimaire))} {
                    #     set valeurToPilot 0
                    # } else {
                    #     set valeurToPilot (int)emeteur_regulation_previous_value[uc8_plug] + (($valuePrimaire - (int)emeteur_regulation_value[uc8_plug]));
                    # }

                    # if {$valeurToPilot > 10000} {
                    #     set valeurToPilot 10000;
                    # }

                    ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regPri+ Dimmer progr:-$plgPrgm- value:-$valuePrimaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupPri- trigLow:-$consigneInfPri-"

                    # On sauvegarde le fait qu'on a une r�gulation primaire
                    set ::plug($nbPlug,inRegulation) "PRI"
                    
                } else {
                    # Cas de la prise sans fils
                    if {$valuePrimaire > $consigneSupPri} {
                    
                        # Standard plug case
                        set valeurToPilot "on"

                        ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regPri+ $module Sup progr:-$plgPrgm- value:-$valuePrimaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupPri- trigLow:-$consigneInfPri-"

                        # On sauvegarde le fait qu'on a une r�gulation primaire
                        set ::plug($nbPlug,inRegulation) "PRI"
                        
                    } elseif {$valuePrimaire < $consigneInfPri} {
                    
                        set valeurToPilot "off"

                        ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regPri+ $module Inf progr:-$plgPrgm- value:-$valuePrimaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupPri- trigLow:-$consigneInfPri-"

                        # On sauvegarde le fait qu'on a une r�gulation primaire
                        set ::plug($nbPlug,inRegulation) "PRI"
                        
                    } else {
                    
                        # Pas de r�gulation particuli�re, on est entre les deux seuils
                        ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regPri+ $module between progr:-$plgPrgm- value:-$valuePrimaire- pilot:-No Pilot- trigHigh:-$consigneSupPri- trigLow:-$consigneInfPri-"
                    
                    }

                }
            } else {
                # sens is -
                if {$valuePrimaire == ""} {
                    # Si pas de donn�e capteur, on �teint l'effecteur
                    set valeurToPilot "off"

                    ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regPri- NoSensor progr:-$plgPrgm- value:-$valuePrimaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupPri- trigLow:-$consigneInfPri-"

                        # On sauvegarde le fait qu'on a une r�gulation primaire
                        set ::plug($nbPlug,inRegulation) "NONE"
                    
                } elseif {$::plug($nbPlug,module) == "dimmer"  || $::plug($nbPlug,module) == "BULCKY"} {
                
                    # On calcul l'erreur entre la consigne et la valeur mesur�e
                    set erreurN     [expr $valuePrimaire - $plgPrgm]
                    set erreurN1    $::plug($nbPlug,regulation,erreurNmoins1)
                    set commandeN1  $::plug($nbPlug,regulation,commandeNmoins1)
                    set Kp          $::plug($nbPlug,regulation,kp)
                    set Ki          $::plug($nbPlug,regulation,ki)
                    set SeuilMin    [format %.2f [expr $::plug($nbPlug,regulation,pourcentMin) / 100.0]]
                    set SeuilMax    [format %.2f [expr $::plug($nbPlug,regulation,pourcentMax) / 100.0]]
                    
                    # On calcul la r�gulation a appliquer :
                    # U = Un-1 + Kp * (erreurN - erreurN-1) + Ki * erreurN 
                    
                    set commande [ expr $commandeN1 - $Kp * ($erreurN - $erreurN1) - $Ki * $erreurN]
                    
                    # On format la commande 
                    set commande [format %.2f $commande]
                    
                    # On seuil la valeur 
                    if {$commande > [expr $SeuilMax / 100.0]} {set valeurToPilot [expr $SeuilMax / 100.0]}
                    if {$commande < [expr $SeuilMin / 100.0]} {set valeurToPilot [expr $SeuilMin / 100.0]}
                
                    # On sauvegarde les valeurs
                    set ::plug($nbPlug,regulation,erreurNmoins1) $erreurN
                    set ::plug($nbPlug,regulation,commandeNmoins1) $commande
                    
                    # on transforme la commande 
                    set valeurToPilot [expr int($commande * 100)]
                
                    # Dimmer case
                    # If  $valeurToPilot < 0
                    # if {(int)emeteur_regulation_previous_value[uc8_plug] < (($valuePrimaire) - (int)emeteur_regulation_value[uc8_plug])} {
                    #     set valeurToPilot 0
                    # } else {
                    #     set valeurToPilot (int)emeteur_regulation_previous_value[uc8_plug] - (($valuePrimaire - (int)emeteur_regulation_value[uc8_plug]))
                    # }

                    # if {$valeurToPilot > 10000} {
                    #     set valeurToPilot 10000
                    # }

                    ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regPri- Dimmer progr:-$plgPrgm- value:-$valuePrimaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupPri- trigLow:-$consigneInfPri-"

                } else {
                
                    # Cas de la prise sans fils
                    if {$valuePrimaire < $consigneInfPri} {
                    
                        # Standard plug case
                        set valeurToPilot "on"

                        ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regPri- $module Inf progr:-$plgPrgm- value:-$valuePrimaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupPri- trigLow:-$consigneInfPri-"

                        # On sauvegarde le fait qu'on a une r�gulation primaire
                        set ::plug($nbPlug,inRegulation) "PRI"
                        
                    } elseif {$valuePrimaire > $consigneSupPri} {
                    
                        set valeurToPilot "off"

                        ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regPri- $module Sup progr:-$plgPrgm- value:-$valuePrimaire- pilot:-$valeurToPilot- trigHigh:-$consigneSupPri- trigLow:-$consigneInfPri-"

                        # On sauvegarde le fait qu'on a une r�gulation primaire
                        set ::plug($nbPlug,inRegulation) "PRI"
                        
                    } else {
                    
                        # Pas de r�gulation particuli�re, on est entre les deux seuils
                        ::piLog::log [clock milliseconds] "debug" "plug:-$nbPlug- regPri- $module between progr:-$plgPrgm- value:-$valuePrimaire- pilot:-No Pilot- trigHigh:-$consigneSupPri- trigLow:-$consigneInfPri-"
                    
                    }
                }
            }
        }
        
        # On envoi la commande au module
        if {$valeurToPilot != "" && $valeurToPilot != $::plug($nbPlug,value)} {
            set errorFind [::${module}::setValue $nbPlug $valeurToPilot $::plug($nbPlug,adress)]
        }
    }
    
    return $errorFind
}


proc computeValueForRegulation {nbPlug sensorType computeType} {
        
    # Calcul de la valeur pour r�gulation primaire
    set find 0
    set outValue 0
    # Le coef permet de multiplier par une valeur ce qui est lu
    set coef 1
    
    # On regarde quelle valeur on doit prendre
    switch $sensorType {
        "H" {
            set indexSensorValue 2
        }
        "C" {
            set indexSensorValue 1
            set coef 0.01
        }
        "T" -
        "L" {
            set indexSensorValue 1
        }
        default {
            ::piLog::log [clock milliseconds] "error" "computeValueForRegulation : sensortype $sensorType is not recognize"
            return ""
        }
    }

    switch $computeType {
        "M" {
            set nbValue 0
            for {set i 1} {$i < 7} {incr i} {
                set valeurCapteur $::sensor(${i},value,${indexSensorValue})
                if {$::plug($nbPlug,calcul,capteur_$i) != 0 && $valeurCapteur != "DEFCOM" && $valeurCapteur != ""} {
                    set outValue [expr $outValue + $valeurCapteur]
                    set find 1
                    incr nbValue
                }
            }
            if {$nbValue != 0} {
                set outValue [expr $outValue / (1.0 * $nbValue)]
            }
        }
        "I" {
            set outValue ""
            set nbValue 0
            for {set i 1} {$i < 7} {incr i} {
                set valeurCapteur $::sensor(${i},value,${indexSensorValue})
                if {$::plug($nbPlug,calcul,capteur_$i) != 0 && $valeurCapteur != "DEFCOM" && $valeurCapteur != ""} {
                    if {$outValue == "" || $outValue > $valeurCapteur} {
                        set outValue $valeurCapteur
                        set find 1
                    }
                }
            }
        }
        "A" {
            set outValue ""
            set nbValue 0
            for {set i 1} {$i < 7} {incr i} {
                set valeurCapteur $::sensor(${i},value,${indexSensorValue})
                if {$::plug($nbPlug,calcul,capteur_$i) != 0 && $valeurCapteur != "DEFCOM" && $valeurCapteur != ""} {
                    if {$outValue == "" || $outValue < $valeurCapteur} {
                        set outValue $valeurCapteur
                        set find 1
                    }
                }
            }
        }
    }
    
    if {$find == 0} {
        set outValue ""
    } else {
        set outValue [expr $outValue * $coef]
    }
    
    
    
    if {$outValue > 2000 || $outValue < -30} {
        ::piLog::log [clock milliseconds] "error" "computeValueForRegulation : Value is out of autorized values (val : $outValue , plug $nbPlug , sensorType $sensorType , computeType $computeType, coef $coef)"
        set outValue "ERROR"
    }
    
    return $outValue
}