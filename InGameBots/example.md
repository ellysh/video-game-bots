# Example with Diablo 2

## Diablo 2 Overview

Now we will write a simple in-game bot for the popular RPG game Diablo 2. Gameplay of Diablo 2 is quite typical for RPG genre. Player should do  quests, kill the monsters and improve his character. Our example bot will be focused on analysis a state of the player character. Therefore it will be helpful to consider parameters of the player character in details.

There is a screenshot of the game's main screen:

![Diablo 2 Interface](diablo-interface.png)

You can see a player character in the center of the screen. There is an yellow model of the knight. Also you can see monsters around the player's character. One of the monster is selected by the mouse cursor.

There is a screenshot of windows with player character's parameters:

![Diablo 2 Player](diablo-player.png)

There are two windows in this screenshot. Left window contains the common information about the player character like his name "Kain", class "Paladin", level and experience points. This information available at the top of the window. Also below there are attributes, that define a behavior of the character in the game process. For example the "Strength" attribute defines a damage amount that will be delivered to the monsters.

Right window contains a tree of the character's skills. There are special abilities and combos that allow you to make a more damage or to improve significantly the character's attributes. Each skill have a level. It defines, how effective an usage of this skill will be. You can get more details about the parameters and skills of player character in the [wiki page](http://diablo.gamepedia.com/Classes_%28Diablo_II%29)

Diablo 2 has the single player and multiplayer game modes. We will consider the single player mode only. It allows us to stop the game at any moment and to explore its memory without any time limitations. Otherwise the game client, who does not respond to the game server's requests, will be disconnected. This limitation does not allow us to use a debugger and to stop the game application for investigation its internals.

Diablo 2 is available for buying at the [Blizzard Entertainment website](https://eu.battle.net/shop/en/product/diablo-ii). There is an open source game with a [Flare](http://flarerpg.org/) name, that is available for free. It has the very close game mechanics and interface to the Diablo 2 ones. You can use the Flare game to try methods of memory investigation, that are described in this chapter. All these methods are applicable to the Flare game too. The main difference between the processes of analysis Diablo 2 and Flare games is a complexity. Diablo 2 has much more library modules and game objects in the memory than the Flare one. Thus analysis of Diablo 2 game memory requires much more efforts.

## Bot Overview

You can find detailed articles by Jan Miller about hacking the Diablo 2 game. This is a first [article](http://extreme-gamerz.org/diablo2/viewdiablo2/hackingdiablo2). This is a second [article](http://www.battleforums.com/threads/howtohackd2-edition-2.111214/). Approaches, that are described in the articles, are focused to the changing a normal behavior of the game. These changes of the application behavior is named "hacks". But a bot application should behave in a different manner. The bot should not affect a normal behavior of the game application. Instead it should analyze a state of the game objects and simulate the player's actions. Meanwhile the game application is still working within its normal algorithms. State of all objects is still valid according to the game mechanics.

Our sample in-game bot will have a very simple algorithm:

1. Read current value of the player character's life parameter.
2. Compare the read value with some threshold value.
3. Change a value of the character's life parameter.

This algorithm allows to keep a player character alive while there are still the health potions. Nevertheless an implementation of so simple algorithm requires a deep research of the Diablo 2 game memory.

## Diablo 2 Memory Analysis

Now we are ready to start our analysis of Diablo 2 memory. First of all you should launch the game. The game is launched by default in the fullscreen mode. But it will be more convenient for us to launch the game in windowed mode. It allows you to switch quickly between the game and scanner windows. There is an [instruction](https://eu.battle.net/support/en/article/diablo-ii-compatibility-issues-and-workarounds) to launch the game in the windowed mode:

1. Right-click the Diablo II icon and click Properties.
2. Click the Shortcut tab.
3. Add -w to the end of the Target. For example: "C:\DiabloII\Diablo II.exe" -w.

When the game is launched, you should select a "Single player" option, create a new character and start a game.

### Parameter Searching

Goal of our analysis is to find a player character's life value into the game memory. First and the most obvious way to achieve our goal is usage the Cheat Engine memory scanner. You can launch the Cheat Engine and try to search the life value in the default mode of the scanner. This approach did not work for me. There are a long list of the resulting values. If you will continue searching by selecting "Next Scan" option with updated life value, the resulting list becomes empty.

One of the problem of our difficulty is a size and complexity of the Diablo 2 game itself. The game model is very complex, and it consist of many objects. Now we do not know, how state and parameters of these objects are stored end encoded inside the game memory. Therefore we can start our research from developing a method that is able to allow us find a specific object in the memory. Let us look at the window with player character's attributes again. There are several parameters that are guaranteed to be unique for the player character object. We will name this kind of unique parameters an **artifacts** for the sake of brevity. What are artifacts for the player character object? This is a list of these:

1. Character name. It is extremely unlikely that other game object will have the same name as player character. Otherwise you can rename your character to guarantee its unique name.
2. Experience value. This is a very long positive integer number. It is able to appear in the other objects rarely. But you can change this value easily by killing several monsters, and then make next memory scan with a new value.
3. Stamina value. This is a long positive number. You can change it easily too by running outside the city.

I suggest to select an experience value for searching. If this value equals to zero in your case, you can kill several monsters. The value will grow rapidly. There are the search results for my case:

![Experience Value](experience-value.png)

There are several values in the memory that equal to the character's experience value.

Next step is to distinguish the value that is contained inside the character object. First of all, we can clarify a type of owning segment for each of these variables. This is a shortened output of the WinDbg debugger:
```
+        0`003c0000        0`003e0000        0`00020000 MEM_PRIVATE MEM_COMMIT  PAGE_READWRITE                     <unknown>  
+        0`03840000        0`03850000        0`00010000 MEM_PRIVATE MEM_COMMIT  PAGE_READWRITE                     <unknown>  
+        0`03850000        0`03860000        0`00010000 MEM_PRIVATE MEM_COMMIT  PAGE_READWRITE                     <unknown>  
+        0`04f50000        0`04fd0000        0`00080000 MEM_PRIVATE MEM_COMMIT  PAGE_READWRITE                     <unknown>  
```
You can see, that all found variables are stored into the segments of "unknown" type. What is the "unknown" type? We already know the segments of stack and heap type. WinDbg debugger is able to distinguish them well. Therefore these unknown segments are neither stack nor heap type. It is able to be a segments that are allocated by the [`VirtualAllocEx`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366890%28v=vs.85%29.aspx) WinAPI function. We can clarify this question very simple by writing a sample application, that uses a `VirtualAllocEx` function. If you will launch this sample application with WinDbg debugger, you will see a segment of "unknown" type in the application's memory map. The base address of the segment will have the same value as returned one by the `VirtualAllocEx` function. But all experience values are kept at the segments of the same type, and we cannot distinguish them by this feature.

We can try another way to find a character object. It is obvious, that parameters of the object will be changed, when a player performs the actions. For example, the object's coordinates will be changed when a character moves. Also the live value will be decreased when the character gains a damage from monsters. Consider this fact, we can analyze the nature of changes in the memory that is located near the experience values. Cheat Engine memory scanner provides a feature of displaying changes in a memory region in real-time. There is an algorithm to open a Memory Viewer window of the Cheat Engine application:

1. Select a value in the resulting list for inspection.
2. Left click on the value.
3. Select the "Browse this memory region" item in the pop-up menu.

You will see the Memory Viewer window after these steps:

![Memory Viewer](memory-viewer.png)

The Memory Viewer window is split into two parts. Disassembled code of the specified memory region is displayed at the upper part of the window. The memory dump in hexadecimal format is displayed at the bottom part of the window. We will focus on the memory dump in our investigation. The experience value is underlined by a red line on the screenshoot. It is not obvious, why the hexadecimal value "9E 36 FF 10" in the memory dump is equal to the actual experience value "285161118" in decimal. Our application is launched on x86 architecture. It has a [little-endian](https://en.wikipedia.org/wiki/Endianness#Little-endian) byte order. This means, that you should reverse the order of bytes in 4 byte integer to get its correct value. The hexadecimal value becomes equal to "10 FF 36 9E" in our case. You can use the standard windows calculator application to make sure, that this hexadecimal value is equal to the "285161118" one in decimal. Actually you can change a display type of the memory dump by left mouse clicking on it and selecting a "Display Type" item of the pop-up menu. But I recommend you to keep a type in the "Byte hex" format. Because you does not know an actual size in bytes of the parameters that you are looking for.

Now you should place Memory Viewer window and Diablo 2 window near each other. It allows you to perform actions in the Diablo 2 window and to inspect a memory region simultaneously. This is a screenshot with results of this kind of memory inspection:

![Memory Inspection](memory-inspection.png)

The object on the screenshot matches to the last value in the resulting list with "04FC04A4" address. The value's address may differ in your case but the order of the resulting values should be the same. You can find the same object by opening the last value in the list. Why we select exact this object instead of other one? The reason is, this object contains more information about the player character. This is a list of parameters that have been detected thanks to analysis of them nature of changes:

| Parameter | Address | Size | Hex Value | Dec Value |
| -- | -- | -- | -- | -- |
| Life | 04FC0490 | 2 | 40 01 | 320 |
| Mana | 04FC0492 | 2 | 9D 01 | 413 |
| Stamina | 04FC0494 | 2 | FE 1F | 8190 |
| Coordinate X | 04FC0498 | 2 | 37 14 | 5175 |
| Coordinate Y | 04FC04A0 | 2 | 47 12 | 4679 |
| Experience | 04FC04A4 | 4 | 9E 36 FF 10 | 285161118 |

All these parameters are underlined by the red color on the memory inspection screenshot. What new we have known about the character's parameters from this inspection? First of all, the size of the life value is equal to 2 bytes. It means, that you should specify the "2 Byte" item of the "Value Type" option on the main window of Cheat Engine, if you want to search the life value. Also you can see, that some of the character's parameters have an [alignment](https://en.wikipedia.org/wiki/Data_structure_alignment), which is not equal to 4 byte. For example a mana value with 04FC0492 address. You can check with calculator that the 04FC0492 value is not divided to 4 without an remainder. It means, that you should unselect the "Fast Scan" check-box on the main window of Cheat Engine for searching this parameters. This is a screenshot of the correctly configured Cheat Engine's window for a future searching:

![Cheat Engine Configured](cheatengine-configured.png)

Two changed options of searching are underlined by the red color on the screenshot. Now you can search a life value with Cheat Engine scanner, and the valid results will be found.

### Object Searching

Next question is, how our bot will be able to find the correct life parameter in the game memory? Let us scroll up the memory dump of the character's object with the experience value at the "04FC04A4" address. You will see the character's name like it was happened in my case:

![Character's Object Head](memory-object-head.png)

It is equals to "Kain" string. [String](https://en.wikipedia.org/wiki/String_%28computer_science%29#Null-terminated) values have not a reversed byte order on the little-endian platform unlike the integers. The reason is strings have the same internal structure as simple byte arrays.

You can see that memory block above the character's name value is zeroed. Now we start to make assumptions and to check these. Let us assume that the character's name is stored close to the upper bound of the character's object. How we can check this assumption? We can use OllyDbg debugger to make a breakpoint on the memory address, where the character's name is stored. When the game application will try to read or to write this memory, the application will be stopped by the breakpoint. Then we can investigate an application code on the breakpoint. It is probably that we will find an indication of the object's bound.

This is an algorithm of this investigation:

1. Launch OllyDbg debugger with administrator privileges and attach it to the Diablo 2 application.

2. Select by a left mouse click the bottom-left sub-window with the memory dump in a hex format.

3. Press the *Ctrl+G* key to open "Enter expression to follow" dialog.

4. Type the address of the character's name string to the "Enter address expression" field. The address is equal to 04FC00D in our case. Then press the "Follow expression" button. Now the cursor of the memory dump sub-window points to the first byte of the character's name.

5. Scroll up in the memory dump sub-window to find first non-zero byte at the assumed object's border. Select this byte by a left mouse click on it.

5. Press the *Shift+F3* key to open the "Set memory breakpoint" dialog. Select "Read access" and "Write access" check-boxes in the dialog. Then press "OK" button. Now the memory breakpoint is set.

6. Continue an execution of the Diablo 2 application by *F9* key. The application can be stopped on several events. One of them is our memory breakpoint. Other event, which happens often, is a break on the guarded memory page access. You can check, what kind of event is happened in the status bar at the bottom of the OllyDbg window. Now you should continue application's execution until the application do not get the "Running" status.

7. Switch to the Diablo 2 window. It should be stopped immediately after this switching.

8. Switch back to the OllyDbg window. It should look like this:

![Diablo 2 Ollydbg](diablo-ollydbg.png)

What do we see in this screenshot? You can see the highlighted line of a disassembled code at the upper-left sub-window, where the read access to our object has happened. This is that line at the "03668D9F" address:
```
CMP DWORD PTR DS:[ESI+4], 4
```
Here the comparison between integer of DWORD type at the "ESI + 4" address and value 4 is happened. **ESI** is a source index [CPU register](http://www.eecg.toronto.edu/~amza/www.mindsec.com/files/x86regs.html). ESI is always used in pair with the **DS** register. DS register holds a base address of the data segment. ESI register equals to "04FC0000" address in our case. You can find this value in the upper-right sub-window, which contains current values of all CPU registers. It is common practice to hold an object address in the ESI register. Let us inspect the disassembled code below the breakpoint line. You can see these lines that are started at the "03668DE0" address:
```
MOV EDI,DWORD PTR DS:[ESI+1B8]
CMP DWORD PTR DS:[ESI+1BC],EDI
JNE SHORT 03668DFA
MOV DWORD PTR DS:[ESI+1BC],EBX
```
All these operation looks like a processing fields of the object, where "1B8" and "1BC" values define the offsets of fields from the object's starting address. If you scroll down this disassembling listing, you will find more operations with object's fields. It allows us to conclude that start address of the player character's object equals to ESI register, i.e., 04FC0000.

We can calculate an offset of the life value from the start address of the character's object:
```
04FC0490 - 04FC0000 = 0x490
```
It is equal to 490 in hexadecimal. Next question, how our bot will find a start address of the character's object? We have determined, that the owning segment of the object has special "unknown" type. Also the segment has 80000 byte size in hex and these flags: `MEM_PRIVATE`, `MEM_COMMIT` and `PAGE_READWRITE`. There are a minimum ten other segments that have the same byte size and flags. It means, that we cannot find the necessary segment by traversing them.

Let us see to the first bytes of the character's object:
```
00 00 00 00 04 00 00 00 03 00 28 0F 00 4B 61 69 6E 00 00 00
```
If you will restart the Diablo 2 application and find this character's object again, you will see the same first bytes. We can make assumption, that these bytes match to the unchanged character's parameters. This kind of parameters is defined at the character creation moment. Once they are created, they are never changed. This is a probable list of the parameters:

1. Character's name.
2. [Expansion character](http://diablo.wikia.com/wiki/Expansion_Character) flag.
3. [Hardcore mode](http://diablo.wikia.com/wiki/Hardcore) flag.
4. Code of the character's class.

This set of unchanged bytes can be used as [**magic numbers**](https://en.wikipedia.org/wiki/Magic_number_%28programming%29) for searching the character's object in the memory. Be aware that these magic numbers will be different for your case. Lack of flexibility is the main disadvantage of the approach. You can test a correctness of the selected magic numbers with Cheat Engine scanner. Select the "Array of byte" item of the "Value Type" option. Then select a "Hex" check-box and copy the first bytes of the character's object into the "Array of byte" field. This is the search result for my case:

![Magic Numbers Search](magic-numbers-search.png)

## Bot Implementation

>> CONTINUE

TODO: Write the resulting bot's algorithm:
	1. Search a life value via magic numbers of the character's object and value's offset.
	2. Read the life value parameter in cycle.
	3. Write new value of the life parameter if it becomes below the trigger value.

TODO: Describe a method of searching magic numbers of an object in the memory by bot. Give a link to video lesson with the code example.

## Another Bot Variants

TODO: Describe a method of searching monsters' coordinates in the memory.

TODO: Write about ideas to emulate the player's actions.

## Summary

TODO: Briefly describe the considered methods and approaches.