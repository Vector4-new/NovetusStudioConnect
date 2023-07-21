# Vector4.new, 19/07/2023
# Updated 20/07/2023: now uses your own outfit.

# Connect to Novetus servers with Studio, without getting kicked for "Modified client".
# Make sure this file is in the same folder as the Novetus bootstrapper.
# Uses your settings/customizations.

# Usage: NovetusStudioConnect.ps1 <client> <user name> <user ID> <server IP> <server port>

$ErrorActionPreference = "Stop"

if ($args.Length -ne 5) {
    "Usage: $($MyInvocation.InvocationName) <client> <user name> <user ID> <server IP> <server port>"
    "P.S.: Make sure this script is in the same folder as the Novetus bootstrapper."

    exit
}

$client = "$PSScriptRoot/clients/$($args[0])"

# Check that client actually exists
if (!(Test-Path -Path $client)) {
    "Can't find client $($args[0])"
    "If the client name ends with an L, wrap it in quotes (e.g. 2010L -> `"2010L`")"
    "P.S.: Make sure this script is in the same folder as the Novetus bootstrapper."

    exit
}

# check for customization
if (!(Test-Path -Path "$PSScriptRoot/config/config_customization.ini")) {
    "Can't find customization file"
    "Using default noob character"

    $Hat1 = "NoHat.rbxm"
    $Hat2 = "NoHat.rbxm"
    $Hat3 = "NoHat.rbxm"
    $Face = "DefaultFace.rbxm"
    $Head = "DefaultHead.rbxm"
    $TShirt = "NoTShirt.rbxm"
    $Shirt = "NoShirt.rbxm"
    $Pants = "NoPants.rbxm"
    $Icon = "NBC"
    $Extra = "NoExtra.rbxm"
    $HeadColorID = 24
    $TorsoColorID = 23
    $LeftArmColorID = 24
    $RightArmColorID = 24
    $LeftLegColorID = 119
    $RightLegColorID = 119

    exit
}
else {
    # I'm not even going to try.
    # Thanks, https://stackoverflow.com/questions/417798/ini-file-parsing-in-powershell
    Function Parse-IniFile ($file) {
    $ini = @{}

    # Create a default section if none exist in the file. Like a java prop file.
    $section = "NO_SECTION"
    $ini[$section] = @{}

    switch -regex -file $file {
        "^\[(.+)\]$" {
        $section = $matches[1].Trim()
        $ini[$section] = @{}
        }
        "^\s*([^#].+?)\s*=\s*(.*)" {
        $name,$value = $matches[1..2]
        # skip comments that start with semicolon:
        if (!($name.StartsWith(";"))) {
            $ini[$section][$name] = $value.Trim()
        }
        }
    }
    $ini
    }

    $loadout = Parse-IniFile "$PSScriptRoot/config/config_customization.ini"

    $Hat1 = $loadout["Items"]["Hat1"]
    $Hat2 = $loadout["Items"]["Hat2"]
    $Hat3 = $loadout["Items"]["Hat3"]
    $Face = $loadout["Items"]["Face"]
    $Head = $loadout["Items"]["Head"]
    $TShirt = $loadout["Items"]["TShirt"]
    $Shirt = $loadout["Items"]["Shirt"]
    $Pants = $loadout["Items"]["Pants"]
    $Icon = $loadout["Items"]["Icon"]
    $Extra = $loadout["Items"]["Extra"]
    $HeadColorID = $loadout["Colors"]["HeadColorID"]
    $TorsoColorID = $loadout["Colors"]["TorsoColorID"]
    $LeftArmColorID = $loadout["Colors"]["LeftArmColorID"]
    $RightArmColorID = $loadout["Colors"]["RightArmColorID"]
    $LeftLegColorID = $loadout["Colors"]["LeftLegColorID"]
    $RightLegColorID = $loadout["Colors"]["RightLegColorID"]
}

# Check that UserID and server port are integers
if (!$($args[2] -as [int])) {
    "Malformed user ID $($args[2])"

    exit
}

if (!$($args[4] -as [int])) {
    "Malformed server port $($args[4])"

    exit
}

$clientMD5 = $(Get-FileHash "$client/RobloxApp_client.exe" -Algorithm MD5).Hash
$scriptMD5 = $(Get-FileHash "$client/content/scripts/CSMPFunctions.lua" -Algorithm MD5).Hash
$launcherMD5 = $(Get-FileHash "$PSScriptRoot/bin/Novetus.exe" -Algorithm MD5).Hash

# Decrypt the clientinfo.nov file
Add-Type -AssemblyName System.Security
Add-Type -AssemblyName System

function Decrypt {
    param ( $str )

    $key = [byte] 1, 2, 3, 4, 5, 6, 7, 8
    $iv = [byte] 1, 2, 3, 4, 5, 6, 7, 8

    $algorithm = [System.Security.Cryptography.DES]::Create()
    $transform = $algorithm.CreateDecryptor($key, $iv)
    $inputBuffer = [System.Convert]::FromBase64String($str)
    $outputBuffer = $transform.TransformFinalBlock($inputBuffer, 0, $inputBuffer.Length)

    return [System.Text.Encoding]::Unicode.GetString($outputBuffer)
}

$data = $(Decrypt $(Get-Content "$client/clientinfo.nov")).Split("|")
$validatedFiles = $(Select-String -InputObject $(Decrypt $data[$data.Length - 1]) -Pattern "<\s*validate\s*>" -AllMatches).Matches.Count
$fix2007 = $(Decrypt $data[8]).ToLower() 

$tripcode = ""

for (($i = 0); $i -lt 56; $i++) {
    $tripcode += $("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" | Get-Random)
}

"Client: $($args[0])`n"

"User name: $($args[1])"
"User ID: $($args[2])"
"Generated tripcode: $tripcode`n"

"Server IP: $($args[3])"
"Server port: $($args[4])`n"

"Client MD5: $clientMD5"
"Script MD5: $scriptMD5"
"Launcher MD5: $launcherMD5"
"Validated files: $validatedFiles`n"

$source = "dofile('rbxasset://scripts\\CSMPFunctions.lua') _G.CSConnect($($args[2]), '$($args[3])', $($args[4]), '$($args[1])', '$Hat1', '$Hat2', '$Hat3', $HeadColorID, $TorsoColorID, $LeftArmColorID, $RightArmColorID, $LeftLegColorID, $RightLegColorID, '$TShirt', '$Shirt', '$Pants', '$Face', '$Head', '$Icon', '$Extra', '$clientMD5', '$launcherMD5', '$scriptMD5', '$tripcode', $validatedFiles, false)"

# 2007's -script parameter accepts files instead of a script source.
# So we need to make a file, put our source in there, and then pass the file over
if ($fix2007 -eq "true") {
    $tempFile = $(New-TemporaryFile).FullName
    
    "Fixing 2007..."
    "Created temporary file $tempFile"
    "Temporary file source: $source`n"

    # Attempting to just write the string will write it as UTF-16.
    # We need a UTF-8 file, so the client can read it properly and not crash.
    [System.IO.File]::WriteAllLines($tempFile, $source)

    $cmdline = $tempFile
}
else {
    $cmdline = $source
}

"Final invoke:"
"$client/RobloxApp_studio.exe -script `"$cmdline`""

& "$client/RobloxApp_studio.exe" -script "$cmdline"