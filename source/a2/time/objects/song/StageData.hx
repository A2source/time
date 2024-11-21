package a2.time.objects.song;

import sys.io.File;
import sys.FileSystem;

import haxe.Json;
import haxe.format.JsonParser;
import a2.time.objects.song.Song;

import a2.time.Paths;

using StringTools;

typedef StageFile = 
{
	var defaultZoom:Float;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;
}

class StageData 
{
	public static function loadDirectory(SONG:SwagSong) 
	{
		var stage:String = '';
		if(SONG.stage != null) 
			stage = SONG.stage;

		else if(SONG.song != null) 
			stage = 'stage';

		var stageFile:StageFile = getStageFile(stage);
	}

	public static function getStageFile(stage:String):StageFile 
	{
		var rawJson:String = null;

		for (mod in Paths.getModDirectories())
		{
			var path:String = Paths.stageJson(stage, mod);

			if (path == null)
				continue;

			rawJson = File.getContent(path);
				
			return cast Json.parse(rawJson);
		}

		return null;
	}
}