package a2.time.states;

import a2.time.util.Controls;
import a2.time.util.Paths;
import a2.time.util.HscriptManager;

import a2.time.states.PlayState;
import a2.time.substates.CustomSubState;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import lime.system.System;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.system.FlxSound;
import a2.time.objects.song.Song.SwagSong;
import flixel.FlxBasic;
import openfl.geom.Matrix;
import flixel.FlxGame;
import flixel.graphics.FlxGraphic;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrailArea;
import openfl.filters.ShaderFilter;
import flixel.math.FlxPoint;
import a2.time.objects.song.Conductor.BPMChangeEvent;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.ui.FlxButton;
import haxe.Json;
import openfl.events.IOErrorEvent;
import flixel.util.FlxSort;
import flixel.effects.FlxFlicker;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.Lib;
import a2.time.util.Discord.DiscordClient;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import openfl.display.BlendMode;
import flixel.util.FlxSave;
import flixel.util.FlxAxes;
import flixel.ui.FlxBar;
import flixel.ui.FlxBar.FlxBarFillDirection;
import Std;
import openfl.filters.BitmapFilter;
import flixel.util.FlxStringUtil;
// import flixel.input.mouse.FlxMouseEvent;
// import flixel.input.mouse.FlxMouseEventManager;

#if desktop
import Sys;
import sys.FileSystem;
#end

#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;
#end

import hscript.Interp;
import hscript.Parser;
import hscript.ParserEx;
import hscript.InterpEx;
import hscript.ClassDeclEx;

import haxe.Json;
import tjson.TJSON;

using StringTools;

class CustomState extends MusicBeatState
{
	public static var instance:CustomState;

	public static var stateName:String;
	public static var modDirectory:String;

	private var hscriptManager:HscriptManager;

