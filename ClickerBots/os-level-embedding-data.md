# OS Level Embedding Data

## Windows API

Main goal of an OS is managing the software and hardware resources and providing an access for launched applications to its. Memory, CPU and peripheral devices are examples of the hardware resources that are managed by OS. Example of the software resource is algorithms that are implemented into the system libraries. The Windows operation system will be considered throughout the book.

The picture illustrates how Windows provide access to the resources:

![Windows Scheme](os-api-noborder.png)

Each launched application is able to ask Windows for performing an action like creating new window, draw a line on the screen, send packet via network, allocate memory and etc. All these actions are implemented in subroutines. Subroutines that solves tasks from one domain are gathered into the system libraries. You can see kernel32.dll, gdi32.dll and etc system libraries at the picture. 

The way how application able to call Windows subroutines is strictly defined, well documented and kept unchanged. This way of communication is called Windows Application Programming Interface (API) or Windows API (WinAPI). The reason of importance API entity is keeping compatibility of new versions of an applications and new versions of Windows. WinAPI can be compared with some kind of contract. If application will follow the contract Windows promise to perform its requests with the certain result.

There are two kind of application is pictured here. Win32 application is an application that interacts with a subset of Windows libraries through WinAPI. Win32 is a historical name for this kind of applications that appears in the first 32-bit version of Windows (Windows NT). These libraries provides high level subroutines. High level means that these subroutines operate with complex abstractions like window, control, file and etc. The subset of Windows libraries that available through WinAPI are called WinAPI libraries.

Second kind of applications is a native application. This application interacts with underlying internal Windows libraries and kernel through Native API. The libraries become available on the system boot stage, when other components of Windows are unavailable. Also the libraries provide low level subroutines. Low level subroutines operate with simple abstractions like memory page, process, thread and etc. 

The WinAPI libraries use the subroutines of the native library for implementing their complex abstractions. The implementation of the internal libraries is based onto kernel functions that are available through the system calls. 

Device drivers provide simplified representation of the devices for the overlying libraries. The representation includes a set of subroutines which implements the typical actions with the device. These subroutines are available for WinAPI libraries and Internal libraries through the kernel.

Hardware Abstraction Layer (HAL) is a software that performs some representation of the physical hardware. The main goal of this layer is assistance to launch Windows on different kind of hardware. HAL provides subroutines with the hardware specific implementation for both device drivers and kernel. But interface of the subroutines is kept the same and it does not depend on the underlying hardware. It allows drivers and kernel developers to minimize the changes in source code to port Windows on new platforms.

## Keyboard Strokes Emulation

### Keystroke in Active Window

