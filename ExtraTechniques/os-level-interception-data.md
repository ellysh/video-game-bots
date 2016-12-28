# OS Level Interception Data

This section is still under development.

## Tools

We will work with Windows API functions in this chapter. C++ language is the best choice for this task. We will use the [Visual Studio 2015 Community IDE](https://www.visualstudio.com/en-us/products/visual-studio-express-vs.aspx#) to compile our examples. More details about this IDE is available in the [In-game Bots](../InGameBots/tools.md) chapter.

There are several open source solutions to simplify hooking of WinAPI calls.

First solution is [DLL Wrapper Generator](https://m4v3n.wordpress.com/2012/08/08/dll-wrapper-generator/), which can help us to create proxy DLLs.

These are steps to install DLL Wrapper Generator:

1. Download scripts from the github [project page](https://github.com/mavenlin/Dll_Wrapper_Gen/archive/master.zip).

2. Download and install [Python 2.7 version](https://www.python.org/downloads/)

Now we are ready to work with DLL Wrapper Generator.

Second solution to hook WinAPI calls is [Deviare](http://www.nektra.com/products/deviare-api-hook-windows/) open source hooking engine.

These are steps to install Deviare software:

1. Download the last version of the [release binaries](https://github.com/nektra/Deviare2/releases/download/v2.8.0/Deviare.2.8.0.zip).

2. Download the latest version of the [source code](https://github.com/nektra/Deviare2/archive/v2.8.0.zip).

3. Unpack both archives in two different directories.

You can find a list of all available Deviare releases in the [github project](https://github.com/nektra/Deviare2/releases). Please, make sure that the version of binaries matches to the version of sources.

## Test Application

We will use almost the same application to test WinAPI calls hooking techniques as we used in the [protection against in-game bots](../InGameBots/protection.md) section.

This is a source code of the [`TestApplication.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ExtraTechniques/OSLevelInterceptionData/TestApplication.cpp):
```C++
#include <stdio.h>
#include <stdint.h>
#include <windows.h>
#include <string> 

static const uint16_t MAX_LIFE = 20;
volatile uint16_t gLife = MAX_LIFE;

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
        
        std::string str(gLife, '#');
        TextOutA(GetDC(NULL), 0, 0, str.c_str(), str.size());

        printf("life = %u\n", gLife);
        Sleep(1000);
    }
    printf("stop\n");
    return 0;
}
```
You can build the 32 bit version of this application and launch it.

Algorithm of this application stays the same. We decrement the `gLife` variable each second if the *1* keyboard key is not pressed. Otherwise, we increment the `gLife`. New feature of the application is a call of the `TextOutA` WinAPI function. This function prints the hash symbols in the upper-left corner of the screen. Count of printed symbols equals to the value of `gLife`.

Now our goal is to hook the `TextOutA` function call and to get its last parameter, which has the same value as the `gLife` variable. According to WinAPI documentation the `TextOutA` function is provided by the `gdi32.dll` library.

## DLL Import

Before we start to consider WinAPI hooking, it will be useful to know how application interacts with DLL libraries. When we start an application, Windows loader reads executable file into process memory. Typical Windows executable file has [**PE**](https://msdn.microsoft.com/en-us/library/ms809762.aspx) format. This format is a standard for data structures, which are stored in file's header. These structures contain necessary information to launch executable code by the Windows loader. List of required DLLs is a part of this information.

Next step of the loader is to find files of all required DLLs on a disk drive. These files are read into the process memory too. Now we face an issue. Locations of the DLL modules in a process memory are not constant. These locations can vary for different versions of the same DLL. Therefore, compiler cannot hardcode addresses of DLL functions in the executable module. This issue is solved by [**Import Table**](http://sandsprite.com/CodeStuff/Understanding_imports.html). There is some kind of confusion with Import Table and **Thunk Table**. Let us consider both these tables.

Each element of Import Table matches to one required DLL module. This element contains the name of the module, the `OriginalFirstThunk` pointer and the `FirstThunk` pointer. The `OriginalFirstThunk` points to the first element of the array with ordinal numbers and names of the imported functions. The `FirstThunk` points to the first element of the array (also known as **Import Address Table** or IAT), which is overwritten by Windows loader with actual addresses of the imported functions. And this is a source of confusion because both these arrays do not contain any stuff that is named [**thunk**](https://en.wikipedia.org/wiki/Thunk).

You can find more details about both `OriginalFirstThunk` and `FirstThunk` pointers [here](http://ntcore.com/files/inject2it.htm). 

Import Table is a part of PE header and it contains constant meta information about imported DLLs. This table together with PE header is stored in the read-only segment of the process memory. Thunk table (also known as a **jump table**) is a part of executable code and it contains `JMP` instructions to transfer control to the imported functions. This table is placed in the read and executable `.text` segment together with all other application code. Import Address Table is stored in the read and write `.idata` segment. The `.idata` segment also contains an array, which is pointed by the `OriginalFirstThunk` pointer. As you see all three tables are placed in different segments.

Some compilers generate a code, which does not use Thunk Table. This allows to avoid one extra jump and to get slightly more optimized solution. Code, which is generated by MinGW compiler, uses the Thunk Table. The scheme below illustrates a call of the `TextOutA` WinAPI function from this code:

![DLL call MinGW](dll-call-mingw.png)

This is an algorithm of the function call:

1. The `CALL` instruction performs two actions. It puts the return location to a stack and passes control to the Thunk Table element with the `40839C` address.

2. The Thunk Table element contains one `JMP` instruction only. This instruction uses actual address of the `TextOutA` function in the `gdi32` module from the Import Address Table record. The `DS` segment register, which points to the `.idata` segment, is used to calculate address of this record:
```
DS + 0x278 = 0x422000 + 0x278 = 0x422278
```
3. The `TextOutA` function from the `gdi32` module is executed. There is a `RETN` instruction at the end of this function. The `RETN` passes control to the next instruction after the `CALL` one in the EXE module. It happens because the `CALL` instruction put the return location to the stack.

The code, which is generated by Visual C++ compiler, does not use Thunk Table. The scheme illustrates a call of the same `TextOutA` WinAPI function in this case:

![DLL call Visual C++](dll-call-visual-cpp.png)

This is an algorithm of the function call:

1. The `CALL` instruction passes control to the `TextOutA` function in the `gdi32` module directly. Address of this function is taken from the Import Address Table record.

2. The `TextOutA` function is executed. Then the `RETN` instruction passes control back to the EXE module.

## API Hooking Techniques

Game application interacts with Windows via system DLLs. Such operations as displaying a text on the screen are performed by WinAPI functions. It is possible to get a state of the game objects by hooking calls to these functions. This approach reminds the output device capture. But now we can analyze data before it will come to the output device. This data can be a picture, sound, network packet or a set of bytes in the temporary file.

You can see how API hooking works by launching the [API Monitor](../ClickerBots/tools.md) tool. This tool prints the hooked calls in the "Summary" sub-window. We can implement a bot application that behaves in the similar way. But unlike the API Monitor the bot should simulate player actions instead of printing hooked calls.

Now we will consider most common API hooking techniques with examples.

### Proxy DLL

First approach to hook WinAPI calls is to substitute original Windows library. We can implement a library that looks like the original one for Windows loader point of view. Therefore, this library is loaded to the process memory during application launching. Then a game application interacts with the library in the same way as with the original one. This approach allows us to execute our code each time, when the game application calls a function from the WinAPI library. 

The library that can substitute original one is named **proxy DLL**.

We need to hook several specific WinAPI functions in most cases. All other functions of the substituted Windows library are not interesting for us. Also there is a requirement: game application should behave with a proxy DLL in the same manner as with the original library. Therefore, the proxy DLL should route function calls to the original library. The functions, which should be hooked, can contain a code of the bot application to simulate player actions or to gather state of the game objects. But the original WinAPI functions should be called after this code. We can make simple wrappers, which route to the original Windows library, for uninteresting for us functions. This means that the original library should be loaded in the process memory too. Windows loader do it automatically because the proxy DLL depends on the original library.

This scheme illustrates a call of the `TextOutA` WinAPI function via a proxy DLL:

![Proxy DLL](proxy-dll.png)

This is an algorithm of the function call:

1. Windows loader finds a proxy DLL instead of the Windows library. The Loader writes addresses of the functions, which are exported by the proxy DLL, to the Import Address Table of the EXE module.

2. Execution of the EXE module code reaches the `CALL` instruction. The record of Import Address Table is used to get an actual function address. Now this record contains an address of the proxy DLL function. The `CALL` instruction transfers control to the proxy DLL module.

3. Proxy DLL contains the Thunk Table. Addresses of its exported functions match to the thunks in this table. Therefore, the Thunk Table receives control from the `CALL` instruction of the executable module.

4. The `JMP` instruction of the thunk transfers control to the wrapper of the `TextOutA` WinAPI function, which is provided by proxy DLL. The wrapper contains bot's code.

5. The `CALL` instruction of the wrapper function passes control to the original `TextOutA` function of the `gdi32` module when the wrapper code is finished.

6. Original `TextOutA` function is executed. Then the `RETN` instruction transfers control back to the wrapper function.

7. The `RETN` instruction at the end of the `TextOutA` wrapper passes control back to the EXE module.

There is one question. How a proxy DLL knows the actual addresses of `gdi32` module's functions? We cannot delegate gathering of this addresses to the Windows loader. The problem is, proxy DLL should load the original Windows library from the specific path. It means that we should avoid a library searching mechanism of Windows loader. Therefore, we should load the original library manually with the [`LoadLibrary`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684175%28v=vs.85%29.aspx) WinAPI function. The [`GetProcAddress`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683212%28v=vs.85%29.aspx) function helps us to dynamically get actual addresses of its exported functions.

These are advantages of the proxy DLL approach:

1. Easy to generate proxy DLL with existing open source tools.

2. We substitute a Windows library for specific application only. All other launched applications still use original libraries.

3. It is difficult to protect application against this approach.

These are disadvantages of the proxy DLL usage:

1. You cannot substitute some of core Windows libraries like `kernel32.dll`. This limitation appears because both `LoadLibrary` and `GetProcAddress` functions are provided by the `kernel32.dll`. They should be available at the moment when proxy DLL loads an original library.

2. It is difficult to make wrappers for some WinAPI functions because they are not documented.

### Example of Proxy DLL

Now we will implement the simplest bot, which is based on proxy DLL technique. The bot will control test application to keep non-zero value of the `gLife` parameter. Bot's algorithm is to simulate the *1* keypress each time when the `gLife` parameter becomes less than 10.

First step of a proxy DLL development is to generate source code of the library with stub functions. We can use the DLL Wrapper Generator script for this purpose. This is the algorithm to use the generator script:

1. Copy the 32-bit version of the `gdi32.dll` library to the directory with the generator script. This library is located in the "C:\Windows\system32" directory for 32-bit Windows and in "C:\Windows\SysWOW64" for 64-bit one.

2. Launch the `cmd.exe` Command Prompt application.

3. Launch the generator script via command line:
```
python Generate_Wrapper.py gdi32.dll
```
You will get a Visual Studio project with generated stub functions. The project is located in the `gdi32` subdirectory. We will work with the 32-bit proxy DLL and 32-bit TestApplication to avoid confusion with its versions.

Second step is to adapt generated proxy DLL for our purposes. This is a list of necessary changes in the library:

1. Open the `gdi32` Visual Studio project and answer "OK" in the "Upgrade VC++ Compiler and Libraries" dialog. This allows you to adapt the project to a new Visual Studio version.

2. Fix the path to the original `gdi32.dll` library in the `gdi32.cpp` source file. This path is specified in the line 10:
```C++
mHinstDLL = LoadLibrary( "ori_gdi32.dll" );
```
The path should be the same as one where you take the `gdi32.dll` library for DLL Wrapper Generator script. This is an example path for the 64-bit Windows case:
```C++
mHinstDLL = LoadLibrary( "C:\\Windows\\SysWOW64\\gdi32.dll" );
```
3. Substitute the stub of the `TextOutA` function to this implementation:
```C++
extern "C" BOOL __stdcall TextOutA_wrapper(
    _In_ HDC     hdc,
    _In_ int     nXStart,
    _In_ int     nYStart,
    _In_ LPCSTR lpString,
    _In_ int     cchString
    )
{
    if (cchString < 10)
    {
        INPUT Input = { 0 };
        Input.type = INPUT_KEYBOARD;
        Input.ki.wVk = '1';
        SendInput(1, &Input, sizeof(INPUT));
    }

    typedef BOOL(__stdcall *pS)(HDC, int, int, LPCTSTR, int);
    pS pps = (pS)mProcs[696];
    return pps(hdc, nXStart, nYStart, lpString, cchString);
}
```
Full version of the `gdi32.cpp` source file is available [here](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ExtraTechniques/OSLevelInterceptionData/gdi32.cpp).

Let us remember the TestApplication code that calls the `TextOutA` function to understand better our wrapper. This is the code.
```
std::string str(gLife, '#');
TextOutA(GetDC(NULL), 0, 0, str.c_str(), str.size());
```
You can see that the length of the string with "#" symbols equals to the `gLife` variable. The length is the last parameter of the `TextOutA_wrapper` function with the `cchString` name. We compare parameter value with the "10" and simulate the keypress with the `SendInput` WinAPI function if the comparison fails. After this we call the original `TextOutA` function via its pointer. The `mProcs` array contains pointers to all function of the original `gdi32.dll` library. We fill this array in the `DllMain` function when the proxy DLL is loaded.

The `TextOutA_wrapper` function was looking like this before our changes:
```C++
extern "C" __declspec(naked) void TextOutA_wrapper(){__asm{jmp mProcs[696*4]}}
```
There is a question, why we use the "696*4" index of the `mProcs` array in the original wrapper and the "696" index in our implementation? This happens because indexing in assembler is performed in bytes. Each element of the `mProcs` array is a pointer to the function. Pointers have the 4 bytes (or 32 bits) size for 32-bit architecture. This is a reason, why we multiply array's index to 4 for the `jmp` assembler instruction. C++ language uses an information about the type of array elements to calculate their offsets correctly.

Third step is to prepare the environment for proxy DLL usage:

1. Build 32-bit version of the `gdi32.dll` proxy DLL.

2. Copy the `gdi32.dll` proxy DLL to the directory with the `TestApplication.exe` executable file.

3. Add the `gdi32.dll` system library to the `ExcludeFromKnownDLL` key register. This is a path to the key:
```
HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\ExcludeFromKnownDlls
```
4. Reboot your computer for the register change to take effect.

Windows has some kind of [protection mechanism](https://support.microsoft.com/en-us/kb/164501) that prevents malware to substitute system libraries. This mechanism implies to list all important libraries in the register. These libraries are able to be load from the predefined system paths only. There is the special `ExcludeFromKnownDLL` register key that allows us to avoid this protection mechanism. We add the `gdi32.dll` library in the exclude list. Now loader uses standard search order for this library. Current directory is the first searching place according to this order. Therefore, the proxy DLL will be loaded instead of the original library.

Now you can launch the `TestApplication.exe` file. You will see that the `gLife` parameter does not fall below 10.

### API Patching

Second approach to hook WinAPI calls is to modify API function itself. When Windows library is loaded into memory of a target process, we can gain access to this memory and modify it.

There are several ways, how we can overwrite beginning of the API function to hook it. The most common approach is to write control transfer assembler instructions like `CALL` or `JMP`. These instructions pass control to our handler function immediately after call of the WinAPI function.

Next task is to execute original API function after the handler done its work. The beginning of the original function was overwritten. We should restore it in our handler. Otherwise, we will get recursive calls of the handler, which lead to stack overflow and application crash. When the original function finishes, we can patch its beginning again. Itallows us to hook next call of this function.

TODO: Mention about DLL injection step to patch the target application.

This is a [code snippet](https://en.wikipedia.org/wiki/Hooking#API.2FFunction_Hooking.2FInterception_Using_JMP_Instruction) with implementation of this technique.

This scheme illustrates the way to handle `TextOutA` WinAPI function with API patching technique:

![API Patching](api-patching.png)

TODO: Write about advantages and disadvantages of this technique below.

These are advantages of the API patching approach:

These are disadvantages of the API patching:

### Example of API Patching

## Summary

We have considered only two approaches to hook WinAPI function calss by game application. There are porxy DLL and API patching techniques. You can learn about other approaches in this [article](http://www.internals.com/articles/apispy/apispy.htm).
