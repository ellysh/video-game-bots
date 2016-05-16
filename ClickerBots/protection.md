# Protection Approaches

This chapter covers approaches to development of protection systems against clicker bots. Most effective protection systems are separated into two parts. One part is launched on a client-side. It allows to control points of interception and embedding data that are related to devices, OS and a game application. Server-side part of the protection system allows to control a communication between a game application and a game server. Most algorithms for detection clicker bots are able to work on client-side only.

Main purpose of the protection system is detection a fact of the bot application usage. There are several variants of reaction on a bot detection:

1. Write a warning message about the suspect player account to the server-side log file.
2. Interrupt current connection between the suspect player and a game server.
3. Ban the suspect player account and prevent its future connection to a game server.

Ways to overcome the described protection approaches will be considered here.

## Test Application

Protection systems approaches will be tested on Notepad application. The protection system should detect an AutoIt script that will type text in the application's window. Our sample protection systems will be implemented on AutoIt language as separate scripts. It will be simpler to demonstrate protection algorithms in this way. But C++ language is used for development real protection systems in most cases.

This is a [`SimpleBot.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/ProtectionApproaches/SimpleBot.au3) script that types a, b and c letters consistently in the Notepad window:
```AutoIt
$hWnd = WinGetHandle("[CLASS:Notepad]")
WinActivate($hWnd)
Sleep(200)

while true
    Send("a")
    Sleep(1000)
    Send("b")
    Sleep(2000)
    Send("c")
    Sleep(1500)
wend
```
Each letter represents some kind of the bot's action in the application's window. Now you can launch Notepad application and the `SimpleBot.au3` script. The script will start to type letters in the application's window in an infinite loop. This is a start point for our research of protection systems. Purpose of each sample protection system is detection of the launched `SimpleBot.au3` script. The protection system should distinguish legal user's actions and simulated actions by a bot in the application's window.

## Analysis of Actions

There are several obvious regularities in the `SimpleBot.au3` script. Our protection system can analyze the performed actions and make a conclusion about usage of a bot. First regularity is time delays between the actions. User has not possibility to repeat his actions with very precise delays. Protection algorithm can measure delays between the actions of one certain type. There is very high probability that the actions are simulated by a bot in case delays between them are less than 100 milliseconds. Now we will implement protection algorithm that is based on this time measurement.

The protection system should solve two tasks: capture user's actions and analyze them. This is a code snippet to capture the pressed keys:
```AutoIt
global const $gKeyHandler = "_KeyHandler"

func _KeyHandler()
    $keyPressed = @HotKeyPressed

    LogWrite("_KeyHandler() - asc = " & asc($keyPressed) & " key = " & $keyPressed)
    AnalyzeKey($keyPressed)

    HotKeySet($keyPressed)
    Send($keyPressed)
    HotKeySet($keyPressed, $gKeyHandler)
endfunc

func InitKeyHooks($handler)
    for $i = 0 to 256
        HotKeySet(Chr($i), $handler)
    next
endfunc

InitKeyHooks($gKeyHandler)

while true
    Sleep(10)
wend
```
We use a [`HotKeySet`](https://www.autoitscript.com/autoit3/docs/functions/HotKeySet.htm) AutoIt function here to assign a **handler** or **hook** for pressed keys. The `_KeyHandler` function is assigned as a handler for all keys with ASCII codes from 0 to 255 in the `InitKeyHooks` function. It means that the `_KeyHandler` is called each time if any key with one of the specified ASCII codes is pressed. The `InitKeyHooks` function is called before the `while` infinite loop. There are several actions in the `_KeyHandler`:

1. Pass the pressed key to the `AnalyzeKey` function. The pressed key is available by `@HotKeyPressed` macro.
2. Disable the `_KeyHandler` by the `HotKeySet($keyPressed)` call. This is needed for sending the captured key to the application's window.
3. Send the pressed key to an application's window by the `Send` function.
4. Enable the `_KeyHandler` by the `HotKeySet($keyPressed, $gKeyHandler)` call.

This is a source of the `AnalyzeKey` function:
```AutoIt
global $gTimeSpanA = -1
global $gPrevTimestampA = -1

func AnalyzeKey($key)
    local $timestamp = (@SEC * 1000 + @MSEC)
    LogWrite("AnalyzeKey() - key = " & $key & " msec = " & $timestamp)
    if $key <> 'a' then
        return
    endif

    if $gPrevTimestampA = -1 then
        $gPrevTimestampA = $timestamp
        return
    endif

    local $newTimeSpan = $timestamp - $gPrevTimestampA
    $gPrevTimestampA = $timestamp

    if $gTimeSpanA = -1 then
        $gTimeSpanA = $newTimeSpan
        return
    endif

    if Abs($gTimeSpanA - $newTimeSpan) < 100 then
        MsgBox(0, "Alert", "Clicker bot detected!")
    endif
endfunc
```
Time spans between the "a" key pressing actions are measured here. We can use a **trigger action** term to name the analyzing key pressing actions. There are two global variables for storing a current state of the function's algorithm:

| Name | Description |
| -- | -- |
| `gPrevTimestampA` | [**Timestamp**](https://en.wikipedia.org/wiki/Timestamp) of the last happening trigger action |
| `gTimeSpanA` | Time span between last two trigger actions |

Both these variables have `-1` value on a startup that matches to the uninitialized state. The analyze algorithm is able to make conclusion about a bot usage after minimum three trigger actions. First action is needed for the `gPrevTimestampA` variable initialization:
```AutoIt
    if $gPrevTimestampA = -1 then
        $gPrevTimestampA = $timestamp
        return
    endif
```
Second action is used for calculation of the `gTimeSpanA` variable. The variable equals to a subtraction between timestamps of the current and previous actions:
```AutoIt
    local $newTimeSpan = $timestamp - $gPrevTimestampA
    $gPrevTimestampA = $timestamp

    if $gTimeSpanA = -1 then
        $gTimeSpanA = $newTimeSpan
        return
    endif
```
Third action is used for calculation a new time span and comparing it with the previous one that is stored in the `gTimeSpanA` variable:
```AutoIt
    if Abs($gTimeSpanA - $newTimeSpan) < 100 then
        MsgBox(0, "Alert", "Clicker bot detected!")
    endif
```
We have two measured time spans here: between first and second trigger actions, between second and third ones. If subtraction of these two time spans is less than 100 milliseconds, user is able to repeat his actions with precision of 100 milliseconds. It is impossible for human but absolutely normal for a bot. Therefore, the protection system concludes that these actions have been simulated by a bot. The message box with "Clicker bot detected!" text will be displayed in this case.

This is a full source of the [`TimeSpanProtection.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/ProtectionApproaches/TimeSpanProtection.au3) script with skipped content of `_KeyHandler` and `AnalyzeKey` functions:
```AutoIt
global const $gKeyHandler = "_KeyHandler"
global const $kLogFile = "debug.log"

global $gTimeSpanA = -1
global $gPrevTimestampA = -1

func LogWrite($data)
    FileWrite($kLogFile, $data & chr(10))
endfunc

func _KeyHandler()
    ; SEE ABOVE
endfunc

func InitKeyHooks($handler)
    for $i = 0 to 256
        HotKeySet(Chr($i), $handler)
    next
endfunc

func AnalyzeKey($key)
    ; SEE ABOVE
endfunc

InitKeyHooks($gKeyHandler)

while true
    Sleep(10)
wend
```
We can improve our `SimpleBot.au3` script to avoid the considered protection algorithm. The simplest improvement is adding random delays between the bot's actions. This is a patched version of the bot with the [`RandomDelayBot.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/ProtectionApproaches/RandomDelayBot.au3) name:
```AutoIt
SRandom(@MSEC)
$hWnd = WinGetHandle("[CLASS:Notepad]")
WinActivate($hWnd)
Sleep(200)

while true
    Send("a")
    Sleep(Random(800, 1200))
    Send("b")
    Sleep(Random(1700, 2300))
    Send("c")
    Sleep(Random(1300, 1700))
wend
```
The combination of `SRandom` and `Random` AutoIt functions is used here for calculation delay time. You can launch `TimeSpanProtection.au3` script and then `RandomDelayBot.au3` script. The bot script will keep working and the protection system is not able to detect it.

