<#
.Synopsis
    Gets S2D stats for a cluster volume.
.DESCRIPTION
    Gets S2D stats for a cluster volume.
.EXAMPLE
    Get-S2DVolumeHubot -Name Volumename
#>
function Get-S2DVolumeHubot
{
    [CmdletBinding()]
    Param
    (
        # Name of the Volume
        [Parameter(Mandatory=$true)]
        $Name,
        # Name of the Volume
        [Parameter(Mandatory=$true)]
        $Cluster
    )

    # Create a hashtable for the results
    $result = @{}

    # Use try/catch block            
    try
    {
        # Create a hashtable for the output
        $output = @{}

        # Use ErrorAction Stop to make sure we can catch any errors
        $volumeqos = Invoke-Command -ComputerName $Cluster -ScriptBlock {
            $Mountpoint = (Get-ClusterSharedVolume -Name "*$($Using:Name)*" -ErrorAction Stop).SharedVolumeInfo.FriendlyVolumeName
            Get-StorageQoSVolume -Mountpoint "$($Mountpoint)\" -ErrorAction Stop
        } -ErrorAction Stop
        $volume = Invoke-Command -ComputerName $Cluster -ScriptBlock {
            Get-Volume -FileSystemLabel $Using:Name -ErrorAction Stop | Get-StorageHealthReport -ErrorAction Stop
        } -ErrorAction Stop

        # Create an attachment for sending back to slack. * and ` are used to make the output look nice in Slack. Details: http://bit.ly/MHSlackFormat
        $output.Name = "$($volumeqos.mountpoint.split("\")[2])"
        $output.IOPS = "$("{0:N0}" -f $volumeqos.IOPS) IOPS"
        $output.Bandwidth = "$("{0:N1}" -f ($volumeqos.Bandwidth/1MB)) MB/s"
        $output.Latency = "$("{0:N1}" -f ($volumeqos.Latency/10000))ms"
        $output.Size = "$("{0:N1}" -f (($volume[0].ItemValue.Records | ?{$_.Name -eq 'CapacityTotal'}).value/1TB))TB"
        $output.Available = "$("{0:N0}" -f (($volume[0].ItemValue.Records | ?{$_.Name -eq 'CapacityAvailable'}).value/1GB))GB"
        $result.Add("output",$output)

        # Set a successful result
        $result.success = $true
    }
    catch
    {
        # If this script fails we can assume the volume did not exist
        $result.output = "Volume ``$($Name)`` does not exist on the cluster $Cluster."
        
        # Set a failed result
        $result.success = $false
    }
    
    # Return the result and conver it to json
    return $result | ConvertTo-Json
}