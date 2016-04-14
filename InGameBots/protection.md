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

1\. Launch OllyDbg debugger. Open the "TestApplication.exe" binary in the "Select 32-bit executable" dialog that is available by *F3* key. You will see a start point of the application execution in the sub-window with disassembled code.

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

Now we know where the `gLife` variable is stored. We have enough information to find the memory segment that owns this variable. Base address of this segment equals to the address of the `gLife` variable because the offset of the variable equals to zero.

### Bot for Test Application

This is a detailed algorithm of our bot:

1. Enable `SE_DEBUG_NAME` privilege for current process.
2. Open the test application process.
3. Search the memory segment that contains the `gLife` variable.
4. Read a value of the life variable in a loop. Write value 20 to variable in case it becomes less than 10.

This is a souce code of the [`SimpleBot.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/SimpleBot.cpp) application:
```C++
#include "stdafx.h"
#include <windows.h>

BOOL SetPrivilege(HANDLE hToken, LPCTSTR lpszPrivilege, BOOL bEnablePrivilege)
{
	// Implementation of the function is still the same 
	// and it is available in the SimpleBot.cpp source file
}

SIZE_T ScanSegments(HANDLE proc)
{
	MEMORY_BASIC_INFORMATION meminfo;
	LPCVOID addr = 0;

	if (!proc)
		return 0;

	while (1)
	{
		if (VirtualQueryEx(proc, addr, &meminfo, sizeof(meminfo)) == 0)
			break;

		if ((meminfo.State == MEM_COMMIT) && (meminfo.Type & MEM_IMAGE) &&
			(meminfo.Protect == PAGE_READWRITE) && (meminfo.RegionSize == 0x1000))
		{
			return (SIZE_T)meminfo.BaseAddress;
		}
		addr = (unsigned char*)meminfo.BaseAddress + meminfo.RegionSize;
	}
	return 0;
}

WORD ReadWord(HANDLE hProc, DWORD_PTR address)
{
	// Implementation of the function is still the same 
	// and it is available in the SimpleBot.cpp source file
}

void WriteWord(HANDLE hProc, DWORD_PTR address, WORD value)
{
	if (WriteProcessMemory(hProc, (void*)address, &value, sizeof(value), NULL) == 0)
		printf("Failed to write memory: %u\n", GetLastError());
}

int main()
{
	// Enable `SE_DEBUG_NAME` privilege for current process here.

	// Open the test application process here.
	
	SIZE_T lifeAddress = ScanSegments(hTargetProc);

	ULONG hp = 0;
	while (1)
	{
		hp = ReadWord(hTargetProc, lifeAddress);
		printf("life = %lu\n", hp);

		if (hp < 10)
			WriteWord(hTargetProc, lifeAddress, 20);

		Sleep(1000);
	}
	return 0;
}
```
Key difference of this bot application from the bot for Diablo 2 game is an algorithm of `ScanSegments` function. In this case, we can distinguish the segment, which contains the `gLife` variable. Flags of this segment and its size are available in the "Memory map" window of OllyDbg debugger. This is a table with meaning of the segment's flags that are provided by OllyDbg:

| Parameter | OllyDbg value | WinAPI value | Description |
| -- | -- | -- | -- |
| Type | Img | [MEM_IMAGE](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366775%28v=vs.85%29.aspx) | Indicates that the memory pages within the region are mapped into the view of an executable image. |
| Access | RW | [PAGE_READWRITE](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366786%28v=vs.85%29.aspx) | Enables read-only or read/write access to the committed region of pages. |

Also all segments, which are related to an executable image, have MEM_COMMIT state flag. It means that virtual memory of this segment has been commited. OS stores data of the segment either in physical memory or on disk.

This is an algorithm to test the bot application:

1. Launch the test application.
2. Launch the bot application with administrator privileges.
3. Switch to the test application window.
4. Wait untill life parameter becomes less than 10.

You will see that the bot application overwrites value of the life parameter.

## Approaches Against Investigation

### WinAPI for Debugger Detection

The most simple and straightforward way to protect your application against debugging is usage of the [`IsDebuggerPresent`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms680345%28v=vs.85%29.aspx) WinAPI function.

This is a first way to protect `TestApplication.cpp` with the `IsDebuggerPresent` function:
```C++
int main()
{
	if (IsDebuggerPresent())
	{
		printf("debugger detected!\n");
		exit(EXIT_FAILURE);
	}

	// Rest function is the same as in TestApplication.cpp
}
```
Here we have added a checking to debugger presence at the beginning of the `main` function. The application is terminated by the [`exit`](http://www.cplusplus.com/reference/cstdlib/exit/) function in case the debugger is detected.

This way of usage `IsDebuggerPresent` function is not effective in most cases. Yes, it detects the debugger at application startup. It means that now you cannot launch OllyDbg debugger and open "TestApplication" binary to start its execution. But you still have a possibility to attach the debugger to the already running "TestApplication" process. The debugger is not detected in this case because the `IsDebuggerPresent` checking has already happened.

This is a second way to protect `TestApplication.cpp` with the `IsDebuggerPresent` function:
```C++
int main()
{
	SHORT result = 0;

	while (gLife > 0)
	{
		if (IsDebuggerPresent())
		{
			printf("debugger detected!\n");
			exit(EXIT_FAILURE);
		}

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
Now the `IsDebuggerPresent` checking happens regularly in the main loop of our test application. Now OllyDbg debugger is detected even in case it is attached to the application.

Let us consider ways to avoid this kind of debugger detection. First way is to modify register's value at the moment of checking condition in the `if` statement. This allows you to change result of this checking and to avoid an application termination.

This is an algorithm to modify the register's value:

1\. Launch OllyDbg debugger and open the "TestApplication.exe" binary to start its debugging.

2\. Press the *Ctrl+N* key to open the "Names in TestApplication" window. There is a [symbol table](https://en.wikipedia.org/wiki/Symbol_table) of TestApplication in this window.

3\. Start to type the "IsDebuggerPresent" function name to search it in the "Names in TestApplication" window. 

4\. Select by left click the "&KERNEL32.IsDebuggerPresent" symbol name.

5\. Press *Ctrl+R* to find references to this symbol name. You will see the "Search - References to..." dialog. There is a list of places where the "&KERNEL32.IsDebuggerPresent" symbol name is used in the code of TestApplication.

6\. Select by left click the first item in the "Search - References to..." dialog. Now a cursor in the disassembler sub-window points to the place of `main` function where the `IsDebuggerPresent` function is called.

7\. Select by left click the `TEST EAX,EAX` instruction, which follows the `IsDebuggerPresent` function call. Press *F2* key to set a breakpoint on this instruction.

8\. Continue execution of the TestApplication by *F9* key. The execution will be stopped at our breakpoint.

9\. Set to zero a value of `EAX` register in the "Registers (FPU)" sub-window. You should double click on the value of `EAX` register to open "Modify EAX" dialog. Then Type value "0" to the "Signed" row of the "EAX" column. Press the "Ok" button after it:

![Modify EAX Register](register-modify-ollydbg.png)

10\. Continue execution of the TestApplication by *F9* key.

You will see that the debugger has not been detected after these actions. But there is the same checking for debugger present on the next iteration of the `while` loop. This means that you should repeat described algorithm each time when the checking happens.

Another way to avoid the debugger detection is to make permanent patch of TestApplication binary. This is an algorithm:

1\. Launch OllyDbg debugger and open the "TestApplication.exe" binary to start its debugging.

2\. Find a place of the "IsDebuggerPresent" function call in code of TestApplication with the "Names in TestApplication" window and "Search - References to..." dialog.

3\. Select by left click the `JE SHORT 01371810` instruction, which follows the `IsDebuggerPresent` function call and the `TEST EAX,EAX` instruction. Press *Space* key to edit selected instruction.

4\. Change the `JE SHORT 01371810` instruction to the `JNE SHORT 01371810` one in the "Assemble" dialog. Then press the "Assmble" button:

![Hack the TestAppliction](byte-hack-ollydbg.png)

5\. Continue execution of the TestApplication by *F9* key.

OllyDbg debugger will not be detected after this. What our change of the [`JE`](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Jump_on_Equality) instruction to [`JNE`](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Jump_on_Inequality) one means? Actually, we inverted logic of this `if` condition in the `TestApplication.cpp` source file:
```C++
		if (IsDebuggerPresent())
		{
			printf("debugger detected!\n");
			exit(EXIT_FAILURE);
		}
```
The condition becomes look like this after our patch:
```C++
		if ( ! IsDebuggerPresent())
		{
			printf("debugger detected!\n");
			exit(EXIT_FAILURE);
		}
```
You see that now we get the "debugger detected!" message in case the debugger is not detected. Otherwise, the execution of TestApplication is continued. We just hack this checking and it becomes broken in the suitable for us way.

There is a [OllyDumpEx](http://low-priority.appspot.com/ollydumpex/) plugin for OllyDbg debugger that allows you to save modified binary file. There is an algorithm to install OllyDbg plugins:

1. Download an archive with a plugin from the developer's website.
2. Unpack the archive to the OllyDbg directory. This is a default path to this directory in my case `C:\Program Files (x86)\odbg200`.
3. Check the configuration of plugins directory in the "Options" dialog of OllyDbg. Select the "Options"->"Options..." item of the main menu to open this dialog. Then, choose the "Directories" item of the tree control on left side of the dialog. "Plugin directory" field should be equal to the installation path of OllyDbg (for example "C:\Program Files (x86)\odbg200").
4. Restart OllyDbg debugger.

You will see new item of the main menu with "Plugins" label. There are steps to save modified binary file:

1. Select the "Plugins"->"OllyDumpEx"->"Dump process" item. You will see the "OllyDumpEx" dialog.
2. Press the "Dump" button. You will see the "Save Dump to File" dialog.
3. Select a path in this dialog.

After these actions the binary file is saved on you hard drive. You can launch the saved binary file. It should work correctly for simple applications like our TestApplication one. But it is probable that a saved binary will crash on the launch step in case of such complex applications as video games.

Both methods to avoid the protection, which is based on usage of the `IsDebuggerPresent` function, are described in details in this [artice](https://www.aldeid.com/wiki/IsDebuggerPresent).

There is another WinAPI function with [`CheckRemoteDebuggerPresent`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms679280%28v=vs.85%29.aspx) name, which allows you to detect a debugger. Primary advantage of this function is possibility to detect debugging of another process. This approach is quite useful for implementation external protection system, which should work in a separate process.

The `CheckRemoteDebuggerPresent` function internally calls the [`NtQueryInformationProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684280%28v=vs.85%29.aspx) WinAPI function. This `NtQueryInformationProcess` function provides detailed information about the specified process. One of the function's options is to get information about debugging of the specified process. There is an issue with usage of the `NtQueryInformationProcess` function directly. WinAPI does not provide an import library for this function. Therefore, you should use the `LoadLibrary` and `GetProcAddress` functions to dynamically link to `ntdll.dll` library, which contains implementation of the `NtQueryInformationProcess`. There is a detailed [article](http://www.codeproject.com/Articles/19685/Get-Process-Info-with-NtQueryInformationProcess) with demonstartion of this approach.

Third protection approach is to use the [`CloseHandle`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms724211%28v=vs.85%29.aspx) WinAPI function. This function generates the EXCEPTION_INVALID_HADNLE exception in case the input handle parameter is invalid or you are trying to close the same handle twice. This means that behavior of the function depends on the debugger presence. This a code snippet to distinguish this behavior:
```C++
BOOL IsDebug()
{
	__try
	{
		CloseHandle((HANDLE)0x12345);
	}
	__except (GetExceptionCode() == EXCEPTION_INVALID_HANDLE ?
		EXCEPTION_EXECUTE_HANDLER : EXCEPTION_CONTINUE_SEARCH)
	{
		return TRUE;
	}
	return FALSE;
}
```
You can see that the [try-except statement](https://msdn.microsoft.com/en-us/library/s58ftw19.aspx) is used here. This is not a C++ standard statement. This is a Microsoft extension for both C and C++ languages that is part of [Structured Exception Handling](https://msdn.microsoft.com/en-us/library/windows/desktop/ms680657%28v=vs.85%29.aspx) (SEH) mechanism.

Now you can substitute a call of `IsDebuggerPresent` WinAPI function to the `IsDebug` one in our test application. Launch the application after this modification under debugger. You will see that this check does not detect the OllyDbg. But it detects WinDbg debugger correctly. This happens because OllyDbg uses technique to avoid this kind of debugger detection.

Another case of this protection approach is usage of [`DebugBreak`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms679297%28v=vs.85%29.aspx) WinAPI function:
```C++
BOOL IsDebug()
{
	__try
	{
		DebugBreak();
	}
	__except (GetExceptionCode() == EXCEPTION_BREAKPOINT ?
		EXCEPTION_EXECUTE_HANDLER : EXCEPTION_CONTINUE_SEARCH)
	{
		return FALSE;
	}
	return TRUE;
}
```
This function always generates the breakpoint exception. If the application is debugged, this exception is handled by a debugger. This means that we will not fall to the `__except` block. If there is no debugger, our application catches an exception and makes conclusion that there is no debugger. The `DebugBreak` function has an alternative variant with [`DebugBreakProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms679298%28v=vs.85%29.aspx) name, which allows you to check another process.

TODO: Describe the Self-debugging approach.

TODO: Write about disadvantages of all WinAPI functions. It is easy to detect them via the executable's import tables.

TODO: Make a table with anti-debugging approach names and user/kernel debugger mode detection.

TODO: Consider anti-debugging and anti-reversing approaches here.

TODO: This is a list of OllyDbg plugins to hide the debugger:
https://www.virusbulletin.com/virusbulletin/2009/05/anti-unpacker-tricks-part-six#id4810837

### CPU Registers Manipulation

TODO: Describe a way to improve WinAPI approach. Use a direct PEB analysis instead. Primary advantage of this approach is more difficult search of protection code and `if` conditions in application's source code.

TODO: Describe how to change the debugging byte in PEB  via OllyDbg to avoid the IsDebuggerPresent based protections.

TODO: Give a link to article with techniques and neutralization:
http://www.codeproject.com/Articles/1090943/Anti-Debug-Protection-Techniques-Implementation-an

TODO: Make a scheme about approaches against Ring 0 and Ring 3 debuggers.

## Approaches Against Bots

TODO: Consider approaches to protect application memory here.

## Summary
