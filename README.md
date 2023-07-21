# NovetusStudioConnect
A PowerShell script to connect to Novetus servers with Studio tools.

# Usage
Put the PowerShell script in the same folder as your Novetus installation (the one with NovetusBootstrapper.exe in it).  
You also need a patched Studio executable. Instructions are below this section.

Then, it's simply running (in PowerShell)

```ps1
.\NovetusStudioConnect.ps1 "<client>" "<username>" <user ID> "<server IP>" <server Port>
```

e.g.
```ps1
.\NovetusStudioConnect.ps1 "2009E-HD" "Vector4" 12345 "localhost" 53640
```
If you want a random user ID, set the user ID to `$(Get-Random)`.

If PowerShell says that you cannot run scripts, run this (on an administrator account)
```ps1
Set-ExecutionPolicy -ExecutionPolicy Bypass
```

Note that tripcodes are randomized: you will have a different tripcode every time you join.  
This can be good, to prevent tripcode bans, but will also fail with tripcode whitelists.  
The script spawns you with your own Novetus outfit, although sometimes you will have to die once to load everything.  
Also, some features may be broken on Studio. Things like conveyors may not function.

# Studio Patching
NOTE: I recommend also doing the extra patch, so you can do basic things like delete or clone objects while in games.   
Patching Studio executables to support this is simple enough:  
* Get [HxD](https://mh-nexus.de/en/hxd/)
* Open up both RobloxApp_client.exe and RobloxApp_studio.exe (you can control-click to open multiple at once)
* In RobloxApp_client.exe, search for the string `NetworkClient`, and click Search All.
* For every found occurence, copy the offset (you can use Alt+Ins), go to RobloxApp_studio.exe, and type in `NetworkClient` (on the right side, on the cursor/to the left of the dotted box).
* After that is done, in the Studio, open up the Search menu, click on Hex-values, and then search for `68 FF 80 00 00`
* If you find nothing, skip, otherwise, replace the `FF 80` with `00 00`. (on the left side) Keep everything else unchanged.
* Do the same thing, but instead search for `68 24 81 00 00`.
* Create a backup, and test the new Studio by opening it up and typing in the command bar `game:GetService("NetworkClient")`.
* If you did everything right, there should be no error, the Studio tools should not disappear, and the explorer should show a NetworkClient instance.

# Extra Patching
Some actions (e.g. trying to clone, delete objects, or trying to Ctrl + A) may show a message box that shows the message "Insufficinet permissions".
Patching this out is easy enough, and allows to do these actions.
* Open RobloxApp_studio.exe in a tool like IDA or [x32dbg](https://x64dbg.com/)
* Open the strings tab, and search for "Insufficinet permissions" (with the spelling mistake)
* Go to the address of the instruction
* In the assembly, you should see a `test` instruction, followed by a `jne` instruction, usually right above the `push` instruction.
* Patch the `jne` instruction to a `jmp` instruction.
* Save the file.
