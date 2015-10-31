# Protection Approaches

Possible approaches of development protection systems against clicker bots will be considered now. Most effective protection systems are separated into two parts. One part is launched on a cliend side. It allows to control points of interception and embedding data that are related to devices, OS and a game application. Server side part of the protection system allows to control a communication between a game application and a game server. Most algorithms for detection clicker bots able to work on client side.

Main purpose of the protection system is detection a fact of the bot application usage. There are several variants of reaction on a bot detection:

1. Write a warning message about a suspect player account to the log file.
2. Interrupt current connection between a suspect player and a game server.
3. Ban a suspect player account and prevent its future connections to a game server.

We will overview possible ways to overcome considered protection algorithms.

TODO: Brief foreword about protection system. Purposes, what it does on detection bot, checks on server and checks on client. Approaches against clickers

## Test Application

We will test protection systems approaches on Notepad application. A protection system should detect a AutoIt script that will type text in the application's window. Our sample protection systems will be implemented on AutoIt language too as separate scripts. It will be simpler to demonstarte protection algorithms with AutoIt language. But C++ language is used for development real protection systems in most cases.

This is a "SimpleBot.au3" script that types letters in the Notepad window:
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
Each letter represents some kind of the bot's action in the appliction's window. Now you can launch Notepad application and the "SimpleBot.au3" script after that. The script will start to type letters in the application's window in an infinite loop. This is a start point for our investigation of protection systems. Purpose of each sample protection system is detection of the launched "SimpleBot.au3" script. The protection system should distinguish legal user's actions and emulation actions by a bot in the application's window.

## Analysis of Actions

There are several obvious regularities in the "SimpleBot.au3" script. Our protection system can analyze the performed actions and make conclusion about usage a bot. First regularity is time delays between the actions. User has not possibility to repeat his actions with very precise delays. Protection algorithm can measure delays between the actions of one certain type. There is very high probability that the actions are emulated by a bot if delays betweeen them less than 100 milliseconds. Now we will implement protection algorithm that is based on this time measurement. 

A protection system should solve two tasks: capture user's actions and analyze them. This is a code snippet to capture the pressed keys:
```AutoIt
global const $gKeyHandler = "_KeyHandler"

func _KeyHandler()
	$key_pressed = @HotKeyPressed

	LogWrite("_KeyHandler() - asc = " & asc($key_pressed) & " key = " & $key_pressed & @CRLF);
	AnalyzeKey($key_pressed)

	HotKeySet($key_pressed)
	Send($key_pressed)
	HotKeySet($key_pressed, $gKeyHandler)
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
We use a [`HotKeySet`](https://www.autoitscript.com/autoit3/docs/functions/HotKeySet.htm) AutoIt function here to assign a handler for pressed keys. The `_KeyHandler` function is assigned as handler for all keys with ASCII codes from 0 to 255 in the `InitKeyHooks` function. The `InitKeyHooks` function is called before the `while` infinite loop. There are several actions in the `_KeyHandler` handler:

1. Pass the pressed key to the `AnalyzeKey` function. The pressed key is available by `@HotKeyPressed` macro.
2. Disable the handler by the `HotKeySet($key_pressed)` call.
3. Send the pressed key to an application window by the `Send` function.
4. Enable the handler by the `HotKeySet($key_pressed, $gKeyHandler)` call.

This is a source of the `AnalyzeKey` function:
```AutoIt
global $gTimeSpanA = -1
global $gPrevTimestampA = -1

func AnalyzeKey($key)
	local $timestamp = (@SEC * 1000 + @MSEC)
	LogWrite("AnalyzeKey() - key = " & $key & " msec = " & $timestamp & @CRLF);
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
Delays between the `a` key pressing actions are measured in the function. We can use a *trigger action* term to name the nanlyzing key pressing actions. There are two global variables for storing the current state of the analyzing algorithm:

