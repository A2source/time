package a2.time.backend.managers;

import a2.time.backend.Assets;
import a2.time.backend.Paths;

import openfl.Lib;

import hscript.InterpEx;
import hscript.ParserEx;

import sys.io.File;
import sys.FileSystem;

using StringTools;

class HscriptManager
{
    private var states:Map<String, InterpEx> = [];

    private var injectCustomInterp:Dynamic = null;
	private var sortedKeys:Array<String>;

	private var useSorted:Bool = false;

	private var currentScript:String;

    public function new(?func:InterpEx->Void) injectCustomInterp = func;

    public static function fileIsValidHscript(file:String):Bool return file.endsWith('.${Paths.HSCRIPT_FILE_EXT}');

    public function addScript(scriptName:String, path:String, fileName:String, ext:String):InterpEx
    {
		var parser = new ParserEx();

        var fullPath = '$path/$fileName.$ext';
		var content:String = Assets.cache(fullPath).content;

        if (content == null)
        {
            Lib.application.window.alert('Hscript file "$fullPath" not found.', Main.ALERT_TITLE);
            return null;
        }

		var program = parser.parseString(content);

		var modDirectory:String = path.split('mods/')[1];
		modDirectory = modDirectory.split('/')[0];

		var interp = new InterpEx(scriptName, modDirectory);

		if (exists(scriptName)) scriptName += Date.now();

        if (injectCustomInterp != null) injectCustomInterp(interp);

		interp.execute(program);
		states.set(scriptName, interp);

		interp.nameInHscriptManager = scriptName;

		return interp;
	}

    public function addScriptFromPath(path:String, ?file:String = ''):InterpEx
	{
		if (path == null || file == null)
			return null;

		if (file != '')
		{
			if (fileIsValidHscript(file))
			{
				var fileName:String = file.split('.')[0];
				var ext:String = file.split('.')[1];

				return addScript(fileName, path, fileName, ext);
			}
		}
		else
		{
			if (fileIsValidHscript(path))
			{
				var split:Array<String> = path.split('/');

				var croppedPath = 'mods';
				for (i in 1...split.length - 1)
					croppedPath += '/${split[i]}';

				var fileStuff:Array<String> = split[split.length - 1].split('.');

				var fileName:String = fileStuff[0];
				var ext:String = fileStuff[1];

				return addScript(fileName, croppedPath, fileName, ext);
			}
		}

		return null;
	}

	public function addScriptsFromFolder(path:String)
	{
		if (!FileSystem.exists(path)) return;

		for (file in FileSystem.readDirectory(path))
			addScriptFromPath(path, file);
	}

    public function call(funcName:String, args:Array<Dynamic>, scriptName:String):Void
	{
        var curScript = states.get(scriptName);

		if (curScript == null)
			return;

		currentScript = scriptName;

		// if function doesn't exist
		if (!curScript.variables.exists(funcName)) 
			return;

		if (curScript.variables == null)
			return;

		var method = curScript.variables.get(funcName);
		if (method == null)
			return;

		switch(args.length) 
		{
			case 0:
				method();
			case 1:
				method(args[0]);
			case 2:
				method(args[0], args[1]);
			case 3:
				method(args[0], args[1], args[2]);
			case 4:
				method(args[0], args[1], args[2], args[3]);
			case 5:
				method(args[0], args[1], args[2], args[3], args[4]);
		}
	}
    
    public function callAll(funcName:String, args:Array<Dynamic>, ?exclude:Array<String>):Void
    {
		var doIt = exclude != null;

		if (useSorted)
		{
			for (script in sortedKeys)
				if (doIt ? !exclude.contains(script) : true)
					call(funcName, args, script);
		}
		else
		{
			for (script in states.keys())
				if (doIt ? !exclude.contains(script) : true)
					call(funcName, args, script);
		}
    }

    public function setVar(key:String, value:Dynamic, script:String):Void
    {
		currentScript = script;
		states.get(script).variables.set(key, value);
	}

	public function getVar(key:String, script:String):Dynamic 
    {
		currentScript = script;
		return states.get(script).variables.get(key);
	}

	public function setAll(key:String, value:Dynamic):Void
    {
		if (useSorted)
		{
			for (script in sortedKeys)
				setVar(key, value, script);
		}
		else
		{
			for (script in states.keys())
				setVar(key, value, script);
		}
	}

	public function exists(key:String)
	{
		return states.get(key) != null;
	}

	// thank you for saving stage editor
	public function sortAlphabetically()
	{
		if (useSorted)
			return;

		sortedKeys = [for (key in states.keys()) key];
		sortedKeys.sort((a, b) -> { return a < b ? -1 : a == b ? 0 : 1; });

		useSorted = true;
	}

    public function toString():String
    {
        return '$states';
    }
}