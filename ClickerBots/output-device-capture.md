# Output Devices Capture

## Windows Graphics Device Interface

The Graphics Device Interface (GDI) is one of the basic Windows operation system components that responses to work with the graphical objects. All graphical elements of a typical application's window are constructed using objects. Examples are Device Contexts, Bitmaps, Brushes, Colors and Fonts.

This illustration represent relationship between an application and basic graphical objects:

![GDI Scheme](gdi-scheme2.png)

The core concept of the GDI library is a Device Context (DC). The DC is an abstraction that allows developers to operate with graphical objects in one universal way for all supported devices. Examples of devices are display, printer, plotter and etc. Also DC allows to prepare a drawing surface in a memory before sending it to output device. This approach allows to significantly increase a performance of the drawing operations.

You can see the DC of two application windows in illustration. Also this is a DC of the entire screen that contains all visible elements of the Windows desktop. DC is a structure in a memory. Developers can interact with this kind of structure only through a Windows API functions. Each DC contain a Device Depended Bitmap (DDB). Bitmap is a in-memory representation of the drawing surface. Any manipulation of the graphic objects in the DC affects the bitmap. Thus, bitmap displays a result of all performed operations.

Bitmap consist of rectangle of pixels. Each pixel have two paramters that are coodinates and color. The compliance of the paramters are defined by two dimensional array. Indexes of the array's element defines a pixel's coordinates. Numeric value of the element defines a code of color in the color-palette that is associated with the bitmap. You should process this array pixel-by-pixel for analysing a bitmap.

The prepared DC should be passed to the device specific library for example Vga.dll. The library transforms DC data to the device driver's representation. Then the image able to be displayed or printed on the output device.

## AutoIt Analysis Functions

## Advanced Image Analysis Libraries

TODO: Write a subsection about available Windows API to capture screen
