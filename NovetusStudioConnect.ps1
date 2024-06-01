# Vector4.new, 19/07/2023, rewritten 01/06/2024
# A script allowing you to connect to Novetus servers with Studio tools.

param(
    [Parameter(Mandatory, Position=0, HelpMessage="The client version to use.")] [string] $ClientVersion,
    [Parameter(Mandatory, Position=1, HelpMessage="The username of your player. Ignored in ghost mode.")] [string] $Username,
    [Parameter(Mandatory, Position=2, HelpMessage="The user ID of your player. Ignored in ghost mode.")] [int32] $UserID,
    [Parameter(Mandatory, Position=3, HelpMessage="The server IP to connect to.")] [string] $ServerIP,
    [Parameter(Mandatory, Position=4, HelpMessage="The server port.")] [uint16] $ServerPort,

    [Parameter(HelpMessage="If set, does not create a player character, and just connects to the server.")] [switch] $Ghost,
    [Parameter(HelpMessage="If set, forces your tripcode to this value.")] [string] $Tripcode
)