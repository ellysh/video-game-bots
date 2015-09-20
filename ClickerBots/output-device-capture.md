# Output Devices Capture

## Windows Graphics Device Interface

The Graphics Device Interface ([GDI](https://en.wikipedia.org/wiki/Graphics_Device_Interface)) is one of the basic Windows operation system components that responses to work with the graphical objects. All graphical elements of a typical application's window are constructed using the objects. Examples of the objects are Device Contexts, Bitmaps, Brushes, Colors and Fonts.

This scheme represents relationship between the graphical objects and devices:

![GDI Scheme](gdi-scheme2.png)

The core concept of the GDI library is a Device Context ([DC](https://msdn.microsoft.com/en-us/library/windows/desktop/dd162467%28v=vs.85%29.aspx)). The DC is an abstraction that allows developers to operate with graphical objects in one universal way for all supported devices. Examples of devices are display, printer, plotter and etc. All operations with DC are performed into a memory before sending a result to the output device.

You can see the DC of two application windows in the scheme. Also this is a DC of the entire screen that represents overall Windows desktop. The screen DC is gotten by composing of DC content of all visible windows and desktop elements.

DC is a structure in a memory. Developers can interact with this kind of structure only through a Windows API functions. Each DC contain a Device Depended Bitmap (DDB). [Bitmap](https://msdn.microsoft.com/en-us/library/windows/desktop/dd162461%28v=vs.85%29.aspx) is a in-memory representation of the drawing surface. Any manipulation of the graphic objects in the DC affects the bitmap. Thus, bitmap displays a result of all performed operations.

Simplistically, bitmap consist of rectangle of pixels. Each pixel have two parameters that are coordinates and color. The compliance of the parameters are defined by two dimensional array. Indexes of the array's element defines a pixel's coordinates. Numeric value of the element defines a code of color in the color-palette that is associated with the bitmap. You should process this array pixel-by-pixel for analyzing a bitmap.

The prepared DC should be passed to the device specific library for example Vga.dll. The library transforms DC data to the device driver's representation. Then the image able to be displayed or document able to be printed on the output device.

## AutoIt Analysis Functions

### Analysis of Specific Pixel

AutoIt provides several functions that simplifies the analysis of the current screen state. All these functions operate with the GDI library objects.

The Autoit pixel

The coordinate systems that is used by AutoIt pixel analyzing functions are totally the same as coordinate systems for mouse functions. This is a list of the avaliable coordinate systems:

0\. Relative coordinates to the specified window.<br/>
1\. Absolute screen coordinates. This mode is used by default.<br/>
2\. Relative coordinates to the client area of the specified window.

You can use the same [**Opt**](https://www.autoitscript.com/autoit3/docs/functions/AutoItSetOption.htm) AutoIt function with **PixelCoordMode** parameter to switch between the coordinate systems. This is example to switch the relative coordinates to the client area mode:
```
Opt("PixelCoordMode", 2)
```
Elementary function to get pixel color is the [**PixelGetColor**](https://www.autoitscript.com/autoit3/docs/functions/PixelGetColor.htm). Input parameters of the function are pixel coordinates. Return value of the function is decimal code of a color. This is example **PixelGetColor.au3** script with usage of the function:
```
$color = PixelGetColor(200, 200)
MsgBox(0, "", "The hex color is: " & Hex($color, 6))
```
You will see a message box with a text after launching the script. This is example of the possible text message:
```
The text color is: 0355BB
```
This means that the pixel with absolute coordinates equal to x=200 and y=200 have a color value 0355BB in a [hex representation](http://www.htmlgoodies.com/tutorials/colors/article.php/3478951). The color will be changed if you activate another application window that covers coordinates x=200 and y=200. This means that **PixelGetColor** doesn't analyze a specific window but instead it provides an information about entire Windows desktop. 

This screen-shoot of API Monitor application with hooked Windows API calls of the script:

![PixelGetColor WinAPI Functions](winapi-get-pixel.png)

You can see that AutoIt **PixelGetColor** wraps the [**GetPixel**](https://msdn.microsoft.com/en-us/library/windows/desktop/dd144909%28v=vs.85%29.aspx) Windows API function. Also a [**GetDC**](https://msdn.microsoft.com/en-us/library/windows/desktop/dd144871%28v=vs.85%29.aspx) WinAPI function is called before the **GetPixel** function. The input parameter of the **GetDC** function equal to NULL. This means that a desktop DC is selected to operating. Let's try to avoid this limitation and specify a window to analyze. It allows our script to analyze not active window that is overlapped by another one.

This is a **PixelGetColorWindow.au3** script that uses a third parameter of the **PixelGetColor** function to specify a window to analyze:
```
$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
$color = PixelGetColor(200, 200, $hWnd)
MsgBox(0, "", "The hex color is: " & Hex($color, 6))
```
This script should analyze a pixel into the Paint application window. The expected value of the pixel color is **FFFFFF** (white). But if you overlap the Paint window by another window with a not white color the result of script executing will differ. The API Monitor log of Windows API function calls for **PixelGetColorWindow.au3** script will be the same as for **PixelGetColor.au3** one. The NULL parameter is still passed to the **GetDC** WinAPI function. It looks like a bug of the **PixelGetColor** function implementation in AutoIt v3.3.14.1 version. Probably, it will be fixed in a next AutoIt version. But we still need to find a solution of the reading from a specific window issue.

A problem of **PixelGetColorWindow.au3** script is an incorrect use of **GetDC** WinAPI function. We can avoid it if all steps of the **PixelGetColor** Autoit function will be perform manually through Windows API calls.

This algorithm is implemented in a **GetPixel.au3** script:
```
#include <WinAPIGdi.au3>

$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
$hDC = _WinAPI_GetDC($hWnd)
$color = _WinAPI_GetPixel($hDC, 200, 200)
MsgBox(0, "", "The hex color is: " & Hex($color, 6))
```
**WinAPIGdi.au3** header is used in the script. It provides a **_WinAPI_GetDC** and **_WinAPI_GetPixel** wrappers to the corresponding WinAPI functions. You will see a message box with correct color measurement after the script launch. The result of the script work is not depend of the windows overlapping. 

But the script will not work properly if you minimize the Paint window. The script will show the same result equal to white color if you minimize the window. It seems correctly. But try to change a color of a canvas to red for example. If the window is in normal mode the script returns a correct red color. If the window is minimized the script returns a white color. This happens because a minimized window have a client area with a zero size. Therefore, the bitmap that is selected in the minimized window's DC does not contain an information about the client area.

This is a **GetClientRect.au3** script to measure a client area size of the minimized window:
```
#include <WinAPI.au3>

$hWnd = WinGetHandle("[CLASS:MSPaintApp]")
$tRECT = _WinAPI_GetClientRect($hWnd)
MsgBox(0, "Rect", _
            "Left: " & DllStructGetData($tRECT, "Left") & @CRLF & _
            "Right: " & DllStructGetData($tRECT, "Right") & @CRLF & _
            "Top: " & DllStructGetData($tRECT, "Top") & @CRLF & _
            "Bottom: " & DllStructGetData($tRECT, "Bottom"))
```
Each of Left, Right, Top and Bottom variables will be equal to 0 for the minimized Paint window. You can compare this result with the window in a normal mode.

The possible solution to avoid this limitation is restoring window in a transparent mode and copying a window's client area by a [**PrintWindow**](https://msdn.microsoft.com/en-us/library/dd162869%28VS.85%29.aspx) WinAPI function. You able to analyze a copy of the window's client by the **_WinAPI_GetPixel** function. This technique described in details [here](http://www.codeproject.com/Articles/20651/Capturing-Minimized-Window-A-Kid-s-Trick).

### Analysis of Pixels Changing

AutoIt provide functions that allows you to analyze happened changes on a game screen. The **PixelGetColor** function relies on predefine pixel coordinates. But this kind of analyzis does not work for situation when a picture on a screen is dynamically changing. The [**PixelSearch**](https://www.autoitscript.com/autoit3/docs/functions/PixelSearch.htm) can help in this case.

This is a **PixelSearch.au3** script to demonstrate the function work:
```
$coord = PixelSearch(0, 207, 1000, 600, 0x000000)
If @error == 0 then
	MsgBox(0, "", "The black point coord: x = " & $coord[0] & " y = " & $coord[1])
else
	MsgBox(0, "", "The black point not found")
endif
```
The script looks for pixel with **0x000000** (black) color in a rectangle between two points: x=0 y=200 and x=1000 y=600. If the pixel have been found a message with coordinates will be displayed. Otherwise, a not found result message will be displayed. The [**@error** macro](https://www.autoitscript.com/autoit3/docs/functions/SetError.htm) is used here to distinguish a success of the **PixelSearch** function. You can launch a Paint application and draw a black point on the white canvas. If you launch the script afterwards you will get coordinates of the black point. The Paint window should be active and not overlapped for proper work of the script.

Now we will investigate internal WinAPI calls that is used by the **PixelSearch** function. Let's launch the **PixelSearch.au3** script in API Monitor application. Search a "0, 207" text in a "Summary" window when the script have finished. You will find a call of [**StretchBlt**](https://msdn.microsoft.com/en-us/library/windows/desktop/dd145120%28v=vs.85%29.aspx) function:

![PixelSearch WinAPI Functions](winapi-pixel-search.png)

TODO: Write about PixelSearch and PixelChecksum function. Write examples of usage it.

## Advanced Image Analysis Libraries

## DirectX Output Capture
