package a2.time.objects;

import a2.time.objects.TimeSprite;
import a2.time.backend.ClientPrefs;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;

class DynamicSprite extends TimeSprite 
{
    public var verbose:Bool = false;

    override public function new(x:Float = 0, y:Float = 0, ?simpleGraphic:Null<flixel.system.FlxAssets.FlxGraphicAsset>)
    {
        super(x, y, simpleGraphic);

        // this is heat
        antialiasing = ClientPrefs.get('antialiasing');
    }

    public function load(key:FlxGraphicAsset, _animated:Bool = false, _width:Int = 0, _height:Int = 0, _unique:Bool = false, ?_key:String)
    {
        super.loadGraphic(key, _animated, _width, _height, _unique, _key);
        return this;
    }

    public function loadAtlas(_frames:FlxAtlasFrames):DynamicSprite
    {
        frames = _frames;
        return this;
    }
}