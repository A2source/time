package a2.time.substates;

import a2.time.states.IntroState;
import a2.time.util.Controls;
import a2.time.objects.song.Conductor;
import a2.time.objects.song.Conductor.BPMChangeEvent;
import a2.time.util.ClientPrefs;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;

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

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);

		if (FocusManager.instance.focus != null && !a2.time.states.MusicBeatState.IGNORE_COMPONENT.contains(Std.string(FocusManager.instance.focus)))
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

		blockInput = false;
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

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
}
