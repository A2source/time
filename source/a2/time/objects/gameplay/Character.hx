package a2.time.objects.gameplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import sys.io.File;
import sys.FileSystem;
import haxe.Json;

import a2.time.backend.Assets;
import a2.time.backend.Paths;
import a2.time.states.PlayState;
import a2.time.objects.TimeSprite;
import a2.time.objects.song.Conductor;
import a2.time.backend.ClientPrefs;
import a2.time.util.Offset;

using StringTools;

typedef CharacterMetadata =
{
	var artists:Array<String>;
	var animators:Array<String>;
}

typedef CharacterFile = 
{
	var name:String;
	var sheets:Array<String>;

	var scale:Float;
	var singDuration:Float;

	var flipX:Bool;
	var flipY:Bool;

	var antialiasing:Bool;

	var playerCameraPosition:Offset;
	var opponentCameraPosition:Offset;

	var metadata:CharacterMetadata;
}
typedef CharacterAnimationsFile = { var animations:Array<CharacterAnimation>; }

typedef CharacterAnimation = 
{
	var tag:String;
	var name:String;

	var fps:Int;

	var flipX:Bool;
	var flipY:Bool;

	var loop:Bool;
	var loopPoint:Int;

	var indices:Array<Int>;

	var playerOffsets:Offset;
	var opponentOffsets:Offset;

	var type:String;
	var typeIndex:Int;
}

typedef CharacterOptions =
{
	var name:String;
	var player:Bool;

	@:optional var dir:String;
	@:optional var type:CharacterType; 
	@:optional var debug:Bool;
}

enum CharacterType
{
	NORMAL;
	TRAIL;
	SHADOW;
}

class Character extends TimeSprite
{
	public static var DEFAULT_CHARACTER:String = 'bf';

	public var name:String = DEFAULT_CHARACTER;
	public var player:Bool = false;

	public var type:CharacterType;
	public var dir:String = '';

	// for idles, also if you character has dance left / right (or more!)
	public var danceAnimations:Array<String> = [];
	private var currentDanceIndex:Int = 0;
	public var doDance:Bool = true;

	// sing and miss animations, sorted by notedata
	public var singAnimations:Array<String> = [];
	public var missAnimations:Array<String> = [];
	public var holdAnimations:Array<String> = [];

	public var hasMissAnimations(get, never):Bool;
	public function get_hasMissAnimations():Bool return missAnimations.length > 0;

	public var hasHoldAnimations(get, never):Bool;
	public function get_hasHoldAnimations():Bool return holdAnimations.length > 0;

	public var animations:Map<String, CharacterAnimation> = new Map();

	public var debug:Bool = false;
	public var metadata:CharacterMetadata;

	public var holdTimer:Float = 0;
	public var singDuration:Float = 4;
	
	public var justHitNote:Bool = false;
	public var prevDir:Int = -1;
	public var prevDirKeep:Int = -1;

	public var animSuffix:String = '';
	public var iconSuffix:String = '';
	
	private var playerCameraPosition:Offset = {x: 0, y: 0}
	private var opponentCameraPosition:Offset = {x: 0, y: 0}

	public var trail:Character;
	public var trailInitAlpha:Float = 0.8;

	public var hitSustainNote:Bool = false;

	public var simpleShadows:Bool = false;
	public var shadow:Character;
	public var simpleShadow:FlxSkewedSprite;

	public var baseOrigin:Offset = {x: 0, y: 0}
	public var baseOffset:Offset = {x: 0, y: 0}
	public var baseScale:Offset = {x: 1, y: 1}
	public var baseSkew:Offset = {x: 0, y: 0}
	public var shadowOffsets:Map<String, Offset> = new Map();
	public var shadowScales:Map<String, Offset> = new Map();
	public var shadowSkews:Map<String, Offset> = new Map();
	public var shadowAlpha:Float = 0;

	public var characterJsonData:CharacterFile;

