$hWnd = WinGetHandle("[CLASS:Notepad]")
WinActivate($hWnd)

while true
	Send("a")
	Sleep(1000)
	Send("b")
	Sleep(2000)
	Send("c ")
	Sleep(1500)
wend