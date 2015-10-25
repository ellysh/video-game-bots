global const $gKeyHandler = "_KeyMapper"
global $kLogFile = "debug.log"

func LogWrite($data)
	FileWrite($kLogFile, $data & chr(10))
endfunc

func _KeyMapper()
	$key_pressed = @HotKeyPressed

	LogWrite("_KeyMapper() - asc = " & asc($key_pressed) & " key = " & $key_pressed & @CRLF);
	ProcessKey($key_pressed)
	
	HotKeySet($key_pressed)
	Send($key_pressed)
	HotKeySet($key_pressed, $gKeyHandler)
endfunc

func InitKeyHooks($handler)
	for $i = 0 to 256
		if $handler <> "" then
			HotKeySet(Chr($i), $handler)
		else
			HotKeySet(Chr($i))
		endif
	next

	for $i = 0 to 12
		if $handler <> "" then
			HotKeySet("{F" & $i & "}", $handler)
		else
			HotKeySet("{F" & $i & "}")
		endif
	next
endfunc

func ProcessKey($key)
	LogWrite("ProcessKey() - key = " & $key & @CRLF);
endfunc

InitKeyHooks($gKeyHandler)

while true
	Sleep(10)
wend
