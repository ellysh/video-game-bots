# Protection Approaches

Possible approaches of development protection systems against clicker bots will be considered now. Most effective protection systems are separated into two parts. One part is launched on a cliend side. It allows to control points of interception and embedding data that are related to devices, OS and a game application. Server side part of the protection system allows to control a communication between a game application and a game server. Most algorithms for detection clicker bots able to work on client side.

Main purpose of the protection system is detection a fact of the bot application usage. There are several variants of reaction on a bot detection:

1. Write a warning message about a suspect player account to the log file.
2. Interrupt current connection between a suspect player and a game server.
3. Ban a suspect player account and prevent its future connections to a game server.

TODO: Brief foreword about protection system. Purposes, what it does on detection bot, checks on server and checks on client. Approaches against clickers

## Test Application

We will test protection systems approaches on Notepad application. A protection system should detect a AutoIt script that will type text in the application's window. Our protection system examples will be implemented on AutoIt language too as separate scripts. It will be simpler to demonstarte protection algorithms with AutoIt language. But C++ language is used for development real protection systems in most cases.

## Analysis of Actions

TODO: Write about the simplest variant of bot and detection it with delay measurement.

TODO: Upgrade bot by random timeouts between actions. Write about detection based on actions sequence.

## Keyboard State Checking

TODO: Write about checking a LLKHF_INJECTED flag when a keypress is hooked.

TODO: Try to avoid this protection in the bot script.

## Process Scanner

TODO: Write about scanning of the launch processes. How to do it for two Autoit scripts? Make one script in Autohotkey?

TODO: Try to avoid this protection by renaming Autohotkey application.

TODO: Write about calculating md5 of the launched binaries. Try to avoid it by patching binary and changing md5.

## Results

TODO: Compare effectiveness of the suggested protection approaches. Is it possible to use one and skip all others?