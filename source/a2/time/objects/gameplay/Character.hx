package a2.time.objects.gameplay;

import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import sys.io.File;
import sys.FileSystem;
import haxe.Json;
import flixel.math.FlxPoint;

import a2.time.states.PlayState;
import a2.time.objects.TimeSprite;
import a2.time.objects.song.Conductor;
import a2.time.util.ClientPrefs;
import a2.time.Paths;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
#end

using StringTools;

typedef CharacterMetadata =
{
	var artists:Array<String>;
	var animators:Array<String>;
}

typedef CharacterFile = 
{
	var name:String;

	var scale:Float;
	var sing_duration:Float;

	var flip_x:Bool;
	var antialiasing:Bool;
	var healthbar_colors:Array<Int>;

	var metadata:CharacterMetadata;
}

typedef AnimArray = 
{
	var anim:String;
	var sheet:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

enum CharacterType
{
	NORMAL;
	TRAIL;
	SHADOW;
}

class Character extends TimeSprite
{
	public static var SING_ANIMATIONS:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var metadata:CharacterMetadata;

	public var rimLightShader:FlxRuntimeShader;

	public var name:String = DEFAULT_CHARACTER;

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;

	public var holdTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;

	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose

	public var danceIdle:Bool = false; //Character use dance left and right instead of idle
	public var skipDance:Bool = false;

	public var animSuffix:String = '';
	public var iconSuffix:String = '';

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	public var trailChar:Character;
	public var trailInitAlpha:Float = 0.8;

	public var prevDir:Int = -1;
	public var prevDirKeep:Int = -1;

	public var hitSustainNote:Bool = false;

	// le shadows
	public var simpleShadows:Bool = false;
	public var shadowChar:Character;
	public var simpleShadow:FlxSkewedSprite;

	public var baseOffset:Array<Float> = [0, 0];
	public var baseSkew:Array<Float> = [0, 0];
	public var baseScale:Array<Float> = [1, 1];
	public var shadowOffsets:Map<String, Array<Float>> = new Map();
	public var shadowSkews:Map<String, Array<Float>> = new Map();
	public var shadowScales:Map<String, Array<Float>> = new Map();

	public var charType:CharacterType;

	private var curController:FlxAnimationController;

	//Used on Character Editor
	public var spriteSheets:Array<String> = [];
	public var sheetAnimations:Array<FlxAnimationController> = [];
	public var sheetFrames:Array<Dynamic> = [];
	public var jsonScale:Float = 1;
	public var initialWidth:Float = 0;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var animSetScale:String = 'idle';

	public var modDirectory:String = '';

	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false, ?type:CharacterType = NORMAL, ?debug:Bool = false)
	{
		super(x, y);

		charType = type;

		curController = animation;

		Paths.VERBOSE = false;

		var scaleToSet:Float = 1;

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		name = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.data.antialiasing;
		var library:String = null;

		var jsonToLoad:String = isPlayer ? 'player' : 'opponent';
		var opposite:String = isPlayer ? 'opponent' : 'player';

		var charPath:String = null;
		var animPath:String = null;

		for (mod in Paths.getModDirectories())
		{
			var charCheck = Paths.charJson(name, 'character', mod);
			var animCheck = Paths.charJson(name, jsonToLoad, mod);

			if (charCheck != null && charPath == null)
			{
				charPath = charCheck;
				modDirectory = mod;
			}

			if (animCheck != null && animPath == null)
			{
				animPath = animCheck;
				modDirectory = mod;
			}

			if (animPath != null && charPath != null)
				break;

			if (animPath == null) 
				animPath = Paths.charJson(name, opposite, mod);
		}

		if (charPath == null || animPath == null)
		{
			animPath = Paths.charJson(DEFAULT_CHARACTER, 'player', Main.MOD_NAME); 
			charPath = Paths.charJson(DEFAULT_CHARACTER, 'character', Main.MOD_NAME);
			modDirectory = Main.MOD_NAME;
		}

		var rawCharJson = File.getContent(charPath);
		var rawAnimJson = File.getContent(animPath);

		var charJson:CharacterFile = cast Json.parse(rawCharJson);

		var castAnimJson = cast Json.parse(rawAnimJson);
		var animJson:Array<AnimArray> = castAnimJson.animations;

		name = charJson.name;
		debugMode = debug;

		var spriteType = "sparrow";

		//sparrow
		//packer
		//texture
		// var modTxtToFind:String = Paths.modsTxt(spriteSheets[0]);
		// var txtToFind:String = Paths.getPath('characters/${name}/${spriteSheets[0]}.txt', TEXT);
		
		// if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
		// 	spriteType = "packer";
		
		// var modAnimToFind:String = Paths.modFolders('characters/${name}/${spriteSheets[0]}/Animation.json');
		// var animToFind:String = Paths.getPath('characters/${name}/${spriteSheets[0]}/Animation.json', TEXT);
		
		// if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
		// 	spriteType = "texture";

		for (anim in animJson)
			animationsArray.push(anim);

		if(animationsArray != null && animationsArray.length > 0) 
		{
			for (anim in animationsArray) 
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;

				shadowOffsets.set(anim.anim, [0, 0]);
				shadowSkews.set(anim.anim, [0, 0]);
				shadowScales.set(anim.anim, [0, 0]);

				if (debugMode && charType == TRAIL)
					animLoop = true;

				// if this animation's spritesheet hasn't been added yet
				// add it
				// and a new animation controller too
				if (!spriteSheets.contains(anim.sheet))
				{
					spriteSheets.push(anim.sheet);
					sheetAnimations.push(new FlxAnimationController(this));

					switch (spriteType)
					{
						case "packer":
							trace('not supported');
						
						case "sparrow":
							frames = Paths.getCharSparrow(name, anim.sheet, modDirectory);
						
						case "texture":
							frames = AtlasFrameMaker.construct(anim.sheet);
					}
				}

				if(animIndices != null && animIndices.length > 0) 
					sheetAnimations[spriteSheets.indexOf(anim.sheet)].addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				else 
					sheetAnimations[spriteSheets.indexOf(anim.sheet)].addByPrefix(animAnim, animName, animFps, animLoop);

				if(anim.offsets != null && anim.offsets.length > 1 && charType != SHADOW)
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		} 
		else 
			quickAnimAdd('idle', 'BF idle dance');

		switch (spriteType)
		{
			case "packer":
				trace('not supported');
				// for (sheet in spriteSheets)
				// {
				// 	frames = Paths.getCharacterPackerAtlas(name, sheet);
				// 	sheetFrames.push(frames);
				// }
			
			case "sparrow":
				for (sheet in spriteSheets)
				{
					frames = Paths.getCharSparrow(name, sheet, modDirectory);
					sheetFrames.push(frames);
				}
			
			case "texture":
				for (sheet in spriteSheets)
				{
					frames = AtlasFrameMaker.construct(sheet);
					sheetFrames.push(frames);
				}
		}

		initialWidth = width;
		scaleToSet = charJson.scale;

		positionArray = castAnimJson.position;
		cameraPosition = castAnimJson.camera_position;

		if (positionArray == null)
		{
			positionArray = [0, 0];
			cameraPosition = [0, 0];
		}

		healthIcon = 'icon';
		singDuration = charJson.sing_duration;

		flipX = !!charJson.flip_x;

		antialiasing = charJson.antialiasing;
		if(!ClientPrefs.data.antialiasing) antialiasing = false;

		if(charJson.healthbar_colors != null && charJson.healthbar_colors.length > 2)
			healthColorArray = charJson.healthbar_colors;

		if (Reflect.hasField(charJson, 'metadata'))
			metadata = charJson.metadata;

		if(animOffsets.exists('singLEFT-miss') || animOffsets.exists('singDOWN-miss') || animOffsets.exists('singUP-miss') || animOffsets.exists('singRIGHT-miss')) hasMissAnimations = true;

		// creating the trail stuff aw yea

		// i accidentally created a recursive loop of making trail characters for trail characters
		// now there is safety in place for that
		// oops
		if (charType == NORMAL)
		{
			trailChar = new Character(x, y, character, isPlayer, TRAIL, debug);
			trailChar.alpha = 0;

			shadowChar = new Character(x, y, character, isPlayer, SHADOW, debug);
			shadowChar.alpha = 0;
			shadowChar.color = 0xFF000000;

			simpleShadow = new FlxSkewedSprite(x, y);
			simpleShadow.loadGraphic(Paths.image('simpleShadow'));
			simpleShadow.alpha = 0;
			simpleShadow.color = 0xFF000000;
		}

		recalculateDanceIdle();
		dance();

		// omfg
		if (animation.curAnim == null)
			playAnim(danceIdle ? 'danceLEFT' : 'idle');

		setScale(scaleToSet);

		Paths.VERBOSE = true;
	}

	public function setScale(val:Float)
	{
		if (charType != NORMAL)
			return;

		jsonScale = val;

		setGraphicSize(Std.int(initialWidth * val));
		updateHitbox();

		trailChar.setGraphicSize(Std.int(initialWidth * val));
		trailChar.updateHitbox();
		trailChar.jsonScale = val;

		shadowChar.setGraphicSize(Std.int(initialWidth * val));
		shadowChar.updateHitbox();
		shadowChar.jsonScale = val;
	}

	function updateFollowChars()
	{
		if (charType != NORMAL)
			return;

		trailChar.setPosition(x, y);
		shadowChar.setPosition(x, y + height);
		simpleShadow.setPosition(x, y + height);

		shadowChar.visible = visible && !simpleShadows;
		shadowChar.flipY = !flipY;

		simpleShadow.visible = visible && simpleShadows;
	}

	override function update(dt:Float)
	{
		updateFollowChars();
		updateAnim(dt);

		super.update(dt);
	}

	private function updateAnim(dt:Float)
	{
		if(debugMode || animation.curAnim == null)
			return;

		if(specialAnim && animation.curAnim.finished)
		{
			specialAnim = false;
			dance();
		}

		if (animation.curAnim.name.startsWith('sing'))
			holdTimer += dt * 0.9;

		if (holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration)
		{
			dance();
			holdTimer = 0;
		}
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (debugMode)
			return;

		if (skipDance)
			return;

		if (specialAnim)
			return;

		if (danceIdle)
		{
			danced = !danced;

			if (danced)
				playAnim('danceRIGHT');
			else
				playAnim('danceLEFT');
		}
		else if (hasAnim('idle'))
			playAnim('idle');
	}

	public function getCameraPosition():FlxPoint
	{
		var point = getMidpoint();

		if(!isPlayer) 
			point.x += 150 + cameraPosition[0];
		else
			point.x -= 100 + cameraPosition[0];

		point.y -= 100 - cameraPosition[1];

		return point;
	}

	function updateShadow(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		if (charType != NORMAL)
			return;

		shadowChar.playAnim(AnimName, Force, Reversed, Frame);

		if (shadowOffsets.get(AnimName) != null)
		{
			var curOffsets = shadowOffsets.get(AnimName);
			shadowChar.offset.x = baseOffset[0] + curOffsets[0];
			shadowChar.offset.y = baseOffset[1] + curOffsets[1];

			simpleShadow.offset.x = baseOffset[0] + curOffsets[0];
			simpleShadow.offset.y = baseOffset[1] + curOffsets[1];
		}

		if (shadowSkews.get(AnimName) != null)
		{
			var curSkews = shadowSkews.get(AnimName);
			shadowChar.skew.x = baseSkew[0] + curSkews[0];
			shadowChar.skew.y = baseSkew[1] + curSkews[1];

			simpleShadow.skew.x = baseSkew[0] + curSkews[0];
			simpleShadow.skew.y = baseSkew[1] + curSkews[1];
		}

		if (shadowScales.get(AnimName) != null)
		{
			var curScales = shadowScales.get(AnimName);
			shadowChar.scale.x = baseScale[0] + curScales[0];
			shadowChar.scale.y = baseScale[1] + curScales[1];

			simpleShadow.scale.x = baseScale[0] + curScales[0];
			simpleShadow.scale.y = baseScale[1] + curScales[1];
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		updateShadow(AnimName, Force, Reversed, Frame);

		specialAnim = false;

		var animIndex:Int = spriteSheets.indexOf(getAnimByName(AnimName).sheet);
		var controller:FlxAnimationController = sheetAnimations[animIndex];

		curController = controller;

		if (frames != sheetFrames[animIndex])
			frames = sheetFrames[animIndex];

		animation.copyFrom(controller);

		animation.play(AnimName + animSuffix, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);

		if (danceIdle)
		{
			if (AnimName == 'singLEFT')
				danced = true;
			
			else if (AnimName == 'singRIGHT')
				danced = false;
		
			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	public function playTrailAnim(tween:Bool, AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (charType != NORMAL)
			return;

		if (tween)
		{
			trailChar.alpha = trailInitAlpha;
			FlxTween.cancelTweensOf(trailChar);
			PlayState.instance.modchartTweens['${name} ${prevDir} trail'] = FlxTween.tween(trailChar, {alpha: 0}, 0.4);
		}

		trailChar.holdTimer = 0;
		trailChar.playAnim(AnimName, Force, Reversed, Frame);
	}

	public function getAnimByName(name:String):AnimArray
	{
		for (anim in animationsArray)
			if (anim.anim == name)
				return anim;

		return animationsArray[0];
	}

	public function hasAnim(name:String, ?suffix:String = ''):Bool
	{
		for (anim in animationsArray)
			if (anim.anim == name + suffix)
				return true;

		return false;
	}

	public function animStartsWith(string:String):Bool
	{
		if (animation.curAnim == null)
			return false;

		return animation.curAnim.name.startsWith(string);
	}

	public function animEndsWith(string:String):Bool
	{
		if (animation.curAnim == null)
			return false;

		return animation.curAnim.name.endsWith(string);
	}

	public function animEquals(string:String):Bool
	{
		if (animation.curAnim == null)
			return false;

		return animation.curAnim.name == string;
	}

	public var curAnimName(get, default):String = '';
	public function get_curAnimName():String
	{
		if (animation.curAnim == null)
			return '';

		return animation.curAnim.name;
	}

	public function hasLoopAnim(name:String):Bool return hasAnim(name, '-loop');

	private function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() 
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (hasAnim('danceLEFT') && hasAnim('danceRIGHT'));

		if(settingCharacterUp)
			danceEveryNumBeats = (danceIdle ? 1 : 2);

		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}

		if (danceIdle)
			animSetScale = 'danceLEFT';

		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0) animOffsets[name] = [x, y];

	public function quickAnimAdd(name:String, anim:String) animation.addByPrefix(name, anim, 24, false);
}