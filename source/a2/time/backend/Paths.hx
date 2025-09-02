package a2.time.backend;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

import haxe.io.Path;

import openfl.media.Sound;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

typedef FileReturnPayload =
{
    content:Dynamic,
    path:String
}

class Paths
{
    public static var VERBOSE:Bool = true;
	static function ptrace(val:String):Void
	{
		if (!VERBOSE) return;
		trace(val);
	}

    public static var mods:Dynamic = {}

    public static var WORKING_MOD_DIRECTORY:String = Main.MOD_NAME;

    public static inline var PNG_FILE_EXT:String = 'png';
    public static inline var OGG_FILE_EXT:String = 'ogg';
    public static inline var TTF_FILE_EXT:String = 'ttf';
    public static inline var OTF_FILE_EXT:String = 'otf';
    public static inline var HSCRIPT_FILE_EXT:String = 'hscript';
    public static inline var HX_FILE_EXT:String = 'hx';
    public static inline var FRAG_FILE_EXT:String = 'frag';
    public static inline var CSS_FILE_EXT:String = 'css';
    public static inline var UI_XML_FILE_EXT:String = 'uixml';
    public static inline var XML_FILE_EXT:String = 'xml';
    public static inline var JSON_FILE_EXT:String = 'json';
    public static inline var MP4_FILE_EXT:String = 'mp4';

    // should have a specific identifying string for this? but whatever
    public static inline var ATLAS_FRAMES:String = '';

    public static inline var SAME_NAME_CONVENTION:String = 'SAME_NAME_CONVENTION';
    public static inline var SONG_INST:String = 'SONG_INST';
    public static inline var SONG_VOCX:String = 'SONG_VOCX';

