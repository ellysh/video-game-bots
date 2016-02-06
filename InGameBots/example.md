# Example with Diablo 2

## Diablo 2 Overview

Now we will write a simple in-game bot for the popular RPG game Diablo 2. Gameplay of Diablo 2 is quite typical for RPG genre. Player should do  quests, kill the monsters and improve his character. Our example bot will be focused on analysis a state of the player character. Therefore it will be helpful to consider parameters of the player character in details.

There is a screenshot of the game's main screen:

![Diablo 2 Interface](diablo-interface.png)

You can see a player character in the center of the screen. There is an yellow model of the knight. Also you can see monsters around the player's character. One of the monster is selected by a mouse cursor.

There is a screenshot of windows with player character parameters:

![Diablo 2 Player](diablo-player.png)

There are two windows in this screenshot. Left window contains the common information about a player character like his name "Kain", class "Paladin", level and experience points. This information available at the top of the window. Also below there are attributes, that define a behavior of the character in the game process. For example the "Strength" attribute defines a damage amount that will be delivered to the monsters.

Right window contains a tree of the character's skills. There are special abilities and combos that allow you to make a more damage or to improve significantly the character's attributes. Each skill have a level. It defines, how effective usage of this skill will be. You can get more details about parameters and skills of player character in the [wiki page](http://diablo.gamepedia.com/Classes_%28Diablo_II%29)

Diablo 2 has the single player and multiplayer game modes. We will consider the single player mode only. It allows us to stop the game at any moment and to explore its memory without any time limitations. Otherwise the game client, who does not respond to the game server's requests, will be disconnected. This limitation does not allow us to use a debugger and to stop the game application for investigation its internals.

Diablo 2 is available for buying at the [Blizzard Entertainment website](https://eu.battle.net/shop/en/product/diablo-ii). There is an open source game with a [Flare](http://flarerpg.org/) name, that is available for free. It has the very close game mechanics and interface to the Diablo 2 ones. You can use the Flare game to try methods of memory investigation, that are described in this chapter. All these methods are applicable to the Flare game too. The main difference between the processes of analysis Diablo 2 and Flare games is a complexity. Diablo 2 has much more library modules and game objects in the memory than the Flare one. Thus analysis of Diablo 2 game memory requires much more efforts.

## Bot Overview

You can find detailed articles by Jan Miller about hacking the Diablo 2 game. This is a first [article](http://extreme-gamerz.org/diablo2/viewdiablo2/hackingdiablo2). This is a second [article](http://www.battleforums.com/threads/howtohackd2-edition-2.111214/). Approaches, that are described in the articles, are focused to the changing a normal behavior of the game. These changes of the application behavior is named "hacks". But a bot application should behave in the different manner. The bot should not affect a normal behavior of the game application. Instead it should analyze a state of the game objects and modify it. Meanwhile the game application is still working within its normal algorithms. Only state of the objects are changed but this state is still valid according to the game mechanics.

Our sample in-game bot will have a very simple algorithm:

1. Read current value of the player character's "Life".
2. Compare the read value with some threshold value.
3. Increase the current "Life" value to the possible maximum one.

This algorithm allows to keep a player character alive regardless of the gained damage from the monsters. Nevertheless an implementation of so simple algorithm requires a deep research of the Diablo 2 game memory.

## Diablo 2 Memory Analysis

Now we are ready to start our analysis of Diablo 2 memory. First of all you should launch the game. The game is launched by default in the fullscreen mode. But it will be more convenient for us to launch the game in windowed mode. It allows you to switch quickly between the game and scanner windows. There is an [instruction](https://eu.battle.net/support/en/article/diablo-ii-compatibility-issues-and-workarounds) to launch the game in the windowed mode:

1. Right-click the Diablo II icon and click Properties.
2. Click the Shortcut tab.
3. Add -w to the end of the Target. For example: "C:\DiabloII\Diablo II.exe" -w.

When the game is launched, you should select a "Single player" option, create a new character and start a game.

Goal of our analysis is to find a player character's life value into the game memory. First and the most obvious way to achieve our goal is usage the Cheat Engine memory scanner. You can launch the Cheat Engine and try to search the life value in the default mode of the scanner. This approach did not work for me. There are a long list of the resulting values. If you will continue searching by selecting "Next Scan" option with updated life value, the resulting list becames empty.

One of the problem of our difficulty is a size and complexity of the Diablo 2 game itself. The game model is very complex, and it consist of many objects. Now we do not know, how state and parameters of these objects are stored end encoded inside the game memory. Therefore we can start our research from developing a method that is able to allow us find a specific object in the memory. Let us look at the window with player character's attributes again. There are several parameters that are guaranteed to be unique for the player character object. We will name this kind of unique parameters an "artifacts" for the sake of brevity. What are artifacts for the player character object? This is a list of these:

1. Character name. It is extremely unlikely that other game object will have the same name as player character. Otherwise you can rename your character to guarantee its unique name.
2. Experience value. This is a very long positive integer number. It is able to appear in the other objects rarely. But you can change this value easly by killing several monsters, and then make next memory scan with a new value.
3. Stamina value. This is a long positive number. You can change it easly too by running outside the city.

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
3. Select the "Browse this memory region" item in the popup menu.

You will see the Memory Viewer window after these steps:

![Memory Viewer](memory-viewer.png)

The Memory Viewer window is splitted into two parts. Disassembled code of the specified memory region is displayed at the top part of the window. The memory dump in hexadecimal format is displayed at the bottom part of the window. We will focus on the memory dump in our investiagtion. The experience value is underlined by a red line on the screenshoot. It is not obvious, why the hexadecimal value "9E 36 FF 10" in the memory dump is equal to the actual experience value "285161118" in decimal. Our application is launched on x86 architecture. It has a [little-endian](https://en.wikipedia.org/wiki/Endianness#Little-endian) byte order. This means, that you should reverse the order of bytes in 4 byte integer to get its correct value. The hexadecimal value becames equal to "10 FF 36 9E" in our case. You can use the standard windows calculator application to make sure, that this hexadecimal value is equal to the "285161118" one in decimal. Actually you can change a display type of the memory dump by left mouse clicking on it and selecting a "Display Type" item of the popup menu. But I recommend you to keep a type in the "Byte hex" format. Because you does not know an actual size in bytes of the parameters that you are looking for.

Now you should place Memory Viewer window and Diablo 2 window near each other. It allows you to perform actions in the Diablo 2 window and to inspect a memory region simultaneously. This is a screenshot with results of this kind of memory inspection:

![Memory Inspection](memory-inspection.png)

These results matches to the last value in the resulting list of the main Cheat Engine window with "04FC04A4" address. This address may differ in your case.


TODO: Describe a method of investigation a fields meaning of the object .

TODO: Describe a method of searching a beginning of the object in the memory (breakpoint on character name).

## Bot Implementation

TODO: Describe a method of searching "magic numbers" of an object in the memory.

## Another Bot Variants

TODO: Describe a method of searching monsters' coordinates in the memory.

TODO: Write about ideas to emulate the player's actions.

## Summary