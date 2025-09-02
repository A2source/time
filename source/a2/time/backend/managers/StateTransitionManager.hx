package a2.time.backend.managers;

import a2.time.backend.Paths;
import a2.time.backend.Paths.FileReturnPayload;
import a2.time.substates.CustomSubState;

import flixel.FlxG;
import flixel.FlxState;

enum TransitionPhase
{
    PRE_EVERYTHING;
    TRANSITION_IN;
    TRANSITION_OUT;
}

class StateTransitionManager
{
    public static var WORKING_STATE_TRANSITION:String = '';
    public static var WORKING_MOD_DIRECTORY:String = Main.MOD_NAME;

    public static var transitionExists(get, never):Bool;
    public static function get_transitionExists():Bool 
    {
        if (WORKING_STATE_TRANSITION == null) return false;
        if (WORKING_STATE_TRANSITION == '') return false;
        if (WORKING_MOD_DIRECTORY == null) return false;
        if (WORKING_MOD_DIRECTORY == '') return false;

        if (transitionStateContent == null) return false;

        return true;
    }

    public static function registerStateTransition(name:String, dir:String = Main.MOD_NAME)
    {
        WORKING_STATE_TRANSITION = name;
        WORKING_MOD_DIRECTORY = dir;

        trace('Set working State Transition to "$name"! ($dir)');
    }

    // wrapper for using paths
    public static var transitionState(get, never):FileReturnPayload;
    public static function get_transitionState():FileReturnPayload 
    {
        Paths.VERBOSE = false;
        var payload:FileReturnPayload = Paths.mods.substate.script([WORKING_STATE_TRANSITION], WORKING_MOD_DIRECTORY);
        Paths.VERBOSE = true;
        
        return payload;
    }

    public static var transitionStateContent(get, never):String;
    public static function get_transitionStateContent():String return transitionState.content;

    public static var transitionStatePath(get, never):String;
    public static function get_transitionStatePath():String return transitionState.path;

    private static var currentStateTransition:CustomSubState;

    private static function openTransitionSubState():Void
    {
        currentStateTransition = new CustomSubState(WORKING_STATE_TRANSITION, null, WORKING_MOD_DIRECTORY);
        FlxG.state.openSubState(currentStateTransition);
    }

    private static var callback:Void->Void;
    private static var phase:TransitionPhase = PRE_EVERYTHING;
    public static function startTransition(_callback:Void->Void):Void
    {
        if (transitionStateContent == null)
        {
            phase = PRE_EVERYTHING;
            _callback();

            return;
        }

        phase = TRANSITION_IN;

        callback = _callback;
        openTransitionSubState();
    }

    public static function runCallback():Void
    {
        if (phase != TRANSITION_IN) return;
        
        phase = TRANSITION_OUT;
        callback();
    }

    // i'm so happy for them :face_holding_back_tears:
    public static function completeTransition():Void
    {
        if (phase != TRANSITION_OUT) return;
        openTransitionSubState();
    }

    public static function close():Void
    {
        phase = PRE_EVERYTHING;

        if (currentStateTransition != null) currentStateTransition.close();
        currentStateTransition = null;

        callback = null;
    }
}