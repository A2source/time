package a2.time.objects.util;

import a2.time.backend.managers.ChartEventManager;
import a2.time.objects.song.Conductor;
import a2.time.objects.song.Section.SongSection;
import a2.time.objects.song.Song;
import a2.time.objects.song.Song.SongCredit;
import a2.time.objects.song.Song.TimeSong;
import a2.time.objects.gameplay.notes.Note.NoteFile;
import a2.time.objects.gameplay.notes.Note.EventFile;

import haxe.Json;

using StringTools;

typedef Time100Song =
{
	var version:String;

	var song:String;
	var stage:String;

	var metadata:Time100SongMetadata;

	var sections:Array<SongSection>;
	var notes:Map<String, Map<String, Array<NoteFile>>>;

	var events:Array<Time100Event>;

	var bpm:Float;
	var speed:Float;

	var needsVoices:Bool;

	var players:Array<String>;
	var opponents:Array<String>;
	var autoGF:String;

	var validScore:Bool;
}

typedef Time100Event =
{
    var strumTime:Float;

	var event:String;

	var value1:String;
	var value2:String;
	var value3:String;
}

typedef Time100SongMetadata =
{
	var musicians:Array<String>;
	var voiceActors:Array<String>;
	var charters:Array<String>;
	var programmers:Array<String>;
	var additionalArtists:Array<String>;
	var additionalAnimators:Array<String>;
}

class ChartVersionUtil
{
    inline public static var CHART_EDITOR_VERSION:String = 'Created with TIME Chart Editor v2.0.0';
    
    public static function timeChart100To200(raw:String):TimeSong
    {
        var stuff:Time100Song = cast Json.parse(raw);

        var stupid:Map<String, Time100Song> = new Map();
        for (field in Reflect.fields(stuff)) stupid.set(field, Reflect.field(stuff, field));

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
				if (!chars.contains(char)) chars.push(char);
				if (tempNotes.get(char) == null) tempNotes.set(char, []);

				tempNotes.get(char).push(Reflect.field(notes, char));
			}

			var theseNotes:Map<String, Array<NoteFile>> = new Map();
			for (char in chars) theseNotes.set(char, tempNotes[char][i]);
			notesThing.set(difficulties[i], theseNotes);

			i++;
		}

		var formattedSong:Time100Song = 
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
		formattedSong.song = _song;

		var _stage:String = cast stupid.get('stage');
		formattedSong.stage = _stage;

		var _metadata:Time100SongMetadata = cast stupid.get('metadata');
		formattedSong.metadata = _metadata;

		var _sections:Array<SongSection> = cast stupid.get('sections');
		formattedSong.sections = _sections;

		var _events:Array<Time100Event> = cast stupid.get('events');
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

        // actually convert old format to new format
        var parsed:TimeSong =
        {
            version: ChartVersionUtil.CHART_EDITOR_VERSION,

            song: formattedSong.song,
            stage: formattedSong.stage,

            metadata: [],

            notes: formattedSong.notes,
            events: [],

            bpm: formattedSong.bpm,
            speed: formattedSong.speed,

            needsVoices: formattedSong.needsVoices,

            players: formattedSong.players,
            opponents: formattedSong.opponents
        }

		var convertMap:Map<String, String> = [
			'additionalAnimators' => 'Animator',
			'charters' => 'Charter',
			'additionalArtists' => 'Artist',
			'programmers' => 'Programmer',
			'musicians' => 'Musician',
			'voiceActors' => 'Voice Actor'
		];

		var credToCreds:Map<String, Array<String>> = new Map();

		for (field in Reflect.fields(formattedSong.metadata))
		{
			var cat:Array<String> = cast Reflect.getProperty(formattedSong.metadata, field);
			for (cred in cat)
			{
				if (cred == '') continue;

				if (credToCreds.get(cred) == null) credToCreds.set(cred, [convertMap.get(field)]);
				else credToCreds.get(cred).push(convertMap.get(field));
			}	
		}

		for (cred in credToCreds.keys())
		{
			var roles = credToCreds.get(cred);
			parsed.metadata.push({
				name: cred,
				roles: roles
			});
		}

		var charArray:Array<String> = [];
		for (char in parsed.players) charArray.push(char);
		for (char in parsed.opponents) charArray.push(char);

		var newEvents:Map<String, Array<EventFile>> = new Map();
        for (event in _events)
        {
            var thisEvent:EventFile =
            {
                t: event.event,
                e: []
            }

            thisEvent.e.push({n: 'Value 1', v: event.value1, t: 'STRING'});
            thisEvent.e.push({n: 'Value 2', v: event.value2, t: 'STRING'});
            thisEvent.e.push({n: 'Value 3', v: event.value3, t: 'STRING'});

			var string:String = '${event.strumTime}';
			if (newEvents.get(string) == null) newEvents.set(string, []);

            newEvents.get(string).push(thisEvent);
        }

		var curFocus:Int = _sections[0].charFocus;
		var curCrochet:Float = Conductor.calculateCrochet(_bpm);
		var curMS:Float = 0;
		for (section in _sections)
		{
			var string:String = '$curMS';

			if (section.charFocus != curFocus)
			{
				if (newEvents.get(string) == null) newEvents.set(string, []);

				newEvents.get(string).push({t: ChartEventManager.CHAR_FOCUS_EVENT_NAME, e: [{n: 'Focus', v: charArray[section.charFocus], t: 'STRING'}]});
				curFocus = section.charFocus;
			}

			if (section.changeBPM)
			{
				if (newEvents.get(string) == null) newEvents.set(string, []);

				newEvents.get(string).push({t: ChartEventManager.BPM_CHANGE_EVENT_NAME, e: [{n: 'BPM', v: section.bpm, t: 'FLOAT'}]});
				curCrochet = Conductor.calculateCrochet(section.bpm);

				trace(newEvents.get(string)[newEvents.get(string).length - 1]);
			}

			curMS += curCrochet * section.sectionBeats;
		}

        parsed.events = newEvents;
		
        return parsed;
    }
}