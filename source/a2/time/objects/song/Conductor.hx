package a2.time.objects.song;

import a2.time.objects.gameplay.Character;
import a2.time.backend.Paths;
import a2.time.states.PlayState;
import a2.time.objects.song.Song.TimeSong;
import a2.time.objects.gameplay.notes.Note;
import a2.time.backend.managers.ChartEventManager;
import a2.time.backend.ClientPrefs;

typedef BPMChangeEvent =
{
	var step:Int;
	var ms:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

typedef CharacterFocusEvent = 
{
	var c:String;
	var ms:Float;
}

class Conductor
{
	public static var song:TimeSong;

	public static var lastFocus(get, never):CharacterFocusEvent;
	public static function get_lastFocus():CharacterFocusEvent return getLastFocus(songPosition);

	public static var focus(get, never):String;
	public static function get_focus():String return lastFocus.c;

	public static var lastChange(get, never):BPMChangeEvent;
	public static function get_lastChange():BPMChangeEvent return getLastChange(songPosition);

	public static var bpm(get, never):Float;
	public static function get_bpm():Float return lastChange.bpm;
	
	public static var initBPM:Float = 100;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	public static var charFocusMap:Array<CharacterFocusEvent> = [];

	public static var onBPMRemap:Array<Void->Void> = [];
	public static var onCharFocusRemap:Array<Void->Void> = [];

	public static var crochet(get, never):Float;
	public static function get_crochet():Float return stepCrochet * 4;

	public static var stepCrochet(get, never):Float;
	public static function get_stepCrochet():Float return lastChange.stepCrochet;

	public static var timescale:Float = 1;

	public static var songPosition:Float = 0;
	public static var lastSongPos:Float;

	public static var offset:Float = 0;

	public static var safeZoneOffset(get, never):Float;
	public static function get_safeZoneOffset():Float return ClientPrefs.get('safeFrames') / 60 * 1000;

	public function new() {}

	public static function loadSong(name:String):TimeSong
	{
		Conductor.songPosition = 0;

		song = Song.loadFromJson(name);
		mapChanges();
		
		return song;
	}

	public static function loadSongFromString(content:String, name:String):TimeSong
	{
		song = Song.parseJSONshit(content, name);
		mapChanges();
		return song;
	}

	private static function mapChanges():Void
	{
		clearCallbacks();

		mapBPMChanges();
		mapCharFocus();
	}

	public static function clearCallbacks():Void
	{
		onBPMRemap.resize(0);
		onCharFocusRemap.resize(0);
	}

	public static function mapBPMChanges():Void
	{
		initBPM = song.bpm;
		bpmChangeMap.resize(0);

		var steps:Int = 0;

		var prev:{ms:Float, change:EventFile} = {
			ms: 0,
			change: {t: ChartEventManager.BPM_CHANGE_EVENT_NAME, e: [{n: 'BPM', v: song.bpm, t: 'FLOAT'}]}
		}
		
		var sortedEvents:Array<{ms:Float, change:EventFile}> = [];
		ChartEventManager.forEachEvent(song, (ms:Float, change:EventFile) ->
		{
			if (change.t != ChartEventManager.BPM_CHANGE_EVENT_NAME) return;
			sortedEvents.push({ms: ms, change: change});
		});
		if (sortedEvents.length > 0) sortedEvents.sort((a, b) -> { return a.ms < b.ms ? -1 : a.ms == b.ms ? 0 : 1; });

		var init = false;
		for (change in sortedEvents)
		{
			if (!init) 
			{
				init = true;
				bpmChangeMap.push({step: 0, ms: 0, bpm: song.bpm, stepCrochet: calculateStepCrochet(song.bpm)});
			}
	
			var bpm = change.change.e[0].v;
			steps += Std.int((change.ms - prev.ms) / calculateStepCrochet(prev.change.e[0].v));
	
			bpmChangeMap.push({
				step: steps,
				ms: change.ms,
				bpm: bpm,
				stepCrochet: calculateStepCrochet(bpm)
			});
	
			prev = change;
		}

		if (bpmChangeMap.length > 0) 
		{
			var instSong = Paths.mods.song.inst([song.song], Paths.WORKING_MOD_DIRECTORY).content;
			bpmChangeMap.push({
				step: steps + Std.int((instSong.length - prev.ms) / bpmChangeMap[0].stepCrochet), 
				ms: instSong.length, 
				bpm: initBPM, 
				stepCrochet: bpmChangeMap[0].stepCrochet
			});
		}
		else bpmChangeMap.push({step: 0, ms: 0, bpm: song.bpm, stepCrochet: calculateStepCrochet(song.bpm)});
	
		for (callback in onBPMRemap) callback();
	}

	public static function mapCharFocus():Void
	{
		charFocusMap.resize(0);

		var prev:CharacterFocusEvent = {
			c: song.players[0],
			ms: 0
		}
		
		var sortedEvents:Array<CharacterFocusEvent> = [];

		ChartEventManager.forEachEvent(song, (ms:Float, change:EventFile) ->
		{
			if (change.t != ChartEventManager.CHAR_FOCUS_EVENT_NAME) return;
			sortedEvents.push({ms: ms, c: change.e[0].v});
		});
		if (sortedEvents.length > 0) sortedEvents.sort((a, b) -> { return a.ms < b.ms ? -1 : a.ms == b.ms ? 0 : 1; });

		var init:Bool = false;
		for (change in sortedEvents)
		{
			if (!init) 
			{
				init = true;
				charFocusMap.push({ms: 0, c: prev.c});
			}

			charFocusMap.push({
				ms: change.ms,
				c: change.c
			});
	
			prev = change;
		}
		if (sortedEvents.length == 0) charFocusMap.push({ms: 0, c: prev.c});

		for (callback in onCharFocusRemap) callback();
	}

	public static function getCrochet(ms:Float):Float
	{
		var lastChange = getLastChange(ms);
		return lastChange.stepCrochet * 4;
	}
	public static function getStepCrochet(ms):Float return getCrochet(ms) / 4;

	public static function getLastChange(ms:Float):BPMChangeEvent
	{
		if (bpmChangeMap.length == 1) return bpmChangeMap[0];

		var change:BPMChangeEvent = {step: 0, ms: 0, bpm: initBPM, stepCrochet: calculateStepCrochet(initBPM)}
		for (event in bpmChangeMap) if (ms >= event.ms) change = event;
		return change;
	}
	public static function getLastChangeStep(step:Float):BPMChangeEvent
	{
		if (bpmChangeMap.length == 1) return bpmChangeMap[0];

		var change:BPMChangeEvent = {step: 0, ms: 0, bpm: initBPM, stepCrochet: calculateStepCrochet(initBPM)}
		for (event in bpmChangeMap) if (step >= event.step) change = event;
		return change;
	}

	public static function getLastFocus(ms:Float):CharacterFocusEvent
	{
		if (charFocusMap.length == 1) return charFocusMap[0];

		var change:CharacterFocusEvent = {ms: 0, c: song.players[0]}
		for (event in charFocusMap) if (ms >= event.ms) change = event;
		return change;
	}
	
	public static var decStep(get, never):Float;
	public static function get_decStep():Float return getStep(songPosition);

	public static var step(get, never):Int;
	public static function get_step():Int return Math.floor(getStep(songPosition));

	public static function getStep(ms:Float):Float
	{
		var prev:BPMChangeEvent = getLastChange(ms);
		return prev.step + ((ms - prev.ms) / prev.stepCrochet);
	}
	public static function getStepI(ms:Float):Int return Math.floor(getStep(ms));

	public static function getMS(step:Float):Float
	{
		var prev:BPMChangeEvent = getLastChangeStep(step);
		return prev.ms + (step - prev.step) * prev.stepCrochet;
	}

	public static function getBeat(ms:Float):Float return getStep(ms) / 4;
	public static function getBeatI(ms:Float):Int return Math.floor(getStepI(ms) / 4);

	static function getSectionBeats(song:TimeSong, section:Int):Int return 4;
	
	inline public static function calculateCrochet(bpm:Float):Float return (60 / bpm) * 1000;
	inline public static function calculateStepCrochet(bpm:Float):Float return calculateCrochet(bpm) / 4;
}