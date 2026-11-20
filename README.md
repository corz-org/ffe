# [ffe](https://corz.org/windows/software/ffe/)

<div>  <a href="https://corz.org/windows/software/ffe/"><img alt="logo for ffe - FFmpeg front-end for windows. it's converting some raw video from my camera - the logo is a simple large text of the three letters, coloured from top to bottom, green, yellow, red, in a smooth gradient." src="https://corz.org/windows/software/ffe/img/ffe-ffmpeg-front-end-logo_corz.png" title="ffe - an FFmpeg front-end, for media files, for Windows..
Click here to go straight to the downloads!"/></a> <a name="section-Intro"></a>
<p><a name="link-FFmpeg"></a><a href="https://ffmpeg.org/" title="FFmpeg is a complete solution to record, convert and stream audio and video">FFmpeg</a> is, by miles and miles, the best multimedia converter / streamer / recorder in existence. It is capable of handling a vast number of input and output (audio, video and other) formats, and depending on which binary you use; supports either a huge number of control parameters, or a <em>really huge</em> number of control parameters. In the time it took you to read this paragraph, a new format has been added.
</p>
<p>FFmpeg, by Fabrice Bellard, et al., is truly incredible software. And free. With FFmpeg you can basically convert anything to anything, whilst doing crazy stuff like mixing MP3 audio tracks with H264 video, and adding ID3 tags to AVI files. Big fun. Of course, it allows you do do things the correct way, too. No limits.
</p>
<p>It is also <code>command-line-only</code>. Because of this, accessing its magic is only possible in the shell, or else with some kind of interface between regular human beings and the wonders of FFmpeg..
</p>
<p>Enter <strong>ffe</strong>; a simple, powerful Windows front-end for FFmpeg; designed for rapid testing of FFmpeg's many, <em>many</em> conversion options inside a (hopefully more) user-friendly interface. While FFmpeg can do many, many things, the focus here is on its media conversion capabilities.
</p>
<p><strong>ffe</strong> takes your ffmpeg operations to the next level; aiming to be powerful and flexible yet intuitive and intelligent. <strong>ffe</strong> turns complex processes into buttons and simplifies just about every aspect of FFmpeg's operation, whilst simultaneously catering for the most advanced FFmpeg processing needs.
</p>
<p>If you are looking to transcode a collection of old AVI video files to HEVC/x265 or AV1 to save space, or convert a folder of WAV or FLAC files to MP3, or mux subtitles into a movie, or make a GIF from a video clip, or part of a video clip, or speed up or reverse a video, or toy with AV1 or, well, you get the idea; pretty much anything you can imagine; <strong>ffe</strong>+FFmpeg can do it.
</p>
<p>Find a cute FFmpeg command online? Or get something finally working exactly the way you want? Save it to a button and it's there whenever you need it. Want to convert and join a folder-full of files? No problem. And then join them all together? Easy. Need to calculate the cropping to remove black bars? With <strong>ffe</strong> it's one click.
</p>
<p>You can setup a complete FFmpeg work-flow, with pre- and post-batch commands, file post-processing and much more, and with a click; save it all to a preset, available for scripted or interactive use at any time. Or drop some files in and save the whole lot as a Windows batch script. Or tell <strong>ffe</strong> to start up the job in a couple of hours, when you're asleep, then shutdown when it's done. Or next Tuesday.
</p>
<p>Out-of-the-box, <strong>ffe</strong> is ready to start work, with a selection of useful (and fun) built-in presets and custom buttons (which you can add-to/edit/delete). When you need more power, <strong>ffe</strong> can handle that, too.
</p>
<p><strong>ffe</strong> is completely free, as in beer. And completely open source, with ready-to-use binaries and ready-to-compile source packs that regular folks can get up and running in a jiffy. Have fun!
</p>
<div>
</div>
<a name="link-internal-ffe-screencaps"></a>
<h3 align="center"><a href="https://corz.org/windows/software/ffe/ffe-screencaps.php">Screencaps</a></h3><a name="section-Features"></a>
<div>
</div>
<h2><strong>ffe</strong>, an FFmpeg front-end for Windows..
</h2>
<p><strong>ffe</strong> provides a huge set of features designed to make working with FFmpeg painless, even joyful, such as..
</p>
<div>
</div>
<ul>
<li>Batch operation.
</li>
<li>Drag-And-Drop file handling.
</li>
<li>Magic Auto-Transforming Output Filename <small>(no more overwriting previous tests 'by mistake')</small>.
</li>
<li>Fully programmable FFmpeg and FFplay quick task buttons.
</li>
<li>Infinite fully-customizable user presets in a handy drop-down.
</li>
<li>Fully Customizable Preset Controls and Programmable Handy Help Buttons.
</li>
<li>Infinite<a href="#refs-almost-infinite" title="go to the reference">*</a>, Fully Customizable One-Click Custom Command Buttons <small>(you favourite settings and templates at a click)</small>.
</li>
<li>Handy, fully customizable selectors for all your common FFmpeg settings.
</li>
<li>Full Import/Export. Share your presets, custom buttons, and even settings, with other <strong>ffe</strong> users.
</li>
<li>Live, interactive shell console output.
</li>
<li>Windows Batch Script Output (rather than process files, <strong>ffe</strong> can create a .bat script for later use).
</li>
<li>URL input and output (HTTP/FTP/rtmp/etc.).
</li>
<li>Accepts files and presets on the command-line.
</li>
<li>Command-line switches to run presets, generate batch scripts and more.
</li>
<li>Drag-And-Drop commands <small>(automatically generate media reports, batch scripts or run jobs for launched or dropped files)</small>.
</li>
<li>Cool Floating Drop Window <small>(transparent and optionally animated. Drag in files and more!)</small>.
</li>
<li>Dynamic <code>@tokens</code> accepted everywhere.
</li>
<li>Automatic concatenation.
</li>
<li>Quit and Shutdown when done options.
</li>
<li>Pre-Job Commands <small>(run Windows shell commands before the job)</small>.
</li>
<li>Post-Job Commands <small>(and after, all with batch script and @token support)</small>.
</li>
<li>Post-File Command <small>(run custom commands on all output files, using <code>@tokens</code>, even inside a batch)</small>.
</li>
<li>Media Info Reporting <small>(ffprobe and <a name="link-external-mediainfo"></a><a href="https://mediaarea.net/en/MediaInfo" title="It gets info about your media!">Mediainfo</a> support)</small>.
</li>
<li>Live Console Output <small>(ffe messages, command output and more)</small>.
</li>
<li>Super-Handy App Menu for common settings and tweaks.
</li>
<li>Live CPU priority Selector.
</li>
<li>Comprehensive logging and debugging options.
</li>
<li>Handy HotKey operation.
</li>
<li>Delayed/Timed Job Start <small>(set jobs to start after bed-time)</small>.
</li>
<li>Optional Mouse-Over ToolTip Help <small>(dynamically updates with current settings)</small>.
</li>
<li>Fully Automatic Recent files menu.
</li>
<li>Comprehensive command-line capabilities.
</li>
<li>Extensive tray and control menus.
</li>
<li>Output Toggle <small>(roll your own output for image sequences and more)</small>.
</li>
<li>ALL dialogs, even the most minor, remember their size and position. <small>(set and forget)</small>.
</li>
<li>Right-Now-Click™ parameter settings. <small>(Skip those unnecessary RSI-inducing context menu clicks!)</small>
</li>
<li>Semi-automatic extension handling <small>(with customisable default fall-back)</small>.
</li>
<li>All settings (optionally) remembered between sessions.
</li>
<li>GIF Output! <small>(okay, I didn't do a lot here. But hey, GIF output!)</small>
</li>
<li>Automatic preset backups and <a title="Graphic User Interface - the window you interact with">GUI</a> backup restore.
</li>
<li>Drop Window Image Pack - <strong>ffe</strong> can download a pack of tasteful starter images.
</li>
<li>And Much, MUCH More!<br/> <br/>
</li>
<li>And don't forget <strong>ffe</strong> comes with a Rastafarian-coloured icon!
</li>
</ul>
<div>
</div> <a name="refs-almost-infinite"></a>
<div>
<p><a href="javascript:history.go(-1)" title="back to the text"><strong>*</strong> Okay, technically you can only make 500 buttons, but seriously, how are you fitting 500 buttons into a GUI?</a>
</p>
</div>
<div>
</div>
<p><strong>ffe</strong> uniquely uses <a name="title-matof-hyper-dooper-advanced-technology"></a><a title="(Magic Auto-Transforming Output Filename)">MATOF™</a> technology to automatically update the output file name (and extension) to match your encoding parameters; you can tweak-and-go, working at a rapid pace, without obliterating any of your previous tests. And then know <em>exactly</em> what parameters were used to encode each and every one of them, all without making notes.
</p>
<p>That and an FFmpeg binary, of course. It's also free, open-source software, and there are quite a few different versions kicking around. If you have some developer tools onboard, I recommend you <a name="link-FFmpeg-source"></a><a href="https://ffmpeg.org/download.html" title="And I mean checkout quite literally!">checkout the source</a> and build it yourself. Or else Google and take your pick..
</p>
<p><a name="link-ffdshow-ffmpeg-binaries-mirror"></a><a href="https://www.gyan.dev/ffmpeg/builds/" title="no binary, no fun.">This</a> is generally reliable - all versions should work fine.
</p><a name="section-Installation"></a>
<div>
</div>
<h2>Installation..
</h2>
<p>Installation is simple. Here is the entire process. Also available in plain text, <a name="link-internal-ffe-quickstart"></a><a href="Resources/QuickStart.txt" title="ffe quickstart guide in plain text">here</a>.
</p>
<ol>
<li>
<p>Go here: (note: this site has nothing to do with me)
</p>
<p><a name="link-external-ffmpeg-binary-builds"></a><a href="https://www.gyan.dev/ffmpeg/builds/" title="Get the latest stable ffmpeg binary here">https://www.gyan.dev/ffmpeg/builds/</a>
</p>
<p>Download the latest release (you will most likely want the static build, either 32 or 64 bit).
</p>
</li>
<li>
<p>Or here: (note: this site also has nothing to do with me)
</p>
<p><a name="link-external-ffmpeg-binary-autobuilds"></a><a href="https://github.com/BtbN/FFmpeg-Builds/releases" title="Get the latest stable ffmpeg binary here">https://github.com/BtbN/FFmpeg-Builds/releases</a>
</p>
</li>
<li>
<p>Unzip that file to somewhere, probably inside your program files, e.g..
</p>
<p>C:\Program Files\corz\ffe\
</p>
<p>If you don't have an unzipping utility that can handle the 7z (7-Zip) format, see here:
</p>
<p><a name="link-external-7-Zip"></a><a href="http://www.7-zip.org/" title="Excellent, FREE archiving tool.">http://www.7-zip.org/</a>
</p>
<p>7-Zip is free. WinRAR (not free) can also handle the format.
</p>
<p>You should now have some files in that folder, including..
</p>
<p>ffmpeg.exe
</p>
</li>
<li>
<p>Drop <code>ffe.exe</code> into the same folder, next to <code>ffmpeg.exe</code> for instant operation. You can keep them in separate places, too - ffe will ask you where your FFmpeg binary is before you start work.
</p>
</li>
<li>
<p>Launch <code>ffe.exe</code>
</p>
</li>
</ol> <a name="section-Usage"></a>
<div>
</div>
<h2><strong>ffe</strong> Usage..
</h2>
<p><strong>ffe</strong>'s operation is simple. Drop media files or folders onto <strong>ffe</strong>'s input (or funky floating drop window), set your chosen parameters (or choose a preset) and click "do it". That's it.
</p>
<p>As you work, <strong>ffe</strong> constructs a set of command-line arguments for FFmpeg and when you "do it", launches FFmpeg with those same arguments. Simple.
</p>
<p>Creating an FFmpeg command-line is the main reason for <strong>ffe</strong>'s existence. Most of the controls simply add or remove text to the FFmpeg command-line. <strong>ffe</strong> of course can do a lot more, like <em>run</em> that command and lots of other useful stuff, but that is essentially <strong>ffe</strong>'s main task. You can see the command-line being constructed, live, as you work.
</p>
<p>Some of the more common FFmpeg parameters and flags are available from drop-downs and logical inputs; things like codec selection, bitrates, sizes and cropping. Any settings and parameters you use often can be saved to custom buttons that you can click to insert that snippet into any command.
</p>
<p><strong>NOTE</strong>: Standard Operating Procedure is to drag your source file(s) into the "input", then setup any parameters, then drag the destination folder into the "output", then hit "Do It". Doing things this way let's ffe calculate any MATOF strings and such afresh, and saves frustration!
</p>
<p>Once you have created a set of parameters and settings that work for a particular job, you can save the whole lot as a preset, for later use.
</p>
<div>
</div>
<h3>Keyboard shortcuts..
</h3>
<p>Most commonly-used <strong>ffe</strong> commands and settings have HotKeys..
</p><a name="shortcuts"></a>
<div>
</div> <ul>
<li>F1 =&gt;  "do it". Run the job/batch.
</li>
<li>F2 =&gt;  Change (global) default video output extension.
</li>
<li>F3 =&gt;  Search in console output.
</li>
<li>F5 =&gt;  Clear console output.
</li>
<li>F6 =&gt;  Toggle FFplay console output.
</li>
<li>F7 =&gt;  Automatic codec drop-downs.
</li>
<li>F8 =&gt;  Copy console output to clipboard.
</li>
<li>F9 =&gt;  Toggle drop window.
</li>
<li>F11 =&gt;  Perform FFmpeg Quick Task.
</li>
<li>F12 =&gt;  Perform FFplay Quick Task.
</li>
<li>Ctrl+D =&gt;  Delayed/Scheduled Start.
</li>
<li>Alt+F4/Esc =&gt;  Quit ffe.
</li>
<li>Alt+F5 =&gt;  Restart ffe.
</li> </ul>
<p>While FFmpeg is running you can also use..
</p><ul>
<li>Pause/Break =&gt;  Abort entire FFmpeg batch/job.
</li>
<li>Ctrl+Q =&gt;  Abort current FFmpeg job.
</li>
<li>ScrollLock =&gt;  Suspend/Resume FFmpeg.
</li>
<li>Alt+C =&gt;  Pause console output.
</li>
<li>Ctrl+R =&gt;  Toggle running time in title bar.
</li> </ul>
<div>
</div>
<p>Alt+Space opens the app menu where you can navigate entirely by keyboard.
</p><a name="button-accelerators"></a>
<div>
</div>
<h5>Custom Button Accelerators..
</h5>
<p>While I'm here, I should add that you can put keyboard accelerators in the names of your custom buttons and then Alt+ keyboard shortcuts to access them. To do this, simply add an ampersand (&amp;) before the letter you wish to use as an accelerator, e.g.. To use the Alt+B accelerator, name your button for example; "&amp;Blur"
</p>
<p>Most of the sample buttons have Alt+ accelerators. The button's title has the accelerator underlined, e.g..
</p>
<p><code><span>B</span>lur  =&gt;  Alt+B</code>
</p>
<p>If you don't see the underlining, hit the Alt key one time!
</p><a name="active labels"></a>
<div>
</div>
<h5>Active Labels..
</h5>
<p>A few of <strong>ffe</strong>'s labels are "active", that is, something happens if you click on them..
</p>
<p>Click the "crop w / h" and "crop x / y" buttons to perform "auto-crop", which uses FFmpeg's built-in cropdetect mechanism to interrogate your video file for the position of black bars and automatically inserts the values into your crop inputs.
</p>
<p>Click the source label (to the left of the source input) to open the source folder, with the source file selected (if it exists).
</p>
<p>Click the output label to disable output (for image sequences, etc.). Shift-click to open the output directory.
</p>
<p>Right-click the output label to delete the output file(s). By default this deletes to the Recycle Bin without warning, but you can set it to also delete directly with or without warning. Be careful!
</p>
<p>The text of the above labels will change to a light blue on mouse-over, to indicate their extra functionality.
</p>
<p>Many of <strong>ffe</strong>'s control have extra functionality when you Shift+Click, Ctrl+Click or Right-Click the control. Hover your mouse over any control for details of its capabilities. Many controls have context menus, too. Right-click for details!
</p><a name="ffe-Console"></a>
<div>
</div>
<h3>The Console..
</h3>
<p><strong>ffe</strong> has its own console. While working, the output from FFmpeg can be viewed live inside the <strong>ffe</strong> console, and when complete, the entire process log is available for viewing and searching. <strong>ffe</strong> uses the console for many things..
</p>
<p>When you run pre-job, post-file and post-job commands, their output can be piped to the console, so <strong>ffe</strong>'s job log contains every scrap of available information.
</p>
<p><strong>ffe</strong> also uses the console to keep you informed of important events, updated information, settings, errors and more. Help files, media report, script output; everything is fed to the console. There is even a search feature.
</p>
<p>It should also be noted, the console output area is fully editable. You can copy from there, paste, type. In other words, if you are ever wondering, "where can I paste this groovy command I found on the web, so I can edit and try it?" No need to switch to your text editor, there's an edit area right there! You can drag files in, too; their paths get pasted in-place.
</p>
<div>
</div>
<h3>The App Menu..
</h3>
<p><strong>ffe</strong> makes extensive use of the "App Menu". That's the one you get by clicking the icon in the top-left of the program window, or right-clicking the main window's title bar, or hitting Alt+Space. It's always handy.
</p>
<p>This is used for application global toggles and settings. The system tray menu is used for one-off commands, and the main GUI is for your regular FFmpeg fun and games, which makes sense to me. Basically, everything you can <em>see</em>, can be saved to a preset. Both app and tray menus contain the "about" options.
</p>
<p>If you activate the app menu using Alt+Space, you get to use keyboard accelerators, which if your hands are on the keyboard anyway, makes operation <em>real</em> quick. <em>All</em> <strong>ffe</strong> app menu options have keyboard accelerators attached. Enjoy!
</p><a name="section-Command-Line"></a>
<div>
</div>
<h2>Command-line usage..
</h2>
<p>As well as its beautifully thought-out graphics user interface, <strong>ffe</strong> can accept instructions on its command line. You can send it files and folders, and they will be loaded into the input upon launch (real handy in your SendTo menu). You can also process presets at launch time. Or both.
</p>
<p>You can instruct <strong>ffe</strong> to jump right to it, start conversion immediately, generate batch scripts and other stuff. You can use this facility in Windows batch scripts, Explorer context commands and other places. Examples..
</p>
<div>
</div>
<p>To load a file at launch..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe E:\path\to\video.flv</code>
</div>
</blockquote>
<div>
</div>
<p>To load a preset at launch (in this example, a preset named <code>Reverse Video+Audio</code>, which does just that)..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe load(Reverse Video+Audio)</code>
</div>
</blockquote>
<div>
</div>
<p>To load that same preset at launch, but override its input files (if any) with a different file..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe load(Reverse Video+Audio) E:\path\to\video.flv</code>
</div>
</blockquote>
<div>
</div>
<p>The same as above, but for a batch run of all files in the specified directory (Windows wildcards accepted)..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe load(Reverse Video+Audio) E:\path\to\*.*</code>
</div>
</blockquote>
<div>
</div>
<p>This more modern version of Windows "all files" wildcard also accepted..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe load(Reverse Video+Audio) E:\path\to\*</code>
</div>
</blockquote>
<div>
</div>
<p>Load a file (with a long path, including spaces, enclosed in "quotes"), and begin conversion immediately, using the <code title="Who doesn't like speeded-up video!">SpeedUp x2</code> preset..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe go(SpeedUp x2) "E:\very\long path\to some\video.flv"</code>
</div>
</blockquote>
<div>
</div>
<p>Load a file and begin conversion immediately, using your <code>ffe</code> default parameters..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe go(ffe) E:\path\to\video.flv</code>
</div>
</blockquote>
<div>
</div>
<p>Load a file and begin conversion immediately, using your <code>ffe</code> default parameters then quit..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe run(ffe) E:\path\to\video.flv</code>
</div>
</blockquote>
<p>or..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe quit(ffe) E:\path\to\video.flv</code>
</div>
</blockquote>
<div>
</div>
<p>Load a group of avi files and generate an FFmpeg Windows batch script, using settings from the <code>x265 Simple</code> preset, then quit..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe generate(x265 Simple) E:\path\to\*.avi</code>
</div>
</blockquote>
<div>
</div>
<p>Load <em>multiple</em> presets on the command-line, process a folder of videos with the layered settings and quit..
</p>
<div>
</div>
<div> <code>C:\path\to\ffe.exe quit(setup|anim filters|tweaks) "E:\path\to some\video\*"</code>
</div>
<p>Note: When you layer presets, settings from later presets override settings from earlier presets. This facility has many uses. See below for more details.
</p>
<div>
</div>
<p>If you supply an input file path on the command-line, your output will be automatically filled with its converted counterpart, and if MATOF™ is enabled, the preset's parameters inserted into its name, ready-to-go.
</p>
<p>And by files, I also mean URLs. http/https and ftp are both fine. You can grab the first 100 frames of a movie online (or any number of frames from any part, though near the start makes sense), check it out, and then if it's what you want, download it. Or not.
</p>
<p>FFmpeg can handle lots of other internet protocols, too. Want to grab a chunk from a RTMP stream? (do any still exist?) Or grab a nice cool Icecast or pluck some Apple HTTP Live Stream? No problem! More details <a name="link-external-ffmpeg-protocols"></a><a href="https://www.ffmpeg.org/ffmpeg-protocols.html" title="it's FFmpeg doing the magic!">here</a>.
</p>
<p>URLs also work for output files; you could grab part of a movie stream and save it directly to a remote FTP server (ftp username and password in the usual format is supported). Quite <em>why</em> one would want to do this is uncertain, but there you have it; flexibility! Just like ffe..
</p>
<div>
</div>
<h3>Pre-Job, Post-File and Post-Job Commands..
</h3>
<p><strong>ffe</strong> has the facility to run tasks before (pre-job) and after (post-job) your ffmpeg job. It can also run tasks after each file processed (post-file), aka. "post-processing".
</p>
<p>The pre- and post-job tasks execute actual Windows batch files, which <strong>ffe</strong> will create automatically for you in your chosen location if you activate this feature. Their <em>locations</em> are stored inside your preset. These batch <code>(.bat</code>) files can be run internally, line-by-line, by ffe (where you can use <code>@tokens</code> and other goodies) or externally, through the Windows command interpreter (<code>cmd.exe</code>).
</p>
<p>These commands can be anything at all. You can move stuff around, delete, zip, unzip, run input and output files through other programs, whatever you need to do before and after a multimedia conversion job. To reduce time wasting and head scratching, enclose all paths and path <code>@tokens</code> in "quotes" inside your commands.
</p>
<p>If you are running lots of tests, a great pre-job command is..
</p>
<p> del /f /q "@outdir\*.*"
</p>
<p>Which would delete all your previous tests before you begin the next batch.
</p>
<p><strong>note</strong>: you can also right-click the output label to delete the most recently-created file(s).
</p>
<div>
</div>
<p>The Post-File (post-processing) command is one single command which is stored inside your preset. <strong>ffe</strong> executes this command (internally or externally, tracking or not, hidden or not) after each completed file (in a batch, this command will run multiple times).
</p>
<p>Generally you would want to use the <code>@outputfile</code> token in this command, to work on the file just created. But you don't need to. This command can be <em>any</em> valid command.
</p>
<div>
</div>
<p><strong>NOTE</strong>: Pre-Job, Post-Job and Post-File settings can all be saved inside presets, even the default preset. However, if you have any of these set (<code>enabled</code> or <code>disabled</code>; they have three states; <code>enabled</code>, <code>disabled</code> and <code>unset</code>) and you then load a preset with them <em><code>unset</code></em>, their state will <em>remain unchanged</em>. This is by design..
</p>
<p>You can load a preset with some commands setup, then another preset without any commands, then (perhaps after some tweaks) re-save the second preset, except now it has commands in it. All the job buttons work this way, remaining in their current state (the default) unless mindfully changed, either manually or via preset.
</p>
<p>You could conceivably create presets <em>solely</em> for loading pre- and post- commands, leaving that stuff completely out of your regular presets and loading only when required. Or, ignore all those buttons completely and they will never get in your way!
</p>
<div>
</div>
<p>The <code>[reset]</code> button resets all job buttons to <code>unset</code>.
</p>
<div>
</div> <a name="section-@tokens"></a>
<div>
</div> <a name="@tokens"></a>
<div>
</div>
<h2>@Tokens..
</h2>
<p>ffe accepts <code>@tokens</code> for most settings, parameters and inputs, even the extra parameters input, so you can do stuff like..
</p>
<p> -frames:v 50 -r 0.1 "@parent\@item_%04d.png"
</p>
<p>Or set your FFplay quick task button to something simple and useful, like..
</p>
<p> "@outputfile"
</p>
<p><code>@Tokens</code> are dynamically transformed at runtime. Here's what they transform <em>into</em>..
</p>
<div> Input/Output File @tokens.. @inputfile Full path of current input file. @item Basename of current input file, minus extension. @ext File extension of current input file. @outputfile Full path of current output file. @ofilename Basename of current output file. @oext File extension of current output file. Date &amp; Time @tokens.. @sec Seconds value of clock. Range is 00 to 59 @min Minutes value of clock. Range is 00 to 59 @hour Hours value of clock in 24-hour format. Range is 00 to 23 @mday Current day of month. Range is 01 to 31 @mon Current month. Range is 01 to 12 @year Current four-digit year @wday Numeric day of week. Range is 1 to 7 which corresponds to Sunday through Saturday. @yday Current day of year. Range is 001 to 365 (366 in a leap year) Dynamic Path @tokens.. @parent Parent directory of current input file @outdir Output Directory (wherever ffe is currently outputting files) @tempdir System Temp directory @datadir ffe data directory (in portable mode, it is the program folder) @desktop Current user's desktop folder @programfiles Your Program Files directory @appdir ffe program directory @homedir Current user's user directory, e.g. "C:\User\Fandango" @mydocuments Current user's "My Documents" directory. Special @tokens.. @arguments The current arguments to be fed to FFmpeg.
</div> <a name="section-Portable_Use"></a>
<div>
</div>
<h2>Portable Install..
</h2>
<p>If <strong>ffe</strong> finds an ini file next to itself, it switches to portable mode. In other words, if you want a portable installation, simply copy an <code>ffe.ini</code> file next to <code>ffe.exe</code>. You're done. Your <code>ffe.ini</code> is probably (Vista, Windows 7, 8, 10, 11, etc.) here..
</p>
<blockquote>
<div> <code>C:\Users\&lt;Username&gt;\AppData\Roaming\corz\ffe</code>
</div>
<p>
</p>
</blockquote>
<p>
</p>
<p>On older Windows most likely here..
</p>
<blockquote>
<div> <code>C:\Documents and Settings\&lt;Username&gt;\Application Data\corz\ffe</code>
</div>
</blockquote>
<p>If you are new to <strong>ffe</strong>, and want to <em>start</em> with a fresh portable install, do your first <a name="tip-instructions-run"></a><a title="Hit Win/Start+R, then drag in ffe.exe, then type ' portable' (no quotes) &lt;enter&gt;">run</a> using the special <code>portable</code> switch..
</p>
<blockquote>
<div> <code>C:\path\to\ffe.exe portable</code>
</div>
</blockquote>
<p>Which will create a fresh ini file right next to <strong>ffe</strong>, for instant portable operation. Or you can drag a fresh ini file next to ffe.exe yourself; there should be one inside the "Info" folder in the distribution.
</p>
<p>Drop your FFmpeg binary (<code>ffmpeg.exe</code>) in the same folder and you are good to go.
</p><a name="section-FAQ"></a>
<div>
</div>
<h2>FAQ..
</h2>
<p><strong>Q: I've changed a bunch of settings. I want to save this to my default "ffe" preset. How do I do this without first loading the default preset and obliterating the settings I just made?</strong>
</p>
<p><strong>A:</strong> Type or choose "ffe" (no quotes) into the presets drop-down and hit "Save".
</p>
<div>
</div>
<p><strong>Q: When I choose <code>MPEG4</code> for the video codec I get an <code>.mp4</code> file, but when I use <code>libx264</code> or <code>libx265</code> I get <code>.mkv</code>. What gives?</strong>
</p>
<p><strong>A:</strong> <code>.mkv</code> is set as your default fall-back extension and MATOF is enabled. If you want an <code>mp4</code> container, set <code>mp4</code> as your default extension. You can set it globally with the <code>{F2}</code> HotKey. You can also set this inside presets, if required (right-click the presets drop-down control for the menu option).
</p>
<p><strong>Note:</strong> THIS IS NOT RECOMMENDED! ffe handles extension mapping internally. If it doesn't recognise some format, let me know and I will add it. And maybe one day, create some kind of user preference for these mappings!
</p>
<p>ffe uses your chosen video codec to select the correct extension. Here is what they are currently..
</p>
<p> xvid,mjpeg =&gt; avi mpeg4 =&gt; mp4 mpeg,mpeg2 =&gt; mpg gif =&gt; gif flv,flash =&gt; flv msvideo,wmv =&gt; wmv vp,webp =&gt; webm
</p>
<p>All other video output will fall-back to your current default extension (normally <code>mkv</code>).
</p>
<p><em>Audio</em> extension mapping is currently..
</p>
<p> dca,dts =&gt; dts flac =&gt; flac gsm =&gt; gsm mp3 =&gt; mp3 mp2 =&gt; mp2 ac3 =&gt; ac3 aac =&gt; aac opus =&gt; opus real =&gt; ra tta =&gt; tta cook,Gecko,Real =&gt; ra vorbis =&gt; ogg wma =&gt; wma pcm =&gt; wav
</p>
<p>All other audio output will fall-back to your current default extension (normally <code>aac</code>).
</p>
<p>When simply extracting (plain copying) audio out of a video file, ffe will automatically interrogate the file for the <em>existing</em> codec before applying the extension mapping.
</p>
<p>By the way, if you see any errors or obvious omissions in the above lists, <em>please</em> <a name="mailerlink-37305"></a><a href="https://corz.org/corz/mail-me.php" title="Mail Me!">let me know about it!</a>
</p>
<div>
</div>
<p><strong>Q: Custom Buttons &amp; Presets.. What's the difference?</strong>
</p>
<p><strong>A:</strong> Think of the <strong>custom buttons</strong> as a place to keep "snippets". The sort of things you regularly add to ffmpeg commands, perhaps setting a CRF value or a favourite blur filter. Any small string that you might want to add to the output (or input) parameters.
</p>
<p>Custom buttons are designed to be <em>quick</em>. Click once to add the string, a second time to remove it. Ctrl+Click to add to input parameters. Shift-Click to edit or add buttons.
</p>
<div>
</div>
<p><strong>Presets</strong> contain <em>everything</em>. All the settings and switches and parameters, pre- and post-job commands, (optionally) input and output file paths; an entire work-flow. The entire <strong>ffe</strong> interface is setup from a preset, named "<strong>ffe</strong>". The default preset. Your retained exit settings are another preset, named "EXIT-SETTINGS". Make your own!
</p>
<p><strong>ffe</strong> is pretty flexible. You can load multiple presets on top of each other to combine layers of settings / parameters / pre- &amp; post- commands. Then tweak input and output parameters with snippets from your custom buttons.
</p>
<p>Then save the whole lot as a <em>second</em> preset for later access, via the command-line or from batch scripts or in the GUI; running jobs manually, or on a delay or even generating a Windows batch script for some other program or user or time. Flexibility underpins most of <strong>ffe</strong>'s design decisions. It aims to be part of the solution.
</p>
<div>
</div>
<p><strong>Q: I edited my help button and now when I press it nothing happens. Help!</strong>
</p>
<p><strong>A:</strong> It sounds like you have entered an invalid command and ffe, by design, does not display error output for help button comands (which would interfere with the help output).
</p>
<p>You can do a quick check of your command with the FFmpeg Quick Task button, which <em>does</em> show error output. Simply right-click on your FFmpeg quick task button [ffmpeg task], enter your experimental help command, then click [ffmpeg task]. All output will be displayed in your console.
</p><a name="section-Upgrading"></a>
<div>
</div>
<h2>Upgrading..
</h2>
<p>Replace your old <code>ffe.exe</code> with the new one. That's it.
</p><a name="section-Itstory"></a>
<div>
</div>
<h2>Itstory..
</h2>
<p><strong>ffe</strong>'s itstory is too lengthy to include here. If you want to know what's been changed, fixed, updated, broken, and so on, check out the <a href="Itstory.txt" title="ffe - Itstory.txt ">itstory</a>
</p><a name="section-Quick_Start"></a>
<div>
</div> <a name="quickstart-ffe"></a>
<h2>Quick Start..
</h2>
<p>There's a short, quick-start type guide, <a name="link-internal-ffe-quickstart-go"></a><a href="Resources/QuickStart.txt" title="ffe quickstart guide in plain text">here</a>.
</p>
<div>
</div>
</div>

## While I try to keep this Git repo up-to-date, the latest source can always be found [here](https://corz.org/windows/software/ffe/)
