#AutoIt3Wrapper_Res_Fileversion=2.5.7.3
global const $VERSION = "2.5.7.3"
global $special_build = "Deep Sea Creatures"

#cs

	ffe - FFmpeg front-end for Windows

	https://www.google.com/search?q=ffmpeg


		*** BEFORE COMPILING ***

		You will want to edit this file.
		Please see the compile options at the foot of this program.

		Also search for "::dev::" in the code.


About:

	FFmpeg, by Fabrice Bellard, et al., is a quite incredible multimedia
	converter (and much more), capable of converting a vast number of input and
	output media formats, and depending on which binary you use, supports either
	a HUGE number of control parameters, or a REALLY HUGE number of control
	parameters.

	ffe is a simple yet powerful Windows® front-end for FFmpeg, designed for
	rapid testing of its various multimedia conversion parameters, enabling you
	to save lots of slightly different versions of a file very, very quickly; in
	other words, "find the best settings". It can then go on to perform the
	final job, of course, and a whole lot more.

	ffe uniquely uses MATOF technology to automatically update output file names
	to match your encoding parameters; you can tweak-and-go without worrying
	about obliterating your previous tests.

	While converting, the console output from FFmpeg can be viewed live inside
	ffe, and when complete, the entire process log is available for
	viewing/searching.

	ffe supports batch operation, automatic concatenation, infinitely
	customizable presets and customizable parameter buttons, pre- and post-job
	(and post-file) shell commands, dynamic @tokens, Media Info Reporting,
	Windows Batch Script Output, floating drop-window, command-line control and
	a host of other handy features and functions.

	More info here:

		https://corz.org/windows/software/ffe/


	ffe version info here..

		https://corz.org/machine/Windows/Software/ffe/Source/Itstory.txt?view


To use:

	Drop ffe.exe next to ffmpeg.exe (the FFmpeg binary).

	Run ffe.exe

	That's it.

	If you run ffe somewhere else, it will ask you to locate FFmpeg before you
	begin work.

	See inside ffe.ini and the current itstory (above) for LOTS of notes & tricks.



Bugs:




2do:

	Search for "2do" inside the code.


  2do Maybe..

	*	Grab post-file exit codes and (if waiting)
		(optionally) only process next file on success (0)

	*	Auto Parameter Increment testing.

			Use a button (next to outputfile?) to set a "sequence".

				<parameter to target> = <sequence>

					<sequence> can be a range, e.g. 1-10,1	(step 1)
						or 1-10,2 (step 2)

					or a list: 1,3,5,6,8,9,10

			button/manually in extra parameters..

					crf=[[20,21,22,24,25,27]]
					crf=[[20-30,2]]


	*	Watch Mode		(use Windows API directly for this)

				_WinAPI_FindFirstChangeNotification()

		Automatically encode to current preset ("go") all files dropped in X folder.

		Add done files to a $known_files array and/or moving originals when done
		moving is better or else clear array after X days, to prevent long-term
		memory issues for instances running for months, processing millions of files.

		If no move-to folder specified, create a "DONE" folder in the working dir.

      !!! Easier to delegate this to a KeyBind Sentinel


Notes..

	The program architecture; to use the term loosely; is fairly linear.
	As these things (GUIs) go, one or two functions becomes three, and
	so on. On the bright side, it should be pretty clear how to hack in
	new stuff.

	If you are compiling this yourself, you need to use "AutoIt Wrapper"
	to add the extra icons. You will also need to use AT LEAST version
	1.9.3 of AutoIt Wrapper for the paths to work correctly. You can
	download it here..

		https://www.autoitscript.com/autoit3/scite/downloads.shtml

	Grab a ready-made binary (with source) here..

		https://corz.org/machine/Windows/Dev/


#ce

#include <Constants.au3>
#include <GuiConstants.au3>
#include <WinAPIConstants.au3>
#include <WinAPISysWin.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <GuiButton.au3>
#include <Date.au3>
#include <Misc.au3>
#include <WinAPIFiles.au3>
#include <InetConstants.au3>
#include <GuiDateTimePicker.au3>
#include <GuiToolTip.au3>
#include <Array.au3>
#include <gdiplus.au3>

#include <WinAPIShellEx.au3>
#include <File.au3>
#include <GuiMenu.au3>

; Bite the bullet..!
#include "Includes\corzShared.au3"

; Fun with animated GIF drop windows..
;
; Of course this is sheer madness, a moving drop target!! lol
; BUT, if you want a dancing girl or throbbing arrow or whatever, on your
; desktop go right ahead. Enjoy your insanity!
;
; Of course you will need trancexx's lovely GIFAnimation.au3 script. Included.
;
; global Const $AC_SRC_ALPHA = 0x011
global Const $AC_SRC_ALPHA = 1
#include "Includes\GIFAnimation.au3"
global $hGIF
global $enable_animated_gif = true
; This gets set on image load, to use GIF routines for gifs..
global $gif_method = false
;
; While this started out as a bit of fun, I have since discovered a few animated
; gifs that work really well, with gentle visual indicators. I've spruced up the
; gif code a bit, too. I'll leave it in for the release.


global const $EXIT_PRESET			= "FFE-EXIT-SETTINGS"
global const $PRESET_BACKUP_STRING	= "--backup--"


AutoItSetOption("GUIOnEventMode", 1)
AutoItSetOption("TrayMenuMode", 11)
AutoItSetOption("TrayOnEventMode", 1)
AutoItSetOption("GUICoordMode", 1) ; NEVER AGAIN!!!	(getting there now, see MakeGUI())
AutoItSetOption("GUIEventOptions", 1)


; Init vars..

global $my_name = "ffe"
$app_name = $my_name
$str_enabled = "enabled"
$str_disabled = "disabled"
$ini_path = $my_name & ".ini"
$data_dir = @AppDataDir & "\corz\" & $my_name

global $me_app
global $my_title = " ffe.. FFmpeg front-end"
global $abort_batch = false
global $got_helps = ""
; Will become the FFmpeg process PID..
global $ffmpeg = 0
global $my_url = "https://corz.org/windows/software/ffe/"
global $versioncheck_url = "https://corz.org/inc/versions.php?app=ffe"
global $download_url = "https://corz.org/windows/software/ffe/#section-Download"

global const $NAME_SETTINGS = "main settings"
global const $NAME_BUTTONS = "custom buttons"
global const $NAME_PRESETS = "presets"
global const $NAME_VIDEO_MAPPINGS = "mappings-video"
global const $NAME_AUDIO_MAPPINGS = "mappings-audio"

global $not_presets
global const $NOT_PRESETS_LIST = $my_name & "," & $NAME_BUTTONS & "," & $NAME_VIDEO_MAPPINGS & "," & $NAME_AUDIO_MAPPINGS & "," & $EXIT_PRESET


; For find in output..
#include "Includes\EditFind.au3"


; Enables you to see icons and such without compiling.
; Alter the second $me_app to match the place where you keep ffe.exe..
if @Compiled then
	$me_app = @ScriptFullPath
else
	;::dev::..
	; Enter the path to your own local binary..
	$me_app = "C:\Program Files\corz\ffe\ffe.exe"
endif

; Set in corzShared.au3..
$debug_level = 0
$debug_log = $data_dir & "\ffe_debug.log"

; 0 = no limit, or a number (in MB). Set in ini prefs.
$max_log_size = 0

; Quick pre-check for installed users, prevents spurious debugging output bugging you..
if FileExists($data_dir & "\" & $ini_path) then
	$debug_level = Int(IniRead($data_dir & "\" & $ini_path, $my_name, "debug_level", $debug_level))
endif
if FileExists($debug_log) then FileDelete($debug_log)


; Memory is cheap! (ok, WAS cheap!)
global $inputfile, $old_inputfile, $extra_args, $v_codec, $a_codec, $resize_preset, $args, $short_args, $msgs, $count_ints
global $installed_ini, $matof_string, $old_matof, $no_video, $no_audio
; Raw user/preset template, last rendered preview, and current undecorated path.
; Generated names must never become the template for the next update.
global $output_template = "", $last_outputfile = "", $output_basefile = ""
global $creating_args = false, $output_edit_pending = false
global $launch_preset, $user_inputfile, $user_outputfile, $enable_custom_buttons
global $find_count = 0, $switches, $go, $do_gen=false, $do_quit=false, $do_shutdown=false
global $button_delim, $am_enable_custom_buttons, $am_button_notes_to_console
global $tray_abort_batch, $tray_toggle_drop_window, $tray_toggle_start_minimized, $tray_toggle_delayed_start
global $tray_toggle_fluid_image_menu, $tray_toggle_auto_copy_images, $tray_choose_image_folder
global $ctxt_toggle_fluid_image_menu, $ctxt_toggle_auto_copy_images, $ctxt_choose_image_folder
global $tray_toggle_retain_recent_files, $tray_about_ffmpeg
global $now_time, $on_top_counter, $clean_comments, $warn_control
global $delete_to_recycle_bin, $am_delete_to_recycle_bin, $always_warn_on_delete, $am_always_warn_on_delete

global $ffeGUI, $GUI_DropWindow, $GUI_DropWindowResizer, $batch_output_dir, $inp_inputfile
global $lab_inputfile, $inp_outputfile, $lab_outputfile, $ini_outputfile, $butt_wipe, $inp_input_params

global $combo_presets, $ctxt_combo_sort
global $x_param

; Prefs where restart is required..
global $sort_presets_list, $sort_presets_list_orig
global $sort_presets_list_texts = "&Sort Presets	(Restart"
global $allow_console_tooltip, $allow_console_tooltip_orig
global $allow_console_tooltip_text = "&ToolTips over Console Output	(Restart"
global $console_wordwrap, $console_wordwrap_orig
global $console_wordwrap_text = "&Wrap Console Output	(Restart"
global $image_buttons, $image_buttons_orig
global $image_buttons_text = "&Images on (some) Buttons	(Restart"
global $do_tooltips_orig
global $do_tooltips_text = "Show &MouseOver ToolTip Help	(Restart"


global $butt_add_file_arg_to_input_params, $check_do_drop_window, $check_do_matof
global $radio_preset_replace, $check_store_filepaths, $combo_v_codec, $combo_v_bitrate, $combo_frames_per_second
global $inp_crop_x, $inp_crop_y, $inp_crop_width, $inp_crop_height, $inp_x_size, $inp_y_size, $check_concatenate
global $label_active_crop_wh, $label_active_crop_xy
global $check_run_pre_job_commands, $check_run_post_job_commands, $check_overwrite
global $check_run_ffmpeg_task, $check_run_ffplay_task, $butt_reset
global $combo_preset_resizes, $check_resize_first, $combo_a_codec, $combo_a_bitrate, $combo_target_type
global $inp_extra_args, $butt_quicktest, $butt_mediareport, $lab_help_info, $edit_in_args, $edit_console_output
global $butt_find, $butt_copy2clip, $butt_clearout, $butt_doit, $label_abort
global $set_wh, $set_xy, $set_if, $set_of, $previous_pos, $do_countdown_timer, $time_in_title
global $am_post_file_run_style, $am_post_file_capture, $am_post_file_show, $am_auto_codecs
global $am_always_on_top, $am_allow_multiple, $am_do_countdown_timer, $am_kill_ffmpeg_on_exit, $am_start_minimized, $am_pause_is_global
global $am_console_wordwrap, $am_trans, $am_reptypes, $am_image_buttons, $am_about_ffmpeg, $am_default_extension, $am_show_ffplay_output
global $am_do_tooltips, $am_time_in_title,  $am_sort_presets_list, $am_cpu, $am_drop_command, $am_launch_with_drop_command, $am_allow_output_tooltip
global $am_retain_exit_settings, $am_use_mediainfo, $am_save_reports, $am_log_each_job, $am_log_append, $am_job_log_append
global $check_quit_when_done, $check_shutdown_when_done, $am_about, $clean_outputfile_ext, $outputfile, $title_msg_string
global $am_custom_buttons_columns, $custom_buttons_array, $preset_notes, $notes_prefix
global $paused, $pause_is_global, $output_paused=false, $generate_script = false, $shifted = false, $timeout=false
global $portable = false, $delay_start_at = false, $loaded_exit_settings = false
global $current_preset = $my_name
global $ctxt_vcombo, $ctxt_acombo
global $dropwin_visible, $dropwin_trans_real, $lab_main_drop, $image_handle, $half_trans, $drop_win_state
global $hover, $hovering, $switching, $blocking
global $monitors_list[1][5]
$monitors_list[0][0] = 0

global $img_index = 1
global $drop_images[1][3] ; trayID and item text

global $made_files[1]
global $recent_files[1][2]

global $min_width = 860
global $min_height = 442
global $height_magic = 33 ; Magic!
global $maximized = $OFF, $minimized = $OFF
global $start_minimized

; App Menu Sub-Menus..
global $DropCommands[5] = ["None", "Go", "Generate", "Report", "Play"]
global $DropCommandMenuItems[UBound($DropCommands)]

global $arTransItems[10], $nTPChecked = 0

global $nCPUChecked = 0
global $arCPU[6] = ["Idle/Low", "Below Normal", "Normal", "Above Normal", "High", "Realtime (Use with caution!)"]
global $arCPUItems[UBound($arCPU)]

global $ReportTypes[7] = ["default", "compact", "csv", "flat", "ini", "json", "xml"]
global $ReportTypesMenuItems[UBound($ReportTypes)]

global $PostFileRunStyles[3] = ["Direct", "DOS", "ShellExecute"]
global $PostFileRunStylesMenuItems[UBound($PostFileRunStyles)]

global $CBMChecked, $custom_buttons[502], $CustomButtonMenuItems[502] ; Arbitrary number


; "Known" files we have probed already..
global $known_files[]
; Associative arrays in AutoIt? Hells yeah!

; We feed this list to FFmpeg for concatenation (join) jobs..
global $concat_list = @TempDir & "\ffe-concat-list.txt"


; Custom Button Grid..
; Well, we put the button grid right *here*..
global $grid_x = 448
global $grid_y = 143

; You can mess with size and spacing in your ini..
global $buttons_x_shunt, $buttons_y_shunt, $button_spacing

; ToolTips..
global $tip_icon_index

; global ToolTips we update on change (we update others, too, but differently)
global $tip_post_file, $tip_pre_job, $tip_post_job, $tip_overwrite, $tip_concatenate
global $tip_ffmpeg_task, $tip_ffplay_task, $tip_quit, $tip_shutdown, $tip_short_test


; ini prefs..
global $presets, $x, $y, $width, $height, $video_codecs, $audio_codecs, $auto_codecs
global $file_types, $video_bitrates, $audio_bitrates, $frames_per_second, $target_types
global $preset_resizes, $always_on_top, $user_trans, $log_each_job
global $job_log_location, $log_append, $job_log_append, $replace_mode, $store_filepaths
global $magic_butt_icon_index, $dropwin_butt_icon_index, $ffmpeg_task_butt_icon_index
; should not change, but /could/, so they're up here.
global $folder_icon_index, $time_icon_index

global $matof_separator, $cpu_priority, $short_test_frames, $fallback_folder, $console_output_font
global $console_output_font_size, $custom_buttons_columns, $custom_buttons_font_size
global $custom_buttons_width, $custom_buttons_height, $do_output, $button_notes_to_console
global $drop_command, $launch_with_drop_command
global $retain_exit_settings, $show_ffe_in_sorted_list, $ffmpeg_binary, $plugins_path, $ffplay_binary
global $help_texts, $help_butts, $retain_recent_files
global $GDI_dll, $allowed_image_types, $do_drop_window, $drop_win_image
global $drop_win_transparency, $drop_win_hover_transparency, $drop_win_image_folder, $fluid_image_menu, $auto_copy_images
global $pre_job_commands_file, $post_job_commands_file, $batch_commands_timeout, $run_commands_with_shell
global $post_file_command, $check_run_post_file_command
global $post_file_run_style="direct", $post_file_capture=$ON, $post_file_show=$ON


; FFprobe/MediaInfo reporting..
global $ffprobe_loc, $report_format, $save_reports, $report_directory, $report_extension
global $report_switches, $nRTChecked, $pfsChecked, $store_probe_type, $un_escape_output
global $use_mediainfo, $mediainfo_location, $mediainfo_switches, $nDCChecked

; Preset-level ffe settings..

; If we set "defaults" here, we can use GetPrefs() to reload at any time using existing values as fall-backs
global $resize_first = $OFF
global $do_matof = $ON

; ffe job buttons.
global $run_pre_job_commands = $UNSET
global $run_post_job_commands = $UNSET
global $run_post_file_command = $UNSET
global $overwrite = $UNSET
global $concatenate = $UNSET
global $quit_when_done = $UNSET
global $shutdown_when_done = $UNSET

global $default_extension = "mkv"
global $kill_ffmpeg_on_exit = $ON
; Read-only setting..
global $default_audio_extension = "aac"

; Red. You can set this in your ini.
global $warn_colour = "FF0000"


; We check the user has actually altered these. If not, we don't save to the preset..
global $altered_resize_first, $altered_do_matof, $altered_do_output

global $current_control_focus, $buttons_xy, $double_check_rclicks
global $show_ffplay_output, $ffmpeg_command, $ffplay_command, $play_command

global $too_far = false
global $right_clicking = false

; We will update the ToolTips with the current state, so set the strings now for re-use..
;
global $tristate_prejob_title = "Pre-Job Commands"
global $tristate_prejob_tip = "Before the job runs, run your specified pre-job commands batch file? " & $MSG_LF & _
								"Right-click to specify/create a pre-job commands file." & $MSG_LF & $MSG_LF & _
								"Running " & $tristate_prejob_title & " is currently: "

global $tristate_postfile_title = "Post-File Commands"
global $tristate_postfile_tip = "After each file is processed, run your specified post-file command. " & $MSG_LF & _
								"Right-click to specify a post-file command." & $MSG_LF & $MSG_LF & _
								"Running " & $tristate_postfile_title & " is currently: "

global $tristate_postjob_title = "Post-Job Commands"
global $tristate_postjob_tip = "After the job runs, run your specified post-job commands batch file? " & $MSG_LF & _
								"Right-click to specify/create a post-job commands file." & $MSG_LF & $MSG_LF & _
								"Running " & $tristate_postjob_title & " is currently: "

global $tristate_overwrite_title = "Overwrite Existing Files"
global $tristate_overwrite_tip = "Should ffe tell FFmpeg to overwrite existing files? " & $MSG_LF & $MSG_LF & _
									$tristate_overwrite_title & " is currently: "

global $tristate_concatenate_title = "Join Output Files"
global $tristate_concatenate_tip = "During batches, should ffe tell FFmpeg to join the output files together? " & $MSG_LF & $MSG_LF & _
									$tristate_concatenate_title & " is currently: "

global $tristate_quit_title = "Quit When Done"
global $tristate_quit_tip = "Should ffe quit when the job is complete? " & $MSG_LF & $MSG_LF & _
							$tristate_quit_title & " is currently: "

global $tristate_shutdown_title = "Shutdown PC When Done"
global $tristate_shutdown_tip = "Should ffe shutdown your computer when the job is complete? " & $MSG_LF & $MSG_LF & _
							$tristate_shutdown_title & " is currently: "






; Unused functions are stripped at compile-time.
; This makes for easy navigation in a good text editor.
; You can click your function list to get straight here.
;
func __________________START_HERE()
endfunc



; Command-Line Parameters..
;

$CmdLineRaw = StringStripWS($CmdLineRaw, 3)

if $CmdLine[0] then

	for $i = 1 to $CmdLine[0]
		$CmdLine[$i] = StringStripWS($CmdLine[$i], 3)
	next

	; File path supplied..
	if StringRight($CmdLineRaw, 1) <> ")" then
		$inputfile = StringStripWS($CmdLine[$CmdLine[0]], 3)
		for $i = 1 to $CmdLine[0]
			if StringStripWS($CmdLine[$i], 3) <> $inputfile then $switches &= " " & StringStripWS($CmdLine[$i], 3)
		next
	else
		$inputfile = ""
		for $i = 1 to $CmdLine[0]
			$switches &= " " & StringStripWS($CmdLine[$i], 3)
		next
	endif
endif



debug("", @ScriptLineNumber, 2);debug
debug($LOG_LF & "Begin DEBUG output for ffe at " & DateTimeString() & $LOG_LF, @ScriptLineNumber, 2);debug
debug("Command-Line Switches:  ($switches): " & $switches, @ScriptLineNumber, 3);debug
debug("Input File ($inputfile): " & $inputfile, @ScriptLineNumber, 3);debug


; Process special switches..
; $go = true : we run the job immediately
; $do_gen = true : generate a batch (.bat) file
; $do_quit = true : we run the job and quit (and don't save exit settings)

if $switches then
	$switches = StringStripWS($switches, 3)
	if StringLeft($switches, 2) = "go" then
		$launch_preset = StringTrimRight(StringMid($switches, 4, -1), 1)
		$go = true
	elseif StringLeft($switches, 8) = "generate" then
		$launch_preset =  StringTrimRight(StringMid($switches, 10, -1), 1)
		$go = true
		$do_gen = true
		$do_quit = true
	elseif StringLeft($switches, 4) = "load" then
		$launch_preset =  StringTrimRight(StringMid($switches, 6, -1), 1)
		$go = false
	elseif StringLeft($switches, 3) = "run" then
		$launch_preset = StringTrimRight(StringMid($switches, 5, -1), 1)
		$go = true
		$do_quit = true
	elseif StringLeft($switches, 4) = "quit" then
		$launch_preset = StringTrimRight(StringMid($switches, 6, -1), 1)
		$go = true
		$do_quit = true
	elseif StringLeft($switches, 8) = "shutdown" then
		$launch_preset = StringTrimRight(StringMid($switches, 10, -1), 1)
		$go = true
		$do_shutdown = true
	endif
endif

debug("$launch_preset: " & $launch_preset, @ScriptLineNumber, 3);debug

; One-time special portable install switch..
if $inputfile = "portable" then
	$installed_ini = FileInstall(".\Resources\ffe.ini", @ScriptDir & "\" & $ini_path)
	; No overwrite flag, so will fail if ffe.ini already exists.
	$inputfile = ""
endif


CheckDirWild($inputfile)
debug("Input File ($inputfile) now: " & $inputfile, @ScriptLineNumber, 3);debug


; Portable mode..
; :bug: weird dev bug - if running program from exec command in notepad++, it
; "finds" the ini inside my "Resources" folder and then goes on to create a
; portable ini next to the program.exe.
; If this happens to you during dev, let me know!
;
if FileExists($ini_path) then
	debug("ffe running in Portable Mode..", @ScriptLineNumber, 2);debug
	$portable = true
	$data_dir = @ScriptDir
	$ini_path = $data_dir & "\" & $ini_path
else
	; Regular AppData usage..
	debug("ffe running in Installed/Dev Mode..", @ScriptLineNumber, 2);debug
	if not FileExists($data_dir) then DirCreate($data_dir)
	$ini_path = $data_dir & "\" & $ini_path
	$installed_ini = FileInstall(".\Resources\ffe.ini", $ini_path)
endif

; Update ini to latest version..
if not $installed_ini then UpdateffeIniFile()




; STILL NO INI FILE!
if not FileExists($ini_path) then
	debug("Problem with ini ==> " & $ini_path, @ScriptLineNumber, 1);debug
	MsgBox(0, "No ffe.ini found!", "ffe.ini was not found and could not be created." & $MSG_LF & "ffe will now exit... ", 10)
	exit -99
endif


; We grab *one* pref here..
global $allow_multiple = IniReadCheckBoxValue($ini_path, $my_name, "allow_multiple", $OFF)

; If already running and multiple instances disallowed, pass the inputfile path to the already running instance..
if $allow_multiple = $OFF then
	_Singleton($my_name, 1)
	if @error = 183 then
		WinActivate($my_title) ; Quite why this is now instance 2, I have no idea. Instance 1 is now the presets combo! Go figure.
		if $inputfile then ControlSetText($my_title, "", "[CLASS:Edit; INSTANCE:2]", $inputfile, 1)
		debug("ffe already running. Passing file to existing ffe instance.. ", @ScriptLineNumber, 2);debug
		exit 5
	endif
endif





; OK!

GetPrefs()
SetHotKeys()
MakeGUI()
MakeTray()
SetOnTop()
MakeAppMenu()


; Load either the default settings [ffe] or some specified preset..
global $preset_loaded = LoadPreset($launch_preset, true) ; 2nd param set here only, for "INIT".
; We will find other uses for this variable!



; If ini file gets too big, or the user chose this now, clean up the comments.
if FileGetSize($ini_path) > (1024*60) then $clean_comments = $ON
CleanIniComments()



; Do it now?


; Command-line action..
if $launch_preset and $inputfile and $go then

	if $preset_loaded then DoIt()

else

	; Start where we left off..
	if $retain_exit_settings = $ON then
		if not $launch_preset and not _IsPressed(10) and InArray($presets, $EXIT_PRESET) then
			$preset_loaded = LoadPreset($EXIT_PRESET, true)
			if $preset_loaded then $loaded_exit_settings = true
			ConsoleAdd("Previous exit settings restored.", @ScriptLineNumber)
		; Hold down SHIFT during launch to disable exit settings..
		elseif _IsPressed(10) then
			$retain_exit_settings = $OFF
			IniWriteCheckBoxValue($ini_path, $my_name, "retain_exit_settings", $retain_exit_settings)
			ConsoleAdd("Retain exit settings disabled.", @ScriptLineNumber)
		endif
	endif

	; launch_with_drop_command ?
	;
	if $launch_with_drop_command = $ON and $inputfile then
		if FileExists($inputfile) then
			DoDropCommand()
		else
			ConsoleAdd("Launch with drop command aborted: " & $inputfile & " does not exist", @ScriptLineNumber)
		endif
	endif

endif





; Idle loop..

while true

	if $delay_start_at then DoIt()

	CheckMouse()

	; This is set if mouse is hovering over one of our controls..
	$hover = @extended

	; MouseOver transparency change..
	if $dropwin_visible then

		$now_time = TimerDiff ($on_top_counter)
		if Mod($now_time, 10000) < 100 then SetDropWinOnTop() ; every 10s or so

		; Mouse over drop window - provide feedback..
		if $hover and not $hovering then

			if $gif_method then
				_WinAPI_SetLayeredWindowAttributes($GUI_DropWindow, 0x345, $half_trans)
			else
				SetTransparentBitmap($GUI_DropWindow, $image_handle, $half_trans)
			endif

			; This flag indicates the mouse is inside the DropWindow.
			; If we didn't set & check for this, we'd be updating the transparency every 1/100th second.
			; Using the two variables we get two states: switch-in & switch-out
			$hovering = true

		; Mouse leaves Drop Window..
		elseif $hovering and not $hover then

			if $gif_method then
				_WinAPI_SetLayeredWindowAttributes($GUI_DropWindow, 0x345, $dropwin_trans_real)
			else
				SetTransparentBitmap($GUI_DropWindow, $image_handle, $dropwin_trans_real)
			endif
			$hovering = false

		endif
	endif

	; Close the Drop Window any time (with HideDropWindow()) and THIS opens it again, so long as $do_drop_window = $ON
	if $do_drop_window = $ON and not $dropwin_visible then ShowDropWindow()
	Sleep(100)

wend




; fin!





; Get user ini values..

func GetPrefs($current_section=$my_name)	; Specify section (for reference (see IniReads below) and later use)

	debug("", @ScriptLineNumber, 6);debug
	debug("GetPrefs($current_section)" & $current_section, @ScriptLineNumber, 4);debug

	; NOW we set the user debug level..
	$debug_level = Int(IniRead($ini_path, $my_name, "debug_level", $debug_level))
	if $debug_level > 1 then debug("***	ffe running debug level: " & $debug_level & "	***", @ScriptLineNumber, 2);debug

	debug("Dumping prefs:: ", @ScriptLineNumber, 8);debug

	$debug_log = ffeDeTokenizeString(FixPathSlashes(IniRead($ini_path, $my_name, "dump_file", $data_dir & "\ffe_debug.log")))
	debug("USER SET $debug_log: " & $debug_log, @ScriptLineNumber, 8);debug
	if not $debug_log then $debug_log = $data_dir & "\ffe_debug.log" ; $data_dir & "\ffe_debug.log"
	debug("$debug_log: " & $debug_log, @ScriptLineNumber, 8);debug

	$max_log_size = Int(IniRead($ini_path, $my_name, "max_debug_log_size", 0 ))
	debug("$max_log_size: " & $max_log_size, @ScriptLineNumber, 8);debug

	; The available sections (presets+)
	$presets = IniReadSectionNames($ini_path)
	debugPrintArray($presets, "$presets:", @ScriptLineNumber, 8);debug

	$x = Int(IniRead($ini_path, $my_name, "x", -1))
	$y = Int(IniRead($ini_path, $my_name, "y", -1))
	$width = Int(IniRead($ini_path, $my_name, "width", 864))
	if $width < $min_width then $width = $min_width
	$height = Int(IniRead($ini_path, $my_name, "height", 590))
	if $height < $min_height then $height = $min_height
	debug("Dimensions: " & "x: " & $x & " y: " & $y & " width: " & $width & " height: " & $height, @ScriptLineNumber, 8);debug


	$minimized = IniReadCheckBoxValue($ini_path, $my_name, "minimized", $OFF)
	$maximized = IniReadCheckBoxValue($ini_path, $my_name, "maximized", $OFF)
	$start_minimized = IniReadCheckBoxValue($ini_path, $my_name, "start_minimized", $OFF)
	if $start_minimized = $ON then $minimized = $ON
	if $minimized = $ON and $maximized = $ON then $maximized = $OFF
	debug("$minimized: " & Human($minimized), @ScriptLineNumber, 8);debug
	debug("$maximized: " & Human($maximized), @ScriptLineNumber, 8);debug

	$always_on_top = IniReadCheckBoxValue($ini_path, $my_name, "always_on_top", $OFF)
	debug("$always_on_top: " & Human($always_on_top), @ScriptLineNumber, 8);debug

	$user_trans = IniRead($ini_path, $my_name, "transparency", 0)
	debug("$user_trans: " & $user_trans, @ScriptLineNumber, 8);debug

	$do_output = IniReadCheckBoxValue($ini_path, $my_name, "do_output", $ON)
	debug("$do_output: " & Human($do_output), @ScriptLineNumber, 8);debug

	; Master ToolTips Switch..
	$do_tooltips = IniReadCheckBoxValue($ini_path, $my_name, "do_tooltips", $ON)
	debug("$do_tooltips: " & Human($do_tooltips), @ScriptLineNumber, 8);debug
	$do_tooltips_orig = $do_tooltips

	$allow_console_tooltip = IniReadCheckBoxValue($ini_path, $my_name, "allow_console_tooltip", $ON)
	debug("$allow_console_tooltip: " & Human($allow_console_tooltip), @ScriptLineNumber, 8);debug
	$allow_console_tooltip_orig = $allow_console_tooltip

	$tooltip_time = IniRead($ini_path, $my_name, "tooltip_time", 10000)
	debug("$tooltip_time: " & $tooltip_time, @ScriptLineNumber, 8);debug

	; ToolTip Icon:
	local $tip_icon_res = IniRead($ini_path, $my_name, "tip_icon_res", $me_app)
	if not $tip_icon_res then $tip_icon_res = $me_app
	$tip_icon_index = IniRead($ini_path, $my_name, "tip_icon_index", 0)
	if not $tip_icon_index then $tip_icon_index = 0
	$tip_icon = $me_app & "," & $tip_icon_index
	debug("$tip_icon_res,idx: " & $tip_icon_res & "," & $tip_icon_index, @ScriptLineNumber, 8);debug

	; System ToolTip Icon override..
	local $system_tip_icon = IniRead($ini_path, $my_name, "system_tip_icon", "")
	if $system_tip_icon and $system_tip_icon >= 0 and $system_tip_icon < 7 then $tip_icon = $system_tip_icon
	debug("$system_tip_icon: " & $system_tip_icon, @ScriptLineNumber, 8);debug

	; ToolTip Style..
	$tip_style = IniRead($ini_path, $my_name, "tip_style", 1)
	debug("$tip_style: " & $tip_style, @ScriptLineNumber, 8);debug

	$sort_presets_list = IniReadCheckBoxValue($ini_path, $my_name, "sort_presets_list", $ON)
	debug("$sort_presets_list: " & Human($sort_presets_list), @ScriptLineNumber, 8);debug

	; Flag set for *initial* sorting pref
	$sort_presets_list_orig = $sort_presets_list

	$show_ffe_in_sorted_list = IniReadCheckBoxValue($ini_path, $my_name, "show_ffe_in_sorted_list", $ON)
	debug("$show_ffe_in_sorted_list: " & Human($show_ffe_in_sorted_list), @ScriptLineNumber, 8);debug


	; Use images on (some) buttons?
	$image_buttons = IniReadCheckBoxValue($ini_path, $my_name, "image_buttons", $ON)
	debug("$image_buttons: " & Human($image_buttons), @ScriptLineNumber, 8);debug
	$image_buttons_orig = $image_buttons

	$replace_mode = IniReadCheckBoxValue($ini_path, $my_name, "replace_mode", $ON)
	debug("$replace_mode: " & Human($replace_mode), @ScriptLineNumber, 8);debug

	; Tristate - unset to remove control...
	$store_filepaths = IniReadCheckBoxValue($ini_path, $my_name, "store_filepaths", $OFF, true)
	debug("$store_filepaths: " & Human($store_filepaths), @ScriptLineNumber, 8);debug

	$console_wordwrap = IniReadCheckBoxValue($ini_path, $my_name, "console_wordwrap", $OFF)
	debug("$console_wordwrap: " & Human($console_wordwrap), @ScriptLineNumber, 8);debug
	$console_wordwrap_orig = $console_wordwrap

	$drop_command = IniRead($ini_path, $my_name, "drop_command", "")
	debug("$drop_command: " & $drop_command, @ScriptLineNumber, 8);debug

	$launch_with_drop_command = IniReadCheckBoxValue($ini_path, $my_name, "launch_with_drop_command", $OFF)
	debug("$launch_with_drop_command: " & Human($launch_with_drop_command), @ScriptLineNumber, 8);debug

	; Recent files list in tray menu..
	$retain_recent_files = IniReadCheckBoxValue($ini_path, $my_name, "retain_recent_files", $OFF)

	if $retain_recent_files = $ON then
		local $tmp_rfstr = IniRead($ini_path, $my_name, "recent_files", "")
		CRT($tmp_rfstr, "|") ; Shouldn't be required - ArrayJoin() does it on writing.
		if $tmp_rfstr then
			$recent_files = StringSplit($tmp_rfstr, "|")
			$recent_files = OneToTwoDArray($recent_files)
		endif
	endif
	debugPrintArray($recent_files, "$recent_files:", @ScriptLineNumber, 8);debug

	$retain_exit_settings = IniReadCheckBoxValue($ini_path, $my_name, "retain_exit_settings", $ON)
	debug("$retain_exit_settings: " & Human($retain_exit_settings), @ScriptLineNumber, 8);debug

	$do_countdown_timer = IniReadCheckBoxValue($ini_path, $my_name, "do_countdown_timer", $ON)
	debug("$do_countdown_timer: " & Human($do_countdown_timer), @ScriptLineNumber, 8);debug

	$time_in_title = IniReadCheckBoxValue($ini_path, $my_name, "time_in_title", $ON)
	debug("$time_in_title: " & Human($time_in_title), @ScriptLineNumber, 8);debug

	$enable_custom_buttons = IniReadCheckBoxValue($ini_path, $my_name, "enable_custom_buttons", $ON)
	debug("$enable_custom_buttons: " & Human($enable_custom_buttons), @ScriptLineNumber, 8);debug

	$button_delim = IniRead($ini_path, $my_name, "button_delim", "***")
	debug("$button_delim: " & $button_delim, @ScriptLineNumber, 8);debug

	; The nifty custom buttons..
	$custom_buttons_columns = IniRead($ini_path, $my_name, "custom_buttons_columns", "auto")
	debug("$custom_buttons_columns: " & $custom_buttons_columns, @ScriptLineNumber, 8);debug
	if $custom_buttons_columns = "auto" then
		$CBMChecked = 501
	else
		if $custom_buttons_columns and $custom_buttons_columns < 0 then $custom_buttons_columns = 0
		$CBMChecked = $custom_buttons_columns
	endif
	debug("$CBMChecked: " & $CBMChecked, @ScriptLineNumber, 8);debug

	$custom_buttons_width = Int(IniRead($ini_path, $my_name, "custom_buttons_width", 75))
	if $custom_buttons_width and ($custom_buttons_width < 8 or $custom_buttons_width > 150) then $custom_buttons_width = 75
	debug("$custom_buttons_width: " & $custom_buttons_width, @ScriptLineNumber, 8);debug

	$custom_buttons_height = Int(IniRead($ini_path, $my_name, "custom_buttons_height", 27))
	debug("$custom_buttons_height: " & $custom_buttons_height, @ScriptLineNumber, 8);debug

	$buttons_x_shunt = Int(IniRead($ini_path, $my_name, "buttons_x_shunt", 0))
	$buttons_y_shunt = Int(IniRead($ini_path, $my_name, "buttons_y_shunt", 11))
	$button_spacing = Int(IniRead($ini_path, $my_name, "button_spacing", 3))
	debug("$buttons_x_shunt: " & $buttons_x_shunt, @ScriptLineNumber, 8);debug
	debug("$buttons_y_shunt: " & $buttons_y_shunt, @ScriptLineNumber, 8);debug
	debug("$button_spacing: " & $button_spacing, @ScriptLineNumber, 8);debug

	$custom_buttons_font_size = Round(IniRead($ini_path, $my_name, "custom_buttons_font_size", 9), 2)
	debug("$custom_buttons_font_size: " & $custom_buttons_font_size, @ScriptLineNumber, 8);debug

	$button_notes_to_console = IniReadCheckBoxValue($ini_path, $my_name, "button_notes_to_console", $ON)
	debug("$button_notes_to_console: " & Human($button_notes_to_console), @ScriptLineNumber, 8);debug

	LoadCustomButtonData()


	$double_check_rclicks = IniReadCheckBoxValue($ini_path, $my_name, "double_check_rclicks", $ON)
	debug("$double_check_rclicks: " & Human($double_check_rclicks), @ScriptLineNumber, 8);debug

	$show_ffplay_output = IniReadCheckBoxValue($ini_path, $my_name, "show_ffplay_output", $OFF)
	$ffmpeg_command = IniRead($ini_path, $my_name, "ffmpeg_command", "-help")
	$ffplay_command = IniRead($ini_path, $my_name, "ffplay_command", "-help")

	debug("$show_ffplay_output: " & Human($show_ffplay_output), @ScriptLineNumber, 8);debug
	debug("$ffmpeg_command: " & $ffmpeg_command, @ScriptLineNumber, 8);debug
	debug("$ffplay_command: " & $ffplay_command, @ScriptLineNumber, 8);debug

	; Play Command. This is for when you right-click on the input file label.
	$play_command = IniRead($ini_path, $my_name, "play_command", "shellex")

	; Logging..
	$log_append = IniReadCheckBoxValue($ini_path, $my_name, "log_append", $OFF)
	$job_log_append = IniReadCheckBoxValue($ini_path, $my_name, "job_log_append", $OFF)
	$log_each_job = IniReadCheckBoxValue($ini_path, $my_name, "log_each_job", $ON)
	debug("$log_append: " & Human($log_append), @ScriptLineNumber, 8);debug
	debug("$job_log_append: " & Human($job_log_append), @ScriptLineNumber, 8);debug
	debug("$log_each_job: " & Human($log_each_job), @ScriptLineNumber, 8);debug


	; Log location..
	GetLogLocation()

	$job_log_location = ffeDeTokenizeString(IniRead($ini_path, $my_name, "job_log_location", "@datadir\logs"))
	debug("$job_log_location: " & $job_log_location, @ScriptLineNumber, 8);debug


	; FFmpeg binary location..
	$i = ffeDeTokenizeString(IniRead($ini_path, $my_name, "ffmpeg_binary", ""))
	if FileExists($i) then
		$ffmpeg_binary = $i
	else
		SetFFmpegBinLocation()
	endif
	debug("$ffmpeg_binary: " & $ffmpeg_binary, @ScriptLineNumber, 8);debug


	; ffprobe/mediainfo..
	GetReportingValues()


	; FFmpeg plugins..
	$plugins_path = ffeDeTokenizeString(IniRead($ini_path, $my_name, "plugins_path", ""))
	if (not $plugins_path) and FileExists($ffmpeg_binary) then
		$plugins_path = GetParent($ffmpeg_binary) & "\plugins"
		IniWrite($ini_path, $my_name, "plugins_path", ffeTokenizeString($plugins_path))
	endif
	debug("$plugins_path: " & $plugins_path, @ScriptLineNumber, 8);debug


	LoadHelpTexts()


	$not_presets = IniRead($ini_path, $my_name, "not_presets", "")
	if not $not_presets then $not_presets = $NOT_PRESETS_LIST
	debug("$not_presets: " & $not_presets, @ScriptLineNumber, 8);debug

	$not_presets = StringSplit($not_presets, ",")
	debugPrintArray($not_presets, "$not_presets:", @ScriptLineNumber, 8);debug

	; Button image indexes..
	$magic_butt_icon_index = IniRead($ini_path, $my_name, "magic_butt_icon_index", -6)
	$dropwin_butt_icon_index = IniRead($ini_path, $my_name, "dropwin_butt_icon_index", -13)
	$folder_icon_index = IniRead($ini_path, $my_name, "folder_icon_index", -5)
	$time_icon_index = IniRead($ini_path, $my_name, "time_icon_index", -11)
	$ffmpeg_task_butt_icon_index = IniRead($ini_path, $my_name, "ffmpeg_task_butt_icon_index", -11)

	debug("$magic_butt_icon_index: " & $magic_butt_icon_index, @ScriptLineNumber, 8);debug
	debug("$dropwin_butt_icon_index: " & $dropwin_butt_icon_index, @ScriptLineNumber, 8);debug
	debug("$folder_icon_index: " & $folder_icon_index, @ScriptLineNumber, 8);debug
	debug("$time_icon_index: " & $time_icon_index, @ScriptLineNumber, 8);debug


	$matof_separator = IniRead($ini_path, $my_name, "matof_separator", " ")
	; Cuz above " " don't work..
	if $matof_separator = "" then $matof_separator = " "
	debug("$matof_separator: " & $matof_separator, @ScriptLineNumber, 8);debug

	; CPU priority..
	$cpu_priority = int(IniRead($ini_path, $current_section, "cpu_priority", 2))
	if $cpu_priority < 0 or $cpu_priority > 5 then $cpu_priority = 2
	$nCPUChecked = $cpu_priority
	debug("$cpu_priority: " & $cpu_priority, @ScriptLineNumber, 8);debug


	; Drop-Downs..

	GetUserCodecs()

	$file_types = IniRead($ini_path, $my_name, "file_types", "All (*.*)|Audio Files (*.mp3;*.wav;*.ogg;*.mp2;*.wma;*.asf;*.asx;*.ape;*.shn;*.mpc;*.flac;*.tta;*.m4a;*.aif;*.aac)|Movie files (*.avi;*.mpg;*.mpeg;*.mov;*.mkv;*.ogm;*.ogv;*.mp4;*.asf;*.wmv;*.rm;*.flv;*.vob;*.webm;*.rmvb;*.nsv;*.mpe;*.3gp;*.gif)")

	$video_bitrates = IniRead($ini_path, $my_name, "video_bitrates", "||360k|512k|640k|768k|1000k|1200k|1600k|1800k|2000k|4000k|8000K|16000K|32000K|64000K")
	$audio_bitrates = IniRead($ini_path, $my_name, "audio_bitrates", "||32k|48k|56k|64k|80k|96k|112k|128k|160k|192k|256k|320k|480k")
	$frames_per_second = IniRead($ini_path, $my_name, "frames_per_second", "||12|15|20|23.976|24|25|29.97|30|50|60")

	$target_types = IniRead($ini_path, $my_name, "target_types", "||pal-vcd|dvd|ntsc-svcd|vcd|svcd|dv|dv50")
	$preset_resizes = IniRead($ini_path, $my_name, "preset_resizes", "||sqcif|qcif|cif|4cif|qqvga|qvga|vga|svga|xga|uxga|qxga|sxga|qsxga|hsxga|wvga|wxga|wsxga|wuxga|woxga|wqsxga|wquxga|whsxga|whuxga|cga|ega|hd480|hd720|hd1080")

	$console_output_font = IniRead($ini_path, $my_name, "console_output_font", "Lucida Console")
	$console_output_font_size = IniRead($ini_path, $my_name, "console_output_font_size", 9)
	debug("$console_output_font: " & $console_output_font, @ScriptLineNumber, 8);debug
	debug("$console_output_font_size: " & $console_output_font_size, @ScriptLineNumber, 8);debug

	$short_test_frames = IniRead($ini_path, $my_name, "short_test_frames", 1000)
	debug("$short_test_frames: " & $short_test_frames, @ScriptLineNumber, 8);debug

	; We will read this again, as-needed, as dynamic @tokens may change, also we can use
	; this as a fall-back, in case no fallback_folder is specified inside the preset..
	$fallback_folder = IniRead($ini_path, $current_section, "fallback_folder", "@parent")
	;$fallback_folder = ffeDeTokenizeString($fallback_folder)
	CRT($fallback_folder)
	debug("$fallback_folder: " & $fallback_folder, @ScriptLineNumber, 8);debug

	; Preset-level settings..

	$resize_first = IniReadCheckBoxValue($ini_path, $current_section, "resize_first", $resize_first)
	$do_matof = IniReadCheckBoxValue($ini_path, $current_section, "do_matof", $do_matof)
	debug("$resize_first: " & Human($resize_first), @ScriptLineNumber, 8);debug
	debug("$do_matof: " & Human($do_matof), @ScriptLineNumber, 8);debug

	; ffe job buttons..
	$run_pre_job_commands = IniReadCheckBoxValue($ini_path, $current_section, "run_pre_job_commands", $run_pre_job_commands, true)
	$run_post_job_commands = IniReadCheckBoxValue($ini_path, $current_section, "run_post_job_commands", $run_post_job_commands, true)
	debug("$run_pre_job_commands: " & Human($run_pre_job_commands), @ScriptLineNumber, 8);debug
	debug("$run_post_job_commands: " & Human($run_post_job_commands), @ScriptLineNumber, 8);debug

	LoadPostFileSettings(true)

	$batch_commands_timeout = Int(IniRead($ini_path, $current_section, "batch_commands_timeout", $batch_commands_timeout))
	debug("$batch_commands_timeout: " & $batch_commands_timeout, @ScriptLineNumber, 8);debug

	$run_commands_with_shell = IniReadCheckBoxValue($ini_path, $current_section, "run_commands_with_shell", $run_commands_with_shell)
	debug("$run_commands_with_shell: " & $run_commands_with_shell, @ScriptLineNumber, 8);debug


	$overwrite = IniReadCheckBoxValue($ini_path, $current_section, "overwrite", $overwrite, true)
	$concatenate = IniReadCheckBoxValue($ini_path, $current_section, "concatenate", $concatenate, true)
	$quit_when_done = IniReadCheckBoxValue($ini_path, $current_section, "quit_when_done", $quit_when_done, true)
	$shutdown_when_done = IniReadCheckBoxValue($ini_path, $current_section, "shutdown_when_done", $shutdown_when_done, true)

	debug("$overwrite: " & Human($overwrite), @ScriptLineNumber, 8);debug
	debug("$concatenate: " & Human($concatenate), @ScriptLineNumber, 8);debug
	debug("$quit_when_done: " & Human($quit_when_done), @ScriptLineNumber, 8);debug
	debug("$shutdown_when_done: " & Human($shutdown_when_done), @ScriptLineNumber, 8);debug

	; Read-only preset-level settings..
	$default_extension = IniRead($ini_path, $current_section, "default_extension", $default_extension)
	debug("$default_extension: " & $default_extension, @ScriptLineNumber, 8);debug
	$default_audio_extension = IniRead($ini_path, $current_section, "default_audio_extension", $default_audio_extension)
	debug("$default_audio_extension: " & $default_audio_extension, @ScriptLineNumber, 8);debug

	$kill_ffmpeg_on_exit = IniReadCheckBoxValue($ini_path, $current_section, "kill_ffmpeg_on_exit", $kill_ffmpeg_on_exit)
	debug("$kill_ffmpeg_on_exit: " & Human($kill_ffmpeg_on_exit), @ScriptLineNumber, 8);debug

	; Funky drop target..
	$do_drop_window = IniReadCheckBoxValue($ini_path, $my_name, "do_drop_window", $ON)
	debug("$do_drop_window: " & Human($do_drop_window), @ScriptLineNumber, 8);debug
	GetDropWinImage()
	GetDropWinImageFolder()

	$drop_win_transparency = IniRead($ini_path, $my_name, "drop_win_transparency", 0)
	debug("$drop_win_transparency: " & $drop_win_transparency, @ScriptLineNumber, 8);debug
	GetRealTrans()

	$drop_win_hover_transparency = IniRead($ini_path, $my_name, "drop_win_hover_transparency", -1)
	debug("$drop_win_hover_transparency: " & $drop_win_hover_transparency, @ScriptLineNumber, 8);debug


	$allowed_image_types = IniRead($ini_path, $my_name, "allowed_image_types", "bmp,png,ico,emf,wmf")
	if $allowed_image_types = "*" then $allowed_image_types = "bmp,png,ico,emf,wmf,jpg,jpeg,gif,tif,tiff"
	$allowed_image_types = "," & $allowed_image_types & ","
	$fluid_image_menu = IniReadCheckBoxValue($ini_path, $my_name, "fluid_image_menu", $OFF)
	debug("$allowed_image_types: " & $allowed_image_types, @ScriptLineNumber, 8);debug
	debug("$fluid_image_menu: " & Human($fluid_image_menu), @ScriptLineNumber, 8);debug

	$auto_copy_images = IniReadCheckBoxValue($ini_path, $my_name, "auto_copy_images", $ON)
	debug("$auto_copy_images: " & Human($auto_copy_images), @ScriptLineNumber, 8);debug

	$GDI_dll = IniRead($ini_path, $my_name, "GDI_dll", "gdiplus.dll")
	debug("$GDI_dll: " & $GDI_dll, @ScriptLineNumber, 8);debug

	; Purge the ini file of all comments..
	$clean_comments = IniReadCheckBoxValue($ini_path, $my_name, "clean_comments", $OFF)
	debug("$clean_comments: " & Human($clean_comments), @ScriptLineNumber, 8);debug

	$pause_is_global = IniReadCheckBoxValue($ini_path, $my_name, "pause_is_global", $OFF)
	debug("$pause_is_global: " & Human($pause_is_global), @ScriptLineNumber, 8);debug

	$delete_to_recycle_bin = IniReadCheckBoxValue($ini_path, $my_name, "delete_to_recycle_bin", $ON)
	debug("$delete_to_recycle_bin: " & Human($delete_to_recycle_bin), @ScriptLineNumber, 8);debug

	$always_warn_on_delete = IniReadCheckBoxValue($ini_path, $my_name, "always_warn_on_delete", $OFF)
	debug("$always_warn_on_delete: " & Human($always_warn_on_delete), @ScriptLineNumber, 8);debug

	$warn_colour = GetUserColor(IniRead($ini_path, $my_name, "warn_colour", $warn_colour))
	debug("$warn_colour: " & $warn_colour, @ScriptLineNumber, 8);debug

	$notes_prefix = IniRead($ini_path, $my_name, "notes_prefix", "\nnotes:\n")
	ConvertNewlines($notes_prefix)
	debug("$notes_prefix: " & $notes_prefix, @ScriptLineNumber, 8);debug

endfunc




; Create the main ffe GUI/Window (this only happens one time)..
;
func MakeGUI()

	debug("", @ScriptLineNumber, 6);debug
	debug("MakeGUI()..", @ScriptLineNumber, 6);debug

	; Handy measurements..
	local $tip, $ttt, $column_two = 590

	if ($width / 2) > $column_two then $column_two = ($width / 2)

	; Biting the bullet..
	AutoItSetOption("GUICoordMode", 0)

	; Create the GUI..
	$ffeGUI = GUICreate($my_title, $width, $height, $x, $y, _
		BitOr($WS_SIZEBOX, $WS_MINIMIZEBOX, $WS_MAXIMIZEBOX, $WS_CAPTION, $WS_POPUP), $WS_EX_ACCEPTFILES)
	GUISetIcon($me_app, 0)

	; Setup some GUI events..
	GUISetOnEvent($GUI_EVENT_CLOSE, "UserDoQuit")
	GUISetOnEvent($GUI_EVENT_RESIZED, "ResizeSaveXYWHPrefs")
	GUISetOnEvent($GUI_EVENT_MINIMIZE, "ToggleWindow")
	GUISetOnEvent($GUI_EVENT_MAXIMIZE, "ToggleMaximizeWindow")
	GUISetOnEvent($GUI_EVENT_RESTORE, "ToggleMaximizeWindow")
	GUISetOnEvent($GUI_EVENT_PRIMARYUP, "PrimaryUpCheckSize")
	GUISetOnEvent($GUI_EVENT_DROPPED, "GetDroppedItem")

	GUISetOnEvent($GUI_EVENT_SECONDARYDOWN, "CheckForRightClickTask")
	if $double_check_rclicks = $ON then
		GUISetOnEvent($GUI_EVENT_SECONDARYUP, "CheckForRightClickTask")
	endif

	; Catch focus passing to $inp_outputfile
	GUIRegisterMsg($WM_COMMAND, "CheckFocus")


	; Dummy controls for Keyboard Accelerators.. (App-Specific HotKeys)
	local $dummy_drop_window = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "MenuToggleDropWindow")
	local $dummy_retain_exit_settings = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "MenuRetainExitSettings")
	local $dummy_toggle_auto_codecs = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "MenuToggleAutoCodecs")
	local $dummy_toggle_matof_status = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "ClickToggleMatofStatus")
	local $dummy_select_all_text = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "CtrlASelectAllText")
	local $dummy_delayed_doit = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "DelayedDoIt")
	local $dummy_find_in_output = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "HKFindInOutput")
	local $dummy_f_find_in_output = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "HKFindInOutput")
	local $dummy_find_replace_in_output = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "HKFindReplaceInOutput")
	local $dummy_copy_output = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "CopyConsoleOutput")
	local $dummy_clear_output = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "ClearOutput")
	local $dummy_quit = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "UserDoQuit")

	local $dummy_ffplay_output_toggle = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "ToggleShowFFplayOut")

	local $dummy_set_default_extension = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "SetDefExtension")

	local $dummy_restart = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "Restart")


	; Input file input..
	GUISetCoord(10, 12)

	$lab_inputfile = GUICtrlCreateLabel("input:", 0, 0, 36)
	$ttt = "Input File(s)"
	$tip = "Enter the full path to the input file (or just drag it in). "
	GUICtrlSetTipOptional(-1, $tip & $MSG_LF & $MSG_LF & "Click here to view the source directory with the" & $MSG_LF & _
												"input file selected.", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "OpenFolderInFileSelected")


	$inp_inputfile = GUICtrlCreateInput($inputfile, 40, 0, $width-110, 18)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "UpdateOutputArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	GUICtrlSetState(-1, $GUI_DROPACCEPTED)



	; Drag-And-Drop Window Activation..
	if $image_buttons = $ON then
		$check_do_drop_window = GUICtrlCreateCheckbox("", $width-103, -1, 20, 20, BitOr($BS_AUTOCHECKBOX, $BS_PUSHLIKE, $BS_ICON))
		if @compiled then
			GUICtrlSetImage(-1,$me_app, $dropwin_butt_icon_index, 0)
		else
			GUICtrlSetImage(-1, ".\Resources\Icons\target.ico", -1, 0)
		endif
	else
		$check_do_drop_window = GUICtrlCreateCheckbox("ꙩ", $width-103, 0, 20, 20, BitOr($BS_AUTOCHECKBOX, $BS_PUSHLIKE))
	endif
	GUICtrlSetTipOptional(-1, _
		"Opens a shaped (with the right image), transparent window you can use to drop files into.     " & $MSG_LF & _
		"It behaves just like your regular input file input, files are queued up or processed with your" & $MSG_LF & _
		"current drag-and-drop command. You can also use it to set the location of your FFmpeg binary.", _
		"Floating Drop Window (F9)")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "ClickToggleDropWindow")
	GUICtrlSetState(-1, $do_drop_window)


	if $image_buttons = $ON then
		GUICtrlCreateButton("...", 24, 0, 20, 20, BitOr($WS_TABSTOP,$BS_FLAT,$BS_ICON))
		if @compiled then
			GUICtrlSetImage(-1,$me_app, $folder_icon_index, 0)
		else
			GUICtrlSetImage(-1, ".\Resources\Icons\document-outline.ico", -1, 0)
		endif
	else
		GUICtrlCreateButton("...", 24, 0, 20, 20, BitOr($WS_TABSTOP,$BS_FLAT))
	endif
	GUICtrlSetTipOptional(-1, "Browse to locate the input file." & $MSG_LF & _
								"Ctrl-click to open the folder.", $ttt)
	GUICtrlSetOnEvent(-1, "BrowseForInputFile")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))



	; Output file input!..
	GUISetCoord(10, 39)

	$ttt = "Output File(s)"

	$lab_outputfile = GUICtrlCreateLabel("output: ", 0, 0, 36)
	$tip = "Enter the full path to the output file (or better yet, drag in folder" & $MSG_LF & _
			"and let ffe work out the rest). Note: Old paths remain until you mindfully" & $MSG_LF & _
			"delete them or drag something else in. This is by design."
	GUICtrlSetTipOptional(-1, $tip & $MSG_LF & $MSG_LF & _
							"Click this label to disable output altogether, e.g. for " & $MSG_LF & _
							"creating image sequences (enter output directly into the extra" & $MSG_LF & _
							"agruments input)." & $MSG_LF & $MSG_LF & _
							"NOTE; You Must Put The Output File(s) LAST" & $MSG_LF & $MSG_LF & _
							"Shift+Click this label to open the output directory." & $MSG_LF & $MSG_LF & _
							"WARNING: " & $MSG_LF & _
							"Right-Clicking This Label DELETES The Output File.", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "ToggleOutput")



	; The actual input area for file output *phew*..
	$inp_outputfile = GUICtrlCreateInput($outputfile, 40, 0, $width-110, 18)
	GUICtrlSetTipOptional(-1, $tip & $MSG_LF & "NOTE: Editing this path disables MATOF for a single file. ", $ttt)
	GUICtrlSetOnEvent(-1, "OutputFileChanged")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	GUICtrlSetState(-1, $GUI_DROPACCEPTED)



	; Magic Auto-Transforming Output Filename [MATOF!] ..
	if $image_buttons = $ON then
		$check_do_matof = GUICtrlCreateCheckbox("", $width-103, -1, 20, 20, BitOr($BS_AUTOCHECKBOX, $BS_PUSHLIKE, $BS_ICON))
		if @compiled then
			GUICtrlSetImage(-1,$me_app, $magic_butt_icon_index, 0)
		else
			GUICtrlSetImage(-1, ".\Resources\Icons\magic-wand.ico", -1, 0)
		endif
	else
		$check_do_matof = GUICtrlCreateCheckbox("!!!", $width-103, 0, 20, 20, BitOr($BS_AUTOCHECKBOX, $BS_PUSHLIKE))
	endif
	GUICtrlSetTipOptional(-1, _
		"Magic Auto-Transforming Output Filename   (MATOF!)      (Ctrl+M)" & $MSG_LF & $MSG_LF & _
		"Check this to have the output file automatically transformed when " & $MSG_LF & _
		"you change stuff below (handy for doing lots of quick tests). " & $MSG_LF & $MSG_LF & _
		"NOTE: When you are running a batch, you cannot disable this. ", "MATOF!")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	GUICtrlSetState(-1, $do_matof)
	GUICtrlSetOnEvent(-1, "ClickToggleMatofStatus")



	; Browse for output file..
	if $image_buttons = $ON then
		GUICtrlCreateButton("...", 24, 0, 20, 20, BitOr($WS_TABSTOP,$BS_FLAT,$BS_ICON))
			if @compiled then
			GUICtrlSetImage(-1,$me_app, $folder_icon_index, 0)
		else
			GUICtrlSetImage(-1, ".\Resources\Icons\document-outline.ico", -1, 0)
		endif
	else
		GUICtrlCreateButton("...", 24, 0, 20, 20, BitOr($WS_TABSTOP,$BS_FLAT))
	endif
	GUICtrlSetTipOptional(-1, "Browse to specify the output file. " & $MSG_LF & _
								"Ctrl-click to open the folder.", $ttt)
	GUICtrlSetOnEvent(-1, "BrowseForOutputFile")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))



	debug("GUI:: Quick Tasks: ", @ScriptLineNumber, 9);debug

	; Quick Tasks...
	;

	GUISetCoord(10, 62)

	; Tip not seen for groups.. bummer :/ Hmm.. what if
	; Hey this is clever (even cleverer for combos - see below)
	; A Label for the ToolTip!
	GUICtrlCreateLabel("", 0, 0, 155, 14, 0, 0)
	; GUICtrlSetBkColor(-1, $COLOR_RED)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetTipOptional(-1, "One button for FFmpeg, another for FFplay." & $MSG_LF & _
								"Right-Click a button to edit its command.", "FFmpeg Quick Tasks..  (F11+F12)" )
	GUISetCoord(10, 62)
	GUICtrlCreateGroup("ffmpeg quick tasks.. ", 0, 0, 155, 35) ; tip not seen.. bummer :/
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))


	; Right-click these controls to edit the commands (see: CheckForRightClickTask())
	;
	$check_run_ffmpeg_task = GUICtrlCreateCheckbox("ffmpeg task", 6, 14, 70, 17, BitOr($BS_AUTOCHECKBOX, $BS_PUSHLIKE))
	GUICtrlSetFont(-1, 7.5)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	$tip_ffmpeg_task = GUICtrlSetTipOptional(-1, $MSG_LF & "Current command: " & $ffmpeg_command, "Quick FFmpeg Task  (F11)")
	GUICtrlSetOnEvent(-1, "RunFFmpegQuickTask")

	$check_run_ffplay_task = GUICtrlCreateCheckbox("ffplay task", 73, 0, 70, 17, BitOr($BS_AUTOCHECKBOX, $BS_PUSHLIKE))
	GUICtrlSetFont(-1, 7.5)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	$tip_ffplay_task = GUICtrlSetTipOptional(-1, $MSG_LF & "Current command: " & $ffplay_command, "Quick FFplay Task  (F12)" _
					& $MSG_LF & "Right-Click to set the command used.")
	GUICtrlSetOnEvent(-1, "ClickRunFFplayQuickTask")




	; ffe (tri-state) job control buttons..
	;

	GUISetCoord(170, 62)
	GUICtrlCreateLabel("", 0, 0, $column_two-178, 14, 0, 0)
	; GUICtrlSetBkColor(-1, $COLOR_RED)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetTipOptional(-1, _
		"These options are always inherited, or not, from the chosen preset. They can be Enabled, Disabled, or Unset." & $MSG_LF & _
		"Until saved to a preset, changes to these settings are volatile (however they will be retained at exit)." & $MSG_LF & _
		"Unless specifically set (on/off) in a preset, the previous setting will be in effect (usually unset).", _
		"ffe job controls (preset-level)")
	GUISetCoord(170, 62)
	GUICtrlCreateGroup("ffe job.. ", 0, 0, $column_two-178, 35) ; tip not seen.. bummer :/
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))


	$ttt = $tristate_prejob_title
	$check_run_pre_job_commands = GUICtrlCreateCheckbox(" pre-job ", 4, 13, 53, 18, BitOr($BS_AUTO3STATE,$BS_RIGHTBUTTON))
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	$tip_pre_job = GUICtrlSetTipOptional(-1, $tristate_prejob_tip & Human($run_pre_job_commands), $ttt)
	GUICtrlSetOnEvent(-1, "ClickSetPreJobState")
	GUICtrlSetState(-1, $run_pre_job_commands)


	$ttt = $tristate_postfile_title
	$check_run_post_file_command = GUICtrlCreateCheckbox(" post-file ", 57, 0, 58, 18, BitOr($BS_AUTO3STATE,$BS_RIGHTBUTTON))
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetState(-1, $run_post_file_command)
	$tip_post_file = GUICtrlSetTipOptional(-1, $tristate_postfile_tip & Human($run_post_file_command), $ttt)
	GUICtrlSetOnEvent(-1, "ClickSetPostFileState")


	$ttt = $tristate_postjob_title
	$check_run_post_job_commands = GUICtrlCreateCheckbox(" post-job ", 62, 0, 58, 18, BitOr($BS_AUTO3STATE,$BS_RIGHTBUTTON))
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	$tip_post_job = GUICtrlSetTipOptional(-1, $tristate_postjob_tip & Human($run_post_job_commands), $ttt)
	GUICtrlSetOnEvent(-1, "ClickSetPostJobState")
	GUICtrlSetState(-1, $run_post_job_commands)


	$ttt = $tristate_overwrite_title
	$check_overwrite = GUICtrlCreateCheckbox(" overwrite ", 63, 0, 63, 20, BitOr($BS_AUTO3STATE,$BS_RIGHTBUTTON))
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetTipOptional(-1, $tristate_overwrite_tip & Human($overwrite), $ttt)
	GUICtrlSetOnEvent(-1, "ClickSetOverwrite")
	GUICtrlSetState(-1, $overwrite)


	$ttt = $tristate_concatenate_title
	$check_concatenate = GUICtrlCreateCheckbox(" join ", 69, 0, 35, 20, BitOr($BS_AUTO3STATE,$BS_RIGHTBUTTON))
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetTipOptional(-1, $tristate_concatenate_tip & Human($concatenate), $ttt)
	GUICtrlSetOnEvent(-1, "ClickSetConcatenateFiles")
	GUICtrlSetState(-1, $concatenate)


	$ttt = $tristate_quit_title
	$check_quit_when_done = GUICtrlCreateCheckbox(" quit ", 39, 0, 35, 20, BitOr($BS_AUTO3STATE,$BS_RIGHTBUTTON))
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetTipOptional(-1, $tristate_quit_tip & Human($quit_when_done), $ttt)
	GUICtrlSetOnEvent(-1, "ClickSetQuitWhenDone")
	GUICtrlSetState(-1, $quit_when_done)


	$ttt = $tristate_shutdown_title
	$check_shutdown_when_done = GUICtrlCreateCheckbox(" shutdown ", 40, 0, 66, 20, BitOr($BS_AUTO3STATE,$BS_RIGHTBUTTON))
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetTipOptional(-1, $tristate_shutdown_tip & Human($shutdown_when_done), $ttt)
	GUICtrlSetOnEvent(-1, "ClickSetShutdownWhenDone")
	GUICtrlSetState(-1, $shutdown_when_done)

	; Some logic needed for quit/shutdown buttons..
	ShutDownOverrideQuit()



	; Input override parameter option things..

	GUISetCoord(10, 97)

	$ttt = "Input Parameter Override"
	GUICtrlCreateGroup("input parameter override.. ", 0, 0, $column_two-18, 39)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)

	$tip =	"If you need to specify special parameters for the input file, do that here. " & $MSG_LF & _
			"NOTE: If you put *anything* here, you must also include the ""-i "" part." & $MSG_LF & _
			$MSG_LF & _
			"This is the place where you would find an SRT file, for example." & $MSG_LF & _
			$MSG_LF & _
			"NOTE: these parameters will usually override output parameters, forcing " & $MSG_LF & _
			"whatever you specify, here." & $MSG_LF & _
			$MSG_LF & _
			"Don't Forget to put '-i' in front of, and ""quotes"" around any file " & $MSG_LF & _
			"paths you put/drop here!" & $MSG_LF & _
			$MSG_LF & _
			"AND, that THIS section goes BEFORE the INPUT (above) in the " & $MSG_LF & _
			"arguments (so -map FIRST!) " & $MSG_LF & _
			$MSG_LF & _
			"NOTE: This input accepts @tokens."
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$inp_input_params = GUICtrlCreateInput("", 5, 15, $column_two-76, 20)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetState(-1, $GUI_DROPACCEPTED)
	GUICtrlSetFont(-1, $console_output_font_size, 400, 0, $console_output_font, 5)


	$ttt = "Quick Add-A-File Button"
	$butt_add_file_arg_to_input_params = GUICtrlCreateButton("+", $column_two-72, 0, 20, 20, _
											BitOr($WS_TABSTOP,$BS_FLAT,$BS_CENTER,$BS_VCENTER))
	GUICtrlSetTipOptional(-1, _
		"Clicking here adds '-i """"' to the input override and places the caret inbetween the two quotes. " _
		& $MSG_LF & _
		"Then you can drag a file directly into the input parameter override input and it's ready-to-go. " & _
		$MSG_LF & $MSG_LF & _
		"Note: The addition is always at the end, so you can easily perform this action multiple times.", $ttt)
	GUICtrlSetOnEvent(-1, "AddInputOverrideFileArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))


	$ttt = "Delete"
	GUICtrlCreateButton(" x", 24, 0, 20, 20, BitOr($WS_TABSTOP,$BS_FLAT,$BS_CENTER,$BS_VCENTER))
	GUICtrlSetTipOptional(-1, "Click here to wipe the current input override parameters. ", $ttt)
	GUICtrlSetOnEvent(-1, "DelInputOverrideFileArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))


	debug("GUI:: Presets: ", @ScriptLineNumber, 9);debug

	; Presets..
	; (aka. Parameter Favourites)


	$tip =	"Select a preset from the list. The selected preset can either add to" & $MSG_LF & _
			"or replace the current settings NOTE: once selected, you can use " & $MSG_LF & _
			"your arrow keys to navigate this combo control. " & $MSG_LF & _
			"(right-click the combo's chevron for a context menu) "

	GUISetCoord($column_two-1, 62)
	GUICtrlCreateLabel("", 0, 0, $column_two-12, 20, 0, 0)
	GUICtrlSetTipOptional(-1, $tip, $NAME_PRESETS)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	; GUICtrlSetBkColor(-1, $COLOR_RED)

	GUISetCoord($column_two-1, 62)
	GUICtrlCreateLabel("", 0, 0, 10, 42, 0, 0)
	GUICtrlSetTipOptional(-1, $tip, $NAME_PRESETS)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	; GUICtrlSetBkColor(-1, $COLOR_RED)

	GUISetCoord($column_two-1, 103)
	GUICtrlCreateLabel("", 0, 0, $column_two-12, 8, 0, 0)
	GUICtrlSetTipOptional(-1, $tip, $NAME_PRESETS)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	; GUICtrlSetBkColor(-1, $COLOR_RED)

	; Enable the background color commands and you will see I am not fucking around here.


	$ttt = $NAME_PRESETS
	GUISetCoord($column_two, 62)

	GUICtrlCreateGroup(StringLower($NAME_PRESETS) & ".. ", 0, 0, ($width-$column_two)-10, 74)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))


	local $combo_styles = BitOr($CBS_DROPDOWN, $CBS_AUTOHSCROLL, $WS_VSCROLL)
	if $sort_presets_list = $ON then $combo_styles = BitOr($CBS_SORT, $CBS_DROPDOWN, $CBS_AUTOHSCROLL, $WS_VSCROLL)

	$combo_presets = GUICtrlCreateCombo("", 10, 20, ($width-$column_two)-120, default, $combo_styles)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "ComboLoadPreset")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	GUICtrlSetState(-1, $GUI_DROPACCEPTED+$GUI_ONTOP)

	UpdatePresetsCombo()

	global $ctxt_combo = GUICtrlCreateContextMenu($combo_presets)

		GUICtrlCreateMenuItem("Rename Preset", $ctxt_combo)
		GUICtrlSetOnEvent(-1, "MenuRenamePreset")

		GUICtrlCreateMenuItem("Refresh List", $ctxt_combo)
		GUICtrlSetOnEvent(-1, "MenuRefreshPresetsList")

		GUICtrlCreateMenuItem("", $ctxt_combo)

		GUICtrlCreateMenuItem("Export Data", $ctxt_combo)
		GUICtrlSetOnEvent(-1, "MenuExportData")

		GUICtrlCreateMenuItem("Import Data", $ctxt_combo)
		GUICtrlSetOnEvent(-1, "ComboImportData")

		GUICtrlCreateMenuItem("", $ctxt_combo)

		GUICtrlCreateMenuItem("Wipe All Preset Backups", $ctxt_combo)
		GUICtrlSetOnEvent(-1, "WipeBackups")

		GUICtrlCreateMenuItem("", $ctxt_combo)

		GUICtrlCreateMenuItem("Change Default Extension For This Preset", $ctxt_combo)
		GUICtrlSetOnEvent(-1, "SetPresetDefExtension")

		GUICtrlCreateMenuItem("", $ctxt_combo)

		GUICtrlCreateMenuItem("Add/Edit Notes For This Preset", $ctxt_combo)
		GUICtrlSetOnEvent(-1, "AddNotesToPreset")

		GUICtrlCreateMenuItem("", $ctxt_combo)


		$ctxt_combo_sort = GUICtrlCreateMenuItem($sort_presets_list_texts & ")", $ctxt_combo)
		GUICtrlSetOnEvent(-1, "MenuToggleSortPresets")
		GUICtrlSetState(-1, $sort_presets_list)




	$ttt = "Save A Preset"
	GUICtrlCreateButton("save", ($width-$column_two)-115, 0, 42, 22, BitOr($WS_TABSTOP,$BS_FLAT), $WS_EX_TOPMOST)
	GUICtrlSetTipOptional(-1,  "Save these settings as a preset (aka. 'favourite settings'). " & $MSG_LF & _
								"NOTE: when overwriting an existing preset, hold down " & $MSG_LF & _
								"the <Shift> key to skip the warning. ", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "ButtSavePreset")


	$ttt = "Wipe A Preset"
	$butt_wipe = GUICtrlCreateButton("wipe", 46 , 0, 42, 22, BitOr($WS_TABSTOP,$BS_FLAT))
	GUICtrlSetTipOptional(-1,  "Remove this preset from the list. " & $MSG_LF & _
								"Shift- or right-click to restore backups.", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "WipePreset")


	; GUISetCoord(70-($width-$column_two), 31)

	$ttt = "Replace Settings"
	$radio_preset_replace = GUICtrlCreateRadio("replace", 70-($width-$column_two), 29, default, 18)
	GUICtrlSetTipOptional(-1,  _
		"Selected presets will replace all the current settings with settings from the preset.", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "TogglePresetMode")
	GUICtrlSetState(-1, $replace_mode)

	$ttt = "Add To Settings"
	GUICtrlCreateRadio("add to", 58, 0, default, 18, -1)
	GUICtrlSetTipOptional(-1,  "The selected preset will ADD to all the current settings. " & $MSG_LF & _
					"This applies to all the visible settings that can be 'added to';" & $MSG_LF & _
					" i.e. not toggles and job settings, which are replaced, as usual.", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "TogglePresetMode")
	if $replace_mode = $OFF then GUICtrlSetState(-1, $ON)


	GUICtrlCreateLabel("settings", 52, 2, default, 18, BitOr($WS_TABSTOP,$BS_FLAT), $WS_EX_TOPMOST)
	GUICtrlSetTipOptional(-1,  "Presets can either replace or add to existing settings. " & $MSG_LF & _
					"This applies to all the visible settings that can be 'added to'," & $MSG_LF & _
					"such as parameter inputs. When using 'add to', other settings" & $MSG_LF & _
					"will be replaced with any corresponding settings in the preset.", "Add To or Replace Existing Settings")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))


	GUISetCoord($width-102, 111)

	; Store the input/output file paths inside the preset?
	;
	$ttt = "Save/Restore File Paths"
	$check_store_filepaths = GUICtrlCreateCheckbox("with file paths", 0, 0, 82, 18, -1, $WS_EX_TOPMOST)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "ToggleStorePaths")
	; GUICtrlSetBkColor(-1, $COLOR_RED)
	GUICtrlSetTipOptional(-1, "Store the full path of the input and output files inside the preset " & $MSG_LF & _
										"and (usually) restore those file paths along with the preset. ", $ttt)
	if $store_filepaths <> $GUI_INDETERMINATE then
		GUICtrlSetState(-1, $store_filepaths)
	else
		GUICtrlDelete(-1)
		GUICtrlCreateLabel(" ", 0, 0, 80, 18)
		GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
		GUICtrlSetTipOptional(-1,	"This feature is disabled inside ffe.ini.", $ttt)
	endif




	; Output options..
	local $out_top = 66
	local $out_left = 10

	GUISetCoord(10, 137)

	GUICtrlCreateGroup(" output parameter override.. ", 0, 0, $width-20, 150)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))


	debug("GUI:: Codecs: ", @ScriptLineNumber, 9);debug


	; Video codec..
	;
	$ttt = "Video Codec"
	$tip = "Here you can select/override the codec used to encode the output video. " & $MSG_LF & _
			"Select a preset codec from the list, or enter one manually. " & $MSG_LF & $MSG_LF & _
			"Note: Auto-Codec Drop-Downs disables this control's context menu."
	GUICtrlCreateLabel("video codec: ", 6, 19)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))


	$combo_v_codec = GUICtrlCreateCombo($v_codec, -1, 16, 128, default, BitOr($CBS_SORT, $CBS_DROPDOWN, $CBS_AUTOHSCROLL, $WS_VSCROLL))
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetData(-1, $video_codecs)



  ;2do..
  AutoItSetOption("GUICoordMode", 1)
  ; We are working our way slowly through the GUI, removing the following nonsense!


	; Need to re-organize from here, into groups, not rows!




	; Video bitrate..

	$ttt = "Video Bitrate"
	$tip = "Override the output video bitrate(bits/s). " & $MSG_LF & "Select a preset, or enter manually. "
	GUICtrlCreateLabel("bitrate: ", $out_left+142, $out_top+90)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$combo_v_bitrate = GUICtrlCreateCombo("", $out_left+142, $out_top+106, 42, default)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetData(-1, $video_bitrates)


	; Video fps..

	$ttt = "Video FPS"
	$tip = "Override the output video fps (frames per second, aka, 'framerate'). " & $MSG_LF & _
		"Select a preset bitrate from the list, or enter one manually. "
	GUICtrlCreateLabel("fps: ", $out_left+194, $out_top+90)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$combo_frames_per_second = GUICtrlCreateCombo("", $out_left+194, $out_top+106, 42, default)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetData(-1, $frames_per_second)




	; Resize-crop order..
	$ttt = "Resize-Crop Order"
	$check_resize_first = GUICtrlCreateCheckbox("resize first", $out_left+194, $out_top+152)
	GUICtrlSetTipOptional(-1, _
			"Check this to resize the video BEFORE the cropping operation (it depends on how your logic goes).." & $MSG_LF & _
			"The order of things affects the dimensions. You might crop THEN resize, or the reverse... ", $ttt)
	GUICtrlSetonEvent(-1, "RFCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetState($check_resize_first, $resize_first)




	; Cropping..

	; new syntax =
	; -vf "crop=out_w:out_h:x:y"

	local $fvwarn = 	"Note: You must either specify all four crop values or" & $MSG_LF & _
							"else specify only width and height (crop will be centred)."

	$ttt = "Crop area dimensions"
	$label_active_crop_wh = GUICtrlCreateLabel("crop  w / h: ", $out_left+262, $out_top+90)
	GUICtrlSetTipOptional(-1, "The crop area will be this width and height (pixels or formula).." & $MSG_LF & $MSG_LF & _
								"Click this label for auto-crop, which will interrogate the file for" & $MSG_LF & _
								"black borders and insert the cropping values automatically." & $MSG_LF & $MSG_LF & _
								"Right-Click to set a new default number of test frames." & $MSG_LF & _
								"Shift+Click to set for THIS test and do it now.", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "DoAutoCrop")

	$ttt = "Crop area width"
	$inp_crop_width = GUICtrlCreateInput("", $out_left+262, $out_top+106, 33, 21, $ES_NUMBER)
	GUICtrlSetTipOptional(-1, "Crop out an area of the video THIS wide (pixels or formula)." & $MSG_LF & $MSG_LF & $fvwarn, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$ttt = "Crop area height"
	$inp_crop_height = GUICtrlCreateInput("", $out_left+302, $out_top+106, 33, 21, $ES_NUMBER)
	GUICtrlSetTipOptional(-1, "Crop out an area of the video THIS high (pixels or formula)." & $MSG_LF & $MSG_LF & $fvwarn, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))




	$ttt = "Crop top-left x/y position"
	$label_active_crop_xy = GUICtrlCreateLabel("crop  x / y: ", $out_left+262, $out_top+132)
	GUICtrlSetTipOptional(-1, "The crop area will begin at this X/Y position (pixels or formula).." & _
								$MSG_LF & $MSG_LF & _
								"For example, to crop 60px black bars from the top and bottom" & $MSG_LF & _
								"of a 720p video you might use 0 60 1280 600 (x/y/w/h)." & $MSG_LF & $MSG_LF & _
								"Click this label for auto-crop, which will interrogate the file for" & $MSG_LF & _
								"black bars and insert the cropping values automatically.", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "DoAutoCrop")


	$ttt = "Crop beginning X Position"
	$inp_crop_x = GUICtrlCreateInput("", $out_left+262, $out_top+148, 33, 21, $ES_NUMBER)
	GUICtrlSetTipOptional(-1, "Crop the video begining at this X position (pixels or formula)." &$MSG_LF&$MSG_LF&$fvwarn, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$ttt = "Crop beginning Y Position"
	$inp_crop_y = GUICtrlCreateInput("", $out_left+302, $out_top+148, 33, 21, $ES_NUMBER)
	GUICtrlSetTipOptional(-1, "Crop the video begining at this Y position (pixels or formula)." & $MSG_LF & $MSG_LF & $fvwarn, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))






	; Video resizing..
	$ttt = "Resizing"

	; x ..
	$tip = "Rescale the video width. "
	GUICtrlCreateLabel("resize x: ", $out_left+350, $out_top+90)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$inp_x_size = GUICtrlCreateInput("", $out_left+350, $out_top+106, 33, 21, $ES_NUMBER)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	; The "x" in 640x480!
	GUICtrlCreateLabel("x", $out_left+389, $out_top+108)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)


	$ttt = "Rescaling"
	; y ..
	$tip = "Rescale the video height. "
	GUICtrlCreateLabel("resize y: ", $out_left+400, $out_top+90)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$inp_y_size = GUICtrlCreateInput("", $out_left+400, $out_top+106, 33, 21, $ES_NUMBER)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))


	; Preset sizes..
	$ttt = "Preset Sizes"
	$tip = ".. or you can select a named preset size from the list (if you know what they mean!) " & $MSG_LF & _
														"Note: this will override the manual settings (above). "
	GUICtrlCreateLabel("preset sizes: ", $out_left+350, $out_top+132)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$combo_preset_resizes = GUICtrlCreateCombo($resize_preset, $out_left+350, $out_top+148, 64, default)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetData(-1, $preset_resizes)





	; Audio codec..
	$ttt = "Audio Codec"
	$tip = "Here you can select/override the codec used to encode the output audio track. " & $MSG_LF & _
			"Select a preset codec from the list, or enter one manually. " & $MSG_LF & $MSG_LF & _
			"Note: Auto-Codec Drop-Downs disables this control's context menu."
	GUICtrlCreateLabel("audio codec: ", $out_left+6, $out_top+132)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$combo_a_codec = GUICtrlCreateCombo($a_codec, $out_left+5, $out_top+148, 128, _
					default, BitOr($CBS_SORT, $CBS_DROPDOWN, $CBS_AUTOHSCROLL, $WS_VSCROLL))
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetData(-1, $audio_codecs)




	; Audio bitrate
	$ttt = "Audio Bitrate"
	$tip = "Override the output audio bitrate (Hz).	 " & $MSG_LF & _
		"Select a preset bitrate from the list, or " & $MSG_LF & "enter one manually. "
	GUICtrlCreateLabel("bitrate: ", $out_left+142, $out_top+132)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$combo_a_bitrate = GUICtrlCreateCombo("", $out_left+142, $out_top+148, 42, default)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetData(-1, $audio_bitrates)



	; Quick targets..
	$ttt = "Quick Targets"
	$tip = "Allow FFmpeg to automatically set all the options for THIS file type. " & $MSG_LF & _
			"You can also override individual parameters manually, so long as " & $MSG_LF & _
			"they are compatible with the target file type. "
	GUICtrlCreateLabel("quick config types: ", $out_left+5, $out_top+174)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$combo_target_type = GUICtrlCreateCombo("", $out_left+6, $out_top+190, 128, default)
	GUICtrlSetData(-1, $target_types)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))



	debug("GUI:: Raw Parameters: ", @ScriptLineNumber, 9);debug

	; Extra raw parameters..
	$ttt = "Extra Raw Parameters"
	$tip ="Feel free to add any other command-line parameters you might need right here. " & $MSG_LF & _
			"The possibilities are almost infinite! Check the manual! " & $MSG_LF & $MSG_LF & _
			"NOTE: This input accepts @tokens."
	GUICtrlCreateLabel("extra parameters.. ", $out_left+142, $out_top+174)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))

	$inp_extra_args = GUICtrlCreateInput("", $out_left+141, $out_top+190, $width-167, 21)
	GUICtrlSetTipOptional(-1, $tip & $MSG_LF, $ttt)
	GUICtrlSetOnEvent(-1, "AutoCreateArgs")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKSIZE))
	GUICtrlSetState(-1, $GUI_DROPACCEPTED)
	GUICtrlSetFont(-1, $console_output_font_size, 400, 0, $console_output_font, 5)



	; Reset all parameters..
	$ttt = "Reset ALL Parameters"
	$butt_reset = GUICtrlCreateButton("reset", $out_left+$width-65, $out_top+84, 40, 22, BitOr($WS_TABSTOP,$BS_FLAT))
	GUICtrlSetTipOptional(-1, "Click this button to reset all the parameters. " & $MSG_LF & _
								"Ctrl/Right-Click to also clear input/output." & $MSG_LF & _
								"Shift+Click to clear ONLY the input/output.", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "ClickResetEverything")


	; "Short Test" button..
	$ttt = "Add Quick Test Parameters"
	$butt_quicktest = GUICtrlCreateButton("short test", $out_left+$width-81, $out_top+107, 56, 22, BitOr($WS_TABSTOP,$BS_FLAT))
	$tip_short_test = GUICtrlSetTipOptional(-1, _
		"Adds some parameters to process only the first " & $short_test_frames & " frames of video. " & _
		$MSG_LF & _
		"You can edit this number (right-click the button). ", $ttt)
	GUICtrlSetonEvent(-1, "AddShortTestParam")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKSIZE))


	; "Report" button..
	$ttt = "Create A Media Report"
	$butt_mediareport = GUICtrlCreateButton("media report", $out_left+$width-95, $out_top+130, 70, 22, BitOr($WS_TABSTOP,$BS_FLAT))
	GUICtrlSetTipOptional(-1, _
		"Use ffprobe or MediaInfo to generate a media report for your input file. " & $MSG_LF & _
		"The report will appear in your console output area." & $MSG_LF & _
		"Shift+Click to open in your detault viewer.", $ttt)
	GUICtrlSetonEvent(-1, "GenerateReport")
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKSIZE))

	CreateCodecContexts()

	if $enable_custom_buttons = $ON then
		; The Super-Nifty Custom Buttons..
		CreateButtonGrid()
	endif


	debug("GUI:: Help Buttons: ", @ScriptLineNumber, 9);debug

	; HELP!

	if IsArray($help_texts) then

		; Big info text for help buttons..
		$lab_help_info = GUICtrlCreatelabel("", $width-82, $out_top+153, 65, 18, BitOr($SS_NOTIFY, $SS_RIGHT))
		GUICtrlSetFont(-1, 10, 800, 0, "", 5)
		GUICtrlSetResizing(-1, BitOr($GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
		;GUICtrlSetBkColor(-1, $COLOR_RED)

		; The help buttons..
		$buttons_xy = $out_top+170
		CreateHelpButtons()

	endif



	; Command-Line input..

	$ttt = "Dynamic Command-line Display"
	GUICtrlCreateLabel("Command-line: ", 10, $out_top+228, $width-20, 20)
	GUICtrlSetResizing(-1, BitOr( $GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	$edit_in_args = GUICtrlCreateEdit("", 10, $out_top+244, $width-20, 64, BitOr($ES_MULTILINE, $ES_READONLY))
	GUICtrlSetTipOptional(-1, "This is the actual command-line that will be used. ", $ttt)
	GUICtrlSetResizing(-1, BitOr( $GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))





	; The Console.
	; Command-Line output..

	$ttt = "Console Output"
	$edit_console_output = GUICtrlCreateEdit("", 10, $out_top+314, $width-20, $height-($out_top+358), GetEditStyles())
	if $allow_console_tooltip = $ON then GUICtrlSetTipOptional(-1, _
		"You can see the output from FFmpeg here, including any errors, messages, and so on.. " & $MSG_LF & _
		"You can also use it as an editing space for any plain text." & $MSG_LF & _
		"Normal text editing functions apply, e.g. Ctrl+A to select ALL text." & $MSG_LF  & $MSG_LF & _
		"NOTE: You can disable this (somewhat annoying) ToolTip from the app menu.", $ttt)
	GUICtrlSetResizing(-1, BitOr( $GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKBOTTOM, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	GUICtrlSetLimit(-1, 2147483647)
	GUICtrlSetFont(-1, $console_output_font_size, 400, 0, $console_output_font, 5)
	GUICtrlSetState(-1, $GUI_DROPACCEPTED)




	; Search in output window..
	;
	$ttt = "Search      (F3)"
	$butt_find = GUICtrlCreateButton("search in output", 10, $height-32, 90, 24, BitOr($WS_TABSTOP,$BS_FLAT))
	GUICtrlSetTipOptional(-1, "Click this button to find text inside the console output (F3). ", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "Butt_FindInOutput")


	; Copy output to clipboard..
	$ttt = "Copy Output To Clipboard      (F8)"
	$butt_copy2clip = GUICtrlCreateButton("copy output to clipboard", 105, $height-32, 130, 24, BitOr($WS_TABSTOP,$BS_FLAT))
	GUICtrlSetTipOptional(-1, _
		"Click this button (or hit F8) to copy the contents of the console output to the clipboard. ", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "CopyConsoleOutput")


	; Clear the output..
	$ttt = "Clear The Output      (F5)"
	$butt_clearout = GUICtrlCreateButton("clear", 240, $height-32, 36, 24, BitOr($WS_TABSTOP,$BS_FLAT))
	GUICtrlSetTipOptional(-1, "Click this button (or hit F5) to clear the console output. ", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "ClearOutput")




	; DO IT!!!
	$ttt = "Start The Job      (F1)"
	$butt_doit = GUICtrlCreateButton("do it!", $width-82, $height-32, 72, 24, BitOr($WS_TABSTOP,$BS_FLAT), $WS_EX_TOPMOST)
	GUICtrlSetTipOptional(-1, "Click this button (or hit F1) to begin the job. " & $MSG_LF & _
												"Shift+Click to generate a batch script.", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKRIGHT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))
	GUICtrlSetOnEvent(-1, "DoIt")
	if not $ffmpeg_binary then DisableRunningControls()


	; NO! STOP!
	$ttt = "ABORT THE JOB!	(Pause/Break)"
	$label_abort = GUICtrlCreateLabel( _
		"To abort the current job, press 'Ctrl+Q'. To abort a batch, press 'Pause/Break'. " & _
		"To suspend/resume, use ScrLk/ScrollLock. Alt+C toggles the console.", 10, $height-32)
	GUICtrlSetTipOptional(-1, "Simply hit 'Ctrl+Q' on your keyboard to quit a job. ", $ttt)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))
	GUICtrlSetState(-1, $GUI_HIDE)


	; All done with creating the gui .. *phew* Like I said, NEVER AGAIN!


	; Set Keyboard Accelerators..
	;
	; F1 became "reserved" in the latest Windows 10, so we are using an accelerator for this now.
	; And also many other things. This is WAY more elegant than the old method.
	; For some, we don't need a dummy control as we have an actual control we can fire (eg. $butt_doit)..
	local $AppHotKeys[18][2] = [ _
						["{F1}", $butt_doit], _
						["{F9}", $dummy_drop_window], _
						["^e", $dummy_retain_exit_settings], _
						["{F7}", $dummy_toggle_auto_codecs], _
						["^m", $dummy_toggle_matof_status], _
						["^a", $dummy_select_all_text], _
						["^f", $dummy_f_find_in_output], _
						["{F3}", $dummy_find_in_output], _
						["+{F3}", $dummy_find_replace_in_output], _
						["{F8}", $dummy_copy_output], _
						["{F5}", $dummy_clear_output], _
						["{Esc}", $dummy_quit], _
						["{F6}", $dummy_ffplay_output_toggle], _
						["{F2}", $dummy_set_default_extension], _
						["{F11}", $check_run_ffmpeg_task], _
						["{F12}", $check_run_ffplay_task], _
						["!{F5}", $dummy_restart], _
						["^d", $dummy_delayed_doit]]
	GUISetAccelerators($AppHotKeys)

	debug("GUI:: All done making GUI: ", @ScriptLineNumber, 9);debug

	CheckSize()

	; Show the main gui..
	if not $do_gen and $minimized = $OFF then GUISetState(@SW_SHOW, $ffeGUI)
	if $maximized = $ON then GUISetState(@SW_MAXIMIZE, $ffeGUI)

	if $minimized = $ON then UnSetHotKeys()
	WinSetTrans($ffeGUI, "", 255 * (100 - $user_trans) / 100)

endfunc





; The Application (system, aka. "App") Menu..
; built from the bottom, up..

;	CreateSystemMenuItem($sText, $app_menu = -1, $bIsPopup=false, $nPos=0xFFFFFFFF)
;	0xFFFFFFFF means "insert at the end"

func MakeAppMenu()

	debug("", @ScriptLineNumber, 6);debug
	debug("MakeAppMenu()..", @ScriptLineNumber, 6);debug

	GUIRegisterMsg($WM_SYSCOMMAND, "CheckAppMenu")

	CreateSystemMenuItem("", -1, false, 0)

	; So we can start checking items right away..
	local $app_menu = GetSystemMenu($ffeGUI, 0)


	; ffe System Menu..
	local $am_system = CreateSystemMenuItem("&ffe..", -1, true, 0)




		$am_always_warn_on_delete = CreateSystemMenuItem(" Always Warn On Delete", $am_system, false, 0)
		CheckMenuItem($app_menu, $am_always_warn_on_delete, $always_warn_on_delete)

		$am_delete_to_recycle_bin = CreateSystemMenuItem(" Delete To Recycle Bin", $am_system, false, 0)
		CheckMenuItem($app_menu, $am_delete_to_recycle_bin, $delete_to_recycle_bin)

		local $ofdeleteoptions = CreateSystemMenuItem("Output File Deletion..", $am_system, false, 0)
		AppMenuItemSetState($app_menu, $ofdeleteoptions, $OFF)
		CreateSystemMenuItem("", $am_system, false, 0)

		$am_do_countdown_timer = CreateSystemMenuItem("Show &Countdown Timer", $am_system, false, 0)
		CheckMenuItem($app_menu, $am_do_countdown_timer, $do_countdown_timer)

		CreateSystemMenuItem("", $am_system, false, 0)

		$am_allow_multiple = CreateSystemMenuItem("Allow &Multiple Instances", $am_system, false, 0)
		CheckMenuItem($app_menu, $am_allow_multiple, $allow_multiple)

		CreateSystemMenuItem("", $am_system, false, 0)

		$am_pause_is_global = CreateSystemMenuItem("&Pause HotKey is Global", $am_system, false, 0)
		CheckMenuItem($app_menu, $am_pause_is_global, $pause_is_global)

		CreateSystemMenuItem("", $am_system, false, 0)

		$am_kill_ffmpeg_on_exit = CreateSystemMenuItem("&Kill FFmpeg On Exit", $am_system, false, 0)
		CheckMenuItem($app_menu, $am_kill_ffmpeg_on_exit, $kill_ffmpeg_on_exit)

		CreateSystemMenuItem("", $am_system, false, 0)

		$am_start_minimized = CreateSystemMenuItem("&Start Minimized", $am_system, false, 0)
		CheckMenuItem($app_menu, $am_start_minimized, $start_minimized)

		CreateSystemMenuItem("", $am_system, false, 0)

		$am_default_extension = CreateSystemMenuItem("Change Default &Extension..	(F2)", $am_system, false, 0)


		CreateSystemMenuItem("", $am_system, false, 0)

		$am_show_ffplay_output = CreateSystemMenuItem("Show FFplay Output in Console..	(F6)", $am_system, false, 0)
		CheckMenuItem($app_menu, $am_show_ffplay_output, $show_ffplay_output)


	CreateSystemMenuItem("", -1, false, 0)


	; Transparency Sub-Menu..
	$am_trans = CreateSystemMenuItem("&Transparency..", -1, true, 0)
		for $i = 0 to 9
			$arTransItems[$i] = CreateSystemMenuItem($i * 10 & "%", $am_trans) ; we filll top-down here
			if $i = $user_trans / 10 then
				$nTPChecked = $arTransItems[$i]
				CheckMenuItem($am_trans, $nTPChecked, $MF_CHECKED)
			endif
		next


	CreateSystemMenuItem("", -1, false, 0)

	; Visual prefs Sub-Menu..
	local $am_visual = CreateSystemMenuItem("&Visual Preferences..", -1, true, 0)

		$am_always_on_top = CreateSystemMenuItem("A&lways on Top", $am_visual, false, 0)
		CheckMenuItem($app_menu, $am_always_on_top, $always_on_top)

		CreateSystemMenuItem("", $am_visual, false, 0)

		$am_allow_output_tooltip = CreateSystemMenuItem($allow_console_tooltip_text & ")", $am_visual, false, 0)
		CheckMenuItem($app_menu, $am_allow_output_tooltip, $allow_console_tooltip)

		$am_console_wordwrap = CreateSystemMenuItem($console_wordwrap_text & ")", $am_visual, false, 0)
		CheckMenuItem($app_menu, $am_console_wordwrap, $console_wordwrap)

		CreateSystemMenuItem("", $am_visual, false, 0)

		$am_image_buttons = CreateSystemMenuItem($image_buttons_text & ")", $am_visual, false, 0)
		CheckMenuItem($app_menu, $am_image_buttons, $image_buttons)

		CreateSystemMenuItem("", $am_visual, false, 0)

		$am_do_tooltips = CreateSystemMenuItem($do_tooltips_text & ")", $am_visual, false, 0)
		CheckMenuItem($app_menu, $am_do_tooltips, $do_tooltips)

		CreateSystemMenuItem("", $am_visual, false, 0)

		$am_time_in_title = CreateSystemMenuItem("Show &Running Time In Title Bar	(Ctrl+R)", $am_visual, false, 0)
		CheckMenuItem($app_menu, $am_time_in_title, $time_in_title)

		CreateSystemMenuItem("", $am_visual, false, 0)


		$am_sort_presets_list = CreateSystemMenuItem($sort_presets_list_texts & ")", $am_visual, false, 0)
		CheckMenuItem($app_menu, $am_sort_presets_list, $sort_presets_list)


	CreateSystemMenuItem("", -1, false, 0)

	; Custom Button Column Menu..
	$am_custom_buttons_columns = CreateSystemMenuItem("Custom &Buttons..", -1, true, 0)

		; Defined column number..
		; We only show 1-12, but you can set higher inside ffe.ini
		for $i = 1 to 12
			$CustomButtonMenuItems[$i] = CreateSystemMenuItem($i, $am_custom_buttons_columns) ; we fill top-down here
			if $i = $custom_buttons_columns then
				$CBMChecked = $CustomButtonMenuItems[$i]
				CheckMenuItem($am_custom_buttons_columns, $CBMChecked, $MF_CHECKED)
			endif
		next

		; Automatic columns..
		$CustomButtonMenuItems[501] = CreateSystemMenuItem("&Automatic", $am_custom_buttons_columns, false, 0)
		if $custom_buttons_columns = "auto" then
			$CBMChecked = $CustomButtonMenuItems[501]
			CheckMenuItem($am_custom_buttons_columns, $CBMChecked, $MF_CHECKED)
		endif

		local $col_itm = CreateSystemMenuItem("Button Columns..", $am_custom_buttons_columns, false, 0)
		AppMenuItemSetState($app_menu, $col_itm, $OFF)
		CreateSystemMenuItem("", $am_custom_buttons_columns, false, 0)

		$am_button_notes_to_console = CreateSystemMenuItem("Button &Notes In Console", $am_custom_buttons_columns, false, 0)
		CheckMenuItem($app_menu, $am_button_notes_to_console, $button_notes_to_console)

		CreateSystemMenuItem("", $am_custom_buttons_columns, false, 0)
		; Disable Custom Buttons altogether..
		$am_enable_custom_buttons = CreateSystemMenuItem("&Enable Custom Buttons", $am_custom_buttons_columns, false, 0)
		CheckMenuItem($app_menu, $am_enable_custom_buttons, $enable_custom_buttons)


	CreateSystemMenuItem("", -1, false, 0)


	; CPU Priority Sub-Menu..	(no accelerators for these)
	 $am_cpu = CreateSystemMenuItem("ffmpeg.exe Process &Priority..", -1, true, 0)
		for $i = 0 to 5
			$arCPUItems[$i] = CreateSystemMenuItem($arCPU[$i], $am_cpu)
			if $i = $cpu_priority then
				$nCPUChecked = $arCPUItems[$i]
				CheckMenuItem($am_cpu, $nCPUChecked, $MF_CHECKED)
			endif
		next


	CreateSystemMenuItem("", -1, false, 0)

	$am_retain_exit_settings = CreateSystemMenuItem("Retain Ex&it Settings	(Ctrl+E)", -1, false, 0)
	CheckMenuItem($app_menu, $am_retain_exit_settings, $retain_exit_settings)


	CreateSystemMenuItem("", -1, false, 0)

	$am_auto_codecs = CreateSystemMenuItem("A&utomatic Codec Drop-downs	(F7)", -1, false, 0)
	CheckMenuItem($app_menu, $am_auto_codecs, $auto_codecs)


	; Reporting types sub-menu..

	CreateSystemMenuItem("", -1, false, 0)
	local $am_reptypes = CreateSystemMenuItem("Media Info &Reporting..", -1, true, 0)

	local $am_ffprobe = CreateSystemMenuItem("Use &ffprobe..", $am_reptypes, false, 0)
	AppMenuItemSetState($app_menu, $am_ffprobe, $OFF)

	for $i = 0 to 6
		$ReportTypesMenuItems[$i] = CreateSystemMenuItem("            &" & $ReportTypes[$i], $am_reptypes)
		if $ReportTypes[$i] = $report_format then
			$nRTChecked = $ReportTypesMenuItems[$i]
			CheckMenuItem($am_reptypes, $nRTChecked, $MF_CHECKED)
		endif
	next

	CreateSystemMenuItem("", $am_reptypes, false, 0)

	$am_use_mediainfo = CreateSystemMenuItem("Use &MediaInfo", $am_reptypes, false, 0)
	if $use_mediainfo = $ON then SetUseMediaInfo()


	CreateSystemMenuItem("", $am_reptypes, false, 0)

	$am_save_reports = CreateSystemMenuItem("&Save Reports", $am_reptypes, false, 0)
	CheckMenuItem($app_menu, $am_save_reports, $save_reports)



	; Post-File Controls sub-menu..
	CreateSystemMenuItem("", -1, false, 0) ; Oooh! dash works as an accelerator!
	local $am_post_file_controls = CreateSystemMenuItem("Post&-File Controls..", -1, true, 0)

		local $am_pf_runstyle = CreateSystemMenuItem("&Run Style..", $am_post_file_controls, false, 0)
		AppMenuItemSetState($app_menu, $am_pf_runstyle, $OFF)

			for $i = 0 to 2
				$PostFileRunStylesMenuItems[$i] = CreateSystemMenuItem(" &" & $PostFileRunStyles[$i], $am_post_file_controls)
				if $PostFileRunStyles[$i] = $post_file_run_style then
					$pfsChecked = $PostFileRunStylesMenuItems[$i]
					CheckMenuItem($am_post_file_controls, $pfsChecked, $MF_CHECKED)
				endif
			next


		CreateSystemMenuItem("", $am_post_file_controls, false, 0)

		$am_post_file_capture = CreateSystemMenuItem("&Capture To Console", $am_post_file_controls, false, 0)
		CheckMenuItem($app_menu, $am_post_file_capture, $post_file_capture)

		$am_post_file_show = CreateSystemMenuItem("&Show Post-File Program", $am_post_file_controls, false, 0)
		CheckMenuItem($app_menu, $am_post_file_show, $post_file_show)



	; Logging sub-menu..
	CreateSystemMenuItem("", -1, false, 0)
	local $am_logging = CreateSystemMenuItem("&Logging..", -1, true, 0)

		$am_log_append = CreateSystemMenuItem("Append &Session Log", $am_logging, false, 0)
		CheckMenuItem($app_menu, $am_log_append, $log_append)

		CreateSystemMenuItem("", $am_logging, false, 0)
		$am_job_log_append = CreateSystemMenuItem("&Append Job Logs", $am_logging, false, 0)
		CheckMenuItem($app_menu, $am_job_log_append, $job_log_append)

		CreateSystemMenuItem("", $am_logging, false, 0)
		$am_log_each_job = CreateSystemMenuItem("&Log Each Job", $am_logging, false, 0)
		CheckMenuItem($app_menu, $am_log_each_job, $log_each_job)


	CreateSystemMenuItem("", -1, false, 0)

	$am_launch_with_drop_command = CreateSystemMenuItem("Run Drag-And-Dr&op Command At Launch", -1, false, 0)
	CheckMenuItem($app_menu, $am_launch_with_drop_command, $launch_with_drop_command)

	; Drop Command sub-menu..
	$am_drop_command = CreateSystemMenuItem("&Drag-And-Drop Command..", -1, true, 0)
	local $ud = UBound($DropCommands)-1
	for $i = 0 to $ud
		if $i = $ud then CreateSystemMenuItem("", $am_drop_command, false, 1)
		$DropCommandMenuItems[$i] = CreateSystemMenuItem("&" & $DropCommands[$i], $am_drop_command)
		if $DropCommands[$i] = $drop_command then
			$nDCChecked = $DropCommandMenuItems[$i]
			CheckMenuItem($app_menu, $nDCChecked, $MF_CHECKED)
		endif
	next


	CreateSystemMenuItem("", -1, false, 0)
	$am_about_ffmpeg = CreateSystemMenuItem("About ffmpe&g", -1, false, 0)
	$am_about = CreateSystemMenuItem("&About " & $my_name, -1, false, 0)

endfunc



func MakeTray()

	debug("", @ScriptLineNumber, 6);debug
	debug("MakeTray()..", @ScriptLineNumber, 6);debug

	; Wipe the tray..
	for $i = 0 to 999
		; Tell me a better way! no, really.
		TrayItemDelete($i)
	next

	; Tray menu..

	local $tray_recent_files = TrayCreateMenu("Recent Files..")

		debugPrintArray($recent_files, "$recent_files:", @ScriptLineNumber, 9);debug

		$tray_toggle_retain_recent_files = TrayCreateItem("Retain Recent Files	(open in default app)", $tray_recent_files)
		TrayItemSetOnEvent(-1, "TrayToggleRetainRecentFiles")
		TrayItemSetState(-1, $retain_recent_files)
		TrayCreateItem("", $tray_recent_files)

		if $recent_files[0][0] then

			local $tray_clear = TrayCreateItem("Clear Recent Files List", $tray_recent_files)
			TrayItemSetOnEvent(-1, "ClearRecentFiles")
			local $spc_clear = TrayCreateItem("", $tray_recent_files)

			local $removed_rf = $recent_files[0][0]
			debug("$removed_rf: " & $removed_rf, @ScriptLineNumber, 9);debug

			for $i = $recent_files[0][0] to 1 step -1
				if FileExists($recent_files[$i][0]) then
					$recent_files[$i][1] = TrayCreateItem(BaseName($recent_files[$i][0]), $tray_recent_files)
					TrayItemSetOnEvent(-1, "OpenRecentFile")
				else
					if $recent_files[$i][0] then
						ConsoleAdd("Removed '" & $recent_files[$i][0] & "' from Recent Files menu.", @ScriptLineNumber)
						$recent_files[$i][0] = ""
						$removed_rf -= 1
					endif
				endif
				debug("$removed_rf: " & $removed_rf, @ScriptLineNumber, 9);debug
			next

			; ALL recent files were removed..
			if $removed_rf = 0 then
				TrayCreateItem("Recent Files list was emptied", $tray_recent_files)
				TrayItemDelete($tray_clear)
				TrayItemDelete($spc_clear)
				ClearRecentFiles()
			endif

		else
			; No recent files were stored from previous session..
			TrayCreateItem("No Recent Files Exist!", $tray_recent_files)
			TrayItemSetState(-1, $TRAY_DISABLE)
		endif

	TrayCreateItem("")

	$tray_toggle_delayed_start = TrayCreateItem("Delayed Start	(Ctrl+D)")
	TrayItemSetOnEvent(-1, "DelayedDoIt")

	TrayCreateItem("")

	$tray_abort_batch = TrayCreateItem("Abort Batch	(Pause/Break)")
	TrayItemSetOnEvent(-1, "AbortBatch")
	TrayItemSetState(-1, $TRAY_DISABLE)

	TrayCreateItem("")

	if $pre_job_commands_file and FileExists($pre_job_commands_file) then
		TrayCreateItem("Edit Pre-Job Commands..")
		TrayItemSetOnEvent(-1, "EditPreJob")
	else
		TrayCreateItem("Create Pre-Job Commands..")
		TrayItemSetOnEvent(-1, "SpecifyPreJobCMDsFile")
	endif


	if $post_job_commands_file and FileExists($post_job_commands_file) then
		TrayCreateItem("Edit Post-Job Commands..")
		TrayItemSetOnEvent(-1, "EditPostJob")
	else
		TrayCreateItem("Create Post-Job Commands..")
		TrayItemSetOnEvent(-1, "SpecifyPostJobCMDsFile")
	endif

	TrayCreateItem("")

	TrayCreateItem("Edit ffe.ini..")
	TrayItemSetOnEvent(-1, "EditIniFile")

	TrayCreateItem("")

	TrayCreateItem("Open Log File..")
	TrayItemSetOnEvent(-1, "OpenLogFile")

	TrayCreateItem("Open Data Folder..")
	TrayItemSetOnEvent(-1, "OpenDataDir")

	TrayCreateItem("")

	TrayCreateItem("Export Data..")
	TrayItemSetOnEvent(-1, "TrayMenuExportData")

	TrayCreateItem("Import Data..")
	TrayItemSetOnEvent(-1, "TrayMenuImportData")

	TrayCreateItem("")

	$tray_toggle_drop_window = TrayCreateItem("Show Drop Window")
	TrayItemSetOnEvent(-1, "MenuToggleDropWindow")
	TrayItemSetState(-1, $do_drop_window)

	$tray_toggle_fluid_image_menu = TrayCreateItem("Fluid Menu	(follows current image)")
	TrayItemSetOnEvent(-1, "MenuToggleFluidMenu")
	TrayItemSetState(-1, $fluid_image_menu)

	$tray_toggle_auto_copy_images = TrayCreateItem("Copy Dragged Images	(to fixed menu)")
	TrayItemSetOnEvent(-1, "MenuToggleAutoCopy")
	TrayItemSetState(-1, $auto_copy_images)
	if $fluid_image_menu = $ON then TrayItemSetState(-1, $TRAY_DISABLE)

	$tray_choose_image_folder = TrayCreateItem("Pick Images Folder..	(for fixed menu)")
	TrayItemSetOnEvent(-1, "MenuChooseFixedImgLoc")
	if $fluid_image_menu = $ON then TrayItemSetState(-1, $TRAY_DISABLE)

	TrayCreateItem("")

	TrayCreateItem("Reset Drop Window")
	TrayItemSetOnEvent(-1, "MenuResetDropWindow")

	TrayCreateItem("")

	TrayCreateItem("Download Drop Window Image Pack")
	TrayItemSetOnEvent(-1, "TrayDownloadImagePack")

	TrayCreateItem("")

	TrayCreateItem("Locate FFmpeg Binary..")
	TrayItemSetOnEvent(-1, "TraySetFFmpegBinLocation")

	TrayCreateItem("")

	TrayCreateItem("Restart ffe..	Alt+F5")
	TrayItemSetOnEvent(-1, "Restart")

	TrayCreateItem("")

	TrayItemSetOnEvent(-1, "DoAboutFFmpeg")
	if not $ffmpeg_binary then TrayItemSetState(-1, $TRAY_DISABLE)
	$tray_about_ffmpeg = TrayCreateItem("About FFmpeg")

	TrayCreateItem("About " & $my_name)
	TrayItemSetOnEvent(-1, "DoAboutBox")

	TrayCreateItem("")

	TrayCreateItem("Exit	(Alt+F4 or Esc)")
	TrayItemSetOnEvent(-1, "UserDoQuit")

	; System tray event..
	; Left-click to show/hide the main window.
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "ToggleWindow")
	TraySetClick(8)
	TraySetIcon($me_app, 0)

	TraySetState()
	TraySetToolTip("left-click to toggle the main window" & $MSG_LF & "right-click to bring up the tray menu")

endfunc


; Okay, here goes.
; Run the job..

func DoIt()

	debug("", @ScriptLineNumber, 6);debug
	debug("DoIt(): inputfile / outputfile: " & $inputfile & " / " & $outputfile, @ScriptLineNumber, 3);debug

	; SHIFT held down or 'generate' set in switches..
	if _IsPressed(10) or $do_gen then $generate_script = true

	if not $inputfile then
		if not BrowseForInputFile() then return
		DoIt()
		return
	endif


	if not IsWild($inputfile) and IsDir($inputfile) then
		CRT($inputfile)
		$inputfile &= "\*"
	endif

	; outputfile loaded in presets???	::BUG?::
	if not $outputfile and not IsWild($inputfile) and $do_output = $ON then
		if not BrowseForOutputFile() then return
		DoIt()
		return
	endif


	$user_inputfile = $inputfile
	$user_outputfile = $outputfile

	UnSetHotKeys()
	ClearOutput()
	DisableRunningControls()
	HideOutputButts()

	local $emsg

	; Store this so we can show the dropwin again at the end, if enabled..
	$drop_win_state = $do_drop_window

	if $dropwin_visible then CloseDropWindow()

	; Delayed Start + Countdown Timer..
	if $delay_start_at then

		ConsoleAdd("Delayed start activated.", @ScriptLineNumber)

		local $d_diff, $h_diff, $m_diff, $t_str, $pl, $ad, $tdiff
		local $diff = _DateDiff("s", _NowCalc(), $delay_start_at)

		while $diff > 0

			; All this for a countdown timer!
			if $do_countdown_timer = $ON then

				$t_str = ""

				; Days..
				$d_diff = _DateDiff("D", _NowCalc(), $delay_start_at)
				$pl = ""
				if $d_diff > 1 then $pl = "s"
				if $d_diff then $t_str = $d_diff & " day" & $pl

				; Hours..
				$h_diff = _DateDiff("h", _NowCalc(), $delay_start_at)
				$pl = ""
				$ad = ""
				$tdiff = $h_diff-($d_diff*24)
				if $tdiff > 1 then $pl = "s"
				if $t_str then $ad = ", "
				if $tdiff then $t_str &= $ad & $tdiff & " hour" & $pl
				$tdiff = ""

				; Minutes..
				$m_diff = _DateDiff("n", _NowCalc(), $delay_start_at)
				$pl = ""
				$ad = ""
				$tdiff = $m_diff-($h_diff*60)
				if $tdiff > 1 then $pl = "s"
				if $t_str then $ad = ", "
				if $tdiff then $t_str &= $ad & $tdiff & " minute" & $pl
				$tdiff = ""

				; Seconds..
				$diff = _DateDiff("s", _NowCalc(), $delay_start_at)
				$tdiff = $diff-($m_diff*60)
				$pl = ""
				if $tdiff > 1 then $pl = "s"
				if $tdiff then
					if $t_str then $t_str &= " and "
					$t_str &= $tdiff & " second" & $pl
				endif
				SetWinTitleText(" delayed start in " & $t_str)
			endif

			if not $delay_start_at then
				$emsg  = "Delayed start aborted."
				debug($emsg, @ScriptLineNumber, 2);debug
				return ReturnNow($emsg, -7)
			endif
			Sleep(1000)
		wend
		debug("delayed start set for: " & $delay_start_at, @ScriptLineNumber, 4);debug

		SetWinTitleText()
	endif


	local $job_log, $msg, $generated, $run_command
	if FileExists($concat_list) then FileDelete($concat_list)


	; Pre-Job Commands..

	if $run_pre_job_commands = $ON then
		LoadPreCommands() ;always nice to grab this fresh, in case of recent edits..
		RunCommandsFile($pre_job_commands_file, $job_log, $generated, "Pre")
		Sleep(500)
	endif


	local $run_files[2] = [1, $inputfile]
	local $run_root = "", $batch = $OFF

	if IsWild($inputfile) then
		if StringInStr($inputfile, "://") then return ReturnNow("Error: Cannot process wildcards in URLs.", -3)

		$run_root = GetParent($inputfile)
		if not $run_root then $run_root = @WorkingDir
		CRT($run_root)
		local $run_mask = Basename($inputfile)
		if $run_mask = "*.*" then $run_mask = "*"
		$run_files = _FileListToArrayRec($run_root & "\", $run_mask, $FLTAR_FILES, $FLTAR_RECUR)
		if not IsArray($run_files) then
			$delay_start_at = false
			return ReturnNow("Error: No matching files under " & $run_root & " for " & $run_mask & ".", -1)
		endif
		$batch = $ON
	endif

	$abort_batch = false
	if $run_files[0] > 1 then TrayItemSetState($tray_abort_batch, $TRAY_ENABLE)

	; Reset "made files" for this job..
	redim $made_files[1]
	local $total_timestamp = TimerInit()
	local $secprt, $thistime


	; Process each file in the batch.. (the BIG loop!)
	;
	for $runs = 1 to $run_files[0]

		local $run_subdir = ""
		$inputfile = $run_files[$runs]
		if $batch = $ON then
			$run_subdir = GetParent($inputfile)
			$inputfile = $run_root & "\" & $inputfile
		endif
		DoArgsCreate($batch, $run_root, $run_subdir)

		if $inputfile = $outputfile and $do_output = $ON then
			; Running from command-line, just get on with *something*..
			if $go then
				; This should rarely happen, but just in case..
				$outputfile = RemoveExtension($outputfile) & TimerInit() & "." & GetExtension($outputfile)
			else
				MsgBox(0, "file name clash!", "You will need to choose a different output filename.. ", 0, $ffeGUI)
				if (BrowseForOutputFile() = 0) then
					$emsg  = "Error starting job: File name clash."
					debug($emsg, @ScriptLineNumber, 1);debug
					return ReturnNow($emsg, -2)
				endif
				DoIt()
				return
			endif
		endif

		debug("$outputfile: " & $outputfile, @ScriptLineNumber, 7);debug

		; We keep a tally of all files created during the job.
		; If FFmpeg wants to output some file with the same name, we will add a timestamp suffix to the name.
		; This is designed to catch a situation where the user has used a *.* wildcard and there are associated
		; files in the same dir as the videos, e.g. "movie.srt". The user sets up a batch job and wakes the
		; next morning to find 10 *tiny* movie files which won't play. Nope, it's never happened to me. Seriously.
		; It also catches situations where you are converting a batch where more than one file shares the same
		; name but has a different extension, e.g. "movie.avi" and "movie.mpg" both being converted to say, MP3.

		; Already made this file - add timestamp suffix to file name..
		if InArray($made_files, $outputfile) then
			local $old_of = $outputfile
			$outputfile = RemoveExtension($outputfile) & "_[" & TimerInit() & "]" & "." & GetExtension($outputfile)
			; Update args with new file name..
			$args = StringReplace($args, $old_of, $outputfile)
		endif

		debug("$outputfile: " & $outputfile, @ScriptLineNumber, 7);debug

		; $outputfile is now SET!

		; Just in case..
		local $out_parent = GetParent($outputfile)
		if not FileExists($out_parent) then DirCreate($out_parent)

		if $concatenate = $ON and $batch = $ON then
			FileWriteLine($concat_list, "file '" & $outputfile & "'")
		endif

		GUICtrlSetState($label_abort, $GUI_SHOW)

		$title_msg_string = "    --> Processing: " & BaseName($inputfile) & "    (Press Ctrl+Q or Pause/Break to abort)"
		if $batch = $ON then
			$title_msg_string = "    --> Processing: " & BaseName($inputfile) & "    (Press Pause/Break to abort batch)"
		endif
		SetWinTitleText($title_msg_string)

		; We will need to pass the "q" to ffmpeg manually..
		HotKeySet("^q", "HK_FFmpegAbort")
		HotKeySet("^r", "HK_ToggleTitleTime")
		; HotKeySet("^{PAUSE}", "PauseOutPut")	; Works, but risky!
		HotKeySet("!c", "PauseOutPut")

		; This also aborts a regular job..
		HotKeySet("{PAUSE}", "HK_RunningAbortBatch")
		HotKeySet("{SCROLLLOCK}", "HK_ProcessPauseSuspend")


		; RUN the amazing FFmpeg..

		$paused = false
		$msg = $LOG_LF & "starting ffe job on " & DateTimeString(true)  & $LOG_LF & "command-line: " & $args & $LOG_LF & $LOG_LF
		DoLog($msg)
		$job_log &= $msg

		; This is REQUIRED to get frei0r plugins to work..
		EnvSet("FREI0R_PATH", $plugins_path)

		; Documentation is scant online. Try these..
		; https://www.mltframework.org/plugins/FilterFrei0r-edgeglow/
		; https://gstreamer.freedesktop.org/documentation/frei0r/index.html?gi-language=c


		; Windows batch script output..
		if $generate_script then

			$generated &= $args & $LOG_LF

		else

			debug("Run() FFmpeg with args: " & $args, @ScriptLineNumber, 3);debug
			ConsoleAdd("", @ScriptLineNumber, true)
			$ffmpeg = Run($args, @ScriptDir, @SW_HIDE, BitOr($STDERR_CHILD, $STDIN_CHILD))
			debug("$ffmpeg running with PID: " & $ffmpeg, @ScriptLineNumber, 4);debug

			ProcessSetPriority($ffmpeg, $cpu_priority)
			local $timestamp = TimerInit()
			local $console_out

			local $ease_time
			local $done_response = 0

			while true

				$ease_time += 1

				Sleep(50)
				if $time_in_title = $ON and Mod($ease_time, 10) = 0 then
					SetWinTitleText($title_msg_string & "      [" & SecondsToDHMS(TimerDiff($total_timestamp)/1000, true) & "]")
				endif
				; Capture Output..
				$console_out = StdErrRead($ffmpeg)

				if @error then exitloop
				if $abort_batch then
					StdinWrite($ffmpeg, "q")
					Sleep(250)
					exitloop
				endif
				;if not @extended then continueloop

				if StringInStr($console_out, "write? [y/N]", 0, -1) then
					WinActivate($ffeGUI)
					WinFlash($ffeGUI, "", 2, 999)
					SetWinTitleText("                [Overwrite Existing File? (hit 'y' or 'n')]")
					HotKeySet("y", "HK_FFmpegResponseYes")
					HotKeySet("n", "HK_FFmpegResponseNo")
					$done_response = 1
				endif

				if $console_out then
					ConsoleAdd($console_out, @ScriptLineNumber, true)
					$job_log &= DoLog(UnifyCRLF($console_out))
					if $done_response then
						switch $done_response
							case 1
								$done_response = 2
							case 2
								HotKeySet("y")
								HotKeySet("n")
								$done_response = 0
						endswitch
					endif
				endif
			wend

			ProcessClose($ffmpeg)
			StdioClose($ffmpeg)

			$thistime = TimerDiff($timestamp)/1000
			$secprt = "	(" & Round($thistime, 2) & " seconds)"
			if $thistime <= 60 then $secprt = ""

			$msg = $LOG_LF & "Completed in " & SecondsToDHMS($thistime) & $secprt  & $LOG_LF & _
					"-----------------------------------" & $LOG_LF
			DoLog($msg)
			$job_log &= $msg
			$job_log &= DoLog(ConsoleAdd($console_out, @ScriptLineNumber)) & $LOG_LF

			if $abort_batch then
				ProcessClose($ffmpeg)
				StdioClose($ffmpeg)
				exitloop
			endif

		endif


		if FileExists($outputfile) then

			if FileGetSize($outputfile) > 0 then

				ArrayAdd($made_files, $outputfile)

				; Add file to recent files and re-build the tray..
				; OK, we're cheating, for now (I'd need to write a 2DAddArray).
				$recent_files = TwoDCol2OneDArray($recent_files)
				ArrayAdd($recent_files, $outputfile, true, true)
				$recent_files = OneToTwoDArray($recent_files)

				; We use this data to re-create our "Recent Files" Tray menu..
				MakeTray()
			else

				$job_log &= DoLog(ConsoleAdd("Deleting zero-length output file: " & $outputfile & $LOG_LF, @ScriptLineNumber)) & $LOG_LF
				FileDelete($outputfile)

			endif

			; Run Post-File Commands, if any..
			$job_log &= RunPostFileCommand()

		endif

	next
	; for $runs = 1 to $run_files[0]



	; ConCATenate Output files..

	if not $abort_batch then

		if $concatenate = $ON and $batch = $ON and $run_files[0] > 1 then

			local $write_loc = $ffmpeg_binary
			local $write_cat = $concat_list
			if $generate_script then
				$write_loc = '"' & $ffmpeg_binary & '"'
				$write_cat = "ffe-concat-list.txt"
			endif

			local $ow_args, $err
			if $overwrite = $ON then $ow_args &= " -y "
			$run_command = $write_loc & " -f concat -safe 0 -i """ & $write_cat & """ " & $ow_args _
							& '-c copy "' & $batch_output_dir & "\joined." & $clean_outputfile_ext & '"'

			if $generate_script then
				$generated &= $run_command & $LOG_LF
			else
				$msg = "Concatenating files.."
				$job_log &= DoLog(ConsoleAdd($LOG_LF & $msg & $LOG_LF, @ScriptLineNumber))
				; re-use process handle so FFmpeg hotkeys still work in concat job..
				ConsoleAdd("", @ScriptLineNumber, true)
				$ffmpeg = Run($run_command, @ScriptDir, @SW_HIDE, BitOr($STDERR_CHILD, $STDIN_CHILD, $STDOUT_CHILD))

				while true

					$err = false
					$console_out = StdErrRead($ffmpeg)
					$err = @error

					if $abort_batch then
						Sleep(250)
						exitloop
					endif

					if StringInStr($console_out, "Overwrite? [y/N]", 0, -1) then
						WinActivate($ffeGUI)
						WinFlash($ffeGUI, "", 2, 999)
						SetWinTitleText("                [Overwrite Existing File? (hit 'y' or 'n')]")
						HotKeySet("y", "HK_FFmpegResponseYes")
						HotKeySet("n", "HK_FFmpegResponseNo")
					endif

					if $console_out then
						ConsoleAdd($console_out, @ScriptLineNumber, true)
						$job_log &= DoLog(UnifyCRLF($console_out))
					endif

					if $err then exitloop
					Sleep(25)
				wend
				ProcessClose($ffmpeg)
				StdioClose($ffmpeg)
			endif

		endif
	endif

	; Report total time for batch..
	if $run_files[0] > 1 then

		$thistime = TimerDiff($total_timestamp)/1000
		$secprt = "	(" & Round($thistime, 2) & " seconds)"
		if $thistime <= 60 then $secprt = ""
		$msg =  $LOG_LF & "Batch completed in " & SecondsToDHMS($thistime) & $secprt & $LOG_LF & _
				"-----------------------------------" & $LOG_LF
		DoLog($msg)
		$job_log &= DoLog(ConsoleAdd($msg, @ScriptLineNumber)) & $LOG_LF

	endif

	; Post-Job Commands..

	if not $abort_batch then
		if $run_post_job_commands = $ON then
			LoadPostCommands()
			RunCommandsFile($post_job_commands_file, $job_log, $generated, "Post")
			Sleep(500)
		endif
	endif


	DoLog("out", $log_append, $LOG_LF & $LOG_LF)
	TrayItemSetState($tray_abort_batch, $TRAY_DISABLE)

	HotKeySet("{PAUSE}")
	HotKeySet("{SCROLLLOCK}")
	HotKeySet("^q")
	HotKeySet("^r")
	HotKeySet("y")
	HotKeySet("n")

	SetWinTitleText()
	GUICtrlSetState($label_abort, $GUI_HIDE)

	SetConsoleOutput($job_log)
	ShowOutputButts()

	; Grab fresh..
	$log_each_job = IniReadCheckBoxValue($ini_path, $my_name, "log_each_job", $ON)
	if $log_each_job = $ON and not $generate_script then SaveOutput($job_log)


	if not $abort_batch then

		if $generate_script then

			local $save_bat, $error = 0
			; Called from command-line, with "generate" flag..
			if $do_gen then
				$save_bat = @WorkingDir & "\ffe.bat"

			; Called from button in GUI..
			else
				local $save_bat_dir = IniRead($ini_path, $my_name, "save_bat_dir", @MyDocumentsDir)
				DialogOpen()
				$save_bat = FileSaveDialog("Save/Append Batch Script", $save_bat_dir, _
					"All (*.*)|Batch files (*.bat)|Command files (*.cmd)", $FD_PATHMUSTEXIST, "ffe.bat", $ffeGUI)
				$error = @error
				DialogClose()
				if FileExists(GetParent($save_bat)) then IniWrite($ini_path, $my_name, "save_bat_dir", GetParent($save_bat))
			endif

			if $error == 0 then
				local $job_batch_file = FileOpen($save_bat, $FO_APPEND+$FO_UTF8_NOBOM)
				FileWrite($job_batch_file, $generated)
				FileClose($job_batch_file)
				ConsoleAdd("Saved batch script to: " & $save_bat & ".", @ScriptLineNumber)
			endif

			FileMove($concat_list, GetParent($save_bat) & "\ffe-concat-list.txt", $FC_OVERWRITE)

		endif

		; Shutdown PC..
		if $do_shutdown or $shutdown_when_done = $ON then
			local $shutdown_response
			if not $do_shutdown then

				DialogOpen()
				$shutdown_response = MsgBox(1, "ffe will now shutdown your computer..", _
					"As instructed, ffe will now shutdown your computer.  " & $MSG_LF & $MSG_LF & _
					"To abort the shutdown process, click [Cancel] within the next 60 seconds." & $MSG_LF & $MSG_LF & _
					"Click [OK] to shutdown immediately.", 60, $ffeGUI)
				DialogClose()
			else
				$shutdown_response = 1
			endif
			if $shutdown_response = 1 or $shutdown_response = -1 then
				Shutdown(BitOr($SD_SHUTDOWN, $SD_POWERDOWN))
				DoQuit()
			endif

		; QUIT..
		elseif $do_quit or $quit_when_done = $ON then

			local $quit_response
			if not $do_quit then
				DialogOpen()
				$quit_response = MsgBox(1,	"ffe will now quit..", _
											"As instructed, ffe will now quit.  " & $MSG_LF & $MSG_LF & _
											"To abort, click [Cancel] within the next 10 seconds.", 10, $ffeGUI)
				DialogClose()
			else
				$quit_response = 1
			endif
			if $quit_response = 1 or $quit_response = -1 then
				DoQuit()
			endif
		endif

	endif


	$do_drop_window = $drop_win_state
	EnableRunningControls()
	UpdateOutputArgs()
	SetHotKeys()
	GUICtrlSetState($edit_console_output, $GUI_FOCUS)


	if $delay_start_at then
		TrayItemSetState($tray_toggle_delayed_start, $OFF)
		$delay_start_at = false
		ConsoleAdd("Delayed Job Complete.", @ScriptLineNumber)
	endif

endfunc








func ______________________PRESETS()
endfunc




; Load the settings from a saved preset into the GUI controls..
; A bit brain-dead, but logical..
func LoadPreset($this_preset="", $init=false)

	local $ctrldown = false
	if _IsPressed(11) then $ctrldown = true

	debug("", @ScriptLineNumber, 6);debug
	debug("", @ScriptLineNumber, 6);debug
	debug("=>>> XXX >>> LoadPreset(): >>>XXX>>>" & $this_preset & "<<<XXX<<<=" & "	INIT: " & $init , @ScriptLineNumber, 6);debug


	; Generally speaking, IF the preference is specified, we update the pref and
	; GUI, otherwise we leave the preference as-is.

	local $param
	local $app_menu = GetSystemMenu($ffeGUI, 0)

	; Command-Line preset launch..
	;
	if StringInStr($this_preset, "|") then
		local $launch_presets = StringSplit($this_preset, "|")
			for $lp = 1 to $launch_presets[0]
				local $loaded = LoadPreset($launch_presets[$lp], $init)
				if not $loaded then return false
			next
			; Will only check the most recently-loaded..
			return true
	endif

	if $this_preset then
		if InArray($presets, $this_preset) and not InArray($not_presets, $this_preset) then
			GUICtrlSetData($combo_presets, $this_preset)
		endif
	else
		if not $init then
			; User selected a preset from the presets drop-down..
			$this_preset = GUICtrlRead($combo_presets)
			$store_filepaths = GUICtrlRead($check_store_filepaths)
			if $ctrldown then
				; we don't alter the control, which will be read when needed (for save, etc.)
				if $store_filepaths = $ON then
					$store_filepaths = $OFF
				else
					$store_filepaths = $ON
				endif
			endif
			debug("$this_preset: " & $this_preset, @ScriptLineNumber, 8);debug
			debug("$store_filepaths: " & $store_filepaths, @ScriptLineNumber, 8);debug
		endif
	endif


	; Blank, load defaults..
	if not $this_preset then $this_preset = $my_name

	if not PresetExists($this_preset) then
		ConsoleAdd("No such preset: " & $this_preset, @ScriptLineNumber)
		return false
	endif

	; Set this handy global variable..
	$current_preset = $this_preset

	if not $init then ConsoleAdd($LOG_LF & "Loading preset: " & $current_preset, @ScriptLineNumber)

	local $read_ini_inputfile = ""
	local $read_ini_outputfile = ""

	; $inputfile not sent on command-line, read ini value..
	if not $inputfile then
		$read_ini_inputfile = ffeDeTokenizeString(IniRead($ini_path, $current_preset, "inputfile", ""))
	endif

	; Keep the output template's @tokens intact here. SetOutputTemplate() stores
	; this raw value; DoArgsCreate() -> ResolveOutputBase() calls
	; ffeDeTokenizeString() for each current input, including each batch item.
	$read_ini_outputfile = IniRead($ini_path, $current_preset, "outputfile", "")

	debug("$read_ini_inputfile: " & $read_ini_inputfile, @ScriptLineNumber, 8);debug
	debug("$read_ini_outputfile: " & $read_ini_outputfile, @ScriptLineNumber, 8);debug

	; Load file paths from ini.
	; IF $store_filepaths = $ON (specified by user in GUI or prefs/preset)
	; or we are loading the $EXIT_PRESET

	; Also if in and out are both specified/discoverable and we are in a go/run() situation..

	if $store_filepaths = $ON or $current_preset = $EXIT_PRESET or _
		($go = true and $read_ini_inputfile) or ($go = true and $inputfile) then

		; INPUT File..
		CRT($inputfile)

		; A wildcard may match only below the source root.
		if IsWild($inputfile) or CheckDirWild($inputfile) then GUICtrlSetData($inp_inputfile, $inputfile)

		debug("$inputfile: " & $inputfile, @ScriptLineNumber, 7);debug

		; $inputfile not sent on command-line, use ini value..
		; This is reset during manual preset loading
		if $read_ini_inputfile then
			$inputfile = $read_ini_inputfile
			GUICtrlSetData($inp_inputfile, $read_ini_inputfile)
		endif

		; OUTPUT File..

		$ini_outputfile = ""
		if $read_ini_outputfile then
			CRT($read_ini_outputfile)
			$ini_outputfile = $read_ini_outputfile
			SetOutputTemplate($ini_outputfile)
		endif
		debug("$ini_outputfile: " & $ini_outputfile, @ScriptLineNumber, 8);debug

	endif


	if $current_preset = $EXIT_PRESET then
		; prevent this popping back into outputfile from exit settings..
		$ini_outputfile = ""
	endif


	if $replace_mode = $ON then
		WipeSettings()
		$x_param = ""
	else
		$x_param = GUICtrlRead($inp_extra_args)
	endif

	$param = IniRead($ini_path, $current_preset, "input_params", "")
	if $param then GUICtrlSetData($inp_input_params, $param)

	$param = IniRead($ini_path, $current_preset, "v_codec", "")
	if $param then GUICtrlSetData($combo_v_codec, $param, $param)
	$param = IniRead($ini_path, $current_preset, "v_bitrate", "")
	if $param then GUICtrlSetData($combo_v_bitrate, $param, $param)

	$param = IniRead($ini_path, $current_preset, "frames_per_second", "")
	if $param then GUICtrlSetData($combo_frames_per_second, $param, $param)

	$param = IniRead($ini_path, $current_preset, "x_size", "")
	if $param then GUICtrlSetData($inp_x_size, $param)
	$param = IniRead($ini_path, $current_preset, "y_size", "")
	if $param then GUICtrlSetData($inp_y_size, $param)

	$param = IniRead($ini_path, $current_preset, "preset_resize", "")
	if $param then GUICtrlSetData($combo_preset_resizes, $param, $param)

	$param = IniRead($ini_path, $current_preset, "crop_width", "")
	if $param then GUICtrlSetData($inp_crop_width, $param)
	$param = IniRead($ini_path, $current_preset, "crop_height", "")
	if $param then GUICtrlSetData($inp_crop_height, $param)
	$param = IniRead($ini_path, $current_preset, "crop_x", "")
	if $param then GUICtrlSetData($inp_crop_x, $param)
	$param = IniRead($ini_path, $current_preset, "crop_y", "")
	if $param then GUICtrlSetData($inp_crop_y, $param)

	$param = IniRead($ini_path, $current_preset, "a_codec", "")
	if $param then GUICtrlSetData($combo_a_codec, $param, $param)
	$param = IniRead($ini_path, $current_preset, "a_bitrate", "")
	if $param then GUICtrlSetData($combo_a_bitrate, $param, $param)

	$param = IniRead($ini_path, $current_preset, "target_type", "")
	if $param then GUICtrlSetData($combo_target_type, $param, $param)

	$param = IniRead($ini_path, $current_preset, "raw_params", "")
	if $param then GUICtrlSetData($inp_extra_args, $x_param & " " & $param)

	$param = IniReadCheckBoxValue($ini_path, $current_preset, "resize_first", "")
	if $param then GUICtrlSetState($check_resize_first, $param)

	$param = IniReadCheckBoxValue($ini_path, $current_preset, "do_output", "")
	if $param then
		$do_output = $param
		if $do_output = $OFF then
			; flip back, also sets altered state and outputs console message
			$do_output = $ON
			ToggleOutput()
		else
			$do_output = $OFF
			ToggleOutput()
		endif
	endif

	$param = IniRead($ini_path, $current_preset, "default_extension", "")
	if $param then
		if $default_extension <> $param and not $init then
			; Let the user know they have a new default extension loaded..
			ConsoleAdd("default_extension: '." & $param & "'", @ScriptLineNumber)
		endif
		$default_extension = $param
	endif

	$param = IniRead($ini_path, $current_preset, "default_audio_extension", "")
	if $param then
		if $default_audio_extension <> $param and not $init then
			ConsoleAdd("default_audio_extension: '." & $param & "'", @ScriptLineNumber)
		endif
		$default_audio_extension = $param
	endif

	; Yes, you can hack this into your presets, if required..
	$param = IniReadCheckBoxValue($ini_path, $current_preset, "kill_ffmpeg_on_exit", "")
	if $param then
		if $param <> $kill_ffmpeg_on_exit and not $init then
			ConsoleAdd("kill_ffmpeg_on_exit: " & Human($param), @ScriptLineNumber)
		endif
		$kill_ffmpeg_on_exit = $param
		CheckMenuItem($app_menu, $am_kill_ffmpeg_on_exit, $kill_ffmpeg_on_exit)
	endif


	; Job button functions..		(TRI-STATE)


	; If ini setting is blank, IniReadCheckBoxValue() will, by design, return 2 ($GUI_INDETERMINATE)
	; Ideally (ffe-generated) prefs are deleted; truly "unset".

	$do_matof = IniReadCheckBoxValue($ini_path, $current_preset, "do_matof", $do_matof, true)
	GUICtrlSetState($check_do_matof, $do_matof)
	debug("$do_matof: " & Human($do_matof), @ScriptLineNumber, 8);debug


	$overwrite = IniReadCheckBoxValue($ini_path, $current_preset, "overwrite", $overwrite, true)
	GUICtrlSetState($check_overwrite, $overwrite)
	debug("$overwrite: " & Human($overwrite), @ScriptLineNumber, 8);debug

	$concatenate = IniReadCheckBoxValue($ini_path, $current_preset, "concatenate", $concatenate, true)
	GUICtrlSetState($check_concatenate, $concatenate)
	debug("$concatenate: " & Human($concatenate), @ScriptLineNumber, 8);debug

	$param = IniReadCheckBoxValue($ini_path, $current_preset, "quit_when_done", $quit_when_done, true)
	if $param then
		if $quit_when_done <> $param and not $init then
			; Inform user of this change from default..
			ConsoleAdd("quit_when_done: " & Human($param), @ScriptLineNumber)
		endif
		$quit_when_done = $param
		GUICtrlSetState($check_quit_when_done, $quit_when_done)
	endif
	debug("$quit_when_done: " & Human($quit_when_done), @ScriptLineNumber, 8);debug

	$param = IniReadCheckBoxValue($ini_path, $current_preset, "shutdown_when_done", $shutdown_when_done, true)
	if $param then
		if $shutdown_when_done <> $param and not $init then
			ConsoleAdd("shutdown_when_done: " & Human($param), @ScriptLineNumber)
		endif
		$shutdown_when_done = $param
		GUICtrlSetState($check_shutdown_when_done, $shutdown_when_done)
	endif
	debug("$shutdown_when_done: " & Human($shutdown_when_done), @ScriptLineNumber, 8);debug

	SetOverwriteTip()
	SetConcatenateFilesTip()
	SetQuitWhenDoneTip()
	SetShutdownWhenDoneTip()

	GetLogLocation($current_preset)
	UpdateOutputArgs()

	; Pre-Post Commands..
	; Do this after input/output is set, so @tokens work..
	; $pre_job_commands_file and $batch_commands_timeout grabbed and Toggles performed inside Load*Commands()

	debug("LOADING PRE+POST COMMANDS.. ", @ScriptLineNumber, 8);debug
	LoadPreCommands(true)
	LoadPostCommands(true)
	LoadPostFileSettings(true)

	GUICtrlSetState($check_run_pre_job_commands, $run_pre_job_commands)
	GUICtrlSetState($check_run_post_job_commands, $run_post_job_commands)
	GUICtrlSetState($check_run_post_file_command, $run_post_file_command)

	SetPreJobTip()
	SetPostJobTip()
	SetPostFileTip()
	GetPresetNotes()

	local $display_pf = $notes_prefix
	if $init then $display_pf = ""
	if $preset_notes then ConsoleAdd($display_pf & $preset_notes & $LOG_LF)

	; All controls are now considered "unaltered"..
	ResetAlteredControls()

	return true
endfunc



func GetPresetNotes()
	$preset_notes = IniRead($ini_path, $current_preset, "notes", "")
	ConvertNewlines($preset_notes)
endfunc


; Wrapper function
func ComboLoadPreset()
	$inputfile = ""
	$preset_loaded = LoadPreset()
endfunc



func ButtSavePreset()
	local $this_preset = GUICtrlRead($combo_presets)
	if $this_preset = $my_name and not _IsPressed(10) then
		DialogOpen()
		local $replace_defaults = MsgBox($MB_YESNO+$MB_TASKMODAL, "Are you SURE?", _
					"If you use the name " & $my_name & ", your settings will become the defaults, " & $MSG_LF & _
					"and will be loaded automatically at startup.  Is this what you want?", 0, $ffeGUI)
		DialogClose()
		if $replace_defaults = 7 then return
	endif
	SavePreset($this_preset)
endfunc




; Ensure user-supplied preset name is safe..
;
func MakePresetNameSafe($user_preset_name)

	debug("$user_preset_name: " & $user_preset_name, @ScriptLineNumber, 6);debug

	; We will use a pipe to separate multiple presets on the command-line..
	$user_preset_name = StringReplace($user_preset_name, "|", "!")
	if @extended then ConsoleAdd("Pipe (special) character replaced with '!'" & $LOG_LF & _
								"A pipe is used to layer multiple presets on the command-line. e.g.." & $LOG_LF & $LOG_LF & _
								"    C:\path\to\ffe.exe run(Test Setup|Test Preset) ""B:\Test\file.mp4""", @ScriptLineNumber)

	; No square brackets inside names - it will mess up "EVERYTHING"..
	$user_preset_name = StringReplace($user_preset_name, "[", "(")
	$user_preset_name = StringReplace($user_preset_name, "]", ")")
	if @extended then ConsoleAdd("Square Brace characters replaced with regular braces." & $LOG_LF & _
								"Preset names are stored *iniside* [square braces].", @ScriptLineNumber)

	; Strip off white space from start+end..
	$user_preset_name = StringStripWS($user_preset_name, 3)

	return $user_preset_name

endfunc


; Save the current settings to a preset..

; We save the setting regardless of whether or not it has a value, in case the
; old preset /does/ have a value; then we are sure to overwrite it.

func SavePreset($this_preset)

	if not $this_preset then return

	$this_preset = MakePresetNameSafe($this_preset)


	$presets = IniReadSectionNames($ini_path)
	if InArray($presets, $this_preset) and $this_preset <> $my_name  and $this_preset <> $EXIT_PRESET and not _IsPressed(10) then
		DialogOpen()
		local $replaceit = MsgBox(4, "Replace Preset?", "That preset exists!" & $MSG_LF & "Do you wish to replace it?", 30, $ffeGUI)
		DialogClose()
		if $replaceit = 7 then return
	endif


	; We read these prefs directly from the GUI controls..

	; Don't store file path if that is disabled. But do on exit..
	if GUICtrlRead($check_store_filepaths) = $ON or $this_preset = $EXIT_PRESET then

		$inputfile = GUICtrlRead($inp_inputfile)
		if $inputfile then IniWrite($ini_path, $this_preset, "inputfile", $inputfile)

		; don't save the MATOF string with the pref..
		; Save the raw template (including tokens), never a generated suffix.
		; No StringReplace($old_matof) is needed: the template has no generated
		; suffix to remove, and matching text typed by the user must survive.
		CaptureOutputTemplate()
		local $saved_output_template = $output_template
		CRT($saved_output_template)
		IniWrite($ini_path, $this_preset, "outputfile", $saved_output_template)

	endif

	SavePref($this_preset, "input_params", $inp_input_params)
	SavePref($this_preset, "v_codec", $combo_v_codec)
	SavePref($this_preset, "v_bitrate", $combo_v_bitrate)
	SavePref($this_preset, "frames_per_second", $combo_frames_per_second)
	SavePref($this_preset, "x_size", $inp_x_size)
	SavePref($this_preset, "y_size", $inp_y_size)
	SavePref($this_preset, "preset_resize", $combo_preset_resizes)
	SavePref($this_preset, "crop_width", $inp_crop_width)
	SavePref($this_preset, "crop_height", $inp_crop_height)
	SavePref($this_preset, "crop_x", $inp_crop_x)
	SavePref($this_preset, "crop_y", $inp_crop_y)
	SavePref($this_preset, "a_codec", $combo_a_codec)
	SavePref($this_preset, "a_bitrate", $combo_a_bitrate)
	SavePref($this_preset, "target_type", $combo_target_type)
	SavePref($this_preset, "raw_params", $inp_extra_args)

	if $altered_resize_first then SavePref($this_preset, "resize_first", $check_resize_first, true)
	if $altered_do_matof then SavePref($this_preset, "do_matof", $check_do_matof, true)


	; Don't use SavePref() for this, no need, also, 0 would not get saved.
	; Users advanced enough to be using this stuff can add parameters to their presets manually.
	; IniWrite($ini_path, $this_preset, "batch_commands_timeout", Int($batch_commands_timeout))
	; IniWriteCheckBoxValue($ini_path, $this_preset, "run_commands_with_shell", $run_commands_with_shell)


	; Job buttons..	(state and bool set on preset load)
	; We don't read the GUI for these next prefs, so the controls better have set the pref itself!

	; Master switch, save setting or delete if unset..
	SavePref($this_preset, "run_pre_job_commands", $check_run_pre_job_commands, true)
	if $pre_job_commands_file then
		IniWrite($ini_path, $this_preset, "pre_job_commands_file", ffeTokenizeString($pre_job_commands_file))
	endif


	SavePref($this_preset, "run_post_file_command", $check_run_post_file_command, true)
	; If not unset, save the associated string (this one is a direct command)..
	if $post_file_command then
		IniWrite($ini_path, $this_preset, "post_file_command", StringReplace($post_file_command, '"', "&quot;"))
	endif

	SavePref($this_preset, "run_post_job_commands", $check_run_post_job_commands, true)
	if $post_job_commands_file then
		IniWrite($ini_path, $this_preset, "post_job_commands_file", ffeTokenizeString($post_job_commands_file))
	endif

	SavePref($this_preset, "overwrite", $check_overwrite, true)
	SavePref($this_preset, "concatenate", $check_concatenate, true)

	; Don't save these to master (ffe) settings..
	if $this_preset <> $my_name then
		SavePref($this_preset, "quit_when_done", $check_quit_when_done, true)
		SavePref($this_preset, "shutdown_when_done", $check_shutdown_when_done, true)
	endif

;	We don't save these with preset save (though they are read from presets). For reference only..
;	$default_extension	$default_audio_extension $kill_ffmpeg_on_exit


	; Not read from GUI, but directly from current $do_output..
	if $altered_do_output then IniWriteCheckBoxValue($ini_path, $this_preset, "do_output", $do_output)


	UpdatePresetsCombo()
	GUICtrlSetData($combo_presets, $this_preset)

	local $sp_str
	local $saved_preset = IniReadSection($ini_path, $this_preset)
	if not IsArray($saved_preset) then return ConsoleAdd("Error displaying saved preset (might be empty).", @ScriptLineNumber)

	; Report the data saved..
	$sp_str = "Saved preset.. " & $LOG_LF & "[" & $this_preset & "]" & $LOG_LF
	for $i = 1 to $saved_preset[0][0]
		$sp_str &= $saved_preset[$i][0] & "=" & $saved_preset[$i][1] & $LOG_LF
	next

	; Update "current preset" global variable..
	$current_preset = $this_preset

	ConsoleAdd($LOG_LF & $sp_str, @ScriptLineNumber)

endfunc



func SavePref($this_preset, $pref_name_string, $ctrl_to_read, $checkbox=false)
	local $ctrl_val = GUICtrlRead($ctrl_to_read)
	if $checkbox then
		IniWriteCheckBoxValue($ini_path, $this_preset, $pref_name_string, $ctrl_val)
		; IniWriteCheckBoxValue() handles empty/unset entries internally (deletes them).
	else
		IniWrite($ini_path, $this_preset, $pref_name_string, $ctrl_val)
		if IniRead($ini_path, $this_preset, $pref_name_string, "") = "" then
			IniDelete($ini_path, $this_preset, $pref_name_string)
		endif
	endif
endfunc


; Delete the current preset from the ini file..

func WipePreset()

	if _IsPressed(10) then return RestoreBackupPreset()

	local $this_preset = GUICtrlRead($combo_presets)
	if not $this_preset then return
	$presets = IniReadSectionNames($ini_path)
	if not InArray($presets, $this_preset) then
		ConsoleAdd("Error wiping preset: '" & $this_preset & "' does not exist!", @ScriptLineNumber)
		return false
	endif

	if $this_preset <> $my_name then
		local $backup_preset = IniReadSection($ini_path, $this_preset)
		if IniDelete($ini_path, $this_preset) then
			; Backup previous backup..
			if InArray($presets, $PRESET_BACKUP_STRING & $this_preset) then
				local $existing_backup = IniReadSection($ini_path, $PRESET_BACKUP_STRING & $this_preset)
				IniWriteSection($ini_path, $PRESET_BACKUP_STRING  & "(previous)--" & $this_preset, $existing_backup)
			endif
			IniWriteSection($ini_path, $PRESET_BACKUP_STRING & $this_preset, $backup_preset)
			ConsoleAdd("Created backup of preset: " & $this_preset, @ScriptLineNumber)
			ConsoleAdd("Wiped preset: " & $this_preset, @ScriptLineNumber)
		else
			ConsoleAdd("Error wiping preset: " & $this_preset & ".", @ScriptLineNumber)
		endif
	else
		DialogOpen()
		MsgBox(0, "Not quite!", _
			"If you wish to reset the default settings, simply hit the reset button" & $MSG_LF & _
			"and then save the (blank) settings to a preset, using the name " & $my_name & "", 0, $ffeGUI)
		DialogClose()
	endif
	; Reset..
	$current_preset = $my_name
	UpdatePresetsCombo()
	return
endfunc



; Delete all the backup presets..

func WipeBackups()

	local $got_backups = false
	$presets = IniReadSectionNames($ini_path)
	if not IsArray($presets) then return
	for $i = 1 to $presets[0]
		; only list the first occurence of each preset (you can have backups inside the ini - only the first is used)
		if StringLeft($presets[$i], 10) = $PRESET_BACKUP_STRING then
			$got_backups = true
			if IniDelete($ini_path, $presets[$i]) then ConsoleAdd("Wiped backup preset: " & $presets[$i] & ".", @ScriptLineNumber)
		endif
	next
	if not $got_backups then ConsoleAdd("No backups found!", @ScriptLineNumber)
endfunc



func RestoreBackupPreset()

	$presets = IniReadSectionNames($ini_path)
	if not IsArray($presets) then return

	local $got_backups = false
	local $msg = "Choose a backup to restore.."

	DialogOpen()

	local $previous_event_mode = AutoItSetOption("GUIOnEventMode", 0)
	local $previous_coord_mode = AutoItSetOption("GUICoordMode", 0)

	local $uw_width = 318
	local $uw_height = 60

	$width = Int(IniRead($ini_path, $my_name, "width", 935))
	if $width < $min_width then $width = $min_width
	$height = Int(IniRead($ini_path, $my_name, "height", 590))
	if $height < $min_height then $height = $min_height
	debug("Dimensions: " & "x: " & $x & " y: " & $y & " width: " & $width & " height: " & $height, @ScriptLineNumber, 8);debug

	local $uw_x = Int(IniRead($ini_path, $my_name, "unwipe_x", -1))
	local $uw_y = Int(IniRead($ini_path, $my_name, "unwipe_y", -1))

	local $butt_width = 50
	local $combo_width = 180

	local $UnWipe = GUICreate("Restore Backup Preset..", $uw_width, $uw_height, $uw_x, $uw_y)

	local $butt_cancel = GUICtrlCreateButton("Cancel", 10, 28, $butt_width, 23)
	local $combo = GUICtrlCreateCombo("", $butt_width+10, 1, $combo_width, 20)
	local $butt_import = GUICtrlCreateButton("Restore", $combo_width+10, -1, $butt_width, 23)

	; Fill up the combo..
	for $i = 1 to $presets[0]
		if StringLeft($presets[$i], 10) = $PRESET_BACKUP_STRING then
			GUICtrlSetData($combo, $presets[$i])
			$got_backups = true
		endif
	next

	GUISetCoord(9, 7)

	; Pay attention people!
	if not $got_backups then $msg = "Got no backups to restore!"
	GUICtrlCreateLabel($msg, 0, 0, $uw_width-20, 20)

	GUISetState(@SW_SHOW, $UnWipe)
	ControlCommand($ffeGUI, "", $combo, "SelectString", $presets[1])

	local $combo_selection, $save_xy

	while 1
		switch GUIGetMsg()
			case $GUI_EVENT_CLOSE, $butt_cancel
				exitloop
			case $butt_import
				$save_xy = true
				$combo_selection = GUICtrlRead($combo)
				if InArray($presets, $combo_selection) then
					local $backup_section = IniReadSection($ini_path, $combo_selection)
					IniDelete($ini_path, $combo_selection)
					local $new_name = StringReplace($combo_selection, $PRESET_BACKUP_STRING, "")
					IniWriteSection($ini_path, $new_name, $backup_section)
					ConsoleAdd("Restored preset: " & $new_name, @ScriptLineNumber)
				endif
				exitloop
		endswitch
		Sleep(10) ; required?
	wend

	if $save_xy then
		local $x_coord = -1, $y_coord = -1
		local $size_array = WinGetPos($UnWipe) ; 0-1-2-3:x-y-w-h
		if IsArray($size_array) then
			$x_coord = $size_array[0]
			$y_coord = $size_array[1]
		endif
		if $x_coord and $x_coord <> -1 then IniWrite($ini_path, $my_name, "unwipe_x", $x_coord)
		if $y_coord and $y_coord <> -1 then IniWrite($ini_path, $my_name, "unwipe_y", $y_coord)
	endif

	GUIDelete($UnWipe)
	AutoItSetOption("GUIOnEventMode", $previous_event_mode)
	AutoItSetOption("GUICoordMode", $previous_coord_mode)
	DialogClose()

	UpdatePresetsCombo()

endfunc



; Context menu wrapper func..
func MenuRefreshPresetsList()
	UpdatePresetsCombo()
endfunc


; Update the combo box with the current presets..
func UpdatePresetsCombo()

	debug("UpdatePresetsCombo()...", @ScriptLineNumber, 9);debug

	local $presets_string = ""
	$presets = IniReadSectionNames($ini_path)
	if not IsArray($presets) then return

	for $i = 1 to $presets[0]
		; Only list the first occurrence of each preset (you can have backups inside the ini - only the first is used)
		if not StringInStr($presets_string, $presets[$i] & "|") and _
			StringLeft($presets[$i], StringLen($PRESET_BACKUP_STRING)) <> $PRESET_BACKUP_STRING then
			$presets_string &= $presets[$i] & "|"
		endif
	next

	; Now we just show it in the list regardless, so users can more easily see how to set defaults. Unless..
	if $sort_presets_list = $ON and $show_ffe_in_sorted_list = $OFF then
		$presets_string = StringReplace($presets_string, "ffe|", "", 1)
	endif

	; Remove special section(s)..
	$presets_string = StringReplace($presets_string, $NAME_BUTTONS & "|", "")
	$presets_string = StringReplace($presets_string, $EXIT_PRESET & "|", "")
	$presets_string = StringReplace($presets_string, $NAME_VIDEO_MAPPINGS & "|", "")
	$presets_string = StringReplace($presets_string, $NAME_AUDIO_MAPPINGS & "|", "")


	CRT($presets_string, "|")
	GUICtrlSetData($combo_presets, "")
	GUICtrlSetData($combo_presets, $presets_string)

	debug("$presets_string: " & $presets_string, @ScriptLineNumber, 9);debug

endfunc





; These four functions could be rolled into one..

func MenuAddToACodecs()
	local $new_user_preset = GUICtrlRead($combo_a_codec)
	if $new_user_preset then
		; This string will *always* be present..
		$audio_codecs = StringReplace($audio_codecs, "|- disable audio -", "|" & $new_user_preset & "|- disable audio -")
		IniWrite($ini_path, $my_name, "audio_codecs", $audio_codecs)
		ConsoleAdd($new_user_preset & " added to audio codecs ", @ScriptLineNumber)
		GUICtrlSetData($combo_a_codec, $audio_codecs)
		ControlCommand($ffeGUI, "", $combo_a_codec, "SelectString", $new_user_preset)
	endif
endfunc
func MenuAddToVCodecs()
	local $new_user_preset = GUICtrlRead($combo_v_codec)
	if $new_user_preset then
		$video_codecs = StringReplace($video_codecs, "|- disable video -", "|" & $new_user_preset & "|- disable video -")
		IniWrite($ini_path, $my_name, "video_codecs", $video_codecs)
		ConsoleAdd($new_user_preset & " added to video codecs ", @ScriptLineNumber)
		GUICtrlSetData($combo_v_codec, $video_codecs)
		ControlCommand($ffeGUI, "", $combo_v_codec, "SelectString", $new_user_preset)
	endif
endfunc
func MenuRemoveFromACodecs()
	local $new_user_preset = GUICtrlRead($combo_a_codec)
	if $new_user_preset then
		; So we don't get a partial match..
		$audio_codecs = StringReplace($audio_codecs, "|" & $new_user_preset & "|", "|")
		IniWrite($ini_path, $my_name, "audio_codecs", $audio_codecs)
		ConsoleAdd($new_user_preset & " removed from audio codecs ", @ScriptLineNumber)
		GUICtrlSetData($combo_a_codec, $audio_codecs)
		$a_codec = IniRead($ini_path, $my_name, "a_codec", "")
		ControlCommand($ffeGUI, "", $combo_a_codec, "SelectString", $a_codec)
	endif
endfunc
func MenuRemoveFromVCodecs()
	local $new_user_preset = GUICtrlRead($combo_v_codec)
	if $new_user_preset then
		; Check for the full string within the codecs..
		$video_codecs = StringReplace($video_codecs, "|" & $new_user_preset & "|", "|")
		IniWrite($ini_path, $my_name, "video_codecs", $video_codecs)
		ConsoleAdd($new_user_preset & " removed from video codecs ", @ScriptLineNumber)
		GUICtrlSetData($combo_v_codec, $video_codecs)
		$v_codec = IniRead($ini_path, $my_name, "v_codec", "")
		ControlCommand($ffeGUI, "", $combo_v_codec, "SelectString", $v_codec)
	endif
endfunc




func MenuRenamePreset()

	if $current_preset = $my_name or  $current_preset = $EXIT_PRESET then
		ConsoleAdd("Cannot rename " & $current_preset & "!", @ScriptLineNumber)
		return
	endif

	DialogOpen()
	local $new_preset_name = CorzFancyInputBox("Rename Preset.. ", _
		"Enter a new name for the preset.. ", $current_preset , "" , 350, 95, default, default, 0, $ffeGUI)
	DialogClose()

	debug("$new_preset_name: " & $new_preset_name, @ScriptLineNumber, 8);debug

	if $new_preset_name then
		if InArray($not_presets, $new_preset_name) then
			ConsoleAdd("Cannot rename: " & $new_preset_name & "!", @ScriptLineNumber)
			return
		endif

		$new_preset_name = MakePresetNameSafe($new_preset_name)
		debug("$new_preset_name: " & $new_preset_name, @ScriptLineNumber, 8);debug

		BetterIniRenameSection($ini_path, $current_preset, $new_preset_name)
		debug("BetterIniRenameSection() error: " & @error, @ScriptLineNumber, 8);debug

		ConsoleAdd("Preset: " & $current_preset &  " renamed to : " & $new_preset_name & ".", @ScriptLineNumber)
		$current_preset = $new_preset_name
		UpdatePresetsCombo()
		ControlCommand($ffeGUI, "", $combo_presets, "SelectString", $current_preset)
	endif
endfunc




func MenuToggleFluidMenu()

	TogglePref($fluid_image_menu)
	IniWriteCheckBoxValue($ini_path, $my_name, "fluid_image_menu", $fluid_image_menu)
	ConsoleAdd("fluid_image_menu set to: " & $fluid_image_menu, @ScriptLineNumber)
	TrayItemSetState($tray_toggle_fluid_image_menu, $fluid_image_menu)

	if $fluid_image_menu = $ON then
		TrayItemSetState($tray_toggle_auto_copy_images, $TRAY_DISABLE)
		TrayItemSetState($tray_choose_image_folder, $TRAY_DISABLE)
		GUICtrlSetState($ctxt_toggle_fluid_image_menu, $GUI_DISABLE)
		GUICtrlSetState($ctxt_toggle_auto_copy_images, $GUI_DISABLE)
	else
		TrayItemSetState($tray_toggle_auto_copy_images, $TRAY_ENABLE)
		TrayItemSetState($tray_choose_image_folder, $TRAY_ENABLE)
		GUICtrlSetState($ctxt_toggle_fluid_image_menu, $GUI_ENABLE)
		GUICtrlSetState($ctxt_toggle_auto_copy_images, $GUI_ENABLE)
	endif
	HideDropWindow()
endfunc





; Some Tray Toggles..



func TrayToggleRetainRecentFiles()
	TogglePref($retain_recent_files)
	IniWriteCheckBoxValue($ini_path, $my_name, "retain_recent_files", $retain_recent_files)
	ConsoleAdd("retain_recent_files set to: " & $retain_recent_files, @ScriptLineNumber)
	TrayItemSetState($tray_toggle_retain_recent_files, $retain_recent_files)
endfunc


func MenuToggleAutoCopy()
	TogglePref($auto_copy_images)
	IniWriteCheckBoxValue($ini_path, $my_name, "auto_copy_images", $auto_copy_images)
	ConsoleAdd("auto_copy_images set to: " & $auto_copy_images, @ScriptLineNumber)
	TrayItemSetState($tray_toggle_auto_copy_images, $auto_copy_images)
	HideDropWindow()
endfunc




; Checks if ffe.ini contains the specified preset (case-insensitive).
; A bit dumb in that it doesn't check if the [section] is or isn't a preset,
; simply that the section exists inside ffe.ini, which is all we need.
; Note: This function is used to check for EXIT_PRESET.
;
func PresetExists($this_preset)
	$presets = IniReadSectionNames($ini_path)
	if not IsArray($presets) then return false
	if InArray($presets, $this_preset) then return $this_preset
	return false
endfunc




; Checks if a given list of ini sections contains presets (return true)
; or is just settings and custom buttons (return false)..
;
func HasPresets(ByRef $ini_section_names_array)
	if not IsArray($ini_section_names_array) then return false
	for $i = 1 to $ini_section_names_array[0]
		if InArray($not_presets, $ini_section_names_array[$i]) then continueloop
		return true
	next
endfunc





func ______________INPUT_OUTPUT()
endfunc




;2do - check which control we click in/out and only update if required

; DoArgsCreate()
; Called on *every* change, user <tab>, click, dropped item, etc..

; A black box. Here be dragons!
; Naming is now split out below: ResolveOutputBase() chooses the clean path,
; BuildMatofOutput() adds the current suffix, and CaptureOutputTemplate()
; distinguishes a user's path from the preview we wrote on the previous call.
;
; Read current controls, build settings, resolve the destination, then expand
; command tokens against that destination. Preview text is not naming state.
;
func DoArgsCreate($batch="null", $run_root="", $run_subdir="")
	debug("", @ScriptLineNumber, 6);debug
	debug("", @ScriptLineNumber, 6);debug
	debug("DoArgsCreate() $batch=" & $batch, @ScriptLineNumber, 6);debug
	debug("$inputfile: " & $inputfile, @ScriptLineNumber, 6);debug

	; Store text selection, if any.
	; This code enables us to retain user text selections even whilst MATOF
	; is working and the input is updating..
	local $caret = _GUICtrlEdit_GetSel($inp_outputfile)

	if $creating_args then return
	$creating_args = true
	CaptureOutputTemplate()

	; During batch, this is set inside DoIt()
	; Explicit batch calls use the current item supplied by DoIt().
	if $batch == "null" then $inputfile = ffeDeTokenizeString(GUICtrlRead($inp_inputfile))
	debug("$inputfile NOW: " & $inputfile, @ScriptLineNumber, 5);debug

	; Clear derived state even when the input has just been cleared.
	$v_codec = ""
	$a_codec = ""
	$matof_string = ""
	$old_matof = ""
	$batch_output_dir = ""
	if not $inputfile then
		$outputfile = ""
		$output_basefile = ""
		$args = ""
		$extra_args = ""
		$x_param = ""
		$no_video = false
		$no_audio = false
		$last_outputfile = $output_template
		GUICtrlSetData($inp_outputfile, $last_outputfile)
		GUICtrlSetData($edit_in_args, "")
		$creating_args = false
		return
	endif

	local $input_params, $read_vcodec, $read_acodec, $write_outputfile


	$extra_args = GUICtrlRead($inp_extra_args)
	debug("$extra_args: " & $extra_args, @ScriptLineNumber, 7);debug
	$x_param = $extra_args

	; We will build this string as we go..
	$matof_string = ""

	if GUICtrlRead($inp_input_params) then
		$input_params = GUICtrlRead($inp_input_params)
	else
		$input_params = ""
	endif

	if GUICtrlRead($check_resize_first) = $ON then
		AddSizing()
		AddCropping()
	else
		AddCropping()
		AddSizing()
	endif

	; YES! DO IT!
	if $overwrite = $ON then $extra_args &= " -y "

	$read_vcodec = GUICtrlRead($combo_v_codec)
	$read_acodec = GUICtrlRead($combo_a_codec)

	if StringInStr($read_vcodec, "disable") and $do_output = $ON then
		$extra_args = " -vn " & $extra_args
		$no_video = true

		if StringInStr($read_acodec, "disable") then
			GUICtrlSetData($combo_a_codec, $audio_codecs)
			$read_acodec = GUICtrlRead($combo_a_codec)
		endif
	else
		$no_video = false
	endif


	if StringInStr($read_acodec, "disable") then
		$extra_args = " -an " & $extra_args
		$no_audio = true
	else
		$no_audio = false
	endif


	; This over-rides everything..
	if GUICtrlRead($combo_target_type) then
		$extra_args &= " -target " & GUICtrlRead($combo_target_type)
		$matof_string &= "[" & GUICtrlRead($combo_target_type) & "]"
		$no_video = false
	endif
	debug("$matof_string: " & $matof_string, @ScriptLineNumber, 7);debug

	if $read_vcodec and not StringInStr($read_vcodec, "disable") then
		$v_codec = " -vcodec " & $read_vcodec
		$matof_string &= "[" & $read_vcodec  & "]"
	else
		$v_codec = ""
	endif
	debug("$matof_string: " & $matof_string, @ScriptLineNumber, 7);debug

	if not $no_video then
		if GUICtrlRead($combo_v_bitrate) then
			$extra_args &= " -b:v " & GUICtrlRead($combo_v_bitrate)
			$matof_string &= "[" & GUICtrlRead($combo_v_bitrate) & "bps]"
		endif

		if GUICtrlRead($combo_frames_per_second) then
			$extra_args &= " -r " & GUICtrlRead($combo_frames_per_second)
			$matof_string &= "[" & GUICtrlRead($combo_frames_per_second) & "fps]"
		endif
	endif
	debug("$matof_string: " & $matof_string, @ScriptLineNumber, 7);debug

	if not $no_audio then
		if $read_acodec then
			$a_codec = " -acodec " & $read_acodec
		else
			$a_codec = ""
		endif

		if $read_acodec then $matof_string &= "[" & $read_acodec  & "]"
		if GUICtrlRead($combo_a_bitrate) then
			$extra_args &= " -ab " & GUICtrlRead($combo_a_bitrate)
			$matof_string &= "[" & GUICtrlRead($combo_a_bitrate) & "]"
		endif
	endif
	debug("$matof_string: " & $matof_string, @ScriptLineNumber, 7);debug


	if GUICtrlRead($inp_extra_args) then
		$matof_string &= "[" & GUICtrlRead($inp_extra_args) & "]"
	endif
	debug("$matof_string: " & $matof_string, @ScriptLineNumber, 7);debug
	; Finished adding args / MATOF strings.


	; Not inside a job (for display purposes only)..
	if $batch == "null" then
		$batch = $OFF
		; It *will* be a batch, when it is actually run..
		if IsWild($inputfile) then $batch = $ON

	endif

	debug("$batch: " & Human($batch), @ScriptLineNumber, 8);debu
	debug("$do_matof: " & Human($do_matof), @ScriptLineNumber, 8);debug

	; If it's a batch, you need matof, or SOMETHING..

	if $do_matof = $OFF and $batch = $ON then
		ToggleMatofStatus(false)
		ConsoleAdd("MATOF required for batch operation!", @ScriptLineNumber)
	endif
	debug("$do_matof: " & Human($do_matof), @ScriptLineNumber, 8);debug



	; Now we set $outputfile..
	; Resolve from raw naming state on every call, including every batch item.
	; The old code used $ini_outputfile both as a preset and as a generated
	; "base name". Keep those separate: never save this preview back into it.
	$output_basefile = ResolveOutputBase($batch, $run_root, $run_subdir)
	$outputfile = $output_basefile
	; By now, $outputfile is a file name, rather than a directory/template.

	; DO MATOF!
	; Determine the extension even when there are no descriptive tags.
	local $output_extension = GetExtension($output_basefile)
	if $do_matof = $ON and $do_output = $ON then
		$output_extension = GetExtFromCodec($read_vcodec, $inputfile)
		if not $output_extension then $output_extension = $default_extension
		$outputfile = BuildMatofOutput($output_basefile, "", $output_extension, "")
	endif
	; Filename tokens refer to the current undecorated destination, with its
	; effective extension. Self-references in a suffix are therefore finite.
	$matof_string = CleanPath(ffeDeTokenizeString($matof_string), ".")
	if $do_matof = $ON and $do_output = $ON then
		$outputfile = BuildMatofOutput($output_basefile, $matof_string, $output_extension, $matof_separator)
		; Remember the rendered suffix, but never strip it from the next preview.
		; The old StringReplace approach needed an empty-string guard and could
		; remove matching user text. Every rebuild now starts from the template.
		if $matof_string then $old_matof = $matof_separator & $matof_string
	endif

	; ffe is handling the output file path.. (not disabled)    go(SINGLE FILE TEST)
	if $do_output = $ON then
		; Updates live during batch run..
		$last_outputfile = $outputfile
		if not (GUICtrlRead($inp_outputfile) == $outputfile) then GUICtrlSetData($inp_outputfile, $outputfile)
		$write_outputfile = '"' & $outputfile & '"'
	else
		; User handling output file in extra args..
		$write_outputfile = ""
	endif

	; Output tokens in executable arguments use the final current destination.
	$x_param = ffeDeTokenizeString(GUICtrlRead($inp_extra_args))
	$extra_args = ffeDeTokenizeString($extra_args)
	$input_params = ffeDeTokenizeString($input_params)


	local $write_loc = $ffmpeg_binary
	if $generate_script then $write_loc = '"' & $ffmpeg_binary & '"'


	; Create the final FFmpeg argument..

	; Input parameters override.
	$input_params = StringStripWS($input_params, 3)

	$args = $write_loc & " " & $input_params & " -i " & """" & $inputfile & """" & _
			$v_codec & " " & $a_codec & " " & $extra_args & " " & $write_outputfile

	; Update the command-line input display..
	GUICtrlSetData($edit_in_args, $args)
	debug("All done creating $args: " & $args, @ScriptLineNumber, 5);debug

	if IsArray($caret) then _GUICtrlEdit_SetSel($inp_outputfile, $caret[0], $caret[1])
	$creating_args = false

endfunc




; During preset load, the output control is set from $ini_outputfile.
; Or the user may have set it to some other gibberish!
; Store that deliberate choice separately from the generated preview.
; Set only for deliberate path changes (preset, browse, drop, or reset).
func SetOutputTemplate($template)
	$output_edit_pending = false
	$output_template = $template
	$last_outputfile = $template
	$old_matof = ""
	GUICtrlSetData($inp_outputfile, $template)
endfunc

; Pick up edits and legacy callers that write directly to the output control.
; The generated preview is deliberately ignored: it is not a new base name.
func CaptureOutputTemplate()
	local $displayed_output = GUICtrlRead($inp_outputfile)
	if $output_edit_pending and $do_matof = $ON and not IsWild(GUICtrlRead($inp_inputfile)) then
		$do_matof = $OFF
		$altered_do_matof = true
		GUICtrlSetState($check_do_matof, $do_matof)
		IniWriteCheckBoxValue($ini_path, $my_name, "do_matof", $do_matof)
		ConsoleAdd("MATOF Status set to: " & Human($do_matof), @ScriptLineNumber)
	endif
	$output_edit_pending = false
	if not ($displayed_output == $last_outputfile) then
		$output_template = $displayed_output
		$last_outputfile = $displayed_output
	endif
endfunc

; A fresh base path for one input. Keep fallback/template tokens unexpanded
; in stored state so @item, @parent, dates, etc. can follow the next job.
func ResolveOutputBase($batch, $run_root, $run_subdir)
	; :look: what if it is wild??
	; Wildcards remain in the preview; DoIt() supplies a concrete input per run.
	local $input_basename = RemoveExtension(BaseName($inputfile))
	local $default_name = $input_basename & "." & $default_extension
	local $seed_dir = GetParent($inputfile)
	if not $seed_dir or StringInStr($inputfile, "://") then $seed_dir = @MyDocumentsDir
	; Self-references in path templates use this current-input seed, not history.
	$outputfile = $seed_dir & "\" & $default_name
	; Grab here, not LoadPreset() as dynamic @tokens may have changed..
	; Keep the cached value raw so the next input can resolve its own @parent.
	$fallback_folder = IniRead($ini_path, $current_preset, "fallback_folder", $fallback_folder)
	local $fallback_template = $fallback_folder
	; Check we aren't grabbing a URL, which has no "parent"..
	if not $fallback_template or (StringInStr($fallback_template, "@parent") and StringInStr($inputfile, "://")) then
		$fallback_template = @MyDocumentsDir
	endif
	local $resolved_fallback = ffeDeTokenizeString($fallback_template)
	$outputfile = $resolved_fallback & "\" & $default_name
	; Preset/manual output @tokens are processed HERE on every rebuild.
	; Do not replace $output_template with this expanded result.
	local $resolved_template = ffeDeTokenizeString($output_template)
	local $template_is_folder = StringRight($resolved_template, 1) = "\"
	CRT($resolved_template)
	; Set output directory from the requested path/fallback dir..
	; Blank output_dir: perhaps a URL and no outputfile (dir) specified in ini.
	; Start with the current fallback; do not inherit the previous run's dir.
	$batch_output_dir = $resolved_fallback
	if $resolved_template then
		; Directory already specified in outputfile..    go(Simple Test)
		if IsDir($resolved_template) or ($run_root and $template_is_folder) then
			$batch_output_dir = $resolved_template
		else
			; Otherwise, use the parent dir of the specified outputfile, if it exists..
			local $template_parent = GetParent($resolved_template)
			if $template_parent and ($run_root or IsDir($template_parent)) then $batch_output_dir = $template_parent
		endif
	endif
	local $destination_dir = $batch_output_dir
	if $run_subdir then $destination_dir &= "\" & $run_subdir
	;
	; BATCH RUN: simply input filename + default_extension, then MATOF extras.
	; SINGLE FILE with a directory or blank template: generate the name too.
	; If counter - increment and create new base name - nah! Still per-input.
	if $batch = $ON or not $resolved_template or IsDir($resolved_template) then
		return $destination_dir & "\" & $default_name
	endif
	; SINGLE FILE.. e.g. https://jell.yfish.us/media/Jellyfish-3-Mbps.mkv
	; Leave output file path as-is (user-set, single file)..
	; Do not replace an explicit name just because the input has changed.
	; FFmpeg needs an extension to work out codecs; if absent, add one..
	if not StringInStr(BaseName($resolved_template), ".") then $resolved_template &= "." & $default_extension
	return $resolved_template
endfunc

; Pure filename composition: no GUI reads, previous suffix removal, or state.
func BuildMatofOutput($base_path, $suffix, $extension, $separator)
	if not $suffix then $separator = ""
	return RemoveExtension($base_path) & $separator & $suffix & "." & $extension
endfunc


func RFCreateArgs()
	$altered_resize_first = true
	AutoCreateArgs()
endfunc


; Create Arguments..

; Create the arguments for the command-line input and MATOF extensions..
; This wrapper function is called when controls are changed.

func AutoCreateArgs()	; outputfile either single complete name or a dir
;	if @GUI_CtrlId = $inp_outputfile then $outputfile = GUICtrlRead($inp_outputfile)
	debug("AutoCreateArgs() --> DoArgsCreate()", @ScriptLineNumber, 6);debug
	DoArgsCreate()
endfunc






; File/Folder dropped onto some input..
; We only handle single files.
; Dropping multiple items results in the last item being placed.
;
; You can, of course, drop folders in, use wildcards to create batches.
;
func GetDroppedItem()

	debug("", @ScriptLineNumber, 6);debug
	debug("GetDroppedItem()..", @ScriptLineNumber, 5);debug

	local $real_file
	; Shift Key down..
	if _IsPressed(10) then
		$real_file = @GUI_DRAGFILE
	else
		$real_file = LnkToReal(@GUI_DRAGFILE)
	endif

	debug("Dropped File ($real_file) set to: " & $real_file, @ScriptLineNumber, 5);debug

	if @GUI_DRAGID = -1 then

		switch @GUI_DROPID

			case $inp_inputfile, $lab_main_drop, $hGIF

				if IsAllowedImage($real_file) then
					$drop_win_image = $real_file
					if $fluid_image_menu = $OFF and $auto_copy_images = $ON then
						FileCopy($real_file, $drop_win_image_folder & "\" & BaseName($real_file))
						if FileExists($drop_win_image_folder & "\" & BaseName($real_file)) then
							$drop_win_image = $drop_win_image_folder & "\" & BaseName($real_file)
						else
							ConsoleAdd("Error copying image to fixed drop images directory.", @ScriptLineNumber)
						endif
					endif
					$switching = true
					Check4GIFmethod()
					HideDropWindow()

				; Not an allowed image..
				else
					; A folder..
					if StringInStr(FileGetAttrib($real_file), "D") then
						GUICtrlSetData($inp_inputfile, $real_file & "\*")
					else
						; Setting the location of FFmpeg binary..
						if BaseName($real_file) = "ffmpeg.exe" then
							SetFFmpegBinLocation($real_file)
							GUICtrlSetData($inp_inputfile, StringReplace(GUICtrlRead($inp_inputfile), $real_file, ""))
							return
						else
							; Replace Input..
							$outputfile = ""
							GUICtrlSetData($inp_inputfile, $real_file)
						endif
					endif
				endif

				UpdateOutputArgs()

				if $drop_command then
					DoDropCommand()
					DoArgsCreate()
				endif


			case $inp_outputfile
				; Replace data..
				$ini_outputfile = $real_file
				SetOutputTemplate($real_file)
				DoArgsCreate()


			case $combo_presets
				ImportData($real_file)
				IniWrite($ini_path, $my_name, "import_dir", GetParent($real_file))

			case $inp_input_params
				; Default behaviour (drop path @ caret)

			case $edit_console_output
				; Ditto

		endswitch

	else
		; @GUI_DRAGID <> -1
		return false
	endif

endfunc



; :look: single files!

; The input has changed - update the output and arguments..

; The old update code tried to preserve the displayed output's parent and
; could overwrite a user-set filename. ResolveOutputBase() now handles this:
; an explicit directory stays selected, a blank template follows the current
; fallback, and an explicit single-file name remains the user's choice.
func UpdateOutputArgs()
	$inputfile = ffeDeTokenizeString(GUICtrlRead($inp_inputfile))
	if IsDir($inputfile) then CRT($inputfile)
	$old_inputfile = $inputfile
	DoArgsCreate()
endfunc



; Use FFmpeg to interrogate the file for cropping values.
; Automatically remove black bars.
;
func DoAutoCrop()

	debug("", @ScriptLineNumber, 6);debug
	debug("DoAutoCrop()...", @ScriptLineNumber, 5);debug

	local $shift_down = false
	if _IsPressed(10) then $shift_down = true

	local $test_file = ffeDeTokenizeString(GUICtrlRead($inp_inputfile))

	if not FileExists($test_file) then
		ConsoleAdd("Unable to detect cropping. File does not exist.")
		return
	endif

	if IsWild($test_file) then
		ConsoleAdd("Can't get cropping values from multiple files!" & $LOG_LF & _
					"If all files have the same cropping, drag in one file and try again."  & $LOG_LF & $LOG_LF & _
					"Afterwards, you can drag in the folder and keep the crop values.")
		return
	endif

	local $auto_crop_frames = Int(IniRead($ini_path, $my_name, "auto_crop_frames", 24))
	local $auto_crop_limit = Int(IniRead($ini_path, $my_name, "auto_crop_limit", 24))
	local $auto_crop_round = Int(IniRead($ini_path, $my_name, "auto_crop_round", 16))
	local $auto_crop_reset = Int(IniRead($ini_path, $my_name, "auto_crop_reset", 0))


	; If <shift> is down, number of frames to test can be set..

	; false = don't save value (right-click the control for that)
	if $shift_down then
		$auto_crop_frames = UserEditCropTestFrames($auto_crop_frames, false)
		if @error then ConsoleAdd($LOG_LF & "Frame test number change cancelled." & $LOG_LF & " Using default values..")
	endif

	debug("$auto_crop_frames: " & $auto_crop_frames, @ScriptLineNumber, 8);debug
	debug("$auto_crop_limit: " & $auto_crop_limit, @ScriptLineNumber, 8);debug
	debug("$auto_crop_round: " & $auto_crop_round, @ScriptLineNumber, 8);debug
	debug("$auto_crop_reset: " & $auto_crop_reset, @ScriptLineNumber, 8);debug

	local $tmpfile = @TempDir & "\ffe_crop_detect.mkv"
	local $detect_args = " -frames:v " & $auto_crop_frames & _
						"  -vf cropdetect=" & $auto_crop_limit & ":" & $auto_crop_round & ":" & $auto_crop_reset & " "
	local $ffmpeg_get_crop = Run($ffmpeg_binary & ' -i "' & $test_file & '" ' & $detect_args & $tmpfile, "", @SW_HIDE, $STDERR_MERGED)
	local $c_out, $v_out

	ConsoleAdd($LOG_LF & _
		"Running FFmpeg cropdetect with the following settings:" & $LOG_LF & $LOG_LF& _
		"Cropdetect frames: " & $auto_crop_frames & $LOG_LF & _
		"Black threshold: " & $auto_crop_limit  & $LOG_LF & _
		"Dimension rounding :" & $auto_crop_round & $LOG_LF & _
		"Calculation reset: " & $auto_crop_reset & $LOG_LF & $LOG_LF & _
		"Please wait a moment.." & $LOG_LF)

	while true
		$c_out = StdOutRead($ffmpeg_get_crop)
		if @error then exitloop
		if StringInStr($c_out, "crop=") then $v_out &= $c_out
		Sleep(10)
	wend

	debug("cropdetect out: " & $v_out, @ScriptLineNumber, 9);debug
	ProcessClose($ffmpeg_get_crop)
	StdioClose($ffmpeg_get_crop)
	FileDelete($tmpfile)

	local $crop_settings
	$crop_settings = StringMid($v_out, StringInStr($v_out, "crop=", 0, -1))
	$crop_settings = StringStripWS($crop_settings, 3)
	; Although this value happens to *exactly* match the string we will send to FFmpeg,
	; we don't do that. We fill in the inputs and let DoArgsCreate() generate the arguments.
	local $display_cs = $crop_settings
	$crop_settings = StringTrimLeft($crop_settings, 5)
	$crop_settings = StringSplit($crop_settings, ":")

	if IsArray($crop_settings) and $crop_settings[0] = 4 then
		GUICtrlSetData($inp_crop_width, $crop_settings[1])
		GUICtrlSetData($inp_crop_height, $crop_settings[2])
		GUICtrlSetData($inp_crop_x, $crop_settings[3])
		GUICtrlSetData($inp_crop_y, $crop_settings[4])
		ConsoleAdd("FFmpeg cropdetect (" & BaseName($test_file) & "): " & $display_cs)
	endif

endfunc




func AddInputOverrideFileArgs()
	local $current_data = GUICtrlRead($inp_input_params)
	if $current_data then $current_data &= " "
	GUICtrlSetData($inp_input_params, $current_data & '-i ""')
	ControlFocus($ffeGUI, "", $inp_input_params)
	ControlSend($ffeGUI, "", $inp_input_params, "{RIGHT}")
	ControlSend($ffeGUI, "", $inp_input_params, "{LEFT}")
endfunc


func DelInputOverrideFileArgs()
	GUICtrlSetData($inp_input_params, "")
endfunc






; Add resizing parameters..
; TODO switch to -vf scale=

func AddSizing()

	local $resize = ""
	local $matof_tmp_string = ""

	local $x_size = GUICtrlRead($inp_x_size)
	local $y_size = GUICtrlRead($inp_y_size)

	if $x_size and $y_size then
		$resize = $x_size & "x" & $y_size
		$matof_tmp_string = "[" & $resize & "]"
	endif

	if GUICtrlRead($combo_preset_resizes) then
		$resize = GUICtrlRead($combo_preset_resizes)
		$matof_tmp_string = "[size=" & $resize & "]"
	endif

	$matof_string &= $matof_tmp_string
	if $resize then $extra_args &= " -s " & $resize
endfunc





; Add cropping parameters..
;
; New syntax:
; -vf "crop=out_w:out_h:x:y"
;
func AddCropping()

	debug("", @ScriptLineNumber, 6);debug
	debug("AddCropping()...", @ScriptLineNumber, 6);debug

	local $do_tally = 0
	if GUICtrlRead($inp_crop_width) then $do_tally += 1
	if GUICtrlRead($inp_crop_height) then $do_tally += 1
	if GUICtrlRead($inp_crop_x) then $do_tally += 3
	if GUICtrlRead($inp_crop_y) then $do_tally += 3

	local $my_args

	switch $do_tally
		case 2
			$my_args = ' -vf "crop=' & GUICtrlRead($inp_crop_width) & ':' & GUICtrlRead($inp_crop_height) & '"'
		case 8
			$my_args = ' -vf "crop=' & GUICtrlRead($inp_crop_width) & ':' & GUICtrlRead($inp_crop_height) & _
						':' & GUICtrlRead($inp_crop_x) & ':' & GUICtrlRead($inp_crop_y) & '"'
	endswitch

	if $my_args then
		$extra_args &= $my_args
		;2do write a generic function for this..
		$matof_string &= "[" & StringStripWS(CleanPath(StringReplace($my_args, '"', ""), "."), 3) & "]"
	endif

	debug("$matof_string: " & $matof_string, @ScriptLineNumber, 7);debug

endfunc


func CreateCodecContexts()
	debug("", @ScriptLineNumber, 6);debug
	debug("$CreateCodecContexts(): $auto_codecs = " & Human($auto_codecs), @ScriptLineNumber, 6);debug

	GUICtrlDelete($ctxt_vcombo)
	GUICtrlDelete($ctxt_acombo)

	$ctxt_vcombo = GUICtrlCreateContextMenu($combo_v_codec)

	local $itm_v1 = GUICtrlCreateMenuItem("Add to Codecs List..", $ctxt_vcombo)
	GUICtrlSetOnEvent(-1, "MenuAddToVCodecs")
	local $itm_v2 = GUICtrlCreateMenuItem("Remove from Codecs List..", $ctxt_vcombo)
	GUICtrlSetOnEvent(-1, "MenuRemoveFromVCodecs")

	$ctxt_acombo = GUICtrlCreateContextMenu($combo_a_codec)

	local $itm_a1 = GUICtrlCreateMenuItem("Add to Codecs List..", $ctxt_acombo)
	GUICtrlSetOnEvent(-1, "MenuAddToACodecs")
	local $itm_a2 = GUICtrlCreateMenuItem("Remove from Codecs List..", $ctxt_acombo)
	GUICtrlSetOnEvent(-1, "MenuRemoveFromACodecs")


	if $auto_codecs = $ON then
		GUICtrlSetState($itm_v1, $GUI_DISABLE)
		GUICtrlSetState($itm_v2, $GUI_DISABLE)
		GUICtrlSetState($itm_a1, $GUI_DISABLE)
		GUICtrlSetState($itm_a2, $GUI_DISABLE)
	endif

endfunc




; Check for correct extension (by codec)..

func GetExtFromCodec($video_codec, $file_name="")

	debug("GetExtFromCodec() 	video_codec: " & $video_codec & "	file_name: " & $file_name, @ScriptLineNumber, 6);debug

	local $this_ext
	if not StringInStr($extra_args, "-vn") then
	; -vn = disable video

		local $map_set = false

		switch true

			case $video_codec = "copy"
				$this_ext = GetExtension($file_name)
				if IsWild($this_ext) then $this_ext = $default_extension
				debug("COPY >> $this_ext: " & $this_ext, @ScriptLineNumber, 8);debug
				$map_set = true

			case else
				; Read video extension mappings from ini file into an array..
				local $video_mappings = IniReadSection($ini_path, $NAME_VIDEO_MAPPINGS)
				debugPrintArray($video_mappings, "$video_mappings:", @ScriptLineNumber, 8);debug

				if IsArray($video_mappings) then
					for $i = 1 to $video_mappings[0][0]
						if StringInStr($video_codec, $video_mappings[$i][0]) then
							$this_ext = $video_mappings[$i][1]
							$map_set = true
							exitloop
						endif
					next
				endif

		endswitch

		if not $map_set then $this_ext = $default_extension
		debug("$this_ext: " & $this_ext, @ScriptLineNumber, 8);debug



	; Video is disabled..
	; Try to guess some likely types..

	else

		local $a_codec_inp = GUICtrlRead($combo_a_codec)

		if $a_codec_inp = "copy" then

			; Already exists in "$known_files" (associative array), use the pre-determined extension..
			if AAExists($known_files, $file_name) then
				$this_ext = AAGetItem($known_files, $file_name)
				debug("this_ext1: " & $this_ext, @ScriptLineNumber, 7);debug

			; Unknown file - run probe and find out what audio codec is used..
			else
				$this_ext = ProbeFileForCodec($file_name)
				debug("this_ext2: " & $this_ext, @ScriptLineNumber, 7);debug
				$this_ext = GetExtFromCodecName($this_ext)
				debug("this_ext3: " & $this_ext, @ScriptLineNumber, 7);debug
				; Store file = audio-ext key=val pair in AA
				if $this_ext then AAAdd($known_files, $file_name, $this_ext)
			endif
		else
			$this_ext = GetExtFromCodecName($a_codec_inp)
		endif
	endif

	return $this_ext

endfunc




; Use ffprobe to grab the audio codec name..
; Used when video is disabled and user is copying audio to a pure audio track..
;
func ProbeFileForCodec($file)

	debug("ProbeFileForCodec: " & $file, @ScriptLineNumber, 6);debug

	if not FileExists($file) then return false

	; Already probed this file..
	; This should have been checked before calling!
	if AAExists($known_files, $file) then return AAGetItem($known_files, $file)

	; Need an actual file to work on..
	if IsWild($file) then return false

	; If not already in $known_files Associative Array - run probe and find out what audio codec is used..
	local $probe_data, $err
	GetFFprobeLocation()
	debug("ffprobe_loc: " & $ffprobe_loc, @ScriptLineNumber, 7);debug

	if FileExists($ffprobe_loc) then						; select first audio stream..
		local $probe_file = Run( $ffprobe_loc & " -v error -select_streams a:0 -show_entries stream=codec_name " & _
														' "'& $file & '"', "", @SW_HIDE, $STDOUT_CHILD)
	else
		return false
	endif

	local $console_out

	while true
		$err = false
		$console_out = StdOutRead($probe_file)
		$err = @error
		if $console_out then $probe_data &= $console_out
		if $err then exitloop
		Sleep(5)
	wend

	ProcessClose($probe_file)
	StdioClose($probe_file)

	debug("$probe_data: " & $probe_data, @ScriptLineNumber, 8);debug

	; Better than simply checking existence of variable
	if not StringInStr($probe_data, "codec_name") then return false
	$probe_data = StringSplit($probe_data, "=")

	debugPrintArray($probe_data, "$probe_data:", @ScriptLineNumber, 8);debug

	; Could specify StringInStr(,,-3), but best to let StringStripWS() handle /whatever/
	; Line-break comes - I don't know how you built your ffprobe!
	return StringStripWS(StringMid($probe_data[2], 1, StringInStr($probe_data[2], "[")-1), 3)

endfunc



; Convert codec names into usable audio file extensions..
;
func GetExtFromCodecName($codec_name)

	debug("GetExtFromCodecName() Codec name: " & $codec_name, @ScriptLineNumber, 7);debug

	local $this_ext
	local $map_set = false

	local $audio_mappings = IniReadSection($ini_path, $NAME_AUDIO_MAPPINGS)
	debugPrintArray($audio_mappings, "$audio_mappings:", @ScriptLineNumber, 8);debug

	if IsArray($audio_mappings) then

		for $i = 1 to $audio_mappings[0][0]
			if StringInStr($codec_name, $audio_mappings[$i][0]) then
				$this_ext = $audio_mappings[$i][1]
				$map_set = true
				exitloop
			endif
		next
	endif

	if not $map_set then $this_ext = $default_audio_extension
	debug("$this_ext: " & $this_ext, @ScriptLineNumber, 8);debug

	return $this_ext

endfunc





; Hardly worth combining these..
;
func EditFFmpegTask()
	local $insert = "remains"
	debug("EditFFmpegTask()..", @ScriptLineNumber, 6);debug
	local $ffmpeg_command = IniRead($ini_path, $my_name, "ffmpeg_command", "-help")
	DialogOpen()
	; They can enter an empty value, no problem.
	local $new_ffmpeg_command = CorzFancyInputBox("New FFmpeg Command.. ", _
		"Enter a command for the FFmpeg button (you can use @tokens).. ", $ffmpeg_command, "", 350, 95, default, default, 0, $ffeGUI)
	if @error = 0 then
		$new_ffmpeg_command = ffeTokenizeString($new_ffmpeg_command)
		if $ffmpeg_command <> $new_ffmpeg_command then
			; Not strictly necessary - it's picked-up at run-time..
			$ffmpeg_command = $new_ffmpeg_command
			$insert = "now set to"
			_GUIToolTip_Destroy($tip_ffmpeg_task)
			$tip_ffmpeg_task = GUICtrlSetTipOptional($check_run_ffmpeg_task, $MSG_LF & _
									"Current command: " & $new_ffmpeg_command, "Quick FFmpeg Task")
			IniWrite($ini_path, $my_name, "ffmpeg_command", ffeTokenizeString($new_ffmpeg_command))
		endif
	endif
	DialogClose()
	ConsoleAdd("FFmpeg command " & $insert & ": " & $ffmpeg_command, @ScriptLineNumber)
endfunc


func EditFFplayTask()
	local $insert = "remains"
	debug("EditFFplayTask()..", @ScriptLineNumber, 6);debug
	$ffplay_command = IniRead($ini_path, $my_name, "ffplay_command", "-help")
	DialogOpen()
	local $new_ffplay_command = CorzFancyInputBox("New FFplay Command.. ", _
		"Enter a command for the FFplay button (you can use @tokens).. ", $ffplay_command, "", 350, 95, default, default, 0, $ffeGUI)
	if @error = 0 then
		$new_ffplay_command = ffeTokenizeString($new_ffplay_command)
		if $ffplay_command <> $new_ffplay_command then
			$ffplay_command = $new_ffplay_command
			ConsoleAdd("FFplay command now set to: " & $ffplay_command, @ScriptLineNumber)
			$insert = "now set to"
			_GUIToolTip_Destroy($tip_ffplay_task)
			$tip_ffplay_task = GUICtrlSetTipOptional($check_run_ffplay_task, $MSG_LF & _
								"Current command: " & $new_ffplay_command, "Quick FFplay Task")
			IniWrite($ini_path, $my_name, "ffplay_command", ffeTokenizeString($new_ffplay_command))
		endif
	endif
	DialogClose()
	ConsoleAdd("FFplay command " & $insert & ": " & $ffplay_command, @ScriptLineNumber)
endfunc




; Launch FFmpeg and display the output (used for Quick Task and About FFmpeg)..
; Note $STDERR_MERGED for the ffmpeg task..
;
func DoFFmpegCommand($my_args)

	debug("DoFFmpegCommand() $my_args = .." & $my_args, @ScriptLineNumber, 7);debug

	local $ffmpeg_info = Run($ffmpeg_binary & " " & $my_args, "", @SW_HIDE, $STDERR_MERGED)
	local $c_out, $v_out

	while true
		$c_out = StdOutRead($ffmpeg_info)
		if @error then exitloop
		if $c_out then
			ConsoleAdd($c_out, @ScriptLineNumber)
			$v_out &= $c_out
		endif
		Sleep(10)
	wend

	ProcessClose($ffmpeg_info)
	StdioClose($ffmpeg_info)
	SetConsoleOutput(StringStripWS($v_out, 3), true) ; and scroll to top

endfunc


; Quick Task..
func RunFFmpegQuickTask()
	GUICtrlSetState($check_run_ffmpeg_task, $GUI_UNCHECKED)
	$ffmpeg_command = ffeDeTokenizeString(IniRead($ini_path, $my_name, "ffmpeg_command", "-help"))
	DoFFmpegCommand($ffmpeg_command)
endfunc


; Drop command..
;
func PlayIt()
	RunFFplayQuickTask($inputfile)
endfunc


func ClickRunFFplayQuickTask()
	RunFFplayQuickTask()
endfunc


; User clicked the ffplay task button..
;
func RunFFplayQuickTask($command="")

	debug("RunFFplayQuickTask() ", @ScriptLineNumber, 7);debug

	GUICtrlSetState($check_run_ffplay_task, $GUI_UNCHECKED)

	; We expect the ffplay.exe binary to be next to ffmpeg.exe, of course..
	local $ffplay_binary = GetParent($ffmpeg_binary) & "\ffplay.exe"
	if not FileExists($ffplay_binary) then
		ConsoleAdd("ffplay.exe not found! Please place it next to ffmpeg.exe", @ScriptLineNumber)
		return false
	endif

	if $command then
		$ffplay_command = $command
	else
		$ffplay_command = ffeDeTokenizeString(IniRead($ini_path, $my_name, "ffplay_command", "-help"))
	endif

	ConsoleAdd("Running FFplay task: " & $ffplay_binary & " " & $ffplay_command, @ScriptLineNumber)

	$show_ffplay_output = IniReadCheckBoxValue($ini_path, $my_name, "show_ffplay_output", $OFF)
	if $show_ffplay_output = $ON then
		local $ffplay_run = Run($ffplay_binary & " " & $ffplay_command, "", @SW_SHOW, $STDERR_CHILD)
		local $c_out
		while true
			$c_out = StdErrRead($ffplay_run)
			if @error then exitloop
			if $c_out then ConsoleAdd($c_out, @ScriptLineNumber)
			Sleep(10)
		wend
		ProcessClose($ffplay_run)
		StdioClose($ffplay_run)
	else
		Run($ffplay_binary & " " & $ffplay_command)
	endif

endfunc



; Suspend/Resume a process.
; NOTE: You *must* do this before sending DebugSetProcessKillOnExit, or else it will have no effect.
func ProcessSuspendResume($proc_name, $do_suspend=true)
   if IsString($proc_name) then $proc_name = ProcessExists($proc_name)
   if not $proc_name then return SetError(2, 0, 0)
   if $do_suspend then
	  DllCall('kernel32.dll','ptr','DebugActiveProcess','int',$proc_name)
							; note: opens process with PROCESS_ALL_ACCESS
   else
	  DllCall('kernel32.dll','ptr','DebugActiveProcessStop','int',$proc_name)
   endif
endfunc










func _____________JOB_CONTROLS()
endfunc




func EditPostJob()
	if $post_job_commands_file then
		OpenSomething($post_job_commands_file)
		LoadPostCommands()
	endif
endfunc

func EditPreJob()
	if $pre_job_commands_file then
		OpenSomething($pre_job_commands_file)
		LoadPreCommands()
	endif
endfunc



; Load all post-file settings and the post-file command..
;
; $get_fresh is set to true during preset load, which is the only time manually
; set controls are replaced.
;
; Inherit these from default preset and current settings..
;
func LoadPostFileSettings($get_fresh=false)
	debug("", @ScriptLineNumber, 6);debug
	debug("LoadPostFileSettings((get_fresh:" & $get_fresh & ") current preset: " & Human($current_preset), @ScriptLineNumber, 8);debug
	if $get_fresh then
		; We don't want to change this if it's been altered manually..
		$post_file_command = IniRead($ini_path, $current_preset, "post_file_command", $post_file_command)
		$post_file_command = StringReplace($post_file_command, "&quot;", '"')
		$run_post_file_command = IniReadCheckBoxValue($ini_path, $current_preset, "run_post_file_command", $run_post_file_command, true)
	endif
	$post_file_run_style = IniRead($ini_path, $current_preset, "post_file_run_style", $post_file_run_style)
	$post_file_capture = IniReadCheckBoxValue($ini_path, $current_preset, "post_file_capture", $post_file_capture)
	$post_file_show = IniReadCheckBoxValue($ini_path, $current_preset, "post_file_show", $post_file_show)
	debug("$run_post_file_command: " & Human($run_post_file_command), @ScriptLineNumber, 8);debug
	debug("$post_file_command: " & $post_file_command, @ScriptLineNumber, 8);debug
	debug("$post_file_run_style: " & $post_file_run_style, @ScriptLineNumber, 8);debug
	debug("$post_file_capture: " & Human($post_file_capture), @ScriptLineNumber, 8);debug
	debug("$post_file_show: " & Human($post_file_show), @ScriptLineNumber, 8);debug
	return $post_file_command
endfunc



; Pre / Post Commands..
;
; These functions are called whenever there is a change in command file or presets..
;
; Return true if command file loaded successfully. False if not.
;
func LoadPreCommands($get_fresh=false)
	debug("", @ScriptLineNumber, 6);debug
	debug("LoadPreCommands(get_fresh:" & $get_fresh & ")...............", @ScriptLineNumber, 5);debug
	if $get_fresh then
		$run_pre_job_commands = IniReadCheckBoxValue($ini_path, $current_preset, "run_pre_job_commands", $run_pre_job_commands)
	endif
	debug("$run_pre_job_commands: " & Human($run_pre_job_commands), @ScriptLineNumber, 8);debug

	local $tmp_cf = IniRead($ini_path, $current_preset, "pre_job_commands_file", "---")
	if not $tmp_cf or $tmp_cf = "---" then $tmp_cf = $pre_job_commands_file
	$pre_job_commands_file = ffeDeTokenizeString($tmp_cf)

	debug("$pre_job_commands_file: " & $pre_job_commands_file, @ScriptLineNumber, 8);debug
	if LoadCommandsFile($pre_job_commands_file, "pre", "run_pre_job_commands", $check_run_pre_job_commands) then
		return true
	endif
	return false
endfunc

func LoadPostCommands($get_fresh=false)
	debug("", @ScriptLineNumber, 6);debug
	debug("LoadPostCommands(get_fresh:" & $get_fresh & ").................", @ScriptLineNumber, 5);debug
	if $get_fresh then
		$run_post_job_commands = IniReadCheckBoxValue($ini_path, $current_preset, "run_post_job_commands", $run_post_job_commands)
	endif
	debug("$run_post_job_commands: " & Human($run_post_job_commands), @ScriptLineNumber, 8);debug

	local $tmp_cf = IniRead($ini_path, $current_preset, "post_job_commands_file", "---")
	if not $tmp_cf or $tmp_cf = "---" then $tmp_cf = $post_job_commands_file
	$post_job_commands_file = ffeDeTokenizeString($tmp_cf)

	debug("$post_job_commands_file: " & $post_job_commands_file, @ScriptLineNumber, 8);debug
	if LoadCommandsFile($post_job_commands_file, "post", "run_post_job_commands", $check_run_post_job_commands) then
		return true
	endif
	return false
endfunc


; The master pre-job and post-job command file loader.
;
; Reads the ini value for the file's path, sets the checkboxes to the correct values.
; Enables/disables checkboxes.
;
; Returns true if command file exists, false if not.
;
func LoadCommandsFile(ByRef $commands_file, $type, $main_switch, $control)

	debug("", @ScriptLineNumber, 6);debug
	debug("LoadCommandsFile(" & $commands_file & "," & $type  & "," & $main_switch & "," & $control & ")...", @ScriptLineNumber, 5);debug

	local $do_this = Eval($main_switch)
	local $return = false

	if $commands_file then
		$commands_file = SetRelPathToDataDir($commands_file)
	else
		if $do_this = $ON then ConsoleAdd("No " & $type & "-job commands file specified!", @ScriptLineNumber)
		return
	endif

	; NOTE: @parent\batch.bat (for example) might not yet exist.
	if FileExists($commands_file) then
		if $do_this = $ON then
			ConsoleAdd($type & "-job commands file loaded: " & $commands_file, @ScriptLineNumber)
		endif
		$return = true
	else
		if $do_this = $ON then
			ConsoleAdd($type & "-job commands file not found: " & $commands_file, @ScriptLineNumber)
		endif
	endif

	$batch_commands_timeout = Int(IniRead($ini_path, $current_preset, "batch_commands_timeout", 0))
	debug("$batch_commands_timeout: " & $batch_commands_timeout, @ScriptLineNumber, 8);debug

	$run_commands_with_shell = IniReadCheckBoxValue($ini_path, $current_preset, "run_commands_with_shell", $run_commands_with_shell)
	debug("$run_commands_with_shell: " & Human($run_commands_with_shell), @ScriptLineNumber, 8);debug

	; Update "create" / "edit" tray menu item..
	MakeTray()
	return $return
endfunc



; Pre-Job command FILE..
func SpecifyPreJobCMDsFile()
	CreateJobCommands($pre_job_commands_file, "pre-job")
endfunc

; Post-File COMMAND..
func SpecifyPostFileCommand()
	DialogOpen()
	local $user_command = CorzFancyInputBox("Post-File Command..",	_
		"Enter the FULL command. Put quotes around any paths with spaces. " & $MSG_LF & _
		"NOTE: You can drag files into this input. You can also use @tokens.", _
	$post_file_command, "", @DesktopWidth/2, 115, default, default, 0, $ffeGUI)
	switch @error
		case 1
			ConsoleAdd("Dialog cancelled. Post-File Command still: '" & $post_file_command & "'.", @ScriptLineNumber)
		case 2
			ConsoleAdd("Dialog time-out. Post-File Command still: '" & $post_file_command & "'.", @ScriptLineNumber)
		case 0
			$post_file_command = $user_command
			ConsoleAdd("Post-File Command set to '" & $post_file_command & "'", @ScriptLineNumber)
	endswitch
	DialogClose()
endfunc

; Post-Job command FILE..
func SpecifyPostJobCMDsFile()
	CreateJobCommands($post_job_commands_file, "post-job")
endfunc



func CreateJobCommands(ByRef $commands_file, $type, $do_edit=true)

	local $def_input = "@datadir\" & StringLower($type) & "-commands.bat"
	if $commands_file then $def_input = ffeTokenizeString($commands_file)
	DialogOpen()
	local $user_prc_filename = CorzFancyInputBox( "Specify A " & $type & " Commands File.. ", _
						"Please specify the location of the " & $type & " Commands file.. " & $MSG_LF & _
						"NOTE: You can drag files into this input. You can also use @Tokens.", $def_input , "" , @DesktopWidth/2, 115, _
						default, default, 0, $ffeGUI)
	DialogClose()
	if $user_prc_filename then

		local $real_user_prc_filename = ffeDeTokenizeString($user_prc_filename)

		if $user_prc_filename and StringLeft($real_user_prc_filename, 2) <> '\\' _
			and StringMid($real_user_prc_filename, 2, 1) <> ':' then
			$real_user_prc_filename = $data_dir & "\" & $real_user_prc_filename
		endif
		$commands_file = $real_user_prc_filename

		if FileExists($real_user_prc_filename) then
			ConsoleAdd("'" & $commands_file & "' already exists!", @ScriptLineNumber)
		else
			ConsoleAdd("Creating: """ & $commands_file & '"', @ScriptLineNumber)
			FileWrite($real_user_prc_filename, ":: ffe " & $type & " commands" & $LOG_LF & $LOG_LF)
		endif

		switch $type
			case "Pre-Job"
				LoadPreCommands()
			case "Post-Job"
				LoadPostCommands()
		endswitch
		if $do_edit then OpenSomething($commands_file)
	endif

endfunc



; User clicked on a (tri-state) job button..

func ClickSetPreJobState()
	$run_pre_job_commands = GUICtrlRead($check_run_pre_job_commands)
	SetPreJobTip()
	if $run_pre_job_commands = $ON then
		ConsoleAdd("Pre-job commands: " & Human($run_pre_job_commands), @ScriptLineNumber)
		if not LoadPreCommands() then
			SpecifyPreJobCMDsFile()
		endif
	endif
endfunc
func SetPreJobTip()
	_GUIToolTip_Destroy($tip_pre_job)
	$tip_pre_job = GUICtrlSetTipOptional($check_run_pre_job_commands, $tristate_prejob_tip & _
													Human($run_pre_job_commands), $tristate_prejob_title)
endfunc

func ClickSetPostJobState()
	$run_post_job_commands = GUICtrlRead($check_run_post_job_commands)
	SetPostJobTip()
	if $run_post_job_commands = $ON then
		ConsoleAdd("Post-job commands: " & Human($run_post_job_commands), @ScriptLineNumber)
		if not LoadPostCommands() then
			SpecifyPostJobCMDsFile()
		endif
	endif
endfunc
func SetPostJobTip()
	_GUIToolTip_Destroy($tip_post_job)
	$tip_post_job = GUICtrlSetTipOptional($check_run_post_job_commands, $tristate_postjob_tip & _
													Human($run_post_job_commands), $tristate_postjob_title)
endfunc

func ClickSetPostFileState()
	$run_post_file_command = GUICtrlRead($check_run_post_file_command)
	SetPostFileTip()
	if $run_post_file_command = $ON then
		ConsoleAdd("post-file command: " & $post_file_command, @ScriptLineNumber)
		if not LoadPostFileSettings() then
			SpecifyPostFileCommand()
		endif
	endif
endfunc
func SetPostFileTip()
	_GUIToolTip_Destroy($tip_post_file)
	$tip_post_file = GUICtrlSetTipOptional($check_run_post_file_command, $tristate_postfile_tip & _
													Human($run_post_file_command), $tristate_postfile_title)
endfunc



func ClickSetOverwrite()
	$overwrite = GUICtrlRead($check_overwrite)
	SetOverwriteTip()
	ConsoleAdd($tristate_overwrite_title & ": " & Human($overwrite), @ScriptLineNumber)
endfunc
func SetOverwriteTip()
	_GUIToolTip_Destroy($tip_overwrite)
	$tip_overwrite = GUICtrlSetTipOptional($check_overwrite, $tristate_overwrite_tip & _
											Human($overwrite), $tristate_overwrite_title)
endfunc

func ClickSetConcatenateFiles()
	$concatenate = GUICtrlRead($check_concatenate)
	SetConcatenateFilesTip()
	ConsoleAdd($tristate_concatenate_title & ": " & Human($concatenate), @ScriptLineNumber)
endfunc
func SetConcatenateFilesTip()
	_GUIToolTip_Destroy($tip_concatenate)
	$tip_concatenate = GUICtrlSetTipOptional($check_concatenate, $tristate_concatenate_tip & _
													Human($concatenate), $tristate_concatenate_title)
endfunc

func ClickSetQuitWhenDone()
	$quit_when_done = GUICtrlRead($check_quit_when_done)
	SetQuitWhenDoneTip()
	ConsoleAdd($tristate_quit_title & ": " & Human($quit_when_done), @ScriptLineNumber)
endfunc
func SetQuitWhenDoneTip()
	_GUIToolTip_Destroy($tip_quit)
	$tip_quit = GUICtrlSetTipOptional($check_quit_when_done, $tristate_quit_tip & _
													Human($quit_when_done), $tristate_quit_title)
endfunc

func ClickSetShutdownWhenDone()
	$shutdown_when_done = GUICtrlRead($check_shutdown_when_done)
	SetShutdownWhenDoneTip()
	ConsoleAdd($tristate_quit_title & ": " & Human($shutdown_when_done), @ScriptLineNumber)
endfunc
func SetShutdownWhenDoneTip()
	ShutDownOverrideQuit()
	_GUIToolTip_Destroy($tip_shutdown)
	$tip_shutdown = GUICtrlSetTipOptional($check_shutdown_when_done, $tristate_shutdown_tip & _
													Human($shutdown_when_done), $tristate_shutdown_title)
endfunc



; There are easier ways, but none so much FUN!
;
; Run the Pre-Job or Post-Job commands (.bat) file..
;
func RunCommandsFile(ByRef $commands_file, ByRef $logfile, ByRef $gen_file, $type)

	debug("", @ScriptLineNumber, 6);debug
	debug("RunCommandsFile(" & $commands_file & "," & $logfile  & "," & $gen_file & "," & $type & ")...", @ScriptLineNumber, 5);debug

	; We check again before running..
	if $commands_file and FileExists($commands_file) then

		local $msg, $run_command, $console_out

		if $generate_script then
			; Simply read the batch file into our new batch file..
			$gen_file &= FileRead($commands_file)
		else
											; The AdLib func simply sets $timeout to true
			if $batch_commands_timeout then AdLibRegister("RunCommandsTimeout", $batch_commands_timeout*1000*60)
			debug("$batch_commands_timeout: " & $batch_commands_timeout, @ScriptLineNumber, 8);debug

			$timeout = false
			local $command_run, $err

			if $run_commands_with_shell = $ON then

				if GetExtension($commands_file) <> "bat" then
					$msg = $type & "-job command processing aborted." & $LOG_LF & _
									"Please give your batch script a .bat extension."
					$logfile &= DoLog(ConsoleAdd($msg, @ScriptLineNumber)) & $LOG_LF
					AdLibUnRegister("RunCommandsTimeout")
					return false
				endif

				; Run the .bat file directly.
				;2do - we could detokenize this before running
				$msg = $LOG_LF & "Running batch file: """ & $commands_file & """.."
				$logfile &= DoLog(ConsoleAdd($msg, @ScriptLineNumber)) & $LOG_LF
				$run_command = @ComSpec & " /c " & ' "' & $commands_file & '" '
				; $command_run = Run($run_command, "", @SW_HIDE, $STDOUT_CHILD)
				$command_run = Run($run_command, "", @SW_HIDE, BitOr($STDERR_CHILD, $STDOUT_CHILD))
				$err = false
				while true
					$console_out = StdErrRead($command_run)
					$err = @error
					$console_out = StringStripWS($console_out, 3)
					if $console_out then
						$logfile &= DoLog(ConsoleAdd($console_out, @ScriptLineNumber)) & $LOG_LF
					endif
					if $err or $timeout then exitloop
					Sleep(25)
				wend
				if $timeout then ProcessClose($command_run)
				StdioClose($command_run)

			else

				; ffe will run the commands one-by-one, replacing @tokens along the way.
				local $run_commands_list
				FileReadIntoArray($commands_file, $run_commands_list) ; populates $run_commands_list
				$msg = $LOG_LF & "Running " & StringLower($type) & "-job commands: " & $commands_file
				$logfile &= DoLog(ConsoleAdd($msg, @ScriptLineNumber)) & $LOG_LF

				for $i = 1 to $run_commands_list[0]
					; Ignore comments and such..
					if StringLeft($run_commands_list[$i], 1) = ":" or StringStripWS($run_commands_list[$i], 3) = "" then continueloop

					$run_command = ffeDeTokenizeString($run_commands_list[$i])
					; $command_run = Run(@ComSpec & " /c " & $run_command, "", @SW_HIDE, $STDOUT_CHILD)
					$command_run = Run(@ComSpec & " /c " & $run_command, "", @SW_HIDE, BitOr($STDERR_CHILD, $STDOUT_CHILD))
					$logfile &= DoLog(ConsoleAdd("exec: " & $run_command, @ScriptLineNumber)) & $LOG_LF

					while true
						$err = false
						$console_out = StdErrRead($command_run)
						$err = @error
						$console_out = StringStripWS($console_out, 3)
						if $console_out then
							$logfile &= DoLog(ConsoleAdd($console_out, @ScriptLineNumber)) & $LOG_LF
						endif
						if $err or $timeout then exitloop
						Sleep(25)
					wend

					if $timeout then ProcessClose($command_run)
					StdioClose($command_run)
				 next

			endif

			 AdLibUnRegister("RunCommandsTimeout")
		endif
	else
		$msg = $type & "-Job Commands File NOT FOUND!"
		$logfile &= DoLog(ConsoleAdd($msg, @ScriptLineNumber))
	endif

	return true
endfunc



; Post file command.
; We have a few choices about how to run this..
;
; Return value is fed to DoLog(), so if you "return false", or you get "False" in your log.
;
func RunPostFileCommand()

	debug("", @ScriptLineNumber, 6);debug
	debug("RunPostFileCommand()...", @ScriptLineNumber, 5);debug

	; Do not get fresh values from ini - use curent values..
	LoadPostFileSettings()

	debug("RunPostFileCommand() " & Human($run_post_file_command), @ScriptLineNumber, 8);debug
	if $run_post_file_command <> $ON then return "" ; do it like this!

	local $job_log, $show_flag, $dos_add
	local $run_command = StringStripWS(ffeDeTokenizeString(String($post_file_command)), 3)

	if not $run_command then return ""

	debug("RunPostFileCommand() *** run_command: " & $run_command, @ScriptLineNumber, 6);debug

	; Whether or not to show the program we are running..
	switch $post_file_show
		case $OFF
			$show_flag = @SW_HIDE
		case else
			$show_flag = @SW_SHOW
	endswitch

	; And how shall we run the program..
	switch $post_file_run_style

		case "shellexecute", "shell"
			debug("*** *** *** ShellExecute POST FILE ", @ScriptLineNumber, 7);debug
			ShellExecute($run_command)

		case "dos"
			debug("*** *** *** DOS POST FILE.. ", @ScriptLineNumber, 7);debug
			$dos_add = @ComSpec & ' /c '
			continuecase

		; "direct"..
		case else
			debug("*** *** *** DIRECT POST FILE ", @ScriptLineNumber, 7);debug

			$timeout = false
			if $batch_commands_timeout then AdLibRegister("RunCommandsTimeout", $batch_commands_timeout*1000*60)

			local $pipe_to = false, $pipe_data = ""

			; Recognise user redirection in post-file command..
			; if StringInStr($run_command, ">") and $post_file_run_style <> "dos" then
			if StringInStr($run_command, ">") then
				local $run_arr = StringSplit($run_command, ">")
				if $run_arr[0] = 2 then
					$run_command = $run_arr[1]
					$pipe_to = StringStripWS(StringReplace($run_arr[2], '"', ""), 3)
					$job_log &= DoLog(ConsoleAdd("Detected '>' redirection in command. " & _
													"Outputting STDIO to file: " & $pipe_to, @ScriptLineNumber))
				endif
			endif

			local $msg = "Running post-file command: " & $run_command
			$job_log &= DoLog(ConsoleAdd($msg & $LOG_LF, @ScriptLineNumber))

			local $err, $console_out

			; Capture the output and feed to console..
			if $post_file_capture = $ON then

				local $command_run = Run($dos_add & $run_command, "", $show_flag, $STDERR_MERGED)

				while true
					$err = false
					$console_out = StdOutRead($command_run)
					$err = @error
					$console_out = StringStripWS($console_out, 3)
					if $console_out then
						if $pipe_to then $pipe_data &= $console_out
						$job_log &= DoLog(ConsoleAdd($console_out, @ScriptLineNumber))
					endif
					if $err or $timeout then exitloop
					Sleep(25)
				wend

				if $timeout then ProcessClose($command_run)
				StdioClose($command_run)

			; Not waiting around.
			; Just run the command and move on..
			else
				Run($dos_add & $run_command, "", $show_flag)
			endif

			; Write out any user ">" redirection..
			if $pipe_to then FileWrite($pipe_to, $pipe_data)
			AdLibUnRegister("RunCommandsTimeout")

	endswitch

	return $job_log

endfunc





; Commands have gone on too long..
;
func RunCommandsTimeout()
	$timeout = true
endfunc








func _____________DROP_WINDOW()
endfunc



; Show it!
; The Funky Drop Window.. v2

func ShowDropWindow()

	debug("", @ScriptLineNumber, 6);debug
	debug("ShowDropWindow()..", @ScriptLineNumber, 6);debug

	$dropwin_visible = true
	$on_top_counter = TimerInit()

	; GDIPLUS.DLL --> Vista/Win 2008 installations	(gdiplus.dll location must be specified)..
	if StringinStr(@OSVersion, "WIN_2008") or StringinStr(@OSVersion, "VISTA") then
		if not $GDI_dll then
			ConsoleAdd("Cannot create png drop window.", @ScriptLineNumber)
			ConsoleAdd("Location of gdiplus.dll not specified.", @ScriptLineNumber)
			ConsoleAdd("Vista or windows server 2008 operating system detected.", @ScriptLineNumber)
			ConsoleAdd("Location of the gdiplus.dll must be manually specified.", @ScriptLineNumber)
			ConsoleAdd("ffe is searching for a likely candidate. Please wait...", @ScriptLineNumber)
			local $find_gdi = RecurseDir(@WindowsDir & "\winsxs", "gdiplus.dll")

			; Find the biggest DLL..
			local $dsize, $oldbig = 0, $biggest_dll
			for $i = 1 to $find_gdi[0]
				$dsize = FileGetSize($find_gdi[$i])
				if $dsize > $oldbig then
					$oldbig = $dsize
					$biggest_dll = $find_gdi[$i]
				endif
			next

			if _GDIPlus_Startup($biggest_dll) then
				$GDI_dll = $biggest_dll
				ConsoleAdd("gdiplus.dll sucessfully located and loaded. saving path to ffe.ini..", @ScriptLineNumber)
				IniWrite($ini_path, $my_name, "GDI_dll", $GDI_dll)
				ConsoleAdd("GDI_dll location set to: " & $GDI_dll, @ScriptLineNumber)
			else
				; Nah, this won't happen..
				ConsoleAdd("gdiplus.dll was found but could not be loaded.", @ScriptLineNumber)
				ConsoleAdd("please look in %windows%\winsxs for one that works! (use F3!).", @ScriptLineNumber)
				ConsoleAdd("then set the full location inside ffe.ini and give it a whirl!", @ScriptLineNumber)
				$do_drop_window = $OFF
				$dropwin_visible = false
				return
			endif
			_GDIPlus_Shutdown()
		endif
	else
		$GDI_dll = "gdiplus.dll"
	endif

	debug("$GDI_dll: " & $GDI_dll, @ScriptLineNumber, 7);debug
	debug("$drop_win_image: " & $drop_win_image, @ScriptLineNumber, 6);debug


	if not FileExists($drop_win_image) then
		ConsoleAdd("ffe could not find specified drop window image: " & $drop_win_image & ".", @ScriptLineNumber)
		return ResetAndReturn()
	endif

	Check4GIFmethod()

	; Load user settings..
	local $dw_width, $dw_height
	local $dw_x = IniRead($ini_path, $my_name, "drop_window_x", 1)
	local $dw_y = IniRead($ini_path, $my_name, "drop_window_y", 1)
	$drop_win_transparency = IniRead($ini_path, $my_name, "drop_win_transparency", 0)
	GetRealTrans()

	; This will load a transparent, animated GIF..
	if $gif_method then
		local $aGIFDimension = _GIF_GetDimension($drop_win_image)
		$dw_width = $aGIFDimension[0]
		$dw_height = $aGIFDimension[1]
	else
		_GDIPlus_Startup($GDI_dll)
		; This will load ANY image type (except animated gif)..

		; Using this method would involve a lot of code to load WMF/EMF files..
		;$image_handle = _GDIPlus_ImageLoadFromFile($drop_win_image)

		; But this works fine..
		$image_handle = _GDIPlus_BitmapCreateFromFile($drop_win_image)

		if not $image_handle then
			ConsoleAdd("Could not load image file: " & $drop_win_image, @ScriptLineNumber)
			return ResetAndReturn()
		endif
		$dw_width = _GDIPlus_ImageGetWidth($image_handle)
		$dw_height = _GDIPlus_ImageGetHeight($image_handle)
	endif
	; Check we can see this image on-screen, if not, move it..
	; Get far-dimensions of multi-monitor setup..
	_GetMonitors()
	local $far_left = $monitors_list[0][1]
	local $far_top = $monitors_list[0][2]
	local $far_right = $monitors_list[0][3]
	local $far_height = $monitors_list[0][4]
	if ($dw_x+$dw_width) < $far_left then $dw_x = $far_left
	if ($dw_x-$dw_width) > $far_right then $dw_x = $far_right-$dw_width
	if ($dw_y+$dw_height) > $far_height then $dw_y = $far_height-$dw_height
	if ($dw_y+$dw_height) < $far_top then $dw_y = $far_top
	; This is flawed (unless we use ALL monitors dimensions;2do.).
	; If monitor 2 is smaller... but hey, it will mostly save yer butt!

	; *** NEED pop-up style here or else title bar becomes inactive for CheckMouse(GUIGetCursorInfo())
	$GUI_DropWindow = GUICreate("ffe file drop", $dw_width, $dw_height, $dw_x, $dw_y, $WS_POPUP, _
						BitOR($WS_EX_LAYERED, $WS_EX_TOOLWINDOW, $WS_EX_TOPMOST, $WS_EX_ACCEPTFILES))

	GUISetOnEvent($GUI_EVENT_DROPPED, "GetDroppedItem")
	GUISetOnEvent($GUI_EVENT_PRIMARYUP, "SaveDropWinLocation")

	HotKeySet("{LEFT}", "PreviousDropImage")
	HotKeySet("{RIGHT}", "NextDropImage")

	local $dummy_drop_windowi = GUICtrlCreateDummy()
	GUICtrlSetOnEvent(-1, "MenuToggleDropWindow")


	$lab_main_drop = GUICtrlCreateLabel("", 0, 0, $dw_width, $dw_height, $SS_NOTIFY, $GUI_WS_EX_PARENTDRAG)
	GUICtrlSetTipOptional(-1,	"Drag media files into here to have them inserted into ffe's file input." & $MSG_LF & _
								"Right-click the Drop Window for a handy context menu." & $MSG_LF & $MSG_LF & _
								"Use your Left/Right arrow keys to quickly cycle through all the" & $MSG_LF & _
								"images in the current directory (and sub-directories) ." & $MSG_LF & $MSG_LF & _
								"Drag images into here to use them as your Drop Window.", "The Drop Window")

	if $gif_method then
		$hGIF = _GUICtrlCreateGIF($drop_win_image, "", 0, 0, default, default, default, 0x345)
		_WinAPI_SetLayeredWindowAttributes($GUI_DropWindow, 0x345, $dropwin_trans_real)
		GUISetBkColor(0x345) ; some random color
	else
		SetTransparentBitmap($GUI_DropWindow, $image_handle, $dropwin_trans_real)
	endif

	GUICtrlSetState(-1, $GUI_DROPACCEPTED)
	GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)

	_WinAPI_SetParent($GUI_DropWindow, 0)

	; If it takes longer than one second, post a notice..
	AdLibRegister("PostScanningNotice", 1000)
	CreateDropWinContextMenu()
	AdLibUnRegister("PostScanningNotice")

	local $AppHotKeys[1][2] = [["{F9}", $dummy_drop_windowi]]
	GUISetAccelerators($AppHotKeys)

	; Let's go!
	GUISetState(@SW_SHOW, $GUI_DropWindow)

	; On launch, switch immediately back to main window..
	if $minimized = $OFF and not $switching then WinActivate($ffeGUI)

	; We only save the new path if it loaded okay..
	if $switching then SetNewDropWinImage()

	$switching = false
	return true
endfunc



; Drop Windows Context menu: current images and controls..
;
func CreateDropWinContextMenu()

	redim $drop_images[1][3]

	local $img_dir = GetParent($drop_win_image)
	if $fluid_image_menu = $OFF then $img_dir = $drop_win_image_folder

	local $ctxt_the_pic = GUICtrlCreateContextMenu($lab_main_drop)

	GUICtrlCreateContextMenu($lab_main_drop)
	GUICtrlCreateMenuItem("Refresh This Menu", $lab_main_drop)
	GUICtrlSetOnEvent(-1, "HideDropWindow")

	GUICtrlCreateMenuItem("", $lab_main_drop)

	GUICtrlCreateMenuItem("Open Images Folder..", $lab_main_drop)
	GUICtrlSetOnEvent(-1, "OpenImagesFolder")

	$ctxt_choose_image_folder = GUICtrlCreateContextMenu($lab_main_drop)
	GUICtrlCreateMenuItem("Pick Images Folder..	(for fixed menu)", $lab_main_drop)
	GUICtrlSetOnEvent(-1, "MenuChooseFixedImgLoc")
	if $fluid_image_menu = $ON then GUICtrlSetState(-1, $GUI_DISABLE)

	GUICtrlCreateMenuItem("", $lab_main_drop)

	; Menu of available images..
	local $img_menu = GUICtrlCreateMenu("Images..", $ctxt_the_pic)
	DigToMenu($img_dir, $img_menu)

	GUICtrlCreateMenuItem("", $lab_main_drop)


	local $ctxt_menu_transparency = GUICtrlCreateMenu("Transparency..", $ctxt_the_pic)
	for $i = 0 to 100 step 5
		GUICtrlCreateMenuItem($i & "%", $ctxt_menu_transparency)
		GUICtrlSetOnEvent(-1, "MenuSwitchTransparency")
		if $i = $drop_win_transparency then
			GUICtrlSetState(-1, $ON)
		endif
	next

	GUICtrlCreateMenuItem("", $lab_main_drop)

	$ctxt_toggle_fluid_image_menu = GUICtrlCreateContextMenu($lab_main_drop)
	GUICtrlCreateMenuItem("Fluid Menu	(follows current image)", $lab_main_drop)
	GUICtrlSetOnEvent(-1, "MenuToggleFluidMenu")
	GUICtrlSetState(-1, $fluid_image_menu)

	GUICtrlCreateMenuItem("", $lab_main_drop)

	$ctxt_toggle_auto_copy_images = GUICtrlCreateContextMenu($lab_main_drop)
	GUICtrlCreateMenuItem("Copy Dragged Images	(to fixed menu)", $lab_main_drop)
	GUICtrlSetOnEvent(-1, "MenuToggleAutoCopy")
	GUICtrlSetState(-1, $auto_copy_images)
	if $fluid_image_menu = $ON then GUICtrlSetState(-1, $GUI_DISABLE)

	GUICtrlCreateMenuItem("", $lab_main_drop)

	GUICtrlCreateMenuItem("Close Drop Window	(F9)", $lab_main_drop)
	GUICtrlSetOnEvent(-1, "CloseDropWindow")

	GUICtrlCreateMenuItem("", $lab_main_drop)

	GUICtrlCreateMenuItem("Exit ffe", $lab_main_drop)
	GUICtrlSetOnEvent(-1, "UserDoQuit")

endfunc



func ResetAndReturn()
	ConsoleAdd("Resetting to default image..  [Images\ffe.png]", @ScriptLineNumber)
	IniWrite($ini_path, $my_name, "drop_win_image", "Images\ffe.png")
	ConsoleAdd("drop_win_image reset to: " & "Images\ffe.png", @ScriptLineNumber)
	$dropwin_visible = false
	_GDIPlus_Shutdown()
	GetDropWinImage()
	return false
endfunc


#cs

	GDI Error Codes..

	$GDIP_ERROK =						0	Method call was successful
	$GDIP_ERRGENERICERROR =				1	Generic method call error
	$GDIP_ERRINVALIDPARAMETER =			2	One of the arguments passed to the method was not valid
	$GDIP_ERROUTOFMEMORY =				3	The operating system is out of memory
	$GDIP_ERROBJECTBUSY =				4	One of the arguments in the call is already in use
	$GDIP_ERRINSUFFICIENTBUFFER =		5	A buffer is not large enough
	$GDIP_ERRNOTIMPLEMENTED =			6	The method is not implemented
	$GDIP_ERRWIN32ERROR =				7	The method generated a Microsoft Win32 error
	$GDIP_ERRWRONGSTATE =				8	The object is in an invalid state to satisfy the API call
	$GDIP_ERRABORTED =					9	The method was aborted
	$GDIP_ERRFILENOTFOUND =				10	The specified image file or metafile cannot be found
	$GDIP_ERRVALUEOVERFLOW =			11	The method produced a numeric overflow
	$GDIP_ERRACCESSDENIED =				12	A write operation is not allowed on the specified file
	$GDIP_ERRUNKNOWNIMAGEFORMAT =		13	The specified image file format is not known
	$GDIP_ERRFONTFAMILYNOTFOUND =		14	The specified font family cannot be found
	$GDIP_ERRFONTSTYLENOTFOUND =		15	The specified style is not available for the specified font
	$GDIP_ERRNOTTRUETYPEFONT =			16	The font retrieved is not a TrueType font
	$GDIP_ERRUNSUPPORTEDGDIVERSION =	17	The installed GDI+ version is incompatible
	$GDIP_ERRGDIPLUSNOTINITIALIZED =	18	The GDI+ API is not in an initialized state
	$GDIP_ERRPROPERTYNOTFOUND =			19	The specified property does not exist in the image
	$GDIP_ERRPROPERTYNOTSUPPORTED =		20	The specified property is not supported

; Of course comments don't get compiled in!

#ce


; Hide it!
func HideDropWindow()

	; Not required, but good practice..
	if not $dropwin_visible then return

	if $gif_method then
		_GIF_DeleteGIF($hGIF)
	else
		_GDIPlus_BitmapDispose($image_handle)
	endif
	_GDIPlus_Shutdown()
	SaveDropWinLocation()
	HotKeySet("{LEFT}")
	HotKeySet("{RIGHT}")

	GUIDelete($GUI_DropWindow)

	$dropwin_visible = false
	$on_top_counter = 0
	; When switching images, $do_drop_window is still true,
	; so idle loop catches this and re-opens the Drop Window.
	; We don't have to.
	return
endfunc


func SaveDropWinLocation()
	local $dw_coords = WinGetPos($GUI_DropWindow)
	if IsArray($dw_coords) then
		; Prevent saving "center" default setting when user puts window at -1 px..
		if $dw_coords[0] = -1 then $dw_coords[0] = 0
		if $dw_coords[1] = -1 then $dw_coords[1] = 0
		IniWrite($ini_path, $my_name, "drop_window_x", $dw_coords[0])
		IniWrite($ini_path, $my_name, "drop_window_y", $dw_coords[1])
	endif
endfunc


; Create transparent image GUI..
;
func SetTransparentBitmap($hGUI, $image_handle, $iOpacity)
	local $hScrDC, $hMemDC, $hBitmap, $hOld, $pSize, $tSize, $pSource, $tSource, $pBlend, $tBlend
	$hScrDC = _WinAPI_GetDC(0)
	$hMemDC = _WinAPI_CreateCompatibleDC($hScrDC)
	$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($image_handle)
	$hOld = _WinAPI_SelectObject($hMemDC, $hBitmap)
	$tSize = DllStructCreate($tagSIZE)
	$pSize = DllStructGetPtr($tSize)
	DllStructSetData($tSize, "X", _GDIPlus_ImageGetWidth($image_handle))
	DllStructSetData($tSize, "Y", _GDIPlus_ImageGetHeight($image_handle))
	$tSource = DllStructCreate($tagPOINT)
	$pSource = DllStructGetPtr($tSource)
	$tBlend = DllStructCreate($tagBLENDFUNCTION)
	$pBlend = DllStructGetPtr($tBlend)
	DllStructSetData($tBlend, "Alpha", $iOpacity)
	DllStructSetData($tBlend, "Format", $AC_SRC_ALPHA)
	_WinAPI_UpdateLayeredWindow($hGUI, $hScrDC, 0, $pSize, $hMemDC, $pSource, 0, $pBlend, $ULW_ALPHA)
	_WinAPI_ReleaseDC(0, $hScrDC)
	_WinAPI_SelectObject($hMemDC, $hOld)
	_WinAPI_DeleteObject($hBitmap)
	_WinAPI_DeleteDC($hMemDC)
endfunc




; Toggled from a menu or accelerator..
func MenuToggleDropWindow()
	if $do_drop_window = $ON then
		CloseDropWindow()
	else
		TrayItemSetState($tray_toggle_drop_window, $ON)
		GUICtrlSetState($check_do_drop_window, $ON)
		$do_drop_window = $ON
		IniWriteCheckBoxValue($ini_path, $my_name, "do_drop_window", $do_drop_window)
	endif
endfunc

; Closed from drop window context menu..
func CloseDropWindow()
	GUICtrlSetState($check_do_drop_window, $OFF)
	ClickToggleDropWindow()
endfunc

; User Toggles Drop Window (or closed directly, see above)..
func ClickToggleDropWindow()
	$do_drop_window = GUICtrlRead($check_do_drop_window)
	TrayItemSetState($tray_toggle_drop_window, $do_drop_window)
	IniWriteCheckBoxValue($ini_path, $my_name, "do_drop_window", $do_drop_window)
	if $do_drop_window = $OFF then HideDropWindow()
endfunc

; Read ini setting and create valid image path for DropWindow, defaulting to built-in image on failure..
func GetDropWinImage()
	$drop_win_image = SetRelPathToDataDir(ffeDeTokenizeString(IniRead($ini_path, $my_name, "drop_win_image", "")))
	if not $drop_win_image or not FileExists($drop_win_image) then
		$drop_win_image = SetRelPathToDataDir("Images\ffe.png")
	endif
	if not FileExists(GetParent($drop_win_image)) then
		DirCreate(GetParent($drop_win_image))
		FileInstall(".\Resources\ffe.png", $drop_win_image, 1)
	endif
	debug("GetDropWinImage() $drop_win_image: " & $drop_win_image, @ScriptLineNumber, 5);debug
	Check4GIFmethod()
endfunc

func GetDropWinImageFolder()
	$drop_win_image_folder = _
		SetRelPathToDataDir(ffeDeTokenizeString(IniRead($ini_path, $my_name, "drop_win_image_folder", "Images")))
	if not $drop_win_image_folder or not FileExists($drop_win_image_folder) then $drop_win_image_folder = SetRelPathToDataDir("Images")
	if not FileExists($drop_win_image_folder) then DirCreate($drop_win_image_folder)
	debug("GetDropWinImageFolder() $drop_win_image_folder: " & $drop_win_image_folder, @ScriptLineNumber, 5);debug
endfunc


func MenuResetDropWindow()
	if $dropwin_visible then HideDropWindow()
	IniWrite($ini_path, $my_name, "drop_win_image", "Images\ffe.png")
	IniWrite($ini_path, $my_name, "drop_win_image_folder", "Images")
	IniWrite($ini_path, $my_name, "drop_window_x", 0)
	IniWrite($ini_path, $my_name, "drop_window_y", 0)
	GetDropWinImage()
	GetDropWinImageFolder()
endfunc



; Recursive search function to dig-and-add-items-to-context-menu-as-it-goes..
; Damn! I love recursive functions!
func DigToMenu($root_dir, $menu_id=false)

	if not FileExists($root_dir) then return

	local $item_text, $item_id, $full_item
	local $dir_list = ReadDir($root_dir, "", "*.*")

	if IsArray($dir_list) then

		for $i = 1 to $dir_list[0]

			$item_text = BaseName($dir_list[$i])
			$full_item = $root_dir & "\" & $dir_list[$i]

			if IsDir($full_item) then

				local $submenu = GUICtrlCreateMenu($item_text, $menu_id)
				DigToMenu($full_item, $submenu)

			elseif IsAllowedImage($item_text) then

				; Slight indentation for files cuz you ain't gettin' sortin!
				$item_id = GUICtrlCreateMenuItem("  " & $item_text, $menu_id)
				GUICtrlSetOnEvent(-1, "MenuSwitchImage")
				local $new_index = AddImageToMenuList($drop_images, $item_id, $item_text, $full_item)

				if $full_item = $drop_win_image then
					$img_index = $new_index
					GUICtrlSetState($item_id, $ON)
				endif

			endif

		next
	endif
endfunc


; Usefully returns the index of the newly created row..
func AddImageToMenuList(ByRef $array, $id, $text, $fullpath)
	if not IsArray($array) then
		global $array[1][3]
	else
		redim $array[UBound($array)+1][3] ; Redim = SLOW!
	endif
	local $idx = UBound($array)-1
	$array[$idx][0] = $id
	$array[$idx][1] = $text
	$array[$idx][2] = $fullpath
	return $idx
endfunc



; User switched transparency from the drop window context menu..
;
func MenuSwitchTransparency()
	local $drop_win_transparency = GUICtrlRead(@GUI_CtrlId, 1)
	CRT($drop_win_transparency, "%")
	ConsoleAdd("Switching Transparency To " & $drop_win_transparency & "%", @ScriptLineNumber);debug
	IniWrite($ini_path, $my_name, "drop_win_transparency", $drop_win_transparency)
	GetRealTrans()
	HideDropWindow()
endfunc


; User chose a new image from the context menu..
;
func MenuSwitchImage()
	if not @GUI_CtrlId then return false
	SwitchDropImage()
endfunc


; We are scanning a LARGE directory..
;
func PostScanningNotice()
	AdLibUnRegister("PostScanningNotice")
	ConsoleAdd("Scanning for images. Please wait a moment..", @ScriptLineNumber)
endfunc


; Choose a new image (hotkeys or menu)..
;
func SwitchDropImage($updown=false)

	GUICtrlSetState($drop_images[$img_index][0], $OFF)
	HideDropWindow()
	$switching = true

	local $i
	if $updown <> false then
		$i = $img_index + $updown
		; wrap around..
		if $i = 0 then $i = Ubound($drop_images)-1
		if $i = Ubound($drop_images) then $i = 1
	else
		if not @GUI_CtrlId then return false
		for $i = 1 to Ubound($drop_images)-1
			if @GUI_CtrlId = $drop_images[$i][0] then exitloop
		next
	endif

	$img_index = $i
	GUICtrlSetState($drop_images[$img_index][0], $ON)
	$drop_win_image = $drop_images[$i][2]
	Check4GIFmethod()

endfunc


; Also used when dropping images into drop-window..
;
func SetNewDropWinImage()
	local $write_img_path = $drop_win_image
	if StringInStr($drop_win_image, $data_dir & "\") then
		$write_img_path = StringReplace($drop_win_image, $data_dir & "\", "")
	endif
	$write_img_path = ffeTokenizeString($write_img_path)
	if $write_img_path then
		IniWrite($ini_path, $my_name, "drop_win_image", $write_img_path)
		ConsoleAdd("drop_win_image set to: " & $write_img_path, @ScriptLineNumber)
	endif
endfunc


; We run this after loading an image (sometimes more than once!)
;
func Check4GIFmethod()
	$gif_method = false
	if $enable_animated_gif and GetExtension($drop_win_image) = "gif" then $gif_method = true
endfunc


; We prepare the string on ini-load, by adding a "," to both ends.
; Then we can check for ",ps," without matching it in, for example, "eps".
; It's quicker than creating an array, especially when used inside recursive
; functions, which it is.
func IsAllowedImage($image_file)
	if StringInStr($allowed_image_types, "," & GetExtension($image_file) & ",") then return true
	return false
endfunc


; On-top status on windows in Windows can "drift". This ensures it stays on top..
func SetDropWinOnTop()
	WinSetOnTop($GUI_DropWindow, "", $WINDOWS_ONTOP)
endfunc


func MenuChooseFixedImgLoc()
	local $choose_root = "::{450D8FBA-AD25-11D0-98A8-0800361B1103}" ; "My Documents"
	if $drop_win_image_folder then $choose_root = $drop_win_image_folder
	DialogOpen()
	local $user_choose_folder = FileSelectFolder("Select a new image folder (for the FIXED menu)", _
															$choose_root, 7, $choose_root, $ffeGUI)
	local $err = @error
	DialogClose()
	if not $user_choose_folder then
		if $err then
			ConsoleAdd("Select image folder aborted: user cancelled.", @ScriptLineNumber)
		else
			ConsoleAdd("Select image folder aborted: invalid selection.", @ScriptLineNumber)
		endif
		return
	endif
	if FileExists($user_choose_folder) then
		$drop_win_image_folder = $user_choose_folder
		IniWrite($ini_path, $my_name, "drop_win_image_folder", $drop_win_image_folder)
		ConsoleAdd("Fixed menu image folder set to: " & $drop_win_image_folder, @ScriptLineNumber)
		GetDropWinImageFolder()
		HideDropWindow()
	endif
endfunc



; $switching, in case they are going nuts on the keys.
; Sending a second SwitchDropImage() before the first is complete could be problematic.
func PreviousDropImage()
	if $switching then return
	if WinActive($GUI_DropWindow) then
		SwitchDropImage(-1)
	else
		HotKeySet("{LEFT}")
		Send("{LEFT}")
		HotKeySet("{LEFT}","PreviousDropImage")
	endif
endfunc

func NextDropImage()
	if $switching then return
	if WinActive($GUI_DropWindow) then
		SwitchDropImage(1)
	else
		HotKeySet("{RIGHT}")
		Send("{RIGHT}")
		HotKeySet("{RIGHT}","NextDropImage")
	endif
endfunc




; Converts user 0-100 into real 0-255, also sets "half transparency" for mouse hover
; (normally 50%, but if user transparency is too close to 50%, we make it 100%),
; unless the user has explicitly set the mouseover transparency level.
;
func GetRealTrans()

	$dropwin_trans_real = 255 * (100 - $drop_win_transparency) / 100

	if $drop_win_hover_transparency >= 0 and $drop_win_hover_transparency <= 100 then
		$half_trans =  255 * (100 - $drop_win_hover_transparency) / 100
	else
		$half_trans = 127
		if $drop_win_transparency >= 45 and $drop_win_transparency <= 55 then
			$half_trans = 255
		endif
	endif
endfunc





; Those Lovely Custom Buttons..
func ____________________BUTTONS()
endfunc




; Load custom buttons data from ini..
;
func LoadCustomButtonData()
	$custom_buttons_array = IniReadSection($ini_path, $NAME_BUTTONS)
	if IsArray($custom_buttons_array) then
		if $custom_buttons_array[0][0] > 500 then $custom_buttons_array[0][0] = 500
		global $custom_buttons[$custom_buttons_array[0][0]+1]
		global $custom_buttons_rename_menu[$custom_buttons_array[0][0]+1]
		global $custom_buttons_delete_menu[$custom_buttons_array[0][0]+1]
		global $custom_buttons_notes[$custom_buttons_array[0][0]+1]
		for $i = 1 to $custom_buttons_array[0][0]
			if StringInStr($custom_buttons_array[$i][1], $button_delim) then
				local $command_array = StringSplit($custom_buttons_array[$i][1], $button_delim, 1)
				debugPrintArray($command_array, "Custom Buttons $command_array:", @ScriptLineNumber, 8);debug
				if $command_array[0] = 2 then
					$custom_buttons_array[$i][1] = $command_array[1]
					$custom_buttons_notes[$i] = $command_array[2]
				endif
			endif
		next
	endif
endfunc



; We don't check for enable_custom_buttons in these functions. We may be
; awaiting restart, and these shouldn't be fired if enable_custom_buttons is
; properly set to false (after a restart).


; Create a grid of buttons from an array (probably created by IniReadSection())
; Supply the button array and the x/y coordinates (top-left origin of grid)..
;
func CreateButtonGrid()

	debug("", @ScriptLineNumber, 6);debug
	debug("CreateButtonGrid()...", @ScriptLineNumber, 6);debug

	if not IsArray($custom_buttons_array) then return false
	debugPrintArray($custom_buttons_array, "$custom_buttons_array:", @ScriptLineNumber, 7);debug

	local $i = 1, $row_num, $bmenu
	local $rows = int((110-$buttons_y_shunt) / ($custom_buttons_height+$button_spacing)) - 1
	; -1 cuz we start at 0 for rows

	for $j = 0 to $rows

		if $custom_buttons_columns = "auto" then
			$row_num = Round((($width - 125) - $grid_x)/$custom_buttons_width)-1
		else
			$row_num = $custom_buttons_columns-1
		endif

		; x/y start at 0, buttons start at 1 ($i)

		; No limit here - how wide is your screen?
		for $k = 0 to $row_num

			local $cbutt_left = $grid_x + $buttons_x_shunt + (($custom_buttons_width+$button_spacing-1)*$k)
			local $cbutt_top = $grid_y + $buttons_y_shunt + (($custom_buttons_height+$button_spacing)*$j)

			local $custom_notes = ""
			$custom_buttons[$i] = GUICtrlCreateButton($custom_buttons_array[$i][0], $cbutt_left, $cbutt_top, _
						$custom_buttons_width-2, $custom_buttons_height, BitOr($WS_TABSTOP,$BS_FLAT))
			GUICtrlSetonEvent(-1, "ClickCustomButton")

			if $custom_buttons_notes[$i] then $custom_notes = $MSG_LF & $MSG_LF & '[' & _
						StringReplace($custom_buttons_notes[$i], '\n', " ~ ") & ']'

			GUICtrlSetTipOptional(-1, $MSG_LF & $custom_buttons_array[$i][1] & $custom_notes, " " & $custom_buttons_array[$i][0] & ":")

			GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
			GUICtrlSetFont(-1, $custom_buttons_font_size)
			$bmenu = GUICtrlCreateContextMenu($custom_buttons[$i])
			$custom_buttons_rename_menu[$i] = GUICtrlCreateMenuItem("Rename:  """ & $custom_buttons_array[$i][0] & '"', $bmenu)
			GUICtrlSetOnEvent(-1, "RenameButton")
			GUICtrlCreateMenuItem("", $bmenu)
			$custom_buttons_delete_menu[$i] = GUICtrlCreateMenuItem("Delete:  """ & $custom_buttons_array[$i][0] & '"', $bmenu)
			GUICtrlSetOnEvent(-1, "DeleteButton")
			GUICtrlCreateMenuItem("", $bmenu)
			GUICtrlCreateMenuItem("Import Buttons", $bmenu)
			GUICtrlSetOnEvent(-1, "ImportButtons")
			GUICtrlCreateMenuItem("Export Buttons", $bmenu)
			GUICtrlSetOnEvent(-1, "MenuExportButtons")

			if $i = $custom_buttons_array[0][0] then exitloop 2
			$i += 1
		next
	next
endfunc



; Re-Build the Custom Button Grid to show new/updated buttons and columns..

func ReCreateButtonGrid()

	; No button array exists, return immediately..
	if not IsArray($custom_buttons_array) then return false

	; Wipe existing buttons first..
	for $i = 1 to $custom_buttons_array[0][0]
		GUICtrlDelete($custom_buttons[$i])
	next

	if $custom_buttons_columns then
		LoadCustomButtonData()
		CreateButtonGrid()
	endif
endfunc




func ClickCustomButton()
	DoCustomButtonAction()
endfunc


; Click once to add the code, a second time to remove..
;
; Shift+Click (10) to rename/edit/add buttons..
; Ctrl+Click (11) to add params to input override.
;
func DoCustomButtonAction($edit_only=false, $clicked=@GUI_CtrlId)

	local $do_edit, $do_input_args
	if _IsPressed(10) or $edit_only then $do_edit = true
	if _IsPressed(11) then $do_input_args = true

	local $clicked_butt = InArray($custom_buttons, $clicked)	; returns index of match
	if $clicked_butt < 1 or $clicked_butt > $custom_buttons_array[0][0] then
		ConsoleAdd("Custom button error!", @ScriptLineNumber)
		return
	endif

	local $this_command = $custom_buttons_array[$clicked_butt][1]

	if $do_edit then
		DialogOpen()
		local $edit_butt_name = CorzFancyInputBox("Custom Button Name.. ",	_
			"Specify a name for the custom button.. " & $MSG_LF & _
			"Enter a new name to create a new button.", $custom_buttons_array[$clicked_butt][0] , _
			"" , 350 , 117, default, default, 0, $ffeGUI)
		DialogClose()
		if not $edit_butt_name then return

		DialogOpen()
		local $edit_butt_args = CorzFancyInputBox("Arguments.. ", "Enter the arguments for the " & '"' & _
			StringReplace($edit_butt_name, "&", "") & "" &  " custom button.. ", $this_command , "" , _
			480, 100, default, default, 0, $ffeGUI)
		DialogClose()
		if not $edit_butt_args then return

		DialogOpen()
		local $edit_butt_notes = _
			CorzFancyInputBox("notes.. ", "Optionally, enter any explanatory notes for .. " & '"' & _
			StringReplace($edit_butt_name, "&", "") & '"..', StringReplace($custom_buttons_notes[$clicked_butt], $LOG_LF, '\n') , "" , _
			@DesktopWidth/2, 100, default, default, 0, $ffeGUI)
		if @error = 1 then
			if $custom_buttons_notes[$clicked_butt] then
				$edit_butt_notes = $custom_buttons_notes[$clicked_butt]
			endif
			; They can cancel this dialog, old notes will be saved.
		endif
		DialogClose()

		local $insert = $LOG_LF & "Updated custom button: "
		if $custom_buttons_array[$clicked_butt][0] <> $edit_butt_name then $insert = $LOG_LF & "Created NEW Button: "

		; I usually avoid ternary operators, because they look like this..
		;	(the expression) ? <-- question mark there <Do if True>  colon there! -> : <Do if False>
		; Ouch!
		ConsoleAdd( ($edit_butt_notes) ? _
			$insert & $edit_butt_name & $LOG_LF  & "arguments: " & $edit_butt_args & $LOG_LF & "notes/tips: " & _
												$LOG_LF & StringReplace($edit_butt_notes, '\n', $LOG_LF) : _
			$insert & $edit_butt_name & $LOG_LF & "arguments: " & $edit_butt_args, @ScriptLineNumber)
		; If we switched the order of things here, we wouldn't need this. I'll leave it "as an exercise".

		if $edit_butt_notes then $edit_butt_notes = $button_delim & $edit_butt_notes
		IniWrite($ini_path, $NAME_BUTTONS, $edit_butt_name, $edit_butt_args & $edit_butt_notes)
		$this_command = $edit_butt_args
		ReCreateButtonGrid()
		if $edit_only then return
	endif

	local $my_control = $inp_extra_args
	if $do_input_args then $my_control = $inp_input_params

	; Existing extra arguments..
	local $current_params = GUICtrlRead($my_control)

	debug("$current_params: " & $current_params, @ScriptLineNumber, 8);debug
	debug("$this_command: " & $this_command, @ScriptLineNumber, 8);debug

	$this_command = StringStripWS($this_command, 3)

	if $custom_buttons_notes[$clicked_butt] and $button_notes_to_console = $ON then
		ConvertNewlines($custom_buttons_notes[$clicked_butt])
		ConsoleAdd($LOG_LF & "BUTTON: " & $custom_buttons_array[$clicked_butt][0] & ": " & $LOG_LF & $LOG_LF & $custom_buttons_notes[$clicked_butt])
	endif
	AddRemoveParam($current_params, $this_command, $my_control)

endfunc



; Rename Custom Button..
;
func RenameButton()

	local $custom_buttons_array = IniReadSection($ini_path, $NAME_BUTTONS)

	local $clicked_butt = InArray($custom_buttons_rename_menu, @GUI_CtrlId)
	; Returns index of match (button 1 - 15, or whatever)
	if $clicked_butt < 1 or $clicked_butt > $custom_buttons_array[0][0] then
		ConsoleAdd("Custom button out of bounds!", @ScriptLineNumber)
		return
	endif
	DialogOpen()
	local $edit_butt_name = CorzFancyInputBox("Custom Button Name.. ", "Specify a new name for this custom button.. ", _
																$custom_buttons_array[$clicked_butt][0] , "" , 300, 94)
	DialogClose()
	; Case-Sensitive Match - User can change case of button ok..
	if not $edit_butt_name or $edit_butt_name == $custom_buttons_array[$clicked_butt][0] then return

	; We are about to change this..
	local $old_name = $custom_buttons_array[$clicked_butt][0]
	for $i = 1 to $custom_buttons_array[0][0]
		if $custom_buttons_array[$i][0] == $custom_buttons_array[$clicked_butt][0] then
			$custom_buttons_array[$i][0] = $edit_butt_name
			exitloop
		endif
	next

	if IniWriteSection($ini_path, $NAME_BUTTONS, $custom_buttons_array) then
		ConsoleAdd("Custom button """ & $old_name & """ renamed to """ & $edit_butt_name & '"', @ScriptLineNumber)
		ReCreateButtonGrid()

		return true
	endif
	ConsoleAdd("Error renaming button """ & $old_name & """ to """ & $edit_butt_name & '"', @ScriptLineNumber)

endfunc




; Remove a Custom Button..
;
func DeleteButton()
	local $clicked_butt = InArray($custom_buttons_delete_menu, @GUI_CtrlId)
	if $clicked_butt < 1 or $clicked_butt > $custom_buttons_array[0][0] then
		ConsoleAdd("Custom button out of bounds!", @ScriptLineNumber)
		return
	endif
	local $seen_delete_warning = IniReadCheckBoxValue($ini_path, $my_name, "warning_seen_butt_delete", $OFF)
	if $seen_delete_warning = $OFF then
		DialogOpen()
		MsgBox($MB_OK,	"This is your only warning!", _
			"ffe isn't some namby-pamby, hold-your-hand baby-app." & $MSG_LF & _
			"It's a program designed for working." & $MSG_LF & $MSG_LF & _
			"When you choose to delete a custom button, it will be deleted." & $MSG_LF & _
			"Gone. Vanished. No auto-backup. No second chance." & $MSG_LF & $MSG_LF & _
			"It's about to happen now, even if you cancel this dialog.", 60, $ffeGUI)
		DialogClose()
		IniWriteCheckBoxValue($ini_path, $my_name, "warning_seen_butt_delete", $ON)
		ConsoleAdd("User warned about permanent button deletion: Check!", @ScriptLineNumber)
	endif
	if IniDelete($ini_path, $NAME_BUTTONS, $custom_buttons_array[$clicked_butt][0]) then
		ConsoleAdd("Deleted button: """ & $custom_buttons_array[$clicked_butt][0] & '".', @ScriptLineNumber)
		ReCreateButtonGrid()
	else
		ConsoleAdd("Error deleting custom button: """ & $custom_buttons_array[$clicked_butt][0] & '".', @ScriptLineNumber)
	endif
endfunc




func SetPresetDefExtension()
	ChooseDefaultExtension(true)
endfunc

func SetDefExtension()
	ChooseDefaultExtension()
endfunc


; Change the default extension..
;
func ChooseDefaultExtension($preset_level=false)

	local $insert, $d_add
	local $section = $my_name

	if $preset_level then
		if not $current_preset then
			return ConsoleAdd("No preset currently selected!", @ScriptLineNumber)
		endif
		if $current_preset = $my_name then
			return ConsoleAdd("No preset currently selected! To set the global default extension, use {F2}", @ScriptLineNumber)
		endif
		$section = $current_preset
		$insert &= "(for " & $current_preset & ") "
		$d_add = " (for " & $current_preset & ") "
	endif

	local $current_extension = IniRead($ini_path, $current_preset, "default_extension", $default_extension)
	debug("Current default_extension for this preset: " & $default_extension, @ScriptLineNumber, 8);debug

	DialogOpen()
	local $edit_default_extension = CorzFancyInputBox("Enter the default extension" & $d_add & ".. ", _
		"You can use any extension you want. No need for the dot (.) here. " & $MSG_LF & _
		"NOTE: Under most circumstances you DO NOT need to alter this. " & $MSG_LF & _
		"File extension mapping is handled internally by ffe. Be Careful!", $default_extension , _
		"" , 440, 128, default, default, 0, $ffeGUI)
	DialogClose()
	CLT($edit_default_extension, ".")

	; Need *something*! ..
	if not $edit_default_extension then return

	if $edit_default_extension == $current_extension then
		$insert &= "remains"
	else
		$insert &= "set to"
		$default_extension = $edit_default_extension
		IniWrite($ini_path, $section, "default_extension", $default_extension)
	endif

	ConsoleAdd("Default extension " & $insert & ": " & $default_extension, @ScriptLineNumber)
endfunc





func AddNotesToPreset()

	if not $current_preset or $current_preset = $EXIT_PRESET then
		return ConsoleAdd("No user preset currently selected!", @ScriptLineNumber)
	endif

	DialogOpen()

	local $previous_event_mode = AutoItSetOption("GUIOnEventMode", 0)
	local $previous_coord_mode = AutoItSetOption("GUICoordMode", 1)

	local $new_notes = false
	local $size_array

	local $min_w = 300
	local $min_h = 100
	local $notes_x = IniRead($ini_path, $my_name, "notes_x", -1)
	local $notes_y = IniRead($ini_path, $my_name, "notes_y", -1)
	local $notes_w = IniRead($ini_path, $my_name, "notes_w", 320)
	local $notes_h = IniRead($ini_path, $my_name, "notes_h", 150)
	if $notes_w < $min_w then $notes_w = $min_w
	if $notes_h < $min_h then $notes_h = $min_h

	local $old_notes = $preset_notes

	local $notes_styles = BitOr($WS_CAPTION, $WS_SIZEBOX, $WS_POPUP)
	local $input_styles = BitOr($ES_LEFT, $ES_AUTOHSCROLL, $ES_MULTILINE, $ES_WANTRETURN)
	local $input_exstyles = BitOr($WS_EX_CLIENTEDGE, $WS_EX_ACCEPTFILES, $WS_EX_TOPMOST)

	local $e_type = "Edit"
	if not $old_notes then $e_type = "Add"
	global $notesGUI = GUICreate($e_type & " notes for " & $current_preset & "..", $notes_w, $notes_h, $notes_x, $notes_y, $notes_styles)

	global $notes_input = GUICtrlCreateInput($old_notes, 10, 10, $notes_w-20, $notes_h-45, $input_styles, $input_exstyles)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKBOTTOM))
	GUICtrlSetTipOptional(-1 , "These notes will be spat out into your ffe console on preset load" & $MSG_LF & _
								"and are a handy place to keep information you might need when" & $MSG_LF & _
								"working with this preset.", "Add some notes for this preset.. ")

	local $butt_cancel = GUICtrlCreateButton("Cancel", 10, $notes_h-30, 75, 22)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKLEFT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))

	local $butt_ok = GUICtrlCreateButton("Save", $notes_w-60, $notes_h-30, 50, 22)
	GUICtrlSetResizing(-1, BitOr($GUI_DOCKRIGHT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))

	GUISetState(@SW_SHOW, $notesGUI)
	HotKeySet("{tab}", "DoTabChar")

	local $msg
	while true

		$msg = GUIGetMsg()
		switch $msg

			case $GUI_EVENT_RESIZED

				$size_array = WinGetPos($notesGUI)
				if not IsArray($size_array) then continueloop

				local $my_width = $size_array[2]
				if $size_array[2] < $min_w then
					WinMove($notesGUI, "", default, default, $min_w, $notes_h)
					$my_width = $min_w
				endif
				if $size_array[3] <> $notes_h then WinMove($notesGUI, "", default, default, $my_width, default)

				local $my_height = $size_array[3]
				if $size_array[3] < $min_h then
					WinMove($notesGUI, "", default, default, default, $min_h)
					$my_height = $min_h
				endif
				if $size_array[3] <> $notes_h then WinMove($notesGUI, "", default, default, default, $my_height)

			case $butt_ok
				$new_notes = GUICtrlRead($notes_input)
				exitloop

			case $GUI_EVENT_CLOSE, $butt_cancel
				exitloop
		endswitch
	wend

	if $msg = $butt_ok then
		$size_array = WinGetPos($notesGUI)
		if IsArray($size_array) then
			IniWrite($ini_path, $my_name, "notes_x", $size_array[0])
			IniWrite($ini_path, $my_name, "notes_y", $size_array[1])
			IniWrite($ini_path, $my_name, "notes_w", $size_array[2])
			IniWrite($ini_path, $my_name, "notes_h", $size_array[3])
		endif
	endif

	AutoItSetOption("GUIOnEventMode", $previous_event_mode)
	AutoItSetOption("GUICoordMode", $previous_coord_mode)
	GUIDelete($notesGUI)


	if $msg = $butt_ok then

		; Set the global variable..
		debug("$new_notes: " & $new_notes, @ScriptLineNumber, 8);debug
		$preset_notes = $new_notes

		; Removing notes..
		if $preset_notes = "" then
			IniDelete($ini_path, $current_preset, "notes")
			ConsoleAdd("Notes removed from " & $current_preset, @ScriptLineNumber)
		else
			; Adding / Editing notes..
			ConvertNewlines($preset_notes, true)
			debug("$preset_notes: " & $preset_notes, @ScriptLineNumber, 8);debug
			IniWrite($ini_path, $current_preset, "notes", $preset_notes)
			GetPresetNotes()
			ConsoleAdd("Preset notes for " & $current_preset & ":" & $LOG_LF & $preset_notes, @ScriptLineNumber)
		endif
	endif

	HotKeySet("{tab}")
	DialogClose()

endfunc


func DoTabChar()
	if WinActive($notesGUI) then
		_GUICtrlEdit_ReplaceSel ($notes_input, chr(9), true)
	else
		HotKeySet("{tab}")
		Send("{tab}")
		HotKeySet("{tab}", "DoTabChar")
	endif
endfunc



; Add or remove parameters to input/output parameters..
; Used by Custom Buttons and Short Test button.
;
func AddRemoveParam($my_current_params, $my_command, $control)

	; If parameters aren't already there, add them..
	if not StringInStr($my_current_params, $my_command) then

		; Remove all leading and trailing spaces..
		$my_current_params = StringStripWS($my_current_params, 3)
		; If (and only if) there are current parameters, pad with one single leading space..
		if $my_current_params then $my_current_params = PadLeft($my_current_params)
		; Finally, add our new command to the existing parameters..
		GUICtrlSetData($control, $my_current_params & PadLeft($my_command))

	; Otherwise, remove them..
	else
		; Remove all leading and trailing spaces from current parameters..
		$my_current_params = StringStripWS($my_current_params, 3)
		; Remove the supplied command and strip leading/trailing spaces from result..
		local $new_params = StringStripWS(StringReplace($my_current_params, $my_command, ""), 3)
		; We might have removed from the middle of the arguments, so replace
		; that double-space then pad the whole lot with a single leading space..
		$new_params = PadLeft(StringReplace($new_params, "  ", " "))
		GUICtrlSetData($control, $new_params)
	endif

endfunc






func _______________MISC_BUTTON()
endfunc


; Clear all the paramater dials and switches back to their defaults..
; Ctrl+Click to also wipe file input/output file paths..
; Shift+Click to ONLY clear the input+output file paths.
func ClickResetEverything()
	local $shiftdown = false
	local $ctrldown = false
	if _IsPressed(10) then $shiftdown = true
	if _IsPressed(11) then $ctrldown = true
	DoClickResetEverything($shiftdown, $ctrldown)
endfunc

; Same as Ctrl+Click, above..
func RightClickResetAll()
	DoClickResetEverything(false, true)
endfunc

func DoClickResetEverything($shifted=false, $ctrled=false)
	if $shifted or $ctrled then
		$inputfile = ""
		$outputfile = ""
		$ini_outputfile = ""
		$output_basefile = ""
		$old_matof = ""
		GUICtrlSetData($inp_inputfile, $inputfile)
		SetOutputTemplate("")
		DoArgsCreate()
	endif
	if $shifted then return
	WipeSettings()
	DoArgsCreate()
	ResetAlteredControls()
	ConsoleAdd("Dials and Switches to Zero!", @ScriptLineNumber)
endfunc

func WipeSettings()

	debug("WipeSettings(!): ", @ScriptLineNumber, 8);debug

	GUICtrlSetData($inp_input_params, "")
	GUICtrlSetData($combo_v_codec, $video_codecs)
	GUICtrlSetData($combo_v_bitrate, $video_bitrates)
	GUICtrlSetData($combo_frames_per_second, $frames_per_second)
	GUICtrlSetData($inp_x_size, "")
	GUICtrlSetData($inp_y_size, "")
	GUICtrlSetData($inp_crop_x, "")
	GUICtrlSetData($inp_crop_height, "")
	GUICtrlSetData($inp_crop_y, "")
	GUICtrlSetData($inp_crop_width, "")
	GUICtrlSetData($combo_a_codec, $audio_codecs)
	GUICtrlSetData($combo_a_bitrate, $audio_bitrates)
	GUICtrlSetData($combo_target_type, $target_types)
	GUICtrlSetData($combo_preset_resizes, $preset_resizes)
	GUICtrlSetData($inp_extra_args, "")

	; GUICtrlSetSTATE ..
	GUICtrlSetState($check_resize_first, $OFF)

	GUICtrlSetState($check_run_pre_job_commands, $UNSET)
	GUICtrlSetState($check_run_post_file_command, $UNSET)
	GUICtrlSetState($check_run_post_job_commands, $UNSET)

	GUICtrlSetState($check_overwrite, $UNSET)
	GUICtrlSetState($check_concatenate, $UNSET)
	GUICtrlSetState($check_quit_when_done, $UNSET)
	GUICtrlSetState($check_shutdown_when_done, $UNSET)

endfunc



func ResetAlteredControls()
	$altered_resize_first = false
	$altered_do_matof = false
	$altered_do_output = false
endfunc



func AddShortTestParam()
	if _IsPressed(10) then UserEditShortTestParams()
	AddRemoveParam(GUICtrlRead($inp_extra_args), "-frames:v " & $short_test_frames, $inp_extra_args)
endfunc



func UserEditShortTestParams()

	DialogOpen()
	local $user_frames = CorzFancyInputBox("Short Test Frames.. ", _
		"Specify a number of frames for the short test button.. ", $short_test_frames , "" , _
														370, 100, default, default, 0, $ffeGUI)
	DialogClose()
	if $user_frames then

		$user_frames = Number($user_frames)
		if $user_frames < 1 or $user_frames > 10000 then $user_frames = 300

		if $short_test_frames <> $user_frames then
			ConsoleAdd("short_test_frames set to: " & $user_frames, @ScriptLineNumber)
			$short_test_frames = $user_frames
			IniWrite($ini_path, $my_name, "short_test_frames", $short_test_frames)
			_GUIToolTip_Destroy($tip_short_test)
			$tip_short_test = GUICtrlSetTipOptional($butt_quicktest , _
				"Adds parameters to process only the first " & $short_test_frames & " frames of video. " & $MSG_LF & _
				"You can edit this number (right-click the button). ", "Add Quick Test Parameters")
		else
			ConsoleAdd("short_test_frames still " & $short_test_frames, @ScriptLineNumber)
		endif
	endif
endfunc




; User altering the cropdetect frames..

func UserEditCropTestFrames($in_crop_frames=default, $save_as_default=false)

	if $in_crop_frames = default then
		$in_crop_frames = Int(IniRead($ini_path, $my_name, "auto_crop_frames", 24))
	endif

	local $error = 0
	local $dialog_title = "For THIS Test.."
	if $save_as_default then $dialog_title = "Set New Default Number.."

	DialogOpen()
	local $new_auto_crop_frames = CorzFancyInputBox($dialog_title, _
		"Enter the number of frames to interrogate.. ", $in_crop_frames, "", 350, 95, default, default, 0, $ffeGUI)
	if @error = 0 then
		if $in_crop_frames <> $new_auto_crop_frames then
			$in_crop_frames = $new_auto_crop_frames
			if $save_as_default then
				IniWrite($ini_path, $my_name, "auto_crop_frames", $in_crop_frames)
				ConsoleAdd($LOG_LF & "AutoCrop default test frames set to: " & $in_crop_frames, true)
			endif
		endif
	else
		$error = 1
	endif

	DialogClose()
	return SetError($error, $in_crop_frames)

endfunc





func ShowOutputButts()
	GUICtrlSetState($butt_copy2clip, $GUI_SHOW)
	GUICtrlSetState($butt_clearout, $GUI_SHOW)
	GUICtrlSetState($butt_find, $GUI_ENABLE)
	GUICtrlSetState($butt_find, $GUI_SHOW)
endfunc

func HideOutputButts()
	GUICtrlSetState($butt_copy2clip, $GUI_HIDE)
	GUICtrlSetState($butt_clearout, $GUI_HIDE)
	GUICtrlSetState($butt_find, $GUI_HIDE)
	GUICtrlSetState($butt_find, $GUI_DISABLE)
endfunc




; Controls we disable/show during an FFmpeg job..
;
func DisableRunningControls()
	GUICtrlSetState($butt_doit, $GUI_DISABLE)
	GUICtrlSetState($inp_inputfile, $GUI_DISABLE)
	GUICtrlSetState($butt_quicktest, $GUI_DISABLE)
	GUICtrlSetState($butt_mediareport, $GUI_DISABLE)
	; GUICtrlSetState($butt_reset, $GUI_DISABLE)
	; Nah, they might want to reset before they begin changing settings and
	; queing up buttons for the next test, while ffmpeg runs.. (yes you can!)
	if IsArray($help_texts) then
		for $i = 1 to $help_texts[0]
			GUICtrlSetState($help_butts[$i], $GUI_DISABLE)
		next
	endif
	GUICtrlSetState($inp_outputfile, $GUI_DISABLE)
	TrayItemSetState($tray_about_ffmpeg, $TRAY_DISABLE)
endfunc


; Re-enable/hide controls after FFmpeg job..
;
func EnableRunningControls()
	if not $ffmpeg_binary then return
	GUICtrlSetState($butt_doit, $GUI_ENABLE)
	GUICtrlSetState($inp_inputfile, $GUI_ENABLE)
	GUICtrlSetState($butt_quicktest, $GUI_ENABLE)
	GUICtrlSetState($butt_mediareport, $GUI_ENABLE)
	if IsArray($help_texts) then
		for $i = 1 to $help_texts[0]
			GUICtrlSetState($help_butts[$i], $GUI_ENABLE)
		next
	endif
	if $do_output = $ON then GUICtrlSetState($inp_outputfile, $GUI_ENABLE)
	$generate_script = false
	TrayItemSetState($tray_about_ffmpeg, $TRAY_ENABLE)
	GUICtrlSetState($edit_console_output, $GUI_ENABLE)
endfunc


func ReturnNow($msg="Error", $retval=-1)
	ConsoleAdd($msg, @ScriptLineNumber)
	SetHotKeys()
	$do_drop_window = $drop_win_state
	ShowOutputButts()
	EnableRunningControls()
	SetWinTitleText()
	return $retval
endfunc










; 		xxx  xxx           xxx            xxx
; 		xxx  xxx           xxx            xxx
; 		xxx  xxx           xxx            xxx
; 		xxx  xxx           xxx            xxx
; 		xxx  xxx   xxxxx   xxx   xxxxxxx  xxx
; 		xxx  xxx  xxxxxxx  xxx   xxxxxxx  xxx
; 		xxxxxxxx  xxx xxx  xxx   xxx  xx  xxx
; 		xxxxxxxx  xxx  xx  xxx   xxx  xxx xxx
; 		xxx  xxx  xxx  xx  xxx   xxx  xxx xxx
; 		xxx  xxx  xxxxxxx  xxx   xxx  xxx xxx
; 		xxx  xxx  xxx      xxx   xxx  xxx xxx
; 		xxx  xxx  xxx      xxx   xxx  xxx
; 		xxx  xxx  xxx xxx  xxx   xxx xxx
; 		xxx  xxx  xxxxxxx  xxxx  xxxxxxx  xxx
; 		xxx  xxx   xxxxx    xxx  xxxxxx   xxx
; 								 xxx
; 								 xxx
; 								 xxx
; 								 xxx



func _________________________HELP()
endfunc



; Custom help..
;
func LoadHelpTexts()
	local $default_help = "Main|help.txt|-h,Filters|help-filters.txt|-filters,Encoders|help-encoders.txt|-encoders,Full|help-full.txt|-h full,ffprobe|ffprobe-help.txt|@appdir\ffprobe.exe -h,ffplay|ffplay-help.txt|@appdir\ffplay.exe -h"
	$help_texts = IniRead($ini_path, $my_name, "help_texts", $default_help)
	$help_texts = StringReplace($help_texts, ",,", ",") ; in case of erm, user error
	if StringInStr($help_texts, "|") then
		$help_texts = StringSplit($help_texts, ",")
		global $help_butts[$help_texts[0]+1] = [$help_texts[0]]
	else
		$help_texts = ""
	endif
endfunc




; Draw the user's help buttons..
;
func CreateHelpButtons()

	debug("CreateHelpButtons().. ", @ScriptLineNumber, 6);debug

	if not IsArray($help_texts) then return false
	debugPrintArray($help_texts, "$help_texts:", @ScriptLineNumber, 7);debug

	; A wee array of button IDs for easy editing/removal of buttons..
	global $help_butts_remove[$help_texts[0]+1] = [$help_texts[0]]
	global $help_butts_editme[$help_texts[0]+1] = [$help_texts[0]]

	; We draw the buttons from right-to-left, so reverse the array first..
	_ArrayReverse($help_texts, 1)


	; Run through the help buttons array..
	;
	for $h = 1 to $help_texts[0]

		debug("$help_texts[$h]: " & $help_texts[$h] & ":" & $h, @ScriptLineNumber, 7);debug

		local $help_data = StringSplit($help_texts[$h], "|")
		if $help_data[0] <> 3 then continueloop
		debugPrintArray($help_data, "$help_data:", @ScriptLineNumber, 7);debug

		local $border = 13
		local $help_x = $h*20
		$help_butts[$h] = GUICtrlCreateButton("?", $width-$help_x-$border, $buttons_xy, 18, 18, BitOr($WS_TABSTOP,$BS_FLAT))

		GUICtrlSetTipOptional(-1, "Click this button to view the " & _
		$help_data[1] & " help file in the console output window (below). " & $MSG_LF & _
							"Shift-click to instead open the help file in your default ." & _
							GetExtension($help_data[2]) & " file viewer ", $help_data[1] & " (Command: " & $help_data[3] & ")")

		GUICtrlSetResizing(-1, BitOr($GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKSIZE))
		GUICtrlSetOnEvent(-1, "HelpMeNow")


		; Context Menu for help buttons..
		local $menu_help_buttons = GUICtrlCreateContextMenu($help_butts[$h])

			; Edit a button..
			$help_butts_editme[$h] = GUICtrlCreateMenuItem("Edit this button", $menu_help_buttons)
			GUICtrlSetOnEvent(-1, "EditHelpButton")

			GUICtrlCreateMenuItem("", $menu_help_buttons)

			; Remove a button..
			$help_butts_remove[$h] = GUICtrlCreateMenuItem("Remove this button", $menu_help_buttons)
			GUICtrlSetOnEvent(-1, "RemoveHelpButton")

			GUICtrlCreateMenuItem("", $menu_help_buttons)

			; Add a button..
			GUICtrlCreateMenuItem("Add a button", $menu_help_buttons)
			GUICtrlSetOnEvent(-1, "AddHelpButton")

	next

endfunc




; Add a help button.. Top-Notch Idea!
;
func AddHelpButton()

	; This should never happen..
	if not IsArray($help_texts) then return false
	local $new_help = EnterHelpButtonDetails("CUSTOM", "custom." & $report_extension, "-help topic", default, default, 0, 6, 6, 11)
	if not $new_help then return false

	_ArrayReverse($help_texts, 1)
	$help_texts = ArrayJoin($help_texts, ",")
	$help_texts &= "," & $new_help

	IniWrite($ini_path, $my_name, "help_texts", $help_texts)
	ConsoleAdd("Adding button: " & StringLeft($new_help, StringInStr($new_help, "|")-1), @ScriptLineNumber)
	ReCreateGUIHelpButtons()

endfunc


func EditHelpButton()

	; This should never happen.
	if not IsArray($help_butts_editme) then return false
	; Again, this should never happen..
	if not IsArray($help_texts) then return false

	local $clicked_butt = InArray($help_butts_editme, @GUI_CtrlId)
	if $clicked_butt < 1 or $clicked_butt > $help_butts_editme[0] then
		ConsoleAdd("Help button out of bounds!", @ScriptLineNumber)
		return
	endif

	local $edit_me = $help_texts[$clicked_butt]
	local $help_data = StringSplit($edit_me, "|")
	if $help_data[0] <> 3 then return

	; So we can select only the basename (minus extension) part, for the user to start typing away..
	local $filename_len = StringLen(CleanName($help_data[2]))
	local $new_details = EnterHelpButtonDetails($help_data[1], $help_data[2], $help_data[3], default, default, 0, $filename_len)
	if not $new_details then return false

	_ArrayReverse($help_texts, 1)
	$help_texts = ArrayJoin($help_texts, ",")
	$help_texts = StringReplace($help_texts, $edit_me, $new_details)

	IniWrite($ini_path, $my_name, "help_texts", $help_texts)
	ConsoleAdd("Edited help button: " & $new_details, @ScriptLineNumber)
	ReCreateGUIHelpButtons()

endfunc



; Three dialogs to return the help button title, file name and command
; already concatenated into the final string..
;
; You can set the text selection start and end points for the three dialogs;
; 0 being the far left side, and -1 being the right. For example, to set the
; selection to the extension part of "file.txt", use 5, -1. By default, the
; entire input text is selected (0,-1).
;
func EnterHelpButtonDetails($title, $filename, $command, $sel1=0, $sel2=-1, $sel3=0, $sel4=-1, $sel5=0, $sel6=-1)

	debug("EnterHelpButtonDetails(title: " & $title & ", filename: " & $filename  & ", command: " & $command & ", sel1: " & $sel1  & ", sel2: " & $sel2  & ", sel3: " & $sel3  & ", sel4: " & $sel4  & ", sel5: " & $sel5  & ", sel6: " & $sel6 & ")...", @ScriptLineNumber, 6);debug

	; Text selection defaults..
	if $sel1 = default then $sel1 = 0
	if $sel2 = default then $sel2 = -1
	if $sel3 = default then $sel3 = 0
	if $sel4 = default then $sel4 = -1
	if $sel5 = default then $sel5 = 0
	if $sel6 = default then $sel6 = -1

	DialogOpen()
	local $butt_title = CorzFancyInputBox("Help Button Title.. ",	_
		"Specify a title for the help button.. ", $title, "", 350 , 90, default, default, 0, $ffeGUI, _
																default, default, default, $sel1, $sel2)
	DialogClose()
	if not $butt_title then return false

	DialogOpen()
	local $butt_filename = CorzFancyInputBox("Help File Name.. ",	_
		"Specify a file name for this (saved) help.. ", $filename, "", 350 , 90, default, default, 0, $ffeGUI, _
																	default, default, default, $sel3, $sel4)
	DialogClose()
	if not $butt_filename then return false

	DialogOpen()
	local $butt_command = CorzFancyInputBox("FFmpeg Command.. ",	_
		"Specify the FFmpeg command used to output this help file. ", $command, "", 350 , 90, default, default, 0, $ffeGUI, _
																		default, default, default, $sel5, $sel6)
	DialogClose()
	if not $butt_command then return false

	return $butt_title & "|" & $butt_filename & "|" & $butt_command
endfunc






; Remove a help button.. Why Oh Why!
;
func RemoveHelpButton()

	debug("RemoveHelpButton()", @ScriptLineNumber, 7);debug

	; This should never happen..
	if not IsArray($help_butts_remove) then return false
	debugPrintArray($help_butts_remove, "$help_butts_remove:", @ScriptLineNumber, 7);debug

	local $clicked_butt = InArray($help_butts_remove, @GUI_CtrlId)

	if $clicked_butt < 1 or $clicked_butt > $help_butts_remove[0] then
		ConsoleAdd("Help button out of bounds!", @ScriptLineNumber)
		return
	endif

	local $removed = $help_texts[$clicked_butt]
	_ArrayReverse($help_texts, 1)
	$help_texts = ArrayJoin($help_texts, ",")
	$help_texts = StringReplace($help_texts, $removed, "")
	$help_texts = StringReplace($help_texts, ",,", ",")
	CBT($help_texts, ",")
	debug("$help_texts: " & $help_texts, @ScriptLineNumber, 7);debug

	IniWrite($ini_path, $my_name, "help_texts", $help_texts)
	ConsoleAdd("Removed help button: " & StringLeft($removed, StringInStr($removed, "|")-1), @ScriptLineNumber)
	ReCreateGUIHelpButtons()

endfunc



func ReCreateGUIHelpButtons()
	for $i = 1 to Ubound($help_butts)-1
		GUICtrlDelete($help_butts[$i])
	next
	GUICtrlSetData($lab_help_info, "")
	LoadHelpTexts()
	CreateHelpButtons()
endfunc





func HelpMeNow()
	debug("HelpMeNow()...", @ScriptLineNumber, 7);debug

	local $this_helpfile, $this_command, $console_out
	local $clicked_butt = InArray($help_butts, @GUI_CtrlId)

	if $clicked_butt < 1 or $clicked_butt > $help_texts[0] then
		ConsoleAdd("ILLEGAL BUTTON ERROR!", @ScriptLineNumber)
		return
	endif

	; SHIFT+Click to open in viewer/editor..	(grab NOW!)
	local $shift_open = false
	if _IsPressed(10) then $shift_open = true

	local $my_help_entry = StringSplit($help_texts[$clicked_butt], "|")

	if $my_help_entry[0] <> 3 then
		ConsoleAdd("Error: Invalid help button text.", @ScriptLineNumber)
		return
	endif

	$this_helpfile = $my_help_entry[2]
	$this_command = ffeDeTokenizeString($my_help_entry[3])
	debug("$this_command: " & $this_command, @ScriptLineNumber, 7);debug

	local $err, $full_log = ""
	local $help_dir = $data_dir & "\Help\"
	if $portable then $help_dir = @ScriptDir & "\Help\"
	if not FileExists($help_dir) then DirCreate($help_dir)
	local $nfo_loc = $help_dir & $this_helpfile
	debug("$nfo_loc: " & $nfo_loc, @ScriptLineNumber, 7);debug

	; Always grab fresh each run, but grab only once (FFmpeg binary assumed not to be updated in this time).
	if not StringInStr($got_helps, $this_helpfile & $this_command) or not FileExists($nfo_loc) then
		debug("Creating FRESH help file: " & $nfo_loc, @ScriptLineNumber, 7);debug

		; Fall-back to ffmpeg help output..
		if not StringInStr($this_command, ":\") then
			$this_command = $ffmpeg_binary & " " & $this_command
		endif
		debug("$this_command: " & $this_command, @ScriptLineNumber, 7);debug

		; Run FFmpeg with help flags (capture stdout only - not merged, which would mess up the help)..
		local $gethelp = Run($this_command, "", @SW_HIDE, $STDOUT_CHILD)
		debug("$gethelp: " & $gethelp, @ScriptLineNumber, 8);debug

		while true
			$err = false
			$console_out = StdOutRead($gethelp)
			$err = @error
			if $console_out then $full_log &= $console_out
			if $err then exitloop
			Sleep(25)
		wend

		; Just in case..
		StdioClose($gethelp)

		; Write out help text to a file..
		if FileExists($nfo_loc) then FileDelete($nfo_loc)
		local $help_file_open = FileOpen($nfo_loc, $FO_OVERWRITE+ $FO_CREATEPATH+$FO_UTF8_NOBOM)
		FileWrite($help_file_open, $full_log)
		FileClose($help_file_open)

		; Add this help file to "already seen" list
		if not StringInStr($got_helps, $this_helpfile & $this_command) then $got_helps &= $this_helpfile & $this_command & "|"

	else
		; Read existing help file..
		$full_log = FileRead($nfo_loc)
	endif

	if $shift_open then
		ShellExecute($nfo_loc)
	else
		SetConsoleOutput($full_log, true)
	endif

endfunc





; AppMenu..
;
; I LOVE this thing!
; Get to it like this (any method works)..
;
; Alt+Space
; Click App Icon (top-left of window)
; Right-Click app's title bar
;

func __________APP_MENU_FUNCS()
endfunc



; An app menu item was clicked..

func CheckAppMenu($hWnd, $Msg, $wParam, $lParam)
#forceref $hWnd, $Msg, $lParam

	local $nID = BitAnd($wParam, 0x0000FFFF)

	switch $nID
		case $arTransItems[0] to $arTransItems[9]
			SetTransparency($nID)

		case $arCPUItems[0] to $arCPUItems[5]
			SetffmpegCPUPriority($nID)

		case $ReportTypesMenuItems[0] to $ReportTypesMenuItems[6]
			SetFFprobeFormat($nID)

		case $am_post_file_capture
			MenuTogglePostFileCapture()

		case $am_post_file_show
			MenuTogglePostFileShow()

		case $PostFileRunStylesMenuItems[0] to $PostFileRunStylesMenuItems[2]
			SetPostFileRunStyle($nID)

		case $am_save_reports
			MenuToggleSaveReports()

		case $am_use_mediainfo
			MenuSetUseMediaInfo()

		case $DropCommandMenuItems[0] to $DropCommandMenuItems[3]
			SetDropCommand($nID)

		case $am_launch_with_drop_command
			SetLaunchDropCommand()

		case $am_about
			DoAboutBox()

		case $am_about_ffmpeg
			DoAboutFFmpeg()

		case $am_retain_exit_settings
			MenuRetainExitSettings()

		case $am_auto_codecs
			MenuToggleAutoCodecs()

		case $am_allow_multiple
			MenuToggleAllowMultiple()

		case $am_pause_is_global
			TogglePauseIsGlobal()

		case $am_kill_ffmpeg_on_exit
			ToggleKillffmpegOnExit()

		case $am_start_minimized
			MenuToggleStartMin()

		case $am_always_warn_on_delete
			SetWarnOnDelete()

		case $am_delete_to_recycle_bin
			SetDeleteToRecycleBin()

		case $am_default_extension
			SetDefExtension()

		case $am_show_ffplay_output
			ToggleShowFFplayOut()

		case $am_do_countdown_timer
			ToggleDoCountdown()

		case $am_always_on_top
			MenuToggleOnTop()

		case $am_console_wordwrap
			MenuToggleWrapConsole()

		case $am_allow_output_tooltip
			MenuToggleConsoleTips()

		case $am_log_each_job
			MenuToggleLogEachJob()

		case $am_log_append
			ToggleLogAppend()

		case $am_job_log_append
			ToggleJobLogAppend()

		case $am_do_tooltips
			MenuToggleToolTipHelp()

		case $am_time_in_title
			MenuToggleTimeInTitle()

		case $am_sort_presets_list
			MenuToggleSortPresets()

		case $am_image_buttons
			MenuToggleImgButts()

		; We keep these down here in case they get set off when adjusting visual prefs. That's right! :/
		case $CustomButtonMenuItems[0] to $CustomButtonMenuItems[501]
			SetCustomButtonColumns($nID)

		case $am_button_notes_to_console
			MenuToggleNotesInConsole()

	    case $am_enable_custom_buttons
			MenuToggleCustomButtons()
			if $enable_custom_buttons = $OFF then
				ConsoleAdd("Custom button disabled. Restart required.", @ScriptLineNumber)
			else
				ConsoleAdd("Custom button enabled.", @ScriptLineNumber)
				LoadCustomButtonData()
				ReCreateButtonGrid()
			endif
	endswitch
endfunc





; Generic AppMenu toggling function (for booleans).
; This makes it trivial to add new menu items.

func ToggleAppMenuItem(ByRef $setting, $menu_item, $ini_name, $report=true, $restart=false, $orig_setting=-1, $menu_text="")
	local $app_menu = GetSystemMenu($ffeGUI, 0)
	if $setting = $OFF then
		$setting = $ON
		CheckMenuItem($app_menu, $menu_item, $MF_CHECKED)
		if $report then ConsoleAdd($ini_name & ": enabled", @ScriptLineNumber)
	else
		$setting = $OFF
		CheckMenuItem($app_menu, $menu_item, $MF_UNCHECKED)
		if $report then ConsoleAdd($ini_name & ": disabled", @ScriptLineNumber)
	endif

	local $pend_add = ")"
	if $restart and $menu_text then
		if $setting <> $orig_setting then $pend_add = " Pending)"
		_GUICtrlMenu_SetItemText($app_menu, $menu_item, $menu_text & $pend_add, false)
	endif

	IniWriteCheckBoxValue($ini_path, $my_name, $ini_name, $setting)

	return $pend_add
endfunc



func MenuToggleSortPresets()
	local $pend_add = ")"
	$pend_add = ToggleAppMenuItem($sort_presets_list, $am_sort_presets_list, "sort_presets_list", _
									false, true, $sort_presets_list_orig, $sort_presets_list_texts)
	GUICtrlSetState($ctxt_combo_sort, $sort_presets_list)
	GUICtrlSetData($ctxt_combo_sort, $sort_presets_list_texts & $pend_add)
	ConsoleAdd("Preset List Sorting: " & Human($sort_presets_list) & " (restart to see changes)", @ScriptLineNumber)
endfunc



; global AppMenu items..

func MenuToggleLogEachJob()
	ToggleAppMenuItem($log_each_job, $am_log_each_job, "log_each_job", false)
	ConsoleAdd("Preset list sorting: " & Human($sort_presets_list) & " (restart to see changes)", @ScriptLineNumber)
endfunc

func ToggleLogAppend()
	ToggleAppMenuItem($log_append, $am_log_append, "log_append")
endfunc

func ToggleJobLogAppend()
	ToggleAppMenuItem($job_log_append, $am_job_log_append, "job_log_append")
endfunc



func MenuRetainExitSettings()
	ToggleAppMenuItem($retain_exit_settings, $am_retain_exit_settings, "retain_exit_settings")
	if $retain_exit_settings = $ON and not $loaded_exit_settings and PresetExists($EXIT_PRESET) then
		local $ldset = MsgBox($MB_OKCANCEL, "Load Previous Exit Settings?", "Do you wish to load the saved exit settings?")
		if $ldset = $IDOK then
			debug("Loading preset : " & $EXIT_PRESET, @ScriptLineNumber, 4);debug
			$preset_loaded = LoadPreset($EXIT_PRESET)
		endif
	endif
endfunc


func MenuToggleAutoCodecs()
	ToggleAppMenuItem($auto_codecs, $am_auto_codecs, "auto_codecs")
	UpdateCodecCombos()
endfunc

func UpdateCodecCombos()
	local $current_vcodec = GUICtrlread($combo_v_codec)
	local $current_acodec = GUICtrlread($combo_a_codec)
	GUICtrlSetData($combo_v_codec, "")
	GUICtrlSetData($combo_a_codec, "")
	GetUserCodecs()
	GUICtrlSetData($combo_v_codec, $video_codecs)
	GUICtrlSetData($combo_a_codec, $audio_codecs)
	GUICtrlSetData($combo_v_codec, $current_vcodec)
	GUICtrlSetData($combo_a_codec, $current_acodec)
	CreateCodecContexts()
endfunc



func SetLaunchDropCommand()
	ToggleAppMenuItem($launch_with_drop_command, $am_launch_with_drop_command, "launch_with_drop_command")
endfunc


func MenuToggleImgButts()
	ToggleAppMenuItem($image_buttons, $am_image_buttons, "image_buttons", false, true, $image_buttons_orig, $image_buttons_text)
	ConsoleAdd("Images On (some) Buttons: " & Human($image_buttons) & " (restart to see changes)", @ScriptLineNumber)
endfunc


func MenuToggleToolTipHelp()
	ToggleAppMenuItem($do_tooltips, $am_do_tooltips, "do_tooltips", false, true, $do_tooltips_orig, $do_tooltips_text)
	ConsoleAdd("Help(ful) ToolTips: " & Human($do_tooltips) & " (restart to see changes)", @ScriptLineNumber)
endfunc


func MenuToggleConsoleTips()
	ToggleAppMenuItem($allow_console_tooltip, $am_allow_output_tooltip, "allow_console_tooltip", false, true, $allow_console_tooltip_orig, $allow_console_tooltip_text)
	ConsoleAdd("Console ToolTips: " & Human($allow_console_tooltip) & " (restart to see changes)", @ScriptLineNumber)
endfunc


func MenuToggleWrapConsole()
	ToggleAppMenuItem($console_wordwrap, $am_console_wordwrap, "console_wordwrap", false, true, $console_wordwrap_orig, $console_wordwrap_text)
	ConsoleAdd("Console Wordwrap: " & Human($console_wordwrap) & " (restart to see changes)", @ScriptLineNumber)
endfunc


func MenuToggleCustomButtons()
	ToggleAppMenuItem($enable_custom_buttons, $am_enable_custom_buttons, "enable_custom_buttons")
endfunc


func MenuToggleOnTop()
	ToggleAppMenuItem($always_on_top, $am_always_on_top, "on_top")
	SetOnTop()
endfunc

func SetOnTop()
	if $always_on_top = $ON then
		WinSetOnTop($ffeGUI, "", 1)
	else
		WinSetOnTop($ffeGUI, "", 0)
	endif
endfunc


func MenuToggleTimeInTitle()
	ToggleAppMenuItem($time_in_title, $am_time_in_title, "time_in_title")
	if $time_in_title = $OFF then SetWinTitleText($title_msg_string)
endfunc


func MenuToggleAllowMultiple()
	ToggleAppMenuItem($allow_multiple, $am_allow_multiple, "allow_multiple")
endfunc


func ToggleDoCountdown()
	ToggleAppMenuItem($do_countdown_timer, $am_do_countdown_timer, "do_countdown_timer")
endfunc


func ToggleKillffmpegOnExit()
	ToggleAppMenuItem($kill_ffmpeg_on_exit, $am_kill_ffmpeg_on_exit, "kill_ffmpeg_on_exit")
endfunc

func TogglePauseIsGlobal()
	ToggleAppMenuItem($pause_is_global, $am_pause_is_global, "pause_is_global")
endfunc


func SetWarnOnDelete()
	ToggleAppMenuItem($always_warn_on_delete, $am_always_warn_on_delete, "always_warn_on_delete")
endfunc


func SetDeleteToRecycleBin()
	ToggleAppMenuItem($delete_to_recycle_bin, $am_delete_to_recycle_bin, "delete_to_recycle_bin")
	if $delete_to_recycle_bin = $OFF then
		IniWriteCheckBoxValue($ini_path, $my_name, "warning_seen_output_delete", $OFF)
		ConsoleAdd("Re-enabled one-time warning about permanent deletion. ", @ScriptLineNumber)
	endif
endfunc

func MenuToggleStartMin()
	ToggleAppMenuItem($start_minimized, $am_start_minimized, "start_minimized")
endfunc


func ToggleShowFFplayOut()
	ToggleAppMenuItem($show_ffplay_output, $am_show_ffplay_output, "show_ffplay_output")
endfunc



func MenuTogglePostFileCapture()
	ToggleAppMenuItem($post_file_capture, $am_post_file_capture, "post_file_capture")
endfunc

func MenuTogglePostFileShow()
	ToggleAppMenuItem($post_file_show, $am_post_file_show, "post_file_show")
endfunc


func MenuToggleNotesInConsole()
	ToggleAppMenuItem($button_notes_to_console, $am_button_notes_to_console, "button_notes_to_console")
endfunc


func MenuToggleSaveReports()
	ToggleAppMenuItem($save_reports, $am_save_reports, "save_reports")
endfunc

func MenuSetUseMediaInfo()
	TogglePref($use_mediainfo)
	IniWriteCheckBoxValue($ini_path, $my_name, "use_mediainfo", $use_mediainfo)
	ConsoleAdd("MediaInfo reporting set to: " & Human($use_mediainfo), @ScriptLineNumber)
	SetUseMediaInfo()
endfunc


func SetUseMediaInfo()
	local $app_menu = GetSystemMenu($ffeGUI, 0)
	if not FileExists($mediainfo_location) then
		ConsoleAdd("MediaInfo.exe not found! Locating..", @ScriptLineNumber)
		LocateMediaInfo()
		if not FileExists($mediainfo_location) then
			AppMenuItemSetState($app_menu, $am_use_mediainfo, $OFF)
			$use_mediainfo = $OFF
			IniWriteCheckBoxValue($ini_path, $my_name, "use_mediainfo", $use_mediainfo)
		endif
	endif
	if $use_mediainfo = $ON then
		CheckMenuItem($app_menu, $am_use_mediainfo, $ON)
		CheckMenuItem($app_menu, $nRTChecked, $MF_UNCHECKED)
		$store_probe_type = $nRTChecked
		$nRTChecked = ""
	else
		CheckMenuItem($app_menu, $am_use_mediainfo, $OFF)
		CheckMenuItem($app_menu, $store_probe_type, $ON)
		ConsoleAdd("ffprobe reporting enabled.", @ScriptLineNumber)
		ConsoleAdd("ffprobe format: " & $report_format, @ScriptLineNumber)
	endif
endfunc




; Non-Toggling AppMenu commands..

func SetPostFileRunStyle($nID)
	debug("SetPostFileRunStyle(nID:" & $nID & ")...", @ScriptLineNumber, 5);debug

	local $app_menu = GetSystemMenu($ffeGUI, 0)

	for $i = 0 to 2
		if $PostFileRunStylesMenuItems[$i] = $nID then exitloop
	next

	$post_file_run_style = $PostFileRunStyles[$i]
	if $pfsChecked <> $nID then CheckMenuItem($app_menu, $pfsChecked, $MF_UNCHECKED)
	CheckMenuItem($app_menu, $nID, $MF_CHECKED)
	IniWrite($ini_path, $my_name, "post_file_run_style", $post_file_run_style)
	$pfsChecked = $nID
	ConsoleAdd("Post-File Run Style set to: " & $post_file_run_style, @ScriptLineNumber)
endfunc



; Set the window transparency..

func SetTransparency($nID)
	; Although you can access menu vars directly in many cases, it's smart to
	; set a convention for these calls and always use $app_menu.
	local $app_menu = GetSystemMenu($ffeGUI, 0)
	for $i = 0 to 9
		if $arTransItems[$i] = $nID then exitloop
	next
	$user_trans = 10 * $i
	local $trans_level = 255 * (100 - $user_trans) / 100

	WinSetTrans($ffeGUI, "", $trans_level)
	if $nTPChecked <> $nID then CheckMenuItem($app_menu, $nTPChecked, $MF_UNCHECKED)
	CheckMenuItem($app_menu, $nID, $MF_CHECKED)
	IniWrite($ini_path, $my_name, "transparency", $user_trans)
	$nTPChecked = $nID
	ConsoleAdd("Transparency set to: " & $user_trans & "%", @ScriptLineNumber)
endfunc


; Set FFmpeg process priority..

func SetffmpegCPUPriority($nID)
	local $app_menu = GetSystemMenu($ffeGUI, 0)
	for $i = 0 to 5
		if $arCPUItems[$i] = $nID then exitloop
	next
	$cpu_priority = $i
	ProcessSetPriority($ffmpeg, $cpu_priority) ; only works if running
	if $nCPUChecked <> $nID then CheckMenuItem($app_menu, $nCPUChecked, $MF_UNCHECKED)
	CheckMenuItem($app_menu, $nID, $MF_CHECKED)
	IniWrite($ini_path, $my_name, "cpu_priority", $cpu_priority)
	$nCPUChecked = $nID
	ConsoleAdd("FFmpeg process priority: " & $cpu_priority & " (" & $arCPU[$i] & ")", @ScriptLineNumber)
endfunc





; Set the type of reporting ffprobe does..

func SetFFprobeFormat($nID)
	local $app_menu = GetSystemMenu($ffeGUI, 0)
	for $i = 0 to 6
		if $ReportTypesMenuItems[$i] = $nID then exitloop
	next
	; We access the original report types array by index (and access the menu by idx),
	; so we can style the actual menu however we want.
	$report_format = $ReportTypes[$i]

	if $nRTChecked <> $nID then CheckMenuItem($app_menu, $nRTChecked, $MF_UNCHECKED)
	if $store_probe_type <> $nID then CheckMenuItem($app_menu, $store_probe_type, $MF_UNCHECKED)
	CheckMenuItem($app_menu, $nID, $MF_CHECKED)
	CheckMenuItem($app_menu, $am_use_mediainfo, $MF_UNCHECKED)
	IniWrite($ini_path, $my_name, "report_format", $report_format)
	$use_mediainfo = $OFF
	IniWriteCheckBoxValue($ini_path, $my_name, "use_mediainfo", $use_mediainfo)
	if not $nRTChecked then ConsoleAdd("ffprobe reporting: enabled", @ScriptLineNumber)
	$nRTChecked = $nID
	ConsoleAdd("ffprobe format: " & $report_format, @ScriptLineNumber)
endfunc


; Set the current drag-and-drop command..

func SetDropCommand($nID)
	local $app_menu = GetSystemMenu($ffeGUI, 0)
	for $i = 0 to 3
		; $DropCommandMenuItems[$i] = 142, or whatever..
		if $nID = $DropCommandMenuItems[$i] then exitloop
	next
	$drop_command = $DropCommands[$i]

	if $nDCChecked <> $nID then CheckMenuItem($app_menu, $nDCChecked, $MF_UNCHECKED)
	CheckMenuItem($app_menu, $nID, $MF_CHECKED)
	IniWrite($ini_path, $my_name, "drop_command", $drop_command)
	$nDCChecked = $nID
	ConsoleAdd("Drag-and-drop command set to: " & $drop_command, @ScriptLineNumber)
endfunc


; Set the number of custom button columns (from app menu - updates live)..
;
func SetCustomButtonColumns($nID)
	local $app_menu = GetSystemMenu($ffeGUI, 0)
	for $i = 1 to 500
		if $CustomButtonMenuItems[$i] = $nID then exitloop
	next
	; if $i = 26 then $i = 0
	if $i = 501 then $i = "auto"

	$custom_buttons_columns = $i
	if $CBMChecked <> $nID then CheckMenuItem($app_menu, $CBMChecked, $MF_UNCHECKED)
	CheckMenuItem($app_menu, $nID, $MF_CHECKED)
	IniWrite($ini_path, $my_name, "custom_buttons_columns", $custom_buttons_columns)
	$CBMChecked = $nID
	ReCreateButtonGrid()
endfunc







; Application menu system functions..
; https://msdn.microsoft.com/en-us/library/windows/desktop/ff468865%28v=vs.85%29.aspx

func GetSystemMenu($hWnd, $bRevert)
	local $app_menu = DllCall("user32.dll",	"hwnd", "GetSystemMenu", _
											"hwnd", $hWnd, _
											"int", $bRevert)
	return $app_menu[0]
endfunc


func InsertMenu($app_menu, $nPosition, $nFlags, $nIDNewItem, $lpNewItem)
	local $nResult = DllCall("user32.dll",	"int", "InsertMenu", _
											"hwnd", $app_menu, _
											"int", $nPosition, _
											"int", $nFlags, _
											"int", $nIDNewItem, _
											"str", $lpNewItem)
	return $nResult[0]
endfunc


func CreatePopupMenu()
	local $app_menu = DllCall("user32.dll", "hwnd", "CreatePopupMenu")
	return $app_menu[0]
endfunc

; 0xFFFFFFFF means "insert at the end"
func CreateSystemMenuItem($sText, $app_menu = -1, $bIsPopup=false, $nPos=0xFFFFFFFF)

	if $app_menu = -1 then $app_menu = GetSystemMenu($ffeGUI, 0)

	local $nID = GUICtrlCreateDummy()
	local $nFlags = 0

	if $sText = "" then
		$nFlags = $MF_SEPARATOR
	elseif $bIsPopup then
		$nID = CreatePopupMenu()
		$nFlags = $MF_POPUP
	endif

	$nFlags = BitOr($MF_BYPOSITION, $nFlags)
	InsertMenu($app_menu, $nPos, $nFlags, $nID, $sText)
	return $nID
endfunc

func CheckMenuItem($app_menu, $nID, $nFlags)
	; So we can pass values directly from "checkboxe boolean" values..
	if $nFlags = $ON then $nFlags = $MF_CHECKED
	if $nFlags = $OFF then $nFlags = $MF_UNCHECKED
	DllCall("user32.dll",	"int", "CheckMenuItem", _
							"hwnd", $app_menu, _
							"int", $nID, _
							"int", $nFlags)
endfunc


func AppMenuItemSetState($app_menu, $nID, $state=$ON)
	if $state = $ON then
		; Enabled
		$state = 0x0
	else
		; Disabled (greyed)
		$state = 0x00000002
	endif
	DllCall("user32.dll",	"int", "EnableMenuItem", _
							"hwnd", $app_menu, _
							"int", $nID, _
							"int", $state)
endfunc








func _____________OTHER_TOGGLES()
endfunc





; Other global Toggles..


; Toggle Main Window...
func ToggleWindow()
	if $minimized = $OFF then
		$minimized = $ON
		UnSetHotKeys()
		GUISetState(@SW_HIDE, $ffeGUI)
		if $do_drop_window = $ON then GUISetState(@SW_SHOW, $GUI_DropWindow)
	else
		$minimized = $OFF
		GUISetState(@SW_SHOW, $ffeGUI)
		TrayItemSetState($tray_toggle_start_minimized, $TRAY_ENABLE)
		SetHotKeys()
	endif
	IniWriteCheckBoxValue($ini_path, $my_name, "minimized", $minimized)
endfunc


func ToggleMaximizeWindow()
	if $maximized = $ON then
		GUISetState(@SW_RESTORE, $ffeGUI)
		$maximized = $OFF
	else
		GUISetState(@SW_MAXIMIZE, $ffeGUI)
		$maximized = $ON
	endif
	IniWriteCheckBoxValue($ini_path, $my_name, "maximized", $maximized)
	ConsoleAdd("maximized: " &  Human($maximized), @ScriptLineNumber)
endfunc


; Replace or add parameters from presets..
func TogglePresetMode()
	$replace_mode = GUICtrlRead($radio_preset_replace)
	IniWriteCheckBoxValue($ini_path, $my_name, "replace_mode", $replace_mode)
	ConsoleAdd("replace_mode: " &  Human($replace_mode), @ScriptLineNumber)
endfunc

func ToggleStorePaths()
	$store_filepaths = GUICtrlRead($check_store_filepaths)
	IniWriteCheckBoxValue($ini_path, $my_name, "store_filepaths", $store_filepaths)
	ConsoleAdd("store_filepaths: " &  Human($store_filepaths), @ScriptLineNumber)
endfunc





; Other preset-level toggles..

; Enable/disable output (for image sequences, etc.)..
func ToggleOutput()

	; Only the label click can open the folder. Preset loading calls this too.
	if @GUI_CtrlId = $lab_outputfile and _IsPressed($VK_SHIFT) then
		local $output_path = ffeDeTokenizeString(GUICtrlRead($inp_outputfile))
		if IsDir($output_path) then
			ConsoleAdd("Opening Output Dir: " & $output_path, @ScriptLineNumber)
			OpenSomething($output_path)
		else
			ConsoleAdd("Opening Output Dir: " & GetParent($output_path), @ScriptLineNumber)
			OpenFolderFileSelected($output_path, $inp_outputfile)
		endif
		return
	endif

	$altered_do_output = true
	if $do_output = $ON then
		$do_output = $OFF
		GUICtrlSetState($inp_outputfile, $GUI_DISABLE)
		ConsoleAdd("Output: disabled")
	else
		$do_output = $ON
		GUICtrlSetState($inp_outputfile, $GUI_ENABLE)
		ConsoleAdd("Output: enabled", @ScriptLineNumber)
	endif
endfunc


func ClickToggleMatofStatus()
	$altered_do_matof = true
	ToggleMatofStatus()
endfunc

; Toggle MATOF..
; This can be set inside DoArgsCreate, hence the loop-preventing flag.
func ToggleMatofStatus($new_args=true)
	; Change the mode without restoring an old preview or discarding a template.
	CaptureOutputTemplate()
	TogglePref($do_matof)
	if IsWild($inputfile) then $do_matof = $ON
	IniWriteCheckBoxValue($ini_path, $my_name, "do_matof", $do_matof)
	ConsoleAdd("MATOF Status set to: " & Human($do_matof), @ScriptLineNumber)
	; In case called from inside batch (not clicked)
	GUICtrlSetState($check_do_matof, $do_matof)
	if $new_args then DoArgsCreate()
endfunc


; Toggling Shutdown on exit greys/ungreys Quit on exit
;
func ShutDownOverrideQuit()
	if $shutdown_when_done = $ON then
		GuiCtrlSetState($check_quit_when_done, $ON)
		GuiCtrlSetState($check_quit_when_done, $GUI_DISABLE)
	else
		GuiCtrlSetState($check_quit_when_done, $quit_when_done)
		GuiCtrlSetState($check_quit_when_done, $GUI_ENABLE)
	endif
endfunc






func _____________________HOTKEYS()
endfunc

; HotKeys.

; ^ = Ctrl
; + = Shift

; Also used, set elsewhere..

;	{SCROLLLOCK}	(when FFmpeg is running)
;	{PAUSE}			(when FFmpeg is running)
;	^q				(when FFmpeg is running)
;	n				(temporarily, when an FFmpeg response is required)
;	y				(temporarily, when an FFmpeg response is required)


func SetHotKeys()
	HotKeySet("{TAB}", "TabToCreateArgs")
endfunc


func UnSetHotKeys()
	HotKeySet("{TAB}")
endfunc


; Create the arguments afresh every time you use the <TAB> key..
func TabToCreateArgs()
	HotKeySet("{TAB}")
	Send("{TAB}")
	HotKeySet("{TAB}","TabToCreateArgs")
	if WinActive($ffeGUI) then DoArgsCreate()
endfunc




; Special "Running" HotKeys..
; In case the user needs to respond to an FFmpeg prompt..
; These send the keys to StdIn, which FFmpeg intercepts.

func HK_FFmpegResponseYes()
	if WinActive($ffeGUI) then
		local $ret = StdinWrite($ffmpeg, "y" & $LOG_LF)
		debug("StdInWrite returned: " & $ret, @ScriptLineNumber, 6);debug
		SetWinTitleText($title_msg_string)
	else
		HotKeySet("y")
		Send("y")
		HotKeySet("y", "HK_FFmpegResponseYes")
	endif
endfunc

func HK_FFmpegResponseNo()
	if WinActive($ffeGUI) then
		local $ret = StdinWrite($ffmpeg, "n" & $LOG_LF)
		debug("StdInWrite returned: " & $ret, @ScriptLineNumber, 6);debug
		SetWinTitleText($title_msg_string)
	else
		HotKeySet("n")
		Send("n")
		HotKeySet("n", "HK_FFmpegResponseNo")
	endif
endfunc


; Suspend/Resume console output during a job..
;
func PauseOutPut()
	if WinActive($ffeGUI) then
		if $output_paused then
			$output_paused = false
			GUICtrlSetState($edit_console_output, $GUI_ENABLE)
			GUICtrlSetState($edit_console_output, $GUI_FOCUS)
		else
			$output_paused = true
			GUICtrlSetState($edit_console_output, $GUI_DISABLE)
		endif
	else
		HotKeySet("!c")
		Send("!c")
		HotKeySet("!c", "PauseOutPut")
	endif
endfunc



; Send an abort command to the running console application (FFmpeg)..

func HK_FFmpegAbort()
	if WinActive($ffeGUI) then
		debug("sending 'q' to FFmpeg..", @ScriptLineNumber, 7);debug
		local $siw = StdInWrite($ffmpeg, "q")
		debug("wrote " & $siw & " characters to StdIn.", @ScriptLineNumber, 7);debug
		Sleep(250)
		ProcessClose($ffmpeg)
		ConsoleAdd("User aborted.", @ScriptLineNumber)
		DoLog($LOG_LF & "user sent abort command!" & $LOG_LF & $LOG_LF)
	else
		HotKeySet("^q")
		Send("^q")
		HotKeySet("^q", "HK_FFmpegAbort")
	endif
endfunc

func HK_RunningAbortBatch()
	if WinActive($ffeGUI) then
		$abort_batch = true
	else
		HotKeySet("{PAUSE}")
		Send("{PAUSE}")
		HotKeySet("{PAUSE}", "HK_RunningAbortBatch")
	endif
endfunc

func HK_ProcessPauseSuspend()
	if WinActive($ffeGUI) or $pause_is_global = $ON then
		if $paused then
			$paused = false
			ProcessSuspendResume($ffmpeg, false)
			SetWinTitleText($title_msg_string)
		else
			$paused = true
			ProcessSuspendResume($ffmpeg)
			SetWinTitleText($title_msg_string & " (Paused)")
		endif
	else
		HotKeySet("{SCROLLLOCK}")
		Send("{SCROLLLOCK}")
		HotKeySet("{SCROLLLOCK}", "HK_ProcessPauseSuspend")
	endif
endfunc


; Ctrl+R during FFmpeg run
func HK_ToggleTitleTime()
	if WinActive($ffeGUI) then
		MenuToggleTimeInTitle()
	else
		HotKeySet("^r")
		Send("^r")
		HotKeySet("^r", "HK_ToggleTitleTime")
	endif
endfunc








func _________________________FIND()
endfunc

; Find..


func HKFindInOutput()
	FindInOutput(false)
endfunc

func HKFindReplaceInOutput()
	FindInOutput(true)
endfunc

func Butt_FindInOutput()
	; Shift Key down (replace)..
	if _IsPressed(10) then
		FindInOutput(true)
	else
		FindInOutput(false)
	endif
endfunc

func FindInOutput($use_replace=false)
	local $con_txt = GUICtrlRead($edit_console_output)
	if $con_txt then
		local $previous_event_mode = AutoItSetOption("GUIOnEventMode", 0)
		if $use_replace then
			_GUICtrlCustomEdit_Find($edit_console_output, 1) ; test replace
		else
			_GUICtrlCustomEdit_Find($edit_console_output)
		endif
		AutoItSetOption("GUIOnEventMode", $previous_event_mode)
	else
		SetWinTitleText("                *** The console is empty. Use the force. ***")
		AdLibRegister("ResetTitle", 3000)
	endif
endfunc






func _______________STRING_FUNCS()
endfunc





; The usual error checking has been omitted here - let the user

func ffeDeTokenizeString($string)

	if not $string then return $string
	if not StringInStr($string, "@") then return $string
	$string = FixPathSlashes($string)

	; Dynamic @tokens..
	$string = StringReplace($string, "@inputfile", $inputfile)
	$string = StringReplace($string, "@item", RemoveExtension(BaseName($inputfile)))
	$string = StringReplace($string, "@ext", GetExtension($inputfile))
	$string = StringReplace($string, "@oext", GetExtension($outputfile))
	$string = StringReplace($string, "@ofilename", BaseName($outputfile))

	$string = StringReplace($string, "@Sec", @Sec)
	$string = StringReplace($string, "@Min", @Min)
	$string = StringReplace($string, "@Hour", @Hour)
	$string = StringReplace($string, "@Mday", @Mday)
	$string = StringReplace($string, "@Mon", @Mon)
	$string = StringReplace($string, "@Year", @Year)
	$string = StringReplace($string, "@Wday", @Wday)
	$string = StringReplace($string, "@Yday", @Yday)

	; Path @tokens..
	$string = StringReplace($string, "@mydocuments", @MyDocumentsDir)
	$string = StringReplace($string, "@desktop", @DesktopDir)
	$string = StringReplace($string, "@tempdir", @TempDir)
	$string = StringReplace($string, "@datadir", $data_dir)
	$string = StringReplace($string, "@outdir", GetParent($outputfile))
	$string = StringReplace($string, "@parent", GetParent($inputfile))
	$string = StringReplace($string, "@appdir", @ScriptDir)

	$string = StringReplace($string, "@homedir", @HomeDrive & @HomePath)
	$string = StringReplace($string, "@programfiles", @ProgramFilesDir)
	$string = StringReplace($string, "@outputfile", $outputfile)

	$string = StringReplace($string, "@arguments", $extra_args)
	$string = StringReplace($string, "@params", $x_param)


	return $string
endfunc



func ffeTokenizeString($string)
	if not $string then return $string
	$string = FixPathSlashes($string)
	$string = StringReplace($string, @DesktopDir, "@desktop")
	$string = StringReplace($string, @MyDocumentsDir, "@mydocuments")
	$string = StringReplace($string, @TempDir, "@tempdir")
	if $data_dir <> "" then $string = StringReplace($string, $data_dir, "@datadir")
	if GetParent($outputfile) <> "" then $string = StringReplace($string, GetParent($outputfile), "@outdir")
	if GetParent($inputfile) <> "" then $string = StringReplace($string, GetParent($inputfile), "@parent")
	$string = StringReplace($string, @HomeDrive & @HomePath, "@homedir")
	$string = StringReplace($string, @ProgramFilesDir, "@programfiles")
	$string = StringReplace($string, @ScriptDir, "@appdir")
	return $string
endfunc




func CtrlASelectAllText()
	GUICtrlSelectAllText($current_control_focus)
endfunc


; Select all the text in a control, usually edit or input controls..
; Pass the ID of the control..
func GUICtrlSelectAllText($control)
	DllCall('user32.dll', 'long', 'SendMessage',	'hwnd', GUICtrlGetHandle($control), _
													'uint', $EM_SETSEL, _
													'int', 0, _
													'int', -1)
endfunc




func ResetTitle()
	SetWinTitleText()
	AdLibUnRegister("ResetTitle")
endfunc


func SetWinTitleText($extra="")
	WinSetTitle($ffeGUI, "", $my_title & $extra)
endfunc






func ___________FILES_AND_PATHS()
endfunc






; Update the user's existing ini with any new prefs..
;
func UpdateffeIniFile()

	debug("UpdateIniFile()..", @ScriptLineNumber, 7);debug

	if FileGetSize($ini_path) < 1 then
		FileInstall(".\Resources\ffe.ini", $ini_path, 1)
		return
	endif

	local $old_version = IniRead($ini_path, $my_name, "version", 0)

	debug("Checking versions: old version: " & $old_version & " my version: " & $VERSION, @ScriptLineNumber, 7);debug
	local $vcomp = _VersionCompare($VERSION, $old_version)

	switch $vcomp
		case 0, -1	; both equal
			return false
	endswitch

	debug("Updating INI FILE: " & $ini_path & "from: v" & $old_version & " to: v" & $VERSION, @ScriptLineNumber, 7);debug

	local $sample_custom_butts, $sample_vmappings, $sample_amappings

	; Drop a temporary ini file somewhere..
	local $tmp_ini = @TempDir & "\ffe.ini.new"
	FileInstall(".\Resources\ffe.ini", $tmp_ini, 1)

	; Delete all non-application prefs from the new (temp) ini
	local $existing_sections = IniReadSectionNames($tmp_ini)

	for $a = 1 to $existing_sections[0]
		if $existing_sections[$a] = $NAME_BUTTONS then
			$sample_custom_butts = IniReadSection($tmp_ini, $existing_sections[$a])
		endif

		if $existing_sections[$a] = $NAME_VIDEO_MAPPINGS then
			$sample_vmappings = IniReadSection($tmp_ini, $existing_sections[$a])
		endif
		if $existing_sections[$a] = $NAME_AUDIO_MAPPINGS then
			$sample_amappings = IniReadSection($tmp_ini, $existing_sections[$a])
		endif

		if $existing_sections[$a] <> $my_name then IniDelete($tmp_ini, $existing_sections[$a])
	next

	; Grab settings from user's old ini file..
	$existing_sections = IniReadSectionNames($ini_path)
	for $a = 1 to $existing_sections[0]
		local $section = IniReadSection($ini_path, $existing_sections[$a])
		if IsArray($section) then
			for $b = 1 to $section[0][0]
				; We manually check for # comments, as AutoIt does not..
				if StringLeft($section[$b][0], 1) <> "#" then
					IniWrite($tmp_ini, $existing_sections[$a], $section[$b][0], $section[$b][1])
				endif
			next
		endif
	next

	; New section added - ensure old users get this..
	if not InArray($existing_sections, $NAME_BUTTONS) then
		IniWriteSection($tmp_ini, $NAME_BUTTONS, $sample_custom_butts)
	endif

	if not InArray($existing_sections, $NAME_VIDEO_MAPPINGS) then
		IniWriteSection($tmp_ini, $NAME_VIDEO_MAPPINGS, $sample_vmappings)
	endif
	if not InArray($existing_sections, $NAME_AUDIO_MAPPINGS) then
		IniWriteSection($tmp_ini, $NAME_AUDIO_MAPPINGS, $sample_amappings)
	endif

	local $backup_dir = GetParent($ini_path) & "\Backup"
	if not FileExists($backup_dir) then DirCreate($backup_dir)

	; Rename their existing ffe.ini to "[@date] ffe.ini"
	FileMove($ini_path, $backup_dir & "\[" & FileDateStamp() & "][v " & $old_version & "] ffe.ini")
	; Move the newly created ini into place, and delete temp file..
	FileMove($tmp_ini, $ini_path, 1)
	; Finally, update the version info in the ini file..
	IniWrite($ini_path, $my_name, "version", $VERSION)

endfunc





; Remove all comments from the user's ini file. This will take the standard ffe
; ini from around 41KB to around 7KB. If your ini file grows to more than 60KB
; in size, this happens automatically, to prevent losing actual data.
;
; "The maximum supported size of an INI file is 64KB.
;  The maximum size of an individual INI section is 32KB"
;
; If this becomes an issue for anyone; let me know.
; I'll write my own ini functions.
;
func CleanIniComments()
	if $clean_comments = $ON then
		debug("Removing comments from: " & $ini_path, @ScriptLineNumber, 7);debug
		local $file_array
		if FileReadIntoArray($ini_path, $file_array) then
			local $new_array[1] = [0]
			for $i = 1 to $file_array[0]
				local $line = StringStripWS($file_array[$i], 3)
				if StringLeft($line, 1) <> ";" then
					if $line then ArrayAdd($new_array, $line)
				endif
			next
			local $file_handle = Fileopen($ini_path, $FO_UTF8_NOBOM+$FO_OVERWRITE)
			if $file_handle <> -1 then
				_FileWriteFromArray($file_handle, $new_array, 1)
				FileClose($file_handle)
			endif
		endif
	endif
endfunc





; ffprobe/MediaInfo media reporting..

func GenerateReport()

	debug("GenerateReport()", @ScriptLineNumber, 5);debug

	; SHIFT+Click to open in viewer/editor (grab this modifier NOW)..
	local $shift_open = false
	if _IsPressed(10) then $shift_open = true

	if IsWild($inputfile) then
		ConsoleAdd("Cannot report on directories or multiple files!", @ScriptLineNumber)
		return false
	endif

	if not GetReportingValues() then return false

	if $save_reports = $ON then
		if not FileExists($report_directory) then $report_directory = GetParent($inputfile)
		local $report_loc = $report_directory & "\" & Basename(RemoveExtension($inputfile)) & "." & $report_extension
		debug("$report_loc: " & $report_loc, @ScriptLineNumber, 5);debug
	endif

	local $report_str, $err, $probe_file, $sw = ""

	if $use_mediainfo = $ON and FileExists($mediainfo_location) then
		ConsoleAdd("Running MediaInfo Command-Line: " & $mediainfo_location & $sw & ' "' & $inputfile & '".', @ScriptLineNumber)
		if $mediainfo_switches then $sw = ' ' & $mediainfo_switches & " "
		$probe_file = Run('"' & $mediainfo_location & '"' & $sw & ' "' & $inputfile & '"', "", @SW_HIDE, $STDERR_MERGED)
	else
		; Run ffprobe (capturing stdout)..
		ConsoleAdd("Running ffprobe Command-Line: " & $ffprobe_loc & _
			" -v error -show_format -show_streams -print_format " & $report_format & $sw & ' "'& $inputfile & '".', @ScriptLineNumber)
		if $report_switches then $sw = " " & $report_switches & " "
		$probe_file = Run($ffprobe_loc & " -v error -show_format -show_streams -print_format " _
						& $report_format & $sw & ' "'& $inputfile & '"', "", @SW_HIDE, $STDERR_MERGED)
	endif

	debug("$probe_file: " & $probe_file, @ScriptLineNumber, 5);debug
	$err = false
	while true
		local $console_out = StdOutRead($probe_file)
		$err = @error
		if $console_out then $report_str &= $console_out
		if $err then exitloop
		Sleep(25)
	wend
	ProcessClose($probe_file)
	StdioClose($probe_file)

	if $un_escape_output = $ON then
		$report_str = StringReplace($report_str, "\\", "\")
		$report_str = StringReplace($report_str, "\:", ":")
	endif

	if $save_reports = $ON then
		if FileExists($report_loc) then FileDelete($report_loc)
		debug("Media Report Location: " & $report_loc, @ScriptLineNumber, 5);debug
		local $report_file_open = FileOpen($report_loc, $FO_OVERWRITE+ $FO_CREATEPATH+$FO_UTF8_NOBOM)
		FileWrite($report_file_open, $report_str)
		FileClose($report_file_open)
	endif

	debug($LOG_LF & "Report String: " & $LOG_LF & $report_str, @ScriptLineNumber, 9);debug

	local $report_to_console = true

	; Shift key held down - open in viewer..
	if $shift_open then
		if $save_reports = $ON then
			debug("ShellExecute(" & $report_loc & ")...", @ScriptLineNumber, 5);debug
			ShellExecute($report_loc)
			$report_to_console = false
		else
			$report_str = "No report saved (disabled). Switching to console output.." & $LOG_LF & $LOG_LF & $report_str
		endif
	endif

	if $report_to_console = true then
		SetConsoleOutput($report_str, true)
	endif

endfunc


; Grab this fresh for every report..

func GetReportingValues()

	debug("GetReportingValues()...", @ScriptLineNumber, 5);debug

	$save_reports = IniReadCheckBoxValue($ini_path, $my_name, "save_reports", $ON)
	$report_format = IniRead($ini_path, $my_name, "report_format", "ini")
	$report_directory = ffeDeTokenizeString(IniRead($ini_path, $my_name, "report_directory", "@parent"))
	$report_extension = IniRead($ini_path, $my_name, "report_extension", "ini")
	$report_switches = IniRead($ini_path, $my_name, "report_switches", "")
	$un_escape_output = IniReadCheckBoxValue($ini_path, $my_name, "un_escape_output", $ON)

	debug("$save_reports: " & Human($save_reports), @ScriptLineNumber, 8);debug
	debug("$report_format: " & $report_format, @ScriptLineNumber, 8);debug
	debug("$report_directory: " & $report_directory, @ScriptLineNumber, 8);debug
	debug("$report_extension: " & $report_extension, @ScriptLineNumber, 8);debug
	debug("$report_switches: " & $report_switches, @ScriptLineNumber, 8);debug
	debug("$un_escape_output: " & Human($un_escape_output), @ScriptLineNumber, 8);debug

	$use_mediainfo = IniReadCheckBoxValue($ini_path, $my_name, "use_mediainfo", $OFF)
	$mediainfo_location = IniRead($ini_path, $my_name, "mediainfo_location", "")
	$mediainfo_switches = IniRead($ini_path, $my_name, "mediainfo_switches", "")
	local $mediainfo_extension = IniRead($ini_path, $my_name, "mediainfo_extension", "nfo")

	debug("$use_mediainfo: " & Human($use_mediainfo), @ScriptLineNumber, 8);debug
	debug("$mediainfo_location: " & $mediainfo_location, @ScriptLineNumber, 8);debug
	debug("$mediainfo_switches: " & $mediainfo_switches, @ScriptLineNumber, 8);debug
	debug("$mediainfo_extension: " & $mediainfo_extension, @ScriptLineNumber, 8);debug

	if $use_mediainfo = $ON then
		$report_extension = $mediainfo_extension
		if not FileExists($mediainfo_location) then
			ConsoleAdd("MediaInfo.exe not found.", @ScriptLineNumber)
			return false
		endif
	else
		if $report_extension = "auto" then
			switch $report_format
				case "compact"
					$report_extension = "txt"
				case else
					$report_extension = "nfo"
			endswitch
		endif
		GetFFprobeLocation()
	endif
	return true
endfunc



; Right-Click on input file label..
;
func PlayInputFile()
	select
		case StringLeft($play_command, 5) = "shell"
			ShellExecute($inputfile)
		case else
			if not FileExists($play_command) then
				ConsoleAdd($play_command & " does not exist. Check the play_command setting inside ffe.ini.")
			else
				Run($play_command & " " & $inputfile)
			endif
	endselect
endfunc


; Right-click on output file label..
;
func DeleteOutputFile()

	local $outfile = GUICtrlRead($inp_outputfile)

	if not FileExists($outfile) then
		ConsoleAdd("Can't delete " & $outfile & ". File does not exist.")
		return
	endif

	local $seen_delete_warning
	local $msg = "Are you sure you wish to delete the output file?"
	local $do_warning = false
	local $response

	if $delete_to_recycle_bin = $ON then
		; It's still there. No biggie..
		$response = $IDOK
		; No reason to post a warning, then..
		$do_warning = false
	else
		; File will be GONE! If user has not been warned, warn them now, one time..
		$seen_delete_warning = IniReadCheckBoxValue($ini_path, $my_name, "warning_seen_output_delete", $OFF)

		if $seen_delete_warning = $ON then
			$response = $IDOK
			$do_warning = false
		else
			$msg = "In future, when you right-click on the label for the output file," & $MSG_LF & _
					"it DELETES the output file. Gone. Vanished. No backup." & $MSG_LF & _
					"(you can also delete to the recycle bin - see your prefs)" & $MSG_LF & $MSG_LF & _
					"It's about to happen now. You will not see this warning again."
				IniWriteCheckBoxValue($ini_path, $my_name, "warning_seen_output_delete", $ON)
				ConsoleAdd("User warned about permanent button deletion: Check!", @ScriptLineNumber)
			$do_warning = true
		endif
	endif

	; Everything can change, if the user has set this..
	if $always_warn_on_delete = $ON then $do_warning = true

	if $do_warning then
		DialogOpen()
		$response = MsgBox($MB_OKCANCEL, "Delete Output File?", $msg, 60, $ffeGUI)
		DialogClose()
	endif

	if $response = $IDOK then
		if $delete_to_recycle_bin = $ON then
			if FileRecycle($outfile) then
				ConsoleAdd("Recycled: " & $outfile)
			endif
		else
			if FileDelete($outfile) then
				ConsoleAdd("Deleted: " & $outfile)
			endif
		endif
	endif

endfunc



func OpenImagesFolder()
	OpenSomething(GetParent($drop_win_image))
endfunc


func OpenFolderInFileSelected()
	OpenFolderFileSelected($inputfile, $inp_inputfile)
endfunc

func OpenFolderOutFileSelected()
	OpenFolderFileSelected($outputfile, $inp_outputfile)
endfunc



; Send a file path to open the parent folder in explorer, with the file selected.
; The $control will flash $warn_colour momentarily if the file does not exist.
;
func OpenFolderFileSelected($file, $control=$inp_inputfile)
	debug("OpenFolderFileSelected " & $file, @ScriptLineNumber, 8);debug
	select
		case FileExists($file)
			; This neat function removes the need to check window already exists..
			_WinAPI_ShellOpenFolderAndSelectItems($file)

		case FileExists(GetParent($file))
			OpenSomething(GetParent($file), true)

		case else
			$warn_control = $control
			SetWarning(true)
	endselect

endfunc




; All this so we can have smaller menu items!
;
; We create a 2D array to store the control IDs.
; Then we can get back the full path to check; basenames may be the same.

; If the user has no "Open" key (highly unlikely) in this filetype, this will fail..
;
func OpenRecentFile()
	debug("OpenRecentFile() ID: " & @tray_id, @ScriptLineNumber, 6);debug
	local $tray_item_full_path
	for $id = 1 to $recent_files[0][0]
		if @tray_id = $recent_files[$id][1] then
			$tray_item_full_path = $recent_files[$id][0]
			exitloop
		endif
	next
	debug("$tray_item_full_path: " & $tray_item_full_path, @ScriptLineNumber, 6);debug
	if FileExists($tray_item_full_path) then
		ShellExecute($tray_item_full_path, "", "", $SHEX_OPEN)
	else
		MakeTray()
	endif
endfunc


func ClearRecentFiles()
	redim $recent_files[1][2]
	$recent_files[0][0] = ""
	ConsoleAdd("Recent Files list was emptied.", @ScriptLineNumber)
	IniDelete($ini_path, $my_name, "recent_files")
	MakeTray()
endfunc





; Browse for an input file..
; When Ctrl key is down, open the current inputfile directory with inputfile selected.

func BrowseForInputFile()
	; Ctrl Key down..
	if _IsPressed(11) then
		OpenFolderInFileSelected()
		return
	endif
	local $input_dir = IniRead($ini_path, $my_name, "input_dir", @MyDocumentsDir)
	DialogOpen()
	local $tmp_ipf = FileOpenDialog("locate the input file..", $input_dir, $file_types, $FD_PATHMUSTEXIST, "", $ffeGUI)
	DialogClose()
	if not $tmp_ipf then return false
	IniWrite($ini_path, $my_name, "input_dir", GetParent($tmp_ipf))
	$inputfile = $tmp_ipf
	GUICtrlSetData($inp_inputfile, $inputfile)
	DoArgsCreate()
	return true
endfunc



; Browse for an output file..
; When Ctrl key is down, open the current outputfile directory with outputfile selected.
;
func BrowseForOutputFile()
	if _IsPressed(11) then
		OpenFolderOutFileSelected()
		return
	endif
	local $save_output_dir = IniRead($ini_path, $my_name, "save_output_dir", @MyDocumentsDir)
	DialogOpen()
	local $tmp_output = FileSaveDialog("specify the output file..", $save_output_dir, $file_types, 0, "", $ffeGUI)
	DialogClose()
	if not $tmp_output then return 0
	if not StringInStr($tmp_output, ".") then $tmp_output &= "." & $default_extension
	local $mum = GetParent($tmp_output)
	IniWrite($ini_path, $my_name, "save_output_dir", $mum)
	ConsoleAdd("Output dir set to: " & $mum, @ScriptLineNumber)
	$outputfile = $tmp_output
	SetOutputTemplate($tmp_output)
	DoArgsCreate()
	return true
endfunc






; Where oh where is ffmpeg.exe..

func TraySetFFmpegBinLocation()
	SetFFmpegBinLocation()
endfunc

func SetFFmpegBinLocation($binary_location=false)

	debug("SetFFmpegBinLocation(" & $binary_location & ")...", @ScriptLineNumber, 5);debug

	; Binary location not supplied in arguments, locate..

	if not $binary_location then
		local $ffmpeg_bin_dir = IniRead($ini_path, $my_name, "ffmpeg_bin_dir", @ProgramFilesDir)
		if FileExists(Getparent($ffmpeg_binary)) then $ffmpeg_bin_dir = Getparent($ffmpeg_binary)
		DialogOpen()
		local $tmp_ffmpeg_binary = FileOpenDialog("Please locate the FFmpeg binary..", _
								$ffmpeg_bin_dir, "FFmpeg binary (ffmpeg.exe)", $ffeGUI)
		local $error = @error
		DialogClose()

		if not $tmp_ffmpeg_binary or $error then
			ConsoleAdd("FFmpeg binary location setting unchanged: User aborted.", @ScriptLineNumber)
			return false
		endif
		$tmp_ffmpeg_binary = ffeDeTokenizeString($tmp_ffmpeg_binary)
		$binary_location = ffeDeTokenizeString($tmp_ffmpeg_binary)
	endif

	debug("$binary_location: " & $binary_location, @ScriptLineNumber, 7);debug


	if $binary_location = $ffmpeg_binary then
		ConsoleAdd("FFmpeg binary location setting unchanged.", @ScriptLineNumber)
		return false
	endif

	if StringMid($binary_location, 1, 2) = "\\" then
		ConsoleAdd("Cannot set network location for FFmpeg binary. Please try again.", @ScriptLineNumber)
		return false
	endif

	IniWrite($ini_path, $my_name, "ffmpeg_bin_dir", GetParent($binary_location))

	if FileExists($binary_location) then
		$ffmpeg_binary = $binary_location
		local $user_ffmpeg_binary = ffeTokenizeString($ffmpeg_binary)
		IniWrite($ini_path, $my_name, "ffmpeg_binary", $user_ffmpeg_binary)
		ConsoleAdd("FFmpeg binary location set to: """ & $user_ffmpeg_binary & """", @ScriptLineNumber)
		EnableRunningControls()
		$got_helps = ""
		UpdateCodecCombos()
	endif

endfunc




func GetFFprobeLocation()
	$ffprobe_loc = GetParent($ffmpeg_binary) & "\ffprobe.exe"
	if not FileExists($ffprobe_loc) then
		ConsoleAdd("ffprobe.exe not found next to FFmpeg" & $LOG_LF & "please place ffprobe.exe next to ffmpeg.exe.", @ScriptLineNumber)
		return false
	endif
endfunc



func LocateMediaInfo()
	local $mi_lookin = GetParent($mediainfo_location)
	if not $mi_lookin then $mi_lookin = @ProgramFilesDir
	DialogOpen()
	local $tmp_mediainfo_location = FileOpenDialog("Please locate MediaInfo.exe..", _
				$mediainfo_location, "MediaInfo executable (MediaInfo.exe)", $ffeGUI)
	local $error = @error
	DialogClose()
	if not $tmp_mediainfo_location or $error then
		ConsoleAdd("Still not got a valid path for MediaInfo. Disabling..", @ScriptLineNumber)
		return false
	endif
	if FileExists($tmp_mediainfo_location) then
		$mediainfo_location = $tmp_mediainfo_location
		IniWrite($ini_path, $my_name, "mediainfo_location", $mediainfo_location)
		ConsoleAdd("MediaInfo location set to: " & $mediainfo_location, @ScriptLineNumber)
	endif
endfunc



;2do - Logging for non-output files (i.e. image sequences)

func SaveOutput($output_data)

	if not $output_data then return false
	local $log_outputfile

	$job_log_location = ffeDeTokenizeString(IniRead($ini_path, $current_preset, "job_log_location", $job_log_location))
	if not $job_log_location then $job_log_location = "@datadir\logs"
	CRT($job_log_location)

	local $use_job_log_location = $job_log_location & "\"
	if IsWild($user_inputfile) then $use_job_log_location &= "[BATCH]_"

	if IsWild($user_outputfile) then
		$log_outputfile = $use_job_log_location & CleanPath(RemoveExtension($outputfile), ".") & _
															$matof_separator & $matof_string & ".log"
	else
		$log_outputfile = $use_job_log_location & RemoveExtension(BaseName($outputfile)) & ".log"
	endif

	local $dl_append = 10
	if $job_log_append = $ON then $dl_append = 9
	local $my_log_file = FileOpen($log_outputfile, $dl_append)
	FileWriteLine($my_log_file, $output_data)
	FileClose($my_log_file)
endfunc











func _____________IMPORT_EXPORT()
endfunc





; Import / Export..


func ComboImportData()
	MenuImportData()
endfunc
func TrayMenuImportData()
	MenuImportData()
endfunc
func ImportButtons()
	MenuImportData($NAME_BUTTONS)
endfunc

func MenuImportData($dtype="")
	local $import_dir = IniRead($ini_path, $my_name, "import_dir", @MyDocumentsDir)
	local $i_type = "data"
	if $dtype then $i_type = $dtype
	local $data_inifile = FileOpenDialog("locate the " & $i_type & " file..", _
		$import_dir, "Ini files (*.ini)|All files (*.*)", $FD_PATHMUSTEXIST, "", $ffeGUI)
	if not $data_inifile then return
	if not FileExists($data_inifile) then
		ConsoleAdd("Import aborted.", @ScriptLineNumber)
		return false
	endif
	IniWrite($ini_path, $my_name, "import_dir", GetParent($data_inifile))
	ImportData($data_inifile, $dtype)
endfunc




func ImportData($import_file, $dtype="")

	if not FileExists($import_file) then return false

	ConsoleAdd("Beginning data import..", @ScriptLineNumber)
	local $import_ini_sections = IniReadSectionNames($import_file)

	; Present dialog for importing:	main settings, presets, custom buttons..
	DialogOpen()
	local $user_choice = CorzImportExportChooser($import_ini_sections, "import", 0, $dtype)
	local $err = @error
	DialogClose()
	if not $user_choice then
		local $msg = "Import aborted."
		if not $dtype then $dtype = "usable data"
		if $err then $msg &= ": no " & $dtype & " found in file."
		ConsoleAdd($msg, @ScriptLineNumber)
		return false
	endif

	local $do_add = false, $r_type, $do_added = false
	local $tmp_ini = @TempDir & "\ffe-import-temp.ini"

	local $restart_required = false
	local $restart_settings = StringSplit("image_buttons,sort_presets_list,do_tooltips,console_wordwrap", ",")

	FileCopy($ini_path, $tmp_ini)

	for $i = 1 to $import_ini_sections[0]

		$do_add = false

		switch $import_ini_sections[$i]
			case $my_name
				if StringInStr($user_choice, $NAME_SETTINGS) then
					$do_add = true
					$r_type = $NAME_SETTINGS
				endif
			case $NAME_VIDEO_MAPPINGS
				if StringInStr($user_choice, $NAME_SETTINGS) then
					$do_add = true
					$r_type = $NAME_VIDEO_MAPPINGS
				endif
			case $NAME_AUDIO_MAPPINGS
				if StringInStr($user_choice, $NAME_SETTINGS) then
					$do_add = true
					$r_type = $NAME_AUDIO_MAPPINGS
				endif
			case $NAME_BUTTONS
				if StringInStr($user_choice, $NAME_BUTTONS) then
					$do_add = true
					$r_type = $NAME_BUTTONS
				endif
			case else
				if StringInStr($user_choice, $NAME_PRESETS) and not StringInStr($import_ini_sections[$i], $PRESET_BACKUP_STRING) then
					$do_add = true
					$r_type = "preset" & ": " & $import_ini_sections[$i]
				endif
		endswitch

		; We have something to add from this section..

		if $do_add then

			local $this_section = IniReadSection($import_file, $import_ini_sections[$i])
			if not @error then

				switch $import_ini_sections[$i]

					; main settings..
					case $my_name
						DialogOpen()
						local $warn_main_settings = MsgBox($MB_OKCANCEL+$MB_ICONWARNING, "Overwrite MAIN Settings?!?", _
							"This will COMPLETELY OVERWRITE MAIN FFE SETTINGS!!!" & $MSG_LF & _
							"(but only those settings present in the imported ini file)" & $MSG_LF & $MSG_LF & _
							"Are you ABSOLUTELY sure you wish to do this? ", 30, $ffeGUI)
						DialogClose()
						if $warn_main_settings = 1 then
							for $st = 1 to $this_section[0][0]
								if IniWrite($ini_path, $my_name, $this_section[$st][0], $this_section[$st][1]) then
									ConsoleAdd("Wrote setting: "&$this_section[$st][0] & "=" & $this_section[$st][1], @ScriptLineNumber)
									; Ahhhh.. NOW we see the beauty of matching ini pref and var names...
									Assign($this_section[$st][0], $this_section[$st][1], $ASSIGN_EXISTFAIL)
									if InArray($restart_settings, $this_section[$st][0]) then $restart_required = true
									$do_added = true
								endif
							next
						endif

					case $NAME_VIDEO_MAPPINGS, $NAME_AUDIO_MAPPINGS
						for $st = 1 to $this_section[0][0]
							if IniWrite($ini_path, $import_ini_sections[$i], $this_section[$st][0], $this_section[$st][1]) then
								ConsoleAdd("Wrote mapping: " & $this_section[$st][0] & "=>" & $this_section[$st][1], @ScriptLineNumber)
								$do_added = true
							endif
						next


					case $NAME_BUTTONS
						; We add/overwrite individual buttons, not simply replace the section..
						for $st = 1 to $this_section[0][0]
							if IniWrite($ini_path, $NAME_BUTTONS, $this_section[$st][0], $this_section[$st][1]) then
								ConsoleAdd("Wrote button: " & $this_section[$st][0] & "=" & $this_section[$st][1], @ScriptLineNumber)
								$do_added = true
							endif
						next

					; preset..
					case else
						if IniWriteSection($ini_path, $import_ini_sections[$i], $this_section) then
							ConsoleAdd("Imported " & $r_type & ".", @ScriptLineNumber)
							$do_added = true
						endif
				endswitch
			endif
		endif
	next

	if StringInStr($user_choice, $NAME_PRESETS) then UpdatePresetsCombo()
	if StringInStr($user_choice, $NAME_BUTTONS) and $enable_custom_buttons = $ON then ReCreateButtonGrid()

	if $do_added then
		local $bax_ini = GetParent($ini_path) & "\PRE-IMPORT [" & FileDateStamp() & "] ffe.ini"
		if $restart_required then ConsoleAdd("Init settings detected - restart to see changes.", @ScriptLineNumber)
		if FileMove($tmp_ini, $bax_ini) then
			ConsoleAdd("Old ffe.ini backed up to: " & $bax_ini & ".", @ScriptLineNumber)
		endif
	else
		FileDelete($tmp_ini)
	endif

endfunc



func MenuExportData()
	ExportData()
endfunc

func TrayMenuExportData()
	ExportData()
endfunc

func MenuExportButtons()
	ExportData($NAME_BUTTONS)
endfunc

func ExportData($dtype="")

	local $ini_sections = IniReadSectionNames($ini_path)
	if not IsArray($ini_sections) then return

	ConsoleAdd("Beginning data export..", @ScriptLineNumber)
	local $tmp_ini_path = @TempDir & "\ffe-data-export.ini"
	if FileExists($tmp_ini_path) then FileDelete($tmp_ini_path)

	; Present dialog for exporting:	main settings, presets, custom buttons..
	DialogOpen()
	local $user_choice = CorzImportExportChooser($ini_sections, "export", 0, $dtype)
	DialogClose()

	if not $user_choice then
		ConsoleAdd("Export aborted.", @ScriptLineNumber)
		return false
	endif
	local $do_add = false, $r_type, $do_added = false

	; Run through section-by-section..
	for $i = 1 to $ini_sections[0]

		$do_add = false

		switch $ini_sections[$i]
			case $my_name, $NAME_VIDEO_MAPPINGS, $NAME_AUDIO_MAPPINGS
				if StringInStr($user_choice, $NAME_SETTINGS) then
					$do_add = true
					$r_type = $ini_sections[$i]
				endif
			case $NAME_BUTTONS
				if StringInStr($user_choice, $NAME_BUTTONS) then
					$do_add = true
					$r_type = $NAME_BUTTONS
				endif
			case else
				if StringInStr($user_choice, $NAME_PRESETS) and not StringInStr($ini_sections[$i], $PRESET_BACKUP_STRING) then
					$do_add = true
					$r_type = "preset" & ": " & $ini_sections[$i]
				endif
		endswitch

		if $do_add then

			; ANY additions will set this flag.
			$do_added = true

			local $this_section = IniReadSection($ini_path, $ini_sections[$i])
			if not @error then
				switch $ini_sections[$i]
					; Main settings..
					case $my_name, $NAME_VIDEO_MAPPINGS, $NAME_AUDIO_MAPPINGS
						if IniWriteSection($tmp_ini_path, $ini_sections[$i], $this_section) then
						if $r_type = $my_name then $r_type = $NAME_SETTINGS
							ConsoleAdd("Exported '" & $r_type & "'.", @ScriptLineNumber)
						endif
					; Custom buttons..
					case $NAME_BUTTONS
						if IniWriteSection($tmp_ini_path, $NAME_BUTTONS, $this_section) then
							ConsoleAdd("Exported '" & $r_type & "'.", @ScriptLineNumber)
						endif
					; Preset..
					case else
						if not InArray($not_presets, $ini_sections[$i]) and _
							StringLeft($ini_sections[$i], StringLen($PRESET_BACKUP_STRING)) <> $PRESET_BACKUP_STRING then
							if IniWriteSection($tmp_ini_path, $ini_sections[$i], $this_section) then
								ConsoleAdd("Exporting preset '" & $r_type & "'.", @ScriptLineNumber)
							endif
						endif
				endswitch
			endif
		endif
	next

	if $do_added then
		local $export_name = "ffe-export-"
		if StringInStr($user_choice, $NAME_SETTINGS) then
			$export_name &= StringLower(StringReplace($NAME_SETTINGS, " ", "-")) & "-"
		endif
		if StringInStr($user_choice, $NAME_BUTTONS) then
			$export_name &= StringLower(StringReplace($NAME_BUTTONS, " ", "-")) & "-"
		endif
		if StringInStr($user_choice, $NAME_PRESETS) then
			$export_name &= StringLower(StringReplace($NAME_PRESETS, " ", "-")) & "-"
		endif
		CRT($export_name, "-")
		local $export_dir = IniRead($ini_path, $my_name, "export_dir", @MyDocumentsDir)
		DialogOpen()
		local $saved_file = FileSaveDialog("specify a location to save the file..", _
			$export_dir, "Ini files (*.ini)|All files (*.*)", $FD_PROMPTOVERWRITE , $export_name & ".ini", $ffeGUI)
		DialogClose()
		if $saved_file then
			IniWrite($ini_path, $my_name, "export_dir", GetParent($saved_file))
			local $i_type = "data"
			if $dtype then $i_type = $dtype
			if FileMove($tmp_ini_path, $saved_file, 9) then
				ConsoleAdd("Finished exporting " & $i_type & " to: " & $saved_file & ".", @ScriptLineNumber)
			endif
		else
			ConsoleAdd("Well, that was fun.", @ScriptLineNumber)
		endif
	endif

endfunc






; Custom inport/export user chooser..

; Returns a string containing relevant substrings, "main settings", "presets" and "custom buttons".
; e.g., if everything is selected the string is, "main settingspresetscustom buttons".

func CorzImportExportChooser(ByRef $ini_sections_array, $mode="import", $timeout=0, $dtype="")

	if not IsArray($ini_sections_array) then
		if $mode = "import" then
			ConsoleAdd("No ini [sections] found to import!", @ScriptLineNumber)
		else
			ConsoleAdd("A serious ini-based error of some unknown description occured.", @ScriptLineNumber)
		endif
		return false
	endif

	local $ie_title = "ffe " & $mode & " choices.."
	local $prompt = "Which data do you wish to " & $mode & "?"
	local $err = 0, $i_type, $no_match = false

	local $ie_x = IniRead($ini_path, $my_name, "import_export_chooser_x", $x + 6)
	local $ie_y = IniRead($ini_path, $my_name, "import_export_chooser_y", $y + 26)
	local $ie_w = IniRead($ini_path, $my_name, "import_export_chooser_width", 300)

	local $ie_h = 170
	local $min_w = 300
	if $ie_w < $min_w then $ie_w = $min_w


	local $return = false
	local $previous_event_mode = AutoItSetOption("GUIOnEventMode", 0)
	local $previous_coord_mode = AutoItSetOption("GUICoordMode", 0)

	local $style = BitOr($WS_CAPTION, $WS_SYSMENU, $WS_POPUP, $WS_SIZEBOX)
	local $styleX = BitOr($WS_EX_CONTEXTHELP, $WS_EX_TOPMOST, $WS_EX_TOOLWINDOW)

	local $ie_GUI = GUICreate($ie_title, $ie_w, $ie_h, $ie_x, $ie_y, $style, $styleX, $ffeGUI)
	GUIsetFont(9)

	local $but_Cancel = GUICtrlCreateButton("Cancel", 6, $ie_h-26, 60, 22)
	GUICtrlSetState(-1, $GUI_ONTOP)
	GUICtrlSetResizing(-1, $GUI_DOCKSTATEBAR+$GUI_DOCKLEFT+$GUI_DOCKWIDTH)

	local $but_OK = GUICtrlCreateButton("OK", $ie_w-60, 0, 50, 22, $BS_DEFPUSHBUTTON)
	GUICtrlSetState(-1, $GUI_ONTOP)
	GUICtrlSetResizing(-1, $GUI_DOCKSTATEBAR+$GUI_DOCKWIDTH+$GUI_DOCKRIGHT)

	GUISetCoord(10, 7)

	GUICtrlCreateLabel($prompt, 0, 0, $ie_w-30)
	GUICtrlSetFont(-1, default, 800)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)

	GUISetCoord(20, 27)

	local $chk_everything, $chk_main_settings, $chk_presets, $chk_custom_buttons
	local $got_main = false, $got_presets = false, $got_buttons = false, $t_count=0

	$i_type = $NAME_SETTINGS
	$chk_main_settings = GUICtrlCreateCheckbox(_StringProper($i_type), 0, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	if InArray($ini_sections_array, $my_name) _
		or InArray($ini_sections_array, $NAME_VIDEO_MAPPINGS) _
		or InArray($ini_sections_array, $NAME_AUDIO_MAPPINGS) then
		$got_main = true
		$t_count += 1
		if $dtype = $i_type then GUICtrlSetState(-1, $ON)
	else
		if $dtype = $i_type then $no_match = true
		GUICtrlSetState(-1, $GUI_DISABLE)
	endif


	$i_type = $NAME_PRESETS
	$chk_presets = GUICtrlCreateCheckbox(_StringProper($i_type), 0, 22)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)

	if HasPresets($ini_sections_array) then
		$got_presets = true
		$t_count += 1
		if $dtype = $i_type then GUICtrlSetState(-1, $ON)
	else
		if $dtype = $i_type then $no_match = true
		GUICtrlSetState(-1, $GUI_DISABLE)
	endif


	$i_type = $NAME_BUTTONS
	$chk_custom_buttons = GUICtrlCreateCheckbox(_StringProper($i_type), 0, 22)
	GUICtrlSetResizing(-1, $GUI_DOCKALL)
	if InArray($ini_sections_array, $i_type) then
		$got_buttons = true
		$t_count += 1
		if $dtype = $i_type then GUICtrlSetState(-1, $ON)
	else
		if $dtype = $i_type then $no_match = true
		GUICtrlSetState(-1, $GUI_DISABLE)
	endif


	if $t_count > 1 then
		$chk_everything = GUICtrlCreateCheckbox("All", 120, 0)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
	endif


	if $no_match then

		; No matching (specific) sections in specified import file..
		$err = 1


	; We have a match..
	else

		; Single type specified (from contextual control)
		if $dtype then

			; No choosing required., return type directly.
			$return = $dtype

		else

			; OK, let's CHOOSE...

			GUISetState(@SW_SHOW, $ie_GUI)
			WinMove($ie_title, "", default, default, $ie_w, $ie_h)

			if $timeout <> 0 then local $dialog_begin = TimerInit()
			local $size_array, $got_ok = false
			WinActivate($ie_title)

			while true

				switch GUIGetMsg()

					case $GUI_EVENT_RESIZED
						$size_array = WinGetPos($ie_title)
						if not IsArray($size_array) then continueloop
						if $size_array[2] < $min_w then WinMove($ie_title, "", default, default, $min_w, $ie_h)
						if $size_array[3] <> $ie_h then WinMove($ie_title, "", default, default, $min_w, $ie_h)

					case $GUI_EVENT_CLOSE, $but_Cancel
						$return = ""
						exitloop

					case $but_OK
						if GUICtrlRead($chk_main_settings) = $ON then $return &= $NAME_SETTINGS
						if GUICtrlRead($chk_presets) = $ON then $return &= $NAME_PRESETS
						if GUICtrlRead($chk_custom_buttons) = $ON then $return &= $NAME_BUTTONS
						$got_ok = true
						exitloop


					case $chk_everything
						if GUICtrlRead($chk_everything) = $OFF then
							GUICtrlSetState($chk_main_settings, $OFF)
							GUICtrlSetState($chk_presets, $OFF)
							GUICtrlSetState($chk_custom_buttons, $OFF)
						else
							if $got_main then GUICtrlSetState($chk_main_settings, $ON)
							if $got_presets then GUICtrlSetState($chk_presets, $ON)
							if $got_buttons then GUICtrlSetState($chk_custom_buttons, $ON)
						endif
				endswitch

				if $timeout <> 0 then
					if TimerDiff($dialog_begin)/1000 > $timeout then exitloop
				endif

			wend

			if $return or $got_ok then

				; save position/size for next time..
				$size_array = WinGetPos($ie_title)	; 0-1-2-3:x-y-w-h
				if IsArray($size_array) then
					if $size_array[0] then IniWrite($ini_path, $my_name, "import_export_chooser_x", $size_array[0])
					if $size_array[1] then IniWrite($ini_path, $my_name, "import_export_chooser_y", $size_array[1])
					if $size_array[2] then IniWrite($ini_path, $my_name, "import_export_chooser_width", $size_array[2])
				endif

			endif

		endif

	endif

	AutoItSetOption("GUIOnEventMode", $previous_event_mode)
	AutoItSetOption("GUICoordMode", $previous_coord_mode)
	GUIDelete($ie_GUI)

	return SetError($err, 0, $return)

endfunc









func __________________________INFO()
endfunc





; Add some text onto the end of the console output and scroll to end of the output..
; Returns the original text for logging; reads $output_paused and updates
; $edit_console_output. Existing callers append a message and a line break.
; FFmpeg callers pass true to replace CR-terminated progress, retaining LF
; lines. Static parsing state spans reads; an empty FFmpeg call resets it.
; A blank line separates startup output from overwritten progress.
; Startup output scrolls to the first CR progress report; subsequent
; progress updates preserve the visible line chosen by the user.
; Paused output returns the original text without changing the display.
func ConsoleAdd($out_string, $ln=@ScriptLineNumber, $ffmpeg_output=false)
	static $ffmpeg_start = -1, $ffmpeg_line = "", $ffmpeg_cr = false, $ffmpeg_progress_started = false
	; An empty FFmpeg call resets parsing before a new process starts.
	if $ffmpeg_output and $out_string = "" then
		$ffmpeg_start = -1
		$ffmpeg_line = ""
		$ffmpeg_cr = false
		$ffmpeg_progress_started = false
		return $out_string
	endif
	if $output_paused then return $out_string
	local $dlevl = 3
	; Automatically switch the level of any message containing "error"
	if StringInStr($out_string, "error", $STR_NOCASESENSEBASIC) then
		$dlevl = 1
		SetWinTitleText("                        ERROR!   [see console for details]")
		AdLibRegister("ResetTitle", 3000)
	endif
	debug("Console Add: " & $out_string, $ln, $dlevl);debug
	local $end = StringLen(GUICtrlRead($edit_console_output))
	local $ffmpeg_scroll = not $ffmpeg_progress_started
	local $ffmpeg_first_line = _GUICtrlEdit_GetFirstVisibleLine($edit_console_output)
	if $ffmpeg_output then
		if $ffmpeg_start < 0 then $ffmpeg_start = $end
		local $ffmpeg_parts = StringRegExp($out_string, "[^\r\n]+|\r|\n", $STR_REGEXPARRAYGLOBALMATCH)
		local $ffmpeg_committed = ""
		if IsArray($ffmpeg_parts) then
			for $ffmpeg_part in $ffmpeg_parts
				switch $ffmpeg_part
					case @CR
						$ffmpeg_cr = true
					case @LF
						; The Windows edit control requires CRLF for displayed lines.
						$ffmpeg_committed &= $ffmpeg_line & @CRLF
						$ffmpeg_line = ""
						$ffmpeg_cr = false
					case else
						if $ffmpeg_cr then
							if not $ffmpeg_progress_started then
								$ffmpeg_committed &= @CRLF
								$ffmpeg_progress_started = true
							endif
							$ffmpeg_line = ""
						endif
						$ffmpeg_cr = false
						$ffmpeg_line &= $ffmpeg_part
				endswitch
			next
		endif
		local $ffmpeg_paint_start = $ffmpeg_start
		_GUICtrlEdit_BeginUpdate($edit_console_output)
		_GUICtrlEdit_SetSel($edit_console_output, $ffmpeg_start, $end)
		_GUICtrlEdit_ReplaceSel($edit_console_output, $ffmpeg_committed & $ffmpeg_line)
		$ffmpeg_start += StringLen($ffmpeg_committed)
	else
		$ffmpeg_start = -1
		$ffmpeg_line = ""
		$ffmpeg_cr = false
		_GUICtrlEdit_SetSel($edit_console_output, $end, $end)
		GUICtrlSetData($edit_console_output, UnifyCRLF($out_string, @CRLF) & @CRLF, 1)
	endif
	if $ffmpeg_output then
		_GUICtrlEdit_EndUpdate($edit_console_output)
		if $ffmpeg_scroll then
			_GUICtrlEdit_Scroll($edit_console_output, $__EDITCONSTANT_SB_SCROLLCARET)
		else
			_GUICtrlEdit_LineScroll($edit_console_output, 0, $ffmpeg_first_line - _GUICtrlEdit_GetFirstVisibleLine($edit_console_output))
		endif
		; Discard full-control invalidation and repaint the changed lines only.
		local $ffmpeg_handle = GUICtrlGetHandle($edit_console_output)
		local $ffmpeg_rect = _WinAPI_GetClientRect($ffmpeg_handle)
		local $ffmpeg_position = _GUICtrlEdit_PosFromChar($edit_console_output, $ffmpeg_paint_start)
		$ffmpeg_position[1] = _WinAPI_WordToShort($ffmpeg_position[1])
		if $ffmpeg_position[1] < 0 then $ffmpeg_position[1] = 0
		if not $ffmpeg_scroll then DllStructSetData($ffmpeg_rect, "Top", $ffmpeg_position[1])
		_WinAPI_RedrawWindow($ffmpeg_handle, 0, 0, $RDW_VALIDATE)
		_WinAPI_InvalidateRect($ffmpeg_handle, $ffmpeg_rect, false)
	else
		_GUICtrlEdit_Scroll($edit_console_output, $__EDITCONSTANT_SB_SCROLLCARET)
	endif
	return $out_string
endfunc



; REPLACE the console output with some new output..
; The original text is returned so we can wrap this function, if required..
;
func SetConsoleOutput($out_string, $scroll_top=false)
	GUICtrlSetState($edit_console_output, $GUI_ENABLE)
	GUICtrlSetData($edit_console_output, UnifyCRLF($out_string, @CRLF))
	if $scroll_top then
		_GUICtrlEdit_Scroll($edit_console_output, 0)
	else
		_GUICtrlEdit_Scroll($edit_console_output, $__EDITCONSTANT_SB_SCROLLCARET)
	endif
	return $out_string
endfunc


func CopyConsoleOutput()
	CopyControlToClipBoard($edit_console_output, "console output")
endfunc

func CopyControlToClipBoard($control, $name)
	local $msg
	if GUICtrlRead($control) then
		ClipPut(GUICtrlRead($control))
		$msg = "                *** " & $name & " copied to the clipboard ***"
	else
		$msg = "                *** the " & $name & " is empty! nothing copied to the clipboard! ***"
	endif
	SetWinTitleText($msg)
	AdLibRegister("ResetTitle", 3000)
endfunc


func ClearOutput()
	SetConsoleOutput("")
endfunc




func DoAboutBox()

	DialogOpen()
	AutoItSetOption("GUIOnEventMode", 0)

	local $aw = 330, $ah = 210
	local $GUI_About = GUICreate(" about " & $my_name & ".. ", $aw, $ah, -1, @DesktopHeight/4, $WS_CAPTION, $WS_EX_TOPMOST, $ffeGUI)

	GUICtrlCreateIcon($me_app, 0, 15, 10, 32, 32)

	local $about_version = $my_name & " v" & $VERSION
	if $special_build then $about_version &= "    (" & $special_build & ")"
	GUICtrlCreateLabel($about_version, 55, 10, default, 22)
	GUICtrlCreateLabel(chr(169) & " corz.org 2007-" & @Year & " ;o) ", 55, 28, default, 22)

	GUICtrlCreateLabel($my_name & " is a simple, powerful front-end for FFmpeg, " & _
		"enabling quick alterations to its parameters for rapid testing and production. " & $MSG_LF & $MSG_LF & _
		"ffe uniquely uses MATOF" & chr(153) & " technology to automatically update output filenames to " & _
		"match your encoding parameters, enabling you to save lots of slightly different versions of a file " & _
		"very, very quickly; in other words, 'find the best settings'" & $MSG_LF & $MSG_LF & _
		"Do you want to visit the " & $my_name & " web page at this time? ", 15, 50, $aw-25, $ah-90)

	local $GUI_About_NO = GUICtrlCreateButton("No", $aw-140, $ah-25, 60, 20, BitOr($WS_TABSTOP,$BS_FLAT))
	local $GUI_About_OK = GUICtrlCreateButton("Yes", $aw-72, $ah-25, 60, 20, BitOr($WS_TABSTOP,$BS_FLAT))

	; GUICtrlSetState($GUI_About_OK, $GUI_FOCUS)
	GUISetState(@SW_SHOW, $GUI_About)

	local $msg
	while true
		sleep(10)
		$msg = GUIGetMsg()
		switch $msg
			case $GUI_EVENT_CLOSE, $GUI_About_NO
				exitloop
			case $GUI_About_OK
				VisitURL($my_url)
				exitloop
		endswitch
	wend

	GUIDelete($GUI_About)
	AutoItSetOption("GUIOnEventMode", 1)
	DialogClose()

endfunc




func DoAboutFFmpeg()
	DoFFmpegCommand("-version")
endfunc




func GetLogLocation($this_preset=$my_name)

	local $i = ffeDeTokenizeString(IniRead($ini_path, $this_preset, "log_location", $log_location))

	if $i <> "-" then
		if $portable then
			if $i and TestFileWrite($i) then
				$log_location = $i
			else
				if TestFileWrite(@ScriptDir & "\" & $my_name & ".log") then
					$log_location = @ScriptDir & "\" & $my_name & ".log"
				endif
			endif
		elseif IsDir($i) and TestFileWrite($i & "\" & $my_name & ".log") then
			$log_location = $i & "\" & $my_name & ".log"
		elseif $i and TestFileWrite($i) then
			$log_location = $i
		else
			$log_location = @TempDir & "\" & $my_name & ".log"
		endif
	endif
	debug("$log_location set to: " & $log_location, @ScriptLineNumber, 7);debug

endfunc








func TrayDownloadImagePack()
	DownloadImagePack($x + 15, $y+338, $width-26, 58)
endfunc



; Download a wee selection of sample images to get you started.
; There are more images at the download URL, below..
;
func DownloadImagePack($windoid_x=default, $windoid_y=default, $windoid_w=default, $windoid_h=default)

	if $windoid_x = default then $windoid_x = -1
	if $windoid_y = default then $windoid_y = -1
	if $windoid_w = default then $windoid_w = 400
	if $windoid_h = default then $windoid_h = 46

	DialogOpen()
	ConsoleAdd("Downloading ffe image pack..", @ScriptLineNumber)

	local $image_pack_url, $img_files, $img_url, $local_img_path, $local_img_list
	$image_pack_url = IniRead($ini_path, $my_name, "image_pack_url", "")
	if not $image_pack_url then $image_pack_url = "https://corz.org/windows/software/ffe/files/DropWindowImages/"

	local $list_file = "image_pack_urls.txt"
	$local_img_list = $data_dir & "\" & $list_file
	debug("$local_img_list: =>" & $local_img_list & "<=", @ScriptLineNumber, 6);debug
	FileDelete($local_img_list)

	local $tooltip_windoid = GUICreate("downloading", $windoid_w, $windoid_h, $windoid_x, $windoid_y, _
			BitOr($WS_POPUP,$WS_DLGFRAME,$DS_MODALFRAME), BitOR($WS_EX_TOOLWINDOW,$WS_EX_TOPMOST,$GUI_WS_EX_PARENTDRAG), $ffeGUI)
	GUICtrlCreateLabel("Downloading ffe image pack..", 5, 3, $windoid_w-10, 22, $SS_LEFT, $GUI_WS_EX_PARENTDRAG)
	local $tool_label = GUICtrlCreateLabel("", 5, 25, $windoid_w-10, 24, $SS_LEFT, $GUI_WS_EX_PARENTDRAG)
	GUISetState(@SW_SHOW, $tooltip_windoid)

	ConsoleAdd("Grabbing image list..", @ScriptLineNumber)
	local $dl = BackGroundDownload($image_pack_url & $list_file, default, default, $local_img_list)

	if @error == 0 then

		FileReadIntoArray($local_img_list, $img_files)

		if not IsArray($img_files) then
			ConsoleAdd("Error reading Image List.", @ScriptLineNumber)
			return false
		endif

		debugPrintArray($img_files, "List of $img_files:", @ScriptLineNumber, 7);debug

		local $current_img

		; Run through the list..
		for $this_img = 1 to $img_files[0]


			$current_img = StringStripWS($img_files[$this_img], 3)
			debug("Current image file: =>" & $current_img & "<=", @ScriptLineNumber, 11);debug

			; Ignore comments..
			if $current_img and StringLeft($current_img, 1) <> ";" then

				$img_url = $image_pack_url & $current_img
				$local_img_path = $drop_win_image_folder & "\" & StringReplace($current_img, "/", "\")

				if not FileExists(GetParent($local_img_path)) then DirCreate(GetParent($local_img_path))

				if FileExists($local_img_path) then
					GUICtrlSetData($tool_label, "Skipping: " & $current_img)
					ConsoleAdd("File exists (skipped): " & $current_img, @ScriptLineNumber)
					Sleep(166) ; The "doing something" delay. It's a human thing.
				else
					GUICtrlSetData($tool_label, "Downloading: " & $current_img)
					Sleep(500)
					$dl = BackGroundDownload($img_url, default, default, $local_img_path)
					if @error <> 0 then
						debug("@error: " & @error, @ScriptLineNumber, 1);debug
						debug("@extended: " & @extended, @ScriptLineNumber, 1);debug
						ConsoleAdd($dl, @ScriptLineNumber)
						exitloop
					endif
					ConsoleAdd("Downloaded: " & $current_img, @ScriptLineNumber)
				endif
			endif
			if $this_img = $img_files[0] then
				ConsoleAdd("Downloading complete.", @ScriptLineNumber)
			endif
		next

		; Clean-up..
		FileDelete($local_img_list)
		GUICtrlSetData($tool_label, "Image Pack Downloaded!")

	else
		debug("@error: " & @error, @ScriptLineNumber, 1);debug
		debug("@extended: " & @extended, @ScriptLineNumber, 1);debug
		ConsoleAdd("", @ScriptLineNumber)
		ConsoleAdd("Download ERROR!", @ScriptLineNumber)
		ConsoleAdd("ffe could not retrieve the image list!" & $LOG_LF & _
					"Without the image list, no images can be downloaded.", @ScriptLineNumber)
		GUICtrlSetData($tool_label, $dl)
		ConsoleAdd($dl, @ScriptLineNumber)
	endif

	GUIDelete($tooltip_windoid)
	DialogClose()
	HideDropWindow()

endfunc







func __________ANCILLARY_FUNCS()
endfunc




func DialogOpen()
	GUISetState(@SW_DISABLE, $ffeGUI)
	UnSetHotKeys()
endfunc

func DialogClose()
	GUISetState(@SW_ENABLE, $ffeGUI)
	WinActivate($ffeGUI)
	SetHotKeys()
endfunc



func GetEditStyles()
	if $console_wordwrap = $ON then
		return BitOR($ES_AUTOVSCROLL, $WS_VSCROLL, $ES_WANTRETURN, $ES_MULTILINE, $ES_NOHIDESEL)
	else
		return BitOR($WS_HSCROLL, $ES_AUTOVSCROLL, $WS_VSCROLL, $ES_AUTOHSCROLL, $ES_MULTILINE, $ES_WANTRETURN, $ES_NOHIDESEL)
	endif
endfunc





; Check if mouse is over certain controls and act accordingly..
; Returns the ID the mouse is currently over, if required.
;
func CheckMouse()

	local $mouse_pos = GUIGetCursorInfo($ffeGUI)
	if not IsArray($mouse_pos) then return false

	; So these functions aren't firing a zillion times a second..
	if $previous_pos <> $mouse_pos[4] then

		; Help buttons..
		if IsArray($help_texts) then
			if IsArray($help_butts) then
				local $help_hover = InArray($help_butts, $mouse_pos[4])
				if $help_hover then
					GUICtrlSetData($lab_help_info, _
						StringLeft($help_texts[$help_hover], StringInStr($help_texts[$help_hover], "|") - 1))
				else
					GUICtrlSetData($lab_help_info, "")
				endif
			endif
		endif

		; Highlight active labels.
		; Nice idea, but we should think about some kind of AA instead of many
		; global flags to store on/off states.

		;2do - consider different colours for different actions, e.g. right-now-click button = green on mouseover

		; We don't put them all into a single select, as it would make mouse-overs less responsive.
		;
		select
			; inputfile label..
			case $set_if = false and $mouse_pos[4] = $lab_inputfile
				GUICtrlSetColor($lab_inputfile, $COLOR_SKYBLUE)
				$set_if = true

			case $set_if = true
				GUICtrlSetColor($lab_inputfile, default)
				$set_if = false
		endselect
		select
			; outputfile label..
			case $set_of = false and $mouse_pos[4] = $lab_outputfile
				GUICtrlSetColor($lab_outputfile, $COLOR_SKYBLUE)
				$set_of = true

			case $set_of = true
				GUICtrlSetColor($lab_outputfile, default)
				$set_of = false
		endselect
		select
			; crop w / h label..
			case $set_wh = false and $mouse_pos[4] = $label_active_crop_wh
				GUICtrlSetColor($label_active_crop_wh, $COLOR_SKYBLUE)
				$set_wh = true

			case $set_wh = true
				GUICtrlSetColor($label_active_crop_wh, default)
				$set_wh = false
		endselect
		select
			; crop x / y label..
			case $set_xy = false and $mouse_pos[4] = $label_active_crop_xy
				GUICtrlSetColor($label_active_crop_xy, $COLOR_SKYBLUE)
				$set_xy = true

			case $set_xy = true
				GUICtrlSetColor($label_active_crop_xy, default)
				$set_xy = false
		endselect

		$previous_pos = $mouse_pos[4]

	endif



	; Button text changes..
	; We set a $shifted flag to prevent updating the buttons every 1/100th second when nothing is happening
	select

		case _IsPressed(10) and WinActive($ffeGUI) and not $shifted
			$shifted = true
			; "Do It!" becomes script output..
			GUICtrlSetData($butt_doit, "script output")
			GUICtrlSetData($butt_wipe, "restore")
			; Set the number of frames (saved to ini)
			GUICtrlSetData($butt_quicktest, "set frames")
			GUICtrlSetData($butt_mediareport, "open report")

			; Custom buttons - Let the user know these can be edited..
			for $i = 1 to $custom_buttons_array[0][0]
				GUICtrlSetFont($custom_buttons[$i], $custom_buttons_font_size-2)
				GUICtrlSetData($custom_buttons[$i], "Edit " & $custom_buttons_array[$i][0])
			next
		case not _IsPressed(10) and $shifted
			GUICtrlSetData($butt_doit, "do it!")
			GUICtrlSetData($butt_wipe, "wipe")
			GUICtrlSetData($butt_quicktest, "short test")
			GUICtrlSetData($butt_mediareport, "media report")
			for $i = 1 to $custom_buttons_array[0][0]
				GUICtrlSetFont($custom_buttons[$i], $custom_buttons_font_size)
				GUICtrlSetData($custom_buttons[$i], $custom_buttons_array[$i][0])
			next
			$shifted = false
	endselect

	; Check if mouse hovering over drop window..
	local $drop_mouse_pos = GUIGetCursorInfo($GUI_DropWindow)

	if IsArray($drop_mouse_pos) and $drop_mouse_pos[4] then
		; @extended is read inside the main loop.
		return SetExtended($drop_mouse_pos[4], $mouse_pos[4])
	endif

	return $mouse_pos[4]
endfunc



; Focus detected on $inp_outputfile and others..
;2do - could store selections of all intputs and restore.. a rainy-day task!
func CheckFocus($hWnd, $iMsg, $wParam, $lParam)
#forceref $hWnd, $iMsg

	debug("CheckFocus(current current_control_focus): " & $current_control_focus, @ScriptLineNumber, 9);debug
	local $iFlag = BitShift($wParam, 16)

	switch $lParam
		case GUICtrlGetHandle($inp_outputfile)
			switch $iFlag
				case $EN_SETFOCUS
					$current_control_focus = $inp_outputfile
					; Focusing/selecting output text does not change naming mode.
				case $EN_CHANGE
					; Only flag the edit here; do not rebuild inside WM_COMMAND.
					if not $creating_args and not (GUICtrlRead($inp_outputfile) == $last_outputfile) then $output_edit_pending = true
			endswitch

		case GUICtrlGetHandle($inp_inputfile)
			switch $iFlag
				case $EN_SETFOCUS
					$current_control_focus = $inp_inputfile
			endswitch

		case GUICtrlGetHandle($inp_input_params)
			switch $iFlag
				case $EN_SETFOCUS
					$current_control_focus = $inp_input_params
			endswitch

		case GUICtrlGetHandle($inp_extra_args)
			switch $iFlag
				case $EN_SETFOCUS
					$current_control_focus = $inp_extra_args
			endswitch

		case GUICtrlGetHandle($edit_console_output)
			switch $iFlag
				case $EN_SETFOCUS
					$current_control_focus = $edit_console_output
			endswitch

		case GUICtrlGetHandle($edit_in_args)
			switch $iFlag
				case $EN_SETFOCUS
					$current_control_focus = $edit_in_args
			endswitch

	endswitch

	debug("$current_control_focus: " & $current_control_focus, @ScriptLineNumber, 9);debug
endfunc



func OutputFileChanged()
	if $creating_args then return
	if not $output_edit_pending and GUICtrlRead($inp_outputfile) == $last_outputfile then return
	; Commit on the normal edit event (or Tab/rebuild), not every keystroke.
	DoArgsCreate()
endfunc





; Right-Now-Click(TM) Functions
; Skip the context menu, save a click, save time, save your fingers!
;
func CheckForRightClickTask()

	if $right_clicking then return

	AdlibRegister("EndRightClick", 400)
	$right_clicking = true

	local $cursor_info = GUIGetCursorInfo($ffeGUI)

	switch $cursor_info[4]

		case $lab_inputfile
			PlayInputFile()

		case $lab_outputfile
			DeleteOutputFile()

		case $check_run_ffmpeg_task
			EditFFmpegTask()

		case $check_run_ffplay_task
			EditFFplayTask()

		case $butt_quicktest
			UserEditShortTestParams()

		case $butt_wipe
			RestoreBackupPreset()

		case $butt_reset
			RightClickResetAll()

		case $check_run_pre_job_commands
			SpecifyPreJobCMDsFile()

		case $check_run_post_file_command
			SpecifyPostFileCommand()

		case $check_run_post_job_commands
			SpecifyPostJobCMDsFile()

		case $label_active_crop_wh, $label_active_crop_xy
			UserEditCropTestFrames(default, true)

	endswitch

endfunc



func EndRightClick()
	$right_clicking = false
	AdlibUnRegister("EndRightClick")
endfunc



; Yes, every time you press the mouse button in the GUI..

func PrimaryUpCheckSize()
	debug("PrimaryUpCheckSize() --> CheckSize()...", @ScriptLineNumber, 7);debug
	if $current_control_focus <> $edit_in_args then
		CheckSize()
		DoArgsCreate()
	endif
endfunc



; Get window to conform to minimum sizes..

func CheckSize()

	debug("CheckSize()...", @ScriptLineNumber, 7);debug

	$too_far = false
	local $size_array = WinGetClientSize($ffeGUI)
	if not IsArray($size_array) then return false

	; User window made too small for controls..
	if $size_array[0] < $min_width then
		WinMove($my_title, "", default, default , $min_width+10)
		$too_far = true
	endif
	if $size_array[1] < $min_height then
		WinMove($my_title, "", default, default , default, $min_height+$height_magic)
		$too_far = true
	endif

	if $too_far then
		$size_array = WinGetClientSize($ffeGUI)
		$width = $size_array[0]
		$height = $size_array[1] ; not actually required

		; The user went too far!
		; ffe has been automatically resized - re-create the button grid..
		if $enable_custom_buttons = $ON and $custom_buttons_columns = "auto" then
			debug("CheckSize() ---> ReCreateButtonGrid() ....................", @ScriptLineNumber, 7);debug
			ReCreateButtonGrid()
		endif
	endif


	if $minimized = $OFF and not $do_gen then GUISetState(@SW_SHOW, $ffeGUI)

	; Quick check on x/y so relative dialogs can remain so..
	$size_array = WinGetPos($ffeGUI)
	if IsArray($size_array) then

		if $size_array[0] <> $x then
			$x = $size_array[0]
			IniWrite($ini_path, $my_name, "x", $x)
		endif

		if $size_array[1] <> $y then
			$y = $size_array[1]
			IniWrite($ini_path, $my_name, "y", $y)
		endif

	endif

	return true
endfunc



func ResizeSaveXYWHPrefs()
	SaveXYWHPrefs()
endfunc



func SaveXYWHPrefs($shutdown=false)

	debug("SaveXYWHPrefs()...", @ScriptLineNumber, 7);debug

	if not CheckSize() then return

	; Set the actual variables, too, so we can refer to them when creating dialogs.
	local $size_array = WinGetPos($ffeGUI)
	if not IsArray($size_array) then return

	if $size_array[0] < (@desktopWidth-25) then
		$x = $size_array[0]
		IniWrite($ini_path, $my_name, "x", $x)
	endif
	if $size_array[1] < (@desktopHeight-25) then
		$y = $size_array[1]
		IniWrite($ini_path, $my_name, "y", $y)
	endif

	$size_array = WinGetClientSize($ffeGUI)
	if not IsArray($size_array) then return

	if $size_array[0] >= $min_width then
		$width = $size_array[0]
		IniWrite($ini_path, $my_name, "width", $size_array[0])
	endif
	if $size_array[1] >= $min_height-$height_magic then
		$height = $size_array[1]
		IniWrite($ini_path, $my_name, "height", $size_array[1])
	endif

	if not $shutdown then
		; We may need to re-calculate the number of custom button columns..
		; the $too_far flag prevents a second firing of ReCreateButtonGrid() after the PRIMARYUP event..
		if $custom_buttons_columns = "auto" and $enable_custom_buttons = $ON and $too_far = false then
			debug("SaveXYWHPrefs() ---> ReCreateButtonGrid() ....................", @ScriptLineNumber, 7);debug
			ReCreateButtonGrid()
		endif
	endif

endfunc







; Either at launch time or on file drop..
;
func DoDropCommand()
	switch $drop_command
		case "Go"
			DoIt()
		case "Play"
			PlayIt()
		case "Generate"
			$do_gen = true
			DoIt()
		case "Report"
			if not StringInStr(FileGetAttrib($inputfile), "D") then GenerateReport()
	endswitch
endfunc



; Read the user's video and audio codec prefs and either load their list or
; use FFmpeg to generate a fresh codec list for the codec combos.
; If the user's list is empty, fall-back to generating a fresh list.
;
func GetUserCodecs()

	$auto_codecs = IniReadCheckBoxValue($ini_path, $my_name, "auto_codecs", $OFF)
	debug("$auto_codecs: " & Human($auto_codecs), @ScriptLineNumber, 8);debug

	switch $auto_codecs

		case $ON

			; Conversely; user has specified auto-codecs but that failed (for
			; some reason). Fall-back to ini file. If that fails, we will try
			; FFmpeg again, one type at a time..
			if not GetCodecsFromFFmpeg() then continuecase

		case else

			$video_codecs = IniRead($ini_path, $my_name, "video_codecs", "")

			if not $video_codecs then
				; No video codecs specified, get these from FFmpeg..
				GetCodecsFromFFmpeg(true,false)

			; Video codecs loaded from ffe.ini, so load audio codecs..
			else
				; Ensure "disable" is included in list..
				if not StringInStr($video_codecs, "|- disable video -") then $audio_codecs &= "|- disable video -"
				$audio_codecs = IniRead($ini_path, $my_name, "audio_codecs", "")

				; No audio codes in ffe.ini, get from FFmpeg..
				if not $audio_codecs then
					GetCodecsFromFFmpeg(false,true)
				else
					if not StringInStr($audio_codecs, "|- disable audio -") then $audio_codecs &= "|- disable audio -"
				endif
			endif

	endswitch

	debug("$video_codecs: " & $video_codecs, @ScriptLineNumber, 8);debug
	debug("$audio_codecs: " & $audio_codecs, @ScriptLineNumber, 8);debug

endfunc


; Get the -encoders help from FFmpeg and parse it for the currently available
; encoders which we use to create lists for the codec drop-downs (combos).
;
func GetCodecsFromFFmpeg($do_video=true, $do_audio=true)

	local $file = @TempDir & "\encoders"
	RunWait(@ComSpec & " /c """ & $ffmpeg_binary & """ -encoders > " & $file , "", @SW_HIDE)
	if not FileExists($file) then return false

	; We need a blank item at the start, for intuitive user input..
	local $v_codecs = "||"
	local $a_codecs = "||"
	local $this_codec

	local $encoders_help_array = FileReadToArray($file)
	if not IsArray($encoders_help_array) then return false

	; Skip intro.
	; Run through the lines..
	for $i = 9 to Ubound($encoders_help_array)-1

		$this_codec = StringStripWS($encoders_help_array[$i], 3)

		; Grab this now; we'll use it..
		local $first_letter = StringLeft($this_codec, 1)

		; Strip off the unwanted parts..	(I do hope they don't change this format! lol)
		$this_codec = StringRegExpReplace($this_codec, "\H{6}\h([^\h]+)[\h]*.*", "$1", 1)

		switch $first_letter
			case "V"
				if $do_video then $v_codecs &= $this_codec & "|"
			case "A"
				if $do_audio then $a_codecs &= $this_codec & "|"
		endswitch
	next

	; Quick check to ensure we have what we expect..
	if (StringInStr($v_codecs, "x264") and $do_video) or (StringInStr($a_codecs, "mp3") and $do_audio) then
		; Ensure essential list items are present..
		if $do_video then $video_codecs = $v_codecs & "copy|- disable video -"
		if $do_audio then $audio_codecs = $a_codecs & "copy|- disable audio -"
		FileDelete($file)
		return true
	endif

endfunc





func AbortBatch()
	$abort_batch = true
endfunc




; Momentary warning.
; Flash a control background (or foreground) red.
;
; $warn_control is a global variable we set to whatever control we want the
; warning to be displayed on. That's really poor English!
; Choose from background (default) or Foreground (text) warning.
;
func SetWarning($bg=true)
	if $bg then
		GuiCtrlSetBkColor($warn_control, $warn_colour)
		AdlibRegister("EndBGWarning", 666)
	else
		GuiCtrlSetColor($warn_control, $warn_colour)
		AdlibRegister("EndFGWarning", 666)
	endif
endfunc
func EndWarning($bg=true)
	if $bg then
		GuiCtrlSetBkColor($warn_control, default)
	else
		GuiCtrlSetColor($warn_control, default)
	endif
endfunc
func EndBGWarning()
	EndWarning(true)
endfunc
func EndFGWarning()
	EndWarning(false)
endfunc



; Validate the user colour and convert it into a binary string to be used as a
; color value for AutoIt functions (they don't mind that it's a string!)..
func GetUserColor($user_color)
	; lop off any preceding "#"..
	$user_color = StringRight($user_color, 6)
	debug("$user_color: " & $user_color, @ScriptLineNumber, 8);debug
	; Magical Binary Conversion..
	return "0x" & $user_color
endfunc




; Delayed start..

func DelayedDoIt()

	if $delay_start_at then
		TrayItemSetState($tray_toggle_delayed_start, $OFF)
		$delay_start_at = false
		return false
	endif

	DialogOpen()
	local $previous_event_mode = AutoItSetOption("GUIOnEventMode", 0)
	local $previous_coord_mode = AutoItSetOption("GUICoordMode", 0)

	local $datetime_picker, $now_date[7] = [False, @Year, @Mon, @Mday, @Hour, @Min, @Sec]

	local $msg, $tip, $ttt, $aw = 285, $ah = 190
	local $GUI_Delayed = GUICreate("Delayed Start Options.. ", $aw, $ah, -1, @DesktopHeight/4, $WS_CAPTION, $WS_EX_TOPMOST, $ffeGUI)

	local $dummy_first_control = GUICtrlCreateDummy()

	GUICtrlCreateLabel("You can run the job at a later time." , 15, 15, $aw-25)
	GUICtrlCreateLabel("Select the required countdown delay:" , 0, 20, $aw-25)

	$tip = "Select the number of days to wait before starting the job. "
	$ttt = "Days Delay"
	local $lab_days = GUICtrlCreateLabel("Days:", 0, 27)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	local $combo_delay_days = GUICtrlCreateCombo("", 30, -2, 42)
	for $i = 1 to 365
		GUICtrlSetData(-1, $i)
	next
	GUICtrlSetTipOptional(-1, $tip, $ttt)

	$tip = "Select the number of hours to wait before starting the job. "
	$ttt = "Hours Delay"
	GUICtrlCreateLabel("Hours:", 55, 2)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	local $combo_delay_hours = GUICtrlCreateCombo("", 35, -2, 42)
	for $i = 1 to 24
		GUICtrlSetData(-1, $i)
	next
	GUICtrlSetTipOptional(-1, $tip, $ttt)

	$tip = "Select the number of minutes to wait before starting the job. "
	$ttt = "Minutes Delay"
	GUICtrlCreateLabel("Minutes:", 50, 2)
	GUICtrlSetTipOptional(-1, $tip, $ttt)
	local $combo_delay_minutes = GUICtrlCreateCombo("", 45, -2, 42)
	for $i = 1 to 60
		GUICtrlSetData(-1, $i)
	next
	GUICtrlSetTipOptional(-1, $tip, $ttt)

	GUISetCoord(15, 75)
	GUICtrlCreateLabel("Alternatively, pick a date/time directly:" , 0, 20, $aw-25)

	local $check_enable_datepick = GUICtrlCreateCheckbox("", 0, 22, 26, 26, BitOr($BS_AUTOCHECKBOX, $BS_PUSHLIKE,$BS_ICON))
	if @compiled then
		GUICtrlSetImage(-1, $me_app, $time_icon_index, 0)
	else
		GUICtrlSetImage(-1, ".\Resources\Icons\ffe-time.ico", -1, 0)
	endif
	local $picker = GUICtrlCreateDate($GUI_Delayed, 30, 1, 226, 24, $DTS_UPDOWN)
	GUICtrlSetFont(-1, 9.5)
	GUICtrlSetState(-1, $GUI_DISABLE)
	$ttt = "Direct Date & Time Input"
	GUICtrlSetTipOptional(-1, "click here to instead enable direct date & time settings. ", $ttt)

	; Grab the handle and we can use the groovy _GUICtrlDTP_* functions
	; (similar, but better, to using _GUICtrlDTP_Create())..
	$datetime_picker = GUICtrlGetHandle($picker)
	_GUICtrlDTP_SetFormat($datetime_picker, "ddd yyyy MMM dd  hh:mm ttt")
	_GUICtrlDTP_SetSystemTime($datetime_picker, $now_date)

	local $range_array[14] = [true, @Year, @Mon, @Mday, @Hour, @Min, @Sec]
	_GUICtrlDTP_SetRange ($datetime_picker, $range_array )

	local $dummy_last_control = GUICtrlCreateDummy()

	for $i = $dummy_first_control to $dummy_last_control
		GUICtrlSetResizing($i, BitOr($GUI_DOCKTOP, $GUI_DOCKLEFT, $GUI_DOCKSIZE))
	next

	guiSetCoord($aw-172, $ah-28)
	local $GUI_Delayed_NO = GUICtrlCreateButton("Cancel", 0, 0, 75, 20, BitOr($WS_TABSTOP, $BS_FLAT))
	local $GUI_Delayed_OK = GUICtrlCreateButton("Set Delay", 80, 0, 80, 20, BitOr($WS_TABSTOP, $BS_FLAT, $BS_DEFPUSHBUTTON))

	ControlFocus($ffeGUI, "", $combo_delay_days)
	GUISetState(@SW_SHOW, $GUI_Delayed)

	while true

		sleep(10)
		$msg = GUIGetMsg()

		switch $msg

			case $GUI_EVENT_CLOSE, $GUI_Delayed_NO
				exitloop

			case $GUI_Delayed_OK

				; Not required, but makes things clear..
				$delay_start_at = ""

				if GUICtrlRead($check_enable_datepick) = $ON then
					local $user_time_array = _GUICtrlDTP_GetSystemTime($datetime_picker)
					_GUICtrlDTP_Destroy($datetime_picker)
					$delay_start_at = $user_time_array[0] & "/" & $user_time_array[1] & "/" & _
						$user_time_array[2] & " " & $user_time_array[3] & ":" & $user_time_array[4] & _
						":" & $user_time_array[5]
				else
					; Countdown..
					if GUICtrlRead($combo_delay_days) then
						$delay_start_at = _DateAdd("D", GUICtrlRead($combo_delay_days), _NowCalc())
					else
						$delay_start_at = _NowCalc()
					endif
					if GUICtrlRead($combo_delay_hours) then $delay_start_at = _
						_DateAdd("h", GUICtrlRead($combo_delay_hours), $delay_start_at)
					if GUICtrlRead($combo_delay_minutes) then $delay_start_at = _
						_DateAdd("n", GUICtrlRead($combo_delay_minutes), $delay_start_at)
				endif

				exitloop

			case $check_enable_datepick

				local $state = $GUI_ENABLE

				if GUICtrlRead($check_enable_datepick) = $ON then
					GUICtrlSetData($GUI_Delayed_OK, "Set Time")
					GUICtrlSetState($picker, $GUI_ENABLE)
					$state = $GUI_DISABLE
				else
					GUICtrlSetData($GUI_Delayed_OK, "Set Delay")
					GUICtrlSetState($picker, $GUI_DISABLE)
				endif

				for $i = $lab_days to $combo_delay_minutes
					GUICtrlSetState($i, $state)
				next
		endswitch

		dim $range_array[14] = [true, @Year, @Mon, @Mday, @Hour, @Min, @Sec]
		_GUICtrlDTP_SetRange($datetime_picker, $range_array)

	wend

	GUIDelete($GUI_Delayed)
	AutoItSetOption("GUIOnEventMode", $previous_event_mode)
	AutoItSetOption("GUICoordMode", $previous_coord_mode)
	DialogClose()

	if $delay_start_at then TrayItemSetState($tray_toggle_delayed_start, $ON)

endfunc






func __________________________EXIT()
endfunc

; Bye Now!

func Restart()
	DoQuit(0, true)
endfunc

func UserDoQuit()
	DoQuit(0)
endfunc


; Really, Bye!
;
func DoQuit($ext=0, $reload=false)

	UnSetHotKeys() ; not actually required

	if $kill_ffmpeg_on_exit = $ON then
		ProcessSuspendResume($ffmpeg)
		DllCall('kernel32.dll', 'ptr', 'DebugSetProcessKillOnExit', 'int', true)
	else
		ProcessSuspendResume($ffmpeg, false)
		DllCall('kernel32.dll', 'ptr', 'DebugSetProcessKillOnExit', 'int', false)
	endif

	if $minimized = $OFF and $maximized = $OFF then
		SaveXYWHPrefs(true)
	endif

	if (not $do_quit) and ($retain_exit_settings = $ON) then
		IniDelete($ini_path, $EXIT_PRESET)
		SavePreset($EXIT_PRESET)
	endif

	VersionCheckOnline($my_name, $versioncheck_url, $download_url, $ini_path, $my_name, $VERSION)

	; Keep recent files..
	; (do this last, in case it's large and we hit the ini character length limit before it parses out)
	; Invalid (cropped) entries will be automatically removed at launch.
	if $retain_recent_files = $ON and $recent_files[0][0] then
		$recent_files = TwoDCol2OneDArray($recent_files)
		IniWrite($ini_path, $my_name, "recent_files", ArrayJoin($recent_files, "|"))
	endif

	; Fade-out	(would ideally like a TV power-off, like the HUDL2). Och well..
	for $tc = 255 to 0 step -20
		WinSetTrans($ffeGUI, "", $tc)
		Sleep(10)
	next

	; Do this AFTER the saving X/Y prefs for main GUI, or else they will be GONE.
	GUIDelete($ffeGUI)

	if $dropwin_visible then HideDropWindow()

	; Reclaim small amount of memory..
	AAWipe($known_files)

	if $reload then Run(@ScriptFullPath)
	exit $ext

endfunc






; AutoIt Wrapper / Compiler directives..
#Region

; For resources included with FileInstall()
#pragma compile(Compression, 9)

;::dev::..
; If you want your binary NOW, set to N
#AutoIt3Wrapper_Run_Au3Stripper=Y

; See the notes above debug() (in corzShared.au3) for what /rsln does.
#Au3Stripper_Parameters=/StripOnly /rsln

; Like calling the wrapper with /debug, which we do anyway. This is handy, though ..
#AutoIt3Wrapper_Run_Debug_Mode=Y
#AutoIt3Wrapper_LogFile=%scriptdir%\wrapper.log
#AutoIt3Wrapper_UseX64=Y
#AutoIt3Wrapper_UseUpx=N
#AutoIt3Wrapper_Run_AU3Check=Y
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w 7 -v 7
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=Y
#AutoIt3Wrapper_Run_Stop_OnError=Y
; Main program icon..
; NOTE: *** MAY NEED FORWARD SLASHES IN RELATIVE PATHS - YMMV!!! ***
#AutoIt3Wrapper_Icon=Resources\Icons\ffe.ico
;-5.
#AutoIt3Wrapper_Res_Icon_Add=Resources\Icons\document-outline.ico
;-6.
#AutoIt3Wrapper_Res_Icon_Add=Resources\Icons\magic-wand.ico
;-7.
#AutoIt3Wrapper_Res_Icon_Add=Resources\Icons\document-small.ico
;-8.
#AutoIt3Wrapper_Res_Icon_Add=Resources\Icons\folder-small.ico
;-9.
#AutoIt3Wrapper_Res_Icon_Add=Resources\Icons\folder-small-outline.ico
;-10.
#AutoIt3Wrapper_Res_Icon_Add=Resources\Icons\auto-out.ico
;-11.
#AutoIt3Wrapper_Res_Icon_Add=Resources\Icons\ffe-time.ico
;-12.
#AutoIt3Wrapper_Res_Icon_Add=Resources\Icons\tooltip.ico
;-13.
#AutoIt3Wrapper_Res_Icon_Add=Resources\Icons\target.ico


; Free-Form Res Fields..
#AutoIt3Wrapper_Res_HiDpi=Y
#AutoIt3Wrapper_Res_Field=Author|Cor
#AutoIt3Wrapper_Res_Field=Contact|windows@corz.org
#AutoIt3Wrapper_Res_Field=Instructions|enable MATOF, drag and drop files into ffe, choose a preset, do it!
#AutoIt3Wrapper_Res_Field=Long Description|ffe is a Windows front-end for the marvelous FFmpeg. It was designed for rapid testing of the many (many) FFmpeg settings, enabling one to quickly find the best settings for a particular file, and when you do, save it as a preset, for future use. Find any cute settings along the way, save those as a handy button. Of course you can also use ffe to perform the actual conversions, with output piped directly into your GUI.
#AutoIt3Wrapper_Res_Field=Publisher|corz.org
#AutoIt3Wrapper_Res_Field=Web Page|https://corz.org/windows/software/ffe/
#AutoIt3Wrapper_Res_Field=Compiled|%date% %time%

; These now have their own fields..
#AutoIt3Wrapper_Res_ProductName=ffe
#AutoIt3Wrapper_Res_CompanyName=corz.org
#AutoIt3Wrapper_Res_LegalCopyright=corz.org

; Application's resource info..
#AutoIt3Wrapper_Res_Comment=ffe

; This is the one that shows up in Process Explorer..
#AutoIt3Wrapper_Res_Description=ffe - FFmpeg Front-End for Windows
#AutoIt3Wrapper_Res_LegalCopyright=corz.org
#AutoIt3Wrapper_Res_ProductVersion=2

;#AutoIt3Wrapper_Res_Field=Build|DEBUG
;#AutoIt3Wrapper_Res_Field=Build|Beta Release
#AutoIt3Wrapper_Res_Field=Build|Public Release




; Run pre- & post-compile tasks elevated (as admin)..
;
#AutoIt3Wrapper_Run_Before_Admin=Y
#AutoIt3Wrapper_Run_After_Admin=Y


; Tasks to perform BEFORE compilation..
;

; You might want to comment this out (kills any running instance of ffe)..
#AutoIt3Wrapper_Run_Before=taskkill /F /T /IM ffe.exe
; But if you do, copying your new binary over (below) probably won't work.



; Tasks to perform AFTER compilation..
;

; Backup this version of the script (dropped into a backup.zip, below). So I don't have to remember to..
#AutoIt3Wrapper_Run_After=copy "%in%" 									".\%scriptfile% - %fileversion%.au3"


; Handy to keep a backup of the stripped version, too..
#AutoIt3Wrapper_Run_After=move /Y .\%scriptfile%_stripped.au3 			".\%scriptfile% - %fileversion%_stripped.au3"


;::dev::..
; Copy latest binaries to app folders (overwrites existing binary)..
; Your copy of ffe may be somewhere else..
#AutoIt3Wrapper_Run_After=copy "%outx64%" 								"C:\Program Files\corz\ffe\ffe.exe"




;::dev::..
; You can probably comment-out this entire next section.
; It relates to building the distribution and source packages.
;
; It has some useful commands for your reference, though.

;
; ffe download package..
; Move latest binaries, etc. to distro folder (out of the way of the source)..
#AutoIt3Wrapper_Run_After=mkdir     "..\ffe"
#AutoIt3Wrapper_Run_After=mkdir     "..\ffe\Info"
#AutoIt3Wrapper_Run_After=move /Y   "%outx64%" 							        "..\ffe\ffe.exe"
#AutoIt3Wrapper_Run_After=copy      ".\Resources\QuickStart.txt" 	  "..\ffe\QuickStart.txt"
#AutoIt3Wrapper_Run_After=copy      ".\Resources\ffe.ini" 					"..\ffe\Info\ffe.ini"
#AutoIt3Wrapper_Run_After=copy      "..\Itstory.txt" 							  "..\ffe\Info\Itstory.txt"


; RELEASE..

; Delete old distros if hanging around.
#AutoIt3Wrapper_Run_After=del /a "C:\Users\Dad\Documents\Dev\AutoIt\ffe\ffe.hash"
#AutoIt3Wrapper_Run_After=del "C:\Users\Dad\Documents\Dev\AutoIt\ffe\ffe.zip"

; NOTE: The 7z and checksum program directories are in my %PATH% (System Properties >> Advanced >> Environment Variables).

; Create zip of distro directory..
#AutoIt3Wrapper_Run_After=7z.exe a -mx7 -tzip "..\ffe.zip" "..\ffe\"

; Hash the zip..
#AutoIt3Wrapper_Run_After=checksum.exe cq-t-h "..\ffe.zip"

; Backup this version of the source files to BackUp.zip..
#AutoIt3Wrapper_Run_After=7z.exe a -mx7 -tzip "..\BackUp\BackUp.zip" ".\%scriptfile% - %fileversion%.au3"
#AutoIt3Wrapper_Run_After=7z.exe a -mx7 -tzip "..\BackUp\BackUp.zip" ".\%scriptfile% - %fileversion%_stripped.au3"



; Finally, remove the (now-zipped) source files..
#AutoIt3Wrapper_Run_After=del /f /q ".\%scriptfile% - %fileversion%.au3"
#AutoIt3Wrapper_Run_After=del /f /q ".\%scriptfile% - %fileversion%_stripped.au3"


#EndRegion
