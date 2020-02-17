# proxmox-hottersnaps
Snapshotting tool to create retentive snapshots for long term snapshots (lts) and short term snapshots (sts).

## Installation
On your proxmox installation run the following.
```bash
git clone https://github.com/knutztar/proxmox-hottersnaps.git
cd proxmox-hottersnaps
./install.sh
```

### Uninstall
```bash
rm /etc/hottersnaps/config.conf; rm /usr/bin/hottersnaps;
#Remove hottersnaps from cron
crontab -e
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

## Configuration

### Naming prefix
```bash
lts=lts
sts=sts
```
The snapshots created by hottersnaps will in this case be called, if snapshotted on date 2020-02-16, lts20200616 and sts20200616 for long term and short term snapshots. 

### Snapshot times
```bash
ltsInterval=7
stsInterval=1
snapshotTime=2
```
Long term snapshots will in this case happen every 7 days and short term every 1 days at the snapshot time in hours i.e. at 02:00 (24H clock).

### Lifetime of snapshots
```bash
ltsLife=30
stsLife=14
```
Long term snapshots will be saved for 30 days and short term for 7.

### Misc. settings
```bash
savestate=1
```
Virtual machines will be saved with RAM in this case. 

## Example snapshot
Snapshot view after hottersnaps have taken an lts snapshot. 
If configured as above, after 30 days the below snapshot will be deleted and the snapshots with the "backup" prefix will remain.
When running the command delete-all all non-hottersnaps snapshots will remain as well. Hottersnaps searches for only snapshots with the configured prefixes.
![Image of snapshots](https://raw.githubusercontent.com/knutztar/proxmox-hottersnaps/master/screenshots/Screenshot_20200216_212240.png)

## Have fun!
If you find any issues, you are very welcome to create an issue. 
Fork, have fun and pull!
