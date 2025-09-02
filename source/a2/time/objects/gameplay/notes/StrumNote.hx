package a2.time.objects.gameplay.notes;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup.FlxTypedGroup;

import a2.time.backend.Paths;
import a2.time.backend.Paths.FileReturnPayload;
import a2.time.states.PlayState;
import a2.time.objects.gameplay.notes.Note;
import a2.time.objects.song.Conductor;
import a2.time.backend.ClientPrefs;
import a2.time.util.Offset;

import haxe.crypto.Base64;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;

import sys.io.File;

using StringTools;
using haxe.EnumTools;

enum ScrollDirection
{
	UP;
	DOWN;
}

enum LaneAngleFollowType
{
	INHERIT; 
	CONSTANT;
}

typedef StrumSkinData =
{
	skin:String,
	mod:String
}

class StrumNote extends FlxSprite
{
	public static inline var DEFAULT_STRUM_SKIN_NAME:String = 'NOTE_assets';

	public static inline var STRUM_IDLE:String = 'idle';
	public static inline var STRUM_CONFIRM:String = 'confirm';
	public static inline var STRUM_PRESS:String = 'press';

	public static inline var NOTE_TAIL_BODY:String = 'body';
	public static inline var NOTE_TAIL_CAP:String = 'cap';

	public var d:Int = 0;

	public var direction:ScrollDirection = ClientPrefs.get('downscroll') ? DOWN : UP;

	// lane angle change sets sprite angle
	public var copyLaneAngle:Bool = false;
	public var laneAngle:Float = 90;
	public var laneAngleFollowType:LaneAngleFollowType = CONSTANT;

	public var noteTails:FlxTypedGroup<NoteTail> = new FlxTypedGroup<NoteTail>();
	public var notes:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	
	public var associatedNotes:Array<Note> = [];

	public var skinData:StrumNoteSkinFile;

	public var speed:Float = 1;

	public var player:Bool = false;

	public var noteOffset:Offset = {x: 0, y: 0}

	private static var DEFAULT_SCALE:Float = 0.65;
	public function new(_d:Int, ?_skinData:StrumSkinData)
	{
		super();

		d = _d;

		scale.set(DEFAULT_SCALE, DEFAULT_SCALE);
		updateHitbox();

		antialiasing = ClientPrefs.get('antialiasing');

		loadSkin(_skinData == null ? {skin: DEFAULT_STRUM_SKIN_NAME, mod: Main.MOD_NAME} : _skinData);
	}

	override function update(dt:Float):Void
	{
		super.update(dt);

		if (copyLaneAngle) angle = laneAngle - 90;
		updateNotes(dt);
	}

	private function updateNotes(dt:Float):Void
	{
		if (associatedNotes.length <= 0) return;

		var note:Note = cast associatedNotes[0];
		if (note == null) return;
		
		var time:Float = PlayState.NOTE_SPAWN_TIME;
		if (speed < 1) time /= speed;
		if (note.speed < 1) time /= note.speed;

		if (note.ms - Conductor.songPosition > time) return;

		note.inheritLaneAngle = laneAngle;

		if (note.hasTail) noteTails.insert(0, note.tail);
		notes.insert(0, note);

		associatedNotes.splice(associatedNotes.indexOf(note), 1);
	}

	public function sortNotes():Void
	{
		associatedNotes.sort((a, b) -> { return a.ms < b.ms ? -1 : a.ms == b.ms ? 0 : 1; });
	}

	public var curSkinMetaData:StrumSkinData;

	public var skinPixels:BitmapData;
	public function loadSkin(data:StrumSkinData, ?forceData:StrumNoteSkinFile):Void
	{
		curSkinMetaData = data;

		if (forceData != null) skinData = forceData;
		else skinData = cast haxe.Json.parse(Paths.mods.strumskin.json([data.skin], data.mod).content);

		if (Reflect.hasField(skinData, 'scale'))
		{
			scale.set(skinData.scale, skinData.scale);
			updateHitbox();
		}

		// notes should only be positioned based on the offset of the idle not the other anims
		var curOffset:StrumOffset = getStrumOffsets();
		noteOffset.x = skinData.offsets.strums.g.x + curOffset.i.x + curOffset.g.x;
		noteOffset.y = skinData.offsets.strums.g.y + curOffset.i.y + curOffset.g.y;

		var img:FileReturnPayload = Paths.mods.strumskin.image([data.skin], data.mod);

		loadGraphic(cast img.content);
		frames = Paths.mods.strumskin.atlas([data.skin], data.mod).content;

		skinPixels = BitmapData.fromBase64(Base64.encode(File.getBytes(img.path)), '');

		loadAnimations();
		updateNoteSkins();

		PlayState.callAllScripts('onStrumLoadSkin', [this, associatedNotes, skinData]);
	}

	public function updateNoteSkins():Void
	{
		for (arr in [associatedNotes, notes.members])
			for (note in arr) note.updateSkin();
	}

	public var tailBodyFrame:FlxFrame;
	public var tailCapFrame:FlxFrame;

