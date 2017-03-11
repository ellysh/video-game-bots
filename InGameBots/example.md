# Example with Diablo 2

## Diablo 2 Overview

Now we will write a simple in-game bot for the popular RPG game Diablo 2. Gameplay of Diablo 2 is quite typical for the RPG genre. Player should do quests, kill monsters and improve his character. Our example bot focuses on analysis of player character's state. When the state is changed, the bot does some actions. Therefore, it will be helpful to consider parameters of the player character in details.

There is a screenshot of the game window:

![Diablo 2 Interface](diablo-interface.png)

You can see the player character in the center of the screen. There is an yellow model of the knight. Also you can see the monsters around the player character. One of the monster is selected by the mouse cursor.

There is a screenshot of windows with parameters of player character:

![Diablo 2 Player](diablo-player.png)

There are two windows on the screenshot. Left window contains common information about the player character like his name "Kain", class "Paladin", level and experience points. This information available at the top side of the window. Also below there are attributes, that define behavior of the character during a game process. For example, the "Strength" attribute defines a damage amount that is delivered to the monsters by the player.

Right window contains a tree of character's skills. There are special abilities and combos that allow you to make a more damage or to improve significantly character's attributes. Each skill has a level. The level defines effectiveness of the skill usage. You can get detailed information about these parameters and skills in the [wiki page](http://diablo.gamepedia.com/Classes_%28Diablo_II%29)

Diablo 2 has a single player and a multiplayer game modes. We will consider the single player mode only. It allows us to stop execution of the game process at any moment and to explore its memory without any time limitations. Otherwise, the game client, which does not respond to requests of a game server, will be disconnected. This limitation does not allow us to use a debugger and to break the game process for analysis its internals.

Diablo 2 is available for buying at the [Blizzard Entertainment website](https://eu.battle.net/shop/en/product/diablo-ii). There is the open source game with the [Flare](http://flarerpg.org/) name. It is available for free and has a very similar game mechanics as Diablo 2 has. You can use the Flare game to try methods of the memory analysis, which are described in this section. All these methods are applicable to the Flare game too. The main difference between these two games is complexity. Diablo 2 has much more library modules and game objects in the memory than the Flare one. Thus, analysis of the Diablo 2 memory is more difficult.

## Bot Overview

You can find detailed articles by Jan Miller about hacking the Diablo 2 game. This is the first [article](http://extreme-gamerz.org/diablo2/viewdiablo2/hackingdiablo2). This is the second [one](http://www.battleforums.com/threads/howtohackd2-edition-2.111214/). Approaches, which are described in the articles, are focused on changing a normal behavior of the game. This kind of behavior changes is called **hacks**. But our bot applications should work in a different manner. The bot should react to state changes of the game objects. Possible reaction of the bot is to simulate player action or change a state of the game objects in a legal way according to the game rules. Meanwhile, the game application is still working within its normal algorithms and the state of all objects is valid according to the game rules.

Our example in-game bot has a very simple algorithm:

1. Read a current life parameter value of the player character.
2. Compare this value with the threshold.
3. Use a healing potion to increase the life parameter.

This algorithm allows us to keep the player character alive while the healing potions are available. Nevertheless an implementation of so simple algorithm requires a deep research of the Diablo 2 process memory.

## Diablo 2 Memory Analysis

Now we are ready to start our analysis of the Diablo 2 process memory. First of all you should launch the game. It is launched in the fullscreen mode by default. But it will be more convenient for us to launch the game in the windowed mode. It allows you to switch quickly between the game window and the memory scanner. There is the instruction how to launch the game in the windowed mode:

1. Right-click on the "Diablo II" icon to open the popup menu and click on the "Properties" menu item.
2. Click the "Shortcut" tab in the "Properties" dialog.
3. Add the `-w` key at the end of the "Target" field. This is an example:
```
"C:\DiabloII\Diablo II.exe" -w
```

Now launch the game via the changed icon. When it is launched, you should select the "Single player" option in the main menu, create a new character and start the game.

### Search the Parameters

Goal of our memory analysis is to find an address of the player's life parameter into the game process memory. First and the most obvious way to achieve this goal is to use Cheat Engine memory scanner. You can launch Cheat Engine and try to search current value of the life parameter without any configuration of the search options. This approach does not work for me. You will get a long list of the resulting addresses. If you continue searching by selecting "Next Scan" option with updated life value, the resulting list becomes empty.

Straightforward approach does not work. The primary reason of this issue is a complexity of the Diablo 2 game model. There are a lot of game objects in the memory. Now we do not know, how parameters of these objects are stored into the memory. Therefore, it will be better to find an approach that allows us to detect a specific object into the memory.

Let us look at the window with attributes of the player character again. There are several parameters that are unique for the player object. We can name this kind of unique parameters as **artifacts** for the sake of brevity. What are the artifacts for the player character object? This is a list of them:

1. **Character name**<br/>
This is extremely unlikely that other game object has the same name as the player character. If it happens, you can rename your character to guarantee its unique name.
2. **Experience value**<br/>
This is a long positive integer number. The number of such length is able to appear in other objects rarely. But you can change it easily by killing several monsters. Then make next memory scan operation with the new value and you will find this number.
3. **Stamina value**<br/>
This is a long positive number too. You can change it by running outside the city.

I suggest to choose the experience value for searching. In case the value equals to zero, you can kill several monsters to change it. The value grows rapidly. This is result of the memory scan for my case:

![Experience Value](experience-value.png)

There are several values in the game memory that equal to the player experience value.

Next step is to distinguish the value that is contained inside the player object. First of all, we can clarify a type of owning segment for each of these variables. This is the shortened output of the `!address` command, which is executed in the WinDbg debugger:
```
+ 0`003c0000  0`003e0000  0`00020000  MEM_PRIVATE MEM_COMMIT PAGE_READWRITE <unknown>
+ 0`03840000  0`03850000  0`00010000  MEM_PRIVATE MEM_COMMIT PAGE_READWRITE <unknown>
+ 0`03850000  0`03860000  0`00010000  MEM_PRIVATE MEM_COMMIT PAGE_READWRITE <unknown>
+ 0`04f50000  0`04fd0000  0`00080000  MEM_PRIVATE MEM_COMMIT PAGE_READWRITE <unknown>
```
You can see, that all found variables are stored into the segments of "unknown" type. What is the "unknown" type? We already know the segments of stack and heap types. WinDbg debugger can distinguish them well. Therefore, these "unknown" segments are neither stack nor heap type. These segments are able to be allocated by the [`VirtualAllocEx`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366890%28v=vs.85%29.aspx) WinAPI function. We can verify this assumption by writing the simple [test application](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/Diablo2Example/VirtualAllocEx.cpp), that uses the `VirtualAllocEx` function. In case you launch this test application with the WinDbg debugger, you will see a segment of "unknown" type in the application's memory map. The base address of the "unknown" segment has the same value as the returned one by the `VirtualAllocEx` function. 

Segments analysis does not allow us to find the player experience parameter. All of these "unknown" segments have the same type and flags. Therefore, we cannot distinguish them.

We can try another way to find the character object. It is obvious that parameters of the object will be changed, when the player performs actions. For example, player's coordinates are changed when we move. Also live value is decreased when the player gains a damage from monsters. Consider this fact, we can analyze the nature of changes in the memory that is located near the experience parameter. Cheat Engine memory scanner provides the feature to display changes of a memory region in real-time. There is the algorithm to open a Memory Viewer window of the Cheat Engine application:

1. Select an address in the resulting list for inspection.
2. Left click on the address.
3. Select the "Browse this memory region" item in the pop-up menu.

Now you see this Memory Viewer window:

![Memory Viewer](memory-viewer.png)

The Memory Viewer window is split into two parts. Disassembled code of the current memory region is displayed at the upper part of the window. The memory dump in the hexadecimal format is displayed at the bottom part. We will focus on the memory dump in our case. Value of the experience parameter is underlined by a red line on the screenshoot. It is not obvious, why the hexadecimal value "9E 36 FF 10" in the memory dump is equal to the actual value "285161118" of experience parameter in decimal. Our application is launched on the x86 architecture. This architecture has the [little-endian](https://en.wikipedia.org/wiki/Endianness#Little-endian) byte order. It means that you should reverse the byte order of the four byte integer to get its correct value. The hexadecimal value becomes equal to "10 FF 36 9E" in our case. You can use the standard Windows Calculator application to check that this hexadecimal value equals to the "285161118" one in decimal.

Actually you can change the format of integers in the memory dump. You should left mouse click on the dump sub-window and choose the "Display Type" item of the pop-up menu. But I recommend you to keep the "Byte hex" format. Because you do not know an actual size in bytes of the parameters that you are looking for.

Now you should place both windows of Memory Viewer and Diablo 2 application one near each other. It allows you to perform actions in the Diablo 2 window and to inspect the memory region in the Memory Viewer simultaneously. This is the screenshot with the results of the memory inspection:

![Memory Inspection](memory-inspection.png)

On the screenshot you can see the memory region near the "04FC04A4" address. This address we got when we have looked for the experience value with the Cheat Engine scanner. If you analyze the memory regions around all addresses from the scanner resulting list, you find that the memory region around the last address in this list contains the maximum of information about the player. We come to this conclusion through trials and errors of changing the values by in-game actions. The address "04FC04A4" may differ in your case but it should be on the last position in the scanner resulting list.

These are parameters that we detected in the memory region:

| Parameter | Address | Offset | Size | Hex Value | Dec Value |
| -- | -- | -- | -- | -- | -- |
| Life | 04FC0490 | 490 | 2 | 40 01 | 320 |
| Mana | 04FC0492 | 492 | 2 | 9D 01 | 413 |
| Stamina | 04FC0494 | 494 | 2 | FE 1F | 8190 |
| Coordinate X | 04FC0498 | 498 | 2 | 37 14 | 5175 |
| Coordinate Y | 04FC04A0 | 4A0 | 2 | 47 12 | 4679 |
| Experience | 04FC04A4 | 4A4 | 4 | 9E 36 FF 10 | 285161118 |

All these parameters are underlined by the red color on the Memory Viewer screenshot. To deduce these parameters I did follow actions:

1. Stay on one place and get the damage from any monster.
All parameters of the player except the life one stay the same in this case. This allows me to deduce that only one changing value at the "04FC0490" matches to the player's life.

2. Stay on one place and cast any spell.
Only one player's parameter, which is changed in this case, is the mana. Therefore, I conclude that value at the "04FC0492" matches to the players' mana.

3. Run outside the city.
Movement of the character leads to a change of three parameters at the same time: stamina, X and Y coordinates. But if you move the character a long time, the stamina parameter become equals to 0. This allows us to distinguish this parameter. Then when I move the character in horizontal and vertical directions, I find which of two values at "04FC0498" and "04FC04A0" addresses match to X and Y coordinates.

4. Kill any random monster.
When the player kill the monster the experience increases. You can easily distinguish this parameter from the life and mana ones because during the fight they are decrease. This way I found that value at the "04FC04A4" address matches to the experience.

What new we have known about the player's parameters from this inspection? First of all, size of the life parameter equals to two bytes. It means that you should specify the "2 Byte" item of the "Value Type" option in the main window of Cheat Engine if you want to search the life parameter. Also you can see that some of the parameters have [alignment](https://en.wikipedia.org/wiki/Data_structure_alignment), which is not equal to four bytes. For example, let us consider the mana parameter at the 04FC0492 address. You can check with calculator that the 04FC0492 value is not divided to 4 without a remainder. It means that you should deselect the "Fast Scan" check-box in the main window of Cheat Engine to find unaligned parameters. 

This is the screenshot of the Cheat Engine window with the correct configuration:

![Cheat Engine Configured](cheatengine-configured.png)

Two changed search options are underlined by the red color on the screenshot. Now the Cheat Engine scanner is able to find any parameter of the player.

There is the "Offset" column in our table of the player parameters. Values in this column define the offset of each parameter from the beginning of the player's object in memory. Now we will consider, how it is possible to find this object in the process memory.

### Search the Object

Next question is, how our bot will be able to find the player parameter inside the memory of the game process? Let us scroll up the memory region with the experience parameter at the 04FC04A4 address. You will find the player name like it happened in my case:

![Character's Object Head](memory-object-head.png)

These four underscored bytes are equal to the "Kain" string. [String](https://en.wikipedia.org/wiki/String_%28computer_science%29#Null-terminated) values do not have the reversed byte order on the little-endian architecture unlike the integer ones. The reason is string has the same internal structure as the simple byte array in a common case.

You can see that the memory block above player name is zeroed. Now we start to make assumptions and to check them. Let us assume that player name is stored close to the upper bound of the player object. How we can check this assumption? We can use OllyDbg debugger to make the breakpoint on the memory address, where player name is stored. When the game application will try to read from or to write into this memory, it will be stopped by the breakpoint. Then we can analyze the application code that tries to access this memory. It is probably that we will find some footprints of the object bounds.

This is the algorithm to search the object bounds:

1. Launch the OllyDbg debugger with the administrator privileges. Attach the debugger to the launched Diablo 2 process.

2. Select by the left mouse click the bottom-left sub-window of the debugger with the memory dump in the hex format.

3. Press the *Ctrl+G* key to open the "Enter expression to follow" dialog.

4. Type an address of the string with the player name into the "Enter address expression" field. The address equals to the 04FC00D value in my case. Then press the "Follow expression" button. Now the cursor in the memory dump sub-window points to the first byte of the string with the player name.

5. Scroll up in the memory dump sub-window to find the first non-zero byte at the assumed object beginning. Select this byte by the left mouse click.

5. Press the *Shift+F3* key to open the "Set memory breakpoint" dialog. Select the "Read access" and the "Write access" check-boxes in the dialog. Then press the "OK" button. Now the memory breakpoint at the object beginning is set.

6. Continue execution of the Diablo 2 process by the *F9* key press. The process can be stopped on several events. One of them is our memory breakpoint. Other event, which happens often, is the break on access to the guarded memory page. You can check, what kind of the event is happened now in the status bar at the bottom side of the OllyDbg window. Now you should continue execution of the process until the "Running" status does not appear at the right-bottom corner of the OllyDbg window.

7. Switch to the Diablo 2 window. The game application should be stopped immediately after this switching.

8. Switch back to the OllyDbg window. The window should look like this:

![Diablo 2 Ollydbg](diablo-ollydbg.png)

You can see the highlighted line of the disassembled code in the upper-left side of the debugger window. This is the code line at the "03668D9F" address, which try to access the memory with our breakpoint:
```
CMP DWORD PTR DS:[ESI+4], 4
```
The comparison between the integer of the DWORD type at the "ESI + 4" address and the "4" value is happened here. **ESI** is the source index [CPU register](http://www.eecg.toronto.edu/~amza/www.mindsec.com/files/x86regs.html). ESI is always used in pair with the **DS** register. The DS register holds a base address of the data segment. The ESI register equals to the "04FC0000" address in our case. You can find this value in the upper-right side of the debugger window, which contains current values of all CPU registers. This is a common practice to hold an object address in the ESI register. Let us inspect the disassembled code below the breakpoint line. 

You can see these lines that are started at the "03668DE0" address:
```
MOV EDI,DWORD PTR DS:[ESI+1B8]
CMP DWORD PTR DS:[ESI+1BC],EDI
JNE SHORT 03668DFA
MOV DWORD PTR DS:[ESI+1BC],EBX
```
All these operations look like processing of the object fields. The "1B8" and "1BC" values define offsets of the fields from the object beginning. If you scroll down this disassembling listing, you will find similar operations with object fields. We can conclude that the beginning address of the player object equals to the "04FC0000" value of the ESI register.

Now we can calculate the offset of the life parameter. This is the parameter offset from the beginning of the player object:
```
04FC0490 - 04FC0000 = 0x490
```
The offset equals to 490 in hexadecimal.

Next question, how our bot will find beginning address of the object? We have determined that the owning segment of the object has the special "unknown" type. Also the segment has size of the 80000 bytes in hexadecimal and it has these flags: `MEM_PRIVATE`, `MEM_COMMIT` and `PAGE_READWRITE`. There are minimum ten other segments that have the same byte size and the flags. It means that we cannot find the necessary segment by traversing them and checking their sizes and flags.

Let us look at the first bytes of the player object:
```
00 00 00 00 04 00 00 00 03 00 28 0F 00 4B 61 69 6E 00 00 00
```
If you restart the Diablo 2 application and find this object again, you see the same byte sequence at the beginning of the object. We can assume, that this byte sequence matches to the unchanged player parameters. This kind of parameters is defined when player creates his character. Once they was set, they are never changed again.

This is the list of  probable unchanged parameters:

1. The player name.
2. The [expansion character](http://diablo.wikia.com/wiki/Expansion_Character) flag.
3. The [hardcore mode](http://diablo.wikia.com/wiki/Hardcore) flag.
4. The encoded class of the character.

This unchanged byte sequence can be used as the [**magic numbers**](https://en.wikipedia.org/wiki/Magic_number_%28programming%29) to search the object in the memory. Be aware that these "magic numbers" will differ for your case. The lack of flexibility is the main disadvantage of this approach. You can check correctness of the magic numbers with the Cheat Engine scanner. Select the "Array of byte" item of the "Value Type" option. Then select the "Hex" check-box and copy the magic numbers into the "Array of byte" field. 

This is the result of search for my case:

![Magic Numbers Search](magic-numbers-search.png)

You can see that the address of the player object is changed. Now it equals to "04F70000". But offsets of all object parameters are still the same. It means that the new address of the life parameter equals to "04F70490".

## Bot Implementation

Now we have enough information to implement our bot application. This is the detailed algorithm of the bot:

1. Enable the `SE_DEBUG_NAME` privilege for the current process. This is needed to read the memory of the Diablo 2 process.
2. Open the Diablo 2 process.
3. Search the player object in the process memory.
4. Calculate the offset of the life parameter.
5. Read a value of the life parameter in a loop. Use a healing potion if the value is less than 100.

First step of the algorithm was described in the [Process Memory Access](process-memory-access.md) section. Second step we can implement in two ways. We can either to use a hardcoded PID value as we did it before or to calculate the PID value of the process that owns the current active window. We assume that Diablo 2 window will be active when we launch our bot. The PID calculation approach allows us to make the bot application more flexible and to avoid its recompilation before launching.

This is the code snippet that calculates the PID of the game process and opens it:
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
Two WinAPI functions are used here. There are [`GetForegroundWindow`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms633505%28v=vs.85%29.aspx) and [`GetWindowThreadProcessId`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms633522%28v=vs.85%29.aspx). The `GetForegroundWindow` function allows us to get a handle of the current window in the foreground mode. This is exact the window, which is used by the user at the moment. The `GetWindowThreadProcessId` function retrieves a PID of the process that owns the specified window. The PID value is stored in the `pid` variable after execution of this code snippet. Also you can see four seconds delay at the first line of the `main` function. The delay provides enough time for us to switch to the Diablo 2 window after launching the bot.

Third step of our bot algorithm is to find the player object. I suggest to use the approach that was described in this [series of video tutorials](https://www.youtube.com/watch?v=YRPMdb1YMS8&feature=share&list=UUnxW29RC80oLvwTMGNI0dAg). The tutorials describe the implementation of the simple memory scanner. Algorithm of this scanner is very similar to the Cheat Engine scanner one. The core idea of the scanner is to traverse all memory segments of a target process by the [VirtualQueryEx](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366907%28v=vs.85%29.aspx) WinAPI function. We will use exact the same function to traverse memory segments of the Diablo 2 process.

This is the code snippet that searches the player object in the Diablo 2 memory:
```C++
SIZE_T IsArrayMatch(HANDLE proc, SIZE_T address, SIZE_T segmentSize, BYTE array[],
				    SIZE_T arraySize)
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

	BYTE array[] = { 0, 0, 0, 0, 0x04, 0, 0, 0, 0x03, 0, 0x28, 0x0F, 0, 0x4B, 0x61,
					 0x69, 0x6E, 0, 0, 0 };

	SIZE_T objectAddress = ScanSegments(hTargetProc, array, sizeof(array));
	
	return 0;
}
```
The `ScanSegments` function implements the algorithm of traversing the memory segments. There are three steps in the loop of this function:

1. Read via the `VirtualQueryEx` WinAPI function the current memory segment, which base address equals to the `addr` variable.

2. Compare flags of the current segment with the flags of a typical "unknown" segment. Skip the segment in case the comparison does not pass.

3. Search the discovered "magic numbers" of the player object into the current segment.

4. Return the resulting address of the player object.

Algorithm to find the "magic numbers" into the current segment is provided by the `IsArrayMatch` function. This function is called from the `ScanSegments` one. There are two steps in the `IsArrayMatch` function:

1. Read data of the entire current segment by the `ReadProcessMemory` WinAPI function.

2. Find the "magic numbers" in the current segment.

Also the code snippet provides the example, how the `ScanSegments` function can be called from the `main` function. You should pass these input parameters to the `ScanSegments` function:

1. The handle of the Diablo 2 process

2. The pointer to the "magic numbers" array

3. The size of this array.

Do not forget that the "magic numbers" will differ in your case.

Fourth step of the algorithm is to calculate the address of the life parameter. The `objectAddress` variable, which is returned by the `ScanSegments` function, is used for this calculation:
```C++
SIZE_T hpAddress = objectAddress + 0x490;
```
Now the `hpAddress` variable stores the address of the life parameter.

Last step of the algorithm is to check the value of the life parameter and to use a healing potion in case the value is less than the threshold. 

This is the code snippet with the implementation of both these actions:
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
The value of the life parameter is read in the infinite loop by the `ReadWord` function. The `ReadWord` function is just a wrapper around the `ReadProcessMemory` WinAPI function. Then the current value of the life parameter is printed to the console. You can check that our bot works properly if you compare the printed value of the life parameter with the actual one, which is displayed in the Diablo 2 window.

If the life value is less than 100, the bot presses the *1* hotkey to use the healing potion. The `PostMessage` WinAPI function is used here to simulate the key press. Yes, this is not the "pure" way to embed data into the process memory. We just inject the [`WM_KEYDOWN`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646280%28v=vs.85%29.aspx) message about the key press action into the event queue of the Diablo 2 process. This is the simplest way to simulate the player actions. More complex approaches to do it will be described further.

The `PostMessage` function has four parameters. The first parameter is a handle of the target window, which receives the message. The second parameter is the message code. It is equal to the `WM_KEYDOWN` code in our case. The third parameter is the [virtual code](https://msdn.microsoft.com/en-us/library/windows/desktop/dd375731%28v=vs.85%29.aspx) of the pressed key. The fourth parameter of the function is the encoded set of several parameters. The most important one from this set is the repeat count for the sent message. The bits from 0 to 15 are used to store the repeat count value. It is equal to "1" in our case. The key press simulation does not work if you specify zero as the fourth parameter of the `PostMessage` function.

Complete implementation of the example bot is available in the [`AutohpBot.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/Diablo2Example/AutohpBot.cpp) source file.

This is the algorithm to launch our bot:

1. Change the "magic numbers" according to your character. This is the code line to change:
```C++
	BYTE array[] = { 0, 0, 0, 0, 0x04, 0, 0, 0, 0x03, 0, 0x28, 0x0F, 0, 0x4B, 0x61,
					 0x69, 0x6E, 0, 0, 0 };
```

2. Compile the bot application with the new "magic numbers".

3. Launch the Diablo 2 game in the windowed mode.

4. Launch the bot application with the administrator privileges.

5. Switch to the Diablo 2 window during four seconds delay. After this delay the bot captures the current active window and start to analyze its process.

6. Get a damage from monsters in the Diablo 2 game to decrease your life parameter below the 100 value.

The bot presses *1* hotkey when the life parameter becomes less than 100. Do not forget to assign a healing potion to the *1* hotkey. You can press *H* key to open the quick tips window. You will see the "Belt" hotkey panel in the right-bottom corner of the game window. You can drag and drop the healing potions to the hotkey panel by the left click on them.

### Further Improvements

Let us consider ways to improve our bot. The first obvious issue of the current implementation is usage only the first socket of the hotkey panel. The more effective solution is to use of all slots of the panel in the loop.

This is the code snippet with the new version of the loop that checks the life parameter:
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
Now we store a list of the virtual key codes in the `keys` array. The `keyIndex` variable is used to index elements of the array. The `keyIndex` value is incremented each time when the healing potion is used. We reset the index back to zero if it reaches the end of the `keys` array. This approach allows us to use all healing potions in the hotkey panel one after each other. When the first row of the potions becomes completely empty, the second row is used and so on.

The second possible improvement is to analyze the mana parameter. It is simple to calculate the offset of this parameter and to read its value in the same checking loop where the life parameter is processed. Bot will able to choose either the healing or the mana potion to use when the player life or mana is low.

Simulate the key press action with the `PostMessage` function is one of several possible ways to embed data into the memory of the process. Another way is to write the new value of the parameter directly to the process memory.

This is the code snippet that demonstrates this approach:
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
You can see that we added the new `WriteWord` function. This is the simple wrapper over the `WriteProcessMemory` WinAPI function. Now the bot writes the life value directly to the process memory if the parameter becomes less than 100. This approach has one issue. It breaks the game rules. Therefore, it is probable that the state of the game objects becomes inconsistent after this write operation.

You can try to launch this version of the bot for Diablo 2 application. The life parameter is still unchanged after the write operation. It happens because the game stores the value of the parameter in several objects. All these values are compared regularly by some control algorithm. The algorithm can fix the wrong values according to other ones. Exact the same fixing of the values happens in the on-line games on the server side. We can conclude that this approach is able to be used just for some games with the single play mode only.

There is the third way to embed data into the process. This is the [first](http://www.codeproject.com/Articles/4610/Three-Ways-to-Inject-Your-Code-into-Another-Proces) and the [second](http://www.codeproject.com/Articles/9229/RemoteLib-DLL-Injection-for-Win-x-NT-Platforms) article about the code injection techniques. The core idea of these techniques is to execute your code inside the game process. When you gain this possibility, you can call any function of the game application. You do not need to simulate any key press actions anymore. Instead you can just call the "UsePotion" function directly. But this approach requires a deep analysis and reverse engineering of the game application.

Our example bot implements a very simple algorithm. It reacts to the low value of the life parameter and performs the key presses. But is it possible to implement in-game farm bot, which will automatically hunt monsters? Yes, we can do it. The major task of the farm bot algorithm is to search the monsters objects in the game memory. Now we know both X and Y coordinates of the player. They are specified in the table with the player parameters. Both coordinates have the size equals to two bytes. Also the Y coordinate follows the X coordinate without any gap.

Now we can assume that the coordinates of monsters, which are located near the player, have almost the same values as the player coordinates. The bot can scan the game memory to four byte number, which consist of couple values of two bytes size. We can add each appropriate result of this search to the list of "possible" monsters. Next action is to filter the wrong results. The hint for filtering algorithm is the assumption that coordinates of all  monsters should have the close addresses. 

Also the bot can remember the memory segment where the monsters coordinates are stored. This segment can be used for all further memory scan operations. The bot can use the same approach of the key press simulation with the `PostMessage` WinAPI function to hit the monsters.

## Summary

We implemented a typical in-game bot for the Diablo 2 game. Let us consider its advantages and disadvantages. This evaluation is able to be generalized for entire class of the in-game bots.

This is the list of advantages of in-game bots:

1. The bot has precise information about the game objects. There is very low probability that the bot will make mistakes.

2. The bot has a lot of ways to modify a state of the game objects. Possible options are: to simulate the player actions, to write new the values directly to the game memory, to call the internal game functions.

This is the list of disadvantages of in-game bots:

1. The analysis and reverse engineering of the game require a lot of efforts and time.

2. The bot is compatible with the specific version of the game only in the most cases. We should adapt the bot for each new version of the game.

3. There are a lot of effective approaches to protect applications against the reverse engineering and debugging techniques.

You can see that in-game bots require much more efforts to develop and to support them than clicker bots. At the same time, they are quite reliable because they can gather detailed information about a state of the game objects.
