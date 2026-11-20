;
; AutoIt Find&Replace-in-text Dialog.
; We ripped this out of the AutoIt includes to work on it..
;

; We still need some ancilliary functions..
#include <GuiEdit.au3>
#include <WindowsConstants.au3>

Global $idStatusBar1
Global $oldFind = ""


;2do.. Store the replace string and if it changes, restart the replacements counter


; #FUNCTION# ====================================================================================================================
; Author ........: Gary Frost (gafrost)
; Modified.......: Cor, 2021-03, for ffe. And renamed so it won't interfere.
; ===============================================================================================================================
Func _GUICtrlCustomEdit_Find($hWnd, $bReplace = False)

	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	$oldFind = ""
	
	Local $iPos = 0, $iCase, $iOccurance = 0, $iReplacements = 0
	Local $aPartsRightEdge[3] = [125, 225, -1]
	Local $iOldMode = Opt("GUIOnEventMode", 0)

	Local $aSel = _GUICtrlEdit_GetSel($hWnd)
	Local $sText = _GUICtrlEdit_GetText($hWnd)
	
	; Get Window position from prefs..
	local $ef_width = 349
	local $ef_height = 177
	local $ef_x = IniRead($ini_path, $my_name, "editfind_x", -1)
	local $ef_y = IniRead($ini_path, $my_name, "editfind_y", -1)

	if $bReplace = false then
		$ef_height = $ef_height-34
	endif

	; Use the public window style: the old internal UDF constant is absent in AutoIt 3.3.18.0.
	Local $hGuiSearch = GUICreate("Find", $ef_width, $ef_height, $ef_x, $ef_y, _
		BitOR($WS_CHILD, $__EDITCONSTANT_WS_MINIMIZEBOX, $__EDITCONSTANT_WS_CAPTION, _
								$__EDITCONSTANT_WS_POPUP, $__EDITCONSTANT_WS_SYSMENU) , $WS_EX_TOPMOST)
								
	$idStatusBar1 = _GUICtrlStatusBar_Create($hGuiSearch, $aPartsRightEdge)
	_GUICtrlStatusBar_SetText($idStatusBar1, "Find: ")
	; GUISetIcon(@SystemDir & "\shell32.dll", 22, $hGuiSearch)
	GUISetIcon($me_app, 0)
	
	GUICtrlCreateLabel("Find what:", 9, 10, 53, 16, $__EDITCONSTANT_SS_CENTER)
	
	Local $idInputSearch = GUICtrlCreateInput("", 80, 8, 257, 21)
	Local $idLblReplace = GUICtrlCreateLabel("Replace with:", 9, $ef_height-135, 69, 17, $__EDITCONSTANT_SS_CENTER)
	Local $idInputReplace = GUICtrlCreateInput("", 80, $ef_height-137, 257, 21)
	
	Local $idChkWholeOnly = GUICtrlCreateCheckbox("Match whole word only", 10, $ef_height-100, 145, 17)
	Local $idChkMatchCase = GUICtrlCreateCheckbox("Match case", 10, $ef_height-76, 145, 17)
	
	Local $idBtnFindNext = GUICtrlCreateButton("Find Next", $ef_width-110, $ef_height-100, 100, 21, $bs_defpushbutton)
	Local $idBtnReplace = GUICtrlCreateButton("Replace", $ef_width-110, $ef_height-76, 100, 21, 0)
	
	Local $idBtnClose = GUICtrlCreateButton("Close", $ef_width-110, $ef_height-47, 100, 21, 0)
	
	
	If (IsArray($aSel) And $aSel <> $EC_ERR) Then
		GUICtrlSetData($idInputSearch, StringMid($sText, $aSel[0] + 1, $aSel[1] - $aSel[0]))
		If $aSel[0] <> $aSel[1] Then ; text was selected when function was invoked
			$iPos = $aSel[0]
			If BitAND(GUICtrlRead($idChkMatchCase), $__EDITCONSTANT_GUI_CHECKED) = $__EDITCONSTANT_GUI_CHECKED Then $iCase = 1
			$iOccurance = 1
			Local $iTPose
			While 1 ; set the current occurance so search starts from here
				$iTPose = StringInStr($sText, GUICtrlRead($idInputSearch), $iCase, $iOccurance)
				If Not $iTPose Then ; this should never happen, but just in case
					$iOccurance = 0
					ExitLoop
				ElseIf $iTPose = $iPos + 1 Then ; found the occurance
					ExitLoop
				EndIf
				$iOccurance += 1
			WEnd
		EndIf
		_GUICtrlStatusBar_SetText($idStatusBar1, "Find: " & GUICtrlRead($idInputSearch))
	EndIf

	If $bReplace = False Then
		GUICtrlSetState($idLblReplace, $__EDITCONSTANT_GUI_HIDE)
		GUICtrlSetState($idInputReplace, $__EDITCONSTANT_GUI_HIDE)
		GUICtrlSetState($idBtnReplace, $__EDITCONSTANT_GUI_HIDE)
	Else
		_GUICtrlStatusBar_SetText($idStatusBar1, "Replacements: " & $iReplacements, 1)
		_GUICtrlStatusBar_SetText($idStatusBar1, "With: ", 2)
	EndIf
	GUISetState(@SW_SHOW)

	Local $iMsgFind
	While 1
		$iMsgFind = GUIGetMsg()
		Select
			Case $iMsgFind = $__EDITCONSTANT_GUI_EVENT_CLOSE Or $iMsgFind = $idBtnClose
				ExitLoop
			Case $iMsgFind = $idBtnFindNext
				GUICtrlSetState($idBtnFindNext, $__EDITCONSTANT_GUI_DISABLE)
				GUICtrlSetCursor($idBtnFindNext, 15)
				Sleep(100)
				_GUICtrlStatusBar_SetText($idStatusBar1, "Find: " & GUICtrlRead($idInputSearch))
				_GUICtrlStatusBar_SetText($idStatusBar1, "", 1)
				If $bReplace = True Then
					_GUICtrlStatusBar_SetText($idStatusBar1, "Find: " & GUICtrlRead($idInputSearch))
					_GUICtrlStatusBar_SetText($idStatusBar1, "With: " & GUICtrlRead($idInputReplace), 2)
				EndIf
				__GUICtrlCustomEdit_FindText($hWnd, $idInputSearch, $idChkMatchCase, $idChkWholeOnly, $iPos, $iOccurance, $iReplacements)
				Sleep(100)
				GUICtrlSetState($idBtnFindNext, $__EDITCONSTANT_GUI_ENABLE)
				GUICtrlSetCursor($idBtnFindNext, 2)
			Case $iMsgFind = $idBtnReplace
				GUICtrlSetState($idBtnReplace, $__EDITCONSTANT_GUI_DISABLE)
				GUICtrlSetCursor($idBtnReplace, 15)
				Sleep(100)
				_GUICtrlStatusBar_SetText($idStatusBar1, "Find: " & GUICtrlRead($idInputSearch))
				_GUICtrlStatusBar_SetText($idStatusBar1, "With: " & GUICtrlRead($idInputReplace), 2)
				If $iPos Then
					_GUICtrlEdit_ReplaceSel($hWnd, GUICtrlRead($idInputReplace))
					$iReplacements += 1
					$iOccurance -= 1
					_GUICtrlStatusBar_SetText($idStatusBar1, "Replacements: " & $iReplacements, 1)
				EndIf
				__GUICtrlCustomEdit_FindText($hWnd, $idInputSearch, $idChkMatchCase, $idChkWholeOnly, $iPos, $iOccurance, $iReplacements)
				Sleep(100)
				GUICtrlSetState($idBtnReplace, $__EDITCONSTANT_GUI_ENABLE)
				GUICtrlSetCursor($idBtnReplace, 2)
		EndSelect
	WEnd
	
	local $ef_coords = WinGetPos($hGuiSearch)
	IniWrite($ini_path, $my_name, "editfind_x", $ef_coords[0])
	IniWrite($ini_path, $my_name, "editfind_y", $ef_coords[1])

	GUIDelete($hGuiSearch)
	Opt("GUIOnEventMode", $iOldMode)
