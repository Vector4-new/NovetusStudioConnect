# Vector4.new, 02/06/2024
# Decode Novetus URIs

param(
    [Parameter(Mandatory, Position=0, HelpMessage="The URI to decode. Follows the format ``novetus://...``")] [string] $URI
)

$ErrorActionPreference = "Stop"

$URI = $URI -replace "^.*://"

$arr = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($URI))).Split("|")

$ip = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($arr[0])))
$port = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($arr[1])))
$version = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($arr[2])))

"Server IP: $ip"
"Server Port: $port"
"Client: $version"