# Tools

## Programming language

[**AutoIt**](https://www.autoitscript.com/site/autoit) is one of the most popular [**scripting programming languages**](https://en.wikipedia.org/wiki/Scripting_language) for writing clicker bots. It has a lot of features that facilitate automation scripts development even when you have no programming experience:

1. Easy to learn syntax.
2. Detailed online documentation and large community-based support forums.
3. Smooth integration with [**WinAPI**](https://en.wikipedia.org/wiki/Windows_API) functions and third-party libraries.
4. Built-in source code editor.

AutoIt is an excellent tool to start with programming. If you already have some experience with another programming language like C++, C#, Python, etc, you can use this language to implement examples from this chapter. Relevant WinAPI functions that are used by AutoIt will be mentioned.

[**AutoHotKey**](http://ahkscript.org) is a second scripting programming language that can be recommended for starting with game bots development. It has most of AutoIt features but the syntax of this language is more unique. Some things will be simpler to implement with AutoHotKey than with AutoIt. But it may be slightly more difficult to learn.

There are a lot of examples and guides about game bots development with both AutoIt and AutoHotKey languages on the Internet. Thus, you are free to choose those tools you like the most. We will use AutoIt language in this chapter.

## Image Processing Libraries

AutoIt language has a powerful support of the image analyzing methods like PixelChecksum and PixelSearch functions. But there are two third-party libraries that will be extremely helpful in this domain:

1. [**ImageSearch**](https://www.autoitscript.com/forum/topic/148005-imagesearch-usage-explanation) this library allows you to search a specified picture sample on the game application screen.

2. [**FastFind**](https://www.autoitscript.com/forum/topic/126430-advanced-pixel-search-library/) this library provides advanced methods for searching regions on the game application screen that contain closest to specified number of [**pixels**](https://en.wikipedia.org/wiki/Pixel) of the given color. Also it allows you to find a pixel of the given color, closest to the given point.

## Image Analyzing Tool

It will be helpful to check the image parameters like pixel color or pixel coordinates manually. This task appears when you try to debug a bot application and check a correctness of the image processing algorithms.

There are plenty of tools for taking pixel colors from the screen and printing current coordinates of the mouse cursor. You can easily find same tools with Google. I use a [**CoolPix**](https://www.colorschemer.com/colorpix_info.php) application that solves debugging tasks perfectly.

## Source Code Editors

AutoIt language is distributed with the customized version of SciTE editor. It is great for programming and debugging AutoIt scripts. But more universal editor like [**Notepad++**](https://notepad-plus-plus.org) will be suitable if you use another programming language like Python or AutoHotKey. [**Microsoft Visual Studio**](https://www.visualstudio.com/en-us/products/visual-studio-express-vs.aspx) will be the best choice for developers who prefer C++ and C# languages.

## API Hooking

We will develop example applications using high level language. The language encapsulates calls to WinAPI functions with simplified interface. But it is necessary to know which WinAPI functions have been actually used in the examples. It will allow you to understand algorithms better. Moreover, when you know the exact WinAPI function you can interact with it directly using your favorite programming language.

There are a lot of tools that provide [**hooking**]((https://en.wikipedia.org/wiki/Hooking)) the application's calls to system libraries technique. I used the freeware [**API Monitor v2**](http://www.rohitab.com/apimonitor) application. It allows you to filter all hooked calls, gather information of the process, decode input/output parameters of the functions and view/edit process memory. Full list of features is available on developers website.