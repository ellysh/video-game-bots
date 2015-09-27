#include "FastFind.au3"

Sleep(5 * 1000)

const $SizeSearch = 80
const $MinNbPixel = 50
const $OptNbPixel = 200
const $PosX = 700
const $PosY = 380

$coords = FFBestSpot($SizeSearch, $MinNbPixel, $OptNbPixel, $PosX, $PosY, 0xA9E89C, 10)

if Not @error then
    MsgBox(0, "Coords", $coords[0] & ", " & $coords[1])
else
    MsgBox(0, "Coords", "Match not found.")
endif