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

Some features may also be broken on Studio. 
* The copy/paste/paste into actions do not work while in game.  
* Conveyors may not function.

# Studio Patching
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

**NOTE:** I recommend also doing the extra patches, so you can do basic things like delete/clone objects, or create Player instances.   

# Extra Patching
## "Insufficinet permissions"
Some actions (e.g. trying to clone, delete objects, or trying to Ctrl + A) may show a message box that shows the message "Insufficinet permissions".  
Patching this out is easy enough, and allows to do these actions.
* Open RobloxApp_studio.exe in a tool like IDA or [x32dbg](https://x64dbg.com/)
* Open the strings tab, and search for "Insufficinet permissions" (with the spelling mistake)
* Go to the address of the instruction.
* In the assembly, you should see a `test` instruction, followed by a `jne` instruction, usually right above the `push` instruction.
* Patch the `jne` instruction to a `jmp` instruction.
* Save the file.

## Identities
**NOTE:** This does not work for versions below 2008.  
The command bar and the Execute Script button do not have the permissions to do everything.  
It is simple enough to patch this out.  
* Open RobloxApp_studio.exe in a tool like IDA or [x32dbg](https://x64dbg.com/)
* Open the strings tab, and search for `Doc script`.
* If nothing is found, search for `Studio.ashx` instead.
* Go to the address of the instruction.
* You should see a `push N` instruction (where N is a number) a few lines after. This is the identity.
* Go to the next function called after the pushes, and get a list of references to that function.
* For every reference, change the push value to a 6 (for 2009 and below, you should use 5).
* If you searched for `Doc script`, do the same but for the string `Cmd`, as it is a different function.
    * If you are using IDA, you may not get any results if you search `Cmd`. To fix this, right click in the Strings menu, click on `Setup`, and change `Minimal string length` to 3.
* Create a backup, and then save the patched file. Try to open up Studio.
* If it opens, open the output and command bar, and type `printidentity()`. You should see `Current identity is 6` in the output. Attempt to create a Player with `print(Instance.new("Player"))`.
    * If it errors, **does not open**, or there is no output, then the identity value is different for your version (e.g. for 2009E, you should put 4 or 5). Otherwise, if you see output (usually just the text `Player`), you are good to go.
