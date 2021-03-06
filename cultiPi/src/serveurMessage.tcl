
proc messageGestion {message networkhost} {

    global statusInitialisation cultipiActualHour
    
    set ::cultipiActualHour [clock format [clock seconds] -format "%d/%m/%Y %H:%M"]

    # Trame standard : [FROM] [INDEX] [commande] [argument]
    set serverForResponse   [::piTools::lindexRobust $message 0]
    set indexForResponse    [::piTools::lindexRobust $message 1]
    set commande            [::piTools::lindexRobust $message 2]

    switch ${commande} {
        "stop" {
            ::piLog::log [clock milliseconds] "info" "Demande Arret de Culti Pi"
            stopCultiPi
        }
        "_pid" {
            set module [::piTools::lindexRobust $message 3]
            set pid [::piTools::lindexRobust $message 4]
            ::piLog::log [clock milliseconds] "info" "Received pid $pid of $module"
            set ::confStart($module,pid) $pid
        }
        "getPort" {
            set module [::piTools::lindexRobust $message 3]
            ::piLog::log [clock milliseconds] "info" "Asked port of $module"
            # Comme c'est une réponse, le nom du serveur est celui de celui qui a demandé
            ::piServer::sendToServer $serverForResponse "$serverForResponse $indexForResponse _getPort $module $::piServer::portNumber($module)" $networkhost
        }
        "getRepere" {
        
            # Pour toutes les variables demandées
            set indexVar 3
            set returnList ""
            while {[set variable [::piTools::lindexRobust $message $indexVar]] != ""} {
                # La variable est le nom de la variable à lire
                
                ::piLog::log [clock milliseconds] "info" "Asked getRepere $variable by $networkhost"
                
                if {[info exists ::$variable] == 1} {
                
                    eval set returnValue $$variable

                    lappend returnList $returnValue
                } else {
                    ::piLog::log [clock milliseconds] "error" "Asked variable $variable by $networkhost - variable doesnot exists"
                }
                
                incr indexVar
            }

            ::piLog::log [clock milliseconds] "info" "response : $serverForResponse $indexForResponse _getRepere - $returnList - to $networkhost"
            ::piServer::sendToServer $serverForResponse "$serverForResponse $indexForResponse _getRepere $returnList" $networkhost

        }
        "_subscription" -
        "_subscriptionEvenement" {
            # On parse le retour de la commande
            set variable  [::piTools::lindexRobust $message 3]
            set valeur [::piTools::lindexRobust $message 4]
            
            # On enregistre le retour de l'abonnement
            set ::${variable} $valeur
            
            # ::piLog::log [clock milliseconds] "debug" "subscription response : variable $variable valeur -$valeur-"
        }
        default {
            ::piLog::log [clock milliseconds] "error" "Received -${message}- but not interpreted"
        }
    }

    
}