    public static function init():Void
    {
        registerPathMethods({
            name: 'module',
            dir: 'custom_modules',
            ext: HX_FILE_EXT
        }, {
            name: 'image',
            dir: 'images',
            ext: PNG_FILE_EXT
        }, {
            name: 'atlas',
            dir: 'images',
            ext: ATLAS_FRAMES
        }, {
            name: 'font',
            dir: 'fonts',
            // says ttf here, actually checks both
            ext: TTF_FILE_EXT
        }, {
            name: 'music',
            dir: 'music',
            ext: OGG_FILE_EXT
        }, {
            name: 'script',
            dir: 'scripts',
            ext: HSCRIPT_FILE_EXT
        }, {
            name: 'shader',
            dir: 'shaders',
            ext: FRAG_FILE_EXT
        }, {
            name: 'sound',
            dir: 'sounds',
            ext: OGG_FILE_EXT
        }, {
            name: 'video',
            dir: 'videos',
            ext: MP4_FILE_EXT
        });

        registerPathGroups(
            // example: `Paths.mods.character.image(['bf', 'icons'])`
            // example: `Paths.mods.character.atlas(['bf', 'bf-alt'])`
            PathGroupBuilder.buildPathGroup('character', 'characters', {
                name: 'image',
                ext: PNG_FILE_EXT
            }, {
                name: XML_FILE_EXT,
                ext: XML_FILE_EXT
            }, {
                name: JSON_FILE_EXT,
                ext: JSON_FILE_EXT
            }, {
                name: 'atlas',
                ext: ATLAS_FRAMES
            }, {
                name: 'script',
                ext: HSCRIPT_FILE_EXT
            }),

            // example: `Paths.mods.event.script(['Camera Flash'])`
            // example: `Paths.mods.event.atlas(['Jumpscare', 'spooky'])`
            PathGroupBuilder.buildPathGroup('event', 'custom_events', {
                name: 'script',
                dir: SAME_NAME_CONVENTION,
                ext: HSCRIPT_FILE_EXT
            }, {
                name: JSON_FILE_EXT,
                dir: SAME_NAME_CONVENTION,
                ext: JSON_FILE_EXT
            }, {
                name: 'image',
                ext: PNG_FILE_EXT
            }, {
                name: XML_FILE_EXT,
                ext: XML_FILE_EXT
            }, {
                name: 'atlas',
                ext: ATLAS_FRAMES
            }, {
                name: 'sound',
                ext: OGG_FILE_EXT
            }),

            // example: `Paths.mods.state.image(['options', 'left-arrow'])`
            // example: `Paths.mods.state.script(['MasterEditorMenu'])`
            PathGroupBuilder.buildPathGroup('state', 'custom_states', {
                name: 'script',
                ext: HSCRIPT_FILE_EXT
            }, {
                name: 'image',
                ext: PNG_FILE_EXT
            }, {
                name: XML_FILE_EXT,
                ext: XML_FILE_EXT
            }, {
                name: 'atlas',
                ext: ATLAS_FRAMES
            }, {
                name: 'sound',
                ext: OGG_FILE_EXT
            }),

            // example: `Paths.mods.substate.script(['BaseTransitionSubState'])`
            PathGroupBuilder.buildPathGroup('substate', 'custom_substates', {
                name: 'script',
                ext: HSCRIPT_FILE_EXT
            }, {
                name: 'image',
                ext: PNG_FILE_EXT
            }, {
                name: XML_FILE_EXT,
                ext: XML_FILE_EXT
            }, {
                name: 'atlas',
                ext: ATLAS_FRAMES
            }, {
                name: 'sound',
                ext: OGG_FILE_EXT
            }),

            PathGroupBuilder.buildPathGroup('strumskin', 'custom_strumskins', {
                name: JSON_FILE_EXT,
                dir: SAME_NAME_CONVENTION,
                ext: JSON_FILE_EXT
            }, {
                name: 'image',
                dir: SAME_NAME_CONVENTION,
                ext: PNG_FILE_EXT
            }, {
                name: XML_FILE_EXT,
                dir: SAME_NAME_CONVENTION,
                ext: XML_FILE_EXT
            }, {
                name: 'atlas',
                dir: SAME_NAME_CONVENTION,
                ext: ATLAS_FRAMES
            }),

            PathGroupBuilder.buildPathGroup('soundtray', 'custom_soundtrays', {
                name: 'image',
                ext: PNG_FILE_EXT
            }, {
                name: 'atlas',
                ext: ATLAS_FRAMES
            }, {
                name: 'script',
                ext: HSCRIPT_FILE_EXT
            }, {
                name: 'sound',
                ext: OGG_FILE_EXT
            }),

            PathGroupBuilder.buildPathGroup('song', 'songs', {
                name: 'chart',
                dir: SAME_NAME_CONVENTION,
                ext: JSON_FILE_EXT
            }, {
                name: 'inst',
                dir: SONG_INST,
                ext: OGG_FILE_EXT
            }, {
                name: 'voices',
                dir: SONG_VOCX,
                ext: OGG_FILE_EXT
            }, {
                name: 'script',
                ext: HSCRIPT_FILE_EXT 
            }, {
                name: 'image',
                ext: PNG_FILE_EXT
            }, {
                name: XML_FILE_EXT,
                ext: XML_FILE_EXT
            }, {
                name: 'atlas',
                ext: ATLAS_FRAMES
            }, {
                name: 'sound',
                ext: OGG_FILE_EXT
            }),

            PathGroupBuilder.buildPathGroup('stage', 'stages', {
                name: 'script',
                ext: HSCRIPT_FILE_EXT
            }, {
                name: 'image',
                ext: PNG_FILE_EXT
            }, {
                name: XML_FILE_EXT,
                ext: XML_FILE_EXT
            }, {
                name: 'atlas',
                ext: ATLAS_FRAMES
            }),

            PathGroupBuilder.buildPathGroup('ui', 'ui', {
                name: XML_FILE_EXT,
                ext: UI_XML_FILE_EXT
            }, {
                name: CSS_FILE_EXT,
                ext: CSS_FILE_EXT
            })
        );
    }

	public static function folder(key:String, dir:String = Main.MOD_NAME):String
	{
		if (!FileSystem.exists('mods/$dir'))
		{
			ptrace('mod directory "$dir" not found');
			return null;
		}

		var checks = key.split('/');
		var cur = 'mods/$dir';
		for (check in checks)
		{
			cur += '/$check';
			if (!FileSystem.exists(cur))
			{
				ptrace('folder "$key" not found in path "$cur"');
				return null;
			}
		}

		return cur;
	}

