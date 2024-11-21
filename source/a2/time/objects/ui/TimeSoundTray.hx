package a2.time.objects.ui;

import a2.time.Paths;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.ui.FlxSoundTray;
import flixel.sound.FlxSound;

import lime.graphics.Image;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

class TimeSoundTray extends FlxSoundTray
{
    var lerpYPos:Float = 0;

    public var volUp:String = 'volumeUP';
    public var volDown:String = 'volumeDOWN';
    public var volMax:String = 'volumeMAX';

    var playMaxSound:Bool = false;

    public function new()
    {
        super();
        removeChildren();

        var bg:Bitmap = new Bitmap(BitmapData.fromImage(Image.fromFile('assets/shared/images/tray.png')));
        bg.scaleX = 0.32;
        bg.scaleY = 0.32;
        addChild(bg);

        var bx:Int = 23;
		var by:Int = 22;
		_bars = new Array();

		for (i in 0...10)
		{
            var dark = new Bitmap(new BitmapData(2, i + 1, false, flixel.util.FlxColor.fromRGBFloat(i / 10, (10 - i) / 10, 0).getDarkened(0.7)));
			dark.x = bx;
			dark.y = by;
			addChild(dark);

			var tmp = new Bitmap(new BitmapData(2, i + 1, false, flixel.util.FlxColor.fromRGBFloat(i / 10, (10 - i) / 10, 0)));
			tmp.x = bx;
			tmp.y = by;
			addChild(tmp);
			_bars.push(tmp);
			bx += 6;
			by--;
		}

        y = -height;
        visible = false;

        screenCenter();
    }

    override public function update(dt:Float):Void
    {
        y = FlxMath.lerp(lerpYPos, y, Math.exp(-dt / 75));

        if (_timer > 0)
            _timer -= dt / 1000;
        else if (y >= -height)
            lerpYPos = -height - 10;

        if (y <= -height)
        {
            visible = false;
            active = false;
        }
    }

    override public function show(up:Bool = false):Void
    {
        _timer = 2;

        lerpYPos = 0;

        visible = true;
        active = true;

        var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

        if (FlxG.sound.muted || FlxG.sound.volume == 0)
            globalVolume = 0;

        if (!silent)
        {
            var sound = up ? volUp : volDown;
            if (globalVolume >= 10) sound = volMax;

            FlxG.sound.play(Paths.sound(sound), FlxG.sound.volume + 0.1);
        }

        for (i in 0..._bars.length)
            _bars[i].visible = i < globalVolume;
    }
}