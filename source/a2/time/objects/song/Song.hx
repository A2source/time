package a2.time.objects.song;

import a2.time.objects.song.Section.SongSection;
import a2.time.objects.song.Section.SwagSection;
import a2.time.objects.gameplay.Note.NoteFile;
import a2.time.objects.gameplay.Note.EventNote;
import a2.time.states.LoadingState;
import a2.time.states.editors.ChartingState;
import a2.time.states.PlayState;
import a2.time.Paths;

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

typedef SongMetadata =
{
	var musicians:Array<String>;
	var voiceActors:Array<String>;
	var charters:Array<String>;
	var programmers:Array<String>;
	var additionalArtists:Array<String>;
	var additionalAnimators:Array<String>;
}

typedef SwagSong =
{
	var version:String;

	var song:String;
	var stage:String;

	var metadata:SongMetadata;

	var sections:Array<SongSection>;
	var notes:Map<String, Map<String, Array<NoteFile>>>;

	var events:Array<EventNote>;

	var bpm:Float;
	var speed:Float;

	var needsVoices:Bool;

	var players:Array<String>;
	var opponents:Array<String>;
	var autoGF:String;

	var validScore:Bool;
}

class Song
{
	public static inline var CHART_VERSION_STRING:String = 'Created with TIME v2.0.0';

	public var song:String;
	public var difficulty:String;
	public var stage:String;

	public var sections:Array<SongSection>;
	public var notes:Map<String, Array<NoteFile>>;

	public var events:Array<EventNote>;

	public var players:Array<String> = ['bf'];
	public var opponents:Array<String> = ['dad'];

	public var characters:Array<String>;

	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var speed:Float = 1;
	public var autoGF:String = 'gf';

	public function new(song, sections, notes, bpm)
	{
		this.song = song;

		this.sections = sections;
		this.notes = notes;

		for (segment in [this.players, this.opponents])
			for (char in segment)
				this.characters.push(char);

		this.bpm = bpm;
	}

	public static function loadFromJson(songName:String, ?openChartOnFail:Bool = false):SwagSong
	{
		var rawJson = null;
		var rawEventJson = null;

		var moddyFile:String;
		moddyFile = Paths.modsSongJson(songName, songName, Paths.WORKING_MOD_DIRECTORY);

		trace('TRYING TO LOAD CHART $moddyFile');
		if (moddyFile != null)
			rawJson = File.getContent(moddyFile).trim();
		else
		{
			Lib.application.window.alert('Chart "$songName" not found. It does not exist.', Main.ALERT_TITLE);
			LoadingState.loadAndSwitchCustomState('IntroState');
			return null;
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var songJson:Dynamic = parseJSONshit(rawJson, songName);

		trace('success! loaded $moddyFile');

		if(songJson != null) 
			StageData.loadDirectory(songJson);

		return songJson;
	}

	public static function parseJSONshit(rawJson:String, songName:String):SwagSong
	{
		var parsedSong:SwagSong = cast Json.parse(rawJson);

		if (!Reflect.hasField(parsedSong, 'version'))
		{
			Lib.application.window.alert('Chart is not in the correct format.\nOpen the Chart Convert Menu in the Master Menu\nto convert this chart.', Main.ALERT_TITLE);
			LoadingState.loadAndSwitchCustomState('IntroState');
			return null;
		}

		var stupid:Map<String, SwagSong> = new Map();
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

		var formattedSong:SwagSong = 
		{
			version: Song.CHART_VERSION_STRING,

			song: '',
			stage: '',

			metadata: null,

			sections: [],
			notes: cast notesThing,

			events: [],

			bpm: 0,
			speed: 0,

			needsVoices: false,

			players: [],
			opponents: [],
			autoGF: '',

			validScore: true
		};

		var _song:String = cast stupid.get('song');
		trace('loading $_song');
		formattedSong.song = _song;

		var _stage:String = cast stupid.get('stage');
		formattedSong.stage = _stage;

		var _metadata:SongMetadata = cast stupid.get('metadata');
		formattedSong.metadata = _metadata;

		var _sections:Array<SongSection> = cast stupid.get('sections');
		formattedSong.sections = _sections;

		var _events:Array<EventNote> = cast stupid.get('events');
		formattedSong.events = _events;

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

		var _autoGF:String = cast stupid.get('autoGF');
		formattedSong.autoGF = _autoGF;

		trace('returning song name "${formattedSong.song}"');

		return formattedSong;
	}
}
