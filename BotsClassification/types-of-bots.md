# Types of Bots

You can often hear about in-game and out-game types of bots when trying to discover this topic in Internet.

In-game bot is a software that embed inside the game client application's memory and provide its functionality by extending game client capabilities. This is illustration of in-game bot on the game application scheme:

[Image: ingame-bot.png]

Out-game bot is a software that works outside the game client application's memory. One kind of out-game bots doesn't need game application at all. This bot substitute the game client. Thus, game server supposes that it works with usual game client application while actually this is out-game bot. This is illustration of this kind out-game bots:

[Image: outgame-bot.png]

Another kind of out-game bots work with game client application in parallel. This bot able to intercept or to gather state of the game objects and notify game application about simulated player's actions through OS:

[Image: outgame-bot-parallel.png]

But this claasification is not convenient enough. It doesn't reflect how bot application actually works and what kind of approaches it uses. Let's consider points on our scheme of game application where bot able to intercept or to gather state of the game objects:
