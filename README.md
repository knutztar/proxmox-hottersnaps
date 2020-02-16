# proxmox-hottersnaps
Snapshotting tool to create retentive snapshots for long term snapshots (lts) and short term snapshots (sts).

## Installation
On your proxmox installation run the following.
```bash
git clone https://github.com/knutztar/proxmox-hottersnaps.git
cd proxmox-hottersnaps
./install.sh
```

## Usage
```bash
#Take long term snapshots of all VM's and CT's
hottersnaps lts

#Take short term snapshots of all VM's and CT's
hottersnaps sts

#Cleanup old snapshots
hottersnaps cleanup

#Install cron file for automated snapshots
hottersnaps install-cron

#Update cron file for automated snapshots
hottersnaps update-cron

#Delete all snapshots created by hottersnaps
hottersnaps delete-all
```

