# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Lecture des arguments : seul le path du fichier XML est donné en argument
set confXML                 [lindex $argv 0]

set moduleLocalName serverMail

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools
package require piTime
package require piXML

# Chargement des fichiers externes
source [file join $rootDir ${::moduleLocalName} src serveurMessage.tcl]

package require smtp
package require mime

# Initialisation d'un compteur pour les commandes externes envoyées
set TrameIndex 0

# On initialise la conf XML
array set configXML {
    verbose     debug
    serverSMTP  NA
    port        25
    username    NA
    password    NA
}

# Chargement de la conf XML
set RC [catch {
    array set configXML [::piXML::convertXMLToArray $confXML]
} msg]
if {$RC != 0} {
    ::piLog::log [clock milliseconds] "error" "$msg"
}

# On initialise la connexion avec le server de log
::piLog::openLog $::piServer::portNumber(serverLog) ${::moduleLocalName} $configXML(verbose)

::piLog::log [clock milliseconds] "info" "starting ${::moduleLocalName} - PID : [pid]"
::piLog::log [clock milliseconds] "info" "port ${::moduleLocalName} : $::piServer::portNumber(${::moduleLocalName})"
::piLog::log [clock milliseconds] "info" "confXML : $confXML"
# On affiche les infos dans le fichier de debug
foreach element [array names configXML] {
    if {$element != "password"} {
        ::piLog::log [clock milliseconds] "info" "$element : $configXML($element)"
    }
}


proc bgerror {message} {
    ::piLog::log [clock milliseconds] error_critic "bgerror in $::argv - pid [pid] -$message-"
}

# Load server
::piLog::log [clock millisecond] "info" "starting serveur"
::piServer::start messageGestion $::piServer::portNumber(${::moduleLocalName})
::piLog::log [clock millisecond] "info" "serveur is started"

proc stopIt {} {
    ::piLog::log [clock milliseconds] "info" "Start stopping ${::moduleLocalName}"
    set ::forever 0
    ::piLog::log [clock milliseconds] "info" "End stopping ${::moduleLocalName}"
    
    # Arrêt du server de log
    ::piLog::closeLog
}

proc send_email {to subject body} { 

    set token [mime::initialize -canonical "text/plain" -encoding "7bit" -string $body]
      mime::setheader $token Subject $subject
      smtp::sendmessage $token \
                    -servers [list $::configXML(serverSMTP)] -ports [list $::configXML(port)]\
                    -usetls true\
                    -debug true\
                    -username $::configXML(username) \
                    -password $::configXML(password) \
                    -queue false\
                    -atleastone true\
                    -header [list From $::configXML(username)] \
                    -header [list To $to] \
                    -header [list Subject $subject]\
                    -header [list Date "[clock format [clock seconds]]"]
      mime::finalize $token
} 

vwait forever

# tclsh "D:\CBX\cultipiCore\serverMail\serverMail.tcl" 6015 "D:\CBX\cultipiCore\serverMail\confExample\conf.xml" 6003 6000
# tclsh /opt/cultipi/serverMail/serverMail.tcl 6015 /etc/cultipi/01_defaultConf_RPi/./serverMail/conf.xml 6003 6000
