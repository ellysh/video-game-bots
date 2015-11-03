global const $kLogFile = "debug.log"

func LogWrite($data)
	FileWrite($kLogFile, $data & chr(10))
endfunc

func ScanProcess($name)
	local $processList = ProcessList($name)

	LogWrite("Name: " & $processList[1][0] & " PID: " & $processList[1][1])

	if $processList[0][0] > 0 then
		MsgBox(0, "Alert", "Clicker bot detected!")
	endif
endfunc

while true
	; TODO: Change it to AutoHotKey binary
	ScanProcess("AutoIt3.exe")
	Sleep(5000)
wend