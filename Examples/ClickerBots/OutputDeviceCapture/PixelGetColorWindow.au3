$hWnd = WinGetHandle("[CLASS:Notepad]")
$color = PixelGetColor(100, 100, $hWnd)
MsgBox(0, "", "The hex color is: " & Hex($color, 6))