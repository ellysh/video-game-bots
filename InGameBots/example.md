# Example with Diablo 2

## Diablo 2 Overview

Now we will write a simple in-game bot for the popular RPG game Diablo 2. Gameplay of Diablo 2 is quite typical for RPG genre. Player should do  quests, kill the monsters and improve his character. Our example bot will be focused on analysis a state of the player character. Therefore it will be helpful to consider parameters of the player character in details.

There is a screenshot of the game's main screen:

![Diablo 2 Interface](diablo-interface.png)

You can see a player character in the center of the screen. There is an yellow model of the knight. Also you can see monsters around the player's character. One of the monster is selected by a mouse cursor.

There is a screenshot of windows with player character parameters:

![Diablo 2 Player](diablo-player.png)

There are two windows in this screenshot. Left window contains the common information about a player character like his name "Kain", class "Paladin", level and experience points. This information available at the top of the window. Also below there are attributes, that define a behavior of the character in the game process. For example the "Strength" attribute defines a damage amount which will be delivered to the monsters.

Right window contains a tree of the character's skills. There are special abilities and combos that allow you to make a more damage or to improve significantly the character's attributes. Each skill have a level. It defines, how effective usage of this skill will be. You can get more details about parameters and skills of player character in the [wiki page](http://diablo.gamepedia.com/Classes_%28Diablo_II%29)

Diablo 2 has the single player and multiplayer game modes. We will consider the single player mode only. It allows us to stop the game at any moment and to explore its memory without any time limitations. Otherwise the game client, who does not respond to the game server's requests, will be disconnected. This limitation does not allow us to use a debugger and to stop the game application for investigation its internals.

Diablo 2 is available for buying at the [Blizzard Entertainment website](https://eu.battle.net/shop/en/product/diablo-ii). There is an open source game with a [Flare](http://flarerpg.org/) name, that is available for free. It has the very close game mechanics and interface to the Diablo 2 ones. You can use the Flare game to try methods of memory investigation, that are described in this chapter. All these methods are applicable to the Flare game too.

## Bot Overview

You can find detailed articles by Jan Miller about hacking Diablo 2 game. This is a first [article](http://extreme-gamerz.org/diablo2/viewdiablo2/hackingdiablo2). This is a second [article](http://www.battleforums.com/threads/howtohackd2-edition-2.111214/). Approaches, that are described in the articles, are focused to the changing of a normal behavior of the game. These changes of the application behavior is named "hacks". But a bot application should behave in the different manner. The bot should not affect a normal behavior of the game application. Instead it should analyze a state of the game objects and modify it. Meanwhile the game application is still working within its normal algorithms. Only state of the objects are changed but this state is still valid according to the game mechanics.

Our sample in-game bot will have a very simple algorithm:

1. Read current value of the player character's "Life".
2. Compare the read value with some threshold value.
3. Increase the current "Life" value to the possible maximum one.

This algorithm allows to keep a player character alive regardless of the gained damage from the monsters. Nevertheless an implementation of so simple algorithm requires a deep research of the Diablo 2 game memory.

## Diablo 2 Memory Analysis

TODO: Describe a method of searching artifacts in the game memory with Cheat Engine.

TODO: Describe a method of searching a beginning of the object in the memory.

TODO: Describe a method of investigation a fields meaning of the object .

## Bot Implementation

TODO: Describe a method of searching "magic numbers" of an object in the memory.

## Another Bot Variants

TODO: Describe a method of searching monsters' coordinates in the memory.

TODO: Write about ideas to emulate the player's actions.

## Summary