# Protection Approaches

We have considered an example to develop in-game bot for Diablo 2 game. Now we will explore methods to protect a game application from these bots. Let us split protection methods into two groups:

1. Methods to prevent analysis and reverse engineering of the game application.
2. Methods against algorithms of in-game bots.

First group is well known methods that allow you to make it complicate to debug application and explore its memory. Second group of methods allows you to violate a normal work of bot applications. Some of these methods are able to be refer to both groups.

## Test Application

Most of the protection approaches against in-game bots should be implemented inside the game application. It is possible to take already existed game application and make separate protection system for it. But this approach requires more efforts and time. I suggest to write a simple application that emulates some game model. Also we can develop a primitive in-game bot that controls our test application. Then we will add specific protection features to this application and test them.

This is an algorithm of the test application:

1. Set a maximum value of the life parameter.
2. Check a state of the *1* keyboard key every second in a loop.
3. Decrement the life value in case the key is not pressed. Otherwise, increment the value.
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
You can see that the life parameter is stored in a global variable with the `gLife` name. After initialization the value equals to the `MAX_LIFE` constant, i.e. 20. State of a keyboard key is checked in the `while` loop. We use the [`GetAsyncKeyState`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646293%28v=vs.85%29.aspx) WinAPI function to read key states. The `GetAsyncKeyState` function has only one input parameter, which defines the key to check. The parameter equals to the `0x31` virtual-key code. This code matches to the key *1*. If this key is not pressed, we decrement the life value. Otherwise, we increment this value. One second delay before the next reading of a key state is performed by the `Sleep` WinAPI function.

You can compile TestApplication in the "Debug" configuration and launch it for testing.

### Analysis of Test Application

Now we are ready to develop an in-game bot for our test application. I suggest you to implement the same algorithm for this bot as we have done in [Example with Diablo 2](example.md) section. The bot should increase a life parameter in case its value becomes less than 10.

Let us analyze, where a life parameter is stored in the test application's memory. This application is quite simple and short. Therefore, we can use OllyDbg only to consider its internals. 

This is an algorithm to analyze our test application:

1\. Launch OllyDbg debugger. Open the "TestApplication.exe" binary in the "Select 32-bit executable" dialog. This dialog is available by *F3* key. When the binary has been loaded, you see a start point of the application execution in the sub-window with disassembled code.

2\. Press the *Ctrl+G* key to open the "Enter expression to follow" dialog.

3\. Type a name of the `main` function into the "Enter address expression" field. Full name of this function equals to the "TestApplication.main" in our case. Then press the "Follow expression" button. Now a cursor in the disassembler sub-window points to the first instruction of the `main` function.

4\. Set a breakpoint on this instruction by pressing the *F2* key.

5\. Start an execution of the test application by *F9* key press. The execution will stop on our breakpoint. The window of OllyDbg should look like this:

![Test Application Ollydbg](test-application-ollydbg.png)

6\. Click by left button on this line of disassembled code:
```
MOV AX,WORD PTR DS:[gLife]
```
The cursor is placed on this line in the screenshoot. Select the "Follow in Dump"->"Memory address" item in the pop-up menu. Now the cursor of the memory dump sub-window is placed on the `gLife` variable. The variable equals to "14" in hexadecimal. An address of the variable equals to "329000" in my case.

7\. Open the "Memory map" window by *Alt+M* key press.

8\. Find a memory segment which contains the `gLife` variable. It should be a ".data" segment of the "TestApplication" module:

![Test App Segment Ollydbg](testapp-segment-ollydbg.png)

Now we know where the `gLife` variable is stored. Address of the this variable equals to the base address of the ".data" segment. It happens because there is the `gLife` variable only in this segment.

### Bot for Test Application

This is detailed bot's algorithm for our test application:

1. Enable the `SE_DEBUG_NAME` privilege for current process.
2. Open the test application process.
3. Search the memory segment that contains the `gLife` variable.
4. Read a value of this variable in a loop. Write 20 value to the `gLife` variable in case it becomes less than 10.

