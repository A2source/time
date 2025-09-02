package a2.time.objects.gameplay;

import flixel.FlxSprite;

import a2.time.backend.ClientPrefs;
import a2.time.backend.Paths;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	
	public var character:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;
		change(char);
		scrollFactor.set();
	}

	override function update(dt:Float)
	{
		super.update(dt);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0, 0];
	public static var ICON_FRAME_SIZE:Int = 150;
	public function change(char:String, suffix:String = '') 
	{
		if(character != char) 
		{
			var iconGraphic:Dynamic = null;
			for (mod in Paths.directories)
			{
				var check = Paths.mods.character.image([char, 'icons$suffix'], mod).content;

				if (check != null)
				{
					iconGraphic = check;
					break;
				}
			}

			var file:Dynamic = iconGraphic;

			if (file == null)
				file = a2.time.backend.Assets.cacheGraphic('assets/shared/images/face.png').content;

			loadGraphic(file); // Load stupidly first for getting the file size

			var iconAmt:Int = Math.floor(width / ICON_FRAME_SIZE);
			loadGraphic(file, true, Math.floor(width / iconAmt), Math.floor(height));

			var frameIndices:Array<Int> = [];
			for (i in 0...iconAmt)
			{
				iconOffsets.push((width - ICON_FRAME_SIZE) / iconAmt);
				frameIndices.push(i);
			}
			
			updateHitbox();
			animation.add(char, frameIndices, 0, false, isPlayer);

			animation.play(char);
			character = char;

			antialiasing = ClientPrefs.get('antialiasing');

			if(character.endsWith('-pixel'))
				antialiasing = false;
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.set(iconOffsets[0], iconOffsets[0]);
	}
}
