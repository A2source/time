package a2.time.openfl.display;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import flixel.math.FlxMath;
import flixel.FlxSprite;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;
	public var currentMem:Float;

	public var highestMem:Float;
	public static var showMem:Bool=true;
	public static var showFPS:Bool=true;
	public static var showMemPeak:Bool=true;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	var lastUpdate:Float = 0;
	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 12, color);
		width = 1280;
		height = 720;

		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		highestMem = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			__enterFrame(Timer.stamp()-lastUpdate);
		});
		#end
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(d:Float):Void
	{
		currentTime = Timer.stamp();

		var dt = currentTime-lastUpdate;
		lastUpdate = currentTime;

		times.push(currentTime);

		while(times[0]<currentTime-1)
			times.shift();

		var currentCount = times.length;
		currentFPS = currentCount;
    	currentMem = Math.abs(Math.round(System.totalMemory / (1e+6)));

		if(currentMem > highestMem)
			highestMem = currentMem;

		if (currentCount != cacheCount)
		{
			text = "";
			if(showFPS)
				text += "FPS: " + currentFPS + "\n";

			// hey all, [A2] here
			// i added the gb detection because
			// seeing 2k mb on the screen playing desperation pisses me off
			// smaller number is more impressive
			// also looks cleaner
			// and is more obv what it actually means
			// like compare "Memory: 2000 MB" to "Memory: 2 GB"
			// which is more obvious? which one OBVIOUSLY tells you that you have an issue with mem usage in desperation?
			// the second one ofc
			// so yea i'm happy with this
			// + i saw other mods do it so i knew it was possible and i really wanted to do it for a while lol

			if(showMem)
			{
				var desiredMem = currentMem;
				var suffix = " MB\n";
				if (desiredMem > 1000)
				{
					desiredMem = FlxMath.roundDecimal(desiredMem / 1000, 2);
					suffix = " GB\n";
				}
				text += "Mem: " + desiredMem + suffix;
			}

			if(showMemPeak)
			{
				var desiredMem = highestMem;
				var suffix = " MB\n";
				if (desiredMem > 1000)
				{
					desiredMem = FlxMath.roundDecimal(desiredMem / 1000, 2);
					suffix = " GB\n";
				}
				text += "Peak Mem: " + desiredMem + suffix;
			}

			cacheCount = currentCount;
		}
	}
}