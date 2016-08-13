# OS Level Interception Data

## Tools

We will work with Windows API functions in this chapter. C++ language is the best choice for this task. We will use the [Visual Studio 2015 Community IDE](https://www.visualstudio.com/en-us/products/visual-studio-express-vs.aspx#) to compile our examples. More details about this IDE is available in the [In-game Bots](../InGameBots/tools.md) section.

There are several open source solutions to simplify process of hook WinAPI calls. We will use the [Deviare](http://www.nektra.com/products/deviare-api-hook-windows/) open source hooking engine.

There are steps to install Deviare software:

1. Download the last version of the [release binaries](https://github.com/nektra/Deviare2/releases/download/v2.8.0/Deviare.2.8.0.zip).

2. Download the latest version of the [source code](https://github.com/nektra/Deviare2/archive/v2.8.0.zip).

3. Unpack both archives in two different directories.

You can find a list of all available releases in the [github project](https://github.com/nektra/Deviare2/releases). Please make sure that the version of binaries matches to the version of sources.

## API Hooking Techniques

Game application interacts with OS via WinAPI calls. There are several approaches to hook these calls. This [article](http://www.internals.com/articles/apispy/apispy.htm) describes these approaches in details.

Tools like [API Monitor](../ClickerBots/tools.md) are based on one of hooking approaches. We can implement a bot application, which behaves in a similar way. But unlike these tools the bot should simulate player actions instead of logging WinAPI calls.

Before we start to consider API hooking, it will be useful to know how application interacts with DLL. When we start an application, Windows loader reads executable file into memory. Then the loader should find files of all required DLLs. These files are read into the process memory by the loader too. Now we face an issue. Locations of the DLL modules in the process memory are not constant. These locations can vary each time when application is launched. Therefore, we cannot hardcode addresses of the DLL functions in the executable module. This issue is solved by [Import Address Table](http://sandsprite.com/CodeStuff/Understanding_imports.html) (IAT).

IAT contains actual addresses of the library functions. Windows loader update these addresses by actual values during application startup. Each time when executable module calls a library function, it uses corresponding IAT slot to clarify target function address.

Now we will briefly consider most common API hooking techniques. 

### Proxy DLL

### IAT Patching

### API Patching

## Test Application

## Deviare Hooking Engine

## Bot Application

## Summary