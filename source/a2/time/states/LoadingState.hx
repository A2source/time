package a2.time.states;

import a2.time.backend.Assets;
import a2.time.backend.Paths;
import a2.time.backend.Paths.PathMethod;
import a2.time.backend.managers.HscriptManager;
import a2.time.backend.managers.LoadingScreenManager;
import a2.time.backend.managers.StateTransitionManager;

import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxTimer;

import haxe.MainLoop;
import haxe.ui.containers.windows.WindowManager;

import hscript.InterpEx;

import sys.thread.Thread;

typedef LoadingBatch = 
{
	@:optional var name:String;
	@:optional var dir:String;

	var jobs:Array<LoadingJob>;
}

typedef LoadingJob =
{
	var method:PathMethod;
	var keys:Array<String>;
}

typedef StateOptions =
{
	var state:String;
	@:optional var dir:String;
}

typedef LoadingThreadMessage =
{
	var job:LoadingJob;
	var batchDirectory:String;
}

class LoadingState extends MusicBeatState
{
	/**
	  * LOADING SCREEN
	**/

	private static var targetStateOptions:StateOptions;
	public static var leavingLoadingScreen:Bool = false;

	public static function initializeLoadingScreen(batches:Array<LoadingBatch>, _targetStateOptions:StateOptions):Void
	{
		allBatches = batches;
		targetStateOptions = _targetStateOptions;

		switchState(new LoadingState());
	}

	private function injectInterp(interp:InterpEx)
	{
		interp.variables.set('add', instance.add);
		interp.variables.set('remove', instance.remove);
		interp.variables.set('insert', instance.insert);
        interp.variables.set('replace', instance.replace);

        interp.variables.set('controls', instance.controls);
	}

	private var loadingScreen:HscriptManager;

	private static var allBatches:Array<LoadingBatch> = [];
	private var batchesToLoad:Array<LoadingBatch> = [];

	private var totalJobs:Int = 0;

	private var currentJobOnThread:Int = -1;
	private var currentJob:Int = 0;

	private var currentBatch:LoadingBatch;
	private var currentBatchJob:Int = 0;

	private var loadingThread:Thread;
	private var killThread:Bool = false;

	private var currentBatchDirectory:String = Main.MOD_NAME;

	public static var instance:LoadingState;

	override public function create():Void
	{
		super.create();
		instance = this;

		Assets.clearKeys();

		for (batch in allBatches)
		{
			batchesToLoad.push(batch);
			for (job in batch.jobs) totalJobs++;
		}
		currentBatch = batchesToLoad[0];

		trace('Batches to load: ${batchesToLoad.length}');
		trace('Total Jobs: $totalJobs');

		loadingScreen = new HscriptManager(injectInterp);
		loadingScreen.addScriptFromPath(LoadingScreenManager.loadingScreenPath);

		updateInterp();
		loadingScreen.callAll('create', []);

		loadingThread = Thread.create(() -> 
		{
			while (true)
			{
				if (killThread) return;

				var message:LoadingThreadMessage = Thread.readMessage(false);
				if (message == null) continue;
				if (currentJob == currentJobOnThread) continue;

				message.job.method(message.job.keys, message.batchDirectory, false);
				currentJobOnThread = currentJob;
			}
		});
	}

	public override function update(dt:Float):Void 
	{
		super.update(dt);
		loadingScreen.callAll('update', [dt]);

		updateInterp();
		updateJobs();
	}

	private function updateJobs():Void
	{
		if (currentJob > totalJobs) return;

		if (currentJob != currentJobOnThread)
		{
			loadingThread.sendMessage({
				job: currentBatch.jobs[currentBatchJob],
				batchDirectory: currentBatchDirectory
			});
		}
		else checkBatchAndStartNewJob();
	}

	private function updateInterp():Void
	{
		loadingScreen.setAll('currentBatch', currentBatch);
		loadingScreen.setAll('allBatches', allBatches);
		
		loadingScreen.setAll('currentBatchJob', killThread ? currentBatch.jobs.length : currentBatchJob);
		loadingScreen.setAll('currentJob', killThread ? totalJobs : currentJob);
		loadingScreen.setAll('totalJobs', totalJobs);
	}
	
	private function checkBatchAndStartNewJob():Void
	{
		currentBatchDirectory = Main.MOD_NAME;
		if (Reflect.hasField(currentBatch, 'dir')) currentBatchDirectory = currentBatch.dir;

		currentBatchJob++;
		if (currentBatchJob == currentBatch.jobs.length)
		{
			batchesToLoad.remove(currentBatch);
			if (batchesToLoad.length == 0)
			{
				completeLoading();
				return;
			}
			
			currentBatch = batchesToLoad[0];
			
			currentBatchJob = -1;
			checkBatchAndStartNewJob();

			return;
		}

		loadingScreen.callAll('onStartJob', [currentBatch.jobs[currentBatchJob], currentBatch]);
		currentJob++;
	}

	private function completeLoading()
	{
		trace('Loading complete!');

		killThread = true;

		var dir:String = Main.MOD_NAME;
		if (Reflect.hasField(targetStateOptions, 'dir')) dir = targetStateOptions.dir;

		updateInterp();

		leavingLoadingScreen = true;
		loadingScreen.callAll('onLoadingComplete', [targetStateOptions.state, dir]);
	}

	/**
	  * STATE SWITCHING
	**/

    public static function switchCustomState(name:String, dir:String = Main.MOD_NAME):Void
    {
        if (Paths.mods.state.script([name], dir).content != null)
        {
			CustomState.name = name;
			CustomState.dir = dir;

			if (BaseState.currentState is CustomState)
				@:privateAccess CustomState.instance.hscriptManager.callAll('onLeaveState', []);

            switchState(new CustomState());	
		}
		else
		{
			openfl.Lib.application.window.alert('Couldn\'t find custom state named "$name" in mod directory "$dir"', Main.ALERT_TITLE);

			CustomState.name = 'IntroState';
			CustomState.dir = Main.MOD_NAME;

            switchState(new CustomState());
		}
    }

	public static function resetHaxeUI()
	{
		WindowManager.instance.reset();
		WindowManager.instance.container = new haxe.ui.core.Component();
	}

	inline public static function switchState(target:FlxState):Void
	{
		StateTransitionManager.startTransition(() ->
		{
			resetHaxeUI();
			BaseState.currentState = target;

			FlxG.switchState(target);
		});
	}
}