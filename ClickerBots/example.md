# Example with Lineage 2

## Lineage 2 Overview

Now we will write a simple clicker bot for a popular MMORPG game Lineage 2. It help us apply in practice  knowledge and approaches that have been already acquired. Gameplay of Lineage 2 is very typical for RPG genre. Player should select one of the available characters before starting a play. Then you should complete quests and hunt monsters to achieve new skills, extract resources and buy new items. Player able to communicate and cooperate with other players during all game process. Other players able to assist you in your activity or hamper you in achieving your goals. This feature encourage you to develop your character faster that helps you to resist the interference of other players. You will able to participate in "team vs team" battles when achieve a high level of your character. These massive events are the main attraction of the game.

The most straightforward way to improve your character is hunting monsters. You will get experience points to improve your skills, gold to buy new items and random resources after killing a monster. We will focus on automation this process as one that allow to develop a player character in the comprehensive manner. Also there are another ways to develop a character like trading, fishing, crafting new items and completing quests.

This is a screenshoot of the Lineage 2 game:

![Lineage 2 Interface](lineage-interface.png)

This is a list of important interface elements on the screenshoot:
1. **Status Window** with current parameters of the player's character. The most important parameters are health points (HP) and mana points (MP).
2. **Target Window** with an information of the selected monster. It allows you to see a HP level of the monster that you are attacking now.
3. **Shortcut Panel** with icons of the available actions and skills.
4. **Chat Window** for input game commands and chating with other players.

