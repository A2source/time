package a2.time.objects.gameplay.notes;

import a2.time.backend.ClientPrefs;
import a2.time.states.PlayState;
import a2.time.objects.song.Conductor;
import a2.time.util.Offset;

import flixel.FlxG;
import flixel.FlxSprite;

import flixel.math.FlxRect;

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
	@:optional var t:String;
}

typedef CustomNoteFile =
{
	var name:String;
	var desc:String;

	var texture:String;
	@:optional var anims:CustomNoteAnims;
}

typedef EventEntry = 
{
	n:String,
	v:Dynamic,
	t:String
}

typedef EventFile =
{
	// event type
	var t:String;

	// entries
	var e:Array<EventEntry>;
}

typedef CustomNoteAnims = 
{
	var solid:StrumNote.SolidNoteAnimationNames;
	var sus:StrumNote.NoteTailAnimationNames;
}

class Note extends FlxSprite
{
	public static final TAIL_SAMPLE_START:Int = 9;
	public static final TAIL_SAMPLE_CUTOFF:Int = 16;

	public var ms:Float = 0;
	public var d:Int = 0;

	// notetype
	public var t:String = '';

	public var earlyHitMult:Float = 0.5;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public var lateHitThreshold(get, never):Float;
	public function get_lateHitThreshold():Float return Conductor.safeZoneOffset * lateHitMult;
		
	public var earlyHitThreshold(get, never):Float; 
	public function get_earlyHitThreshold():Float return Conductor.safeZoneOffset * earlyHitMult;

	public function getShouldHit(time:Float):Bool return ms > time - lateHitThreshold && ms < time + earlyHitThreshold;

	// public var hit:Bool = false;
	public var missed:Bool = false;

	public var prevNote:Note;
	public var nextNote:Note;

	// visual offsets
	public var xOffset:Float = 0;
	public var yOffset:Float = 0;
	public var angleOffset:Float = 0;
	public var scaleOffset:Offset = {x: 0, y: 0}

	public var tail:NoteTail;
	public var tailAngleOffset:Float = 0;

	public var hasTail(get, never):Bool;
	public function get_hasTail():Bool return l > 0;

	public var l:Float = 0;

	public var parentNote:Note;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;

	public var rating:String = 'unknown';
	public var ratingMod:Float = 0;
	public var ratingDisabled:Bool = false;

	public var noAnimation:Bool = false;
	public var distance:Float = PlayState.NOTE_SPAWN_TIME;

	// attached character
	public var c:String;

	public var ignore:Bool = false;

	public var parentStrum:StrumNote;
	public var speed:Float = 1;

	public var onUpdate:Float->Void = null;
	public var onUpdatePost:Float->Void = null;

	public function new(data:NoteFile, _parentStrum:StrumNote, _c:String)
	{
		super();

		parentStrum = _parentStrum;

		ms = data.ms;
		d = data.d;
		l = data.l;
		t = data.t;

		c = _c;

		antialiasing = parentStrum.antialiasing;

		tail = new NoteTail(this);
		_parentStrum.associatedNotes.push(this);
	}

	public function calculateDistance(_ms:Float):Float
	{
		return (0.45 * (parentStrum.direction == DOWN ? 1 : -1)) * (Conductor.songPosition - _ms) * parentStrum.speed * speed;
	}

	public var inheritLaneAngle:Float = 90;
	private var holding:Bool = false;
	override function update(dt:Float)
	{
		super.update(dt);

		if (onUpdate != null) onUpdate(dt);

		scale.set(parentStrum.scale.x, parentStrum.scale.y);
		scale.x += scaleOffset.x;
		scale.y += scaleOffset.y;

		updateHitbox();

		offset.x = savedOffset.x;
		offset.y = savedOffset.y;

		var angleToUse:Float = parentStrum.laneAngleFollowType == INHERIT ? inheritLaneAngle : parentStrum.laneAngle;
		var laneAngleRads:Float = angleToUse * Math.PI / 180;

		distance = calculateDistance(ms);
		x = parentStrum.x + Math.cos(laneAngleRads) * distance - parentStrum.noteOffset.x + xOffset;
		y = parentStrum.y + Math.sin(laneAngleRads) * distance - parentStrum.noteOffset.y + yOffset;

		angle = parentStrum.angle + angleOffset;

		updateTail(dt);

		if (holding)
		{
			parentStrum.playAnimation('confirm');
			return;
		}
		if (Conductor.songPosition >= ms && ((PlayState.gameInstance.botplay && parentStrum.player) || !parentStrum.player))
		{
			if (active) hit();
			return;
		}

		if (onUpdatePost != null) onUpdatePost(dt);

		var tailLengthOffset:Float = l + ClientPrefs.get('noteTailWindow');
		if (Conductor.songPosition < PlayState.NOTE_KILL_OFFSET + ms + tailLengthOffset) return;
		
		runKill();
		if (parentStrum.player) @:privateAccess PlayState.gameInstance.missNote(this);
	}

