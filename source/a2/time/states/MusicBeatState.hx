package a2.time.states;

import a2.time.objects.song.Conductor;
import a2.time.objects.song.Conductor.BPMChangeEvent;
import a2.time.backend.ClientPrefs;

import flixel.FlxG;

class MusicBeatState extends BaseState
{
	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	override function update(dt:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep) if(curStep > 0) stepHit();

		super.update(dt);
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
