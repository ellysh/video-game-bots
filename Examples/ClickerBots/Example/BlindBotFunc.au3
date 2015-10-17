#RequireAdmin

Sleep(2000)

func SearchTarget()
	Send("{F9}")
	Sleep(1000)
endfunc

func Attack()
	Send("{F1}")
	Sleep(5000)
endfunc

func Pickup()
	Send("{F8}")
	Sleep(1000)
endfunc

while true
	SearchTarget()
	Attack()
	Pickup()
wend