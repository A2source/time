package a2.time.backend.managers;

import a2.time.backend.Paths;
import a2.time.objects.gameplay.notes.Note.EventEntry;
import a2.time.objects.gameplay.notes.Note.EventFile;
import a2.time.objects.song.Song.TimeSong;

import haxe.Json;
import haxe.ui.core.Component;

import sys.FileSystem;
import sys.io.File;

typedef EventGrouping =
{
    ms:Float,
    events:Array<EventFile>
}

typedef EventStructure =
{
	// event type
	t:String,

	// entry structure
	e:Array<EventEntryStructure>
}

typedef EventEntryStructure =
{
	// entry name
	n:String,

	// entry type (for chart editor ui)
	t:String,

    // default value of this entry
    d:Dynamic
}

class ChartEventManager
{
    // important event names
    public static inline var BPM_CHANGE_EVENT_NAME:String = 'Change BPM';
    public static inline var CHAR_FOCUS_EVENT_NAME:String = 'Set Character Focus';

    public static inline function generateEventStructureJSON(e:EventStructure, ?space:String = '\t'):String return Json.stringify(e, space);

    public static inline function createNewEvent(type:String, e:EventStructure, dir:String = Main.MOD_NAME, ?space:String = '\t'):Void
    {
        var content:String = generateEventStructureJSON(e, space);

        var path:String = Paths.mods.event.folder(type, dir);
        if (path != null)
        {
            openfl.Lib.application.window.alert('Event of type "$type" already exists.\n$path', Main.ALERT_TITLE);
            return;
        }
            
        FileSystem.createDirectory('mods/$dir/custom_events/$type');
        path = Paths.mods.event.folder(type, dir);

        File.saveContent('$path/$type.json', content);

        openfl.Lib.application.window.alert('Created new event "$type"!\n$path', Main.ALERT_TITLE);
    }

    private static var editorStructureMap:Map<String, EventStructure> = new Map();
    public static inline function registerEventStructure(e:EventStructure):Void editorStructureMap.set(e.t, e);
    public static inline function getEventStructure(t:String):EventStructure return editorStructureMap.get(t);
    public static inline function getRegisteredStructures():Array<String> return Lambda.array({iterator: editorStructureMap.keys});

    public static inline function forEachEventGrouping(song:TimeSong, callback:Float->Array<EventFile>->Void):Void 
        for (key in song.events.keys()) callback(Std.parseFloat(key), song.events.get(key));

    public static inline function forEachEvent(song:TimeSong, callback:Float->EventFile->Void):Void
        for (key in song.events.keys()) for (event in song.events.get(key)) callback(Std.parseFloat(key), event);

    public static function getGroupingFromMS(song:TimeSong, ms:Float):Array<EventFile>
    {
        var string:String = '$ms';

        for (key in song.events.keys()) if (string == key) return song.events.get(key);
        return null;
    }

    public static function getEvent(song:TimeSong, ms:Float, eventID:Int):EventFile
    {
        var grouping:Array<EventFile> = getGroupingFromMS(song, ms);

        if (grouping == null) return null;
        return grouping[eventID];
    }

    public static function getEventEntry(song:TimeSong, ms:Float, eventID:Int, entryID:Int):EventEntry
    {
        var event:EventFile = getEvent(song, ms, eventID);

        if (event == null) return null;
        return event.e[entryID];
    }

    // map of chart editor functions
    // the function returns the component to be added to the edit window by this entry type
    // for example, "STRING" returns a text field to edit the value.
    private static var editorEntryMap:Map<String, TimeSong->EventGrouping->EventFile->EventEntry->Component> = new Map();
    public static inline function registerEntryBehaviour(id:String, callback:TimeSong->EventGrouping->EventFile->EventEntry->Component):Void editorEntryMap.set(id, callback);

    public static inline function getEntryBehaviour(id:String, song:TimeSong, ms:Float, eventID:Int, entryID:Int):Component 
    { 
        if (editorEntryMap.get(id) == null)
        {
            openfl.Lib.application.window.alert('No behaviour found for entry type "$id".\nPlease set it using "ChartEventManager.registerEntryBehaviour"', Main.ALERT_TITLE);
            return null;
        }

        var curGrouping:Array<EventFile> = getGroupingFromMS(song, ms);
        return editorEntryMap.get(id)(song, {ms: ms, events: curGrouping}, curGrouping[eventID], curGrouping[eventID].e[entryID]);
    }
}