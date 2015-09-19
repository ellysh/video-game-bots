#include <WinAPIGdi.au3>

$hWnd = WinGetHandle("[CLASS:Notepad]")
$hDC = _WinAPI_GetDC($hWnd)
$color = _WinAPI_GetPixel($hDC, 300, 300)
MsgBox(0, "", "The hex color is: " & Hex($color, 6))