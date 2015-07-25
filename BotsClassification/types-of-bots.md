# Types of Bots

You can often hear about in-game and out-game types of bots when trying to discover this topic in Internet. These terms are widely used and well known in the gamers community.

In-game bot is a software that embed inside the game client application's memory and provide its functionality by extending game client capabilities. This is illustration of in-game bot on the game application scheme:

![In-game Bot Scheme](ingame-bot.png)

Out-game bot is a software that works outside the game client application's memory. One kind of out-game bots doesn't need game application at all. This bot substitute the game client. Thus, game server supposes that it works with usual game client application while actually this is out-game bot. This is illustration of this kind out-game bots:

![Out-game Bot Scheme](outgame-bot.png)

Another kind of out-game bots work with game client application in parallel. This bot able to intercept the state of game objects and notify the game application about simulated player's actions through OS:

![Out-game Bot Parallel Scheme](outgame-bot-parallel.png)

Also you can faced with a mention about clicker bots. This is a special case of the out-game bots that work with game application in parallel. Clicker bot sends the keyboard and mouse events notifications to game application through the OS.

But this widespread in gamers community classification is not convenient enough for bot developers. It doesn't reflect how the bot application actually works and what kind of approaches it uses. It will be better to use as classification basis the methods that bot application uses for [input data about game objects and output bot actions](http://stackoverflow.com/questions/2741040/video-game-bots).

Let's consider points on our scheme of game application where bot able to intercept the state of game objects. The points of intercepting the data is marked by red cross:

![Intercepting Data by Bot](input-data-bot.png)

This is a list of the interception points:

1. Output devices. It is possible to capture data from the output devices like monitor or audio column and parse it.

2. Operation system. You can substitute or change some libraries or drivers of operation system. This allow you to trace the notifications that are sent to the game client application and the requests to OS from the application. Another way is launching game application under emulator of operation system like Wine. Emulators often have an advanced logging system. Thus, you have a detailed information about the each step of the game application work.

3. Game server. The network packets that are sent to the game application from the game server can be intercepted. The current state of the game objects is transmitted by this way in most cases.

4. Game client application. You can get access to the game application memory and gather necessary information from there.

Bot application should notify the game server about simulated player's actions after analyzing the state of game object and performing the appropriate algorithms. This is a scheme of points marked as green cross where bot application able to embed their notifications:

![Embedding Data by Bot](output-data-bot.png)

This is a list of the embedding notification points:

1. Input device. Special devices can be used for emulation usual input device. You can use Arduino board that emulates the keyboard behavior and that is controlled by bot application for example.

2. Operation system. Parts of operation system able to be modified for becoming controlled by bot application. You can modify a keyboard driver and allow bot to notify OS about keyboard actions through the driver for example. Thus, OS will not have possibility to distinguish whether the keyboard event really happened or it was embed by bot.

3. Game server. Bot application able to send network packets with simulated actions directly to the game server the same way as it always done by game client application. Game server have not possibility to distinguish the source application of the network packet in some cases.

4. Game client application. The bot simulated actions can able to be embed directly to the state of the current game that holds in the game application memory. Thus, game application will consider that new state have been updated legally and will send notification about it to the game server.
