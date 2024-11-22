package a2.time.states.editors;

import a2.time.objects.song.Song;
import a2.time.objects.song.Song.SongMetadata;
import a2.time.util.Discord.DiscordClient;
import a2.time.util.UIShortcuts as UiS;

import flash.geom.Rectangle;
import haxe.Json;
import haxe.format.JsonParser;
import haxe.io.Bytes;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxInputText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.ByteArray;
import openfl.Lib;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;

import a2.time.objects.ui.AttachedSprite;
import a2.time.objects.song.Conductor;
import a2.time.objects.song.Conductor.BPMChangeEvent;
import a2.time.objects.song.Section.SongSection;
import a2.time.objects.song.Song;
import a2.time.objects.song.Song.SwagSong;
import a2.time.objects.gameplay.StrumNote;
import a2.time.objects.song.StageData;
import a2.time.objects.gameplay.Character;
import a2.time.objects.gameplay.Note;
import a2.time.objects.gameplay.Note.CustomNoteFile;
import a2.time.objects.gameplay.Note.NoteFile;
import a2.time.objects.gameplay.HealthIcon;
import a2.time.util.CoolUtil;
import a2.time.Paths;

import flixel.util.typeLimit.OneOfTwo;

import haxe.ui.core.Screen;

import Type;

using StringTools;
using Lambda; // gordon freeman

#if sys
import flash.media.Sound;
import sys.FileSystem;
import sys.io.File;
#end

typedef NoteCopyPayload =
{
	var events:Array<EventNote>;
	var chars:Map<String, Array<NoteFile>>;
}

