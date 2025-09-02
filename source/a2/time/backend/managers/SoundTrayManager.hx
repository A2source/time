package a2.time.backend.managers;

import a2.time.backend.Paths;
import a2.time.backend.Paths.FileReturnPayload;

import a2.time.objects.ui.CustomSoundTray;

class SoundTrayManager
{
    public static var WORKING_SOUND_TRAY:String = '';
    public static var WORKING_MOD_DIRECTORY:String = Main.MOD_NAME;

    public static var soundTrayExists(get, never):Bool;
    public static function get_soundTrayExists():Bool 
    {
        if (WORKING_SOUND_TRAY == null) return false;
        if (WORKING_SOUND_TRAY == '') return false;
        if (WORKING_MOD_DIRECTORY == null) return false;
        if (WORKING_MOD_DIRECTORY == '') return false;

        if (soundTrayContent == null) return false;

        return true;
    }

    public static function registerSoundTray(name:String, dir:String = Main.MOD_NAME)
    {
        WORKING_SOUND_TRAY = name;
        WORKING_MOD_DIRECTORY = dir;

        for (child in CustomSoundTray.children) child.destroy();
        CustomSoundTray.children.resize(0);

        CustomSoundTray.resetSoundTray();

        trace('Set working Sound Tray to "$name"! ($dir)');
    }

    public static var soundTray(get, never):FileReturnPayload;
    public static function get_soundTray():FileReturnPayload 
    {
        Paths.VERBOSE = false;
        var payload:FileReturnPayload = Paths.mods.soundtray.script([WORKING_SOUND_TRAY], WORKING_MOD_DIRECTORY);
        Paths.VERBOSE = true;
        
        return payload;
    }

    public static var soundTrayContent(get, never):String;
    public static function get_soundTrayContent():String return soundTray.content;

    public static var soundTrayPath(get, never):String;
    public static function get_soundTrayPath():String return soundTray.path;
}