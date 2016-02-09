# Game Application

Before we start our investigation of the bot applications, it will be appropriate to consider how video game applications work.

This is a scheme with components of a typical on-line game application:

![On-line Game Application Scheme](game-application.png)

Launched game client application is one of the plenty [**computing processes**](https://en.wikipedia.org/wiki/Process_%28computing%29) of [**operating system**](https://en.wikipedia.org/wiki/Operating_system) (OS). Each of these processes has a separate [**memory sandbox**](http://duartes.org/gustavo/blog/post/anatomy-of-a-program-in-memory) that has been allocated by OS. OS provides an access to devices for all launched processes. Examples of devices are monitor, keyboard, mouse, network adapter and etc. OS handles requests from the processes for data output events like displaying a picture on the screen or sending a packet through the network adapter. Also OS notifies processes about the data input events like a keyboard key pressing or reception of a packet on the network adapter. OS performs all these tasks using [**drivers**](https://en.wikipedia.org/wiki/Device_driver) and [**system libraries**](https://en.wikipedia.org/wiki/Library_%28computing%29). They are combined in a block with OS name in the scheme for simplification purpose.

Now we will consider a concrete player action and its consequence. We will use the scheme to follow which components will participate in the action's processing. Let us suppose, that you want to move player's character. You press the appropriate arrow key on the keyboard to do it. This is an approximate list of events that will provide a character's movement action:

1. The keyboard driver signals OS by the [**interrupt**](https://en.wikipedia.org/wiki/Interrupt) mechanism that an arrow key was pressed.
2. OS handles the keyboard driver notification. Then OS notifies a process about the keyboard event. Usually this notification will be received by the process whose window has an active state at the moment. Let us assume, that this is the process of a game application.
3. Game application's process receives the keyboard event notification from OS. The process requires OS to send a network packet to the game server. The packet contains an information about the new character's position.
4. Game server validates the new character's position according to the game rules. If the check is succeded, the server sends a network packet to the client host. There is a confirmation of the new character's position oin the packet.
5. OS notifies the game application's process about receiving a packet from the game server. The process reads data from the packet via a network library of the OS. The library uses a driver of a network adapter to read the received data.
6. Game application's process updates the state of game objects in own memory according to the new character's position.
7. Game application's process requires OS to update a current picture at the screen according to the new state of the game objects.
8. OS requires a graphic library like [**OpenGL**](https://en.wikipedia.org/wiki/OpenGL) or [**DirectX**](https://en.wikipedia.org/wiki/DirectX) to draw a new picture on the screen. 
9. Graphic library performs calculations for the new picture and draws it using the video driver.

That is all what is needed for moving the character.

This algorithm still almost the same for other player's actions. It may vary in case of the internal game events. This kind of events usually happen on the game server side. Algorithm of the processing these events will contain the steps from 5 to 9 numbers of the considered algorithm. The game server notifies client that something was changed. Game application's process updates the state of game objects and requires to refresh the screen picture.

The considered game application scheme is still valid for the most of modern popular on-line games. The game genre like RPG, real-time strategy, shooter, sports and etc is not important in this case. All of these genres use the similar mechanisms and [**client-server architecture**](https://en.wikipedia.org/wiki/Client%E2%80%93server_model).

The scheme should be corrected slightly if we will consider the games with a single play mode only:

![Local Game Application Scheme](game-local-application.png)

Game server component should be excluded from the scheme. All player actions and game events affect an game application's process memory only. State of all game objects is  stored on a local PC. Please note, that the state of game objects is stored on both server-side and client-side in case of the on-line games. But the server-side information has a higher priority than a client-side one. Therefore if the state of the game objects differs on the server-side and client-side, the server-side state will be chosen as a genuine. Game server implicitly controls a correctness of the game objects' state. But nobody controls this correctness in case of the single player game.

Single player and on-line games have the same algorithm of interaction with OS resources via drivers and system libraries.