	public var tailBodyRect:Rectangle;
	public var tailCapRect:Rectangle;

	public var tailBodyWidth:Int;
	public var tailBodyHeight:Int;

	public var tailCapWidth:Int;
	public var tailCapHeight:Int;

	public var tailBodyPixels:ByteArray;
	public var tailCapPixels:ByteArray;

	private function loadAnimations():Void
	{
		for (name in animation.getNameList()) animation.remove(name);
		
		var anims:StrumDirectionAnimations = getSkinAnimations();
		animation.addByPrefix(STRUM_IDLE, anims.i.tag, anims.i.fps, false);
		animation.addByPrefix(STRUM_PRESS, anims.p.tag, anims.p.fps, false);
		animation.addByPrefix(STRUM_CONFIRM, anims.c.tag, anims.c.fps, false);

		var tailAnims:NoteTailSegmentAnimationNames = getNoteTailAnimations();
		animation.addByPrefix(NOTE_TAIL_BODY, tailAnims.b.tag, tailAnims.b.fps, false);
		animation.addByPrefix(NOTE_TAIL_CAP, tailAnims.c.tag, tailAnims.c.fps, false);

		animation.play(NOTE_TAIL_BODY, true);
		tailBodyFrame = frame;

		animation.play(NOTE_TAIL_CAP, true);
		tailCapFrame = frame;

		tailBodyRect = new Rectangle(tailBodyFrame.frame.x, tailBodyFrame.frame.y + tailRenderer.start, tailBodyFrame.frame.width, tailBodyFrame.frame.height);
		tailCapRect = new Rectangle(tailCapFrame.frame.x, tailCapFrame.frame.y, tailCapFrame.frame.width, tailCapFrame.frame.height);

		tailBodyWidth = cast tailBodyRect.width;
		tailBodyHeight = cast tailBodyRect.height;

		tailCapWidth = cast tailCapRect.width;
		tailCapHeight = cast tailCapRect.height;

		tailBodyPixels = skinPixels.getPixels(tailBodyRect);
		tailCapPixels = skinPixels.getPixels(tailCapRect);

		playAnimation(STRUM_IDLE);
		animation.onFinish.add((name) -> { playAnimation(STRUM_IDLE); });
	}

	private final DIRS:Array<String> = ['l', 'd', 'u', 'r'];

	private var cachedSkinAnimations:Dynamic = {
		skin: '',
		data: {}
	}
	private function getSkinAnimations():StrumDirectionAnimations 
	{
		if (cachedSkinAnimations.skin != curSkinMetaData.skin)
		{
			cachedSkinAnimations.skin = curSkinMetaData.skin;
			cachedSkinAnimations.data = Reflect.getProperty(skinData.anims.strums, DIRS[d]);
		}
		
		return cachedSkinAnimations.data;
	}

	private var cachedStrumOffsets:Dynamic = {
		skin: '',
		data: {}
	}
	private function getStrumOffsets():StrumOffset 
	{
		if (cachedStrumOffsets.skin != curSkinMetaData.skin)
		{
			cachedStrumOffsets.skin = curSkinMetaData.skin;
			cachedStrumOffsets.data = Reflect.getProperty(skinData.offsets.strums, DIRS[d]);
		}

		return cachedStrumOffsets.data;
	}

	private var cachedSolidNoteAnimations:Dynamic = {
		skin: '',
		data: {}
	}
	public function getSolidNoteAnimations():SkinAnimation 
	{
		if (cachedSolidNoteAnimations.skin != curSkinMetaData.skin)
		{
			cachedSolidNoteAnimations.skin = curSkinMetaData.skin;
			cachedSolidNoteAnimations.data = Reflect.getProperty(skinData.anims.notes.solid, DIRS[d]);
		}

		return cachedSolidNoteAnimations.data;
	}

	private var cachedNoteTailAnimations:Dynamic = {
		skin: '',
		data: {}
	}
	public function getNoteTailAnimations():NoteTailSegmentAnimationNames 
	{
		if (cachedNoteTailAnimations.skin != curSkinMetaData.skin)
		{
			cachedNoteTailAnimations.skin = curSkinMetaData.skin;
			cachedNoteTailAnimations.data = Reflect.getProperty(skinData.anims.notes.tail, DIRS[d]);
		}

		return cachedNoteTailAnimations.data;
	}

	private var cachedNoteOffsets:Dynamic = {
		skin: '',
		data: {}
	}
	public function getNoteOffsets():Offset 
	{
		if (cachedNoteOffsets.skin != curSkinMetaData.skin)
		{
			cachedNoteOffsets.skin = curSkinMetaData.skin;
			cachedNoteOffsets.data = Reflect.getProperty(skinData.offsets.notes, DIRS[d]);
		}

		return cachedNoteOffsets.data;
	}

