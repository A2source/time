package a2.time.backend.managers;

import a2.time.states.CustomState;

import lime.ui.KeyModifier;
import lime.ui.KeyCode;

import openfl.Lib;
import openfl.events.Event;

typedef Action =
{
    // parent object that was affected
    parents:Array<Dynamic>,
    // variable of parent to access with Reflect.field
    // or whatever way you use it in custom behaviour
    targets:Array<Dynamic>,

    // value before action was performed
    prevValues:Array<Dynamic>,
    // current value
    values:Array<Dynamic>,

    // any extra data wishing to be passed through the event
    payload:Array<Dynamic>,

    // action type, to be undone and redone
    // access the undo/redo database with this id and perform the correct action
    type:String
}

typedef PendingAction =
{
    parents:Array<Dynamic>,
    targets:Array<Dynamic>,
    values:Array<Dynamic>,
    payload:Array<Dynamic>,
    type:String
}

typedef ActionBehaviour =
{
    undo:Action->Void,
    redo:Action->Void
}

// automatically tracks values
// on change, pushes to the actions list
typedef UndoTracker =
{
    parents:Array<Dynamic>,
    targets:Array<Dynamic>,
    values:Array<Dynamic>,
    trackers:Array<Dynamic>,

    payload:Array<Dynamic>,

    changedClause:UndoTracker->Bool,

    behaviourId:String,
    pendingActionId:String,

    timer:Int,
    started:Bool
}

class UndoManager
{
    public static var VERBOSE:Bool = false;

    private static var pendingActions:Map<String, PendingAction> = new Map();
    public static var actions:Array<Action> = [];

    public static var undos:Array<Action> = [];

    public static var lastAction(get, never):Action;
    public static function get_lastAction():Action
    {
        return UndoManager.actions[UndoManager.actions.length - 1];
    }

    public static var lastUndo(get, never):Action;
    public static function get_lastUndo():Action
    {
        return UndoManager.undos[UndoManager.undos.length - 1];
    }

    public static var behaviourMap:Map<String, ActionBehaviour> = new Map();

    // public tracker of if changes remain unsaved
    public static var unsaved:Bool = false;

    private static var trackers:Map<String, UndoTracker> = new Map();

    // begin registering a new action
    // eg. moving an object with your mouse, you begin action on initial mouse move and 
    // complete action when movement ceases
    public static function beginAction(parents:Array<Dynamic>, targets:Array<Dynamic>, payload:Array<Dynamic>, values:Array<Dynamic>, id:String, ?type:String):Void
    {
        pendingActions.set(id, {
            parents: parents, 
            targets: targets, 
            values: values, 
            payload: payload, 
            type: type == null ? id : type
        });
    }

    // complete registering new action
    public static function completeAction(values:Array<Dynamic>, payload:Array<Dynamic>, id:String):Void
    {
        var pending:PendingAction = pendingActions.get(id);
        if (pending == null)
        {
            trace('Pending Action with id "$id" not found.');
            return;
        }

        UndoManager.registerAction(pending.parents, pending.targets, pending.values, values, payload != [] ? payload : pending.payload, pending.type);
        pendingActions.remove(id);
    }

    public static function registerAction(parents:Array<Dynamic>, targets:Array<Dynamic>, prevValues:Array<Dynamic>, values:Array<Dynamic>, payload:Array<Dynamic>, type:String):Void
    {
        actions.push({
            parents: parents, 
            targets: targets, 
            prevValues: prevValues, 
            values: values,
            payload: payload,
            type: type
        });
    }

    private static var _savedUndoCount:Int = 0;
    public static function registerUndo(parents:Array<Dynamic>, targets:Array<Dynamic>, prevValues:Array<Dynamic>, values:Array<Dynamic>, payload:Array<Dynamic>, type:String):Void
    {
        undos.push({
            parents: parents,
            targets: targets,
            prevValues: prevValues, 
            values: values, 
            payload: payload,
            type: type
        });
    }

