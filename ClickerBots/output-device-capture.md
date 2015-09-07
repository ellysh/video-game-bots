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

AutoIt provides several functions that simplify the analysis of the current screen state. All these this functions operates with GDI library objects.

Elementary function is the [**PixelGetColor**](https://www.autoitscript.com/autoit3/docs/functions/PixelGetColor.htm). The function allows to get color of the pixel with specified coordinates.

This is example of the **PixelGetColor** usage:
'''
$color = PixelGetColor(100, 100)
MsgBox(0, "", "The hex color is: " & Hex($color, 6))
'''

## Advanced Image Analysis Libraries

TODO: Write a subsection about available Windows API to capture screen