	private var spriteSheets:Array<String> = [];

	public function new(x:Float, y:Float, options:CharacterOptions)
	{
		super(x, y);

		name = '${options.name}';
		player = options.player;

		var parsedDir:String = Reflect.hasField(options, 'dir') ? options.dir : Main.MOD_NAME;
		var parsedType:CharacterType = Reflect.hasField(options, 'type') ? options.type : NORMAL;
		var parsedDebug:Bool = Reflect.hasField(options, 'debug') ? options.debug : false;

		dir = parsedDir;
		type = parsedType;
		debug = parsedDebug;

		var charContent:String = Paths.mods.character.json([name, 'character'], dir).content;
		var charJson:CharacterFile = cast Json.parse(charContent);

		characterJsonData = charJson;
		
		playerCameraPosition = charJson.playerCameraPosition;
		opponentCameraPosition = charJson.opponentCameraPosition;

		singDuration = charJson.singDuration;

		var doFlipX:Bool = !!charJson.flipX;
		var doFlipY:Bool = !!charJson.flipY;

		characterJsonData.flipX = doFlipX;
		characterJsonData.flipY = doFlipY;

		flipX = !player;
		if (doFlipX) flipX = !flipX;

		if (doFlipY) flipY = true;

		antialiasing = charJson.antialiasing;
		if(!ClientPrefs.get('antialiasing')) antialiasing = false;

		if (Reflect.hasField(charJson, 'metadata')) metadata = charJson.metadata;

		spriteSheets = charJson.sheets;
		frames = Paths.mods.character.atlas([name, spriteSheets[0]], dir).content;
		for (i in 1...spriteSheets.length - 1)
		{
			var sheetFrames:FlxAtlasFrames = Paths.mods.character.atlas([name, spriteSheets[i]], dir).content;
			for (frame in sheetFrames.frames) frames.pushFrame(frame);
		}

		var animContent:String = Paths.mods.character.json([name, 'animations'], dir).content;
		var animJson:CharacterAnimationsFile = cast Json.parse(animContent);

		var foundDanceAnimations:Array<CharacterAnimation> = [];
		var foundSingAnimations:Array<CharacterAnimation> = [];
		var foundMissAnimations:Array<CharacterAnimation> = [];
		var foundHoldAnimations:Array<CharacterAnimation> = [];
		for (anim in animJson.animations)
		{
			animations.set(anim.name, {
				tag: cast anim.tag,
				name: cast anim.name,

				fps: cast anim.fps,

				flipX: cast anim.flipX,
				flipY: cast anim.flipY,

				loop: cast anim.loop,
				loopPoint: cast anim.loopPoint,
				
				indices: cast anim.indices,

				playerOffsets: cast anim.playerOffsets,
				opponentOffsets: cast anim.opponentOffsets,

				type: cast anim.type,
				typeIndex: cast anim.typeIndex
			});

			shadowOffsets.set(anim.name, {x: 0, y: 0});
			shadowSkews.set(anim.name, {x: 0, y: 0});
			shadowScales.set(anim.name, {x: 0, y: 0});

			switch(anim.type)
			{
				case 'DANCE': foundDanceAnimations.push(anim);
				case 'SING': foundSingAnimations.push(anim);
				case 'MISS': foundMissAnimations.push(anim);
				case 'HOLD': foundHoldAnimations.push(anim);
			}

			var parsedLoop:Bool = (type == TRAIL && debug) ? true : anim.loop;
			if (anim.indices.length > 0) 
				animation.addByIndices(anim.name, anim.tag, anim.indices, "", cast anim.fps, parsedLoop, anim.flipX, anim.flipY);
			else 
				animation.addByPrefix(anim.name, anim.tag, cast anim.fps, parsedLoop, anim.flipX, anim.flipY);

			@:privateAccess 
			{
				var thisAnim = animation._animations.get(anim.name);
				if (thisAnim == null) continue;
				thisAnim.loopPoint = anim.loopPoint;
			}
		}

		// foundDanceAnimations.sort((a, b) -> { a.type.order < b.type.order ? -1 : a.type.order == b.type.order ? 0 : 1; });
		// foundSingAnimations.sort((a, b) -> { a.type.data < b.type.data ? -1 : a.type.data == b.type.data ? 0 : 1; });
		// foundMissAnimations.sort((a, b) -> { a.type.data < b.type.data ? -1 : a.type.data == b.type.data ? 0 : 1; });

		for (anim in foundDanceAnimations) danceAnimations[anim.typeIndex] = anim.name;
		for (anim in foundSingAnimations) singAnimations[anim.typeIndex] = anim.name;
		for (anim in foundMissAnimations) missAnimations[anim.typeIndex] = anim.name;
		for (anim in foundHoldAnimations) holdAnimations[anim.typeIndex] = anim.name;

		// i accidentally created a recursive loop of making trail characters for trail characters
		// now there is safety in place for that
		// oops
		if (type == NORMAL)
		{
			trail = new Character(x, y, {
				name: name,
				player: player, 
				dir: dir, 
				type: TRAIL,
				debug: debug
			});
			trail.alpha = 0;

			shadow = new Character(x, y, {
				name: name,
				player: player, 
				dir: dir, 
				type: SHADOW,
				debug: debug
			});
			shadow.alpha = 0;
			shadow.color = 0xFF000000;

			simpleShadow = new FlxSkewedSprite(x, y);
			simpleShadow.loadGraphic(cast Assets.cacheGraphic('assets/shared/images/simpleShadow.png').content);
			simpleShadow.alpha = 0;
			simpleShadow.color = 0xFF000000;

			shadow.animation.copyFrom(animation);
			trail.animation.copyFrom(animation);
		}

		setScale(charJson.scale);

		if (debug) playAnim(danceAnimations[0], true);
		else dance();
	}

