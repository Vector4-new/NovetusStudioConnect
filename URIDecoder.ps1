# Vector4.new, 02/06/2024
# Decode Novetus URIs

param(
    [Parameter(Mandatory, Position=0, HelpMessage="The URI to decode. Follows the format ``novetus://...``")] [string] $URI
)

$ErrorActionPreference = "Stop"

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

$URI = $URI -replace "^.*://"

$arr = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($URI))).Split("|")

$ip = Decrypt($arr[0])
$port = Decrypt($arr[1])
$version = Decrypt($arr[2])

"Server IP: $ip"
"Server Port: $port"
"Client: $version"