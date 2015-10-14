# Example with Lineage 2

## Lineage 2 Overview

Now we will write a simple clicker bot for a popular MMORPG game Lineage 2. It help us apply in practice  knowledge and approaches that have been already acquired. Gameplay of Lineage 2 is very typical for RPG genre. Player should select one of the available characters before starting a play. Then you should complete quests and hunt monsters to achieve new skills, extract resources and buy new items. Player able to communicate and cooperate with other players during all game process. Other players able to assist you in your activity or hamper you in achieving your goals. This feature encourage you to develop your character faster that helps you to resist the interference of other players. You will able to participate in "team vs team" battles when achieve a high level of your character. These massive events are the main attraction of the game.

The most straightforward way to improve your character is hunting monsters. You will get experience points to improve your skills, gold to buy new items and random resources after killing a monster. We will focus on automation this process as one that allow to develop a player character in the comprehensive manner. Also there are another ways to develop a character like trading, fishing, crafting new items and completing quests.

This is a screenshoot of the Lineage 2 game:

[Image: Screenshot of the game client]

This is a list of important interface elements on the screenshoot:
1. Status Window with current parameters of the player's character. The most important parameters are health points (HP) and mana points (MP).
2. Target Window with an information of the selected monster. It allows you to see a HP level of the monster that you are attacking now.
3. Shortcut Panel with icons of the available actions and skills.
4. Chat Window for input game commands and chating with other players.

Understanding the game's interface allow us to make a clicker bot that will interact with the game in more efficient manner. Detailed information regarding the game's interface available [here](https://l2wiki.com/Game_Interface).

This is a simplified algorithm of hunting monsters:
1. Select a monster by left button clicking on him. Alternative way to select a monster is typing a command in the chat window:
```
/target MonsterName
```
Full list of the game commands is available [here](http://www.lineage2.com/en/game/getting-started/how-to-play/macros-and-commands.php).
2. Click to the "attack" action in the Shortcut Panel. Alternative way to select an "attack" action is pressing a **F1** (by default) keyboard key.
3. Wait of killing a monster by player character.
4. Click a "pickup" action in the Shortcut Panel to pickup the items that have been dropped out from the killed monster. You can also use keyboard hotkey for it.

You can see that the algorithm is quite simple and easy to automate at first look.

There are a lot of Lineage 2 servers. They differs by game version, extra gameplay features and protection systems that are used to prevent a usage of bots. The most reliable and effective protection system is used on [official servers](http://www.lineage2.eu). But there are freeshard private servers that suggest you an alternative for official one. We will use a [Rpg-Club server](http://www.rpg-club.com) in our example because the protection system on this server allows to use clicker bots.

## Bot Implementation

## Conclusion