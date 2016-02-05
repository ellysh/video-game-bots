# Example with Diablo 2

## Diablo 2 Overview

Now we will write a simple ingame bot for the RPG game Diablo 2. Gameplay of Diablo 2 is quite typical for RPG genre. Player should do  quests, kill the monsters and improve his character. Our example bot will be focused on analysis a state of the player character. Therefore, it will be helpful to consider parameters of the player character in details.

There is a screenshot of the game's main screen:

![Diablo 2 Interface](diablo-interface.png)

You can see a player character in the center of the screen. There is an yellow model of the knight. Also you can see monsters around the player's character. One of the monster is selected by a mouse cursor.

There is a screenshot of windows with player character parameters:

![Diablo 2 Player](diablo-player.png)

There are two windows in this screenshot. Left window contains the common information about a player character like his name, class, level and experience points. This information available at the top of the window. Also below there are attributes, that define a behavior of the character in the game process. For example the strength attribute defines a damage amount which will be delivered to the monsters.

Right window contains a tree of the character's skills. There are special abilitites and combos that allow you to make a more damage or to improve significantly the character's attributes. Each skill have a level. It defines, how effective usage of this skill will be. You can get more details about parameters and skills of player character in the [wiki page](http://diablo.gamepedia.com/Classes_%28Diablo_II%29)

## Bot Overview
