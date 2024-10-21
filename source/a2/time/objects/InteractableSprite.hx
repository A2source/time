package a2.time.objects;

import flixel.FlxG;

import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

class InteractableSprite extends DynamicSprite
{
    public var onHover:Dynamic;
    public var whileHovered:Dynamic;
    public var onExit:Dynamic;
    
    private var justHovered:Bool = false;

    public var onClick:Dynamic;
    public var camIndex:Int = 0;

    public var cursor:MouseCursor = BUTTON;
    public var setCursor:Bool = true;

    override public function update(dt:Float)
    {
        super.update(dt);

        if (!isOnScreen(cameras[camIndex]))
            return;

        if (!FlxG.mouse.overlaps(this, cameras[camIndex]))
        {
            if (justHovered)
            {
                justHovered = false;

                if (setCursor)
                    Mouse.cursor = ARROW;

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

        if (setCursor)
            Mouse.cursor = cursor;

        if (whileHovered != null)
            whileHovered();

        if (!FlxG.mouse.justPressed)
            return;

        if (onClick == null)
            return;

        onClick();
    }

    override public function destroy()
    {
        if (setCursor)
            Mouse.cursor = ARROW;

        super.destroy();
    }
}