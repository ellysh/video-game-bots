# Protection Approaches

TODO: Brief foreword about protection system. Purposes, what it does on detection bot, checks on server and checks on client. Approaches against clickers

## Test Application

TODO: Write how we will investigate protection approaches. Work scheme is notepad + autoit protection script vs bot script to perform actions in notepad.

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