EndFunc   ;==>_GUICtrlCustomEdit_Find


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUICtrlCustomEdit_FindText
; Description ...:
; Syntax.........: __GUICtrlCustomEdit_FindText ( $hWnd, $idInputSearch, $idChkMatchCase, $idChkWholeOnly, ByRef $iPos, ByRef $iOccurance, ByRef $iReplacements )
; Parameters ....: $hWnd          - Handle to the control
;                  $idInputSearch   - controlID
;                  $idChkMatchCase  - controlID
;                  $idChkWholeOnly  - controlID
;                  $iPos          - position of text found
;                  $iOccurance    - occurance to find
;                  $iReplacements - # of occurances replaced
; Return values .:
; Author ........: Gary Frost (gafrost)
; Modified.......: Cor, 2021-03, for ffe. And renamed so it won't interfere.
; Remarks .......:
; Related .......: _GUICtrlCustomEdit_Find
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func __GUICtrlCustomEdit_FindText($hWnd, $idInputSearch, $idChkMatchCase, $idChkWholeOnly, ByRef $iPos, ByRef $iOccurance, ByRef $iReplacements)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)

	Local $iCase = 0, $iWhole = 0
	Local $bExact = False
	Local $sFind = GUICtrlRead($idInputSearch)
	if $sFind <> $oldFind then $iReplacements = 0
	$oldFind = $sFind
	
	Local $sText = _GUICtrlEdit_GetText($hWnd)

	If BitAND(GUICtrlRead($idChkMatchCase), $__EDITCONSTANT_GUI_CHECKED) = $__EDITCONSTANT_GUI_CHECKED Then $iCase = 1
	If BitAND(GUICtrlRead($idChkWholeOnly), $__EDITCONSTANT_GUI_CHECKED) = $__EDITCONSTANT_GUI_CHECKED Then $iWhole = 1
	
	If $sFind <> "" Then
		$iOccurance += 1
		$iPos = StringInStr($sText, $sFind, $iCase, $iOccurance)
		If $iWhole And $iPos Then
			Local $s_Compare2 = StringMid($sText, $iPos + StringLen($sFind), 1)
			If $iPos = 1 Then
				If ($iPos + StringLen($sFind)) - 1 = StringLen($sText) Or _
						($s_Compare2 = " " Or $s_Compare2 = @LF Or $s_Compare2 = @CR Or _
						$s_Compare2 = @CRLF Or $s_Compare2 = @TAB) Then $bExact = True
			Else
				Local $s_Compare1 = StringMid($sText, $iPos - 1, 1)
				If ($iPos + StringLen($sFind)) - 1 = StringLen($sText) Then
					If ($s_Compare1 = " " Or $s_Compare1 = @LF Or $s_Compare1 = @CR Or _
							$s_Compare1 = @CRLF Or $s_Compare1 = @TAB) Then $bExact = True
				Else
					If ($s_Compare1 = " " Or $s_Compare1 = @LF Or $s_Compare1 = @CR Or _
							$s_Compare1 = @CRLF Or $s_Compare1 = @TAB) And _
							($s_Compare2 = " " Or $s_Compare2 = @LF Or $s_Compare2 = @CR Or _
							$s_Compare2 = @CRLF Or $s_Compare2 = @TAB) Then $bExact = True
				EndIf
			EndIf
			If $bExact = False Then ; found word, but as part of another word, so search again
				__GUICtrlCustomEdit_FindText($hWnd, $idInputSearch, $idChkMatchCase, $idChkWholeOnly, $iPos, $iOccurance, $iReplacements)
			Else ; found it
				_GUICtrlEdit_SetSel($hWnd, $iPos - 1, ($iPos + StringLen($sFind)) - 1)
				_GUICtrlEdit_Scroll($hWnd, $__EDITCONSTANT_SB_SCROLLCARET)
			EndIf
		ElseIf $iWhole And Not $iPos Then ; no more to find
			$iOccurance = 0
			_GUICtrlStatusBar_SetText($idStatusBar1, "Reached The End!")
			;MsgBox($MB_SYSTEMMODAL, "Find", "Reached End of document, Can not find the string '" & $sFind & "'")
		ElseIf Not $iWhole Then
			If Not $iPos Then ; wrap around search and select
				$iOccurance = 1
				_GUICtrlEdit_SetSel($hWnd, -1, 0)
				_GUICtrlEdit_Scroll($hWnd, $__EDITCONSTANT_SB_SCROLLCARET)
				$iPos = StringInStr($sText, $sFind, $iCase, $iOccurance)
				_GUICtrlStatusBar_SetText($idStatusBar1, "Search Wrapped!")
				If Not $iPos Then ; no more to find
					$iOccurance = 0
					
					if not $iReplacements then _GUICtrlStatusBar_SetText($idStatusBar1, "Reached the END!")
					;_GUICtrlStatusBar_SetText($idStatusBar1, "Not Found: '" & $sFind & "'", 1)
					;MsgBox($MB_SYSTEMMODAL, "Find", "Reached End of document, Can not find the string  '" & $sFind & "'")
				Else ; found it
					_GUICtrlEdit_SetSel($hWnd, $iPos - 1, ($iPos + StringLen($sFind)) - 1)
					_GUICtrlEdit_Scroll($hWnd, $__EDITCONSTANT_SB_SCROLLCARET)
				EndIf
			Else ; set selection
				_GUICtrlEdit_SetSel($hWnd, $iPos - 1, ($iPos + StringLen($sFind)) - 1)
				_GUICtrlEdit_Scroll($hWnd, $__EDITCONSTANT_SB_SCROLLCARET)
			EndIf
		EndIf
	EndIf
EndFunc   ;==>__GUICtrlCustomEdit_FindText