1. `gPrevTimestampA` is a [timestamp](https://en.wikipedia.org/wiki/Timestamp) of the last happening trigger action.
2. `gTimeSpanA` is a time span between last two trigger actions.

Both these variables have `-1` value on a startup that matches to the uninitialized state. The analyze algorithm is able to make conclusion about a bot usage after minimum three trigger actions. First action is needed for the `gPrevTimestampA` variable initialization:
```AutoIt
	if $gPrevTimestampA = -1 then
		$gPrevTimestampA = $timestamp
		return
	endif
```
Second action is used for calculation of the `gTimeSpanA` variable. The variable equals to a subtraction between timestamps of the current and previos actions:
```AutoIt
	local $newTimeSpan = $timestamp - $gPrevTimestampA
	$gPrevTimestampA = $timestamp

	if $gTimeSpanA = -1 then
		$gTimeSpanA = $newTimeSpan
		return
	endif
```
Third action is used for calculation a time span second time and comparing it with a value of the `gTimeSpanA` variable:
```AutoIt
	if Abs($gTimeSpanA - $newTimeSpan) < 100 then
		MsgBox(0, "Alert", "Clicker bot detected!")
	endif
```
Now we have two measured time spans: between first and second actions, between second and third actions. If subtraction of these two time spans is less than 100 milliseconds it means that the actions have been emulated by a bot. The message box with "Clicker bot detected!" text will be displayed in this case.

This is a full source of the "TimeSpanProtection.au3" script:
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
We can improve our "SimpleBot.au3" script to avoid considered protection aproach. The simplest improvement is adding random delays between the bot's actions. This is a "RandomDelayBot.au3" script:
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
The combination of `SRandom` and `Random` AutoIt functions is used here for calculation values of delays. You can launch "TimeSpanProtection.au3" script and then "RandomDelayBot.au3" script. The bot script will keep working and protection system is not able to detect it.

Second regulatiry of a bot script can help us to detect it. The regularity is emulated actions itself. The script repeats actions `a`, `b` and `c` cyclically. There is very low probability that user will repeat these actions in the same order more than 3 times.

This is a code snippet from "ActionSequenceProtection.au3" script with the new version of `AnalyzeKey` function that checks a sequence of actions:
```AutoIt
global const $gActionTemplate[3] = ['a', 'b', 'c']
global $gActionIndex = 0
global $gCounter = 0

func AnalyzeKey($key)
	LogWrite("AnalyzeKey() - key = " & $key & @CRLF);

	if $gActionIndex < 3 and $key = $gActionTemplate[$gActionIndex] then
		$gActionIndex += 1
	else
		$gActionIndex = 0
		return
	endif

	if $gActionIndex = UBound($gActionTemplate) - 1 then
		$gCounter += 1

		if $gCounter = 3 then
			MsgBox(0, "Alert", "Clicker bot detected!")
		endif
	endif
endfunc
```
There are global variables and constant that are used in the algorithm:

1. `gActionTemplate` is a list of actions sequence that specific for the bot script.
2. `gActionIndex` is an index of the captured action that matches to the action from the `gActionTemplate` list.
3. `gCounter` is a counter of repeating actions sequence that matches to the `gActionTemplate` list.

TODO: Write about detection based on actions sequence.

TODO: Write about improvement of the algorithm that allows todetect bots without the predefined actions template. Write about possible false positives.

## Keyboard State Checking

TODO: Write about checking a LLKHF_INJECTED flag when a keypress is hooked.

TODO: Try to avoid this protection in the bot script.

## Process Scanner

TODO: Write about scanning of the launch processes. How to do it for two Autoit scripts? Make one script in Autohotkey?

TODO: Try to avoid this protection by renaming Autohotkey application.

TODO: Write about calculating md5 of the launched binaries. Try to avoid it by patching binary and changing md5.

## Results

TODO: Compare effectiveness of the suggested protection approaches. Is it possible to use one and skip all others?