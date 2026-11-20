#include-once
global $corz_shared_version = "1.10.26"

; corz.org apps essential shared functions.

#include <GuiConstants.au3>
#include <ColorConstants.au3>
#include <FontConstants.au3>
#include <Misc.au3>
#include <Date.au3>
#include <GuiToolTip.au3>
#include <WinAPIFiles.au3>
#include <InetConstants.au3>
#include <WinNet.au3>
; #include <WinAPISysWin.au3>
; #include <WinAPIGdi.au3>

; for clean ini.
#include <File.au3>
#include <String.au3>
#include <GuiEdit.au3>
#include <WinAPI.au3>

; Setup a few variables.
global const $LOG_LF			= @LF	; for logs/saved text files/console
global const $MSG_LF			= @LF	; for dialog boxes, etc.
global $LF 						= @LF	; User-configurable line-endings.
global const $LINE_FEED_ITEMS = "LF" & Chr(30) & "CRLF" & Chr(30) & "CR"

; These make great AutoIt Booleans for sooooooo many reasons.
global const $ON				= $GUI_CHECKED			; 1
global const $OFF				= $GUI_UNCHECKED		; 4
global const $UNSET				= $GUI_INDETERMINATE	; 2


; Boolean TRUTH lives here! Master word lists for user-supplied booleans.
; ALL boolean functions below read these (via InArray()), so add new words
; here, once, and every reader picks them up. Lowercase; lookup is
; case-insensitive. Numbers ("1"/"0") are usually handled in the functions.
global const $BOOL_TRUE_WORDS[19] = [18, "true", "on", "y", "yes", "yes!", "yay", "yay!", "yup", "hell yes!", _
											"indeed", "yes sir!", "yes sir", "yessir!", "yessir", "affirmative", "cool", "enable", "enabled"]
global const $BOOL_FALSE_WORDS[20] = [19, "false", "off", "n", "no", "not", "nope", "nay", "nay!", "nah", "nah!", _
											"no way!", "no sir!", "negative", "neg", "no!", "nyet", "disable", "disabled", "disables"]
global const $BOOL_TOGGLE_WORDS[3] = [2, "toggle", "switch"]

; Command-state signals returned by GetOnOffState()/ParseCommandBool().
global const $STATE_INVALID = -1
global const $STATE_NO_CHANGE = -2
global const $STATE_TOGGLE = -3

; About Box state. Set by About() for its event handlers.
global $about_gui = "", $about_is_open = false, $about_time_ctrl = 0, $about_last_sec = 0, $about_hicon = 0
global $about_app = "", $about_url = "", $about_log = "", $about_launch = "", $about_show_runtime = $ON


; This combo gets used a lot.
global const $STR_STRIP_ENDS = $STR_STRIPLEADING + $STR_STRIPTRAILING
global const $SEPARATOR = "--------------------------------------------------------------------------------"

; Unreserved URL characters (RFC 3986). Everything else gets percent-encoded.
global const $URL_UNRESERVED = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"

; URL placeholder for the resolved definition or web-search phrase.
global const $LOOKUP_TOKEN = "@LookUp"

; For "humanizing" AutoIt booleans (and for reporting/display purposes).
global $str_enabled				= "true" 	; "enabled"
global $str_disabled			= "false" 	; "disabled"

; ToolTip time-out.
global const $DEF_MSG_TIME		= 2000

; Input box default width.
global const $DEF_INPUTBOX_WIDTH	= 400

; Handy for Win10/11 GUI stuff.
global const $COLOR_LTGREY			= 0xD0D0D0
global const $COLOR_DARKCHARCOAL	= 0x444444
; Clickable-link hover color, used is About box link.
global const $COLOR_LINK_HOVER 		= 0x5e84c5

; So we can do GUICtrlSetData($ctrl, $state[$some_ON/OFF_bool])
; global $state[5] = [0, $str_enabled, 0, 0, $str_disabled]
; Nice idea, but Human($pref) gets you the same result and is more easily understood.

; I use these variables meaningfully.
; You can override these in your app, if required.
global $debug_log = "compiled.debug"
global $debug_level = 0
global $max_debug_log_size = 0 ; 0 = no limit, or a number (in MB). Set in ini prefs.
global $user_quit = false

global $app_name, $my_domain, $data_dir, $scripts_dir, $ini_path
global $log_string, $log_location
global $max_log_size = 0 ; 0 = no limit, or a number (in MB)
; Ini section cache switch for KeyBind's readers. KeyBindIniReadCore serves
; cached rows while true; the config dialog sets and clears it around its
; build. Declared here, first in every include order, so all readers agree.
global $ini_cache_active = false

global $monitors_list[1][5]
$monitors_list[0][0] = 0
global $do_tooltips
global $tip_icon = @ScriptFullPath & ",0"
global $tip_style = 1
global $tooltip_time = 10000

; For UpdateIniFile().
global $file_array, $new_array[1]

; Set to true during Send() operations [SendWait()]
global $am_sending

; Enable the creation of a list of user token, for save/recall.
global $known_user_tokens[1][2]

; Last text captured by GetSelectedText(). Surfaced as @Selected.
global $selected_text = ""

; Most recent normalized definition or web-search phrase; never saved.
global $lookup_text = ""

; Current ForEach() entry; empty outside iteration. Never saved to the ini.
global $foreach_item = ""

; Explorer selection for the current task; restored after nested task returns.
global $explorer_selection = "", $explorer_selection_error = 0

; Full path from the most recent @Random result. Surfaced as @LastRandom.
; Reads 0 until @Random has been used.
global $last_random = "0"

; Saving format for remembered window X/Y; numeric values remain valid.
global $position_saving_method = "absolute"

; Bounds of the window found by GetWindow(). Surfaced as @WindowX,
; @WindowY, @WindowWidth and @WindowHeight. Until GetWindow() runs they
; describe the desktop.
global $window_x = 0
global $window_y = 0
global $window_width = @DesktopWidth
global $window_height = @DesktopHeight

; Status code of the most recent HttpGET()/HttpPOST() request.
; Surfaced as @HttpStatus. 0 means no response arrived.
global $http_status = 0


;
; UserDialog() - One dialog to rule them all!
;
; Apps using legacy CFMB are being moved over one-at-a-time. KeyBind first.

; UserDialog basic layout state.
; Only one of each type of UserDialog() should be opened at once, though they
; can call nested UserDialog() functions for sub-dialogs, if required.

global $user_dialog_prompt = 0, $user_dialog_check = 0, $user_dialog_remember = false
global $user_dialog_buttons[1] = [0]
global $user_dialog_indent = 16
global const $USER_DIALOG_ICON_SIZE = 32

; Outside padding and button spacing for every UserDialog, however many buttons.
global const $USER_DIALOG_PADDING = 7

; Breathing room between the prompt text and the window's right edge.
global const $USER_DIALOG_TEXT_RIGHT_PAD = 6

; The checkbox sits this far right of the button row's left edge.
global const $USER_DIALOG_CHECKBOX_OFFSET = 2

; Design metrics for every UserDialog. Single row of equally spaced buttons
; along the bottom; these names replace the old inline numbers exactly.
global const $USER_DIALOG_DESIGN_W = 430
global const $USER_DIALOG_BUTTON_H = 28
global const $USER_DIALOG_TOP_MARGIN = 12
global const $USER_DIALOG_MID_GAP = 12
global const $USER_DIALOG_LABEL_FIRST_H = 20
global const $USER_DIALOG_LABEL_LINE_H = 18
global const $USER_DIALOG_LABEL_BOTTOM_GAP = 6
global const $USER_DIALOG_CHECK_H = 24
global const $USER_DIALOG_CHECK_ROW_H = 24
global const $USER_DIALOG_CHECKBOX_H = 18

global const $USER_DIALOG_PROMPT_FONT_SIZE = 10
global const $USER_DIALOG_CHECK_FONT_SIZE = 9
global const $USER_DIALOG_FONT_NAME = "Segoe UI"
global const $USER_DIALOG_FONT_WEIGHT = $FW_NORMAL
global const $DIALOG_FONT_DEFAULT = "Consolas|8.5|400"
global const $INPUTBOX_FONT_DEFAULT = "Consolas|10|400|0"
global const $FONT_PREFS_MIN_SIZE = 6, $FONT_PREFS_MAX_SIZE = 72
global const $FONT_PREFS_ATTRIBUTES = BitOR($GUI_FONTITALIC, $GUI_FONTUNDER, $GUI_FONTSTRIKE)
global const $USER_DIALOG_ICON_GAP = 10
global const $USER_DIALOG_TEXT_NUDGE = 4
global const $USER_DIALOG_ICON_UP_NUDGE = 6
global const $USER_DIALOG_BUTTON_TEXT_PAD = 32
global const $USER_DIALOG_VISIBLE_MARGIN = 100
global const $USER_DIALOG_MIN_TRACK = 1

; App icon for dialog title bars is the executable's own built-in icon.

; UserDialog()
global $USER_DIALOG_OK[2] = [1, "OK"]
global $USER_DIALOG_YES_NO[3] = [2, "Yes", "No"]
global $minmax_limits[]
global $sized_handlers[]
global $notify_handlers[]
global const $MINMAXINFO_LAYOUT =	"long ReservedX;long ReservedY;long MaxSizeX;long MaxSizeY;long MaxPositionX;" & _
									"long MaxPositionY;long MinTrackSizeX;long MinTrackSizeY;long MaxTrackSizeX;long MaxTrackSizeY"




; Constants for Special Folders in Windows.

Const $WIN_Internet_Explorer						= 0x1
Const $WIN_Programs									= 0x2
Const $WIN_Control_Panel							= 0x3
Const $WIN_Printers_and_Faxes						= 0x4
Const $WIN_My_Documents								= 0x5
Const $WIN_Favorites								= 0x6
Const $WIN_Startup									= 0x7
Const $WIN_My_Recent_Documents						= 0x8
Const $WIN_SendTo									= 0x9
Const $WIN_Recycle_Bin								= 0xa
Const $WIN_WinStart_Menu							= 0xb
Const $WIN_My_Music									= 0xd
Const $WIN_My_Videos								= 0xe
Const $WIN_Desktop									= 0x10
Const $WIN_My_Computer								= 0x11
Const $WIN_My_Network_Places						= 0x12
Const $WIN_NetHood									= 0x13
Const $WIN_Fonts									= 0x14
Const $WIN_Templates								= 0x15
Const $WIN_All_Users_Start_Menu						= 0x16
Const $WIN_All_Users_Programs						= 0x17
Const $WIN_All_Users_Startup						= 0x18
Const $WIN_All_Users_Desktop						= 0x19
Const $WIN_Application_Data							= 0x1a
Const $WIN_PrintHood								= 0x1b
Const $WIN_Local_Settings_Application_Data			= 0x1c
Const $WIN_All_Users_Favorites						= 0x19
Const $WIN_Local_Settings_Temporary_Internet_Files	= 0x20
Const $WIN_Cookies									= 0x21
Const $WIN_Local_Settings_History					= 0x22
Const $WIN_All_Users_Application_Data				= 0x23
Const $WIN_Windows									= 0x24
Const $WIN_System32									= 0x25
Const $WIN_Program_Files							= 0x26
Const $WIN_My_Pictures								= 0x27
Const $WIN_User_Profile								= 0x28
Const $WIN_Common_Files								= 0x2b
Const $WIN_All_Users_Templates						= 0x2e
Const $WIN_Administrative_Tools						= 0x2f
Const $WIN_Network_Connections						= 0x31
Const $WIN_CD_Burning_Folder						= 0x003b

; OpenSpecialFolder($WIN_Recycle_Bin) .
func OpenSpecialFolder($Folder_ID)
	local $ShellObj = ObjCreate("Shell.Application")
	$ShellObj.Open($ShellObj.NameSpace($Folder_ID))
	$ShellObj = 0
endfunc







;
; BoolWord()
;
; Tests $word against a master boolean list. $which=true checks the true
; list, $which=false checks the false list. Exists because const arrays
; cannot be passed ByRef (so InArray() cannot read them); this reads them
; by index instead. Case-insensitive exact match. Returns true/false.
;
func BoolWord($word, $which)
	if $which then
		for $i = 1 to $BOOL_TRUE_WORDS[0]
			if $word = $BOOL_TRUE_WORDS[$i] then return true
		next
	else
		for $i = 1 to $BOOL_FALSE_WORDS[0]
			if $word = $BOOL_FALSE_WORDS[$i] then return true
		next
	endif
	return false
endfunc



;
; IsToggleWord()
;
; Tests $word against $BOOL_TOGGLE_WORDS ("toggle", "switch").
; Case-insensitive exact match. Returns true/false.
;
func IsToggleWord($word)
	local $clean = StringLower(StringStripWS($word, 3))
	for $i = 1 to $BOOL_TOGGLE_WORDS[0]
		if $clean = $BOOL_TOGGLE_WORDS[$i] then return true
	next
	return false
endfunc



;
; ParseCommandBool()
;
; Pure-boolean command params (on|off, nothing else): translates user
; command words to $ON/$OFF using the master lists (via BoolWord()).
; "1" is ON, "0" is OFF. Empty/missing params map to $OFF. Unknown
; words return $STATE_INVALID. Toggle words ("toggle", "switch") and
; empty calls are resolved by GetOnOffState(), not here.
;
func ParseCommandBool($bool_text)
	local $clean = StringLower(StringStripWS($bool_text, 3))
	if $clean = "" then return $OFF
	if $clean = "1" then return $ON
	if $clean = "0" then return $OFF
	if BoolWord($clean, false) then return $OFF
	if BoolWord($clean, true) then return $ON
	return $STATE_INVALID
endfunc




; Generic File & Folder Opening function.
;
; If it's a file, opens the given file in the user's editor.
; If it's a directory, opens in Explorer.
;
func OpenSomething($filepath, $use_log_viewer=false)

	debug("OpenSomething: =>" & $filepath & "<=" , @ScriptLineNumber, 7);debug

	if not FileExists($filepath) then
		debug($filepath & " not found!", @ScriptLineNumber, 1);debug
		return false
	endif

	if IsDir($filepath) then
		; Exact title match only. A substring match hits any editor window
		; showing a full path inside this folder, e.g. the ini file itself,
		; and just focuses that instead of opening the folder.
		local $open_windows = WinList()
		for $i = 1 to $open_windows[0][0]
			if $open_windows[$i][0] = $filepath then
				WinActivate($open_windows[$i][1])
				return
			endif
		next
		debug("Opening: =>" & $filepath & "<=" , @ScriptLineNumber, 7);debug
		Run("Explorer.exe """ & $filepath & '"')
		;ShellExecute($filepath)
	else
		local $user_editor = DeTokenizeString(IniRead($ini_path, $app_name, "editor", "notepad.exe"))

		if $use_log_viewer then
			local $log_viewer = DeTokenizeString(IniRead($ini_path, $app_name, "log_viewer", ""))
			if FileExists($log_viewer) then $user_editor = $log_viewer
		endif

		if not Run($user_editor & ' "' & $filepath & '"') then
			debug("ERROR! I couldn't run:" & '"' & $user_editor & '"', @ScriptLineNumber, 7);debug
			debug("You need to check your ini settings! ", @ScriptLineNumber, 7);debug
		endif
	endif
endfunc




; Functions that use it.
; These are standard in all apps that use this library.

; Open debug log file.
func OpenDebugLog()
	OpenSomething($debug_log)
endfunc




; User data dir.
func OpenDataDir()
	OpenSomething($data_dir)
endfunc




; Edit ini prefs.
func EditIniFile()
	;OpenSomething($ini_path)
	ShellExecute($ini_path)
endfunc




; Open log file.
func OpenLogFile()
	ShellExecute($log_location)
endfunc




; Position stored when a persistent tooltip opens; first movement or click away clears it.
global $persist_mouse[2] = [0, 0]


; Display a ToolTip message slightly up from the mouse position.
; pass $screen=true to place it instead at the centre-top of the screen.
; pass $persist=true to keep the tip until the first mouse movement or click
; instead of clearing it after $time; $time is then unused.
func DisplayTooltipMessage($message, $time=$DEF_MSG_TIME, $title=$app_name, $screen=false, $persist=false) ; $DEF_MSG_TIME = 2000

 debug("", @ScriptLineNumber, 7);debug
 debug("DisplayTooltipMessage(" & $message & "," & $time  & "," & $title & ")", @ScriptLineNumber, 7);debug

	local $x, $y

	if not $screen then
		local $mousepos = MouseGetPos()
		$x = $mousepos[0]
		$y = $mousepos[1]-16
	else
		$x = (@DesktopWidth/2)-StringLen($message)*3
		$y = 32
	endif

	ToolTip($message, $x, $y, $title, 1, $TIP_FORCEVISIBLE)
	debug("Displaying Message: =>" & $message & "<=" , @ScriptLineNumber, 7);debug
	AdLibUnRegister("ClearMessage")
	AdLibUnRegister("ClearMessageOnInput")
	if $persist then
		$persist_mouse = MouseGetPos()
		AdLibRegister("ClearMessageOnInput", 100)
	else
		AdLibRegister("ClearMessage", $time)
	endif
endfunc




; Clears the above message.
func ClearMessage()
 debug("", @ScriptLineNumber, 7);debug
 debug("ClearMessage()", @ScriptLineNumber, 7);debug
	ToolTip("")
	AdLibUnRegister("ClearMessage")
endfunc


; Clears a persistent tooltip on first input. Takes no parameters; reads the
; stored mouse position. AdLibRegister() runs this ten times a second after
; DisplayTooltipMessage(..., true); the first detected movement or
; left/right/middle click clears the tip and unregisters this watcher.
; Ordinary timed tips never call it.
func ClearMessageOnInput()
	if MouseGetPos(0) <> $persist_mouse[0] or MouseGetPos(1) <> $persist_mouse[1] or _IsPressed("01") or _IsPressed("02") or _IsPressed("04") then
		ToolTip("")
		AdLibUnRegister("ClearMessageOnInput")
	endif
endfunc




#cs

	Optional ToolTips

	Set a tooltip or don't, dependant on the global $do_tooltips variable,
	which you should set first, generally when gathering global prefs.

	This is a drop-in replacement for GUICtrlSetTip() and will happily
	work in this simple state.

	$options: these numbers can be added together.

		1 = Display as Balloon Tip
		2 = Centre the tip horizontally under the control
		And so on. See below this function for more details.

#ce

; Sets a tooltip on a control only when tooltips are enabled, filling defaults
; for text, title, icon and style. Used everywhere optional GUI tips are
; attached.
;
func GUICtrlSetTipOptional($control_ID, $tip_text=default, $title=default, $icon=default, $options=default)

	if $do_tooltips = $OFF then return

	if $tip_text = default then $tip_text = ""
	if $title = default then $title = "Information:"
	if $icon = default then $icon = $tip_icon
	if $options = default then $options = $tip_style

	; $options = BitOr($tip_style, $TTF_SUBCLASS, $TTF_IDISHWND, $TTF_PARSELINKS)
	; $options = $tip_style

	local $style = 0, $hicon, $ret
	$control_ID = GUICtrlGetHandle($control_ID)

	if BitAND($options, 1) then $style = $TTS_BALLOON
	$style = BitOr($style, $TTS_ALWAYSTIP)

	local $hToolTip = _GUIToolTip_Create(0, $style)

	$options = BitOr($options, $TTF_SUBCLASS, $TTF_IDISHWND)
	_GUIToolTip_AddTool($hToolTip, 0, $tip_text, $control_ID, default, default, default, default, $options, 0)

	; Time the pointer must remain stationary within a tool's bounding rectangle before the window appears.
	_GUIToolTip_SetDelayTime($hToolTip, $TTDT_INITIAL, 400)	; (500ms)
	; Time the ToolTip window remains visible if the pointer is stationary within a tool's bounding rectangle.
	_GUIToolTip_SetDelayTime($hToolTip, $TTDT_AUTOPOP, $tooltip_time) ; (5000ms)
	; Time it takes for subsequent ToolTip windows to appear as the pointer moves from one tool to another.
	_GUIToolTip_SetDelayTime($hToolTip, $TTDT_RESHOW, 150) ; (100ms)

	if not StringInStr($icon, ".") then
		_GUIToolTip_SetTitle($hToolTip, $title, $icon)
	else
		$hicon = DllStructCreate("ptr")
		$icon = StringSplit($icon, ",")

		if $icon[0] > 1 then
			$ret = DllCall("shell32.dll", _
									"uint", _
									"ExtractIconExW", _
									"wstr", $icon[$icon[0] - 1], _
									"int", -1 * (Int($icon[$icon[0]])), _
									"ptr", 0, _
									"ptr", DllStructGetPtr($hicon), _
									"uint", 1)

			if not @Error and $ret[0] then
				$hicon = DllStructGetData($hicon, 1)
			else
				$hicon = 0
			endif

			_GUIToolTip_SetTitle($hToolTip, $title, $hicon)
			DllCall("user32.dll", "none", "DestroyIcon", "handle", $hIcon)
		endif
	endif

	return $hToolTip
endfunc




#cs

	[optional] Flags that control the ToolTip display:

		global Const $TTF_IDISHWND = 0x00000001		- Indicates that $iID is a window or control handle, instead of the ID of the tool
		global Const $TTF_CENTERTIP = 0x00000002	- Centers the tooltip below the control specified by $iID
		global Const $TTF_RTLREADING = 0x00000004	- Indicates that text will be displayed in opposite direction of the parent window
													  (see remarks)
		global Const $TTF_SUBCLASS = 0x00000010		- Indicates that the control should subclass the tool's window
		global Const $TTF_TRACK = 0x00000020		- Positions the tooltip window next to the tool to which it corresponds
		global Const $TTF_ABSOLUTE = 0x00000080		- Positions the window at the same coordinates provided by TTM_TRACKPOSITION.
													  (see remarks)
		global Const $TTF_TRANSPARENT = 0x00000100	- Causes the control to forward mouse messages to the parent window
		global Const $TTF_PARSELINKS = 0x00001000	- Indicates that links in the control text should be displayed as links
		global Const $TTF_DI_SETITEM = 0x00008000

		Default = BitOr($TTF_SUBCLASS, $TTF_IDISHWND)
	_GUIToolTip_Create STYLE

		$TTS_ALWAYSTIP (0x01)	- Indicates that the ToolTip control appears when the cursor is on a tool even if the
								  ToolTip control's owner window is inactive.
								  Without this style, the ToolTip appears only when the tool's owner window is active.
		$TTS_NOPREFIX (0x02)	- Prevents the system from stripping the ampersand character from a string.
								  Without this style the system automatically strips ampersand characters.
								  This allows an application to use the same string as both a menu item and as text in a ToolTip control.
		$TTS_NOANIMATE (0x10)	- Disables sliding ToolTip animation.
		$TTS_NOFADE (0x20)		- Disables fading ToolTip animation.
		$TTS_BALLOON (0x40)		- Indicates that the ToolTip control has the appearance of a cartoon "balloon"
		$TTS_CLOSE (0x80)		- Displays a close icon so that the tooltip can be cancelled

		Default: $_TT_ghTTDefaultStyle = BitOr($TTS_ALWAYSTIP, $TTS_NOPREFIX)
Icon idx.

	 [optional] Set to one of the values below:.
		 $TTI_NONE (0) - No icon [default]
		 $TTI_INFO (1) - Information icon
		 $TTI_WARNING (2) - Warning icon
		 $TTI_ERROR (3) - Error Icon
		 $TTI_INFO_LARGE (4) - Large Information Icon
		 $TTI_WARNING_LARGE (5) - Large Warning Icon
		 $TTI_ERROR_LARGE (6) - Large Error Icon
#ce

; Dynamic @Tokens.
;
;
; There are 10 path tokens, 8 time tokens and 2 dimension tokens, as well as one
; clipboard token, one date token and lastly, user-definable variable tokens.
;
; The usual error checking has been omitted here - let the user have some fun!
;
; decode_linefeeds converts \n after ordinary @Token expansion. expand_lists
; inserts @Item and @ExplorerSelection last; false defers that insertion.
; Text consumers use these options to decode input without changing path data.
func DeTokenizeString($string, $inipath=$ini_path, $section=$app_name, $pref="date_format", $voice=default, $decode_linefeeds=false, $expand_lists=true)

 debug("", @ScriptLineNumber, 7);debug
 debug("DeTokenizeString(" & $string & ")", @ScriptLineNumber, 7);debug

	if not $string then return $string
	if not StringInStr($string, "@") then
		if $decode_linefeeds then return StringReplace($string, "\n", $LF)
		return $string
	endif

	; Replace the active speech voice before user @tokens.
	if $voice <> default then $string = StringReplace($string, "@Voice", $voice)

	; Replace user @tokens first (they may contain other tokens)
	$string = DeUserTokenizeString($string)
	; If no @Tokens remain, only requested line-break decoding is needed.
	if not StringInStr($string, "@") then
		if $decode_linefeeds then return StringReplace($string, "\n", $LF)
		return $string
	endif

	$string = ReplaceWorkAreaTokens($string)

	; Special @ClipBoard @Token.
	$string = StringReplace($string, "@ClipBoard", ClipGet())

	; Last selected text, captured by GetSelectedText().
	$string = StringReplace($string, "@Selected", $selected_text)

	; Lookup text is distinct from the captured selection.
	$string = StringReplace($string, $LOOKUP_TOKEN, $lookup_text)

	; Bounds of the window found by GetWindow().
	$string = StringReplace($string, "@WindowX", $window_x)
	$string = StringReplace($string, "@WindowY", $window_y)
	$string = StringReplace($string, "@WindowWidth", $window_width)
	$string = StringReplace($string, "@WindowHeight", $window_height)

	; Status code of the most recent HttpGET()/HttpPOST() request.
	$string = StringReplace($string, "@HttpStatus", $http_status)

	; The most recent @Random result, as a full path.
	$string = StringReplace($string, "@LastRandom", $last_random)

	; Date/Time @tokens.
	$string = DeTokenizeTimeStrings($string)
	$string = ReplaceDateTimeToken($string)
	$string = ReplaceDateToken($string, $inipath, $section, $pref)

	; Path @tokens.
	; We still replace these when $path=false
	$string = ReplacePathToken($string)

	if $decode_linefeeds then $string = StringReplace($string, "\n", $LF)
	if $expand_lists then $string = ExpandListTokens($string)

	debug("DeTokenizeString() RETURNING: =>" & $string & "<=", @ScriptLineNumber, 7);debug
	return $string
endfunc




; Inserts task list values without expanding @Tokens inside their data.
; Reads text, $explorer_selection and $foreach_item. Replaces occurrences in
; the supplied text only, including repeated tokens, and returns the result.
; Data from one token is never searched for another token. DeTokenizeString()
; calls this last; text consumers can defer insertion until after decoding.
func ExpandListTokens($string)
	; Replace list tokens from the original text, never from inserted paths.
	local $list_text = "", $list_offset = 1
	while true
		local $list_token = StringRegExp($string, "(?i)@(ExplorerSelection|Item)", 1, $list_offset)
		if not IsArray($list_token) then exitloop
		local $token = "@" & $list_token[0]
		local $token_start = StringInStr($string, $token, 0, 1, $list_offset)
		$list_text &= StringMid($string, $list_offset, $token_start-$list_offset)
		if $list_token[0] = "ExplorerSelection" then
			$list_text &= $explorer_selection
		else
			$list_text &= $foreach_item
		endif
		$list_offset = $token_start+StringLen($token)
	wend
	$string = $list_text & StringMid($string, $list_offset)
	return $string
endfunc


; Resolves usable monitor edges for placement and text containing @tokens.
; Reads the input string and an optional window handle; 0 selects the active
; window. UserDialogWorkArea() selects the monitor nearest the window centre
; and returns desktop-coordinate edges excluding reserved taskbar space.
; Returns the input with @WorkAreaLeft/Top/Right/Bottom replaced by numbers;
; text without @WorkArea bypasses the query. Failed monitor lookup uses the
; full virtual desktop bounds. Shared token expansion and coordinates call it.
func ReplaceWorkAreaTokens($string, $dialog=0)
	if not StringInStr($string, "@WorkArea") then return $string
	if not $dialog then $dialog = WinGetHandle("[ACTIVE]")
	local $area = UserDialogWorkArea($dialog)
	local $edges[4] = ["Left", "Top", "Right", "Bottom"]
	for $i = 0 to 3
		$string = StringReplace($string, "@WorkArea" & $edges[$i], $area[$i])
	next
	return $string
endfunc


; Replaces @MSec, @Sec, @Min and other time tokens in a string with current
; values. Used when expanding task text and display strings.
;
func DeTokenizeTimeStrings($string)
	$string = StringReplace($string, "@MSec", @MSec)
	$string = StringReplace($string, "@Sec", @Sec)
	$string = StringReplace($string, "@Min", @Min)
	$string = StringReplace($string, "@Hour", @Hour)
	$string = StringReplace($string, "@MDay", @MDay)
	$string = StringReplace($string, "@Mon", @Mon)
	$string = StringReplace($string, "@Year", @Year)
	$string = StringReplace($string, "@WDay", @WDay)
	$string = StringReplace($string, "@YDay", @YDay)
	$string = StringReplace($string, "@Weekday", _DateDayOfWeek(@WDAY))
	$string = StringReplace($string, "@Time", _NowTime())

	return $string
endfunc




func ReplaceDateToken($string, $inipath=$ini_path, $section=$app_name, $pref="date_format")
	$string = StringReplace($string, "@Date", GetUserDate($inipath, $section, $pref))
	return $string
endfunc




; Expands every supported DateTime variant so mixed formats all resolve.
; Reads only the input string and the current system date/time; returns the
; input with every @DateTime0..@DateTime5 replaced, or the unchanged string
; when none occur. All formats use one time snapshot. Called during token
; expansion; this function does not change preferences or global variables.
func ReplaceDateTimeToken($string)
	local $tokens = StringRegExp($string, "@DateTime[0-5]", $STR_REGEXPARRAYGLOBALMATCH)
	if not IsArray($tokens) then return $string

	local $now = _NowCalc()
	for $i = 0 to UBound($tokens)-1
		$string = StringReplace($string, $tokens[$i], _DateTimeFormat($now, Int(StringRight($tokens[$i], 1))))
	next
	return $string
endfunc




; We may be inside DeTokenizeString() here.
func GetUserDate($inipath=$ini_path, $section=$app_name, $pref="date_format")
	return DeTokenizeTimeStrings(IniRead($inipath, $section, $pref, @Year & "-" & @Mon & "-" & @Mday))
endfunc




; Replaces @DataDir, @ScriptsDir, @Documents, @Desktop and similar path tokens
; with real folders. Used before any ini path is touched. @ScriptsDir is the
; live scripts folder ($scripts_dir); before it is set it falls back to the
; factory default inside the data folder.
;
func ReplacePathToken($string)

	if $data_dir <> "" then
		$string = StringReplace($string, "@DataDir", $data_dir)
		if $scripts_dir <> "" then
			$string = StringReplace($string, "@ScriptsDir", $scripts_dir)
		else
			$string = StringReplace($string, "@ScriptsDir", $data_dir & "\Scripts")
		endif
	endif

	$string = StringReplace($string, "@AppDataDir", @AppDataDir)
	$string = StringReplace($string, "@WindowsDir", @WindowsDir)
	$string = StringReplace($string, "@SystemDir", @SystemDir)
	$string = StringReplace($string, "@Documents", @MyDocumentsDir)
	$string = StringReplace($string, "@MyDocumentsDir", @MyDocumentsDir)
	$string = StringReplace($string, "@MyDocuments", @MyDocumentsDir)
	$string = StringReplace($string, "@Desktop", @DesktopDir)
	$string = StringReplace($string, "@TempDir", @TempDir)
	$string = StringReplace($string, "@ScriptFullPath", @ScriptFullPath)
	$string = StringReplace($string, "@ThisApp", @ScriptFullPath)
	$string = StringReplace($string, "@KeyBind", @ScriptFullPath)
	$string = StringReplace($string, "@Me", @UserName)
	$string = StringReplace($string, "@UserProfileDir", @UserProfileDir)
	$string = StringReplace($string, "@UserDir", @UserProfileDir)
	$string = StringReplace($string, "@UserName", @UserName)
	$string = StringReplace($string, "@User", @UserName)

	$string = StringReplace($string, "@HomeDir", @HomeDrive & @HomePath)
	$string = StringReplace($string, "@HomeDrive", @HomeDrive)
	$string = StringReplace($string, "@HomePath", @HomePath)
	$string = StringReplace($string, "@ProgramFiles", @ProgramFilesDir)
	; $string = StringReplace($string, "@outputfile", $outputfile)
	return $string
endfunc




;
; Debugging is like particles and waves. With a shitload of debugging lines, you
; can't read the code, but you can read the debug output OK. It's code or debug
; output, never both at once (unless you leave your debug output open and then
; remove the debug lines to study both, but hey! It's nice philosophy!).
;

; User @tokens.
;
; 16 AlphaNumeric Characters Maximum.
;
; User variables will be named "var_VARIABLE_NAME"
; They will be declared using Assign(), with the Global flag.
;
; Skips processing if there are no known user tokens.
;
;2do. Still doesn't know what @tokens are standard @tokens
;2do - Maybe take this out of main Detokenize and call separately when required.
;
func DeUserTokenizeString($string)

 debug("", @ScriptLineNumber, 7);debug
 debug("DeUserTokenizeString(" & $string & ")", @ScriptLineNumber, 7);debug
 debugPrintArray($known_user_tokens, "cel.au3 :: $known_user_tokens:", @ScriptLineNumber, 7);debug

	if not StringInStr($string, "@") then return $string

	; No user tokens known: nothing in here can resolve, skip the work.
	if $known_user_tokens[0][0] < 1 then return $string

	local $this_token, $maybe_token
	local $split_string = StringSplit($string, "@")
	local $var_tag = "var_"

	for $i = 2 to $split_string[0] ; first element is /definitely/ not a @token.
		$this_token = ""
		$maybe_token = $split_string[$i]

		debug("$maybe_token: =>" & $maybe_token & "<=", @ScriptLineNumber, 7);debug

		; Remove everything after the alphanumerics and underscores.
		$this_token = StringRegExpReplace($maybe_token, "(\w+).*", "\1", 1)
		debug("Test $this_token: =>" & $this_token & "<=", @ScriptLineNumber, 7);debug

		; We got the length of the first Alphanumeric string.
		; Now test if that is a valid @token.

		; This @token assigned already (we double-check here).
		if InArray2D($known_user_tokens, $this_token, 0) and IsDeclared($var_tag & $this_token) then
			debug("SUCCESS!! Found USER Variable: =>@" & $this_token & "<=", @ScriptLineNumber, 7);debug
			; Replace the @token with the user's variable value.
			local $token_val = Eval($var_tag & $this_token)
			debug("Assign USER Value: " & $this_token & " => " & $token_val & "<=", @ScriptLineNumber, 7);debug
			$split_string[$i] = StringReplace($maybe_token, $this_token, $token_val)
		else
			; The grabbed word may be a known token plus glued text, as in @file_sizeMB. Use the longest known token that starts the word.
			local $best_name = ""
			local $best_len = 0
			for $token_row = 1 to $known_user_tokens[0][0]
				local $candidate = $known_user_tokens[$token_row][0]
				local $candidate_len = StringLen($candidate)
				if $candidate_len > $best_len and $candidate_len < StringLen($this_token) and StringLeft($this_token, $candidate_len) == $candidate and IsDeclared($var_tag & $candidate) then
					$best_name = $candidate
					$best_len = $candidate_len
				endif
			next
			if $best_name <> "" then
				local $glued_val = Eval($var_tag & $best_name)
				debug("SUCCESS!! Found glued USER Variable: =>@" & $best_name & "<=", @ScriptLineNumber, 7);debug
				$split_string[$i] = $glued_val & StringTrimLeft($maybe_token, $best_len)
			else ; no var of that name assigned., or empty ("@@")!!.
				debug("No Such User Token as @" & $this_token & "!", @ScriptLineNumber, 7);debug
				; Continue on, use it as-is (was) replacing the @ we took.
				$split_string[$i] = "@" & $maybe_token
			endif
		endif
	next

;

	; Pop all the pieces back together again.
	debugPrintArray($split_string, "cel.au3 :: $split_string:", @ScriptLineNumber, 7);debug
	$string = ArrayJoin($split_string, "")
	debug("DeUserTokenizeString() RETURNING: =>" & $string & "<=", @ScriptLineNumber, 7);debug

	return $string
endfunc




; Tokenize a string (create macro tokens).
; Start with longest paths. The live scripts folder goes first, so a custom
; scripts_dir outside the data folder still comes back as @ScriptsDir.
;
func TokenizeString($string, $path=true)
	if not $string then return $string
	if $path then $string = FixPathSlashes($string)

	if $data_dir <> "" then
		if $scripts_dir <> "" then $string = StringReplace($string, $scripts_dir, "@ScriptsDir")
		$string = StringReplace($string, $data_dir & "\Scripts", "@ScriptsDir")
		$string = StringReplace($string, $data_dir, "@DataDir")
	endif

	$string = StringReplace($string, @DesktopDir, "@Desktop")
	$string = StringReplace($string, @MyDocumentsDir, "@MyDocuments")
	$string = StringReplace($string, @SystemDir, "@SystemDir")
	$string = StringReplace($string, @WindowsDir, "@WindowsDir")
	$string = StringReplace($string, @AppDataDir, "@AppDataDir")
	$string = StringReplace($string, @HomeDrive & @HomePath, "@HomeDir")
	$string = StringReplace($string, @UserProfileDir, "@UserDir")
	$string = StringReplace($string, @TempDir, "@TempDir")
	$string = StringReplace($string, @ScriptFullPath, "@ThisApp")
	$string = StringReplace($string, @ProgramFilesDir, "@ProgramFiles")
	return $string
endfunc




; Fix potentially messed-up slashes.
func FixPathSlashes($string)
	if StringInStr($string, "://") then return $string ; but not for URLs
	; Watch out! We don't want to "fix" flags, like: del /f /q "C:\some/path\*"
	$string = StringRegExpReplace($string, "(.+)([^ ])/", "\1\2\\")
	$string = StringReplace($string, "\\", "\")
	return $string
endfunc




; CipherSaber stream cipher over text. Symmetric: the same call decrypts
; what it encrypted. Port of the CorzSpaZio routine in house style; the
; keystream setup matches the original 20-round form, so only the
; surrounding encoding differs. Empty keys fail.
func CipherSaberCrypt($data, $password, $loops=20)
	if $password = "" then return SetError(1, 0, "")
	local $i = 0, $swap = ""
	local $state[256]
	for $i = 0 to 255
		$state[$i] = $i
	next
	local $key_len = StringLen($password)
	local $key_bytes[256]
	for $i = 0 to 255
		$key_bytes[$i] = Asc(StringMid($password, Mod($i, $key_len)+1, 1))
	next
	local $j = 0
	for $round = 0 to $loops-1
		for $i = 0 to 255
			$j = BitAND($j+$state[$i]+$key_bytes[$i], 0xFF)
			$swap = $state[$i]
			$state[$i] = $state[$j]
			$state[$j] = $swap
		next
	next
	$i = 0
	$j = 0
	local $out = ""
	for $pos = 1 to StringLen($data)
		$i = BitAND($i+1, 0xFF)
		$j = BitAND($j+$state[$i], 0xFF)
		$swap = $state[$i]
		$state[$i] = $state[$j]
		$state[$j] = $swap
		$out &= Chr(BitXOR($state[BitAND($state[$i]+$state[$j], 0xFF)], Asc(StringMid($data, $pos, 1))))
	next
	return $out
endfunc




; Obscures ini secrets (mail passwords) with a random salt plus CipherSaber,
; hex-encoded for ini-safe text with an ENC: marker, so hand-typed values
; never decode by accident. NOT real security, just enough that outside
; eyes see nothing useful; the account itself remains the protection. ASCII
; only. Returns marked hex, empty on failure.
func MailEncrypt($text, $key)
	if $text = "" or $key = "" then return SetError(1, 0, "")
	local $salt = ""
	for $i = 1 to 10
		$salt &= Chr(Random(48, 57, 1))
	next
	local $cipher = CipherSaberCrypt($salt & $text, $key & $salt)
	if @error then return SetError(2, 0, "")
	local $hex = ""
	for $i = 1 to StringLen($cipher)
		$hex &= StringFormat("%02X", Asc(StringMid($cipher, $i, 1)))
	next
	return "ENC:" & $salt & $hex
endfunc




; Reverses MailEncrypt(). CorzSpaZio base64 blobs decrypt too, under their
; own key, so values copied from CorzSpaZio work untouched. The two forms
; frame differently: KeyBind ciphers salt and text together, CorzSpaZio
; ciphers the text alone with the salt only in the key. Returns the plain
; text, or empty with @error set when neither form decodes.
func MailDecrypt($blob, $key)
	if $blob = "" then return SetError(1, 0, "")
	local $salt = ""
	local $cipher = ""
	local $plain = ""
	if StringLeft($blob, 4) = "ENC:" then
		local $marked = StringMid($blob, 5)
		if not StringRegExp($marked, "^[0-9A-F]+$") or Mod(StringLen($marked), 2) or StringLen($marked) < 32 then return SetError(1, 0, "")
		$salt = StringLeft($marked, 10)
		for $i = 11 to StringLen($marked) step 2
			$cipher &= Chr(Dec(StringMid($marked, $i, 2)))
		next
		$plain = CipherSaberCrypt($cipher, $key & $salt)
		if @error then return SetError(2, 0, "")
		return StringMid($plain, 11)
	endif
	if StringRegExp($blob, "^[0-9A-F]+$") then
		if Mod(StringLen($blob), 2) or StringLen($blob) < 32 then return SetError(1, 0, "")
		$salt = StringLeft($blob, 10)
		for $i = 11 to StringLen($blob) step 2
			$cipher &= Chr(Dec(StringMid($blob, $i, 2)))
		next
		$plain = CipherSaberCrypt($cipher, $key & $salt)
		if @error then return SetError(2, 0, "")
		return StringMid($plain, 11)
	endif
	local $raw = Base64DecodeText($blob)
	if @error or StringLen($raw) < 11 then return SetError(3, 0, "")
	$salt = StringLeft($raw, 10)
	$cipher = CipherSaberCrypt(StringMid($raw, 11), "CorzSpaZio" & $salt)
	if @error then return SetError(4, 0, "")
	return $cipher
endfunc



; Decodes base64 text to a string. Compact table-free codec for short
; blobs like encrypted secrets. Returns "" with @error set on bad input.
func Base64DecodeText($text)
	local $alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local $clean = StringRegExpReplace($text, "[^A-Za-z0-9+/=]", "")
	if $clean = "" or Mod(StringLen($clean), 4) then return SetError(1, 0, "")
	local $out = ""
	for $group = 1 to StringLen($clean) step 4
		local $quad = StringMid($clean, $group, 4)
		local $bits = 0
		local $pad = 0
		for $char = 1 to 4
			$bits *= 64
			local $letter = StringMid($quad, $char, 1)
			if $letter = "=" then
				$pad += 1
			else
				local $value = StringInStr($alphabet, $letter, 1)-1
				if $value < 0 then return SetError(2, 0, "")
				$bits += $value
			endif
		next
		if $pad > 2 then return SetError(3, 0, "")
		$out &= Chr(BitAND(BitShift($bits, 16), 0xFF))
		if $pad < 2 then $out &= Chr(BitAND(BitShift($bits, 8), 0xFF))
		if $pad < 1 then $out &= Chr(BitAND($bits, 0xFF))
	next
	return $out
endfunc



; Conditional Right/Left Trim
;
; If the far-right character(s) is(are) such-and-such, remove it(them).
; Handy for normalizing path ends and other stuff.
;
; Because we need this sort of thing quite a lot.
;
;	if StringRight($string, 1) = "\" then $string = StringTrimRight($string, 1)
;
; Functions work on the string byref; you simply do:
;
;	CRT("my string")
;
; The idea of the names is; quick to type.
;
; These functions return a positive integer if any changes were made, the
; integer being the number of changes performed. Otherwise 0, so you can
; optionally set a variable from their return value.
;
;	$contains_modifier = CRT("my string")
;
; or use them in conditional statements.
;
;	if CRT("my string") then ..
;
; So.
; func CRT(byref $string, $character="\")
	; local $ret = 0, $char_num = StringLen($character)
	; if StringRight($string, $char_num) == $character then
		; while StringRight($string, $char_num) == $character
			; $ret += 1
			; $string = StringTrimRight($string, $char_num)
		; wend
	; endif
	; return $ret
; endfunc



func CRT(byref $string, $character="\")
	local $ret = 0, $char_num = StringLen($character)
	if not $char_num then return SetExtended(0, $string)

	if StringRight($string, $char_num) == $character then
		while StringRight($string, $char_num) == $character
			$ret += 1
			$string = StringTrimRight($string, $char_num)
		wend
	endif

	return SetExtended($ret, $string)
endfunc




; And for the left-hand side.
; The default character here is a space.
func CLT(byref $string, $character=" ")
	local $ret = 0, $char_num = StringLen($character)

	while StringLeft($string, $char_num) == $character
		$ret += 1
		$string = StringTrimLeft($string, $char_num)
	wend

	return $ret
endfunc




; And now both together.
; Note different default character.
; This double-function wrapper is mostly used for prefs lists.
;
; You can, however, send your own replacement character(s).
;
; Either specify one character to use it for both left and right,
; or specify both left and right characters.
;
func CBT(byref $string, $character_left=default, $character_right=default)
	if $character_left = default then $character_left = ","
	if $character_right = default then $character_right = $character_left
	local $ret = 0
	$ret += CLT($string, $character_left)
	$ret += CRT($string, $character_right)
	return $ret
endfunc




; Strip off any leading white space and pad with exact number of <$pad_string>.
; Used to separate parameters on the command-line (we add a space " ").
;
func PadLeft($string, $pad_string=" ", $number=1)
	$string = StringStripWS($string, $STR_STRIPLEADING)
	$string = _StringRepeat($pad_string, $number) & $string
	return $string
endfunc




; Tests whether a file can be created at a path, without ever
; touching an existing file. Creation is exclusive, so an
; existing path returns false instead of being truncated, and
; only the file this test created is deleted. Data in: the full
; probe path. Data out: true when the probe file was created and
; removed, false otherwise. Used by every directory writability
; check, beside FileExists().
;
; BUG: ffe, LoopDropZ, and MangleeZee call TestFileWrite() with real paths such as the intended log file; where the file already exists they now get false and fall back to the temp-dir log instead of truncating and deleting the existing log. That is the same data-loss bug, but their log location choice changes in that case.
func TestFileWrite($tmpfile)
	local $handle = _WinAPI_CreateFileEx($tmpfile, $CREATE_NEW, $GENERIC_WRITE, $FILE_SHARE_READ)
	if @error or not $handle then return false
	_WinAPI_CloseHandle($handle)
	FileDelete($tmpfile)
	return true
endfunc




;
; BubbleSort()

; A very basic, but very handy array sort.
; Designed for small lists; menus and such-like, where it excels.
; Purist can kiss my butt, this is simple, and elegant.
;
; NOTE: this is for "AutoIt Arrays", where the first value is
; the total number of elements. Basically, it will be left as-is.
; Also note, this is a case-insensitive search.
;
; To use.		BubbleSort($my_array)
;
func BubbleSort(byref $bs_array)

	for $i = uBound($bs_array)-1 to 1 step -1
		for $j = 2 to $i
			if $bs_array[$j-1] > $bs_array[$j] then
				local $temp = $bs_array[$j-1]
				$bs_array[$j-1] = $bs_array[$j]
				$bs_array[$j] = $temp
			endif
		next
	next

	return $bs_array
endfunc




;
; By the way, it should be noted that I have no idea why this works.
; Technically, using strings as numbers in AutoIt should implicitly call
; Number() and all "words" would be 0. But it does work, and works great!
; Hmmm.

;
; InsertionSort()

; Slightly different results, here.
; Simple algo, good for lists of numbers, and pretty fast, too.
;
func InsertionSort(byref $is_array)

	for $i = 1 to uBound($is_array)-1
		local $index = $is_array[$i]
		local $j = $i

		while $j > 1 and $is_array[$j-1] > $index
			$is_array[$j] = $is_array[$j-1]
			$j -= 1
		wend

		$is_array[$j] = $index
	next

	return $is_array
endfunc




; mail me if you want an AutoIt version of the QuickSort algo

; ShellSort()
; Invented by Donald Shell, 1959.
;
; More efficient than a BubbleSort.
; Good for repetative sorting of smaller lists.
; Neck-and-neck with InsertionSort in most of my tests.
;
; Note: This is designed for "AutoIt Arrays" (first element it the total).
;
func ShellSort(byref $some_array)

	local $increment = 1

	while $increment > 0
		for $i = 2 to uBound($some_array)-1
			local $j = $i
			local $temp = $some_array[$i]

			while $j >= $increment and $some_array[$j-$increment] > $temp
				$some_array[$j] = $some_array[$j-$increment]
				$j = $j - $increment
			wend

			$some_array[$j] = $temp
		next

		if $increment/2 <> 0 then ; ?
			$increment = int($increment/2)
		elseif $increment = 1 then
			$increment = 0
		else
			$increment = 1
		endif
	wend

	return $some_array
endfunc




;
; MaxMax()

; Evaluates two or three numbers and returns the highest.
; Because _Max($a,(_Max($b,$c)) is just plain ugly.
;
func MaxMax($num1, $num2, $num3=1.7E-308)
	if not IsNumber($num1) or not IsNumber($num2) or not IsNumber($num3) then return

	if $num1 > $num2 then
		if $num3 > $num1 then return $num3
		return $num1
	else
		if $num3 > $num2 then return $num3
		return $num2
	endif
endfunc




;
; MinMin()

; Evaluates two or three numbers and returns the smallest.
;
func MinMin($num1, $num2, $num3=1.7E+308)
	if not IsNumber($num1) or not IsNumber($num2) or not IsNumber($num3) then return

	if $num1 > $num2 then
		if $num3 < $num2 then return $num3
		return $num2
	else
		if $num3 < $num1 then return $num3
		return $num1
	endif
endfunc




; String format, a-la C.
;
func printf($format, $var1, $var2=-1, $var3=-1)

	if $var2=-1 then
		return StringFormat($format, $var1)
	else
		return StringFormat($format, $var1, $var2, $var3)
	endif
endfunc




; Repeats a given string a given number of times.
;
func StringRepeat($string, $count)
	$count = Int($count)
	if not $count then return ""
	if not StringLen($string) then return SetError(-1, 0, "Invalid Parameters sent.")
	local $return

	while $count
		$return &= $string
		$count -= 1
	wend

	return $return
endfunc




; A pipe is the delimiter used in ListViews, to separate columns.
; Obviously, literal pipes in our ListViews would cause all sorts of issues.
;
; So, when adding them to the ListView, we translate them into this identical-
; looking Unicode character. And back again when pulling them out. Simple.
;
; This is all completely transparent to the user, unless they happen across
; these comments somehow, in which case the game is up and I'm sure they will be
; absolutely furious.
;
; On Hebrew systems it probably shows up as a Star of David and then the joke is
; on me.
;
; These two functions are for when, for some reason, we can't do.
;
;	AutoItSetOption("GUIDataSeparatorChar", "") ; A Record Separator, Chr(30).
;
; FYI, good ole ASCII provides.
;
;	Chr(28):		File separator
;	Chr(29):		Group separator
;
; .in addition to the most appropriate separator for ListViews.
;
;	Chr(30):		Record separator
;
; By the way, if you /don't/ see a cute box with "RS" in it (or similar cute
; character), I can only assume you are using some piece-of-shit text editor not
; fit to view this code. In that case, go upgrade to something decent, eh!
; Notepad++ is free!	>>	https://notepad-plus-plus.org/
;
func Str2LV($string)
	return StringReplace($string, "|", "ǀ")		; ǀ <> | !		[U+01C0]
endfunc




func LV2Str($string)
	return StringReplace($string, "ǀ", "|")
endfunc




;
; NOTE: If you grab a task from the ListView in your code and forget to use this
; translations, you will be in for a debugging nightmare trying to figure out
; why "ǀfoo" is not equal to "|foo" when, you know, they LOOK THE SAME ..

;
; CleanPath()

; Clean-up potentially problematic file path characters.
;
func CleanPath($string, $chr="~")
	; $string = StringReplace($string, " ", "_")
	$string = StringReplace($string, "|", $chr)
	$string = StringReplace($string, '"', "'")
	$string = StringReplace($string, ":", $chr)
	$string = StringReplace($string, "*", $chr)
	$string = StringReplace($string, "/", $chr)
	$string = StringReplace($string, "\", $chr)
	$string = StringReplace($string, ">", $chr)
	$string = StringReplace($string, "<", $chr)
	$string = StringReplace($string, "?", $chr)
	return $string
endfunc




;
; CleanPrefName()

; Make a string safe to use in an ini [section pref name].
;
func CleanPrefName($string, $translate_spaces=true)
	$string = CleanPath($string)
	if $translate_spaces then $string = StringReplace($string, " ", "_")
	$string = StringReplace($string, '"', "_")
	$string = StringReplace($string, "'", "_")
	$string = StringReplace($string, "=", "_")
	$string = StringReplace($string, "[", "_")
	$string = StringReplace($string, "]", "_")
	$string = StringReplace($string, "(", "_")
	$string = StringReplace($string, ")", "_")
	$string = StringReplace($string, ".", "_")
	$string = StringReplace($string, ",", "_")
	$string = StringReplace($string, "-", "_")
	return $string
endfunc




;
; BaseName()

; Get the base name of a file from a full path.
; In other words; returns the path name without the folders part (ie. file name only)
func BaseName($bn_path)
	$bn_path = StringReplace($bn_path, "/", "\")
	CRT($bn_path)
	local $parts = StringSplit($bn_path, "\")
	local $bn_tmp = $parts[$parts[0]]
	CRT($bn_tmp, ":")
	return $bn_tmp
endfunc




;
; GetParent()

; Returns the parent directory, adding a long-path prefix when required.
func GetParent($gp_dir)
	local const $MAX_PATH_LENGTH = 260
	local $had_long_path_prefix = StringLeft($gp_dir, 4) = "\\?\"
	local $parent_path = __LFN_Target_UnSetUnicodePrefix($gp_dir)
	local $path_parts = StringSplit($parent_path, "\")
	$parent_path = StringTrimRight($parent_path, StringLen($path_parts[$path_parts[0]]) + 1)
	if $had_long_path_prefix or StringLen($parent_path) >= $MAX_PATH_LENGTH then return __LFN_Target_SetUnicodePrefix($parent_path)
	return $parent_path
endfunc




;
; GetLongParent()

; Returns the parent folder of a file or directory path.
func GetLongParent($some_path)
	local $use_extended = false
	if StringLeft($some_path, 4) = "\\?\" or StringLeft($some_path, 8) = "\\?\UNC\" then $use_extended = true
	if StringLen($some_path) > 258 then $use_extended = true
	if StringRight($some_path, 1) = "\" then $some_path = StringTrimRight($some_path, 1)
	$some_path = StripLongPathPrefix($some_path)

	if not StringInStr($some_path, "\", 2, 1, 3) or (StringInStr($some_path, "\UNC\") and not StringInStr($some_path, "\", 2, 1, 9)) then
		if $use_extended then
			return PrependLongPathPrefix($some_path)
		else
			return $some_path
		endif
	endif

	$some_path = StringLeft($some_path, StringInStr($some_path, "\", 2, -1) - 1)

	if $use_extended then
		return ConvertToLongPathFormat($some_path)
	else
		return $some_path
	endif
endfunc




;
; GetExtension()

; Returns the extension of a file name, e.g. "txt"
; If the file has no extension, returns a blank "" string
func GetExtension($some_name)
	if not StringInStr($some_name, ".") then return ""
	local $parts = StringSplit($some_name, ".")
	local $e = $parts[$parts[0]]
	; "." was not found - extensionless file, possibly in a path with a dot.
	if $e <> $some_name and not StringInStr($e, "\") then
		return $e
	else
		return ""
	endif
endfunc




;
; RemoveExtension()

; Removes the extension of a file name (including the dot ".")
; Requires the above functions.
; Also works for folders.
;
func RemoveExtension($some_name)
	local $add = 0
	if StringInStr(BaseName($some_name), ".") then $add = 1 ; might not have an extension
	return StringTrimRight($some_name, StringLen(GetExtension($some_name)) + $add)
endfunc




;
; CleanName()

; Returns a file name minus the path AND the extension.
; Basically does two of the above functions, all-in-one.
;
func CleanName($some_name)
	return RemoveExtension(BaseName($some_name))
endfunc






; Append text to a file's own name, before the extension. The original
; name remains: photo.jpg + "_sorted" becomes photo_sorted.jpg.
;
func MakeAppendName($old_name, $suffix)
	if $suffix = "" or $suffix = "-" then return $old_name
	return StringReplace($old_name, CleanName($old_name), CleanName($old_name) & $suffix)
endfunc




;
; SimpleProper()

; Very simple version of StringProper
; Capitalizes the first letter of a given ASCII string.
;
func SimpleProper($string)
	local $first_chr = Asc(StringLeft($string, 1))
	if $first_chr < 97 or $first_chr > 122 then return $string
	$string = Chr($first_chr-32) & StringMid($string, 2)
	return $string
endfunc




;
; ToProperCase()

; A more robust version
; Converts string to Title Case
func ToProperCase($text)

	local $is_new_word = true
	local $result = ""
	local $char = ""

	for $i = 1 to StringLen($text)
		$char = StringMid($text, $i, 1)

		select
			case $is_new_word
				if StringRegExp($char, "(?i)[a-z\p{L}]") then
					$char = StringUpper($char)
					$is_new_word = false
				endif

			case not StringRegExp($char, "(?i)[a-z\p{L}]")
				$is_new_word = true

			case else
				$char = StringLower($char)
		endselect

		$result &= $char
	next

	return $result
endfunc




;
; A2RBool()

; Convert my AutoIt boolean ($ON=1,$OFF=4) to regular boolean (on=1,off=0)
; Handy for converting prefs to functions that require regular normal booleans,
; e.g.
;
; 	WinSetOnTop($GUI, "", A2RBool($always_on_top))
;
; Basically converts 4 into 0 and anything else into 1.
;
func A2RBool($autoit_boolean)
	if $autoit_boolean == $OFF then return 0
	return 1
endfunc




;
; MakeTheParents()

; If the parent directories of a file do not exist, create them.
;
func MakeTheParents(byref $file_path)

	if not FileExists(GetParent($file_path)) then
		DirCreate(GetParent($file_path))
	endif
endfunc




;
; MakeAFile()

; If a file does not exist, create it.
;
func MakeAFile(byref $file_path, $create_new=false)

	if not FileExists($file_path) or $create_new then
		local $target_file = FileOpen($file_path, $FO_OVERWRITE)
		FileClose($target_file)
	endif
endfunc




#cs
 AppendFileData()

 Append the contents of $data_file to the end of $target_file.

 $flags are the usual FileOpen flags, which apply to opening $data_file.
 Obviously you don't want to send any WRITE flags. Nincompoop!
 But this is handy for forcing binary reading, or whatever.

 Useful flags:

    $FO_READ (0) = Read mode (default)	(Auto-Detects Encoding)
	$FO_APPEND (1) = Write mode (append to end of file)
    $FO_OVERWRITE (2) = Write mode (erase previous contents)
    $FO_CREATEPATH (8) = Create directory structure if it doesn't exist.
    $FO_BINARY (16) = Force binary (byte) data mode.
    $FO_UNICODE or $FO_UTF16_LE (32) = Use Unicode UTF16 Little Endian reading and writing mode.
    $FO_UTF16_BE (64) = Use Unicode UTF16 Big Endian reading and writing mode.
    $FO_UTF8 (128) = Use Unicode UTF8 (with BOM) reading and writing mode.
    $FO_UTF8_NOBOM (256) = Use Unicode UTF8 (without BOM) reading and writing mode.
    $FO_ANSI (512) = Use ANSI reading and writing mode.
    $FO_UTF16_LE_NOBOM (1024) = Use Unicode UTF16 Little Endian (without BOM) reading and writing mode.
    $FO_UTF16_BE_NOBOM (2048) = Use Unicode UTF16 Big Endian (without BOM) reading and writing mode.
    $FO_FULLFILE_DETECT (16384) = When opening for reading and no BOM is present, use the entire file to
								  determine if it is UTF8 or UTF16. If this is not used then only the
								  initial part of the file (up to 64KB) is checked for performance reasons.
#ce

; Appends the whole contents of one file onto another and returns the write
; result. Used when building reports and combined scripts.
;
func AppendFileData($target_file, $data_file, $flags=0)

	$data_file = FileOpen($data_file, $flags)
	local $file_data = FileRead($data_file)
	FileClose($data_file)

	$target_file = FileOpen($target_file, 1)
	local $return = FileWrite($target_file, $file_data)
	FileClose($target_file)

	return $return
endfunc




;
; GetWinDrive()

; Returns the parent DRIVE of a given path.
;
; "I:\temp\test\musk.mp3" >> returns: I
;
; Invalid (or UNC) paths return an empty string.
;
func GetWinDrive($gd_path)

	select
		case StringMid($gd_path, 2, 1) == ":"
			return StringLeft($gd_path, 1)

		case else
			return ""
	endselect
endfunc




;
; LnkToReal()

; Convert shortcut to its real target path.
; If link is invalid, returns false.
; If file path sent is not a .lnk file, returns the path that was sent.
; So you can safely insert it into any user's path choosing operation.
;
func LnkToReal($file)

	if GetExtension($file) = "lnk" then
		local $lnk_arr = FileGetShortCut($file)
		if IsArray($lnk_arr) and FileExists($lnk_arr[0]) then return $lnk_arr[0]
	else
		return $file
	endif

	return false
endfunc




; DateToDayOfWeekISO all-in-one.
;
func DateToDayOfWeekISO($iYear, $iMonth, $iDay)
	local $i_aFactor, $i_yFactor, $i_mFactor, $i_dFactor
	$i_aFactor = Int((14 - $iMonth) / 12)
	$i_yFactor = $iYear - $i_aFactor
	$i_mFactor = $iMonth + (12 * $i_aFactor) - 2
	$i_dFactor = Mod($iDay + $i_yFactor + Int($i_yFactor / 4) - Int($i_yFactor / 100) _
								+ Int($i_yFactor / 400) + Int((31 * $i_mFactor) / 12), 7)
	if $i_dFactor >= 1 then return $i_dFactor - 1
	return 6
endfunc




; For use in logs, etc.
;
func DateTimeString($msec=false, $sec=true, $time=true)
	local $addm, $adds
	if $time then $time = " @ " & @Hour & "." & @Min
	if $sec then $adds =  ":" & @Sec
	if $msec then $addm = "." & @Msec
	return @Year & "-" & @Mon & "-" & @Mday & $time & $adds & $addm
endfunc




; For backup files, etc.
;
func FileDateStamp()
	return @Year & "-" & @Mon & "-" & @Mday & "@" & @Hour & "." & @Min
endfunc




;
; FolderIsEmpty()

; Empty the folder is?
;
; Returns 0 is folder is not empty
; Returns 1 if the given folder path is empty
; Returns 2 if the path does not exist
;
func FolderIsEmpty($fie_folder)
	if not FileExists($fie_folder) then return 2
	local $ret = 0
	local $fie_search_files = FileFindFirstFile($fie_folder & "\*")
	if $fie_search_files = -1 then ; No files! Good!

		if @Error = 1 then
			$ret = 1
		else
			$ret = 2
		endif
	endif

	FileClose($fie_search_files)
	return $ret
endfunc




func IsWild($string)
	if StringInStr($string, "*") or StringInStr($string, "?") then return true
	return false
endfunc




; Check if a string is a directory path string and if so, add standard wildcards.
; If the supplied path is valid, return true, otherwise false.
;
func CheckDirWild(byref $pathstring)

	if IsDir($pathstring) and not IsWild($pathstring) then
		$pathstring &= "\*"
	endif

	local $testfiles = FileFindFirstFile($pathstring)
	if $testfiles = -1 then return false
	return true
endfunc




;
; IsDir()

; Is the given path a directory?
func IsDir($some_path)
	; simple but slow.
	; (although the fastest of all the methods I've tried - a lot)
	; return StringInStr(FileGetAttrib($some_path), "D") ;, 2 = slower!
	return StringInStr(_LFN_FileGetAttrib($some_path), "D")
endfunc




;
; ReadDir()

; Open a folder and return files with a particular $extension (no "." dot)
; as an array of file names. See RecurseDir() (below) for
; more functionality.
;
; NO Wild-Cards Allowed.
;
; Alternatively, supply full file name. Wilcards allowed.
func ReadDir($folder, $extension, $full_filename="")

	; AutoIt array handling is basic, to say the least!
	local $files[1]
	local $new_array[2]
	local $filename = "*."

	if $full_filename then
		$filename = $full_filename
		$extension = ""
	else
		CLT($extension, ".")
	endif

	local $init_dir = $folder & "\" & $filename & $extension

	; Create a "search handle" of all the *.$extension files in the folder
	local $search_files = FileFindFirstFile($init_dir)

	if $search_files = -1 then
		FileClose($search_files)
		$search_files = FileFindFirstFile($init_dir)
	endif

	local $i = 1

	do
		local $tmp = FileFindNextFile($search_files)
		$files[$i-1] = $tmp
		$i += 1 ; like php, same as $i = $i + 1
		redim $files[$i]
	until @Error

	FileClose($search_files) ; close the search handle

	; This removes the extraneous/empty elements from the array
	$i = 2

	for $this_file in $files
		local $entry = StringStripWS($this_file, $STR_STRIP_ENDS)

		if $entry then
			redim $new_array[$i]
			$new_array[0] = $i-1
			$new_array[$i-1] = $entry
			$i = $i + 1
		endif
	next

	; Wipe this array.
	$files = 0

	if $new_array[0] = "" then return 0

	; Return the array of filenames.
	return $new_array
endfunc




;
; RecurseDir()	v2.4
;
; Recursively search a directory structure for files matching a pattern
; and return its files as an array of file paths, the first value being the
; total number of file paths in the array (a-la "AutoIt Array").
;
; I spent some time testing many different routines. _GetFileList, by Jos van
; der Zande, always gave me the best results, and nicely coded, but around ten
; times slower (52s) than Larry (and Beerman's) recursion routines (4.9s) when
; recursing my home folder.**
;
; ** 1000 folders, 4773 files, 702MB. [cpu:1.3GHz, 640MB RAM] at time of writing
;
; This function is based on _GetFileList, but after a few hacks and tweaks is now
; more than fifteen times faster than the original.** The results are still as good,
; but instead of 50+ seconds to recurse my home folder, it now takes 3.3 seconds,
; making it fastest and bestest of all the AutoIt recursion routines! *tic*
;
; Note: you can now supply multiple file masks (needed for backup). It makes a lot
; of sense to grab any other extensions while we are in a directory.
; The delimiter is a comma.
;
;		RecurseDir("C:\Program Files", "*.reg,*.ini,*.cfg")
;
; When searching for multiple masks the speed improvements are *staggering*, and
; logarithmic; basically multiply the number of masks. For instance, a backup of
; all the pref files in my Program Files folder is scanned, copied, zipped and
; completed in around a minute. pretty good, considering it's over 12GB; all
; tools, no big game installs, and ten file masks to search.
;
; The optional third parameter "$top_level_only" tells RecurseDir() to only
; return matches for files in the top level directory, no deeper. (true/false)
; see also ReadDir() above.
;
; You can also supply an optional fourth parameter which is a string; the path to
; a "dump file" to dump (log) the paths of all matched files; for debugging only,
; because it will slow things down some.
;
; In v2.2 you can also supply an optional fifth parameter, "$return_dirs" which
; will do exactly that, returning an AutoIt array of all the directories in the
; path, and *only* the directories. (true/false)
;
; The optional 6th parameter ($max) is the maximum limit for queued
; directories, normally 1,000,000 (one million). The queue starts at 64
; entries and doubles as the tree needs it, so memory follows the tree,
; not the cap. The absolute maximum size for an array is around 8,388,606,
; so don't go above that, or you will get errors. Also, ensure this value
; is never zero.
;
; This function gets used a lot in my apps.
;
; **	A lot to do with using the "&=" operator. Those wee differences mount up.
;		Probably that operator wasn't available when the code was first written.
;

;global $quit = false
func RecurseDir($dir, $mask, $top_level_only=false, $dump="", $return_dirs=false, $mx=1000000)

	local $n_dirnames[64] = [0]	; Counted directory queue, grown as needed.
	local $n_dircount = 0
	local $n_file
	local $n_search
	local $n_tfile
	local $file_array
	local $filenames
;	local $filecount

	; if there was an "\" on the end of the given directory, remove that.
	CRT($dir)
	debug("$dir: =>" & $dir & "<=", @ScriptLineNumber, 7);debug

	ArrayAppendFast($n_dirnames, $dir)

	if not FileExists($dir) then return 0

	; Keep on looping until all directories are scanned.
	while $n_dirnames[0] > $n_dircount
;		if $quit = 1 then return

		$n_dircount += 1

		; Top-level-only scans match files below and never queue subdirs,
		; so the discovery pass is skipped outright.
		if not $top_level_only then
			$n_search = FileFindFirstFile($n_dirnames[$n_dircount] & "\*")
			if @Error then debug("@Error: =>" & @Error & "<=", @ScriptLineNumber, 7);debug
			debug("$n_search: =>" & $n_search & "<=", @ScriptLineNumber, 7);debug

			; Find all subdirs in this directory and store them in a array.
			while true
				$n_file = FileFindNextFile($n_search)
				if @Error then exitloop
				; Skip directory references.
				if $n_file = "." or $n_file = "." then continueloop

				$n_tfile = $n_dirnames[$n_dircount] & "\" & $n_file

				; If it's a directory, add it to the list of directories to be processed.
				if StringInStr(FileGetAttrib($n_tfile ), "D") then
					if $n_dirnames[0] < $mx then ArrayAppendFast($n_dirnames, $n_tfile)
				endif
			wend

			FileClose($n_search)
		endif

		; Multiple masks.
		if StringInStr($mask, ",", 2) then
			local $mask_array = StringSplit($mask, ",")
		else ; or else create a dummy array.
			local $mask_array[2] = [1, $mask]
		endif

		; Loop through the array of masks.
		for $mask_c = 1 to $mask_array[0]
			; Find all files that match this mask.
			$n_search = FileFindFirstFile($n_dirnames[$n_dircount] & "\" & $mask_array[$mask_c] )
			if $n_search = -1 then continueloop

			while true
				$n_file = FileFindNextFile($n_search)
				if @Error then exitloop ; end of dir
				if $n_file = "." or $n_file = "." then continueloop

				$n_tfile = $n_dirnames[$n_dircount] & "\" & $n_file

				if not StringInStr(FileGetAttrib( $n_tfile ), "D") then
;					$filecount += 1
					$filenames &= $n_tfile & @LF
				endif
			wend

			FileClose($n_search)
		next
	wend

	; Flip to a string and back to remove extraneous entries.
	; This is much quicker than redimming on every loop.
	if $return_dirs then
		local $tmp_str = ""
		local $i = 1

		while $n_dirnames[$i] <> ""
			$tmp_str &= $n_dirnames[$i] & "|"
			$i += 1
		wend

		$tmp_str = StringTrimRight($tmp_str, 1)
		$n_dirnames = StringSplit($tmp_str, "|")
		return $n_dirnames
	endif

	$filenames = StringTrimRight($filenames, 1)
	if $filenames = "" then return 0
	$file_array = StringSplit($filenames, @LF)

	; Dump results to a file.
	if $dump then
		local $dumpfile = FileOpen($dump, $FO_OVERWRITE)
		FileWrite($dumpfile, $filenames)
		FileClose($dumpfile)
	endif

	return($file_array)
endfunc




#cs

	IniReadCheckBoxValue()

	Slightly altered for BlobDrop and its "tristate" checkboxes.

	This function "transforms" an AutoIt or human unchecked value (4 or 0,
	respectively), into plain old 4, which AutoIt can understand. this
	function is intended as a drop-in replacement for the IniRead command,
	simply replace the function name. Of course, it's only useful when
	reading checkbox values, e.g.

		$big_switch = IniReadCheckBoxValue($ini_path, $app_name, "big_switch", $GUI_UNCHECKED)

	However I've gotten into the habit of using $GUI_CHECKED and
	$GUI_UNCHECKED as general booleans, which has proven to be very
	effective, especially when coupled with these two functions. I have them
	set to $ON and $OFF.

	global const $ON		= $GUI_CHECKED			; 1
	global const $OFF		= $GUI_UNCHECKED		; 4

	Why?

	Windows uses 1 as the value for checked checkboxes, and 4 as the value

	for unchecked checkboxes.* This makes passing the values directly in and
	out of ini files undesirable, because "4" is not a logical value, and
	most humans would expect it to be 0 (zero). The following two functions
	act as interface between the program and the ini file, making sense of
	the "human" equivalents. Other "human" values are also understood, just
	in case.

	Using these custom booleans enables us to pass values directly back-and-
	forth between user settings and GUI Controls and tray menu items DIRECTLY,
	e.g.

	TrayItemSetState($tray_menu, $some_pref)
																			#ce

; Reads an ini value as a checkbox state, returning the default when missing and
; indeterminate for blanks in three-state mode. Used by every checkbox pref.
;
func IniReadCheckBoxValue($rcbv_inifile, $rcbv_section, $rcbv_key, $rcbv_default, $three_state=false)

	; IF key NOT FOUND, returns DEFAULT
	; IF key BLANK (empty) returns INTERMEDIATE

	local $ircbv_val = IniRead($rcbv_inifile, $rcbv_section, $rcbv_key, "---")

	if $ircbv_val = "---" then $ircbv_val = $rcbv_default
	if $three_state and $ircbv_val = "" then return $GUI_INDETERMINATE

	; Boolean words come from $BOOL_TRUE_WORDS/$BOOL_FALSE_WORDS (via BoolWord()).
	if $ircbv_val = $GUI_UNCHECKED then return $GUI_UNCHECKED
	if $ircbv_val = $GUI_CHECKED then return $GUI_CHECKED
	local $clean = StringLower(StringStripWS($ircbv_val, 3))
	if $clean = "1" then return $GUI_CHECKED
	if $clean = "0" then return $GUI_UNCHECKED
	if $clean = "2" or $clean = "unset" or $clean = "-" or $clean = "maybe" then return $GUI_INDETERMINATE
	if BoolWord($clean, true) then return $GUI_CHECKED
	if BoolWord($clean, false) then return $GUI_UNCHECKED
	return $ircbv_val ; some special value
endfunc




;
; IniWriteCheckBoxValue()
; 2026-10-10 - now writes "", no more deleting.

; This function transforms an AutoIt checkbox value into a 'human' unchecked value (4 into 0, basically)
; this is intended as a drop-in replacement for the IniWrite command, simply replace the function name.
; Of course, it's only useful when writing checkbox values that will be read by 'IniReadCheckBoxValue'
; above. Instead of 0, you can also write "no", "off", or whatever, by passing the optional 5th parameter.
func IniWriteCheckBoxValue($wcbv_inifile, $wcbv_section, $wcbv_key, $wcbv_val, $tru_val="true", $fal_val="false")
	debug("IniWriteCheckBoxValue() : "&$wcbv_inifile&" : "&$wcbv_section&" : "&$wcbv_key&" : "&$wcbv_val, @ScriptLineNumber, 8);debug

	switch $wcbv_val
		case $GUI_CHECKED ; 1
			$wcbv_val = $tru_val

		case $GUI_UNCHECKED	; 4
			$wcbv_val = $fal_val

		case $GUI_INDETERMINATE	; 2
			$wcbv_val = ""
	endswitch

	if $wcbv_val then
		IniWrite($wcbv_inifile, $wcbv_section, $wcbv_key, $wcbv_val)
	else
		IniWrite($wcbv_inifile, $wcbv_section, $wcbv_key, "")
	endif
endfunc




; The above functions are useful until you create a proper preferences interface for your application!
; actually, I tend to use $GUI_CHECKED and $GUI_UNCHECKED as general-purpose booleans these days.
func ProcessReadHumanCheckBoxValue($some_string)
	; Boolean words come from $BOOL_TRUE_WORDS/$BOOL_FALSE_WORDS (via BoolWord()).
	if $some_string = $OFF then return $OFF
	if $some_string = $ON then return $ON
	local $clean = StringLower(StringStripWS($some_string, 3))
	if $clean = "1" then return $ON
	if $clean = "0" then return $OFF
	if BoolWord($clean, true) then return $ON
	if BoolWord($clean, false) then return $OFF
	; one last try for positive! .
	if StringLeft($clean, 1) = "y" then
		return $ON
	else
		return $OFF
	endif
endfunc




; For display purposes.
func ProcessWriteHumanCheckBoxValue($some_string, $on_str=$str_enabled, $off_str=$str_disabled, $indet_str="unset")

	switch $some_string
		case $ON
			return $on_str

		case $OFF
			return $off_str

		case $GUI_INDETERMINATE, ""
			return $indet_str

		case else
			return $some_string
	endswitch
endfunc




; Alias.
func Human($some_string, $on_str=$str_enabled, $off_str=$str_disabled,$indet_str="unset")
	return ProcessWriteHumanCheckBoxValue($some_string, $on_str, $off_str, $indet_str)
endfunc




;
;
; IniKeyExists()

; Feed it a 2-dimensional array (as supplied by IniReadSeaction)
; if the key exists, IniKeyExists() returns its value; if not, it returns false.
; The search is case-insensitive, but otherwise must be an exact (not partial) match.
; sometimes handy.
;
func IniKeyExists(byref $search_array, $search_string)

	if not IsArray($search_array) then
		return false
	endif

	for $i = 1 to $search_array[0][0]
		if $search_string = $search_array[$i][0] then
			return $search_array[$i][1]
		endif
	next

	return false
endfunc




; Simply creates an empty ini section you can later fill.
;
func CreateEmptyIniSection($inipath, $inisection)
	IniWrite($inipath, $inisection, "", "")
	IniDelete($inipath, $inisection, "")
endfunc




; The AutoIt built-in function moves the "new" section to the bottom of the ini
; file, which is annoying. This Blunderbuss approach works well, and leaves
; the section order as-is, meaning menus and such that rely on section order (or
; at least use it) won't find themselves reshuffled.
;
; Usage: BetterIniRenameSection(<path of ini file>, <Old Name>, <New Name>)
;
func BetterIniRenameSection($inifile, $old_name, $new_name)

	debug("", @ScriptLineNumber, 8);debug
	debug("cel.au3 :: BetterIniRenameSection($inifile=" & $inifile & ", $old_name=" & $old_name & ", $new_name=" & $new_name & "):", @ScriptLineNumber, 8);debug

	local $existing_sections = IniReadSectionNames($inifile)
	if not InArray($existing_sections, $old_name) then return SetError(1, 0, false)

	local $inifile_contents = FileRead($inifile)
	local $new_ini_string = StringReplace($inifile_contents, "[" & $old_name & "]", "[" & $new_name & "]")

	local $temp_inifile = _WinAPI_GetTempFileName(@TempDir & "\" & $app_name, "cel")
	FileDelete($temp_inifile)
	FileWrite($temp_inifile, $new_ini_string)

	; Compare ini files for matching (other) section names.
	local $compare1 = ArrayJoin($existing_sections, "|")
	$compare1 = StringReplace($compare1, $old_name, "|")

	local $new_sections = IniReadSectionNames($temp_inifile)
	local $compare2 = ArrayJoin($new_sections, "|")
	$compare2 = StringReplace($compare2, $new_name, "|")

	if StringCompare($compare1, $compare2) == 0 then
		BackupFile($inifile)
		FileMove($temp_inifile, $inifile, 1)
		return true
	endif

	return SetError(2, 0, false)
endfunc




; This tiny function saves a HEAP of code.
;
func TogglePref(byref $variable)

	if $variable = $ON then
		$variable = $OFF
	else
		$variable = $ON
	endif
endfunc




;
; GetToggledState()
;
; Returns the opposite of an $ON/$OFF state, without touching it.
;
func GetToggledState($state)
	if $state = $ON then return $OFF
	return $ON
endfunc




; Save one of the above tray prefs to the ini and set the state of the tray to
; match the setting.
;
func SaveTrayPref($tray_control, $pref_var, $pref_name)
	IniWriteCheckBoxValue($ini_path, $app_name, $pref_name, $pref_var)
	TrayItemSetState($tray_control, $pref_var)
endfunc




; InArray()		[for single-dimension arrays]
;
; Feed it an AutoIt array and a string, returns true if $ia_string
; is one of the $ia_array's *values*. Non-AutoIt arrays work fine,
; the first element is not relied upon, it is simply ignored.
;
; The search is case-insensitive, but must be an exact (not partial) match.
; There's probably a real function for this these days. (Not yet!)
;
func InArray(byref $ia_array, $ia_string, $match_case=false)
	if not IsArray($ia_array) then return false
	local $start_index = 0
	local $end_index = UBound($ia_array) - 1

	if IsNumber($ia_array[0]) and $ia_array[0] = $end_index then
		$end_index = $ia_array[0]
		$start_index = 1
	endif

	if $match_case then
		for $i = $start_index to $end_index
			if $ia_string == $ia_array[$i] then return $i
		next
	else
		for $i = $start_index to $end_index
			if $ia_string = $ia_array[$i] then return $i
		next
	endif

	return false
endfunc




; InArrayValue()		[for single-dimension arrays]
;
; Feed it an AutoIt (zero-indexed) array and a string, returns true if
; $ia_string is inside one of the $ia_array's *values*. Non-AutoIt arrays work
; fine, the first element is not relied upon, it is simply ignored.
;
; The search is case-insensitive, and can be a partial) match.
; Returns the index of the first value containing the string.
;
func InArrayValue(byref $ia_array, $ia_string)
	if not IsArray($ia_array) then return SetError(1, -8, false)
	local $start_index = 0
	local $end_index = UBound($ia_array) - 1

	if IsNumber($ia_array[0]) and $ia_array[0] = $end_index then
		$end_index = $ia_array[0]
		$start_index = 1
	endif

	for $i = $start_index to $end_index
		if StringInStr($ia_array[$i], $ia_string) then return $i
	next

	return false
endfunc




; InArrayColumn()	[for single-dimension arrays, with columned indexes]
;
; Feed it an AutoIt array and a string, returns true if $ia_string
; is a column of one of the $ia_array's *values*. Non-AutoIt arrays work
; fine, the first element is not relied upon, it is simply ignored.
;
; Because AutoIt's array-handling is almost non-existant, and redimming
; amazingly slow, other methods need to be devised to work with indexed
; lists. A "column marker" is simply a delimiter within the value which
; can be used to further split a value into multiple values.
;
; This function is designed to find text (e.g. "path/name.ext") inside a
; value that may look like. "path/name.ext|179|20080621114934".
;
; The search is case-insensitive, and must be an exact match for a
; particular column. Columns are numbered from 1, which is the value of
; the first column, and the correct match in the above example.
;
;	Success: Returns the index of the first value containing the string.
;	Fail: Returns false
;
func InArrayColumn(byref $ia_array, $ia_string, $col=1, $marker="*")
	if not IsArray($ia_array) then return SetError(1, -8, false)
	local $start_index = 0
	local $end_index = UBound($ia_array) - 1

	if IsNumber($ia_array[0]) and $ia_array[0] = $end_index then
		$end_index = $ia_array[0]
		$start_index = 1
	endif

	for $i = $start_index to $end_index
		local $columns = StringSplit($ia_array[$i], $marker, $STR_ENTIRESPLIT)

		if $col <= $columns[0] then
			if $columns[$col] == $ia_string then return $i
		endif
	next

	return false
endfunc




;
; MakeDummyArray()

; We need an array, but only have a string, what to do? this function returns an
; "AutoIt array" with a single data element, that is, two elements; $dummy_array[1]
; containing your string, and $dummy_array[0] being the total number of data elements,
; AutoIt-style, which will always be 1, of course.
;
; Although this is simple enough to do in place, it's more readable to do use a function.
;
func MakeDummyArray($regular_string)
	local $dummy_array[2] = [1, $regular_string]
	return $dummy_array
endfunc




; Send it a regular 1-D AutoIt array and get back a 2-D array, with
; the original array filling the first column, and a second, blank column
; for you to fill with "associated" data. See also Associative Array
; Functions, below.
func OneToTwoDArray($array)
	debug("OneToTwoDArray()", @ScriptLineNumber, 9);debug
	local $new_array[1][2]
	$new_array[0][0] = $array[0]

	for $e = 1 to $array[0]
		redim $new_array[$e+1][2] ; an extra 1!
		$new_array[$e][0] = $array[$e]
		$new_array[$e][1] = ""
		debugPrintArray($new_array, "cel.au3 :: 1D->2D Array:", @ScriptLineNumber, 9);debug
	next

	debugPrintArray($new_array, "cel.au3 :: 1D->2D RETURNING Array:", @ScriptLineNumber, 9);debug
	return $new_array
endfunc




;
; TwoD2OneDArray()

; Convert a 2-dimensional array into a 1-dimensional array
; of all the *values* of the original 2D array.
;
; Pass true as the 2nd parameter to instead have it made from the /keys/.
;
; The 3rd parameter is any character or string of characters you with to strip
; (replace with "") from each key or value. Handy for trimming @Macros and such.
;
func TwoD2OneDArray(byref $Array2D, $keys=false, $strip="")
	if not IsArray($Array2D) then return false
	local $array[$Array2D[0][0]+1]
	$array[0] = $Array2D[0][0]

	for $i = 1 to $Array2D[0][0]
		if $keys then local $key = $Array2D[$i][0]
		local $value = $Array2D[$i][1]

		if $strip then
			if $keys then $key = StringReplace($key, $strip, "")
			$value = StringReplace($value, $strip, "")
		endif

		if $keys then
			$array[$i] = $key
		else
			$array[$i] = $value
		endif
	next

	return $array
endfunc




; Take a two-dimensional array and convert it to a one-dimensional array
; using the chosen column of data.
func TwoDCol2OneDArray($Array2D, $col=0)
	debug("TwoDCol2OneDArray()", @ScriptLineNumber, 9);debug
	debugPrintArray($Array2D, "cel.au3 :: $Array2D:", @ScriptLineNumber, 7);debug
	if not IsArray($Array2D) then return false
	local $array[$Array2D[0][0]+1]
	$array[0] = $Array2D[0][0]

	for $i = 1 to $Array2D[0][0]
		$array[$i] = $Array2D[$i][$col]
		debugPrintArray($array, "cel.au3 :: $array:", @ScriptLineNumber, 9);debug
	next

	debugPrintArray($array, "cel.au3 :: 2D->1D RETURNING Array:", @ScriptLineNumber, 9);debug
	return $array
endfunc




; Takes a 2-dimensional array as input and splits it into two arrays,
; the first, all the indexes, the second, all the values.
;
func TwoD22OneDArrays(byref $Array2D)
	if not IsArray($Array2D) then return false
	local $array[$Array2D[0][0]+1]
	local $array2[$Array2D[0][0]+1]
	$array[0] = $Array2D[0][0]
	$array2[0] = $Array2D[0][0]

	for $i = 1 to $Array2D[0][0]
		$array[$i] = $Array2D[$i][0]
		$array2[$i] = $Array2D[$i][1]
	next

	local $newarray[2] = [$array, $array2]

	return $newarray
endfunc




#cs
	ArrayAdd()

	Add a single item to an AutoIt array.

	ArrayAdd() automatically increases the [0] index, but DOES NOT rely upon it.

	Enable the third parameter to NOT add items which already exist in the
	array.

	Set the fourth parameter to true, and when an item is added which
	already exists, the array is re-indexed, moving the entry to the END of
	the array. In other words, it becomes the "most recent entry".

#ce

; Appends an item to a counted array, skipping existing entries in unique mode
; or moving them last in update mode. Used for every key, app and trigger list.
;
func ArrayAdd(byref $array, $item, $unique=false, $update=false)

	if not IsArray($array) then return
	local $size = UBound($array)

	if $unique and $update = false then
		if InArray($array, $item) then return
	endif

	if $update then
		local $idx = InArray($array, $item)

		if $idx then
			for $i = $idx to $size-2
				$array[$i] = $array[$i+1]
			next

			$size -= 1
		endif
	endif

	redim $array[$size+1]
	$array[$size] = $item
	$array[0] = $size
endfunc


; Appends one item to a counted 1D array without unique or update checks,
; keeping $array[0] current on every call and doubling spare capacity
; instead of resizing per item. Data in: the array (numeric [0] is the
; item count) and the item. Data out: nothing; the count grows by one.
; Pre-size the array before the loop and trim once with redim
; $array[$array[0]+1] when done, so later InArray() calls see no spare
; cells. Runs from bulk collectors such as FolderSync and FileList().
;
func ArrayAppendFast(byref $array, $item)
	if not IsArray($array) then return
	local $capacity = UBound($array)
	if $capacity < 2 then $capacity = 2
	$array[0] += 1
	if $array[0]+1 >= $capacity then redim $array[$capacity*2]
	$array[$array[0]] = $item
endfunc




#cs
	ArrayRemove()

	If $item is a number, that index is removed, otherwise the array is
	searched for values matching {String} $item and that key is removed.

	Remaining elements are moved down to fill the gap and the resulting
	array is one element shorter. The [0] count element is updated with
	the new total.

	Returns true is changes were made, false otherwise.

#ce

; Removes an index or matching value from a counted array and closes the gap.
; Used to drop keys, triggers and list entries.
;
func ArrayRemove(byref $array, $item)

 debug("", @ScriptLineNumber, 7);debug
 debug("ArrayRemove(" & $item & ")", @ScriptLineNumber, 7);debug

	if not IsArray($array) then return SetError(1, 0, false)
	debugPrintArray($array, "cel.au3 :: Remove from this: $array:", @ScriptLineNumber, 7);debug

	local $match = false
	local $total_rows = UBound($array, $UBOUND_ROWS)-1
	debug("$total_rows: =>" & $total_rows & "<=", @ScriptLineNumber, 7);debug

	if IsNumber($item) then
		$match = $item
	else
		for $i = 1 to $total_rows
			debug("$array[$i] =>" & $array[$i] & "<=", @ScriptLineNumber, 7);debug

			if $array[$i] == $item then
				$match = $i
				; Stop here. Run through remaining rows.
				exitloop
			endif
		next
	endif

	if $match then
		for $k = $match to $total_rows-1
			; Fill /this/ row with the /next/ row's values.
			debug("$array[$k+1]: =>" & $array[$k+1] & "<=", @ScriptLineNumber, 7);debug
			$array[$k] = $array[$k+1]
		next

		Redim $array[$total_rows]
		$array[0] = $total_rows-1

		return true
	endif
endfunc




; An alias for the above function.
func ArrayDelete(byref $array, $item)
	return ArrayRemove($array, $item)
endfunc




#cs
	Very simple 2D array add.

	Param 1: The array to add to.
	Param 2: A pipe delimited list of values.

		ArrayAdd2D($my_array, "foo|bar|sheep|shoe")

	If your list has less items than there are columns, the remaining
	columns will be empty. If you list contains more items than there are
	columns, the extra items will be ignored. It's okay to send blank
	vaules.

		ArrayAdd2D($my_array, "||foo||bar")

	The index value $my_array[0][0] is automatically updated.

	Set the 3rd parameter to true to ensure no duplicate entries. Only the
	first column is checked.

 	Set the 4th parameter to true to replace existing values, otherwise if a
 	key already exists, it will we left alone.

 		ArrayAdd2D($array, "foo|bar|sheep|shoe", $unique, $replace_existing)

 	When a value itself holds the delimiter, supply a zero-based,
 	one-dimensional array of column values instead, with no count
 	element. Other array shapes fail and change nothing:

 		local $row[2] = ["foo", "bar|sheep"]
 		ArrayAdd2D($array, $row, $unique, $replace_existing)

 #ce

; Appends a row to a counted 2D array with unique and replace handling
; matched on the first column only. Used for token, trigger and preset
; tables. $items is a delimited string or, for values containing the
; delimiter, a zero-based one-dimensional array of column values.
;
func ArrayAdd2D(byref $array, $items, $unique=false, $replace=false, $delim="|")

	if not IsArray($array) then return SetError(1, 0, false)

	local $values[1] = [""]
	if IsArray($items) then
		if UBound($items, 0) <> 1 or UBound($items) < 1 then return SetError(3, 0, false)
		$values = $items
	else
		local $split = StringSplit($items, $delim, $STR_ENTIRESPLIT)
		redim $values[$split[0]]
		for $i = 1 to $split[0]
			$values[$i-1] = $split[$i]
		next
	endif
	debug("$values[0]: =>" & $values[0] & "<=", @ScriptLineNumber, 7);debug

	local $exists = InArray2D($array, $values[0], 0)
	debug("$exists: =>" & $exists & "<=", @ScriptLineNumber, 7);debug

	if $exists and $unique and not $replace then return SetError(2, 0, false)

	; Column 1 is empty, forget matching!
	if not $values[0] then $exists = false

	local $rows
	if $exists and $replace then $rows = $exists
	local $columns = UBound($array, $UBOUND_COLUMNS)

	if not $exists then
		$rows = UBound($array, $UBOUND_ROWS)
		redim $array[$rows+1][$columns]
		$array[0][0] += 1
		debug("$array[0][0]: =>" & $array[0][0] & "<=", @ScriptLineNumber, 7);debug
	endif

	; Add the items to this row.
	for $i = 0 to UBound($values)-1
		$array[$rows][$i] = $values[$i]
		if $i+1 = $columns then exitloop
	next

	return true
endfunc




#cs

	ArrayRemove2D(byref $array, $item, $column)

	Remove the first row of a 2D array where $array[row][$column] matches
	$item.

	Supply the array to search, a string to search for (This is a

	CaSe-sEnsItiVe search), and the column to search in for that string.
	When a match is found, the entire row is removed and the remaining rows
	are re-indexed from the removal point and the array is one row shorter.

	The count [0][0] element is not relied upon when removing rows, but it
	is updated with the correct new total, which will usually be the old
	total minus one.

	Returns true if changes were made, otherwise false.

#ce

; Removes the first row matching a value in a column of a 2D array. Used to drop
; token, trigger and preset rows.
;
func ArrayRemove2D(byref $array, $item, $column)

 debug("", @ScriptLineNumber, 7);debug
 debug("ArrayRemove2D([" & $item & "," & $column & "])", @ScriptLineNumber, 7);debug

	if not IsArray($array) then return SetError(1, 0, false)
	debugPrintArray($array, "cel.au3 :: Remove from: $array:", @ScriptLineNumber, 7);debug

	local $total_columns = UBound($array, $UBOUND_COLUMNS)
	local $total_rows = UBound($array, $UBOUND_ROWS)-1
	debug("$total_columns: =>" & $total_columns & "<=", @ScriptLineNumber, 7);debug
	debug("$total_rows: =>" & $total_rows & "<=", @ScriptLineNumber, 7);debug

	for $i = 1 to $total_rows
		debug("$array[$i][$column]: =>" & $array[$i][$column] & "<=", @ScriptLineNumber, 7);debug

		if $array[$i][$column] == $item then
			; Stop here. Run through remaining rows.
			for $k = $i to $total_rows-1
				; Fill /this/ row with the /next/ row's values.
				for $m = 0 to $total_columns-1
					debug("$array[$k+1][$m]: =>" & $array[$k+1][$m] & "<=", @ScriptLineNumber, 7);debug
					$array[$k][$m] = $array[$k+1][$m]
				next
			next

			Redim $array[$total_rows][$total_columns]
			$array[0][0] = $total_rows-1
			return true
		endif
	next
endfunc




#cs

	InArray2D($array, $search_string, $search_column)

	Very Simple 2D Array Search.
	Suppy:

		param 1: The 2D Array to search.
		param 2: The string to search for (CaSe-sEnsItiVe match).
		param 3: (optional) The column to search.
				 If this is omitted, all columns are searched.

	Returns the number of the row which contained the string as one of its
	column's values. Otherwise returns false.

	If you can suppply the search column, it will increase speed slightly.
	Column numbering begins at zero (0). Example.

		global $array[1][7]

		ArrayAdd2D($array, "|apple|pear||orange")
		ArrayAdd2D($array, "dog|cat|cow|pig|goat")
		ArrayAdd2D($array, "||||nut|seed|")

		local $row = InArray2D($array, "pig", 3)
		if $row then debug("PIG IN THE DUNGEON!!!", @ScriptLineNumber, 7);debug

		Will print out "PIG IN THE DUNGEON!!!"
		$row will equal 2.
#ce

; Returns the row containing a value, either in one column or across all columns.
; Used to look up tokens, triggers and presets.
;
func InArray2D(byref $array, $string, $search_column=false)

	if not IsArray($array) then return false

	local $rows = UBound($array, $UBOUND_ROWS) - 1
	local $columns = UBound($array, $UBOUND_COLUMNS)

	; Boolean false searches every column; numeric 0 searches column zero.
	local $search_all = VarGetType($search_column) = "Bool" and $search_column = false

	for $i = 1 to $rows
		if $search_all then
			for $k = 0 to $columns-1
				if $string == $array[$i][$k] then return $i
			next
		else
			if $string == $array[$i][$search_column] then return $i
		endif
	next

	return false
endfunc




; Take a comma-delimited list, usually an ini pref, check it's formatted okay
; and then convert to an array. It all happens ByRef.
;
func CommaDelimListToArray(byref $my_list)
	CBT($my_list, ",")
	$my_list = StringSplit(StringReplace($my_list, ",,", ","), ",") ; now an array
endfunc




; Improvements on the UDF-supplied versions; posted in the AutoIt forum.
;
; This is the fastest FileReadToArray, but uses the most memory for big files.
;
; #FUNCTION# ====================================================================================================================
; Name......:	FileReadIntoArray
; Description ..:	Reads the specified file into an array.
; Syntax.....:	FileReadIntoArray($TmpFile, ByRef $aArray [, $iFlag])
; Parameters ..:	$TmpFile		- Full path and filename of the file to be read.
;					$aArray			- The array in which to store the contents of the file.
;					$iFlag			- Optional: (add the flags together for multiple operations):
;					|$iFlag = 0 Return the array count in the [0] element (create 1-based array index - the Default)
;					|$iFlag = 1 Don't return the array count (create 0-based array index)
;					|$iFlag = 2 Don't return Line empty (ignores @CR & @LF & @CRLF)
;					|$iFlag = 4 Don't return Line empty or lines containing only whitespace character (ignores @CRLF, " ", @CR, @TAB, @CR, @LF, etc.)
;					|$iFlag = 8 Strip Line leading white space
; Return values .:	Success - Returns a 1
;					Failure - Returns a 0
;					@Error  - 0 = No error.
;					|1 = Error opening specified file
;					|2 = Unable to Split the file
; Authors ....:	Jonathan Bennett, Valik, Jpm, Gary, guinness, DXRW4E, corz.org
; ===============================================================================================================================
func FileReadIntoArray($TmpFile, byref $aArray, $iFlag = 0)
	local $ArrayCount, $RegExp = "(?:\r\n|\n|\r)([^\r\n]*)"
	local $hFileOpen = FileOpen($TmpFile, 0)
	if $hFileOpen = -1 then return SetError(1, 0, 0)
	local $sFileRead = StringStripWS(FileRead($hFileOpen), $STR_STRIP_ENDS)
	FileClose($hFileOpen)

	; Flags.
	if not BitAND($iFlag, 1) then $ArrayCount = "ArrayCount" & @LF
	if BitAND($iFlag, 2) then $RegExp = "(?:\r\n|\n|\r)([^\r\n]+)"
	if BitAND($iFlag, 4) then $RegExp = "s*(?:\r\n|\n|\r)([^\r\n]+)"
	if BitAND($iFlag, 8) then $RegExp = StringReplace($RegExp, ")", ")h*", 1, 1)

	$aArray = StringRegExp(@LF & $ArrayCount & $sFileRead, $RegExp, 3)

	if @Error then
		if StringLen($sFileRead) then
			local $ret[2] = [1, $sFileRead]
			$aArray = $ret
		else
			return SetError(2, 0, 0)
		endif
	elseif $ArrayCount then
		$aArray[0] = UBound($aArray) - 1
	endif

	return 1
endfunc




; func ArrayAddRow(byref $array, $row_data)
	; local $size = UBound($array, $UBOUND_COLUMNS)
; endfunc




; Native Map helper functions.
; Associative Arrays in AutoIt!

; Declare Maps directly in the calling script:
;
; 	global $associative_array[]
;
func AAAdd(byref $map, $key, $value, $unique = false)

	if MapExists($map, $key) then
		if $unique then return SetError(1, 1, -2)
		return SetError(1, 1, -1)
	endif

	$map[$key] = $value
	return true
endfunc




; Removes a key from a map, erroring when absent. Used to drop cached dialog
; state and handlers.
;
func AARemove(byref $map, $key)
	if not MapExists($map, $key) then return SetError(1, 1, -1)
	MapRemove($map, $key)
	return true
endfunc




func AAExists(byref $map, $key)
	return MapExists($map, $key)
endfunc




func AAGetItem(byref $map, $key)
	if not MapExists($map, $key) then return SetError(1, 1, "")
	return $map[$key]
endfunc




; Returns the number of keys in a map. Used to size loops over cached state.
;
func AACount(byref $map)
	local $map_keys = MapKeys($map)
	if not IsArray($map_keys) then return 0
	return UBound($map_keys)
endfunc




; Removes every key from a map. Used when dialog caches and handler tables are
; reset.
;
func AAWipe(byref $map)
	local $map_keys = MapKeys($map)
	local $key
	if not IsArray($map_keys) then return true

	for $key in $map_keys
		MapRemove($map, $key)
	next

	return true
endfunc




; Debug Function.
; List all the "Key" => "Item" pairs in the array.
func debugAAList(byref $map, $title = "Associative Array:", $line_number = @ScriptLineNumber, $level = 1)
	if not $debug_level or $level > $debug_level then return false

	local $map_keys = MapKeys($map)
	local $map_count = 0
	if IsArray($map_keys) then $map_count = UBound($map_keys)

	debug($title & " [" & $map_count & " items] :=>", $line_number, 10);debug

	for $index = 0 to $map_count - 1
		debug($map_keys[$index] & @TAB & "==>" & @TAB & $map[$map_keys[$index]], $line_number, 10)
	next
endfunc




#cs

	SaveComboSelection()

		SaveComboSelection( array{this combo box's special selection array}, string{value to store})

	Does what it says on the tin	(erm, also works for regular drop-downs!)

	If the user deletes an item, the previous item will be selected
	This makes multiple deltions easier, and more. This code is also
	more compact than checking for even a single "previous" entry on
	each combo box individually. It's neater, too.

	To use, simply create a global "AutoIt" array for the values,

	with the number of values you would like to remember (remember
	to set element 0 to the total).

		global $previous_combo_selections[501] = [500] ; plenty!

	Make one for each combo.
	Rather than set a limit, we could use redim, but it's  slow.

	Anyway, when the user selects something, store that.

		SaveComboSelection($previous_combo_selections, $current_preset)

	And when they delete an item, recall the previous item with.

		$previous_selection = GetComboSelection($previous_combo_selections_array, $valid_names_array)

	Or use it directly.

		ControlCommand($GUI_foo, "", $Control_ID, "SelectString", _
			GetComboSelection($previous_combo_selections_array, $valid_names_array))

	If your deleted entry is still in the list at the point you need to get this information,
	simply repeat the command. Essentially, go "back two".

		; this selects and removes the currently selected item.
		GetComboSelection($previous_combo_selections_array, $valid_names_array)

		; now the previous one.
		ControlCommand($GUI_foo, "", $Control_ID, "SelectString", _
			GetComboSelection($previous_combo_selections_array, $valid_names_array))

																			#ce

; Stores a combo value into the first empty slot of its history array. Used to
; remember recent combo choices.
;
func SaveComboSelection(byref $combo_array, $value)

	for $i = 1 to $combo_array[0]
		if $combo_array[$i] = "" then
			if $combo_array[$i-1] <> $value then
				$combo_array[$i] = $value
			endif

			exitloop ; store or not, we're outta here
		endif
	next
endfunc




;
; GetComboSelection()

; Get back the user's previous drop-down selection after a delete operation.
;
; We simply iterate the saved-combo strings array backwards, deleting all non-
; valid entries until the most recent valid entry is found. Then we delete it
; from the array and return the value.
;
; In the absence of a stored value, we return the "last" value in the names
; list. If deleting newly imported/created presets, this will get you the
; most recent addition, even when it hasn't been selected this session.
;
; It would be trivial to store this array in an ini file between launches, and
; keep a selection "history", if you require that.
;
; 	$String = GetComboSelection( array{this combo box's special selection array}, array{list of current valid names in this combo})
;
func GetComboSelection(byref $combo_array, byref $names_list)

	local $new_val = ""
	local $i = $combo_array[0]

	while $i > 0
		if $combo_array[$i] <> "" then
			if not InArray($names_list, $combo_array[$i]) then
				$combo_array[$i] = ""
				$i -= 1
				continueloop
			endif

			$new_val = $combo_array[$i]
			$combo_array[$i] = ""
			exitloop
		endif

		$i -= 1
	wend

	if $new_val = "" then $new_val = $names_list[$names_list[0]]
	return $new_val
endfunc




;
; VisitUrl()

; Send the "default browser" to our URL.

; This uses the USER'S SYSTEM BROWSER! (eg. Firefox)
func VisitUrl($VisitURL="https://corz.org/")
	debug("VisitURL: =>" & $VisitURL & "<=" , @ScriptLineNumber, 7);debug
	ShellExecute($VisitURL)

	if @Error <> 0 then
		return true
	else
		return SetError (@Error, default , true)
	endif
endfunc




;
; ReplaceHTMLEntities()

;
; Probably rather slow, but, erm, fairly thorough.
;
; Note: unless you are using a proper international font, many of the entities
; below will appear as boxes, or empty. Worry not, everything is working fine.
;
; Updated with routine from Dhilip89
;
func ReplaceHTMLEntities($text)

	Local $Entity[65536]

	$Entity[34] = "quot"
	$Entity[38] = "amp"
	$Entity[39] = "apos"
	$Entity[60] = "lt"
	$Entity[62] = "gt"
	$Entity[160] = "nbsp"
	$Entity[161] = "iexcl"
	$Entity[162] = "cent"
	$Entity[163] = "pound"
	$Entity[164] = "curren"
	$Entity[165] = "yen"
	$Entity[166] = "brvbar"
	$Entity[167] = "sect"
	$Entity[168] = "uml"
	$Entity[169] = "copy"
	$Entity[170] = "ordf"
	$Entity[171] = "laquo"
	$Entity[172] = "not"
	$Entity[173] = "shy"
	$Entity[174] = "reg"
	$Entity[175] = "macr"
	$Entity[176] = "deg"
	$Entity[177] = "plusmn"
	$Entity[178] = "sup2"
	$Entity[179] = "sup3"
	$Entity[180] = "acute"
	$Entity[181] = "micro"
	$Entity[182] = "para"
	$Entity[183] = "middot"
	$Entity[184] = "cedil"
	$Entity[185] = "sup1"
	$Entity[186] = "ordm"
	$Entity[187] = "raquo"
	$Entity[188] = "frac14"
	$Entity[189] = "frac12"
	$Entity[190] = "frac34"
	$Entity[191] = "iquest"
	$Entity[192] = "Agrave"
	$Entity[193] = "Aacute"
	$Entity[194] = "Acirc"
	$Entity[195] = "Atilde"
	$Entity[196] = "Auml"
	$Entity[197] = "Aring"
	$Entity[198] = "AElig"
	$Entity[199] = "Ccedil"
	$Entity[200] = "Egrave"
	$Entity[201] = "Eacute"
	$Entity[202] = "Ecirc"
	$Entity[203] = "Euml"
	$Entity[204] = "Igrave"
	$Entity[205] = "Iacute"
	$Entity[206] = "Icirc"
	$Entity[207] = "Iuml"
	$Entity[208] = "ETH"
	$Entity[209] = "Ntilde"
	$Entity[210] = "Ograve"
	$Entity[211] = "Oacute"
	$Entity[212] = "Ocirc"
	$Entity[213] = "Otilde"
	$Entity[214] = "Ouml"
	$Entity[215] = "times"
	$Entity[216] = "Oslash"
	$Entity[217] = "Ugrave"
	$Entity[218] = "Uacute"
	$Entity[219] = "Ucirc"
	$Entity[220] = "Uuml"
	$Entity[221] = "Yacute"
	$Entity[222] = "THORN"
	$Entity[223] = "szlig"
	$Entity[224] = "agrave"
	$Entity[225] = "aacute"
	$Entity[226] = "acirc"
	$Entity[227] = "atilde"
	$Entity[228] = "auml"
	$Entity[229] = "aring"
	$Entity[230] = "aelig"
	$Entity[231] = "ccedil"
	$Entity[232] = "egrave"
	$Entity[233] = "eacute"
	$Entity[234] = "ecirc"
	$Entity[235] = "euml"
	$Entity[236] = "igrave"
	$Entity[237] = "iacute"
	$Entity[238] = "icirc"
	$Entity[239] = "iuml"
	$Entity[240] = "eth"
	$Entity[241] = "ntilde"
	$Entity[242] = "ograve"
	$Entity[243] = "oacute"
	$Entity[244] = "ocirc"
	$Entity[245] = "otilde"
	$Entity[246] = "ouml"
	$Entity[247] = "divide"
	$Entity[248] = "oslash"
	$Entity[249] = "ugrave"
	$Entity[250] = "uacute"
	$Entity[251] = "ucirc"
	$Entity[252] = "uuml"
	$Entity[253] = "yacute"
	$Entity[254] = "thorn"
	$Entity[255] = "yuml"
	$Entity[338] = "OElig"
	$Entity[339] = "oelig"
	$Entity[352] = "Scaron"
	$Entity[353] = "scaron"
	$Entity[376] = "Yuml"
	$Entity[402] = "fnof"
	$Entity[710] = "circ"
	$Entity[732] = "tilde"
	$Entity[913] = "Alpha"
	$Entity[914] = "Beta"
	$Entity[915] = "Gamma"
	$Entity[916] = "Delta"
	$Entity[917] = "Epsilon"
	$Entity[918] = "Zeta"
	$Entity[919] = "Eta"
	$Entity[920] = "Theta"
	$Entity[921] = "Iota"
	$Entity[922] = "Kappa"
	$Entity[923] = "Lambda"
	$Entity[924] = "Mu"
	$Entity[925] = "Nu"
	$Entity[926] = "Xi"
	$Entity[927] = "Omicron"
	$Entity[928] = "Pi"
	$Entity[929] = "Rho"
	$Entity[931] = "Sigma"
	$Entity[932] = "Tau"
	$Entity[933] = "Upsilon"
	$Entity[934] = "Phi"
	$Entity[935] = "Chi"
	$Entity[936] = "Psi"
	$Entity[937] = "Omega"
	$Entity[945] = "alpha"
	$Entity[946] = "beta"
	$Entity[947] = "gamma"
	$Entity[948] = "delta"
	$Entity[949] = "epsilon"
	$Entity[950] = "zeta"
	$Entity[951] = "eta"
	$Entity[952] = "theta"
	$Entity[953] = "iota"
	$Entity[954] = "kappa"
	$Entity[955] = "lambda"
	$Entity[956] = "mu"
	$Entity[957] = "nu"
	$Entity[958] = "xi"
	$Entity[959] = "omicron"
	$Entity[960] = "pi"
	$Entity[961] = "rho"
	$Entity[962] = "sigmaf"
	$Entity[963] = "sigma"
	$Entity[964] = "tau"
	$Entity[965] = "upsilon"
	$Entity[966] = "phi"
	$Entity[967] = "chi"
	$Entity[968] = "psi"
	$Entity[969] = "omega"
	$Entity[977] = "thetasym"
	$Entity[978] = "upsih"
	$Entity[982] = "piv"
	$Entity[8194] = "ensp"
	$Entity[8195] = "emsp"
	$Entity[8201] = "thinsp"
	$Entity[8204] = "zwnj"
	$Entity[8205] = "zwj"
	$Entity[8206] = "lrm"
	$Entity[8207] = "rlm"
	$Entity[8211] = "ndash"
	$Entity[8212] = "mdash"
	$Entity[8216] = "lsquo"
	$Entity[8217] = "rsquo"
	$Entity[8218] = "sbquo"
	$Entity[8220] = "ldquo"
	$Entity[8221] = "rdquo"
	$Entity[8222] = "bdquo"
	$Entity[8224] = "dagger"
	$Entity[8225] = "Dagger"
	$Entity[8226] = "bull"
	$Entity[8230] = "hellip"
	$Entity[8240] = "permil"
	$Entity[8242] = "prime"
	$Entity[8243] = "Prime"
	$Entity[8249] = "lsaquo"
	$Entity[8250] = "rsaquo"
	$Entity[8254] = "oline"
	$Entity[8260] = "frasl"
	$Entity[8364] = "euro"
	$Entity[8465] = "image"
	$Entity[8472] = "weierp"
	$Entity[8476] = "real"
	$Entity[8482] = "trade"
	$Entity[8501] = "alefsym"
	$Entity[8592] = "larr"
	$Entity[8593] = "uarr"
	$Entity[8594] = "rarr"
	$Entity[8595] = "darr"
	$Entity[8596] = "harr"
	$Entity[8629] = "crarr"
	$Entity[8656] = "lArr"
	$Entity[8657] = "uArr"
	$Entity[8658] = "rArr"
	$Entity[8659] = "dArr"
	$Entity[8660] = "hArr"
	$Entity[8704] = "forall"
	$Entity[8706] = "part"
	$Entity[8707] = "exist"
	$Entity[8709] = "empty"
	$Entity[8711] = "nabla"
	$Entity[8712] = "isin"
	$Entity[8713] = "notin"
	$Entity[8715] = "ni"
	$Entity[8719] = "prod"
	$Entity[8721] = "sum"
	$Entity[8722] = "minus"
	$Entity[8727] = "lowast"
	$Entity[8730] = "radic"
	$Entity[8733] = "prop"
	$Entity[8734] = "infin"
	$Entity[8736] = "ang"
	$Entity[8743] = "and"
	$Entity[8744] = "or"
	$Entity[8745] = "cap"
	$Entity[8746] = "cup"
	$Entity[8747] = "int"
	$Entity[8756] = "there4"
	$Entity[8764] = "sim"
	$Entity[8773] = "cong"
	$Entity[8776] = "asymp"
	$Entity[8800] = "ne"
	$Entity[8801] = "equiv"
	$Entity[8804] = "le"
	$Entity[8805] = "ge"
	$Entity[8834] = "sub"
	$Entity[8835] = "sup"
	$Entity[8836] = "nsub"
	$Entity[8838] = "sube"
	$Entity[8839] = "supe"
	$Entity[8853] = "oplus"
	$Entity[8855] = "otimes"
	$Entity[8869] = "perp"
	$Entity[8901] = "sdot"
	$Entity[8968] = "lceil"
	$Entity[8969] = "rceil"
	$Entity[8970] = "lfloor"
	$Entity[8971] = "rfloor"
	$Entity[9001] = "lang"
	$Entity[9002] = "rang"
	$Entity[9674] = "loz"
	$Entity[9824] = "spades"
	$Entity[9827] = "clubs"
	$Entity[9829] = "hearts"
	$Entity[9830] = "diams"

	local $e1 = StringRegExp($text, '&#x(.*?);', 3)
	local $e2 = StringRegExp($text, '&#(.*?);', 3)
	local $e3 = StringRegExp($text, '&(.*?);', 3)

	for $i = 0 To UBound($e1) - 1 step 1
		$text = StringReplace($text, '&#x' & $e1[$i] & ';', ChrW(Dec($e1[$i])))
	next

	for $i = 0 To UBound($e2) - 1 step 1
		$text = StringReplace($text, '&#' & $e2[$i] & ';', ChrW($e2[$i]))
	next

	for $i = 0 To UBound($e3) - 1 step 1
		$text = StringReplace($text, '&' & $e3[$i] & ';', ChrW(_ArraySearch($Entity, $e3[$i], 0, 0, 1)))
	next

	return $text
endfunc




; Encodes every character of a string as a numeric HTML entity. Used when
; writing HTML reports.
;
func CreateHTMLEntities($string)
	local $len = StringLen($string)
	local $ret
	if not $len then return $string

	for $i = 1 to $len
		local $wchar = StringMid($string, $i, 1)
		$ret &= "&#" & AscW($wchar) & ";"
	next

	return $ret
endfunc




; Percent-encodes a URL string character by character. Used before opening or
; fetching URLs built from tasks.
;
func EnCodeUrl($text)
	$text = StringReplace($text, " ", "%20")
	$text = StringReplace($text, "!", "%21")
	$text = StringReplace($text, '"', "%22")
	$text = StringReplace($text, "#", "%23")
	$text = StringReplace($text, "$", "%24")
	$text = StringReplace($text, "%", "%25")
	$text = StringReplace($text, "&", "%26")
	$text = StringReplace($text, "'", "%27")
	$text = StringReplace($text, "(", "%28")
	$text = StringReplace($text, ")", "%29")
	$text = StringReplace($text, "*", "%2A")
	$text = StringReplace($text, "+", "%2B")
	$text = StringReplace($text, ",", "%2C")
	$text = StringReplace($text, "-", "%2D")
	$text = StringReplace($text, ".", "%2E")
	$text = StringReplace($text, "/", "%2F")
	$text = StringReplace($text, "0", "%30")
	$text = StringReplace($text, "1", "%31")
	$text = StringReplace($text, "2", "%32")
	$text = StringReplace($text, "3", "%33")
	$text = StringReplace($text, "4", "%34")
	$text = StringReplace($text, "5", "%35")
	$text = StringReplace($text, "6", "%36")
	$text = StringReplace($text, "7", "%37")
	$text = StringReplace($text, "8", "%38")
	$text = StringReplace($text, "9", "%39")
	$text = StringReplace($text, ":", "%3A")
	$text = StringReplace($text, ";", "%3B")
	$text = StringReplace($text, "<", "%3C")
	$text = StringReplace($text, "=", "%3D")
	$text = StringReplace($text, ">", "%3E")
	$text = StringReplace($text, "?", "%3F")
	$text = StringReplace($text, "@", "%40")
	$text = StringReplace($text, "A", "%41")
	$text = StringReplace($text, "B", "%42")
	$text = StringReplace($text, "C", "%43")
	$text = StringReplace($text, "D", "%44")
	$text = StringReplace($text, "E", "%45")
	$text = StringReplace($text, "F", "%46")
	$text = StringReplace($text, "G", "%47")
	$text = StringReplace($text, "H", "%48")
	$text = StringReplace($text, "I", "%49")
	$text = StringReplace($text, "J", "%4A")
	$text = StringReplace($text, "K", "%4B")
	$text = StringReplace($text, "L", "%4C")
	$text = StringReplace($text, "M", "%4D")
	$text = StringReplace($text, "N", "%4E")
	$text = StringReplace($text, "O", "%4F")
	$text = StringReplace($text, "P", "%50")
	$text = StringReplace($text, "Q", "%51")
	$text = StringReplace($text, "R", "%52")
	$text = StringReplace($text, "S", "%53")
	$text = StringReplace($text, "T", "%54")
	$text = StringReplace($text, "U", "%55")
	$text = StringReplace($text, "V", "%56")
	$text = StringReplace($text, "W", "%57")
	$text = StringReplace($text, "X", "%58")
	$text = StringReplace($text, "Y", "%59")
	$text = StringReplace($text, "Z", "%5A")
	$text = StringReplace($text, "[", "%5B")
	$text = StringReplace($text, "\", "%5C")
	$text = StringReplace($text, "]", "%5D")
	$text = StringReplace($text, "^", "%5E")
	$text = StringReplace($text, "_", "%5F")
	$text = StringReplace($text, "`", "%60")
	$text = StringReplace($text, "a", "%61")
	$text = StringReplace($text, "b", "%62")
	$text = StringReplace($text, "c", "%63")
	$text = StringReplace($text, "d", "%64")
	$text = StringReplace($text, "e", "%65")
	$text = StringReplace($text, "f", "%66")
	$text = StringReplace($text, "g", "%67")
	$text = StringReplace($text, "h", "%68")
	$text = StringReplace($text, "i", "%69")
	$text = StringReplace($text, "j", "%6A")
	$text = StringReplace($text, "k", "%6B")
	$text = StringReplace($text, "l", "%6C")
	$text = StringReplace($text, "m", "%6D")
	$text = StringReplace($text, "n", "%6E")
	$text = StringReplace($text, "o", "%6F")
	$text = StringReplace($text, "p", "%70")
	$text = StringReplace($text, "q", "%71")
	$text = StringReplace($text, "r", "%72")
	$text = StringReplace($text, "s", "%73")
	$text = StringReplace($text, "t", "%74")
	$text = StringReplace($text, "u", "%75")
	$text = StringReplace($text, "v", "%76")
	$text = StringReplace($text, "w", "%77")
	$text = StringReplace($text, "x", "%78")
	$text = StringReplace($text, "y", "%79")
	$text = StringReplace($text, "z", "%7A")
	$text = StringReplace($text, "{", "%7B")
	$text = StringReplace($text, "|", "%7C")
	$text = StringReplace($text, "}", "%7D")
	$text = StringReplace($text, "~", "%7E")
	$text = StringReplace($text, " ", "%7F")
	$text = StringReplace($text, "€", "%80")
	$text = StringReplace($text, " ", "%81")
	$text = StringReplace($text, "‚", "%82")
	$text = StringReplace($text, "ƒ", "%83")
	$text = StringReplace($text, "„", "%84")
	$text = StringReplace($text, "…", "%85")
	$text = StringReplace($text, "†", "%86")
	$text = StringReplace($text, "‡", "%87")
	$text = StringReplace($text, "ˆ", "%88")
	$text = StringReplace($text, "‰", "%89")
	$text = StringReplace($text, "Š", "%8A")
	$text = StringReplace($text, "‹", "%8B")
	$text = StringReplace($text, "Œ", "%8C")
	$text = StringReplace($text, " ", "%8D")
	$text = StringReplace($text, "Ž", "%8E")
	$text = StringReplace($text, " ", "%8F")
	$text = StringReplace($text, " ", "%90")
	$text = StringReplace($text, "‘", "%91")
	$text = StringReplace($text, "’", "%92")
	$text = StringReplace($text, "“", "%93")
	$text = StringReplace($text, "”", "%94")
	$text = StringReplace($text, "•", "%95")
	$text = StringReplace($text, "–", "%96")
	$text = StringReplace($text, "—", "%97")
	$text = StringReplace($text, "˜", "%98")
	$text = StringReplace($text, "™", "%99")
	$text = StringReplace($text, "š", "%9A")
	$text = StringReplace($text, "›", "%9B")
	$text = StringReplace($text, "œ", "%9C")
	$text = StringReplace($text, " ", "%9D")
	$text = StringReplace($text, "ž", "%9E")
	$text = StringReplace($text, "Ÿ", "%9F")
	$text = StringReplace($text, " ", "%A0")
	$text = StringReplace($text, "¡", "%A1")
	$text = StringReplace($text, "¢", "%A2")
	$text = StringReplace($text, "£", "%A3")
	$text = StringReplace($text, " ", "%A4")
	$text = StringReplace($text, "¥", "%A5")
	$text = StringReplace($text, "|", "%A6")
	$text = StringReplace($text, "§", "%A7")
	$text = StringReplace($text, "¨", "%A8")
	$text = StringReplace($text, "©", "%A9")
	$text = StringReplace($text, "ª", "%AA")
	$text = StringReplace($text, "«", "%AB")
	$text = StringReplace($text, "¬", "%AC")
	$text = StringReplace($text, "¯", "%AD")
	$text = StringReplace($text, "®", "%AE")
	$text = StringReplace($text, "¯", "%AF")
	$text = StringReplace($text, "°", "%B0")
	$text = StringReplace($text, "±", "%B1")
	$text = StringReplace($text, "²", "%B2")
	$text = StringReplace($text, "³", "%B3")
	$text = StringReplace($text, "´", "%B4")
	$text = StringReplace($text, "µ", "%B5")
	$text = StringReplace($text, "¶", "%B6")
	$text = StringReplace($text, "·", "%B7")
	$text = StringReplace($text, "¸", "%B8")
	$text = StringReplace($text, "¹", "%B9")
	$text = StringReplace($text, "º", "%BA")
	$text = StringReplace($text, "»", "%BB")
	$text = StringReplace($text, "¼", "%BC")
	$text = StringReplace($text, "½", "%BD")
	$text = StringReplace($text, "¾", "%BE")
	$text = StringReplace($text, "¿", "%BF")
	$text = StringReplace($text, "À", "%C0")
	$text = StringReplace($text, "Á", "%C1")
	$text = StringReplace($text, "Â", "%C2")
	$text = StringReplace($text, "Ã", "%C3")
	$text = StringReplace($text, "Ä", "%C4")
	$text = StringReplace($text, "Å", "%C5")
	$text = StringReplace($text, "Æ", "%C6")
	$text = StringReplace($text, "Ç", "%C7")
	$text = StringReplace($text, "È", "%C8")
	$text = StringReplace($text, "É", "%C9")
	$text = StringReplace($text, "Ê", "%CA")
	$text = StringReplace($text, "Ë", "%CB")
	$text = StringReplace($text, "Ì", "%CC")
	$text = StringReplace($text, "Í", "%CD")
	$text = StringReplace($text, "Î", "%CE")
	$text = StringReplace($text, "Ï", "%CF")
	$text = StringReplace($text, "Ð", "%D0")
	$text = StringReplace($text, "Ñ", "%D1")
	$text = StringReplace($text, "Ò", "%D2")
	$text = StringReplace($text, "Ó", "%D3")
	$text = StringReplace($text, "Ô", "%D4")
	$text = StringReplace($text, "Õ", "%D5")
	$text = StringReplace($text, "Ö", "%D6")
	$text = StringReplace($text, " ", "%D7")
	$text = StringReplace($text, "Ø", "%D8")
	$text = StringReplace($text, "Ù", "%D9")
	$text = StringReplace($text, "Ú", "%DA")
	$text = StringReplace($text, "Û", "%DB")
	$text = StringReplace($text, "Ü", "%DC")
	$text = StringReplace($text, "Ý", "%DD")
	$text = StringReplace($text, "Þ", "%DE")
	$text = StringReplace($text, "ß", "%DF")
	$text = StringReplace($text, "à", "%E0")
	$text = StringReplace($text, "á", "%E1")
	$text = StringReplace($text, "â", "%E2")
	$text = StringReplace($text, "ã", "%E3")
	$text = StringReplace($text, "ä", "%E4")
	$text = StringReplace($text, "å", "%E5")
	$text = StringReplace($text, "æ", "%E6")
	$text = StringReplace($text, "ç", "%E7")
	$text = StringReplace($text, "è", "%E8")
	$text = StringReplace($text, "é", "%E9")
	$text = StringReplace($text, "ê", "%EA")
	$text = StringReplace($text, "ë", "%EB")
	$text = StringReplace($text, "ì", "%EC")
	$text = StringReplace($text, "í", "%ED")
	$text = StringReplace($text, "î", "%EE")
	$text = StringReplace($text, "ï", "%EF")
	$text = StringReplace($text, "ð", "%F0")
	$text = StringReplace($text, "ñ", "%F1")
	$text = StringReplace($text, "ò", "%F2")
	$text = StringReplace($text, "ó", "%F3")
	$text = StringReplace($text, "ô", "%F4")
	$text = StringReplace($text, "õ", "%F5")
	$text = StringReplace($text, "ö", "%F6")
	$text = StringReplace($text, "÷", "%F7")
	$text = StringReplace($text, "ø", "%F8")
	$text = StringReplace($text, "ù", "%F9")
	$text = StringReplace($text, "ú", "%FA")
	$text = StringReplace($text, "û", "%FB")
	$text = StringReplace($text, "ü", "%FC")
	$text = StringReplace($text, "ý", "%FD")
	$text = StringReplace($text, "þ", "%FE")
	$text = StringReplace($text, "ÿ", "%FF")
	return $text
endfunc




; Decodes percent-encoded characters back to plain text. Used when reading URLs
; back from tasks and logs.
;
func DeCodeUrl($text)
	$text = StringReplace($text, "%20", " ")
	$text = StringReplace($text, "%21", "!")
	$text = StringReplace($text, "%22", '"')
	$text = StringReplace($text, "%23", "#")
	$text = StringReplace($text, "%24", "$")
	$text = StringReplace($text, "%25", "%")
	$text = StringReplace($text, "%26", "&")
	$text = StringReplace($text, "%27", "'")
	$text = StringReplace($text, "%28", "(")
	$text = StringReplace($text, "%29", ")")
	$text = StringReplace($text, "%2A", "*")
	$text = StringReplace($text, "%2B", "+")
	$text = StringReplace($text, "%2C", ",")
	$text = StringReplace($text, "%2D", "-")
	$text = StringReplace($text, "%2E", ".")
	$text = StringReplace($text, "%2F", "/")
	$text = StringReplace($text, "%30", "0")
	$text = StringReplace($text, "%31", "1")
	$text = StringReplace($text, "%32", "2")
	$text = StringReplace($text, "%33", "3")
	$text = StringReplace($text, "%34", "4")
	$text = StringReplace($text, "%35", "5")
	$text = StringReplace($text, "%36", "6")
	$text = StringReplace($text, "%37", "7")
	$text = StringReplace($text, "%38", "8")
	$text = StringReplace($text, "%39", "9")
	$text = StringReplace($text, "%3A", ":")
	$text = StringReplace($text, "%3B", ";")
	$text = StringReplace($text, "%3C", "<")
	$text = StringReplace($text, "%3D", "=")
	$text = StringReplace($text, "%3E", ">")
	$text = StringReplace($text, "%3F", "?")
	$text = StringReplace($text, "%40", "@")
	$text = StringReplace($text, "%41", "A")
	$text = StringReplace($text, "%42", "B")
	$text = StringReplace($text, "%43", "C")
	$text = StringReplace($text, "%44", "D")
	$text = StringReplace($text, "%45", "E")
	$text = StringReplace($text, "%46", "F")
	$text = StringReplace($text, "%47", "G")
	$text = StringReplace($text, "%48", "H")
	$text = StringReplace($text, "%49", "I")
	$text = StringReplace($text, "%4A", "J")
	$text = StringReplace($text, "%4B", "K")
	$text = StringReplace($text, "%4C", "L")
	$text = StringReplace($text, "%4D", "M")
	$text = StringReplace($text, "%4E", "N")
	$text = StringReplace($text, "%4F", "O")
	$text = StringReplace($text, "%50", "P")
	$text = StringReplace($text, "%51", "Q")
	$text = StringReplace($text, "%52", "R")
	$text = StringReplace($text, "%53", "S")
	$text = StringReplace($text, "%54", "T")
	$text = StringReplace($text, "%55", "U")
	$text = StringReplace($text, "%56", "V")
	$text = StringReplace($text, "%57", "W")
	$text = StringReplace($text, "%58", "X")
	$text = StringReplace($text, "%59", "Y")
	$text = StringReplace($text, "%5A", "Z")
	$text = StringReplace($text, "%5B", "[")
	$text = StringReplace($text, "%5C", "\")
	$text = StringReplace($text, "%5D", "]")
	$text = StringReplace($text, "%5E", "^")
	$text = StringReplace($text, "%5F", "_")
	$text = StringReplace($text, "%60", "`")
	$text = StringReplace($text, "%61", "a")
	$text = StringReplace($text, "%62", "b")
	$text = StringReplace($text, "%63", "c")
	$text = StringReplace($text, "%64", "d")
	$text = StringReplace($text, "%65", "e")
	$text = StringReplace($text, "%66", "f")
	$text = StringReplace($text, "%67", "g")
	$text = StringReplace($text, "%68", "h")
	$text = StringReplace($text, "%69", "i")
	$text = StringReplace($text, "%6A", "j")
	$text = StringReplace($text, "%6B", "k")
	$text = StringReplace($text, "%6C", "l")
	$text = StringReplace($text, "%6D", "m")
	$text = StringReplace($text, "%6E", "n")
	$text = StringReplace($text, "%6F", "o")
	$text = StringReplace($text, "%70", "p")
	$text = StringReplace($text, "%71", "q")
	$text = StringReplace($text, "%72", "r")
	$text = StringReplace($text, "%73", "s")
	$text = StringReplace($text, "%74", "t")
	$text = StringReplace($text, "%75", "u")
	$text = StringReplace($text, "%76", "v")
	$text = StringReplace($text, "%77", "w")
	$text = StringReplace($text, "%78", "x")
	$text = StringReplace($text, "%79", "y")
	$text = StringReplace($text, "%7A", "z")
	$text = StringReplace($text, "%7B", "{")
	$text = StringReplace($text, "%7C", "|")
	$text = StringReplace($text, "%7D", "}")
	$text = StringReplace($text, "%7E", "~")
	$text = StringReplace($text, "%7F", " ")
	$text = StringReplace($text, "%80", "€")
	$text = StringReplace($text, "%81", " ")
	$text = StringReplace($text, "%82", "‚")
	$text = StringReplace($text, "%83", "ƒ")
	$text = StringReplace($text, "%84", "„")
	$text = StringReplace($text, "%85", "…")
	$text = StringReplace($text, "%86", "†")
	$text = StringReplace($text, "%87", "‡")
	$text = StringReplace($text, "%88", "ˆ")
	$text = StringReplace($text, "%89", "‰")
	$text = StringReplace($text, "%8A", "Š")
	$text = StringReplace($text, "%8B", "‹")
	$text = StringReplace($text, "%8C", "Œ")
	$text = StringReplace($text, "%8D", " ")
	$text = StringReplace($text, "%8E", "Ž")
	$text = StringReplace($text, "%8F", " ")
	$text = StringReplace($text, "%90", " ")
	$text = StringReplace($text, "%91", "‘")
	$text = StringReplace($text, "%92", "’")
	$text = StringReplace($text, "%93", "“")
	$text = StringReplace($text, "%94", "”")
	$text = StringReplace($text, "%95", "•")
	$text = StringReplace($text, "%96", "–")
	$text = StringReplace($text, "%97", "—")
	$text = StringReplace($text, "%98", "˜")
	$text = StringReplace($text, "%99", "™")
	$text = StringReplace($text, "%9A", "š")
	$text = StringReplace($text, "%9B", "›")
	$text = StringReplace($text, "%9C", "œ")
	$text = StringReplace($text, "%9D", " ")
	$text = StringReplace($text, "%9E", "ž")
	$text = StringReplace($text, "%9F", "Ÿ")
	$text = StringReplace($text, "%A0", " ")
	$text = StringReplace($text, "%A1", "¡")
	$text = StringReplace($text, "%A2", "¢")
	$text = StringReplace($text, "%A3", "£")
	$text = StringReplace($text, "%A4", " ")
	$text = StringReplace($text, "%A5", "¥")
	$text = StringReplace($text, "%A6", "|")
	$text = StringReplace($text, "%A7", "§")
	$text = StringReplace($text, "%A8", "¨")
	$text = StringReplace($text, "%A9", "©")
	$text = StringReplace($text, "%AA", "ª")
	$text = StringReplace($text, "%AB", "«")
	$text = StringReplace($text, "%AC", "¬")
	$text = StringReplace($text, "%AD", "¯")
	$text = StringReplace($text, "%AE", "®")
	$text = StringReplace($text, "%AF", "¯")
	$text = StringReplace($text, "%B0", "°")
	$text = StringReplace($text, "%B1", "±")
	$text = StringReplace($text, "%B2", "²")
	$text = StringReplace($text, "%B3", "³")
	$text = StringReplace($text, "%B4", "´")
	$text = StringReplace($text, "%B5", "µ")
	$text = StringReplace($text, "%B6", "¶")
	$text = StringReplace($text, "%B7", "·")
	$text = StringReplace($text, "%B8", "¸")
	$text = StringReplace($text, "%B9", "¹")
	$text = StringReplace($text, "%BA", "º")
	$text = StringReplace($text, "%BB", "»")
	$text = StringReplace($text, "%BC", "¼")
	$text = StringReplace($text, "%BD", "½")
	$text = StringReplace($text, "%BE", "¾")
	$text = StringReplace($text, "%BF", "¿")
	$text = StringReplace($text, "%C0", "À")
	$text = StringReplace($text, "%C1", "Á")
	$text = StringReplace($text, "%C2", "Â")
	$text = StringReplace($text, "%C3", "Ã")
	$text = StringReplace($text, "%C4", "Ä")
	$text = StringReplace($text, "%C5", "Å")
	$text = StringReplace($text, "%C6", "Æ")
	$text = StringReplace($text, "%C7", "Ç")
	$text = StringReplace($text, "%C8", "È")
	$text = StringReplace($text, "%C9", "É")
	$text = StringReplace($text, "%CA", "Ê")
	$text = StringReplace($text, "%CB", "Ë")
	$text = StringReplace($text, "%CC", "Ì")
	$text = StringReplace($text, "%CD", "Í")
	$text = StringReplace($text, "%CE", "Î")
	$text = StringReplace($text, "%CF", "Ï")
	$text = StringReplace($text, "%D0", "Ð")
	$text = StringReplace($text, "%D1", "Ñ")
	$text = StringReplace($text, "%D2", "Ò")
	$text = StringReplace($text, "%D3", "Ó")
	$text = StringReplace($text, "%D4", "Ô")
	$text = StringReplace($text, "%D5", "Õ")
	$text = StringReplace($text, "%D6", "Ö")
	$text = StringReplace($text, "%D7", " ")
	$text = StringReplace($text, "%D8", "Ø")
	$text = StringReplace($text, "%D9", "Ù")
	$text = StringReplace($text, "%DA", "Ú")
	$text = StringReplace($text, "%DB", "Û")
	$text = StringReplace($text, "%DC", "Ü")
	$text = StringReplace($text, "%DD", "Ý")
	$text = StringReplace($text, "%DE", "Þ")
	$text = StringReplace($text, "%DF", "ß")
	$text = StringReplace($text, "%E0", "à")
	$text = StringReplace($text, "%E1", "á")
	$text = StringReplace($text, "%E2", "â")
	$text = StringReplace($text, "%E3", "ã")
	$text = StringReplace($text, "%E4", "ä")
	$text = StringReplace($text, "%E5", "å")
	$text = StringReplace($text, "%E6", "æ")
	$text = StringReplace($text, "%E7", "ç")
	$text = StringReplace($text, "%E8", "è")
	$text = StringReplace($text, "%E9", "é")
	$text = StringReplace($text, "%EA", "ê")
	$text = StringReplace($text, "%EB", "ë")
	$text = StringReplace($text, "%EC", "ì")
	$text = StringReplace($text, "%ED", "í")
	$text = StringReplace($text, "%EE", "î")
	$text = StringReplace($text, "%EF", "ï")
	$text = StringReplace($text, "%F0", "ð")
	$text = StringReplace($text, "%F1", "ñ")
	$text = StringReplace($text, "%F2", "ò")
	$text = StringReplace($text, "%F3", "ó")
	$text = StringReplace($text, "%F4", "ô")
	$text = StringReplace($text, "%F5", "õ")
	$text = StringReplace($text, "%F6", "ö")
	$text = StringReplace($text, "%F7", "÷")
	$text = StringReplace($text, "%F8", "ø")
	$text = StringReplace($text, "%F9", "ù")
	$text = StringReplace($text, "%FA", "ú")
	$text = StringReplace($text, "%FB", "û")
	$text = StringReplace($text, "%FC", "ü")
	$text = StringReplace($text, "%FD", "ý")
	$text = StringReplace($text, "%FE", "þ")
	$text = StringReplace($text, "%FF", "ÿ")
	return $text
endfunc




;
; EncodeUrlWord()
;
; Percent-encodes a single URL word/phrase (RFC 3986). Leaves unreserved
; characters alone, encodes spaces as %20 and everything else as UTF-8 %HH.
; Only the substituted word is encoded, never the surrounding URL.
;
func EncodeUrlWord($word)
	debug("EncodeUrlWord(" & $word & ")", @ScriptLineNumber, 7)

	local $utf8 = StringToBinary($word, $SB_UTF8)
	local $encoded = ""

	for $i = 1 to BinaryLen($utf8)
		local $byte = Number(BinaryMid($utf8, $i, 1))
		local $char = Chr($byte)

		if StringInStr($URL_UNRESERVED, $char, 0) then
			$encoded &= $char
		else
			$encoded &= "%" & Hex($byte, 2)
		endif
	next

	return $encoded
endfunc




;
; NormaliseSelectedPhrase()
;
; Collapses a selection (one word or many) to a single clean phrase.
; Multi-word selections stay intact, e.g. "ice  cream" becomes "ice cream".
;
func NormaliseSelectedPhrase($phrase)
	$phrase = StringReplace($phrase, @CRLF, " ")
	$phrase = StringReplace($phrase, @CR, " ")
	$phrase = StringReplace($phrase, @LF, " ")
	$phrase = StringReplace($phrase, @TAB, " ")
	$phrase = StringRegExpReplace($phrase, "[ ]{2,}", " ")
	return StringStripWS($phrase, $STR_STRIP_ENDS)
endfunc




;
; FetchDefineHtml()
;
; Downloads a page and returns it as a UTF-8 string. Keeps the raw HTML
; so ExtractInnerText() can still see the tags around the anchor.
;
func FetchDefineHtml($url)
	debug("FetchDefineHtml(" & $url & ")", @ScriptLineNumber, 5)

	local $page_data = InetRead($url, BitOR($INET_FORCERELOAD, $INET_FORCEBYPASS))
	if @error then return SetError(1, @error, "")
	return BinaryToString($page_data, $SB_UTF8)
endfunc




;
; ExtractInnerText()
;
; Finds the nearest unique identifier in raw HTML, steps past the end of
; the tag it sits inside, drills through any nested opening tags to the
; innermost text, and stops at the next closing tag. So the user only
; needs any stable nearby string, e.g. "id-def-0-0-0" yields the text
; inside its inner <span>. An optional end marker trims the result further.
;
; Locates the capture span a start marker anchors in raw HTML: past
; the tag the marker sits inside, then any nested opening tags down
; to the innermost text, stopping at its closing tag. An optional end
; marker trims the span further. Data in: the page and both markers.
; Data out: [from, stop] as 1-based positions. @error 3 without a
; marker, 4 without an anchor, 5 without the tag end, 6 without the
; closing tag. Used by ExtractInnerText() and LocateDefineSpan().
;
func DefineSpan($html, $start_marker, $end_marker="")
	if not $start_marker then return SetError(3, 0, "")
	local $anchor_pos = StringInStr($html, 'id="' & $start_marker & '"')
	if not $anchor_pos then $anchor_pos = StringInStr($html, "id='" & $start_marker & "'")
	if not $anchor_pos then $anchor_pos = StringInStr($html, $start_marker)
	if not $anchor_pos then return SetError(4, 0, "")
	local $tag_end = StringInStr($html, ">", 0, 1, $anchor_pos)
	if not $tag_end then return SetError(5, 0, "")
	local $from = $tag_end + 1
	local $html_len = StringLen($html)
	while $from <= $html_len
		local $here = StringMid($html, $from, 1)
		if $here <> " " and $here <> @TAB and $here <> @CR and $here <> @LF then exitloop
		$from += 1
	wend
	while $from <= $html_len and StringMid($html, $from, 1) = "<" and StringMid($html, $from, 2) <> "</"
		$tag_end = StringInStr($html, ">", 0, 1, $from)
		if not $tag_end then exitloop
		$from = $tag_end + 1
		while $from <= $html_len
			local $gap = StringMid($html, $from, 1)
			if $gap <> " " and $gap <> @TAB and $gap <> @CR and $gap <> @LF then exitloop
			$from += 1
		wend
	wend
	local $scan = $from
	local $depth = 1
	local $stop = 0
	while $scan <= $html_len
		local $tag_start = StringInStr($html, "<", 0, 1, $scan)
		if not $tag_start then exitloop
		$tag_end = StringInStr($html, ">", 0, 1, $tag_start)
		if not $tag_end then exitloop
		local $tag = StringStripWS(StringMid($html, $tag_start+1, $tag_end-$tag_start-1), $STR_STRIP_ENDS)
		if StringLeft($tag, 1) = "/" then
			$depth -= 1
			if $depth = 0 then
				$stop = $tag_start
				exitloop
			endif
		elseif $tag and StringLeft($tag, 1) <> "!" and StringLeft($tag, 1) <> "?" and _
				StringRight($tag, 1) <> "/" and not StringRegExp($tag, "(?i)^(area|base|br|col|embed|hr|img|input|link|meta|param|source|track|wbr)(\s|$)") then
			$depth += 1
		endif
		$scan = $tag_end+1
	wend
	if not $stop then return SetError(6, 0, "")
	if $end_marker then
		local $cut = StringInStr(StringMid($html, $from, $stop-$from), $end_marker)
		if $cut then $stop = $from+$cut-1
	endif
	local $span[2] = [$from, $stop]
	return $span
endfunc


func ExtractInnerText($html, $start_marker, $end_marker="")
	debug("ExtractInnerText(" & $start_marker & ") len =>" & StringLen($html) & "<=", @ScriptLineNumber, 5)

	local $span = DefineSpan($html, $start_marker, $end_marker)
	if @error then return SetError(@error, @extended, "")
	local $inner = StringMid($html, $span[0], $span[1]-$span[0])
	$inner = StringRegExpReplace($inner, "(?i)<br\s*/?>", " ")
	$inner = NormaliseSelectedPhrase(ReplaceHTMLEntities(StripHTML($inner, @LF)))
	if not $inner then return SetError(7, 0, "")
	return $inner
endfunc




; Strip HTML tags from a string.
;
func StripHTML($web_text, $lf=$LOG_LF)
	; strip out the HTML.
	$web_text = StringReplace($web_text, "&nbsp;", " ")
	$web_text = StringRegExpReplace($web_text, '</?[^>]*?>', '')
	$web_text = StringReplace($web_text, $lf & $lf, $lf)
	return StringStripWS($web_text, $STR_STRIP_ENDS)
endfunc




;
; OrdAbbAppend()

; Used to append ordinal abbreviations onto numbers, for
; use in human-readable numeric strings, mainly dates.
;
; Feed it a number, OrdAbbAppend() returns that number,
; plus the appendment, as a string. e.g.
;
;	$foo = OrdAbbAppend(20)
;	; $foo = "20th"
;
func OrdAbbAppend($d_str)

	if $d_str < 1 then
		SetError(1)
		return ""
	endif

	local $appends[10]
	$appends[0] = "th"
	$appends[1] = "st"
	$appends[2] = "nd"
	$appends[3] = "rd"
	$appends[4] = "th"
	$appends[5] = "th"
	$appends[6] = "th"
	$appends[7] = "th"
	$appends[8] = "th"
	$appends[9] = "th"

	if StringMid($d_str, StringLen($d_str)-1, 1) == 1 then
		$appends[1] = "th"
		$appends[2] = "th"
		$appends[3] = "th"
	endif

	return $d_str & $appends[StringRight($d_str, 1)]
endfunc




; Convert seconds to readable H/M/S time.
; Useful for timing things, like how long the app has been running.
;
func SecondsToDHMS($sec=0, $round=true)

	debug("SecondsToDHMS(sec) =>" & $sec & "<=", @ScriptLineNumber, 9);debug

	if $round then $sec = StringFormat("%.02f", $sec)

	if $sec < 0 then return -1

	select
		case  $sec < 61
			return $sec & " seconds"

		case $sec < 3601
			return StringFormat('%.01dm %.01ds', Mod(($sec / 60), 60), Mod($sec, 60))

		case $sec < 86401
			return StringFormat('%.01dh %.01dm %.01ds', Mod($sec / 3600, 24), Int(Mod(($sec / 60), 60)), Mod($sec, 60))

		case else
			return StringFormat('%.01dd %.01dh %.01dm %.01ds', Mod($sec / 86400, 7), _
						Mod($sec / 3600, 24), Int(Mod(($sec / 60), 60)), Mod($sec, 60))
	endselect
endfunc




;
; GetUptime()

; Formats System Uptime into a human-readable string.
;
func GetUptime()

	local $dll_call_result = DllCall("kernel32.dll", "uint64", "GetTickCount64")
	if @Error or not IsArray($dll_call_result) then return 0

	local $uptime_ms = $dll_call_result[0]
	local $total_seconds = Int($uptime_ms / 1000)
	local $current_date = _NowCalc()
	local $remaining_date = _DateAdd("s", -$total_seconds, $current_date)
	if @Error then return 0

	local $elapsed_years = _DateDiff("Y", $remaining_date, $current_date)
	$remaining_date = _DateAdd("Y", $elapsed_years, $remaining_date)
	local $elapsed_months = _DateDiff("M", $remaining_date, $current_date)
	$remaining_date = _DateAdd("M", $elapsed_months, $remaining_date)
	local $elapsed_weeks = _DateDiff("w", $remaining_date, $current_date)
	$remaining_date = _DateAdd("w", $elapsed_weeks, $remaining_date)
	local $elapsed_days = _DateDiff("D", $remaining_date, $current_date)
	$remaining_date = _DateAdd("D", $elapsed_days, $remaining_date)
	local $elapsed_hours = _DateDiff("h", $remaining_date, $current_date)
	$remaining_date = _DateAdd("h", $elapsed_hours, $remaining_date)
	local $elapsed_minutes = _DateDiff("n", $remaining_date, $current_date)
	$remaining_date = _DateAdd("n", $elapsed_minutes, $remaining_date)
	local $elapsed_seconds = _DateDiff("s", $remaining_date, $current_date)

	local $output_string = ""

	if $elapsed_years > 0 then
		$output_string &= $elapsed_years & "y "
	endif

	if $elapsed_years > 0 or $elapsed_months > 0 then
		$output_string &= StringFormat("%2dmo ", $elapsed_months)
	endif

	if $elapsed_years > 0 or $elapsed_months > 0 or $elapsed_weeks > 0 then
		$output_string &= StringFormat("%2dw ", $elapsed_weeks)
	endif

	if $elapsed_years > 0 or $elapsed_months > 0 or $elapsed_weeks > 0 or $elapsed_days > 0 then
		$output_string &= StringFormat("%2dd ", $elapsed_days)
	endif

	if $elapsed_years > 0 or $elapsed_months > 0 or $elapsed_weeks > 0 or $elapsed_days > 0 or $elapsed_hours > 0 then
		$output_string &= StringFormat("%2dh ", $elapsed_hours)
	endif

	if $elapsed_years > 0 or $elapsed_months > 0 or $elapsed_weeks > 0 or $elapsed_days > 0 or $elapsed_hours > 0 or $elapsed_minutes > 0 then
		$output_string &= StringFormat("%2dm ", $elapsed_minutes)
	endif

	$output_string &= StringFormat("%2ds", $elapsed_seconds)

	return StringStripWS($output_string, $STR_STRIP_ENDS)
endfunc




;
; UserTimeToUnitTime
;
; This is an emtremely limited function designed for specific back-end tasks.
; If you want to mess with time stuff, use the functions inside <Date.au3>.
;
; This converts "user" (Human) time to an integer unit of time.
; Input a string indicating a time, returns that time in some unit. Here's ms.
;
;	input		Returned Milliseconds
;	------		---------------------
;	1000	=>	1000
;	1000ms	=>	1000
;	1s		=>	1000
;	1m		=>	60000
;	1h		=>	3600000
;	1d		=>	86400000
;
; The second parameter controls the units which will be returned.
; By default it is milliseconds. You can also ask for s, m, h & d.
;
; You can specify "full info" (3rd parameter) which will have UserTimeToUnitTime
; return an array of two values, [0] = the final units, [1] = the user (human)
; unit they arrived in, e.g. "h".
;
func UserTimeToUnitTime($user_time, $time_unit="ms", $full_info=false)

	local $ret_array[2] = [0,"ms"]

	if IsNumber($user_time) then
		if $full_info then
			$ret_array[0] = $user_time
			return $ret_array
		else
			return $user_time
		endif
	endif

	select
		case StringRight($user_time, 2) = "ms"
			CRT($user_time, "ms")
			; leave number as-is
		case StringRight($user_time, 1) = "s"
			CRT($user_time, "s")
			$user_time *= 1000

		case StringRight($user_time, 1) = "m"
			CRT($user_time, "m")
			$user_time *= (1000*60)

		case StringRight($user_time, 1) = "h"
			CRT($user_time, "h")
			$user_time *= (1000*60*60)

		case StringRight($user_time, 1) = "d"
			CRT($user_time, "d")
			$user_time *= (1000*60*60*24)
	endselect

	switch $time_unit
		; case "ms" ; also 1st for quickness
			; $user_time = $user_time
		case "s"
			$user_time = $user_time/1000
			$ret_array[1] = "s"

		case "m"
			$user_time = $user_time/1000/60
			$ret_array[1] = "m"

		case "h"
			$user_time = $user_time/1000/60/60
			$ret_array[1] = "h"

		case "d"
			$user_time = $user_time/1000/60/60/24
			$ret_array[1] = "h"
	endswitch

	$ret_array[0] = Number($user_time)

	if $full_info then
		return $ret_array
	else
		return $user_time
	endif
endfunc




; 24h > Human Time > 24h.
;
;
; HourToHumanTime()

; Feed it a 24-hour format hour (e.g. "16").
; Returns a 1-dimensional array with two values.	[4, "pm"]
;
;	[0] = hour (integer in 12-hour clock format)
;	[1] = am/pm (string)
;
func HourToHumanTime($24hour)
	local $human_hour[2]
		$human_hour[0] = Number($24hour) ; 02 -> 2
		$human_hour[1] = "am"
		if $24hour > 11 then $human_hour[1] = "pm"
		if $24hour = 00 then $human_hour[0] = 12
		if $24hour > 12 then $human_hour[0] -= 12
		$human_hour[0] = int($human_hour[0])
	return $human_hour
endfunc




; And the reverse.
;
; Feed it the twelve-hour-clock format hour, and the am/pm string ("am" or "pm")
; Returns an integer (the hour, in 24 hour clock format, padded with a zero, if
; necessary), e.g.
;
;		HumanTimeToHour(3, "am") = 03
;		HumanTimeToHour(3, "pm") = 15
;
; I use two variables here because a) it's clearer, and b)
; I've been gagging to use the word "puter" in a variable for ages.
;
func HumanTimeToHour($12hour, $am_pm)
	local $puter_hours

	switch $am_pm
		case "am"
			if $12hour = 12 then
				$puter_hours = 0
			else
				$puter_hours = $12hour
			endif

		case "pm"
			if $12hour = 12 then
				$puter_hours = 12
			else
				$puter_hours = $12hour + 12
			endif
	endswitch

	return StringFormat("%02d", $puter_hours)
endfunc




; Convert a plain ASCII file to Unicode.
func MakeUnicodeFile($file)
	local $non_unicode_text = FileRead($file)
	; only ASCII will produce the same length string as file the size.
	if FileGetSize($file) = StringLen($non_unicode_text) then
		local $unicode_file = FileOpen($file, $FO_OVERWRITE + $FO_UTF16_LE)
		FileWrite($unicode_file, $non_unicode_text)
		return true
	endif

	; or else something bad happened.
	return false
endfunc




; Converts a named user line-feed choice to its actual separator.
; Takes LF, CRLF or CR, case-insensitively; reads no globals. Returns
; @LF for LF or an unrecognised choice, @CRLF for CRLF and @CR for CR.
; Preference loading and each ListView window use the same conversion.
func GetLineFeed($name)
	switch StringUpper($name)
		case "CRLF"
			return @CRLF
		case "CR"
			return @CR
	endswitch
	return @LF
endfunc


; Normalize all line-endings
; to @LF, or whatever; this is the fastest, bestest, simplest method.
func UnifyCRLF($some_text, $LF=@LF)
	return StringRegExpReplace($some_text, "\R", $LF)
endfunc




; Convert newlines from preferences "\n" to actual Linefeeds, for use in logs,
; console display, etc. Also works the other way around.
;
; Conversion happens ByRef, so simply do.
;
;	ConvertNewlines($string)
;
func ConvertNewlines(ByRef $pref_string, $reverse=false, $LF=$LOG_LF)

	if $reverse then
		$pref_string = StringReplace($pref_string, $LF, "\n")
	else
		$pref_string = StringReplace($pref_string, "\n", $LF)
	endif
endfunc




; Feed it a number (which is always a MB value), returns value + " MB". If the
; number is > 1024 MB, it is (optionally) converted and returned + " GB", then
; " TB".
func FormatMB($mb, $round=0, $array=false)

	local $return, $unit
	$mb = Number($mb)

	select
		case $mb = 0
			$return = 0

		case $mb < 1024
			$return = Round($mb, $round)
			$unit = "MB"

		case $mb >= 1048576
			$return = Round($mb / 1048576, $round)
			$unit = "TB"

		case $mb >= 1024
			$return = Round($mb / 1024, $round)
			$unit = "GB"
	endselect

	if $array then
		local $ret[2]
		$ret[0] = $mb
		$ret[1] = $unit
		return $ret
	endif

	return $return & " " & $unit
endfunc




; Converts a byte count to KB, MB or larger units with rounding. Used by file
; size displays and reports.
;
func BytesToByteUnit($bytes_value, $unit_required, $round=2)

 debug("", @ScriptLineNumber, 7);debug
 debug("BytesToByteUnit(" & $bytes_value & "," & $unit_required  & "," & $round & ")", @ScriptLineNumber, 7);debug

	local $return = $bytes_value
	; SI names are decimal (powers of 1000); IEC ..IB names are binary
	; (powers of 1024). Letter case, full names and a trailing S are free.
	local $unit = StringUpper(StringStripWS($unit_required, $STR_STRIP_ENDS))
	if StringRight($unit, 1) = "S" and StringLen($unit) > 1 then $unit = StringTrimRight($unit, 1)
	switch $unit
		case "B", "BYTE"
			$return = $bytes_value
		case "KB", "KILOBYTE"
			$return = Round($bytes_value/1000, $round)
		case "KIB", "KIBIBYTE"
			$return = Round($bytes_value/1024, $round)
		case "MB", "MEGABYTE"
			$return = Round($bytes_value/1000000, $round)
		case "MIB", "MEBIBYTE"
			$return = Round($bytes_value/1048576, $round)
		case "GB", "GIGABYTE"
			$return = Round($bytes_value/1000000000, $round)
		case "GIB", "GIBIBYTE"
			$return = Round($bytes_value/1073741824, $round)
		case "TB", "TERABYTE"
			$return = Round($bytes_value/1000000000000, $round)
		case "TIB", "TEBIBYTE"
			$return = Round($bytes_value/1099511627776, $round)
		case "PB", "PETABYTE"
			$return = Round($bytes_value/1000000000000000, $round)
		case "PIB", "PEBIBYTE"
			$return = Round($bytes_value/1125899906842624, $round)
		case "EB", "EXABYTE"
			$return = Round($bytes_value/1000000000000000000, $round)
		case "EIB", "EXBIBYTE"
			$return = Round($bytes_value/1152921504606846976, $round)
		case "ZB", "ZETTABYTE"
			$return = Round($bytes_value/1e21, $round)
		case "ZIB", "ZEBIBYTE"
			$return = Round($bytes_value/1.180591620717411e+021, $round)
		case "YB", "YOTTABYTE" ; Yottabyte	(named after Yoda!)
			$return = Round($bytes_value/1e24, $round)
		case "YIB", "YOBIBYTE"
			$return = Round($bytes_value/1.208925819614629e+024, $round)
	endswitch

	debug("Returning: =>" & $return & "<=", @ScriptLineNumber, 7);debug

	return $return
endfunc




; Create a random String.
; Returns a string of "random" upper and lower case letters to the specified length.
; Only letters are returned, no special characters.
func MakeRandomString($length=32, $seed=@Min*@Sec*@MSec)

 debug("", @ScriptLineNumber, 7);debug
 debug("MakeRandomString(" & $seed & ")", @ScriptLineNumber, 7);debug

	SRandom($seed)
	local $a[$length]
	local $x = 0

	while $a[$length-1] = ""
		local $tmp = Chr(Random(65, 122, 1))

		if StringIsAlpha($tmp) then
			$a[$x] = Asc($tmp)
			$x += 1
		endif
	wend

	$a = StringFromASCIIArray($a)
	debug("MakeRandomString() returning: =>" & $a & "<=", @ScriptLineNumber, 7);debug
	return $a
endfunc




; local $first_done = false
; if not $params then $params = 12
; for $i = 1 to Random($random_name_lower_limit, $params, 1)
	; if not $first_done then
		; $new_name &= Chr(Random(65, 90, 1))
		; $first_done = true
	; endif
	; $new_name &= Chr(Random(97, 122, 1))
; next

; From Color-Pickin-Chooser.
;

;
; ConvertColorValue()

;	ConvertColorValue(RGB_color{HEX}, mode{TEXT}, add_prefix{BOOL}, index{INT} (0=return full 6 digits), lowercase{BOOL})
;
;	To get this.		Use any of these.
;	-------------		--------------------------------------------------------
; 	RGB Integer:		"i", "RGB Integer", "RGB Int" or "int".
; 	AutoIt RGB			"a", "Autoit RGB Hex", "Autoit RGB", "AutoIt Hex", or "AutoIt".
; 	AutoIt BGR			"b", "Autoit BGR Hex", "Autoit BGR", "BGR Hex" or "bgr".
; 	Delphi Hex			"d", "Delphi" or "Delphi Hex".
; 	Visual C++ BGR		"v", "vc", "Visual C++ Hex", "Visual C++ BGR", "Visual C++", "Visual C++ BGR Hex" or "C++".
; 	RGB Float			"RGB Float", "float" or "f".
; 	HSL					"h", "Hue/Sat/Lum", "HSL" or "h/s/l".
; 	CMYK				"k", "cmyk" or "c/m/y/k".
; 	Web Hex				"w", "Web Hex", "Web", or "Hex".
func ConvertColorValue($color, $mode = "web", $prefix = false, $index = 0, $lowercase = $off)
	if StringLeft($color, 1) = "#" Then $color = StringTrimLeft($color, 1)
	local $pre = ""

	switch $mode
		case "i", "RGB Integer", "RGB Int", "int"
			switch $index
				case 0
					$color = Dec(StringLeft($color, 2)) & "," & Dec(StringMid($color, 3, 2)) & "," & Dec(StringRight($color, 2))

				case 1
					return Dec(StringLeft($color, 2))

				case 2
					return Dec(StringMid($color, 3, 2))

				case 3
					return Dec(StringRight($color, 2))
			endswitch

		case "a", "Autoit RGB Hex", "Autoit RGB", "AutoIt Hex", "AutoIt"
			$color = "0x" & $color

		case "b", "Autoit BGR Hex", "Autoit BGR", "BGR Hex", "bgr"
			$color = "0x" & StringRight($color, 2) & StringMid($color, 3, 2) & StringLeft($color, 2)

		case "d", "Delphi", "Delphi Hex"
			$color = "00" & StringRight($color, 2) & StringMid($color, 3, 2) & StringLeft($color, 2)
			$pre = "$"

		case "v", "vc", "Visual C++ Hex", "Visual C++ BGR", "Visual C++", "Visual C++ BGR Hex", "C++"
			$color = "0x00" & StringRight($color, 2) & StringMid($color, 3, 2) & StringLeft($color, 2)

		case "RGB Float", "float", "f"
			local $r = Round((1 / 255) * Dec(StringLeft($color, 2)), 2)
			local $g = Round((1 / 255) * Dec(StringMid($color, 3, 2)), 2)
			local $b = Round((1 / 255) * Dec(StringRight($color, 2)), 2)
			$color = StringFormat("%#.2f", $r) & "," & StringFormat("%#.2f", $g) & "," & StringFormat("%#.2f", $b)

		case "h", "Hue/Sat/Lum", "HSL", "h/s/l"
			$color = RGBtoHSL($color, ",", 100)

		case "k", "cmyk", "c/m/y/k"
			if $prefix = 1 then
				$color = RGBtoCMYK($color, true)
			else
				$color = RGBtoCMYK($color)
			endif

		case "w", "Web Hex", "Web", "Hex"
			$pre = "#"
	endswitch

	if not $prefix or $prefix = 4 then $pre = ""
	if $lowercase = $on then $color = StringLower($color)
	return $pre & $color
endfunc




; Converts an RGB color to a CMYK string, normalized to percents on request.
; Used by the color picker reports.
;
Func RGBtoCMYK($rgb_color, $norm = 0)
	local $rc_r = ConvertColorValue($rgb_color, "i", 0, 1) / 255
	local $rc_g = ConvertColorValue($rgb_color, "i", 0, 2) / 255
	local $rc_b = ConvertColorValue($rgb_color, "i", 0, 3) / 255
	local $k = MinMin(1 - $rc_r, 1 - $rc_g, 1 - $rc_b)
	local $c = (1 - $rc_r - $k) / (1 - $k)
	local $m = (1 - $rc_g - $k) / (1 - $k)
	local $y = (1 - $rc_b - $k) / (1 - $k)

	if $norm then
		return Round($c * 100, 1) & "," & Round($m * 100, 1) & "," & Round($y * 100, 1) & "," & Round($k * 100, 1)
	else
		return Round($c, 3) & "," & Round($m, 3) & "," & Round($y, 3) & "," & Round($k, 3)
	endif
endfunc




; Converts an RGB color to HSL, optionally returning one channel scaled. Used by
; the color picker and reports.
;
func RGBtoHSL($rgb_color, $idx = "", $simple_array = false, $hsl_scale = 1)
	local $rh_r = ConvertColorValue($rgb_color, "i", 0, 1) / 255
	local $rh_g = ConvertColorValue($rgb_color, "i", 0, 2) / 255
	local $rh_b = ConvertColorValue($rgb_color, "i", 0, 3) / 255
	local $rh_min = MinMin($rh_r, $rh_g, $rh_b)
	local $rh_max = MaxMax($rh_r, $rh_g, $rh_b)
	local $rh_delta = $rh_max - $rh_min

	if $idx <> 1 then
		local $rh_lightness = ($rh_min + $rh_max) / 2
		if $idx = 3 then return Round($rh_lightness * $hsl_scale, 2)
		local $rh_saturation = 0

		if $rh_lightness > 0 and $rh_lightness < 1 then
			If $rh_lightness < 0.5 then
				$rh_saturation = $rh_delta / (2 * $rh_lightness)
			else
				$rh_saturation = $rh_delta / (2 - 2 * $rh_lightness)
			endif
		endif

		If $idx = 2 then return Round($rh_saturation * $hsl_scale, 2)
	endif

	local $rh_hue = 0

	if $rh_delta > 0 then
		if $rh_max = $rh_r and $rh_max <> $rh_g then
			$rh_hue += ($rh_g - $rh_b) / $rh_delta
		endif

		if $rh_max = $rh_g and $rh_max <> $rh_b then
			$rh_hue += 2 + ($rh_b - $rh_r) / $rh_delta
		endif

		if $rh_max = $rh_b and $rh_max <> $rh_r then
			$rh_hue += 4 + ($rh_r - $rh_g) / $rh_delta
		endif

		$rh_hue *= 60
	endif

	if $rh_hue < 0 then $rh_hue += 360
	if $idx = 1 then return Round($rh_hue)
	local $do_string = true

	if not $idx then
		$idx = ","
		$do_string = false
	endif

	local $hsl_arr[3]
	$hsl_arr[0] = Round($rh_hue)
	$hsl_arr[1] = Round($rh_saturation * $hsl_scale, 2)
	$hsl_arr[2] = Round($rh_lightness * $hsl_scale, 2)
	local $hsl = $hsl_arr[0] & $idx & $hsl_arr[1] & $idx & $hsl_arr[2]
	if $do_string then return $hsl
	if $simple_array then return $hsl_arr
	return StringSplit($hsl, $idx)
endfunc




; Send the $string after the Shift, Alt, Ctrl & Win (L or R) keys are released.
; Optionally, give a warning after 1 sec if any of those keys are still down.
; $flag is the same as for Send().
func SendWait($string, $flag=0, $warn="You don't need to hold the modifier keys down for so long!")

 ; debug("", @ScriptLineNumber, 7);debug
 ; debug("string(" & $string & "," & $flag  & "," & $warn & ")", @ScriptLineNumber, 7);debug

	$am_sending = true
	local $HKt = TimerInit()

	while _IsPressed($VK_SHIFT) or _IsPressed($VK_CONTROL) or _IsPressed($VK_MENU) or _IsPressed($VK_LWIN) or _IsPressed($VK_RWIN)
		if $warn <> "" and TimerDiff($HKt) > 1000 then
			debug("SendWait(HOLDING_KEYS_WARNING)", @ScriptLineNumber, 7);debug

			if IniRead($ini_path, $app_name, "holding_keys_warning", $OFF) = $OFF then
				MsgBox($MB_TOPMOST, "Note.", $warn) ; 0x00040000
				IniWrite($ini_path, $app_name, "holding_keys_warning", $ON)
			endif
		endif

		Sleep(50)
	wend

	Send($string, $flag)
	$am_sending = false
	return $string
endfunc




; Shrink a label or checkbox to its own text plus padding, so
; neighbouring columns never overlap. Never grows past the width given,
; and retains that on any failure.
;
func FitLabelWidth($control, $text, $max_width, $padding=4)
	local $handle = GUICtrlGetHandle($control)
	if not $handle then return $max_width
	local $dc = _WinAPI_GetDC($handle)
	if not $dc then return $max_width
	local $font = GUICtrlSendMsg($control, $WM_GETFONT, 0, 0)
	local $old_font = 0
	if $font then $old_font = _WinAPI_SelectObject($dc, $font)
	local $fitted = $max_width
	local $size = _WinAPI_GetTextExtentPoint32($dc, $text)
	if IsDllStruct($size) then
		$fitted = DllStructGetData($size, "X")+$padding
		if $fitted > $max_width then $fitted = $max_width
	endif
	if $old_font then _WinAPI_SelectObject($dc, $old_font)
	_WinAPI_ReleaseDC($handle, $dc)
	return $fitted
endfunc


; Measures a wrapped label so its caller can reserve enough vertical space.
; Takes a control ID, text, pixel width, minimum height and bottom padding.
; Reads the control's current font; returns the greater of minimum height and
; the Windows word-wrapped text height plus padding. Invalid controls, widths
; or failed measurements return minimum height. Does not resize the control
; or write settings. Dialog layout functions call this before positioning text.
func FitLabelHeight($control, $text, $width, $min_height=0, $padding=2)
	if $width < 1 then return $min_height
	local $handle = GUICtrlGetHandle($control)
	if not $handle then return $min_height
	local $dc = _WinAPI_GetDC($handle)
	if not $dc then return $min_height
	local $font = GUICtrlSendMsg($control, $WM_GETFONT, 0, 0)
	local $old_font = 0
	if $font then $old_font = _WinAPI_SelectObject($dc, $font)
	local $rect = DllStructCreate($tagRECT)
	DllStructSetData($rect, "Right", $width)
	local $height = $min_height
	if _WinAPI_DrawText($dc, $text, $rect, BitOr($DT_CALCRECT, $DT_WORDBREAK)) then
		local $measured = DllStructGetData($rect, "Bottom")+$padding
		if $measured > $height then $height = $measured
	endif
	if $old_font then _WinAPI_SelectObject($dc, $old_font)
	_WinAPI_ReleaseDC($handle, $dc)
	return $height
endfunc


; Fits a text input dialog to its wrapped prompt and one input/button row.
; Takes the window, prompt, OK, Cancel and input control IDs plus an optional
; minimum client height. Reads native text, fonts and geometry; writes no
; settings. Returns [client width, client height, minimum client width], or
; false for an invalid window. Caption and field metrics determine the row;
; explicit minimum height can reserve extra space above it. Called at creation
; and after resizing; vertical resizing fits back to the required height.
func LayoutFancyInputBox($dialog, $prompt, $ok, $cancel, $input, $minimum_height=0)
	local $client = WinGetClientSize($dialog), $outer = WinGetPos($dialog)
	if not IsArray($client) or not IsArray($outer) then return false
	local const $PROMPT_X = 10, $PROMPT_Y = 5, $PROMPT_GAP = 6, $BOTTOM_GAP = 8
	local const $ROW_MARGIN = 5, $FIELD_GAP = 5, $BUTTON_PADDING = 16, $FIELD_PADDING = 10, $VERTICAL_PADDING = 8
	local $ok_width = FitLabelWidth($ok, GUICtrlRead($ok), 32767, $BUTTON_PADDING)
	local $cancel_width = FitLabelWidth($cancel, GUICtrlRead($cancel), 32767, $BUTTON_PADDING)
	local $input_width = FitLabelWidth($input, "0000000000", 32767, $FIELD_PADDING)
	local $minimum_width = 2*($ROW_MARGIN+$FIELD_GAP)+$ok_width+$cancel_width+$input_width
	local $width = $client[0]
	if $width < $minimum_width then $width = $minimum_width
	local $label_height = FitLabelHeight($prompt, GUICtrlRead($prompt), $width-2*$PROMPT_X)
	local $row_height = FitLabelHeight($input, "Ag", $input_width, 0, $VERTICAL_PADDING)
	local $ok_height = FitLabelHeight($ok, GUICtrlRead($ok), $ok_width, 0, $VERTICAL_PADDING)
	local $cancel_height = FitLabelHeight($cancel, GUICtrlRead($cancel), $cancel_width, 0, $VERTICAL_PADDING)
	if $ok_height > $row_height then $row_height = $ok_height
	if $cancel_height > $row_height then $row_height = $cancel_height
	local $height = $PROMPT_Y+$label_height+$PROMPT_GAP+$row_height+$BOTTOM_GAP
	if $height < $minimum_height then $height = $minimum_height
	if $width <> $client[0] or $height <> $client[1] then _
		WinMove($dialog, "", default, default, $width+$outer[2]-$client[0], $height+$outer[3]-$client[1])
	local $row_y = $height-$BOTTOM_GAP-$row_height
	local $input_x = $ROW_MARGIN+$cancel_width+$FIELD_GAP
	local $ok_x = $width-$ROW_MARGIN-$ok_width
	GUICtrlSetPos($prompt, $PROMPT_X, $PROMPT_Y, $width-2*$PROMPT_X, $label_height)
	GUICtrlSetPos($cancel, $ROW_MARGIN, $row_y, $cancel_width, $row_height)
	GUICtrlSetPos($input, $input_x, $row_y, $ok_x-$FIELD_GAP-$input_x, $row_height)
	GUICtrlSetPos($ok, $ok_x, $row_y, $ok_width, $row_height)
	local $result[3] = [$width, $height, $minimum_width]
	return $result
endfunc


; Fancy Custom Input Box.	(accepts drag-and-drop of files)

;	returns:

;	Success:	The value input by the user.
;				@Error contains the X coordinate of the window when closed
;				@extended contains the X coordinate of the window when closed
;
;				If you leave the width at the default (-1), CorzFancyInputBox will
;				save and restore its own width settings. Or else specify your own.
;
;	Failure:	Empty "" value.
;				@Error contains a non-0 value.
;
;				1 = The Cancel/Close button was pushed.
;				2 = The Timeout time was reached.
;
; As well as being a drop-in replacement for InputBox, you can optionally supply
; the full path to an ini file and section name to have CorzFancyInputBox save
; the x/y/width specifications for the inputbox, recall them the next time the
; user accesses the same inputbox.
;
; If you are using the defaults ($ini_path/$app_name), you can leave out the ini prefs.
;
;
; NOTE: CorzFancyInputBox() uses the title to create a preference name. If you
; send 100 separate titles for say, 100 buttons, you will create 100 preferences (x3!)
;
; In other words, best to put any control-specific text into the *prompt*.
;
; Reads dialog_font for prompt/buttons and inputbox_font for the input
; from the selected INI path and section, using ReadFontPrefs().
; Default height fits the wrapped prompt and input/button row; an explicit
; height reserves at least that much client space. Width changes reflow text.
;
func CorzFancyInputBox($title, $prompt, $default_text="", $pass=default, $ib_w=default, $ib_h=default, $ib_x=default, $ib_y=default, _
			$timeout=default, $gui_ex=false, $style=default, $inipath=default, $sectionname=default, $sel1=default, $sel2=default, $demo=false)

	debug("CorzFancyInputBox(title: " & $title & ", prompt: " & $prompt  & ", default_text: " & $default_text & _
			", pass: " & $pass  & ", ib_w: " & $ib_w  & ", ib_h: " & $ib_h  & ", ib_x: " & $ib_x  & ", ib_y: " & $ib_y  & _
			", timeout: " & $timeout  & ", gui_ex: " & $gui_ex  & ", style: " & $style  & ", inipath: " & $inipath  & _
			", sectionname: " & $sectionname  & ", sel1: " & $sel1   & ", sel2: " & $sel2 & ")..", @ScriptLineNumber, 7);debug

	local $previous_event_mode = AutoItSetOption("GUIOnEventMode", 0)
	local $previous_coord_mode = AutoItSetOption("GUICoordMode", 1)

	local $pref_name = CleanPrefName($title)

	if not $inipath or $inipath = default then $inipath = $ini_path
	if not $sectionname or $sectionname = default then $sectionname = $app_name
	if not $style or $style = default then $style = -1
	if not $pass or $pass = default then $pass = ""

	if $ib_x = Default then $ib_x = -1
	if $ib_y = default then $ib_y = -1
	local $minimum_height = 0
	if $ib_h <> default and Number($ib_h) > 0 then $minimum_height = Number($ib_h)
	if $ib_h = default then $ib_h = 96
	if $ib_w = default then $ib_w = $DEF_INPUTBOX_WIDTH

	if not $demo then
		$ib_x = WindowPositionCoord(IniRead($inipath, $sectionname, "inputbox_" & $pref_name & "_x", $ib_x), "x")
		$ib_y = WindowPositionCoord(IniRead($inipath, $sectionname, "inputbox_" & $pref_name & "_y", $ib_y), "y")
		$ib_w = IniRead($inipath, $sectionname, "inputbox_" & $pref_name & "_width", $ib_w)
	endif

	if not $ib_x then $ib_x = -1
	if not $ib_y then $ib_y = -1
	if not $ib_h then $ib_h = 96
	if not $ib_w then $ib_w = $DEF_INPUTBOX_WIDTH

	debug("$ib_x: " & $ib_x, @ScriptLineNumber, 8);debug
	debug("$ib_y: " & $ib_y, @ScriptLineNumber, 8);debug
	debug("$ib_h: " & $ib_h, @ScriptLineNumber, 8);debug
	debug("$ib_w: " & $ib_w, @ScriptLineNumber, 8);debug

	if $timeout = default then $timeout = 0
	if $sel1 = default then $sel1 = 0
	if $sel2 = default then $sel2 = -1

	local $return = false
	local $error = 0
	local $inputstyle = $ES_AUTOHSCROLL
	local $exStyle = BitOr($WS_EX_ACCEPTFILES, $WS_EX_TOPMOST)

	if $style = -1 then $style = BitOr($WS_MINIMIZEBOX, $WS_CAPTION, $WS_POPUP, $WS_SYSMENU, $WS_SIZEBOX)
	if $pass <> 0 then $inputstyle = BitOr($ES_AUTOHSCROLL, $ES_PASSWORD)

	local $face = ReadFontPrefs("dialog_font", $DIALOG_FONT_DEFAULT, $inipath, $sectionname)
	local $face_control_h = 22, $ok_w = 40, $cancel_w = 60, $label_h = 1, $buttons_y = 5
	; Make the dialog.
	local $ib_GUI = GUICreate($title, $ib_w, $ib_h, $ib_x, $ib_y, $style, $exStyle, $gui_ex)
	GUISetFont($face[1], $face[2], $face[3], $face[0], $ib_GUI)
	local $lab_prompt = GUICtrlCreateLabel($prompt, 10, 5, $ib_w-20, $label_h)

	local $but_OK = GUICtrlCreateButton("OK", $ib_w-5-$ok_w, $buttons_y, $ok_w, $face_control_h, $BS_DEFPUSHBUTTON)
	GUICtrlSetState(-1, $GUI_ONTOP)
	GUICtrlSetTip(-1,	"Save the setting." & $MSG_LF & _
						"When you click this button (and the input is not empty)," & $MSG_LF & _
						"the size and position of this dialog will be saved for future use.")

	local $but_Cancel = GUICtrlCreateButton("Cancel", 5, $buttons_y, $cancel_w, $face_control_h)
	GUICtrlSetState(-1, $GUI_ONTOP)
	GUICtrlSetTip(-1,	"Cancel this dialog." & $MSG_LF & _
						"Do not save the input."  & $MSG_LF & _
						"Do not save dialog's size and position.")

	local $input_face = ReadFontPrefs("inputbox_font", $INPUTBOX_FONT_DEFAULT, $inipath, $sectionname)
	local $inp_MyID = GUICtrlCreateInput($default_text, $cancel_w+10, $buttons_y, $ib_w-$ok_w-$cancel_w-25, $face_control_h, $inputstyle)
	GUICtrlSetState(-1, $GUI_FOCUS)
	GUICtrlSetFont(-1, $input_face[1], $input_face[2], $input_face[3], $input_face[0])
	GUICtrlSetState(-1, $GUI_DROPACCEPTED)
	GUICtrlSetTip(-1, $prompt)

	GUICtrlSetResizing($lab_prompt, BitOr($GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKHEIGHT))
	GUICtrlSetResizing($but_OK, $GUI_DOCKSTATEBAR+$GUI_DOCKWIDTH+$GUI_DOCKRIGHT)
	GUICtrlSetResizing($but_Cancel, $GUI_DOCKSTATEBAR+$GUI_DOCKLEFT+$GUI_DOCKWIDTH)
	GUICtrlSetResizing($inp_MyID, $GUI_DOCKSTATEBAR+$GUI_DOCKLEFT+$GUI_DOCKRIGHT)

	LayoutFancyInputBox($ib_GUI, $lab_prompt, $but_OK, $but_Cancel, $inp_MyID, $minimum_height)
	GUISetState(@SW_SHOW, $ib_GUI)
	PadDialogInputs($ib_GUI)
	_GUICtrlEdit_SetSel($inp_MyID, $sel1, $sel2)

	if $timeout <> 0 then local $dialog_begin = TimerInit()
	local $size_array

	while true
		switch GUIGetMsg()
			case $GUI_EVENT_RESIZED
				LayoutFancyInputBox($ib_GUI, $lab_prompt, $but_OK, $but_Cancel, $inp_MyID, $minimum_height)

			case $GUI_EVENT_CLOSE, $but_Cancel
				$return = false
				$error = 1
				exitloop

			case $but_OK
				$return = StringStripWS(GUICtrlRead($inp_MyID), $STR_STRIP_ENDS)
				exitloop
		endswitch

		if $timeout <> 0 then
			if TimerDiff($dialog_begin)/1000 > $timeout then
				$return = false
				$error = 2
				exitloop
			endif
		endif
	wend

	; The spot is remembered however the dialog closes.
	local $x_coord = -1, $y_coord = -1, $ib_width = 0
	$size_array = WinGetPos($title)	; 0-1:x-y
	if IsArray($size_array) then
		$x_coord = $size_array[0]
		$y_coord = $size_array[1]
	endif
	local $ib_client = WinGetClientSize($ib_GUI)
	if IsArray($ib_client) then $ib_width = $ib_client[0]

	AutoItSetOption("GUIOnEventMode", $previous_event_mode)
	AutoItSetOption("GUICoordMode", $previous_coord_mode)
	GUIDelete($ib_GUI)

	if not $demo then
		; Only write prefs if the user actually changed the position/dimensions from the defaults.
		if $x_coord and $x_coord <> -1 then IniWrite($inipath, $sectionname, "inputbox_" & $pref_name & "_x", WindowPositionCoord($x_coord, "x", true, $size_array))
		if $y_coord and $y_coord <> -1 then IniWrite($inipath, $sectionname, "inputbox_" & $pref_name & "_y", WindowPositionCoord($y_coord, "y", true, $size_array))

		if $ib_width and $ib_width <> @DesktopWidth/2 then
			IniWrite($inipath, $sectionname, "inputbox_" & $pref_name & "_width", $ib_width)
		endif
	endif

	if $return then
		return $return
	endif

	return SetError($error, 0, "")
endfunc




#cs
	CorzFancyMsgBox()

	A replacement for MsgBox, except with a checkbox for the user to never be
	asked about the issue again. It's basic, but does the job.

	Returns the number of the button the user clicked (1, 2, 3 or 4).

	You can set the usual $hwnd and styles (defaults should be fine).

	It will resize its height to fit the text sent (ish).

	You can have from one to four buttons, sending the text required for each
	button, or blank to produce no button. Obviously, if you want only two
	buttons, you set the value of the first two and leave the last two blank.

	If you set, for example, the value of the first and last buttons, leaving 2
	and 3 blank, you will get four buttons, two of which will be blank!

	You can also set which is the default button (1, 2, 3 or 4).

	CorzFancyMsgBox() will store the X & Y position of the dialog for future
	instances. Each dialog gets its own settings (the pref name being derived
	from the title of the message box).

	You can supply an ini path and section name to store the prefs, otherwise
	CorzFancyMsgBox() will use the app default ini and main app [name] section.

	If the user checks the "Always perform the chosen action" box, the user's
	choice is saved to the ini file and in future CorzFancyMsgBox() will simply
	return the pre-saved value.

	You can also set an icon (full path, unless it's in your PATH) and icon
	index (note: most icons inside shell32.dll use -negative IDs).

	Handy shell32.dll icons.

		ID			Icon
		-----		-------------
		24			question mark
		-211		question mark 3D
		-28/28		stop 	(appliance)
		-220		stop	(no entry)
		-237		warning triangle
		-278		information (i)	old 2D				(default icon)
		-317		cog	(completely square, no transparency required!)
		-239		Recycle

	CorzFancyMsgBox() returns:

		The number of the button the user clicked (1, 2, 3 or 4).

		If the user clicked a button, @Error and @extended are set to the final
		X and Y positions of the dialog, respectively. FYI.

		If the user cancels out of the dialog, @Error will be set to 1 and the
		function will return 0 as the value.

	Examples:

	CorzFancyMsgBox("This is a notice", "You never have to see this notice again")

	$debug = CorzFancyMsgBox("Really Overwrite Files?", "Many triggers and tasks have been found to already exist in KeyBind.ini. Overwrite?" , 60, false, -1, $ini_path, "Test", "Yes", "No", "", "", 2, "shell32.dll", -237)
	debug("$debug: =>" & $debug & "<=", @ScriptLineNumber, 7);debug

#ce

; Shows a rich message box with up to four buttons, timeout, icons and a
; don't-bug-me pref. Used for confirmations that can be permanently dismissed.
; Pass a ReadFontPrefs("dialog_font", $DIALOG_FONT_DEFAULT) [name, size, weight, attribute] array as $font
; to restyle the text; default keeps Segoe UI.
;
func CorzFancyMsgBox($title, $text, $timeout=0, $gui_ex=false, $style=-1, $inipath=$ini_path, _
					$sectionname=$app_name, $butt1_txt="OK", $butt2_txt="", $butt3_txt="", $butt4_txt="", _
					$default_butt=1, $icon_path="shell32.dll", $icon_id=-278, $font=default)

 debug("", @ScriptLineNumber, 7);debug
 debug("CorzFancyMsgBox(" & $title & "," & $text  & "," & $gui_ex & "," & $style  & "," & $inipath & "," & $sectionname  & "," & $butt1_txt & "," & $butt2_txt  & "," & $butt3_txt & "," & $butt4_txt  & "," & $default_butt & "," & $icon_path  & "," & $icon_id & ")", @ScriptLineNumber, 7);debug

	local $pref_name = CleanPrefName($title)

	; There may be a predetermined response.
	local $dont_bug_me = IniRead($inipath, $sectionname, $pref_name & "_dont_bug_me", 0)
	debug("$dont_bug_me: =>" & $dont_bug_me & "<=", @ScriptLineNumber, 7);debug
	if $dont_bug_me <> 0 then return $dont_bug_me	; the number of the saved response

	if $timeout		= default then $timeout		= 0
	if $gui_ex		= default then $gui_ex		= false
	if $style		= default then $style		= -1
	if $inipath		= default then $inipath		= $ini_path
	if $butt1_txt	= default then $butt1_txt	= "OK"
	if not $butt1_txt then $butt1_txt = "OK"
	if $sectionname	= default then $sectionname	= $app_name

	local $dt_pushed
	local $dt_warn_count = 0

	local $error, $extended
	local $last_event_mode = AutoItSetOption("GUIOnEventMode", 0)
	local $last_coord_mode = AutoItSetOption("GUICoordMode", 0) ; relative to last control

	; work out some sizes and positions.
	if $style = -1 then $style = BitOr($WS_CAPTION, $WS_SYSMENU, $WS_SIZEBOX)
	local $exStyle = BitOr($WS_EX_TOPMOST, $GUI_WS_EX_PARENTDRAG)

	local $dt_min_w = 400
	local $dt_min_h = 153
	local $dt_w
	local $dt_h = $dt_min_h

	; Not very clever. Works well within our limited range.	(under 1000 characters)
	local $text_len = StringLen($text)
	debug("$text_len: =>" & $text_len & "<=", @ScriptLineNumber, 7);debug

	local $size_array
	local $addin_height = 0

	while $addin_height < $text_len
		$dt_h += 22		; add these pixels to the GUI height
		$addin_height += 50 ; for every extra this many characters text length (slightly magic!)
		$dt_min_h += 22
	wend

	local $butt_width
	local $dt_x = WindowPositionCoord(IniRead($inipath, $sectionname, "msgbox_" & $pref_name & "_x", -1), "x")
	local $dt_y = WindowPositionCoord(IniRead($inipath, $sectionname, "msgbox_" & $pref_name & "_y", -1), "y")
	$dt_w = IniRead($inipath, $sectionname, "msgbox_" & $pref_name & "_width", $dt_min_w)

	; create the GUI.
	;

	local $dt_GUI = GUICreate($title, $dt_w, $dt_h, $dt_x, $dt_y, $style, $exStyle, $gui_ex)
	local $face_name = "Segoe UI", $face_weight = 400, $face_attribute = 0
	if IsArray($font) then
		if UBound($font) >= 3 then
			$face_name = $font[0]
			$face_weight = $font[2]
		endif
		if UBound($font) >= 4 then $face_attribute = $font[3]
	endif
	GUISetFont(-1, 10, $face_weight, $face_attribute, $face_name, 5)
	GUISetBkColor(0xFFFFFF)

	; icon_path
	local $icon_width = 0
	if $icon_path then $icon_width = 36

	local $gap = 7

	; the "text" label. It ends where the checkbox begins, so the two
	; can never overlap and fight over painting.
	;
	GUISetCoord(15+$icon_width, 6)
	GUICtrlCreatelabel($text, 0, 0, $dt_w-30-$icon_width, $dt_h-72, _
							BitOr($SS_NOTIFY, $SS_LEFT), $GUI_WS_EX_PARENTDRAG)
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	; GUICtrlSetBkColor(-1, 0xFF0000)
	GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)
	GUICtrlSetFont(-1, 10, $face_weight, $face_attribute, $face_name, 5)
	GUICtrlSetTip(-1, " You can click and drag the entire window around quickly from here ")

	; icon		"shell32.dll"
	;
	if $icon_path then
		GUISetCoord(10, 10)
		GUICtrlCreateIcon("", "", 0, -2, 32, 32, $SS_ICON, $WS_EX_TRANSPARENT)
		GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
		GUICtrlSetTip(-1, " this is an image ")
		GUICtrlSetState(-1,$GUI_DISABLE)
		GUICtrlSetImage(-1, $icon_path, $icon_id)
		GUICtrlSetResizing(-1, $GUI_DOCKSIZE+$GUI_DOCKLEFT+$GUI_DOCKTOP)
	endif

	; The Stripe
	; (F0F0F0).
	;
	GUISetCoord(50,$dt_h-43)
	; $label_stripe = GUICtrlCreatelabel("", 0, 0, $dt_w, $dt_h, 0, $GUI_WS_EX_PARENTDRAG)
	GUICtrlCreatelabel(" ", 0, 0, $dt_w-100, 2, 0, $GUI_WS_EX_PARENTDRAG)
	GUICtrlSetBkColor(-1, 0xF0F0F0)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKHEIGHT)

	; Make The Buttons.
	;
	local $buttons = 1
	if $butt2_txt then $buttons = 2
	if $butt3_txt then $buttons = 3
	if $butt4_txt then $buttons = 4
	local $buttons_array[$buttons+1][2] = [[$buttons]]
	local $buttonstyle = BitOr($BS_CENTER, $BS_FLAT, $BS_VCENTER, $BS_NOTIFY, $WS_TABSTOP)
	local $total_width = 0
	local $button_top = $dt_h-33
	local $i = 1 ; [0] => Button ID, [1] => text of button

	while $i <= $buttons
		$buttons_array[$i][1] = Eval("butt" & $i & "_txt") ; screw the manual! It works!
		$i += 1
	wend

	; create buttons, as required.
	for $i = $buttons_array[0][0] to 1 step -1
		$butt_width = (StringLen($buttons_array[$i][1])*8)+20
		GUISetCoord($dt_w-$total_width-$butt_width-$gap, $button_top)
		$buttons_array[$i][0] = GUICtrlCreateButton($buttons_array[$i][1], 0, 0, $butt_width, 25, $buttonstyle)
		GUICtrlSetFont(-1, 9, $face_weight, $face_attribute, $face_name, 5)
		GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM+$GUI_DOCKSIZE+$GUI_DOCKRIGHT)
		$total_width += $butt_width+$gap
		if $i = $default_butt then ControlFocus($dt_GUI, "", $buttons_array[$i][0])
	next

	; Another Dragable Area.
	;
	GUISetCoord(0,$button_top-8)
	GUICtrlCreateLabel("", 0, 0, $dt_w-$total_width-2, 50, 0, $GUI_WS_EX_PARENTDRAG)
	GUICtrlSetTip(-1, " Yes, you can click and drag the entire window around quickly from here, too ")
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM+$GUI_DOCKSIZE+$GUI_DOCKLEFT+$GUI_DOCKRIGHT)

	; CheckBox last so no sibling can cover it. Left-aligned with the
	; leftmost button. Don't bug me again about this!!
	;
	local $check_x = $dt_w-$total_width
	if $check_x > $dt_w-220-$gap then $check_x = $dt_w-220-$gap
	GUISetCoord($check_x, $dt_h-66)
	local $check_dont_bug = GUICtrlCreateCheckbox("Always perform the chosen action.", 0, 0, 220, default, _
		Bitor($WS_TABSTOP, $BS_AUTOCHECKBOX), $WS_EX_TOPMOST)
	GUICtrlSetFont(-1, 8.5, $face_weight, $face_attribute, $face_name, 5)
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM+$GUI_DOCKSIZE+$GUI_DOCKRIGHT)
	_WinAPI_SetWindowPos(GUICtrlGetHandle($check_dont_bug), $HWND_TOP, 0, 0, 0, 0, BitOr($SWP_NOMOVE, $SWP_NOSIZE))

	; Show the dialog.
	;
	GUISetState(@SW_SHOW, $dt_GUI)
	WinMove($dt_GUI, "", default, default, $dt_w, $dt_h)

	local $msg

	while true
		$dt_pushed = 0

		$msg = GUIGetMsg()

		for $i = 1 to $buttons_array[0][0]
			if $msg = $buttons_array[$i][0] then
				$dt_pushed = $i
				exitloop
			endif
		next

		if $dt_pushed then
			exitloop
		else
			select
				case $msg = $GUI_EVENT_CLOSE
					exitloop

				case $msg = $GUI_EVENT_RESIZED
					$size_array = WinGetPos($dt_GUI)
					if not IsArray($size_array) then return false
					local $new_width = $size_array[2]
					local $new_height = $size_array[3]
					if $new_width < $dt_min_w then $new_width = $dt_min_w
					if $new_height < $dt_min_h then $new_height = $dt_min_h
					if $new_width <> $size_array[2] or $new_height <> $size_array[3] then _
						WinMove($dt_GUI, "", default, default, $new_width, $new_height)

				case $msg = $check_dont_bug
					if GUICtrlread($check_dont_bug) = $ON then
						$dt_warn_count += 1
						local $message = 	"From now on you will no longer be notified and " & $app_name & _
											" will just get on with doing whatever YOU CHOOSE NEXT.."
						if $dt_warn_count > 1 then $message = "You have been warned!"
						if $dt_warn_count > 3 then $message = "Oh! Just DECIDE will you!"
						MsgBox($MB_ICONWARNING+$MB_SYSTEMMODAL, "This is PERMANENT!!", $message)
					endif
			endselect
		endif

		Sleep(50)
	wend

	; User clicked a button (didn't cancel out)
	;
	if $dt_pushed = 0 then
		$error = 1	; user cancelled out
	else
		debug("CorzFancyMsgBox() User Clicked Button: " & $dt_pushed, @ScriptLineNumber, 7);debug
		debug("CorzFancyMsgBox() User Chooses Option: " & $buttons_array[$dt_pushed][1], @ScriptLineNumber, 7);debug

		; There may already be a response for this dialog.
		; Re-use $dont_bug_me.
		$dont_bug_me = GUICtrlRead($check_dont_bug)

		if $dont_bug_me = $ON then
			IniWrite($inipath, $sectionname, $pref_name & "_dont_bug_me", $dt_pushed)
		else
			; If you are never seeing this dialog again you don't need this lot.
			$size_array = WinGetPos($dt_GUI)	; 0-1:x-y

			if IsArray($size_array) then
				IniWrite($inipath, $sectionname, "msgbox_" & $pref_name & "_x", WindowPositionCoord($size_array[0], "x", true, $size_array))
				IniWrite($inipath, $sectionname, "msgbox_" & $pref_name & "_y", WindowPositionCoord($size_array[1], "y", true, $size_array))
				$error = $size_array[0]
				$extended = $size_array[1]
			endif
			local $dt_client = WinGetClientSize($dt_GUI)
			if IsArray($dt_client) then IniWrite($inipath, $sectionname, "msgbox_" & $pref_name & "_width", $dt_client[0])
		endif
	endif

	AutoItSetOption("GUIOnEventMode", $last_event_mode)
	AutoItSetOption("GUICoordMode", $last_coord_mode)
	GUIDelete($dt_GUI)

	return SetError($error, $extended, $dt_pushed)
endfunc





; Event-Mode version of above function.
; Pass a ReadFontPrefs("dialog_font", $DIALOG_FONT_DEFAULT) [name, size, weight, attribute] array as $font
; to restyle the text; default keeps Segoe UI.
;
func CorzFancyMsgBoxEM($title, $text, $timeout=0, $gui_ex=false, $style=-1, $inipath=$ini_path, _
					$sectionname=$app_name, $butt1_txt="OK", $butt2_txt="", $butt3_txt="", $butt4_txt="", _
					$default_butt=1, $icon_path="shell32.dll", $icon_id=-278, $font=default)

 debug("", @ScriptLineNumber, 7);debug
 debug("CorzFancyMsgBoxEM(" & $title & "," & $text  & "," & $gui_ex & "," & $style  & "," & $inipath & "," & $sectionname  & "," & $butt1_txt & "," & $butt2_txt  & "," & $butt3_txt & "," & $butt4_txt  & "," & $default_butt & "," & $icon_path  & "," & $icon_id & ")", @ScriptLineNumber, 7);debug

	local $pref_name = CleanPrefName($title)

	; There may be a predetermined response.
	local $dont_bug_me = IniRead($inipath, $sectionname, $pref_name & "_dont_bug_me", 0)
	debug("$dont_bug_me: =>" & $dont_bug_me & "<=", @ScriptLineNumber, 7);debug
	if $dont_bug_me <> 0 then return $dont_bug_me	; the number of the saved response

	if $timeout		= default then $timeout		= 0
	if $gui_ex		= default then $gui_ex		= false
	if $style		= default then $style		= -1
	if $inipath		= default then $inipath		= $ini_path
	if $butt1_txt	= default then $butt1_txt	= "OK"
	if not $butt1_txt then $butt1_txt = "OK"
	if $sectionname	= default then $sectionname	= $app_name

	global $dt_open = true
	global $dt_pushed = 0
	global $dt_warn_count = 0

	local $error, $extended
	local $last_event_mode = AutoItSetOption("GUIOnEventMode", 1)
	local $last_coord_mode = AutoItSetOption("GUICoordMode", 0) ; relative to last control

	; work out some sizes and positions.
	if $style = -1 then $style = BitOr($WS_CAPTION, $WS_SYSMENU, $WS_SIZEBOX)
	local $exStyle = BitOr($WS_EX_TOPMOST, $GUI_WS_EX_PARENTDRAG)

	global $dt_min_w = 400
	global $dt_min_h = 145
	local $dt_w
	local $dt_h = $dt_min_h

	; Not very clever. Works well within our limited range.	(under 1000 characters)
	local $text_len = StringLen($text)
	debug("$text_len: =>" & $text_len & "<=", @ScriptLineNumber, 7);debug

	local $addin_height = 0

	while $addin_height < $text_len
		$dt_h += 22		; add these pixels to the GUI height
		$addin_height += 50 ; for every extra this many characters text length (slightly magic!)
		$dt_min_h += 22
	wend

	local $butt_width
	local $dt_x = WindowPositionCoord(IniRead($inipath, $sectionname, "msgbox_" & $pref_name & "_x", -1), "x")
	local $dt_y = WindowPositionCoord(IniRead($inipath, $sectionname, "msgbox_" & $pref_name & "_y", -1), "y")
	$dt_w = IniRead($inipath, $sectionname, "msgbox_" & $pref_name & "_width", $dt_min_w)

	; create the GUI.
	;

	global $dt_GUI = GUICreate($title, $dt_w, $dt_h, $dt_x, $dt_y, $style, $exStyle, $gui_ex)
	local $face_name = "Segoe UI", $face_weight = 400, $face_attribute = 0
	if IsArray($font) then
		if UBound($font) >= 3 then
			$face_name = $font[0]
			$face_weight = $font[2]
		endif
		if UBound($font) >= 4 then $face_attribute = $font[3]
	endif
	GUISetFont(-1, 10, $face_weight, $face_attribute, $face_name, 5)
	GUISetBkColor(0xFFFFFF)

	GUISetOnEvent($GUI_EVENT_CLOSE, "cfmbCloseDialog", $dt_GUI)
	GUISetOnEvent($GUI_EVENT_RESIZED, "cfmbResize", $dt_GUI)

	; icon_path
	local $icon_width = 0
	if $icon_path then $icon_width = 36

	; the "text" label.
	;
	GUISetCoord(15+$icon_width, 6)
	GUICtrlCreatelabel($text, 0, 0, $dt_w-30-$icon_width, $dt_h-53, _
							BitOr($SS_NOTIFY, $SS_LEFT), $GUI_WS_EX_PARENTDRAG)
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	; GUICtrlSetBkColor(-1, 0xFF0000)
	GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)
	GUICtrlSetFont(-1, 10, $face_weight, $face_attribute, $face_name, 5)
	GUICtrlSetTip(-1, " You can click and drag the entire window around quickly from here ")

	; icon		"shell32.dll"
	;
	if $icon_path then
		GUISetCoord(10, 10)
		GUICtrlCreateIcon("", "", 0, -2, 32, 32, $SS_ICON, $WS_EX_TRANSPARENT)
		GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
		GUICtrlSetTip(-1, " this is an image ")
		GUICtrlSetState(-1,$GUI_DISABLE)
		GUICtrlSetImage(-1, $icon_path, $icon_id)
		GUICtrlSetResizing(-1, $GUI_DOCKSIZE+$GUI_DOCKLEFT+$GUI_DOCKTOP)
	endif

	; The Stripe
	; (F0F0F0).
	;
	GUISetCoord(50,$dt_h-43)
	; $label_stripe = GUICtrlCreatelabel("", 0, 0, $dt_w, $dt_h, 0, $GUI_WS_EX_PARENTDRAG)
	GUICtrlCreatelabel(" ", 0, 0, $dt_w-100, 2, 0, $GUI_WS_EX_PARENTDRAG)
	GUICtrlSetBkColor(-1, 0xF0F0F0)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKHEIGHT)

	; Make The Buttons.
	;
	local $buttons = 1
	if $butt2_txt then $buttons = 2
	if $butt3_txt then $buttons = 3
	if $butt4_txt then $buttons = 4
	global $buttons_array[$buttons+1][2] = [[$buttons]]
	local $buttonstyle = BitOr($BS_CENTER, $BS_FLAT, $BS_VCENTER, $BS_NOTIFY, $WS_TABSTOP)
	local $total_width = 0, $gap = 7
	local $button_top = $dt_h-33
	local $i = 1 ; [0] => Button ID, [1] => text of button

	while $i <= $buttons
		$buttons_array[$i][1] = Eval("butt" & $i & "_txt") ; screw the manual! It works!
		$i += 1
	wend

	; create buttons, as required.
	for $i = $buttons_array[0][0] to 1 step -1
		$butt_width = (StringLen($buttons_array[$i][1])*8)+20
		GUISetCoord($dt_w-$total_width-$butt_width-$gap, $button_top)
		$buttons_array[$i][0] = GUICtrlCreateButton($buttons_array[$i][1], 0, 0, $butt_width, 25, $buttonstyle)
		GUICtrlSetFont(-1, 9, $face_weight, $face_attribute, $face_name, 5)
		GUICtrlSetOnEvent(-1, "cfmbPushButton")
		GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM+$GUI_DOCKSIZE+$GUI_DOCKRIGHT)
		;GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
		$total_width += $butt_width+$gap
		if $i = $default_butt then ControlFocus($dt_GUI, "", $buttons_array[$i][0])
	next

	; Another Dragable Area.
	;
	GUISetCoord(0,$button_top-8)
	GUICtrlCreateLabel("", 0, 0, $dt_w-$total_width-2, 50, 0, $GUI_WS_EX_PARENTDRAG)
	GUICtrlSetTip(-1, " Yes, you can click and drag the entire window around quickly from here, too ")
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM+$GUI_DOCKSIZE+$GUI_DOCKLEFT+$GUI_DOCKRIGHT)

	; CheckBox last so no sibling can cover it. A checkbox toggles, it
	; never drags the window and never lets clicks through.
	;
	GUISetCoord(10, $dt_h-66)
	global $check_dont_bug = GUICtrlCreateCheckbox("Always perform the chosen action.", 0, 0, 220, default, _
		Bitor($WS_TABSTOP, $BS_AUTOCHECKBOX), $WS_EX_TOPMOST)
	GUICtrlSetFont(-1, 8.5, $face_weight, $face_attribute, $face_name, 5)
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM+$GUI_DOCKSIZE+$GUI_DOCKLEFT)
	GUICtrlSetOnEvent(-1, "cfmbWarnPermanent")
	_WinAPI_SetWindowPos(GUICtrlGetHandle($check_dont_bug), $HWND_TOP, 0, 0, 0, 0, BitOr($SWP_NOMOVE, $SWP_NOSIZE))

	; Show the dialog.
	;
	GUISetState(@SW_SHOW, $dt_GUI)
	WinMove($dt_GUI, "", default, default, $dt_w, $dt_h)

	while $dt_open
		Sleep(25)
	wend

	; User clicked a button (didn't cancel out)
	;
	if $dt_pushed = 0 then
		$error = 1	; user cancelled out
	else
		debug("CorzFancyMsgBox() User Clicked Button:: " & $dt_pushed, @ScriptLineNumber, 7);debug
		debug("CorzFancyMsgBox() User Chooses Option:: " & $buttons_array[$dt_pushed][1], @ScriptLineNumber, 7);debug

		; There may already be a response for this dialog.
		; Re-use $dont_bug_me.
		$dont_bug_me = GUICtrlRead($check_dont_bug)

		if $dont_bug_me = $ON then
			IniWrite($inipath, $sectionname, $pref_name & "_dont_bug_me", $dt_pushed)
		else
			; If you are never seeing this dialog again you don't need this lot.
			local $size_array = WinGetPos($dt_GUI)	; 0-1:x-y

			if IsArray($size_array) then
				IniWrite($inipath, $sectionname, "msgbox_" & $pref_name & "_x", WindowPositionCoord($size_array[0], "x", true, $size_array))
				IniWrite($inipath, $sectionname, "msgbox_" & $pref_name & "_y", WindowPositionCoord($size_array[1], "y", true, $size_array))
				$error = $size_array[0]
				$extended = $size_array[1]
			endif
			local $dt_client = WinGetClientSize($dt_GUI)
			if IsArray($dt_client) then IniWrite($inipath, $sectionname, "msgbox_" & $pref_name & "_width", $dt_client[0])
		endif
	endif

	AutoItSetOption("GUIOnEventMode", $last_event_mode)
	AutoItSetOption("GUICoordMode", $last_coord_mode)
	GUIDelete($dt_GUI)

	return SetError($error, $extended, $dt_pushed)
endfunc


; Enforces the fancy message box minimum size while it is resized. Used as the
; resize handler for that dialog.
;
func cfmbResize()
	local $size_array = WinGetPos($dt_GUI)
	if not IsArray($size_array) then return false
	local $new_width = $size_array[2]
	local $new_height = $size_array[3]
	if $new_width < $dt_min_w then $new_width = $dt_min_w
	if $new_height < $dt_min_h then $new_height = $dt_min_h
	if $new_width <> $size_array[2] or $new_height <> $size_array[3] then _
		WinMove($dt_GUI, "", default, default, $new_width, $new_height)
endfunc


; Records which fancy message box button was pressed and closes the dialog. Used
; as the button handler for that dialog.
;
func cfmbPushButton()
 debug("", @ScriptLineNumber, 7);debug
 debug("cfmbPushButton(" & @GUI_CtrlId & ")", @ScriptLineNumber, 7);debug

	for $i = 1 to $buttons_array[0][0]
		if @GUI_CtrlId = $buttons_array[$i][0] then
			$dt_pushed = $i
			cfmbCloseDialog()
		endif
	next
endfunc


; Warns with growing impatience when don't-bug-me is ticked on the fancy box.
; Used to confirm permanent dismissal.
;
func cfmbWarnPermanent()
	if GUICtrlread($check_dont_bug) = $OFF then return
	$dt_warn_count += 1
	local $message = 	"From now on you will no longer be notified and " & $app_name & _
						" will just get on with doing whatever YOU CHOOSE NEXT.."
	if $dt_warn_count > 1 then $message = "You have been warned!"
	if $dt_warn_count > 3 then $message = "Oh! Just DECIDE will you!"
	MsgBox($MB_ICONWARNING+$MB_SYSTEMMODAL, "This is PERMANENT!!", $message)
endfunc


func cfmbCloseDialog()
	$dt_open = false
endfunc



; Translates saved window coordinates between pixels and screen expressions.
; Takes one X or Y value, its axis, a saving flag and an optional WinGetPos()
; array. Saving reads position_saving_method: absolute retains the value;
; desktop/workarea use the nearest horizontal or vertical edge. A centred
; coordinate uses /2. The array selects the source monitor; omitted context
; uses the active window's monitor. Does not clamp or move any coordinate.
; Reading evaluates screen expressions against the active window's monitor,
; independently of the current saving method. Other values, empty strings
; and numeric defaults are returned unchanged. An invalid screen expression
; returns -1 with @error 1. Reads no INI and writes no settings. Position
; readers and writers share this helper so saved expressions remain portable.
func WindowPositionCoord($value, $axis, $saving=false, $position=default)
	if $value == "" then return $value
	if $saving then
		if $position_saving_method <> "desktop" and $position_saving_method <> "workarea" then return $value
		if not StringRegExp($value, "^-?\d+$") then return $value
		if not IsArray($position) and $value = -1 then return $value
	elseif not StringInStr($value, "@Desktop") and not StringInStr($value, "@WorkArea") then
		return $value
	endif
	local $reference = $position
	if not IsArray($reference) then $reference = WinGetHandle("[ACTIVE]")
	local $edges[4] = ["Left", "Top", "Right", "Bottom"]
	if $saving then
		local $area = UserDialogWorkArea($reference, $position_saving_method = "desktop")
		local $index = ($axis = "y" ? 1 : 0)
		local $prefix = ($position_saving_method = "desktop" ? "@Desktop" : "@WorkArea")
		if 2*$value = $area[$index]+$area[$index+2] then
			return "(" & $prefix & $edges[$index] & "+" & $prefix & $edges[$index+2] & ")/2"
		endif
		if Abs($value-$area[$index]) > Abs($area[$index+2]-$value) then $index += 2
		local $distance = $value-$area[$index]
		return $prefix & $edges[$index] & ($distance < 0 ? "" : "+") & $distance
	endif
	local $expression = $value
	for $desktop = 0 to 1
		local $bounds = UserDialogWorkArea($reference, $desktop)
		local $token = ($desktop ? "@Desktop" : "@WorkArea")
		$expression = StringReplace($expression, $token & "Width", $bounds[2]-$bounds[0])
		$expression = StringReplace($expression, $token & "Height", $bounds[3]-$bounds[1])
		for $edge = 0 to 3
			$expression = StringReplace($expression, $token & $edges[$edge], $bounds[$edge])
		next
	next
	$expression = StringRegExpReplace($expression, "(?i)(?<=\d)px\b", "")
	local $result = Execute($expression)
	if @error then return SetError(1, 0, -1)
	return Int($result)
endfunc


; Recall a dialog's saved spot, keyed by its title exactly like
; UserDialog() does. Returns [x, y, w, h]; [-1, -1, -1, -1] for first
; show or a spot stranded outside the desktop (unplugged monitor,
; most likely). Callers wanting only position read [0] and [1].
;
func DialogRecallPos($title, $inipath=$ini_path, $section=$app_name)
	local $pref_name = CleanPrefName($title)
	local $pos[4] = [-1, -1, -1, -1]
	$pos[0] = WindowPositionCoord(IniRead($inipath, $section, "msgbox_" & $pref_name & "_x", -1), "x")
	$pos[1] = WindowPositionCoord(IniRead($inipath, $section, "msgbox_" & $pref_name & "_y", -1), "y")
	if $pos[0] = -1 and $pos[1] = -1 then return $pos
	local const $VISIBLE_MARGIN = $USER_DIALOG_VISIBLE_MARGIN
	local $desk_x = _WinAPI_GetSystemMetrics($SM_XVIRTUALSCREEN)
	local $desk_y = _WinAPI_GetSystemMetrics($SM_YVIRTUALSCREEN)
	local $desk_w = _WinAPI_GetSystemMetrics($SM_CXVIRTUALSCREEN)
	local $desk_h = _WinAPI_GetSystemMetrics($SM_CYVIRTUALSCREEN)
	if $pos[0] < $desk_x or $pos[1] < $desk_y or _
			$pos[0] > $desk_x+$desk_w-$VISIBLE_MARGIN or $pos[1] > $desk_y+$desk_h-$VISIBLE_MARGIN then
		$pos[0] = -1
		$pos[1] = -1
		$pos[2] = -1
		$pos[3] = -1
		return $pos
	endif
	$pos[2] = IniRead($inipath, $section, "msgbox_" & $pref_name & "_w", -1)
	$pos[3] = IniRead($inipath, $section, "msgbox_" & $pref_name & "_h", -1)
	return $pos
endfunc



; Save a dialog's spot under its title, for DialogRecallPos(). Needs the
; WinGetPos() array; anything else returns false and writes nothing.
; Position always saves; size saves when [2] and [3] are present.
;
func DialogSavePos($title, $pos, $inipath=$ini_path, $section=$app_name)
	if not IsArray($pos) then return false
	local $pref_name = CleanPrefName($title)
	IniWrite($inipath, $section, "msgbox_" & $pref_name & "_x", WindowPositionCoord($pos[0], "x", true, $pos))
	IniWrite($inipath, $section, "msgbox_" & $pref_name & "_y", WindowPositionCoord($pos[1], "y", true, $pos))
	if UBound($pos) > 3 then
		IniWrite($inipath, $section, "msgbox_" & $pref_name & "_w", $pos[2])
		IniWrite($inipath, $section, "msgbox_" & $pref_name & "_h", $pos[3])
	endif
	return true
endfunc



; Loads a font preference and validates optional partial changes.
; Reads font_type from inipath/section over fallback_font and system defaults.
; Returns [name, size, weight, attribute]. Missing, blank, invalid and "-"
; fields in saved/default specifications retain the previous field value.
; Optional changes uses the same checks but rejects invalid supplied fields:
; returns "" with @error 1 and @extended 0 for excess fields, or 1-4 for the
; invalid name/size/weight/attribute. Omitted changes and "-" fields retain the
; loaded values. Success sets @error 0 and @extended to the number of supplied,
; non-skipped fields; zero means all optional fields were skipped. Writes
; nothing. Existing four-argument callers load preferences; KeyBind() supplies
; partial changes.
func ReadFontPrefs($font_type, $fallback_font="", $inipath=$ini_path, $section=$app_name, $changes=default)
	local $font[4] = ["", 8.5, $FW_NORMAL, $GUI_FONTNORMAL]
	local $specs[3] = [$fallback_font, IniRead($inipath, $section, $font_type, ""), $changes]
	local $changed_fields = 0
	for $spec_index = 0 to UBound($specs)-1
		local $strict = $spec_index = UBound($specs)-1
		if $strict and IsKeyword($changes) then exitloop
		local $parts = StringSplit($specs[$spec_index], "|", $STR_ENTIRESPLIT)
		if $strict and $parts[0] > UBound($font) then return SetError(1, 0, "")
		for $field = 1 to UBound($font)
			if $field > $parts[0] then exitloop
			local $value = StringStripWS($parts[$field], $STR_STRIP_ENDS), $valid = false
			if $value = "-" then continueloop
			switch $field
				case 1
					$valid = $value <> "" and not StringRegExp($value, "[\x00-\x1F\x7F]")
				case 2
					$valid = StringRegExp($value, "^\d+(?:\.\d+)?$") and Number($value) >= $FONT_PREFS_MIN_SIZE and Number($value) <= $FONT_PREFS_MAX_SIZE
				case 3
					$valid = StringRegExp($value, "^\d+$") and Number($value) >= $FW_THIN and Number($value) <= $FW_HEAVY
				case 4
					$valid = StringRegExp($value, "^\d+$") and Number($value) <= $FONT_PREFS_ATTRIBUTES and BitAND(Number($value), $FONT_PREFS_ATTRIBUTES) = Number($value)
			endswitch
			if not $valid then
				if $strict then return SetError(1, $field, "")
				continueloop
			endif
			$font[$field-1] = $field = 1 ? $value : Number($value)
			if $strict then $changed_fields += 1
		next
	next
	return SetError(0, $changed_fields, $font)
endfunc


; One dialog to rule them all.
;
; $title string, window title and ini key base via CleanPrefName; renaming loses saved answers, position and width (height is always calculated, depending on contents).
; $text string with @LF breaks, literal \n also breaks and \\n prints as \n; empty is allowed but pointless; oversize text pins to the monitor work area.
; $buttons count array like StringSplit output; needs 1 or more labels; one row, last button absorbs rounding.
; $x horizontal centre for the sized dialog, -1 or default keeps auto-centre; a saved user spot always wins.
; $y vertical centre for the sized dialog, -1 or default keeps auto-centre; a fraction
; between 0 and 1 centres at that height of the work area, e.g. 0.25 sits a small
; warning a quarter down the screen; results outside the work area are pulled back in.
; $timeout number of seconds, 0 waits forever; on timeout returns "" with @error 1 and saves nothing.
; $modal boolean, true keeps the dialog topmost and blocks the parent window while open; with no parent it stays topmost and ignores other windows; false lets the user work behind it.
; $remember boolean, true shows the checkbox and auto-returns a saved choice without showing when one exists.
; $resizable boolean, true adds a size border with live resize; false fixes the size at the fitted design.
; $suspend string naming a caller func taking no args, run before the loop; must return true when it acted.
; $resume string naming a caller func taking no args, run after close only when $suspend acted; true means done.
; $resume_failed_msg string shown in a warning box when $resume reports false; empty string stays silent.
; $inipath string ini file containing saved answers, position and width; must be writable whenever recall is wanted.
; $section string ini section for the saved keys; a wrong section means answers and placement never recall.
; $lock_height boolean, true caps resizable height at the fitted size; false lets resizable height grow freely.
; $remember_width boolean, only with $resizable, true saves and restores outer width; never shrinks below the fit.
; $icon_path string icon file or dll, empty means no prompt icon; the title bar always uses the app icon.
; $icon_id number icon index in $icon_path, ignored when empty; negative ids address dll resources.
; $parent number window handle owning the dialog, 0 means no owner; modal input is blocked here while open; a dead handle strands the dialog.
; $default_button 1-based number taking keyboard focus, clamped into range; out of range falls back to button 1.
; $checkbox_text caption for the remember checkbox, one short line; blank keeps the standard text.
; Returns the 1-based button number, or "" closed with X or on timeout (@error 1 on timeout).
;
func UserDialog($title, $text, $buttons, $x=default, $y=default, $timeout=0, $modal=true, $remember=false, $resizable=false, _
				$suspend="", $resume="", $resume_failed_msg="", $inipath=$ini_path, $section=$app_name, _
				$lock_height=true, $remember_width=true, $icon_path="", $icon_id=0, $parent=0, $default_button=1, $checkbox_text="")

	local $event_mode = AutoItSetOption("GUIOnEventMode", 0)
	local $coord_mode = AutoItSetOption("GUICoordMode", 1)

	if not IsArray($buttons) or $buttons[0] < 1 then
		AutoItSetOption("GUIOnEventMode", $event_mode)
		AutoItSetOption("GUICoordMode", $coord_mode)
		return SetError(1, 0, "")
	endif

	local $count = $buttons[0]
	local $dialog_face = ReadFontPrefs("dialog_font", $DIALOG_FONT_DEFAULT)
	local $dialog_line_h = Int($dialog_face[1]*1.8)
	local $dialog_first_h = Int($dialog_face[1]*2.0)
	local $dialog_button_h = Int($dialog_face[1]*2.8)
	local $dialog_check_h = Int($dialog_face[1]*2.4)
	local $dialog_checkbox_h = Int($dialog_face[1]*1.8)
	local $pref_name = CleanPrefName($title)
	$text = NormaliseDialogText($text)

	if $remember then
		local $saved = IniRead($inipath, $section, $pref_name & "_dont_bug_me", 0)
		if $saved <> 0 then
			AutoItSetOption("GUIOnEventMode", $event_mode)
			AutoItSetOption("GUICoordMode", $coord_mode)
			return $saved
		endif
	endif

	local const $DIALOG_W = $USER_DIALOG_DESIGN_W
	local $BUTTON_H = $dialog_button_h
	local $split_lines = StringSplit($text, @LF, $STR_ENTIRESPLIT)
	local $label_h = UserDialogLabelHeight($split_lines[0], $dialog_first_h, $dialog_line_h)
	local $check_h = 0
	if $remember then $check_h = $dialog_check_h
	; A huge message must never push the buttons off-screen. Clip the
	; label to the desktop; overflow text simply does not paint.
	local $max_label_h = @DesktopHeight-($USER_DIALOG_TOP_MARGIN+$USER_DIALOG_MID_GAP+$check_h+$BUTTON_H+$USER_DIALOG_PADDING*2)-64
	if $max_label_h < $USER_DIALOG_LABEL_FIRST_H then $max_label_h = $USER_DIALOG_LABEL_FIRST_H
	if $label_h > $max_label_h then $label_h = $max_label_h
	local $win_w = $DIALOG_W
	; An icon steals text width; hand it back, so icon dialogs fit like plain ones.
	if $icon_path <> "" then $win_w += $USER_DIALOG_ICON_SIZE + $USER_DIALOG_ICON_GAP
	; The prompt keeps breathing room on the right; the window grows, never the wrap.
	$win_w += $USER_DIALOG_TEXT_RIGHT_PAD
	local $dialog_h = $USER_DIALOG_TOP_MARGIN+$label_h+$USER_DIALOG_MID_GAP+$check_h+$BUTTON_H+$USER_DIALOG_PADDING
	local $dlg_x = -1
	local $dlg_y = -1

	; Every dialog saves and restores its spot; a saved spot outside the
	; desktop (unplugged monitor maybe?) falls back to centered.
	local $recall_pos = DialogRecallPos($title, $inipath, $section)
	$dlg_x = $recall_pos[0]
	$dlg_y = $recall_pos[1]

	if $resizable and $remember_width then
		local $saved_w = IniRead($inipath, $section, "msgbox_" & $pref_name & "_width", $DIALOG_W)
		if $saved_w > $DIALOG_W then $win_w = $saved_w
	endif

	local $style = BitOr($WS_CAPTION, $WS_SYSMENU)
	if $resizable then $style = BitOr($style, $WS_SIZEBOX)
	local $ex_style = 0
	if $modal then $ex_style = $WS_EX_TOPMOST
	local $dialog = GUICreate($title, $win_w, $dialog_h, $dlg_x, $dlg_y, $style, $ex_style, $parent)
	$user_dialog_indent = $USER_DIALOG_PADDING+$USER_DIALOG_TEXT_NUDGE

	if $icon_path <> "" then
		GUICtrlCreateIcon($icon_path, $icon_id, $USER_DIALOG_PADDING, $USER_DIALOG_TOP_MARGIN-$USER_DIALOG_ICON_UP_NUDGE, $USER_DIALOG_ICON_SIZE, $USER_DIALOG_ICON_SIZE)
		GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
		$user_dialog_indent = $USER_DIALOG_PADDING+$USER_DIALOG_ICON_SIZE+$USER_DIALOG_ICON_GAP+$USER_DIALOG_TEXT_NUDGE
	endif

	local $create_cw = $win_w-($USER_DIALOG_PADDING*2)
	local $create_client = WinGetClientSize($dialog)
	if IsArray($create_client) then $create_cw = $create_client[0]
	local $button_w = UserDialogButtonWidth($create_cw, $count)
	local $prompt = GUICtrlCreateLabel($text, $user_dialog_indent, $USER_DIALOG_TOP_MARGIN, $win_w-$user_dialog_indent-$USER_DIALOG_PADDING-$USER_DIALOG_TEXT_RIGHT_PAD, $label_h)
	GUICtrlSetFont($prompt, $dialog_face[1], $dialog_face[2], $dialog_face[3], $dialog_face[0])
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKRIGHT))

	local $check_dont_bug = 0
	if $remember then
		if $checkbox_text = "" then $checkbox_text = "Always perform the chosen action."
		$check_dont_bug = GUICtrlCreateCheckbox($checkbox_text, $USER_DIALOG_PADDING+$USER_DIALOG_CHECKBOX_OFFSET, $USER_DIALOG_TOP_MARGIN+$label_h+$USER_DIALOG_MID_GAP, _
																													$win_w-($USER_DIALOG_PADDING*2), $dialog_checkbox_h)
		GUICtrlSetFont($check_dont_bug, $dialog_face[1], $dialog_face[2], $dialog_face[3], $dialog_face[0])
		GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKRIGHT))
	endif

	local $button_y = $dialog_h-$USER_DIALOG_PADDING-$BUTTON_H
	local $button_ids[$count+1]
	$button_ids[0] = $count

	for $i = 1 to $count
		local $button_x = UserDialogButtonX($i, $button_w)
		local $button_bw = $button_w
		if $i = $count then $button_bw = $create_cw-$USER_DIALOG_PADDING-$button_x
		$button_ids[$i] = GUICtrlCreateButton($buttons[$i], $button_x, $button_y, $button_bw, $BUTTON_H)
		GUICtrlSetFont(-1, $dialog_face[1], $dialog_face[2], $dialog_face[3], $dialog_face[0])
		GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))
	next

	; Fit the dialog to its text, so no line wraps onto clipped lines. Only ever grows.
	local $floor_client = $win_w
	local $fit_client_w = $win_w
	local $fit_pos = WinGetPos($dialog)
	local $fit_client = WinGetClientSize($dialog)

	if IsArray($fit_pos) and IsArray($fit_client) then

		local $fit = FitDialogText($prompt, $button_ids[1], $text, $buttons, $count, $user_dialog_indent, 0, $dialog)
		$fit_client_w = $fit[1]
		if $fit[1] > $floor_client then $floor_client = $fit[1]
		local $chrome_w = $fit_pos[2]-$fit_client[0]
		local $chrome_h = $fit_pos[3]-$fit_client[1]
		local $fit_w = $win_w
		if $fit[1]+$chrome_w > $fit_w then $fit_w = $fit[1]+$chrome_w

		; Height follows the final label width, so the dialog grows only
		; for lines that really wrap. No wrap, no grow.
		local $fit_height = FitDialogText($prompt, $button_ids[1], $text, $buttons, $count, $user_dialog_indent, $fit_w-$chrome_w, $dialog)
		local $fit_label_h = UserDialogLabelHeight($fit_height[2], $dialog_first_h, $dialog_line_h)
		if $fit_label_h < $label_h then $fit_label_h = $label_h
		if $fit_label_h > $max_label_h then $fit_label_h = $max_label_h
		local $fit_h = $USER_DIALOG_TOP_MARGIN+$fit_label_h+$USER_DIALOG_MID_GAP+$check_h+$BUTTON_H+$USER_DIALOG_PADDING
		if $fit_h < $dialog_h then $fit_h = $dialog_h

		; Oversize fits pin to the monitor work area and re-wrap inside it.
		local $work = UserDialogWorkArea($dialog)
		if IsArray($work) then
			local $max_outer_w = $work[2]-$work[0]
			local $max_outer_h = $work[3]-$work[1]
			if $fit_w > $max_outer_w then
				$fit_w = $max_outer_w
				$fit_height = FitDialogText($prompt, $button_ids[1], $text, $buttons, $count, $user_dialog_indent, $fit_w-$chrome_w, $dialog)
				$fit_label_h = UserDialogLabelHeight($fit_height[2], $dialog_first_h, $dialog_line_h)
				if $fit_label_h < $label_h then $fit_label_h = $label_h
				if $fit_label_h > $max_label_h then $fit_label_h = $max_label_h
				$fit_h = $USER_DIALOG_TOP_MARGIN+$fit_label_h+$USER_DIALOG_MID_GAP+$check_h+$BUTTON_H+$USER_DIALOG_PADDING
				if $fit_h < $dialog_h then $fit_h = $dialog_h
			endif
			if $fit_h+$chrome_h > $max_outer_h then $fit_h = $max_outer_h-$chrome_h
		endif

		if $fit_w <> $win_w or $fit_h <> $dialog_h then
			WinMove($dialog, "", $fit_pos[0], $fit_pos[1], $fit_w, $fit_h+$chrome_h)
			local $fit_cw = $fit_w-$chrome_w
			$button_w = UserDialogButtonWidth($fit_cw, $count)
			$button_y = $fit_h-$USER_DIALOG_PADDING-$BUTTON_H
			GUICtrlSetPos($prompt, $user_dialog_indent, $USER_DIALOG_TOP_MARGIN, $fit_cw-$user_dialog_indent-$USER_DIALOG_PADDING-$USER_DIALOG_TEXT_RIGHT_PAD, $fit_label_h)

			if $remember then
				GUICtrlSetPos($check_dont_bug, $USER_DIALOG_PADDING+$USER_DIALOG_CHECKBOX_OFFSET, _
					$USER_DIALOG_TOP_MARGIN+$fit_label_h+$USER_DIALOG_MID_GAP, $fit_cw-($USER_DIALOG_PADDING*2), $dialog_checkbox_h)
			endif

			for $i = 1 to $count
				local $fit_x = UserDialogButtonX($i, $button_w)
				local $fit_bw = $button_w
				if $i = $count then $fit_bw = $fit_cw-$USER_DIALOG_PADDING-$fit_x
				GUICtrlSetPos($button_ids[$i], $fit_x, $button_y, $fit_bw, $BUTTON_H)
			next

		endif

		$label_h = $fit_label_h
		$dialog_h = $fit_h
		$win_w = $fit_w

	endif

	; Requested centre, honoured only with no saved spot. Both -1 and default
	; mean auto-centre for that axis. The finished size is known here, and the
	; work area pulls back anything off-screen below.
	if $x = default then $x = -1
	if $y = default then $y = -1
	; A fractional $y centres the finished dialog at that height of its monitor's
	; work area. A saved spot still wins, exactly like a pixel centre.
	if $dlg_x = -1 and $dlg_y = -1 and IsFloat($y) and $y > 0 and $y < 1 then
		local $fraction_area = UserDialogWorkArea($dialog)
		if IsArray($fraction_area) then $y = $fraction_area[1]+($fraction_area[3]-$fraction_area[1])*$y
	endif
	if $dlg_x = -1 and $dlg_y = -1 and ($x <> -1 or $y <> -1) then
		local $spot = WinGetPos($dialog)
		if IsArray($spot) then
			local $spot_x = $spot[0]
			local $spot_y = $spot[1]
			if $x <> -1 then $spot_x = Int($x-$spot[2]/2)
			if $y <> -1 then $spot_y = Int($y-$spot[3]/2)
			WinMove($dialog, "", $spot_x, $spot_y)
		endif
	endif
	local $area = UserDialogWorkArea($dialog)
	if IsArray($area) then
		local $clamp = WinGetPos($dialog)
		if IsArray($clamp) then
			local $edge_x = $clamp[0]
			local $edge_y = $clamp[1]
			if $edge_x+$clamp[2] > $area[2] then $edge_x = $area[2]-$clamp[2]
			if $edge_y+$clamp[3] > $area[3] then $edge_y = $area[3]-$clamp[3]
			if $edge_x < $area[0] then $edge_x = $area[0]
			if $edge_y < $area[1] then $edge_y = $area[1]
			if $edge_x <> $clamp[0] or $edge_y <> $clamp[1] then WinMove($dialog, "", $edge_x, $edge_y)
		endif
	endif
	local $parent_disabled = false
	if $modal and IsHWnd($parent) then
		GUISetState(@SW_DISABLE, $parent)
		$parent_disabled = true
	endif

	GUISetState(@SW_SHOW, $dialog)
	local $app_hicon = SetDialogAppIcon($dialog)
	local $focus_button = $default_button
	if $focus_button < 1 or $focus_button > $count then $focus_button = 1
	ControlFocus($dialog, "", $button_ids[$focus_button])
	$user_dialog_prompt = $prompt
	$user_dialog_check = $check_dont_bug
	$user_dialog_remember = $remember
	$user_dialog_buttons = $button_ids

	if $resizable then
		local $outer = WinGetPos($dialog)
		local $client = WinGetClientSize($dialog)
		if IsArray($outer) and IsArray($client) then
			local $max_h = 0
			if $lock_height then $max_h = $dialog_h+($outer[3]-$client[1])
			RegisterMinMax($dialog, $fit_client_w+($outer[2]-$client[0]), $dialog_h+($outer[3]-$client[1]), $max_h)
			RegisterSized($dialog, "UserDialogSized")
		endif
	endif

	local $choice = ""
	local $error = 0
	local $timer = TimerInit()
	local $warn_count = 0
	local $suspended = false
	if $suspend <> "" then $suspended = Call($suspend)

	while 1
		if $timeout > 0 and TimerDiff($timer) >= $timeout*1000 then
			$error = 1
			exitloop
		endif
		local $gui_message = GUIGetMsg($GUI_EVENT_ARRAY)
		if not IsArray($gui_message) or $gui_message[1] <> $dialog then
			Sleep(5)
			continueloop
		endif
		local $msg = $gui_message[0]
		if $msg = $GUI_EVENT_CLOSE then exitloop
		if $remember and $msg = $check_dont_bug and GUICtrlRead($check_dont_bug) = $ON then
			$warn_count += 1
			local $warn_msg = "From now on you will no longer be notified" & $MSG_LF & _
					"and " & $app_name & " will just get on with doing" & $MSG_LF & _
					"whatever YOU CHOOSE NEXT.."
			if $warn_count > 1 then $warn_msg = "You have been warned!"
			if $warn_count > 3 then $warn_msg = "Oh! Just DECIDE will you!"
			local $warn_buttons[2] = [1, "OK"]
			local $saved_state = PushUserDialogState()
			UserDialog("This is PERMANENT!!", $warn_msg, $warn_buttons, default, default, 0, true, false, false, "", "", "", $ini_path, $app_name, true, false, "shell32.dll", -237, $dialog, 1)
			PopUserDialogState($saved_state)
		endif
		for $i = 1 to $count
			if $msg = $button_ids[$i] then
				$choice = $i
				exitloop 2
			endif
		next
		Sleep(5)
	wend

	UnregisterMinMax($dialog)
	UnregisterSized($dialog)

	if $parent_disabled then
		GUISetState(@SW_ENABLE, $parent)
		WinActivate($parent)
	endif

	if $suspended then
		local $resumed = true
		if $resume <> "" then $resumed = Call($resume)
		if not $resumed and $resume_failed_msg <> "" then MsgBox($MB_ICONWARNING+$MB_TOPMOST, $app_name, $resume_failed_msg)
	endif

	local $pos = WinGetPos($dialog)
	if IsArray($pos) then DialogSavePos($title, $pos, $inipath, $section)
	local $dialog_client = WinGetClientSize($dialog)
	if IsArray($dialog_client) and $choice <> "" and $resizable and $remember_width then _
			IniWrite($inipath, $section, "msgbox_" & $pref_name & "_width", $dialog_client[0])

	if $choice <> "" then
		if $remember and GUICtrlRead($check_dont_bug) = $ON then IniWrite($inipath, $section, $pref_name & "_dont_bug_me", $choice)
	endif

	GUIDelete($dialog)
	if $app_hicon then _WinAPI_DestroyIcon($app_hicon)
	AutoItSetOption("GUIOnEventMode", $event_mode)
	AutoItSetOption("GUICoordMode", $coord_mode)
	return SetError($error, 0, $choice)
endfunc



; Layout for /resizable/ UserDialog()
;
func UserDialogSized($hWnd, $msg, $wParam, $lParam)

	#forceref $msg, $lParam, $wParam

	if not MapExists($sized_handlers, String($hWnd)) then return $GUI_RUNDEFMSG
	local $count = $user_dialog_buttons[0]
	if $count < 1 then return $GUI_RUNDEFMSG
	if not MapExists($minmax_limits, String($hWnd)) then return $GUI_RUNDEFMSG
	local $client = WinGetClientSize($hWnd)
	local $outer = WinGetPos($hWnd)
	if not IsArray($client) or not IsArray($outer) or $client[0] < 1 or $client[1] < 1 then return $GUI_RUNDEFMSG

	local $dialog_face = ReadFontPrefs("dialog_font", $DIALOG_FONT_DEFAULT)
	local $BUTTON_H = Int($dialog_face[1]*2.8)
	local $dialog_check_h = Int($dialog_face[1]*2.4)
	local $dialog_checkbox_h = Int($dialog_face[1]*1.8)
	local $limits = $minmax_limits[String($hWnd)]
	local $min_client_w = $limits[0]-($outer[2]-$client[0])
	local $min_client_h = $limits[1]-($outer[3]-$client[1])
	local $use_w = $client[0]
	if $use_w < $min_client_w then $use_w = $min_client_w
	local $use_h = $client[1]
	if $use_h < $min_client_h then $use_h = $min_client_h
	local $button_y = $use_h-$USER_DIALOG_PADDING-$BUTTON_H
	local $top = $button_y
	if $user_dialog_remember then $top = $button_y-$dialog_check_h
	local $label_h = $top-$USER_DIALOG_TOP_MARGIN-$USER_DIALOG_LABEL_BOTTOM_GAP
	if $label_h < $USER_DIALOG_MIN_TRACK then $label_h = $USER_DIALOG_MIN_TRACK
	local $label_w = $use_w-$user_dialog_indent-$USER_DIALOG_PADDING
	if $label_w < $USER_DIALOG_MIN_TRACK then $label_w = $USER_DIALOG_MIN_TRACK
	local $button_w = UserDialogButtonWidth($use_w, $count)
	if $button_w < $USER_DIALOG_MIN_TRACK then $button_w = $USER_DIALOG_MIN_TRACK
	GUICtrlSetPos($user_dialog_prompt, $user_dialog_indent, $USER_DIALOG_TOP_MARGIN, $label_w, $label_h)
	if $user_dialog_remember then GUICtrlSetPos($user_dialog_check, $USER_DIALOG_PADDING+$USER_DIALOG_CHECKBOX_OFFSET, $button_y-$dialog_check_h, _
																								$use_w-($USER_DIALOG_PADDING*2), $dialog_checkbox_h)

	for $i = 1 to $count
		local $sized_x = UserDialogButtonX($i, $button_w)
		local $sized_bw = $button_w
		if $i = $count then $sized_bw = $use_w-$USER_DIALOG_PADDING-$sized_x
		GUICtrlSetPos($user_dialog_buttons[$i], $sized_x, $button_y, $sized_bw, $BUTTON_H)
	next
	return $GUI_RUNDEFMSG
endfunc


; Normalise dialog text to real line breaks. @CRLF and lone @CR become
; @LF first, then each literal backslash-n becomes @LF. A doubled
; backslash is sheltered through a placeholder so double-backslash-n
; prints as backslash-n instead of breaking. Returns the converted string.
;
func NormaliseDialogText($string)
	local const $SHELTER = ChrW(0xE000)
	$string = StringReplace($string, @CRLF, @LF)
	$string = StringReplace($string, @CR, @LF)
	$string = StringReplace($string, "\\", $SHELTER)
	$string = StringReplace($string, "\n", @LF)
	$string = StringReplace($string, $SHELTER, "\")
	return $string
endfunc


; Single row of equally spaced buttons along the bottom. Shared by the
; initial fit and the resize handler so both lay out identically.
;
func UserDialogButtonWidth($client_w, $count)
	if $count < 1 then return $USER_DIALOG_MIN_TRACK
	local $button_w = Int(($client_w-($USER_DIALOG_PADDING*2)-($USER_DIALOG_PADDING*($count-1)))/$count)
	if $button_w < $USER_DIALOG_MIN_TRACK then $button_w = $USER_DIALOG_MIN_TRACK
	return $button_w
endfunc


; Left edge of button $index for a shared button width.
;
func UserDialogButtonX($index, $button_w)
	return $USER_DIALOG_PADDING+($index-1)*($button_w+$USER_DIALOG_PADDING)
endfunc


; Prompt height for a row count. First row carries the top leading.
;
func UserDialogLabelHeight($rows, $first_h=$USER_DIALOG_LABEL_FIRST_H, $line_h=$USER_DIALOG_LABEL_LINE_H)
	if $rows < 1 then $rows = 1
	return $first_h+$line_h*($rows-1)
endfunc


; Save and restore the open dialog layout state around a nested UserDialog.
;
func PushUserDialogState()
	local $state[5] = [$user_dialog_indent, $user_dialog_prompt, $user_dialog_check, $user_dialog_remember, 0]
	$state[4] = $user_dialog_buttons
	return $state
endfunc


; Restores dialog indent, prompt, check, remember and button state from a saved
; array. Used after nested user dialogs close.
;
func PopUserDialogState($state)
	$user_dialog_indent = $state[0]
	$user_dialog_prompt = $state[1]
	$user_dialog_check = $state[2]
	$user_dialog_remember = $state[3]
	$user_dialog_buttons = $state[4]
endfunc


; Monitor bounds for a window handle or WinGetPos() array. Returns
; [left, top, right, bottom], using the work area unless desktop is true.
; Falls back to the virtual desktop when the monitor cannot be read.
;
func UserDialogWorkArea($dialog, $desktop=false)
	local $point = DllStructCreate("long X;long Y")
	if IsDllStruct($point) then
		local $pos = $dialog
		if not IsArray($pos) then $pos = WinGetPos($dialog)
		if IsArray($pos) then
			DllStructSetData($point, "X", $pos[0]+Int($pos[2]/2))
			DllStructSetData($point, "Y", $pos[1]+Int($pos[3]/2))
			local $monitor = _WinAPI_MonitorFromPoint($point)
			if $monitor then
				local $info = _WinAPI_GetMonitorInfo($monitor)
				if IsArray($info) then
					local $rectangle = $info[($desktop ? 0 : 1)]
					local $work[4] = [DllStructGetData($rectangle, "Left"), DllStructGetData($rectangle, "Top"), DllStructGetData($rectangle, "Right"), DllStructGetData($rectangle, "Bottom")]
					return $work
				endif
			endif
		endif
	endif
	local $fallback[4] = [_WinAPI_GetSystemMetrics($SM_XVIRTUALSCREEN), _WinAPI_GetSystemMetrics($SM_YVIRTUALSCREEN), 0, 0]
	$fallback[2] = $fallback[0]+_WinAPI_GetSystemMetrics($SM_CXVIRTUALSCREEN)
	$fallback[3] = $fallback[1]+_WinAPI_GetSystemMetrics($SM_CYVIRTUALSCREEN)
	return $fallback
endfunc


; Dialog scale factor from the window DPI, falling back to system DPI.
;
func UserDialogScale($dialog)
	local $dpi = DllCall("user32.dll", "uint", "GetDpiForWindow", "hwnd", $dialog)
	if not @error and IsArray($dpi) and $dpi[0] > 0 then return $dpi[0]/96
	$dpi = DllCall("user32.dll", "uint", "GetDpiForSystem")
	if not @error and IsArray($dpi) and $dpi[0] > 0 then return $dpi[0]/96
	return 1
endfunc


; Pin size limits for a window. max_h of 0 means no height cap.
func RegisterMinMax($hwnd, $min_w, $min_h, $max_h=0)
	if not $hwnd then return false
	GUIRegisterMsg($WM_GETMINMAXINFO, "MinMaxDispatch")
	local $limits[3] = [$min_w, $min_h, $max_h]
	$minmax_limits[String($hwnd)] = $limits
	return true
endfunc

func UnregisterMinMax($hwnd)
	if MapExists($minmax_limits, String($hwnd)) then MapRemove($minmax_limits, String($hwnd))
	return true
endfunc

; Pin a resize handler for a window. The handler takes ($hWnd, $msg, $wParam, $lParam).
func RegisterSized($hwnd, $funcname)
	if not $hwnd or not $funcname then return false
	GUIRegisterMsg($WM_SIZE, "SizedDispatch")
	$sized_handlers[String($hwnd)] = $funcname
	return true
endfunc

func UnregisterSized($hwnd)
	if MapExists($sized_handlers, String($hwnd)) then MapRemove($sized_handlers, String($hwnd))
	return true
endfunc

; Route window notifications to a per-control handler. The handler
; takes ($hWnd, $msg, $wParam, $lParam) and the sending control selects it.
func RegisterNotify($control_handle, $funcname)
	if not $control_handle or not $funcname then return false
	if not GUIRegisterMsg($WM_NOTIFY, "NotifyDispatch") then return false
	$notify_handlers[String(HWnd($control_handle))] = $funcname
	return true
endfunc

func UnregisterNotify($control_handle)
	if MapExists($notify_handlers, String(HWnd($control_handle))) then MapRemove($notify_handlers, String(HWnd($control_handle)))
	return true
endfunc

; Passes one notification to its control's handler. Used as the shared
; $WM_NOTIFY target; unknown senders run the default message instead.
;
func NotifyDispatch($hWnd, $msg, $wParam, $lParam)
	local $notify = DllStructCreate("hwnd", $lParam)
	if @error then return $GUI_RUNDEFMSG
	local $from = String(HWnd(DllStructGetData($notify, 1)))
	if not MapExists($notify_handlers, $from) then return $GUI_RUNDEFMSG
	return Call($notify_handlers[$from], $hWnd, $msg, $wParam, $lParam)
endfunc

; Enforces registered minimum and maximum track sizes for a window. Used as the
; min-max handler for resizable dialogs.
;
func MinMaxDispatch($hWnd, $msg, $wParam, $lParam)
	#forceref $msg, $wParam
	if not MapExists($minmax_limits, String($hWnd)) then return $GUI_RUNDEFMSG
	local $limits = $minmax_limits[String($hWnd)]
	local $info = DllStructCreate($MINMAXINFO_LAYOUT, $lParam)
	DllStructSetData($info, "MinTrackSizeX", $limits[0])
	DllStructSetData($info, "MinTrackSizeY", $limits[1])
	if $limits[2] then DllStructSetData($info, "MaxTrackSizeY", $limits[2])
	return 0
endfunc

func SizedDispatch($hWnd, $msg, $wParam, $lParam)
	if not MapExists($sized_handlers, String($hWnd)) then return $GUI_RUNDEFMSG
	return Call($sized_handlers[String($hWnd)], $hWnd, $msg, $wParam, $lParam)
endfunc


; Width from the buttons with their own font; height from wrapped lines.
; Single row of equally spaced buttons along the bottom; the width fits
; the widest button label. Word-aware wrapping counts how each explicit
; line folds into the final label width. Pass $wrap_w to wrap into a
; final width instead. Oversize fits are clamped by the caller.
; Never fails safe: any measurement trouble returns zero width and the
; explicit line count, leaving the design size in charge.
;
func FitDialogText($prompt, $button_ctrl, $text, $buttons, $count, $indent, $wrap_w=0, $dialog=0)

	local const $BUTTON_PAD = $USER_DIALOG_BUTTON_TEXT_PAD
	local $fit[3] = [2, 0, 1]
	local $lines = StringSplit($text, @LF, $STR_ENTIRESPLIT)
	if $lines[0] < 1 then return $fit
	$fit[2] = $lines[0]
	local $handle = GUICtrlGetHandle($prompt)
	if not $handle then return $fit

	local $dc = _WinAPI_GetDC($handle)
	if not $dc then return $fit

	local $scale = 1
	if $dialog then
		$scale = UserDialogScale($dialog)
	else
		local $dpi = DllCall("user32.dll", "uint", "GetDpiForSystem")
		if not @error and IsArray($dpi) and $dpi[0] > 0 then $scale = $dpi[0]/96
	endif

	local $prompt_font = GUICtrlSendMsg($prompt, $WM_GETFONT, 0, 0)
	local $old_font = 0
	if $prompt_font then $old_font = _WinAPI_SelectObject($dc, $prompt_font)
	local $space_w = UserDialogTextWidth($dc, " ", $scale)

	local $button_font = GUICtrlSendMsg($button_ctrl, $WM_GETFONT, 0, 0)
	if $button_font then _WinAPI_SelectObject($dc, $button_font)
	local $widest = 0

	for $i = 1 to $count
		local $btn_w = UserDialogTextWidth($dc, $buttons[$i], $scale)
		if $btn_w > $widest then $widest = $btn_w
	next

	if $prompt_font then _WinAPI_SelectObject($dc, $prompt_font)
	; Width comes from the buttons alone; every line wraps into it and
	; the height follows. Empty lines still count as lines.
	local $btn_share = $widest+$BUTTON_PAD
	local $need = $btn_share*$count+$USER_DIALOG_PADDING*($count-1)+($USER_DIALOG_PADDING*2)
	local $wrap_into = $need
	if $wrap_w > 0 then $wrap_into = $wrap_w
	local $avail = $wrap_into-$indent-$USER_DIALOG_PADDING-$USER_DIALOG_TEXT_RIGHT_PAD
	if $avail < $USER_DIALOG_MIN_TRACK then $avail = $USER_DIALOG_MIN_TRACK
	local $total = 0
	for $i = 1 to $lines[0]
		$total += UserDialogWrapRows($dc, $lines[$i], $avail, $space_w, $scale)
	next

	if $old_font then _WinAPI_SelectObject($dc, $old_font)
	_WinAPI_ReleaseDC($handle, $dc)

	$fit[1] = $need
	$fit[2] = $total
	return $fit

endfunc


; Pixel width of $string in the selected DC font, scaled to dialog units.
;
func UserDialogTextWidth($dc, $string, $scale)
	if $string = "" then return 0
	local $size = _WinAPI_GetTextExtentPoint32($dc, $string)
	if not IsDllStruct($size) then return 0
	return DllStructGetData($size, "X")/$scale
endfunc


; Wrapped row count for one explicit line inside $avail width. Wraps
; between words; only a single word wider than the line splits mid-word.
; The prompt font must already be selected into $dc.
;
func UserDialogWrapRows($dc, $line, $avail, $space_w, $scale)
	if $line = "" then return 1
	local $words = StringSplit($line, " ", $STR_ENTIRESPLIT)
	local $rows = 1
	local $current = 0
	for $i = 1 to $words[0]
		if $words[$i] = "" then
			if $current > 0 then $current += $space_w
			continueLoop
		endif
		local $word_w = UserDialogTextWidth($dc, $words[$i], $scale)
		if $current <= 0 then
			if $word_w <= $avail then
				$current = $word_w
			else
				local $parts = Ceiling($word_w/$avail)
				if $parts < 1 then $parts = 1
				$rows += $parts-1
				$current = $word_w-($parts-1)*$avail
			endif
		else
			if $current+$space_w+$word_w <= $avail then
				$current += $space_w+$word_w
			else
				$rows += 1
				if $word_w <= $avail then
					$current = $word_w
				else
					local $over = Ceiling($word_w/$avail)
					if $over < 1 then $over = 1
					$rows += $over-1
					$current = $word_w-($over-1)*$avail
				endif
			endif
		endif
	next
	return $rows
endfunc



; Put the app's built-in icon in a dialog's title bar, so it never wears
; the generic app icon. Every run is a fresh build, so the executable
; always carries it. Returns the icon handle, or 0: destroy it after
; the dialog closes.
;
func SetDialogAppIcon($dialog)
	local $image = _WinAPI_ExtractIcon(@AutoItExe, 0)
	if not $image then return 0
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $dialog, "uint", $WM_SETICON, "wparam", 0, "lparam", $image)
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $dialog, "uint", $WM_SETICON, "wparam", 1, "lparam", $image)
	return $image
endfunc










; Automatic Version Checking.
; See corz_essentials.au3 for more info
; requires.
;	#include <Date.au3>
;	#include <Misc.au3>
;	#include <WinAPIFiles.au3>
;	#include <InetConstants.au3>
func VersionCheckOnline($v_name, $vck_url, $dl_url, $my_ini, $my_section, $this_version, $GUI=default)

	debug("VersionCheckOnline(v)" & $this_version, @ScriptLineNumber, 6);debug

	if not @Compiled then return

	local $version_checking = IniRead($my_ini, $my_section, "version_checking", "")

	if $version_checking == 0 then return false

	if $version_checking = -1 or $version_checking = "" then	; -1 at install time
		local $do_checkver = CorzFancyInputBox("Automatic Version Checking?", $v_name & _
						" can check online for a new version of itself." & $MSG_LF & _
						"Enter the number of days between checks." & $MSG_LF & _
						"(enter 0 to disable version checking.)", "" , " M" , _
						400, 130 , (@DesktopWidth/2)-200, (@DesktopHeight/2)-50, 0, $GUI)
		if $do_checkver = "" then return false ; cancelled out of inputbox
		; They enter "fuck off!", we write "0"
		$version_checking = Number($do_checkver)
		IniWrite($my_ini, $my_section, "version_checking", $version_checking)
		if $version_checking = 0 then return false
	endif

	if $version_checking > 365 then $version_checking = 365

	if $version_checking > 0 or StringLeft($version_checking, 1) = "a" then
		local $version_checked = IniRead($my_ini, $my_section, "version_checked", "2000/01/01 00:00:00")

		if StringLeft($version_checking, 1) <> "a" then
			local $days_passed = _DateDiff("D", $version_checked, _NowCalc())
			if $days_passed < $version_checking then return false
		endif
	endif

	local $day_string = "every day"
	if $version_checking > 1 then $day_string = "every " & $version_checking & " days"
	if StringLeft($version_checking, 1) = "a" then $day_string = "always"

	local const $MINIMUM_PROGRESS_DISPLAY_MS = 1500
	ProgressOn("Version Check (" & $day_string & ")", "Checking for new version.")
	local $progress_started = TimerInit()
	local $display_remaining
	ProgressSet(25)

	$vck_url &= "&frequency=" & $version_checking & "&current=" & $this_version

	local $published_version = BackGroundDownload($vck_url, 5000, 25)
	local $errmsg, $ext_error = @extended

	if @Error <> 0 or not $published_version then
		switch $ext_error
			case 1
				$errmsg = $MSG_LF & "The server did not return version information."

			case 2
				$errmsg = $MSG_LF & "Connexion timed-out."
		endswitch

		debug("Version Check FAILED." & $errmsg, @ScriptLineNumber, 1);debug
		ProgressSet(100, "Version check failed.")
		$display_remaining = $MINIMUM_PROGRESS_DISPLAY_MS - TimerDiff($progress_started)
		if $display_remaining > 0 then Sleep($display_remaining)
		ProgressOff()
		MsgBox(16, "Version Check FAILED!", "Could not determine version online." & $errmsg)
		return false
	endif

	ProgressSet(50)
	IniWrite($my_ini, $my_section, "version_checked", _NowCalc())
	ProgressSet(75)

	local $vcomp = _VersionCompare($this_version, $published_version)

	switch $vcomp
		case 0, 1	; both equal (or $this_version is greater!!!)
			ProgressSet(100, "No new version available.")
			$display_remaining = $MINIMUM_PROGRESS_DISPLAY_MS - TimerDiff($progress_started)
			if $display_remaining > 0 then Sleep($display_remaining)
			ProgressOff()
			return false

		case -1
			ProgressSet(100, "New version available.")
			$display_remaining = $MINIMUM_PROGRESS_DISPLAY_MS - TimerDiff($progress_started)
			if $display_remaining > 0 then Sleep($display_remaining)
			ProgressOff()
			local $version_response = MsgBox(4+48+262144, "New Version Available", _
									"A newer version of " & $v_name & " is available." & $MSG_LF _
										&  "Would you like to visit the download page?")

			switch $version_response
				case $IDYES	; yes - go to download page
					ShellExecute($dl_url)
			endswitch

			return $published_version
	endswitch
endfunc




; Download a file from $dl_URL in the background, wait for $timeout milliseconds.
; This is designed to be used with VersionCheckOnline(), but could be used for any background download.
; Returns the raw file data.
; Abort, set @Error to non-0 and return false if file not received.
; Type of fail is in @extended (1=download failed, 2=timeout)
;
; NOTE: this function updates a progress dialog (set current position with $start). Optional.
func BackGroundDownload($dl_URL, $timeout=default, $start=default, $save_file=default)

	if $timeout = default then $timeout = 3000
	local $show_progress = $start <> default
	if $start = default then $start = 0
	if $save_file = default then $save_file = false

	local $c_time, $tmp_file

	if $save_file then
		$tmp_file = $save_file
	else
		$tmp_file = _WinAPI_GetTempFileName(@TempDir, $app_name)
	endif

	local $download = InetGet($dl_URL, $tmp_file, ($INET_FORCERELOAD + $INET_FORCEBYPASS), $INET_DOWNLOADBACKGROUND)

	; We could use a sleep step for calculating time, but using small steps (eg. 25) would throw the total out of whack
	local $BG_time = TimerInit()
	local $dmsg

	do
		Sleep(10)

		$c_time = Round(TimerDiff($BG_time))

		if Mod($c_time, 100) < 11 then	; 1 larger than sleep time (above).

			if $show_progress and $c_time > 999 then
				ProgressSet($start+(($c_time*3)/1000), "", "Checking: timeout in " & ($timeout-$c_time) & " ms")
			endif
		endif

		if $c_time >= $timeout then
			InetClose($download)
			if not $save_file then FileDelete($tmp_file)
			$dmsg = "Failed. Connexion Timeout."
			if $show_progress then ProgressSet(0, "", $dmsg)
			debug($dmsg, @ScriptLineNumber, 1);debug
			return SetError(1, 2, $dmsg)	; 2 = timeout
		endif
	until InetGetInfo($download, $INET_DOWNLOADCOMPLETE)

	local $success = InetGetInfo($download, $INET_DOWNLOADSUCCESS)
	InetClose($download)

	local $dl_data = FileRead($tmp_file)
	if @error then $success = false

	if not $success then
		if not $save_file then FileDelete($tmp_file)
		$dmsg = "Failed. Download Error."
		debug($dmsg, @ScriptLineNumber, 1);debug
		if $show_progress then ProgressSet(0, "", $dmsg)
		return SetError(1, 1, $dmsg)
	endif

	if $show_progress then ProgressSet(0, "", "Success!")

	if not $save_file then
		FileDelete($tmp_file)
		return SetError(0, 0, $dl_data)
	endif
endfunc




; Feed it a path, if it is a full, valid path it is returned as-is.
; If it's a relative path, it is added to the datadir path and that full path is returned.
func SetRelPathToDataDir($some_path)

	if $some_path and StringLeft($some_path, 2) <> '\\' and StringMid($some_path, 2, 1) <> ':' then
		CLT($some_path)
		$some_path = $data_dir & "\" & $some_path
		CRT($some_path)
	endif

	return $some_path
endfunc




; Fire up the user's default screensaver.
;
func StartScreenSaver()
	global $user32_dll = DllOpen("user32.dll")
	local Const $WM_SYSCOMMAND = 0x112
	local Const $SC_SCREENSAVE = 0xF140
	local $gui = GUICreate("",10,10,-100,-100)
	local $guiHandle = WinGetHandle($gui)
	DllCall($user32_dll, "long", "SendMessageA", "long", $guiHandle, "long", $WM_SYSCOMMAND, "long", $SC_SCREENSAVE, "long", 0x0)
	DllClose($user32_dll)
	GUIDelete($gui)
endfunc




; Lock the WorkStation.
; Simple, effective.
;
func LockWorkStation()
	ShellExecute("rundll32.exe", 'user32.dll,LockWorkStation') ; NOTE: CaSe is Crucial, here.
	if @Error then return SetError(@Error, @Extended, false)
	return true
endfunc




; Author:       xrxca (autoit at forums dot xrx dot ca) + wee bits by me
;
func _GetMonitors()
	$monitors_list[0][0] = 0  ;  Added so that the global array is reset if this is called multiple times
	local $handle = DllCallbackRegister("_MonitorEnumProc", "int", "hwnd;hwnd;ptr;lparam")
	DllCall("user32.dll", "int", "EnumDisplayMonitors", "hwnd", 0, "ptr", 0, "ptr", DllCallbackGetPtr($handle), "lparam", 0)
	DllCallbackFree($handle)
	local $i = 0

	for $i = 1 To $monitors_list[0][0]
		if $monitors_list[$i][1] < $monitors_list[0][1] then $monitors_list[0][1] = $monitors_list[$i][1]
		if $monitors_list[$i][2] < $monitors_list[0][2] then $monitors_list[0][2] = $monitors_list[$i][2]
		if $monitors_list[$i][3] > $monitors_list[0][3] then $monitors_list[0][3] = $monitors_list[$i][3]
		if $monitors_list[$i][4] > $monitors_list[0][4] then $monitors_list[0][4] = $monitors_list[$i][4]
	next

	return $monitors_list
endfunc   ;==>_GetMonitors

; Collects one monitor's handle and rectangle into the monitors list during
; enumeration. Used to map multi-monitor layouts.
;
func _MonitorEnumProc($hMonitor, $hDC, $lRect, $lParam)
#forceref $lParam, $hDC
	local $Rect = DllStructCreate("int left;int top;int right;int bottom", $lRect)
	$monitors_list[0][0] += 1
	redim $monitors_list[$monitors_list[0][0] + 1][5]
	$monitors_list[$monitors_list[0][0]][0] = $hMonitor
	$monitors_list[$monitors_list[0][0]][1] = DllStructGetData($Rect, "left")
	$monitors_list[$monitors_list[0][0]][2] = DllStructGetData($Rect, "top")
	$monitors_list[$monitors_list[0][0]][3] = DllStructGetData($Rect, "right")
	$monitors_list[$monitors_list[0][0]][4] = DllStructGetData($Rect, "bottom")
	return 1 ; Return 1 to continue enumeration
endfunc




; By ascend4nt (encapsulated by cor)
; Returns the handle of the owner window directly under the mouse.
func GetWindowUnderMouse($iX,$iY)
	local $stInt64,$aRet,$stPoint=DllStructCreate("long;long")
	DllStructSetData($stPoint,1,$iX)
	DllStructSetData($stPoint,2,$iY)
	$stInt64=DllStructCreate("int64",DllStructGetPtr($stPoint))
	$aRet=DllCall("user32.dll","hwnd","WindowFromPoint","int64",DllStructGetData($stInt64,1))
	if @Error then return SetError(2,@Error,0)
	if $aRet[0]=0 Then return SetError(3,0,0)
	; The above can return 'sub' windows, or control handles, so we get the owner window.
	local $aResult = DllCall("user32.dll", "hwnd", "GetAncestor", "hwnd", $aRet[0], "uint", 2)
	if @Error then return SetError(@Error, @Extended, 0)
	return $aResult[0]
endfunc




; check wether a number is within a set range.
func NumberInRange($number, $min, $max)
	return ($number >= $min and $number <= $max);
endfunc




; Speak some text out loud.
;
; Rate is -10 to 10 or thereabouts.
; Volume 0 - 100, maybe.
; Voice is a substring of one of your available system voices (e.g. "Hazel").
;
func Speak($text, $vol=50, $rate=0, $voice="", $wait=false)
 debug("", @ScriptLineNumber, 7);debug
 debug("Speak(" & $text & "," & $vol  & "," & $rate & "," & $wait & ")", @ScriptLineNumber, 7);debug

	; Use a global variable so speech call is asynchronous. If you start a
	; new speech command, it will cut-off the old one and begin immediately.
	global $o_speech = ObjCreate("SAPI.SpVoice")
	if not IsObj($o_speech) then return false
	local $speak_flag

	if $wait then
		$speak_flag = 10	; no asynch
	else
		$speak_flag = 11	;8 = XML 	1 = SVSFlagsAsync	2: purge (seems to do this, anyway)
	endif

debug("Speak() --> DeTokenizeString -->" & $text & "<=", @ScriptLineNumber, 7);debug
	$text = DeTokenizeString($text, default, default, default, $voice)

	if FileExists($text) then
		$speak_flag += 4	; will read file contents when given valid file path
	endif

	; choose a voice.
	local $choose_voice = $o_speech.GetVoices().Item(0)

	if $voice then
		for $i = 0 to $o_speech.GetVoices().Count() - 1
			local $MS_voice = $o_speech.GetVoices().Item($i)

			if StringInStr($MS_voice.GetAttribute("Name"), $voice) then
				$choose_voice = $MS_voice
				exitloop
			endif
		next
	endif

	; speak the text.
	with $o_speech
		.Voice = $choose_voice
		.Rate = $rate
		.Volume = $vol
		.Speak($text, $speak_flag); with XML + purge before speak
	endwith

	return true
endfunc




; Returns an array of available system voices.
; NOTE: Unless you hack your registry, you will probably only have a small
; selection of voices to play with. See KeyBind docs for how to expand this.
func GetSpeechVoices()
	local $o_speech = ObjCreate("SAPI.SpVoice")
	if not IsObj($o_speech) then return -1
	local $this_voice
	local $voice_array[1]

	for $i = 0 to $o_speech.GetVoices().Count() - 1
		$this_voice = $o_speech.GetVoices().Item($i)
		ArrayAdd($voice_array, $this_voice.GetAttribute("Name"))
	next

	return $voice_array
endfunc




;
; Get the command-line arguments.
; Returns an array with two values.
;
;	$ret_array[0]	=>	switches
;	$ret_array[1]	=>	filename (if supplied)
;
;	Do:
;
; 	local $cmd_array = $CmdLine
; 	local $cmdline = GetCommandLine($CmdLineRaw, $cmd_array)
; 	global $switches = $cmdline[0]
; 	global $inputfile = $cmdline[1]
;
;	Note, when running inside your IDE (not @Compiled) you may not get the same
;	results as you will when @Compiled, depending on your IDE. Test the compiled
;	version!
;
func GetCommandLine($command_line, $cmd_array)
 debug("", @ScriptLineNumber, 7);debug
 debug("GetCommandLine(" & $command_line & ")", @ScriptLineNumber, 7);debug
 debugPrintArray($cmd_array, $LOG_LF & "cel.au3 :: (" & @ScriptLineNumber & ") " & " $cmd_array: ");debug

	$command_line = StringStripWS($command_line, $STR_STRIP_ENDS)

	local $ret_array[2]

	if $cmd_array[0] then
		for $i = 1 to $cmd_array[0]
			$cmd_array[$i] = StringStripWS($cmd_array[$i], $STR_STRIP_ENDS)
		next

		; file path supplied.
		if StringRight($command_line, 1) <> ")" then
			$ret_array[1] = StringStripWS($cmd_array[$cmd_array[0]], $STR_STRIP_ENDS)

			for $i = 1 to $cmd_array[0]
				if StringStripWS($cmd_array[$i], $STR_STRIP_ENDS) <> $ret_array[1] then _
					$ret_array[0] &= StringStripWS($cmd_array[$i], $STR_STRIP_ENDS) & " "
			next
		else
			$ret_array[1] = ""

			for $i = 1 to $cmd_array[0]
				$ret_array[0] &= StringStripWS($cmd_array[$i], $STR_STRIP_ENDS) & " "
			next
		endif
	endif

	CRT($ret_array[0], " ")
	return $ret_array
endfunc




;
; UrlToText()

; Basic HTML > text translation, for spoken web pages
; slow, and not terribly clever.
;
; Feed it a URL or path to a local html file, returns the plain text, for speaking
; all formatting is removed, and "." dots are also added to break up big sections.
;
; You can send start and end points for the text stream; simply tag the words/phrases
; onto the end of the URL (or local file location) using an asterisk, e.g.
;
; $myText = UrlToText('https://news.bbc.co.uk/*Last Updated*CONTACT US')
;
; Which would get you the latest headlines from the BBC, ready for feeding to Sam, or Mike
; or Mary or whoever. If you omit the end point, e.g.
;
; $myText = UrlToText('https://www.answers.com/topic/gal-pagos-tortoise-2*Synonyms')
;
; All the text from the start point to the end of the page will be returned. If you provide
; no start and end points, the text of the whole page is returned. Something to play with.
;
; True when text starts with an http(s) address, any case, blanks allowed.
;
func IsWebUrl($text)
	return StringRegExp($text, "(?i)^\s*https?://") = 1
endfunc





; Fetches a URL and returns its readable text with optional space stripping.
; Used by download and speak-URL tasks.
;
func UrlToText($url, $strip_spaces=true)
 debug("", @ScriptLineNumber, 7);debug
 debug("UrlToText(" & $url & ")", @ScriptLineNumber, 7);debug

	local $start = ""
	local $end = ""
	local $handle = ""

	if StringInStr($url, "*", 0, -1) then
		local $url_parts = StringSplit($url, "*")
		$url = $url_parts[1]
		if uBound($url_parts) > 2 then $start = $url_parts[2]
		if uBound($url_parts) > 3 then $end = $url_parts[3]
	endif

	if IsWebUrl($url) then
		local $tmpfile = @TempDir & "\" & $app_name & "\UrlToText.tmp"
		InetGet($url, $tmpfile, 1)
		; If no file or temp
		$handle = FileOpen($tmpfile, $FO_READ)
	else
		$handle = FileOpen($url, $FO_READ)
	endif

	local $web_text = FileRead($handle)

	if StringInStr($web_text, "<") then
		; We'll break shit up for speaking.
		$web_text = StringRegExpReplace($web_text, '</(div|p|tr|table)>', '. ')
		; Strip out the HTML.
		$web_text = StringRegExpReplace($web_text, '\s', ' ')
		$web_text = StringRegExpReplace($web_text, '<(?i)head(.*?)</(?i)head>', '') ; best done individually.
		$web_text = StringRegExpReplace($web_text, '<(?i)script(.*?)</(?i)script>', '')
		$web_text = StringRegExpReplace($web_text, '<(?i)style(.*?)</(?i)style>', '')
		$web_text = StringRegExpReplace($web_text, '</?[^>]*?>', '')
		$web_text = StringReplace($web_text, '|', '')
		$web_text = ReplaceHTMLEntities($web_text)
	endif

	; From.
	if $start then
		$web_text = StringTrimLeft($web_text, StringInStr($web_text, $start)-1)
	endif

	; To.
	local $strlen = StringLen($web_text)
	local $end_pos = StringInStr($web_text, $end)

	if $end_pos = 0 then $end_pos = $strlen

	if $end then
		$web_text = StringTrimRight($web_text, $strlen-$end_pos+1)
	endif

	FileClose($handle)
	FileDelete(@TempDir & "\" & $app_name & "\UrlToText.tmp")
	debug("web_text: =>" & $web_text & "<=" , @ScriptLineNumber, 10)

	if $strip_spaces then return StringStripWS($web_text, $STR_STRIPSPACES)
	return $web_text
endfunc




; DoLog()

; Logs stuff.
;
; The optional second parameter tells DoLog to append, or not.
; $dl_append will most likely receive the output from a checkbox.
; 1 (append) or 4 [or anything else] (create new log)
;
; To stop and close the log, send "out" as your log string
; the optional third parameter '$log_extra' goes at top of log,
; and, if required, you must send it along with your "out" command, eg.
;
;
; DoLog("out", 0, "command-line: " & $my_arguments & $LOG_LF & $LOG_LF)

;
; and now the function itself.
func DoLog($dl_string, $dl_append=$OFF, $log_extra="")

	debug("Log extra: " & $log_extra, @ScriptLineNumber, 10 );debug

	if $dl_string = "out" then
		if $log_string then
			if $dl_append = $ON then
				$dl_append = $FO_APPEND + $FO_CREATEPATH
			else
				$dl_append = $FO_OVERWRITE  + $FO_CREATEPATH
			endif

			local $my_log_file = FileOpen($log_location, $dl_append)
			FileWrite($my_log_file, $app_name & _
				" log:  " & DateTimeString() & ". " & $LOG_LF & _
				"--------------------------------------------------------------------------------" & $LOG_LF)

			if not $log_extra then
				FileWrite($my_log_file, "command-line: " & $CmdLineRaw & $LOG_LF & $LOG_LF)
			endif

			FileWrite($my_log_file, $log_extra & @LF)
			FileWrite($my_log_file, $log_string & $LOG_LF)
			FileClose($my_log_file)
			$log_string = ""
		endif
	else
		$log_string &= UnifyCRLF($dl_string) & $LOG_LF
	endif

	return $dl_string
endfunc




;;	Debugging Functions.

; One of AutoIt's "limitations" is that it converts all console output to ASCII.
; Here we say, "FUCK THAT!" and bypass all that CP_OEMCP shite and use
; GetStdHandle(-11) directly (well, via WriteFile ()).

; Basically, you can now see "foreign" characters in the console.
; Some languages will still resist (e.g. Kannada), but most should display fine.

; If your IDE is dumb, you can call this before you start debug output.
func AttachParentConsole()
    local $kernel32_handle = "kernel32.dll"
    ; Attach to parent process console stream if available
    DllCall($kernel32_handle, "bool", "AttachConsole", "dword", -1)
endfunc




; ConsoleWrite() replacement.
func ConsoleWriteUTF8($text)
    local $kernel32_handle = "kernel32.dll"

    local $std_handle = DllCall($kernel32_handle, "handle", "GetStdHandle", "dword", -11)[0]
    if $std_handle = 0 or $std_handle = -1 then return false

    local $char_count = StringLen($text)
    if $char_count = 0 then return true

    ; Calculate required UTF-8 byte buffer size (CP_UTF8 = 65001)
    local $buffer_size = DllCall($kernel32_handle, "int", "WideCharToMultiByte", _
        "uint", 65001, _
        "dword", 0, _
        "wstr", $text, _
        "int", $char_count, _
        "ptr", 0, _
        "int", 0, _
        "ptr", 0, _
        "ptr", 0)[0]

    if $buffer_size = 0 then return false

    local $buffer_struct = DllStructCreate("byte[" & $buffer_size & "]")
    local $buffer_ptr = DllStructGetPtr($buffer_struct)

    ; Convert wide string into UTF-8 byte array
    DllCall($kernel32_handle, "int", "WideCharToMultiByte", _
        "uint", 65001, _
        "dword", 0, _
        "wstr", $text, _
        "int", $char_count, _
        "ptr", $buffer_ptr, _
        "int", $buffer_size, _
        "ptr", 0, _
        "ptr", 0)

    local $written_bytes = 0

    ; Write UTF-8 bytes to handle (works on pipes, file streams, and consoles)
    DllCall($kernel32_handle, "bool", "WriteFile", _
        "handle", $std_handle, _
        "ptr", $buffer_ptr, _
        "dword", $buffer_size, _
        "dword*", $written_bytes, _
        "ptr", 0)
endfunc




;
; debug()

; Provides quick debug report in your console/log.
;
; If your text editor can do it (probably), this is a great
; way to get debug output without halting the script execution.
;
; Newbies: you set your global $debug_level and bugs of that level
; and below are logged. Stuff you always want to see will have a low
; level, and stuff you rarely want to see (it's large, etc.) will
; have a higher level.
;
; Debug level 0 disables all output. Active levels go from 1 to 10,
; though typically in my apps there is also level 11, where gobs of
; generally unnecessary output is produced. An occasionally useful
; nod to Spinal Tap, keeps the Gnomes away.
;
; NOTE: if you call debug() in a compiled script you will get
; the debug() output debugDump()ed to a log, instead.
;
; The Au3Stripper Parameter "/rsln" ensures these line numbers are
; preserved in the compiled script, so debug output is fairly useful.
; A typical debug line might look like this:
;
; (1103/2899) : ==> $do_output: enabled
;
; The numbers in braces refer to (original script line / stripped
; script line). The one on the left is probably the most useful.
;
func debug($debug_string, $ln=false, $level=1, $max_size=$max_log_size)

	if not $debug_level or $level > $debug_level then return false

	if @Compiled then return debugDump($debug_string, $ln, $level, true, $max_size)

	; This is unlikely to catch actual arrays under normal circumstances (there is a string prepended to input!).
	if IsArray($debug_string) then return debugPrintArray($debug_string, "cel.au3 :: NOT A STRING!", $ln, $level, 0, $max_size);debug

	local $pre = ""

	; We add the line numbers so that:
	; a) We know where shit happens, and.
	; b) if your text editor supports it, we can click those lines in the console output
	; and go directly to that line in the script. If your text editor/IDE does not support
	; this feature, upgrade your editor. The time you are wasting ..

	; Notepad++
	if $ln and $ln <> -1 then $pre = "(" & $ln & ") " & @Tab
	; ; Editplus.
	; if $ln then $pre = ".\" & @ScriptName & "(" & $ln & "): ==> "
	; etc.
	; if $ln then $pre = """" & @ScriptFullPath & """(" & $ln & "): ==> "
	if $pre then $pre &= "[ " & _NowCalcDate() & " @ " & _NowTime() & "::" & @Msec & " ][l:" & $level & "]" & @Tab

	; NOTE: Currently AutoIt converts all console output to ANSI. Let's bypass that.
	ConsoleWriteUTF8($pre & $debug_string & $LOG_LF)
endfunc




;
; debugDump()

; Like debug (), but to a file.
func debugDump($debug_string, $ln=false, $level=1, $append=true, $max_size=$max_log_size)

	if not $debug_level or $level > $debug_level then return false
	if IsArray($debug_string) then return debugDumpArray($debug_string, "$ARRAY:", $append, $level, $max_size)

	local $pre
	local $code = $FO_APPEND + $FO_UTF8;
	if $append = false then $code = $FO_OVERWRITE + $FO_UTF8
	if $ln and $ln <> -1 then $pre = "(" & $ln & ") : ==> "
	CheckLogSize($max_size)
	local $fileh = FileOpen($debug_log, $code)
	FileWrite($fileh, $pre & $debug_string & $LOG_LF)
	FileClose ($fileh)
endfunc




;
; LogError()

; It should be "errer", really.
; Log an (usually, exit) error to a file
;
func debugLogError($error_string)
	local $handle = FileOpen(@ScriptDir & "\error.log", $FO_APPEND + $FO_CREATEPATH)
	if $handle = -1 then return
	FileWrite($handle, @LF & "--------------------------------------------------------------------------------" & @LF & _
		@Year & "/" & @Mon & "/" & @MDay & "  " & @Hour & ":" & @Min & ":" & @Sec & @LF & @LF & _
		"command-line: " & $CmdLineRaw & @LF & @LF & $error_string & @LF)
	FileClose($handle)
endfunc




;
; debugPrintArray()

; Debug output of an array, in the console
; (your text editor/IDE can probably display this for you, if you so desire).
func debugPrintArray(byref $array, $tring="array", $ln="", $level=1, $limit=0, $max_size=$max_log_size, $forcedump=false, $string=false, $simple_list=false)

	if not $debug_level or $level > $debug_level then return false

	local $pre
	$pre = "(" & $ln & ") " & @Tab
	if $pre then $pre &= "[ " & _NowCalcDate() & " @ " & _NowTime() & "::" & @Msec & " ][l:" & $level & "]" & @Tab
	if not IsArray($array) then return ConsoleWriteUTF8($LOG_LF & $pre & $tring & ": NOT an array!" & _
						$LOG_LF & $pre & "it's a string: " & "->" & $array & "<-" & $LOG_LF & $LOG_LF)

	; 2+dimensional array sent.
	if UBound($array, 0) > 1 then return debugPrint2DArray($array, $tring, $ln, $level, $limit, $max_size, $forcedump, $string)

	local $pa_string = ""
	local $count = 0

	for $element in $array
		if $simple_list then
			$pa_string &= $element & ", "
		else
			$pa_string &= '[' & $count & '] : ' & $element & $LOG_LF
		endif

		$count += 1
		if $count = $limit then exitloop
	next

	local $delimiter = $LOG_LF

	if $simple_list then
		$pa_string = StringTrimRight($pa_string, 2)
		$delimiter = ""
	endif

	local $return_string = $pre & $tring & ": " & $delimiter & $pa_string & $LOG_LF
	if not $simple_list then $return_string = $LOG_LF & $return_string
	if $string then return $return_string

	if @Compiled or $forcedump then
		debugDump($return_string, $ln, $level, true, $max_size)
	else
		ConsoleWriteUTF8($return_string)
	endif
endfunc




; Like debugPrintArray, but will handle arrays with more than two columns.
;
; For if you know what you should have, and want to see it.
; Only works for the kind of arrays returned by IniReadSection() and similar
; functions, or ones you created yourself, needs $array[0][0] to be meaningful.
func debugPrint2DArray(byref $array, $tring="array", $ln="", $level=1, $limit=0, $max_size=$max_log_size, $forcedump=false, $string=false) ; $limit for compatability only
	if not $debug_level or $level > $debug_level then return 0
	local $pre
	if $ln then $pre = "(" & $ln & ") " & @Tab
	if not IsArray($array) then return debug($pre & $tring & ": NOT an array!" & $LOG_LF & _
				$pre & "it's a string: " & "->" & $array & "<-" & $LOG_LF, @ScriptLineNumber, 5);debug
	; 1-dimensional array sent.
	if UBound($array, 0) < 2 then return debugPrintArray($array, $tring, $ln, $level, $limit, $ln)

	if $pre then $pre &= "[ " & _NowCalcDate() & " @ " & _NowTime() & "::" & @Msec & " ][l:" & $level & "]" & @Tab
	$limit += 1
	local $cols = UBound($array, 2)
	local $pa_string = ""

	for $i = 0 to UBound($array, 1)-1
			$pa_string &= '[' & $i & ']	[0] = ' & $array[$i][0] & '	'

		for $j = 1 to $cols-1
			$pa_string &= '	[' & $j & '] = ' & $array[$i][$j] & '	'
		next

		$pa_string &= $LOG_LF
	next

	if $string then return $LOG_LF & $pre & $tring & ": " & $LOG_LF & $pa_string & $LOG_LF

	if @Compiled or $forcedump then
		debugDump($LOG_LF & $pre & $tring & ": " & $LOG_LF & $pa_string & $LOG_LF, $ln, $level, true, $max_size)
	else
		ConsoleWriteUTF8($LOG_LF & $pre & $tring & ": " & $LOG_LF & $pa_string & $LOG_LF)
	endif
endfunc




; debugDumpArray()
; Debug output of an array, to a file.
func debugDumpArray(byref $array, $title="array", $append=true, $level=1, $max_size=$max_log_size)

	if not IsArray($array) then return 0
	if not $debug_level or $level > $debug_level then return false
	if UBound($array, 0) > 1 then return debugPrint2DArray($array, $title, "", $level, 0, $max_size)

	CheckLogSize($max_size)
	local $code = $FO_APPEND + $FO_UTF8
	if $append = false then $code = $FO_OVERWRITE + $FO_UTF8
	local $fileh = FileOpen($debug_log, $code)
	local $da_string = $title & $LOG_LF
	local $count = 0

	for $element in $array
		$da_string &= '[' & $count & '] : ' & $element & $LOG_LF
		$count += 1
	next

	FileWrite($fileh, $da_string)
	FileClose($fileh)
endfunc




; #include <WinAPISysWin.au3>
; #include <WinAPIGdi.au3>

; Gives every text input in a dialog breathing margins, so text never sits
; hard against the border. Runs once per dialog after its inputs exist;
; inputs added later need another pass. Returns the padded input count.
func PadDialogInputs($dialog, $left=4, $right=2)
	local $window_handle = IsHWnd($dialog) ? $dialog : WinGetHandle($dialog)
	if not IsHWnd($window_handle) then return SetError(1, 0, 0)
	local $children = _WinAPI_EnumChildWindows($window_handle)
	if not IsArray($children) then return SetError(2, 0, 0)
	local $padded = 0
	for $i = 1 to $children[0][0]
		if _WinAPI_GetClassName($children[$i][0]) <> "Edit" then continueloop
		DllCall("user32.dll", "none", "SendMessageW", "hwnd", $children[$i][0], "uint", $EM_SETMARGINS, _
			"wparam", BitOR($EC_LEFTMARGIN, $EC_RIGHTMARGIN), "lparam", BitOR($left, BitShift($right, 16)))
		$padded += 1
	next
	return $padded
endfunc




; Adds borders to all GUI controls so you can see what's what.
func debugGUICtrlBorders($gui_handle)

	if $debug_level <> 10 then return

	local $window_handle = IsHWnd($gui_handle) ? $gui_handle : WinGetHandle($gui_handle)
	if not IsHWnd($window_handle) then return

	local $child_windows = _WinAPI_EnumChildWindows($window_handle)
	local $current_style
	; Fallback for native controls if WinAPI enumeration returns 0
	if not IsArray($child_windows) then
		for $control_id = 3 to 1000
			local $control_handle = GUICtrlGetHandle($control_id)
			if $control_handle = 0 then continueloop

			if _WinAPI_GetParent($control_handle) = $window_handle then
				$current_style = _WinAPI_GetWindowLong($control_handle, $GWL_STYLE)
				_WinAPI_SetWindowLong($control_handle, $GWL_STYLE, BitOr($current_style, $WS_BORDER))
				_WinAPI_SetWindowPos($control_handle, 0, 0, 0, 0, 0, BitOr($SWP_FRAMECHANGED, $SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER))
			endif
		next

		return
	endif

	for $index = 1 to $child_windows[0][0]
		local $child_handle = $child_windows[$index][0]
		$current_style = _WinAPI_GetWindowLong($child_handle, $GWL_STYLE)
		_WinAPI_SetWindowLong($child_handle, $GWL_STYLE, BitOr($current_style, $WS_BORDER))
		_WinAPI_SetWindowPos($control_handle, 0, 0, 0, 0, 0, BitOr($SWP_FRAMECHANGED, $SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER))
		_WinAPI_RedrawWindow($child_handle)
	next
endfunc




; If the log reaches a preset size, backup and start again.
func CheckLogSize($max_size=$max_log_size)

	if $max_size <> 0 then
		if FileGetSize($debug_log) > ($max_size * 1048576) then	; Bytes > MB = * 1048576 (1024*1024)
			BackupLogFile($debug_log)
		endif
	endif
endfunc




; Provides a time-stamped backup of a file.
func BackupFile($file)
	local $backup = GetParent($file) & "\[" & FileDateStamp() & "]_" & RemoveExtension(Basename($file)) & "." & GetExtension($file)
	local $ret = FileMove($file, $backup)
	Run(@ComSpec & " /c " & 'compact.exe /C "' & $debug_log & '"', "", @SW_HIDE)
	return $ret
endfunc


; Rotates a log using the application's optional LogsDir() directory.
; Takes the live log path. If LogsDir() exists, calls it with true to
; prepare the destination and returns FileMove()'s result, or false if
; preparation fails. Otherwise returns BackupFile()'s result, keeping
; timestamped backups beside the supplied file. The application hook
; controls directory creation and compression; no hook is required.
#ignorefunc LogsDir
#Au3Stripper_Ignore_Errors_in_Funcs=BackupLogFile
func BackupLogFile($file)
	if not IsFunc("LogsDir") then return BackupFile($file)
	local $logs = Call("LogsDir", true)
	if $logs = false then return false
	local $backup = $logs & "\[" & FileDateStamp() & "]_" & RemoveExtension(Basename($file)) & "." & GetExtension($file)
	return FileMove($file, $backup)
endfunc




; _IsPressed (is a key pressed?)
; Author(s):	ezzetabi and Jon / Valik
func ce_IsPressed($Key)
	local $kp = DllCall('user32.dll', "int", "GetAsyncKeyState", "int", '0x' & $Key)
	if not @Error and BitAND($kp[0], 0x8000) = 0x8000 then return 1
	return 0
endfunc




; Is some window visible?
func WinVisible($GUI)
	return BitAnd(WinGetState($GUI), 2)
endfunc




; Grow a window back up to its minimum client size. Min-track messages
; never reach message handlers, so windows lacking them snap back from
; their resize path instead. Returns the client size in use.
;
func SnapWindowToMin($hwnd, $min_w, $min_h)
	local $outer = WinGetPos($hwnd)
	local $client = WinGetClientSize($hwnd)
	if not IsArray($outer) or not IsArray($client) then return 0
	local $use_w = $client[0]
	local $use_h = $client[1]
	if $use_w < $min_w then $use_w = $min_w
	if $use_h < $min_h then $use_h = $min_h
	if $use_w <> $client[0] or $use_h <> $client[1] then _
		WinMove($hwnd, "", $outer[0], $outer[1], $use_w + $outer[2] - $client[0], $use_h + $outer[3] - $client[1])
	return WinGetClientSize($hwnd)
endfunc




; Just for fun, reverses a StringSplit - handy if you have split a string to
; manipulate and now want it back as a string.
; Pass it an AutioIt array, as returned by StringSplit
;
; This also makes a great part 1 of a 1-2 WriteArrayToFromFile type function.
; (see above for exactly that)
;
func ArrayJoin($array, $join_str=$LOG_LF)
	debugPrintArray($array, "cel.au3 :: ArrayJoin():", @ScriptLineNumber, 8);debug
	debug("$join_str: " & $join_str, @ScriptLineNumber, 8);debug

	local $ret_str

	for $i = 1 to $array[0]
		if $array[$i] <> "" then
			$ret_str &= $array[$i] & $join_str
		endif
	next

	CRT($ret_str, $join_str)
	debug("$ret_str: " & $ret_str, @ScriptLineNumber, 8);debug

	return $ret_str
endfunc




; Reduce memory usage
; Author wOuter ( mostly )
; this requires Win2K Pro + to work	;o)
; http://msdn.microsoft.com/en-us/library/ms682606(VS.85).aspx
func ReduceMemory()
    DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', -1)
endfunc




; Return total available free memory.
func GetFreeMem()
	local $mem_stats = MemGetStats()
	local $free = $mem_stats[2] * 1024	; convert to bytes
	return $free
endfunc




; Returns free physical memory as a formatted megabyte string. Used by guards
; before large sound and download tasks.
;
func GetFreeMemHuman()
	local $mem_stats = MemGetStats()
	local $free = $mem_stats[2] / 1024	; convert to MB
	return FormatMB($free, 2)
endfunc




; close some running process.
func CloseProcess($process_name)
	SetError(0)
	local $closed = ProcessClose($process_name)
	if @Error then $closed = ProcessWaitClose($process_name)
	if @Error then $closed = Run(@ComSpec & " /c " & 'taskkill /F /T /IM ' & $process_name, "", @SW_HIDE)
	debug("Closed " & $process_name & ": " & $closed, @ScriptLineNumber, 7);debug
	return $closed
endfunc




; Cute little System Info Box.
; Designed to be included as an About Box Easter Egg.
;
; Modeless state for the box. SysInfoCreate() fills these, SysInfoTick()
; reads them, SysInfoClose() clears the open flag. Hosts driving the box
; modelessly tick it from their own loop; legacy callers keep the blocking
; SysInfoBox() wrapper, which pumps the same shared handlers below.
global $sysinfo_open = false, $sysinfo_gui = 0, $sysinfo_app = ""
global $sysinfo_x = -1, $sysinfo_y = -1, $sysinfo_w = 800, $sysinfo_h = 404
global $sysinfo_free = "Free", $sysinfo_current_drive = "", $sysinfo_last_sec = 0
global $sysinfo_link = false, $sysinfo_label_env = 0, $sysinfo_combo = 0
global $sysinfo_first_a = 0, $sysinfo_last_a = 0, $sysinfo_first_b = 0, $sysinfo_last_b = 0
global $sysinfo_in_time = 0, $sysinfo_in_date = 0, $sysinfo_in_freemem = 0, $sysinfo_in_uptime = 0
global $sysinfo_in_drive_label = 0, $sysinfo_in_totalspace = 0, $sysinfo_in_freespace = 0

; Opens the box without blocking, for hosts with their own loop. Returns
; the window handle, activating the existing box when already open. The host
; ticks SysInfoTick() from its loop and never touches the open flag. Returns
; 0 when creation failed. Optional warning_color sets the low-space warning;
; omitted values preserve red for other hosts.
func SysInfoCreate($app_name, $warning_color=$COLOR_RED)
	if $sysinfo_open then
		WinActivate($sysinfo_gui)
		return $sysinfo_gui
	endif
	return SysInfoBox($app_name, true, $warning_color)
endfunc




; Ticks the modeless box once per pass: liveness check, live readouts plus
; the clickable-link hover highlight. Takes no input, returns false when
; closed. warning_color selects the low-space warning, default red. Runs
; from the host loop while the box is open.
func SysInfoTick($warning_color=$COLOR_RED)
	if not $sysinfo_open then return false
	if not WinExists($sysinfo_gui) then
		SysInfoClose()
		return false
	endif
	SysInfoRefresh($warning_color)
	SysInfoLinkHover()
	return true
endfunc




; Refreshes the once-per-second readouts: clock, date, drive spaces, free
; memory and uptime. Takes a low-space warning color, default red, and returns
; nothing. Runs from SysInfoTick()
; and the blocking wrapper loop.
func SysInfoRefresh($warning_color=$COLOR_RED)
	if @Sec = $sysinfo_last_sec then return
	GUICtrlSetData($sysinfo_in_time, @Hour & ":" & @Min & ":" & @Sec)
	if @Sec < 2 and @Hour = 0 and @Min = 0 then
		GUICtrlSetData($sysinfo_in_date, @Year & "-" & @Mon & "-" & @Mday)
	endif
	$sysinfo_current_drive = GUICtrlRead($sysinfo_combo)
	GUICtrlSetData($sysinfo_in_drive_label, DriveGetLabel($sysinfo_current_drive & "\"))
	local $capacity = DriveSpaceTotal($sysinfo_current_drive & "\")
	local $free_space = DriveSpaceFree($sysinfo_current_drive & "\")
	GUICtrlSetData($sysinfo_in_totalspace, FormatMB($capacity, 2))
	GUICtrlSetData($sysinfo_in_freespace, FormatMB($free_space, 2) & " " & $sysinfo_free)
	if $free_space < ($capacity / 10) then
		GUICtrlSetBkColor($sysinfo_in_freespace, $warning_color)
	else
		GUICtrlSetBkColor($sysinfo_in_freespace, default)
	endif
	GUICtrlSetData($sysinfo_in_freemem, GetFreeMemHuman() & " " & $sysinfo_free)
	GUICtrlSetData($sysinfo_in_uptime, GetUptime())
	$sysinfo_last_sec = @Sec
endfunc




; Highlights the ENV link while hovered. Takes no input, returns nothing.
; Runs from SysInfoTick() and the blocking wrapper loop.
func SysInfoLinkHover()
	local $mouse = GUIGetCursorInfo($sysinfo_gui)
	if not IsArray($mouse) then return
	if $mouse[4] <> $sysinfo_link then
		if $mouse[4] = $sysinfo_label_env and $sysinfo_link = false then
			$sysinfo_link = $mouse[4]
			GUICtrlSetColor($sysinfo_label_env, $COLOR_LINK_HOVER)
			GUISetCursor(0, 1, $sysinfo_gui)
		else
			GUICtrlSetColor($sysinfo_label_env, default)
			GUISetCursor()
			$sysinfo_link = false
		endif
	endif
endfunc




; Reloads the drive readouts for the newly picked drive. Takes no input,
; returns nothing. Runs from the drive combo, event or polled.
func SysInfoDriveChanged()
	$sysinfo_current_drive = GUICtrlRead($sysinfo_combo)
	GUICtrlSetData($sysinfo_in_drive_label, DriveGetLabel($sysinfo_current_drive & "\"))
	GUICtrlSetData($sysinfo_in_totalspace, FormatMB(DriveSpaceTotal($sysinfo_current_drive & "\"), 2))
	GUICtrlSetData($sysinfo_in_freespace, FormatMB(DriveSpaceFree($sysinfo_current_drive & "\"), 2) & " " & $sysinfo_free)
endfunc




; Focuses the input beside a clicked label. Takes the clicked control id and
; the gap to its input, returns nothing. Runs from label clicks, event or
; polled.
func SysInfoFocusClicked($control_id, $gap)
	GUICtrlSetState($control_id + $gap, $GUI_FOCUS)
endfunc




; Shows the environment dialog above the box. Takes no input, returns
; nothing. Runs from ENV link clicks, event or polled.
func SysInfoEnvClicked()
	GUISetState(@SW_DISABLE, $sysinfo_gui)
	DisplayEnvVars()
	GUISetState(@SW_ENABLE, $sysinfo_gui)
endfunc




; Saves the box position and size, deletes the window and drops the open
; flag. Takes no input, returns nothing. Safe on an already dead window.
; Runs from close events, dead-window ticks and the blocking wrapper.
func SysInfoClose()
	if not $sysinfo_open then return
	$sysinfo_open = false
	local $size_array = WinGetPos($sysinfo_gui)
	if IsArray($size_array) and not BitAND(WinGetState($sysinfo_gui), $WIN_STATE_MINIMIZED) then
		if $sysinfo_x <> $size_array[0] then IniWrite($ini_path, $sysinfo_app, "si_x", WindowPositionCoord($size_array[0], "x", true, $size_array))
		if $sysinfo_y <> $size_array[1] then IniWrite($ini_path, $sysinfo_app, "si_y", WindowPositionCoord($size_array[1], "y", true, $size_array))
		$size_array = WinGetClientSize($sysinfo_gui)
		if IsArray($size_array) then
			if $size_array[0] <> $sysinfo_w and $size_array[0] >= 100 then IniWrite($ini_path, $sysinfo_app, "si_w", $size_array[0])
			if $size_array[1] <> $sysinfo_h and $size_array[1] >= 100 then IniWrite($ini_path, $sysinfo_app, "si_h", $size_array[1])
		endif
	endif
	GUIDelete($sysinfo_gui)
	$sysinfo_gui = 0
endfunc




; Closes the box from its X. Takes no input, returns nothing. Runs as the
; window close event under hosts with event mode on; inert otherwise.
func SysInfoCloseEvent()
	SysInfoClose()
endfunc




; Reloads the drive readouts from the combo. Takes no input, returns
; nothing. Runs as the combo event under hosts with event mode on.
func SysInfoDriveEvent()
	SysInfoDriveChanged()
endfunc




; Focuses the input beside the clicked label. Takes no input, returns
; nothing. Runs as the shared label event under hosts with event mode on.
func SysInfoFocusEvent()
	local $control_id = @GUI_CtrlId
	if $control_id >= $sysinfo_first_a and $control_id <= $sysinfo_last_a then SysInfoFocusClicked($control_id, 20)
	if $control_id >= $sysinfo_first_b and $control_id <= $sysinfo_last_b then SysInfoFocusClicked($control_id, 22)
endfunc




; Shows the environment dialog from the ENV link. Takes no input, returns
; nothing. Runs as the ENV label event under hosts with event mode on.
func SysInfoEnvEvent()
	SysInfoEnvClicked()
endfunc




; Cute little System Info Box.
; Designed to be included as an About Box Easter Egg.
;
; Modeless state for the box. SysInfoCreate() fills these, SysInfoTick()
; reads them, SysInfoClose() clears the open flag. Hosts driving the box
; modelessly tick it from their own loop; legacy callers keep the blocking
; SysInfoBox() wrapper, which pumps the same shared handlers below.

func SysInfoBox($app_name, $modeless = false, $warning_color=$COLOR_RED)

	local $last_event_mode = AutoItSetOption("GUIOnEventMode", 0)
	local $last_coord_mode = AutoItSetOption("GUICoordMode", 0)

	local $si_x = WindowPositionCoord(IniRead($ini_path, $app_name, "si_x", -1), "x")
	local $si_y = WindowPositionCoord(IniRead($ini_path, $app_name, "si_y", -1), "y")
	local $si_w = IniRead($ini_path, $app_name, "si_w", 800)
	local $si_h = IniRead($ini_path, $app_name, "si_h", 404)
	if $si_w < 400 Then $si_w = 400
	local $label_width = 140
	local $info_width = $si_w - $label_width - 20
	local $free = _T("Free")

	local $gui_sysinfo = GUICreate(_T("System Information"), $si_w, $si_h, $si_x, $si_y, _
			BitOR($WS_CLIPSIBLINGS, $WS_CAPTION, $WS_SYSMENU, $WS_SIZEBOX), $WS_EX_TOPMOST)
	GUISetIcon(@AutoItExe, 0, $gui_sysinfo)

	GUISetCoord($si_w-33, 10)
	local $label_env = GUICtrlCreateLabel("ENV", 0, 0, 30, 20)
	GUICtrlSetResizing(-1, $GUI_DOCKMENUBAR+$GUI_DOCKWIDTH+$GUI_DOCKRIGHT)
	GUICtrlSetTip(-1, _T("Click here to see this system's Environment Variables (aka. '{{ENV VAR}}')."))

	GUISetCoord(10, -10)
	local $computername = GUICtrlCreateLabel(_T("Computer Name:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("Memory:"), $label_width + 220, 0, 60)

	GUISetCoord(10, 10)
	GUICtrlCreateLabel(_T("Current UserName:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("Operating System:"), 0, 20, $label_width)
	local $last_expand_env_strings = AutoItSetOption("ExpandEnvStrings", 0)
	GUICtrlCreateLabel(_T("System {{%PATH%}}:"), 0, 20, $label_width)
	AutoItSetOption("ExpandEnvStrings", $last_expand_env_strings)
	local $ip = GUICtrlCreateLabel(_T("Local {{IP}} Address:"), 0, 20, $label_width)
	local $combo_info_drives = GUICtrlCreateCombo("", 0, 22, 100, 200)
	local $my_drives = DriveGetDrive("FIXED")

	for $i = 1 to $my_drives[0]
		GUICtrlSetData($combo_info_drives, $my_drives[$i])
	next

	ControlCommand($gui_sysinfo, "", $combo_info_drives, "SelectString", @HomeDrive)
	local $startupdir = GUICtrlCreateLabel(_T("Startup Directory:"), 0, 28, $label_width)
	GUICtrlCreateLabel(_T("{{Windows}} Directory:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("System Folder:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("Desktop Directory:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("'{{My Documents}}' Directory:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("{{Program Files}} Directory:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("{{Start Menu}} Directory:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("Temporary File Directory:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("Desktop:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("Date [Y-M-D]:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("Time [H:M:S]:"), 0, 20, $label_width)
	GUICtrlCreateLabel(_T("Uptime:"), 0, 20, $label_width)

	local $myini = GUICtrlCreateLabel(_T("My {{ini}}:"), 0, 20, $label_width)

	GUISetCoord($label_width + 10, -12)
	local $current_drive = GUICtrlRead($combo_info_drives)
	local $inp_computername = GUICtrlCreateInput(@ComputerName, 0, 20, 200, 20)
	local $input_freemem = GUICtrlCreateInput(GetFreeMemHuman(), $label_width * 2, 0, 120, 20)

	local $input_tip = _T("Click the labels to select all the input text.\nNOTE: Some update dynamically and will quickly deselect themselves!")

	for $i = $computername to $input_freemem
		GUICtrlSetResizing($i, $GUI_DOCKALL)
		GUICtrlSetTip($i, _L($input_tip))
	next

	GUISetCoord($label_width + 10, 10)
	local $input_username = GUICtrlCreateInput(@UserName, 0, 20, $info_width, 20)
	local $vbit = "x86"
	if @AutoItX64 = 1 then $vbit = "x64"
	local $os_string = StringReplace(@OSVersion, "_", " ") & " (" & $vbit & ") " & @OSServicePack & " [" & @OSType & "][CPU:" & StringLower(@CPUArch) & "]"
	GUICtrlCreateInput($os_string, 0, 20, $info_width, 20)
	GUICtrlCreateInput(EnvGet("PATH"), 0, 20, $info_width, 20)
	local $ip_text = "1: " & @IPAddress1
	if @IPAddress2 <> "0.0.0.0" then $ip_text &= "  2: " & @IPAddress2
	if @IPAddress3 <> "0.0.0.0" then $ip_text &= "  3: " & @IPAddress3
	if @IPAddress4 <> "0.0.0.0" then $ip_text &= "  4: " & @IPAddress4
	GUICtrlCreateInput($ip_text, 0, 20, $info_width, 20)
	local $input_drive_label = GUICtrlCreateInput(DriveGetLabel($current_drive & "\"), 0, 23, 150, 20)
	local $input_totalspace = GUICtrlCreateInput(FormatMB(DriveSpaceTotal($current_drive & "\"), 2), 155, 0, 100, 20)
	local $input_freespace = GUICtrlCreateInput(FormatMB(DriveSpaceFree($current_drive & "\"), 2) & " " & $free, 105, 0, 150, 20)
	GUISetCoord($label_width + 10, 138)
	GUICtrlCreateInput(@StartupDir, 0, 0, $info_width, 20)
	GUICtrlCreateInput(@WindowsDir, 0, 20, $info_width, 20)
	GUICtrlCreateInput(@SystemDir, 0, 20, $info_width, 20)
	GUICtrlCreateInput(@DesktopDir, 0, 20, $info_width, 20)
	GUICtrlCreateInput(@MyDocumentsDir, 0, 20, $info_width, 20)
	GUICtrlCreateInput(@ProgramFilesDir, 0, 20, $info_width, 20)
	GUICtrlCreateInput(@StartMenuDir, 0, 20, $info_width, 20)
	GUICtrlCreateInput(@TempDir, 0, 20, $info_width, 20)
	GUICtrlCreateInput(@DesktopWidth & "px x " & @DesktopHeight & "px " & _
						@DesktopDepth & "bit [" & @DesktopRefresh & "Hz]", 0, 20, $info_width, 20)
	local $input_date = GUICtrlCreateInput(@Year & "-" & @Mon & "-" & @Mday, 0, 20, $info_width, 20)
	local $input_time = GUICtrlCreateInput(@Hour & ":" & @Min & ":" & @Sec, 0, 20, $info_width, 20)
	local $input_uptime = GUICtrlCreateInput(GetUptime(), 0, 20, $info_width, 20)

	local $input_ini = GUICtrlCreateInput($ini_path, 0, 20, $info_width, 20)

	for $i = $input_username To $input_ini
		GUICtrlSetResizing($i, $GUI_DOCKALL+$GUI_DOCKRIGHT)
	next

	for $i = $inp_computername To $input_ini
		GUICtrlSetFont($i, 8.5, 400, 0, "Consolas", 5)
	next

	for $i = $input_drive_label To $input_freespace
		GUICtrlSetResizing($i, $GUI_DOCKALL)
	next

	$sysinfo_app = $app_name
	$sysinfo_gui = $gui_sysinfo
	$sysinfo_x = $si_x
	$sysinfo_y = $si_y
	$sysinfo_w = $si_w
	$sysinfo_h = $si_h
	$sysinfo_free = $free
	$sysinfo_current_drive = $current_drive
	$sysinfo_label_env = $label_env
	$sysinfo_combo = $combo_info_drives
	$sysinfo_first_a = $computername
	$sysinfo_last_a = $ip
	$sysinfo_first_b = $startupdir
	$sysinfo_last_b = $myini
	$sysinfo_in_time = $input_time
	$sysinfo_in_date = $input_date
	$sysinfo_in_freemem = $input_freemem
	$sysinfo_in_uptime = $input_uptime
	$sysinfo_in_drive_label = $input_drive_label
	$sysinfo_in_totalspace = $input_totalspace
	$sysinfo_in_freespace = $input_freespace
	$sysinfo_last_sec = @Sec
	$sysinfo_link = false
	$sysinfo_open = true
	GUISetOnEvent($GUI_EVENT_CLOSE, "SysInfoCloseEvent", $gui_sysinfo)
	GUICtrlSetOnEvent($label_env, "SysInfoEnvEvent")
	GUICtrlSetOnEvent($combo_info_drives, "SysInfoDriveEvent")
	for $i = $computername to $ip
		GUICtrlSetOnEvent($i, "SysInfoFocusEvent")
	next
	for $i = $startupdir to $myini
		GUICtrlSetOnEvent($i, "SysInfoFocusEvent")
	next

	GUISetState()

	if $modeless then
		AutoItSetOption("GUIOnEventMode", $last_event_mode)
		AutoItSetOption("GUICoordMode", $last_coord_mode)
		return $gui_sysinfo
	endif

	while $sysinfo_open
		SysInfoRefresh($warning_color)

		local $msg = GUIGetMsg()

		switch $msg
			case $label_env
				SysInfoEnvClicked()

			case $gui_event_close
				SysInfoClose()

			case $combo_info_drives
				SysInfoDriveChanged()

			case $computername to $ip
				SysInfoFocusClicked($msg, 20)

			case $startupdir to $myini
				SysInfoFocusClicked($msg, 22)
		endswitch

		SysInfoLinkHover()

		Sleep(50)
	wend
	AutoItSetOption("GUIOnEventMode", $last_event_mode)
	AutoItSetOption("GUICoordMode", $last_coord_mode)
	return true
endfunc




;
; About()
;
; A generic About Box for corz apps, after KeyBind's excellent DoAboutBox().
; Icon, texts, links, debug log button and runtime readout all come from params.
;
; $app_name		the app name, e.g. "CorzSpaZio".
; $app_version	the version string, e.g. "1.4.2.8".
; $app_blurb		a short description (use @LF for line breaks).
; $app_url		home page, opened by the Okay button.
; $pic_file		image to show (gif/bmp/jpg/png) or icon source (exe/ico/dll).
; $build_name		optional codename, shown after the version.
; $since_year		first year for the copyright line.
; $debug_level	truthy to show the "debug log" button.
; $debug_log		file the "debug log" button opens.
; $launch_time	app start time ("YYYY/MM/DD HH:MM:SS") for the runtime readout, "" to skip it.
; $show_runtime	default for the runtime readout toggle.
;
func About($app_name, $app_version, $app_blurb, $app_url, $pic_file, $build_name = "", $since_year = "2000", $debug_level = 0, $debug_log = "", $launch_time = "", $show_runtime = $ON)

	debug("About() [" & $app_name & "]   ------------------------------------------------>", @ScriptLineNumber, 3)

	local $event_mode = AutoItSetOption("GUIOnEventMode", 1)
	local $coord_mode = AutoItSetOption("GUICoordMode", 0)

	local $aw = 372
	local $ah = 169
	$about_app = $app_name
	$about_url = $app_url
	$about_log = $debug_log
	$about_launch = $launch_time
	$about_show_runtime = $show_runtime
	$about_gui = GUICreate(" About " & $app_name & ". ", $aw, $ah, -1, @DesktopHeight / 4, $WS_CAPTION, $WS_EX_TOPMOST)
	GUISetFont(8.5, 400, 0, "Consolas", $about_gui, 5)
	GUISetOnEvent($GUI_EVENT_CLOSE, "AboutBoxClose", $about_gui)

	if $debug_level and $debug_log <> "" then
		GUISetCoord($aw - 75, 5)
		GUICtrlCreateButton("debug log", 0, 0, 70, 20, BitOr($WS_TABSTOP, $BS_FLAT))
		GUICtrlSetOnEvent(-1, "AboutBoxDebug")
	endif

	GUISetCoord(13, 6)

	local $pic_ext = StringLower(StringTrimLeft($pic_file, StringInStr($pic_file, ".", 0, -1)))

	if $pic_ext = "gif" or $pic_ext = "bmp" or $pic_ext = "jpg" or $pic_ext = "jpeg" or $pic_ext = "png" then
		GUICtrlCreatePic($pic_file, 0, 0, 48, 48)
	else
		GUICtrlCreateIcon($pic_file, 0, 0, 0, 48, 48)
		; GUICtrlCreateIcon only manages 32px, swap in the high-res icon.
		local $hires_icon = _WinAPI_ShellExtractIcon($pic_file, 0, 48, 48)

		if $hires_icon then
			_WinAPI_DestroyIcon(GUICtrlSendMsg(-1, $STM_SETIMAGE, $IMAGE_ICON, $hires_icon))
			$about_hicon = $hires_icon
		endif
	endif

	GUICtrlSetTip(-1, " Click me to toggle the elapsed runtime readout.  ")
	GUICtrlSetOnEvent(-1, "AboutBoxIcon")

	local $ver_text = $app_name & " v" & $app_version
	if $build_name <> "" then $ver_text &= " '" & $build_name & "'"
	GUICtrlCreateLabel($ver_text, 59, 14)
	GUICtrlCreateLabel(Chr(169) & " corz.org " & $since_year & "-" & @Year, 0, 15)

	GUISetCoord(15, 60)
	GUICtrlCreateLabel($app_blurb, 0, 0, $aw - 25, $ah - 85)

	GUISetCoord(15, $ah - 25)
	$about_time_ctrl = 0

	if $launch_time <> "" then
		$about_show_runtime = IniReadCheckBoxValue($ini_path, $app_name, "show_runtime", $show_runtime)
		$about_time_ctrl = GUICtrlCreateLabel("", 0, 0, 140, 25)
		if $about_show_runtime = $OFF then GUICtrlSetState(-1, $GUI_HIDE)
	endif

	GUISetCoord($aw - 170, $ah - 25)
	GUICtrlCreateButton("Nah", 0, 0, 75, 20, BitOr($WS_TABSTOP, $BS_FLAT))
	GUICtrlSetOnEvent(-1, "AboutBoxClose")
	GUICtrlSetTip(-1, " Click here to close the About Box.  ")

	local $ok_button = GUICtrlCreateButton("Okay", 85, 0, 75, 20, BitOr($WS_TABSTOP, $BS_FLAT))
	GUICtrlSetOnEvent(-1, "AboutBoxVisit")
	GUICtrlSetTip(-1, " Click here to close the About Box and visit the " & $app_name & " web site.  ")

	local $vbit = "x86"
	if @AutoItX64 = 1 then $vbit = "x64"
	GUISetCoord($aw - 26, 29)
	local $lab_v = GUICtrlCreateLabel($vbit, 0, 0, 18, 12)
	GUICtrlSetOnEvent(-1, "AboutBoxSysInfo")
	GUICtrlSetTip(-1, " Click here for system info. ")

	GUICtrlSetState($ok_button, $GUI_FOCUS)
	GUISetState(@SW_SHOW, $about_gui)

	$about_is_open = true
	$about_last_sec = @Sec
	local $link = false

	while $about_is_open
		Sleep(50)

		if $about_time_ctrl and @Sec <> $about_last_sec then
			GUICtrlSetData($about_time_ctrl, "Runtime: " & SecondsToDHMS(_DateDiff("s", $about_launch, _NowCalcDate() & " " & _NowTime()), false))
			$about_last_sec = @Sec
		endif

		; Visual indication of clickable link.
		local $mouse = GUIGetCursorInfo($about_gui)

		if $mouse[4] <> $link then
			if $mouse[4] = $lab_v and $link = false then
				$link = $mouse[4]
				GUICtrlSetColor($lab_v, 0x008DFF)
				GUISetCursor(0, 1, $about_gui)
			else
				GUICtrlSetColor($lab_v, default)
				GUISetCursor()
				$link = false
			endif
		endif
	wend

	GUIDelete($about_gui)
	AutoItSetOption("GUIOnEventMode", $event_mode)
	AutoItSetOption("GUICoordMode", $coord_mode)

	if $about_hicon then
		_WinAPI_DestroyIcon($about_hicon)
		$about_hicon = 0
	endif

	$about_gui = ""
	$about_is_open = ""
	$about_time_ctrl = ""
	$about_last_sec = ""
	$about_launch = ""
	$about_show_runtime = ""
	$about_app = ""
	$about_url = ""
	$about_log = ""
endfunc




func AboutBoxClose()
	$about_is_open = false
endfunc




func AboutBoxVisit()
	VisitUrl($about_url)
	AboutBoxClose()
endfunc




; Toggles the About box runtime display on and off and saves the pref. Used by
; the About dialog icon click.
;
func AboutBoxIcon()
	if not $about_time_ctrl then return

	if $about_show_runtime = $ON then
		$about_show_runtime = $OFF
		GUICtrlSetState($about_time_ctrl, $GUI_HIDE)
	else
		$about_show_runtime = $ON
		GUICtrlSetState($about_time_ctrl, $GUI_SHOW)
	endif

	IniWriteCheckBoxValue($ini_path, $about_app, "show_runtime", $about_show_runtime)
endfunc




func AboutBoxDebug()
	OpenSomething($about_log, true)
	AboutBoxClose()
endfunc




; Shows the system info box modally above the About dialog. Used by the About
; dialog button.
;
func AboutBoxSysInfo()
	GUISetState(@SW_DISABLE, $about_gui)
	SysInfoBox($about_app)
	GUISetState(@SW_ENABLE, $about_gui)
endfunc




; GUI readout of the System Environment Variables.
;
func DisplayEnvVars()

	local $PID = Run(@ComSpec & " /c set", @SystemDir, @SW_HIDE, $STDOUT_CHILD)
	local $env_vars

	while true
		$env_vars &= StdoutRead($PID)
		if @Error then exitloop
	wend

	$env_vars = StringStripWS($env_vars, $STR_STRIP_ENDS)

	DisplayText($env_vars, "Environment Variables", 700, 600)
endfunc




; Simple GUI to display some text for the user.
;
; Perhaps a readme, or license agreement.
; With an option to copy the text to the ClipBoard.
; $suspend names a no-arg func returning true when it paused input;
; $resume names its no-arg restore, run only then; nesting stacks
; because only the dialog that paused anything resumes it.
; $resume_failed_msg shows when $resume reports false, empty stays silent.
;
#Au3Stripper_Ignore_Funcs=DisplayText
func DisplayText($text, $title="For Reading.", $width=650, $height=$width, $inipath=$ini_path, $sectionname=$app_name, $suspend="", $resume="", $resume_failed_msg="")

	$text = UnifyCRLF($text, @CRLF)
	local $last_event_mode = AutoItSetOption("GUIOnEventMode", 0)
	local $last_coord_mode = AutoItSetOption("GUICoordMode", 0)

	; local $height = $width
	local $GUI_styles = BitOR($WS_CLIPSIBLINGS, $WS_CAPTION, $WS_SYSMENU, $WS_SIZEBOX)
	local $edit_styles = BitOr($ES_WANTRETURN, $WS_VSCROLL, $WS_HSCROLL, $ES_AUTOHSCROLL, $ES_MULTILINE, $WS_TABSTOP)

	local $prefname = "display_txt_" & CleanPrefName($title)
	local $dt_x = WindowPositionCoord(IniRead($inipath, $sectionname, $prefname & "_x", -1), "x")
	local $dt_y = WindowPositionCoord(IniRead($inipath, $sectionname, $prefname & "_y", -1), "y")
	local $dt_w = Int(IniRead($inipath, $sectionname, $prefname & "_w", $width))
	local $dt_h = Int(IniRead($inipath, $sectionname, $prefname & "_h", $height))
	if $dt_w <= 0 then $dt_w = $width
	if $dt_h <= 0 then $dt_h = $height

	local $GUI_txt_display = GUICreate($title, $dt_w, $dt_h, $dt_x, $dt_y, $GUI_styles, $WS_EX_TOPMOST)
	local $edit_env = GUICtrlCreateEdit($text, 5, 5, $dt_w-10, $dt_h-40, $edit_styles)

	local $butt_copy = GUICtrlCreateButton("Copy To ClipBoard", $dt_w-155, $dt_h-35, 105, 25)
	local $butt_done = GUICtrlCreateButton("OK", 110, 0, 35, 25)

	GUICtrlSetResizing($edit_env, $GUI_DOCKBORDERS)
	GUICtrlSetResizing($butt_copy, $GUI_DOCKSTATEBAR+$GUI_DOCKWIDTH+$GUI_DOCKRIGHT)
	GUICtrlSetResizing($butt_done, $GUI_DOCKSTATEBAR+$GUI_DOCKWIDTH+$GUI_DOCKRIGHT)

	ControlFocus($GUI_txt_display, "", $edit_env)
	Send("{Right}")

	GUISetState(@SW_SHOW, $GUI_txt_display)

	local $suspended = false
	#Au3Stripper_Off
	if $suspend <> "" then $suspended = Call($suspend)
	#Au3Stripper_On

	while true
		switch GUIGetMsg()
			case $butt_done, $gui_event_close
				exitloop

			case $butt_copy
				ClipPut($text)
				DisplayTooltipMessage("Data Successfully Copied to the ClipBoard", 3000, "Success!", true)
		endswitch

		Sleep(25)
	wend

	if $suspended then
		local $resumed = true
		#Au3Stripper_Off
		if $resume <> "" then $resumed = Call($resume)
		#Au3Stripper_On
		if not $resumed and $resume_failed_msg <> "" then MsgBox($MB_ICONWARNING+$MB_TOPMOST, $app_name, $resume_failed_msg)
	endif

	local $size_array = WinGetPos($GUI_txt_display)

	if IsArray($size_array) then
		IniWrite($inipath, $sectionname, $prefname & "_x", WindowPositionCoord($size_array[0], "x", true, $size_array))
		IniWrite($inipath, $sectionname, $prefname & "_y", WindowPositionCoord($size_array[1], "y", true, $size_array))
	endif

	local $client_size = WinGetClientSize($GUI_txt_display)
	if IsArray($client_size) then
		IniWrite($inipath, $sectionname, $prefname & "_w", $client_size[0])
		IniWrite($inipath, $sectionname, $prefname & "_h", $client_size[1])
	endif

	GUIDelete($GUI_txt_display)
	AutoItSetOption("GUIOnEventMode", $last_event_mode)
	AutoItSetOption("GUICoordMode", $last_coord_mode)

	return true
endfunc




; Linear search through a 1D string array returning the index of match or false
func FindInStringArray(byref $arr, $val)
	if not IsArray($arr) then return SetError(1, 0, false)
	local $max = UBound($arr) - 1
	local $i

	for $i = 1 to $max
		if $val = $arr[$i] then return $i
	next

	return false
endfunc




; Counts line breaks in a file by reading decoded-text chunks and tallying
; each break sequence. Returns the break total, so a lone "a" gives 0 and
; "a\nb\n" gives 2. Detects encoding across the whole file, which covers
; ANSI, UTF-8 and UTF-16 in either byte order, with or without a BOM.
;
func CountFileLines($file, $mb = 100)

	local $handle = OpenFileHandle($file, BitOr($FO_READ, $FO_FULLFILE_DETECT))
	if $handle = -1 then return SetError(1, 0, 0)
	local $lines = 0, $chunk, $eof
	local $trailing_cr = false

	select
		case $mb < 50
			$mb = 1

		case $mb < 100
			$mb = 2

		case $mb > 499
			$mb = 8

		case else
			$mb = 4
	endselect

	local const $chunk_bytes = $mb * 1024 * 1024

	do
		$chunk = FileRead($handle, $chunk_bytes)
		$eof = (@extended <> $chunk_bytes)
		if $trailing_cr and StringLeft($chunk, 1) = @LF then $lines -= 1
		StringRegExpReplace($chunk, "\R", "")
		$lines += @extended
		$trailing_cr = StringRight($chunk, 1) = @CR
		if $user_quit then return "quit"
	until $eof

	FileClose($handle)
	return $lines
endfunc




; Opens a file handle with specified mode flags, creates parent dirs if needed
func OpenFileHandle($my_path, $my_flag = 0)
	$my_path = PrependLongPathPrefix($my_path)
	if Bitand($my_flag, 8) then _LFN_DirCreate(StringLeft($my_path, StringInStr($my_path, "\", 0, -1) - 1))
	local $x = FileOpen($my_path, $my_flag)
	return SetError(@Error, @extended, $x)
endfunc




; ; Removes trailing delimiter string from a variable passed by reference
; func TrimTrailingDelimiter(byref $text, $delim = "\")
	; local $delim_len = StringLen($delim)
	; if StringRight($text, $delim_len) = $delim then $text = StringTrimRight($text, $delim_len)
; endfunc




; Reads lines from file looking for a pattern; returns matching line number or array of [lineNum, text] pairs if accumulating
func SearchFileForPattern($file_path, $pattern, $return_array = false, $all_matches = false)
	local $found
	local $line
	local $line_num = 0
	local $file = OpenFileHandle($file_path, 0)
	if $all_matches then $return_array = true

	if $return_array then
		local $count = 1
		local $results[$count][2]
	endif

	while true
		if $user_quit then return "quit"
		$found = false
		$line = FileReadLine($file)
		if @Error then exitloop
		$line_num += 1

		if StringInStr($line, $pattern) then
			$found = true

			if $return_array then
				$results[$count - 1][0] = $line_num
				$results[$count - 1][1] = $line
			endif

			if $all_matches then
				$count += 1
				redim $results[$count][2]
			else
				exitloop
			endif
		endif
	wend

	FileClose($file)

	if $return_array then
		if $found then return $results
	endif

	if $found then
		return $line_num
	endif

	return false
endfunc




;
; ResolveAndNormalizePath()

; Absolute, canonical form of a file path with "." and ".." resolved.
; Reads $my_path plus $base_dir for ordinary relative paths, returns
; the resolved path or the joined path when the Windows lookup fails.
; Absolute, UNC, root-relative and drive-relative paths bypass $base_dir
; and resolve as Windows resolves them. SendMailMessage() attachment
; paths arrive here with the default base.
;
func ResolveAndNormalizePath($my_path, $base_dir = @WorkingDir)
	if not $my_path or $my_path = "." then return $base_dir
	if $base_dir = default then $base_dir = @WorkingDir
	local $norm_path = StringReplace($my_path, "/", "\")
	local $combined = $norm_path
	if not (StringLeft($norm_path, 2) = "\\" or StringRight(StringLeft($norm_path, 2), 1) = ":" or StringLeft($norm_path, 1) = "\") then
		$combined = $base_dir & "\" & $norm_path
	endif
	local $full_path = _WinAPI_GetFullPathName($combined)
	if @error or not $full_path then return $combined
	return $full_path
endfunc




; ===============================================================================================================================
; File/path helpers - generic routines, moved here from checksumShared.au3 and LFN.au3 (not checksum-specific).
; checksumShared.au3 and LFN.au3 use these from here now; do not re-add them there.
; ===============================================================================================================================

; --- moved from checksumShared.au3 ---
; Opens a FindFirstFile search handle on an expanded path pattern
func OpenFileSearchHandle($my_file)
	$my_file = PrependLongPathPrefix($my_file)
	local $x = FileFindFirstFile($my_file)
	return SetError(@Error, @extended, $x)
endfunc




; --- moved from checksumShared.au3 ---
; Copies file content byte-by-byte using 1MB chunked read/write, then preserves attributes and timestamps on destination
func CopyFileByHandle($src, $dest, $overwrite = 0)
	if not IsFileEmpty($src) then return SetError(1, 1, 0)
	local $src_handle = OpenFileHandle($src, 16)
	if $src_handle = -1 then return SetError(1, 1, 0)
	local $dest_handle = OpenFileHandle($dest, 16 + 2 - $overwrite)

	if $dest_handle = -1 then
		_LFN_FileClose($src_handle)
		return SetError(1, 2, 0)
	endif

	local $chunk_size = 1 * 1024 * 1024
	local $data
	local $done = false

	while not $done
		$data = _LFN_FileRead($src_handle, $chunk_size)

		switch @Error
			case 1
				_LFN_FileClose($src_handle)
				_LFN_FileClose($dest_handle)
				return SetError(1, 3, 0)

			case -1
				$done = true
		endswitch

		if not FileWrite($dest_handle, $data) then
			_LFN_FileClose($src_handle)
			_LFN_FileClose($dest_handle)
			return SetError(1, 4, 0)
		endif
	wend

	_LFN_FileClose($src_handle)
	_LFN_FileClose($dest_handle)
	_LFN_FileSetAttrib($dest, _LFN_FileGetAttrib($src))
	_LFN_FileSetTime($dest, _LFN_FileGetTime($src, 0, 1), 0)
	if GetPathType($dest) and @extended = 1 and CompareFileMetadata($src, $dest) then return 1
	return SetError(1, 5, 0)
endfunc




; --- moved from checksumShared.au3 ---
; Returns true if file size is 0 or first byte read returns error; otherwise false
; like __LFN_FileReadable(), but uses OpenFileHandle() to create parents, if required.
func IsFileEmpty($my_path)
	if _LFN_FileGetSize($my_path) = 0 then return true
	local $my_handle = OpenFileHandle($my_path, 16)
	_LFN_FileRead($my_handle, 1)
	local $my_error = @Error
	_LFN_FileClose($my_handle)
	return ($my_error = 0)
endfunc




; --- moved from checksumShared.au3 ---
; Tests if path exists, returning extended info: 0=nothing, 1=file, 2=folder, 3=both (file+dir)
func GetPathType($file_path)
	local $exists = 0
	local $type = 0
	if PathHasWildcard($file_path) then $type = 2
	$file_path = PrependLongPathPrefix($file_path)
	local $handle = FileFindFirstFile($file_path)

	if $handle = -1 and not FileExists($file_path) then
		$exists = 0
	else
		$exists = 1

		if $type = 0 then
			if StringInStr(FileGetAttrib($file_path), "D") then
				$type = 3
			else
				$type = 1
			endif
		endif
	endif

	FileClose($handle)
	return SetExtended($type, $exists)
endfunc




; --- moved from checksumShared.au3 ---
; Expands wildcard file search pattern into arrays of matching files and directories
func ExpandFileSearchPattern($pattern, $recurse = false)

	local $results[1] = [0]
	local $sub_results[1] = [0]
	local $file_count = 0
	$pattern = PrependLongPathPrefix($pattern)
	local $dir = ""
	local $mask = StringTrimLeft($pattern, StringInStr($pattern, "\", 0, -1))

	if not StringInStr($mask, "*") and not StringInStr($mask, "?") and StringInStr(FileGetAttrib($pattern), "D") then
		$dir = $pattern
		$mask = "*"
		$pattern = $pattern & "\" & $mask
	else
		$dir = StringLeft($pattern, StringInStr($pattern, "\", 0, -1) - 1)
	endif

	if not GetPathType($dir) then return SetExtended($file_count, $results)
	local $handle, $item, $i
	$handle = FileFindFirstFile($pattern)

	while true
		$item = FileFindNextFile($handle)
		if @Error then exitloop

		if not StringInStr(FileGetAttrib($dir & "\" & $item), "D") then
			EnsureArrayCapacity($results)
			$results[$results[0]] = $dir & "\" & $item
			$file_count += 1
		endif
	wend

	FileClose($handle)
	$handle = FileFindFirstFile($dir & "\*")

	while true
		$item = FileFindNextFile($handle)
		if @Error then exitloop

		if StringInStr(FileGetAttrib($dir & "\" & $item), "D") then
			redim $results[$results[0] + 2]
			$results[0] += 1
			$results[$results[0]] = $dir & "\" & $item & "\"

			if $recurse then
				$sub_results = ExpandFileSearchPattern($dir & "\" & $item & "\" & $mask, $recurse)
				$file_count += @extended

				if $sub_results[0] > 0 then
					redim $results[$results[0] + 1 + $sub_results[0]]

					for $i = 1 to $sub_results[0]
						$results[$results[0] + $i] = $sub_results[$i]
					next

					$results[0] += $sub_results[0]
				endif
			endif
		endif
	wend

	FileClose($handle)
	return SetExtended($file_count, $results)
endfunc




; --- moved from checksumShared.au3 ---
; Compares two files by checking modification time difference (<3s tolerance) and equal file size
func CompareFileMetadata($file_path_1, $file_path_2)
	local $time_1 = _LFN_FileGetTime($file_path_1, 0, 1)
	if @Error then return SetError(1, 0, 0)
	local $time_2 = _LFN_FileGetTime($file_path_2, 0, 1)
	if @Error then return SetError(1, 0, 0)
	if Abs(Number($time_1) - Number($time_2)) > 2 then return SetExtended(1, 0)
	local $file_size_1 = _LFN_FileGetSize($file_path_1)
	if @Error then return SetError(2, 0, 0)
	local $file_size_2 = _LFN_FileGetSize($file_path_2)
	if @Error then return SetError(2, 0, 0)
	if $file_size_1 <> $file_size_2 then return SetExtended(2, 0)
	return 1
endfunc




; --- moved from checksumShared.au3 ---
; Resizes an array to 1.5x if near capacity, then increments element count for append
func EnsureArrayCapacity(byref $some_array)

	if $some_array[0] >= UBound($some_array) - 1 then
		local $new_limit = Ceiling((UBound($some_array) + 1) * 1.5)
		redim $some_array[$new_limit]
	endif

	$some_array[0] += 1
endfunc




; --- moved from checksumShared.au3 ---
; Returns true if path's filename portion contains * or ? characters
func PathHasWildcard($file_path)
	local $my_filename = GetFileNameFromPath($file_path)
	if (StringInStr($my_filename, "*") or StringInStr($my_filename, "?")) then return true
	return false
endfunc




; --- moved from checksumShared.au3 ---
; Extracts the basename (last component after final backslash) from a full path
func GetFileNameFromPath($file_path)
	local $stripped_path = StripLongPathPrefix($file_path)
	return StringTrimLeft($stripped_path, StringInStr($stripped_path, "\", 0, -1))
endfunc




; --- moved from checksumShared.au3 ---
; Converts paths to \\?\ format for long-path support, handling UNC normalization and drive-root detection
func PrependLongPathPrefix($file_path)
	if (StringLeft($file_path, 4) = "\\?\") then $file_path = StripLongPathPrefix($file_path)
	if (StringLen($file_path) = 2 and StringRight($file_path, 1) = ":") or (StringLen($file_path) = 3 and StringRight($file_path, 2) = ":\") then return $file_path
	if StringLeft($file_path, 2) <> "\\" and StringMid($file_path, 2, 1) <> ":" then return $file_path

	if StringLeft($file_path, 2) = "\\" then
		return SetExtended(2, "\\?\UNC\" & StringTrimLeft($file_path, 2))
	else
		return SetExtended(1, "\\?\" & $file_path)
	endif
endfunc




; --- moved from checksumShared.au3 ---
; Simpler version that just prepends \\?\ or \\?\UNC\ prefix without full path normalization
func ConvertToLongPathFormat($cli_input_path)
	if StringLeft($cli_input_path, 3) = "\\?" then return $cli_input_path

	if StringLeft($cli_input_path, 2) = "\\" then
		return SetExtended(2, "\\?\UNC\" & StringTrimLeft($cli_input_path, 2))
	else
		return SetExtended(1, "\\?\" & $cli_input_path)
	endif
endfunc




; --- moved from checksumShared.au3 ---
; Reverses \\?\ or \\?\UNC\ prefixes back to normal paths (opposite of PrependLongPathPrefix)
func StripLongPathPrefix($file_path)
	if (StringLeft($file_path, 8) = "\\?\UNC\") then return SetExtended(2, "\\" & StringTrimLeft($file_path, 8))
	if (StringLeft($file_path, 4) = "\\?\") then return SetExtended(1, StringTrimLeft($file_path, 4))
	return $file_path
endfunc




; --- moved from checksumShared.au3 ---
; Returns the parent directory path with long-path prefix prepended
func GetParentDirectoryWithPrefix($file_path)
	local $stripped_path = StripLongPathPrefix($file_path)
	return PrependLongPathPrefix(StringLeft($stripped_path, StringInStr($stripped_path, "\", 0, -1) - 1))
endfunc




; --- moved from checksumShared.au3 ---
; Converts wildcard/glob patterns (* ? ; separated) to case-insensitive AutoIt regex pattern strings
func GlobToRegexPattern($my_pattern)
	if StringRegExp($my_pattern, "\\|/|:|\<|\>|\|") then return false
	$my_pattern = StringReplace($my_pattern, ",", ";")
	if $my_pattern = "*.*" or $my_pattern = "*" then return "(?i)^(.*?)\z"
	$my_pattern = StringReplace(StringStripWS(StringRegExpReplace($my_pattern, "\s*;\s*", ";"), $STR_STRIP_ENDS), ";", "|")
	$my_pattern = StringReplace(StringReplace(StringRegExpReplace($my_pattern, "[][$^.{}()+\-]", "\\$0"), "?", "."), "*", ".*?")
	return "(?i)^(" & $my_pattern & ")\z"
endfunc




; --- moved from checksumShared.au3 ---
; Read a checkbox value from the ini
func IniReadCheckBox($file, $section, $key, $default)
	local $val = IniRead($file, $section, $key, $default)
	return returnCheckBoxValue($val)
endfunc




; --- moved from checksumShared.au3 ---
; Convert ini true/false strings to $ON/$OFF
func returnCheckBoxValue($user_true_false)
	; Boolean TRUTH: $BOOL_TRUE_WORDS/$BOOL_FALSE_WORDS (via BoolWord()).
	; Historical quirk, preserved: boolean false passes through untouched.
	if IsBool($user_true_false) and not $user_true_false then return $user_true_false
	if $user_true_false = $OFF then return $OFF
	if $user_true_false = $ON then return $ON
	local $clean = StringLower(StringStripWS($user_true_false, 3))
	if $clean = "1" then return $ON
	if $clean = "0" then return $OFF
	if BoolWord($clean, true) then return $ON
	if BoolWord($clean, false) then return $OFF
	return $user_true_false
endfunc




; --- moved from LFN.au3 ---
; #INTERNAL_USE_ONLY# ===========================================================================================================
;__LFN_DllOpen
;__LFN_FileReadable
;__LFN_FilesExist
;__LFN_FilesListToArray
;__LFN_FilesSimilar
;__LFN_FileWritable
;__LFN_ReDim
;__LFN_ReDim2D
;__LFN_Target_IsExistingFile
;__LFN_Target_IsExistingFolder
;__LFN_Target_IsMask
;__LFN_Target_LastElement_Get
;__LFN_Target_LastElement_Trim
;__LFN_Target_RemoveTrailingBackslash
;__LFN_Target_SetUnicodePrefix
;__LFN_Target_UnSetUnicodePrefix
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_DllOpen
; Description ..: Opens "kernel32.dll" unless already opened.
; Syntax.....: __LFN_DllOpen()
; Parameters ..: none
; Return values .: Success - Returns a handle to "kernel32.dll"
;                  Failure - Returns -1 and sets @Error to 1
; Author ....: orbs
; Modified....:
; Remarks ....:
; Related ....:
; Dependencies .:
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func __LFN_DllOpen()
    Local Static $hDLL
    If $hDLL < 1 Then $hDLL = DllOpen('kernel32.dll')
    If $hDLL < 1 Then Return SetError(1, 0, -1)
    Return $hDLL
EndFunc   ;==>__LFN_DllOpen

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_FilesExist
; Description ..: Checks if the target exists, and if so, also checks its type (single file, multiple files, or folder).
; Syntax.....: __LFN_FilesExist($sTarget)
; Parameters ..: $sTarget - Full path to check (wildcards supported).
; Return values .: Success - Returns 1 if the target exists, and sets @extended:
;                    0 - Target does not exist (therefore can not determine if it is a file or a folder)
;                    1 - Target is a single file
;                    2 - Target is multiple files
;                    3 - Target is a folder
;                  Failure - Returns 0
; Author ....: orbs
; Modified ...:
; Remarks ....: If the target is a mask (i.e. contains wildcards):
;                   - For a success return, it is sufficient that at least one of the files matching the mask exists.
;                   - It is always considered as "multiple files" (@extended=2), even if only a single match exists.
;                  @Error is not used.
; Related ....:
; Dependencies .:
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func __LFN_FilesExist($sTarget)
    Local $nResult = 0
    Local $nExtended = 0
    If __LFN_Target_IsMask($sTarget) Then $nExtended = 2 ; multiple files
    $sTarget = __LFN_Target_SetUnicodePrefix($sTarget)
    Local $hSearch = FileFindFirstFile($sTarget)
    If $hSearch = -1 And Not FileExists($sTarget) Then ; not exist
        $nResult = 0
    Else ; exists
        $nResult = 1
        If $nExtended = 0 Then ; not yet determined if file or folder, but definitely not multiple files
            If StringInStr(FileGetAttrib($sTarget), 'D') Then ; folder
                $nExtended = 3
            Else ; single file
                $nExtended = 1
            EndIf
        EndIf
    EndIf

    FileClose($hSearch)
    Return SetExtended($nExtended, $nResult)
EndFunc   ;==>__LFN_FilesExist

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_FilesListToArray
; Description ..: Creates a list of files.
; Syntax.....: __LFN_FilesListToArray($sMask[, $bRecurse = False])
; Parameters ..: $sMask    - Full path and mask of files to list (wildcards supported).
;                  $bRecurse - [optional] Set to True if to recurse subdirectories
; Return values .: Success - Returns a 1-D 1-based array of filesystem entries (files & subfolders) with unicode prefix:
;                    [0] = number of entries
;                    [1] = 1st entry
;                    [2] = 2nd entry
;                    [N] = Nth entry
;                  The count of files only is returned in @extended.
;                  Failure - Returns a 1-D array of one element [0] = 0, and sets @Error to 1
; Author ....: orbs
; Modified ...:
; Remarks ....: If the parameter is a folder, the files therein will be listed just as if you had used the * mask.
;                  Directories are listed with suffix backslash ("\").
; Related ....:
; Dependencies .:
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func __LFN_FilesListToArray($sMask, $bRecurse = False)
    Local $aResult[1] = [0]
    Local $aTemp[1] = [0]
    Local $nExtended = 0
    $sMask = __LFN_Target_SetUnicodePrefix($sMask)
    Local $sPath = ''
    Local $sMaskOnly = __LFN_Target_LastElement_Get($sMask)

    If Not StringInStr($sMaskOnly, '*') And Not StringInStr($sMaskOnly, '?') And StringInStr(FileGetAttrib($sMask), 'D') Then
        $sPath = $sMask
        $sMaskOnly = '*'
        $sMask = $sMask & '\' & $sMaskOnly
    Else
        $sPath = __LFN_Target_LastElement_Trim($sMask)
    EndIf

    If Not __LFN_FilesExist($sPath) Then Return SetExtended($nExtended, $aResult)
    Local $hSearch, $sFile, $i
    ; files
    $hSearch = FileFindFirstFile($sMask)

    While True
        $sFile = FileFindNextFile($hSearch)
        If @Error Then ExitLoop

        If StringInStr(FileGetAttrib($sPath & '\' & $sFile), 'D') Then
            __LFN_ReDim($aResult, $sPath & '\' & $sFile & '\')
        Else
            __LFN_ReDim($aResult, $sPath & '\' & $sFile)
            $nExtended += 1
        EndIf
    WEnd

    FileClose($hSearch)
    ; folders
    If $bRecurse Then
        $hSearch = FileFindFirstFile($sPath & '\*')

        While True
            $sFile = FileFindNextFile($hSearch)
            If @Error Then ExitLoop

            If StringInStr(FileGetAttrib($sPath & '\' & $sFile), 'D') Then
                $aTemp = __LFN_FilesListToArray($sPath & '\' & $sFile & '\' & $sMaskOnly, $bRecurse)
                $nExtended += @extended

                If $aTemp[0] > 0 Then
                    ReDim $aResult[$aResult[0] + 1 + $aTemp[0]]

                    For $i = 1 To $aTemp[0]
                        $aResult[$aResult[0] + $i] = $aTemp[$i]
                    Next

                    $aResult[0] += $aTemp[0]
                EndIf
            EndIf
        WEnd

        FileClose($hSearch)
    EndIf

    Return SetExtended($nExtended, $aResult)
EndFunc   ;==>__LFN_FilesListToArray

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_ReDim
; Description ..: Applies ReDim on a 1-D array in an efficient way.
; Syntax.....: __LFN_ReDim(ByRef $aArray[, $xData=''])
; Parameters ..: $aArray - The array to ReDim
;                  $xData  - [optional] Data to add to the array
; Return values .: Returns the array after ReDim
; Author ....: guinness
; Modified....: orbs
; Remarks ....: The returned array probably has empty cells at the end. the value at element [0] is the count of used cells,
;                  not the count of total cells. To work with the returned array, use element [0] to determine the last used cell
;                  instead of UBound.
;                  To truncate the array to used size: ReDim $aArray[$aArray[0]+1]
; Related ....:
; Dependencies .:
; Link .....: http://www.autoitscript.com/forum/topic/129689-redim-the-most-efficient-way-so-far-when-you-have-to-resize-an-existing-array/?hl=array+2d
; Example ....: No
; ===============================================================================================================================
Func __LFN_ReDim(ByRef $aArray, $xData = '')
    Local $iNewRealSize = UBound($aArray)
    If $aArray[0] >= UBound($aArray) - 1 Then ; if used size = real size then must redim, otherwise do nothing
        $iNewRealSize = Ceiling((UBound($aArray) + 1) * 1.5)
        ReDim $aArray[$iNewRealSize]
    EndIf

    $aArray[0] += 1 ; anyway used size increased
    If $xData <> '' Then $aArray[$aArray[0]] = $xData
EndFunc   ;==>__LFN_ReDim

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_Target_IsExistingFolder
; Description ..: Checks if the target is a folder that exists.
; Syntax.....: __LFN_Target_IsExistingFolder($sTarget)
; Parameters ..: $sTarget - Full path to check.
; Return values .: True if the target is an existing folder.
;                  False if the target is a mask, a file, or does not exist.
; Author ....: orbs
; Modified ...:
; Remarks ....:
; Related ....:
; Dependencies .:
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func __LFN_Target_IsExistingFolder($sTarget)
    If __LFN_FilesExist($sTarget) And @extended = 3 Then Return True
    Return False
EndFunc   ;==>__LFN_Target_IsExistingFolder

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_Target_IsMask
; Description ..: Checks if the target is multiple files (includes wildcards).
; Syntax.....: __LFN_Target_IsMask($sTarget)
; Parameters ..: $sTarget - Full path to check (wildcards supported).
; Return values .: True if the target is multiple files.
;                  False if the target is a single file.
; Author ....: orbs
; Modified ...:
; Remarks ....: If the target is a folder then it is not multiple files, therefore False is returned.
;                  The target does not have to exist.
; Related ....:
; Dependencies .: __LFN_Target_LastElement_Get
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func __LFN_Target_IsMask($sTarget)
    Local $sLastElement = __LFN_Target_LastElement_Get($sTarget)
    If (StringInStr($sLastElement, '*') Or StringInStr($sLastElement, '?')) Then Return True
    Return False
EndFunc   ;==>__LFN_Target_IsMask

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_Target_LastElement_Get
; Description ..: Isolates the last filesystem element of a target - what's after the last backslash ("\") character.
; Syntax.....: __LFN_Target_LastElement_Get($sTarget[, $sDelimiter = '\'])
; Parameters ..: $sTarget    - Filesystem element to check (wildcards supported).
;                  $sDelimiter - Delimiter to determine the last element
; Return values .: A string of the last filesystem element.
; Author ....: orbs
; Modified ...:
; Remarks ....: $sDelimiter MUST be a single character!
;                  The target does not have to exist.
;                  The return string does not begin with the leading delimiter.
; Related ....:
; Dependencies .:
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func __LFN_Target_LastElement_Get($sTarget, $sDelimiter = '\')
    Local $sTargetUnset = __LFN_Target_UnSetUnicodePrefix($sTarget)
    Local $iPos = StringInStr($sTargetUnset, $sDelimiter, 0, -1)
    Return StringTrimLeft($sTargetUnset, $iPos)
EndFunc   ;==>__LFN_Target_LastElement_Get

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_Target_LastElement_Trim
; Description ..: Trims the last filesystem element of a target and returns what's before the last backslash ("\") character.
; Syntax.....: __LFN_Target_LastElement_Trim($sTarget[, $sDelimiter = '\'])
; Parameters ..: $sTarget    - Filesystem element to check (wildcards supported).
;                  $sDelimiter - Delimiter to determine the last element
; Return values .: A string of the target with the last filesystem element stripped from it.
; Author ....: orbs
; Modified ...:
; Remarks ....: $sDelimiter MUST be a single character!
;                  The target does not have to exist.
;                  The return string does not end with the trailing delimiter.
; Related ....:
; Dependencies .:
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func __LFN_Target_LastElement_Trim($sTarget, $sDelimiter = '\')
    Local $sTargetUnset = __LFN_Target_UnSetUnicodePrefix($sTarget)
    Local $iPos = StringInStr($sTargetUnset, $sDelimiter, 0, -1)
    Return __LFN_Target_SetUnicodePrefix(StringLeft($sTargetUnset, $iPos - 1))
EndFunc   ;==>__LFN_Target_LastElement_Trim

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_Target_SetUnicodePrefix
; Description ..: Adds the unicode prefix to a given target, unless already present or some conditios are mey - see Remarks.
; Syntax.....: __LFN_Target_SetUnicodePrefix($sTarget)
; Parameters ..: $sTarget - Path to prefix with the unicode prefix ("\\?\" or "\\?\UNC\").
; Return values .: Returns the parameter with the unicode prefix and sets @extended:
;                    1 - $sTarget is on a locally mounted volume (local drive, mapped network drive, etc.)
;                    2 - $sTarget is on a network share (UNC path)
; Author ....: orbs
; Modified....:
; Remarks ....: The unicode prefix is added only if needed. it is not added under these conditions:
;                    $sTarget already has the unicode prefix
;                    $sTarget is a drive root
;                    $sTarget is a relative path
; Related ....:
; Dependencies .:
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func __LFN_Target_SetUnicodePrefix($sTarget)
    If (StringLeft($sTarget, 4) = '\\?\') Then $sTarget = __LFN_Target_UnSetUnicodePrefix($sTarget) ; remove unicode prefix in case it's a drive root
    If (StringLen($sTarget) = 2 And StringRight($sTarget, 1) = ':') Or (StringLen($sTarget) = 3 And StringRight($sTarget, 2) = ':\') Then Return $sTarget ; $sTarget is a drive root
    If StringLeft($sTarget, 2) <> '\\' And StringMid($sTarget, 2, 1) <> ':' Then Return $sTarget ; $sTarget is a relative path
    ; before adding prefix, embody relative elements "\."
    Local $iPos, $iPosPrevBackslash, $sSubstringToReplace

    While True
        $iPos = StringInStr($sTarget, '\.')
        If $iPos = 0 Then ExitLoop
        $iPosPrevBackslash = $iPos

        Do
            $iPosPrevBackslash -= 1
        Until StringMid($sTarget, $iPosPrevBackslash, 1) = '\' Or $iPos = 0

        $sSubstringToReplace = StringMid($sTarget, $iPosPrevBackslash, $iPos - $iPosPrevBackslash + 3)
        $sTarget = StringReplace($sTarget, $sSubstringToReplace, '', 1)
    WEnd

    ; now add the unicode prefix and return
    If StringLeft($sTarget, 2) = '\\' Then
        Return SetExtended(2, '\\?\UNC\' & StringTrimLeft($sTarget, 2))
    Else
        Return SetExtended(1, '\\?\' & $sTarget)
    EndIf
EndFunc   ;==>__LFN_Target_SetUnicodePrefix

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_Target_UnSetUnicodePrefix
; Description ..: Removes the unicode prefix from a given target.
; Syntax.....: __LFN_Target_UnSetUnicodePrefix($sTarget)
; Parameters ..: $sTarget - Filesystem element to remove the unicode prefix ("\\?\" or "\\?\UNC\") from.
; Return values .: Returns the parameter without the unicode prefix and sets @extended:
;                    0 - The unicode prefix was not found.
;                    1 - $sTarget is on a locally mounted volume (local drive, mapped network drive, etc.)
;                    2 - $sTarget is on a network share (UNC path)
; Author ....: orbs
; Modified....:
; Remarks ....:
; Related ....:
; Dependencies .:
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func __LFN_Target_UnSetUnicodePrefix($sTarget)
    If (StringLeft($sTarget, 8) = '\\?\UNC\') Then Return SetExtended(2, '\\' & StringTrimLeft($sTarget, 8))
    If (StringLeft($sTarget, 4) = '\\?\') Then Return SetExtended(1, StringTrimLeft($sTarget, 4))
    Return $sTarget
EndFunc   ;==>__LFN_Target_UnSetUnicodePrefix

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_DirCreate
; Description ..: Creates a directory.
; Syntax.....: _LFN_DirCreate($sPath)
; Parameters ..: $sPath - Full path of the directory to create.
; Return values .: Success - Returns 1
;                  Failure - Returns 0, sets @Error to 1, and sets @extended to the @Error returned from DllCall
; Author ....: orbs, corz.org 2026-07-23 (fixed bug and edge cases)
; Modified ...:
; Remarks ....: This function will also create all parent directories given in $sPath if they do not already exist.
; Related ....:
; Dependencies .:
; Link .....: http://msdn.microsoft.com/en-us/library/windows/desktop/aa363855(v=vs.85).aspx
; Example ....: No
; ===============================================================================================================================
func _LFN_DirCreate($s_path)
	local $h_dll = __LFN_DllOpen()
	if @Error then return SetError(1, 0, 0)
	local $i_first_element = 7 ; assuming local drive
	local $i_nth_found = 0
	local $i_idx
	$s_path = __LFN_Target_SetUnicodePrefix($s_path)
	if @extended = 2 then; assumption is incorrect, it's a UNC path
		$i_first_element = 0

		for $i_idx = 1 to StringLen($s_path)
			if StringMid($s_path, $i_idx, 1) = "\" then
				$i_nth_found += 1

				if $i_nth_found = 6 then
					$i_first_element = $i_idx
					exitloop
				endif
			endif
		next

		if $i_first_element = 0 then return SetError(1, 0, 0)
	endif

	for $i_idx = $i_first_element to StringLen($s_path)
		if StringMid($s_path, $i_idx, 1) = "\" then
			DllCall($h_dll, "bool", "CreateDirectoryW", "wstr", StringLeft($s_path, $i_idx), "struct*", 0)
		endif
	next

	DllCall($h_dll, "bool", "CreateDirectoryW", "wstr", $s_path, "struct*", 0)
	if __LFN_Target_IsExistingFolder($s_path) then return 1
	return 0
endfunc




; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_FileClose
; Description ..: Use exactly like the native AutoIt function FileClose
; Syntax.....: _LFN_FileClose($hFile)
; ===============================================================================================================================
Func _LFN_FileClose($hFile)
    Local $result = FileClose($hFile)
    Return SetError(@Error, @extended, $result)
EndFunc   ;==>_LFN_FileClose

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_FileGetAttrib
; Description ..: Use exactly like the native AutoIt function FileGetAttrib
; Syntax.....: _LFN_FileGetAttrib($sTarget)
; ===============================================================================================================================
Func _LFN_FileGetAttrib($sTarget)
    $sTarget = __LFN_Target_SetUnicodePrefix($sTarget)
    Local $result = FileGetAttrib($sTarget)
    Return SetError(@Error, @extended, $result)
EndFunc   ;==>_LFN_FileGetAttrib

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_FileGetSize
; Description ..: Use exactly like the native AutoIt function FileGetSize
; Syntax.....: _LFN_FileGetSize($sFile)
; ===============================================================================================================================
Func _LFN_FileGetSize($sFile)
    $sFile = __LFN_Target_SetUnicodePrefix($sFile)
    Local $result = FileGetSize($sFile)
    Return SetError(@Error, @extended, $result)
EndFunc   ;==>_LFN_FileGetSize

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_FileGetTime
; Description ..: Use exactly like the native AutoIt function FileGetTime
; Syntax.....: _LFN_FileGetTime($sFile[, $nOption = 0[, $nFormat = 0]])
; ===============================================================================================================================
Func _LFN_FileGetTime($sFile, $nOption = 0, $nFormat = 0)
    $sFile = __LFN_Target_SetUnicodePrefix($sFile)
    Local $result = FileGetTime($sFile, $nOption, $nFormat)
    Return SetError(@Error, @extended, $result)
EndFunc   ;==>_LFN_FileGetTime

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_FileRead
; Description ..: Use exactly like the native AutoIt function FileRead
; Syntax.....: _LFN_FileRead($xFile[, $nCount = -1])
; ===============================================================================================================================
Func _LFN_FileRead($xFile, $nCount = -1)
    If IsString($xFile) Then $xFile = __LFN_Target_SetUnicodePrefix($xFile)
    Local $result

    If $nCount < 0 Then
        $result = FileRead($xFile)
    Else
        $result = FileRead($xFile, $nCount)
    EndIf

    Return SetError(@Error, @extended, $result)
EndFunc   ;==>_LFN_FileRead

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_FileSetAttrib
; Description ..: Sets or clears attributes of one or more files/directories.
; Syntax.....: _LFN_FileSetAttrib($sTarget, $sAttrib[, $bRecurse = False])
; Parameters ..: Target    - Full path of file(s) to set attributes for (wildcards supported).
;                  $sAttrib  - A string representation of the attributes to set or clear - see Remarks.
;                  $bRecurse - [optional] Set to True if to recurse subdirectories.
; Return values .: Success - Returns 1
;                  Failure - Returns 0 and sets @Error:
;                    1 - Error opening the kernel32 DLL.
;                    2 - The attributes parameter includes an invalid attribute - see Remarks.
;                    3 - deprecated (used to be "No files found", but this is not an error, but a legitimate result).
;                    4 - At least one file could not have its attributes changed.
; Author ....: orbs
; Modified ...:
; Remarks ....: - The attributes that can be modified with the function are + or -:
;                    "R" = READONLY
;                    "A" = ARCHIVE
;                    "S" = SYSTEM
;                    "H" = HIDDEN
;                    "N" = NORMAL
;                    "O" = OFFLINE
;                    "T" = TEMPORARY
; Related ....:
; Dependencies .:
; Link .....: http://msdn.microsoft.com/en-us/library/aa365535(v=vs.85).aspx
;                  http://msdn.microsoft.com/en-us/library/gg258117(v=vs.85).aspx
;                  http://stackoverflow.com/questions/12594403/fasm-if-file-exists-using-getfileattributes-invalid-file-attributes-value
; Example ....: No
; ===============================================================================================================================
Func _LFN_FileSetAttrib($sTarget, $sAttrib, $bRecurse = False)
    ; reversion
    If Not __LFN_Target_IsMask($sTarget) And _ ; target is a single file or folder
            StringLen($sTarget) < 260 And _ ; target is short
            Not $bRecurse Then _ ; no recurse (recurse may breach MAX_PATH limit)
            Return FileSetAttrib($sTarget, $sAttrib, $bRecurse)
    ; standard procedure
    Local $hDLL = __LFN_DllOpen()
    If @Error Then Return SetError(1, 0, 0)
    ; preparation
    Local Const $_LFN_FILE_ATTRIBUTE_ARCHIVE = 32 ;(0x20)
    Local Const $_LFN_FILE_ATTRIBUTE_COMPRESSED = 2048 ;(0x800)
    Local Const $_LFN_FILE_ATTRIBUTE_DEVICE = 64 ;(0x40)            ; not used here
    Local Const $_LFN_FILE_ATTRIBUTE_DIRECTORY = 16 ;(0x10)
    Local Const $_LFN_FILE_ATTRIBUTE_ENCRYPTED = 16384 ;(0x4000)        ; not used here
    Local Const $_LFN_FILE_ATTRIBUTE_HIDDEN = 2 ;(0x2)
    Local Const $_LFN_FILE_ATTRIBUTE_INTEGRITY_STREAM = 32768 ;(0x8000)     ; not used here
    Local Const $_LFN_FILE_ATTRIBUTE_NORMAL = 128 ;(0x80)
    Local Const $_LFN_FILE_ATTRIBUTE_NOT_CONTENT_INDEXED = 8192 ;(0x2000)       ; not used here
    Local Const $_LFN_FILE_ATTRIBUTE_NO_SCRUB_DATA = 131072 ;(0x20000)      ; not used here
    Local Const $_LFN_FILE_ATTRIBUTE_OFFLINE = 4096 ;(0x1000)
    Local Const $_LFN_FILE_ATTRIBUTE_READONLY = 1 ;(0x1)
    Local Const $_LFN_FILE_ATTRIBUTE_REPARSE_POINT = 1024 ;(0x400)      ; not used here
    Local Const $_LFN_FILE_ATTRIBUTE_SPARSE_FILE = 512 ;(0x200)     ; not used here
    Local Const $_LFN_FILE_ATTRIBUTE_SYSTEM = 4 ;(0x4)
    Local Const $_LFN_FILE_ATTRIBUTE_TEMPORARY = 256 ;(0x100)
    Local Const $_LFN_FILE_ATTRIBUTE_VIRTUAL = 65536 ;(0x10000)     ; not used here
    Local $aAttributes[18][2] = [[0, 0], _
            [$_LFN_FILE_ATTRIBUTE_ARCHIVE, 'A'], _
            [$_LFN_FILE_ATTRIBUTE_COMPRESSED, 'C'], _
            [$_LFN_FILE_ATTRIBUTE_DEVICE, ''], _
            [$_LFN_FILE_ATTRIBUTE_DIRECTORY, 'D'], _
            [$_LFN_FILE_ATTRIBUTE_ENCRYPTED, ''], _
            [$_LFN_FILE_ATTRIBUTE_HIDDEN, 'H'], _
            [$_LFN_FILE_ATTRIBUTE_INTEGRITY_STREAM, ''], _
            [$_LFN_FILE_ATTRIBUTE_NORMAL, 'N'], _
            [$_LFN_FILE_ATTRIBUTE_NOT_CONTENT_INDEXED, ''], _
            [$_LFN_FILE_ATTRIBUTE_NO_SCRUB_DATA, ''], _
            [$_LFN_FILE_ATTRIBUTE_OFFLINE, 'O'], _
            [$_LFN_FILE_ATTRIBUTE_READONLY, 'R'], _
            [$_LFN_FILE_ATTRIBUTE_REPARSE_POINT, ''], _
            [$_LFN_FILE_ATTRIBUTE_SPARSE_FILE, ''], _
            [$_LFN_FILE_ATTRIBUTE_SYSTEM, 'S'], _
            [$_LFN_FILE_ATTRIBUTE_TEMPORARY, 'T'], _
            [$_LFN_FILE_ATTRIBUTE_VIRTUAL, '']]
    Local Const $_LFN_INVALID_FILE_ATTRIBUTES = 4294967295 ;(0xFFFFFFFF, also equals -1 for unsigned DWORD)
    Local $bAttribToSet = True
    Local $nAttribToSet = 0
    Local $nAttribToClear = 0
    Local $i, $j

    For $i = 1 To StringLen($sAttrib)
        Switch StringUpper(StringMid($sAttrib, $i, 1))
            Case '+'
                $bAttribToSet = True

            Case '-'
                $bAttribToSet = False

            Case 'R', 'A', 'S', 'H', 'N', 'O', 'T'
                For $j = 1 To UBound($aAttributes) - 1
                    If $aAttributes[$j][1] = StringUpper(StringMid($sAttrib, $i, 1)) Then
                        If $bAttribToSet Then
                            $nAttribToSet = BitOR($nAttribToSet, $aAttributes[$j][0])
                        Else
                            $nAttribToClear = BitOR($nAttribToClear, $aAttributes[$j][0])
                        EndIf
                    EndIf
                Next

            Case Else
                Return SetError(2, 0, 0)
        EndSwitch
    Next

    ; main action
    Local $aFiles[2] = [1, $sTarget]
    If Not __LFN_Target_IsExistingFolder($sTarget) Or $bRecurse Then $aFiles = __LFN_FilesListToArray($sTarget, $bRecurse)
    If __LFN_Target_IsExistingFolder($sTarget) And $bRecurse Then __LFN_ReDim($aFiles, $sTarget & '\')
    Local $bOneFail = False
    Local $sOneName = ''
    Local $aRet, $nAttribToChange

    For $i = $aFiles[0] To 1 Step -1
        $sOneName = $aFiles[$i]
        If StringRight($sOneName, 1) = '\' Then $sOneName = StringTrimRight($sOneName, 1)
        $aRet = DllCall($hDLL, 'dword', 'GetFileAttributesW', 'wstr', $sOneName)

        If @Error Or $aRet[0] = $_LFN_INVALID_FILE_ATTRIBUTES Then
            $bOneFail = True
            ContinueLoop
        EndIf

        $nAttribToChange = $aRet[0]
        $nAttribToChange = BitOR($nAttribToChange, $nAttribToSet)
        $nAttribToChange = BitAND($nAttribToChange, BitNOT($nAttribToClear))
        If $nAttribToChange = $aRet[0] Then ContinueLoop ; no need to change
        $aRet = DllCall($hDLL, 'int', 'SetFileAttributesW', 'wstr', $sOneName, 'dword', $nAttribToChange)

        If @Error Or $aRet[0] = 0 Then
            $bOneFail = True
            ContinueLoop
        EndIf
    Next

    If $bOneFail Then Return SetError(4, 0, 0)
    Return 1
EndFunc   ;==>_LFN_FileSetAttrib

; --- moved from LFN.au3 ---
; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_FileSetTime
; Description ..: Sets the timestamp of one of more files.
; Syntax.....: _LFN_FileSetTime($sTarget, $sTimestamp[, $nType = 0[, $bRecurse = False]])
; Parameters ..: Target      - Full path of file(s) to set timestamp for (wildcards supported).
;                  $sTimestamp - A string which denotes the new time to set.
;                    format: "YYYYMMDDhhmmss" (Year, Month, Day, hour (24hr clock), minute, second).
;                    If an empty string is passed, then the current time is used.
;                  $nType      - [optional] Timestamp to change:
;                    $FT_MODIFIED (0) = Last modified (default)
;                    $FT_CREATED (1)  = Created
;                    $FT_ACCESSED (2) = Last accessed
;                    Constants are defined in FileConstants.au3
;                  $bRecurse   - [optional] Set to True if to recurse subdirectories.
; Return values .: Success - Returns 1
;                  Failure - Returns 0 and sets @Error to 1
; Author ....: orbs
; Modified ...:
; Remarks ....: Using a date earlier than 1980-01-01 will have no effect.
;                  Trying to change a timestamp on read-only files will result in an error.
;                  This function fails in the following conditions:
;                  - Invalid timestamp: string is not all integer or not exactly 14 characters in length
; Related ....:
; Dependencies .:
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func _LFN_FileSetTime($sTarget, $sTimestamp, $nType = 0, $bRecurse = False)
    ; reversion
    If Not __LFN_Target_IsMask($sTarget) And _ ; target is a single file or folder
            StringLen($sTarget) < 260 And _  ; target is short
            Not $bRecurse Then _ ; no recurse (recurse may breach MAX_PATH limit)
            Return FileSetTime($sTarget, $sTimestamp, $nType, $bRecurse)
    ; standard procedure
    Local $hDLL = __LFN_DllOpen()
    If @Error Then Return SetError(1, 0, 0)
    ; preparation
    If Not __LFN_FilesExist($sTarget) Then Return SetError(1, 0, 0)
    If Not StringIsInt($sTimestamp) Or StringLen($sTimestamp) <> 14 Then Return SetError(1, 0, 0)
    ; - parse parameter
    Local $sYYYY = StringLeft($sTimestamp, 4)
    Local $sMM = StringMid($sTimestamp, 5, 2)
    Local $sDD = StringMid($sTimestamp, 7, 2)
    Local $sHH = StringMid($sTimestamp, 9, 2)
    Local $sMN = StringMid($sTimestamp, 11, 2)
    Local $sSS = StringMid($sTimestamp, 13, 2)
    ; - enclode time to "System" time format    ; = _Date_Time_EncodeSystemTime
    Local Const $_LFN_tagSYSTEMTIME = 'struct;word Year;word Month;word Dow;word Day;word Hour;word Minute;word Second;word MSeconds;endstruct'
    Local $tSystemTime_File = DllStructCreate($_LFN_tagSYSTEMTIME)
    DllStructSetData($tSystemTime_File, 'Month', Number($sMM))
    DllStructSetData($tSystemTime_File, 'Day', Number($sDD))
    DllStructSetData($tSystemTime_File, 'Year', Number($sYYYY))
    DllStructSetData($tSystemTime_File, 'Hour', Number($sHH))
    DllStructSetData($tSystemTime_File, 'Minute', Number($sMN))
    DllStructSetData($tSystemTime_File, 'Second', Number($sSS))
    DllStructSetData($tSystemTime_File, 'MSeconds', 0)
    ; - convert "System" time format to "UTC System" time format    ; = _Date_Time_TzSpecificLocalTimeToSystemTime
    Local $aRet
    Local $tUTC = DllStructCreate($_LFN_tagSYSTEMTIME)
    $aRet = DllCall("kernel32.dll", "ptr", "TzSpecificLocalTimeToSystemTime", "ptr", 0, "ptr", DllStructGetPtr($tSystemTime_File), "struct*", $tUTC)
    If @Error Then Return SetError(1, 0, 0)
    ; - convert "System" time format to "File" time format  ; = _Date_Time_SystemTimeToFileTime
    Local Const $_LFN_tagFILETIME = 'struct;dword Lo;dword Hi;endstruct'
    Local $tFileTime_File = DllStructCreate($_LFN_tagFILETIME)
    $aRet = DllCall($hDLL, 'bool', 'SystemTimeToFileTime', 'struct*', $tUTC, 'struct*', $tFileTime_File)
    If @Error Then Return SetError(1, 0, 0)
    ; - decide which timestamp to change
    Local $pCreated = 0
    Local $pAccessed = 0
    Local $pModified = 0

    Switch $nType
        Case 1 ; "Created"
            $pCreated = DllStructGetPtr($tFileTime_File)

        Case 2 ; "Accessed"
            $pAccessed = DllStructGetPtr($tFileTime_File)

        Case Else ; "Modified"
            $pModified = DllStructGetPtr($tFileTime_File)
    EndSwitch

    ; main action
    Local $aFiles = __LFN_FilesListToArray($sTarget, $bRecurse)
    If @extended = 0 Then Return SetError(1, 0, 0) ; no files found
    Local $hFile
    Local $bOneFail = False

    For $i = $aFiles[0] To 1 Step -1
        If StringRight($aFiles[$i], 1) = '\' Then ContinueLoop ; it's a subfolder
        ; _WinAPI_CreateFile (does not equal FileOpen!)
        $aRet = DllCall($hDLL, 'handle', 'CreateFileW', 'wstr', $aFiles[$i], 'dword', 0x40000000, 'dword', 0, 'ptr', 0, 'dword', 3, 'dword', 0, 'ptr', 0)
        $hFile = $aRet[0]
        ; finally..
        $aRet = DllCall($hDLL, 'bool', 'SetFileTime', 'handle', $hFile, 'ptr', $pCreated, 'ptr', $pAccessed, 'ptr', $pModified)

        If $aRet[0] = 0 Then
            $bOneFail = True
        EndIf

        ;_WinAPI_CloseHandle (does not equal FileClose!)
        $aRet = DllCall($hDLL, 'bool', 'CloseHandle', 'handle', $hFile)
    Next

    If $bOneFail Then Return SetError(1, 0, 0)
    Return 1
EndFunc   ;==>_LFN_FileSetTime

; --- moved from LFN.au3 (missed in first pass) ---

; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_FileExists
; Description ..: Use exactly like the native AutoIt function FileExists
; Syntax.....: _LFN_FileExists($sFile)
; ===============================================================================================================================
Func _LFN_FileExists($sFile)
    $sFile = __LFN_Target_SetUnicodePrefix($sFile)
    Local $result = FileExists($sFile)
    Return SetError(@Error, @extended, $result)
EndFunc   ;==>_LFN_FileExists

; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_FileWrite
; Description ..: Use exactly like the native AutoIt function FileWrite
; Syntax.....: _LFN_FileWrite($xFile, $xData)
; ===============================================================================================================================
Func _LFN_FileWrite($xFile, $xData)
    If IsString($xFile) Then $xFile = __LFN_Target_SetUnicodePrefix($xFile)
    Local $result = FileWrite($xFile, $xData)
    Return SetError(@Error, @extended, $result)
EndFunc   ;==>_LFN_FileWrite

; #FUNCTION# ====================================================================================================================
; Name .....: _LFN_FileWriteLine
; Description ..: Use exactly like the native AutoIt function FileWriteLine
; Syntax.....: _LFN_FileWriteLine($xFile, $xData)
; ===============================================================================================================================
Func _LFN_FileWriteLine($xFile, $xData)
    If IsString($xFile) Then $xFile = __LFN_Target_SetUnicodePrefix($xFile)
    Local $result = FileWriteLine($xFile, $xData)
    Return SetError(@Error, @extended, $result)
EndFunc   ;==>_LFN_FileWriteLine

; #FUNCTION# ====================================================================================================================
; Name .....: __LFN_Target_RemoveTrailingBackslash
; Description ..: Strips all trailing backslash characters ("\") from the end of the given target path.
; Syntax.....: __LFN_Target_RemoveTrailingBackslash($sTarget)
; Parameters ..: $sTarget - Target path to remove trailing backslash characters from (wildcards supported).
; Return values .: A string of the target path without trailing backslash.
;                  @extended holds the number of backslash characters removed.
; Author ....: orbs
; Modified ...:
; Remarks ....: The target does not have to exist.
; Related ....:
; Dependencies .:
; Link .....:
; Example ....: No
; ===============================================================================================================================
Func __LFN_Target_RemoveTrailingBackslash($sTarget)
    Local $nBackslashedRemoved = 0

    While StringRight($sTarget, 1) = '\'
        $sTarget = StringTrimRight($sTarget, 1)
        $nBackslashedRemoved += 1
    WEnd

    Return SetExtended($nBackslashedRemoved, $sTarget)
EndFunc   ;==>__LFN_Target_RemoveTrailingBackslash

; Moved from Languages.au3: translation lookup is needed by cel itself (SysInfoBox) ---

;
; _T()
; Main translate function.

; Supply an English string.
; Returns the string in the current language.
;
func _T($source_text, $token_name_1="", $token_value_1="", $token_name_2="", $token_value_2="", $token_name_3="", $token_value_3="")

    debug("_T() ---> source_text:     =>" & $source_text & "<=" , @ScriptLineNumber, 11)

    local $translated_text = $source_text
    local $lookup_key = $source_text

	; Host-provided map (see LoadLanguage in Languages.au3); fetched by name so
	; apps that don't use translations don't need the global declared. It evals to "" when unused.
	local $translation_map = Eval("translation_dictionary")

	if IsMap($translation_map) and MapExists($translation_map, $lookup_key) then
		$translated_text = String($translation_map[$lookup_key])
    else
        ; Try matching against unescaped @LF if file parser converted \n on load
        $lookup_key = StringReplace($source_text, "\n", @LF)

		if IsMap($translation_map) and MapExists($translation_map, $lookup_key) then
			$translated_text = String($translation_map[$lookup_key])
        else
            ; Try matching against @CRLF if file parser normalized line endings
            $lookup_key = StringReplace($source_text, "\n", @CRLF)

			if IsMap($translation_map) and MapExists($translation_map, $lookup_key) then
				$translated_text = String($translation_map[$lookup_key])
            endif
        endif
    endif

    $translated_text = StringReplace(StringReplace($translated_text, "{{", ""), "}}", "")

    if $token_name_1 <> "" then $translated_text = StringReplace($translated_text, $token_name_1, $token_value_1)
    if $token_name_2 <> "" then $translated_text = StringReplace($translated_text, $token_name_2, $token_value_2)
    if $token_name_3 <> "" then $translated_text = StringReplace($translated_text, $token_name_3, $token_value_3)

    debug("_T() ---> translated_text: =>" & $translated_text & "<=" , @ScriptLineNumber, 11)
    return $translated_text
endfunc




;
; _L()

; LineFeed recovery macro.
;
; Converts strings (multi-line text with \n linebreaks, as found in language.ini
; files) for use in MsgBox, system tray, etc., simply converting \n to @LF.
;
func _L($string_with_breaks)
	return StringReplace($string_with_breaks, "\n", @LF)
endfunc



