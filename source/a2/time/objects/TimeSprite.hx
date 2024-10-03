package a2.time.objects;

import flixel.addons.effects.FlxSkewedSprite;

// huggy wuggy

class TimeSprite extends FlxSkewedSprite
{
    public var onDraw:Dynamic = null;
    public var bypassDraw:Bool = false;

    override public function draw()
    {
        if (onDraw != null && !bypassDraw)
            onDraw(this);
        else
            super.draw();
    }
}