<#
.Synopsis
    Gets stats for a VM.
.DESCRIPTION
    Gets stats for a VM.
.EXAMPLE
    Get-S2DVMHubot -Name VMName -VMMServer VMMServerName
#>
function Get-S2DVMHubot
{
    [CmdletBinding()]
    Param
    (
        # Name of the VM
        [Parameter(Mandatory=$true)]
        $Name,
        # Name of the VMM Server
        [Parameter(Mandatory=$true)]
        $VMMServer
    )

    # Create a hashtable for the results
    $result = @{}
    
    # Use try/catch block            
    try
    {
        $output = @{}

        # Use ErrorAction Stop to make sure we can catch any errors
        $SCVM = Invoke-Command -ComputerName $VMMServer -ScriptBlock {
            Get-SCVirtualMachine -Name $Using:Name -ErrorAction Stop
        } -ErrorAction Stop

        $PerfCounters = Invoke-Command -ComputerName $SCVM.VMHost -ScriptBlock {
            ((Get-Counter -Counter "\Hyper-V Hypervisor Virtual Processor($($Using:SCVM.Name)*)\% Guest Run Time" -ErrorAction Stop).countersamples | measure -Property cookedvalue -Average).Average
        } -ErrorAction Stop

        $VMQoS = Invoke-Command -ComputerName $SCVM.VMHost -ScriptBlock {
            Get-StorageQoSFlow -InitiatorName $Using:SCVM.Name 
        } -ErrorAction Stop

        $VMDisk = Invoke-Command -ComputerName $VMMServer -ScriptBlock {
            $SQLQuery = "SELECT        TOP (100) PERCENT dbo.tbl_WLC_VObject.Name AS VM, dbo.tbl_WLC_VMInstance.VMTotalMaxSize, dbo.tbl_WLC_VMInstance.VMTotalSize
                         FROM            dbo.tbl_WLC_VMInstance INNER JOIN
                         dbo.tbl_WLC_VObject ON dbo.tbl_WLC_VMInstance.ObjectId = dbo.tbl_WLC_VObject.ObjectId
                         WHERE        (dbo.tbl_WLC_VObject.Name = N'$($Using:SCVM.Name)')
                         ORDER BY VM"
            Invoke-Sqlcmd -ServerInstance localhost\scvmm -Database virtualmanagerdb -Query $SQLQuery -ErrorAction Stop
        } -ErrorAction Stop

        $output.Name = $scvm.Name
        $output.CPU = ("{0:N0}" -f $PerfCounters)+"%"
        $output.CPUCores = "($($SCVM.CPUCount) vCPU)"
        $output.RAM = "$(100-$SCVM.MemoryAvailablePercentage)%"
        $output.RAMTotal = "($('{0:N2}' -f (($SCVM.Memory*((100-$SCVM.MemoryAvailablePercentage)/100))/1024))GB/$('{0:N1}' -f ($SCVM.Memory/1024))GB)"
        $output.IOPS = "$('{0:N0}' -f ($VMQoS | measure -property InitiatorIOPS -Sum).sum) IOPS"
        $output.Bandwidth = "$('{0:N1}' -f (($VMQoS | measure -property InitiatorBandwidth -Sum).sum/1MB)) MB/s"
        $output.Latency = "$('{0:N1}' -f (($VMQoS | measure -property InitiatorLatency -Average).Average/10000))ms"
        $output.Cloud = "$($SCVM.Cloud)"
        $output.Snapshots = "$($SCVM.VMCheckpoints.Count)"
        $output.DiskUsage = "$('{0:N0}' -f (($VMDisk.VMTotalSize)/1GB))GB/$('{0:N0}' -f (($VMDisk.VMTotalMaxSize)/1GB))GB"
        $result.Add("output",$output)

        # Set a successful result
        $result.success = $true
    }
    catch
    {
        # If this script fails we can assume the VM did not exist
        $result.output = "VM ``$($Name)`` does not exist."
        
        # Set a failed result
        $result.success = $false
    }
    
    # Return the result and conver it to json
    return $result | ConvertTo-Json
}