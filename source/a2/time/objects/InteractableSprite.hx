package a2.time.objects;

import flixel.FlxG;

class InteractableSprite extends DynamicSprite
{
    public var onHover:Dynamic;
    public var whileHovered:Dynamic;
    public var onExit:Dynamic;
    
    private var justHovered:Bool = false;

    public var onClick:Dynamic;
    public var camIndex:Int = 0;

    override public function update(dt:Float)
    {
        if (!FlxG.mouse.overlaps(this, cameras[camIndex]))
        {
            if (justHovered)
            {
                justHovered = false;

                if (onExit != null)
                    onExit();
            }

            return;
        }

        if (!justHovered)
        {
            justHovered = true;

            if (onHover != null)
                onHover();
        }

        if (whileHovered != null)
            whileHovered();

        if (!FlxG.mouse.justPressed)
            return;

        if (onClick == null)
            return;

        onClick();
    }
}