	// returns an interp with lots of the basic classes set
	public static function getBasicInterp(name:String = 'hscript'):Interp
	{
		var interp = new Interp(name);

		interp.variables.set("MP4Handler", a2.time.objects.util.MP4Handler);	
		interp.variables.set("FlxTextBorderStyle", FlxTextBorderStyle);
		interp.variables.set("FlxSprite", a2.time.objects.DynamicSprite);
		interp.variables.set("FlxText", FlxText);
		interp.variables.set("FlxSave", flixel.util.FlxSave);
		interp.variables.set("ChartingState", a2.time.states.editors.ChartingState);
		interp.variables.set("Alphabet", a2.time.objects.ui.Alphabet);
		interp.variables.set("CharacterEditorState", a2.time.states.editors.CharacterEditorState);
		interp.variables.set("pi", Math.PI);
		interp.variables.set("curMusicName", Main.curMusicName);
		interp.variables.set("Highscore", a2.time.objects.song.Highscore);
		interp.variables.set("Conductor", a2.time.objects.song.Conductor);
		interp.variables.set("HealthIcon", a2.time.objects.gameplay.HealthIcon);
		interp.variables.set("FlxTransitionableState", flixel.addons.transition.FlxTransitionableState);
		interp.variables.set("TitleState", a2.time.states.IntroState);
		interp.variables.set("IntroState", a2.time.states.IntroState);
		interp.variables.set("LoadingState", a2.time.states.LoadingState);
		interp.variables.set("makeTransition", a2.time.states.IntroState.makeTransition);
		interp.variables.set("Path", haxe.io.Path);
		interp.variables.set("Std", Std);
		interp.variables.set("FileSystem", sys.FileSystem);
		interp.variables.set("File", sys.io.File);
		interp.variables.set("Controls", a2.time.util.Controls);
		interp.variables.set("flixelSave", FlxG.save);
		interp.variables.set("Paths", a2.time.util.Paths);
		interp.variables.set("CoolUtil", a2.time.util.CoolUtil);
		interp.variables.set("Math", Math);
		interp.variables.set("FlxCamera", FlxCamera);
		interp.variables.set("FlxStringUtil", FlxStringUtil);

		interp.variables.set('colorFromCMYK', FlxColor.fromCMYK);
		interp.variables.set('colorFromHSB', FlxColor.fromHSB);
		interp.variables.set('colorFromHSL', FlxColor.fromHSL);
		interp.variables.set('colorFromInt', FlxColor.fromInt);
		interp.variables.set('colorFromRGB', FlxColor.fromRGB);
		interp.variables.set('colorFromRGBFloat', FlxColor.fromRGBFloat);
		interp.variables.set('colorFromString', FlxColor.fromString);

		interp.variables.set("FlxEffectSprite", flixel.addons.effects.chainable.FlxEffectSprite);
		interp.variables.set("FlxWaveEffect", flixel.addons.effects.chainable.FlxWaveEffect);
		interp.variables.set("FlxGlitchEffect", flixel.addons.effects.chainable.FlxGlitchEffect);
		interp.variables.set("Song", a2.time.objects.song.Song);
		interp.variables.set("Reflect", Reflect);
		interp.variables.set("PlayState", a2.time.states.PlayState);
		interp.variables.set("WeekData", a2.time.objects.song.WeekData);
		interp.variables.set("DiscordClient", a2.time.util.DiscordClient);
		interp.variables.set("controls", a2.time.util.Controls.instance);
		interp.variables.set("FlxObject", FlxObject);
		interp.variables.set("FlxCameraFollowStyle", FlxCameraFollowStyle);

		interp.variables.set("CustomState", CustomState);
		interp.variables.set("CustomSubState", CustomSubState);

		interp.variables.set('ClientPrefs', a2.time.util.ClientPrefs);
		interp.variables.set("MusicBeatState", a2.time.states.MusicBeatState);
		interp.variables.set("Note", a2.time.objects.gameplay.Note);
		interp.variables.set("Section", a2.time.objects.song.Section);
		interp.variables.set("ColorSwap", a2.time.shader.ColorSwap);
		interp.variables.set("Song", a2.time.objects.song.Song);
		interp.variables.set("FlxFlicker", FlxFlicker);
		interp.variables.set("FlxGroup", flixel.group.FlxGroup);
		interp.variables.set("FlxTrailArea", FlxTrailArea);
		interp.variables.set("ShaderFilter", openfl.filters.ShaderFilter);
		interp.variables.set("FlxTypedSpriteGroup", flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup);
		interp.variables.set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);
		interp.variables.set("FlxTypedGroup", flixel.group.FlxGroup.FlxTypedGroup);
		interp.variables.set("FlxSkewedSprite", flixel.addons.effects.FlxSkewedSprite);
		interp.variables.set("FlxBackdrop", flixel.addons.display.FlxBackdrop);
		interp.variables.set("Json", haxe.Json);
		interp.variables.set("stringifyJson", function(object:Dynamic, ?space:String) { return haxe.Json.stringify(object, space); });
		interp.variables.set("FlxSound", FlxSound);
		interp.variables.set("FlxGridOverlay", FlxGridOverlay);
		interp.variables.set("FlxG", FlxG);
		interp.variables.set("AttachedSprite", a2.time.objects.ui.AttachedSprite);
		interp.variables.set("AttachedText", a2.time.objects.ui.AttachedText);
		interp.variables.set("FlxTimer", flixel.util.FlxTimer);
		interp.variables.set("window", Lib.application.window);
		interp.variables.set("Lib", openfl.Lib);
		interp.variables.set("blendModeFromString", CustomState.blendModeFromString);
		interp.variables.set("InputFormatter", a2.time.objects.util.InputFormatter);
		interp.variables.set('CustomFadeTransition', a2.time.objects.util.CustomFadeTransition);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('FlxAtlasFrames', flixel.graphics.frames.FlxAtlasFrames);
		interp.variables.set('FlxMath', flixel.math.FlxMath);
		interp.variables.set('FlxBar', FlxBar);
		interp.variables.set('FlxBarFillDirection', FlxBarFillDirection);

		interp.variables.set('AXES_X', FlxAxes.X);
		interp.variables.set('AXES_Y', FlxAxes.Y);
		interp.variables.set('AXES_XY', FlxAxes.XY);

		interp.variables.set('StringTools', StringTools);
		interp.variables.set('ValueType', Type.ValueType);

		interp.variables.set("Character", a2.time.objects.gameplay.Character);
		interp.variables.set("Boyfriend", a2.time.objects.gameplay.Boyfriend);

		interp.variables.set('OUTLINE', FlxTextBorderStyle.OUTLINE);

