package a2.time.backend;

import a2.time.backend.Paths.FileReturnPayload;
import a2.time.states.LoadingState;

import flixel.FlxG;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

import hxvlc.flixel.FlxInternalVideo as Video;

import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;

import openfl.Assets as OpenFLAssets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetCache;

#if sys
import sys.io.File;
#end

class Assets
{
    private static var exclusions:Array<String> = [];

    private static var graphicCache:Map<String, FlxGraphic> = [];
    private static var soundCache:Map<String, Sound> = [];
    private static var atlasCache:Map<String, FlxAtlasFrames> = [];
    private static var videoCache:Map<String, Video> = [];
    private static var generalCache:Map<String, String> = [];

    public static function init():Void
	{
        Paths.init();

		clearExclusions();

		FlxG.signals.preStateCreate.add(clearMemory);
		FlxG.signals.postStateSwitch.add(System.gc);
	}

    private static function clearExclusions():Void exclusions.resize(0);
    public static function registerExclusion(path:String):Void exclusions.push(path);

    public static function clearKeys():Void
    {
        graphicCache.clear();
        soundCache.clear();
        atlasCache.clear();
        videoCache.clear();
        generalCache.clear();
    }

    private static var tryingToLoad:Bool;
    private static var previousStateWasLoadingState:Bool;
    public static function clearMemory(state:Null<FlxState>):Void
    {
        tryingToLoad = previousStateWasLoadingState;
        previousStateWasLoadingState = state is LoadingState;

        if (tryingToLoad) return;

        var openflCache:AssetCache = cast(OpenFLAssets.cache, AssetCache);
        
		@:privateAccess for (key in FlxG.bitmap._cache.keys())
        {
            if (exclusions.contains(key)) continue;

			var graphic:FlxGraphic = FlxG.bitmap.get(key);
            
            @:privateAccess graphic.bitmap?.__texture?.dispose();
		    FlxG.bitmap.remove(graphic);
            graphic.destroy();

            graphicCache.remove(key);
        }
        for (key in openflCache.bitmapData.keys())
            if (!FlxG.bitmap.checkCache(key))
                openflCache.bitmapData.remove(key);

        graphicCache.clear();

		for (key in soundCache.keys())
        {
			if (exclusions.contains(key)) continue;
			
            OpenFLAssets.cache.clear(key);
            soundCache.get(key).close();
            soundCache.remove(key);
        }
        openflCache.sound.clear();

        for (key in atlasCache.keys())
        {
            if (exclusions.contains(key)) continue;

            atlasCache.get(key).destroy();
            atlasCache.remove(key);
        }

        for (key in videoCache.keys())
        {
            if (exclusions.contains(key)) return;

            var video:Video = videoCache.get(key);
            video.dispose();

            videoCache.remove(key);
        }

        for (key in generalCache.keys())
        {
            if (exclusions.contains(key)) continue;

            generalCache.remove(key);
        }

        openflCache.font.clear();
        
		@:privateAccess haxe.ui.ToolkitAssets.instance._fontCache?.clear();
		@:privateAccess haxe.ui.ToolkitAssets.instance._imageCache?.clear();
    }

    public static function getGraphic(path:String):FlxGraphic
    {
        var bitmap:BitmapData = BitmapData.fromFile(path);
		bitmap.disposeImage();

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, path, false);
		graphic.persist = true;

        return graphic;
    }

    public static function cacheGraphic(path:String):FileReturnPayload
    {
        if (path == null) return {path: null, content: null}
        if (graphicCache.exists(path)) return {path: path, content: graphicCache.get(path)}

        var graphic:FlxGraphic = getGraphic(path);
		graphicCache.set(path, graphic);

		return {path: path, content: graphicCache.get(path)};
    }

    public static function getSound(path:String, ?streamed:Bool = false):Sound
    {
        var sound:Sound;
        
        if (streamed) sound = Sound.fromAudioBuffer(AudioBuffer.fromVorbisFile(VorbisFile.fromFile(path))) 
        else sound = Sound.fromFile(path);

        return sound;
    }

    public static function cacheSound(path:String, ?streamed:Bool = false):FileReturnPayload
    {
        if (path == null) return {path: null, content: null}
        if (soundCache.exists(path)) return {path: path, content: soundCache.get(path)}

        var sound:Sound = getSound(path, streamed);
		soundCache.set(path, sound);

		return {path: path, content: soundCache.get(path)};
    }

    public static function getAtlas(path:String):FlxAtlasFrames
    {
        var image:FileReturnPayload = cacheGraphic('$path${Paths.PNG_FILE_EXT}');
        var xml:FileReturnPayload = cache('$path${Paths.XML_FILE_EXT}');

        return FlxAtlasFrames.fromSparrow(cast image.content, Xml.parse(xml.content));
    }

    public static function cacheAtlas(path:String):FileReturnPayload
    {
        if (path == null) return {path: null, content: null}
        if (atlasCache.exists(path)) return {path: path, content: atlasCache.get(path)}
        
        var atlas:FlxAtlasFrames = getAtlas(path);
        atlasCache.set(path, atlas);

        return {path: path, content: atlasCache.get(path)};
    }

    public static function getVideo(path:String):Video
    {
        var video:Video = new Video();
        video.load(path);

        return video;
    }

    public static function cacheVideo(path:String):FileReturnPayload
    {
        if (path == null) return {path: null, content: null}
        if (videoCache.exists(path)) return {path: path, content: videoCache.get(path)}
        
        var video:Video = getVideo(path);
        videoCache.set(path, video);

        return {path: path, content: videoCache.get(path)};
    }

    public static function get(path:String):String return File.getContent(path);

    public static function cache(path:String):FileReturnPayload
    {
        if (path == null) return {path: null, content: null}
        if (generalCache.exists(path)) return {path: path, content: generalCache.get(path)}

        var content:String = get(path);
        generalCache.set(path, content);

        return {path: path, content: generalCache.get(path)};
    }
}