package a2.time.objects.ui;

import a2.time.backend.managers.HscriptManager;
import a2.time.backend.managers.SoundTrayManager;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.ui.FlxSoundTray;

class CustomSoundTray extends FlxSoundTray
{
    public static var instance:CustomSoundTray;
    public var customTray:HscriptManager;

    public static var children:Array<Dynamic> = [];

    public function new()
    {
        super();
        instance = this;

        removeChildren();
    }

    public static function resetSoundTray():Void
    {
        instance.removeChildren();

        instance.customTray = new HscriptManager((interp:hscript.InterpEx) ->
        {
            interp.variables.set('add', (child:Dynamic) ->
            {
                FlxG.state.add(cast child);
                CustomSoundTray.children.push(child);
            });
            interp.variables.set('parent', instance);
        });

        if (!SoundTrayManager.soundTrayExists) return;

        instance.customTray.addScriptFromPath(SoundTrayManager.soundTrayPath);
    }

    override public function update(dt:Float):Void instance.customTray.callAll('update', [dt]);

    override public function showAnim(volume:Float, ?sound:FlxSoundAsset, duration:Float = 1, label:String = ''):Void
    {
        FlxG.save.data.timeVolume = volume;
        instance.customTray.callAll('onVolumeChanged', [Math.floor(volume * 10) / 10, silent]);
    }

    public static function removeObjects():Void for (child in CustomSoundTray.children) FlxG.state.remove(cast child);
    public static function addObjects():Void
    {
        for (child in CustomSoundTray.children) FlxG.state.add(cast child);
        
        if (instance.customTray == null) return;
        instance.customTray.callAll('create', []);
    }
}