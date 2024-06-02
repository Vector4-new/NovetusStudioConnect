# Vector4.new, 19/07/2023, rewritten 01/06/2024
# A script allowing you to connect to Novetus servers with Studio tools.

param(
    [Parameter(Mandatory, Position=0, HelpMessage="The client version to use.")] [string] $ClientVersion,
    [Parameter(Mandatory, Position=1, HelpMessage="The username of your player. Ignored in ghost mode.")] [string] $Username,
    [Parameter(Mandatory, Position=2, HelpMessage="The user ID of your player. Ignored in ghost mode.")] [int32] $UserID,
    [Parameter(Mandatory, Position=3, HelpMessage="The server IP to connect to.")] [string] $ServerIP,
    [Parameter(Mandatory, Position=4, HelpMessage="The server port.")] [uint16] $ServerPort,
    
    [Parameter(HelpMessage="If set, does not create a player character, and just connects to the server.")] [switch] $Ghost,
    [Parameter(HelpMessage="If set, forces your tripcode to this value. Ignored in ghost mode.")] [string] $Tripcode
)
    
$ErrorActionPreference = "Stop"

$clientDirectory = "$PSScriptRoot/clients/$ClientVersion"

if (!(Test-Path -Path "$clientDirectory")) {
    "Can't find client version $ClientVersion."
    "Is the script in the same directory as the bootstrapper?"

    exit
}

# parse customization
if (!(Test-Path -Path "$PSScriptRoot/config/config_customization.ini")) {
    "WARN: Customization file is missing!"
    "Using default customization."

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

# generate tripcode if none was given and also validate any given ones
if (!$Tripcode) {
    $Tripcode = ""

    for (($i = 0); $i -lt 56; $i++) {
        $Tripcode += $("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" | Get-Random)
    }
}

$Tripcode = $Tripcode.ToUpper()

if (($Tripcode | Select-String -Pattern "[^0-9A-F]") -or ($Tripcode.Length -ne 56)) {
    "Tripcode is not in a valid format."
    "Tripcodes must be 56 characters long, and only contain hex digits."

    exit
}

$clientMD5 = $(Get-FileHash "$clientDirectory/RobloxApp_client.exe" -Algorithm MD5).Hash
$scriptMD5 = $(Get-FileHash "$clientDirectory/content/scripts/CSMPFunctions.lua" -Algorithm MD5).Hash
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

$data = $(Decrypt $(Get-Content "$clientDirectory/clientinfo.nov")).Split("|")
$validatedFiles = $(Select-String -InputObject $(Decrypt $data[$data.Length - 1]) -Pattern "<\s*validate\s*>" -AllMatches).Matches.Count
$fix2007 = $(Decrypt $data[8]).ToLower() 

"Client: $ClientVersion`n"

if (!$Ghost) {
    "Username: $Username"
    "User ID: $UserID"
    "Tripcode: $Tripcode`n"

    "Client MD5: $clientMD5"
    "Script MD5: $scriptMD5"
    "Launcher MD5: $launcherMD5"
    "Validated files: $validatedFiles`n"
}
else {
    "Ghost mode enabled, no player or security data."
    "NOTE: Ghost mode WILL LEAK YOUR IP if they look in the NetworkServer object!`n"
}

$connectCode = "_G.CSConnect($UserId, '$ServerIP', $ServerPort, '$Username', '$Hat1', '$Hat2', '$Hat3', $HeadColorID, $TorsoColorID, $LeftArmColorID, $RightArmColorID, $LeftLegColorID, $RightLegColorID, '$TShirt', '$Shirt', '$Pants', '$Face', '$Head', '$Icon', '$Extra', '$clientMD5', '$launcherMD5', '$scriptMD5', '$Tripcode', $validatedFiles, false)"

if (!$Ghost) {
    $source = "dofile('rbxasset://scripts\\CSMPFunctions.lua') $connectCode"
}
else {
    $needPatch = $false

    if (!(Test-Path -Path "$clientDirectory/content/scripts/NSC_CSMPFunctions.lua")) {
        $needPatch = $true
    }
    else {
        if (!((Get-Content -Raw -Path "$clientDirectory/content/scripts/NSC_CSMPFunctions.lua") -match "--CSMPMD5:[A-F0-9]{32}")) {
            $needPatch = $true
        }
        else {
            if ($Matches[0] -ne ((Get-FileHash -Path "$clientDirectory/content/scripts/CSMPFunctions.lua" -Algorithm MD5).Hash)) {
                $needPatch = $true
            }
        }
    }

    if ($needPatch) {
        # bad hack. we basically just remove any code that handles creating the player
        $csmpSource = "$(Get-Content -Raw -Path "$clientDirectory/content/scripts/CSMPFunctions.lua")"

        $csmpSource = "--CSMPMD5:$((Get-FileHash -Path "$clientDirectory/content/scripts/CSMPFunctions.lua" -Algorithm MD5).Hash)`n$csmpSource"

        # this has multiple hits but its fine
        $csmpSource = $csmpSource -replace "player\s*=\s","player = Instance.new(`"Model`") --"
        $csmpSource = $csmpSource -replace ":SetSuperSafeChat",":children"
        $csmpSource = $csmpSource -replace ".CharacterAppearance\s*=.*`n",":children()`n"

        [System.IO.File]::WriteAllLines("$clientDirectory/content/scripts/NSC_CSMPFunctions.lua", $csmpSource)
    }

    $source += "dofile('rbxasset://scripts\\NSC_CSMPFunctions.lua') $connectCode"
}

# 2007's -script parameter accepts files instead of a script source.
# So we need to make a file, put our source in there, and then pass the file over
if ($fix2007 -eq "true") {
    $tempFile = $(New-TemporaryFile).FullName
    
    "Fixing 2007..."
    "Created temporary file $tempFile"

    # Attempting to just write the string will write it as UTF-16.
    # We need a UTF-8 file, so the client can read it properly and not crash.
    [System.IO.File]::WriteAllLines($tempFile, $source)

    $cmdline = $tempFile
}
else {
    $cmdline = $source
}

"Final invoke:"
"$clientDirectory/RobloxApp_studio.exe -script `"$cmdline`""

& "$clientDirectory/RobloxApp_studio.exe" -script "$cmdline"