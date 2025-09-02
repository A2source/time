package a2.time.states;

import a2.time.backend.DiscordClient;
import a2.time.backend.Paths;
import a2.time.backend.ClientPrefs;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

import lime.app.Application;

class IntroState extends BaseState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	override public function create():Void
	{
		a2.time.backend.Assets.clearMemory(null);
		
		DiscordClient.instance.init();
		lime.app.Application.current.onExit.add((e) -> {
			DiscordClient.instance.shutdown();
		});
		
		super.create();

		FlxG.mouse.visible = false;
		FlxG.save.bind('time', '[A2]');

		ClientPrefs.loadPrefs();

		var manager = new a2.time.backend.managers.HscriptManager(null);
		manager.addScript('startup', 'mods/${Main.MOD_NAME}', 'onStartup', 'hscript');
		manager.callAll('create', []);
	}
}
