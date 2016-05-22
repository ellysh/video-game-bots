# Example with Lineage 2

## Lineage 2 Overview

Now we will write a simple clicker bot for the popular MMORPG game Lineage 2. This helps us to apply in a practice the knowledge and approaches that have been already acquired. Gameplay of Lineage 2 is a very typical for RPG genre. Player should select one of the available characters before starting to play. Then you should do quests and hunt monsters to achieve new skills, extract resources and buy new items. Player is able to communicate and to cooperate with other players during all game process. Other players able to assist you in your activity or hamper you in achieving your goals. This feature encourage you to develop your character faster that helps you to resist the interference of other players. You will be able to participate in "team vs team" battles when you achieve high level of your character. These massive events are a main attraction of the game.

The most straightforward way to improve your character is hunting monsters. You will get experience points to improve your skills, gold to buy new items and random resources after killing a monster. We will focus on automation this process because it allows you to develop a player's character in comprehensive manner. Also there are other ways to develop a character like trading, fishing, crafting new items and completing quests.

This is a screenshoot of the Lineage 2 game:

![Lineage 2 Interface](lineage-interface.png)

This is a list of important interface elements on this screenshoot:
1. **Status Window** with current parameters of the player's character. The most important parameters are health points (HP) and mana points (MP).
2. **Target Window** with information of selected monster. Here you can see HP of the monster that you are attacking now.
3. **Shortcut Panel** with icons of available actions and skills that are attached to hotkeys.
4. **Chat Window** for input game commands and chatting with other players.

