# Appendix

## AutoIt and Windows API Compliance

The table below shows which Windows API function is used by AutoIt functions. The AutoIt function is a wrapper for Windows APII one in most cases. But AutoIt function combine several Windows API calls in some cases.

| AutoIt v3.3.8.1 | Windows API |
| -- | -- |
| [Send](https://www.autoitscript.com/autoit3/docs/functions/Send.htm) | [SendInput](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646310%28v=vs.85%29.aspx) |
| [ControlSend](https://www.autoitscript.com/autoit3/docs/functions/ControlSend.htm) | [SetKeyboardState](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646314%28v=vs.85%29.aspx) |
| [MouseClick](https://www.autoitscript.com/autoit3/docs/functions/MouseClick.htm) | [mouse_event](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646260%28v=vs.85%29.aspx) |
| [MouseClickDrag](https://www.autoitscript.com/autoit3/docs/functions/MouseClickDrag.htm) | [mouse_event](https://msdn.microsoft.com/en-us/library/windows/desktop/ms646260%28v=vs.85%29.aspx) |
| [ControlClick](https://www.autoitscript.com/autoit3/docs/functions/ControlClick.htm) | [PostMessageW](https://msdn.microsoft.com/en-us/library/windows/desktop/ms644944%28v=vs.85%29.aspx)([WM_LBUTTONDOWN](https://msdn.microsoft.com/en-us/library/windows/desktop/ms645607%28v=vs.85%29.aspx)) + [PostMessageW](https://msdn.microsoft.com/en-us/library/windows/desktop/ms644944%28v=vs.85%29.aspx)([WM_LBUTTONUP](https://msdn.microsoft.com/en-us/library/windows/desktop/ms645608%28v=vs.85%29.aspx)) |
| [PixelGetColor](https://www.autoitscript.com/autoit3/docs/functions/PixelGetColor.htm) | [GetPixel](https://msdn.microsoft.com/en-us/library/windows/desktop/dd144909%28v=vs.85%29.aspx) |
