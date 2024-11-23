package a2.time.substates;

import a2.time.states.CustomState;
import a2.time.Paths;
import a2.time.objects.managers.HscriptManager;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import hscript.Interp;

import openfl.Lib;

class CustomSubState extends MusicBeatSubstate
{
	public static var instance:CustomSubState;

	private var stateName:String;
	private var modDirectory:String;
    private var parentState:CustomState;

	public var hscriptManager:HscriptManager;

	public static var mPos:{x:Float, y:Float} = {x: FlxG.width / 2, y: FlxG.height / 2}
	public static var tweening:Bool = false;

    function injectInterp(interp:Interp)
	{
		interp.variables.set('add', instance.add);
		interp.variables.set('remove', instance.remove);
		interp.variables.set('insert', instance.insert);
        interp.variables.set('replace', instance.replace);
        interp.variables.set('close', instance.close);

		interp.variables.set('tweening', CustomSubState.tweening);
		interp.variables.set('mPos', CustomSubState.mPos);
		interp.variables.set('tweenMouse', CustomSubState.tweenMouse);

        interp.variables.set('parent', parentState);
	}

    public function new(name:String, parent:CustomState, modDir:String = Main.MOD_NAME)
    {
        super();

        stateName = name;
        modDirectory = modDir;
        parentState = parent;

        instance = this;

		hscriptManager = new HscriptManager(injectInterp);
		hscriptManager.addScriptFromPath(Paths.customState(stateName, modDirectory));
        hscriptManager.setAll('parentState', parentState);

		closeCallback = onClose;
    }

    override function create()
    {
        super.create();

		hscriptManager.callAll('create', []);

		if (parentState != null)
        	@:privateAccess parentState.hscriptManager.callAll('onOpenSubState', []);
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
				desiredY += (camera.scroll.y - camera.y);
			}
			
			Lib.application.window.warpMouse(Std.int(desiredX), Std.int(desiredY));
		}, onComplete: (t)->
		{
			tweening = false;
		}});
	}
    
    function onClose()
    {
        hscriptManager.callAll('onClose', []);

		if (parentState != null)
        	@:privateAccess parentState.hscriptManager.callAll('onCloseSubState', []);
    }

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.mouse.justMoved && !tweening) FlxTween.cancelTweensOf(mPos);

		hscriptManager.callAll('update', [elapsed]);
	}

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
		hscriptManager.callAll("stepHit", [curStep]);
	}
}