Second regularity of a bot script can help us to detect improved version of the bot. The regularity is the simulated actions itself. The script repeats actions "a", "b" and "c" cyclically. There is very low probability that an user will repeat these actions in the same order constantly.

This is a code snippet from [`ActionSequenceProtection.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/ProtectionApproaches/ActionSequenceProtection.au3) script with the new version of `AnalyzeKey` function. It checks repeating sequence of the captured actions:
```AutoIt
global const $gActionTemplate[3] = ['a', 'b', 'c']
global $gActionIndex = 0
global $gCounter = 0

func Reset()
    $gActionIndex = 0
    $gCounter = 0
endfunc

func AnalyzeKey($key)
    LogWrite("AnalyzeKey() - key = " & $key);

    $indexMax = UBound($gActionTemplate) - 1
    if $gActionIndex <= $indexMax and $key <> $gActionTemplate[$gActionIndex] then
        Reset()
        return
    endif

    if $gActionIndex < $indexMax and $key = $gActionTemplate[$gActionIndex] then
        $gActionIndex += 1
        return
    endif

    if $gActionIndex = $indexMax and $key = $gActionTemplate[$gActionIndex] then
        $gCounter += 1
        $gActionIndex = 0

        if $gCounter = 3 then
            MsgBox(0, "Alert", "Clicker bot detected!")
            Reset()
        endif
    endif
endfunc
```
This is a list of global variables and constants that are used in the algorithm:

| Name | Description |
| -- | -- |
| `gActionTemplate` | List of actions in the sequence that should be specific for a bot script |
| `gActionIndex` | Index of the captured action according to the `gActionTemplate` list |
| `gCounter` | Number of repetitions of the actions sequence |

The `AnalyzeKey` function processes three cases of matching captured action and elements of `gActionTemplate` list. First case processes the captured action that does not match the `gActionTemplate` list:
```AutoIt
    $indexMax = UBound($gActionTemplate) - 1
    if $gActionIndex <= $indexMax and $key <> $gActionTemplate[$gActionIndex] then
        Reset()
        return
    endif
```
The `Reset` function is called in this case. Values of both `gActionIndex` and `gCounter` variables are set to zero in the `Reset` function. Second case is matching the captured action and not last element of the `gActionTemplate` list with an index that equals to the `gActionIndex`:
```AutoIt
    if $gActionIndex < $indexMax and $key = $gActionTemplate[$gActionIndex] then
        $gActionIndex += 1
        return
    endif
```
Value of the `gActionIndex` variable is incremented in this case. Last case is matching the captured action and last element of the `gActionTemplate` list:
```AutoIt
    if $gActionIndex = $indexMax and $key = $gActionTemplate[$gActionIndex] then
        $gCounter += 1
        $gActionIndex = 0

        if $gCounter = 3 then
            MsgBox(0, "Alert", "Clicker bot detected!")
            Reset()
        endif
    endif
```
The `gCounter` is incremented and `gActionIndex` reset to zero here. It allows to analyze next captured action and compare it with the `gActionTemplate` list. The protection system concludes about the bot usage in case the actions sequence is repeated three times i.e. value of `gCounter` equals to three. A message box with the "Clicker bot detected!" text will be displayed in this case. Also both `gCounter` and `gActionIndex` variables will be reset to zero. Now protection system ready to detect a bot again.

You can launch a `ActionSequenceProtection.au3` script and then `RandomDelayBot.au3` script. New protection system able to detect the improved bot. But the described approach of actions sequence analyzing can lead to false positives. It means that the protection system detects a bot incorrectly in case user repeats his actions three times. Increasing maximum allowable value of the `gCounter` can help to decrease the false positives cases. Also it is possible to improve the considered protection approach to analyze actions without a predefine actions sequence. Protection system able to accumulate all user's actions and search frequently repeated regularities. It is able to signal about usage of a clicker bot in some cases.

We can improve our bot script further to avoid the protection systems that are based on actions regularities. This is a [`RandomActionBot.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/ProtectionApproaches/RandomActionBot.au3) script:
```AutoIt
SRandom(@MSEC)
$hWnd = WinGetHandle("[CLASS:Notepad]")
WinActivate($hWnd)
Sleep(200)

while true
    Send("a")
    Sleep(1000)
    if Random(0, 9, 1) < 5 then
        Send("b")
        Sleep(2000)
    endif
    Send("c")
    Sleep(1500)
wend
```
Idea of the script improvement is to perform the simulated actions irregularly. The action "b" will be simulated by the bot with 50% probability in our example. This should be enough to avoid the simple protection algorithm of a `ActionSequenceProtection.au3` script. You can launch the protection system script and the bot script for testing.

