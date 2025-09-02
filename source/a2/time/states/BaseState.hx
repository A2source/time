package a2.time.states;

import a2.time.backend.managers.StateTransitionManager;
import a2.time.backend.managers.StateTransitionManager.TransitionPhase;
import a2.time.backend.Controls;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;

import haxe.ui.core.Screen;
import haxe.ui.focus.FocusManager;

class BaseState extends FlxState
{
    private var controls(get, never):Controls;
    inline function get_controls():Controls return Controls.instance;

	public var blockInput:Bool = false;

	public static var instance:BaseState;

	public static var currentState:FlxState;
	public static var currentSubState:FlxSubState;

	override function create() 
	{
		super.create();
		instance = this;

		FlxG.cameras.setDefaultDrawTarget(FlxG.camera, true);
        
        // custom states need to complete the state transition AFTER hscript create is called
        if (!(currentState is CustomState)) StateTransitionManager.completeTransition();
	}

	override function update(dt:Float)
	{
		super.update(dt);

		if (FocusManager.instance.focus != null || Screen.instance.hasSolidComponentUnderPoint(Screen.instance.currentMouseX, Screen.instance.currentMouseY))
		{
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];

			this.blockInput = true;
		}
		else
		{
			FlxG.sound.muteKeys = IntroState.muteKeys;
			FlxG.sound.volumeDownKeys = IntroState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = IntroState.volumeUpKeys;

			this.blockInput = false;
		}
	}

	public function unblockInput()
	{
		if (FocusManager.instance.focus == null) return;
		FocusManager.instance.focus.focus = false;

		// i unfocused but forgot to turn this off so the keys were still locked
		this.blockInput = false;
	}

	override public function openSubState(sub:FlxSubState):Void
	{
		super.openSubState(sub);
		currentSubState = sub;
	}

	override public function closeSubState():Void
	{
		super.closeSubState();
		currentSubState = null;
	}
}