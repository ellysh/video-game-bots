# Output Device Emulation

## Tools

First of all we should choose hardware for emulation input devices. This is a list of hardware features, which are important for our goals:

1. Low price of the device.
2. IDE and compiler should be available for free.
3. IDE should have libraries for emulation input devices.
4. Active project community and good documentation.

Arduino board has all of these features. This hardware is a good choice if you do not have experience with embedded development. Next question is which version of Arduino board you should buy. Arduino IDE provides [libraries](https://www.arduino.cc/en/Reference/MouseKeyboard) to emulate keyboard and mouse devices. According to the documentation some of boards do not support these libraries. Appropriate versions of boards for you are Leonardo, Micro and Due. You should connect the board to your computer via USB cable. Now the hardware is ready to work.

Second topic after preparing the hardware is to choose a software for development. Arduino IDE with C++ compiler and libraries is available for download on the [official website](http://www.arduino.org/downloads).

There are steps to configure Arduino IDE after installation:

1. Choose a model of your board as a target device for compiler. This option is available in the "Tools"->"Board:..." item of the main menu. You can clarify the model of connected board via the "Tools"->"Port:..." menu item.

2. Choose a connection port to the board via the "Tools"->"Board:..." item of the main menu.

Now Arduino IDE is prepared to work. Next step is installation of the drivers for Arduino board. You should launch the installer application from the Arduino IDE subdirectory. This is a default path for the installer `C:\Program Files (x86)\Arduino\drivers`. There are two installers with `dpinst-amd64.exe` and `dpinst-x86.exe` names in the `drivers` directory. You should choose the first installer for 64-bit Windows version and the second one for 32-bit version. The board should be connected to your computer during all drivers installation process.

We will use AutoIt scripting language to send commands to the Arduino board. Also you need [CommAPI scripts](https://www.autoitscript.com/wiki/CommAPI), which provide access to the WinAPI communications functions. This is a [mirror](https://github.com/ellysh/CommAPI) with all CommAPI scripts in one archive.

## Keyboard Emulation

There are several ways to implement a bot application with an input device emulator. 

First possibility is to write an application for Arduino board with all bot algorithms on C++ language. You can upload this application on the board and then the bot starts to work. This way is appropriate in case your goal is to implement a blind clicker bot. This kind of bot should simulate keystrokes with fixed time delays in the infinite loop. Primary disadvantage of this approach is absence information about the state of a game application. Arduino board does not have any possibility to access the screen device or memory of a game process.

Second way is to write an application for Arduino board, which is able to receive commands via [serial port](https://en.wikipedia.org/wiki/Serial_port) and simulate keystrokes according to these commands. In this case we can implement a clicker bot application, which analyzes a picture of the game window and performs appropriate actions with a keyboard emulator. We will consider this way as more universal and flexible one.

This is an application for Arduino board with the [`keyboard.ino`](https://ellysh.gitbooks.io/video-game-bots/content/Examples/OtherApproaches/OutputDeviceEmulation/keyboard.ino) name:
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
Let us consider this application in details. We use a standard library with the **Keyboard** name in our application. This library allows us to send keystrokes to a connected computer. We include the `Keyboard.h` header at the first line of application. The `Keyboard_` class is defined in this header and the `Keyboard` global object is created. We should use the `Keyboard` object to access features of the library.

There are two functions with `setup` and `loop` names in our application. When you compile your Arduino application, the IDE adds the default `main` function implicitly. This `main` function calls the `setup` function once at startup. Then the `loop` function is called one repeatedly. [Signatures](http://stackoverflow.com/questions/2322736/what-is-the-difference-between-function-declaration-and-signature) of both `setup` and `loop` functions are predefined and you cannot change these.

We initialize both `Serial` and `Keyboard` objects in the `setup` function. The baud rate parameter is passed to the [`begin`](https://www.arduino.cc/en/Serial/Begin) method of the `Serial` object. This parameter defines the data transfer rate between Arduino board and connected computer. The [`begin`](https://www.arduino.cc/en/Reference/KeyboardBegin) method of the `Keyboard` object does not have input parameters. Now the serial communication and the keyboard emulation are ready to work.

There are three actions in the `loop` function:

1. Check if the data is recieved via the serial port with the [`available`](https://www.arduino.cc/en/Serial/Available) method of the `Serial` object. This method returns number of received bytes.

2. Read one received byte by the [`read`](https://www.arduino.cc/en/Serial/Read) method of the `Serial` object.

3. Send a keystroke to the connected computer with the [`write`](https://www.arduino.cc/en/Reference/KeyboardWrite) method of the `Keuboard` object. ASCII code of the emulated key matches to the received byte from the serial port.

Press the *Ctrl+U* hotkey to compile and upload our application to the Arduino board.

TODO: Give an example of the AutoIt script. Give a link to download serial library for AutoIt (make a github mirror?). Notice about the issue with the serial port number.

## Mouse Emulation

## Keyboard and Mouse Emulation

## Summary