	public function setScale(val:Float)
	{
		if (type != NORMAL) return;

		scale.set(val, val);
		updateHitbox();

		trail.scale.set(val, val);
		trail.updateHitbox();

		shadow.scale.set(val, val);
		shadow.updateHitbox();
	}

	function updateFollowChars()
	{
		if (type != NORMAL) return;

		trail.setPosition(x, y);
		shadow.setPosition(x, y + height);
		simpleShadow.setPosition(x, y + height);

		shadow.visible = visible && !simpleShadows;
		shadow.flipX = flipX;
		shadow.flipY = !flipY;

		simpleShadow.visible = visible && simpleShadows;

		trail.visible = visible;
		trail.flipX = flipX;
		trail.flipY = flipY;

		shadow.origin.set(baseOrigin.x, baseOrigin.y);
		simpleShadow.origin.set(baseOrigin.x, baseOrigin.y);

		shadow.alpha = shadowAlpha;
		simpleShadow.alpha = shadowAlpha;
	}

	override function update(dt:Float)
	{
		updateFollowChars();
		updateAnim(dt);

		super.update(dt);
	}

	private function updateAnim(dt:Float)
	{
		if(debug || animation.curAnim == null) return;

		if (animations.get(curAnimName).type == 'SING' && !hitSustainNote) holdTimer += dt * 0.9;

		if (holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration)
		{
			holdTimer = 0;
			justHitNote = false;

			dance();
		}
	}

	public function dance()
	{
		if (debug) return;
		if (!doDance) return;

		if (justHitNote && holdTimer == 0) return;
		if (holdTimer > 0) 
		{
			justHitNote = false;
			return;
		}

		if (hitSustainNote) return;

		playAnim(danceAnimations[currentDanceIndex]);

		currentDanceIndex++;
		if (currentDanceIndex > danceAnimations.length - 1) currentDanceIndex = 0;
	}

