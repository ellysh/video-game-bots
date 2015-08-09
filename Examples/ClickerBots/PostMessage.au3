#RequireAdmin

#include <SendMessage.au3>

Func PostMessage($hWnd, $msg, $wParm, $lParm)
    Return DllCall("user32.dll", "int", "PostMessage", _
            "hwnd", $hWnd, _
            "int", $msg, _
            "int", $wParm, _
            "int", $lParm)
EndFunc   ;==>PostMessage

$hWnd = WinGetHandle("[CLASS:Notepad]")
WinActivate($hWnd)
Sleep(2 * 1000)
Local Const $WM_KEYDOWN = 0x0100
Local Const $WM_KEYUP = 0x0101
Local Const $KEY_A = 0x41

$control = ControlGetHandle("[CLASS:Notepad]", "", "[Class:Edit; INSTANCE:1]")
;MsgBox(0, "", "control = " & $control)

;$ret = _SendMessage($hWnd, 0x100, 0x41, 0x410001)
;$ret = _SendMessage($hWnd, 0x101, 0x41, 0xC0410001)

PostMessage($control,$WM_KEYDOWN,0xbf,0x00350001);
PostMessage($control,$WM_KEYUP,0xbf,0xC0350099);

_SendMessage($control,$WM_KEYDOWN,0xbf,0x00350001);
_SendMessage($control,$WM_KEYUP,0xbf,0xC0350099);