    public static function init():Void
    {
        UndoManager.fullClear();
        UndoManager.registerKeyListeners();

        var valueUndoRedo:Action->Void = (action:Action) ->
        { 
            for (i in 0...action.parents.length)
                Reflect.setProperty(action.parents[i], '${action.targets[i]}', action.prevValues[i]);
        }

        behaviourMap.set('VALUE', {
            undo: valueUndoRedo,
            redo: valueUndoRedo
        });
    }

    public static function registerKeyListeners():Void
    {
        Lib.application.window.onKeyDown.add(onKeyDown);
        Lib.application.window.onKeyUp.add(onKeyUp);
    }

    public static var UNDO_TIME_THRESHOLD:Int = 10;
    private static function enterFrame(e:Event):Void
    {
        @:privateAccess
        {
            for (key in UndoManager.trackers.keys())
            {
                var tracker:UndoTracker = UndoManager.trackers.get(key);

                var targets:Array<Dynamic> = cast tracker.targets;
                for (i in 0...tracker.parents.length)
                    tracker.values[i] = Reflect.getProperty(tracker.parents[i], tracker.targets[i]);
            }
        }
    }

    public static var performedThisFrame:Bool = false;
    private static function exitFrame(e:Event):Void
    {
        @:privateAccess
        {
            for (key in UndoManager.trackers.keys())
            {
                var tracker = UndoManager.trackers.get(key);

                if (tracker.timer > UNDO_TIME_THRESHOLD)
                {
                    var valuesCopy:Array<Dynamic> = [];
                    for (value in tracker.values)
                        valuesCopy.push(value);

                    UndoManager.completeAction(valuesCopy, tracker.payload, tracker.pendingActionId);
                    tracker.timer = 0;
                    tracker.started = false;

                    UndoManager.setUnsaved(true);
                    CustomState.callAll('onAction', []);

                    if (VERBOSE) trace('Completed action for tracking "${tracker.pendingActionId}"');
                }

                if (tracker.started)
                    tracker.timer++;

                var changed:Bool = false;
                for (i in 0...tracker.parents.length)
                {
                    if (changed || UndoManager.performedThisFrame) break;
                    changed = tracker.values[i] != tracker.trackers[i] && (tracker.changedClause != null ? tracker.changedClause(tracker) : true);
                }

                if (changed && tracker.started)
                    tracker.timer = 0;
                else if (changed && !tracker.started)
                {
                    var payloadCopy:Array<Dynamic> = [];
                    for (item in tracker.payload)
                        payloadCopy.push(item);

                    var valuesCopy:Array<Dynamic> = [];
                    for (value in tracker.trackers)
                        valuesCopy.push(value);

                    UndoManager.beginAction(tracker.parents, tracker.targets, payloadCopy, valuesCopy, tracker.behaviourId, tracker.pendingActionId);
                    tracker.timer = 0;
                    tracker.started = true;

                    if (VERBOSE) trace('Started action for tracking "${tracker.pendingActionId}"');
                }

                for (i in 0...tracker.parents.length)
                    tracker.trackers[i] = Reflect.getProperty(tracker.parents[i], tracker.targets[i]);
            }

            UndoManager.performedThisFrame = false;
        }
    }

    public static function registerTracking(parents:Array<Dynamic>, targets:Array<Dynamic>, payload:Array<Dynamic>, changedClause:UndoTracker->Bool, behaviourId:String, pendingActionId:String):Void
    {
        var values:Array<Dynamic> = [];
        for (i in 0...parents.length)
            values[i] = Reflect.getProperty(parents[i], targets[i]);

        var trackers:Array<Dynamic> = [];
        for (value in values)
            trackers.push(value);

        @:privateAccess UndoManager.trackers.set(pendingActionId, {
            parents: parents,
            targets: targets,
            values: values,
            trackers: trackers,

            payload: payload,

            changedClause: changedClause,

            behaviourId: behaviourId,
            pendingActionId: pendingActionId,

            timer: 0,
            started: false
        });
        trace('Set new tracking for action "$pendingActionId"');
    }

