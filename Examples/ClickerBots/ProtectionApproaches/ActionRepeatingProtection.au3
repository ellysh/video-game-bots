global const $gKeyHandler = "_KeyHandler"
global const $kLogFile = "debug.log"

global const $gActionTemplate[3] = ['a', 'b', 'c']
global $gActionMatch = 0
global $gCounter = 0

func LogWrite($data)
	FileWrite($kLogFile, $data & chr(10))
endfunc

func _KeyHandler()
	$key_pressed = @HotKeyPressed

	LogWrite("_KeyHandler() - asc = " & asc($key_pressed) & " key = " & $key_pressed & @CRLF);
	AnalyzeKey($key_pressed)

	HotKeySet($key_pressed)
	Send($key_pressed)
	HotKeySet($key_pressed, $gKeyHandler)
endfunc

func InitKeyHooks($handler)
	for $i = 0 to 256
		HotKeySet(Chr($i), $handler)
	next
endfunc

func AnalyzeKey($key)
	LogWrite("AnalyzeKey() - key = " & $key & @CRLF);

	if $gActionMatch < 3 and $key = $gActionTemplate[$gActionMatch] then
		$gActionMatch += 1
	else
		$gActionMatch = 0
		return
	endif

	if $gActionMatch = UBound($gActionTemplate) - 1 then
		$gCounter += 1

		if $gCounter = 3 then
			MsgBox(0, "Alert", "Clicker bot detected!")
		endif
	endif
endfunc

InitKeyHooks($gKeyHandler)

while true
	Sleep(10)
wend