This is a source code of the [`SimpleBot.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/SimpleBot.cpp) application:
```C++
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
Key difference of this application from the bot for Diablo 2 game is an algorithm of the `ScanSegments` function. Now we can distinguish the segment, which contains the `gLife` variable. Flags of this segment and its size are available in the "Memory map" window of OllyDbg debugger. This is a table with meaning of the segment's flags, which are provided by OllyDbg:

| Parameter | OllyDbg value | WinAPI value | Description |
| -- | -- | -- | -- |
| Type | Img | [MEM_IMAGE](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366775%28v=vs.85%29.aspx) | Indicates that the memory pages within the region are mapped into the view of an executable image. |
| Access | RW | [PAGE_READWRITE](https://msdn.microsoft.com/en-us/library/windows/desktop/aa366786%28v=vs.85%29.aspx) | Enables read-only or read/write access to the committed region of pages. |

Also all segments, which are related to an executable image, have the MEM_COMMIT state flag. It means that virtual memory of this segment has been committed. OS stores data of the segment either in physical memory or on a disk.

This is an algorithm to launch our bot:

1. Launch the TestAplication.
2. Launch the bot executable with administrator privileges.
3. Switch to a window of the TestAplication.
4. Wait until life parameter becomes less than 10.

You will see that the bot overwrites value of the life parameter when its value becomes less than 10.

## Approaches Against Analysis

### WinAPI for Debugger Detection

The simplest and straightforward way to protect your application against debugging is usage of the [`IsDebuggerPresent`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms680345%28v=vs.85%29.aspx) WinAPI function.

This is the first try to protect TestApplication with the `IsDebuggerPresent` function:
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
Here we have added a check to debugger presence at the beginning of the `main` function. The application is terminated by the [`exit`](http://www.cplusplus.com/reference/cstdlib/exit/) function in case a debugger is detected.

This way of usage `IsDebuggerPresent` function is not effective in most cases. Yes, it detects the debugger at application startup. This means that now you cannot launch OllyDbg debugger and open TestApplication binary to start its execution. But you still have a possibility to attach the debugger to the already running TestApplication process. The debugger is not been detected in this case because the `IsDebuggerPresent` check has already happened.

This is a `main` function of the [`IsDebuggerPresent.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/IsDebuggerPresent.cpp) application, which implements the second way of usage the `IsDebuggerPresent` function:
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
Now the `IsDebuggerPresent` check happens regularly in the `while` loop. OllyDbg debugger is detected even in case it is attached to the application after its launch.

Let us consider ways to avoid this kind of debugger detection. The first way is to modify a value of the CPU register at the moment when a condition of the `if` statement is checked. This allows you to change the result of this check and to avoid an application termination.

This is an algorithm to modify a value of the CPU register:

1\. Launch OllyDbg debugger and open the "TestApplication.exe" binary to start its debugging.

2\. Press the *Ctrl+N* key to open the "Names in TestApplication" window. This window contains a [symbol table](https://en.wikipedia.org/wiki/Symbol_table) of TestApplication.

3\. Start to type the "IsDebuggerPresent" function name to search it in the "Names in TestApplication" window. 

4\. Select by left click the "&KERNEL32.IsDebuggerPresent" symbol name.

5\. Press *Ctrl+R* to find references to this symbol name. You will see the "Search - References to..." dialog. There is a list of places where the "&KERNEL32.IsDebuggerPresent" symbol name is used in the code of TestApplication.

6\. Select by left click the first item in the "Search - References to..." dialog. Now a cursor in the disassembler sub-window points to the place of `main` function where the `IsDebuggerPresent` function is called.

7\. Select by left click the `TEST EAX,EAX` instruction that follows the `IsDebuggerPresent` function call. Press *F2* key to set a breakpoint on this instruction.

8\. Continue execution of the TestApplication by *F9* key. The execution will be stopped at our breakpoint.

9\. Set to zero a value of `EAX` register in the "Registers (FPU)" sub-window. You should double click on the value of `EAX` register to open "Modify EAX" dialog. Then type value "0" in the "Signed" row of the "EAX" column. Press the "Ok" button after it:

![Modify EAX Register](register-modify-ollydbg.png)

10\. Continue execution of the TestApplication by *F9* key.

You will see that a debugger is not detected after modification of the CPU register. But the same check for debugger will happen on the next iteration of the `while` loop. This means that you should repeat described actions on each iteration.

Another way to avoid the debugger detection is to make a permanent patch of the TestApplication code, which is already loaded in memory. This is an algorithm to do it:

1\. Launch OllyDbg debugger and open the "TestApplication.exe" binary to start its debugging.

2\. Find a place where the "IsDebuggerPresent" function is call.

3\. Select by left click the `JE SHORT 01371810` instruction, which follows a call of the `IsDebuggerPresent` function and the `TEST EAX,EAX` line. Press *Space* key to edit selected instruction.

4\. Change the `JE SHORT 01371810` line to the `JNE SHORT 01371810` one in the "Assemble" dialog. Then press the "Assemble" button:

![Hack the TestApplication](byte-hack-ollydbg.png)

5\. Continue execution of the TestApplication by *F9* key.

OllyDbg debugger is not detected after this patch. What does our change of the [`JE`](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Jump_on_Equality) line to the [`JNE`](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Jump_on_Inequality) one mean? Actually, we have inverted the logic of this `if` condition:
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
Now the "debugger detected!" message is printed when the debugger absents. Otherwise, the execution of TestApplication is continued. We just hacked this check and it becomes broken in the suitable for us way.

There is a [OllyDumpEx](http://low-priority.appspot.com/ollydumpex/) plugin for OllyDbg debugger, which allows you to save a modified code back to the binary file. This is an algorithm to install OllyDbg plugins:

1. Download an archive with a plugin from the developer's website.
2. Unpack the archive to the OllyDbg directory. Default path to this directory equals to "C:\Program Files (x86)\odbg200" in my case.
3. Check the configuration of plugins directory in the "Options" dialog of OllyDbg. Select the "Options"->"Options..." item of the main menu to open this dialog. Then, choose the "Directories" item of a tree control on the left side of the dialog. The "Plugin directory" field should be equal to your installation path of OllyDbg (for example "C:\Program Files (x86)\odbg200").
4. Restart OllyDbg debugger.

You will see new item of the main menu with the "Plugins" label. There are steps to save modified code:

1. Select the "Plugins"->"OllyDumpEx"->"Dump process" item. You will see the "OllyDumpEx" dialog.
2. Press the "Dump" button. You will see the "Save Dump to File" dialog.
3. Select the path to saved binary in this dialog.

After these actions the binary file is saved on you hard drive. You can launch this file again. It should work correctly for simple applications like our TestApplication one. But it is probable that a saved binary will crash on the launch step in case of such complex applications as video games.

There is another WinAPI function with [`CheckRemoteDebuggerPresent`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms679280%28v=vs.85%29.aspx) name, which allows you to detect a debugger. Primary advantage of this function is a possibility to detect debugging of another process. This feature is quite useful when your goal is implementation of external protection system, which should work separately from a game application.

The `CheckRemoteDebuggerPresent` function internally calls the [`NtQueryInformationProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684280%28v=vs.85%29.aspx) WinAPI function, which provides detailed information about the specified process. Debugging state of the process is contained in this information.

The third protection approach is to use the [`CloseHandle`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms724211%28v=vs.85%29.aspx) WinAPI function. This function generates the EXCEPTION_INVALID_HADNLE in case the specified handle is invalid or you are trying to close the same handle twice. This exception is generated only when the application is launched under a debugger. Otherwise, the error value is returned. This means that behavior of this function depends on the debugger presence. This is a code snippet, which allows us to distinguish this behavior:
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
You can see that the [try-except statement](https://msdn.microsoft.com/en-us/library/s58ftw19.aspx) is used here. This is not a C++ standard statement. This is a Microsoft extension for both C and C++ languages, which is part of [Structured Exception Handling](https://msdn.microsoft.com/en-us/library/windows/desktop/ms680657%28v=vs.85%29.aspx) (SEH) mechanism.

Now you can substitute a call of `IsDebuggerPresent` WinAPI function to the `IsDebug` one in the TestApplication. The source code of this modification is available in the [`CloseHandle.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/CloseHandle.cpp) file. If you launch this application under OllyDbg, you will see that the debugger is not detected. But the WinDbg is detected correctly. This happens because OllyDbg uses technique to avoid this kind of debugger detection.

Another variation of this protection approach is to use the [`DebugBreak`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms679297%28v=vs.85%29.aspx) WinAPI function. This is a modified version of the `IsDebug` function:
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
Full code of this example is available in the [`DebugBreak.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/DebugBreak.cpp) file.

The `DebugBreak` function always generates a breakpoint exception. If the application is debugged, this exception is handled by a debugger. This means that we will not reach to the `__except` block. If there is no debugger, our application catches the exception and makes conclusion that there is no debugger. This approach detects correctly both OllyDbg and WinDbg debuggers. The `DebugBreak` function has an alternative variant with [`DebugBreakProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms679298%28v=vs.85%29.aspx) name, which allows you to check another process.

The fourth protection approach, which we will consider, is a self-debugging. There is a limitation of Windows OS that only one debugger can be attached to the process at the same time. Therefore, if our test application starts to debug self, nobody else can do it.

This technique is based on creating a child process by the [`CreateProcess`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms682425%28v=vs.85%29.aspx) WinAPI function. Then there are two possibilities. The first is a child process debugs the parent one. In this case all work of TestApplication happens in the parent process. This approach is described in this [article](http://www.codeproject.com/Articles/30815/An-Anti-Reverse-Engineering-Guide#SelfDebugging). The second way is a parent process debugs the child one. In this case the child process does all work of TestApplication. We will consider an example of the second case.

This is a source code of the [`SelfDebugging.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/SelfDebugging.cpp) application, which demonstrates the self-debugging approach:
```C++
#include <stdint.h>
#include <windows.h>
#include <string>

using namespace std;

static const uint16_t MAX_LIFE = 20;
static uint16_t gLife = MAX_LIFE;

void DebugSelf()
{
	wstring cmdChild(GetCommandLine());
	cmdChild.append(L" x");

	PROCESS_INFORMATION pi;
	STARTUPINFO si;
	ZeroMemory(&pi, sizeof(PROCESS_INFORMATION));
	ZeroMemory(&si, sizeof(STARTUPINFO));
	GetStartupInfo(&si);

	CreateProcess(NULL, (LPWSTR)cmdChild.c_str(), NULL, NULL, FALSE,
		DEBUG_PROCESS | CREATE_NEW_CONSOLE, NULL, NULL, &si, &pi);

	DEBUG_EVENT de;
	ZeroMemory(&de, sizeof(DEBUG_EVENT));

	for (;;)
	{
		if (!WaitForDebugEvent(&de, INFINITE))
			return;

		ContinueDebugEvent(de.dwProcessId,
			de.dwThreadId,
			DBG_CONTINUE);
	}
}

int main(int argc, char* argv[])
{
	if (argc == 1)
	{
		DebugSelf();
	}
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
This is a scheme, which demonstrates a relationship between the parent and child processes:

![Self-Debugging Scheme](self-debugging.png)

TestAplication is launched indirectly in this example. You should start the "TestApplication.exe" executable without any command line parameters. Then this checking of the command line arguments number happens:
```C++
	if (argc == 1)
	{
		DebugSelf();
	}
```
Now there is only one command line argument, which equals to the executable name ("TestApplication.exe"). Therefore, the `DebugSelf` function is called. Three actions are performed in this function:

1. Add an extra "x" parameter to the command line of the current process:
```C++
	wstring cmdChild(GetCommandLine());
	cmdChild.append(L" x");
```
This parameter allows child process to distinguish that it should perform an actual work.

2. Create a child process in debugging mode with the `CreateProcess` WinAPI function. The `DEBUG_PROCESS` flag of this function allows you to debug the child process. The extra `CREATE_NEW_CONSOLE` flag is used here to create separate console for the child process. This console allows you to get output messages from the child.

3. Start an infinite loop to receive all debug events from the child process.

You can launch the SelfDebugging application and try to debug it. OllyDbg and WinDbg debuggers cannot attach to this application. Our example just demonstrates the self-debugging approach. This is quite simple to avoid the protection. You can launch "TestApplication.exe" executable from the command line with one extra parameter:
```
TestApplication.exe x
```
The application starts normally and you can debug it.

You should not rely on a number of command line arguments in your applications. Instead for example, you should use an algorithm to generate the random key. Then child process receives this key via command line and checks its correctness with the same algorithm. But more secure approaches against an unauthorized application launch rely on [interprocess communication](https://msdn.microsoft.com/en-us/library/windows/desktop/aa365574%28v=vs.85%29.aspx) mechanisms, which are provided by WinAPI.

### Registers Manipulation for Debugger Detection

Primary disadvantage of anti-debugging approaches, which are based on WinAPI calls, is ease to detect them in application's code. When you find these calls, it is quite simple to manipulate the `if` condition that checks debugger presence.

There are several anti-debugging approaches that are based on CPU registers manipulation. You are able to access these registers directly via [inline assembler](https://en.wikipedia.org/wiki/Inline_assembler). Usage of inline assembler makes it more difficult to find checkpoints of debugger presence. 

Let us consider internals of the `IsDebuggerPresent` WinAPI function. These are steps that allows you to analyze this function:

1. Launch the OllyDbg debugger.

2. Open the "TestApplication.exe" binary, which is protected by the `IsDebuggerPresent` function.

3. Find the place where the `IsDebuggerPresent` function is called. Make a breakpoint on this call and continue an execution.

4. When the process stops by the breakpoint, press the *F7* button to make a step into the `IsDebuggerPresent` function.

You will see an assembler code of this function in the disassembler sub-window of OllyDbg:

![IsDebuggerPresent internals](is-debugger-present.png)

Let us consider each line of the `IsDebuggerPresent` function:

1. Read a linear address of the TEB segment, which matches to the current active thread, into the `EAX` register. The `FS` register always points to the TEB segment. The `0x18` hexadecimal offset in the TEB segment matches to its linear address.

2. Read a linear address of the PEB segment to the `EAX` register. The `0x30` hexadecimal offset in the TEB segment matches to PEB segment's linear address.

3. Read a value with `0x2` offset from the PEB segment to the `EAX` register. This value matches to the BeingDebugged flag, which detects the debugger presence.

4. Return from the function.

Now we have enough information to repeat an algorithm of the `IsDebuggerPresent` function in TestApplication:
```C++
int main()
{
	SHORT result = 0;

	while (gLife > 0)
	{
		int res = 0;
		__asm
		{
			mov eax, dword ptr fs:[18h]
			mov eax, dword ptr ds:[eax+30h]
			movzx eax, byte ptr ds:[eax+2h]
			mov res, eax
		};
		if (res)
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
Here we repeat each step of the `IsDebuggerPresent` function in the inline assembler code. The result of these assembler commands is saved in the `res` variable. The value of this variable allows us to detect a debugger.

There are several approaches to avoid duplication of assembler code. It is not recommended to move this code into regular C++ function. This is quite easy to find calls of specific function in the application code. First approach to move assembler code into a function securely is to use the [`__forceinline`](https://msdn.microsoft.com/en-us/library/bw1hbe6y.aspx) keyword. This keyword force compiler to insert function's body into each place where the function is called. But this mechanism works only in the "Release" configuration of the application build. The `__forceinline` is ignored in several cases:

1. The "Debug" build configuration is used.
2. The inline function has recursive calls.
3. The inline function calls the [`alloca`](https://msdn.microsoft.com/en-us/library/wb1s57t5.aspx)WinAPI function.

Second solution is to use [preprocessor macro](http://www.cplusplus.com/doc/tutorial/preprocessor). Macro body is inserted in each place where the macro identifier is used in the source code. This behavior does not depend on configuration of the build.

This is an example of checking the BeingDebugged flag with a macro:
```C++
#define CheckDebug() \
int isDebugger = 0; \
{ \
__asm mov eax, dword ptr fs : [18h] \
__asm mov eax, dword ptr ds : [eax + 30h] \
__asm movzx eax, byte ptr ds : [eax + 2h] \
__asm mov isDebugger, eax \
} \
if (isDebugger) \
{ \
printf("debugger detected!\n"); \
exit(EXIT_FAILURE); \
}

int main()
{
	SHORT result = 0;

	while (gLife > 0)
	{
		CheckDebug()
		...
	}

	printf("stop\n");

	return 0;
}
```
Full code of this example is available in the [`BeingDebugged.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/BeingDebugged.cpp) file.

You can avoid this kind of debugger detection by changing the BeingDebugged flag manually. This is an algorithm to do it with OllyDbg:

1. Launch the OllyDbg debugger.

2. Open the "TestApplication.exe" binary, which is protected by the BeingDebugged flag checking.

3. Press the *Alt+M* key to open a memory map of the TestApplication process. Find the "Process Environment Block" segment in this window. 

5. Double left-click on this segment. You will see "Dump - Process Environment Block" window. Find the "BeingDebugged" flag value in this window.

6. Left click on the "BeingDebugged" flag to select it. Press *Ctrl+E* to open "Edit data at address..." dialog.

7. Change a value in the "HEX+01" field from "01" to "00" and tress the "OK" button:

![Change the BeingDebugged flag](beingdebugged-ollydbg.png)

Now you can continue execution of the TestApplication process. The debugger presence is not detected anymore.

The `DebugBreak` WinAPI function is able to be substituted by assembler instructions too. You can use the same approach, as we have used for `IsDebuggerPresent` function, to analyze internals of the `DebugBreak` one. The [`INT 3`](https://en.wikipedia.org/wiki/INT_%28x86_instruction%29#INT_3) instruction is used there.

This is an alternative variant of the `IsDebug` function, which is based on usage of the `INT 3` instruction:
```C++
BOOL IsDebug()
{
	__try
	{
		__asm int 3;
	}
	__except (GetExceptionCode() == EXCEPTION_BREAKPOINT ?
		EXCEPTION_EXECUTE_HANDLER : EXCEPTION_CONTINUE_SEARCH)
	{
		return FALSE;
	}
	return TRUE;
}
```
We can use `__forceinline` keyword to hide calls of the `IsDebug` function. But this keyword does not have any effect in this case. It happens because the `__try`/`__except` exception handler operates in own memory frame and uses the `alloca` WinAPI function implicitly. This prevent compiler to insert function's body to the caller code. Alternative solution is to move this check to the macro:
```C++
#define CheckDebug() \
bool isDebugger = true; \
__try \
{ \
	__asm int 3 \
} \
__except (GetExceptionCode() == EXCEPTION_BREAKPOINT ? \
		  EXCEPTION_EXECUTE_HANDLER : EXCEPTION_CONTINUE_SEARCH) \
{ \
	isDebugger = false; \
} \
if (isDebugger) \
{ \
	printf("debugger detected!\n"); \
	exit(EXIT_FAILURE); \
}
```
Full code of this example is available in the [`Int3.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/Int3.cpp) file.

You can avoid this protection by inverting the `if` condition logic. But the most difficult task now is to find these `if` conditions. OllyDbg debugger provides the feature to search specific assembler instruction. You can press *Ctrl+F* key in the disassembler sub-window and type the `INT3` value into the dialog's field. When you press the "Search" button, you get an instruction, which contains `0xCC` number in its opcode. This search procedure takes a lot of time for huge applications.

## Approaches Against Bots

Windows provides Security Descriptors (SD) mechanism, which allows you to restrict access for system objects (for example processes). This [article](https://helgeklein.com/blog/2009/03/permissions-a-primer-or-dacl-sacl-owner-sid-and-ace-explained/?PageSpeed=noscript) describes the SD mechanism in details. Also there are [first](http://www.cplusplus.com/forum/windows/96406/) and [second](http://stackoverflow.com/questions/6185975/prevent-user-process-from-being-killed-with-end-process-from-process-explorer/10575889#10575889) examples, which demonstrate how to protect your application with Discretionary Access Control List (DACL). But this SD mechanism is not able to protect your application against bots, which are run with administrator privileges.

You should implement algorithms to protect data of your application yourself. This is the most effective solution against in-game bots and memory scanners.

There are two tasks, which a reliable protection algorithm should solve:

1. Hide game data from memory scanners like Cheat Engine.
2. Check correctness of game data to prevent their unauthorized modification.

The simplest way to hide data from memory scanners is to store encrypted values of game objects' states. The simplest encryption algorithm is the [XOR cipher](https://en.wikipedia.org/wiki/XOR_cipher). This is a source code of the TestApplication, which is protected by XOR cipher ([`XORCipher.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/XORCipher.cpp)):
```C++
#include <stdint.h>
#include <windows.h>

using namespace std;

inline uint16_t maskValue(uint16_t value)
{
	static const uint16_t MASK = 0xAAAA;
	return (value ^ MASK);
}

static const uint16_t MAX_LIFE = 20;
static uint16_t gLife = maskValue(MAX_LIFE);

int main(int argc, char* argv[])
{
	SHORT result = 0;

	while (maskValue(gLife) > 0)
	{
		result = GetAsyncKeyState(0x31);
		if (result != 0xFFFF8001)
			gLife = maskValue(maskValue(gLife) - 1);
		else
			gLife = maskValue(maskValue(gLife) + 1);

		printf("life = %u\n", maskValue(gLife));
		Sleep(1000);
	}
	printf("stop\n");
	return 0;
}
```
The `maskValue` function encapsulates both encryption and decryption operations. We use the [XOR](https://en.wikipedia.org/wiki/Exclusive_disjunction) operation with predefined `MASK` constant to get an encrypted value. The `MASK` constant is a key of the cipher in this case. To decrypt the `gLife` we use the same `maskValue` function again. 

You can launch this XORCipher application and attach Cheat Engine scanner to it. Now the scanner has no possibility to find the `gLife` value in the memory. But this search task becomes trivial if you know the `MASK` value. You can calculate encrypted value of `gLife` manually and use Cheat Engine to find it.

Our implementation of the XOR cipher is just a demonstration of this approach. You should significantly improve it for usage in your application. First improvement is to encapsulate the protection algorithm in a template class with overloaded assignment and arithmetic operators. This allows you to make the encryption operations implicit. Second improvement is to generate a random cipher key in the constructor of the template class. This solution makes it difficult to decrypt protected values for attacker.

The XOR cipher approach solves only first task of data protection. It hides data from the memory scanners.

You can use more sophisticated cipher algorithms to protect application data. WinAPI provides a set of [cryptography functions](https://msdn.microsoft.com/en-us/library/windows/desktop/aa380252%28v=vs.85%29.aspx). This [article](http://www.codeproject.com/Articles/11578/Encryption-using-the-Win-Crypto-API) describes how to use RSA encryption with WinAPI.

This is a source code of the TestApplication, which is protected by RSA cipher ([`RSACipher.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/RSACipher.cpp)):
```C++
#include <stdint.h>
#include <windows.h>

using namespace std;

static BYTE PrivateKeyWithExponentOfOne[] =
{
	...
};

static const uint16_t MAX_LIFE = 20;
static uint16_t gLife = maskValue(MAX_LIFE);

HCRYPTPROV hProv;
HCRYPTKEY hKey;
HCRYPTKEY hSessionKey;

void CreateContex()
{
	DWORD dwResult;
	if (!CryptAcquireContext(&hProv, NULL, MS_DEF_PROV, PROV_RSA_FULL, 0))
	{
		dwResult = GetLastError();
		if (dwResult == NTE_BAD_KEYSET)
		{
			if (!CryptAcquireContext(&hProv,
				NULL, MS_DEF_PROV, PROV_RSA_FULL,
				CRYPT_NEWKEYSET))
			{
				dwResult = GetLastError();
				printf("Error: CryptAcquireContext() failed\n");
				return;
			}
		}
		else 
		{
			dwResult = GetLastError();
			return;
		}
	}
}

void CreateKeys()
{
	DWORD dwResult;
	if (!CryptImportKey(hProv, PrivateKeyWithExponentOfOne,
		sizeof(PrivateKeyWithExponentOfOne), 0, 0, &hKey))
	{
		dwResult = GetLastError();
		printf("Error CryptImportKey() failed\n");
		return;
	}
	if (!CryptGenKey(hProv, CALG_RC4, CRYPT_EXPORTABLE, &hSessionKey))
	{
		dwResult = GetLastError();
		printf("Error CryptGenKey() failed\n");
		return;
	}
}

void Encrypt()
{
	DWORD dwResult;
	unsigned long length = sizeof(gLife);
	unsigned char * cipherBlock = (unsigned char*)malloc(length);
	memset(cipherBlock, 0, length);
	memcpy(cipherBlock, &gLife, length);

	if (!CryptEncrypt(hSessionKey, 0, TRUE, 0, cipherBlock, &length, length))
	{
		dwResult = GetLastError();
		printf("Error CryptEncrypt() failed\n");
		return;
	}
	memcpy(&gLife, cipherBlock, length);
	free(cipherBlock);
}

void Decrypt()
{
	DWORD dwResult;
	unsigned long length = sizeof(gLife);
	unsigned char * cipherBlock = (unsigned char*)malloc(length);
	memset(cipherBlock, 0, length);
	memcpy(cipherBlock, &gLife, length);

	if (!CryptDecrypt(hSessionKey, 0, TRUE, 0, cipherBlock, &length))
	{
		dwResult = GetLastError();
		printf("Error CryptDencrypt() failed\n");
		return;
	}
	memcpy(&gLife, cipherBlock, length);
	free(cipherBlock);
}

int main(int argc, char* argv[])
{
	CreateContex();
	CreateKeys();
	
	gLife = MAX_LIFE;
	Encrypt();

	SHORT result = 0;
	while (true)
	{
		result = GetAsyncKeyState(0x31);

		Decrypt();
		if (result != 0xFFFF8001)
			gLife = gLife - 1;
		else
			gLife = gLife + 1;

		printf("life = %u\n", gLife);
		if (gLife == 0)
			break;

		Encrypt();
		Sleep(1000);
	}
	printf("stop\n");
	return 0;
}
```
This is an algorithm of the RSACipher application:

1. Create a context for a cryptographic algorithm by the `CreateContex` function. This function calls the [`CryptAcquireContext`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa379886%28v=vs.85%29.aspx) internally. Context is a combination of two components: key container and cryptographic service provider (CSP). Key container contains all keys belonging to a specific user. CSP is a software module, which provides a cryptographic algorithm.

2. Create cryptographic keys by the `CreateKeys` function. There are two actions in this function. The first is to import a public key with [`CryptImportKey`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa380207%28v=vs.85%29.aspx) WinAPI function. This key is stored in the `hKey` global byte array. You can use the [`CryptExportKey `](https://msdn.microsoft.com/en-us/library/windows/desktop/aa379931%28v=vs.85%29.aspx) WinAPI function to generate this byte array for your case. Second action is to generate private key with the [`CryptGenKey`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa379941%28v=vs.85%29.aspx) WinAPI function. Resulting private key is stored in the `hSessionKey` global variable. It will be used each time for encrypt and decrypt operations.

3. Initialize the `gLife` variable and encrypt it by the `Encrypt` function. This function calls [`CryptEncrypt`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa379924%28v=vs.85%29.aspx) internally.

4. Decrypt the `gLife` variable on each step of the `while` loop. Then update the `gLife` variable and encrypt it again. The `while` loop is interrupted when a value of the `gLife` variable equals to zero. The [`CryptDecrypt`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa379913%28v=vs.85%29.aspx) WinAPI function is used for decryption.

Primary advantage of RSA cipher approach is a reliable algorithm for encryption. Attacker need both public and private keys to decrypt protected data. You are able to keep private key in secret in some cases. But when your application is launched on attacker's local machine, he have full access to its memory. Therefore, he has both public and private keys. All that you can do is to complicate an access to these keys. For example, you can periodically change one of them randomly or by a command from server host. Also you can change a location of the keys in application memory periodically. Then it will be difficult to find them for bot application. Disadvantage of the RSA cipher against the XOR one is more time to encrypt and decrypt operations.

Now we will consider ways to protect game data from modification. Core idea of this protection is to duplicate data and compare them periodically. If data and their copy differs, the data is modified in unauthorized way. But this is quite simple to find a copy of data with a memory scanner because the copy has the same value as original. We can hide copied data thanks to encryption or [hashing](https://en.wikipedia.org/wiki/Hash_function).

This is a source code of the TestApplication with check for data modification ([`HashCheck.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/InGameBots/ProtectionApproaches/HashCheck.cpp)):
```C++
#include <stdint.h>
#include <windows.h>
#include <functional>

using namespace std;

static const uint16_t MAX_LIFE = 20;
static uint16_t gLife = MAX_LIFE;

std::hash<uint16_t> hashFunc;
static size_t gLifeHash = hashFunc(gLife);

void UpdateHash()
{
	gLifeHash = hashFunc(gLife);
}

__forceinline void CheckHash()
{
	if (gLifeHash != hashFunc(gLife))
	{
		printf("unauthorized modification detected!\n");
		exit(EXIT_FAILURE);
	}
}

int main(int argc, char* argv[])
{
	SHORT result = 0;
	while (gLife > 0)
	{
		result = GetAsyncKeyState(0x31);

		CheckHash();

		if (result != 0xFFFF8001)
			--gLife;
		else
			++gLife;

		UpdateHash();

		printf("life = %u\n", gLife);
		Sleep(1000);
	}
	printf("stop\n");
	return 0;
}
```
The `gLifeHash` variable stores a hashed value of the `gLife`. To calculate a hash we use the [`hash`](http://www.cplusplus.com/reference/functional/hash/) function, which is provided by STL since C++11 standard. The `CheckHash` function is called in each iteration of the `while` loop before modification of the `gLife` variable. In this function there are a calculation of hash for current `gLife` value and compare this hash with the stored one. If these two hashes differ, we can conclude that `gLife` value has been changed in unauthorized way. Otherwise, the `CheckHash` returns control back to the `main` function. After modification of the `gLife` value in the `while` loop iteration the `UpdateHash` function is called. The stored `gLifeHash` value is updated there.

You can compile and launch this TestApplication. If you try to modify the `gLife` variable via Cheat Engine, the application terminates.

It is possible to avoid this protection. Bot application should modify both `gLife` and `gLifeHash` values simultaneously. But there are two obstacles here. First issue is a moment when these values should be modified. If the bot modifies them, when they are compared in the `CheckHash` function, this check fails. Therefore, the modification will be detected. Second issue is how to find the hashed value. If you know the hash algorithm, you can calculate hash for current `gLife` value and find it with Cheat Engine. You should analyze the disassembled code of the application to determine used hash algorithm. Also you can manipulate with `if` condition in the `CheckHash` function to disable application termination. But this becomes difficult to find all these `if` conditions in case the `CheckHash` function is inline or it is implemented via macro.

The most effective way to prevent an unauthorized data modification is to store all game data on the server side. Client side receives these data for visualisation of current game state on the screen only. Modification of the client side data affects a screen picture and keeps server side data unchanged in this case. Therefore, the server always knows an actual state of game objects and can force clients to accept these data as authentic.

## Summary

We have considered approaches, which are based on WinAPI functions usage, to protect a game application from memory analysis with debuggers. Then we have considered ways to improve these approaches by usage CPU registers directly. This way allows us to hide our protection from attackers. Then methods to protect application from memory scanners and in-game bots have been considered.