Understanding the game's interface allow us to make a clicker bot that will interact with the game in more efficient manner. Detailed information regarding the game's interface available  in [wiki](https://l2wiki.com/Game_Interface).

There are a lot of Lineage 2 servers. They differs by game version, extra gameplay features and protection systems that are used to prevent a usage of bots. The most reliable and effective protection system is used on [official servers](http://www.lineage2.eu). But there are freeshard private servers that suggest you an alternative for official one. We will use a [Rpg-Club](http://www.rpg-club.com) server in our example because the protection system on this server allows to use clicker bots.

## Bot Implementation

This is a simplified algorithm of hunting monsters:
1. Select a monster by left button clicking on him. Alternative way to select a monster is typing a command in the chat window or use a macro with this command:
```
/target MonsterName
```
Full list of the game commands and manual for usage macros are available [here](http://www.lineage2.com/en/game/getting-started/how-to-play/macros-and-commands.php).
2. Click to the "attack" action in the Shortcut Panel. Alternative way to select an attack action is pressing a *F1* (by default) keyboard key.
3. Wait of killing a monster by player character.
4. Click a "pickup" action in the Shortcut Panel to pickup the items that have been dropped out from the killed monster. You can also use keyboard hotkey for it.

You can see that the algorithm is quite simple and easy to automate at first look.

### Blind Bot

First we will implement the simplest variant of a bot. The bot will perform one by one steps of the hunting algorithm. It will not analyze a result of performed actions. The bot will use keystroke emulation approach for performing game actions.

It will be helpful to consider a configuration of our Shortcut Panel before we start to write a code. This is a screenshot of the panel:

![Shortcut Panel](lineage-hotbar.png)

This is a list of actions and corresponding hotkeys on the panel:

* *F1* - this is a command to attack the current selected monster.
* *F2* - this is a command to use attack skill on the selected monster.
* *F5* - this is a command to use health potion for restoring player's HP
* *F8* - this is a command to pickup items near the player.
* *F9* - this is a macro with `/target MonsterName` command to select a monster.
* *F10* - this is a command to select a nearest monster.

Now it becomes simple to associate keys with algorithm actions and writes a code. This is a script with `BlindBot.au3` name that implements all steps of the algorithm:
```AutoIt
#RequireAdmin

Sleep(2000)

while true
	Send("{F9}")
	Sleep(200)
	Send("{F1}")
	Sleep(5000)
	Send("{F8}")
	Sleep(1000)
wend
```
First line of the script is a  [`#RequireAdmin`](https://www.autoitscript.com/autoit3/docs/keywords/RequireAdmin.htm) keyword. The keyword allows interaction between the script and an application that have been launched with administrator privileges. Lineage 2 client can request the administrator privileges for launching. Next action in the script is a waiting two seconds that are needed to you for manually switching to the Lineage 2 application. All bot's actions is performed in the infinite `while` loop. This is a list of the actions:

1. `Send("{F9}")` - select a monster by a macro that is available via *F9* hotkey.
2. `Sleep(200)` - sleep a 200 milliseconds. This delay is needed for the game application to select a monster and draw a Target Window. You should remember that all actions of the game take a nonzero time. Often this time is much less than the human reaction time and therefore it looks instantly.
3. `Send("{F1}")` - attack the selected monster.
4. `Sleep(5000)` - sleep 5 seconds while the character reaches a monster and kill it.
5. `Send("{F8}")` - pickup one item.
6. `Sleep(1000)` - sleep 1 second while character picking up the item.

You can see that we have made few assumptions in the script. First assumption is successful result of the monster selecting. All further actions will not have an effect if this is not a monster with the specified name near the player's character. Second assumption is delay for 5 seconds after an attack action. The distance between the selected monster and character can vary. It means that it is needed 1 second to achieve the monster in one time. But it is needed 6 seconds to achieve the monster in the other time. Third assumption is picking up only one item. But it is possible that more than one item will be dropped from the monster.

Now you can launch the script and test it. Obviously, the moment comes when one of our three assumptions will be violated. The important thing for blind types of clicker bots is a possibility to continue work correctly  after a violation of the assumptions. This possibility is available for our test bot. The reasons why it happens are features of the macro with `/target` command and the attack action. If the macro will be pressed twice the same monster will be selected. It allows the bot to attack the same monster until it still alive. If the moster have not been killed on a current iteration of the loop this process will be continued on the next iteration. Also an attack action will not be interrupted after sending a pickup action by *F8* key if there are not available items for picking up near the character. It means that the character will not stop to attack the current monster even a 5 second timeout have been exceeded. This is still third assumption regarding to count of items for picking up. The issue can be solved by hardcoding an exact count of the items that usually dropped from this type of monsters.

We can improve the script by moving each step of the algorithm to a separate function with a descriptive name. It will make the code more readable. This is a `BlindBotFunc.au3` script with the separate functions:
```AutoIt
#RequireAdmin

Sleep(2000)

func SelectTarget()
	Send("{F9}")
	Sleep(200)
endfunc

func Attack()
	Send("{F1}")
	Sleep(5000)
endfunc

func Pickup()
	Send("{F8}")
	Sleep(1000)
endfunc

while true
	SelectTarget()
	Attack()
	Pickup()
wend
```

### Adding Analysis

The blind bot can be improved by adding a feature of checking the results of own actions. We will substitute our assumptions to the reliable checks that are based on a pixels analyzing. But before we start to implement the checks it will be very helpful to add a mechanism of printing log messages. The mechanism will help us to trace results of all checks and discover possible bugs.

This is a code snippet with a `LogWrite` function that prints a log message into the file:
```AutoIt
global const $kLogFile = "debug.log"

func LogWrite($data)
	FileWrite($kLogFile, $data & chr(10))
endfunc

LogWrite("Hello world!")
```
Result of the code execution is creation of the file with a `debug.log` name which contains a string "Hello world!". `LogWrite` function is a wrapper for AutoIt [`FileWrite`](https://www.autoitscript.com/autoit3/docs/functions/FileWrite.htm) function. You can change name and path of the output file by changing value of the `kLogFile` constant.

First assumption of the blind bot is a success of the monster select by a macro. One of the possible check for the selecting action success is looking for a Target Window with FastFind library. `FFBestSpot` is a suitable function for this task. Now we should pick a color in the Target Window that will signal about the window presence. We can pick a color of the target's HP bar for example. This is a code snippet with `IsTargetExist` function that checks a presence of the Target Window:
```AutoIt
func IsTargetExist()
	const $SizeSearch = 80
	const $MinNbPixel = 3
	const $OptNbPixel = 10
	const $PosX = 688
	const $PosY = 67
	
	$coords = FFBestSpot($SizeSearch, $MinNbPixel, $OptNbPixel, $PosX, $PosY, 0x871D18, 10)

	const $MaxX = 800
	const $MinX = 575
	const $MaxY = 100
	
	if not @error then
		if $MinX < $coords[0] and $coords[0] < $MaxX and $coords[1] < $MaxY then
			LogWrite("IsTargetExist() - Success, coords = " & $coords[0] & ", " & $coords[1] & " pixels = " & $coords[2])
			return True
		else
			LogWrite("IsTargetExist() - Fail #1")
			return False
		endif
	else
		LogWrite("IsTargetExist() - Fail #2")
		return False
	endif
endfunc
```
`PosX` and `PosY` coordinates are the proximity position of the HP bar in a Target Window. The `0x871D18` parameter matches to a red color of full HP bar for searching. `FFBestSpot` function performs searching over all game screen. Therefore, HP bar in the player's Status Window is detected if the HP bar in the Target Window have not been found. This leads to extra checking of the resulting coordinates that are returned by `FFBestSpot` function. Comparing a resulting X coordinate (`coords[0]`) with maximum (`MaxX`) and minimum (`MinX`) allowed values solves the task of distinguish HP bars on Status Window and Target Window. The same comparison of Y coordinate (`coords[0]`) with maximum (`MaxY`) value allow to avoid false positives. Values of all coordinates are depended on a screen resolution and a position of the game window. You should adopt it to your configuration. Also `LogWrite` is called here to trace each conclusion of the `IsTargetExist` function. It can help to check correctness of the specified coordinates.

We can use new `IsTargetExist` function both in `SelectTarget` and `Attack` functions. It checks a success of the monster select in the `SelectTarget` that helps to avoid first assumption of the blind bot. Also it is possible to check if a monster have been killed with the same `IsTargetExist` function to avoid the second assumption. If the function return `False` it means that pixels with the color equal to full HP bar absent in the Target Window. In other words, the HP bar of a target is empty and monster is died.

This is a resulting script with `AnalysisBot.au3` name:
```AutoIt
#include "FastFind.au3"

#RequireAdmin

Sleep(2000)

global const $kLogFile = "debug.log"
	
func LogWrite($data)
	FileWrite($kLogFile, $data & chr(10))
endfunc

func IsTargetExist()
	; SEE ABOVE
endfunc

func SelectTarget()
	LogWrite("SelectTarget()")
	while not IsTargetExist()
		Send("{F9}")
		Sleep(200)
	wend
endfunc

func Attack()
	LogWrite("Attack()")
	while IsTargetExist()
		Send("{F1}")
		Sleep(1000)
	wend
endfunc

func Pickup()
	Send("{F8}")
	Sleep(1000)
endfunc

while true
	SelectTarget()
	Attack()
	Pickup()
wend
```
Pay attention to the new implementation of `SelectTarget` and `Attack` functions. Command for selecting a monster will be sending in the `SelectTarget` function until success result. Similarly, the attack action will be sending until monster alive in the `Attack` function. Also there are log messages printing in the both functions. It allows to distinguish a source of each `IsTargetExist` function call in the log file. All these improvements lead to more precise work of the bot and help to select a correct action according to the current game situation.

### Further Improvements

TODO: Remove the unused actions and skill from the Shortcut Bar

TODO: Write about HP potion usage and F10 monster switching as alternative searching mechanism

## Conclusion