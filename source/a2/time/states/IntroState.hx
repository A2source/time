package a2.time.states;

import a2.time.objects.song.Highscore;
import a2.time.util.CoolUtil;
import a2.time.util.ClientPrefs;
import a2.time.util.Discord;

import a2.time.util.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSpriteUtil;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.util.FlxSave;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import lime.ui.Window;
import openfl.Assets;
import haxe.Json;
import openfl.Lib;

#if sys
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;
import sys.FileSystem;
import a2.time.objects.song.Song.SwagSong;
#end

import tjson.TJSON;
import flixel.input.keyboard.FlxKey;

import hscript.ParserEx;

using StringTools;

class IntroState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	
	static var initialized:Bool = false;
	static public var soundExt:String = ".ogg";
	static public var firstTime = false;

	function togglePersistUpdate(toggle:Bool)
	{
		persistentUpdate = toggle;
	}

	public static function makeTransition()
	{
		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
			{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
	}

	function getRandomObject(object:Dynamic):Array<Dynamic>
	{
		return (FlxG.random.getObject(object));
	}

	override public function create():Void
	{
		a2.time.util.Paths.clearStoredMemory();
		
		#if windows
		a2.time.util.Discord.DiscordClient.initialize();

		Application.current.onExit.add(function(exitCode)
		{
			a2.time.util.Discord.DiscordClient.shutdown();
		});
		#end
		
		super.create();

		FlxG.mouse.visible = false;

		FlxG.save.bind('time', '[A2]');

		ClientPrefs.loadPrefs();

		Highscore.load();

		trace('should be running startup now.');

		LoadingState.loadAndSwitchCustomState('IntroState');
	}
}
