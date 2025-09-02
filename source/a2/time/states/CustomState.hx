package a2.time.states;

import a2.time.backend.Assets;
import a2.time.backend.Paths;
import a2.time.substates.CustomSubState;
import a2.time.backend.managers.HscriptManager;
import a2.time.backend.managers.StateTransitionManager;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

import hscript.InterpEx;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;

import openfl.Lib;

using StringTools;

class CustomState extends MusicBeatState
{
	public static var instance:CustomState;

	public static var name:String;
	public static var dir:String;

	public var hscriptManager:HscriptManager;

	public static var mPos:{x:Float, y:Float} = {x: FlxG.width / 2, y: FlxG.height / 2}
	public static var tweening:Bool = false;

	function injectInterp(interp:InterpEx)
	{
		interp.variables.set('add', instance.add);
		interp.variables.set('remove', instance.remove);
		interp.variables.set('insert', instance.insert);
        interp.variables.set('replace', instance.replace);

        interp.variables.set('controls', BaseState.instance.controls);

		interp.variables.set('openCustomSubState', openCustomSubState);
		interp.variables.set('closeSubState', instance.closeSubState);
		interp.variables.set('persistentUpdate', instance.persistentUpdate);

		interp.variables.set('this', CustomState.instance);
        interp.variables.set('reset', resetCustomState);
	}

	public static function tweenMouse(x:Float, y:Float, ?camera:FlxCamera = null, ?time:Float = 0.5)
	{
		tweening = true;

		FlxTween.cancelTweensOf(mPos);
		FlxTween.tween(mPos, {x: x, y: y}, time, {ease: FlxEase.expoOut, onUpdate: (_)->
		{
			var desiredX:Float = mPos.x;
			var desiredY:Float = mPos.y;

			if (camera != null)
			{
				desiredX += (camera.scroll.x - camera.x);
				desiredY -= (camera.scroll.y - camera.y);
			}
			
			Lib.application.window.warpMouse(Std.int(desiredX), Std.int(desiredY));
		}, onComplete: (t)->
		{
			tweening = false;
		}});
	}

	override function create()
	{
		super.create();
		instance = this;

		CustomState.clearEventListeners();
		CustomState.addEventListeners();

		var path:String = Paths.mods.state.script([name], dir).path;

		trace('Creating new custom state "$name" from mod "$dir" ($path)');

		hscriptManager = new HscriptManager(injectInterp);
		hscriptManager.addScriptFromPath(path);

		@:privateAccess
		if (!LoadingState.leavingLoadingScreen)
		{
			for (script in hscriptManager.states.keys())
			{
				if (hscriptManager.getVar('load', script) == null) continue;

				hscriptManager.callAll('load', []);
				hscriptManager.states.clear();

				break;
			}

			hscriptManager.callAll('create', []);
		}
		else 
		{
			hscriptManager.callAll('create', []);
			LoadingState.leavingLoadingScreen = false;
		}

		StateTransitionManager.completeTransition();
	}

	public static function clearEventListeners()
	{
		Lib.application.window.onKeyDown.remove(CustomState.onKeyDown);
		Lib.application.window.onKeyUp.remove(CustomState.onKeyUp);
	}

	public static function addEventListeners()
	{
		Lib.application.window.onKeyDown.add(CustomState.onKeyDown);
		Lib.application.window.onKeyUp.add(CustomState.onKeyUp);
	}

	public static function callAll(name:String, args:Array<Dynamic>):Void
	{
		if (instance == null) return;
		instance.hscriptManager.callAll(name, args);
	}

	public static function onKeyDown(key:Int, modifiers:KeyModifier) 
		CustomState.instance.hscriptManager.callAll('onKeyDown', [key, modifiers]);
	
	public static function onKeyUp(key:Int, modifiers:KeyModifier) 
		CustomState.instance.hscriptManager.callAll('onKeyUp', [key, modifiers]);

	override function update(dt:Float)
	{
		super.update(dt);

		if (FlxG.mouse.justMoved && !tweening) FlxTween.cancelTweensOf(mPos);

		hscriptManager.callAll('update', [dt]);

		// reset the state
		if (FlxG.keys.justPressed.F1 && !this.blockInput) resetCustomState();
	}

	private static function resetCustomState() LoadingState.switchCustomState(name, dir);

	override function beatHit()
	{
		super.beatHit();
		hscriptManager.setAll('curBeat', curBeat);
		hscriptManager.callAll('beatHit', [curBeat]);
	}

	override function stepHit()
	{
		super.stepHit();
		hscriptManager.setAll('curStep', curStep);
		hscriptManager.callAll('stepHit', [curStep]);
	}

	public function openCustomSubState(_name:String, ?_dir:String = Main.MOD_NAME):CustomSubState
	{
		var sub:CustomSubState = new CustomSubState(_name, this, _dir);
		openSubState(sub);

		return sub;
	}

	override function closeSubState() 
	{
		super.closeSubState();
		hscriptManager.callAll('onCloseSubState', []);
	}

	override function onFocus()
	{
		super.onFocus();
		hscriptManager.callAll('onFocus', []);
	}

	override function onFocusLost()
	{
		super.onFocusLost();
		hscriptManager.callAll('onFocusLost', []);
	}
}