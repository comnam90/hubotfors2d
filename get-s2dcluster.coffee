# Description:
#   Script to gather Stats on cluster usage 
#
# Commands:
#   hubot get s2d cluster <cluster name> - Gets cluster Stats for a specific cluster
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md



 
# Require the edge module we installed
edge = require("edge")

# Build the PowerShell that will execute
executePowerShell = edge.func('ps', -> ###
  # Dot source the function
  . .\scripts\Get-S2DClusterHubot.ps1
  # Edge.js passes an object to PowerShell as a variable - $inputFromJS
  # This object is built in CoffeeScript on line 28 below
  Get-S2DClusterHubot -Name $inputFromJS.ClusterName
###
)

module.exports = (robot) ->
  # Capture the user message using a regex capture to find the name of the cluster
  robot.respond /get s2d cluster (.*)$/i, (msg) ->
  
    # Set the Cluster name to a varaible
    clusterName = msg.match[1]

    # Build an object to send to PowerShell
    psObject = {
      clusterName: clusterName
    }

    # Build the PowerShell callback
    callPowerShell = (psObject, msg) ->
      executePowerShell psObject, (error,result) ->
        # If there are any errors that come from the CoffeeScript command
        if error
          msg.send ":fire: An error was thrown in Node.js/CoffeeScript"
          msg.send error
        else
          # Capture the PowerShell outpout and convert the JSON that the function returned into a CoffeeScript object
          result = JSON.parse result[0]

          # Output the results into the Hubot log file so we can see what happened - useful for troubleshooting
          console.log result

          # Check in our object if the command was a success (checks the JSON returned from PowerShell)
          # If there is a success, prepend a check mark emoji to the output from PowerShell.
          if result.success is true
            # Build an attachment to send back to the channel and include the output (this comes from the JSON output)
            msg.send 
                attachments: [
                    fallback: "#{result.output.Name} Stats: #{result.output.CPU} CPU, #{result.output.IOPS} IOPS" 
                    text: "#{result.output.Name}"
                    pretext: "Here are your stats!"
                    title: "Cluster"
                    fields: [
                        title: "CPU Usage"
                        value: "#{result.output.CPU}"
                        short: true
                    ,
                        title: "RAM Free"
                        value: "#{result.output.RAM}/#{result.output.RAMTotal}"
                        short: true
                    ,
                        title: "S2D Status"
                        value: "#{result.output.Health}"
                        short: true
                    ,
                        title: "VMs"
                        value: "#{result.output.VMs}"
                        short: true
                    ,
                        title: "Disk IOPS"
                        value: "#{result.output.IOPS}"
                        short: true
                    ,
                        title: "Disk Bandwidth"
                        value: "#{result.output.Bandwidth}"
                        short: true
                    ,
                        title: "Disk Latency"
                        value: "#{result.output.Latency}"
                        short: true
                    ,
                        title: "Disk Usage"
                        value: "#{result.output.DiskUsage}"
                        short: true
                        ]
                    color: "good"
                ]
          # If there is a failure, prepend a warning emoji to the output from PowerShell.
          else
            # Build a string to send back to the channel and include the output (this comes from the JSON output)
            msg.send ":warning: #{result.output}"

    # Call PowerShell function
    callPowerShell psObject, msg