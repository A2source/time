package a2.time.backend.managers;

import a2.time.backend.Paths;
import a2.time.backend.Paths.FileReturnPayload;

class LoadingScreenManager
{
    public static var WORKING_LOADING_SCREEN:String = '';
    public static var WORKING_MOD_DIRECTORY:String = Main.MOD_NAME;

    public static var loadingScreenExists(get, never):Bool;
    public static function get_loadingScreenExists():Bool 
    {
        if (WORKING_LOADING_SCREEN == null) return false;
        if (WORKING_LOADING_SCREEN == '') return false;
        if (WORKING_MOD_DIRECTORY == null) return false;
        if (WORKING_MOD_DIRECTORY == '') return false;

        if (loadingScreenContent == null) return false;

        return true;
    }

    public static function registerLoadingScreen(name:String, dir:String = Main.MOD_NAME)
    {
        WORKING_LOADING_SCREEN = name;
        WORKING_MOD_DIRECTORY = dir;

        trace('Set working Loading Screen to "$name"! ($dir)');
    }

    // wrapper for using paths
    public static var loadingScreen(get, never):FileReturnPayload;
    public static function get_loadingScreen():FileReturnPayload 
    {
        Paths.VERBOSE = false;
        var payload:FileReturnPayload = Paths.mods.state.script([WORKING_LOADING_SCREEN], WORKING_MOD_DIRECTORY);
        Paths.VERBOSE = true;
        
        return payload;
    }

    public static var loadingScreenContent(get, never):String;
    public static function get_loadingScreenContent():String return loadingScreen.content;

    public static var loadingScreenPath(get, never):String;
    public static function get_loadingScreenPath():String return loadingScreen.path;
}