#!/bin/bash
# This file is part of the proxmox-hottersnaps https://github.com/knutztar/proxmox-hottersnaps,
#
# This source file is available under GNU General Public License version 3 (GPLv3)
# Full copyright and license information is available in
# LICENSE.md which is distributed with this source code.
#

hottersnaps="./hottersnaps.sh";
sampleconf="./config.conf-sample";

#Installation paths.
    cronFile="/etc/cron.d/hottersnaps";
    configFile="/etc/hottersnaps/config.conf";
    installationFile="/usr/bin/hottersnaps";

#Checks and warnings
if [ ! -r $hottersnaps ]; then
    echo "Error: ${hottersnaps} does not exist. Installation failed";
    exit 1;
fi;

# Variables installationFile and configFile found in hottersnaps.

touch $installationFile > /dev/null 2>&1;

if [ ! -w $installationFile ]; then 
    echo "Error: no write permissions ($installationFile)";
    exit 1;
fi;

echo "Installing hottersnaps"
#Copy hottersnaps
cp $hottersnaps "$installationFile";
chmod +x $installationFile;

#Copy config file
if [[ ! -f $configFile ]] ; then 
    mkdir -p "$(dirname "${configFile}")";
    cp "${sampleconf}" "${configFile}";
fi;

hottersnaps install-cron
