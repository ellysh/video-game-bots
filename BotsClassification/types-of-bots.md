# Types of Bots

## Community Classification

You can often find references to the **in-game** and **out-game** types of bots while you looking for information about them on the Internet. These terms are widely used and well known in a gamer community.

In-game bot is a software that is embedded inside the game client application's process. Bot provides own functionality by extending capabilities of the game client. This is a scheme of interaction the in-game bot and a game application:

![In-game Bot Scheme](ingame-bot.png)

Out-game bot is a software that works outside the game client application's process. First kind of out-game bots does not need the game application at all. The bot substitutes the game client. Therefore a game server supposes, that it communicates with an usual game client application, while in reality there is the out-game bot. This is a scheme of interaction the standalone out-game bot and the game server:

![Out-game Bot Scheme](outgame-bot.png)

Second kind of out-game bots works with a game client application's process in a parallel manner. These bots are able to gather information about a state of the game objects and and to notify the game application about the simulated player's actions through the system libraries of OS:

![Out-game Bot Parallel Scheme](outgame-bot-parallel.png)

Also you can be faced with a mention about the **clicker** type of bots. This is a special case of the out-game bots. Clicker bots send the keyboard and mouse events notifications to the game application's process through the system libraries or drivers.

We will use the **community classification** term for naming these three kinds of bots.

## Developers Classification

Community classification is quite convenient for users of the bot applications. The problem is that the classification reflects, how the bot application works. But it does not reflect which approaches and methods it uses. Therefore it can be not enough for the bot developers. We can avoid this kind of the information lack, if we will choose another basis for the bots classification. I suggest to consider actual methods, that a bot application uses to intercept data about the game objects and methods to simulate player's actions. These methods are able to become a new basis for the bots classification.

Now we will consider points in our game application scheme, where the bot is able to intercept a state of the game objects. These points of the data interception are marked by the red crosses:

![Intercepting Data by Bot](input-data-bot.png)

This is a list of the data interception points:

1. **Output Devices**<br/>
It is possible to capture data from the output devices like a monitor or an audio card. This feature of the data capture is provided by the system libraries of OS. When game objects are drew on the screen, they have the specific colors. Similar game events are often accompanied by the specific sounds, that are reproduced by an audio card. You can compare these captured colors and sounds with the predefined values. It allows you to make a conclusion about the current state of objects.

2. **Operating System**<br/>
You can substitute or modify some system libraries or drivers of OS. It allows you to trace interactions between the game application and OS. Another way is to launch the game application under an OS emulator like Wine or others. Emulators often have an advanced logging system. Thus you will get a detailed information about each step that has been performed by the game application.

3. **Game Server**<br/>
[**Network packets**](https://en.wikipedia.org/wiki/Network_packet), that are sent to the game application from the game server, can be intercepted. Current state of the game objects is transmitted this way in most cases. Therefore you can get this state by analyzing of the intercepted packets.

4. **Game Client Application**<br/>
You can get an access to the memory of a game application's process and read the state of game objects from there. This feature of the interprocess communication is provided by the system libraries of OS. 

Result of a bot application's work is simulated player actions that should be transmitted to the game server. This scheme illustrates points (that are marked by the green crosses) where the bot application can embed its data:

![Embedding Data by Bot](output-data-bot.png)

This is a list of the data embedding points:

1. **Input Device**<br/>
All input devices are legal from the point of view of OS. Therefore special devices can be used to substitute or emulate the standard input devices like a mouse or a keyboard. For example, you can use [**Arduino**](https://en.wikipedia.org/wiki/Arduino) board that will emulate a keyboard's behavior. This board can be controlled by a bot application.

2. **Operating System**<br/>
Bot application is able to modify and to control some components of the OS. For example, you can modify a keyboard driver in the way, that allows a bot application to notify the OS about keyboard actions through this driver. In this case, the OS cannot distinguish whether the keyboard event has really happened or it has embedded by the bot. Also the interprocess communication feature allows you to simulate keyboard events for the specific process.

3. **Game Server**<br/>
Bot application can send network packets with the simulated actions directly to the game server. It can be performed in the same way as the game client application does. Game server has no possibility to distinguish the network packet's source in some cases.

4. **Game Client Application**<br/>
Bot simulated actions and a new game state are able to be embedded directly into the memory of game application's process. Thus the game application will consider, that  the player's actions have really happened and the new game state has been changed in a regular way.

We will use the **developer classification** term for naming bots with emphasizing their methods of the interception and embedding data.

## Summary

Following table summarizes community and developers bots classification:

![Types of Bots](types-of-bots.png)

Each crossing of the row and column defines type of a bot application that uses respective methods of the data interception and data embedding. Community classification defined types of the bots are placed into the corresponding cells. 

You can see plus and minus signs inside each cell. This illustrates an approximate evaluation of two parameters balance for each type of bot:

1. How difficult is this approach in development?

2. How effective and reliable (error-free) is the bot resulting from this approach?

This is a description of possible values:

The "–" sign means that this combination of data interception and embedding methods requires an unreasonable work effort. Effectiveness and reliability of result can be easier achieved with other approaches.

The "+" sign means that this combination of methods allows you to achieve accurate and effective solution. Also it requires a reasonable amount of work.

The "++" sign marks the combinations of methods that allow you to achieve the most effective or the simplest implementation solution.

Now we can briefly explain the evaluation:

1. **Network** packets analysis is one of the most difficult ways to intercept game data. You should implement a communication protocol between the game client and the game server. Obviously there is no any official documentation regarding the protocol. Usually, everything bot developer has is a game application executable file and examples of already intercepted network packets. Moreover, network packets are often encrypted, and sometimes you have no possibility to decrypt it unambiguously. On the other hand, this approach provides the most precise and complete data about the state of game objects. Bots that are based on the network packets interception can be very efficient thanks to this detailed data.

2. **Memory** analysis is the second difficult approach to intercept game data. Game developers distribute their applications in binary codes that were produced by [**compiler**](https://en.wikipedia.org/wiki/Compiler) from a source code. You have no chance to get the exact source code of the application to investigate algorithms and data structures. Protection systems are able to relocate and to encrypt information regarding game objects in the application memory. Patching game application memory is a quite dangerous method of embedding data because of possibility to crash application. But this approach provides almost the same accurate game data as the network packets analyzing one.

3. Capturing of the **Output Device** data is one of the simplest approaches to data interception. But the result of this approach is not reliable. For example, algorithms of image analysis may be wrong in some cases. The evaluation of this approach effectiveness depends largely on the specific game application.

4. Embedding data with **Input Device** is a good way to avoid some types of [**anti-cheat protection systems**](https://en.wikipedia.org/wiki/Cheating_in_online_games#Anti-cheating_methods_and_limitations). But you need to buy the device itself and to write an appropriate firmware for it. It makes sense to use this approach only when it is necessary to avoid a game application's protection. The embedding data on the OS level works quite similar but it is easier for an protection system to detect it.

5. Intercepting data with **OS** can be a very universal and reliable method. You can find already available open source solutions for the [system library substitution](https://graphics.stanford.edu/~mdfisher/D3D9Interceptor.html) that allow you to gather information about the game application work.

You can see that a community classification covers most effective and simplest for implementation combinations of the intercepting and embedding data methods. On the other hand, rarely used and ineffective method combinations are not mentioned in the community classification. We will primarily use the community classification throughout this book. The developers classification will be used in cases when it is important to emphasize exact bot's algorithms.