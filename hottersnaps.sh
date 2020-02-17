#!/bin/bash
# This file is part of the proxmox-hottersnaps https://github.com/knutztar/proxmox-hottersnaps,
#
# This source file is available under GNU General Public License version 3 (GPLv3)
# Full copyright and license information is available in
# LICENSE.md which is distributed with this source code.
#

#Default settings
    #Name of snapshots (prefix)
    lts=lts;
    sts=sts;
    #Interval of automated snapshots in days (1-14)
    ltsInterval=7;
    stsInterval=1;
    snapshotTime=0; 
    #Life time of snapshots i days.
    ltsLife=30;
    stsLife=14; 
    #include ram
    savestate=1;

#Default vars
    BIYellow='\e[1;93m';     # Yellow
    BIRed='\e[1;91m';        # Red
    NC='\033[0m';            # No Color
    
#Files
    cronFile="/etc/cron.d/hottersnaps";
    tmpCron="/tmp/hottersnaps$(date +%s)";
    configFile="/etc/hottersnaps/config.conf";
    installationFile="/usr/bin/hottersnaps";

#Config file
#Checks and warnings
if [[ ! -r $configFile ]]; then
    echo -e "${BIYellow}Warning: configuration file missing (${configFile})${NC}";
else 
    source $configFile;
fi;
#Check for cron file and warn.
if [[ ! -w $cronFile ]] && [[ ! "${1}" =  "install-cron" ]]; then
    echo -e "${BIYellow}Cron file not installed. Automated snapshots is not enabled.${NC}";
fi;

    
#Datestamp lts and sts
    dateStamp=$(date +%Y%m%d);
    ltsDate="${lts}${dateStamp}";
    stsDate="${sts}${dateStamp}";
    currentTime=$(date +%s);
    

function helpmenu() {
    echo "proxmox-hottersnaps - GNU General Public License version 3 (GPLv3)";
    echo "Copyright (C) 2020 knutztar (https://github.com/knutztar)";
    echo "";
    echo "Usage:";
    echo "      hottersnaps command";
    echo "";
    echo "Commands:";
    echo "      lts             - Take long term snapshots of all VM's and CT's";
    echo "      sts             - Take short term snapshots of all VM's and CT's";
    echo "      cleanup         - Cleanup old snapshots";
    echo "      install-cron    - Install cron file for automated snapshots";
    echo "      update-cron     - Update cron file for automated snapshots";
    echo "      delete-all      - Warning: Delete all snapshots created by hottersnaps";
}

