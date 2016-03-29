# Protection Approaches

**This section is still under development.**

We have considered approaches to develop in-game bots. Now we will investigate methods to protect game application against these bots. Let us split protecton methods into two groups:

1. Methods against investiagtion and reverse engineering of the game application.
2. Methods against algorithms of in-game bots.

First group of methods is well known methods that allow you to make it complicate to debug application and explore its memory. Second group of methods allows you to violate a normal work of bot application. Yes, some of methods are able to be refer to both groups. We will emphasize the main goal of each method.

## Test Application

Most of the protection approaches against in-game bots should be implemented inside the game application. It is possible to take already existed game application and try to write a separate protection system for it. But this approach requires much more efforts and time. I suggest to take a simple application that emulates some game model. Also we can develop simple in-game bot that control our test application. Then we will add specific protection features to this application and check, how it helps to protect the application against the bot.

This is an algorithm of the test application:

1. Set a maximum value of the life parameter.
2. Check in the loop, is the keyboard key *1* pressed.
3. Decrement life value in case the key is not pressed. Otherwise, increment the value.
4. Finish the loop and application in case the life parameter become equal to zero.

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

TODO: Describe an algorithm of the test application.

### Investigation of Test Application

TODO: Describe algorithm of reversing the test application.

### Bot for Test Application

TODO: Describe the simplest bot for test application.

## Approaches Against Investiagtion

TODO: Consider anti-debugging and anti-reversing approaches here.

## Approaches Against Bots

TODO: Consider approaches to protect application memory here.

## Summary
