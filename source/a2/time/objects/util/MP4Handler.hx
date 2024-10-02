package a2.time.objects.util;

import a2.time.states.LoadingState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.events.Event;
import vlc.VlcBitmap;

import openfl.display.Bitmap;
import openfl.display.BitmapData;

// old things that work are better than new things that sometimes work
// i refuse to work with flxvideo

class MP4Handler
{
	public var finishCallback:Void->Void;
	public var stateCallback:FlxState;
    public var fadeFinish:Bool = false;

	public var bitmap:VlcBitmap;

	public var sprite:FlxSprite;

	// needs to be here
	public function new() {}

	public function playMP4(path:String, ?repeat:Bool = false, ?outputTo:FlxSprite = null, ?isWindow:Bool = false, ?isFullscreen:Bool = false,
			?midSong:Bool = false, ?fadeFinished:Bool = false, ?customWidth:Float = 0, ?customHeight:Float = 0):Void
	{
		if (!midSong)
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
		}

		bitmap = new VlcBitmap();

		if (FlxG.stage.stageHeight / 9 < FlxG.stage.stageWidth / 16)
		{
			bitmap.set_width(FlxG.stage.stageHeight * (16 / 9));
			bitmap.set_height(FlxG.stage.stageHeight);
		}
		else
		{
			bitmap.set_width(FlxG.stage.stageWidth);
			bitmap.set_height(FlxG.stage.stageWidth / (16 / 9));
		}

		// easy video size
		if (customWidth > 0 && customHeight > 0)
		{
			bitmap.set_width(customWidth);
			bitmap.set_height(customHeight);
		}

		bitmap.onVideoReady = onVLCVideoReady;
		bitmap.onComplete = onVLCComplete;
		bitmap.onError = onVLCError;

		if (fadeFinished)
			fadeFinish = true;

		FlxG.stage.addEventListener(Event.ENTER_FRAME, update);

		if (repeat)
			bitmap.repeat = -1;
		else
			bitmap.repeat = 0;

		bitmap.inWindow = isWindow;
		bitmap.fullscreen = isFullscreen;

		FlxG.addChildBelowMouse(bitmap);
		bitmap.play(checkFile(path));

		if (outputTo != null)
		{
			// lol this is bad kek
			bitmap.alpha = 0;

			sprite = outputTo;
		}
	}

	function checkFile(fileName:String):String
	{
		var pDir = "";
		var appDir = "file:///" + Sys.getCwd() + "/";

		if (fileName.indexOf(":") == -1) // Not a path
			pDir = appDir;
		else if (fileName.indexOf("file://") == -1 || fileName.indexOf("http") == -1) // C:, D: etc? ..missing "file:///" ?
			pDir = "file:///";

		return pDir + fileName;
	}

	/////////////////////////////////////////////////////////////////////////////////////

	function onVLCVideoReady()
	{
		trace("video loaded!");

		if (sprite != null)
			sprite.loadGraphic(bitmap.bitmapData);
	}

	public function onVLCComplete()
	{
		if (bitmap.isDisposed)
			return;

		bitmap.stop();

		// Clean player, just in case! Actually no.
		if (fadeFinish)
			FlxG.camera.fade(FlxColor.BLACK, 0, false);
		
		trace('subscribe to [A2] on youtube @A2music');

		if (finishCallback != null)
			finishCallback();
		
		else if (stateCallback != null)
			LoadingState.loadAndSwitchState(stateCallback);

		bitmap.dispose();

		if (FlxG.game.contains(bitmap))
			FlxG.game.removeChild(bitmap);
	}

	public function kill()
	{
		bitmap.stop();

		if (finishCallback != null)
			finishCallback();

		bitmap.visible = false;
		bitmap.dispose();
	}

	function onVLCError()
	{
		if (finishCallback != null)
			finishCallback();
		
		else if (stateCallback != null)
			LoadingState.loadAndSwitchState(stateCallback);
	}

	// hey guys it's me [A2] i am video gaming
	public function pause()
	{
		bitmap.pause();

		// should hopefully stop audio from desyncing?
		//bitmap.seek(Std.parseFloat(Std.string(bitmap.getTime())));

		// didn't even need that fucking shit fuck this video
	}

	public function resume()
	{
		bitmap.resume();
	}

	var holdTime:Float = 0;
	function update(e:Event)
	{
		bitmap.volume = FlxG.sound.volume + 0.3; // shitty volume fix. then make it louder.

		if (FlxG.sound.volume <= 0.1)
			bitmap.volume = 0;
	}
}