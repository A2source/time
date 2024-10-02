package a2.time.substates;

import a2.time.states.CustomState;
import a2.time.util.Paths;
import a2.time.util.HscriptManager;

import hscript.Interp;

class CustomSubState extends MusicBeatSubstate
{
	public static var instance:CustomSubState;

	private var stateName:String;
	private var modDirectory:String;
    private var parentState:CustomState;

	public var hscriptManager:HscriptManager;

    function injectInterp(interp:Interp)
	{
		interp.variables.set('add', instance.add);
		interp.variables.set('remove', instance.remove);
		interp.variables.set('insert', instance.insert);
        interp.variables.set('replace', instance.replace);
        interp.variables.set('close', instance.close);

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
    
    function onClose()
    {
        hscriptManager.callAll('onClose', []);

		if (parentState != null)
        	@:privateAccess parentState.hscriptManager.callAll('onCloseSubState', []);
    }

	override function update(elapsed:Float)
	{
		super.update(elapsed);
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