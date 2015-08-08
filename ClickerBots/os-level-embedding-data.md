# OS Level Embedding Data

## Windows API

Main goal of an OS is managing the software and hardware resources and providing an access for launched applications to its. Memory, CPU and peripheral devices are examples of the hardware resources that are managed by OS. Example of the software resource is algorithms that are implemented into the system libraries. The Windows operation system will be considered throughout the book.

The picture illustrates how Windows provide access to the resources:

![Windows Scheme](os-api-noborder.png)

Each launched application is able to ask Windows for performing an action like creating new window, draw a line on the screen, send packet via network, allocate memory and etc. All these actions are implemented in subroutines. Subroutines that solves tasks from one domain are gathered into the system libraries. You can see kernel32.dll, gdi32.dll and etc system libraries at the picture. 

The way how application able to call Windows subrutines is strictly defined, well documented and keeped unchanged. This way of communication is called Windows Application Programming Interface (API) or Windows API (WinAPI). The reason of importance API entity is keeping compatibility of new versions of an applications and new versions of Windows. Windows API can be compared with some kind of contract. If application will follow the contract Windows promise to perform its requests with the certain result.

There are two kind of application is pictured here. Win32 application is an application that interacts with a subset of Windows libraries through Windows API. Win32 is a historical name for this kind of applications that appears in the first 32-bit version of Windows (Windows NT). These libraries provides high level subrutines. High level means that these subrutines operate with complex abstractions like window, control, file and etc. This subset of Windows libraries that available through Windows API sometimes are called WinAPI libraries.

Second kind of applications is a native application. This application interacts with underlying internal Windows libraries and kernel. The libraries become available on the system boot stage, when other components of Windows are unavailable. Also the libraries provide low level subrutines. Low level subrutines operate with simple abstractions like memory page, process, thread and etc. 

The WinAPI libraries use the subrutines of the native library for implementing their complex abstractions. The implementation of the internal libraries is based onto kernel functions that are available through the system calls. 

Device drivers provide simplified representation of the devices for the overlying libraries. The representation includes a set of subrutines which implements the typical actions with the device. These subrutines are available for WinAPI libraries and Internal libraries through the kernel.

Hardware Abstraction Layer (HAL) is a software that performs some representation of the physical hardware. The main goal of this layer is assistance to launch Windows on different kind of hardware. HAL provides subrutines with the hardware specific implementation for both device drivers and kernel. But interface of the subrutines is kept the same and it doesn't depend on the underlying hardware. It allows drivers and kernel developers to minimize their changes in source code to port Windows on new platforms.

TODO: Make a scheme of WinAPI and application interfaction.

## Keyboard Strokes Emulation

TODO: Write about example with input text in Notepad window

TODO: Give example with bare WinAPI (for C++ programmers)

TODO: Write about tricks with random timeouts

## Extra Keyboard Driver

TODO: Write here about the InpOut library. What it allows to do? How it works?

http://www.highrez.co.uk/Downloads/InpOut32/
http://logix4u.net/parallel-port/16-inpout32dll-for-windows-982000ntxp

## Mouse Actions Emulation

TODO: Write about example with drawing in Paint

TODO: Information from "Types of Bots" section

interception
2. **Operation system**. You can substitute or modify some libraries or drivers of operation system. This allows you to trace the interaction between game application and OS. Another way is launching game application under an emulator of the operation system like Wine. Emulators have an advanced logging system often. Thus, you will get a detailed information about each step of the game application work.

embedding
2. **Operation system**. Components of the operation system able to be modified for becoming controlled by the bot application. You can modify a keyboard driver and allow a bot to notify the OS about keyboard actions through the driver for example. Thus, OS will not have possibility to distinguish whether the keyboard event really happened or it was embed by the bot. Also you can use a standard OS interface of applications interaction to notify game application about the embedded by bot keyboard events.