@:access(flixel.system.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class ChartingState extends MusicBeatState
{
	public static var instance:ChartingState;

	public static var noteTypeDataBase:Array<CustomNoteFile> =
	[
		{name: '', desc: 'The default note.', texture: ''},
		{name: 'No Animation', desc: 'When hit, no animation is played.', texture: ''}
	];

	public static var HARDCODED_NOTES:Array<String> = ['', 'No Animation'];

	var formattedDifficulties:Map<String, String> = 
	[
		'easy' => 'Easy',
		'' => 'Normal',
		'hard' => 'Hard'
	];

	var ALERT_STRING:String = 'A / D: Change current section\n
W / S: Scroll time
CTRL scrolls more precisely, SHIFT scrolls faster\n
J / L: Change current character\n
E / Q: Change selected note sustain length\n
SPACE: Play / pause song\n
Z / X: Zoom in and out\n
LEFT / RIGHT: Change beat snap\n
BACKSPACE / ESCAPE: Leave editor\n
Click on notes to select them, right click to delete them\n
ENTER: Play song\n
If you have any questions about the editor, ask me!';

	var currentType:String = '';

	private var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
	private var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();
	public var ignoreWarnings = false;
	var eventStuff:Map<String, String> =
	[
		'' => "Nothing. Yep, that's right.",
		'Hey!' => "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s",
		'Set GF Speed' => "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!",
		'Add Camera Zoom' => "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default.",
		'Play Animation' => "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)",
		'Camera Follow Pos' => "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank.",
		'Alt Idle Animation' => "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)",
		'Screen Shake' => "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity.",
		'Change Scroll Speed' => "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds.",
		'Set Property' => "Value 1: Variable name\nValue 2: New value",
		'Set Anim Suffix' => "Sets suffix for each animation this character plays.\n\nValue 1: Character Name\nValue 2: Animation Suffix\nExample: bf, jacket\n\nThe '-' is automatically added so don't worry about putting it there.",
		'Set Icon Suffix' => "Sets suffix for the icon of the character.\n\nValue 1: Character Name\nValue 2: Icon Suffix\nExample: bf, evil\n\nThe '-' is automatically added so don't worry about putting it there.",
		'Load Rim Light File' => 'Loads Rim Light File with the postfix set (don\'t include the "-")\nExample: "evil" loads "shade-evil.json"\n\nValue 1: Postfix to load'
	];

	public static var HARDCODED_EVENTS:Array<String> = ['', 'Hey!', 'Set GF Speed', 'Add Camera Zoom', 'Play Animation', 'Camera Follow Pos', 'Alt Idle Animation', 'Screen Shake', 'Change Scroll Speed', 'Set Property', 'Setting Crossfades', 'Set Anim Suffix', 'Set Icon Suffix', 'Load RTX File'];

	public static var goToPlayState:Bool = false;
	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;
	public static var lastSection:Int = 0;
	private static var lastSong:String = '';

	var secText:FlxText;
	var beatText:FlxText;
	var stepText:FlxText;
	var quantText:FlxText;

	var secLabel:FlxText;
	var beatLabel:FlxText;
	var stepLabel:FlxText;
	var quantLabel:FlxText;

	var timeText:FlxText;
	var curSongText:FlxText;

	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:a2.time.objects.ui.AttachedSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var curSong:String = 'Test';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var noteDisplayNameList:Array<String> = [];

	var highlight:FlxSprite;

	public static var GRID_SIZE:Int = 55;
	var CAM_OFFSET:Int = 360;

	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxText>;

	var otherRenderedSustains:FlxTypedGroup<FlxSprite>;
	var otherRenderedNotes:FlxTypedGroup<Note>;
	var otherRenderedIcons:FlxTypedGroup<HealthIcon>;

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var gridBorder:FlxSprite;
	var nextGridBorder:FlxSprite;

	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;

	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var _song:SwagSong;

	var selectedNote:Note = null;
	var selectedNoteReference:OneOfTwo<NoteFile, Array<EventNote>> = null; // OneOfTwo MENTIONED!
	var selectedEventIndex:Int = 0;

	var noteReference(get, never):NoteFile;
	function get_noteReference():NoteFile
	{
		if (!selectingNote)
			return null;

		return cast selectedNoteReference;
	}

	var eventReference(get, never):Array<EventNote>;
	function get_eventReference():Array<EventNote>
	{
		if (!selectingEvent)
			return null;

		return cast selectedNoteReference;
	}

	var selectingNote(get, never):Bool;
	function get_selectingNote():Bool
	{
		if (selectedNoteReference == null)
			return false;

		return Reflect.hasField(selectedNoteReference, 'ms');
	}

	var selectingEvent(get, never):Bool;
	function get_selectingEvent():Bool
	{
		if (selectedNoteReference == null)
			return false;

		switch(Type.typeof(selectedNoteReference))
		{
			case TClass(Array):
				return true;

			case _:
				return false;
		}
	}

	var playbackSpeed:Float = 1;

	var vocals:FlxSound = null;
	var inst:FlxSound = null;

	var icon:HealthIcon;

	var charIndicator:HealthIcon;
	var indicator_isPlayer:FlxSprite;
	var indicator_hasFocus:FlxSprite;

	var focusTimer:FlxTimer;
	var eyeOpened:Bool = false;

	function openEye()
	{
		indicator_hasFocus.animation.play('toggle', true, true);

		if (focusTimer != null)
		{
			focusTimer.cancel();
			focusTimer.start(0.2, (timer:FlxTimer)->
			{
				indicator_hasFocus.animation.play('idle', true);
			});
		}

		eyeOpened = true;
	}

	function closeEye()
	{
		focusTimer.cancel();

		indicator_hasFocus.animation.play('toggle', true, false);
		eyeOpened = false;
	}

	var currentSongName:String;

	var zoomTxt:FlxText;

	var zoomList:Array<Float> = [
		0.25,
		0.5,
		1,
		2,
		3,
		4,
		6,
		8,
		12,
		16,
		24
	];
	var curZoom:Int = 2;

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	public var quantizations:Array<Int> = [
		4,
		8,
		12,
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];

	var ALERT_TITLE_STRING:String = 'FNF: TIME Chart Editor';

	private var characterList:Array<String> = [];
	private var charsAndNames:Map<String, Character> = new Map();
	private var hitsoundShit:Array<Bool> = [];
	private var noteOpacityShit:Array<Float> = [];

	private var curCharIndex:Int = 0;

	var lastData:Dynamic;

	// HAXE UI
	var haxeUIBox:haxe.ui.containers.TabView = null;

	var songTab:haxe.ui.containers.Box = null;
	var sectionTab:haxe.ui.containers.Box = null;
	var noteTab:haxe.ui.containers.Box = null;
	var eventsTab:haxe.ui.containers.Box = null;
	var chartingTab:haxe.ui.containers.Box = null;
	var characterTab:haxe.ui.containers.Box = null;
	var metaTab:haxe.ui.containers.Box = null;
	var editorTab:haxe.ui.containers.Box = null;
	var createTab:haxe.ui.containers.Box = null;
	//

	var autoLoadData = 
	{
		song: '',
		difficulty: '',
		doIt: false
	}

	override public function new(songToLoad:String = '', dif:String = 'normal')
	{
		super();
		
		if (songToLoad != '')
		{
			autoLoadData.song = songToLoad;
			autoLoadData.difficulty = dif;
			autoLoadData.doIt = true;
		}
		else
		{
			autoLoadData.song = '';
			autoLoadData.difficulty = '';
			autoLoadData.doIt = false;
		}
	}

	var text:String = "";
	public static var vortex:Bool = false;
	public var mouseQuant:Bool = false;
	override function create()
	{
		instance = this;

		lastData = 
		{
			section: 0,
			beat: 0,
			step: 0,
			quant: quantization
		};

		// convert the chart and automatically save it!
		if (autoLoadData.doIt)
		{
			loadJson(autoLoadData.song);
			return;
		}

		if (PlayState.SONG != null)
		{
			_song = PlayState.SONG;
			trace('current song ${_song.song}');
		}
		else
		{
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

			_song = cast Song.loadFromJson('test');

			addSection();
			PlayState.SONG = _song;
		}

		for (seg in [_song.players, _song.opponents])
			for (guy in seg)
			{
				trace('adding guy: "$guy"');
				characterList.push(guy);

				hitsoundShit.push(false);
				noteOpacityShit.push(0.3);
			}

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence('Chart Editor');
		#end

		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);

		var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE + 20, -110).loadGraphic(Paths.image('eventArrow'));
		icon = new HealthIcon('bf');
		eventIcon.scrollFactor.set(1, 1);
		icon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(40, 40);
		icon.setGraphicSize(0, 75);

		add(eventIcon);
		add(icon);

		icon.setPosition(GRID_SIZE + GRID_SIZE / 2 + 5, -120);

		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxText>();

		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		otherRenderedSustains = new FlxTypedGroup<FlxSprite>();
		otherRenderedNotes = new FlxTypedGroup<Note>();
		otherRenderedIcons = new FlxTypedGroup<HealthIcon>();

		if(curSec >= _song.sections.length) curSec = _song.sections.length - 1;

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 5), 4);
		add(strumLine);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		for (i in 0...4)
		{
			var note:StrumNote = new StrumNote(GRID_SIZE * (i + 1), strumLine.y, i, 0);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		add(strumLineNotes);

		addSection();

		currentSongName = _song.song;
		loadSong();
		reloadGridLayer();
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		var SPACE_BETWEEN_TEXT:Int = 30;
		var TEXT_X:Int = 565;

		curSongText = new FlxText(TEXT_X, FlxG.height, 0, '${_song.song} (${formattedDifficulties[PlayState.difficulty]})', 16);
		curSongText.scrollFactor.set();
		curSongText.y -= curSongText.height + 10;
		add(curSongText);

		timeText = new FlxText(TEXT_X, curSongText.y - SPACE_BETWEEN_TEXT, 0, '', 16);
		timeText.scrollFactor.set();
		add(timeText);

		var f1Text = new FlxText(FlxG.width - 5, FlxG.height - 5, -1, 'Press "F1" for help', 16);
		f1Text.scrollFactor.set();
		f1Text.alignment = 'right';
		f1Text.x -= f1Text.width;
		f1Text.y -= f1Text.height;
		add(f1Text);

		stepLabel = new FlxText(TEXT_X, timeText.y - SPACE_BETWEEN_TEXT, 0, 'Step: ', 16);
		stepLabel.scrollFactor.set();
		stepText = new FlxText(stepLabel.x + stepLabel.width, stepLabel.y, 0, '', 16);
		stepText.scrollFactor.set();
		add(stepLabel);
		add(stepText);

		stepText.origin.set(0, stepText.height / 2);

		beatLabel = new FlxText(TEXT_X, stepLabel.y - SPACE_BETWEEN_TEXT, 0, 'Beat: ', 16);
		beatLabel.scrollFactor.set();
		beatText = new FlxText(beatLabel.x + beatLabel.width, beatLabel.y, 0, '', 16);
		beatText.scrollFactor.set();
		add(beatLabel);
		add(beatText);

		beatText.origin.set(0, beatText.height / 2);

		secLabel = new FlxText(TEXT_X, beatLabel.y - SPACE_BETWEEN_TEXT, 0, 'Section: ', 16);
		secLabel.scrollFactor.set();
		secText = new FlxText(secLabel.x + secLabel.width, secLabel.y, 0, '', 16);
		secText.scrollFactor.set();
		add(secLabel);
		add(secText);

		secText.origin.set(0, secText.height / 2);

		quantLabel = new FlxText(TEXT_X, secLabel.y - SPACE_BETWEEN_TEXT * 2, 0, 'Beat Snap: ', 16);
		quantLabel.scrollFactor.set();
		quantText = new FlxText(quantLabel.x + quantLabel.width, quantLabel.y, 0, '', 16);
		quantText.scrollFactor.set();
		add(quantLabel);
		add(quantText);

		quantText.origin.set(0, quantText.height / 2);

		charIndicator = new HealthIcon(characterList[curCharIndex]);
		charIndicator.scale.set(1.5, 1.5);
		charIndicator.setPosition(10, FlxG.height - charIndicator.height - 10);
		charIndicator.scrollFactor.set();
		add(charIndicator);

		indicator_isPlayer = new FlxSprite(charIndicator.x + 170, charIndicator.y);
		indicator_isPlayer.frames = Paths.getSparrowAtlas('playerIndicator');
		indicator_isPlayer.animation.addByPrefix('player', 'player', 1, true);
		indicator_isPlayer.animation.addByPrefix('opponent', 'opponent', 1, true);
		indicator_isPlayer.scale.set(0.5, 0.5);
		indicator_isPlayer.updateHitbox();
		indicator_isPlayer.scrollFactor.set();
		indicator_isPlayer.antialiasing = true;
		add(indicator_isPlayer);

		indicator_hasFocus = new FlxSprite(indicator_isPlayer.x - 5, indicator_isPlayer.y + 80);
		indicator_hasFocus.frames = Paths.getSparrowAtlas('charFocus');
		indicator_hasFocus.animation.addByPrefix('idle', 'idle', 2, true);
		indicator_hasFocus.animation.addByPrefix('toggle', 'toggle', 8, false);
		indicator_hasFocus.scale.set(0.4, 0.4);
		indicator_hasFocus.updateHitbox();
		indicator_hasFocus.scrollFactor.set();
		indicator_hasFocus.antialiasing = true;
		add(indicator_hasFocus);

		focusTimer = new FlxTimer();

		if (_song.sections[curSec].charFocus == curCharIndex)
			openEye();
		else
			closeEye();

		quant = new AttachedSprite(Paths.image('chart_quant'), Paths.file('images/chart_quant.xml'));
		quant.animation.addByPrefix('q','chart_quant',0,false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		add(otherRenderedSustains);
		add(otherRenderedNotes);
		add(otherRenderedIcons);

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		if(lastSong != currentSongName)
			changeSection();
		
		lastSong = currentSongName;

		zoomTxt = new FlxText(10, 10, 0, "Zoom: 1 / 1", 16);
		zoomTxt.scrollFactor.set();
		add(zoomTxt);

		updateGrid();
		super.create();

		var mainView = new haxe.ui.containers.HBox();

		haxeUIBox = new haxe.ui.containers.TabView();
		haxeUIBox.closable = false;
		haxeUIBox.width = 400;
		haxeUIBox.height = 635;

		editorTab = new haxe.ui.containers.Box();
		editorTab.text = 'Editor';

		metaTab = new haxe.ui.containers.Box();
		metaTab.text = 'Metadata';

		songTab = new haxe.ui.containers.Box();
		songTab.text = 'Song';

		sectionTab = new haxe.ui.containers.Box();
		sectionTab.text = 'Section';

		noteTab = new haxe.ui.containers.Box();
		noteTab.text = 'Note';

		eventsTab = new haxe.ui.containers.Box();
		eventsTab.text = 'Events';

		chartingTab = new haxe.ui.containers.Box();
		chartingTab.text = 'Charting';

		characterTab = new haxe.ui.containers.Box();
		characterTab.text = 'Character';

		createTab = new haxe.ui.containers.Box();
		createTab.text = 'Create';

		haxeUIBox.addComponent(characterTab);
		haxeUIBox.addComponent(eventsTab);
		haxeUIBox.addComponent(noteTab);
		haxeUIBox.addComponent(sectionTab);
		haxeUIBox.addComponent(chartingTab);
		haxeUIBox.addComponent(songTab);
		haxeUIBox.addComponent(metaTab);
		haxeUIBox.addComponent(createTab);
		haxeUIBox.addComponent(editorTab);

		setupNotetypeDatabase();

		addCharacterHaxeUI();
		addChartingHaxeUI();
		addEventsHaxeUI();
		addNoteHaxeUI();
		addSectionHaxeUI();
		addSongHaxeUI();
		addEditorHaxeUI();
		addMetaHaxeUI();
		addCreateHaxeUI();

		haxeUIBox.selectedPage = songTab;

		updateHeads();
		updateWaveform();
		
		UiS.addSpacer(785, 0, mainView);

		var piss = new haxe.ui.containers.VBox();
		UiS.addSpacer(0, 25, piss);
		piss.addComponent(haxeUIBox);

		mainView.addComponent(piss);

		uiLayer.addComponent(mainView);

		haxe.ui.Toolkit.styleSheet.buildStyleFor(haxeUIBox);

		Screen.instance.addComponent(getQuickCharacterHaxeUI());

		FlxG.camera.follow(camPos);

		updateGrid();
	}

	override function onFocusLost()
	{
		pauseSong();
	}

	override function onFocus()
	{
		pauseSong();
	}

	function pauseSong()
	{
		FlxG.sound.music.pause();
		if(vocals != null) vocals.pause();
	}

	function setupNotetypeDatabase()
	{
		Paths.VERBOSE = false;

		var key:Int = 0;
		while (key < noteTypeDataBase.length) 
		{
			noteDisplayNameList.push(noteTypeDataBase[key].name);
			noteTypeMap.set(noteTypeDataBase[key].name, key);
			noteTypeIntMap.set(key, noteTypeDataBase[key].name);
			key++;
		}

		var mods:Array<String> = [];
		for (mod in Paths.getModDirectories())
			if (Paths.mods('custom_notetypes', mod) != null)
				mods.push(mod);

		for (mod in mods)
			for (file in FileSystem.readDirectory(Paths.mods('custom_notetypes', mod)))
			{
				var check = Paths.noteJson(file.split('.json')[0], mod);
				if (check == null)
					continue;

				var fileToCheck:CustomNoteFile = cast haxe.Json.parse(File.getContent(check));
				if (noteDisplayNameList.contains(fileToCheck.name))
					continue;

				noteDisplayNameList.push(fileToCheck.name);
				noteTypeMap.set(fileToCheck.name, key);
				noteTypeIntMap.set(key, fileToCheck.name);
				noteTypeDataBase.push(fileToCheck);
				
				key++;
			}

		Paths.VERBOSE = true;
	}

	function getQuickCharacterHaxeUI()
	{
		var formatBox = new haxe.ui.containers.VBox();
		var push = new haxe.ui.containers.HBox();

		UiS.addSpacer(0, 490, formatBox);

		var setFocus = new haxe.ui.components.Button();
		setFocus.text = 'Set Focus Here';
		setFocus.percentWidth = 100;
		setFocus.onClick = (e) ->
		{
			_song.sections[curSec].charFocus = curCharIndex;

			updateSectionUI();
			
			updateGrid();
			updateHeads();
		}
		formatBox.addComponent(setFocus);

		var charBox = new haxe.ui.containers.HBox();

		var charLeft = new haxe.ui.components.Button();
		charLeft.text = '<';
		charLeft.height = 35;
		charLeft.width = 35;
		charLeft.onClick = (e) ->
		{
			changeChar(-1);
		}
		charBox.addComponent(charLeft);

		UiS.addSpacer(7, 0, charBox);

		var charRight = new haxe.ui.components.Button();
		charRight.text = '>';
		charRight.height = 35;
		charRight.width = 35;
		charRight.onClick = (e) ->
		{
			changeChar(1);
		}
		charBox.addComponent(charRight);

		formatBox.addComponent(charBox);

		UiS.addSpacer(35, 0, push);
		push.addComponent(formatBox);

		return push;
	}

	// BMM BMM ahahahahaha haha BMM
	// why so serious?
	function getCurrentModCharacters()
	{
		Paths.VERBOSE = false;

		var mods:Array<String> = [Main.MOD_NAME];
		for (mod in Paths.getModDirectories())
			if (Paths.mods('characters', mod) != null)
				mods.push(mod);

		var characters:Array<String> = [];
		var tempMap:Map<String, Bool> = new Map<String, Bool>();

		for (mod in mods)
			for (char in FileSystem.readDirectory(Paths.mods('characters', mod)))
				if (FileSystem.exists('${Paths.charFolder(char, mod)}/character.json'))
					if (!tempMap.exists(char))
					{
						tempMap.set(char, true);
						characters.push(char);
					}

		Paths.VERBOSE = true;

		return characters;
	}

	function addCreateHaxeUI()
	{
		var formatBox = new haxe.ui.containers.VBox();

		UiS.addHeader('Create new song', formatBox);

		var createSongName = new haxe.ui.components.TextField();
		createSongName.placeholder = 'Song Name...';
		createSongName.width = 200;

		formatBox.addComponent(createSongName);
		UiS.addHR(7, formatBox);

		var oggBox = new haxe.ui.containers.HBox();

		var createInstLabel = new haxe.ui.components.Label();
		createInstLabel.text = 'No instrumental file loaded';

		var createVocLabel = new haxe.ui.components.Label();
		createVocLabel.text = 'No vocal file loaded';

		var extData = [{label: 'OGG File', extension: 'ogg'}];
		var instFile:Dynamic = null;
		var vocFile:Dynamic = null;

		var createInstButton = new haxe.ui.components.Button();
		createInstButton.text = 'Open instrumental file';
		createInstButton.width = 100;
		createInstButton.height = 100;
		createInstButton.onClick = function(e)
		{
			haxe.ui.containers.dialogs.Dialogs.openFile(function(button, files)
			{
				if (files == null || files == [])
					return;

				instFile = files[0];
				createInstLabel.text = 'Loaded instrumental "${instFile.name}"';

			}, {multiple: false, extensions: extData});
		}
		oggBox.addComponent(createInstButton);

		var createVocButton = new haxe.ui.components.Button();
		createVocButton.text = 'Open vocal file';
		createVocButton.width = 100;
		createVocButton.height = 100;
		createVocButton.onClick = function(e)
		{
			haxe.ui.containers.dialogs.Dialogs.openFile(function(button, files)
			{
				if (files == null || files == [])
					return;

				vocFile = files[0];
				createVocLabel.text = 'Loaded voices "${vocFile.name}"';

			}, {multiple: false, extensions: extData});
		}
		oggBox.addComponent(createVocButton);

		formatBox.addComponent(oggBox);

		formatBox.addComponent(createInstLabel);
		formatBox.addComponent(createVocLabel);

		UiS.addHR(7, formatBox);

		var createLoadSong = new haxe.ui.components.CheckBox();
		createLoadSong.text = 'Load song after creation?';
		createLoadSong.selected = true;

		formatBox.addComponent(createLoadSong);
		UiS.addHR(7, formatBox);

		UiS.addLabel('Working Mod Directory: "${Paths.WORKING_MOD_DIRECTORY}"', formatBox);

		var createNewSong = new haxe.ui.components.Button();
		createNewSong.text = 'Create';
		createNewSong.onClick = function(e)
		{
			if (instFile == null)
			{
				Lib.application.window.alert('No instrumental file loaded.\nPlease open one by clicking the "open instrumental file" button.', ALERT_TITLE_STRING);
				return;
			}

			var name = createSongName.text;

			if (Paths.mods('songs', Paths.WORKING_MOD_DIRECTORY) == null)
				FileSystem.createDirectory('mods/${Paths.WORKING_MOD_DIRECTORY}/songs');

			var checkSong = Paths.songFolder(name, Paths.WORKING_MOD_DIRECTORY);

			if (checkSong != null)
			{
				Lib.application.window.alert('Song "$name" song folder already exists, please finish adding it manually.', ALERT_TITLE_STRING);
				return;
			}

			var songPath = '${Paths.mods('songs', Paths.WORKING_MOD_DIRECTORY)}/$name';

			FileSystem.createDirectory(songPath);

			File.copy(instFile.fullPath, '$songPath/inst.ogg');

			if (vocFile != null)
				File.copy(vocFile.fullPath, '$songPath/voices.ogg');

			var dummyMetadata:SongMetadata = 
			{
				musicians: [''],
				voiceActors: [''],
				charters: [''],
				programmers: [''],
				additionalArtists: [''],
				additionalAnimators: ['']
			}

			var dummySection:SongSection =
			{
				sectionBeats: 4,

				bpm: 140,
				changeBPM: false,

				charFocus: 0
			}

			var dummySong:SwagSong = 
			{
				song: name,
				stage: 'stage',

				metadata: dummyMetadata,

				sections: [dummySection],
				notes: ['easy' => ['bf' => [], 'dad' => []], 'normal' => ['bf' => [], 'dad' => []], 'hard' => ['bf' => [], 'dad' => []]],

				events: [],

				bpm: 140,
				speed: 2.5,

				needsVoices: vocFile != null,

				players: ['bf'],
				opponents: ['dad'],
				autoGF: 'gf',

				countdownType: 'normal',

				validScore: false
			};

			var dummyData:String = Json.stringify(dummySong, "\t");
			if ((dummyData != null) && (dummyData.length > 0))
				File.saveContent('$songPath/$name.json', dummyData);

			Lib.application.window.alert('Created new song "$name"!\n"$songPath/$name', ALERT_TITLE_STRING);

			if (createLoadSong.selected)
				loadJson(name);
		}

		formatBox.addComponent(createNewSong);

		createTab.addComponent(formatBox);
	}

	var musiciansTextField:haxe.ui.components.TextField;
	var voiceActorsTextField:haxe.ui.components.TextField;
	var chartersTextField:haxe.ui.components.TextField;
	var programmersTextField:haxe.ui.components.TextField;
	var additionalArtistsTextField:haxe.ui.components.TextField;
	var additionalAnimatorsTextField:haxe.ui.components.TextField;
	function addMetaHaxeUI()
	{
		var formatBox = new haxe.ui.containers.VBox();

		var placeholderMeta:SongMetadata =
		{
			musicians: [],
			voiceActors: [],
			charters: [],
			programmers: [],
			additionalArtists: [],
			additionalAnimators: []
		}

		if (_song.metadata != null)
		{
			placeholderMeta.musicians = _song.metadata.musicians;
			placeholderMeta.voiceActors = _song.metadata.voiceActors;
			placeholderMeta.charters = _song.metadata.charters;
			placeholderMeta.programmers = _song.metadata.programmers;
			placeholderMeta.additionalArtists = _song.metadata.additionalArtists;
			placeholderMeta.additionalAnimators = _song.metadata.additionalAnimators;
		}

		var label = new haxe.ui.components.Label();
		label.text = 'Musicians';

		formatBox.addComponent(label);

		var musString:String = '';
		var list:Array<String> = placeholderMeta.musicians;
		for (mus in list)
			musString += '${mus},';

		musiciansTextField = new haxe.ui.components.TextField();
		musiciansTextField.text = musString.substring(0, musString.length - 1);
		musiciansTextField.width = 200;

		formatBox.addComponent(musiciansTextField);

		//
		UiS.addSpacer(0, 25, formatBox);

		var label = new haxe.ui.components.Label();
		label.text = 'Voice Actors';

		formatBox.addComponent(label);

		var vaString:String = '';
		var list:Array<String> = placeholderMeta.voiceActors;
		for (va in list)
			vaString += '${va},';

		voiceActorsTextField = new haxe.ui.components.TextField();
		voiceActorsTextField.text = vaString.substring(0, vaString.length - 1);
		voiceActorsTextField.width = 200;

		formatBox.addComponent(voiceActorsTextField);

		//
		UiS.addSpacer(0, 25, formatBox);

		var label = new haxe.ui.components.Label();
		label.text = 'Charters';

		formatBox.addComponent(label);

		var chartString:String = '';
		var list:Array<String> = placeholderMeta.charters;
		for (chart in list)
			chartString += '${chart},';

		chartersTextField = new haxe.ui.components.TextField();
		chartersTextField.text = chartString.substring(0, chartString.length - 1);
		chartersTextField.width = 200;

		formatBox.addComponent(chartersTextField);

		//
		UiS.addSpacer(0, 25, formatBox);

		var label = new haxe.ui.components.Label();
		label.text = 'Programmers';

		formatBox.addComponent(label);

		// progesterone string...
		var progString:String = '';
		var list:Array<String> = placeholderMeta.programmers;
		for (prog in list)
			progString += '${prog},';

		programmersTextField = new haxe.ui.components.TextField();
		programmersTextField.text = progString.substring(0, progString.length - 1);
		programmersTextField.width = 200;

		formatBox.addComponent(programmersTextField);

		//
		UiS.addSpacer(0, 25, formatBox);

		var label = new haxe.ui.components.Label();
		label.text = 'Additional Artists';

		formatBox.addComponent(label);

		var artString:String = '';
		var list:Array<String> = placeholderMeta.additionalArtists;
		for (art in list)
			artString += '${art},';

		additionalArtistsTextField = new haxe.ui.components.TextField();
		additionalArtistsTextField.text = artString.substring(0, artString.length - 1);
		additionalArtistsTextField.width = 200;

		formatBox.addComponent(additionalArtistsTextField);

		//
		UiS.addSpacer(0, 25, formatBox);

		var label = new haxe.ui.components.Label();
		label.text = 'Additional Animators';

		formatBox.addComponent(label);

		var animString:String = '';
		var list:Array<String> = placeholderMeta.additionalAnimators;
		for (anim in list)
			animString += '${anim},';

		additionalAnimatorsTextField = new haxe.ui.components.TextField();
		additionalAnimatorsTextField.text = animString.substring(0, animString.length - 1);
		additionalAnimatorsTextField.width = 200;

		formatBox.addComponent(additionalAnimatorsTextField);

		//

		metaTab.addComponent(formatBox);
	}

	var editorGridCol1:haxe.ui.components.ColorPicker;
	var editorGridCol2:haxe.ui.components.ColorPicker;
	var editorWaveformCol:haxe.ui.components.ColorPicker;
	function addEditorHaxeUI()
	{
		if (FlxG.save.data.chart_gridCol1 == null) FlxG.save.data.chart_gridCol1 = FlxColor.fromInt(0xffe7e6e6);
		if (FlxG.save.data.chart_gridCol2 == null) FlxG.save.data.chart_gridCol2 = FlxColor.fromInt(0xffd9d5d5);
		if (FlxG.save.data.chart_waveformCol == null) FlxG.save.data.chart_waveformCol = FlxColor.BLUE;

		var initialized:Dynamic = 
		{
			col1: false,
			col2: false,
			waveform: false
		}

		var formatBox = new haxe.ui.containers.VBox();

		UiS.addHeader('Grid Colours', formatBox);

		var gridBox = new haxe.ui.containers.HBox();
		editorGridCol1 = new haxe.ui.components.ColorPicker();
		editorGridCol1.onChange = (e) ->
		{ 
			if (!initialized.col1)
			{
				FlxTimer.wait(0.05, ()-> { editorGridCol1.currentColor = FlxG.save.data.chart_gridCol1; });

				initialized.col1 = true;
				return;
			}

			FlxG.save.data.chart_gridCol1 = editorGridCol1.currentColor;
			reloadGridLayer();
		}
		editorGridCol1.height = 190;
		editorGridCol1.width = 190;
		editorGridCol1.styleNames = 'no-controls';

		editorGridCol2 = new haxe.ui.components.ColorPicker();
		editorGridCol2.onChange = (e) -> 
		{ 
			if (!initialized.col2)
			{
				FlxTimer.wait(0.05, ()-> { editorGridCol2.currentColor = FlxG.save.data.chart_gridCol2; });

				initialized.col2 = true;
				return;
			}

			FlxG.save.data.chart_gridCol2 = editorGridCol2.currentColor; 
			reloadGridLayer();
		}
		editorGridCol2.height = 190;
		editorGridCol2.width = 190;
		editorGridCol2.styleNames = 'no-controls';

		gridBox.addComponent(editorGridCol1);
		gridBox.addComponent(editorGridCol2);

		formatBox.addComponent(gridBox);
		UiS.addSpacer(0, 25, formatBox);

		UiS.addHeader('Waveform Colour', formatBox);

		editorWaveformCol = new haxe.ui.components.ColorPicker();
		editorWaveformCol.onChange = (e) -> 
		{ 
			if (!initialized.waveform)
			{
				FlxTimer.wait(0.05, ()-> { editorWaveformCol.currentColor = FlxG.save.data.chart_waveformCol; });

				initialized.waveform = true;
				return;
			}

			FlxG.save.data.chart_waveformCol = editorWaveformCol.currentColor; 
			reloadGridLayer();
		}
		editorWaveformCol.height = 190;
		editorWaveformCol.width = 190;
		editorWaveformCol.styleNames = 'no-controls';

		formatBox.addComponent(editorWaveformCol);

		editorTab.addComponent(formatBox);
	}

	var charSelectDropDown:haxe.ui.components.DropDown;
	var charIsPlayerCheck:haxe.ui.components.CheckBox;
	var charHitsoundsCheck:haxe.ui.components.CheckBox;
	var noteGhostSlider:haxe.ui.components.HorizontalSlider;
	var removeCharButton:haxe.ui.components.Button;
	function addCharacterHaxeUI()
	{
		var formatBox = new haxe.ui.containers.VBox();

		//
		var charBox = new haxe.ui.containers.VBox();

		UiS.addLabel('Character:', charBox);

		var characters = getCurrentModCharacters();
		var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
		var filteredCharacters = [];
		for (char in characters)
			if (!characterList.contains(char) || char == characterList[curCharIndex])
			{
				dataSource.add({text: char});
				filteredCharacters.push(char);
			}

		var curCharString:String = characterList[curCharIndex];

		charSelectDropDown = new haxe.ui.components.DropDown();
		charSelectDropDown.searchable = true;
		charSelectDropDown.searchPrompt = 'Find Character';
		charSelectDropDown.width = 150;
		charSelectDropDown.dataSource = dataSource;
		charSelectDropDown.selectedIndex = filteredCharacters.indexOf(characterList[curCharIndex]);
		charSelectDropDown.onChange = (e) ->
		{
			var prevChar:String = characterList[curCharIndex];

			if (charSelectDropDown.selectedItem == null)
				return;

			var character:String = charSelectDropDown.selectedItem.text;

			if (prevChar == character)
				return;
			
			trace('$prevChar => $character');

			if (charIsPlayerCheck.selected)
				_song.players[_song.players.indexOf(prevChar)] = character;
			else
				_song.opponents[_song.opponents.indexOf(prevChar)] = character;

			for (dif in _song.notes)
			{
				dif.set(character, dif[prevChar]);
				dif.remove(prevChar);
			}

			characterList[curCharIndex] = character;

			updateCharacterUI();
		}

		charBox.addComponent(charSelectDropDown);

		formatBox.addComponent(charBox);
		//

		UiS.addHR(7, formatBox);

		//
		charIsPlayerCheck = new haxe.ui.components.CheckBox();
		charIsPlayerCheck.selected = _song.players.contains(curCharString);
		charIsPlayerCheck.text = 'Is Player?';
		charIsPlayerCheck.onClick = function(e) 
		{ 
			var curChar = characterList[curCharIndex];

			var oldCharList = [];
			for (char in characterList)
				oldCharList.push(char);

			characterList.remove(curChar);

			var i:Int;
			if (charIsPlayerCheck.selected)
			{
				_song.opponents.remove(curChar);
				_song.players.push(curChar);

				i = _song.players.length - 1;
			}
			else
			{
				_song.players.remove(curChar);
				_song.opponents.push(curChar);

				i = _song.opponents.length - 1;
			}

			characterList.insert(i, curChar);

			for (sec in _song.sections)
			{
				var connectedChar = oldCharList[sec.charFocus];
				sec.charFocus = characterList.indexOf(connectedChar);
			}

			trace('NEW CHAR LIST: ${characterList}');
			trace('NEW PLAYER LIST: ${_song.players}');
			trace('NEW OPP LIST: ${_song.opponents}\n');

			curCharIndex = characterList.indexOf(curChar);
			updateCharacterUI();
		}

		charHitsoundsCheck = new haxe.ui.components.CheckBox();
		charHitsoundsCheck.selected = hitsoundShit[curCharIndex];
		charHitsoundsCheck.text = 'Play Hitsounds?';
		charHitsoundsCheck.onClick = function(e) { hitsoundShit[curCharIndex] = charHitsoundsCheck.selected; }

		formatBox.addComponent(charIsPlayerCheck);
		formatBox.addComponent(charHitsoundsCheck);
		//

		UiS.addHR(7, formatBox);

		//
		var ghostBox = new haxe.ui.containers.VBox();

		noteGhostSlider = new haxe.ui.components.HorizontalSlider();
		noteGhostSlider.min = 0;
		noteGhostSlider.max = 1;

		noteGhostSlider.pos = noteOpacityShit[curCharIndex];

		UiS.addLabel('Editor note opacity:', ghostBox);
		ghostBox.addComponent(noteGhostSlider);

		formatBox.addComponent(ghostBox);
		//

		UiS.addHR(7, formatBox);

		//
		removeCharButton = new haxe.ui.components.Button();
		removeCharButton.text = 'Remove Character';
		removeCharButton.onClick = function(e) 
		{
			var curChar = characterList[curCharIndex];

			var oldCharList = [];
			for (char in characterList)
				oldCharList.push(char);

			characterList.remove(curChar);

			var i:Int;
			if (charIsPlayerCheck.selected)
				_song.players.remove(curChar);
			else
				_song.opponents.remove(curChar);

			for (sec in _song.sections)
			{
				if (sec.charFocus == curCharIndex)
					sec.charFocus = 0;
			}

			for (dif in _song.notes)
				dif.remove(curChar);

			trace('NEW CHAR LIST: ${characterList}');
			trace('NEW PLAYER LIST: ${_song.players}');
			trace('NEW OPP LIST: ${_song.opponents}\n');

			curCharIndex = 0;
			updateCharacterUI();
		};
		removeCharButton.borderColor = 0;
		removeCharButton.backgroundColor = Std.int(FlxColor.RED.to24Bit());
		removeCharButton.color = Std.int(FlxColor.WHITE.to24Bit());

		formatBox.addComponent(removeCharButton);
		//

		characterTab.addComponent(formatBox);
	}

	function updateCharacterUI():Void
	{
		// not loaded then lel
		if (charIsPlayerCheck == null)
			return;

		var curCharString:String = characterList[curCharIndex];

		charIsPlayerCheck.selected = _song.players.contains(curCharString);
		charHitsoundsCheck.selected = hitsoundShit[curCharIndex];

		noteGhostSlider.pos = noteOpacityShit[curCharIndex];

		var chars = getCurrentModCharacters();

		var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (char in chars)
			if (!characterList.contains(char))
				dataSource.add({text: char});

		var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
		var filtered = [];
		for (char in chars)
			if (!characterList.contains(char) || char == curCharString)
			{
				dataSource.add({text: char});
				filtered.push(char);
			}

		charSelectDropDown.dataSource = dataSource;
		charSelectDropDown.selectedIndex = filtered.indexOf(curCharString);

		var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (char in characterList)
			dataSource.add({text: char});

		sectionCharFocus.dataSource = dataSource;
		sectionCopyFrom.dataSource = dataSource;

		updateSectionUI();

		updateHeads();
	}

	var songHeader:haxe.ui.components.SectionHeader;

	var songVoicesCheck:haxe.ui.components.CheckBox;

	var songBPMStepper:haxe.ui.components.NumberStepper;
	var songSpeedStepper:haxe.ui.components.NumberStepper;

	var songStageDrop:haxe.ui.components.DropDown;
	function addSongHaxeUI():Void
	{
		var formatBox = new haxe.ui.containers.VBox();

		songHeader = new haxe.ui.components.SectionHeader();
		songHeader.text = '${_song.song} | ${formattedDifficulties[PlayState.difficulty]}';
		formatBox.addComponent(songHeader);

		var chartButtons = new haxe.ui.containers.HBox();

		var saveButton = new haxe.ui.components.Button();
		saveButton.text = 'Save';
		// lol
		saveButton.onClick = (e) -> { saveLevel(); };

		chartButtons.addComponent(saveButton);
		UiS.addVR(5, chartButtons);

		var reloadSong = new haxe.ui.components.Button();
		reloadSong.text = 'Refresh Audio';
		reloadSong.onClick = (e) ->
		{
			currentSongName = _song.song;
			loadSong();
			updateWaveform();
		}

		chartButtons.addComponent(reloadSong);
		formatBox.addComponent(chartButtons);

		UiS.addHR(7, formatBox);

		var loadButtons = new haxe.ui.containers.HBox();

		var loadNewSong = new haxe.ui.components.Button();
		loadNewSong.text = 'Load New';
		loadNewSong.onClick = (e) ->
		{
			var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();

			var root:String = Paths.mods('songs', Paths.WORKING_MOD_DIRECTORY);
			for (song in FileSystem.readDirectory(root))
			{
				if (!FileSystem.isDirectory('$root/$song'))
					continue;

				dataSource.add({text: song});
			}

			var select = new haxe.ui.containers.ListView();
			select.width = 200;
			select.height = 500;
			select.dataSource = dataSource;

			var dialogue = haxe.ui.containers.dialogs.Dialogs.dialog(select, 'Load' | haxe.ui.containers.dialogs.Dialog.DialogButton.CANCEL);

			dialogue.destroyOnClose = false;
			dialogue.title = 'Select Song';

			this.blockInput = true;

			dialogue.onDialogClosed = function(e)
			{
				this.blockInput = false;

				switch(e.button)
				{
					case '{{cancel}}':
						return;

					case 'Load':
						loadJson(select.selectedItem.text.toLowerCase());
				}
			}
		}

		loadButtons.addComponent(loadNewSong);
		UiS.addVR(5, loadButtons);

		var changeDifficulty = new haxe.ui.components.Button();
		changeDifficulty.text = 'Change Difficulty';
		changeDifficulty.onClick = (e) ->
		{
			var diffs:Array<String> = ['easy', 'normal', 'hard'];
			var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
			for (dif in diffs)
				dataSource.add({text: dif});

			var select = new haxe.ui.containers.ListView();
			select.width = 200;
			select.dataSource = dataSource;

			var dialogue = haxe.ui.containers.dialogs.Dialogs.dialog(select, 'OK' | haxe.ui.containers.dialogs.Dialog.DialogButton.CANCEL);

			dialogue.destroyOnClose = false;
			dialogue.title = 'Select Difficulty';

			this.blockInput = true;

			dialogue.onDialogClosed = function(e)
			{
				this.blockInput = false;

				switch(e.button)
				{
					case '{{cancel}}':
						return;

					case 'OK':
						if (select.selectedItem == null)
							return;
							
						PlayState.difficulty = select.selectedItem.text == 'normal' ? '' : select.selectedItem.text;

						songHeader.text = '${_song.song} | ${formattedDifficulties[PlayState.difficulty]}';
						curSongText.text = '${_song.song} (${formattedDifficulties[PlayState.difficulty]})';
				}
			}
		}
		loadButtons.addComponent(changeDifficulty);

		formatBox.addComponent(loadButtons);
		UiS.addHR(7, formatBox);

		UiS.addLabel('BPM:', formatBox);

		songBPMStepper = new haxe.ui.components.NumberStepper();
		songBPMStepper.min = 1;
		songBPMStepper.max = 999;
		songBPMStepper.pos = _song.bpm;
		songBPMStepper.step = 1;
		songBPMStepper.autoCorrect = false;
		songBPMStepper.onChange = (e) ->
		{
			_song.bpm = songBPMStepper.pos;
			Conductor.mapBPMChanges(_song);
			Conductor.changeBPM(songBPMStepper.pos);
		}

		formatBox.addComponent(songBPMStepper);

		UiS.addSpacer(0, 5, formatBox);

		UiS.addLabel('Song Speed:', formatBox);

		songSpeedStepper = new haxe.ui.components.NumberStepper();
		songSpeedStepper.min = 1;
		songSpeedStepper.max = 10;
		songSpeedStepper.pos = _song.speed;
		songSpeedStepper.step = 0.1;
		songSpeedStepper.autoCorrect = false;
		songSpeedStepper.onChange = (e) ->
		{
			_song.speed = songSpeedStepper.pos;
		}

		formatBox.addComponent(songSpeedStepper);

		UiS.addHR(7, formatBox);
		
		var characters = getCurrentModCharacters();

		var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (char in characters)
			dataSource.add({text: char});

		UiS.addLabel('Girlfriend:', formatBox);

		var	autoGFDropDown = new haxe.ui.components.DropDown();
		autoGFDropDown.searchable = true;
		autoGFDropDown.searchPrompt = 'Find Character';
		autoGFDropDown.width = 150;
		autoGFDropDown.dataSource = dataSource;
		autoGFDropDown.selectedIndex = characters.indexOf(_song.autoGF);
		autoGFDropDown.onChange = (e) ->
		{
			_song.autoGF = characters[characters.indexOf(autoGFDropDown.selectedItem.text)];
			updateHeads();
		}

		formatBox.addComponent(autoGFDropDown);
		UiS.addSpacer(0, 10, formatBox);

		var stageDataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();

		var directories:Array<String> = [Paths.mods('stages/')];
		for (mod in Paths.getModDirectories())
			if (Paths.mods('stages', mod) != null)
				directories.push(Paths.mods('stages', mod));

		var stages:Array<String> = [];
		for (dir in directories) 
		{
			var mod:String = dir.split('/')[1];

			for (stage in FileSystem.readDirectory(dir))
				if (Paths.stageJson(stage, mod) != null && !stages.contains(stage))
				{
					stages.push(stage);
					stageDataSource.add({text: stage});
				}
		}

		songStageDrop = new haxe.ui.components.DropDown();
		songStageDrop.searchable = true;
		songStageDrop.searchPrompt = 'Find Stage';
		songStageDrop.width = 150;
		songStageDrop.dataSource = stageDataSource;
		songStageDrop.selectedIndex = stages.indexOf(_song.stage);
		songStageDrop.onChange = (e) ->
		{
			_song.stage = stages[songStageDrop.selectedIndex];
		}

		UiS.addLabel('Stage:', formatBox);
		formatBox.addComponent(songStageDrop);

		UiS.addHR(7, formatBox);

		var addCharacter = new haxe.ui.components.Button();
		addCharacter.text = 'Add New Character';
		addCharacter.onClick = (e) ->
		{
			var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();

			var directories:Array<String> = [Paths.mods('characters')];
			for (mod in Paths.getModDirectories())
				if (Paths.mods('characters', mod) != null)
					directories.push(Paths.mods('characters', mod));
			
			for (root in directories)
				for (character in FileSystem.readDirectory(root))
				{
					if (!FileSystem.isDirectory('$root/$character'))
						continue;

					if (!FileSystem.exists('$root/$character/character.json'))
						continue;

					if (characterList.contains(character))
						continue;

					dataSource.add({text: character});
				}

			var select = new haxe.ui.containers.ListView();
			select.width = 200;
			select.height = 500;
			select.dataSource = dataSource;

			var dialogue = haxe.ui.containers.dialogs.Dialogs.dialog(select, 'Add' | haxe.ui.containers.dialogs.Dialog.DialogButton.CANCEL);

			dialogue.destroyOnClose = false;
			dialogue.title = 'Select Character';

			this.blockInput = true;

			dialogue.onDialogClosed = function(e)
			{
				this.blockInput = false;

				switch(e.button)
				{
					case '{{cancel}}':
						return;

					case 'Add':
						var charToAdd = select.selectedItem.text;

						trace('ADDING NEW CHAR ${charToAdd}');

						characterList.push(charToAdd);
						_song.opponents.push(charToAdd);

						for (dif in _song.notes)
							dif.set(charToAdd, []);

						trace('total char num ${characterList.length}');

						curCharIndex = characterList.length - 1;

						trace('selected ${curCharIndex}');

						noteOpacityShit[curCharIndex] = 0.3;

						updateCharacterUI();
						updateGrid();
				}
			}
		}

		formatBox.addComponent(addCharacter);

		UiS.addHR(7, formatBox);

		var clearEventButton = new haxe.ui.components.Button();
		clearEventButton.text = 'Clear Events';
		clearEventButton.onClick = (e) ->
		{
			clearEvents();
		}
		clearEventButton.borderColor = 0;
		clearEventButton.backgroundColor = Std.int(FlxColor.RED.to24Bit());
		clearEventButton.color = Std.int(FlxColor.WHITE.to24Bit());

		var clearNotes = new haxe.ui.components.Button();
		clearNotes.text = 'Clear Notes';
		clearNotes.onClick = (e) ->
		{
			for (char in _song.notes[chartDifficultyString])
				char = [];

			updateGrid();
		}
		clearNotes.borderColor = 0;
		clearNotes.backgroundColor = Std.int(FlxColor.RED.to24Bit());
		clearNotes.color = Std.int(FlxColor.WHITE.to24Bit());

		formatBox.addComponent(clearNotes);
		formatBox.addComponent(clearEventButton);

		songTab.addComponent(formatBox);
	}

	function getCopyLastString(char:String, amt:Int)
	{
		var mode = cutSection.selected ? 'Cut' : 'Copy';

		if (char == characterList[curCharIndex] && amt == 0)
			copyLastButton.disabled = true;

		if (copyLastButton.disabled && amt != 0)
			copyLastButton.disabled = false;

		if (amt == 0)
			return '$mode this section from $char';

		return '$mode from $char $amt section${amt > 1 ? 's' : ''} ago';
	}

	var sectionStepperBeats:haxe.ui.components.NumberStepper;
	var sectionChangeBPM:haxe.ui.components.CheckBox;
	var sectionStepperBPM:haxe.ui.components.NumberStepper;

	var cutSection:haxe.ui.components.CheckBox;

	var sectionCharFocus:haxe.ui.components.DropDown;
	var sectionCopyFrom:haxe.ui.components.DropDown;

	var copyLastButton:haxe.ui.components.Button;

	var notesCopied:NoteCopyPayload = 
	{
		events: [],
		chars: []
	}
	var sectionToCopy:Int = 0;
	function addSectionHaxeUI():Void
	{
		var formatBox = new haxe.ui.containers.VBox();

		UiS.addLabel('Char Focus:', formatBox);

		var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (char in characterList)
			dataSource.add({text: char});

		sectionCharFocus = new haxe.ui.components.DropDown();
		sectionCharFocus.searchable = true;
		sectionCharFocus.searchPrompt = 'Find Character';
		sectionCharFocus.width = 150;
		sectionCharFocus.dataSource = dataSource;
		sectionCharFocus.onChange = (e) ->
		{
			_song.sections[curSec].charFocus = characterList.indexOf(sectionCharFocus.selectedItem.text);
			
			updateSectionUI();
			
			updateGrid();
			updateHeads();
		}

		formatBox.addComponent(sectionCharFocus);
		
		UiS.addHR(7, formatBox);

		UiS.addLabel('Beats Per Section:', formatBox);

		sectionStepperBeats = new haxe.ui.components.NumberStepper();
		sectionStepperBeats.min = 1;
		sectionStepperBeats.max = 6;
		sectionStepperBeats.pos = getSectionBeats();
		sectionStepperBeats.step = 1;
		sectionStepperBeats.autoCorrect = false;
		sectionStepperBeats.onChange = (e) ->
		{
			_song.sections[curSec].sectionBeats = sectionStepperBeats.pos;
			reloadGridLayer();
		}

		formatBox.addComponent(sectionStepperBeats);

		UiS.addHR(7, formatBox);

		sectionChangeBPM = new haxe.ui.components.CheckBox();
		sectionChangeBPM.text = 'Change BPM';
		sectionChangeBPM.onClick = (e) ->
		{
			_song.sections[curSec].changeBPM = sectionChangeBPM.selected;
		}

		sectionStepperBPM = new haxe.ui.components.NumberStepper();
		sectionStepperBPM.min = 0;
		sectionStepperBPM.max = 999;
		sectionStepperBPM.pos = sectionChangeBPM.selected ? _song.sections[curSec].bpm : Conductor.bpm;
		sectionStepperBPM.step = 1;
		sectionStepperBPM.autoCorrect = false;
		sectionStepperBPM.onChange = (e) ->
		{
			_song.sections[curSec].bpm = sectionStepperBPM.pos;
			updateGrid();
		}

		formatBox.addComponent(sectionChangeBPM);
		formatBox.addComponent(sectionStepperBPM);

		UiS.addHR(7, formatBox);

		var copyPasteBox = new haxe.ui.containers.HBox();

		var cvButtons = new haxe.ui.containers.VBox();
		var cvBoxes = new haxe.ui.containers.VBox();

		var sectionCopyButton = new haxe.ui.components.Button();
		var sectionPasteButton = new haxe.ui.components.Button();

		var sectionClearButton = new haxe.ui.components.Button();

		var copyNotes = new haxe.ui.components.CheckBox();
		var copyEvents = new haxe.ui.components.CheckBox();
		cutSection = new haxe.ui.components.CheckBox();

		copyNotes.text = 'Notes';
		copyEvents.text = 'Events';
		cutSection.text = 'Cut';

		copyNotes.selected = true;

		cvBoxes.addComponent(copyNotes);
		cvBoxes.addComponent(copyEvents);
		cvBoxes.addComponent(cutSection);

		sectionCopyButton.text = 'Copy Section';
		sectionCopyButton.onClick = (e) ->
		{
			notesCopied = 
			{
				events: [],
				chars: []
			}

			var i:Int = 0;
			var finalNotes:Map<String, Array<NoteFile>> = new Map();
			for (char in _song.notes[chartDifficultyString])
			{
				if (notesCopied.chars[characterList[i]] == null)
				{
					notesCopied.chars[characterList[i]] = [];
					finalNotes[characterList[i]] = [];
				}

				for (note in _song.notes[chartDifficultyString][characterList[i]])
				{
					if (!copyNotes.selected)
						break;

					finalNotes[characterList[i]].push(note);

					if (!noteInSection(note))
						continue;

					if (cutSection.selected)
						finalNotes[characterList[i]].remove(note);

					notesCopied.chars[characterList[i]].push(note);
				}

				i++;
			}

			if (copyNotes.selected)
				for (char in characterList)
				{
					_song.notes[chartDifficultyString][char].resize(0);

					for (note in finalNotes[char])
						_song.notes[chartDifficultyString][char].push(note);
				}

			var finalEvents:Array<EventNote> = [];
			for (event in _song.events)
			{
				if (!copyEvents.selected)
					break;

				finalEvents.push(event);

				if(!noteInSection(event))
					continue;

				notesCopied.events.push(event);

				if (cutSection.selected)
					finalEvents.remove(event);
			}

			if (copyEvents.selected)
				_song.events = finalEvents;

			sectionPasteButton.disabled = false;

			sectionToCopy = curSec;

			updateGrid();
		}

		sectionPasteButton.text = 'Paste Section';
		sectionPasteButton.disabled = true;
		sectionPasteButton.onClick = (e) ->
		{
			if(notesCopied == null)
				return;

			var addToTime:Float = Math.ceil(Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy)));

			var i:Int = 0;
			for (char in notesCopied.chars)
			{
				for (note in notesCopied.chars[characterList[i]])
				{
					var copiedNote:NoteFile = 
					{
						ms: note.ms + addToTime,
						d: note.d,
						l: note.l,
						t: note.t
					}

					_song.notes[chartDifficultyString][characterList[i]].push(copiedNote);
				}

				i++;
			}

			for (event in notesCopied.events)
			{
				var copiedEvent:EventNote =
				{
					strumTime: event.strumTime + addToTime,

					event: event.event,

					value1: event.value1,
					value2: event.value2,
					value3: event.value3
				}

				_song.events.push(copiedEvent);
			}

			notesCopied = null;
			sectionPasteButton.disabled = true;

			updateGrid();
		}

		sectionClearButton.text = 'Clear Section';
		sectionClearButton.onClick = (e) ->
		{
			if (copyNotes.selected)
			{
				for (char in _song.notes[chartDifficultyString])
				{
					var i:Int = char.length;
					while(i > -1)
					{
						--i;

						var note:NoteFile = char[i];

						if (!noteInSection(note))
							continue;

						char.remove(note);
					}
				}
			}

			if(copyEvents.selected)
			{
				var i:Int = _song.events.length;
				while(i > -1) 
				{
					--i;

					var event:EventNote = _song.events[i];

					if (!noteInSection(event))
						continue;

					_song.events.remove(event);
				}
			}
			
			updateGrid();
		}
		sectionClearButton.borderColor = 0;
		sectionClearButton.backgroundColor = Std.int(FlxColor.RED.to24Bit());
		sectionClearButton.color = Std.int(FlxColor.WHITE.to24Bit());

		sectionCopyButton.width = 125;
		sectionPasteButton.width = 125;
		sectionClearButton.width = 125;

		cvButtons.addComponent(sectionCopyButton);
		cvButtons.addComponent(sectionPasteButton);
		cvButtons.addComponent(sectionClearButton);

		copyPasteBox.addComponent(cvButtons);
		copyPasteBox.addComponent(cvBoxes);

		formatBox.addComponent(copyPasteBox);
		UiS.addSpacer(0, 15, formatBox);

		var copyBox = new haxe.ui.containers.HBox();

		copyLastButton = new haxe.ui.components.Button();
		copyLastButton.width = 125;
		copyLastButton.height = 60;

		copyBox.addComponent(copyLastButton);

		sectionCopyFrom = new haxe.ui.components.DropDown();
		sectionCopyFrom.searchable = true;
		sectionCopyFrom.searchPrompt = 'Find Character';
		sectionCopyFrom.width = 150;
		sectionCopyFrom.dataSource = dataSource;
		sectionCopyFrom.selectedIndex = 0;

		var sectionCopyStepper = new haxe.ui.components.NumberStepper();
		sectionCopyStepper.min = 0;
		sectionCopyStepper.max = 999; // lol
		sectionCopyStepper.step = 1;
		sectionCopyStepper.pos = 1;

		var lolFunction = (e) ->
		{
			if (sectionCopyFrom.selectedItem != null)
				copyLastButton.text = getCopyLastString(sectionCopyFrom.selectedItem.text, Std.int(sectionCopyStepper.pos));
		}

		if (sectionCopyFrom.selectedItem != null)
			copyLastButton.text = getCopyLastString(sectionCopyFrom.selectedItem.text, Std.int(sectionCopyStepper.pos));

		sectionCopyStepper.onChange = lolFunction;
		sectionCopyFrom.onChange = lolFunction;

		copyLastButton.onClick = (e) ->
		{
			if (sectionCopyFrom.selectedItem == null)
				return;

			var value:Int = Std.int(sectionCopyStepper.pos);

			var daSec = FlxMath.maxInt(curSec, value);
			var mode = cutSection.selected ? 'cutting' : 'copying';
			trace('$mode $value into the past');

			var finalNotes:Array<NoteFile> = [];
			for (note in _song.notes[chartDifficultyString][sectionCopyFrom.selectedItem.text])
			{
				if (!copyNotes.selected)
					break;

				var lightCopy:NoteFile = {d: note.d, ms: note.ms, l: note.l, t: note.t};

				finalNotes.push(note);

				if (!noteInSection(note, -value))
					continue;

				if (cutSection.selected)
					finalNotes.remove(note);

				var copiedNote:NoteFile = 
				{
					d: note.d,
					ms: note.ms + Math.ceil(Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value)),
					l: note.l,
					t: note.t
				}

				_song.notes[chartDifficultyString][characterList[curCharIndex]].push(copiedNote);
			}

			if (copyNotes.selected)
			{	
				_song.notes[chartDifficultyString][sectionCopyFrom.selectedItem.text].resize(0);

				for (note in finalNotes)
					_song.notes[chartDifficultyString][sectionCopyFrom.selectedItem.text].push(note);
			}

			var finalEvents:Array<EventNote> = [];
			for (event in _song.events)
			{
				if (!copyEvents.selected)
					break;

				finalEvents.push(event);
				
				if(!noteInSection(event, -value))
					continue;

				if (cutSection.selected)
					finalEvents.remove(event);

				var copiedEvent:EventNote =
				{
					strumTime: event.strumTime + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value),

					event: event.event,

					value1: event.value1,
					value2: event.value2,
					value3: event.value3
				}

				_song.events.push(copiedEvent);
			}

			if (copyEvents.selected)
			{
				_song.events.resize(0);

				for (event in finalEvents)
					_song.events.push(event);
			}

			updateGrid();
		}

		cutSection.onClick = function(e)
		{
			var mode = cutSection.selected ? 'Cut' : 'Copy';

			sectionCopyButton.text = '$mode Section';
			copyLastButton.text = getCopyLastString(sectionCopyFrom.selectedItem.text, Std.int(sectionCopyStepper.pos));
		}

		var setDisabled = function(e)
		{
			var disabled:Bool = !copyNotes.selected && !copyEvents.selected;

			sectionCopyButton.disabled = disabled;
			sectionClearButton.disabled = disabled;

			copyLastButton.disabled = disabled;
		}

		copyNotes.onChange = setDisabled;
		copyEvents.onChange = setDisabled;

		var rightBox = new haxe.ui.containers.VBox();
		rightBox.addComponent(sectionCopyStepper);
		rightBox.addComponent(sectionCopyFrom);

		copyBox.addComponent(rightBox);

		formatBox.addComponent(copyBox);
		sectionTab.addComponent(formatBox);
	}

	var noteSustainStepper:haxe.ui.components.NumberStepper;
	var noteStrumTime:haxe.ui.components.TextField;
	var noteTypeSelect:haxe.ui.components.DropDown;
	var noteDescContent:haxe.ui.components.Label;
	function addNoteHaxeUI():Void
	{
		var formatBox = new haxe.ui.containers.VBox();

		noteSustainStepper = new haxe.ui.components.NumberStepper();
		noteSustainStepper.min = 0;
		noteSustainStepper.max = Math.ceil(Conductor.stepCrochet * 64);
		noteSustainStepper.pos = 0;
		noteSustainStepper.step = Math.ceil(Conductor.stepCrochet / 2);
		noteSustainStepper.autoCorrect = false;
		noteSustainStepper.onChange = (e) ->
		{
			if(!selectingNote)
				return;

			noteReference.l = Math.ceil(noteSustainStepper.pos);
			updateGrid();
		}

		UiS.addLabel('Sustain Length:', formatBox);
		formatBox.addComponent(noteSustainStepper);

		UiS.addHR(7, formatBox);

		noteStrumTime = new haxe.ui.components.TextField();
		noteStrumTime.restrictChars = '0-9.';
		noteStrumTime.onChange = (e) ->
		{
			if (!selectingNote)
				return;

			var value:Float = Std.parseFloat(noteStrumTime.text);
			if(Math.isNaN(value)) value = 0;

			noteReference.ms = value;
			updateGrid();
		}

		UiS.addLabel('Strum Time (in MS):', formatBox);
		formatBox.addComponent(noteStrumTime);

		UiS.addHR(7, formatBox);

		var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (i in 0...noteDisplayNameList.length)
			dataSource.add({text: '$i. ${noteDisplayNameList[i]}'});

		trace(noteDisplayNameList);

		noteTypeSelect = new haxe.ui.components.DropDown();
		noteTypeSelect.searchable = true;
		noteTypeSelect.searchPrompt = 'Find Note Type';
		noteTypeSelect.width = 150;
		noteTypeSelect.dataSource = dataSource;
		noteTypeSelect.onChange = (e) ->
		{
			if (noteTypeSelect.selectedItem == null)
				return;

			// removes the "0." "1." formatting from the start of the names
			var noteTypeName:String = noteTypeSelect.selectedItem.text.substr(3);
			noteDescContent.text = noteTypeDataBase[noteTypeMap[noteTypeName]].desc;

			if (!selectingNote)
				return;

			noteReference.t = noteTypeName;
			updateGrid();
		}

		UiS.addLabel('Note Type:', formatBox);
		formatBox.addComponent(noteTypeSelect);

		noteDescContent = new haxe.ui.components.Label();
		noteDescContent.text = '';

		var noteDesc = new haxe.ui.containers.ScrollView();
		noteDesc.width = 300;
		noteDesc.height = 150;
		noteDesc.addComponent(noteDescContent);

		formatBox.addComponent(noteDesc);
		noteTab.addComponent(formatBox);
	}

	function changeEventSelected(change:Int = 0)
	{
		if (selectingEvent)
		{
			selectedEventIndex += change;

			if (selectedEventIndex < 0) 
				selectedEventIndex = eventReference.length - 1;
			else if (selectedEventIndex >= eventReference.length)
				selectedEventIndex = 0;
		}
		else
			selectedEventIndex = 0;

		updateGrid();
		updateEventUI();
	}

	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}

	var eventsDropDown:haxe.ui.components.DropDown;
	var eventDesc:haxe.ui.containers.ScrollView;
	var eventDescContent:haxe.ui.components.Label;

	var eventSelectedText:haxe.ui.components.Label;

	var val1Input:haxe.ui.components.TextArea;
	var val2Input:haxe.ui.components.TextArea;
	var val3Input:haxe.ui.components.TextArea;
	function addEventsHaxeUI():Void
	{
		var formatBox = new haxe.ui.containers.VBox();

		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];
		for (mod in Paths.getModDirectories())
			if (Paths.mods('custom_events', mod) != null)
				directories.push(Paths.mods('custom_events', mod));

		var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();

		for (path in directories)
		{
			var mod = path.split('/')[1];

			for (file in FileSystem.readDirectory(path))
			{
				if (file.endsWith('txt') && !eventPushedMap.exists(file))
				{
					var split:String = file.split('.txt')[0];
					eventPushedMap.set(split, true);
					eventStuff.set(split, File.getContent(Paths.eventTxt(split, mod)));
				}
			}
		}

		var eventStuffBox = new haxe.ui.containers.HBox();

		var dropdownBox = new haxe.ui.containers.VBox();

		eventDescContent = new haxe.ui.components.Label();
		eventDescContent.text = eventStuff[''];

		eventDesc = new haxe.ui.containers.ScrollView();
		eventDesc.percentWidth = 100;
		eventDesc.height = 150;
		eventDesc.addComponent(eventDescContent);

		var eventNames = Lambda.array({iterator: eventStuff.keys});
		eventNames.sort(function(a:String, b:String):Int 
		{
			a = a.toUpperCase();
			b = b.toUpperCase();

			return a < b ? -1 : a > b ? 1 : 0;
		});
		
		for (name in eventNames) 
			dataSource.add({text: name});

		var lol = new haxe.ui.containers.HBox();
		eventsDropDown = new haxe.ui.components.DropDown();
		eventsDropDown.searchable = true;
		eventsDropDown.searchPrompt = 'Find Event';
		eventsDropDown.width = 150;
		eventsDropDown.dataSource = dataSource;
		eventsDropDown.selectedIndex = 0;
		eventsDropDown.onChange = (e) ->
		{
			if (eventsDropDown.selectedItem == null)
				return;

			var selectedEvent:String = eventsDropDown.selectedItem.text;
			eventDescContent.text = eventStuff[selectedEvent];

			if (!selectingEvent)
				return;

			eventReference[selectedEventIndex].event = selectedEvent;

			updateGrid();
		}

		lol.addComponent(eventsDropDown);
		UiS.addVR(5, lol);

		// New event buttons
		var removeEvent = new haxe.ui.components.Button();
		removeEvent.text = '-';
		removeEvent.onClick = function(e) 
		{
			if(!selectingEvent)
				return;

			if (eventReference.length <= 1)
				return;

			var curEvent = eventReference[selectedEventIndex];

			_song.events.remove(curEvent);
			eventReference.remove(curEvent);

			changeEventSelected(-1);

			updateGrid();
		}
		removeEvent.borderColor = 0;
		removeEvent.backgroundColor = Std.int(FlxColor.RED.to24Bit());
		removeEvent.color = Std.int(FlxColor.WHITE.to24Bit());

		lol.addComponent(removeEvent);

		var addEvent = new haxe.ui.components.Button();
		addEvent.text = '+';
		addEvent.onClick = function(e) 
		{
			if(!selectingEvent)
				return;

			var newEvent:EventNote =
			{
				strumTime: eventReference[0].strumTime,

				event: '',

				value1: '',
				value2: '',
				value3: ''
			}

			_song.events.push(newEvent);
			eventReference.push(newEvent);

			changeEventSelected(1);
			updateGrid();
		}
		addEvent.borderColor = 0;
		addEvent.backgroundColor = Std.int(FlxColor.LIME.to24Bit());
		addEvent.color = Std.int(FlxColor.WHITE.to24Bit());

		lol.addComponent(addEvent);
		UiS.addVR(5, lol);

		var moveLeftButton = new haxe.ui.components.Button();
		moveLeftButton.text = '<';
		moveLeftButton.onClick = function(e) 
		{
			changeEventSelected(-1);
		}

		lol.addComponent(moveLeftButton);

		var moveRightButton = new haxe.ui.components.Button();
		moveRightButton.text = '>';
		moveRightButton.onClick = function(e) 
		{
			changeEventSelected(1);
		}

		lol.addComponent(moveRightButton);

		dropdownBox.addComponent(lol);
		UiS.addHR(7, dropdownBox);

		eventSelectedText = new haxe.ui.components.Label();
		eventSelectedText.text = 'Selected: 0 / 0';

		dropdownBox.addComponent(eventSelectedText);
		dropdownBox.addComponent(eventDesc);
		UiS.addHR(7, dropdownBox);

		val1Input = new haxe.ui.components.TextArea();
		val1Input.placeholder = 'Value 1...';
		val1Input.height = 50;
		val1Input.onChange = (e) ->
		{
			if (!selectingEvent)
				return;

			eventReference[selectedEventIndex].value1 = val1Input.text;
			updateGrid();
		}

		dropdownBox.addComponent(val1Input);

		UiS.addSpacer(0, 10, dropdownBox);

		val2Input = new haxe.ui.components.TextArea();
		val2Input.placeholder = 'Value 2...';
		val2Input.height = 50;
		val2Input.onChange = (e) ->
		{
			if (!selectingEvent)
				return;

			eventReference[selectedEventIndex].value2 = val2Input.text;
			updateGrid();
		}

		dropdownBox.addComponent(val2Input);

		UiS.addSpacer(0, 10, dropdownBox);

		val3Input = new haxe.ui.components.TextArea();
		val3Input.placeholder = 'Value 3...';
		val3Input.height = 50;
		val3Input.onChange = (e) ->
		{
			if (!selectingEvent)
				return;

			eventReference[selectedEventIndex].value3 = val3Input.text;
			updateGrid();
		}

		dropdownBox.addComponent(val3Input);

		eventStuffBox.addComponent(dropdownBox);

		formatBox.addComponent(eventStuffBox);
		eventsTab.addComponent(formatBox);
	}

	var chartingWaveformInst:haxe.ui.components.CheckBox;
	var chartingWaveformVoc:haxe.ui.components.CheckBox;
	var chartingMuteInst:haxe.ui.components.CheckBox;
	var chartingMuteVoc:haxe.ui.components.CheckBox;

	var chartingMouseQuant:haxe.ui.components.CheckBox;
	var chartingShowStrums:haxe.ui.components.CheckBox;

	var chartingMetronome:haxe.ui.components.CheckBox;

	var metronomeStepper:haxe.ui.components.NumberStepper;
	var metronomeOffsetStepper:haxe.ui.components.NumberStepper;

	var chartingAutoScroll:haxe.ui.components.CheckBox;

	var chartingInstVolume:haxe.ui.components.NumberStepper;
	var chartingVocVolume:haxe.ui.components.NumberStepper;

	var chartingTimescale:haxe.ui.components.HorizontalSlider;

	function addChartingHaxeUI() 
	{
		var formatBox = new haxe.ui.containers.VBox();

		var voicesBox = new haxe.ui.containers.HBox();
		
		var muteBox = new haxe.ui.containers.VBox();
		chartingMuteInst = new haxe.ui.components.CheckBox();
		chartingMuteInst.text = 'Mute Instrumental';
		chartingMuteInst.selected = false;
		chartingMuteInst.onClick = function(e) { FlxG.sound.music.volume = chartingMuteInst.selected ? 0 : 1; }

		chartingMuteVoc = new haxe.ui.components.CheckBox();
		chartingMuteVoc.text = 'Mute Voices';
		chartingMuteVoc.selected = false;
		chartingMuteVoc.onClick = function(e) { vocals.volume = chartingMuteInst.selected ? 0 : 1; }

		muteBox.addComponent(chartingMuteInst);
		muteBox.addComponent(chartingMuteVoc);

		voicesBox.addComponent(muteBox);
		UiS.addSpacer(25, 0, voicesBox);

		#if desktop
		if (FlxG.save.data.chart_waveformInst == null) FlxG.save.data.chart_waveformInst = false;
		if (FlxG.save.data.chart_waveformVoices == null) FlxG.save.data.chart_waveformVoices = false;

		//
		var waveBox = new haxe.ui.containers.VBox();
		chartingWaveformInst = new haxe.ui.components.CheckBox();
		chartingWaveformInst.selected = FlxG.save.data.chart_waveformInst;
		chartingWaveformInst.text = 'Waveform for Instrumental';
		chartingWaveformInst.onClick = function(e) 
		{ 
			chartingWaveformVoc.selected = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformInst = chartingWaveformInst.selected;
			updateWaveform();
		}

		chartingWaveformVoc = new haxe.ui.components.CheckBox();
		chartingWaveformVoc.selected = FlxG.save.data.chart_waveformVoices;
		chartingWaveformVoc.text = 'Waveform for Voices';
		chartingWaveformVoc.onClick = function(e) 
		{ 
			chartingWaveformInst.selected = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformVoices = chartingWaveformVoc.selected;
			updateWaveform();
		}

		waveBox.addComponent(chartingWaveformInst);
		waveBox.addComponent(chartingWaveformVoc);

		voicesBox.addComponent(waveBox);
		//
		#end

		formatBox.addComponent(voicesBox);

		UiS.addHR(7, formatBox);

		chartingMouseQuant = new haxe.ui.components.CheckBox();
		if (FlxG.save.data.mouseScrollingQuant == null) FlxG.save.data.mouseScrollingQuant = false;
		chartingMouseQuant.selected = FlxG.save.data.mouseScrollingQuant;
		chartingMouseQuant.text = 'Quantized Mouse Scrolling';
		chartingMouseQuant.onClick = function(e) 
		{
			FlxG.save.data.mouseScrollingQuant = chartingMouseQuant.selected;
			mouseQuant = FlxG.save.data.mouseScrollingQuant;
		}
		formatBox.addComponent(chartingMouseQuant);

		UiS.addHR(7, formatBox);

		chartingShowStrums = new haxe.ui.components.CheckBox();
		if (FlxG.save.data.chart_vortex == null) FlxG.save.data.chart_vortex = false;
		chartingShowStrums.selected = FlxG.save.data.chart_vortex;
		chartingShowStrums.text = 'Show Strums';
		chartingShowStrums.onClick = function(e) 
		{
			FlxG.save.data.chart_vortex = chartingShowStrums.selected;
			vortex = FlxG.save.data.chart_vortex;

			reloadGridLayer();
		}
		formatBox.addComponent(chartingShowStrums);

		UiS.addHR(7, formatBox);

		var metronomeSteppers = new haxe.ui.containers.HBox();

		var metronomeBox = new haxe.ui.containers.VBox();
		metronomeStepper = new haxe.ui.components.NumberStepper();
		metronomeStepper.min = 1;
		metronomeStepper.max = 9999;
		metronomeStepper.pos = _song.bpm;
		metronomeStepper.step = 1;
		metronomeStepper.autoCorrect = false;

		UiS.addLabel('Metronome BPM:', metronomeBox);

		metronomeBox.addComponent(metronomeStepper);
		metronomeSteppers.addComponent(metronomeBox);

		UiS.addVR(5, metronomeSteppers);

		var offsetBox = new haxe.ui.containers.VBox();
		metronomeOffsetStepper = new haxe.ui.components.NumberStepper();
		metronomeOffsetStepper.min = -1000;
		metronomeOffsetStepper.max = 1000;
		metronomeOffsetStepper.pos = 0;
		metronomeOffsetStepper.step = 25;
		metronomeOffsetStepper.autoCorrect = false;

		UiS.addLabel('Metronome Offset (MS):', offsetBox);

		offsetBox.addComponent(metronomeOffsetStepper);
		metronomeSteppers.addComponent(offsetBox);

		formatBox.addComponent(metronomeSteppers);

		chartingMetronome = new haxe.ui.components.CheckBox();
		if (FlxG.save.data.chart_metronome == null) FlxG.save.data.chart_metronome = false;
		chartingMetronome.selected = FlxG.save.data.chart_metronome;
		chartingMetronome.onClick = function(e) { FlxG.save.data.chart_metronome = chartingMetronome.selected; }
		chartingMetronome.text = 'Metronome';

		formatBox.addComponent(chartingMetronome);

		UiS.addHR(7, formatBox);

		chartingAutoScroll = new haxe.ui.components.CheckBox();
		if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
		chartingAutoScroll.selected = FlxG.save.data.chart_noAutoScroll;
		chartingAutoScroll.onClick = (e) -> { FlxG.save.data.chart_noAutoScroll = chartingAutoScroll.selected; }
		chartingAutoScroll.text = 'Disable Autoscroll (Not Recommended)';

		formatBox.addComponent(chartingAutoScroll);

		UiS.addHR(7, formatBox);

		var volumeSteppers = new haxe.ui.containers.HBox();

		var instBox = new haxe.ui.containers.VBox();

		chartingInstVolume = new haxe.ui.components.NumberStepper();
		chartingInstVolume.min = 0.1;
		chartingInstVolume.max = 1;
		chartingInstVolume.pos = FlxG.sound.music.volume;
		chartingInstVolume.step = 0.1;
		chartingInstVolume.autoCorrect = false;
		chartingInstVolume.onChange = (e) ->
		{
			FlxG.sound.music.volume = chartingInstVolume.pos;
		}

		var label = new haxe.ui.components.Label();
		label.text = 'Inst Volume:';

		instBox.addComponent(label);
		instBox.addComponent(chartingInstVolume);

		volumeSteppers.addComponent(instBox);

		UiS.addVR(5, volumeSteppers);

		var vocBox = new haxe.ui.containers.VBox();

		chartingVocVolume = new haxe.ui.components.NumberStepper();
		chartingVocVolume.min = 0.1;
		chartingVocVolume.max = 1;
		chartingVocVolume.pos = vocals.volume;
		chartingVocVolume.step = 0.1;
		chartingVocVolume.autoCorrect = false;
		chartingVocVolume.onChange = (e) ->
		{
			vocals.volume = chartingVocVolume.pos;
		}

		var label = new haxe.ui.components.Label();
		label.text = 'Voice Volume:';

		vocBox.addComponent(label);
		vocBox.addComponent(chartingVocVolume);

		volumeSteppers.addComponent(vocBox);
		
		formatBox.addComponent(volumeSteppers);

		#if !html5
		UiS.addHR(7, formatBox);

		var timescaleBox = new haxe.ui.containers.VBox();

		chartingTimescale = new haxe.ui.components.HorizontalSlider();
		chartingTimescale.min = 0.5;
		chartingTimescale.max = 3;

		chartingTimescale.pos = 1;

		var timescaleLabel = new haxe.ui.components.Label();
		timescaleLabel.text = 'Timescale';

		var resetTimescale = new haxe.ui.components.Button();
		resetTimescale.text = 'Reset Timescale';
		resetTimescale.onClick = function(e) { chartingTimescale.pos = 1; };

		timescaleBox.addComponent(timescaleLabel);
		timescaleBox.addComponent(chartingTimescale);
		timescaleBox.addComponent(resetTimescale);

		formatBox.addComponent(timescaleBox);
		#end

		chartingTab.addComponent(formatBox);
	}

	function loadSong():Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			// vocals.stop();
		}

		var file:Dynamic = Paths.modsVoices(currentSongName, Paths.WORKING_MOD_DIRECTORY);
		vocals = new FlxSound();
		if (file != null) 
		{
			vocals.loadEmbedded(file);
			FlxG.sound.list.add(vocals);
		}

		var file:Dynamic = Paths.modsInst(currentSongName, Paths.WORKING_MOD_DIRECTORY);
		inst = new FlxSound();
		if (file != null)
		{
			inst.loadEmbedded(file);
			FlxG.sound.list.add(inst);
		}

		FlxG.sound.music = inst;
			
		generateSong();

		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;
	}

	function generateSong() 
	{
		FlxG.sound.music.play();

		if (chartingInstVolume != null) FlxG.sound.music.volume = chartingInstVolume.pos;
		if (chartingMuteInst != null && chartingMuteInst.selected) FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if(vocals != null) {
				vocals.pause();
				vocals.time = 0;
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			vocals.play();
		};
	}

	var updatedSection:Bool = false;

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add)
		{
			if(_song.sections[i] != null)
			{
				if (_song.sections[i].changeBPM)
					daBPM = _song.sections[i].bpm;
				
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return Math.floor(daPos);
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;
	override function update(dt:Float)
	{
		// lol!
		if (autoLoadData.doIt)
			return;

		curStep = recalculateSteps();

		noteOpacityShit[curCharIndex] = noteGhostSlider.pos;

		var hasFocus:Bool = _song.sections[curSec].charFocus == curCharIndex;
		if (eyeOpened && !hasFocus)
			closeEye();
		else if (!eyeOpened && hasFocus)
			openEye();

		if(FlxG.sound.music.time < 0) 
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) 
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;

		strumLineUpdateY();
		for (i in 0...4)
			strumLineNotes.members[i].y = strumLine.y;

		FlxG.mouse.visible = true; // cause reasons. trust me

		camPos.y = strumLine.y;
		if(!chartingAutoScroll.selected) 
		{
			if (Math.ceil(strumLine.y) >= gridBG.height)
			{
				if (_song.sections[curSec + 1] == null)
					addSection();

				changeSection(curSec + 1, false);
			} 
			else if (strumLine.y < -10)
				changeSection(curSec - 1, false);
		}


		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
			{
				var gridmult = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		} 
		else
			dummyArrow.visible = false;

		if (FlxG.mouse.overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:Note)
			{
				if (FlxG.mouse.overlaps(note))
				{
					if (FlxG.mouse.justPressed)
						selectNote(note);
					else if (FlxG.mouse.justPressedRight)
						deleteNote(note);
				}
			});
		}
		else
			if (FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom]) 
					addNote();
			}

		if (FlxG.keys.justPressed.F1)
			Lib.application.window.alert(ALERT_STRING, ALERT_TITLE_STRING);

		handleInput(dt);

		strumLineNotes.visible = quant.visible = vortex;

		if(FlxG.sound.music.time < 0) 
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) 
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}

		Conductor.songPosition = FlxG.sound.music.time;

		strumLineUpdateY();

		camPos.y = strumLine.y;

		for (i in 0...4)
		{
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
		}

		playbackSpeed = chartingTimescale.pos;

		FlxG.sound.music.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;

		updateUIText(dt);

		var playedSound:Array<Bool> = [false, false, false, false]; //Prevents ouchy GF sex sounds
		curRenderedNotes.forEachAlive(function(note:Note) 
		{
			note.alpha = 1;

			checkSelectedNote(note);

			if(note.strumTime <= Conductor.songPosition) 
			{
				note.alpha = 0.4;
				if(note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1) 
				{
					var data:Int = note.noteData % 4;
					var noteDataToCheck:Int = note.noteData;

					strumLineNotes.members[note.noteData].playAnim('confirm', true);
					strumLineNotes.members[note.noteData].resetAnim = (note.sustainLength / 1000) + 0.15;

					if(!playedSound[data]) 
					{
						if(hitsoundShit[curCharIndex])
						{
							var soundToPlay = 'hitsound';

							FlxG.sound.play(Paths.sound(soundToPlay)).pan = note.noteData < 4? -0.3 : 0.3; //would be coolio
							playedSound[data] = true;
						}
					}
				}
			}
		});

		if (selectedNote != null)
		{
			colorSine += dt;
			var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;

			// Alpha can't be 100% or the color won't be updated for some reason, guess i will die
			selectedNote.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); 
		}

		if(chartingMetronome.selected && lastConductorPos != Conductor.songPosition) 
		{
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);

			if(metroStep != lastMetroStep) 
				FlxG.sound.play(Paths.sound('Metronome_Tick'));
		}

		lastConductorPos = Conductor.songPosition;
		super.update(dt);
	}

	function checkSelectedNote(note:Note)
	{
		if (selectingNote)
			if (noteReference.d == note.noteData && noteReference.ms == note.strumTime)
				selectedNote = note;

		if (selectingEvent)
			if (eventReference[0].strumTime == note.strumTime && note.eventData.length > 0)
				selectedNote = note;
	}

	function updateUIText(dt:Float)
	{
		var curBeat = Std.parseInt(Std.string(curDecBeat).substring(0,4));
		var textBumpAmt:Float = 1.2;

		if (lastData.section != curSec)
		{
			secText.scale.set(textBumpAmt, textBumpAmt);
			secText.updateHitbox();
		}

		if (lastData.beat != curBeat)
		{
			beatText.scale.set(textBumpAmt, textBumpAmt);
			beatText.updateHitbox();

			if (FlxG.sound.music.playing)
			{
				charIndicator.scale.set(1.3, 1.3);
				charIndicator.updateHitbox();
			}
		}

		if (lastData.step != curStep)
		{
			stepText.scale.set(textBumpAmt, textBumpAmt);
			stepText.updateHitbox();
		}

		if (lastData.quant != quantization)
		{
			quantText.scale.set(textBumpAmt, textBumpAmt);
			quantText.updateHitbox();
		}

		lastData.section = curSec;
		lastData.beat = curBeat;
		lastData.step = curStep;
		lastData.quant = quantization;

		var mult:Float = FlxMath.lerp(1, charIndicator.scale.x, CoolUtil.boundTo(1 - (dt * 9 * playbackSpeed), 0, 1));
		charIndicator.scale.set(mult, mult);
		charIndicator.updateHitbox();

		var mult:Float = FlxMath.lerp(1, quantText.scale.x, CoolUtil.boundTo(1 - (dt * 9 * playbackSpeed), 0, 1));
		quantText.text = '${quantization}th';
		quantText.scale.set(mult, mult);
		quantText.updateHitbox();

		var mult:Float = FlxMath.lerp(1, secText.scale.x, CoolUtil.boundTo(1 - (dt * 9 * playbackSpeed), 0, 1));
		secText.text = '${curSec}';
		secText.scale.set(mult, mult);
		secText.updateHitbox();

		var mult:Float = FlxMath.lerp(1, beatText.scale.x, CoolUtil.boundTo(1 - (dt * 9 * playbackSpeed), 0, 1));
		beatText.text = '${curBeat}';
		beatText.scale.set(mult, mult);
		beatText.updateHitbox();

		var mult:Float = FlxMath.lerp(1, stepText.scale.x, CoolUtil.boundTo(1 - (dt * 9 * playbackSpeed), 0, 1));
		stepText.text = '${curStep}';
		stepText.scale.set(mult, mult);
		stepText.updateHitbox();

		var curTime:Float = Math.max(0, Conductor.songPosition - FlxG.save.data.noteOffset);
		var secondsTotal:Int = Math.floor(curTime / 1000);

		timeText.text = FlxStringUtil.formatTime(secondsTotal, false) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, false);
	}

	function updateZoom() 
	{
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if(daZoom < 1) zoomThing = Math.round(1 / daZoom) + ' / 1';
		zoomTxt.text = 'Zoom: ' + zoomThing;
		reloadGridLayer();
	}

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;
	function reloadGridLayer() 
	{
		gridLayer.clear();
		var intCol1 = FlxColor.fromInt(FlxG.save.data.chart_gridCol1);
		var intCol2 = FlxColor.fromInt(FlxG.save.data.chart_gridCol2);
		var col1 = FlxColor.fromRGB(intCol1.red, intCol1.green, intCol1.blue);
		var col2 = FlxColor.fromRGB(intCol2.red, intCol2.green, intCol2.blue);
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 5, Std.int(GRID_SIZE * getSectionBeats() * 4 * zoomList[curZoom]), true, col1, col2);

		#if desktop
		if(FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices)
			updateWaveform();
		#end

		var leHeight:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = false;
		if(sectionStartTime(1) <= FlxG.sound.music.length)
		{
			nextGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 5, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]), true, col1, col2);
			leHeight = Std.int(gridBG.height + nextGridBG.height);
			foundNextSec = true;
		}
		else nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		nextGridBG.y = gridBG.height;

		gridBorder = new FlxSprite(gridBG.x - 2, gridBG.y - 2).makeGraphic(Std.int(gridBG.width + 4), Std.int(gridBG.height + 4), FlxColor.BLACK);
		gridLayer.add(gridBorder);

		nextGridBorder = new FlxSprite(nextGridBG.x - 2, nextGridBG.y - 2).makeGraphic(Std.int(nextGridBG.width + 4), Std.int(nextGridBG.height + 4), FlxColor.BLACK);
		gridLayer.add(nextGridBorder);

		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		if(foundNextSec)
		{
			var gridBlack:FlxSprite = new FlxSprite(0, gridBG.height).makeGraphic(Std.int(GRID_SIZE * 5), Std.int(nextGridBG.height), FlxColor.BLACK);
			gridBlack.alpha = 0.4;
			gridLayer.add(gridBlack);
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width - (GRID_SIZE * 4)).makeGraphic(2, leHeight, FlxColor.BLACK);
		gridLayer.add(gridBlackLine);

		for (i in 1...4) {
			var beatsep1:FlxSprite = new FlxSprite(gridBG.x, (GRID_SIZE * (4 * curZoom)) * i).makeGraphic(Std.int(gridBG.width), 1, 0x44FF0000);
			if(vortex)
			{
				gridLayer.add(beatsep1);
			}
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, leHeight, FlxColor.BLACK);
		gridLayer.add(gridBlackLine);
		updateGrid();

		lastSecBeats = getSectionBeats();
		if(sectionStartTime(1) > FlxG.sound.music.length) lastSecBeatsNext = 0;
		else getSectionBeats(curSec + 1);
	}

	function handleInput(dt:Float)
	{
		if (this.blockInput)
			return;

		if (FlxG.keys.justPressed.ENTER)
		{
			autosaveSong();
			FlxG.mouse.visible = false;
			PlayState.SONG = _song;
			FlxG.sound.music.stop();
			if(vocals != null) vocals.stop();

			StageData.loadDirectory(_song);
			LoadingState.loadAndSwitchState(new PlayState());
		}

		if(selectingNote)
		{
			if (FlxG.keys.justPressed.E)
				ustain(Math.ceil(Conductor.stepCrochet));
			
			if (FlxG.keys.justPressed.Q)
				ustain(-Math.ceil(Conductor.stepCrochet));
		}

		if (FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ESCAPE) 
		{
			PlayState.chartingMode = false;
			LoadingState.loadAndSwitchCustomState('MasterEditorMenu');
			FlxG.sound.playMusic(Paths.getModsMusic('menu_theme'));
			FlxG.mouse.visible = false;
			return;
		}

		if(FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL) {
			--curZoom;
			updateZoom();
		}
		if(FlxG.keys.justPressed.X && curZoom < zoomList.length-1) {
			curZoom++;
			updateZoom();
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			if (FlxG.sound.music.playing)
				pauseSong();
			else
			{
				if(vocals != null) {
					vocals.play();
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
					vocals.play();
				}
				FlxG.sound.music.play();
			}
		}

		if (FlxG.mouse.wheel != 0 && !haxeUIBox.hasComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY))
		{
			FlxG.sound.music.pause();
			if (!mouseQuant)
				FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet*0.8);
			else
				{
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.mouse.wheel > 0)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}else{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
			if(vocals != null) {
				vocals.pause();
				vocals.time = FlxG.sound.music.time;
			}
		}

		if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
		{
			FlxG.sound.music.pause();

			var holdingShift:Float = 1;
			if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
			else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;

			var daTime:Float = 700 * FlxG.elapsed * holdingShift;

			if (FlxG.keys.pressed.W)
			{
				FlxG.sound.music.time -= daTime;
			}
			else
				FlxG.sound.music.time += daTime;

			if(vocals != null) {
				vocals.pause();
				vocals.time = FlxG.sound.music.time;
			}
		}

		if(!vortex)
		{
			if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
			{
				FlxG.sound.music.pause();
				updateCurStep();
				var time:Float = FlxG.sound.music.time;
				var beat:Float = curDecBeat;
				var snap:Float = quantization / 4;
				var increase:Float = 1 / snap;

				var fuck:Float = CoolUtil.quantize(beat, snap) - (FlxG.keys.pressed.UP ? increase : -increase);
				FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
			}
		}

		var style = currentType;

		var conductorTime = Conductor.songPosition; //+ sectionStartTime();Conductor.songPosition / Conductor.stepCrochet;

		//AWW YOU MADE IT SEXY <3333 THX SHADMAR

		if(FlxG.keys.justPressed.RIGHT)
		{
			curQuant++;
			if(curQuant>quantizations.length-1)
				curQuant = 0;

			quantization = quantizations[curQuant];
		}

		if(FlxG.keys.justPressed.LEFT)
		{
			curQuant--;
			if(curQuant<0)
				curQuant = quantizations.length-1;

			quantization = quantizations[curQuant];
		}
		quant.animation.play('q', true, false, curQuant);
		
		var shiftThing:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftThing = 4;

		if (FlxG.keys.justPressed.D)
			changeSection(curSec + shiftThing);

		if (FlxG.keys.justPressed.A) 
		{
			if(curSec <= 0)
				changeSection(_song.sections.length-1);
			else
				changeSection(curSec - shiftThing);
		}

		if (FlxG.keys.justPressed.J)
			changeChar(-1);

		if (FlxG.keys.justPressed.L)
			changeChar(1);
	}

	function strumLineUpdateY()
	{
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / (getSectionBeats() / 4);
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];
	function updateWaveform() 
	{
		#if desktop
		if(waveformPrinted) {
			waveformSprite.makeGraphic(Std.int(GRID_SIZE * 4), Std.int(gridBG.height), 0x00FFFFFF);
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		if(!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformVoices) {
			//trace('Epic fail on the waveform lol');
			return;
		}

		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];

		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		if (FlxG.save.data.chart_waveformInst) 
		{
			var sound:FlxSound = FlxG.sound.music;

			if (sound._sound != null && sound._sound.__buffer != null) {
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();

				wavData = waveformData(
					sound._sound.__buffer,
					bytes,
					st,
					et,
					1,
					wavData,
					Std.int(gridBG.height)
				);
			}
		}

		if (FlxG.save.data.chart_waveformVoices) {
			var sound:FlxSound = vocals;
			if (sound._sound != null && sound._sound.__buffer != null) {
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();

				wavData = waveformData(
					sound._sound.__buffer,
					bytes,
					st,
					et,
					1,
					wavData,
					Std.int(gridBG.height)
				);
			}
		}

		// Draws
		var gSize:Int = Std.int(GRID_SIZE * 4);
		var hSize:Int = Std.int(gSize / 2);

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var size:Float = 1;

		var leftLength:Int = (
			wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length
		);

		var rightLength:Int = (
			wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length
		);

		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		var index:Int;
		for (i in 0...length) {
			index = i;

			lmin = FlxMath.bound(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			lmax = FlxMath.bound(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			rmin = FlxMath.bound(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			rmax = FlxMath.bound(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			var intCol = FlxColor.fromInt(FlxG.save.data.chart_waveformCol);
			var col = FlxColor.fromRGB(intCol.red, intCol.green, intCol.blue);
			waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), i * size, (lmin + rmin) + (lmax + rmax), size), col);
		}

		waveformPrinted = true;
		#end
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null) steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true;//samples > 17200;
		var v1:Bool = false;

		if (array == null) array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1)) {
			if (index >= 0) {
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0) {
					if (sample > lmax) lmax = sample;
				} else if (sample < 0) {
					if (sample < lmin) lmin = sample;
				}

				if (channels >= 2) {
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0) {
						if (sample > rmax) rmax = sample;
					} else if (sample < 0) {
						if (sample < rmin) rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow) {
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
					else array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
					else array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2) {
					if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else {
					if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if(gotIndex > steps) break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}

	function ustain(value:Float):Void
	{
		if (!selectingNote)
			return;

		noteReference.l += Math.ceil(value);
		noteReference.l = Math.max(noteReference.l, 0);
		noteReference.l = Math.ceil(noteReference.l);

		updateGrid();
	}

	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		if(vocals != null) {
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (_song.sections[sec] != null)
		{
			curSec = sec;

			if (updateMusic)
			{
				FlxG.sound.music.pause();

				FlxG.sound.music.time = sectionStartTime();
				if(vocals != null) {
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
				updateCurStep();
			}

			var curSectionBeats:Float = getSectionBeats();
			var nextSectionBeats:Float = getSectionBeats(curSec + 1);
			if(sectionStartTime(1) > FlxG.sound.music.length) nextSectionBeats = 0;
	
			if(curSectionBeats != lastSecBeats || nextSectionBeats != lastSecBeatsNext)
				reloadGridLayer();

			else
				updateGrid();
			
			updateSectionUI();

			updateCharacterUI();
		}

		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
	}

	function changeChar(amt:Int)
	{
		var charLength:Int = characterList.length;
		curCharIndex += amt;

		if (curCharIndex >= charLength)
			curCharIndex = 0;

		else if (curCharIndex < 0)
			curCharIndex = charLength - 1;

		updateGrid();
		updateHeads();

		updateCharacterUI();
	}

	function updateSectionUI():Void
	{
		var sec = _song.sections[curSec];

		// lol!
		if (sectionStepperBeats == null)
			return;

		sectionStepperBeats.pos = getSectionBeats();
		sectionChangeBPM.selected = sec.changeBPM;
		sectionStepperBPM.pos = sec.bpm;

		var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (char in characterList)
			dataSource.add({text: char});

		sectionCharFocus.dataSource = dataSource;
		sectionCharFocus.selectedItem = {text: characterList[sec.charFocus]};

		sectionCopyFrom.dataSource = dataSource;

		updateHeads();
	}

	function updateHeads():Void
	{
		var name:String = characterList[curCharIndex];

		icon.change(name);

		if (name != charIndicator.character)
		{
			FlxTween.cancelTweensOf(indicator_isPlayer);

			indicator_isPlayer.y = charIndicator.y - 10;
			FlxTween.tween(indicator_isPlayer, {y: charIndicator.y}, 0.175, {ease: FlxEase.sineOut});
		}

		charIndicator.change(name);

		if (_song.players.contains(name))
		{
			indicator_isPlayer.x = charIndicator.x + 170;
			indicator_isPlayer.animation.play('player');
		}
		else
		{
			indicator_isPlayer.x = charIndicator.x + 160;
			indicator_isPlayer.animation.play('opponent');
		}
	}

	function updateNoteUI():Void
	{
		if (!selectingNote) 
			return;

		noteSustainStepper.pos = noteReference.l;

		// if note is not a custom note type
		var type:Int = noteTypeMap[noteReference.t];
		if(type <= 0)
			noteTypeSelect.selectedIndex = 0;
		else
			noteTypeSelect.selectedIndex = type;

		noteStrumTime.text = '${noteReference.ms}';
		noteTypeSelect.selectedIndex = type;
		noteDescContent.text = noteTypeDataBase[noteTypeSelect.selectedIndex].desc;
	}

	function updateEventUI()
	{
		if (eventsDropDown == null)
			return;

		if (eventReference == null)
			return;

		eventSelectedText.text = 'Selected: ${selectedEventIndex + 1} / ${eventReference.length}';

		var selected:String = eventReference[selectedEventIndex].event;

		eventsDropDown.selectedItem = {text: selected};

		if(eventStuff.exists(selected))
			eventDescContent.text = eventStuff[selected];
		
		val1Input.text = eventReference[selectedEventIndex].value1;
		val2Input.text = eventReference[selectedEventIndex].value2;
		val3Input.text = eventReference[selectedEventIndex].value3;
	}

	function updateGrid():Void
	{
		Paths.VERBOSE = false;

		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedNoteType.clear();
		nextRenderedNotes.clear();
		nextRenderedSustains.clear();

		otherRenderedNotes.clear();
		otherRenderedSustains.clear();
		otherRenderedIcons.clear();

		// clear notes of each strum
		if (strumLineNotes != null)
			for (strum in strumLineNotes.members)
				strum.associatedNotes = [];

		if (_song.sections[curSec].changeBPM && _song.sections[curSec].bpm > 0)
			Conductor.changeBPM(_song.sections[curSec].bpm);
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;

			for (i in 0...curSec)
				if (_song.sections[i].changeBPM)
					daBPM = _song.sections[i].bpm;

			Conductor.changeBPM(daBPM);
		}

		// CURRENT SECTION
		var beats:Float = getSectionBeats();
		for (char in characterList)
		{
			var charIndex:Int = characterList.indexOf(char);

			for (_note in _song.notes[chartDifficultyString][char])
			{
				if (!noteInSection(_note))
					continue;

				var note:Note = setupNoteData(_note, false);

				if (charIndex == curCharIndex)
				{
					curRenderedNotes.add(note);

					if (note.sustainLength > 0)
						curRenderedSustains.add(setupSusNote(note, beats));

					if(_note.t != null && note.noteType != null && note.noteType.length > 0) 
					{
						var typeInt:Null<Int> = noteTypeMap.get(_note.t);
						var theType:String = '' + typeInt;
						if(typeInt == null) theType = '?';

						var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
						daText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						daText.xAdd = -22;
						daText.yAdd = 12;
						daText.borderSize = 2;
						curRenderedNoteType.add(daText);
						daText.sprTracker = note;
					}

					note.mustPress = _song.sections[curSec].charFocus == curCharIndex;
				}
				else
				{
					var otherNoteCol = 0xFF000000;
					var otherNoteAlpha = noteOpacityShit[charIndex];

					otherRenderedNotes.add(note);
					if (note.sustainLength > 0)
					{
						var sus = setupSusNote(note, beats);

						sus.color = otherNoteCol;
						sus.alpha = otherNoteAlpha;

						otherRenderedSustains.add(sus);
					}

					note.color = otherNoteCol;
					note.alpha = otherNoteAlpha;

					// var icon:HealthIcon = new HealthIcon(characterList[charIndex]);
					// icon.scale.set(0.3, 0.3);
					// icon.updateHitbox();
					// icon.setPosition(note.x + icon.width / 4 + GRID_SIZE * 4, note.y - icon.height / 2 + GRID_SIZE * 6);
					// icon.alpha = otherNoteAlpha;

					// otherRenderedIcons.add(icon);
				}
			}
		}

		// CURRENT EVENTS
		var eventGroups:Map<String, Array<EventNote>> = new Map();

		var i:Int = 1;
		for (_event in _song.events)
		{
			if(!noteInSection(_event))
				continue;

			var string = '${_event.strumTime}';

			if (eventGroups[string] == null)
				eventGroups[string] = [];

			eventGroups[string].push(_event);
		}

		for (strumTime in eventGroups.keys())
		{
			var note:Note = setupEventNote(eventGroups.get(strumTime), false);
			curRenderedNotes.add(note);

			var text:String = '${note.eventName} (${Math.floor(note.strumTime)} ms)\nValue 1: ${note.eventVal1}\nValue 2: ${note.eventVal2}\nValue 3: ${note.eventVal3}';
			if(note.eventLength > 1) text = '${note.eventLength} Events:\n${note.eventName}';

			var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text);
			daText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			daText.xAdd = -410;
			daText.borderSize = 2.5;
			if(note.eventLength > 1) daText.yAdd += 8;
			curRenderedNoteType.add(daText);
			daText.sprTracker = note;
		}

		// NEXT SECTION
		var beats:Float = getSectionBeats(1);
		if(curSec < _song.sections.length - 1) 
		{
			for (_note in curCharNotes)
			{
				if (!noteInSection(_note, 1))
					continue;

				var note:Note = setupNoteData(_note, true);

				note.alpha = 0.6;
				nextRenderedNotes.add(note);

				if (note.sustainLength > 0)
					nextRenderedSustains.add(setupSusNote(note, beats));
			}
		}

		// NEXT EVENTS
		var eventGroups:Map<String, Array<EventNote>> = new Map();

		var i:Int = 1;
		for (_event in _song.events)
		{
			if(!noteInSection(_event, 1))
				continue;

			var string = '${_event.strumTime}';

			if (eventGroups[string] == null)
				eventGroups[string] = [];

			eventGroups[string].push(_event);
		}

		for (strumTime in eventGroups.keys())
		{
			var note:Note = setupEventNote(eventGroups.get(strumTime), true);
			note.alpha = 0.6;
			nextRenderedNotes.add(note);
		}

		updateNoteUI();

		Paths.VERBOSE = true;
	}

	function setupNoteData(_note:NoteFile, isNextSection:Bool):Note
	{
		var note:Note = new Note(Math.ceil(_note.ms), _note.d, null, null, true);
		note.sustainLength = _note.l;
		note.noteType = _note.t;

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(_note.d * GRID_SIZE) + GRID_SIZE;

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = getYfromStrumNotes(Math.ceil(_note.ms) - sectionStartTime(), beats);
		//if(isNextSection) note.y += gridBG.height;
		if(note.y < -150) note.y = -150;
		return note;
	}

	function setupEventNote(notes:Array<EventNote>, isNextSection:Bool):Note
	{
		var note:Note = new Note(Math.ceil(notes[0].strumTime), -1, null, null, true);

		note.loadGraphic(Paths.image('eventArrow'));
		note.eventName = getEventName(notes);
		note.eventLength = notes.length;

		if(notes.length == 1)
		{
			note.eventVal1 = notes[0].value1;
			note.eventVal2 = notes[0].value2;
			note.eventVal3 = notes[0].value3;
		}

		note.eventData = notes;
		
		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(-1 * GRID_SIZE) + GRID_SIZE;

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = getYfromStrumNotes(Math.ceil(notes[0].strumTime - sectionStartTime()), beats);
		//if(isNextSection) note.y += gridBG.height;
		if(note.y < -150) note.y = -150;
		return note;
	}

	function getEventName(notes:Array<EventNote>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...notes.length)
		{
			if(addedOne) retStr += ', ';
			retStr += notes[i].event;
			
			addedOne = true;
		}
		return retStr;
	}

	function setupSusNote(note:Note, beats:Float):FlxSprite {
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom]) + (GRID_SIZE * zoomList[curZoom]) - GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		if(height < 1) height = 1; //Prevents error of invalid height

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		return spr;
	}

	private function addSection(sectionBeats:Float = 4):Void
	{
		var curSection = _song.sections[curSec];

		var sec:SongSection = 
		{
			sectionBeats: sectionBeats,

			bpm: _song.bpm,
			changeBPM: false,

			charFocus: 0
		};

		if (curSection != null)
		{
			sec.bpm = curSection.bpm;
			sec.charFocus = curSection.charFocus;
		}

		_song.sections.push(sec);
	}

	function selectNote(note:Note):Void
	{
		if(note.noteData > -1)
		{
			for (_note in curCharNotes)
			{
				if (!noteInSection(_note))
					continue;

				if (_note.ms != note.strumTime || _note.d != note.noteData)
					continue;

				selectedNote = note;
				selectedNoteReference = _note;

				break;
			}
		}
		else
		{
			var grouping:Array<EventNote> = [];
			for (_event in _song.events)
			{
				if(_event.strumTime != note.strumTime)
					continue;

				grouping.push(_event);
			}

			selectedNote = note;
			selectedNoteReference = grouping;
		}

		changeEventSelected();
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;

		if(note.noteData > -1) //Normal Notes
		{
			for (_note in curCharNotes)
			{
				if (!noteInSection(_note))
					continue;

				if (_note.ms != note.strumTime || _note.d != noteDataToCheck)
					continue;

				if(_note == selectedNoteReference)
					selectedNoteReference = null;

				curCharNotes.remove(_note);
				break;
			}
		}
		else //Events
		{
			for (_event in _song.events)
			{
				if(_event.strumTime != note.strumTime)
					continue;

				if(selectingEvent && eventReference.contains(_event))
				{
					selectedNoteReference = null;
					changeEventSelected();
				}

				_song.events.remove(_event);
				break;
			}
		}

		updateGrid();
	}

	function clearSong():Void
	{
		for (char in characterList)
			_song.notes[chartDifficultyString][char] = [];

		updateGrid();
	}

	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Void
	{
		var noteStrum = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		var noteSus = 0;
		var daAlt = false;

		var typeName = '';
		if (noteTypeSelect.selectedItem != null)
			typeName = noteTypeSelect.selectedItem.text.substr(3);

		var daType = noteTypeMap[typeName];

		if (strum != null) noteStrum = strum;
		if (data != null) noteData = data;
		if (type != null) daType = type;

		if(noteData > -1)
		{
			var newNote:NoteFile =
			{
				d: noteData,
				ms: Math.ceil(noteStrum),
				l: Math.ceil(noteSus),
				t: noteTypeIntMap.get(daType)
			}
			curCharNotes.push(newNote);
			
			selectedNoteReference = newNote;
		}
		else
		{
			var eventName = '';
			if (eventsDropDown.selectedItem != null)
				eventName = eventsDropDown.selectedItem.text;

			var newEvent:EventNote =
			{
				strumTime: Math.ceil(noteStrum),

				event: eventName,

				value1: val1Input.text != null ? val1Input.text : '',
				value2: val2Input.text != null ? val2Input.text : '',
				value3: val3Input.text != null ? val3Input.text : ''
			}

			_song.events.push(newEvent);

			selectedNoteReference = [newEvent];
		}

		changeEventSelected();

		updateGrid();
	}

	var chartDifficultyString(get, never):String;
	function get_chartDifficultyString():String
	{
		var format:String = formattedDifficulties[PlayState.difficulty];
		if (format == null)
			format = 'normal'
		else
			format = format.toLowerCase();

		return format;
	}

	var curCharNotes(get, never):Array<NoteFile>;
	function get_curCharNotes():Array<NoteFile>
	{
		return _song.notes[chartDifficultyString][characterList[curCharIndex]];
	}

	function noteInSection(note:Dynamic, add:Int = 0, verbose:Bool = false):Bool
	{
		var start = sectionStartTime(add);
		var end = sectionStartTime(1 + add);

		if (verbose)
			trace(start, end);

		if (Reflect.hasField(note, 'ms'))
			return end > Math.ceil(note.ms) && Math.ceil(note.ms) >= start;

		if (Reflect.hasField(note, 'strumTime'))
			return end > Math.ceil(note.strumTime) && Math.ceil(note.strumTime) >= start;

		return false;
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return Math.floor(FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet));
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return Math.floor(FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom));
	}
	
	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y;
	}

	function loadJson(song:String):Void
	{
		var songToLoad:SwagSong = Song.loadFromJson(song.toLowerCase());
		if (songToLoad == null)
		{
			Lib.application.window.alert('Chart data not found: ${song}', ALERT_TITLE_STRING);
			return;
		}

		trace('Success :) loaded ${song}');

		PlayState.SONG = songToLoad;

		if (autoLoadData.doIt)
		{
			_song = songToLoad;

			for (seg in [_song.players, _song.opponents])
				for (char in seg)
					characterList.push(char);

			saveLevel();

			FlxG.mouse.visible = false;
			FlxG.sound.music.stop();
			if(vocals != null) vocals.stop();

			StageData.loadDirectory(_song);
			LoadingState.loadAndSwitchState(new PlayState());

			return;
		}

		characterList = [];
		charsAndNames = new Map();

		MusicBeatState.resetHaxeUI();

		// fixes a silly bug, hitting enter while focused on the reload json button makes the charting ui appear in playstate
		if (!MusicBeatState.transitioning)
			FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	function clearEvents() {
		_song.events = [];
		updateGrid();
	}

	private function saveLevel()
	{
		if (Paths.songFolder(_song.song, Paths.WORKING_MOD_DIRECTORY) == null)
		{
			var path:String = '${Paths.mods('songs', Paths.WORKING_MOD_DIRECTORY)}/${_song.song}';
			trace('creating "$path"');

			FileSystem.createDirectory(path);
		}

		// sort notes and events by time

		if(_song.events != null && _song.events.length > 1) 
			_song.events.sort(function(a:EventNote, b:EventNote):Int
			{
				return a.strumTime < b.strumTime ? -1 : a.strumTime > b.strumTime ? 1 : 0;
			});

		for (charNotes in _song.notes[chartDifficultyString])
			charNotes.sort(function(a:NoteFile, b:NoteFile):Int
			{
				return a.ms < b.ms ? -1 : a.ms > b.ms ? 1 : 0;
			});

		var formattedMetadata:SongMetadata = 
		{
			musicians: musiciansTextField != null ? StringTools.trim(musiciansTextField.text).split(',') : [''],
			voiceActors: voiceActorsTextField != null ? StringTools.trim(voiceActorsTextField.text).split(',') : [''],
			charters: chartersTextField != null ? StringTools.trim(chartersTextField.text).split(',') : [''],
			programmers: programmersTextField != null ? StringTools.trim(programmersTextField.text).split(',') : [''],
			additionalArtists: additionalArtistsTextField != null ? StringTools.trim(additionalArtistsTextField.text).split(',') : [''],
			additionalAnimators: additionalAnimatorsTextField != null ? StringTools.trim(additionalAnimatorsTextField.text).split(',') : ['']
		}

		var mainJson:SwagSong = 
		{
			song: _song.song,
			stage: _song.stage,

			metadata: formattedMetadata,

			sections: _song.sections,
			notes: _song.notes,

			events: _song.events,

			bpm: _song.bpm,
			speed: _song.speed,

			needsVoices: _song.needsVoices,

			players: _song.players,
			opponents: _song.opponents,
			autoGF: _song.autoGF,

			countdownType: _song.countdownType,

			validScore: _song.validScore,
		};

		// lol!
		var songPath:String = Paths.songFolder(_song.song, Paths.WORKING_MOD_DIRECTORY);

		var chartData:String = Json.stringify(mainJson, "\t");
		if ((chartData != null) && (chartData.length > 0))
			File.saveContent('$songPath/${_song.song}.json', chartData);

		Lib.application.window.alert('Saved chart ${_song.song}!\n"$songPath/"', ALERT_TITLE_STRING);
	}

	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null) section = curSec;
		var val:Null<Float> = null;
		
		// if(_song.notes[section] != null) val = _song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	function indexOfChar(name:String)
	{
		var char:Int = characterList.indexOf(name);
		trace(char);
		return char;
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(dt:Float)
	{
		super.update(dt);

		if (sprTracker != null) 
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}
