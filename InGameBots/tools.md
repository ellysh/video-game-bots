# Tools

## Programming Language

C++ language will be used in this chapter. It is recommended to use freeware [Visual Studio 2015 Community IDE](https://www.visualstudio.com/en-us/products/visual-studio-express-vs.aspx#) instead of open source MinGW environment. The issue with MinGW is a leak of support importing of some Windows library for example **dbghelp.dll**. You can try to compile examples of this chapter with MinGW but you should be ready to switch to Visual Studio in case of issues.

Do not forget to update [**Internet Explorer**](http://windows.microsoft.com/en-us/internet-explorer/download-ie) application to 11 version for usage Visual Studio 2015.

## Debugger

[**OllyDbg**(http://www.ollydbg.de) freeware debugger will be used in this chapter. One of the base features that will be used here is a memory map of the process. But OllyDbg provides wide functionality to investigate Windows applications without a source code. It allows to debug and [**disassemble**](https://en.wikipedia.org/wiki/Disassembler) both 32-bit and 64-bit Windows applications.

## Memory Analyzing Tools

[**Cheat Engine**](http://www.cheatengine.org/) is open source tool that combines features of memory scanner, debugger and hex editor. Cheat Engine allows to find an address of the specific variable in the Windows application and modify it. This feature will be used to gather information for implementation an in-game bot.