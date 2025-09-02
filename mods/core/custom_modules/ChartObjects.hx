import a2.time.objects.gameplay.Note.NoteFile;

import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;

class ChartLane
{
	// associated character
	var c:String;

	// id on screen
	var i:Int;

	// grid sprite backdrop
	var grid:FlxBackdrop = null;

	// beats & sections display
	var sections:FlxBackdrop = null;
	var beats:FlxBackdrop = null;

	// strum sprites
	var strums:Array<FlxSprite> = [];

	// current note we're looking at hitting next (per strum)
	var currentFocus:Array<Dynamic> = [0, 0, 0, 0];

	// note sprites & data
	// for note lanes this contains {sprite, sus, note}
	// for event lane this contains {sprite, text, events}
	var laneNotes:Array<Array<Dynamic>> = [[], [], [], []];

	// character display info
	var icon:FlxSprite = null;
	var text:FlxText = null;

	function new(_c:String, _i:String)
	{
		c = _c;
		i = _i;
	}

	function getNoteFromData(data:Dynamic) { for (note in getAllNotes()) if (note.note.ms == data.ms && note.note.d == data.d) return note; }
	function getGroupingFromMS(ms:Float) { for (grouping in getAllNotes()) if (grouping.ms == ms) return grouping; }
	
	function removeNoteWithData(data:Dynamic) 
	{ 
		var remove = null;
		for (note in laneNotes[data.d])
		{
			if (note.note.ms != data.ms) continue;
			remove = note;
		}

		if (remove == null)
		{
			alert('Note could not be deleted!', ALERT_TITLE);
			trace(data);
			
			return;
		}
			
		laneNotes[data.d].remove(remove);

		remove.sprite.destroy();
		if (remove.sus != null) remove.sus.destroy();
	}

	function getAllNotes() 
	{
		var all = [];
		for (notes in laneNotes) for (note in notes) all.push(note);
		return all;
	}
}