    public static function path(_folder:String, key:String, ext:String, dir:String = Main.MOD_NAME):String
    {
        var __folder = folder(_folder, dir);

        switch(ext)
        {
            case UI_XML_FILE_EXT: ext = 'xml';
        }

		var check = '$__folder/$key.$ext';
		if (!FileSystem.exists(check) && ext != ATLAS_FRAMES)
		{
			ptrace('$ext file "$key" not found in directory "$__folder"');
			return null;
		}

        return check;
    }

	public static function file(_folder:String, key:String, ext:String, dir:String = Main.MOD_NAME, ?returnPath:Bool = false):FileReturnPayload
	{
		var _path:String = path(_folder, key, ext, dir);

        if (returnPath) return { content: null, path: _path }

        switch(ext)
        {
            case PNG_FILE_EXT: return Assets.cacheGraphic(_path);
            case OGG_FILE_EXT: return Assets.cacheSound(_path);
            case ATLAS_FRAMES: return Assets.cacheAtlas(_path);
            case MP4_FILE_EXT: return Assets.cacheVideo(_path);

            default: return Assets.cache(_path);
        }
	}

    public static var directories(get, never):Array<String>;
    public static function get_directories():Array<String> 
	{
		var list:Array<String> = [];

		for (_folder in FileSystem.readDirectory('mods/')) 
		{
			var _path = 'mods/$_folder';
			if (sys.FileSystem.isDirectory(_path) && !list.contains(_folder))
				list.push(_folder);
		}

		return list;
	}

    public static function registerPathGroups(...args:PathGroup):Void
    {
        for (group in args)
        {
            Reflect.setProperty(Paths.mods, group.name, group);
            trace('Registered Path Group "${group.name}"');
        }
    }

    public static function registerPathMethods(...args:PathGroupMethod):Void
    {
        for (method in args)
        {
            var root:String = method.parent != null ? method.parent.root : method.dir;
            if (root == null) root = '';

            Reflect.setProperty(Paths.mods, method.name, PathGroupBuilder.buildPathMethod(root, method));
            trace('Registered Path Method "${method.name}"');
        }
    }

    public static function openInFileExplorer(path:String):Void
    {
        var fullPath:String = Path.join([Sys.getCwd(), path]).replace('/', '\\');
        Sys.command('explorer "${fullPath}"');
    }
}

typedef PathGroup = 
{
    var name:String;
    var root:String;
    var folder:PathGroupFolderMethod;
}

typedef PathGroupMethod =
{
    var name:String;
    @:optional var dir:String;
    var ext:String;
    @:optional var parent:PathGroup;
}

typedef PathGroupFolderMethod = String->String->String;
typedef PathMethod = Array<String>->String->Bool->Paths.FileReturnPayload;

class PathGroupBuilder
{
    public static inline function buildPathGroup(_name:String, _root:String, ...args:PathGroupMethod)
    {
        var group:PathGroup = {
            name: _name,
            root: _root,
            folder: function(key:String = '', ?dir:String = Main.MOD_NAME):String { return Paths.folder('$_root/$key', dir); }
        }

        for (method in args) Reflect.setProperty(group, method.name, buildPathMethod(_root, method));

        return group;
    }

    public static inline function buildPathMethod(_root:String, method:PathGroupMethod):PathMethod
    {
        return function(keys:Array<String>, ?dir:String = Main.MOD_NAME, ?returnPath:Bool = false):Paths.FileReturnPayload
        { 
            var path:String = '$_root/';

            if (keys.length <= 0) return {path: Paths.folder(path, dir), content: null}
            
            var key:String = keys[keys.length - 1];
            keys.remove(key);

            if (method.dir == Paths.SAME_NAME_CONVENTION || 
                method.dir == Paths.SONG_INST || 
                method.dir == Paths.SONG_VOCX) {
                path += '$key/';
            }

            switch(method.dir)
            {
                default: 
                    for (_key in keys) path += '/$_key';

                case Paths.SONG_INST: key = 'inst';
                case Paths.SONG_VOCX: key = 'voices';
            }

            switch(method.ext)
            {
                case Paths.TTF_FILE_EXT: 
                    return Paths.file(path, key, Paths.TTF_FILE_EXT, dir, returnPath) ?? 
                           Paths.file(path, key, Paths.OTF_FILE_EXT, dir, returnPath);

                default: return Paths.file(path, key, method.ext, dir, returnPath);
            }
        }
    }
}