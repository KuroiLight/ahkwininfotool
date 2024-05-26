;Author: KuroiLight - klomb - <kuroilight@openmailbox.org>
;Started On: 04/19/15
;Licensed under: MIT License (MIT) as described here: http://www.opensource.org/licenses/MIT

SetBatchLines -1
ListLines Off
#Persistent
#NoEnv
#MaxHotkeysPerInterval 1000
#MaxThreads 2
#SingleInstance force
#KeyHistory 0
SetWinDelay, -1
SetTitleMatchMode, Fast
CoordMode, Mouse, Screen
; DetectHiddenWindows, On
; DetectHiddenText, On
StringCaseSense, Off
SetWorkingDir %A_ScriptDir%
#MaxThreadsPerHotkey 1
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen
;SetTimer, ShowInfo, 15

SysGet, FullScreenHeight, 17 ;79
SysGet, FullScreenWidth, 16 ;78

Styles := {"WS_BORDER":0x00800000, "WS_CAPTION":0x00C00000, "WS_CHILD":0x40000000, "WS_CLIPCHILDREN":0x02000000, "WS_CLIPSIBLINGS":0x04000000, "WS_DISBLED":0x08000000, "WS_DLGFRAME":0x00400000, "WS_GROUP":0x00020000, "WS_HSCROLL":0x00100000, "WS_VSCROLL":0x00200000, "WS_ICONIC":0x20000000, "WS_MAXIMIZE":0x01000000, "WS_MAXIMIZEBOX":0x00010000, "WS_MINIMIZE":0x20000000, "WS_MINIMIZEBOX":0x00020000, "WS_POPUP":0x80000000, "WS_SIZEBOX":0x00040000, "WS_SYSMENU":0x00080000, "WS_TABSTOP":0x00010000, "WS_THICKFRAME":0x00040000, "WS_VISIBLE":0x10000000}
ExStyles := {"WS_EX_ACCEPTFILES":0x00000010, "WS_EX_APPWINDOW" : 0x00040000, "WS_EX_CLIENTEDGE":0x00000200, "WS_EX_COMPOSITED":0x02000000, "WS_EX_CONTEXTHELP":0x00000400, "WS_EX_CONTROLPARENT":0x00010000, "WS_EX_DLGMODALFRAME":0x00000001, "WS_EX_LAYERED":0x00080000, "WS_EX_LAYOUTRTL":0x00400000, "WS_EX_LEFTSCROLLBAR":0x00004000, "WS_EX_MDICHILD":0x00000040, "WS_EX_NOACTIVATE":0x08000000, "WS_EX_NOINHERITLAYOUT":0x00100000, "WS_EX_NOPARENTNOTIFY":0x00000004, "WS_EX_NOREDIRECTIONBITMAP":0x00200000, "WS_EX_RIGHT":0x00001000, "WS_RTL_READING":0x00002000, "WS_EX_STATICEDGE":0x00020000, "WS_EX_TOOLWINDOW":0x00000080, "WS_EX_TOPMOST":0x00000008, "WS_EX_TRANSPARENT":0x00000020, "WS_EX_WINDOWEDGE":0x00000100}

OUTLINE_WINDOWS := true
LOCKTOWINDOW := false

CreateWindow()
ShowInfo()
return

^+i::Pause, Toggle
^+u::OUTLINE_WINDOWS := !OUTLINE_WINDOWS
^+l::LOCKTOWINDOW := !LOCKTOWINDOW
^!+c::WinGetTitle, clipboard, ahk_id %tooltip_hwnd%

CreateWindow() {
    global myWin
    WinGetPos,,, W, H, Program Manager
    Gui Color, 0xFFFFFF
    Gui +E0x20 -Caption +LastFound +ToolWindow +AlwaysOnTop
    WinSet, TransColor, 0xFFFFFF
    Gui Show, x0 y0 w%W% h%H%
    WinGet, myWin, ID, 
}

GetMyToolTip() {
    myPID := DllCall("GetCurrentProcessId")
    WinGet, hwnds, List, ahk_pid %myPID%
    Loop %hwnds%
    {
        thisId := hwnds%A_Index%
        WinGetClass, thisClass, ahk_id %thisId%
        if(thisClass = "tooltips_class32") {
            return thisId
        }
    }
}

DisplayToolTip(data, pos := "") {
    CoordMode, ToolTip, Screen
    CoordMode, Mouse, Screen
    global FullScreenWidth, FullScreenHeight, tooltip_hwnd := 0
    static prevX := 0, Y := 1
    
    ToolTip, % data, prevX, Y,
    
    if(!tooltip_hwnd or !WinExist("ahk_id " . tooltip_hwnd))
        tooltip_hwnd := GetMyToolTip()
    
    sleep 25
    WinGetPos, prevX,, W,, ahk_id %tooltip_hwnd%
    MouseGetPos, mouseX
    side := ((mouseX > (FullScreenWidth / 2)) ? "left" : "right")
    
    if(side = "left") {
        prevX := 1
    } else if(side = "right") {
        prevX := (FullScreenWidth - W)
    }
    
    WinMove, ahk_id %tooltip_hwnd%, , prevX, Y
}

