package a2.time.states;

import flixel.graphics.FlxGraphic;

import a2.time.objects.song.Highscore;
import a2.time.objects.song.WeekData;
import a2.time.objects.song.Song;
import a2.time.objects.TimeSprite;
import a2.time.objects.util.CustomFadeTransition;
import a2.time.shader.OverlayShader;
import a2.time.shader.ColorSwap;
import a2.time.util.Discord.DiscordClient;
import a2.time.util.ClientPrefs;
import a2.time.util.Paths;
import a2.time.util.CoolUtil;
import a2.time.util.HscriptManager;
import a2.time.util.UIShortcuts as UiS;

import a2.time.objects.song.Section.SongSection;
import a2.time.objects.song.Song.SwagSong;
import a2.time.objects.song.StageData;
import a2.time.objects.song.Conductor;
import a2.time.objects.song.StrumNote;
import a2.time.states.editors.ChartingState;
import a2.time.states.editors.CharacterEditorState;
import a2.time.objects.gameplay.CameraManager;
import a2.time.objects.gameplay.Character;
import a2.time.objects.gameplay.Boyfriend;
import a2.time.objects.gameplay.HealthIcon;
import a2.time.objects.gameplay.Note;
import a2.time.objects.gameplay.Note.EventNote;
import a2.time.objects.ui.AttachedSprite;
import a2.time.shader.WiggleEffect.WiggleEffectType;
import a2.time.shader.Shaders;

import openfl.utils.ByteArray;
import flash.media.Sound as FlashSound;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxSpriteUtil;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.FlxFlicker;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxSave;
import flixel.animation.FlxAnimationController;
import animateatlas.AtlasFrameMaker;
import hscript.Interp;
import hscript.Parser;
import hscript.ParserEx;
import hscript.InterpEx;
import hscript.ClassDeclEx;
import lime.ui.MouseButton;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Window;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.display.Sprite;
import openfl.utils.Assets;
import openfl.Lib;
import flixel.input.mouse.FlxMouse;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.effects.particles.FlxParticle;
import openfl.system.Capabilities;

import flash.filters.BlurFilter;
import flixel.graphics.frames.FlxFilterFrames;

#if sys
import sys.io.File;
import sys.FileSystem;
import Sys;
import Sys.command;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
#end

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

import a2.time.objects.util.MP4Handler;

import haxe.ui.containers.windows.WindowManager;

using StringTools;

typedef RimLightFile =
{
	var lights:Array<CharacterRimLightFile>;
}

typedef CharacterRimLightFile =
{
	var satinCol:Array<Float>;
	var innerCol:Array<Float>;
	var overlayCol:Array<Float>;

	var angle:Float;
	var dist:Float;

	var name:String;
}

typedef ShadowFile =
{
	var simplified:Bool;
	var shadows:Array<CharacterShadowFile>;
}

typedef CharacterShadowFile =
{
	var alpha:Float;

	var baseOffset:Array<Float>;
	var offsets:Map<String, Array<Float>>;

	var baseSkew:Array<Float>;
	var skews:Map<String, Array<Float>>;

	var baseScale:Array<Float>;
	var scales:Map<String, Array<Float>>;

	var name:String;
}

enum CharacterPosition
{
	BEHIND_GF;
	BEHIND_BF;
	BEHIND_DAD;
	BEHIND_ALL;
	BEHIND_NONE;
}

class PlayState extends MusicBeatState
{
	// for hscript stuff yea
	public var canMoveCamera:Bool = true;

	var rtxWindow:haxe.ui.containers.windows.Window;
	var debugWindow:haxe.ui.containers.windows.Window;

	var shadowWindow:haxe.ui.containers.windows.Window;
	var shadowIndex:Int = 0;

	var shadeNameInput:haxe.ui.components.TextField;
	var shadeCharSelect:haxe.ui.containers.ListView;

	var overlayColPicker:haxe.ui.components.ColorPicker;
	var satinColPicker:haxe.ui.components.ColorPicker;
	var innerColPicker:haxe.ui.components.ColorPicker;

	var overlayAlphaSlider:haxe.ui.components.HorizontalSlider;
	var satinAlphaSlider:haxe.ui.components.HorizontalSlider;
	var innerAlphaSlider:haxe.ui.components.HorizontalSlider;

	var innerAngleSlider:haxe.ui.components.HorizontalSlider;
	var innerDistSlider:haxe.ui.components.HorizontalSlider;

	var shadowAnimSelect:haxe.ui.containers.ListView;

	var simplifiedShadows:haxe.ui.components.CheckBox;

	var shadowAlphaSlider:haxe.ui.components.HorizontalSlider;

	var baseOffsetXSlider:haxe.ui.components.HorizontalSlider;
	var baseOffsetYSlider:haxe.ui.components.HorizontalSlider;

	var baseShadowWidthSlider:haxe.ui.components.HorizontalSlider;
	var baseShadowHeightSlider:haxe.ui.components.HorizontalSlider;

	var baseSkewXSlider:haxe.ui.components.HorizontalSlider;
	var baseSkewYSlider:haxe.ui.components.HorizontalSlider;

	var shadowWidthSlider:haxe.ui.components.HorizontalSlider;
	var shadowHeightSlider:haxe.ui.components.HorizontalSlider;

	var skewXSlider:haxe.ui.components.HorizontalSlider;
	var skewYSlider:haxe.ui.components.HorizontalSlider;

	var offsetXSlider:haxe.ui.components.HorizontalSlider;
	var offsetYSlider:haxe.ui.components.HorizontalSlider;

	var animShadowCopy:Dynamic =
	{
		offsets: [0, 0],
		skews: [0, 0],
		scales: [0, 0]
	}

	var rimLightCopy:Dynamic =
	{
		overlay: [0, 0, 0, 0],
		satin: [0, 0, 0, 0],
		inner: [0, 0, 0, 0],

		angle: 0,
		dist: 0
	}

	var editingRimLight:Bool = false;
	public var editingShadows:Bool = false;

	var editingMode:Bool = false;

	var rtxSaveButton:haxe.ui.components.Button;
	var rtxResetButton:haxe.ui.components.Button;

	var timescaleSlider:haxe.ui.components.HorizontalSlider;
	var botplayBox:haxe.ui.components.CheckBox;
	var editModeBox:haxe.ui.components.CheckBox;

	var hudBox:haxe.ui.components.CheckBox;

	public static var instance:PlayState;
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	var dadCol:FlxColor;
	var bfCol:FlxColor;
	var gfCol:FlxColor;

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	public var spriteZone:Map<String, FlxSprite> = new Map();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartVideos:Map<String, MP4Handler> = new Map<String, MP4Handler>();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var spriteZone:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartSaves:Map<String, FlxSave> = new Map();
	public var modchartVideos:Map<String, MP4Handler> = new Map();
	#end

	public var doFNFCountdown:Bool = true;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var cfDuration:Float = 0.75;
	public var cfIntensity:Float = 1.0;
	public var cfBlend:String = "add";

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var playerGroup:FlxSpriteGroup;
	public var opponentGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public var gf:Character = null;

	public var characters:Array<Character> = [];
	public var charNames:Array<String> = [];

	private var charFocus:Int = 0;
	private var curBF:Int = 0;
	private var curDAD:Int = 0;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;

	public static var videoToPlay:String = '';

	public static var SONG:SwagSong = null;
	var allEvents:Array<String> = [];

	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public static var difficulty:String = '';

	public var spawnTime:Float = 2000;

	public var pauseNotesMoving:Bool = false;

	public var vocals:FlxSound;

	public var customGameOver:Bool = false;
	public static var customGameOverChar:String = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;

	public var strumPositions:Array<FlxPoint> = [];

	public var camManager:CameraManager = new CameraManager();
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	var songPercent:Float = 0;

	public var clock:Float = 0;

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	public var debugMode:Bool = false;

	var ignoreEventHscript:Array<String> = [];

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var camOther2:FlxCamera;

	public var trailDadOverride:Bool = false;

	var heyTimer:Float;

