#!/usr/bin/tclsh

# Init directory
set rootDir [file dirname [file dirname [info script]]]
set logFile [file join $rootDir log.txt]

puts "Stoping cultiPi"
set rc [catch { set channel [socket localhost 6000] } msg]

if {$rc != 0} {
    puts "Can not connect to CultiPi socket (port 6000)"
    puts "Maybe already closed...."
    exit
}

proc send:data {channel data} \
{
    set rc [catch \
    {
        puts $channel $data
        flush $channel
    } msg]
    if {$rc == 1} { log $msg }
}

# Demande arrêt du server
# Trame standard : [FROM] [INDEX] [commande] [argument]
send:data $channel "NA 0 stop"

# fermeture connexion
close $channel
puts "CultiPi is stopped"
# tclsh "D:\CBX\cultipiCore\cultiPi\cultiPistop.tcl" 
# tclsh /opt/cultipi/cultiPi/cultiPistop.tcl