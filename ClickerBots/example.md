# Example with Lineage 2

## Lineage 2 Overview

Now we will write a simple clicker bot for the popular MMORPG game Lineage 2. It will help us to apply in a practice the knowledge and approaches that have been already acquired. Gameplay of Lineage 2 is a very typical for RPG genre. Player should select one of the available characters before starting to play. Then you should do quests and hunt monsters to achieve new skills, extract resources and buy new items. Player is able to communicate and to cooperate with other players during all game process. Other players able to assist you in your activity or hamper you in achieving your goals. This feature encourage you to develop your character faster that helps you to resist the interference of other players. You will be able to participate in "team vs team" battles when you achieve a high level of your character. These massive events are a main attraction of the game.

The most straightforward way to improve your character is hunting monsters. You will get experience points to improve your skills, gold to buy new items and random resources after killing a monster. We will focus on automation this process as one that allows to develop a player's character in the comprehensive manner. Also there are other ways to develop a character like trading, fishing, crafting new items and completing quests.

This is a screenshoot of the Lineage 2 game:

![Lineage 2 Interface](lineage-interface.png)

This is a list of important interface elements on the screenshoot:
1. **Status Window** with current parameters of the player's character. The most important parameters are health points (HP) and mana points (MP).
2. **Target Window** with an information of the selected monster. It allows you to see a HP of the monster that you are attacking now.
3. **Shortcut Panel** with icons of the available actions and skills that are attached to hotkeys.
4. **Chat Window** for input game commands and chatting with other players.