	public var cameraPosition(get, never):FlxPoint;
	public function get_cameraPosition():FlxPoint
	{
		var point = getMidpoint();

		var position:Offset;
		if (player)
		{
			position = playerCameraPosition;
			point.x -= 100 + position.x;
		}
		else
		{			
			position = opponentCameraPosition;
			point.x -= 100 + position.x;
		}

		point.y -= 100 - position.y;

		return point;
	}

	function updateShadow(_name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		if (type != NORMAL) return;

		shadow.playAnim(_name, force, reversed, frame);

		if (shadowOffsets.get(_name) != null)
		{
			var curOffsets = shadowOffsets.get(_name);
			shadow.offset.x = baseOffset.x + curOffsets.x;
			shadow.offset.y = baseOffset.y + curOffsets.y;

			simpleShadow.offset.x = baseOffset.x + curOffsets.x;
			simpleShadow.offset.y = baseOffset.y + curOffsets.y;
		}

		if (shadowSkews.get(_name) != null)
		{
			var curSkews = shadowSkews.get(_name);
			shadow.skew.x = baseSkew.x + curSkews.x;
			shadow.skew.y = baseSkew.y + curSkews.y;

			simpleShadow.skew.x = baseSkew.x + curSkews.x;
			simpleShadow.skew.y = baseSkew.y + curSkews.y;
		}

		if (shadowScales.get(_name) != null)
		{
			var curScales = shadowScales.get(_name);
			shadow.scale.x = baseScale.x + curScales.x;
			shadow.scale.y = baseScale.y + curScales.y;

			simpleShadow.scale.x = baseScale.x + curScales.x;
			simpleShadow.scale.y = baseScale.y + curScales.y;
		}
	}

	public function playAnim(_name:String, force:Bool = true, reversed:Bool = false, frame:Int = 0):Void
	{
		PlayState.callAllScripts('preCharacterAnimation', [this, _name, force, reversed, frame]);

		hitSustainNote = false;
		updateShadow(_name, force, reversed, frame);

		animation.play(_name + animSuffix, force, reversed, frame);

		var foundOffset:Offset = {x: 0, y: 0}
		if (animations.exists(_name))
		{
			if (player) foundOffset = animations.get(_name).playerOffsets;
			else foundOffset = animations.get(_name).opponentOffsets;
		}

		offset.set(foundOffset.x * scale.x, foundOffset.y * scale.y);

		PlayState.callAllScripts('onCharacterAnimation', [this, _name, force, reversed, frame]);
	}

	public function playTrailAnim(tween:Bool, _name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		if (type != NORMAL) return;

		if (tween)
		{
			trail.alpha = trailInitAlpha;
			FlxTween.cancelTweensOf(trail);
			PlayState.gameInstance.scriptTweens.set('${name} ${prevDir} trail', FlxTween.tween(trail, {alpha: 0}, 0.4));
		}

		trail.holdTimer = 0;
		trail.playAnim(_name, force, reversed, frame);
	}

	public function getAnimFromName(name:String):CharacterAnimation return animations.get(name);
	public function hasAnim(name:String, ?suffix:String = ''):Bool return animations.exists(name + suffix);

	public function getSingAnimationFromData(data:Int)
	{
		if (singAnimations[data] == null) return '';
		return singAnimations[data];
	}

	public function getMissAnimationFromData(data:Int)
	{
		if (missAnimations[data] == null) return '';
		return missAnimations[data];
	}

	public function getHoldAnimationFromData(data:Int)
	{
		if (holdAnimations[data] == null) return '';
		return holdAnimations[data];
	}

	public function animStartsWith(string:String):Bool return curAnimName.startsWith(string);
	public function animEndsWith(string:String):Bool return curAnimName.endsWith(string);
	public function animEquals(string:String):Bool return curAnimName == string;

	public var curAnimName(get, never):String;
	public function get_curAnimName():String
	{
		if (animation.curAnim == null) return '';
		return animation.curAnim.name;
	}
}