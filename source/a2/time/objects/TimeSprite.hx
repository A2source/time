package a2.time.objects;

import a2.time.states.PlayState;

import flixel.FlxG;
import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.effects.FlxSkewedSprite;

class TimeSprite extends FlxSkewedSprite
{
    public var onDraw:Dynamic->Void = null;
    public var bypassDraw:Bool = false;

    public var zIndexCallback:Int->Int->Void;

    public var zIndex(default, set):Int = 0;
    public function set_zIndex(value:Int):Int
    {
        if (zIndexCallback != null) zIndexCallback(zIndex, value);
        if (FlxG.state is PlayState && PlayState.gameInstance.members.contains(this))
        {
            PlayState.gameInstance.remove(this);
            PlayState.gameInstance.insert(value, this);
        }

        zIndex = value;
        return value;
    }

    private var _setRimShader:Bool = false;

    public var rimLightShader(default, set):FlxRuntimeShader;
    public function set_rimLightShader(value:FlxRuntimeShader):FlxRuntimeShader
    {
        if (!_setRimShader)
        {
            rimLightShader = value;
            shader = value;

            rimLightShader.setFloatArray('overlayColor', [1, 0, 0, 0]);
            rimLightShader.setFloatArray('satinColor', [1, 0, 0, 0]);
            rimLightShader.setFloatArray('innerShadowColor', [1, 0, 0, 0]);
        
            rimLightShader.setFloat('innerShadowAngle', 0);
            rimLightShader.setFloat('innerShadowDistance', 0);

            _setRimShader = true;
        }

        return rimLightShader;
    }

    public var onUpdate:Float->Void = null;
    public var onUpdatePost:Float->Void = null;
    override public function update(dt:Float)
    {
        if (onUpdate != null) onUpdate(dt);
        super.update(dt);
        if (onUpdatePost != null) onUpdatePost(dt);
    }

    override public function draw()
    {
        if (onDraw != null && !bypassDraw) onDraw(this);
        else super.draw();
    }

    private static final DEFAULT_IMAGE_PATH:String = 'assets/images/default.png';
	override function checkEmptyFrame()
	{
		if (_frame == null) loadGraphic(DEFAULT_IMAGE_PATH);
		else if (graphic != null && graphic.isDestroyed)
		{
			final width = this.width;
			final height = this.height;

			loadGraphic(DEFAULT_IMAGE_PATH);

			this.width = width;
			this.height = height;
		}
	}
}