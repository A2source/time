package a2.time.util;

import animateatlas.AtlasFrameMaker;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import haxe.xml.Access;
import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;

import openfl.Lib;

import flash.media.Sound;

using StringTools;

class Paths
{
	public static var VERBOSE:Bool = true;
	static function pathsTrace(val:String)
	{
		if (!VERBOSE)
			return;

		trace(val);
	}

	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static var ignoremods:Array<String> = 
	[
		'characters',
		'custom_events',
		'custom_notetypes',
		'custom_states',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'fonts',
		'scripts',
	];

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];
	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() 
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys()) 
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key)
				&& !dumpExclusions.contains(key)) 
			{
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) 
				{
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory(?cleanUnused:Bool = false) 
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj == null || currentTrackedAssets.exists(key))
				continue;

			openfl.Assets.cache.removeBitmapData(key);
			FlxG.bitmap._cache.remove(key);
			obj.destroy();
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys()) 
		{
			if (!localTrackedAssets.contains(key)
			&& !dumpExclusions.contains(key) && key != null) {
				//pathsTrace('test: ' + dumpExclusions, key);
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear('songs');
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') 
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		var returnPath = '$library:assets/$library/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('$key.xml', TEXT, library);
	}

	inline static public function imgXml(key:String, ?library:String)
	{
		return getPath('images/$key.xml', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}
	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}
	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String):Any
	{
		var songKey:String = '$song/Voices';
		var voices = returnSound('songs', songKey);
		return voices;
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String = '$song/Inst';
		var inst = returnSound('songs', songKey);
		return inst;
	}

	inline static public function image(key:String, ?library:String):FlxGraphic
	{
		// streamlined the assets process more
		var returnAsset:FlxGraphic = returnGraphic(key, library);
		return returnAsset;
	}

	// better version so you can get an image from all of the build and not just images
	inline static public function getImage(key:String):FlxGraphic
	{
		// streamlined the assets process more
		var returnAsset:FlxGraphic = timeGraphic(key); // ill make this not shit later
		return returnAsset;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		#end
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		return OpenFlAssets.exists(getPath(key, type));
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function returnGraphic(key:String, ?library:String, folder:String = 'images/') 
	{
		var path = getPath('images/$key.png', IMAGE, library);
		//pathsTrace(path);
		if (OpenFlAssets.exists(path, IMAGE)) 
		{
			if(!currentTrackedAssets.exists(path)) 
			{
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
			
		pathsTrace('oh no it ("images/$key.png")\'s returning null NOOOO');

		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:String, key:String, ?library:String) 
	{

		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// pathsTrace(gottenPath);
		if(!currentTrackedSounds.exists(gottenPath))
		{
			var folder:String = '';
			if(path == 'songs') folder = 'songs:';

			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		}

		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	/*
	 * Mods Folder
	 */

	inline static public function found(file:String)
	{
		return file != null && file != '';
	}

	static public function mods(key:String, modDirectory:String = Main.MOD_NAME)
	{
		if (!FileSystem.exists('mods/$modDirectory'))
		{
			pathsTrace('mod directory "$modDirectory" not found'/*, alertTitleString*/);
			return null;
		}

		var checks = key.split('/');
		var curCheck = 'mods/$modDirectory';
		for (check in checks)
		{
			curCheck += '/$check';
			if (!FileSystem.exists(curCheck))
			{
				pathsTrace('folder "$key" not found in path "$curCheck"'/*, alertTitleString*/);
				return null;
			}
		}

		return curCheck;
	}

	static public function modsFile(folder:String, key:String, ext:String, modDirectory:String = Main.MOD_NAME)
	{
		var folder = mods(folder, modDirectory);

		var check = '$folder/$key.$ext';
		if (!FileSystem.exists(check))
		{
			pathsTrace('$ext file "$key" not found in directory "$folder"'/*, alertTitleString*/);
			return null;
		}

		return check;
	}

	static public function forEachMod(key:String)
	{
		for (mod in getModDirectories())
		{
			var check = mods(key, mod);
			if (check != null)
				return check;
		}

		return null;
	}

	static public function modsFont(key:String, modDirectory:String = Main.MOD_NAME) 
	{
		var check = '';
		for (extension in ['ttf', 'otf'])
			check = found(check) ? check : modsFile('fonts', key, extension, modDirectory);

		return check;
	}

	static public function modsJson(folder:String, key:String, modDirectory:String = Main.MOD_NAME) 
	{
		return modsFile(folder, key, 'json', modDirectory);
	}

	static public function modsVideo(key:String, modDirectory:String = Main.MOD_NAME) 
	{
		return modsFile('videos', key, 'mp4', modDirectory);
	}

	static public function modsSound(key:String, modDirectory:String = Main.MOD_NAME) 
	{
		return modsFile('sounds', key, 'ogg', modDirectory);
	}

	static public function modsMusic(key:String, modDirectory:String = Main.MOD_NAME) 
	{
		return modsFile('music', key, 'ogg', modDirectory);
	}

	static public function getModsSound(key:String, modDirectory:String = Main.MOD_NAME) 
	{
		return returnModsSound('sounds', key, modDirectory);
	}

	static public function getModsMusic(key:String, modDirectory:String = Main.MOD_NAME) 
	{
		return returnModsSound('music', key, modDirectory);
	}

	static public function modsImage(key:String, modDirectory:String = Main.MOD_NAME) 
	{
		return modsFile('images', key, 'png', modDirectory);
	}

	static public function modsXml(key:String, modDirectory:String = Main.MOD_NAME) 
	{
		return modsFile('images', key, 'xml', modDirectory);
	}

	static public function modsTxt(folder:String, key:String, modDirectory:String = Main.MOD_NAME) 
	{
		return modsFile(folder, key, 'txt', modDirectory);
	}

	static public function modsSparrow(folder:String, key:String, modDirectory:String = Main.MOD_NAME):FlxAtlasFrames
	{
		var png = modsFile(folder, key, 'png', modDirectory);
		var imageLoaded:FlxGraphic = timeImage(png);

		var xml = modsFile(folder, key, 'xml', modDirectory);
		
		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : timeImage(png)), (found(xml) ? File.getContent(xml) : file(xml)));
	}

	/*
	 * Song Stuff
	 */

	public static function songFolder(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return mods('songs/$key', modDirectory);
	}

	public static function songFile(song:String, key:String, ext:String, modDirectory:String = Main.MOD_NAME)
	{
		return modsFile('songs/$song', key, ext, modDirectory);
	}

	static public function modsSongJson(song:String, key:String, modDirectory:String = Main.MOD_NAME) 
	{
		return songFile(song, key, 'json', modDirectory);
	}

	public static function modsVoices(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return returnModsSound('songs/$key', 'voices', modDirectory);
	}

	public static function modsInst(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return returnModsSound('songs/$key', 'inst', modDirectory);
	}

	public static function returnModsSound(path:String, key:String, modDirectory:String = Main.MOD_NAME, library:String = null) 
	{
		var file:String = modsFile(path, key, 'ogg', modDirectory);

		if (file == null)
			return new Sound();

		if(FileSystem.exists(file)) 
		{
			if(!currentTrackedSounds.exists(file)) {
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}

		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// pathsTrace(gottenPath);
		if(!currentTrackedSounds.exists(gottenPath))
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));

		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	/*
	 * Stage related stuff
	 */

	static public function stageFolder(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return mods('stages/$key', modDirectory);
	}

	static public function stageFile(stage:String, key:String, ext:String, modDirectory:String = Main.MOD_NAME)
	{
		return modsFile('stages/$stage', key, ext, modDirectory);
	}

	static public function stageImage(stage:String, key:String, modDirectory:String = Main.MOD_NAME)
	{
		return stageFile(stage, key, 'png', modDirectory);
	}

	static public function stageXml(stage:String, key:String, modDirectory:String = Main.MOD_NAME)
	{
		return stageFile(stage, key, 'xml', modDirectory);
	}

	static public function stageJson(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return stageFile(key, key, 'json', modDirectory);
	}

	static public function stageScript(stage:String, key:String, modDirectory:String = Main.MOD_NAME)
	{
		return stageFile(stage, key, 'hscript', modDirectory);
	}

	/*
	 * Character stuff
	 */

	static public function charFolder(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return mods('characters/$key', modDirectory);
	}

	static public function charFile(name:String, key:String, ext:String, modDirectory:String = Main.MOD_NAME)
	{
		return modsFile('characters/$name', key, ext, modDirectory);
	}

	static public function charImage(name:String, key:String, modDirectory:String = Main.MOD_NAME)
	{
		return charFile(name, key, 'png', modDirectory);
	}

	static public function charXml(name:String, key:String, modDirectory:String = Main.MOD_NAME)
	{
		return charFile(name, key, 'xml', modDirectory);
	}

	static public function charJson(name:String, key:String, modDirectory:String = Main.MOD_NAME)
	{
		return charFile(name, key, 'json', modDirectory);
	}

	static public function getCharSparrow(name:String, key:String, modDirectory:String = Main.MOD_NAME):FlxAtlasFrames
	{
		return modsSparrow('characters/$name', key, modDirectory);
	}

	/*
	 * Event Stuff
	 */

	public static function eventFile(key:String, ext:String, modDirectory:String = Main.MOD_NAME)
	{
		return modsFile('custom_events', key, ext, modDirectory);
	}

	public static function eventScript(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return eventFile(key, 'hscript', modDirectory);
	}
	
	public static function eventTxt(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return eventFile(key, 'txt', modDirectory);
	}

	/*
	 * Custom Notes
	 */

	public static function noteFile(key:String, ext:String, modDirectory:String = Main.MOD_NAME)
	{
		return modsFile('custom_notetypes', key, ext, modDirectory);
	}

	public static function noteScript(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return noteFile(key, 'hscript', modDirectory);
	}

	public static function noteJson(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return noteFile(key, 'json', modDirectory);
	}

	/*
	 * Custom States
	 */

	static public function customStateFolder(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return mods('custom_states/$key', modDirectory);
	}

	static public function customState(key:String, modDirectory:String = Main.MOD_NAME)
	{
		return modsFile('custom_states', key, 'hscript', modDirectory);
	}

	static public function fromState(state:String, key:String, ext:String, modDirectory:String = Main.MOD_NAME)
	{
		return modsFile('custom_states/$state', key, ext, modDirectory);
	}

	static public function stateImage(state:String, key:String, modDirectory:String = Main.MOD_NAME)
	{
		return fromState(state, key, 'png', modDirectory);
	}

	static public function stateXml(state:String, key:String, modDirectory:String = Main.MOD_NAME)
	{
		return fromState(state, key, 'xml', modDirectory);
	}

	static public function stateSound(state:String, key:String, modDirectory:String = Main.MOD_NAME)
	{
		return returnModsSound(customStateFolder(state, modDirectory), key, modDirectory);
	}

	/*
	 * our util
	 */

	public static function timeGraphic(key:String) 
	{
		if(FileSystem.exists(key)) 
		{
			if(!currentTrackedAssets.exists(key)) 
			{
				var newBitmap:BitmapData = BitmapData.fromFile(key);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, key);
				newGraphic.persist = true;
				currentTrackedAssets.set(key, newGraphic);
			}

			localTrackedAssets.push(key);
			// pathsTrace(key);
			return currentTrackedAssets.get(key);
		}

		pathsTrace('graphic "$key" is returning null'/*, alertTitleString*/);
		return null;
	}

	public static function timeImage(key:String)
	{
		return timeGraphic(key);
	}

	/* Goes unused for now

	inline static public function modsShaderFragment(key:String, ?library:String)
	{
		return mods('shaders/'+key+'.frag');
	}
	inline static public function modsShaderVertex(key:String, ?library:String)
	{
		return mods('shaders/'+key+'.vert');
	}
	inline static public function modsAchievements(key:String) {
		return mods('achievements/' + key + '.json');
	}*/

	public static var globalMods:Array<String> = [];

	static public function getGlobalMods()
		return globalMods;

	static public function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path))
		{
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path = Paths.mods(folder + '/pack.json');
					if(FileSystem.exists(path)) {
						try{
							var rawJson:String = File.getContent(path);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if(global)globalMods.push(dat[0]);
							}
						} catch(e:Dynamic){
							pathsTrace(e);
						}
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String> 
	{
		var list:Array<String> = [];

		for (folder in FileSystem.readDirectory('mods/')) 
		{
			var path = 'mods/$folder';
			if (sys.FileSystem.isDirectory(path) && !ignoremods.contains(folder) && !list.contains(folder))
				list.push(folder);
		}

		return list;
	}
}