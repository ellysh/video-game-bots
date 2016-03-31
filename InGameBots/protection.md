# Protection Approaches

**This section is still under development.**

We have considered approaches to develop in-game bots. Now we will investigate methods to protect game application against these bots. Let us split protecton methods into two groups:

1. Methods against investiagtion and reverse engineering of the game application.
2. Methods against algorithms of in-game bots.

First group of methods is well known methods that allow you to make it complicate to debug application and explore its memory. Second group of methods allows you to violate a normal work of bot application. Yes, some of methods are able to be refer to both groups. We will emphasize the main goal of each method.

## Test Application

Most of the protection approaches against in-game bots should be implemented inside the game application. It is possible to take already existed game application and try to write a separate protection system for it. But this approach requires much more efforts and time. I suggest to write a simple application that emulates some game model. Also we can develop primitive in-game bot that controls our test application. Then we will add specific protection features to this application and check, how it helps us to protect the application against the bot.

This is an algorithm of the test application:

1. Set a maximum value of the life parameter.
2. Check in the loop with one second delay, is the keyboard key *1* pressed.
3. Decrement life value in case the key is not pressed. Otherwise, increment the value.
4. Finish the loop and application in case the life parameter becomes equal to zero.

This is a source code of the [`TestApplication.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/TestApplication.cpp):
```C++
#include <stdint.h>
#include <windows.h>

static const uint16_t MAX_LIFE = 20;
static uint16_t gLife = MAX_LIFE;

int main()
{
	SHORT result = 0;

	while (gLife > 0)
	{
		result = GetAsyncKeyState(0x31);
		if (result != 0xFFFF8001)
			--gLife;
		else
			++gLife;

		printf("life = %u\n", gLife);
		Sleep(1000);
	}

	printf("stop\n");

	return 0;
}
```
You can see that life parameter is stored in the global variable with the `gLife` name. After initialization the value equals to `MAX_LIFE` constant, i.e. 20. The state of keyboard keys is checked in the `while` loop. We use [`GetAsyncKeyState`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646293%28v=vs.85%29.aspx) WinAPI function for this checking. `GetAsyncKeyState` function has only one input parameter that equals to the virtual-key code, which state should be checked. The parameter equals to `0x31` value, i.e. key *1* in our case. Then we decrement a life parameter in case the *1* key is not pressed. Otherwise, we increment the parameter. One second delay is performed by `Sleep` WinAPI function.

You can compile and launch the test application to clarify, how it works.

### Investigation of Test Application

Now we are ready to start development of an in-game bot for our test application. I suggest to implement the same algorithm for this bot as we have done in [Example with Diablo 2](example.md) section. The bot should increase a life parameter in case its value becomes less than 10.

Let us investigate, where a life parameter is stored in the test application's memory. This application is quite simple and short. Therefore, we can use OllyDbg only to consider its internals. 

This is an algorithm for investigation of our test application:

1\. Launch OllyDbg debugger. Open the "TestApplication" binary in the "Select 32-bit executable" dialog that is available by *F3* key. You will see a start point of the application execution in the sub-window with disassembled code.

2\. Press the *Ctrl+G* key to open the "Enter expression to follow" dialog.

3\. Type a name of the `main` function into the "Enter address expression" field. This is a "TestApplication.main" name in our case. Then press the "Follow expression" button. Now a cursor in the disassembler sub-window points to the first instruction of the `main` function.

4\. Set a breakpoint on this instruction by pressing the *F2* key.

5\. Start execution of the test application by *F9* key press. The execution will break on our breakpoint. The window of OllyDbg should look like this:

![Test Application Ollydbg](test-application-ollydbg.png)

6\. Click by left button on this line of dissasembled code:
```
MOV AX,WORD PTR DS:[gLife]
```
The cursor is placed on this line in the screenshoot. Select the "Follow in Dump" and then "Memory address" items in the popup menu. Now the cursor of the memory dump sub-window is placed on the `gLife` variable. The variable equals to "14" in hexadecimal. An address of the variable equals to "329000" in my case.

7\. Open the "Memory map" window by *Alt+M* key press.

8\. Find a memory segment which contains the `gLife` variable. This should be a ".data" segment of the "TestApplication" module:

![Test App Segment Ollydbg](testapp-segment-ollydbg.png)

Now we know where the `gLife` variable is stored. We have enough information to find the memory segment that owns this variable. Offset of the variable inside the `.data` segment equals to zero.

### Bot for Test Application

TODO: Describe the simplest bot for test application.

## Approaches Against Investiagtion

TODO: Consider anti-debugging and anti-reversing approaches here.

## Approaches Against Bots

TODO: Consider approaches to protect application memory here.

## Summary