## Process Scanner

Another approach to detect clicker bots is analysis a list of the launched applications. If you know a name of the bot application, you can scan a list of launched processes for this name.

This is a [`ProcessScanProtection.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/ProtectionApproaches/ProcessScanProtection.au3) script that performs the scan algorithm:
```AutoIt
global const $kLogFile = "debug.log"

func LogWrite($data)
    FileWrite($kLogFile, $data & chr(10))
endfunc

func ScanProcess($name)
    local $processList = ProcessList($name)

    if $processList[0][0] > 0 then
        LogWrite("Name: " & $processList[1][0] & " PID: " & $processList[1][1])
        MsgBox(0, "Alert", "Clicker bot detected!")
    endif
endfunc

while true
    ScanProcess("AutoHotKey.exe")
    Sleep(5000)
wend
```
List of the launched processes is available via [`ProcessList`](https://www.autoitscript.com/autoit3/docs/functions/ProcessList.htm) AutoIt function. The function is able to receive an input parameter with a process name for searching. The `AutoHotKey.exe` process name is passed to the function in our example. `ProcessList` returns two dimensional array. This is a description of a meaning of the resulting array's elements from our example:

| Element | Description |
| -- | -- |
| `$processList[0][0]` | Count of processes in the array |
| `$processList[1][0]` | Process name |
| `$processList[1][1]` | Process ID (PID) |

It is enough for our case to check the value of `$processList[0][0]` element. The `AutoHotKey.exe` application is launched in case the value is greater than zero. 

There is a problem with testing this protection system example. It is written in the AutoIt language. Therefore, a `AutoIt.exe` process of AutoIt [**interpreter**](https://en.wikipedia.org/wiki/Interpreted_language) will be started on a script launching. The same `AutoIt.exe` process will be started on the `SimpleBot.au3` launching. It will be better for our example to implement algorithm of the `SimpleBot.au3` script in the AutoHotKey language. This is a [`SimpleBot.ahk`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/ProtectionApproaches/SimpleBot.ahk) script with AutoHotKey implementation of the bot:
```AutoHotKey
WinActivate, Untitled - Notepad
Sleep, 200

while true
{
    Send, a
    Sleep, 1000
    Send, b
    Sleep, 2000
    Send, c
    Sleep, 1500
}
```
You can compare it with the `SimpleBot.au3` script. Both scripts looks very similar. There is minor differences in the syntax of the function calls. You should specify input parameters of all functions after a comma in AutoHotKey. But all function names like `WinActivate`, `Sleep` and `Send` are still the same as AutoIt variants.

Now we are ready to test our protection system example. This is an algorithm to do it:

1. Launch the Notepad application.
2. Launch the `ProcessScanProtection.au3` script.
3. Launch the `SimpleBot.ahk` script. Check that AutoHotKey application is installed in your system for launching the script.
4. Wait until protection system will not detect a launched bot script.

You will see a "Clicker bot detected!" when bot script will be detected.

It is very simple to avoid this kind of protection system. The most straightforward way is usage AutoHotKey compiler. The compiler allows you to get executable binary file from the specified AutoHotKey script.

These are steps to create `SimpleBot.exe` executable file from the `SimpleBot.ahk` script:

1. Launch the AutoHotKey compiler application. Path of the application by default is `C:\Program Files (x86)\AutoHotkey\Compiler\Ahk2Exe.exe`.
2. Select the `SimpleBot.ahk` script as a "Source (script file)" parameter in the "Required Parameters" panel.
3. Leave a "Destination (.exe file)" parameter empty in the "Required Parameters" panel. It means that resulting executable file will be created in the same directory as the source script.
4. Press the "> Convert <" button.

This is a screenshoot of the AutoHotKey compiler's window with an example of the specified parameters:

![AutoHotKey Compiler](ahk2exe.png)

You will get a message box with "Conversion complete" message after compilation finish. Resulting executable file will be created in the same directory as the source script.

Now you can launch the generated `SimpleBot.exe` file instead of the `SimpleBot.ahk` script. The `ProcessScanProtection.au3` system is not able to detect it anymore. It happens because now there is a process with `SimpleBot.exe` name instead of the `AutoHotKey.exe` one.

How we can improve the `ProcessScanProtection.au3` system to detect new version of the bot? It is very simple to change a name of the binary file. But it is more difficult to change the file's content. There are many possible ways to analyze the file content. These are just several ideas to do it:

1. Calculate a [**hash sum**](https://en.wikipedia.org/wiki/Checksum) for all file content and compare it with the predefined value.
2. Check a sequence of bytes in the specific place of the file.
3. Search a specific byte sequence or string in the file.

This is a [`Md5ScanProtection.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/ProtectionApproaches/Md5ScanProtection.au3) script that calculates and checks the  [**MD5**](https://en.wikipedia.org/wiki/MD5) hash sum:
```AutoIt
#include <Crypt.au3>

global const $kLogFile = "debug.log"
global const $kCheckMd5[2] = ["0x3E4539E7A04472610D68B32D31BF714B", _
                              "0xD960F13A44D3BD8F262DF625F5705A63"]

func LogWrite($data)
    FileWrite($kLogFile, $data & chr(10))
endfunc

func _ProcessGetLocation($pid)
    local $proc = DllCall('kernel32.dll', 'hwnd', 'OpenProcess', 'int', _
                          BitOR(0x0400, 0x0010), 'int', 0, 'int', $pid)
    if $proc[0] = 0 then 
        return ""
    endif
    local $struct = DllStructCreate('int[1024]')
    DllCall('psapi.dll', 'int', 'EnumProcessModules', 'hwnd', $proc[0], 'ptr', _
            DllStructGetPtr($struct), 'int', DllStructGetSize($struct), 'int_ptr', 0)

    local $return = DllCall('psapi.dll', 'int', 'GetModuleFileNameEx', 'hwnd', _
                            $proc[0], 'int', DllStructGetData($struct, 1), 'str', _
                            '', 'int', 2048)
    if StringLen($return[3]) = 0 then
        return ""
    endif
    return $return[3]
endfunc

func ScanProcess()
    local $processList = ProcessList()
    for $i = 1 to $processList[0][0]
        local $path = _ProcessGetLocation($processList[$i][1])
        local $md5 = _Crypt_HashFile($path, $CALG_MD5)
        LogWrite("Name: " & $processList[$i][0] & " PID: " & $processList[$i][1] & _
                 " Path: " & $path & " md5: " & $md5)

        for $j = 0 to Ubound($kCheckMd5) - 1
            if $md5 == $kCheckMd5[$j] then
                MsgBox(0, "Alert", "Clicker bot detected!")
            endif
        next
    next
endfunc

while true
    ScanProcess()
    Sleep(5000)
wend
```
We have changed the `ScanProcess` function here. Now the `ProcessList` function is called without any parameter. It means that a list of all running processes will be returned in the resulting `processList` array. Process is a set of [**modules**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684232%28v=vs.85%29.aspx). Each module represents an executable file or DLL. It is possible to get full path of these executable files or DLLs from the module's information. This algorithm is encapsulated in the `_ProcessGetLocation` function. There is a [`_Crypt_HashFile`](https://www.autoitscript.com/autoit3/docs/libfunctions/_Crypt_HashFile.htm) AutoIt function that allows to calculate MD5 hash sum for the specified file. We process the module's executable file with the `_Crypt_HashFile` and then compare resulting MD5 hash sum with the predefined values from the `kCheckMd5` array. The array has two values: hash sum for `SimpleBot.exe` binary and hash sum for 'AutoHotKey.exe' binary. Therefore, this protection system able to detect both `SimpleBot.ahk` script and compiled version of it.

This is an algorithm of the `_ProcessGetLocation` function:

1. Call a [`OpenProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684320%28v=vs.85%29.aspx) WinAPI function to receive a handle of the process.
2. Call a [`EnumProcessModules`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms682631%28v=vs.85%29.aspx) WinAPI function to get list of modules of the process that is passed to the function by a handle.
3. Call a [`GetModuleFileNameEx`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683198%28v=vs.85%29.aspx) WinApi function to get full path of the executable file. First module in the list returned by `EnumProcessModules`  function matches to the executable file and all others modules match to DLLs.

You can launch `Md5ScanProtection.au3` script and check that both `SimpleBot.ahk` script and `SimpleBot.exe` executable file are detected successfully. In case the `SimpleBot.ahk` script is not detected, it means that you use another version of AutoHotKey application. You should check correct MD5 sum of the application in a `debug.log` file and change the `kCheckMd5` array accordingly.

There are several ways to improve a bot allowing to avoid the `Md5ScanProtection.au3` protection system. All of them focus on changing a content of the executable file. This is a list of these ways:

1. Perform a minor change of the `SimpleBot.ahk` script for example in the delay value. Then compile a new version of the script with `Ahk2Exe.exe` application.

2. Patch a header of the `AutoHotKey.exe` executable file with an editor for binary files. [**HT editor**](http://hte.sourceforge.net) is an example of this kind of editors.

The safest way to change executable file header is changing timestamp of the file creation in [**COFF**](https://en.wikipedia.org/wiki/COFF) header. This is an algorithm to change it with HT editor:

1. Launch the HT editor application with the administrator privileges. This is a `ht-2.1.0-win32.exe` filename for the current version of the application. It will be convenient to copy the editor into the directory with an `AutoHotKey.exe` file.
2. Press *F3* key to pop up the "open file" dialog.
3. Press *Tab* for switching to the "files" list and select an `AutoHotKey.exe` file. Press *Enter* to open the selected file.
4. Press *F6* key to open the "select mode" dialog with the list of available modes. Select a "- pe/header" item of the list. Now you see a headers list of the executable file.
5. Select the "COFF header" item and press *Enter*. Select a "time-data stamp" field of the header.
6. Press *F4* key to start editing a timestamp value. Change the value.
7. Press *F4* and select "Yes" option in the "confirmation" dialog to save changes.

This is a screenshot of HT editor application at the changing timestamp step:

![HT Editor](ht-editor.png)

You get a new `AutoHotKey.exe` executable file which content differs from the original file. It means that a MD5 hash sum for the new file will differ from a hash sum for the original file. Now `Md5ScanProtection.au3` is not able to detect any launched AutoHotKey script.

Possible way to improve the protection system is usage more difficult approaches to analyze a content of executable files. It is possible to check sequence of bytes in the specific place of the file by calculating a hash sum only for these bytes.

## Keyboard State Checking

Windows OS provides a kernel level mechanism to distinguish the simulated keystrokes. It is possible to set a hook function by [`SetWindowsHookEx`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms644990%28v=vs.85%29.aspx) WinAPI function for monitoring system events. There are several types of available hook functions. Each of them captures a specific kind of the events. The `WH_KEYBOARD_LL` hook type allows to capture all low-level keyboard input events. The function hook receives a [`KBDLLHOOKSTRUCT`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms644967%28v=vs.85%29.aspx) structure which contains a detailed information about the events. All keyboard events, that have been produced by `SendInput` or `keybd_event` WinAPI functions, have a `LLKHF_INJECTED` flag in the `KBDLLHOOKSTRUCT` structure. Keyboard events, that are produced by a keyboard driver, has not the `LLKHF_INJECTED` flag. This behaviour is provided by the Windows kernel level and this is impossible to customize it on WinAPI level.

This is a [`KeyboardCheckProtection.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/ProtectionApproaches/KeyboardCheckProtection.au3) script that checks `LLKHF_INJECTED` flag to detect a clicker bot:
```AutoIt
#include <WinAPI.au3>

global const $kLogFile = "debug.log"
global $gHook

func LogWrite($data)
    FileWrite($kLogFile, $data & chr(10))
endfunc

func _KeyHandler($nCode, $wParam, $lParam)
    if $nCode < 0 then
        return _WinAPI_CallNextHookEx($gHook, $nCode, $wParam, $lParam)
    endIf

    local $keyHooks = DllStructCreate($tagKBDLLHOOKSTRUCT, $lParam)

    LogWrite("_KeyHandler() - keyccode = " & DllStructGetData($keyHooks, "vkCode"));

    local $flags = DllStructGetData($keyHooks, "flags")
    if $flags = $LLKHF_INJECTED then
        MsgBox(0, "Alert", "Clicker bot detected!")
    endif

    return _WinAPI_CallNextHookEx($gHook, $nCode, $wParam, $lParam)
endfunc

func InitKeyHooks($handler)
    local $keyHandler = DllCallbackRegister($handler, "long", "int;wparam;lparam")
    local $hMod = _WinAPI_GetModuleHandle(0)
    $gHook = _WinAPI_SetWindowsHookEx($WH_KEYBOARD_LL, _
                                      DllCallbackGetPtr($keyHandler), $hMod)
endfunc

InitKeyHooks("_KeyHandler")

while true
    Sleep(10)
wend
```
This script uses an algorithm that is similar to the algorithms of `TimeSpanProtection.au3` and `ActionSequenceProtection.au3` scripts. User's input actions are analyzed in all these scripts. There is a `InitKeyHooks` function that installs `_KeyHandler` hook for the low-level keyboard input events. This is an algorithm of installing the hook:

1. Register a `_KeyHandler` function as a callback function by the [`DllCallbackRegister`](https://www.autoitscript.com/autoit3/docs/functions/DllCallbackRegister.htm) AutoIt function. This operation allows you to pass `_KeyHandler` to the WinAPI functions.
2. Get handle of the current module by the [`GetModuleHandle`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683199%28v=vs.85%29.aspx) WinAPI function.
3. Install a `_KeyHandler` function into a hook chain by the `SetWindowsHookEx` function. The module handle where the `_KeyHandler` function has been defined should be passed to the `SetWindowsHookEx`.

There is a `LLKHF_INJECTED` flag checking algorithm in the `_KeyHandler` function. These are steps of the algorithm:

1. Check a value of the `nCode` parameter. In case the value is less than zero, the captured keyboard event is passed to the next hook in a chain without processing. Both `wParam` and `lParam` parameters does not contain actual information about the keyboard event in this case.
2. Create a `KBDLLHOOKSTRUCT` structure from the `lParam` input parameter by the `DllStructCreate` function.
3. Get a `flags` field from the `KBDLLHOOKSTRUCT` structure by `DllStructGetData` function. Compare values of the field and `LLKHF_INJECTED` flag. The keyboard event is simulated if the values match. Thus, the keyboard event has been simulated by a clicker bot.

You can launch the `KeyboardCheckProtection.au3` script, Notepad application and the `SimpleBot.au3` script to test a protection system example. Message box with the "Clicker bot detected!" text will appear after a first key press simulation by the bot.

There are several ways allowing to avoid protection systems that are based on the `LLKHF_INJECTED` flag checking. All of them focused on keyboard events simulation at level that is lower than WinAPI. These are list of these ways:

1. [**Virtual machine**](https://en.wikipedia.org/wiki/Virtual_machine) (VM) trick.
2. Use a keyboard driver instead of WinAPI functions to simulate keyboard events. [InpOut32](http://www.highrez.co.uk/downloads/inpout32/) project is an example of this kind of drivers.
3. Use an external device for keyboard events simulation. The device is able to be controlled by a bot application. This is a [link](https://www.arduino.cc/en/Reference/MouseKeyboard) to libraries for keyboard and mouse simulation that are provided by Arduino platform.

Usage a VM can help us to avoid a protection system. VM has a [**virtual device drivers **](https://en.wikipedia.org/wiki/Device_driver#Virtual_device_drivers) for simulation a hardware devices. Drivers of this type are launched inside the VM. All requests of VM to access hardware devices are routed via the virtual device drivers. There are two ways for the drivers to process these requests. The first way is to send request to the hardware device. The second way is to simulate behavior of the hardware device by driver itself. Also virtual device drivers can send simulated processor-level events like interrupts to the VM. The simulation of interrupts solves a task of avoiding protection systems of `KeyboardCheckProtection.au3` type.

This is an algorithm for testing a VM trick:

1. Install one of the VM applications ([Virtual Box](https://www.virtualbox.org), [VMWare](http://www.vmware.com/products/desktop_virtualization.html) or [Windows Virtual PC](http://www.microsoft.com/windows/virtual-pc/)).
2. Install a Windows OS inside the VM.
3. Launch a Notepad application and `KeyboardCheckProtection.au3` script inside the VM. It is common to launch both a game application and a client-side protection system simultaneously.
4. Launch a `VirtualMachineBot.au3` script outside the VM i.e. on the host system.

This is a [`VirtualMachineBot.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/ProtectionApproaches/VirtualMachineBot.au3) script:
```AutoIt
Sleep(2000)

while true
    Send("a")
    Sleep(1000)
    Send("b")
    Sleep(2000)
    Send("c")
    Sleep(1500)
wend
```
There is only one difference between this script and `SimpleBot.au3`. Notepad application's window is not activated at startup in the `VirtualMachineBot.au3`. There is a two second delay instead at the script startup. You should activate the VM application's window during this delay. Then script start to work and the protection system will not detect it. This happens because a virtual keyboard driver of the VM simulates a hardware interrupt for each clicker bot's action in the VM window. Therefore, Windows OS that is launched inside the VM have not possibility to distinguish simulated keyboard actions.

## Summary

We have considered approaches to protect a game application from clicker bots. Obviously, it is not difficult to avoid all these protection approaches. But this task becomes so simple only in case you have exact information about how a protection system works. There are several ways to gather this information:

1. Monitor WinAPI calls that a protection system's process performs by API Monitor or similar application.
2. [**Reverse**](https://en.wikipedia.org/wiki/Reverse_engineering) an executable file of a protection system.
3. Consequently try all known methods for avoiding a protection system.

You will get an opportunity to avoid a protection system only when you will understand well its internals.

Most of the modern client-side protection system combines several protection approaches. Therefore, effective clicker bot should combine several approaches of avoiding protection systems too.