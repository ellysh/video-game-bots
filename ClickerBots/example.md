# Example with Lineage 2

## Lineage 2 Overview

Now we will write a simple clicker bot for a popular MMORPG game Lineage 2. It help us apply in practice  knowledge and approaches that have been already acquired. Gameplay of Lineage 2 is very typical for RPG genre. Player should select one of the available characters before starting a play. Then you should complete quests and hunt monsters to achieve new skills, extract resources and buy new items. Player able to communicate and cooperate with other players during all game process. Other players able to assist you in your activity or hamper you in achieving your goals. This feature encourage you to develop your character faster that helps you to resist the interference of other players. You will able to participate in "team vs team" battles when achieve a high level of your character. These massive events are the main attraction of the game.

The most straightforward way to improve your character is hunting monsters. You will get experience points to improve your skills, gold to buy new items and random resources after killing a monster. We will focus on automation this process as one that allow to develop a player character in the comprehensive manner. Also there are another ways to develop a character like trading, fishing, crafting new items and completing quests.

This is a screenshoot of the Lineage 2 game:

![Lineage 2 Interface](lineage-interface.png)

This is a list of important interface elements on the screenshoot:
1. Status Window with current parameters of the player's character. The most important parameters are health points (HP) and mana points (MP).
2. Target Window with an information of the selected monster. It allows you to see a HP level of the monster that you are attacking now.
3. Shortcut Panel with icons of the available actions and skills.
4. Chat Window for input game commands and chating with other players.

Understanding the game's interface allow us to make a clicker bot that will interact with the game in more efficient manner. Detailed information regarding the game's interface available [here](https://l2wiki.com/Game_Interface).

There are a lot of Lineage 2 servers. They differs by game version, extra gameplay features and protection systems that are used to prevent a usage of bots. The most reliable and effective protection system is used on [official servers](http://www.lineage2.eu). But there are freeshard private servers that suggest you an alternative for official one. We will use a [Rpg-Club server](http://www.rpg-club.com) in our example because the protection system on this server allows to use clicker bots.

## Bot Implementation

This is a simplified algorithm of hunting monsters:
1. Select a monster by left button clicking on him. Alternative way to select a monster is typing a command in the chat window or use a macro with this command:
```
/target MonsterName
```
Full list of the game commands and manual for usage macros are available [here](http://www.lineage2.com/en/game/getting-started/how-to-play/macros-and-commands.php).
2. Click to the "attack" action in the Shortcut Panel. Alternative way to select an "attack" action is pressing a **F1** (by default) keyboard key.
3. Wait of killing a monster by player character.
4. Click a "pickup" action in the Shortcut Panel to pickup the items that have been dropped out from the killed monster. You can also use keyboard hotkey for it.

You can see that the algorithm is quite simple and easy to automate at first look.

### Blind Bot

First we will implement the simplest variant of a bot. The bot will perform one by one steps of the hunting algorithm. It will not analyze a result of performed actions. The bot will use keystroke emulation approach for performing game actions.

It will be helpful to consider a configuration of our Shortcut Panel before we start to write a code. This is a screenshot of the panel:

![Shortcut Panel](lineage-hotbar.png)

This is a list of actions and corresponding hotkeys on the panel:

* F1 - this is a command to attack the current selected monster.
* F2 - this is a command to use attack skill on the selected monster.
* F5 - this is a command to use health potion for restoring player's HP
* F8 - this is a command to pickup items near the player.
* F9 - this is a macro with "/target MonsterName" command to select a monster.
* F10 - this is a command to select a nearest monster.

Now it becomes simple to associate keys with algorithm actions and writes a code. This is a script with **BlindBot.au3** name that implements all steps of the algorithm:
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
First line of the script is a  [**#RequireAdmin**](https://www.autoitscript.com/autoit3/docs/keywords/RequireAdmin.htm) keyword. The keyword allows interaction between the script and an application that have been launched with administrator privileges. Lineage 2 client can request the administrator privileges for launching. Next action in the script is a waiting two seconds that are needed to you for manually switching to the Lineage 2 application. All bot's actions is performed in the infinite **while** loop. This is a list of the actions:

1. **Send("{F9}")** - select a monster by a macro that is available via **F9** hotkey.
2. **Sleep(200)** - sleep a 200 milliseconds. This delay is needed for the game application to select a monster and draw a Target Window. You should remember that all actions of the game take a nonzero time. Often this time is much less than the human reaction time and therefore it looks instantly.
3. **Send("{F1}")** - attack the selected monster.
4. **Sleep(5000)** - sleep 5 seconds while the character reaches a monster and kill it.
5. **Send("{F8}")** - pickup one item.
6. **Sleep(1000)** - sleep 1 second while character picking up the item.

You can see that we have made few assumptions in the script. First assumption is successful result of the monster selecting. All further actions will not have an effect if this is not a monster with the specified name near the player's character. Second assumption is delay for 5 seconds after an attack action. The distance between the selected monster and character can vary. It means that it is needed 1 second to achieve the monster in one time. But it is needed 6 seconds to achieve the monster in the other time. Third assumption is picking up only one item. But it is possible that more than one item will be dropped from the monster.

Now you can launch the script and test it. Obviously, the moment comes when one of our three assumptions will be violated. The important thing for blind types of clicker bots is a possibility to continue work correctly  after a violation of the assumptions. This possibility is available for our test bot. The reasons why it happens are features of the macro with "/target" command and the attack action. If the macro will be pressed twice the same monster will be selected. It allows the bot to attack the same monster until it still alive. If the moster have not been killed on a current iteration of the loop this process will be continued on the next iteration. Also an attack action will not be interrupted after sending a pickup action by **F8** key if there are not available items for picking up near the character. It means that the character will not stop to attack the current monster even a 5 second timeout have been exceeded. This is still third assumption regarding to count of items for picking up. The issue can be solved by hardcoding an exact count of the items that usually dropped from this type of monsters.

### Adding Analysis

The blind bot can be improved by adding feature of checking the results of its actions. We will substitute our assumptions to the reliable checks with a pixels analyzing. First assumption is success of the monster selecting by macro. 

TODO: Substitute each assumption by checking

TODO: Add a log file output for debugging

TODO: Name script "AnalysisBot.au3"

TODO: Remove the unused actions and skill from the Shortcut Bar

### Further Improvements

TODO: Write about HP potion usage and F10 monster switching as alternative searching mechanism

## Conclusion