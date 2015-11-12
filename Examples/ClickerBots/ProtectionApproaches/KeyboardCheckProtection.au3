#include <StructureConstants.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>

global const $kLogFile = "debug.log"
global $gHook

func LogWrite($data)
	FileWrite($kLogFile, $data & chr(10))
endfunc

Func _KeyHandler($nCode, $wParam, $lParam)
	local $keyHooks = DllStructCreate($tagKBDLLHOOKSTRUCT, $lParam)

	LogWrite("_KeyHandler() - keyccode = " & DllStructGetData($keyHooks, "vkCode"));

	if $nCode < 0 then
	return _WinAPI_CallNextHookEx($gHook, $nCode, $wParam, $lParam)
	endIf

	local $flags = DllStructGetData($keyHooks, "flags")
	if $flags = $LLKHF_INJECTED then
		MsgBox(0, "Alert", "Clicker bot detected!")
	endif

	return _WinAPI_CallNextHookEx($gHook, $nCode, $wParam, $lParam)
endfunc

func InitKeyHooks($handler)
	local $keyHandler = DllCallbackRegister($handler, "long", "int;wparam;lparam")
	local $hMod = _WinAPI_GetModuleHandle(0)
	$gHook = _WinAPI_SetWindowsHookEx($WH_KEYBOARD_LL, DllCallbackGetPtr($keyHandler), $hMod)
endfunc

InitKeyHooks("_KeyHandler")

while true
	Sleep(10)
wend