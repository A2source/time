package a2.time.substates;

import a2.time.states.IntroState;
import a2.time.backend.Controls;
import a2.time.objects.song.Conductor;
import a2.time.objects.song.Conductor.BPMChangeEvent;
import a2.time.backend.ClientPrefs;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;

import haxe.ui.core.Screen;
import haxe.ui.focus.FocusManager;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;

	public var blockInput:Bool = false;

	override function update(dt:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(dt);

		if (FocusManager.instance.focus != null || Screen.instance.hasSolidComponentUnderPoint(Screen.instance.currentMouseX, Screen.instance.currentMouseY))
		{
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];

			this.blockInput = true;
		}
		else
		{
			FlxG.sound.muteKeys = IntroState.muteKeys;
			FlxG.sound.volumeDownKeys = IntroState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = IntroState.volumeUpKeys;

			this.blockInput = false;
		}
	}

	public function unblockInput()
	{
		if (FocusManager.instance.focus == null)
			return;

		FocusManager.instance.focus.focus = false;

		this.blockInput = false;
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		curDecStep = Conductor.decStep;
		curStep = Math.floor(curDecStep);
	}

	public function stepHit():Void if (curStep % 4 == 0) beatHit();
	public function beatHit():Void {}
}
