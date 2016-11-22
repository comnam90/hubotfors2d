# Description:
#   Script to gather Stats on S2D Volume usage
#
# Configuration:
#   S2D_DEFAULT_CLUSTER
#
# Commands:
#   hubot get s2d volume <volume name> - Gets S2D Stats for a Volume 
#   hubot get s2d volume <volume name> <cluster name> - Gets S2D Stats for a Volume on a specific cluster
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
  . .\scripts\Get-S2DVolumeHubot.ps1
  # Edge.js passes an object to PowerShell as a variable - $inputFromJS
  # This object is built in CoffeeScript on line 28 below
  Get-S2DVolumeHubot -Name $inputFromJS.volumeName -Cluster $inputFromJS.clusterName
###
)

# Pull Environment Variables
S2DCluster = process.env.S2D_DEFAULT_CLUSTER

module.exports = (robot) ->
  # Capture the user message using a regex capture to find the name of the volume
  robot.respond /get s2d volume (.*)$/i, (msg) ->
    # Check for Environment Variables
    unless S2DCluster?
        msg.send ":gear: Environment Variable ``S2D_DEFAULT_CLUSTER`` has not been set in the config."
        return

    # Set the slack input to a varaible
    slackInput = msg.match[1]
    
    # Check for manual cluster input
    splitinputs = msg.match[1].split " "
    count = (k for own k of splitinputs).length
    if count is 1
        volumeName = slackInput
    else
        volumeName = splitinputs[0]
        S2DCluster = splitinputs[1]

    # Build an object to send to PowerShell
    psObject = {
      volumeName: volumeName
      clustername: S2DCluster
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
            # Build a string to send back to the channel and include the output (this comes from the JSON output)
            msg.send 
                attachments: [
                    fallback: "#{result.output.Name} Stats: #{result.output.IOPS}"
                    text: "#{result.output.Name}"
                    pretext: "Here are your stats!"
                    title: "Volume"
                    fields: [
                        title: "IOPS"
                        value: "#{result.output.IOPS}"
                        short: true
                    ,
                        title: "Bandwidth"
                        value: "#{result.output.Bandwidth}"
                        short: true
                    ,
                        title: "Latency"
                        value: "#{result.output.Latency}"
                        short: true
                    ,
                        title: "Size"
                        value: "#{result.output.Size}"
                        short: true
                    ,
                        title: "Available Space"
                        value: "#{result.output.Available}"
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