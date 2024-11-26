package a2.time.states;

import a2.time.states.CustomState;
import a2.time.util.ClientPrefs;
import a2.time.util.Discord;
import a2.time.util.Discord.DiscordClient;
import a2.time.Paths;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import lime.app.Application;

class IntroState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	
	static var initialized:Bool = false;
	static public var soundExt:String = ".ogg";
	static public var firstTime = false;

	function togglePersistUpdate(toggle:Bool)
	{
		persistentUpdate = toggle;
	}

	public static function makeTransition()
	{
		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, 0xFF000000, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, 0xFF000000, 0.7, new FlxPoint(0, 1),
			{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
	}

	function getRandomObject(object:Dynamic):Array<Dynamic>
	{
		return (FlxG.random.getObject(object));
	}

	override public function create():Void
	{
		a2.time.Paths.clearStoredMemory();
		
		#if windows
		a2.time.util.Discord.DiscordClient.initialize();

		Application.current.onExit.add(function(exitCode)
		{
			a2.time.util.Discord.DiscordClient.shutdown();
		});
		#end
		
		super.create();

		FlxG.mouse.visible = false;

		FlxG.save.bind('time', '[A2]');

		ClientPrefs.loadPrefs();

		trace('should be running startup now.');

		var manager = new a2.time.objects.managers.HscriptManager(null);
		manager.addScript('startup', Paths.mods('', Main.MOD_NAME), 'onStartup', 'hscript');
		manager.callAll('create', []);
	}
}
