package a2.time.objects.ui;

import a2.time.util.ClientPrefs;
import a2.time.Paths;

import flixel.FlxSprite;
import animateatlas.AtlasFrameMaker;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class AttachedSprite extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public function new(?pngPath:Dynamic = null, ?xmlPath:String = null, ?library:String = null, ?loop:Bool = false)
	{
		super();

		if (xmlPath != null)
			frames = FlxAtlasFrames.fromSparrow(pngPath, xmlPath);
		else
			loadGraphic(pngPath);
		
		antialiasing = ClientPrefs.data.antialiasing;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) 
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if(copyAngle)
				angle = sprTracker.angle + angleAdd;

			if(copyAlpha)
				alpha = sprTracker.alpha * alphaMult;

			if(copyVisible) 
				visible = sprTracker.visible;
		}
	}
}
