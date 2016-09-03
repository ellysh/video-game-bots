# OS Level Interception Data

## Tools

We will work with Windows API functions in this chapter. C++ language is the best choice for this task. We will use the [Visual Studio 2015 Community IDE](https://www.visualstudio.com/en-us/products/visual-studio-express-vs.aspx#) to compile our examples. More details about this IDE is available in the [In-game Bots](../InGameBots/tools.md) chapter.

There are several open source solutions to simplify process of hook WinAPI calls.

First solution is [DLL Wrapper Generator](https://m4v3n.wordpress.com/2012/08/08/dll-wrapper-generator/), which can help us to create proxy DLLs.

There are steps to install DLL Wrapper Generator:

1. Download the scripts on the github [project page](https://github.com/mavenlin/Dll_Wrapper_Gen/archive/master.zip).

2. Download and install [Python 2.7 version](https://www.python.org/downloads/)

Now we are ready to work with DLL Wrapper Generator.

Second solution to hook WinAPI calls is [Deviare](http://www.nektra.com/products/deviare-api-hook-windows/) open source hooking engine.

There are steps to install Deviare software:

1. Download the last version of the [release binaries](https://github.com/nektra/Deviare2/releases/download/v2.8.0/Deviare.2.8.0.zip).

2. Download the latest version of the [source code](https://github.com/nektra/Deviare2/archive/v2.8.0.zip).

3. Unpack both archives in two different directories.

You can find a list of all available Deviare releases in the [github project](https://github.com/nektra/Deviare2/releases). Please make sure that the version of binaries matches to the version of sources.

## Test Application

We will use the same application to test WinAPI calls hooking techniques as we used in the [protection against in-game bots](../InGameBots/protection.md) section.

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
Algorithm of this application still the same. We decrement the `gLife` variable each second if the *1* keyboard key is not pressed. Otherwise, we increment the `gLife`. New feature of the application is a call of the `TextOutA` WinAPI function. This function prints the hash symbols in the upper-left corner of your screen. Count of printed symbols equals to the value of `gLife`.

Now our goal is to hook the `TextOutA` function call and to get its last parameter, which has the same value as the `gLife` variable.

## DLL Import

Before we start to consider WinAPI hooking, it will be useful to know how application interacts with DLL. When we start an application, Windows loader reads executable file into process memory. Typical Windows executable file has [**PE**](https://msdn.microsoft.com/en-us/library/ms809762.aspx) format. This format is a standard for data structures, which are stored in file's header. These structures contain necessary information to launch executable code by the Windows loader. List of required DLLs is a part of this information.

Next step of the loader is to find files of all required DLLs on a disk drive. These files are read into the process memory too. Now we face an issue. Locations of the DLL modules in a process memory are not constant. These locations can vary for different versions of the same DLL. Therefore, compiler cannot hardcode addresses of DLL functions in the executable module. This issue is solved by [**Import Table**](http://sandsprite.com/CodeStuff/Understanding_imports.html). There is some kind of confusion with Import Table and **Thunk Table**.

Each element of Import Table matches to one imported DLL module. This element contains name of the module, `OriginalFirstThunk` pointer and `FirstThunk` pointer. You can find more details about these pointers [here](http://ntcore.com/files/inject2it.htm). The `OriginalFirstThunk` points to the first element of array with ordinal numbers and names of the imported functions. The `FirstThunk` points to the first element of array (also known as Import Address Table or IAT), which is overwritten by Windows loader with actual addresses of the imported functions. And this is a source of confusion because both these arrays do not contain any stuff that is named [**thunk**](https://en.wikipedia.org/wiki/Thunk#Overlays_and_dynamic_linking).

Import Table is a part of PE header and it contains constant meta information about imported DLLs. This table is stored in the read-only process memory segment with PE header. Thunk table (also known as jump table) is a part of executable code and it contains `JMP` instructions to transfer control to the imported functions. This table is placed in the read and executable `.text` segment with all other application code. Import Address Table is stored in the read and write `.idata` segment. The `.idata` segment also contains an array, which is pointed by `OriginalFirstThunk`. As you see all three tables are placed in different segments.

Some compilers generate a code, which does not use Thunk Table. This allows to avoid one extra jump and to get slightly more optimized solution. Code, which is generated by MinGW compiler, uses the Thunk Table. The scheme illustrates a call of the `TextOutA` WinAPI function from this code:

![DLL call MinGW](dll-call-mingw.png)

This is an algorithm of the function call:

1. The `CALL` instruction is used to save a return location to stack and to pass control to the Thunk Table element with `40839C` address.

2. The Thunk Table element contains one `JMP` instruction only. This instruction uses actual address of the `TextOutA` function in the `gdi32` module from a Import Address Table record. The `DS` segment register, which points to the `.idata` segment, is used to calculate the record address:
```
DS + 0x278 = 0x422000 + 0x278 = 0x422278
```
3. The `TextOutA` function from the `gdi32` module is executed. There is a `RETN` instruction at the end of the function. The `RETN` passes control to the next instruction after the `CALL` one in the EXE module. It happens because the `CALL` put this return location on the stack.

Visual C++ compiler generated code does not use Thunk Table. The scheme illustrates a call of the same `TextOutA` WinAPI function in this case:

![DLL call Visual C++](dll-call-visual-cpp.png)

This is an algorithm of the function call:

1. The `CALL` instruction is used to pass control to the `TextOutA` function in the `gdi32` module directly. Address of this function is taken from the Import Address Table record.

2. The `TextOutA` is executed. Then the `RETN` instruction passes control back to the EXE module.

## API Hooking Techniques

Game application interacts with Windows via system DLLs. Such operations as displaying a text on the screen are performed by WinAPI functions. It is possible to get a state of the game objects by hooking calls to these functions. This approach reminds the output device capture. But now we can analyze data before it will come to the output device. This data can be a picture, sound, network packet or set of bytes in a temporary file.

You can see how API hooking works by launching the [API Monitor](../ClickerBots/tools.md) tool. This tool prints the hooked calls in the "Summary" sub-window. We can implement a bot application that behaves in a similar way. But unlike the API Monitor a bot should simulate player actions instead of printing hooked calls.

Now we will briefly consider most common API hooking techniques with examples.

### Proxy DLL

First approach to hook WinAPI calls is to substitute original Windows library. We can implement a library that looks like the original one for Windows loader point of view. Therefore, this library can be loaded to the process memory during application launching. Then game application will interact with the library in the same way as with the original one. This approach allows us to execute our code each time, when a game application calls a function from the WinAPI library. 

The library that can substitute original one is named **Proxy DLL**.

We need to hook several specific WinAPI functions in most cases. All other functions of the substituted Windows library are not interesting for us. Also there is a requirement - game application should behave with proxy DLL in the same manner as with the original library. Therefore, proxy DLL should route function calls to the original library. The functions, which should be hooked, can contain code of the bot application to simulate player actions or to gather state of the game objects. But the original WinAPI functions should be called after this code. We can make simple stubs, which route to the original Windows library, for not interesting for us functions. It means that the original library should be loaded in the process memory too. Windows loader performs this task because the proxy DLL depends on the original library.

This scheme illustrates a call of the `TextOutA` WinAPI function via a proxy DLL:

![Proxy DLL](proxy-dll.png)

This is an algorithm of the function call:

1. Windows loader finds a proxy DLL instead of the Windows library. Addresses of the functions, which are exported by the proxy DLL, are written to the Import Address Table of the EXE module.

2. Execution of the EXE module code meets the `CALL` instruction. The record of Import Address Table is used to get an actual function address. Now this record contains an address of the proxy DLL function. The `CALL` instruction passes control to this function.

3. Proxy DLL contains the Thunk Table. Addresses of the exported functions match to the thunks in this table. Therefore, EXE module pass control to the thunk.

4. The `JMP` instruction of thunk pass control to the wrapper of the `TextOutA` WinAPI function, which is provided by proxy DLL. Code of a bot application is executed in this wrapper.

5. The `CALL` instruction is used to pass control to the original `TextOutA` function of `gdi32` module when the wrapper code is finished.

6. The `TextOutA` is executed. Then the `RETN` instruction passes control back to the proxy DLL module.

7. The `RETN` instruction at the end of the `TextOutA` wrapper passes control back to the EXE module.

There is one question. How a proxy DLL knows the actual addresses of `gdi32` module's functions? We cannot delegate gathering of this addresses to the Windows loader. The problem is, we want to load the original Windows library from the specific path in our proxy DLL. It means that we should avoid a library searching mechanism of Windows loader. Therefore, we should load the original library manually with the [`LoadLibrary`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms684175(v=vs.85).aspx) WinAPI function. The [`GetProcAddress`](https://msdn.microsoft.com/en-us/library/windows/desktop/ms683212%28v=vs.85%29.aspx) function helps us to dynamically get actual addresses of its exported functions. Proxy DLL uses the Thunk Table to store these dynamically gathered function addresses.

These are advantages of the proxy DLL approach:

1. Easy to generate proxy DLL with existing open source tools.

2. Proxy DLL substitutes a Windows library for specific application only. All other launched applications still use original libraries.

3. It is difficult to protect application against this approach.

These are disadvantages of the proxy DLL usage:

1. You cannot substitute some core Windows libraries like `kernel32.dll`. This limitation appears because both `LoadLibrary` and `GetProcAddress` functions are provided by the `kernel32.dll`. They should be available at the moment when proxy DLL loads an original library.

2. It is difficult to make wrappers for some WinAPI functions because they are not documented.

### Example of Proxy DLL

### IAT Patching

### API Patching

This [article](http://www.internals.com/articles/apispy/apispy.htm) describes these approaches in details.

## Summary