MouseGetPosBoth(ByRef Window, ByRef MainControl, ByRef MDIControl, ByRef ActiveWindow) {
    MouseGetPos,,, Window, MainControl, 2
    MouseGetPos,,,, MDIControl, 3
    WinGet, ActiveWindow, ID, A
    WinGetPos, X, Y, W, H, ahk_id %Window%
    return (Window . MainControl . MDIControl . ActiveWindow) . (X . Y . W . H)
}

GetHWNDInfo(hwnd) {
    global Styles, ExStyles

    WinGetTitle, winTitle, ahk_id %hwnd%
    if(StrLen(winTitle) > 32) {
        winTitle := RTrim(SubStr(winTitle, 1, 32) . "...", " `t`n")
    }
    
    WinGet, processId, PID, ahk_id %hwnd%
    WinGet, procName, ProcessName, ahk_id %hwnd%
    WinGetClass, classname, ahk_id %hwnd%
    WinGetTitle, wtext, ahk_id %hwnd%
    WinGet, wStyle, Style, ahk_id %hwnd%
    WinGet, wExStyle, ExStyle, ahk_id %hwnd%
    WinGetPos, X, Y, Width, Height, ahk_id %hwnd%
    
    StyleStr := StyleToString(wStyle, Styles)
    ExStyleStr := StyleToString(wExStyle, ExStyles)
    
    Output := "TITLE = " . winTitle . "`nPID = " . processID . ", EXE = " . procName . "`nHWND = " . hwnd . ", CLASS = " . classname . "`nX = " . X . ", Y = " . Y . ", W = " . Width . ", H = " . Height . "`nStyle = " . wStyle . ", ExStyle = " . wExStyle . StyleStr . ExStyleStr
    return RTrim(Output, " `t`n")
}

StyleToString(style, styles) {
    if(!style)
        return
    count := 0
    style_string := "`n    "
    for k, v in styles {
        if(style & v) {
            count++
            style_string .= k . (!Mod(count, 2) ? "`n    " : "  ")
        }
    }
    
    return RTrim(style_string, " `t`n")
}

GenerateInfo(Window, MainControl, MDIControl, ActiveWindow) {
    global LOCKTOWINDOW
    static prevAWin
    
    if(LOCKTOWINDOW)
        ActiveWindow := prevAWin
    else
        prevAWin := ActiveWindow
    res := ""
    if(ActiveWindow) {
        res .= "[ACTIVE WINDOW]" . (LOCKTOWINDOW ? "(LOCKED)" : "") . "`n" . GetHWNDInfo(ActiveWindow) . "`n`n"
    }
    if(Window) {
        res .= "[WINDOW UNDER MOUSE]" . "`n" . GetHWNDInfo(Window) . "`n`n"
    }
    if(MainControl and MainControl != Window) {
        res .= "[CONTROL UNDER MOUSE]" . "`n"  . GetHWNDInfo(MainControl) . "`n`n"
    }
    if(MDIControl and MDIControl != MainControl) {
        res .= "[MDI CONTROL UNDER MOUSE]" . "`n" . GetHWNDInfo(MDIControl) . "`n`n"
    }
    
    return RTrim(res, " `t`n")
}

ShowInfo() {
    global myWin
    prevData := 0
    Loop {
        Loop {
            curData := MouseGetPosBoth(mWin, mCont1, mCont2, aWin)
            Sleep, 15
        } Until prevData != curData
        prevData := curData
        DisplayToolTip(GenerateInfo(mWin, mCont1, mCont2, aWin), "switch")
        DrawHWNDs(mWin, mCont1, mCont2, aWin)
        DllCall("BringWindowToTop", UInt, myWin)
    }
}

DrawHWNDs(Window, MainControl, MDIControl, ActiveWindow) {
    global myWin
    static TEAL := 0x99FF00, RED := 0x0000FF, MAGENTA := 0xFF00FF, ORANGE := 0x0099FF, Windows := {}
    
    Windows[TEAL] := (ActiveWindow != Window ? ActiveWindow : 0)
    Windows[RED] := Window
    Windows[MAGENTA] := ((MainControl != Window and MainControl != "") ? MainControl : 0)
    Windows[ORANGE] := ((MDIControl != MainControl and MDIControl != "") ? MDIControl : 0)

    RectWindows(Windows)
}

DrawRect(hdc, l, t, r, b) {
    DllCall("MoveToEx", Int, hdc, Int, l, Int, t, UInt, 0)
    DllCall("LineTo", Int, hdc, Int, r, Int, t)
    DllCall("LineTo", Int, hdc, Int, r, Int, b)
    DllCall("LineTo", Int, hdc, Int, l, Int, b)
    DllCall("LineTo", Int, hdc, Int, l, Int, t-1)
}

RectWindows(win_arr) {
    global myWin

    DllCall("InvalidateRect", UInt, myWin, UInt, 0, Int, 1)
    DllCall("UpdateWindow", UInt, myWin)
    
    HDC := DllCall("GetDC", Int, myWin)
    For k, v in win_arr {
        if(v) {
            WinGetPos, x, y, w, h, ahk_id %v%
            
            pen := DllCall("CreatePen", UInt, 0, UInt, 2, UInt, k)
            DllCall("SelectObject", Int, HDC, Int, pen)
            DrawRect(HDC, x, y, x+w, y+h)
            DllCall("DeleteObject", Int, pen)
        }
    }
    DllCall("ReleaseDC", Int, myWin, Int, HDC)
}