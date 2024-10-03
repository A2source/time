package a2.time.objects.gameplay;

import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;

import a2.time.util.ClientPrefs;
import a2.time.util.Paths;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;
		change(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0, 0];
	public function change(char:String, suffix:String = '') 
	{
		if(this.char != char) 
		{
			var iconGraphic:Dynamic = null;
			for (mod in Paths.getModDirectories())
			{
				var check = Paths.timeGraphic(Paths.charImage(char, 'icons$suffix', mod));

				if (check != null)
				{
					iconGraphic = check;
					break;
				}
			}

			var file:Dynamic = iconGraphic;

			if (file == null)
				file = Paths.image('face');

			loadGraphic(file); // Load stupidly first for getting the file size
			var width2 = width;

			if (width == 450) 
			{
				loadGraphic(file, true, Math.floor(width / 3), Math.floor(height)); // winning icons go br
				iconOffsets[0] = (width - 150) / 3;
				iconOffsets[1] = (width - 150) / 3;
				iconOffsets[2] = (width - 150) / 3;
			} 
			else 
			{
				loadGraphic(file, true, Math.floor(width / 2), Math.floor(height)); // Then load it fr
				iconOffsets[0] = (width - 150) / 2;
				iconOffsets[1] = (width - 150) / 2;
			}
			
			updateHitbox();

			if (width2 == 450)
				animation.add(char, [0, 1, 2], 0, false, isPlayer);
			else
				animation.add(char, [0, 1], 0, false, isPlayer);

			animation.play(char);
			this.char = char;

			antialiasing = ClientPrefs.data.antialiasing;

			if(char.endsWith('-pixel'))
				antialiasing = false;
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}
}
