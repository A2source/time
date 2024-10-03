package a2.time.util;

import openfl.Lib;

import hscript.Interp;
import hscript.ParserEx;

import sys.io.File;
import sys.FileSystem;

import a2.time.states.CustomState;
import a2.time.util.Paths;

using StringTools;

class HscriptManager
{
    private var states:Map<String, Interp> = [];

    private var injectCustomInterp:Dynamic = null;

    public function new(func:Dynamic)
    {
        injectCustomInterp = func;
    }

    public static function fileIsValidHscript(file:String):Bool
	{
		// what the sigma!
		return (file.endsWith('.hscript') || file.endsWith('.hxs') || file.endsWith('.skibidi'));
	}

    public function addScript(scriptName:String, path:String, fileName:String, ext:String)
    {
		var parser = new ParserEx();

        var fullPath = '$path/$fileName.$ext';
        var check = FileSystem.exists(fullPath);
        if (!check)
        {
            Lib.application.window.alert('Hscript file "$fullPath" not found.', Main.ALERT_TITLE);
            return;
        }

		var program = parser.parseString(File.getContent(fullPath));

		var modDirectory:String = path.split('mods/')[1];
		modDirectory = modDirectory.split('/')[0];

		var interp = CustomState.getBasicInterp('$modDirectory/$fileName');

		if (exists(scriptName))
			scriptName += Date.now();

        if (injectCustomInterp != null)
            injectCustomInterp(interp);

		interp.execute(program);
		states.set(scriptName, interp);
	}

    public function addScriptFromPath(path:String, ?file:String = '')
	{
		if (path == null || file == null)
			return;

		if (file != '')
		{
			if (fileIsValidHscript(file))
			{
				var fileName:String = file.split('.')[0];
				var ext:String = file.split('.')[1];

				addScript(fileName, path, fileName, ext);
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

				addScript(fileName, croppedPath, fileName, ext);
			}
		}
	}

	public function addScriptsFromFolder(path:String)
	{
		if (!FileSystem.exists(path))
			return;

		for (file in FileSystem.readDirectory(path))
			addScriptFromPath(path, file);
	}

    public function call(funcName:String, args:Array<Dynamic>, scriptName:String)
	{
        var curScript = states.get(scriptName);

		if (curScript == null)
			return;

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
    
    public function callAll(funcName:String, args:Array<Dynamic>)
    {
        for (script in states.keys())
            call(funcName, args, script);
    }

    public function setVar(name:String, value:Dynamic, scriptName:String) 
    {
		states.get(scriptName).variables.set(name, value);
	}

	public function getVar(name:String, scriptName:String):Dynamic 
    {
		return states.get(scriptName).variables.get(name);
	}

	public function setAll(name:String, value:Dynamic) 
    {
		for (script in states.keys())
			setVar(name, value, script);
	}

	public function exists(name:String)
	{
		return states.get(name) != null;
	}

    public function toString():String
    {
        return '$states';
    }
}