package a2.time.objects.gameplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

import a2.time.states.PlayState;
import a2.time.objects.gameplay.Note;
import a2.time.util.ClientPrefs;
import a2.time.Paths;

import sys.io.File;

using StringTools;

class StrumNote extends FlxSprite
{
	public static inline var DEFAULT_STRUM_SKIN_NAME:String = 'NOTE_assets';

	public var resetAnim:Float = 0;
	private var noteData:Int = 0;

	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb

	public var sustainReduce:Bool = true;
	
	private var player:Int;

	public var curSkin:String = '';
	public var curSkinDir:String = '';

	public var skinData:StrumNoteSkinFile;
	private var curOffsetData:StrumDirectionOffsets;

	public var associatedNotes:Array<Note> = [];

	public function new(x:Float, y:Float, leData:Int, player:Int, skin:String = DEFAULT_STRUM_SKIN_NAME, skinModDirectory:String = Main.MOD_NAME)
	{
		noteData = leData;

		this.player = player;
		this.noteData = leData;
		super(x, y);

		reloadStrumSkin(skin, skinModDirectory);

		scrollFactor.set();
	}

	public function reloadStrumSkin(skin:String = DEFAULT_STRUM_SKIN_NAME, skinModDirectory:String = Main.MOD_NAME)
	{
		// if skin is exactly the same, return
		if (skin == curSkin && skinModDirectory == curSkinDir)
			return;

		curSkin = skin;
		curSkinDir = skinModDirectory;

		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		skinData = cast haxe.Json.parse(File.getContent(Paths.customStrumSkinJson(skin, skinModDirectory)));
		frames = Paths.modsSparrow('custom_strumskins/$skin', skin, skinModDirectory);

		var curData:StrumDirectionAnimations = {i: '', p: '', h: ''};
		switch(noteData % 4)
		{
			case 0: 
				curData = cast skinData.anims.l;
				curOffsetData = cast skinData.offsets.l;

			case 1: 
				curData = cast skinData.anims.d;
				curOffsetData = cast skinData.offsets.d;

			case 2: 
				curData = cast skinData.anims.u;
				curOffsetData = cast skinData.offsets.u;

			case 3: 
				curData = cast skinData.anims.r;
				curOffsetData = cast skinData.offsets.r;
		}

		animation.addByPrefix('static', curData.i, 24, true);
		animation.addByPrefix('pressed', curData.p, 24, false);
		animation.addByPrefix('confirm', curData.h, 24, false);

		setGraphicSize(Std.int(width * 0.7));

		updateHitbox();

		if(lastAnim != null)
			playAnim(lastAnim, true);

		antialiasing = ClientPrefs.data.antialiasing;

		for (note in associatedNotes)
		{
			if (!note.alive || note.texture != '')
				continue;

			note.reloadNoteTexture();
		}
	}

	public function postAddedToGroup() 
	{
		playAnim('static');

		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
	}

	override function update(dt:Float) 
	{
		if(resetAnim > 0) 
		{
			resetAnim -= dt;
			if (resetAnim <= 0) 
			{
				playAnim('static');
				resetAnim = 0;
			}
		}

		super.update(dt);
	}

	public function playAnim(anim:String, ?force:Bool = false) 
	{
		animation.play(anim, force);

		centerOffsets();
		centerOrigin();

		switch(anim)
		{
			case 'static':
				offset.x += curOffsetData.i.x;
				offset.y += curOffsetData.i.y;

			case 'pressed':
				offset.x += curOffsetData.p.x;
				offset.y += curOffsetData.p.y;

			case 'confirm':
				offset.x += curOffsetData.h.x;
				offset.y += curOffsetData.h.y;
		}

		offset.x += curOffsetData.g.x;
		offset.y += curOffsetData.g.y;
	}
}

typedef StrumNoteSkinFile =
{
	var notes:StrumSkinNoteAnimationNames;
	var anims:StrumSkinAnimationNames;
	var offsets:StrumSkinAnimationOffsets;
}

typedef StrumSkinNoteAnimationNames =
{
	var solid:SolidNoteAnimationNames;
	var sus:SustainNoteAnimationNames;
}

typedef SolidNoteAnimationNames =
{
	var l:String;
	var d:String;
	var u:String;
	var r:String;
}

typedef SustainNoteAnimationNames =
{
	var l:SustainNotePieceAnimationNames;
	var d:SustainNotePieceAnimationNames;
	var u:SustainNotePieceAnimationNames;
	var r:SustainNotePieceAnimationNames;
}

typedef SustainNotePieceAnimationNames =
{
	// hold piece
	var p:String;
	// hold end
	var e:String;
}

typedef StrumSkinAnimationNames =
{
	// left
	var l:StrumDirectionAnimations;
	// down
	var d:StrumDirectionAnimations;
	// up
	var u:StrumDirectionAnimations;
	// right
	var r:StrumDirectionAnimations;
}

typedef StrumSkinAnimationOffsets =
{
	var l:StrumDirectionOffsets;
	var d:StrumDirectionOffsets;
	var u:StrumDirectionOffsets;
	var r:StrumDirectionOffsets;
}

typedef StrumDirectionAnimations =
{
	// idle
	var i:String;
	// pressed
	var p:String;
	// hit
	var h:String;
}

typedef StrumDirectionOffsets =
{
	// general offset (always applied regardless of anim)
	var g:Offset;

	var i:Offset;
	var p:Offset;
	var h:Offset;
}

typedef Offset =
{
	var x:Float;
	var y:Float;
}