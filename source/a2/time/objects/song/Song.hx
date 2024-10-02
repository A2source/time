package a2.time.objects.song;

import a2.time.objects.song.Section.SongSection;
import a2.time.objects.song.Section.SwagSection;
import a2.time.objects.gameplay.Note.NoteFile;
import a2.time.objects.gameplay.Note.EventNote;
import a2.time.states.LoadingState;
import a2.time.states.editors.ChartingState;
import a2.time.states.PlayState;
import a2.time.util.Paths;

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

	var countdownType:String;

	var validScore:Bool;
}

// for conversion :p
typedef OldSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var countdownType:String;
	var stage:String;

	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;
}

class Song
{
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
	public var countdownType:String = 'normal';

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
		moddyFile = Paths.modsSongJson(songName, songName);

		trace('TRYING TO LOAD CHART $moddyFile');
		if (moddyFile != null)
			rawJson = File.getContent(moddyFile).trim();
		else
		{
			if (openChartOnFail)
			{
				Lib.application.window.alert('Opening chart "$songName" to convert.', Main.ALERT_TITLE);
				LoadingState.loadAndSwitchState(new ChartingState(songName));

				return null;
			}

			var diffToCheck:Array<String> = ['-easy', '', '-hard'];

			for (dif in diffToCheck)
			{
				var jsonName = songName.replace(' ', '-').toLowerCase();
				trace('searching psych chart "$jsonName$dif"');
				if (Paths.modsSongJson(songName, '$jsonName$dif') != null)
				{
					trace('Converting song "$songName" from Psych format.');
					return convertFromPsych(songName, jsonName, dif);
				}
			}

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

	static function convertFromPsych(song:String, oldName:String, dif:String):SwagSong
	{
		var oldPath = Paths.modsSongJson(oldName, '$oldName$dif');
		var newPath = Paths.modsSongJson(song, '$song$dif');

		var oldPathNewName = Paths.modsSongJson(oldName, '$song$dif');
		var newPathOldName = Paths.modsSongJson(song, '$oldName$dif');

		var rawJson:String = '';
		if (oldPath != null)
			rawJson = File.getContent(oldPath);

		if (newPath != null)
			rawJson = File.getContent(newPath);

		if (oldPathNewName != null)
			rawJson = File.getContent(oldPathNewName);

		if (newPathOldName != null)
			rawJson = File.getContent(newPathOldName);

		var parsedSong:OldSong = cast Json.parse(rawJson);

		var chart:Dynamic = cast parsedSong.song;

		var formattedSong:SwagSong = 
		{
			song: '',
			stage: '',

			metadata: null,

			sections: [],
			notes: [],

			events: [],

			bpm: 0,
			speed: 0,

			needsVoices: false,

			players: [],
			opponents: [],
			autoGF: '',

			countdownType: '',

			validScore: true
		}

		formattedSong.players.push(chart.player1);
		formattedSong.opponents.push(chart.player2);

		var chars:Array<String> = [chart.player1, chart.player2];

		formattedSong.song = chart.song;
		formattedSong.stage = chart.stage;

		var dummyMetadata:SongMetadata =
		{
			musicians: [],
			voiceActors: [],
			charters: [],
			programmers: [],
			additionalArtists: [],
			additionalAnimators: []
		}
		formattedSong.metadata = dummyMetadata;

		// - SECTIONS
		var formattedSections:Array<SongSection> = [];
		var parsedSections:Array<SwagSection> = chart.notes;
		for (sec in parsedSections)
		{
			var curSection:SongSection =
			{
				sectionBeats: sec.sectionBeats,

				bpm: sec.bpm,
				changeBPM: sec.changeBPM,

				charFocus: sec.mustHitSection ? 0 : 1
			}

			formattedSections.push(curSection);
		}

		formattedSong.sections = formattedSections;
		// - SECTIONS

		// - NOTES
		var formattedNotes:Map<String, Map<String, Array<NoteFile>>> = new Map();
		var diffs:Array<String> = ['easy', 'normal', 'hard'];
		for (daDif in diffs)
		{
			formattedNotes.set(daDif, []);
			for (char in chars)
				formattedNotes.get(daDif).set(char, []);
		}

		PlayState.difficulty = dif.replace('-', '');

		for (sec in parsedSections)
		{
			var parsedNotes:Array<Dynamic> = sec.sectionNotes;

			for (note in parsedNotes)
			{
				var char:String = sec.mustHitSection ? (note[1] >= 4 ? chars[1] : chars[0]) : (note[1] >= 4 ? chars[0] : chars[1]);

				var curNote:NoteFile =
				{
					d: Std.int(note[1] % 4),
					ms: Math.ceil(note[0]),
					l: note[2],
					t: note[3] != null ? note[3] : ''
				}

				formattedNotes.get(PlayState.difficulty).get(char).push(curNote);
			}
		}

		formattedSong.notes = formattedNotes;
		// - NOTES

		// - EVENTS
		var formattedEvents:Array<EventNote> = [];
		var parsedEvents:Array<Dynamic> = chart.events;
		if (chart.events.length == 0)
		{
			var eventsPath:String = Paths.modsSongJson(song, 'events');
			if (eventsPath != null)
			{
				var rawEvents = File.getContent(eventsPath);
				var dummy:{var events:Array<Dynamic>;} = cast Json.parse(rawEvents);
				parsedEvents = dummy.events;
			}
		}

		for (event in parsedEvents)
		{
			var subEvents:Array<Dynamic> = event[1];
			for (subEvent in subEvents)
			{
				var curEvent:EventNote =
				{
					strumTime: Math.ceil(event[0]),

					event: subEvent[0],

					value1: subEvent[1] != null ? subEvent[1] : '',
					value2: subEvent[2] != null ? subEvent[2] : '',
					value3: subEvent[3] != null ? subEvent[3] : ''
				}

				formattedEvents.push(curEvent);
			}
		}

		formattedSong.events = formattedEvents;
		// - EVENTS

		formattedSong.bpm = chart.bpm;
		formattedSong.speed = chart.speed;

		formattedSong.needsVoices = chart.needsVoices;

		formattedSong.autoGF = chart.gfVersion;

		formattedSong.countdownType = chart.countdownType;

		trace('Done!');

		return formattedSong;
	}

	public static function parseJSONshit(rawJson:String, songName:String):SwagSong
	{
		var parsedSong:SwagSong = cast Json.parse(rawJson);

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

			countdownType: '',

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

		var _countdownType:String = cast stupid.get('countdownType');
		formattedSong.countdownType = _countdownType;

		trace('returning song name "${formattedSong.song}"');

		return formattedSong;
	}
}