    public static function updateTrackingPayload(payload:Array<Dynamic>, pendingActionId:String):Void
    {
        trackers.get(pendingActionId).payload = payload;
    }

    public static function fullClear():Void
    {
        UndoManager.clear();
        Lib.application.window.onKeyDown.remove(onKeyDown);
        Lib.application.window.onKeyUp.remove(onKeyUp);
    }

    public static function clear():Void
    {
        UndoManager.clearQueues();

        UndoManager.unsaved = false;

        @:privateAccess 
        {
            UndoManager.didSave = false;
            UndoManager._savedUndoCount = 0;
        }
    }

    public static function clearQueues():Void
    {
        @:privateAccess UndoManager.pendingActions.clear();
        UndoManager.actions.resize(0);

        UndoManager.undos.resize(0);

        @:privateAccess UndoManager.trackers.clear();
    }

    private static var didSave:Bool = false;
    private static function onKeyDown(key:Int, modifiers:KeyModifier):Void
    {
        if (!modifiers.ctrlKey) return;

        switch(key)
        {
            case KeyCode.S: 
                if (didSave) return;
                didSave = true;

                UndoManager.performSave();

            case KeyCode.Z: UndoManager.performUndo();
            case KeyCode.Y: UndoManager.performRedo();
        }
    }

    private static function onKeyUp(key:Int, modifiers:KeyModifier):Void
    {
        switch(key)
        {
            case KeyCode.S: didSave = false;
        }
    }

    public static function setUnsaved(value:Bool):Void
    {
        UndoManager.unsaved = value;
        CustomState.callAll('onChangedSaved', [value]);
    }

    public static function performSave():Void
    {
        @:privateAccess UndoManager._savedUndoCount = UndoManager.actions.length;

        UndoManager.setUnsaved(false);
        CustomState.callAll('onSave', []);
    }

    public static function performUndo():Void
    {
        var lastAction:Action = UndoManager.lastAction;
        CustomState.callAll('preUndo', [lastAction]);

        if (UndoManager.actions.length < 1) return;

        var behaviour = UndoManager.validateBehaviour(lastAction.type);
        if (behaviour == null) return;

        @:privateAccess UndoManager.setUnsaved(UndoManager.actions.length != UndoManager._savedUndoCount);
        @:privateAccess UndoManager.performedThisFrame = true;

        behaviour.undo(lastAction);
        UndoManager.registerUndo(lastAction.parents, lastAction.targets, lastAction.values, lastAction.prevValues, lastAction.payload, lastAction.type);
        UndoManager.actions.remove(lastAction);

        CustomState.callAll('onUndo', [lastAction]);
    }
    
    public static function performRedo():Void
    {
        var lastUndo:Action = UndoManager.lastUndo;
        CustomState.callAll('preRedo', [lastUndo]);

        if (UndoManager.undos.length < 1) return;

        var behaviour = UndoManager.validateBehaviour(lastUndo.type);
        if (behaviour == null) return;

        @:privateAccess UndoManager.setUnsaved(UndoManager.actions.length != UndoManager._savedUndoCount);
        @:privateAccess UndoManager.performedThisFrame = true;

        behaviour.redo(lastUndo);
        UndoManager.registerAction(lastUndo.parents, lastUndo.targets, lastUndo.values, lastUndo.prevValues, lastUndo.payload, lastUndo.type);
        UndoManager.undos.remove(lastUndo);

        CustomState.callAll('onRedo', [lastUndo]);
    }

    public static function validateBehaviour(id:String):ActionBehaviour
    {
        var string:String = '';

        var behaviour:ActionBehaviour = behaviourMap.get(id);

        if (behaviour == null) string += 'Behaviour "$id" returned null.';
        if (behaviour.undo == null) string += 'Missing undo behaviour.';
        if (behaviour.redo == null) string += 'Missing redo behaviour.';
        if (string.length > 0) trace(string);

        return behaviour;
    }

    public static function registerBehaviour(id:String, undo:Action->Void, redo:Action->Void):Void
    {
        behaviourMap.set(id, {
            undo: undo,
            redo: redo
        });
    }
}