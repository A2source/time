package a2.time.states;

import a2.time.objects.song.Conductor;
import a2.time.objects.song.Conductor.BPMChangeEvent;
import a2.time.util.Controls;
import a2.time.util.ClientPrefs;

import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import openfl.Lib;

import haxe.ui.core.Screen;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.focus.FocusManager;
import haxe.ui.Toolkit;

class MusicBeatState extends FlxUIState
{
	private var prevSection:Int = 0;
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	private var uiLayer:haxe.ui.containers.VBox = null;

	public var blockInput:Bool = false;

	public static var transitioning:Bool = false;

	public static final IGNORE_COMPONENT:Array<String> = 
	[
		'[object TabBarButton]',
		'[object Window]'
	];

	// bullshit
	static var lol:MusicBeatState;

	inline function get_controls():Controls
		return Controls.instance;

	override function create() 
	{
		camBeat = FlxG.camera;

		super.create();

		// HAXEUI!!
		uiLayer = new haxe.ui.containers.VBox();
		uiLayer.percentWidth = 100;
		uiLayer.percentHeight = 100;

		lol = this;

		transitioning = false;

		FlxG.mouse.visible = false;

		Toolkit.screen.addComponent(uiLayer);

		FlxG.cameras.setDefaultDrawTarget(FlxG.camera, true);
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);

		if (FlxG.keys.justPressed.F6)
			trace(Std.string(FocusManager.instance.focus));

		if (FocusManager.instance.focus != null && !IGNORE_COMPONENT.contains(Std.string(FocusManager.instance.focus)))
		{
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];

			blockInput = true;
		}
		else
		{
			FlxG.sound.muteKeys = IntroState.muteKeys;
			FlxG.sound.volumeDownKeys = IntroState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = IntroState.volumeUpKeys;

			blockInput = false;
		}
	}

	public function unblockInput()
	{
		if (FocusManager.instance.focus == null)
			return;

		FocusManager.instance.focus.focus = false;

		// i unfocused but forgot to turn this off so the keys were still locked
		blockInput = false;
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			prevSection = curSection;
			
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.sections.length)
		{
			if (PlayState.SONG.sections[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState) {
/*
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if(!FlxTransitionableState.skipNextTransIn) {
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if(nextState == FlxG.state) {
				CustomFadeTransition.finishCallback = function() {
					FlxG.resetState();
				};
				//trace('resetted');
			} else {
				CustomFadeTransition.finishCallback = function() {
					FlxG.switchState(nextState);
				};
				//trace('changed state');
			}
			return;
		}
*/

		resetHaxeUI();

		transitioning = true;

		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;
		
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public static function resetHaxeUI()
	{
		WindowManager.instance.reset();
		WindowManager.instance.container = new haxe.ui.core.Component();

		Toolkit.screen.removeComponent(lol.uiLayer);

		@:privateAccess haxe.ui.ToolkitAssets.instance._imageCache?.clear();
	}

	public static function getState():MusicBeatState 
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.sections[curSection] != null) val = PlayState.SONG.sections[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