	public var iconOverride:Bool = false;

	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var SING_ANIMATIONS:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var playerCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	public var shaderUpdates:Array<Float->Void> = [];
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];

	// Lua shit
	public var introSoundsSuffix:String = '';
	public var countdownSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	var precacheList:Map<String, String> = new Map<String, String>();

	public var marketableShakeIntensity:Float = 0;
	
	public var windowsUser:String = "";

	function getHaxeActor(name:String):Dynamic {
		switch (name) {
			case "boyfriend" | "bf":
				return 'lol';
			case "girlfriend" | "gf":
				return gf;
			case "dad":
				return 'LOL';
			default:
				return strumLineNotes.members[Std.parseInt(name)];
		}
	}

	var hscriptManager:HscriptManager;
	function playstateInterp(interp:Interp) 
	{
		// set vars
		interp.variables.set("BEHIND_GF", CharacterPosition.BEHIND_GF);
		interp.variables.set("BEHIND_BF", CharacterPosition.BEHIND_BF);
		interp.variables.set("BEHIND_DAD", CharacterPosition.BEHIND_DAD);
		interp.variables.set("BEHIND_ALL", CharacterPosition.BEHIND_ALL);
		interp.variables.set("BEHIND_NONE", CharacterPosition.BEHIND_NONE);

		interp.variables.set("videoToPlay", videoToPlay);
		interp.variables.set("preEndSong", function() {});

		// interp.variables.set('uiLayer', uiLayer);

		interp.variables.set("charFocus", charFocus);

		interp.variables.set('precache', function(path:String, type:String)
		{
			precacheList.set(path, type);
		});

		interp.variables.set("difficulty", storyDifficulty);
		interp.variables.set("isDemoMode", cpuControlled);
		interp.variables.set("Sys", Sys);
		interp.variables.set("bpm", Conductor.bpm);
		interp.variables.set('SONG', SONG);
		interp.variables.set("curSong", SONG.song);

		interp.variables.set("songLength", songLength);
		interp.variables.set("curStep", 0);
		interp.variables.set("curBeat", 0);
		interp.variables.set("camHUD", camHUD);
		interp.variables.set("camOther", camOther);
		interp.variables.set("camOther2", camOther2);
		interp.variables.set("playerStrums", playerStrums);
		interp.variables.set("enemyStrums", opponentStrums);

		interp.variables.set("mustHitSection", false);
		interp.variables.set("gfSection", false);

		interp.variables.set('SING_ANIMATIONS', SING_ANIMATIONS);

		interp.variables.set("strumLineY", strumLine.y);
		interp.variables.set("pauseNotesMoving", pauseNotesMoving);
		interp.variables.set("setGameOverChar", setGameOverChar);
		interp.variables.set("getEmitterMode", getEmitterMode);
		interp.variables.set("triggerEventNote", triggerEventNote);
		interp.variables.set("FlxCamera", FlxCamera);
		interp.variables.set("customGameOverChar", customGameOverChar);

		for (i in 0...charNames.length)
		{
			var curName = charNames[i];
			var char = characters[i];

			interp.variables.set('char_${StringTools.replace(curName, '-', '_')}', char);
		}

		interp.variables.set("gf", gf);

		interp.variables.set("colFromInt", FlxColor.fromInt);

		// literally for marketable
		interp.variables.set("FlxSpriteUtil", FlxSpriteUtil);
		interp.variables.set('HealthIcon', HealthIcon);
		interp.variables.set('marketableShakeIntensity', marketableShakeIntensity);

		interp.variables.set("FlxBarFillDirection", FlxBarFillDirection);
		interp.variables.set("TRANSPARENT", FlxColor.TRANSPARENT);

		interp.variables.set('OUTLINE', FlxTextBorderStyle.OUTLINE);

		interp.variables.set("vocals", vocals);
		interp.variables.set("gfSpeed", gfSpeed);
		interp.variables.set("health", health);
		interp.variables.set("game", this);
		interp.variables.set("clock", clock);
		interp.variables.set("PlayState", PlayState);
		interp.variables.set("windowsUser", windowsUser);
		interp.variables.set("makeText", function (posx:Float, posy:Float, fwidth:Float, ?text:String, size:Int = 8, embFont:Bool = true) {
			return (new FlxText(posx, posy, fwidth, text, size, embFont)); //make text in hcripts
		});
		interp.variables.set("window", Lib.application.window);
		// give them access to save data, everything will be fine ;)

		interp.variables.set("camManager", camManager);

		// callbacks
		interp.variables.set("start", function (song) {});
		interp.variables.set("beatHit", function (beat) {});
		interp.variables.set("update", function (elapsed) {});
		interp.variables.set("endUpdate", function (elapsed) {});
		interp.variables.set("stepHit", function(step) {});

		interp.variables.set('spawnNoteSplash', function(x, y, data) {});

		interp.variables.set("bfDance", function() {});
		interp.variables.set("dadDance", function() {});
		interp.variables.set("gfDance", function() {});

		interp.variables.set("blendModeFromString", blendModeFromString);
		interp.variables.set("goodNoteHit", function(id:Note, direction:Int, noteType:String, isSustainNote:Bool, isPlayer:Bool) {});
		interp.variables.set("opponentNoteHit", function(id:Note, direction:Int, noteType:String, isSustainNote:Bool) {});

		interp.variables.set("addSprite", function (sprite:FlxSprite, position:CharacterPosition) 
		{
			switch(position)
			{
				case BEHIND_ALL, BEHIND_GF:
					addBehindGF(sprite);

				case BEHIND_BF:
					addBehindBF(sprite);

				case BEHIND_DAD:
					addBehindDad(sprite);

				case BEHIND_NONE:
					add(sprite);
			}	
		});

		interp.variables.set("add", add);
		interp.variables.set("remove", remove);
		interp.variables.set("insert", insert);
		interp.variables.set("replace", replace);
		interp.variables.set("setDefaultZoom", function(zoom:Float){
			camManager.defaultZoom = zoom;
			FlxG.camera.zoom = zoom;
		});
		interp.variables.set("removeSprite", function(sprite) {
			remove(sprite);
		});
		interp.variables.set("getHaxeActor", getHaxeActor);
		interp.variables.set("onEvent", function (eventName:String, value1:Dynamic, value2:Dynamic, value3:Dynamic) {});
		interp.variables.set("notes", notes);

		//Shader Shit
		interp.variables.set("addPulseEffect", addPulseEffect);
		interp.variables.set("addDistortionEffect", addDistortionEffect);
		interp.variables.set("addVCREffect", addVCREffect);
		interp.variables.set("addInvertEffect", addInvertEffect);
		interp.variables.set("addGrayScaleEffect", addGrayScaleEffect);
		interp.variables.set("addScanLineEffect", addScanLineEffect);
		interp.variables.set("addChromaticAberrationEffect", addChromaticAberrationEffect);
		interp.variables.set("OverlayShader", OverlayShader);
		interp.variables.set("ColorSwap", ColorSwap);
		interp.variables.set("ShaderFilter", ShaderFilter);
		interp.variables.set("clearShaderFromCamera", clearShaderFromCamera);
		interp.variables.set("createRuntimeShader", createRuntimeShader);
        interp.variables.set("initShader", initShader);
		interp.variables.set("getColorFromString", getColorFromString);
		
		interp.variables.set("onEndSong", function() {});

		interp.variables.set('setStrumPos', function(player:Bool, receptor:Int, x:Float, y:Float)
		{
			var strumsToChange:FlxTypedGroup<StrumNote> = player ? playerStrums : opponentStrums;

			var recep = strumsToChange.members[receptor];

			recep.x = x;
			recep.y = y;
		});

		interp.variables.set("screenResolutionX", Capabilities.screenResolutionX);
		interp.variables.set("screenResolutionY", Capabilities.screenResolutionY);

		interp.variables.set('char', char);

		interp.variables.set('applyRtxShader', function(sprite:FlxSprite) {});

		interp.variables.set('addToScripts', function(name:String, object:Dynamic)
		{
			hscriptManager.setAll(name, object);
		});
	}

	function formatSongDifficulty(dif:String)
	{
		if (dif == '')
			return 'normal';

		return dif.toLowerCase();
	}

	function setGameOverChar(help:String)
	{
        customGameOverChar = help;
	}

	function getColorFromString(color:String)
    {
        return FlxColor.fromString(color);
		// this is just because FlxColor is an abstract. can't use it on hscript, so if i put the function here it will run through playstate and will work
	}

	function getEmitterMode(emitter:String)
        {
	if (emitter == "square") 
	   {
	   return FlxEmitterMode.SQUARE;
	   } else if (emitter == "circle") {
	   return FlxEmitterMode.SQUARE;
           } else {
	   return null;
	   trace("Emitter mode could not be found!");
	   }
        }

	function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
			case 'normal': return NORMAL;
		}
		return NORMAL;
	}

	public function addShaderToCam(cam:String,effect:ShaderEffect)
	{ //STOLE FROM ANDROMEDA AND PSYCH ENGINE 0.5.1 WITH SHADERS

		switch(cam.toLowerCase()) 
		{
			case 'camhud' | 'hud':
					camHUDShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camHUDShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camHUD.setFilters(newCamEffects);
			default:
					camGameShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camGameShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camGame.setFilters(newCamEffects);
		}
	}

	public function addSpriteShader(sprite:FlxSprite, effect:ShaderEffect)
	{
		sprite.shader = effect.shader;
	}

	public function removeShaderFromCamera(cam:String, effect:ShaderEffect)
	{
		switch(cam.toLowerCase()) 
		{
			case 'camhud' | 'hud': 
				camHUDShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camHUDShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camHUD.setFilters(newCamEffects);
			default: 
				camGameShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camGameShaders){
				  newCamEffects.push(new ShaderFilter(i.shader));
				}
				camGame.setFilters(newCamEffects);
		}
	}

	public function clearShaderFromCamera(cam:String)
	{
		switch(cam.toLowerCase()) 
		{
			case 'camhud' | 'hud': 
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camHUD.setFilters(newCamEffects);
			default: 
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camGame.setFilters(newCamEffects);
		}
	}

	//SHADERS STUFF

	public function addPulseEffect(dest:String, sprite:Null<FlxSprite> = null, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
	{
		switch (dest.toLowerCase())
		{
			case 'camhud', 'hud', 'camgame', 'game', 'shadercam':
				addShaderToCam(dest, new PulseEffect(waveSpeed,waveFrq,waveAmp));
			default:
				if (sprite != null)
					sprite.shader = (new PulseEffect(waveSpeed,waveFrq,waveAmp)).shader;
		}
	}

	public function addDistortionEffect(dest:String, sprite:Null<FlxSprite> = null, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
	{
		switch (dest.toLowerCase())
		{
			case 'camhud', 'hud', 'camgame', 'game', 'shadercam':
				addShaderToCam(dest, new DistortBGEffect(waveSpeed,waveFrq,waveAmp));
			default:
				if (sprite != null)
					sprite.shader = (new DistortBGEffect(waveSpeed,waveFrq,waveAmp)).shader;
		}
	}

	public function addVCREffect(dest:String, sprite:Null<FlxSprite> = null, glitchFactor:Float = 1, distortion:Bool = true, perspectiveOn:Bool = true, vignetteMoving:Bool = true)
	{
		switch (dest.toLowerCase())
		{
			case 'camhud', 'hud', 'camgame', 'game', 'shadercam':
				addShaderToCam(dest, new VCRDistortionEffect(glitchFactor,distortion,perspectiveOn,vignetteMoving));
			default:
				if (sprite != null)
					sprite.shader = (new VCRDistortionEffect(glitchFactor,distortion,perspectiveOn,vignetteMoving)).shader;
		}
	}

	public function addInvertEffect(dest:String, sprite:Null<FlxSprite> = null, lockAlpha:Bool = false)
	{
		switch (dest.toLowerCase())
		{
			case 'camhud', 'hud', 'camgame', 'game', 'shadercam':
				addShaderToCam(dest, new InvertColorsEffect(lockAlpha));
			default:
				if (sprite != null)
					sprite.shader = (new InvertColorsEffect(lockAlpha)).shader;
		}
	}

	public function addGrayScaleEffect(dest:String, sprite:Null<FlxSprite> = null)
	{
		switch (dest.toLowerCase())
		{
			case 'camhud', 'hud', 'camgame', 'game', 'shadercam':
				addShaderToCam(dest, new GreyscaleEffect());
			default:
				if (sprite != null)
					sprite.shader = (new GreyscaleEffect()).shader;
		}
	}

	public function addScanLineEffect(dest:String, sprite:Null<FlxSprite> = null, lockAlpha:Bool = false)
	{
		switch (dest.toLowerCase())
		{
			case 'camhud', 'hud', 'camgame', 'game', 'shadercam':
				addShaderToCam(dest, new ScanlineEffect(lockAlpha));
			default:
				if (sprite != null)
					sprite.shader = (new ScanlineEffect(lockAlpha)).shader;
		}
	}

	public function addChromaticAberrationEffect(dest:String, sprite:Null<FlxSprite> = null, offset:Float = 0.03)
	{
		switch (dest.toLowerCase())
		{
			case 'camhud', 'hud', 'camgame', 'game', 'shadercam':
				addShaderToCam(dest, new ChromaticAberrationEffect(offset));
			default:
				if (sprite != null)
					sprite.shader = (new ChromaticAberrationEffect(offset)).shader;
		}
	}

	override public function create()
	{
		Paths.clearStoredMemory();

		instance = this;

		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		keysArray = [
			ClientPrefs.keyBinds.get('note_left'),
			ClientPrefs.keyBinds.get('note_down'),
			ClientPrefs.keyBinds.get('note_up'),
			ClientPrefs.keyBinds.get('note_right')
		];

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camOther2 = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camOther2.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther2, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
		{
			Lib.application.window.alert('Chart data does not exist, maybe you need to convert this song to the new chart format?', Main.ALERT_TITLE);
			LoadingState.loadAndSwitchState(new ChartingState());
		}

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		var songName:String = SONG.song;

		curStage = SONG.stage;
		if(SONG.stage == null || SONG.stage.length < 1) 
			curStage = 'stage';
		
		SONG.stage = curStage;

		var envs = Sys.environment();
        windowsUser = envs['USERNAME'];

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		camManager.defaultZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			camManager.speed = stageData.camera_speed;

		playerCameraOffset = stageData.camera_boyfriend;
		if(playerCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			playerCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		playerGroup = new FlxSpriteGroup(BF_X, BF_Y);
		opponentGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		if(isPixelStage) 
			introSoundsSuffix = '-pixel';

		add(gfGroup);

		add(opponentGroup);
		add(playerGroup);

		var gfVersion:String = SONG.autoGF;

		gf = new Character(0, 0, gfVersion);
		startCharacterPos(gf);
		gf.visible = !stageData.hide_girlfriend;
		gfGroup.add(gf.shadowChar);
		gfGroup.add(gf.simpleShadow);
		gfGroup.add(gf.trailChar);
		gfGroup.add(gf);

		for (char in SONG.players)
		{
			var player:Boyfriend = new Boyfriend(0, 0, char);
			startCharacterPos(player);

			playerGroup.add(player.shadowChar);
			playerGroup.add(player.simpleShadow);
			playerGroup.add(player.trailChar);
			playerGroup.add(player);

			characters.push(player);
			charNames.push(char);
		}

		for (char in SONG.opponents)
		{
			var guy:Character = new Character(0, 0, char);
			startCharacterPos(guy);

			opponentGroup.add(guy.shadowChar);
			opponentGroup.add(guy.simpleShadow);
			opponentGroup.add(guy.trailChar);
			opponentGroup.add(guy);

			characters.push(guy);
			charNames.push(char);
		}

		charNames.push(gf.name);

		updateCharCols();

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.data.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		FlxG.camera.follow(camManager.currentPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = camManager.defaultZoom;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection();

		reloadHealthBarColors();

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		var daSong:String = curSong;
		if (!seenCutscene)
		{
			if (videoToPlay == '')
				startCountdown();

			else
				startVideo(videoToPlay);

			seenCutscene = true;
		}
		else
		{
			if (videoToPlay == '')
				startCountdown();

			else
				startVideo(videoToPlay);
		}

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.data.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		precacheList.set('alphabet', 'image');
	
		#if desktop
		DiscordClient.changePresence('In Game', SONG.song);
		#end

		if(!controls.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		hscriptManager.callAll('postStart', [SONG.song]);

		super.create();

		cacheCountdown();

		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		Paths.clearUnusedMemory();
		
		CustomFadeTransition.nextCamera = camOther;

		// HAXE UI STUFF
		var layoutBox = new haxe.ui.containers.HBox();

		var source = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (char in charNames)
			source.add({text: char});

		shadeCharSelect = new haxe.ui.containers.ListView();
		shadeCharSelect.dataSource = source;
		shadeCharSelect.width = 200;
		shadeCharSelect.height = 50;
		shadeCharSelect.selectedIndex = 0;

		rtxWindow = new haxe.ui.containers.windows.Window();
		rtxWindow.title = 'RTX Editor';

		rtxWindow.closable = false;
		rtxWindow.minimizable = true;
		rtxWindow.maximizable = false;
		rtxWindow.draggable = true;

		overlayColPicker = new haxe.ui.components.ColorPicker();
		satinColPicker = new haxe.ui.components.ColorPicker();
		innerColPicker = new haxe.ui.components.ColorPicker();

		overlayAlphaSlider = new haxe.ui.components.HorizontalSlider();
		satinAlphaSlider = new haxe.ui.components.HorizontalSlider();
		innerAlphaSlider = new haxe.ui.components.HorizontalSlider();

		var pickers = [overlayColPicker, satinColPicker, innerColPicker];
		var sliders = [overlayAlphaSlider, satinAlphaSlider, innerAlphaSlider];

		var pickerLabels = ['Overlay', 'Satin', 'Inner'];

		var i:Int = 0;
		var pickerSize:Int = 150;
		for (picker in pickers)
		{
			picker.styleNames = 'no-controls';

			picker.width = pickerSize;
			picker.height = pickerSize;

			var pickerBox = new haxe.ui.containers.VBox();

			var label = new haxe.ui.components.Label();
			label.text = '${pickerLabels[i]} RGB';

			sliders[i].min = 0;
			sliders[i].max = 1;

			sliders[i].width = pickerSize;

			var alphaLabel = new haxe.ui.components.Label();
			alphaLabel.text = '${pickerLabels[i]} Alpha';

			//
			pickerBox.addComponent(label);
			pickerBox.addComponent(picker);

			pickerBox.addComponent(new haxe.ui.components.Spacer());

			pickerBox.addComponent(alphaLabel);
			pickerBox.addComponent(sliders[i]);
			//

			layoutBox.addComponent(pickerBox);

			i++;
		}

		// sliders
		var sliderBox = new haxe.ui.containers.HBox();

		var angleBox = new haxe.ui.containers.VBox();
		innerAngleSlider = new haxe.ui.components.HorizontalSlider();

		innerAngleSlider.min = 0;
		innerAngleSlider.max = 360;

		innerAngleSlider.width = layoutBox.width / 2;

		var angleLabel = new haxe.ui.components.Label();
		angleLabel.text = 'Inner Angle';

		angleBox.addComponent(angleLabel);
		angleBox.addComponent(innerAngleSlider);

		var distBox = new haxe.ui.containers.VBox();
		innerDistSlider = new haxe.ui.components.HorizontalSlider();

		innerDistSlider.width = layoutBox.width / 2;

		innerDistSlider.min = 0;
		innerDistSlider.max = 50;

		var distLabel = new haxe.ui.components.Label();
		distLabel.text = 'Inner Distance';

		angleBox.addComponent(distLabel);
		angleBox.addComponent(innerDistSlider);

		sliderBox.addComponent(angleBox);
		sliderBox.addComponent(distBox);
		//

		shadeCharSelect.onChange = function(e)
		{
			if (shadeCharSelect.selectedItem == null)
				return;

			var light = char(shadeCharSelect.selectedItem.text).rimLightShader;

			if (light == null)
				return;

			var overlayCol:Array<Float> = light.getFloatArray('overlayColor');
			var satinCol:Array<Float> = light.getFloatArray('satinColor');
			var innerCol:Array<Float> = light.getFloatArray('innerShadowColor');

			if (overlayCol == null)
				return;

			overlayColPicker.currentColor = Std.int(FlxColor.fromRGBFloat(overlayCol[0], overlayCol[1], overlayCol[2]).to24Bit());
			satinColPicker.currentColor = Std.int(FlxColor.fromRGBFloat(satinCol[0], satinCol[1], satinCol[2]).to24Bit());
			innerColPicker.currentColor = Std.int(FlxColor.fromRGBFloat(innerCol[0], innerCol[1], innerCol[2]).to24Bit());

			overlayAlphaSlider.pos = overlayCol[3];
			satinAlphaSlider.pos = satinCol[3];
			innerAlphaSlider.pos = innerCol[3];

			innerAngleSlider.pos = light.getFloat('innerShadowAngle');
			innerDistSlider.pos = light.getFloat('innerShadowDistance');
		}

		// button shit
		var buttonBox = new haxe.ui.containers.HBox();

		rtxSaveButton = new haxe.ui.components.Button();
		rtxSaveButton.text = 'Save';
		rtxSaveButton.onClick = saveRimLighting;

		rtxResetButton = new haxe.ui.components.Button();
		rtxResetButton.text = 'Reload';
		rtxResetButton.onClick = function(e) { loadRimLightJson(); }

		buttonBox.addComponent(rtxSaveButton);
		buttonBox.addComponent(rtxResetButton);
		UiS.addVR(7, buttonBox);

		var rimCopyButton = new haxe.ui.components.Button();
		rimCopyButton.text = 'Copy';

		var rimPasteButton = new haxe.ui.components.Button();
		rimPasteButton.text = 'Paste';
		rimPasteButton.disabled = true;

		rimCopyButton.onClick = function(e)
		{
			if (shadeCharSelect.selectedItem == null)
				return;

			var light = char(shadeCharSelect.selectedItem.text).rimLightShader;

			rimLightCopy.overlay = light.getFloatArray('overlayColor');
			rimLightCopy.satin = light.getFloatArray('satinColor');
			rimLightCopy.inner = light.getFloatArray('innerShadowColor');

			rimLightCopy.alpha = light.getFloat('innerShadowAngle');
			rimLightCopy.dist = light.getFloat('innerShadowDistance');

			rimPasteButton.disabled = false;
		}

		rimPasteButton.onClick = function(e)
		{
			var overlayCol:Array<Float> = rimLightCopy.overlay;
			var satinCol:Array<Float> = rimLightCopy.satin;
			var innerCol:Array<Float> = rimLightCopy.inner;

			overlayColPicker.currentColor = Std.int(FlxColor.fromRGBFloat(overlayCol[0], overlayCol[1], overlayCol[2]).to24Bit());
			satinColPicker.currentColor = Std.int(FlxColor.fromRGBFloat(satinCol[0], satinCol[1], satinCol[2]).to24Bit());
			innerColPicker.currentColor = Std.int(FlxColor.fromRGBFloat(innerCol[0], innerCol[1], innerCol[2]).to24Bit());

			overlayAlphaSlider.pos = overlayCol[3];
			satinAlphaSlider.pos = satinCol[3];
			innerAlphaSlider.pos = innerCol[3];

			innerAngleSlider.pos = rimLightCopy.angle;
			innerDistSlider.pos = rimLightCopy.dist;
		}

		buttonBox.addComponent(rimCopyButton);
		buttonBox.addComponent(rimPasteButton);
		//

		var nameBox = new haxe.ui.containers.HBox();

		var shadeLabel = new haxe.ui.components.Label();
		shadeLabel.text = 'shade';
		shadeLabel.verticalAlign = 'center';
		nameBox.addComponent(shadeLabel);

		shadeNameInput = new haxe.ui.components.TextField();
		shadeNameInput.width = 100;
		shadeNameInput.text = '';
		shadeNameInput.onChange = function(e)
		{
			if (shadeNameInput.text == '' || shadeNameInput.text == null)
			{
				shadeLabel.text = 'shade';
				return;
			}

			shadeLabel.text = 'shade-';
		}
		nameBox.addComponent(shadeNameInput);

		var jsonLabel = new haxe.ui.components.Label();
		jsonLabel.text = '.json';
		jsonLabel.verticalAlign = 'center';
		nameBox.addComponent(jsonLabel);

		rtxWindow.addComponent(nameBox);
		UiS.addHR(7, rtxWindow);
		rtxWindow.addComponent(shadeCharSelect);
		UiS.addHR(7, rtxWindow);
		rtxWindow.addComponent(layoutBox);

		var spacer = new haxe.ui.components.Spacer();
		spacer.height = 25;
		rtxWindow.addComponent(spacer);

		rtxWindow.addComponent(sliderBox);

		var spacer = new haxe.ui.components.Spacer();
		spacer.height = 25;
		rtxWindow.addComponent(spacer);
		
		rtxWindow.addComponent(buttonBox);
		//

		initShader('rimLighting');
		for (char in characters)
		{
			char.rimLightShader = createRuntimeShader('rimLighting');

			char.shader = char.rimLightShader;
			char.trailChar.shader = char.rimLightShader;
		}

		// forgot this one LOL
		gf.rimLightShader = createRuntimeShader('rimLighting');
		gf.shader = gf.rimLightShader;
		gf.trailChar.shader = gf.rimLightShader;

		loadRimLightJson();

		// DEBUG MENU
		var debugBox = new haxe.ui.containers.VBox();

		debugWindow = new haxe.ui.containers.windows.Window();
		debugWindow.title = 'Debug Menu';

		debugWindow.closable = false;
		debugWindow.minimizable = true;
		debugWindow.maximizable = false;
		debugWindow.draggable = true;

		botplayBox = new haxe.ui.components.CheckBox();
		botplayBox.selected = cpuControlled;
		botplayBox.text = 'Botplay';
		botplayBox.onClick = function(e) { cpuControlled = botplayBox.selected; }

		editModeBox = new haxe.ui.components.CheckBox();
		editModeBox.selected = false;
		editModeBox.text = 'Edit Mode';
		editModeBox.onClick = function(e)
		{
			editingMode = editModeBox.selected;

			switch(editingMode)
			{
				case true:
					camManager.halt();
					editZoom = FlxG.camera.zoom;

				case false:
					camManager.unlock();
			}

		}

		debugBox.addComponent(botplayBox);

		hudBox = new haxe.ui.components.CheckBox();
		hudBox.selected = camHUD.visible;
		hudBox.text = 'HUD Visible';
		hudBox.onClick = function(e) { camHUD.visible = hudBox.selected; }

		debugBox.addComponent(hudBox);

		var timescaleBox = new haxe.ui.containers.VBox();

		timescaleSlider = new haxe.ui.components.HorizontalSlider();
		timescaleSlider.min = 0;
		timescaleSlider.max = 5;

		timescaleSlider.pos = 1;

		var timescaleLabel = new haxe.ui.components.Label();
		timescaleLabel.text = 'Timescale';

		var resetTimescale = new haxe.ui.components.Button();
		resetTimescale.text = 'Reset Timescale';
		resetTimescale.onClick = function(e) { timescaleSlider.pos = 1; };

		timescaleBox.addComponent(timescaleLabel);
		timescaleBox.addComponent(timescaleSlider);
		timescaleBox.addComponent(resetTimescale);

		UiS.addHR(7, debugBox);

		debugBox.addComponent(editModeBox);

		UiS.addHR(7, debugBox);

		debugBox.addComponent(timescaleBox);

		debugWindow.addComponent(debugBox);

		addShadowEditorUI();

		rtxWindow.fadeOut();
		debugWindow.fadeOut();
		shadowWindow.fadeOut();

		rtxWindow.cameras = [camOther2];
		debugWindow.cameras = [camOther2];
		shadowWindow.cameras = [camOther2];

		unblockInput();

		WindowManager.instance.container = uiLayer;
		uiLayer.cameras = [camOther2];

		@:privateAccess rtxWindow._allowDispose = false;
		@:privateAccess debugWindow._allowDispose = false;
		@:privateAccess shadowWindow._allowDispose = false;
	}

	function addShadowEditorUI()
	{
		initShader('blur');

		simplifiedShadows = new haxe.ui.components.CheckBox();
		simplifiedShadows.selected = false;
		simplifiedShadows.text = 'Simple Shadows';
		simplifiedShadows.onChange = function(e)
		{
			for (name in charNames)
				char(name).simpleShadows = simplifiedShadows.selected;
		}

		for (name in charNames)
			char(name).shadowChar.shader = createRuntimeShader('blur');

		loadShadowFile();

		shadowWindow = new haxe.ui.containers.windows.Window();
		shadowWindow.title = 'Shadow Menu';

		shadowWindow.closable = false;
		shadowWindow.minimizable = true;
		shadowWindow.maximizable = false;
		shadowWindow.draggable = true;

		var shadowBox = new haxe.ui.containers.HBox();

		var charBox = new haxe.ui.containers.VBox();

		var charSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (char in charNames)
			charSource.add({text: char});

		var curChar = char(charNames[shadowIndex]);

		var animSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (anim in curChar.animationsArray)
			animSource.add({text: anim.anim});

		var shadowCharSelect = new haxe.ui.containers.ListView();
		shadowCharSelect.width = 200;
		shadowCharSelect.height = 50;
		shadowCharSelect.selectedIndex = 0;
		shadowCharSelect.dataSource = charSource;

		shadowAnimSelect = new haxe.ui.containers.ListView();
		shadowAnimSelect.width = 200;
		shadowAnimSelect.height = 75;
		shadowAnimSelect.dataSource = animSource;
		shadowAnimSelect.selectedIndex = 0;

		shadowAlphaSlider = new haxe.ui.components.HorizontalSlider();
		shadowAlphaSlider.width = 200;
		shadowAlphaSlider.min = 0;
		shadowAlphaSlider.max = 1;

		shadowAlphaSlider.pos = curChar.shadowChar.alpha;
		shadowAlphaSlider.onChange = function(e)
		{
			var reference = char(charNames[shadowIndex]);

			reference.shadowChar.alpha = shadowAlphaSlider.pos;
			reference.simpleShadow.alpha = shadowAlphaSlider.pos;
		}

		charBox.addComponent(simplifiedShadows);

		charBox.addComponent(shadowCharSelect);
		UiS.addHR(7, charBox);
		UiS.addLabel('Shadow Alpha', charBox);
		charBox.addComponent(shadowAlphaSlider);

		var baseOffsetBox = new haxe.ui.containers.HBox();

		//
		var baseOffsetXBox = new haxe.ui.containers.VBox();
		UiS.addLabel('Base Offset X', baseOffsetXBox);

		baseOffsetXSlider = new haxe.ui.components.HorizontalSlider();
		baseOffsetXSlider.width = 100;
		baseOffsetXSlider.pos = curChar.baseOffset[0];
		baseOffsetXSlider.min = -500;
		baseOffsetXSlider.max = 500;
		baseOffsetXSlider.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			curChar.baseOffset[0] = baseOffsetXSlider.pos;

			var curAnim = shadowAnimSelect.selectedItem.text;
			curChar.shadowChar.offset.x = curChar.baseOffset[0] + curChar.shadowOffsets[curAnim][0];
			curChar.simpleShadow.offset.x = curChar.baseOffset[0] + curChar.shadowOffsets[curAnim][0];
		}

		baseOffsetXBox.addComponent(baseOffsetXSlider);

		baseOffsetBox.addComponent(baseOffsetXBox);
		//

		//
		var baseOffsetYBox = new haxe.ui.containers.VBox();
		UiS.addLabel('Base Offset Y', baseOffsetYBox);

		baseOffsetYSlider = new haxe.ui.components.HorizontalSlider();
		baseOffsetYSlider.width = 100;
		baseOffsetYSlider.pos = curChar.baseOffset[1];
		baseOffsetYSlider.min = -500;
		baseOffsetYSlider.max = 500;
		baseOffsetYSlider.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			curChar.baseOffset[1] = baseOffsetYSlider.pos;

			var curAnim = shadowAnimSelect.selectedItem.text;
			curChar.shadowChar.offset.y = curChar.baseOffset[1] + curChar.shadowOffsets[curAnim][1];
			curChar.simpleShadow.offset.y = curChar.baseOffset[1] + curChar.shadowOffsets[curAnim][1];
		}

		baseOffsetYBox.addComponent(baseOffsetYSlider);

		baseOffsetBox.addComponent(baseOffsetYBox);
		//

		charBox.addComponent(baseOffsetBox);

		var baseSkewBox = new haxe.ui.containers.HBox();

		//
		var baseSkewXBox = new haxe.ui.containers.VBox();
		UiS.addLabel('Base Skew X', baseSkewXBox);

		baseSkewXSlider = new haxe.ui.components.HorizontalSlider();
		baseSkewXSlider.width = 100;
		baseSkewXSlider.pos = curChar.baseSkew[0];
		baseSkewXSlider.min = -90;
		baseSkewXSlider.max = 90;
		baseSkewXSlider.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			curChar.baseSkew[0] = baseSkewXSlider.pos;

			var curAnim = shadowAnimSelect.selectedItem.text;
			curChar.shadowChar.skew.x = curChar.baseSkew[0] + curChar.shadowSkews[curAnim][0];
			curChar.simpleShadow.skew.x = curChar.baseSkew[0] + curChar.shadowSkews[curAnim][0];
		}

		baseSkewXBox.addComponent(baseSkewXSlider);

		baseSkewBox.addComponent(baseSkewXBox);
		//

		//
		var baseSkewYBox = new haxe.ui.containers.VBox();
		UiS.addLabel('Base Skew Y', baseSkewYBox);

		baseSkewYSlider = new haxe.ui.components.HorizontalSlider();
		baseSkewYSlider.width = 100;
		baseSkewYSlider.pos = curChar.baseSkew[1];
		baseSkewYSlider.min = -90;
		baseSkewYSlider.max = 90;
		baseSkewYSlider.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			curChar.baseSkew[1] = baseSkewYSlider.pos;

			var curAnim = shadowAnimSelect.selectedItem.text;
			curChar.shadowChar.skew.y = curChar.baseSkew[1] + curChar.shadowSkews[curAnim][1];
			curChar.simpleShadow.skew.y = curChar.baseSkew[1] + curChar.shadowSkews[curAnim][1];
		}

		baseSkewYBox.addComponent(baseSkewYSlider);

		baseSkewBox.addComponent(baseSkewYBox);
		//

		charBox.addComponent(baseSkewBox);

		//
		var baseScaleSliders = new haxe.ui.containers.HBox();

		var baseWidthBox = new haxe.ui.containers.VBox();

		UiS.addLabel('Base Width', baseWidthBox);

		baseShadowWidthSlider = new haxe.ui.components.HorizontalSlider();
		baseShadowWidthSlider.width = 100;
		baseShadowWidthSlider.min = 0;
		baseShadowWidthSlider.max = 2;
		baseShadowWidthSlider.pos = curChar.baseScale[0];

		baseWidthBox.addComponent(baseShadowWidthSlider);
		baseScaleSliders.addComponent(baseWidthBox);

		var baseHeightBox = new haxe.ui.containers.VBox();

		UiS.addLabel('Base Height', baseHeightBox);

		baseShadowHeightSlider = new haxe.ui.components.HorizontalSlider();
		baseShadowHeightSlider.width = 100;
		baseShadowHeightSlider.min = 0;
		baseShadowHeightSlider.max = 2;
		baseShadowHeightSlider.pos = curChar.baseScale[1];

		baseHeightBox.addComponent(baseShadowHeightSlider);
		baseScaleSliders.addComponent(baseHeightBox);

		charBox.addComponent(baseScaleSliders);

		shadowBox.addComponent(charBox);
		UiS.addVR(7, shadowBox);

		var animBox = new haxe.ui.containers.VBox();

		animBox.addComponent(shadowAnimSelect);
		UiS.addHR(7, animBox);

		var slidersBox = new haxe.ui.containers.HBox();

		//
		var skewXBox = new haxe.ui.containers.VBox();

		skewXSlider = new haxe.ui.components.HorizontalSlider();
		skewXSlider.width = 100;
		skewXSlider.min = -90;
		skewXSlider.max = 90;
		skewXSlider.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			var curAnim = shadowAnimSelect.selectedItem.text;

			curChar.shadowChar.skew.x = curChar.baseSkew[0] + skewXSlider.pos;
			curChar.simpleShadow.skew.x = curChar.baseSkew[0] + skewXSlider.pos;

			curChar.shadowSkews.set(curAnim, [skewXSlider.pos, skewYSlider.pos]);
		}

		var labelBox = new haxe.ui.containers.HBox();
		UiS.addLabel('Skew X', labelBox);

		var reset = resetButton();
		reset.onClick = function(e)
		{
			skewXSlider.pos = 0;
		}
		labelBox.addComponent(reset);

		skewXBox.addComponent(labelBox);
		skewXBox.addComponent(skewXSlider);

		slidersBox.addComponent(skewXBox);
		//

		//
		var skewYBox = new haxe.ui.containers.VBox();

		skewYSlider = new haxe.ui.components.HorizontalSlider();
		skewYSlider.width = 100;
		skewYSlider.min = -90;
		skewYSlider.max = 90;
		skewYSlider.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			var curAnim = shadowAnimSelect.selectedItem.text;

			curChar.shadowChar.skew.y = curChar.baseSkew[1] + skewYSlider.pos;
			curChar.simpleShadow.skew.y = curChar.baseSkew[1] + skewYSlider.pos;

			curChar.shadowSkews.set(curAnim, [skewXSlider.pos, skewYSlider.pos]);
		}

		var labelBox = new haxe.ui.containers.HBox();
		UiS.addLabel('Skew Y', labelBox);

		var reset = resetButton();
		reset.onClick = function(e)
		{
			skewYSlider.pos = 0;
		}
		labelBox.addComponent(reset);

		skewYBox.addComponent(labelBox);
		skewYBox.addComponent(skewYSlider);

		slidersBox.addComponent(skewYBox);
		//

		animBox.addComponent(slidersBox);

		//
		var scaleSliders = new haxe.ui.containers.HBox();

		var widthBox = new haxe.ui.containers.VBox();

		shadowWidthSlider = new haxe.ui.components.HorizontalSlider();
		shadowWidthSlider.width = 100;
		shadowWidthSlider.min = -1;
		shadowWidthSlider.max = 1;

		var labelBox = new haxe.ui.containers.HBox();
		UiS.addLabel('Width', labelBox);

		var reset = resetButton();
		reset.onClick = function(e)
		{
			shadowWidthSlider.pos = 0;
		}
		labelBox.addComponent(reset);

		widthBox.addComponent(labelBox);

		widthBox.addComponent(shadowWidthSlider);
		scaleSliders.addComponent(widthBox);

		var heightBox = new haxe.ui.containers.VBox();

		shadowHeightSlider = new haxe.ui.components.HorizontalSlider();
		shadowHeightSlider.width = 100;
		shadowHeightSlider.min = -1;
		shadowHeightSlider.max = 1;

		var labelBox = new haxe.ui.containers.HBox();
		UiS.addLabel('Height', labelBox);

		var reset = resetButton();
		reset.onClick = function(e)
		{
			shadowHeightSlider.pos = 0;
		}
		labelBox.addComponent(reset);

		heightBox.addComponent(labelBox);
		heightBox.addComponent(shadowHeightSlider);

		scaleSliders.addComponent(heightBox);

		shadowWidthSlider.onChange = function(e)
		{
			shadowWidthSlider.pos;

			var curChar = char(charNames[shadowIndex]);

			var curAnim = shadowAnimSelect.selectedItem.text;

			curChar.shadowChar.scale.x = curChar.baseScale[0] + shadowWidthSlider.pos;
			curChar.simpleShadow.scale.x = curChar.baseScale[0] + shadowWidthSlider.pos;

			curChar.shadowScales.set(curAnim, [shadowWidthSlider.pos, shadowHeightSlider.pos]);
		}

		shadowHeightSlider.onChange = function(e)
		{
			shadowHeightSlider.pos;

			var curChar = char(charNames[shadowIndex]);

			var curAnim = shadowAnimSelect.selectedItem.text;

			curChar.shadowChar.scale.y = curChar.baseScale[1] + shadowHeightSlider.pos;
			curChar.simpleShadow.scale.y = curChar.baseScale[1] + shadowHeightSlider.pos;

			curChar.shadowScales.set(curAnim, [shadowWidthSlider.pos, shadowHeightSlider.pos]);
		}

		baseShadowWidthSlider.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			curChar.baseScale[0] = baseShadowWidthSlider.pos;

			curChar.shadowChar.scale.x = curChar.baseScale[0] + shadowWidthSlider.pos;
			curChar.simpleShadow.scale.x = curChar.baseScale[0] + shadowWidthSlider.pos;
		}

		baseShadowHeightSlider.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			curChar.baseScale[1] = baseShadowHeightSlider.pos;

			curChar.shadowChar.scale.y = curChar.baseScale[1] + shadowHeightSlider.pos;
			curChar.simpleShadow.scale.y = curChar.baseScale[1] + shadowHeightSlider.pos;
		}

		animBox.addComponent(scaleSliders);

		var offsetSliders = new haxe.ui.containers.HBox();

		//
		var offsetXBox = new haxe.ui.containers.VBox();

		offsetXSlider = new haxe.ui.components.HorizontalSlider();
		offsetXSlider.width = 100;
		offsetXSlider.min = -500;
		offsetXSlider.max = 500;
		offsetXSlider.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			var curAnim = shadowAnimSelect.selectedItem.text;

			curChar.shadowOffsets[curAnim][0] = offsetXSlider.pos;
			
			var curAnim = shadowAnimSelect.selectedItem.text;
			curChar.shadowChar.offset.x = curChar.baseOffset[0] + curChar.shadowOffsets[curAnim][0];
			curChar.simpleShadow.offset.x = curChar.baseOffset[0] + curChar.shadowOffsets[curAnim][0];
		}

		var labelBox = new haxe.ui.containers.HBox();
		UiS.addLabel('Offset X', labelBox);

		var reset = resetButton();
		reset.onClick = function(e)
		{
			offsetXSlider.pos = 0;
		}
		labelBox.addComponent(reset);

		offsetXBox.addComponent(labelBox);
		offsetXBox.addComponent(offsetXSlider);

		offsetSliders.addComponent(offsetXBox);
		//

		//
		var offsetYBox = new haxe.ui.containers.VBox();

		offsetYSlider = new haxe.ui.components.HorizontalSlider();
		offsetYSlider.width = 100;
		offsetYSlider.min = -500;
		offsetYSlider.max = 500;
		offsetYSlider.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			var curAnim = shadowAnimSelect.selectedItem.text;

			curChar.shadowOffsets[curAnim][1] = offsetYSlider.pos;
			
			var curAnim = shadowAnimSelect.selectedItem.text;
			curChar.shadowChar.offset.y = curChar.baseOffset[1] + curChar.shadowOffsets[curAnim][1];
			curChar.simpleShadow.offset.y = curChar.baseOffset[1] + curChar.shadowOffsets[curAnim][1];
		}

		var labelBox = new haxe.ui.containers.HBox();
		UiS.addLabel('Offset Y', labelBox);

		var reset = resetButton();
		reset.onClick = function(e)
		{
			offsetYSlider.pos = 0;
		}
		labelBox.addComponent(reset);

		offsetYBox.addComponent(labelBox);
		offsetYBox.addComponent(offsetYSlider);

		offsetSliders.addComponent(offsetYBox);
		//

		animBox.addComponent(offsetSliders);

		shadowCharSelect.onChange = function(e)
		{
			if (shadowCharSelect.selectedItem == null)
			{
				shadowAnimSelect.disabled = true;
				return;
			}

			shadowAnimSelect.disabled = false;

			shadowIndex = charNames.indexOf(shadowCharSelect.selectedItem.text);

			var curChar = char(charNames[shadowIndex]);

			var animSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
			for (anim in curChar.animationsArray)
				animSource.add({text: anim.anim});

			shadowAnimSelect.dataSource = animSource;
			shadowAnimSelect.selectedIndex = 0;

			var name = shadowAnimSelect.selectedItem.text;

			curChar.playAnim(name);

			shadowAlphaSlider.pos = curChar.shadowChar.alpha;
			
			shadowWidthSlider.pos = curChar.shadowScales[name][0];
			shadowHeightSlider.pos = curChar.shadowScales[name][1];

			skewXSlider.pos = curChar.shadowSkews[name][0];
			skewYSlider.pos = curChar.shadowSkews[name][1];

			baseSkewXSlider.pos = curChar.baseSkew[0];
			baseSkewYSlider.pos = curChar.baseSkew[1];
		}

		shadowAnimSelect.onChange = function(e)
		{
			var curChar = char(charNames[shadowIndex]);

			if (shadowAnimSelect.selectedItem == null || (curChar.animation.curAnim != null && curChar.animation.curAnim.name == shadowAnimSelect.selectedItem.text))
				return;

			var name = shadowAnimSelect.selectedItem.text;

			curChar.playAnim(name);

			curChar.animation.curAnim.looped = true;
			curChar.shadowChar.animation.curAnim.looped = true;

			var curOffsets = curChar.shadowOffsets[name];
			offsetXSlider.pos = curOffsets[0];
			offsetYSlider.pos = curOffsets[1];

			var curSkews = curChar.shadowSkews[name];
			skewXSlider.pos = curSkews[0];
			skewYSlider.pos = curSkews[1];

			var curScales = curChar.shadowScales[name];
			shadowWidthSlider.pos = curScales[0];
			shadowHeightSlider.pos = curScales[1];
		}
		
		//
		var animCopyButton = new haxe.ui.components.Button();
		animCopyButton.text = 'Copy';

		var animPasteButton = new haxe.ui.components.Button();
		animPasteButton.text = 'Paste';
		animPasteButton.disabled = true;

		animCopyButton.onClick = function(e)
		{
			animShadowCopy.offsets = [offsetXSlider.pos, offsetYSlider.pos];
			animShadowCopy.skews = [skewXSlider.pos, skewYSlider.pos];
			animShadowCopy.scales = [shadowWidthSlider.pos, shadowHeightSlider.pos];

			animPasteButton.disabled = false;
		}

		animPasteButton.onClick = function(e)
		{
			offsetXSlider.pos = animShadowCopy.offsets[0];
			offsetYSlider.pos = animShadowCopy.offsets[1];

			skewXSlider.pos = animShadowCopy.skews[0];
			skewYSlider.pos = animShadowCopy.skews[1];

			shadowWidthSlider.pos = animShadowCopy.scales[0];
			shadowHeightSlider.pos = animShadowCopy.scales[1];

			animPasteButton.disabled = true;
		}

		var cvButtons = new haxe.ui.containers.HBox();
		cvButtons.addComponent(animCopyButton);
		cvButtons.addComponent(animPasteButton);

		UiS.addHR(7, animBox);
		animBox.addComponent(cvButtons);
		//

		var shadowSaveButton = new haxe.ui.components.Button();
		shadowSaveButton.text = 'Save Shadows';
		shadowSaveButton.onClick = function(e)
		{
			var shadows:ShadowFile = 
			{
				simplified: simplifiedShadows.selected,
				shadows: []
			};

			for (name in charNames)
			{
				var ref = char(name);

				var data:CharacterShadowFile =
				{
					alpha: ref.shadowChar.alpha,
					baseOffset: ref.baseOffset,
					offsets: ref.shadowOffsets,
					baseSkew: ref.baseSkew,
					skews: ref.shadowSkews,
					baseScale: ref.baseScale,
					scales: ref.shadowScales,
					name: name
				}

				shadows.shadows.push(data);
			}

			var shadowData:String = haxe.Json.stringify(shadows, '\t');

			var songPath:String = Paths.songFolder(SONG.song, Paths.WORKING_MOD_DIRECTORY);
			File.saveContent('$songPath/shadows.json', shadowData);

			Lib.application.window.alert('Saved Shadow Data.\n"$songPath/"', Main.ALERT_TITLE);
		}

		var name:String = shadowAnimSelect.selectedItem.text;
		
		var curOffsets = curChar.shadowOffsets[name];
		offsetXSlider.pos = curOffsets[0];
		offsetYSlider.pos = curOffsets[1];

		var curSkews = curChar.shadowSkews[name];
		skewXSlider.pos = curSkews[0];
		skewYSlider.pos = curSkews[1];

		var curScales = curChar.shadowScales[name];
		shadowWidthSlider.pos = curScales[0];
		shadowHeightSlider.pos = curScales[1];

		shadowBox.addComponent(animBox);

		shadowWindow.addComponent(shadowBox);

		UiS.addHR(7, shadowWindow);
		shadowWindow.addComponent(shadowSaveButton);
	}

	function resetButton():haxe.ui.components.Button
	{
		var reset = new haxe.ui.components.Button();
		reset.text = '*';
		reset.width = 20;
		reset.height = 20;

		return reset;
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

		#if (!flash && sys)
		if(!runtimeShaders.exists(name) && !initShader(name))
		{
			trace('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		trace("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		if(runtimeShaders.exists(name))
		{
			trace('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders')];

		for(mod in Paths.getModDirectories())
			foldersToCheck.push(Paths.mods('shaders', mod));
		
		for (path in foldersToCheck)
		{
			if (path == null)
				continue;

			trace('$path/$name');

			var frag:String = '$path/$name.frag';
			var vert:String = '$path/$name.vert';
			var found:Bool = false;

			if(FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;

			if (FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;

			if(found)
			{
				runtimeShaders.set(name, [frag, vert]);
				return true;
			}
		}

		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;

			if (FlxG.sound.music != null)
				FlxG.sound.music.pitch = value;
		}

		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		return value;
	}

	public function reloadHealthBarColors() 
	{
		if (hscriptManager != null)
			hscriptManager.callAll('reloadHealthBarColors', []);
	}

	public function getCharCol(character:Character)
	{
		return FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]);
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					playerGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScript(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					opponentGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScript(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScript(newGf.curCharacter);
				}
		}
	}

	public function startCharacterScript(name:String)
	{
		if (hscriptManager == null)
			return;

		var check:String = Paths.charFolder(name, char(name).modDirectory);

		if (check != null)
			hscriptManager.addScriptsFromFolder(check);
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) 
	{
		if(gfCheck && char.curCharacter.startsWith('gf')) 
		{
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];

		if (char.hasAnim('idle'))
			char.playAnim('idle');
		else
			char.playAnim(char.animationsArray[0].anim);
	}

	public function startVideo(name:String)
	{
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		video.playMP4(filepath, false, null, false, true, false, false);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}

		videoToPlay = '';
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage) introAlts = introAssets.get('pixel');
		
		for (asset in introAlts)
			Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown():Void
	{
		if(startedCountdown)
			return;

		inCutscene = false;
		if (false)
			return;

		if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		startedCountdown = true;
		Conductor.songPosition = -Conductor.crochet * 5;

		hscriptManager = new HscriptManager(playstateInterp);

		for (mod in Paths.getModDirectories())
			hscriptManager.addScriptsFromFolder(Paths.mods('scripts', mod));

		for (mod in Paths.getModDirectories())
		{
			var check = Paths.stageFolder(SONG.stage.toLowerCase(), mod);
			if (check != null)
				hscriptManager.addScriptsFromFolder(check);
		}
		
		hscriptManager.addScriptsFromFolder(Paths.songFolder(SONG.song.toLowerCase(), Paths.WORKING_MOD_DIRECTORY));

		for (char in charNames)
			startCharacterScript(char);

		startCharacterScript(gf.curCharacter);

		for (event in allEvents)
			for (mod in Paths.getModDirectories())
			{
				var script:String = Paths.eventScript(event, mod);
				if (script == null)
					continue;

				hscriptManager.addScriptFromPath(script);
			}

		for (chars in [SONG.players, SONG.opponents])
		{
			for (char in chars)
			{
				for (note in SONG.notes[formatSongDifficulty(difficulty)][char])
				{
					if (!hscriptManager.exists(note.t) && ChartingState.HARDCODED_NOTES != null && !ChartingState.HARDCODED_NOTES.contains(note.t))
					{
						for (mod in Paths.getModDirectories())
						{
							var script:String = Paths.noteScript(note.t, mod);
							if (script != null)
								hscriptManager.addScriptFromPath(script);
						}
					}
				}
			}
		}

		hscriptManager.callAll('start', [SONG.song]);

		trace(hscriptManager);

		if (doFNFCountdown) 
		{
			var swagCounter:Int = 0;

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) 
			{
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
					gf.dance();
			
				for (char in characters)
				{
					if (tmr.loopsLeft % char.danceEveryNumBeats == 0 && char.animation.curAnim != null && !char.animation.curAnim.name.startsWith('sing') && !char.stunned)
						char.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.data.antialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0] + countdownSuffix));
						countdownReady.cameras = [camHUD];
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						insert(members.indexOf(notes), countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1] + countdownSuffix));
						countdownSet.cameras = [camHUD];
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						insert(members.indexOf(notes), countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2] + countdownSuffix));
						countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						insert(members.indexOf(notes), countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
				}

				notes.forEachAlive(function(note:Note) 
				{
					if(!note.mustPress)
						return;
					
					note.copyAlpha = false;
					note.alpha = note.multAlpha;

					if(ClientPrefs.data.middleScroll && !note.mustPress)
						note.alpha *= 0.35;
				});

				// CALL ALL HSCRIPT FOR COUNTDOWN TICK PLEASE

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}

		playerStrums.forEach(function(spr:StrumNote)
		{
			strumPositions.push(new FlxPoint(spr.x, spr.y));
		});
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(playerGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(opponentGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.modsInst(PlayState.SONG.song, Paths.WORKING_MOD_DIRECTORY), 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) 
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

   		songLength = FlxG.sound.music.length;
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.modsVoices(PlayState.SONG.song.toLowerCase(), Paths.WORKING_MOD_DIRECTORY));
		else
			vocals = new FlxSound();

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.modsInst(PlayState.SONG.song.toLowerCase(), Paths.WORKING_MOD_DIRECTORY)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		allEvents = [];

		var songName:String = SONG.song;
		var eventsData:Array<EventNote> = SONG.events;
		for (event in eventsData)
		{
			event.strumTime += ClientPrefs.data.noteOffset;
			event.strumTime -= eventNoteEarlyTrigger(event);

			if (!allEvents.contains(event.event))
				allEvents.push(event.event);

			eventNotes.push(event);
			eventPushed(event);
		}

		var isPlayer:Bool = true;
		for (chars in [SONG.players, SONG.opponents])
		{
			for (char in chars)
			{
				for (note in SONG.notes[formatSongDifficulty(difficulty)][char])
				{
					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = new Note(note.ms, note.d, oldNote);
					swagNote.sustainLength = note.l;
					swagNote.noteType = note.t;

					swagNote.attachedChar = char;
					swagNote.mustPress = isPlayer;

					swagNote.scrollFactor.set();

					var susLength:Float = swagNote.sustainLength;

					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);

					var floorSus:Int = Math.floor(susLength);
					if(floorSus > 0) 
					{
						for (susNote in 0...floorSus + 1)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

							var sustainNote:Note = new Note(note.ms + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), note.d, oldNote, true);
							sustainNote.mustPress = swagNote.mustPress;
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							swagNote.tail.push(sustainNote);
							sustainNote.parent = swagNote;
							unspawnNotes.push(sustainNote);
							sustainNote.attachedChar = swagNote.attachedChar;

							if (sustainNote.mustPress)
								sustainNote.x += FlxG.width / 2; // general offset
							else if(ClientPrefs.data.middleScroll)
							{
								sustainNote.x += 310;
								if(note.d > 1) //Up and Right
								{
									sustainNote.x += FlxG.width / 2 + 25;
								}
							}
						}
					}

					if (swagNote.mustPress)
						swagNote.x += FlxG.width / 2; // general offset
					else if(ClientPrefs.data.middleScroll)
					{
						swagNote.x += 310;
						if(note.d > 1) //Up and Right
						{
							swagNote.x += FlxG.width / 2 + 25;
						}
					}

					if(!noteTypeMap.exists(swagNote.noteType))
						noteTypeMap.set(swagNote.noteType, true);
				}
			}

			isPlayer = false;
		}

		for (event in songData.events) //Event Notes
		{
			event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.push(event);
			eventPushed(event);
		}

		unspawnNotes.sort(sortByTime);
		if(eventNotes.length > 1) //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);

		checkEventNote();
		generatedMusic = true;

		trace(hscriptManager);
	}

	function eventPushed(event:EventNote) 
	{
		switch(event.event) 
		{
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event.event)) 
			eventPushedMap.set(event.event, true);
	}

	function eventNoteEarlyTrigger(event:EventNote):Float 
	{
		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
				if(ClientPrefs.data.middleScroll) targetAlpha = 0;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;

			if (!skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			babyArrow.ID = i;

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	function pauseStuff()
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		if (startTimer != null && !startTimer.finished)
			startTimer.active = false;
		if (finishTimer != null && !finishTimer.finished)
			finishTimer.active = false;
		if (songSpeedTween != null)
			songSpeedTween.active = false;

		for (char in characters) {
			if(char != null && char.colorTween != null) {
				char.colorTween.active = false;
			}
		}

		for (tween in modchartTweens) {
			tween.active = false;
		}
		for (timer in modchartTimers) {
			timer.active = false;
		}
		for (sound in modchartSounds) {
			sound.pause();
		}
		for(video in modchartVideos) {
			if(video.bitmap != null) video.pause();
		}
	}

	function unpauseStuff()
	{
		if (FlxG.sound.music != null && !startingSong)
			resyncVocals();

		if (startTimer != null && !startTimer.finished)
			startTimer.active = true;
		if (finishTimer != null && !finishTimer.finished)
			finishTimer.active = true;
		if (songSpeedTween != null)
			songSpeedTween.active = true;

		for (char in characters) {
			if(char != null && char.colorTween != null) {
				char.colorTween.active = true;
			}
		}

		for (tween in modchartTweens) {
			tween.active = true;
		}
		for (timer in modchartTimers) {
			timer.active = true;
		}
		for (sound in modchartSounds) {
			sound.play();
		}
		for(video in modchartVideos) {
			if(video.bitmap != null) video.resume();
		}
	}

	override function closeSubState()
	{
		if (paused)
		{
			unpauseStuff();
			paused = false;
		}

		super.closeSubState();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public function checkFunctionKeys()
	{
		if (FlxG.keys.justPressed.F1)
		{
			openPauseMenu();

			Lib.application.window.alert('F3 - Open RTX Editor\nF4 - Open Debug Menu\nF5 - Open Shadow Editor\nF6 - Print current HaxeUI focus\nF9 - Toggle Mouse', Main.ALERT_TITLE);
		}

		if (FlxG.keys.justPressed.F3)
		{
			cpuControlled = true;

			camHUD.visible = false;
			hudBox.selected = false;

			WindowManager.instance.addWindow(rtxWindow);

			FlxTimer.wait(0.1, function()
			{
				editingRimLight = true;
				loadRimLightJson();
			});

			FlxG.mouse.visible = true;
		}

		if (FlxG.keys.justPressed.F4)
		{
			WindowManager.instance.addWindow(debugWindow);

			debugMode = true;
			cpuControlled = true;

			botplayBox.selected = true;
			hudBox.selected = true;

			FlxG.mouse.visible = true;
		}

		if (FlxG.keys.justPressed.F5)
		{
			editingMode = true;
			editModeBox.selected = true;
			editingShadows = true;

			timescaleSlider.pos = 0;
			FlxG.animationTimeScale = 1;

			shadowAnimSelect.selectedIndex = 0;

			var anim = shadowAnimSelect.selectedItem.text;

			var curChar = char(charNames[shadowIndex]);
			curChar.playAnim(anim);

			curChar.animation.curAnim.looped = true;
			curChar.shadowChar.animation.curAnim.looped = true;

			editZoom = FlxG.camera.zoom;

			camManager.halt();

			debugMode = true;
			cpuControlled = true;

			botplayBox.selected = true;
			hudBox.selected = true;

			FlxG.mouse.visible = true;

			FlxTimer.wait(0.1, function()
			{
				WindowManager.instance.addWindow(shadowWindow);

				shadowAlphaSlider.pos = curChar.shadowChar.alpha;

				shadowWidthSlider.pos = curChar.shadowScales[anim][0];
				shadowHeightSlider.pos = curChar.shadowScales[anim][1];

				skewXSlider.pos = curChar.shadowSkews[anim][0];
				skewYSlider.pos = curChar.shadowSkews[anim][1];

				offsetXSlider.pos = curChar.shadowOffsets[anim][0];
				offsetYSlider.pos = curChar.shadowOffsets[anim][1];
			});
		}

		if (FlxG.keys.justPressed.F9) FlxG.mouse.visible = !FlxG.mouse.visible;
	}

	function updateRimLighting()
	{
		if (!editingRimLight)
			return;

		if (shadeCharSelect.selectedItem == null)
			return;

		var name:String = shadeCharSelect.selectedItem.text;

		var overlayCol = FlxColor.fromInt(overlayColPicker.currentColor);
		var satinCol = FlxColor.fromInt(satinColPicker.currentColor);
		var innerCol = FlxColor.fromInt(innerColPicker.currentColor);

		var ref = char(name).rimLightShader;

		if (ref == null)
			return;

		ref.setFloatArray('overlayColor', [overlayCol.redFloat, overlayCol.greenFloat, overlayCol.blueFloat, overlayAlphaSlider.pos]);
		ref.setFloatArray('satinColor', [satinCol.redFloat, satinCol.greenFloat, satinCol.blueFloat, satinAlphaSlider.pos]);
		ref.setFloatArray('innerShadowColor', [innerCol.redFloat, innerCol.greenFloat, innerCol.blueFloat, innerAlphaSlider.pos]);

		ref.setFloat('innerShadowAngle', innerAngleSlider.pos * (Math.PI / 180));
		ref.setFloat('innerShadowDistance', innerDistSlider.pos);
	}

	function loadRimLightJson(?forceName:String)
	{
		var rtxFile:String = Paths.modsSongJson(SONG.song, shadeNameInput.text =='' ? 'shade' : 'shade-${shadeNameInput.text}', Paths.WORKING_MOD_DIRECTORY);
		if (forceName != null)
			rtxFile = Paths.modsSongJson(SONG.song, 'shade${forceName != '' ? '-$forceName' : ''}', Paths.WORKING_MOD_DIRECTORY);
		
		if (rtxFile == null)
		{
			rtxResetButton.disabled = true;

			for (name in charNames)
			{
				var ref = char(name).rimLightShader;

				ref.setFloatArray('overlayColor', [0, 0, 0, 0]);
				ref.setFloatArray('satinColor', [0, 0, 0, 0]);
				ref.setFloatArray('innerShadowColor', [0, 0, 0, 0]);

				ref.setFloat('innerShadowAngle', 0);
				ref.setFloat('innerShadowDistance', 0);
			}

			return;
		}

		if (forceName != null)
			shadeNameInput.text = forceName;

		var data:RimLightFile = cast haxe.Json.parse(File.getContent(rtxFile));
		var lights:Array<CharacterRimLightFile> = data.lights;

		if (lights == null)
		{
			Lib.application.window.alert('Old shade format detected. Please delete shade file for this song', Main.ALERT_TITLE);
			return;
		}

		var curData:CharacterRimLightFile;
		for (light in lights)
		{
			var ref = char(light.name).rimLightShader;
			if (ref == null)
				continue;

			ref.setFloatArray('overlayColor', [light.overlayCol[0], light.overlayCol[1], light.overlayCol[2], light.overlayCol[3]]);
			ref.setFloatArray('satinColor', [light.satinCol[0], light.satinCol[1], light.satinCol[2], light.satinCol[3]]);
			ref.setFloatArray('innerShadowColor', [light.innerCol[0], light.innerCol[1], light.innerCol[2], light.innerCol[3]]);

			ref.setFloat('innerShadowAngle', light.angle);
			ref.setFloat('innerShadowDistance', light.dist);

			if (shadeCharSelect.selectedItem == null)
				continue;

			if (light.name != shadeCharSelect.selectedItem.text)
				continue;

			overlayColPicker.currentColor = Std.int(FlxColor.fromRGBFloat(light.overlayCol[0], light.overlayCol[1], light.overlayCol[2]).to24Bit());
			satinColPicker.currentColor = Std.int(FlxColor.fromRGBFloat(light.satinCol[0], light.satinCol[1], light.satinCol[2]).to24Bit());
			innerColPicker.currentColor = Std.int(FlxColor.fromRGBFloat(light.innerCol[0], light.innerCol[1], light.innerCol[2]).to24Bit());

			overlayAlphaSlider.pos = light.overlayCol[3];
			satinAlphaSlider.pos = light.satinCol[3];
			innerAlphaSlider.pos = light.innerCol[3];

			innerAngleSlider.pos = light.angle;
			innerDistSlider.pos = light.dist;
		}
	}

	function saveRimLighting(e:haxe.ui.events.MouseEvent = null)
	{
		var data:RimLightFile = 
		{
			lights: []
		}

		for (name in charNames)
		{
			var ref = char(name).rimLightShader;

			if (ref == null)
			{
				data.lights.push({
					satinCol: [0, 0, 0],
					innerCol: [0, 0, 0],
					overlayCol: [0, 0, 0],

					angle: 0,
					dist: 0,

					name: name
				});

				continue;
			}

			var angle = ref.getFloat('innerShadowAngle');
			var dist = ref.getFloat('innerShadowDistance');

			var curFile:CharacterRimLightFile =
			{
				satinCol: ref.getFloatArray('satinColor'),
				innerCol: ref.getFloatArray('innerShadowColor'),
				overlayCol: ref.getFloatArray('overlayColor'),

				angle: angle == null ? 0 : angle,
				dist: dist == null ? 0 : dist,

				name: name
			}

			trace(angle, dist);

			data.lights.push(curFile);
		}

		var string:String = haxe.Json.stringify(data, "\t");

		var songPath:String = Paths.songFolder(SONG.song, Paths.WORKING_MOD_DIRECTORY);
		var fullPath:String = '$songPath/${shadeNameInput.text == '' ? 'shade' : 'shade-${shadeNameInput.text}'}.json';
		File.saveContent(fullPath, string);

		rtxResetButton.disabled = false;

		Lib.application.window.alert('Saved Rim Light Data.\n"$fullPath/"', Main.ALERT_TITLE);
	}

	function loadShadowFile(?suffix:String)
	{
		var shadowPath = Paths.modsSongJson(SONG.song, 'shadows', Paths.WORKING_MOD_DIRECTORY);
		if (shadowPath == null)
			return;

		var data:ShadowFile = cast haxe.Json.parse(File.getContent(shadowPath));

		simplifiedShadows.selected = data.simplified;

		var shadows:Array<CharacterShadowFile> = data.shadows;
		for (shadow in shadows)
		{
			var ref = char(shadow.name);

			ref.simpleShadows = data.simplified;

			ref.baseOffset = shadow.baseOffset;
			if (shadow.baseOffset == null)
				ref.baseOffset = [0, 0];

			ref.baseSkew = shadow.baseSkew;
			if (shadow.baseSkew == null)
				ref.baseSkew = [0, 0];

			ref.baseScale = shadow.baseScale;
			if (shadow.baseScale == null)
				ref.baseScale = [0, 0];

			ref.shadowChar.alpha = shadow.alpha;
			ref.simpleShadow.alpha = shadow.alpha;

			var thisData:Map<String, CharacterShadowFile> = new Map();
			for (field in Reflect.fields(shadow))
				thisData.set(field, Reflect.field(shadow, field));
			
			var offsets:Map<String, Array<Float>> = new Map();
			for (offset in Reflect.fields(thisData.get('offsets')))
				offsets.set(offset, Reflect.field(thisData.get('offsets'), offset));

			var skews:Map<String, Array<Float>> = new Map();
			for (skew in Reflect.fields(thisData.get('skews')))
				skews.set(skew, Reflect.field(thisData.get('skews'), skew));

			var scales:Map<String, Array<Float>> = new Map();
			for (scale in Reflect.fields(thisData.get('scales')))
				scales.set(scale, Reflect.field(thisData.get('scales'), scale));

			ref.shadowChar.shader = createRuntimeShader('blur');

			for (anim in ref.animationsArray)
			{
				var curOffset = offsets[anim.anim];
				ref.shadowOffsets.set(anim.anim, curOffset);

				var curSkew = skews[anim.anim];
				ref.shadowSkews.set(anim.anim, curSkew);

				var curScales = scales[anim.anim];
				ref.shadowScales.set(anim.anim, curScales);
			}
		}
	}

	var EDITING_MOVE_AMT:Float = 500;
	var editZoom:Float = 1;
	function updateEditingMode(dt:Float)
	{
		if (!editingMode)
			return;

		var amt = EDITING_MOVE_AMT * dt;

		camManager.currentPos.x += FlxG.keys.pressed.A ? -amt : FlxG.keys.pressed.D ? amt : 0;
		camManager.currentPos.y += FlxG.keys.pressed.W ? -amt : FlxG.keys.pressed.S ? amt : 0;

		editZoom +=  FlxG.keys.pressed.Q ? -2 * dt : FlxG.keys.pressed.E ? 2 * dt : 0;

		FlxG.camera.zoom = editZoom;
		camManager.defaultZoom = editZoom;

		FlxG.animationTimeScale = 1;
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		
		hscriptManager.callAll('update', [elapsed]);

		checkFunctionKeys();

		// updating rim light shader
		updateRimLighting();

		updateCharCols();

		for (window in WindowManager.instance.windows)
			window.cameras = [camOther2];

		if (debugMode)
			playbackRate = timescaleSlider.pos;

		// wow :o
		camManager.update(elapsed, playbackRate);

	 	clock = Sys.cpuTime();

		if (controls.PAUSE && startedCountdown && canPause)
			openPauseMenu();

		if (controls.justPressed('debug_1') && !endingSong && !inCutscene)
			openChartEditor();

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		if (health >= 2)
			health = 2;

		if (controls.justPressed('debug_2') && !endingSong && !inCutscene) 
		{
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.opponents[curDAD]));
		}
		
		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camManager.zoom.zooming)
		{
			if (camManager.zoom.gameZooming)
				FlxG.camera.zoom = FlxMath.lerp(camManager.defaultZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camManager.zoom.decay * playbackRate), 0, 1));
			
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camManager.zoom.decay * playbackRate), 0, 1));
			camOther.zoom = FlxMath.lerp(1, camOther.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camManager.zoom.decay * playbackRate), 0, 1));
		}

		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
			health = 0;

		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic && !inCutscene)
		{
			if(!cpuControlled) {
				keyShit();
			} else 
			{
				for (person in characters)
				{
					if (person.animation.curAnim == null)
						continue;
						
					if (FlxG.sound.music == null)
						return;

					if (person.holdTimer < Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * person.singDuration)
						continue;
					
					if (person.animation.curAnim.name.startsWith('sing'))
						continue;

					person.dance();
				}
			}

			if(startedCountdown)
			{
				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				notes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if(!daNote.mustPress) strumGroup = opponentStrums;

					var strumX:Float;
					var strumY:Float;
					var strumAngle:Float;
					var strumDirection:Float;
					var strumAlpha:Float;
					var strumScroll:Bool;

					strumX = strumGroup.members[daNote.noteData].x;
					strumY = strumGroup.members[daNote.noteData].y;
					strumAngle = strumGroup.members[daNote.noteData].angle;
					strumDirection = strumGroup.members[daNote.noteData].direction;
					strumAlpha = strumGroup.members[daNote.noteData].alpha;
					strumScroll = strumGroup.members[daNote.noteData].downScroll;

					strumX += daNote.offsetX;
					strumY += daNote.offsetY;
					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;

					if (!pauseNotesMoving)
					{
						if (strumScroll) //Downscroll
							daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);

						else //Upscroll
							daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
   					}

					var angleDir = strumDirection * Math.PI / 180;
					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;

					if(daNote.copyAlpha)
						daNote.alpha = strumAlpha;

					if(daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

					if (!pauseNotesMoving)
					{
						if(daNote.copyY)
						{
							daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

							// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							if(strumScroll && daNote.isSustainNote)
							{
								if (daNote.animation.curAnim.name.endsWith('end')) {
									daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
									daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
									if(PlayState.isPixelStage) {
										daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
									} else {
										daNote.y -= 19;
									}
								}
								daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
								daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
							}
						}
					} // I have no idea what im doing

					if (!daNote.mustPress && daNote.wasGoodHit)
					{
						opponentNoteHit(daNote);
					}

					if(!daNote.blockHit && daNote.mustPress && cpuControlled && daNote.canBeHit) {
						if(daNote.isSustainNote) {
							if(daNote.canBeHit) {
								goodNoteHit(daNote);
							}
						} else if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
							goodNoteHit(daNote);
						}
					}
					
					if (daNote.noteType != 'kitoDodge')
					{
						var center:Float = strumY + Note.swagWidth / 2;
						if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
							(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							if (strumScroll)
							{
								if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
								{
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}
							else
							{
								if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
								{
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}
						}
					}

					// Kill extremely late notes and cause misses
					if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();

						if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
							onMiss(daNote.noteData, daNote);
					}
				});
			}
			else
			{
				notes.forEachAlive(function(daNote:Note)
				{
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
			}
		}
		checkEventNote();

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		updateEditingMode(elapsed);
	}

	// hooray
	function zoomCams()
	{
		if (camManager.zoom.gameZooming)
			FlxG.camera.zoom += camManager.zoom.amounts.game * camManager.zoom.mult;
			
		camHUD.zoom += camManager.zoom.amounts.hud * camManager.zoom.mult;
		camOther.zoom += camManager.zoom.amounts.other * camManager.zoom.mult;
	}

	function getAltCharCol(char:String, bright:Bool = true, amt:Float = 0.2)
	{
		switch(char)
		{
			case 'bf', 'boyfriend':
				if (bright)
					return getCharCol(getCurBF()).getLightened(amt);
				else
					return getCharCol(getCurBF()).getDarkened(amt);

			case 'gf', 'girlfriend':
				if (bright)
					return getCharCol(gf).getLightened(amt);
				else
					return getCharCol(gf).getDarkened(amt);

			case 'dad':
				if (bright)
					return getCharCol(getCurDad()).getLightened(amt);
				else
					return getCharCol(getCurDad()).getDarkened(amt);
		}

		return 0xFFFFFFFF;
	}

	function pauseGame()
	{
		pauseStuff();

		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) 
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}
	}

	function openPauseMenu()
	{
		if (endingSong)
			return;

		pauseGame();

		hscriptManager.callAll('onPause', [getCurBF()]);
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		LoadingState.loadAndSwitchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence('Chart Editor');
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) 
	{
		if (practiceMode)
			return false;

		if (isDead)
			return false;

		if (health >= 0)
			return false;

		if (skipHealthCheck && instakillOnMiss)
		{
			var guy = getCurBF();

			guy.stunned = true;
			deathCounter++;

			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			persistentUpdate = false;
			persistentDraw = false;

			for (tween in modchartTweens)
				tween.active = true;
			
			for (timer in modchartTimers)
				timer.active = true;

			hscriptManager.callAll('onGameover', []);

			isDead = true;
			return true;
		}

		return false;
	}

	public function checkEventNote() 
	{
		while(eventNotes.length > 0) 
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			var value3:String = '';
			if(eventNotes[0].value3 != null)
				value3 = eventNotes[0].value3;

			triggerEventNote(eventNotes[0].event, value1, value2, value3);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, value3:String) 
	{
		if (hscriptManager != null && !hscriptManager.exists(eventName) 
		&& ChartingState.HARDCODED_EVENTS != null && !ChartingState.HARDCODED_EVENTS.contains(eventName) 
		&& ignoreEventHscript != null && !ignoreEventHscript.contains(eventName))
		{
			Paths.VERBOSE = false;

			for (mod in Paths.getModDirectories())
			{
				var script:String = Paths.eventScript(eventName, mod);
				if (script != null)
				{
					hscriptManager.addScriptFromPath(script);
					hscriptManager.call('start', [SONG.song], eventName);
				}
			}

			Paths.VERBOSE = true;
		}

		switch(eventName) 
		{
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf', 'boyfriend', '0':
						value = 0;
					case 'gf', 'girlfriend', '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					var dad = getCurDad();

					if(dad.curCharacter.startsWith('gf')) 
					{ //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering

						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} 
					else if (gf != null) 
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if(value != 1) 
				{
					var boyfriend = getCurBF();

					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && camManager.zoom.zooming && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = getCurDad();
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = getCurBF();
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = getCurBF();
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Alt Idle Animation':
				var char:Character = getCurDad();
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = getCurBF();
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = getCurBF();
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Scroll Speed':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (songSpeedType == "constant")
				   return;

				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;


				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Anim Suffix':
				if (!charNames.contains(value1))
				{
					trace('Character "$value1" not found, cannot set anim suffix');
					return;
				}

				var char = char(value1);
				char.animSuffix = '-$value2';

			case 'Load Rim Light File':
				if (value1 != null)
					loadRimLightJson(value1);

			case 'Load Shadow File':
				if (value1 != null)
					loadRimLightJson(value1);
		}

		if (hscriptManager != null)
			hscriptManager.callAll('onEvent', [eventName, value1, value2, value3]);
	}

	function moveCameraSection():Void 
	{
		if(SONG.sections[curSection] == null) return;

		var newFocus = SONG.sections[curSection].charFocus;
		if (charFocus != newFocus)
			moveCamera(newFocus);
	}

	var cameraTwn:FlxTween;
	public function moveCamera(charToFocus:Int)
	{
		var char = characters[charToFocus];

		var point:FlxPoint = char.getCameraPosition();

		var offset = getCameraOffset(char.isPlayer);
		point.x += offset[0];
		point.y += offset[1];

		camManager.focusOnPoint(point);
	}

	function getCameraOffset(isPlayer:Bool)
	{
		return isPlayer ? playerCameraOffset : opponentCameraOffset;
	}

	function tweenCamIn(camZoom:Float = 1.3):Void
	{
		FlxTween.tween(FlxG.camera, {zoom: camZoom}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	function zoomCamera2(zoom:Float = 1, time:Int = 1)
        {
        FlxTween.tween(FlxG.camera, {zoom: zoom}, time, {ease: FlxEase.quadInOut, onComplete: 					
					function (twn:FlxTween)
					{
					camlock2();
					}});
        }

	function camlock2()
	{
        camManager.defaultZoom = FlxG.camera.zoom;
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		hscriptManager.callAll('preEndSong', []);

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();

		endingSong = true;

		if (videoToPlay != '')
			startVideo(videoToPlay)
		else
		{
			if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
				finishCallback();
			} else {
				finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
					finishCallback();
				});
			}
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		hscriptManager.callAll('onEndSong', []);

		//Should kill you if you tried to cheat
		if(!startingSong) 
		{
			notes.forEach(function(daNote:Note) 
			{
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) 
					health -= 0.05 * healthLoss;
			});

			for (daNote in unspawnNotes) 
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;

			if (doDeathCheck())
				return;
		}

		canPause = false;
		endingSong = true;
		camManager.zoom.zooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		if (transitioning) 
			return;

		playbackRate = 1;

		storyPlaylist.remove(storyPlaylist[0]);

		if (storyPlaylist.length <= 0)
		{
			cancelMusicFadeTween();
			if(FlxTransitionableState.skipNextTransIn)
				CustomFadeTransition.nextCamera = null;

			changedDifficulty = false;
		}
		else
		{
			trace('LOADING NEXT SONG');
			trace(PlayState.storyPlaylist[0]);

			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0]);
			FlxG.sound.music.stop();

			cancelMusicFadeTween();
			LoadingState.loadAndSwitchState(new PlayState());
		}

		transitioning = true;
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {

	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!cpuControlled && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || controls.controllerMode))
		{
			if(!getCurBF().stunned && generatedMusic && !endingSong)
			{
				var lastTime:Float = Conductor.songPosition;
				if (FlxG.sound.music != null)
					Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.data.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) 
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) 
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else
					if (canMiss)
						onMiss(key);

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				if (FlxG.sound.music != null)
					Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if(!cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}

			if (key == FlxKey.SPACE)
				return 10;
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();

		if(controls.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		var lol = getCurBF();

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !lol.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote);
				}
			});

			if (FlxG.sound.music != null && lol.animation.curAnim != null && lol.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * lol.singDuration && lol.animation.curAnim.name.startsWith('sing') && !lol.animation.curAnim.name.endsWith('miss'))
				lol.dance();
		}

		if(controls.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}

	function onMiss(dir:Int, noteRef:Note = null)
	{
		hscriptManager.callAll('onMiss', [dir, noteRef]);
	}

	function opponentNoteHit(note:Note):Void
	{
		var charIndex:Int = charNames.indexOf(note.attachedChar);

		var char:Dynamic = getCurDad();

		var animToPlay:String = SING_ANIMATIONS[Std.int(Math.abs(note.noteData))] + char.animSuffix;
		
		if(!note.noAnimation) 
		{
			if(char != null)
			{
				if (char.curAnim != null)
					char.curAnim.finish();
				
				if (!note.animation.curAnim.name.endsWith('end'))
				{
					char.playAnim(animToPlay, true);
					char.holdTimer = 0;
				}
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
			time += 0.15;

		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)), time);

		hscriptManager.callAll('opponentNoteHit', [note]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (note.wasGoodHit)
			return;

		vocals.volume = 1;
		
		if(cpuControlled && note.hitCausesMiss) return;

		var charIndex = charNames.indexOf(note.attachedChar);

		var char:Dynamic = getCurBF();

		var animToPlay:String = SING_ANIMATIONS[Std.int(Math.abs(note.noteData))] + char.animSuffix;

		if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

		if(note.hitCausesMiss) 
		{
			onMiss(note.noteData, note);

			note.wasGoodHit = true;
			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
			return;
		}

		if(!note.noAnimation)
		{
			char.playAnim(animToPlay + char.animSuffix, true);
			char.holdTimer = 0;
		}

		if(cpuControlled) 
		{
			var time:Float = 0.15;
			if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				time += 0.15;
			
			StrumPlayAnim(false, Std.int(Math.abs(note.noteData)), time);
		} 
		else 
		{
			var spr = playerStrums.members[note.noteData];
			if(spr != null)
			{
				spr.playAnim('confirm', true);
			}
		}
		note.wasGoodHit = true;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		hscriptManager.callAll('goodNoteHit', [note]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	override function destroy() 
	{
		if(!controls.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		FlxG.animationTimeScale = 1;

		if (FlxG.sound.music != null)
			FlxG.sound.music.pitch = 1;

		super.destroy();
	}

	public static function cancelMusicFadeTween() 
	{
		if (FlxG.sound.music == null)
			return;

		if (FlxG.sound.music.fadeTween != null)
			FlxG.sound.music.fadeTween.cancel();
		
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	var weaklingFC:Bool = true;
        var xFC:Bool = true;
	override function stepHit()
	{
		super.stepHit();
		hscriptManager.setAll("curStep", curStep);
		hscriptManager.callAll("stepHit", [curStep]);

		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();
		hscriptManager.setAll('curBeat', curBeat);
		hscriptManager.callAll('beatHit', [curBeat]);

		if(lastBeatHit >= curBeat)
			return;

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		if (gf != null && curBeat % Std.int(gfSpeed * gf.danceEveryNumBeats) == 0 && (gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") || gf.animation.curAnim == null) && !gf.stunned)
		{
			gf.dance();
			hscriptManager.callAll('gfDance', []);
		}

		for (char in characters)
		{
			if (char.animation.curAnim == null)
				continue;

			if (char.animation.curAnim.name.startsWith('sing'))
				continue;

			if (char.stunned)
				continue;

			if (char.animation.curAnim.name == 'idle' && char.animation.curAnim.looped)
				continue;

			if (curBeat % char.danceEveryNumBeats != 0)
				continue;

			char.dance();
			hscriptManager.callAll('bfDance', []);
		}

		lastBeatHit = curBeat;

		if (curBeat % camManager.zoom.interval == 0 && camManager.zoom.zooming)
			zoomCams();
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.sections[curSection] != null)
		{
			if (generatedMusic && !endingSong)
				moveCameraSection();

			if (camManager.zoom.zooming && FlxG.camera.zoom < 1.35)
				zoomCams();

			if (SONG.sections[curSection].changeBPM)
				Conductor.changeBPM(SONG.sections[curSection].bpm);

			charFocus = SONG.sections[curSection].charFocus;
			hscriptManager.setAll('charFocus', charFocus);
		}

		hscriptManager.callAll('sectionHit', [curSection]);
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}
	
	function updateCharCols()
	{
		bfCol = getCharCol(getCurBF());
		dadCol = getCharCol(getCurDad());
		gfCol = getCharCol(gf);

		reloadHealthBarColors();
	}

	public function getCurBF()
	{
		return characters[curBF];
	}

	public function getCurDad()
	{
		return characters[SONG.players.length + curDAD];
	}

	public function char(name:String)
	{
		if (gf.name == name)
			return gf;

		if (!charNames.contains(name))
			return new Character(0, 0, '', true);

		return characters[charNames.indexOf(name)];
	}
}
