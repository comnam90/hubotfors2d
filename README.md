# Scripts for Hubot

This repo contains a number of scripts for use with Hubot, so that you can interact with your Windows Server 2016 Storage Spaces Direct Cluster via Slack Bots

If you need a primer on deploying hubot on windows for running powershell, check here: https://hodgkins.io/chatops-on-windows-with-hubot-and-powershell  
I'll be writing a walkthrough of my own to support these scripts end-to-end in future. 

Currently the VM interactions require VMM to be present. I'll look at refactoring these in future to not rely on VMM.

## Commands:

### get s2d cluster `cluster name`
Output:
* Cluster CPU Usage
* RAM Usage
* S2D Health Status
* \# of VMs
* Cluster IOPS
* Cluster Throughput
* Cluster Latency
* Cluster Disk Capacity

### get s2d volume `volume name`
Output:
* IOPS
* Throughput
* Latency
* Size
* Free Spaces

### get s2d vm `volume name`
Output:
* CPU Usage
* RAM Usage
* \# of Snapshots
* VMM Cloud
* IOPS
* Throughput
* Latency
* Disk Capacity Usage


TODO:
* [ ] Write guide for deploying Hubot on Windows
* [ ] Remove reliance on VMM for some of the VM Stats
* [ ] Tidy up scripts