	private function updateTail(dt:Float):Void
	{
		if (!hasTail) return;

		tail.scale.x = scale.x;
		tail.updateHitbox();

		var tailOffsets:Offset = parentStrum.getNoteTailOffsets();

		var tailX:Float = x - offset.x;
		tailX += width / 2;
		tailX += tailOffsets.x + parentStrum.skinData.offsets.tails.g.x;

		var tailY:Float = y - offset.y;
		tailY += height / 2;
		tailY += tailOffsets.y + parentStrum.skinData.offsets.tails.g.y;
		if (parentStrum.flipTail) tailY -= tail.height;

		tail.setPosition(tailX, tailY);
		tail.angle = angle + tailAngleOffset;

		if (holding) clipTail();
	}

	private function clipTail():Void
	{
		var clipOffset:Float = parentStrum.direction == UP ? -distance : distance;
		if (clipOffset > tail.height) runKill();

		tail.clipRect = FlxRect.weak(0, clipOffset, tail.frameWidth, tail.frameHeight);
	}

	private var didHit:Bool = false;
	public function hit():Void
	{
		if (didHit) return;
		didHit = true;

		if (PlayState.gameInstance.botplay && parentStrum.player) @:privateAccess PlayState.gameInstance.hitNote(cast this, 0);
		if (!parentStrum.player) @:privateAccess PlayState.gameInstance.opponentHit(cast this);

		parentStrum.playAnimation('confirm');
		runKill(hasTail);
	}

	private function runKill(?_holding:Bool = false):Void
	{
		if (!_holding) runKillTail();
		else holding = true;

		visible = false;
		if (!holding) kill();
	}

	override public function kill():Void
	{
		active = false;
		
		parentStrum.notes.remove(this);

		destroy();
		super.kill();
	}

	private function runKillTail():Void
	{
		if (!hasTail) return;

		@:privateAccess PlayState.gameInstance.hitSustainNote(cast this);
		PlayState.gameInstance.currentlyHeldNotes.remove(this);

		holding = false;

		tail.active = false;
		tail.visible = false;
		
		tail.kill();
		parentStrum.noteTails.remove(tail);
		tail.destroy();
	}

	public function updateSkin():Void
	{
		frames = parentStrum.frames;
		
		loadAnimations();
		if (hasTail) tail.render();
	}

	private var savedOffset:Offset = {x: 0, y: 0}
	private function loadAnimations():Void
	{
		var anims:StrumNote.SkinAnimation = parentStrum.getSolidNoteAnimations();
		var tailAnims:StrumNote.NoteTailSegmentAnimationNames = parentStrum.getNoteTailAnimations();

		for (name in animation.getNameList()) animation.remove(name);

		animation.addByPrefix('body', tailAnims.b.tag, tailAnims.b.fps, true);
		animation.addByPrefix('cap', tailAnims.c.tag, tailAnims.c.fps, true);

		animation.addByPrefix('idle', anims.tag, anims.fps, true);
		animation.play('idle');

		var offsets:Offset = parentStrum.getNoteOffsets();
		offset.set(offsets.x, offsets.y);

		offset.x += parentStrum.skinData.offsets.notes.g.x;
		offset.y += parentStrum.skinData.offsets.notes.g.y;

		savedOffset.x = offset.x;
		savedOffset.y = offset.y;
	}

	public override function toString():String return '(MS: $ms | Tail Length: $l |  Data: $d | Type: $t | Character: $c)';
}