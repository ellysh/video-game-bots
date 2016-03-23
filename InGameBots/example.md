# Example with Diablo 2

## Diablo 2 Overview

Now we will write a simple in-game bot for the popular RPG game Diablo 2. Gameplay of Diablo 2 is a quite typical for the RPG genre. Player should do quests, kill monsters and improve his character. Our example bot is focused on analysis a state of the player character. Therefore it will be helpful to consider parameters of the player character in details.

There is a screenshot of the game's main screen:

![Diablo 2 Interface](diablo-interface.png)

You can see a player character in the center of the screen. There is an yellow model of the knight. Also you can see the monsters around the player character. One of the monster is selected by the mouse cursor.

There is a screenshot of windows with the player character's parameters:

![Diablo 2 Player](diablo-player.png)

There are two windows in the screenshot. Left window contains the common information about the player character like his name "Kain", class "Paladin", level and experience points. This information available at the top of the window. Also below there are attributes, that define a behavior of the character in the game process. For example, the "Strength" attribute defines a damage amount that is delivered to the monsters by the player.

Right window contains a tree of the character's skills. There are special abilities and combos that allow you to make a more damage or to improve significantly the character's attributes. Each skill have a level. It defines, how effective an usage of this skill will be. You can get more details about the parameters and skills of the player character in a [wiki page](http://diablo.gamepedia.com/Classes_%28Diablo_II%29)

Diablo 2 has the single player and multiplayer game modes. We will consider the single player mode only. It allows us to stop a game's process execution at any moment and to explore its memory without any time limitations. Otherwise the game client, that does not respond to the game server's requests, will be disconnected. This limitation does not allow us to use a debugger and to stop the game application for investigation its internals.

Diablo 2 is available for buying at the [Blizzard Entertainment website](https://eu.battle.net/shop/en/product/diablo-ii). There is an open source game with a [Flare](http://flarerpg.org/) name, that is available for free. It has the very close game mechanics and interface to the Diablo 2 ones. You can use the Flare game to try methods of memory investigation, that are described in this chapter. All these methods are applicable to the Flare game too. The main difference between the processes of analysis Diablo 2 and Flare games is a complexity. Diablo 2 has much more library modules and game objects in the memory than the Flare one. Thus analysis of Diablo 2 process memory requires much more efforts.

## Bot Overview

You can find detailed articles by Jan Miller about hacking the Diablo 2 game. This is a first [article](http://extreme-gamerz.org/diablo2/viewdiablo2/hackingdiablo2). This is a second [article](http://www.battleforums.com/threads/howtohackd2-edition-2.111214/). Approaches, that are described in the articles, are focused to the changing a normal behavior of the game. These changes of the application behavior are named hacks. But a bot application should behave in a different manner. The bot should not affect a normal behavior of the game application. Instead it should analyze a state of the game objects and simulate the player's actions. Meanwhile the game application is still working within its normal algorithms. State of all objects is still valid according to the game rules.

Our sample in-game bot have a very simple algorithm:

1. Read current value of the player character's life parameter.
2. Compare the read value with the threshold value.
3. Change a value of the character's life parameter.

This algorithm allows to keep a player character alive while there are still the health potions. Nevertheless an implementation of so simple algorithm requires a deep research of the Diablo 2 process memory.

## Diablo 2 Memory Analysis

Now we are ready to start our analysis of the Diablo 2 process memory. First of all you should launch the game. The game is launched by default in a fullscreen mode. But it will be more convenient for us to launch the game in a windowed mode. It allows you to switch quickly between the game and memory scanner windows. There is an [instruction](https://eu.battle.net/support/en/article/diablo-ii-compatibility-issues-and-workarounds) how to launch the game in the windowed mode:

1. Right-click the "Diablo II" icon and click "Properties".
2. Click the "Shortcut" tab.
3. Add `-w` to the end of the "Target". For example: 
```
"C:\DiabloII\Diablo II.exe" -w
```

When the game is launched, you should select a "Single player" option, create a new character and start the game.

### Parameter Searching

Goal of our analysis is to find an address of the player character's life parameter into the game process memory. First and the most obvious way to achieve our goal is to use the Cheat Engine memory scanner. You can launch the Cheat Engine and try to search the current life value in the default mode of the scanner. This approach do not work for me. There is a long list of the resulting addresses. If you continue searching by selecting "Next Scan" option with updated life value, the resulting list becomes empty.

Primary reason of our issue is a size and complexity of the Diablo 2 game itself. The game model is very complex, and there are a lot of game objects in the memory. Now we do not know, how a state and parameters of these objects are stored into the memory. Therefore we can start our research from developing a method, that allows us to find a specific object in the memory. Let us look at the window with the player character's attributes again. There are several parameters that are guaranteed to be unique for the player character object. We can name this kind of unique parameters an **artifacts** for the sake of brevity. What are artifacts for the player character object? This is a list of these:

1. **Character name**<br/>
It is extremely unlikely that other game object has the same name as a player character. Otherwise you can rename your character to guarantee its unique name.
2. **Experience value**<br/>
This is a long positive integer number. It is able to appear in the other objects rarely. But you can change this value easily by killing several monsters, and then make next memory scan operation with the new value.
3. **Stamina value**<br/>
This is a long positive number. You can change it easily too by running outside the city.

I suggest to select an experience value for searching. In case the value equals to zero, you can kill several monsters to change it. The value will grow rapidly. There are the memory scan results for my case:

![Experience Value](experience-value.png)

There are several values in the memory that equal to the character's experience value.

Next step is to distinguish the value that is contained inside the character object. First of all, we can clarify a type of owning segment for each of these variables. This is a shortened output of the `!address` command of WinDbg debugger:
```
+ 0`003c0000  0`003e0000  0`00020000  MEM_PRIVATE MEM_COMMIT PAGE_READWRITE <unknown>
+ 0`03840000  0`03850000  0`00010000  MEM_PRIVATE MEM_COMMIT PAGE_READWRITE <unknown>
+ 0`03850000  0`03860000  0`00010000  MEM_PRIVATE MEM_COMMIT PAGE_READWRITE <unknown>
+ 0`04f50000  0`04fd0000  0`00080000  MEM_PRIVATE MEM_COMMIT PAGE_READWRITE <unknown>
```
You can see, that all found variables are stored into the segments of "unknown" type. What is the "unknown" type? We already know the segments of stack and heap types. WinDbg debugger can distinguish them well. Therefore these unknown segments are neither stack nor heap type. It is able to be segments that are allocated by the [`VirtualAllocEx`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366890%28v=vs.85%29.aspx) WinAPI function. We can clarify this question very simple by writing a sample application, that uses a `VirtualAllocEx` function. If you launch this sample application with WinDbg debugger, you see a segment of "unknown" type in the application's memory map. The base address of the "unknown" segment has the same value as returned one by the `VirtualAllocEx` function. 

Analyzing of segments do not allow us to find the character's experience parameter. All of these "unknown" segments have the same type and flags. Therefore we cannot distinguish them.

We can try another way to find the character object. It is obvious, that parameters of the object will be changed, when a player performs the actions. For example, the object's coordinates are changed when a character moves. Also the live value is decreased when the character gains a damage from monsters. Consider this fact, we can analyze the nature of changes in the memory that is located near the character's experience parameter. Cheat Engine memory scanner provides a feature to display changes of a memory region in real-time. There is an algorithm to open a Memory Viewer window of the Cheat Engine application:

1. Select an address in the resulting list for inspection.
2. Left click on the address.
3. Select the "Browse this memory region" item in the pop-up menu.

Now you see this Memory Viewer window:

![Memory Viewer](memory-viewer.png)

The Memory Viewer window is split into two parts. Disassembled code of the current memory region is displayed at the upper part of the window. The memory dump in a hexadecimal format is displayed at the bottom part of the window. We will focus on the memory dump in our investigation. Value of the character's experience parameter is underlined by a red line on the screenshoot. It is not obvious, why the hexadecimal value "9E 36 FF 10" in the memory dump is equal to the actual value "285161118" of experience parameter in decimal. Our application is launched on the x86 architecture. It has a [little-endian](https://en.wikipedia.org/wiki/Endianness#Little-endian) byte order. It means, that you should reverse the order of bytes in 4 byte integer to get its correct value. The hexadecimal value becomes equal to "10 FF 36 9E" in our case. You can use the standard windows Calculator application to make sure, that this hexadecimal value equals to the "285161118" one in decimal. Actually you can change a display type of the memory dump by left mouse clicking on it and selecting a "Display Type" item of the pop-up menu. But I recommend you to keep a type in the "Byte hex" format. Because you do not know an actual size in bytes of the parameters that you are looking for.

Now you should place windows of Memory Viewer and Diablo 2 application one near each other. It allows you to perform actions in the Diablo 2 window and to inspect a memory region simultaneously in the Memory Viewer. This is a screenshot with the results of this kind of memory inspection:

![Memory Inspection](memory-inspection.png)

The memory region on the screenshot matches to the last "04FC04A4" address in the resulting list of Cheat Engine scanner. This address may differ in your case but the order of addresses in the resulting list should be the same. You can find the same memory region by opening the last address in your resulting list. Why we prefer this memory region instead of other one? The reason is, this memory region contains more information about the player character. This is a list of parameters that have been detected thanks to the inspection:

| Parameter | Address | Offset | Size | Hex Value | Dec Value |
| -- | -- | -- | -- | -- | -- |
| Life | 04FC0490 | 490 | 2 | 40 01 | 320 |
| Mana | 04FC0492 | 492 | 2 | 9D 01 | 413 |
| Stamina | 04FC0494 | 494 | 2 | FE 1F | 8190 |
| Coordinate X | 04FC0498 | 498 | 2 | 37 14 | 5175 |
| Coordinate Y | 04FC04A0 | 4A0 | 2 | 47 12 | 4679 |
| Experience | 04FC04A4 | 4A4 | 4 | 9E 36 FF 10 | 285161118 |

All these parameters are underlined by the red color on the memory inspection screenshot. What new we have known about the character's parameters from this inspection? First of all, size of the life parameter equals to 2 bytes. It means, that you should specify the "2 Byte" item of the "Value Type" option in the main window of Cheat Engine in case you want to search the life parameter. Also you can see, that some of the character's parameters have [alignment](https://en.wikipedia.org/wiki/Data_structure_alignment), which is not equal to 4 byte. For example, the mana parameter at the 04FC0492 address. You can check with calculator that the 04FC0492 value is not divided to 4 without a remainder. It means, that you should unselect the "Fast Scan" check-box in the main window of Cheat Engine for searching these parameters. This is a screenshot of the correctly configured Cheat Engine window:

![Cheat Engine Configured](cheatengine-configured.png)

Two changed search options are underlined by red color on the screenshot. Now you can find a life parameter with the Cheat Engine scanner.

There is an "offset" column in our character's parameters table. Values in this column define a parameter's offset from the beginning of the character's object. Now we will discuss, how it is possible to find this object in the process memory.

### Object Searching

Next question is, how our bot will be able to find the correct life parameter in the game's process memory? Let us scroll up the memory region with the experience parameter at the "04FC04A4" address. You will see the character's name like it was happened in my case:

![Character's Object Head](memory-object-head.png)

These four underscored bytes are equal to the "Kain" string. [String](https://en.wikipedia.org/wiki/String_%28computer_science%29#Null-terminated) values have not a reversed byte order on the little-endian platform unlike the integers. The reason is strings have the same internal structure as simple byte arrays in a common case.

You can see that the memory block above the character's name value is zeroed. Now we start to make assumptions and to check them. Let us assume that the character's name is stored close to the upper bound of the character's object. How we can check this assumption? We can use OllyDbg debugger to make a breakpoint on the memory address, where the character's name is stored. When the game application will try to read or to write this memory, the application will be stopped by the breakpoint. Then we can investigate an application code on the breakpoint. It is probably that we will find a some kind of indication of the object's bound.

This is an algorithm of this investigation:

1. Launch OllyDbg debugger with the administrator privileges and attach it to the Diablo 2 process.

2. Select by a left mouse click the bottom-left sub-window with the memory dump in a hex format.

3. Press the *Ctrl+G* key to open the "Enter expression to follow" dialog.

4. Type the address of the character's name string to the "Enter address expression" field. The address is equal to 04FC00D in my case. Then press the "Follow expression" button. Now the cursor of the memory dump sub-window points to the first byte of the character's name.

5. Scroll up in the memory dump sub-window to find the first non-zero byte at the assumed object's border. Select this byte by a left mouse click on it.

5. Press the *Shift+F3* key to open the "Set memory breakpoint" dialog. Select the "Read access" and "Write access" check-boxes in the dialog. Then press the "OK" button. Now the memory breakpoint has set.

6. Continue an execution of the Diablo 2 process by the *F9* key. The process can be stopped on several events. One of them is our memory breakpoint. Other event, which happens often, is a break on the guarded memory page access. You can check, what kind of the event is happened in a status bar at the bottom of the OllyDbg window. Now you should continue process's execution until the "Running" status will not appear at the right-bottom corner of the OllyDbg window.

7. Switch to the Diablo 2 window. It should be stopped immediately after this switching.

8. Switch back to the OllyDbg window. It should look like this:

![Diablo 2 Ollydbg](diablo-ollydbg.png)

What do we see in this screenshot? You can see the highlighted line of a disassembled code at the upper-left sub-window. This is a code line, where the read access to our memory address with the breakpoint has happened. This is that line at the "03668D9F" address:
```
CMP DWORD PTR DS:[ESI+4], 4
```
Here the comparison between the integer of DWORD type at the "ESI + 4" address and the value 4 is happened. **ESI** is a source index [CPU register](http://www.eecg.toronto.edu/~amza/www.mindsec.com/files/x86regs.html). ESI is always used in pair with the **DS** register. DS register holds a base address of the data segment. ESI register equals to "04FC0000" address in our case. You can find this value in the upper-right sub-window, which contains current values of all CPU registers. It is common practice to hold an object address in the ESI register. Let us inspect the disassembled code below the breakpoint line. You can see these lines that are started at the "03668DE0" address:
```
MOV EDI,DWORD PTR DS:[ESI+1B8]
CMP DWORD PTR DS:[ESI+1BC],EDI
JNE SHORT 03668DFA
MOV DWORD PTR DS:[ESI+1BC],EBX
```
All these operations look like a fields of the object processing, where "1B8" and "1BC" values define the offsets of fields from the object's starting address. When you scroll down this disassembling listing, you will find similar operations with the object's fields. It allows us to conclude that start address of the player character's object equals to ESI register, i.e. 04FC0000.

We can calculate an offset of the life parameter from the start address of the character's object:
```
04FC0490 - 04FC0000 = 0x490
```
It is equal to 490 in hexadecimal. Next question, how our bot will find a start address of the character's object? We have determined, that the owning segment of the object has a special "unknown" type. Also the segment has 80000 byte size in hex and it has these flags: `MEM_PRIVATE`, `MEM_COMMIT` and `PAGE_READWRITE`. There are a minimum ten other segments that have the same byte size and flags. It means, that we cannot find the necessary segment by traversing them.

Let us look at the first bytes of the character's object:
```
00 00 00 00 04 00 00 00 03 00 28 0F 00 4B 61 69 6E 00 00 00
```
If you will restart the Diablo 2 application and find this character's object again, you will see the same first bytes. We can make assumption, that these bytes match to the unchanged character's parameters. This kind of parameters is defined at the character creation moment. Once they are created, they are never changed. This is a probable list of the parameters:

1. Character's name.
2. [Expansion character](http://diablo.wikia.com/wiki/Expansion_Character) flag.
3. [Hardcore mode](http://diablo.wikia.com/wiki/Hardcore) flag.
4. Code of the character's class.

This set of the unchanged bytes can be used as [**magic numbers**](https://en.wikipedia.org/wiki/Magic_number_%28programming%29) for searching the character's object in the memory. Be aware that these "magic numbers" will be different for your case. Lack of flexibility is the main disadvantage of this approach. You can test a correctness of the selected magic numbers with the Cheat Engine scanner. Select the "Array of byte" item of the "Value Type" option. Then select a "Hex" check-box and copy the first bytes of the character's object into the "Array of byte" field. This is the search result for my case:

![Magic Numbers Search](magic-numbers-search.png)

You can see that the address of a character's object has been changed. Now the address is equal to "04F70000". But offsets of all object's parameters are still the same. It means that the new address of the character's life parameter equals to "04F70490".

## Bot Implementation

Now we have enough information to implement our bot application. There is a detailed algorithm of the bot:

1. Enable `SE_DEBUG_NAME` privilege for the current process. It is needed to read memory of the Diablo 2 process.
2. Open the Diablo 2 process.
3. Search a player character object in the process memory.
4. Calculate an offset of character's life parameter.
5. Read in a value of life parameter in loop. Use a health potion if the value is less than 100.

First step of the algorithm has been described in the [Process Memory Access](process-memory-access.md) section. Second algorithm's step is able to be implemented in two ways. We can either to use a hardcoded PID value as we did it before or to calculate PID value of the current active window. PID calculation allows us to make the bot application more flexible and to avoid its recompilation before start.

There is a code snippet that calculates the PID and opens the game process:
```C++
int main()
{
	Sleep(4000);

	HWND wnd = GetForegroundWindow();
	DWORD pid = 0;
	if (!GetWindowThreadProcessId(wnd, &pid))
	{
		printf("Error of the pid detection\n");
		return 1;
	}
	
	HANDLE hTargetProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
	if (!hTargetProc)
		printf("Failed to open process: %u\n", GetLastError());
	
	return 0;
}
```
Two WinAPI functions are used here. There are [`GetForegroundWindow`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms633505%28v=vs.85%29.aspx) and [`GetWindowThreadProcessId`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms633522%28v=vs.85%29.aspx). `GetForegroundWindow` function allows us to get a handle of the current window in foreground mode. This is an active window with which the user is currently working. `GetWindowThreadProcessId` function retrieves a PID of the process that owns the specified window. The PID value is stored in the `pid` variable after execution of this code snippet. Also you can see a four seconds delay at the first line of the `main` function. The delay provides a time for us to switch to the Diablo 2 window after the bot application start.

Third step of our bot algorithm is searching character's object. I suggest to use an approach that has been described in this [series of video lessons](https://www.youtube.com/watch?v=YRPMdb1YMS8&feature=share&list=UUnxW29RC80oLvwTMGNI0dAg). It is described how to write a memory scanner for video games in these lessons. Core idea of the scanner is to traverse all memory segments of the game process via the [VirtualQueryEx](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366907%28v=vs.85%29.aspx) WinAPI function. We will use exact the same function to traverse memory segments of Diablo 2 process.

This is a code snippet that searches character's object in the Diablo 2 memory:
```C++
SIZE_T IsArrayMatch(HANDLE proc, SIZE_T address, SIZE_T segmentSize, BYTE array[], SIZE_T arraySize)
{
	BYTE* procArray = new BYTE[segmentSize];

	if (ReadProcessMemory(proc, (void*)address, procArray, segmentSize, NULL) != 0)
	{
		printf("Failed to read memory: %u\n", GetLastError());
		delete[] procArray;
		return 0;
	}
	
	for (SIZE_T i = 0; i < segmentSize; ++i)
	{
		if ((array[0] == procArray[i]) && ((i + arraySize) < segmentSize))
		{
			if (!memcmp(array, procArray + i, arraySize))
			{
				delete[] procArray;
				return address + i;
			}
		}
	}

	delete[] procArray;
	return 0;
}

SIZE_T ScanSegments(HANDLE proc, BYTE array[], SIZE_T size)
{
	MEMORY_BASIC_INFORMATION meminfo;
	LPCVOID addr = 0;
	SIZE_T result = 0;

	if (!proc)
		return 0;

	while (1)
	{
		if (VirtualQueryEx(proc, addr, &meminfo, sizeof(meminfo)) == 0)
			break;

		if ((meminfo.State & MEM_COMMIT) && (meminfo.Type & MEM_PRIVATE) && 
			(meminfo.Protect & PAGE_READWRITE) && !(meminfo.Protect & PAGE_GUARD))
		{
			result = IsArrayMatch(proc, (SIZE_T)meminfo.BaseAddress, 
				meminfo.RegionSize, array, size);

			if (result != 0)
				return result;
		}
		addr = (unsigned char*)meminfo.BaseAddress + meminfo.RegionSize;
	}
	return 0;
}

int main()
{
	// Enable `SE_DEBUG_NAME` privilege for current process here.

	// Open the Diablo 2 process here.

	BYTE array[] = { 0, 0, 0, 0, 0x04, 0, 0, 0, 0x03, 0, 0x28, 0x0F, 0, 0x4B, 0x61, 0x69, 0x6E, 0, 0, 0 };

	SIZE_T objectAddress = ScanSegments(hTargetProc, array, sizeof(array));
	
	return 0;
}
```
`ScanSegments` function implements the algorithm of traversing the segments. There are three steps in the function's loop:

1. Read via `VirtualQueryEx` function current memory segment which base address equals to the `addr` variable.
2. Compare flags of the current segment with the flags of a typical "unknown" segment. Skip the segment in case the comparison does not pass.
3. Search the discovered "magic numbers" of the character object into current segment.
4. Return resulting address of the character object.

"Magic numbers" searching algorithm is provided by the `IsArrayMatch` function. This function is called from the `ScanSegments` one. There are two steps of the `IsArrayMatch` function:

1. Read data of entire current segment by the `ReadProcessMemory` WinAPI function.
2. Compare memory of "magic numbers" array with the segment's memory in a loop.

Also the code snippet provides an example how the `ScanSegments` function can be called from the `main` function. You should pass these input parameters to the function: handle of the Diablo 2 process, pointer to the "magic numbers" array and size of this array. Do not forget that "magic numbers" will be different in your case.

Fourth step of the bot's algorithm is calculation of life parameter's address. The `objectAddress` variable provided by `ScanSegments` function is used for this calculation:
```C++
SIZE_T hpAddress = objectAddress + 0x490;
```
Now the `hpAddress` variable stores an address of the life parameter.

Last step of the bot's algorithm contains checking of the life parameter value and usage of a health potion when it is needed. This is a code snippet with implementation of both these actions:
```C++
WORD ReadWord(HANDLE hProc, DWORD_PTR address)
{
	WORD result = 0;

	if (ReadProcessMemory(hProc, (void*)address, &result, sizeof(result), NULL) == 0)
		printf("Failed to read memory: %u\n", GetLastError());

	return result;
}

int main()
{
	// Enable `SE_DEBUG_NAME` privilege for current process here.

	// Open the Diablo 2 process here.

	// Search a player character object here.

	// Calculate an offset of character's life parameter here.

	ULONG hp = 0;

	while (1)
	{
		hp = ReadWord(hTargetProc, hpAddress);
		printf("HP = %lu\n", hp);

		if (hp < 100)
			PostMessage(wnd, WM_KEYDOWN, 0x31, 0x1);

		Sleep(2000);
	}
	return 0;
}
```
Value of the life parameter is read in the infinite loop via `ReadWord` function. The `ReadWord` function is just a wrapper around the `ReadProcessMemory` WinAPI function. Then current value of the life parameter is printed to the console. You can check a correctness of the bot's algorithm by comparing a printed life value with the actual one in the Diablo 2 game application.

If the life value is less than 100, the bot presses *1* hotkey to use a health potion. The `PostMessage` WinAPI function is used here for key pressing simulation. Yes, this is not a "pure" way to embed data into the game process memory. We just inject a [`WM_KEYDOWN`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646280%28v=vs.85%29.aspx) message about a key pressing action into the event queue of Diablo 2 process. This is the simplest way for player actions simulation. More complex approaches of actions simulation will be described further.

`PostMessage` function has four parameters. First parameter is a handle of the target window which receives the message. Second parameter is a message code. It is equal to `WM_KEYDOWN` for our case. Third parameter is a [virtual code](https://msdn.microsoft.com/en-us/library/windows/desktop/dd375731%28v=vs.85%29.aspx) of the pressed key. Fourth function's parameter is an encoded set of several parameters. Most important one from this set is a repeat count for the current message. Bits from 0 to 15 are used to store a repeat count value. It is equal to "1" in our case. The key press simulation does not work if you specify a zero as the fourth parameter of the `PostMessage` function.

Complete implementation of the example bot is available in the [`AutohpBot.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/Diablo2Example/AutohpBot.cpp) source file.

This is an algorithm to test the example bot:

1. Change the "magic numbers" according to your character in this code line:
```C++
	BYTE array[] = { 0, 0, 0, 0, 0x04, 0, 0, 0, 0x03, 0, 0x28, 0x0F, 0, 0x4B, 0x61, 0x69, 0x6E, 0, 0, 0 };
```
2. Compile the bot application with new "magic numbers".
3. Launch the Diablo 2 game in the windowed mode.
4. Launch the bot application with administrator privileges.
5. Switch to the Diablo 2 window during the four seconds delay. After this delay the bot captures current active window and start to analyze its process.
6. Get a damage from monsters in the Diablo 2 game to decrease character's life parameter below the 100 value.

The bot presses *1* hotkey when character's life parameter becomes less than 100. Do not forget to assign a health potion to the *1* hotkey. You can press *H* key to open a quick tips window. You will see a "Belt" hotkey panel in the right-bottom corner of the game window. You can drag and drop health potions to the hotkey panel by left clicking on them.

### Further Improvements

Let us consider ways to improve our example bot application. First obvious issue of current bot implementation is usage only first socket of the hotkey panel. More effective solution is sequential usage of the slots from first to fourth number in the loop.

This is a code snippet with a new version of the checking life parameter loop:
```C++
	ULONG hp = 0;
	BYTE keys[] = { 0x31, 0x32, 0x33, 0x34 };
	BYTE keyIndex = 0;

	while (1)
	{
		hp = ReadWord(hTargetProc, hpAddress);
		printf("HP = %lu\n", hp);

		if (hp < 100)
		{
			PostMessage(wnd, WM_KEYDOWN, keys[keyIndex], 0x1);
			++keyIndex;
			if (keyIndex == sizeof(keys))
				keyIndex = 0;
		}
		Sleep(2000);
	}
```
Now list of virtual codes of keys is stored in the `keys` array. The `keyIndex` variable is used for indexing elements of the array. The `keyIndex` value is incremented each time when a health potion is used. The index is reset back to zero value if it reaches a bound of the `keys` array. This approach allows us to use all health potions in the hotkey panel one after each other. When the first row of potions becomes completely empty, the second row is used and so on.

Second possible improvements is analyzing character's mana parameter. It is simple to calculate offset of the parameter and read its value in the same checking loop. Bot is able to choose either health or mana potion to use when character's life or mana parameter is low.

Simulate a keypress action with `PostMessage` function is one of several ways to embed data into the game process memory. Another way is just to write a new value of the parameter to its address. 

This is a code snippet that demonstrates this approach:
```C++
void WriteWord(HANDLE hProc, DWORD_PTR address, WORD value)
{
	if (WriteProcessMemory(hProc, (void*)address, &value, sizeof(value), NULL) == 0)
		printf("Failed to write memory: %u\n", GetLastError());
}

int main()
{
	// Enable `SE_DEBUG_NAME` privilege for current process here.

	// Open a game process here.

	// Search a player character object here.

	// Calculate an offset of character's life parameter here.

	ULONG hp = 0;

	while (1)
	{
		hp = ReadWord(hTargetProc, hpAddress);
		printf("HP = %lu\n", hp);

		if (hp < 100)
			WriteWord(hTargetProc, hpAddress, 100);

		Sleep(2000);
	}
	return 0;
}
```
You can see that we have added an extra function with the `WriteWord` name. This is a simple wrapper over the `WriteProcessMemory` WinAPI function. Now the bot writes 100 value to the life parameter directly if the parameter's value becomes less than 100. This approach has an issue. It breaks the game rules. Therefore, it is probable that a state of game objects becomes inconsistent after this writing operation. You can try to launch this version of the bot for Diablo 2 application. The character's life parameter is still unchanged. It happens because the parameter's value is stored in several game objects. All these values are compared regularly by a control algorithm. The algorithm can fix incorrect values according to other ones. Exact the same values of parameters fixing happens for the on-line game. The fixing is happened on the server side in this case. We can conclude that this approach is able to be used for some games with single play mode only.

There is a third way to embed bot's data to the process. This is the [first](http://www.codeproject.com/Articles/4610/Three-Ways-to-Inject-Your-Code-into-Another-Proces) and the [second](http://www.codeproject.com/Articles/9229/RemoteLib-DLL-Injection-for-Win-x-NT-Platforms) article about code injection techniques. Core idea of these techniques is execution your code inside the game process. It means that the bot application has a direct access to call any function of the game application. You do not need to simulate any keypress action now. Instead you can just call "UsePotion" function directly. But this approach requires deep analysis and reverse engineering of the game application.

Our example bot implements a very simple algorithm. It reacts to a low value of the life parameter and performs keypresses. But is it possible to implement an in-game farm bot that will automatically hunt monsters? Yes, we can do it. The major task for a farm bot algorithm implementation is searching monsters in the game process memory. Now we know both X and Y coordinates of the player's character. They are specified in the player's character parameters table above. Both coordinates have a size equals to two bytes. Also Y coordinate follows the X coordinate without any gap. Now we can assume that the monsters near the player's character have coordinates with the close values. Bot application can scan the game memory to four byte number, which consist of couple values of two bytes size. Each appropriate search result is able to be added to a "possible monsters" list. Next action is filtering actual and wrong results. Tip for filtering algorithm is an assumption that all actual monsters' coordinates should have close addresses. Also bot application can remember a memory segment where the actual monsters' coordinates are stored. This segment will be used for all further scan operations. Bot can use the same approach of keypress simulation with the `PostMessage` WinAPI function to hit monsters.

## Summary

TODO: Briefly describe the considered methods and approaches. Look at the clicker bot example section.