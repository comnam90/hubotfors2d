<#
.Synopsis
    Gets stats for a S2D Cluster.
.DESCRIPTION
    Gets stats for a S2D Cluster.
.EXAMPLE
    Get-S2DClusterHubot -Name ClusterName
#>
function Get-S2DClusterHubot
{
    [CmdletBinding()]
    Param
    (
        # Name of the Volume
        [Parameter(Mandatory=$true)]
        $Name
    )

    # Create a hashtable for the results
    $result = @{}
    
    # Use try/catch block            
    try
    {
        $output = @{}

        # Use ErrorAction Stop to make sure we can catch any errors
        $ClusterStats = Invoke-Command -ComputerName $Name -ScriptBlock {
            Get-StorageSubSystem clu*  -ErrorAction Stop | Get-StorageHealthReport -ErrorAction Stop
        } -ErrorAction Stop

        $ClusterHealth = Invoke-Command -ComputerName $Name -ScriptBlock {
            Get-StoragePool S2D* -ErrorAction Stop
        } -ErrorAction Stop

        $ClusterVMs = Invoke-Command -ComputerName $Name -ScriptBlock {
            Get-ClusterResource -ErrorAction Stop | ?{$_.ResourceType -eq 'Virtual Machine'}
        } -ErrorAction Stop

        $health = Switch ($ClusterHealth.HealthStatus){
            "0"{"Healthy"}
            "1"{"Warning"}
            "2"{"Unhealth"}
        }

        $output.Name = "$((Get-Cluster $Name).Name)"
        $output.CPU = "$('{0:N0}' -f ($ClusterStats[0].ItemValue.Records | ?{$_.Name -eq 'CPUUsageAverage'}).value)%"
        $output.RAM = "$('{0:N2}' -f (($ClusterStats[0].ItemValue.Records | ?{$_.Name -eq 'MemoryAvailable'}).value/1TB))TB"
        $output.RAMTotal = "$('{0:N2}' -f (($ClusterStats[0].ItemValue.Records | ?{$_.Name -eq 'MemoryTotal'}).value/1TB))TB"
        $output.IOPS = "$('{0:N0}' -f ($ClusterStats[0].ItemValue.Records | ?{$_.Name -eq 'IOPSTotal'}).value) IOPS"
        $output.Bandwidth = "$('{0:N1}' -f ((($ClusterStats[0].ItemValue.Records | ?{$_.Name -eq 'IOThroughputTotal'}).value)/1MB)) MB/s"
        $output.Latency = "$('{0:N1}' -f (($ClusterStats[0].ItemValue.Records | ?{$_.Name -eq 'IOLatencyAverage'}).value*1000))ms"
        $output.DiskUsage = "$('{0:N1}' -f (($ClusterStats[0].ItemValue.Records | ?{$_.Name -eq 'CapacityVolumesAvailable'}).value/1TB))TB/$('{0:N1}' -f (($ClusterStats[0].ItemValue.Records | ?{$_.Name -eq 'CapacityVolumesTotal'}).value/1TB))TB"
        $output.Health = "$($Health)"
        $output.VMs = "$($ClusterVMs.count)"
        $result.Add("output",$output)

        # Set a successful result
        $result.success = $true
    }
    catch
    {
        # If this script fails we can assume the volume did not exist
        $result.output = "Cluster ``$($Name)`` does not exist."
        
        # Set a failed result
        $result.success = $false
    }
    
    # Return the result and conver it to json
    return $result | ConvertTo-Json
}