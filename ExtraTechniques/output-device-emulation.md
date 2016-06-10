# Output Device Emulation

**This section is still under development.**

## Tools

First of all we should choose hardware to emulate input devices. This is a list of hardware features, which are important for our goals:

1. Low price of the device.
2. IDE and compiler should be available for free.
3. IDE should have libraries for emulation input devices.
4. Active project community and good documentation.

Arduino board has all of these features. This hardware is a good choice if you do not have experience with embedded development. Next question is which version of Arduino board you should buy. Arduino IDE provides [libraries](https://www.arduino.cc/en/Reference/MouseKeyboard) to emulate keyboard and mouse devices. According to the documentation some of boards do not support these libraries. Appropriate versions of boards for you are Leonardo, Micro and Due. You should connect the board to your computer via USB cable. Now the hardware is ready to work.

Second topic after preparing the hardware is to choose a software for development. Arduino IDE with C++ compiler and libraries is available for download on the [official website](http://www.arduino.org/downloads).

There are steps to configure Arduino IDE after installation:

1. Choose a model of your board as a target device for compiler. This option is available in the "Tools"->"Board:..." item of the main menu. You can clarify the model of connected board via the "Tools"->"Port:..." menu item.

2. Choose a connection port to the board via the "Tools"->"Board:..." item of the main menu.

Now Arduino IDE is prepared to work.

Next step is installation of the drivers for Arduino board. You should launch the installer application from the Arduino IDE subdirectory. This is a default path for the installer `C:\Program Files (x86)\Arduino\drivers`. There are two installers with `dpinst-amd64.exe` and `dpinst-x86.exe` names in the `drivers` directory. You should choose the first installer for 64-bit Windows version and the second one for 32-bit version. The board should be connected to your computer during the process of drivers installation.

We will use AutoIt scripting language to send commands to the Arduino board. Also you need [CommAPI scripts](https://www.autoitscript.com/wiki/CommAPI), which provide access to the WinAPI communications functions. This is a [mirror](https://github.com/ellysh/CommAPI) with all CommAPI scripts in one archive.

## Keyboard Emulation

There are several ways to implement a bot application with emulator of input device.

First possibility is to write an application for Arduino board with all bot algorithms on C++ language. You can upload this application on the board. The bot starts its work when you connect this board to your computer. This way is appropriate in case your goal is to implement a blind clicker bot. This kind of bot should simulate keystrokes with fixed time delays in the infinite loop. Primary disadvantage of this approach is absence information about the state of game application. Arduino board does not have any possibility to access the screen device or memory of game process.

Second way is to write an application for Arduino board, which is able to receive commands via [serial port](https://en.wikipedia.org/wiki/Serial_port) and simulate keystrokes according to these commands. In this case we can implement a clicker bot application, which analyzes a picture of the game window and performs appropriate actions with a keyboard emulator. We will consider this way as more universal and flexible one.

This is an application for Arduino board with the [`keyboard.ino`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ExtraTechniques/OutputDeviceEmulation/keyboard.ino) name:
```C++
#include <Keyboard.h>

void setup()
{
  Serial.begin(9600);
  Keyboard.begin();
}

void loop()
{
  if (Serial.available() > 0)
  {
    int incomingByte = Serial.read();
    Keyboard.write(incomingByte);
  }
}
```
Let us consider this application in details. We use a standard library with the **Keyboard** name in our application. This library allows us to send keystrokes to a connected computer. We include the `Keyboard.h` header at the first line of the application. The `Keyboard_` class is defined in this header and the `Keyboard` global object is created. We should use the `Keyboard` object to access features of the library.

There are two functions with `setup` and `loop` names in our application. When you compile your Arduino application, the IDE adds the default `main` function implicitly. This `main` function calls the `setup` function once at startup. Then the `loop` function is called repeatedly. [Signatures](http://stackoverflow.com/questions/2322736/what-is-the-difference-between-function-declaration-and-signature) of both `setup` and `loop` functions are predefined and you cannot change these.

We initialize both `Serial` and `Keyboard` objects in the `setup` function. The baud rate parameter, which equals to 9600 bit/s, is passed to the [`begin`](https://www.arduino.cc/en/Serial/Begin) method of the `Serial` object. This parameter defines the data transfer rate between the Arduino board and connected computer. The [`begin`](https://www.arduino.cc/en/Reference/KeyboardBegin) method of the `Keyboard` object does not have input parameters. Now the serial communication and the keyboard emulation are ready to work.

There are three actions in the `loop` function:

1. Check if the data is received via the serial port with the [`available`](https://www.arduino.cc/en/Serial/Available) method of the `Serial` object. This method returns the number of received bytes.

2. Read one received byte by the [`read`](https://www.arduino.cc/en/Serial/Read) method of the `Serial` object. This byte defines an ASCII code of the key, which should be emulated.

3. Send a keystroke to the connected computer with the [`write`](https://www.arduino.cc/en/Reference/KeyboardWrite) method of the `Keyboard` object.

Press the *Ctrl+U* hotkey to compile and upload the `keyboard.ino` application to the Arduino board.

Now we have the Arduino board, which emulates the keyboard. Next step is to implement an AutoIt script to control this board via the serial port. This control script uses CommAPI wrappers. You should download all CommAPI files and copy them to the directory with the control script.

This is a list of necessary CommAPI files:

1. [`CommAPI.au3`](https://www.autoitscript.com/wiki/CommAPI.au3)
2. [`CommAPIConstants.au3`](https://www.autoitscript.com/wiki/CommAPIConstants.au3)
3. [`CommAPIHelper.au3`](https://www.autoitscript.com/wiki/CommAPIHelper.au3)
4. [`CommInterface.au3`](https://www.autoitscript.com/wiki/CommInterface.au3)
5. [`CommUtilities.au3`](https://www.autoitscript.com/wiki/CommUtilities.au3)

Make sure that all these files are present.

This is a control script with the [`ControlKeyboard.au3`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/ExtraTechniques/OutputDeviceEmulation/ControlKeyboard.au3) name:
```AutoIt
#include "CommInterface.au3"

func ShowError()
	MsgBox(16, "Error", "Error " & @error)
endfunc

func OpenPort()
	local const $iPort = 7
	local const $iBaud = 9600
	local const $iParity = 0
	local const $iByteSize = 8
	local const $iStopBits = 1

	$hPort = _CommAPI_OpenCOMPort($iPort, $iBaud, $iParity, $iByteSize, $iStopBits)
	if @error then
		ShowError()
		return NULL
	endif
 
	_CommAPI_ClearCommError($hPort)
	if @error then
		ShowError()
		return NULL
	endif
 
	_CommAPI_PurgeComm($hPort)
	if @error then
		ShowError()
		return NULL
	endif
	
	return $hPort
endfunc

func SendArduino($hPort, $command)
	_CommAPI_TransmitString($hPort, $command)
	if @error then ShowError()
endfunc

func ClosePort($hPort)
	_CommAPI_ClosePort($hPort)
endfunc

$hWnd = WinGetHandle("[CLASS:Notepad]")
WinActivate($hWnd)
Sleep(200)

$hPort = OpenPort()

SendArduino($hPort, "Hello world!")

ClosePort($hPort)
```
This is an algorithm of the `ControlKeyboard.au3` script:

1. Switch to the already opened Notepad window with the `WinActivate` AutoIt function.

2. Open the serial port with the `OpenPort` function.

3. Send command to the Arduino board to type the "Hello world!" string. The `SendArduino` function encapsulates algorithm of sending this command.

4. Close the serial port with the `ClosePort` function.

Let us consider internals of `OpenPort`, `SendArduino` and `ClosePort` user functions.

The `OpenPort` function opens the serial port and prepare the connected device for communication. This function returns a handle to the opened port. Three CommAPI functions are used here:

1. The `_CommAPI_OpenCOMPort` function opens a COM port with the specified settings. These settings are defined by the input parameters of this function. The `iParity`, `iByteSize` and `iStopBits` parameters have constant values for hardware serial connection with Arduino boards. You should pay attention to the `iBaud` and `iPort` parameters only. The value of `iBaud` parameter should match to the value that you have passed to the `begin` method of the `Serial` object in the `keyboard.ino` application. This equals to 9600 in our case. The `iPort` parameter should be equal to the number of a COM port, which is used for connection with your Arduino board. You can check this value in the "Tools"->"Port:..." item of the Arduino IDE menu. For example, value `7` of the `iPort` parameter matches to the "COM7" port.

2. The `_CommAPI_ClearCommError` function retrieves information about communication errors and the current status of the connected board. This information is returned via the second parameter of this function. This parameter is not used in our case. The function is used here to clear the error flag of the Arduino board. Communication will be blocked until this flag is not cleared.

3. The `_CommAPI_PurgeComm` function clears the input and output buffers of the Arduino board and terminate pending read and write operations. The board becomes ready to receive commands after call of this function.

The `SendArduino` function is a wrapper around the `_CommAPI_TransmitString`. This function writes a string to the specified port handle.

The `ClosePort` function closes the serial port by the specified handle.

Also there is a `ShowError` function, which is used to show a message box with the code of last occurred error.

You can connect Arduino board, launch Notepad application and start the `ControlKeyboard.au3` script. The text "Hello world!" will be typed in the Notepad window.

## Mouse Emulation

## Keyboard and Mouse Emulation

## Summary