First of all it will be useful to investigate AutoIt provided ways for keyboard strokes emulation. The most appropriate way is a [**Send**](https://www.autoitscript.com/autoit3/docs/functions/Send.htm) function according to the list of [available varaints](https://www.autoitscript.com/autoit3/docs/functions.htm).

Our test application will press the "a" key in the already opened Notepad window. This is an algorithm of the application work:

1. Find an opened Notepad window.
2. Switch to the Notepad window.
3. Emulate "a" key pressing.

The Notepad window able to be found with the [**WinGetHandle**](https://www.autoitscript.com/autoit3/docs/functions/WinGetHandle.htm) function. The first parameter of the function can be window title, window handle or window class. We will specify the window class as more reliable variant. These are steps to investigate class of the Notepad window:

1. Open the **C:\Program Files\AutoIt3\Au3Info.exe** application. Your AutoIt installation path can be different.
2. Drag-and-drop **Finder Tool** to the Notepad window.
3. You will get result like this:

![AutoIt3 Info Tool](au3info.png)

The information that we are looking for is specified in the **Class** field of the **Basic Window Info** block. The value of the window class is **Notepad**.

This is a **Send.au3** application code for implementing our algorithm:
```AutoIt
$hWnd = WinGetHandle("[CLASS:Notepad]")
WinActivate($hWnd)
Send("a")
```
Here we get window handle of the Notepad window with the **WinGetHandle** function. Next step is switching to the window with the **WinActivate** function. And last step is emulating "a" key pressing. You can just put this code into the file with **Send.au3** name and launch it by double click.

### AutoIt Send Function Internal

Actually the **Send** AutoIt function uses one of the WinAPI subroutines or functions. It will be useful to discover which one of the possible WinAPI functions have been used. API Monitor is a suitable tool for hooking API calls that are made by an application. We will rely on it in our investigation.

These are steps to monitor **Send.au3** application WinAPI calls:

1. Launch the **API Monitor 32-bit** application.
2. Find (Ctrl+F) and select the **Keyboard an Mouse Input** item in the **API Filter** child window.
3. Press Ctrl+M to open the **Monitor New Process** dialog.
4. Specify **C:\Program Files\AutoIt3\AutoIt3.exe** application in the **Process** field and press **OK** button.
5. Specify the **Send.au3** application in the opened **Run Script** dialog. The application will be launched after this action.
6. Find (Ctrl+F) the **'a'** text (with the single quotes) in the **Summary** child window of the API Monitor application.

You will get a result similar to this:

![API Monitor Application](api-monitor.png)

**VkKeyScanW** is a function that explicitly get the 'a' character as parameter. But it does not perform the keystroke emulation according to WinAPI documentation. Actually, **VkKeyScanW** and a next called **MapVirtualKeyW** functions are used for preparing input parameters for the [**SendInput**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646310%28v=vs.85%29.aspx) function. **SendInput** performs actual work for emulating keystroke.

Now we can try to implement our algorithm of pressing "a" key in the Notepad window through a direct interaction with WinAPI functions. The most important thing now is a way to keystrokes emulation. Thus, usage the **WinGetHandle** and **WinActivate** AutoIt function will be kept.

This is a **SendInput.au3** application code for implementing the algorithm through WinAPI interaction:
```AutoIt
$hWnd = WinGetHandle("[CLASS:Notepad]")
WinActivate($hWnd)

Const $KEYEVENTF_UNICODE = 4
Const $INPUT_KEYBOARD = 1
Const $iInputSize = 28

Const $tagKEYBDINPUT = _
    'word wVk;' & _
    'word wScan;' & _
    'dword dwFlags;' & _
    'dword time;' & _
    'ulong_ptr dwExtraInfo'
    
Const $tagINPUT = _
    'dword type;' & _
    $tagKEYBDINPUT & _
    ';dword pad;'

$tINPUTs = DllStructCreate($tagINPUT)
$pINPUTs = DllStructGetPtr($tINPUTs)
$iINPUTs = 1
$Key = AscW('a')

DllStructSetData($tINPUTs, 1, $INPUT_KEYBOARD)
DllStructSetData($tINPUTs, 3, $Key)
DllStructSetData($tINPUTs, 4, $KEYEVENTF_UNICODE)

DllCall('user32.dll', 'uint', 'SendInput', 'uint', $iINPUTs, 'ptr', $pINPUTs, 'int', $iInputSize)
```
We call **SendInput** WinAPI function through the [**DllCall**](https://www.autoitscript.com/autoit3/docs/functions/DllCall.htm) AutoIt function here. You should specify the library name, WinAPI function name, return type and function's input parameters for the **DllCall**. The preparation of the input parameters for **SendInput** is the most part of the work in our **SendInput.au3** application. 

First parameter of the **SendInput** is a count of structures with the [**INPUT**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646270%28v=vs.85%29.aspx) type. Only one structure is used in our example. Thus, the **$iINPUTs** variable equal to 1.

Second parameter is a pointer to the array of **INPUT** structures. The pointer to the single structure is possible to pass too. We uses the **$tagINPUT** variable for representing structure's fields according to the WinAPI documentation. The significant fields here are the first with the **type** name and the second unnamed with the [**KEYBDINPUT**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646271%28v=vs.85%29.aspx) type. You see that we have a situation of the nested structures. The **INPUT** contains within itself the **KEYBDINPUT** one. The **$tagKEYBDINPUT** variable is used for representing fields of the **KEYBDINPUT**. The **$tagINPUT** variable is used for creating structure in the process memory by [**DllStructCreate**](https://www.autoitscript.com/autoit3/docs/functions/DllStructCreate.htm) call. Next step is receiving pointer of the created **INPUT** with the [**DllStructGetPtr**](https://www.autoitscript.com/autoit3/docs/functions/DllStructGetPtr.htm) function. And the last step is writing actual data to the **INPUT** structure with the [**DllStructSetData**](https://www.autoitscript.com/autoit3/docs/functions/DllStructSetData.htm) function.

Third parameter of the **SendInput** is a size of a single **INPUT** structure. This is constant and equal to 28 bytes in our case:
```
dword + (word + word + dword + dword + ulong_ptr) + dword =  4 + (2 + 2 + 4 + 4 + 8) + 4 = 28
```
The question is why we need the last padding dword field in the **INPUT** structure. If you clarify the **INPUT** definition you will see the **union** C++ keyword. This means that the reserved memory size will be enough for storing the biggest of the **MOUSEINPUT**, **KEYBDINPUT** and **HARDWAREINPUT** structures. The biggest structure is **MOUSEINPUT** that have dword extra field compared to **KEYBDINPUT**.

Now you can see the benefit of usage such high-level language as AutoIt. It hides from the developer a lot of inconsiderable details and allow to operate with simple abstractions and functions.

### Keystroke in Inactive Window

The **Send** function emulates keystroke in the window that is active at the moment. It means that you can not minimize or switch to background the window where you want to emulate keystrokes. This is not suitable in some cases. AutoIt contains function that able to help in this situation. This is a [**ControlSend**](https://www.autoitscript.com/autoit3/docs/functions/ControlSend.htm) function. 

We can rewrite our **Send.au3** application to use **ControlSend** function in this way:
```AutoIt
$hWnd = WinGetHandle("[CLASS:Notepad]")
ControlSend($hWnd, "", "Edit1", "a")
```
You can see that now we should specify the control name, class or id which will process the keystroke. The control have an **Edit1** classname in our case according to information from Au3Info tool.

We can use the API Monitor application to clarify the underlying WinAPI function that is called by **ControlSend**. This is a [**SetKeyboardState**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646314%28v=vs.85%29.aspx). You can try to rewrite our **ControlSend.au3** application to use **SetKeyboardState** function directly as an exercise.

But now we face with the question how to send keystrokes to the maximized DirectX window? The problem is DirectX window have not internal controls. Actually, it will work correctly if you just skip the **controlID** parameter of the **ControlSend** function.

This is an example of the "a" keystroke emulation in the inactive Warcraft III window:
```AutoIt
$hWnd = WinGetHandle("Warcraft III")
ControlSend($hWnd, "", "", "a")
```
You can see that we used the "Warcraft III" window title here to get the window handle. Way to discover this window title become tricky if it is impossible to switch off a fullscreen mode of the DirectX window. The problem is tool like Au3Info do not give you a possibility to gather information from the fullscreen windows. You can use an API Monitor application for this goal. Just move mouse cursor on the desired process in the **Running Process** child window. This is example for the Notepad application:

![Window Title in API Monitor](api-monitor-title.png)

If the target process does not exist in the child window you can try to enter into administrator mode of API Monitor application or launch 32 or 64 API Monitor version. 

Some fullscreen windows may not have a title text. The alternative solution is addressing to the window by the window class. But API Monitor does not provide a window class information.

This is the AutoIt script that will show you a title text and a window class of the current active window:
```AutoIt
#include <WinAPI.au3>

Sleep(5 * 1000)
$handle = WinGetHandle('[Active]')
MsgBox(0, "", "Title   : " & WinGetTitle($handle) & @CRLF & "Class : " & _WinAPI_GetClassName($handle))
```
First line contains an [**include**](https://www.autoitscript.com/autoit3/docs/keywords/include.htm) keyword that allows you to append the specified file into the current script. **WinAPI.au3** file contains a defintion of the [**_WinAPI_GetClassName**](https://www.autoitscript.com/autoit3/docs/libfunctions/_WinAPI_GetClassName.htm) function that performs a necessary job. The script will sleep 5 seconds after the start. This is performed by the [**Sleep**](https://www.autoitscript.com/autoit3/docs/functions/Sleep.htm) function. You should switch to the fullscreen window while the script sleeps. After sleep a handle of the current active window will be saved into the **$handle** variable. Last action is showing a message box by the [**MsgBox**](https://www.autoitscript.com/autoit3/docs/functions/MsgBox.htm) function with the necessary information.

## Mouse Actions Emulation

The keyboard stroke emulation will be enough for controlling player character in some games. But the most of modern video games have a complex control by both keyboard and mouse. AutoIt language have several functions that allows you to emulate typical mouse actions like clicking, moving and holding mouse button pressed. Now we will consider them sequentially.

### Mouse Actions in Active Window

We will test our mouse emulation examples in the standard Microsoft Paint application window. This is a **MouseClick.au3** script that performs a mouse click in the active Paint window:
```AutoIt
$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
WinActivate($hWnd)
MouseClick("left", 250, 300)
```
You should launch the Paint application, switch to the **Brushes** tool and launch the **MouseClick.au3** script. You will see a black dot at the x=250 and y=300 coordinates. The **ColorPix** application that have been mentioned in the [Tools](tools.md) section will help you to check the coordinate correctness. The [**MouseClick**](https://www.autoitscript.com/autoit3/docs/functions/MouseClick.htm) AutoIt function have been used in the example. You can specify these function parameters:

1. Which mouse button will be clicked.
2. Coordinates of the click action.
3. Count of clicks.
4. Mouse movement speed to the specified coordinates.

The [**mouse_event**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646260%28v=vs.85%29.aspx) WinAPI function is used by **MouseClick**.

Now it is time to consider the coordinate systems that is used by AutoIt mouse functions. Three modes to specify mouse coordinates are available in the AutoIt:

0\. Relative coordinates to the active window.<br/>
1\. Absolute screen coordinates. This mode is used by default.<br/>
2\. Relative coordinates to the client area of the active window.

This is an illustration of the mentioned variants:

![Mouse Coordinate Types](mouse-coordinate-types.png)

You can see numbered red dots on the picture. Each number defines a type of the dot's coordinate system. The dot with 0 number have a relative coordinates to the active window for example. The indexed x and y letters are appropriate coordinates of the each dot.

You can switch between types of coordinate system by **MouseCoordMode** parameter of the [**Opt**](https://www.autoitscript.com/autoit3/docs/functions/AutoItSetOption.htm) AutoIt function. This is a modified  **MouseClick.au3** script that will use a relative coordinates to the client area of the active window:
```AutoIt
Opt("MouseCoordMode", 2)
$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
WinActivate($hWnd)
MouseClick("left", 250, 300)
```
You can launch this script and see that coordinates of the new drawn dot in the Paint window differs. Usage of the 2nd mode with a relative coordinates to the client area of window will give your more reliable results. It works well both for windowed and full-screen modes of an application. But it may be harder to check the relative coordinates with a tool like CoolPix. Most of these tools measure the absolute screen coordinates.

Click a mouse button and drag a cursor is a common action in video games. AutoIt provides a [MouseClickDrag](https://www.autoitscript.com/autoit3/docs/functions/MouseClickDrag.htm) function that performs this kind of action.  This is a **MouseClickDrag.au3** script that demonstrates a work of the **MouseClickDrag** function into the Paint window:
```AutoIt
$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
WinActivate($hWnd)
MouseClickDrag("left", 250, 300, 400, 500)
```
You will see a drawn line into the Paint window. Start absolute screen coordinates of the line are x=250 and y=300. End coordinates are x=400 and y=500. The same **mouse_event** WinAPI function is used by **MouseClickDrag** one.

Both considered AutoIt functions **MouseClick** and **MouseClickDrag** perform mouse actions in the current active window.

### Mouse Actions in Inactive Window

AutoIt provides [ControlClick.htm](https://www.autoitscript.com/autoit3/docs/functions/ControlClick.htm) function that allows you to emulate mouse click into the inactive window. This is a **ControlClick.au3** script for example:
```AutoIt
$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
ControlClick($hWnd, "", "Afx:00000000FFC20000:81", "left", 1, 250, 300)
```
It performs a mouse click into the inactive or minimized Paint window. The **ControlClick** function is very similar to **ControlSend** one. You should specify the control in which the mouse click will be emulated. The control for drawing in the Paint application have a **Afx:00000000FFC20000:81** classname according to the information from Au3Info tool.

You can notify that **MouseClick** and **ControlClick** functions perform mouse clicks in different dots when the passed input coordinates are the same.  The coordinates in **ControlClick** function are relative coordinates to the control in which the mouse click is performed. This means that mouse click in our example will occur at the point with x=250 and y=300 from the left-up corner of the control for drawing. The coordinate system of the **MouseClick** function is defined by the **MouseCoordMode** AutoIt option.

The job of AutoIt **ControlClick** function is performed by two calls of [**PostMessageW**](https://msdn.microsoft.com/en-us/library/windows/desktop/ms644944%28v=vs.85%29.aspx) WinAPI function:

![ControlClick WinAPI Functions](controlclick-winapi.png)

First call of **PostMessageW** have a **WM_LBUTTONDOWN** input parameter. It allows to emulate mouse button down action. Second call have a **WM_LBUTTONUP** parameter for mouse up emulation correspondingly.

The **ControlClick** function works very unreliable with the minimized DirectX windows. Some of tested applications just ignore this emulation of the mouse actions. Other applications process the actions only after application's window activation. This behavior looks like a limitation of the Windows messaging mechanism that is used by **ControlClick** function.