Understanding the game's interface allow us to make a clicker bot that will interact with the game in a more efficient manner. Detailed information regarding the game's interface available in the [wiki page](https://l2wiki.com/Game_Interface).

There are a lot of Lineage 2 servers. They differs by game version, extra gameplay features and protection systems that are used to prevent a usage of bots. The most reliable and effective protection system is used on [official servers](http://www.lineage2.eu). But there are private servers that suggest you an alternative for official one. We will use a [Rpg-Club](http://www.rpg-club.com) server in our example because the protection system on this server allows to use clicker bots.

## Bot Implementation

This is a simplified algorithm of hunting monsters:
1. Select a monster by left button clicking on him. Alternative way to select a monster is typing a command in the chat window or use a macro with this command:
```
/target MonsterName
```
Full list of the game commands and manual for usage macros are available [here](http://www.lineage2.com/en/game/getting-started/how-to-play/macros-and-commands.php).
2. Click to the "attack" action in the Shortcut Panel. Alternative way to select an attack action is pressing a *F1* (by default) keyboard key.
3. Wait until a player character kill the monster.
4. Click a "pickup" action in the Shortcut Panel to pickup the items that have been dropped out from the killed monster. You can also use a keyboard hotkey for it.

You can see that the algorithm is quite simple and easy to automate at first look.

### Blind Bot

First we will implement the simplest variant of a bot. The bot will perform one by one steps of the hunting algorithm. It will not analyze a result of the performed actions. The bot will use keystroke emulation approach for performing game actions.

It will be helpful to consider a configuration of our Shortcut Panel before we start to write a code. This is a screenshot of the panel:

![Shortcut Panel](lineage-hotbar.png)

This is a list of actions and corresponding hotkeys on the panel:

| Hotkey | Command |
| -- | -- |
| *F1* | Attack the current selected monster |
| *F2* | Use attack skill on the selected monster |
| *F5* | Use a health potion for restoring player's HP |
| *F8* | Pickup items near the player | 
| *F9* | Macro with `/target MonsterName` command to select a monster |
| *F10* | Select a nearest monster |

Now it becomes simple to associate hotkeys with algorithm actions and writes a code. This is a script with [`BlindBot.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/Lineage2Example/BlindBot.au3) name that implements all steps of the algorithm:
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
First line of the script is a  [`#RequireAdmin`](https://www.autoitscript.com/autoit3/docs/keywords/RequireAdmin.htm) keyword. The keyword allows interaction between the script and an application that has been launched with administrator privileges. Lineage 2 client can request the administrator privileges for launching. Next action in the script is a waiting two seconds that are needed to you for manually switching to the Lineage 2 application. All bot's actions is performed in the infinite `while` loop. This is a sequence of the actions:

1. `Send("{F9}")` - select a monster by a macro that is available via *F9* key.
2. `Sleep(200)` - sleep a 200 milliseconds. This delay is needed for the game application to select a monster and to draw a Target Window. You should remember that all actions of the game take a nonzero time. Often this time is much less than the human reaction time and therefore it looks instantly.
3. `Send("{F1}")` - attack the selected monster.
4. `Sleep(5000)` - sleep 5 seconds while the character reaches a monster and kills it.
5. `Send("{F8}")` - pickup one item.
6. `Sleep(1000)` - sleep 1 second while character is picking up the item.

You can see that we have made few assumptions in the script. First assumption is successful result of the monster selecting. All further actions will not have an effect if there is not any monster with the specified name near the player's character. Second assumption is delay for 5 seconds after an attack action. The distance between the selected monster and character is able to vary. It means that 1 second will be enough to achieve the monster in one case. But it is needed 6 seconds to achieve the monster in another case. Third assumption is a count of picking up items. Now only one item will be picked up but  more than one item is able to be dropped from the monster.

Now you can launch the script and test it. Obviously, the moment comes when one of our three assumptions will be violated. The important thing for blind types of clicker bots is a possibility to continue work correctly  after a violation of the assumptions. This possibility is available for our test bot. The reasons why it happens are features of the macro with `/target` command and the attack action mechanism. If the macro will be pressed twice the same monster will be selected. Thus, the bot will continue to attack the same monster until it still alive. If the monster has not been killed on a current iteration of the loop this process will be continued on the next iteration. Also an attack action will not be interrupted after sending a pickup action by *F8* key if there are not any available items for picking up near the character. It means that the character will not stop to attack the current monster even the 5 second timeout for attack action will be exceeded. There is third assumption regarding to count of items for picking up. The issue can be solved by hardcoding an exact count of the items that usually dropped by this type of monsters.

We can improve the script by moving each step of the algorithm to a separate function with a descriptive name. It will make the code more readable. This is a [`BlindBotFunc.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/Lineage2Example/BlindBotFunc.au3) script with the separate functions:
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

The blind bot can be improved by adding a feature of checking the results of own actions. We will substitute our assumptions to the checks that are based on a pixels analyzing approach. But before we start to implement the checks it will be helpful to add a mechanism of printing log messages. The mechanism will help us to trace results of all checks and to discover possible bugs.

This is a code snippet with a `LogWrite` function that prints a log message into the file:
```AutoIt
global const $LogFile = "debug.log"

func LogWrite($data)
    FileWrite($LogFile, $data & chr(10))
endfunc

LogWrite("Hello world!")
```
Result of the code execution is creation of the file with a `debug.log` name which contains a string "Hello world!". `LogWrite` function is a wrapper for AutoIt [`FileWrite`](https://www.autoitscript.com/autoit3/docs/functions/FileWrite.htm) function. You can change a name and a path of the output file by changing a value of the `LogFile` constant.

First assumption of the blind bot is a success of the monster select by a macro. One of the possible check for the selecting action success is looking for a Target Window with functions from FastFind library. `FFBestSpot` is a suitable function for solving this task. Now we should pick a color in the Target Window that will signal about the window presence. We can pick a color of the target's HP bar for example. This is a code snippet with `IsTargetExist` function that checks a presence of the Target Window:
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
`PosX` and `PosY` coordinates are an approximate position of the HP bar in Target Window. The `0x871D18` parameter matches to a red color of a full HP bar and it will be used by a searching algorithm. `FFBestSpot` function performs searching of pixels with the specified color over all game screen. Therefore, HP bar in the player's Status Window will be detected if the HP bar in the Target Window has not been found. There is an extra checking of the resulting coordinates that are returned by `FFBestSpot` function. It allows to distinguish Target Window and Status Window. The checking is performed by comparing a resulting X coordinate (`coords[0]`) with maximum (`MaxX`) and minimum (`MinX`) allowed values. Also the same comparison of Y coordinate (`coords[0]`) with maximum (`MaxY`) value is performed to distinguish Target Window and Shortcut Panel. Values of all coordinates are depended on a screen resolution and a position of the game window. You should adopt it to your screen configuration. 

Also `LogWrite` function is called here to trace each conclusion of the `IsTargetExist` function. It can help you to check a correctness of the specified coordinates and a color value.

We can use new `IsTargetExist` function both in `SelectTarget` and `Attack` functions. It checks a success of the monster select in the `SelectTarget` that helps to avoid first assumption of the blind bot. Also it is possible to check if a monster has been killed with the same `IsTargetExist` function to avoid the second assumption. If the function has returned `False` value it means that there are no pixels with the color equal to full HP bar in the Target Window. In other words, the HP bar of a target is empty and the monster has died.

This is a resulting script with [`AnalysisBot.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/Lineage2Example/AnalysisBot.au3) name:
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
Pay attention to a new implementation of `SelectTarget` and `Attack` functions. Command for selecting a monster will be sending in the `SelectTarget` function until success result has happened. Similarly, the attack action will be sending in the `Attack` function until the target monster is alive. Also there are log messages printing in the both functions. It allows to distinguish a source of each `IsTargetExist` function call in the log file. All these improvements lead to more precise work of the bot, and they help to select a correct action according to the current game situation.

### Further Improvements

Now our bot is able to analyze results of own actions. But there are several game events that can lead to the character's death. First problem is an existence of the aggressive monsters. Bot selects a monster with the specified name but all other monsters are "invisible" for the bot. The issue can be solved by command to select a nearest monster that is available via *F10* key in our Shortcut Panel.

This is a new `SelectTarget` function:
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
Now the bot will try to select a nearest monster first. The macro with `/target` command will be used after if there is no monster near a character. This approach should solve a problem of the "invisible" monsters. 

Second problem is obstacles at a hunting area. Thu bot can stuck while moving to the selected monster. The simplest solution of this problem is adding a timeout for the attack action. If the timeout is exceeded the bot should move randomly to avoid an obstacle.

This is new `Attack` and auxiliary `Move` functions:
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
You can see that a `timeout` variable has been added. The variable stores a counter of `while` loop  iterations. It is incremented in each iteration and compared with the threshold value of a `TimeoutMax` constant. If a value of `timeout` equals to the threshold one a `Move` function will be called. The `Move`  performs a mouse click by `MouseClick` function in the point with random coordinates.  [`SRandom`](https://www.autoitscript.com/autoit3/docs/functions/SRandom.htm) AutoIt function is called here to initialize a random number generator. After that, [`Random`](https://www.autoitscript.com/autoit3/docs/functions/Random.htm) function is called to generate coordinates. A result of the `Random` function will be between two numbers that passed as input parameters.

One extra feature has been added to the `Attack` function. This is a usage of the attack skill that is available via *F2* key. It allows to kill monsters faster and get a less damage from them.

Now our example bot is able to work autonomously a long period of time. It will overcome obstacles and attack aggressive monsters. There is a last improvement that is able to make the bot more hardy. It can use a health potions that are attached to the *F5* key. Additional pixel analyzing similar to `IsTargetExist` function should be added in this case to check a character's HP in the Status Window.

## Summary

We have implemented an example bot for Lineage 2 game. But it is a typical clicker bot that uses the most widespread approaches that are specific for this type of bots. Therefore, we can evaluate its effectiveness, advantages and disadvantages for making an overview of clicker type of bots at all.

This is a list of advantages of clicker bots:

1. Easy to develop, extend functionality and debug.
2. Easy to integrate with any version of the target game even if an interface of these versions differs significantly.
3. It is difficult to protect a game against this type of bots.

This is a list of disadvantages of clicker bots:

1. The configuration of pixels' coordinates and colors is needed for each user.
2. It is possible that the bot can stuck in a obstacle or unexpected condition. It will not able to continue its work in this cases.
3. Delays and timeouts lead to waste of time in the most cases.
4. Analysis operations of the bot has an unreliable results. It means that the bot will make wrong actions in some cases.

A clicker bot can be effective for solving strictly defined tasks. These tasks should be easy to split by separate steps and algorithmize. Also a clicker bot works more reliable if the algorithm has a minimal count of conditions, and the cost of a mistake does not extremely expensive.