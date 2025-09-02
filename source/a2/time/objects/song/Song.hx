package a2.time.objects.song;

import a2.time.objects.song.Section.SongSection;
import a2.time.objects.song.Section.SwagSection;
import a2.time.objects.gameplay.notes.Note.NoteFile;
import a2.time.objects.gameplay.notes.Note.EventFile;
import a2.time.objects.util.ChartVersionUtil;
import a2.time.states.LoadingState;
import a2.time.states.PlayState;
import a2.time.backend.Paths;

import haxe.Json;
import haxe.DynamicAccess;
import haxe.format.JsonParser;
import lime.utils.Assets;
import openfl.Lib;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

typedef SongCredit =
{
	name:String,
	roles:Array<String>
}

typedef TimeSong =
{
	var version:String;

	var song:String;
	var stage:String;

	var metadata:Array<SongCredit>;

	var notes:Map<String, Map<String, Array<NoteFile>>>;
	var events:Map<String, Array<EventFile>>;

	var bpm:Float;
	var speed:Float;

	var needsVoices:Bool;

	var players:Array<String>;
	var opponents:Array<String>;
}

class Song
{
	public static inline var CHART_VERSION_STRING:String = ChartVersionUtil.CHART_EDITOR_VERSION;

	public static function loadFromJson(name:String, ?openChartOnFail:Bool = false):TimeSong
	{
		var paths = Paths.mods.song.chart([name], Paths.WORKING_MOD_DIRECTORY);

		var content:String = paths.content;

		if (content != null)
			content = content.trim();
		else
		{
			Lib.application.window.alert('Chart "$name" not found. It does not exist.', Main.ALERT_TITLE);
			LoadingState.switchCustomState('IntroState');
			return null;
		}

		while (!content.endsWith("}")) content = content.substr(0, content.length - 1);

		return parseJSONshit(content, name);
	}

	public static function parseJSONshit(content:String, name:String):TimeSong
	{
		var parsedSong:TimeSong = cast Json.parse(content);

		if (!Reflect.hasField(parsedSong, 'version'))
		{
			Lib.application.window.alert('Chart is not in the correct format.\nOpen the Chart Convert Menu in the Chart Editor\nto convert this chart.', Main.ALERT_TITLE);
			LoadingState.switchCustomState('IntroState');
			return null;
		}

		switch (parsedSong.version)
		{
			case 'Created with TIME v2.0.0': return ChartVersionUtil.timeChart100To200(content);
		}

		var stupid:Map<String, TimeSong> = new Map();
        for (field in Reflect.fields(parsedSong))
        	stupid.set(field, Reflect.field(parsedSong, field));

		var charNotes:Array<Dynamic> = [];
		var difficulties:Array<String> = [];

		for (difficulty in Reflect.fields(stupid.get('notes')))
		{
			difficulties.push(difficulty);
			charNotes.push(Reflect.field(stupid.get('notes'), difficulty));
		}

		var chars:Array<String> = [];
		var tempNotes:Map<String, Array<Array<NoteFile>>> = new Map();

		var notesThing:Map<String, Map<String, Array<NoteFile>>> = new Map();
		var i:Int = 0;
		for (notes in charNotes)
		{
			for (char in Reflect.fields(notes))
			{
				if (!chars.contains(char))
					chars.push(char);

				if (tempNotes.get(char) == null)
					tempNotes.set(char, []);

				tempNotes.get(char).push(Reflect.field(notes, char));
			}

			var theseNotes:Map<String, Array<NoteFile>> = new Map();

			for (char in chars)
				theseNotes.set(char, tempNotes[char][i]);

			notesThing.set(difficulties[i], theseNotes);

			i++;
		}

		var parsedGroupings:Array<Array<EventFile>> = [];
		var msKey:Array<String> = [];

		for (ms in Reflect.fields(stupid.get('events')))
		{
			msKey.push(ms);
			parsedGroupings.push(Reflect.field(stupid.get('events'), ms));
		}

		var eventsThing:Map<String, Array<EventFile>> = new Map();
		for (i in 0...msKey.length)
		{
			var key:String = msKey[i];
			var grouping:Array<EventFile> = parsedGroupings[i];

			eventsThing.set(key, grouping);
		}

		var formattedSong:TimeSong = 
		{
			version: ChartVersionUtil.CHART_EDITOR_VERSION,

			song: '',
			stage: '',

			metadata: null,

			notes: cast notesThing,
			events: cast eventsThing,

			bpm: 0,
			speed: 0,

			needsVoices: false,

			players: [],
			opponents: []
		}

		var _song:String = cast stupid.get('song');
		formattedSong.song = _song;

		var _stage:String = cast stupid.get('stage');
		formattedSong.stage = _stage;

		var _metadata:Array<SongCredit> = cast stupid.get('metadata');
		formattedSong.metadata = _metadata;

		var _bpm:Float = cast stupid.get('bpm');
		formattedSong.bpm = _bpm;

		var _speed:Float = cast stupid.get('speed');
		formattedSong.speed = _speed;

		var _needsVoices:Bool = cast stupid.get('needsVoices');
		formattedSong.needsVoices = _needsVoices;

		var _players:Array<String> = cast stupid.get('players');
		formattedSong.players = _players;

		var _opponents:Array<String> = cast stupid.get('opponents');
		formattedSong.opponents = _opponents;
		
		return formattedSong;
	}
}