		interp.variables.set("byteArrayFromFile", ByteArray.fromFile);
		interp.variables.set("BitmapFilter", BitmapFilter);

		interp.variables.set("alert", openfl.Lib.application.window.alert);

		interp.variables.set("Main", Main);
		interp.variables.set("ALERT_TITLE", Main.ALERT_TITLE);
		interp.variables.set('MOD_NAME', Main.MOD_NAME);
		interp.variables.set('WORKING_MOD_DIRECTORY', Paths.WORKING_MOD_DIRECTORY);

		interp.variables.set("Interp", Interp);
		interp.variables.set("ParserEx", ParserEx);
		interp.variables.set('HscriptManager', HscriptManager);

		interp.variables.set('UIShortcuts', a2.time.util.UIShortcuts);
		interp.variables.set('UiS', a2.time.util.UIShortcuts);

		interp.variables.set('Button', haxe.ui.components.Button);
		interp.variables.set('TextField', haxe.ui.components.TextField);
		interp.variables.set('TextArea', haxe.ui.components.TextArea);
		interp.variables.set('HorizontalSlider', haxe.ui.components.HorizontalSlider);
		interp.variables.set('VerticalSlider', haxe.ui.components.VerticalSlider);
		interp.variables.set('CheckBox', haxe.ui.components.CheckBox);

		interp.variables.set('Type', Type);
		interp.variables.set('Array', Array);

		interp.variables.set('Box', haxe.ui.containers.Box);
		interp.variables.set('HBox', haxe.ui.containers.HBox);
		interp.variables.set('VBox', haxe.ui.containers.VBox);
		interp.variables.set('TabView', haxe.ui.containers.TabView);
		interp.variables.set('ListView', haxe.ui.containers.ListView);
		interp.variables.set('ScrollView', haxe.ui.containers.ScrollView);
		interp.variables.set('getDataSource', function()
		{
			return new haxe.ui.data.ArrayDataSource<Dynamic>();
		});

		interp.variables.set('FocusManager', haxe.ui.focus.FocusManager);

		interp.variables.set('Screen', haxe.ui.Toolkit.screen);

		interp.variables.set('blockInput', MusicBeatState.instance.blockInput);
		interp.variables.set('this', CustomState.instance);

		return interp;
	}

	function injectInterp(interp:Interp)
	{
		interp.variables.set('add', instance.add);
		interp.variables.set('remove', instance.remove);
		interp.variables.set('insert', instance.insert);
        interp.variables.set('replace', instance.replace);

		interp.variables.set('openCustomSubState', openCustomSubState);
		interp.variables.set('closeSubState', instance.closeSubState);
		interp.variables.set('persistentUpdate', instance.persistentUpdate);
	}

	override function create()
	{
		super.create();

		instance = this;

		trace('Creating new custom state "$stateName" from mod "$modDirectory"');
		trace(Paths.mods('custom_states', modDirectory));

		hscriptManager = new HscriptManager(injectInterp);
		hscriptManager.addScriptFromPath(Paths.customState(stateName, modDirectory));
		hscriptManager.callAll('create', []);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		hscriptManager.callAll('update', [elapsed]);

		// reset the state
		if (FlxG.keys.justPressed.ONE) LoadingState.loadAndSwitchCustomState(stateName, modDirectory);
	}

	override function beatHit()
	{
		super.beatHit();
		hscriptManager.setAll('curBeat', curBeat);
		hscriptManager.callAll('beatHit', [curBeat]);
	}

	override function stepHit()
	{
		super.stepHit();
		hscriptManager.setAll('curStep', curStep);
		hscriptManager.callAll('stepHit', [curStep]);
	}

	public function openCustomSubState(name:String, ?modDirectory:String = Main.MOD_NAME):CustomSubState
	{
		var sub:CustomSubState = new CustomSubState(name, this, modDirectory);
		openSubState(sub);

		return sub;
	}

	override function closeSubState() 
	{
		super.closeSubState();
		hscriptManager.callAll('onCloseSubState', []);
	}

	public static function blendModeFromString(blend:String):BlendMode 
	{
		switch(blend.toLowerCase().trim()) 
		{
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
		}
		return NORMAL;
	}
}