	private var cachedNoteTailOffsets:Dynamic = {
		skin: '',
		data: {}
	}
	public function getNoteTailOffsets():Offset 
	{
		if (cachedNoteTailOffsets.skin != curSkinMetaData.skin)
		{
			cachedNoteTailOffsets.skin = curSkinMetaData.skin;
			cachedNoteTailOffsets.data = Reflect.getProperty(skinData.offsets.tails, DIRS[d]);
		}

		return cachedNoteTailOffsets.data;
	}

	public var tailRenderer(get, never):NoteTailRenderer;
	public function get_tailRenderer():NoteTailRenderer
	{
		if (!Reflect.hasField(skinData, 'tailRenderer')) 
			return {start: Note.TAIL_SAMPLE_START, cutoff: Note.TAIL_SAMPLE_CUTOFF}

		return skinData.tailRenderer;
	}

	public var flipTail(get, never):Bool;
	public function get_flipTail():Bool 
	{
		if (!Reflect.hasField(skinData, 'flipTail')) return direction == DOWN;

		var isUp:Bool = skinData.flipTail == UP;
		var isDown:Bool = skinData.flipTail == DOWN;

		if (Type.typeof(skinData.flipTail) == TInt) 
		{
			var int:Int = cast skinData.flipTail;
			var parsedDirection:ScrollDirection = ScrollDirection.createByIndex(int);

			isUp = parsedDirection == UP;
			isDown = parsedDirection == DOWN;
		}
		
		if (direction == UP && isUp) return true;
		if (direction == DOWN && isDown) return true;

		return false;
	}
	
	public function playAnimation(anim:String, ?force:Bool = true):Void 
	{
		animation.play(anim, force);

		var offsets:StrumOffset = getStrumOffsets();
		switch(anim)
		{
			case STRUM_IDLE: offset.set(offsets.i.x, offsets.i.y);
			case STRUM_PRESS: offset.set(offsets.p.x, offsets.p.y);
			case STRUM_CONFIRM: offset.set(offsets.c.x, offsets.c.y);
		}

		// global offsets
		offset.x += skinData.offsets.strums.g.x;
		offset.y += skinData.offsets.strums.g.y;

		// strum "general" offset
		offset.x += offsets.g.x;
		offset.y += offsets.g.y;
	}

	public override function toString():String return '(Data: $d | Direction: $direction | Lane Angle: $laneAngle | Player: $player)';
}

typedef StrumNoteSkinFile =
{
	var anims:StrumSkinAnimationData;
	var offsets:StrumSkinAnimationOffsets;

	// gap between opp and player strums in playstate
	@:optional var strumGap:Float;

	@:optional var scale:Float;

	// controls which direction flips the trail sprite frames
	// downscroll is assumed by default
	@:optional var flipTail:ScrollDirection;

	@:optional var tailRenderer:NoteTailRenderer;
}

typedef NoteTailRenderer =
{
	// 9
	var start:Int;
	// 16
	var cutoff:Int;
}

typedef StrumSkinAnimationData =
{
	var notes:StrumSkinNoteAnimationNames;
	var strums:StrumSkinAnimationNames;
}

typedef StrumSkinNoteAnimationNames =
{
	var solid:SolidNoteAnimationNames;
	var tail:NoteTailAnimationNames;
}

typedef SolidNoteAnimationNames =
{
	var l:SkinAnimation;
	var d:SkinAnimation;
	var u:SkinAnimation;
	var r:SkinAnimation;
}

typedef NoteTailAnimationNames =
{
	var l:NoteTailSegmentAnimationNames;
	var d:NoteTailSegmentAnimationNames;
	var u:NoteTailSegmentAnimationNames;
	var r:NoteTailSegmentAnimationNames;
}

typedef NoteTailSegmentAnimationNames =
{
	// tail body
	var b:SkinAnimation;
	// tail cap
	var c:SkinAnimation;
}

typedef StrumSkinAnimationNames =
{
	var l:StrumDirectionAnimations;
	var d:StrumDirectionAnimations;
	var u:StrumDirectionAnimations;
	var r:StrumDirectionAnimations;
}

typedef StrumDirectionAnimations =
{
	// idle
	var i:SkinAnimation;
	// press
	var p:SkinAnimation;
	// confirm
	var c:SkinAnimation;
}

typedef StrumSkinAnimationOffsets =
{
	var notes:StrumSkinNoteOffsets;
	var tails:StrumSkinNoteOffsets;
	var strums:StrumSkinOffsets;
}

typedef StrumSkinNoteOffsets =
{
	// global offset (always applied regardless of anim)
	var g:Offset;

	var l:Offset;
	var d:Offset;
	var u:Offset;
	var r:Offset;
}

typedef StrumSkinOffsets =
{
	var g:Offset;

	var l:StrumOffset;
	var d:StrumOffset;
	var u:StrumOffset;
	var r:StrumOffset;
}

typedef StrumOffset =
{
	// general strum offset (applied regardless of anim)
	// different from global offset, only applies to THIS recep
	var g:Offset;

	var i:Offset;
	var p:Offset;
	var c:Offset;
}

typedef SkinAnimation =
{
	var tag:String;
	var fps:Float;
}