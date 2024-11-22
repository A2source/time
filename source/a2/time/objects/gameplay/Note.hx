package a2.time.objects.gameplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import a2.time.states.PlayState;
import a2.time.states.editors.ChartingState;
import a2.time.objects.song.Conductor;
import a2.time.objects.gameplay.StrumNote;
import a2.time.util.ClientPrefs;
import a2.time.Paths;

import sys.io.File;

using StringTools;

typedef NoteFile =
{
	// note data (left, down, up, right)
	var d:Int;

	// note time in milliseconds
	var ms:Float;

	// note sustain length
	var l:Float;

	// custom notetype
	var t:String;
}

typedef CustomNoteFile =
{
	var name:String;
	var desc:String;

	var texture:String;
	@:optional var anims:CustomNoteAnims;
}

typedef CustomNoteAnims = 
{
	var solid:StrumNote.SolidNoteAnimationNames;
	var sus:StrumNote.SustainNoteAnimationNames;
}

typedef EventNote = 
{
	var strumTime:Float;

	var event:String;

	var value1:String;
	var value2:String;
	var value3:String;
}

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;

	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;

	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var isEventNote:Bool = false;
	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventData:Array<EventNote> = [];
	public var eventVal1:String = '';
	public var eventVal2:String = '';
	public var eventVal3:String = '';

	public var inEditor:Bool = false;

	public var earlyHitMult:Float = 0.5;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var swagWidth:Float = 160 * 0.7;
	
	private var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	// Lua shit
	public var noteSplashDisabled:Bool = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;

	public var func = null;
	public var activated:Bool = false;
	public var funcThreshold:Float = 0;

	public var attachedChar:String;

	public var ignoreNote:Bool = false;

	public var parentStrumNote:StrumNote;
	private var solidStrumSkinName:String;
	private var susStrumSkinData:StrumNote.SustainNotePieceAnimationNames;

	public var isHoldEnd:Bool = false;

	private function set_multSpeed(value:Float):Float 
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;

		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(!isSustainNote || animation.curAnim.name.endsWith('end'))
			return;

		scale.y *= ratio;
		updateHitbox();
	}

	private function set_texture(value:String):String 
	{
		if(texture != value)
			reloadNoteTexture(value);

		texture = value;
		return value;
	}

	private function set_noteType(value:String):String 
	{
		loadCustomNote(value);

		noteType = value;

		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, mustHit:Bool = false)
	{
		super();

		mustPress = mustHit;
		isEventNote = noteData == -1;

		if (!inEditor)
		{
			var game:PlayState = PlayState.instance;
			parentStrumNote = mustPress ? game.playerStrums.members[noteData % 4] : game.opponentStrums.members[noteData % 4];
			parentStrumNote.associatedNotes.push(this);
		}
		else
		{
			if (!isEventNote)
			{
				@:privateAccess parentStrumNote = ChartingState.instance.strumLineNotes.members[noteData % 4];
				parentStrumNote.associatedNotes.push(this);
			}
		}

		if (!isEventNote)
		{
			var noteSkinData:StrumSkinNoteAnimationNames = cast parentStrumNote.skinData.notes;

			switch(noteData % 4)
			{
				case 0: 
					solidStrumSkinName = cast noteSkinData.solid.l;
					susStrumSkinData = cast noteSkinData.sus.l;

				case 1: 
					solidStrumSkinName = cast noteSkinData.solid.d;
					susStrumSkinData = cast noteSkinData.sus.d;

				case 2: 
					solidStrumSkinName = cast noteSkinData.solid.u;
					susStrumSkinData = cast noteSkinData.sus.u;

				case 3: 
					solidStrumSkinName = cast noteSkinData.solid.r;
					susStrumSkinData = cast noteSkinData.sus.r;
			}
		}

		this.func = null;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if(noteData > -1) 
		{
			texture = '';

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData > -1 && noteData < 4) 
			{
				var animToPlay:String = '';
				animToPlay = colArray[noteData % 4];
				animation.play(animToPlay + 'Scroll');
			}
		}

		if(prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			flipY = ClientPrefs.data.downScroll;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % 4] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % 4] + 'hold');
				isHoldEnd = true;

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(PlayState.instance != null)
					prevNote.scale.y *= PlayState.instance.songSpeed;

				prevNote.updateHitbox();
			}
		} 
		else if(!isSustainNote) 
			earlyHitMult = 1;
		
		x += offsetX;
	}

	public function loadCustomNote(name:String):Note
	{
		if (ChartingState.HARDCODED_NOTES.contains(name))
			return this;

		for (mod in Paths.getModDirectories())
		{
			Paths.VERBOSE = false;

			var path = Paths.noteJson(name, mod);
			if (path == null)
				continue;

			var data:CustomNoteFile = haxe.Json.parse(File.getContent(path));

			switch(noteData % 4)
			{
				case 0:
					solidStrumSkinName = data.anims.solid.l;
					susStrumSkinData = cast data.anims.sus.l;

				case 1:
					solidStrumSkinName = data.anims.solid.d;
					susStrumSkinData = cast data.anims.sus.d;

				case 2:
					solidStrumSkinName = data.anims.solid.u;
					susStrumSkinData = cast data.anims.sus.u;

				case 3:
					solidStrumSkinName = data.anims.solid.r;
					susStrumSkinData = cast data.anims.sus.r;
			}

			reloadNoteTexture(data.texture);
		}

		return this;
	}

	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var lastNoteScaleToo:Float = 1;
	public var originalHeightForCalcs:Float = 6;
	public function reloadNoteTexture(?texture:String = '') 
	{
		if(texture == null) texture = '';

		var animName:String = null;
		if(animation.curAnim != null)
			animName = animation.curAnim.name;

		var lastScaleY:Float = scale.y;

		loadNoteFrames(texture);

		loadNoteAnims();
		antialiasing = ClientPrefs.data.antialiasing;

		Paths.VERBOSE = true;
		
		if(isSustainNote)
			scale.y = lastScaleY;

		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(!inEditor)
			return;

		setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
		updateHitbox();
	}

	private function loadNoteFrames(skin:String = '')
	{
		Paths.VERBOSE = false;

		if (skin == '')
		{
			frames = parentStrumNote.frames;
			return;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length - 1] = arraySkin[arraySkin.length - 1];

		var blahblah:String = arraySkin.join('/');

		var anyMods:Bool = false;
		for (mod in Paths.getModDirectories())
		{
			var mods = Paths.modsSparrow('custom_strumskins/$blahblah', blahblah, mod);

			if (mods == null)
				continue;
			
			frames = mods;
			anyMods = true;
		}
	}

	function loadNoteAnims() 
	{
		animation.addByPrefix(colArray[noteData] + 'Scroll', solidStrumSkinName);

		if (isSustainNote)
		{
			animation.addByPrefix(colArray[noteData] + 'holdend', susStrumSkinData.e);
			animation.addByPrefix(colArray[noteData] + 'hold', susStrumSkinData.p);
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// fun stuff
		if (this.func != null)
		{
			if (Conductor.songPosition + this.funcThreshold > strumTime && !activated)
			{
				activated = true;

				trace('activate!');
				this.func();
			}
		}

		if (!inEditor)
			updateNoteStates();
	}

	private function updateNoteStates()
	{
		if (mustPress)
		{
			// ok river
			if (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult)
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (Conductor.songPosition + funcThreshold > strumTime && !activated)
		{
			if (func != null)
				func();

			activated = true;
		}

		if (tooLate && alpha > 0.3)
			alpha = 0.3;
	}

	public override function toString():String return '(Strum Time: $strumTime | Data: $noteData | Type: $noteType ${eventData.length > 0 ? '| Event Data: $eventData' : ''})';
}
