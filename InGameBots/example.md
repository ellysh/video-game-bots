# Example with Diablo 2

## Diablo 2 Overview

Now we will write a simple ingame bot for the RPG game Diablo 2. Gameplay of Diablo 2 is quite typical for RPG genre. Player should resolve quests, kill the monsters and improve his character. Our example bot will be focused on analysis a state of the player character. Therefore, it will be helpful to consider parameters of the player character in details.

There is a screenshot of the game's main screen:

![Diablo 2 Interface](lineage-interface.png)

There is a screenshot of windows with player character parameters:

![Diablo 2 Player](lineage-player.png)

## Bot Overview






## Lineage 2 Overview

Now we will write a simple clicker bot for the popular MMORPG game Lineage 2. It will help us to apply in a practice the knowledge and approaches that have been already acquired. Gameplay of Lineage 2 is a very typical for RPG genre. Player should select one of the available characters before starting to play. Then you should complete quests and hunt monsters to achieve new skills, extract resources and buy new items. Player is able to communicate and to cooperate with other players during all game process. Other players able to assist you in your activity or hamper you in achieving your goals. This feature encourage you to develop your character faster that helps you to resist the interference of other players. You will be able to participate in "team vs team" battles when you achieve a high level of your character. These massive events are a main attraction of the game.

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
