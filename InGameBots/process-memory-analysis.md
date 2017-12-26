# Process Memory Analysis

## Process Memory Overview

There are a lot of books and articles that describe process memory structure. We will consider aspects of this topic that are important for a practical purpose of a process memory analysis.

First of all, it will be useful to emphasize a difference between an executable binary file and a launched process. We can compare an executable file with a bowl. Data can be compared with liquid. The bowl defines the future form of liquid that will be poured into it. The executable file contains algorithms to process data and description of ways to interpret them. This description of a data interpretation is represented by encoded rules of the [**type system**](https://en.wikipedia.org/wiki/Type_system).

When the executable file is launched, the liquid starts to pour into a bowl. The first step is OS loads the file into memory. Then OS manages execution of a [**machine code**](https://en.wikipedia.org/wiki/Machine_code) of the loaded file. Typical results of this execution are manipulation with memory where application data is stored. There are three common types of memory operations: allocation, modification, and deallocation. It means that you can get information of a game state in the [**run-time**](https://en.wikipedia.org/wiki/Run_time_%28program_lifecycle_phase%29) only when actual operations with data happen.

This is a scheme with components of a typical Windows process:

![Process Scheme](process-scheme.png)

You can see that typical Windows process consists of several modules. EXE module exists always. It matches the executable file, which was loaded to memory on application launch. All Windows applications use at least one library which provides access to WinAPI functions. Compiler links some libraries by default even if you do not use WinAPI functions explicitly in your application. Such WinAPI functions as `ExitProcess` or `VirtualQuery` are used by all applications for correct termination or process memory management. These functions are embedded implicitly into the application code by a compiler.

This is a point where it will be useful to describe two types of libraries. There are [**dynamic-link libraries**](https://support.microsoft.com/en-us/kb/815065) (DLL) and static libraries. The key difference between them is a time of resolving dependencies. In case executable file depends on a static library, the library must be available at compile time. A linker will produce one resulting file that contains both machine code of the static library and the executable file. In case an executable file depends on a DLL, the DLL must be available at the compile time too. But resulting file does not contain machine code of the library. This code will be founded and loaded by OS into the process memory at run-time. Launched application crashes if OS does not find the required DLL. This kind of loaded into the process memory DLLs is the second type of process modules.

A [**thread**](https://en.wikipedia.org/wiki/Thread_%28computing%29) is the smallest portion of machine code that can be executed separately from others in a concurrent manner. Actually, threads interact with each other via shared resources such as memory. But OS is free to select which thread will be executed at the moment. The number of simultaneously executed threads is defined by a number of CPU cores. You can see in the scheme that each module contains one or more threads. Also, module is able to not contain threads at all. EXE module always contains main thread, which is launched by OS on application start.

The described scheme focuses on details of application execution. Now we will consider a memory layout of a typical Windows application.

![Process Memory Scheme](process-memory-scheme.png)

You can see an [**address space**](https://en.wikipedia.org/wiki/Virtual_address_space) of the typical application. The address space is split into memory locations that are named [**segments**](https://en.wikipedia.org/wiki/Segmentation_%28memory%29). Each segment has a [**base address**](https://en.wikipedia.org/wiki/Base_address), length and set of permissions (for example write, read, execute.) Splitting memory into segments simplifies memory management by OS. Information about segment length allows OS to hook violation of segment bounds. Segment permissions allow to control access to the segment.

The illustrated process has three threads including the main thread. Each thread has own [**stack segment**](https://en.wikipedia.org/wiki/Call_stack). Also, there are several [**heap segments**](https://msdn.microsoft.com/en-us/library/ms810603) that can be shared between all threads. The process contains two modules. The first is a mandatory EXE module and the second is a DLL module. Each of these modules has mandatory segments like [`.text`](https://en.wikipedia.org/wiki/Code_segment), [`.data`](https://en.wikipedia.org/wiki/Data_segment#Data), and [`.bss`](https://en.wikipedia.org/wiki/.bss). Also, there are extra segments like `.rsrc`, which are not mentioned in our scheme.

This is a brief description of each segment in the scheme:

| Segment | Description |
| -- | -- |
| Stack of main thread | Contains call stack, parameters of the called functions and [**automatic variables**](https://en.wikipedia.org/wiki/Automatic_variable). The segment is used only by the main thread. |
| Dynamic heap ID 1 | Dynamic heap that is created by default when an application starts. This type of heaps is created and destroyed on the fly during the process execution. |
| Default heap ID 0 | Heap that has been created by OS at application start. This heap is used by all global and local memory management functions in case a handle to the certain dynamic heap is not specified. |
| Stack of thread 2 | Contains call stack, function parameters and automatic variables, which are specific for thread 2 |
| EXE module `.text` | Contains machine code of the EXE module |
| EXE module `.data` | Contains not constant [**globals**](https://en.wikipedia.org/wiki/Global_variable) and [**static variables**](https://en.wikipedia.org/wiki/Static_variable) of the EXE module, which have predefined values |
| EXE module `.bss` | Contains not constant globals and static variables without predefined values |
| Stack of thread 3 | Contains call stack, function parameters and automatic variables, which are specific for thread 3 |
| Dynamic heap ID 2 | Dynamic heap that has been created automatically by a [**heap manager**](http://wiki.osdev.org/Heap) when the default heap has reached the maximum available size. This heap extends the default heap. |
| DLL module `.text` | Contains machine code of the DLL module |
| DLL module `.data` | Contains DLL module specific not constant globals and static variables with predefined values |
| DLL module `.bss` | Contains not constant globals and static variables without predefined values |
| Dynamic heap ID 3 | Dynamic heap that has been created by the heap manager when the dynamic heap with ID 2 has reached the maximum available size |
| TEB of thread 3 | Contains [**Thread Environment Block**](https://en.wikipedia.org/wiki/Win32_Thread_Information_Block) (TEB) or **Thread Information Block** (TIB) data structure with information about thread 3 |
| TEB of thread 2 | Contains TEB with information about thread 2 |
| TEB of main thread | Contains TEB with information about the main thread |
| PEB | Contains [**Process Environment Block**](https://msdn.microsoft.com/en-us/library/windows/desktop/aa813706%28v=vs.85%29.aspx) (PEB) data structure with information about a whole process |
| User shared data | Contains memory that is shared by current process with other processes |
| Kernel memory | Contains memory that is reserved for OS purposes like device drivers and system cache |

Segments, which can contain states of game objects, are marked by a red color in the scheme. Base addresses of these segments are assigned when the application starts. It means that these addresses can differ each time when you launch the application. Moreover, the sequence of these segments in the process memory can vary too. On the other hand, base addresses and sequence of some other segments are predefined. Examples of the constant segments are PEB, user shared data and kernel memory.

OllyDbg debugger allows you to get memory map of a launched process. These screenshots demonstrate the feature:

![OllyDbg Memory Map Head](ollydbg-mem-map-1.png)

![OllyDbg Memory Map Tail](ollydbg-mem-map-2.png)

The first screenshot represents the beginning of the process address space. Remaining address space you can find in the second screenshot. There is a table of correspondence segments on the scheme and screenshots:

| Address | Segment |
| -- | -- |
| 001ED000 | Stack of main thread |
| 004F0000 | Dynamic heap with ID 1 |
| 00530000 | Default heap with ID 0 |
| 00ACF000<br>00D3E000<br>0227F000 | Stacks of additional threads |
| 00D50000-00D6E000 | Segments of the EXE module with "ConsoleApplication1" name |
| 02280000-0BB40000<br>0F230000-2BC70000 | Extra dynamic heaps |
| 0F0B0000-0F217000 | Segments of the DLL module with "ucrtbased" name |
| 7EFAF000<br>7EFD7000<br>7EFDA000 | TEB of additional threads |
| 7EFDD000 | TEB of main thread |
| 7EFDE000 | PEB of main thread |
| 7FFE0000 | User shared data |
| 80000000 | Kernel memory |

You can notice that OllyDbg does not detect extra dynamic heaps automatically. You can use WinDbg debugger or HeapMemView utility to clarify base addresses of all heap segments.

## Variables Searching

Bot application should read a state of game objects from memory of a game process. The state can be stored in variables from several different segments. Base addresses of these segments and offsets of variables inside them can be changed each time when a game application is launched. This means that final absolute address of each variable is not constant. Therefore, the bot should have an algorithm to search variables in process memory. This algorithm should deduce absolute addresses of specific variables.

We use an "absolute address" term here but it is not precise in terms of [**x86 memory segmentation model**](https://en.wikipedia.org/wiki/X86_memory_segmentation). Absolute address in terms of this model is named **linear address**. This is a formula to calculate linear address:
```
linear address = base address + offset
```
We will continue to use "absolute address" term for simplification as more intuitive understanding one. The "linear address" term will be used when nuances of x86 memory segmentation model will be discussed.

We can divide search of specific variable in process memory into three steps:

1. Find a segment which contains the variable.
2. Define a base address of this segment.
3. Define an offset of the variable inside the segment.

It is very likely that the variable will be kept in the same segment on next application launches. The segment can vary often only in case the variable is stored in a heap segment. This happens because of mechanism, which creates dynamic heaps. Therefore, it is possible to solve first step of search by analyzing process memory in run-time manually. We can hardcode the result into our bot. 

The second step of search segment base address should be solved by a bot each time when a game application is launched.

There is no guarantee that variable offset inside a segment will be the same on each application launch. But the offset may remain constant in some cases. It depends on type of the owning segment. This table illustrates dependency between segment types and offsets of its inner variables:

| Segment Type | Offset Constancy |
| -- | -- |
| `.bss` | Always constant |
| `.data` | Always constant |
| stack | Offset is constant in most cases. It can vary when [**control flow**](https://en.wikipedia.org/wiki/Control_flow) of application execution differs between new application launches. |
| heap | Offset vary in most cases |

Therefore, we can solve the third step of search algorithm manually in some cases.

### 32-bit Application Analyzing

We will use [ColorPix](https://www.colorschemer.com/colorpix_info.php) 32-bit application to demonstrate how to search specific variable in process memory. Now we will do all search steps manually to understand each of them better.

ColorPix application was described and used in the [Clicker Bots](../ClickerBots/tools.md) chapter. This is a screenshoot of the application window:

![ColorPix](colorpix.png)

We will find a variable that matches X coordinate of the selected pixel on a screen. This value is underlined by a red line on the screenshot.

It is important to emphasize that you should not close the ColorPix application during all process of analysis. In case you close and restart the application, you should start to search variable from beginning.

The first step is to find a memory segment, which contains the X coordinate. This task can be done in two stages:

1. Find absolute address of the variable with Cheat Engine scanner.

2. Compare discovered absolute address with base addresses and lengths of all memory segments. It will allow us to deduce a segment, which contains this variable.

This is an algorithm to find absolute address of the variable with Cheat Engine scanner:

1\. Launch 32-bit version of the Cheat Engine scanner with administrator privileges.

2\. Select "File"->"Open Process" menu item. You will see the dialog with a list of launched applications at the moment:

![Cheat Engine Process List](cheatengine-process-list.png)

3\. Select a process with "ColorPix.exe" name in the list and press the "Open" button. Now the process name is displayed above the progress bar at the top of Cheat Engine window.

4\. Type current value of the X coordinate into the "Value" control of the Cheat Engine window.

5\. Press the "First Scan" button to search the typed value into memory of ColorPix process. The number in the "Value" control should match the X coordinate that is displayed in ColorPix window at the moment when you are pressing the "First Scan" button. You can use *Tab* and *Shift+Tab* keys to switch between the "Value" control and "First Scan" button. It allows you to keep pixel coordinate unchanged during switching.

Search results will be displayed in the list control:

![Cheat Engine Result](cheatengine-result.png)

If there are more than two absolute addresses in the list, you should cut off inappropriate results. Move mouse to change X coordinate of the current pixel. Then type a new value of X coordinate into the "Value" control and press "Next Scan" button. Be sure that the new value differs from the previous one. There are still present two variables in the results list after cutting of inappropriate results. Absolute addresses of them equal to "0018FF38" and "0025246C".

Now we know absolute address of two variables that match to X coordinate of selected pixel. Next step is to find segments, which contains these variables. OllyDbg debugger will be used in our example.

This is an algorithm to search the segment with the OllyDbg debugger:

1\. Launch OllyDbg debugger with administrator privileges. Default path of the debugger executable file is `C:\Program Files (x86)\odbg201\ollydbg.exe`.

2\. Select the "File"->"Attach" menu item. You will see a dialog with list of launched 32-bit applications at the moment:

![OllyDbg Process List](ollydbg-process-list.png)

3\. Select the process with "ColorPix.exe" name in the list and press the "Attach" button. When debugger is attached, you see the "Paused" text in the right-bottom corner of the OllyDbg window.

4\. Press *Alt+M* to open a memory map of the ColorPix process. Now the OllyDbg window looks like this:

![OllyDbg Memory Map](ollydbg-result.png)

You can see that variable with absolute address 0018FF38 matches the "Stack of main thread" segment. This segment occupies addresses from "0017F000" to "00190000" because a base address of the next segment equals to "00190000". Second variable with absolute address 0025246C matches unknown segment with "00250000" base address. It will be more reliable to choose the "Stack of main thread" segment to read a value of the X coordinate in future. It is much easer to find a stack segment than some kind of unknown segment.

Last step of search algorithm is to calculate a variable offset inside the owning segment. Stack segment grows down for x86 architecture. It means that stack grows from higher addresses to lower addresses. Therefore, base address of the stack segment equals to its upper bound i.e. 00190000 in our case. Lower segment bound will change when the stack grows.

Variable offset equals subtraction of a variable absolute address from a base address of the segment. This is an calculation example for our case:
```
00190000 - 0018FF38 = C8
```
Variable offset inside the owning segment equals C8. This formula differs for heap, `.bss` and `.data` segments. Heap grows up, and its base address equals lower segment bound. `.bss` and `.data` segments do not grow at all. Their base addresses equal to lower segments bounds too. You can follow the rule to subtract a smaller address from a larger one to calculate variable offset correctly.

Now we have enough information to find and read value of X coordinate for any launched ColorPix process. This is the algorithm to do it:

1. Get base address of the main thread stack segment. This information is available from the TEB segment.

2. Calculate absolute address of the X coordinate variable by adding the variable offset 10F38 to the base address of the stack segment.

3. Read four bytes from the ColorPix application memory at the resulting absolute address.

As you see, it is quite simple to write a bot application that implements this algorithm.

You can get a dump of TEB segment with OllyDbg by left button double-click on a "Data block of main thread" segment in the "Memory Map" window. This is a screenshot of TEB dump for ColorPix application:

![OllyDbg TEB](ollydbg-teb.png)

Base address of the stack segment equals to "00190000" according to the screenshot. But this address can vary and you should read it each time when ColorPix application is restarted.

### 64-bit Application Analyzing

Current version of OllyDbg debugger does not support 64-bit applications. Therefore, we should use the WinDbg debugger instead. The search variable algorithm still the same for 64-bit applications.

We will take Resource Monitor application from Windows 7 for analysis. Bitness of this application matches the bitness of the Windows OS. If you have 64-bit Windows version, you have 64-bit Resource Monitor. You can launch it by typing the `perfmon.exe /res` command in a search box of the "Start" Windows menu. This is a screenshot of the application:

![Resource Monitor](resource-monitor.png)

The "Free" memory amount is underlined by a red line. We will find this variable in process memory.

The first step to find a segment, which contains a target variable, is still the same as one for 32-bit application. You can use 64-bit version of Cheat Engine scanner to get an absolute address of the variable. There are two results with "00432FEC" and "00433010" addresses in my case.

The second step to compare process memory map and variables addresses differs from 32-bit application analysis because we use another debugger. This is an algorithm to get a process memory map with WinDbg:

1\. Launch 64-bit version of the WinDbg debugger with administrator privileges. Default path of the debugger executable file is `C:\Program Files (x86)\Windows Kits\8.1\Debuggers\x64\windbg.exe`.

2\. Select the "File"->"Attach to a Process..." menu item. You will see a dialog with list of launched 64-bit applications at the moment:

![WinDbg Process List](windbg-process-list.png)

3\. Select a process with the "perfmon.exe" name in this list and press the "OK" button.

4\. Type `!address` in a command line at bottom of the "Command" window, and press *Enter*. You will see a memory map of the Resource Monitor application in the "Command" window:

![WinDbg Result](windbg-result.png)

You can see that both variables with absolute addresses 00432FEC and 00433010 match the first heap segment with ID 2. This segment occupies addresses from "003E0000" to "00447000". We can use first variable with 00432FEC absolute address to read free memory amount.

This is a calculation of the variable offset:
```
00432FEC - 003E0000 = 52FEC
```
This is an algorithm to find and read a free memory amount from a launched Resource Monitor application:

1\. Get a base address of the heap segment with ID 2. You can use this set of WinAPI functions to traverse process heap segments:
* `CreateToolhelp32Snapshot`
* `Heap32ListFirst`
* `Heap32ListNext`

2\. Calculate an absolute address of the variable by adding the offset 52FEC to the base address of the heap segment.

3\. Read four bytes from the Resource Monitor application memory at the resulting absolute address.

## Summary

We have considered memory structure of a typical windows application. Also we learned how to find an absolute address of the specific variable in memory of 32-bit and 64-bit processes.
