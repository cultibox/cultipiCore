#!/usr/bin/tclsh

# Init directory
set rootDir [file dirname [file dirname [info script]]]

# Load lib
lappend auto_path [file join $rootDir lib tcl]
package require piLog
package require piServer
package require piTools


::piLog::openLogAs "none"

set module   [lindex $argv 0]
set adresseIP [lindex $argv 1]

#puts "Reading variable [lrange $argv 1 [expr $argc - 1]] of module $module"


# Demande d'écriture du repere
# Trame standard : [FROM] [INDEX] [commande] [argument]
::piServer::sendToServer $::piServer::portNumber($module) "$::piServer::portNumber(serverSet) 0 setRepere [lrange $argv 2 [expr $argc - 1]]" $adresseIP


# tclsh /opt/cultipi/cultiPi/set.tcl serverPlugUpdate localhost 1 on 10
# tclsh "C:\cultibox\04_CultiPi\01_Software\01_cultiPi\cultiPi\set.tcl" serverPlugUpdate localhost 1 on 10

