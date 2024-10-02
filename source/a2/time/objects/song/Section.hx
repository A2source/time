package a2.time.objects.song;

// goodbye SwagSection... sad
typedef SongSection =
{
	var sectionBeats:Float;

	var bpm:Float;
	var changeBPM:Bool;
	
	var charFocus:Int;
}

// just kidding! it stays for conversion reasons
typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
	var crossfadeBf:Bool;
	var crossfadeDad:Bool;
}

class Section
{
	public var sectionNotes:Array<Dynamic> = [];

	public var sectionBeats:Float = 4;

	/**
	 *	Copies the first section into the second section!
	 */
	public static var COPYCAT:Int = 0;

	public function new(sectionBeats:Float = 4)
	{
		this.sectionBeats = sectionBeats;
		trace('test created section: ' + sectionBeats);
	}
}
