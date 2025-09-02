package a2.time.backend;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import a2.time.states.IntroState;

class ClientPrefs
{
	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_up'		=> [W, UP],
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_right'	=> [D, RIGHT],
		
		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],
		
		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];

	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],
		
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(controller:Null<Bool> = null) //Null = both, False = Keyboard, True = Controller
	{
		if(controller != true)
			for (key in keyBinds.keys())
				if(defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());

		if(controller != false)
			for (button in gamepadBinds.keys())
				if(defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while(gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
	}

	public static function init()
	{
		register('downscroll', false);
		register('middlescroll', false);
		register('showFPS', true);
		register('flashing', true);
		register('autoPause', true);
		register('antialiasing', true);
		register('lowQuality', false);
		register('shaders', true);
		register('framerate', 60);
		register('camZooms', true);
		register('hideHud', false);
		register('offset', 0.0);

		register('ghostTapping', true);
		register('allowReset', true);
		register('hpAlpha', 1);
		register('hitsoundVolume', 0.0);
		register('gameplaySettings', {
			scrollspeed: 1.0,
			scrolltype: 'multiplicative',
			songspeed: 1.0,
			healthgain: 1.0,
			healthloss: 1.0,
			instakill: false,
			practice: false,
			botplay: false
		});

		register('ratingOffset', 0.0);
		register('sickWindow', 45.0);
		register('goodWindow', 90.0);
		register('badWindow', 135.0);
		register('safeFrames', 10.0);
		register('noteTailWindow', -10.0);

		register('discordRPC', true);

		loadDefaultKeys();

		save();
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
	}

	public static function register(name:String, value:Dynamic):Dynamic
	{
		if (Reflect.field(FlxG.save.data, name) == null) 
		{
			Reflect.setProperty(FlxG.save.data, name, value);
			return value;
		}

		return get(name);
	}

	public static function get(name:String):Dynamic return Reflect.getProperty(FlxG.save.data, name);
	public static function set(name:String, value:Dynamic):Void Reflect.setProperty(FlxG.save.data, name, value);
	public static function save():Void FlxG.save.flush();

	// more in-depth saving
	public static function saveClientPrefs() 
	{
		ClientPrefs.save();

		// Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', savePath);
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.flush();
		trace('Prefs Saved!');
	}

	public static function loadPrefs() 
	{
		if(Main.fpsVar != null) Main.fpsVar.visible = get('showFPS');

		var fps:Null<Int> = get('framerate');
		#if (!html5 && !switch)
		FlxG.autoPause = ClientPrefs.get('autoPause');

		if (fps == null) {
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			set('framerate',  Std.int(FlxMath.bound(refreshRate, 60, 240)));
		}
		#end

		if (fps > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = fps;
			FlxG.drawFramerate = fps;
		}
		else
		{
			FlxG.drawFramerate = fps;
			FlxG.updateFramerate = fps;
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		// #if DISCORD_ALLOWED
		// DiscordClient.check();
		// #end

		// controls on a separate save file
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', savePath);
		if(save != null)
		{
			if(save.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
				for (control => keys in loadedControls)
					if(keyBinds.exists(control)) keyBinds.set(control, keys);
			}
			if(save.data.gamepad != null)
			{
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
				for (control => keys in loadedControls)
					if(gamepadBinds.exists(control)) gamepadBinds.set(control, keys);
			}
			reloadVolumeKeys();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		return  get('gameplaySettings').get(name);
	}

	public static function reloadVolumeKeys()
	{
		IntroState.muteKeys = keyBinds.get('volume_mute').copy();
		IntroState.volumeDownKeys = keyBinds.get('volume_down').copy();
		IntroState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		FlxG.sound.muteKeys = turnOn ? IntroState.muteKeys : [];
		FlxG.sound.volumeDownKeys = turnOn ? IntroState.volumeDownKeys : [];
		FlxG.sound.volumeUpKeys = turnOn ? IntroState.volumeUpKeys : [];
	}

	public static var SAVE_PATH_FOLDER:String = '[A2]';

	public static var savePath(get, never):String;
	public static function get_savePath():String 
	{
		#if (flixel < "5.0.0")
		return SAVE_PATH_FOLDER;
		#else 
		@:privateAccess
		return '${FlxG.stage.application.meta.get('company')}/${FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		#end
	}
}