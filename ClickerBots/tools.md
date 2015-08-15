# Tools

## Programming language

[AutoIt](https://www.autoitscript.com/site/autoit) is one of the most popular scripting programming language for writing clicker bots. It have a lot of features that facilitates the automation scripts development even you have not a programming experience:

1. Easy to learn syntax.
2. Detailed online documentation and large community-based support forums.
3. Smooth integration with Windows API functions and third-party libraries.
4. Build-in source code editor.

AutoIt is an excellent tool to start with programming. If you already have an experience with an another programming language like C++, C#, Python and etc you can use it for implementation examples in this chapter. The relevant Windows API functions that are used by AutoIt will be mentioned. 

[AutoHotKey](http://ahkscript.org) is the second scripting language that able to be recommended for starting with game bots development. It have most of the AutoIt features but the syntax of this language more unique. Some things will be simpler to implement with AutoHotKey than with AutoIt. But it may be slightly more difficult for learning.

There are a lot of examples and guides about the game bots development with both AutoIt and AutoHotKey languages in Internet. Thus, you are free to choose the tool that you likes more. We will use AutoIt language in this chapter.

## Image Processing Libraries

AutoIt language have a powerful support of the image analyzing methods like PixelChecksum and PixelSearch functions. But there are two third-party libraries that will be extremely helpful in this domain:

1. [ImageSearch](https://www.autoitscript.com/forum/topic/148005-imagesearch-usage-explanation) this library allows you to search a specified picture sample on the game application screen.

2. [FastFind](https://www.autoitscript.com/forum/topic/126430-advanced-pixel-search-library/) this library suggests an advanced methods for searching regions on the game application screen that contains the best number of pixels of the given color. Also it allows you to find a pixel of the given color, closest to the given point.

## Image Analyzing Tool

It will be helpful to check the image parameters like pixel color or pixel coordinates manually. This task appears when you try to debug a bot application and check a correctness of the image processing algorithms.

There are plenty tools for picking the pixel colors at the screen and printing current coordinates of the mouse cursor. You can easily find same tools with Google. I use a [CoolPix](https://www.colorschemer.com/colorpix_info.php) application that solves the debugging tasks perfectly.

## Source Code Editors

AutoIt language is distributed with the customized version of SciTE editor. It is great for programming and debugging AutoIt scripts. But more universal editor like [Notepad++](https://notepad-plus-plus.org) will be suitable if you use another programming language like Python or AutoHotKey. [Microsoft Visual Studio](https://www.visualstudio.com/en-us/products/visual-studio-express-vs.aspx) will be the best choice for developers who prefers C++ and C# languages.
