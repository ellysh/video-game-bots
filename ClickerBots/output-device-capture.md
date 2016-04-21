# Output Devices Capture

## Windows Graphics Device Interface

[**Graphics Device Interface**](https://en.wikipedia.org/wiki/Graphics_Device_Interface) (GDI) is one of basic components of Windows OS. This component responds for representing graphical objects and transmitting them to output devices. All visual elements of typical application's window are constructed using graphical objects. Examples of these objects are Device Contexts, Bitmaps, Brushes, Colors and Fonts.

This scheme represents a relationship between graphical objects and devices:

![GDI Scheme](gdi-scheme.png)

Core concept of the GDI is [**Device Context**](https://msdn.microsoft.com/en-us/library/windows/desktop/dd162467%28v=vs.85%29.aspx) (DC). DC is an abstraction that allows developers to operate with graphical objects in one way, which does not depend on a type of output device. Examples of output devices are display, printer, plotter and etc. All operations with DC are performed into memory. Then result of these operations is sent to the output device.

You can see two DCs in the scheme. They store a content of two windows. Also there is a DC of the entire screen that store a content of overall desktop. OS should obtain the screen DC before sending it to the display. This DC can be gathered by composing DCs of all visible windows and DCs of desktop visual elements like taskbar. Another case is when you want to print a document. OS need a DC of text editor's window to send it to the printer. All other DCs are not used in this case.

DC is a structure in memory. Developers can manipulate it only via WinAPI functions. Each DC contains [**Device Depended Bitmap**](https://msdn.microsoft.com/en-us/library/windows/desktop/dd183561%28v=vs.85%29.aspx) (DDB). [**Bitmap**](https://msdn.microsoft.com/en-us/library/windows/desktop/dd162461%28v=vs.85%29.aspx) is in-memory representation of a drawing surface. All manipulations with graphic objects in the DC affects DC's bitmap. Therefore, the bitmap contains a result of all performed operations.

Bitmap consist of a rectangle of pixels and meta information. Each pixel has two parameters: pixel's coordinates and its color. Compliance of these parameters are defined by two dimensional array. Indexes of array's element defines pixel's coordinates. Numeric value of this element defines the color code in a color-palette that is associated with this bitmap. The array should be processed sequentially pixel-by-pixel for analyzing the bitmap.

When DC has been prepared for the output, it should be passed to the device specific library. Vga.dll is an example of this kind of libraries for screen device. The library transforms DC's data to the representation of a device driver. It allows the driver to show screen DC's content on the display device.

## AutoIt Analysis Functions

### Analysis of Specific Pixel

AutoIt provides several functions that simplifies analysis of a current screen picture. All these functions operate with the GDI library objects.

There is a set of coordinate systems that can be used by AutoIt functions for pixels analyzing. This set is totally the same as the set of coordinate systems for AutoIt mouse functions. This is a list of available coordinate systems:

| Mode | Description |
| -- | -- |
| 0 | Relative coordinates to the specified window |
| 1 | Absolute screen coordinates. This mode is used by default. |
| 2 | Relative coordinates to the client area of the specified window |

You can use the same [`Opt`](https://www.autoitscript.com/autoit3/docs/functions/AutoItSetOption.htm) AutoIt function with `PixelCoordMode` parameter to switch between the coordinate systems for pixels analyzing. This is an example of enabling the mode of relative coordinates to the client area:
```AutoIt
Opt("PixelCoordMode", 2)
```
Elementary AutoIt function to get pixel's color is  [`PixelGetColor`](https://www.autoitscript.com/autoit3/docs/functions/PixelGetColor.htm). Input parameters of this function are pixel's coordinates. Return value is a decimal code of pixel's color. This is a sample [`PixelGetColor.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/PixelGetColor.au3) script that demonstrates usage of the function:
```AutoIt
$color = PixelGetColor(200, 200)
MsgBox(0, "", "The hex color is: " & Hex($color, 6))
```
You will see a message box with a color code after launching this script. Text in the message box should look like this: "The text color is: 0355BB". This means that the pixel with absolute coordinates equal to x=200 and y=200 has a color value "0355BB" in the [hexadecimal representation](http://www.htmlgoodies.com/tutorials/colors/article.php/3478951). We use the [`Hex`](https://www.autoitscript.com/autoit3/docs/functions/Hex.htm) AutoIt function to transform a result of `PixelGetColor` from decimal code to hexadecimal one. Color representation in hexadecimal is widespread. The most of graphical editors and tools use it. Resulting color value "0355BB" is changed in case you switch to another window, which covers coordinates x=200 and y=200. This means that `PixelGetColor` function does not analyze a specific window but the entire desktop picture instead.

This is a screenshoot of API Monitor application that hooks WinAPI calls of `PixelGetColor.au3` script:

![PixelGetColor WinAPI Functions](winapi-get-pixel.png)

You can see that AutoIt `PixelGetColor` function uses [`GetPixel`](https://msdn.microsoft.com/en-us/library/windows/desktop/dd144909%28v=vs.85%29.aspx) WinAPI function. Also [`GetDC`](https://msdn.microsoft.com/en-us/library/windows/desktop/dd144871%28v=vs.85%29.aspx) WinAPI function is called before the `GetPixel` one. Input parameter of the `GetDC` function equals to "NULL". This means that desktop's DC has been selected for further operations. We can avoid this limitation by a specifying a window to analyze. This allows our script to analyze inactive windows that are overlapped by another ones.

This is a [`PixelGetColorWindow.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/PixelGetColorWindow.au3) script, which passes third parameter to the `PixelGetColor` function. This allows us to specify a certain window for analysis:
```AutoIt
$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
$color = PixelGetColor(200, 200, $hWnd)
MsgBox(0, "", "The hex color is: " & Hex($color, 6))
```
This script should analyze pixel's color into Paint application's window even this window is overlapped. Expected value of pixel's color is "FFFFFF" (white). But if you overlap the Paint window by another one, which has not white color, the result of script execution is different. API Monitor application shows us that both `PixelGetColorWindow.au3` and `PixelGetColor.au3` scripts have totally the same sequence of WinAPI functions calls. 

The "NULL" parameter is still passed to the `GetDC` WinAPI function. It looks like a bug of the `PixelGetColor` function implementation in AutoIt v3.3.14.1 version. Probably, this will be fixed in the next AutoIt version. But we still need to find a solution to analyze pixel's color of a specific window.

Issue of `PixelGetColor` function now is incorrect usage of the `GetDC` WinAPI function. If we repeat all WinAPI calls of `PixelGetColor` function directly, we avoid this issue and pass correct parameter to the `GetDC`.

This is a [`GetPixel.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/GetPixel.au3) script, which demonstrates direct calls of WinAPI functions:
```AutoIt
#include <WinAPIGdi.au3>

$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
$hDC = _WinAPI_GetDC($hWnd)
$color = _WinAPI_GetPixel($hDC, 200, 200)
MsgBox(0, "", "The hex color is: " & Hex($color, 6))
```
This script starts by the `include` keyword, which appends the `WinAPIGdi.au3` file. This file provides `_WinAPI_GetDC` and `_WinAPI_GetPixel` wrappers to the corresponding WinAPI functions. If you launch the script, you get the message box with the correct code of pixel's color. This means that result of `GetPixel.au3` script does not depend on windows overlapping.

There is still one issue with the `GetPixel.au3` script. If you minimize window of Paint application, this script returns white pixel's color. You can change a color of Paint window's canvas to red and test this behavior of the script. At the same time, the `GetPixel.au3` script returns red color of a pixel correctly in case Paint's window is in a normal mode (not minimized). Reason of this issue is the minimized windows do not have a client area. Size of the client area of this kind of windows is zeroed. Therefore, a bitmap, which is selected in the DC of minimized window, is empty.

This is a [`GetClientRect.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/GetClientRect.au3) script. This script measures a size of window's client area:
```AutoIt
#include <WinAPI.au3>

$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
$tRECT = _WinAPI_GetClientRect($hWnd)
MsgBox(0, "Rect", _
            "Left: " & DllStructGetData($tRECT, "Left") & @CRLF & _
            "Right: " & DllStructGetData($tRECT, "Right") & @CRLF & _
            "Top: " & DllStructGetData($tRECT, "Top") & @CRLF & _
            "Bottom: " & DllStructGetData($tRECT, "Bottom"))
```
Each of `Left`, `Right`, `Top` and `Bottom` variables is equal to zero for Paint window in minimized mode. You can compare results of this script for both windows in minimized and normal mode. The results differs.

There is a possible solution to avoid this limitation. You can restore a minimized window in the transparent mode. Then you can copy to memory DC a client area of this window. The [`PrintWindow`](https://msdn.microsoft.com/en-us/library/dd162869%28VS.85%29.aspx) WinAPI function provides this kind of copy operation. When you have got a copy of the client area, you are able to analyze it with the `_WinAPI_GetPixel` function. This approach is described in details in this [article](http://www.codeproject.com/Articles/20651/Capturing-Minimized-Window-A-Kid-s-Trick).

### Analysis of Pixels Changing

AutoIt provides functions that allow you to analyze changes that happen on a screen. We have already considered the `PixelGetColor` function. This function requires precise coordinates of an analyzing pixel. But you do not know these coordinates in case of dynamically changed pictures. [`PixelSearch`](https://www.autoitscript.com/autoit3/docs/functions/PixelSearch.htm) is another AutoIt function that can help us in this case.

This is a [`PixelSearch.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/PixelSearch.au3) script that demonstrates usage of this function:
```AutoIt
$coord = PixelSearch(0, 207, 1000, 600, 0x000000)
If @error = 0 then
    MsgBox(0, "", "The black point coord: x = " & $coord[0] & " y = " & $coord[1])
else
    MsgBox(0, "", "The black point not found")
endif
```
The script searches a pixel with the `0x000000` (black) color inside a rectangle between two points with coordinates x=0, y=207 and x=1000, y=600. The message with coordinates of found pixel is displayed in case the search has succeed. Otherwise, a message about unsuccessful result will be displayed. The [`error`](https://www.autoitscript.com/autoit3/docs/functions/SetError.htm) macro is used here to distinguish success of the `PixelSearch` function. 

To test this script, you can use the Paint application. Draw a black point on the white canvas. If you launch the script, you get coordinates of the black point. The Paint window should be active and not be overlapped for proper work of the script.

Now we will check WinAPI functions that are called internally by the `PixelSearch` function. You should launch the `PixelSearch.au3` script from API Monitor application. Then search the "0, 207" text in the "Summary" window when the script has finished. You will find a call of [`StretchBlt`](https://msdn.microsoft.com/en-us/library/windows/desktop/dd145120%28v=vs.85%29.aspx) WinAPI function:

![PixelSearch WinAPI Functions](winapi-pixel-search.png)

`StretchBlt` function performs copying a bitmap from desktop's DC to the compatible DC, which is created in memory. You can verify this assumption easily. Compare input parameters and  returning values of the `GetDC`, [`CreateCompatibleDC`](https://msdn.microsoft.com/en-us/library/windows/desktop/dd183489%28v=vs.85%29.aspx) and `StretchBlt` functions. The result of `GetDC` function is used to create a compatible DC with [`CreateCompatibleDC`](https://msdn.microsoft.com/en-us/library/windows/desktop/dd183488%28v=vs.85%29.aspx) function. Then the `StretchBlt` function is used for copying.

Next step of the `PixelSearch` function is a call of [`GetDIBits`](https://msdn.microsoft.com/en-us/library/windows/desktop/dd144879%28v=vs.85%29.aspx) function. This function performs a conversion of pixels from DDB format to the [**Device Independent Bitmap**](https://msdn.microsoft.com/en-us/library/windows/desktop/dd183562%28v=vs.85%29.aspx) (DIB).

DIB is the most convenient format for analysis because it allows us to process bitmap as regular array. Probable next step of the `PixelSearch` function is to check colors of pixels in this DIB. WinAPI functions are not needed to perform this kind of checking. Therefore, we do not see any other calls in the log of API Monitor. You can find sample implementation of the image capturing algorithm that is written in C++ [here](https://msdn.microsoft.com/en-us/library/dd183402%28v=VS.85%29.aspx). This sample allows you to understand internals of the `PixelSearch` function better.

The `PixelSearch` function has a window handle input parameter, which has a default value. We can ignore this value. In this case, entire desktop is used for searching a pixel. Otherwise, the function analyzes pixels of specified window only.

This is a [`PixelSearchWindow.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/PixelSearchWindow.au3) script. It demonstrates how to use the window handle parameter:
```AutoIt
$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
$coord = PixelSearch(0, 207, 1000, 600, 0x000000, 0, 1, $hWnd)
If @error = 0 then
    MsgBox(0, "", "The black point coord: x = " & $coord[0] & " y = " & $coord[1])
else
    MsgBox(0, "", "The black point not found")
endif
```
The script should analyze overlapped Paint window too but this does not happen. We face the same bug as present in `PixelGetColor` AutoIt function. API Monitor log for this script is still the same as the log for `PixelSearch.au3` script. This means that the `GetDC` function still receives the "NULL" input parameter. Therefore, the `PixelSearch` function always processes a desktop DC. You can try to avoid the bug by usage of WinAPI functions directly. This way was considered for `PixelGetColor` function above.

[`PixelChecksum`](https://www.autoitscript.com/autoit3/docs/functions/PixelChecksum.htm) is another AutoIt function that we can use to analyze dynamically changing pictures. `PixelGetColor` and `PixelSearch` functions gather information about the specific pixel. The `PixelChecksum` works in different manner. This function allows you to detect that something has been changed inside the specified region of a screen. This kind of analysis can be useful when you implement algorithms of bot's reactions for game events.

This is a [`PixelChecksum.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/PixelChecksum.au3) script with typical use case of this function:
```AutoIt
$checkSum = PixelChecksum(0, 0, 50, 50)

while $checkSum = PixelChecksum(0, 0, 50, 50)
    Sleep(100)
wend

MsgBox(0, "", "Something in the region has changed!")
```
This script shows you a message box in case something is changed on a desktop inside the region between two points with coordinates x=0, y=0 and x=50, y=50. We calculate initial value of the checksum at the first line of the script. Further, checksum's value is recalculated and checked every 100 milliseconds into the [`while`](https://www.autoitscript.com/autoit3/docs/keywords/While.htm) loop. The `while` loop continues until the checksum value is still the same.

Now we will consider how the `PixelChecksum` function works internally. API Monitor shows us exact the same sequence of WinAPI function calls as it happened for `PixelSearch` function. This means that AutoIt uses the same algorithm for both `PixelChecksum` and `PixelSearch` functions to get a DIB. Next step is calculation of a checksum for this DIB with selected algorithm. You can select either [**ADLER**](https://en.wikipedia.org/wiki/Adler-32) or [**CRC32**](https://en.wikipedia.org/wiki/Cyclic_redundancy_check) algorithm to calculate a checksum. Differences between these algorithms are speed and reliability. CRC32 algorithm works slower but it able to detect changes of pixels more precisely.

All considered AutoIt functions are able to process pictures in fullscreen DirectX windows.

## Advanced Image Analysis Libraries

### FastFind Library

We have considered functions for screen analysis that are provided by AutoIt itself. Now we will consider extra functions that are provided by third-party libraries.

[**FastFind**](https://www.autoitscript.com/forum/topic/126430-advanced-pixel-search-library/) library provides advanced functions for searching pixels on screen. You are able to call library's functions from both AutoIt scripts and C++ applications.

These are steps to call library's functions from AutoIt script:

1\. Create a project directory for your AutoIt script. For example, this directory has the `FFDemo` name. 

2\. Copy the `FastFind.au3` file from FastFind archive to the `FFDemo` directory.

3\. Copy either `FastFind.dll` or `FastFind64.dll` file from the library archive to the `FFDemo` directory. The `FastFind64.dll` file should be used for x64 Windows systems. Otherwise, you should choose the `FastFind.dll` file.

4\. Include the `FastFind.au3` file in your AutoIt script by `include` keyword:
```AutoIt
#include "FastFind.au3"
```
Now you are able to call functions of the FastFind library from your AutoIt script.


These are steps to call functions of FastFind from C++ application:

1\. Download a preferable C++ compiler. [**Visual Studio Community IDE**](https://www.visualstudio.com/en-us/products/visual-studio-express-vs.aspx#) from Microsoft website or [**MinGW**](http://nuwen.net/mingw.html) environment.

2\. Install the C++ compiler on your computer.

3\. Create a source file with `test.cpp` name in case you use the MinGW compiler. Create the "Win32 Console Application" project in case you use Visual Studio IDE.

4\. This is a content of the [`test.cpp`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/FastFindCpp/test.cpp) source file:
```C++
#include <iostream>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

using namespace std;

typedef LPCTSTR(CALLBACK* LPFNDLLFUNC1)(void);

HINSTANCE hDLL;               // Handle to DLL
LPFNDLLFUNC1 lpfnDllFunc1;    // Function pointer
LPCTSTR uReturnVal;

int main()
{
    hDLL = LoadLibraryA("FastFind");
    if (hDLL != NULL)
    {
        lpfnDllFunc1 = (LPFNDLLFUNC1)GetProcAddress(hDLL,
            "FFVersion");
        if (!lpfnDllFunc1)
        {
            // handle the error
            FreeLibrary(hDLL);
            cout << "error" << endl;
            return 1;
        }
        else
        {
            // call the function
            uReturnVal = lpfnDllFunc1();
            cout << "version = " << uReturnVal << endl;
        }
    }
    return 0;
}
```
5\. Copy the `FastFind.dll` file into project's directory.

6\. In case you use MinGW, create the file with [`Makefile`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/FastFindCpp/Makefile) name, which contains these two lines:
```Makefile
all:
    g++ test.cpp -o test.exe
```
7\. Build the application with `make` command for MinGW and *F7* hotkey for Visual Studio.

Now you have an executable file. The message with a version number of the FastFind library is printed to console when you launch this executable file. This is an example of the output to console:
```
version = 2.2
```
We have used an [explicitly library linking](https://msdn.microsoft.com/en-us/library/784bt7z7.aspx) approach here. Alternative approach is an [implicitly library linking](https://msdn.microsoft.com/en-us/library/d14wsce5.aspx). You can use this implicitly linking to call functions of FastFind library. But there is one limitation in this case. You should use exactly the same C++ compiler version that has been used by the developer of FastFind library.

Now we will consider possible tasks that we can solve with FastFind library. First task is to search an area that contains the best number of pixels with the given color. This task is solved by the `FFBestSpot` function. Let us consider an example.

This is a screenshoot of popular MMORPG game Lineage 2:

![FFBestSpot Example](ffbestspot.png)

You can see two models on this screenshot. First one is the player character, which has the "Zagstruck" name. Second one is the monster with the "Wretched Archer" name. We can use the `FFBestSpot` function to figure out monster's coordinates on the screen. But we should choose an appropriate color of pixels that should be found by this function. Best pixels to search are the text labels, which you can see under both models. Text labels are not depend on light effects or camera scale. Therefore, searching coordinates of these text labels will provide us the most reliable results. Monster has an extra green text label under it. This label is a perfect search target for us.

Also you can use the models itself as the search targets. But the algorithm of `FFBestSpot` function makes wrong decisions very often in this case. This happens because the models are affected by shadows, light effects and also they can rotate. Wide variation of pixel colors is a consequent of all these effects.

This is the [`FFBestSpot.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/FastFindAu3/FFBestSpot.au3) script that searches the green text on the screen and shows message box with text's coordinates:
```AutoIt
#include "FastFind.au3"

Sleep(5 * 1000)

const $sizeSearch = 80
const $minNbPixel = 50
const $optNbPixel = 200
const $posX = 700
const $posY = 380

$coords = FFBestSpot($sizeSearch, $minNbPixel, $optNbPixel, $posX, $posY, _
                     0xA9E89C, 10)

if not @error then
    MsgBox(0, "Coords", $coords[0] & ", " & $coords[1])
else
    MsgBox(0, "Coords", "Match not found.")
endif
```
You can launch this script, switch to the window with the Lineage 2 screenshot and get coordinates of the green text after five seconds. The script sleeps five second after launching. This delay gives you a time to switch to the window that you want. The `FFBestSpot` function is called after the delay. This is a list of parameters that are passed to this function:

| Parameter | Description |
| -- | -- |
| `sizeSearch` | Width and height of the area to search |
| `minNbPixel` | Minimum number of pixels with a given color in the area |
| `optNbPixel` | Optimal number of pixels with a given color in the area |
| `posX` | X coordinate of a proximity position of the area |
| `posY` | Y coordinate of a proximity position of the area |
| `0xA9E89C` | Pixels' color in hexadecimal representation |
| `10` | Shade variation parameter from 0 to 255 that defines allowed deviation from the specified color for red, blue and green color's components |

Return value of the `FFBestSpot` function is an array with three elements in case of success and zero value in case of failure. First two elements of the array are X and Y coordinates of found area. Third element is a number of matched pixels in this area. You can find detailed information about this function in the documentation of FastFind library.

`FFBestSpot` function is an effective tool to search the interface elements like progress bars, icons, windows and text. Also you can try to search 2D models with it but a result will not be reliable enough.

Second task, which we can solve with FastFind library, is localization of changes on the screen. The `FFLocalizeChanges` function provides an appropriate algorithm for this case. We can use Notepad application to demonstrate how this function works. Example AutoIt script will determine the coordinates of the new text, which you have typed in the Notepad window.

This is a [`FFLocalizeChanges.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/FastFindAu3/FFLocalizeChanges.au3) script:
```AutoIt
#include "FastFind.au3"

Sleep(5 * 1000)
FFSnapShot(0, 0, 0, 0, 0)

MsgBox(0, "Info", "Change a picture now")

Sleep(5 * 1000)
FFSnapShot(0, 0, 0, 0, 1)

$coords = FFLocalizeChanges(0, 1, 10)

if not @error then
    MsgBox(0, "Coords", "x1 = " & $coords[0] & ", y1 = " & $coords[1] & _
           " x2 = " & $coords[2] & ", y2 = " & $coords[3])
else
    MsgBox(0, "Coords", "Changes not found.")
endif
```
This is the algorithm to launch this script:

1. Launch Notepad application and maximize its window.
2. Launch the `FFLocalizeChanges.au3` script.
3. Switch to Notepad's window. 
4. Wait until the message box with the "Change a picture now" text appear.
5. Type several symbols in the Notepad window.
6. Wait until a message box with coordinates of the added text appear. There is a five seconds delay between showing this message box and previous one.

Functions of the FastFind library operate with **SnapShots**. SnapShot is a copy of the screen in memory. When we use the `FFBestSpot` function, the SnapShot for analyzing is made implicitly. But we should make SnapShots explicitly in case of the `FFLocalizeChanges` function usage. This function compares two SnapShots to find how they are differ.

First SnapShot is made by the `FFSnapShot` function in five seconds after launching the `FFLocalizeChanges.au3` script. This five seconds delay is needed for you to switch to the Notepad window. Second SnapShot is made in five seconds after the showing a message box with "Change a picture now" text. This delay is needed for you to type the text.

The `FFSnapShot` function takes these parameters:

| Parameter | Description |
| -- | -- |
| `0` | X coordinate of the left-top SnapShot area's corner |
| `0` | Y coordinate of the left-top SnapShot area's corner |
| `0` | X coordinate of the right-bottom SnapShot area's corner |
| `0` | Y coordinate of the right-bottom SnapShot area's corner. The whole screen is copied in case all coordinates are zeroed. |
| `0` or `1` | Last parameter is a number of the SnapShot slot. The maximum slot number is 1023. |

This function does not have any return value.

The `FFLocalizeChanges` function, which compares two SnapShots, takes three parameters:

| Parameter | Description |
| -- | -- |
| `0` | Slot number of the first SnapShot to compare |
| `1` | Slot number of the second SnapShot to compare |
| `10` | Shade variation parameter that works in the same way as for `FFBestSpot` function one |

Return value of this function is an array with five elements in case of success and zero value in case of failure. First four elements of the array are left, top, right and bottom coordinates of the changed region. Last array's element is a number of the changed pixels.

The `FFLocalizeChanges` function is an effective alternative for the `PixelChecksum` function, which are provided by AutoIt. The `FFLocalizeChanges` is more reliable and provides more information about happened changes.

Functions of the FastFind library are able to work with overlapped windows. But they do not work with minimized windows. Most of the functions have window handle parameter, which allows you to specify the window for analyzing. Also all these functions work correctly with DirectX windows in the fullscreen mode.

### ImageSearch Library

[**ImageSearch**](https://www.autoitscript.com/forum/topic/148005-imagesearch-usage-explanation) is a library that solves only one specific task. It allows to find a specified picture in an entire screen or in the specified region of a screen. Steps to access the library's functions from AutoIt script are similar to FastFind library ones:

1. Create a project directory for your project for example with `ImageSearchDemo` name.
2. Copy `ImageSearch.au3` file into the `ImageSearchDemo` directory.
3. Copy `ImageSearchDLL.dll` library into the `ImageSearchDemo` directory.
4. Include the `ImageSearch.au3` file into your AutoIt script:
```AutoIt
#include "ImageSearch.au3"
```
Also you can use explicitly library linking approach to compile a C++ application that will use functions of the ImageSearch library. This approach has been described in details for the FastFind library.

We will find a logo picture of the Notepad's window in our demonstration example. First of all you should make a file with the logo picture to search and copy the file to a project's directory. You can use Paint application for preparing a picture. This is an example of a picture that you should get:

![Notepad Logo](notepad-logo.bmp)

This is a [`Search.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ClickerBots/OutputDeviceCapture/ImageSearch/Search.au3) script that performs a searching of the logo picture:
```AutoIt
#include <ImageSearch.au3>

Sleep(5 * 1000)

global $x = 0, $y = 0
$search = _ImageSearch('notepad-logo.bmp', 0, $x, $y, 20)

if $search = 1 then
    MsgBox(0, "Coords", $x & ", " & $y)
else
    MsgBox(0, "Coords", "Picture not found.")
endif
```
These are steps to test `_ImageSearch` function with the script:
1. Launch Notepad application.
2. Launch `Search.au3` script.
3. Switch to the Notepad window.
4. Wait a message box with coordinates of the Notepad logo's picture. It should appear after five seconds since the script has been launched.

If you have faced with issues when launching current version of the library you can download a previous stable version [here](https://github.com/ellysh/ImageSearch).

The `_ImageSearch` function takes these parameters:

| Parameter | Description |
| -- | -- |
| `'notepad-logo.bmp'` | Path to the file with a picture for searching |
| `0` | This flag defines which coordinates of the resulting picture should be returned. The `0` value matches top-left coordinates of the picture. The `1` value matches coordinates of the picture center. |
| `x` | Variable to write resulting X coordinate |
| `y` | Variable to write resulting Y coordinate |
| `20` | Shade variation parameter that defines a possible colors deviation from the specified picture |

The function returns value of an error code. If any error happens, the zero value is returned. Otherwise, the non zero value is returned.

`_ImageSearch` function performs searching of the specified picture in entire screen. ImageSearch library provides second function with `_ImageSearchArea` name. It allows to search a picture in the specified region of a screen. This is a code snippet of calling `_ImageSearchArea` function instead of the `_ImageSearch` one in the `Search.au3` script:
```AutoIt
$search = _ImageSearchArea('notepad-logo.bmp', 0, 100, 150, 400, 450, $x, $y, 20)
```
Four extra parameters have been added to the function call. These are coordinates of the left-top and right-bottom points of the screen's region. The coordinates of points equal to x1=100 y1=150 and x2=400 y2=450 in the example. Resulting value of the function has the same meaning as for `_ImageSearch` function.

Both functions of the ImageSearch library are able to search only a picture that is present on the screen at the moment. This means for our example that  Notepad's window should not be overlapped or minimized. Also both functions works correctly with fullscreen DirectX windows.

ImageSearch library is a reliable tool for searching immutable images in the game screen like interface elements or immobile 2D models.