Understanding game interface allow us to make a clicker bot that will interact with the game in a more efficient manner. Detailed information about game interface available in the [wiki page](https://l2wiki.com/Game_Interface).

There are a lot of Lineage 2 servers. They differs by game version, extra gameplay features and protection systems, which are used to prevent usage of bots. The most reliable and effective protection system is used on [official servers](http://www.lineage2.eu). But there are many private servers that suggest you an alternative for official one. We will use the [Rpg-Club](http://www.rpg-club.com) server in our example because the protection system on this server does not block clicker bots.

## Bot Implementation

This is a simplified algorithm of hunting monsters:
1. Select a monster by left button clicking on him. Alternative way to select a monster is typing a command in the chat window or use the macro with this command:
```
/target MonsterName
```
Full list of the game commands and manual for usage macros are available [here](http://www.lineage2.com/en/game/getting-started/how-to-play/macros-and-commands.php).
2. Click to the "attack" action in the Shortcut Panel. Alternative way to select an attack action is to press the *F1* (by default) keyboard key.
3. Wait until a player character kill the monster.
4. Click a "pickup" action in the Shortcut Panel to pickup the items that have been dropped out from the killed monster. You can also use a keyboard hotkey for this.

You can see that the algorithm is quite simple and easy to automate at first look.

### Blind Bot

First we will implement the simplest variant of a bot. The bot will perform one by one steps of the hunting algorithm. It will not analyze a result of the performed actions. The bot will use keystroke simulation approach for performing game actions.

It will be helpful to consider a configuration of our Shortcut Panel before we start to write a code. This is a screenshot of the panel:

![Shortcut Panel](lineage-hotbar.png)

This is a list of actions and corresponding hotkeys on this panel:

| Hotkey | Command |
| -- | -- |
| *F1* | Attack the current selected monster |
| *F2* | Use an offensive skill on the selected monster |
| *F5* | Use a health potion for restoring player's HP |
| *F8* | Pickup items near the player | 
| *F9* | Macro with `/target MonsterName` command to select a monster |
| *F10* | Select a nearest monster |

Now it becomes simple to associate hotkeys with algorithm steps and write a code. This is a script with [`BlindBot.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/Lineage2Example/BlindBot.au3) name that implements all steps of our algorithm:
```AutoIt
#RequireAdmin

Sleep(2000)

while True
    Send("{F9}")
    Sleep(200)
    Send("{F1}")
    Sleep(5000)
    Send("{F8}")
    Sleep(1000)
wend
```
First line of the script is a  [`#RequireAdmin`](https://www.autoitscript.com/autoit3/docs/keywords/RequireAdmin.htm) keyword. This keyword permits interaction between the script and an application that has been launched with administrator privileges. Lineage 2 client can request the administrator privileges for launching. Next action in the script is two seconds delay, which is needed for you to switch to the Lineage 2 window. Now the bot is able to work in the active game window only. All bot actions are performed in the infinite `while` loop. This is a sequence of these actions:

1. `Send("{F9}")` - select a monster by the macro that is available via *F9* key.
2. `Sleep(200)` - sleep 200 milliseconds. This delay is needed for the game application to select a monster and to draw a Target Window. You should remember that all actions in the game window take nonzero time. Often this time is much less than time of human reaction and therefore it looks instantly.
3. `Send("{F1}")` - attack the selected monster.
4. `Sleep(5000)` - sleep 5 seconds while the character reaches a monster and kills it.
5. `Send("{F8}")` - pickup one item.
6. `Sleep(1000)` - sleep 1 second while the character is picking up the item.

You can see that we have made few assumptions in this script. First assumption is successful result of the monster selecting. All further actions do not have any effect if there is no monster with the specified name near the player's character. Second assumption is the delay for 5 seconds after an attack action. A distance between the selected monster and the character is able to vary. This means that 1 second is enough to achieve the monster in one case. But it is needed 6 seconds for this movement in another case. Third assumption is a count of picking up items. Now only one item is picked up. But more than one item is able to be dropped from the monster.

You can launch the bot script and test it. Obviously, the moment comes when one of our three assumptions is violated. The important requirement for blind type of clicker bots is a possibility to continue work correctly after violation of its assumptions. Our test bot provides this possibility. This happens because of features the `/target` command and the attack action mechanism. If the macro with the `/target` command is pressed twice, the same monster is selected. Thus, the bot will continue to attack the same monster until it is still alive. If the monster is not killed on a current iteration of the loop, this process is continued on the next iteration. Also an attack action is not interrupted after sending a pickup command by *F8* key if there are not any dropped items near the character. This means that the character does not stop to attack the current monster after exceeding the 5 second timeout for this action. There is third assumption regarding count of items for picking up. This issue can be solved by hardcoding an exact count of the items that usually dropped by this type of monsters.

We can improve the script by moving each step of the algorithm to a separate function with a descriptive name. This makes the code more comprehensible. This is a [`BlindBotFunc.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/Lineage2Example/BlindBotFunc.au3) script, which is separated to functions:
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

while True
    SelectTarget()
    Attack()
    Pickup()
wend
```

### Adding Analysis

We can improve our blind bot. Now the bot makes several assumptions, which can be wrong. If the bot is able to check results of own actions, it allows him less likely to make mistakes. We will use pixels analyzing approach for these checks. But before we start to implement this feature, it will be helpful to add a mechanism of printing log messages. This mechanism will help us to trace bot's decisions and detect possible bugs.

This is a code snippet with a `LogWrite` function that prints a log message into the file:
```AutoIt
global const $LogFile = "debug.log"

func LogWrite($data)
    FileWrite($LogFile, $data & chr(10))
endfunc

LogWrite("Hello world!")
```
After execution of this code you will get a file with the `debug.log` name which contains the "Hello world!" string. The `LogWrite` function is a wrapper for AutoIt [`FileWrite`](https://www.autoitscript.com/autoit3/docs/functions/FileWrite.htm) function. You can change a name and a path of the output file by changing a value of the `LogFile` constant.

First assumption of the blind bot is success select a monster after usage a macro. When a monster is selected, the Target Window appears. We can search this window with functions from FastFind library. If the window is present, the monster is selected successfully.

The `FFBestSpot` function provides suitable algorithm to solve this task. Now we should pick a color that is specific for the Target Window. Presence of this color on the screen will signal us that the Target Window is present. We can pick a color of monster's HP bar for example. This is a code snippet of the `IsTargetExist` function that checks a presence of the Target Window on the screen:
```AutoIt
func IsTargetExist()
    const $SizeSearch = 80
    const $MinNbPixel = 3
    const $OptNbPixel = 10
    const $PosX = 688
    const $PosY = 67
    
    $coords = FFBestSpot($SizeSearch, $MinNbPixel, $OptNbPixel, $PosX, $PosY, _
                         0x871D18, 10)

    const $MaxX = 800
    const $MinX = 575
    const $MaxY = 100
    
    if not @error then
        if $MinX < $coords[0] and $coords[0] < $MaxX and $coords[1] < $MaxY then
            LogWrite("IsTargetExist() - Success, coords = " & $coords[0] & _ 
                     ", " & $coords[1] & " pixels = " & $coords[2])
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
The `PosX` and `PosY` coordinates define approximate position of monster's HP bar. The `0x871D18` parameter matches to a red color of a full HP bar. This color is used by a searching algorithm. The `FFBestSpot` function searches pixels with the specified color in any position on the screen. Therefore, this function can detect player's HP bar instead the monster's HP bar. It happens when Target Window is not present. To avoid this mistake we check resulting coordinates that are provided by the `FFBestSpot` function. We compare resulting X coordinate (`coords[0]`) with maximum (`MaxX`) and minimum (`MinX`) allowed values. Also the same comparison of Y coordinate (`coords[0]`) with maximum (`MaxY`) values is performed. Values of all coordinates are depended on a screen resolution and a position of the game window. You should adapt these coordinates to your screen configuration. 

We call the `LogWrite` function here to trace each conclusion of the `IsTargetExist` function. This helps us to check correctness of the specified coordinates and the color value.

We can use new `IsTargetExist` function in both `SelectTarget` and `Attack` functions. This function checks a success of the monster select in the `SelectTarget` function. Therefore, we avoid the first assumption of the blind bot. But also the same `IsTargetExist` function is able to check is a monster still alive in the `Attack` functions. If the bot executes the `Attack` functions, this means that a target monster is already selected. Now if the `IsTargetExist` function returns the `False` value, it means that the full HP bar does not present in the Target Window anymore. Thus, we can conclude that monster's HP bar is empty and a monster has died. We avoid the second assumption of the blind bot just now.

This is the complete script with [`AnalysisBot.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/Lineage2Example/AnalysisBot.au3) name, which checks the Target Window presence:
```AutoIt
#include "FastFind.au3"

#RequireAdmin

Sleep(2000)

global const $LogFile = "debug.log"
    
func LogWrite($data)
    FileWrite($LogFile, $data & chr(10))
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

while True
    SelectTarget()
    Attack()
    Pickup()
wend
```
Pay attention to a new implementation of the `SelectTarget` and the `Attack` functions. Command to select a monster is sent in the `SelectTarget` function until the `IsTargetExist` function does not confirm success of this action. Similarly the attack action is sent in the `Attack` function until the target monster is alive. Also log messages are printed in both these functions. This allows us to distinguish a source of each call of the `IsTargetExist` function. Now the bot selects a correct action according to the current game situation.

### Further Improvements

Now our bot is able to analyze results of own actions. But there are several game situations that can lead to the character's death. First problem is an existence of the aggressive monsters. Bot selects a monster with the specified name but all other monsters are still "invisible" for the bot. The issue can be solved by command to select a nearest monster. This command is available via the *F10* key in our Shortcut Panel.

This is a new `SelectTarget` function with selection of the nearest monster:
```AutoIt
func SelectTarget()
    LogWrite("SelectTarget()")
    while not IsTargetExist()
        Send("{F10}")
        Sleep(200)
        
        if IsTargetExist() then
            exitloop
        endif
        
        Send("{F9}")
        Sleep(200)
    wend
endfunc
```
Now the bot tries to select the nearest monster first. Then a macro with the `/target` command is used in case there is no monster near the character. This approach should solve the issue with the "invisible" aggressive monsters. 

Second problem is, there are obstacles in a hunting area. The bot can stuck while moving to the selected monster. The simplest solution of this problem is to add a timeout for the attack action. If the timeout is exceeded, the bot moves randomly to avoid an obstacle.

This is a new version of the `Attack` and the `Move` functions, which provide the feature to avoid obstacles:
```AutoIt
func Move()
    SRandom(@MSEC)
    MouseClick("left", Random(300, 800), Random(170, 550), 1)
endfunc

func Attack()
    LogWrite("Attack()")
    
    const $TimeoutMax = 10
    $timeout = 0
    while IsTargetExist() and $timeout < $TimeoutMax
        Send("{F1}")
        Sleep(2000)
        
        Send("{F2}")
        Sleep(2000)
        
        $timeout += 1
    wend
    
    if $timeout == $TimeoutMax then
        Move()
    endif
endfunc
```
We have added the `timeout` counter to the `Attack` function. This counter is incremented in each iteration of the `while` loop. Then the counter is compared with the threshold value of the `TimeoutMax` constant. If a value of the `timeout` equals to the threshold one, the bot detects own stuck on an obstacle. The `Move` function is called in this case. This function performs a mouse click by `MouseClick` function in the point with random coordinates.  The [`SRandom`](https://www.autoitscript.com/autoit3/docs/functions/SRandom.htm) AutoIt function is called here to initialize a random number generator. After that, the [`Random`](https://www.autoitscript.com/autoit3/docs/functions/Random.htm) function is called to generate random coordinates. The result of the `Random` function is between two numbers that passed as input parameters.

We have added one extra feature to the `Attack` function. This is usage of the attack skill, which is available via the *F2* key. This allows bot to kill monsters faster and get a less damage from them.

Now our example bot is able to work autonomously a long period of time. The bot will overcome obstacles and attack aggressive monsters. There is a last improvement that is able to make the bot more hardy. It can use health potions, which are attached to the *F5* key. We should analyze a level of the character's HP bar in the Status Window in this case. Algorithm of pixels analyzing, which is similar to the `IsTargetExist` function, should solve this task.

## Summary

We have implemented an example bot for Lineage 2 game. This is a typical clicker bot, which uses the most widespread approaches. Therefore, we can evaluate effectiveness of our bot to make an overview of clicker type of bots at all.

This is a list of advantages of clicker bots:

1. Easy to develop, extend functionality and debug.
2. Easy to integrate with any version of the target game even there are significant differences in user interface between these versions.
3. It is difficult to protect a game against this type of bots.

This is a list of disadvantages of clicker bots:

1. The configuration of pixels' coordinates and colors is unique for each user.
2. It is possible that the bot stucks in an obstacle or unexpected condition. The bot will not able to continue its work in some of these cases.
3. Delays and timeouts lead to waste of time.
4. Analysis operations of the bot have unreliable results. It means that the bot will make wrong actions in some cases.

Clicker bot can be effective for solving strictly defined tasks. These tasks should be easy to split to separate steps and algorithmize. Also clicker bot works more reliable in case the algorithm has a minimal count of conditions, and the cost of a mistake is not extremely expensive.