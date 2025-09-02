package;

import a2.time.backend.Assets;
import a2.time.backend.managers.UndoManager;
import a2.time.objects.ui.CustomSoundTray;
import a2.time.objects.ui.FPS;
import a2.time.states.BaseState;
import a2.time.states.CustomState;
import a2.time.states.PlayState;
// import a2.time.util.Discord;
// import a2.time.util.Discord.DiscordClient;
import a2.time.backend.ClientPrefs;

import flash.display.BitmapData;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;

import haxe.ui.Toolkit;

import lime.app.Application;
import lime.graphics.Image;
import lime.ui.KeyModifier;
import lime.ui.KeyCode;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.system.System;

import sys.FileSystem;
import sys.io.File;

#if CRASH_HANDLER
import haxe.CallStack;
import haxe.io.Path;

import openfl.events.UncaughtErrorEvent;

import sys.io.Process;
#end

using StringTools;

typedef StyleThing =
{
	name:String,
	path:String
}

class Main extends Sprite
{
	public static var baseTrace = haxe.Log.trace;
	public static var cwd:String;
	public static var curMusicName:String = "";

	public static inline final MOD_NAME:String = 'core';
	public static inline final ALERT_TITLE:String = 'WELCOME BACK';

	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = a2.time.states.IntroState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	public static var fpsVar:FPS;

	public static var styles:Map<String, StyleThing> = new Map();

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		cwd = Sys.getCwd();
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void
	{
		initHaxeUI();
		
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		var game:FlxGame = new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen);
	
		ClientPrefs.init();
		Assets.init();

		@:privateAccess game._customSoundTray = CustomSoundTray;
		FlxG.signals.preStateCreate.add(_ -> CustomSoundTray.removeObjects);
		FlxG.signals.postStateSwitch.add(CustomSoundTray.addObjects);
		
		addChild(game);

		a2.time.backend.Controls.instance = new a2.time.backend.Controls();

		#if !mobile
		fpsVar = new FPS(3, 3, 0xFFFFFF);
		addChild(fpsVar);

		Lib.application.window.onKeyDown.add(onKeyDown);

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		
		if(fpsVar != null)
			fpsVar.visible = ClientPrefs.get('showFPS');
		#end

		if (FlxG.save.data.timeVolume == null)
            FlxG.save.data.timeVolume = 10;

        FlxG.sound.volume = FlxG.save.data.timeVolume;

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.mouse.useSystemCursor = true;
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onFatalCrash);
		#end
		#end

		UndoManager.init();
		@:privateAccess addEventListener(Event.ENTER_FRAME, UndoManager.enterFrame);
		@:privateAccess addEventListener(Event.EXIT_FRAME, UndoManager.exitFrame);
	}

	private function initHaxeUI()
	{
		// HAXEUI !!
		Toolkit.init();
		Toolkit.theme = 'time';
		Toolkit.autoScale = true;

		haxe.ui.focus.FocusManager.instance.autoFocus = false;
		haxe.ui.focus.FocusManager.instance.enabled = true;
		haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
	}

	public static function setWindowIcon(path:String):Void
	{
		var icon:Image = Image.fromFile(path);
		Lib.application.window.setIcon(icon);
	}

	private function onKeyDown(key:Int, modifiers:KeyModifier):Void
	{
		switch(key)
		{
			// refresh cache
			case KeyCode.F5:
				Assets.clearKeys();
				@:privateAccess if (BaseState.currentState is CustomState) CustomState.resetCustomState();

			case KeyCode.F6:
				trace(Std.string(haxe.ui.focus.FocusManager.instance.focus));
				trace(BaseState.instance.blockInput);
			
			case KeyCode.F7:
				trace('Refreshing style...');

				for (key in styles.keys())
				{
					var style = styles.get(key);

					trace(style.name);

					Toolkit.styleSheet.clear(style.name);
					Toolkit.styleSheet.parse(File.getContent(style.path), style.name);
				}

				trace('Done.');

		}
	}

	public static function parseStyle(path:String, name:String)
	{
		var thing:StyleThing = {name: name, path: path};

		styles.set(name, thing);
		Toolkit.styleSheet.parse(File.getContent(thing.path), thing.name);
	}

	public static var halfWidth(get, never):Float;
    public static function get_halfWidth():Float return flixel.FlxG.width / 2;

    public static var halfHeight(get, never):Float;
    public static function get_halfHeight():Float return flixel.FlxG.height / 2;

	public static inline function moveFPS(value:Float):Void
    {
		if (Main.fpsVar == null) return;
		
        flixel.tweens.FlxTween.cancelTweensOf(Main.fpsVar);
        flixel.tweens.FlxTween.tween(Main.fpsVar, {y: value + 3}, 1, {ease: flixel.tweens.FlxEase.elasticOut});
    }

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	private function onCrash(e:UncaughtErrorEvent):Void
	{
		handleCrash(e.error);
		if (CustomState.instance.hscriptManager != null) CustomState.instance.hscriptManager.callAll('onCrash', [e]);
		PlayState.callAllScripts('onCrash', [e]);
	}

	// ELITEMASTERERIC I FUCKING LOVE YOU
	private function onFatalCrash(msg:String):Void 
	{
		handleCrash(msg);
		if (CustomState.instance.hscriptManager != null) CustomState.instance.hscriptManager.callAll('onFatalCrash', [msg]);
		PlayState.callAllScripts('onCrash', [msg]);
	}

	private function handleCrash(msg:String):Void
	{
		var errMsg:String = "\n";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "TIME_" + dateNow + ".txt";

		errMsg += '$msg\n';

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += 'in ${file} (line ${line})\n';
				default:
					Sys.println(stackItem);
			}
		}

		@:privateAccess
		{
			var manage:a2.time.backend.managers.HscriptManager = null;

			if (a2.time.states.BaseState.currentState is a2.time.states.LoadingState)
				manage = a2.time.states.LoadingState.instance.loadingScreen;

			if (a2.time.states.BaseState.currentSubState is a2.time.substates.CustomSubState)
				manage = a2.time.substates.CustomSubState.instance.hscriptManager;

			if (a2.time.states.BaseState.currentState is PlayState)
				manage = PlayState.gameInstance.hscriptManager;

			if (a2.time.states.BaseState.currentState is a2.time.states.CustomState)
				manage = a2.time.states.CustomState.instance.hscriptManager;

			if (manage != null && errMsg.contains('HscriptManager.hx'))
			{
				var interp:hscript.InterpEx = manage.states.get(manage.currentScript);
				errMsg += '\nin ${interp.nameToLog}.hscript (Line ${interp.curLine})';
			}
		}

		errMsg += "\n\n> Crash Handler written by: squirra-rng, EliteMasterEric, and [A2]";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		if (CustomState.instance.hscriptManager != null) CustomState.instance.hscriptManager.callAll('onHandleCrash', [errMsg]);

		Application.current.window.alert(errMsg, "Error!");
		// DiscordClient.shutdown();
		Sys.exit(1);
	}
	#end
}
