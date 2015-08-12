Sleep(5 * 1000)

$handle = WinGetHandle('[Active]')

MsgBox(0, "", "Title   : " & WinGetTitle($handle) & @CRLF & "Process : " & WinGetProcess($handle))
