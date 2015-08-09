sleep(5 * 1000)

$handle = WinGetHandle('[Active]')

; TODO: Gather all boxes into one
MsgBox(0, "", '!Title   : ' & WinGetTitle($handle) & @CRLF)
MsgBox(0, "", '!Process : ' & WinGetProcess($handle) & @CRLF)
MsgBox(0, "", '!Text    : ' & WinGetText($handle) & @CRLF)

; TODO: Print a window class here
#cs
#include <WinAPI.au3>
$hwnd = WinGetHandle("Untitled")
MsgBox(4096,"",_WinAPI_GetClassName($hwnd))
#ce