function snapshot(){
    #Snapshot all vm and ct.
    #Usage snapshot prefix i.e. snapshot "lts"
    if [[ ! $# -eq 0 ]]; then 
        snapname=$1;
        
        echo "Snapshotting vitual machines";
        while read vm; do
            vmno=$(echo $vm | awk '/[0-9]/{print $1}');
            vmname=$(echo $vm | awk '/[0-9]/{print $2}');
            if [ ! -z "$vmno" ]; then
                echo "VM ${vmno} ${vmname}:";
                qm snapshot $vmno $snapname --description "hottersnaps snapshot" --vmstate $savestate;
            fi;
        done < <(qm list);
        echo
        
        echo "Snapshotting containers";
        while read ct; do
            ctno=$(echo $ct | awk '/[0-9]/{print $1}');
            ctname=$(echo $ct | awk '/[0-9]/{print $3}');
            if [ ! -z "$ctno" ]; then
                echo "CT ${ctno} ${ctname}:";
                pct snapshot $ctno $snapname --description "hottersnaps snapshot";
            fi;
        done < <(pct list);
        echo 
        
    else
        echo "Error snapshots(): No argument passed.";
        exit 1;
    fi;

}

function cleanup(){
    #Cleanup all old snapshots
    
    case "$1" in
    $lts) 
        cleanupLife=$ltsLife;
        snapFind=$lts;
        ;;
    $sts) 
        cleanupLife=$stsLife;
        snapFind=$sts;
        ;;
    *) 
        echo "Error cleanup(): Wrong argument(s) passed.";
        exit 1;
        ;;
    esac

    while read vm; do
        vmno=$(echo $vm | awk '/[0-9]/{print $1}');
        vmname=$(echo $vm | awk '/[0-9]/{print $2}');
        if [[ ! -z "$vmno" ]]; then
        
            while read snap; do
                snapname=$(echo $snap | awk '/[0-9]/{print $2}');
                snapdate=$(echo $snap | awk '/[0-9]/{print $3}');
                if [[ $snap == *"${snapFind}"* ]]; then
                    
                    #Calculate deletion date for current snapshot
                    ltsDeleteTime=$(date -d "${snapdate} +${cleanupLife} days" +%s);
                    
                    if [[ $currentTime -gt $ltsDeleteTime ]]; then
                        echo "Found old snapshot ${snapname} for virtual machine ${vmno} ${vmname}";
                        qm delsnapshot $vmno $snapname
                    fi;
                    
                fi;
            done < <(qm listsnapshot $vmno);

        fi;
    done < <(qm list);
    
    while read ct; do
        ctno=$(echo $ct | awk '/[0-9]/{print $1}');
        ctname=$(echo $ct | awk '/[0-9]/{print $2}');
        if [[ ! -z "$ctno" ]]; then
        
            while read snap; do
                snapname=$(echo $snap | awk '/[0-9]/{print $2}');
                snapdate=$(echo $snap | awk '/[0-9]/{print $3}');
                if [[ $snap == *"${snapFind}"* ]]; then
                    
                    #Calculate deletion date for current snapshot
                    ltsDeleteTime=$(date -d "${snapdate} +${cleanupLife} days" +%s);
                    
                    if [[ $currentTime -gt $ltsDeleteTime ]]; then
                        echo "Found old snapshot ${snapname} for container ${ctno} ${ctname}";
                        pct delsnapshot $ctno $snapname
                    fi;
                    
                fi;
            done < <(pct listsnapshot $ctno);

        fi;
    done < <(pct list);
    
}

function install-cron(){
    
    crontab -l > $tmpCron;
    
    # Delete currently installed hottesnaps
    sed -i '/.*hottersnaps.*/d' $tmpCron
    
    if [[ ! -w $tmpCron ]]; then 
        echo "Error: No write permission for file ${tmpCron}";
        exit 1;
    fi;
    
    if [[ ! -r $installationFile ]]; then 
        echo -e "${BIRed}Error: hottersnaps not installed (${installationFile})${NC}";
        exit 1;
    fi;
    
    echo "# hottersnaps CRON file for automated snapshotting" >> $tmpCron;
    echo "# hottersnaps Do not edit. This will be overwritten" >> $tmpCron;
    echo "0 ${snapshotTime} */${ltsInterval} * * root ${installationFile} lts > /dev/null" >> $tmpCron;
    echo "0 ${snapshotTime} */${stsInterval} * * root ${installationFile} sts > /dev/null" >> $tmpCron;
    echo "0 ${snapshotTime} * * * root ${installationFile} cleanup > /dev/null" >> $tmpCron;
    echo "*/10 * * * * root ${installationFile} update-cron > /dev/null" >> $tmpCron;    
    
    crontab $tmpCron;
    rm $tmpCron;
    
}

case "$1" in
    "lts") 
        echo
        echo "Snapshotting for long term storage";
        snapshot $ltsDate;
        exit 0;
        ;;
    "sts") 
        echo
        echo "Snapshotting for short term storage";
        snapshot $stsDate;
        exit 0;
        ;;
    "cleanup") 
        echo
        echo "Performing long term cleanup";
        cleanup $lts;
        echo
        echo "Performing short term cleanup";
        cleanup $sts;
        echo
        echo "Cleanup complete";
        exit 0;
        ;;
    "install-cron")
        echo
        echo "Installing cron";
        install-cron;
        exit 0;
        ;;
    "update-cron")
        echo
        echo "Update cron";
        install-cron;
        exit 0;
        ;;
    "delete-all")
        echo
        echo "Removing ALL hottersnaps snapshots";
        ltsLife=0;
        stsLige=0;
        cleanup $lts;
        cleanup $sts;
        exit 0;
        ;;
    *) 
        helpmenu
        exit 0;
        ;;
esac


