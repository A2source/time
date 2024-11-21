package a2.time.objects.ui;

import flixel.FlxG;

import openfl.display.Bitmap;
import openfl.display.BitmapData;

import haxe.Timer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
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

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends Sprite
{
	public var currentFPS(default, null):Int;
	public var currentMem:Float;

	public var highestMem:Float;
	public static var showMem:Bool = true;
	public static var showFPS:Bool = true;
	public static var showMemPeak:Bool = true;

	private var cacheCount:Int;
	private var currentTime:Float;
	private var times:Array<Float>;

	var text:TextField;
	var bg:Bitmap;

	var lastUpdate:Float = 0;
	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		bg = new Bitmap(new BitmapData(1, 1, true, 0x80000000));
		addChild(bg);

		text = new TextField();

		text.multiline = true;
		text.autoSize = TextFieldAutoSize.LEFT;

		text.selectable = false;
		text.mouseEnabled = false;
		text.defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont('assets/fonts/pixel.otf').fontName, 8, color);
		addChild(text);
		
		currentFPS = 0;

		cacheCount = 0;
		currentTime = 0;
		highestMem = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			__enterFrame(Timer.stamp() - lastUpdate);
		});
		#end
	}

	var PADDING:Int = 4;
	private #if !flash override #end function __enterFrame(d:Float):Void
	{
		currentTime = Timer.stamp();

		var dt = currentTime - lastUpdate;
		lastUpdate = currentTime;

		times.push(currentTime);

		while(times[0] < currentTime - 1)
			times.shift();

		var currentCount = times.length;
		currentFPS = currentCount;
    	currentMem = Math.abs(Math.round(System.totalMemory / (1e+6)));

		if(currentMem > highestMem)
			highestMem = currentMem;

		if (currentCount != cacheCount)
		{
			text.text = '';
			if(showFPS)
				text.text += "FPS: " + currentFPS + "\n";

			if(showMem)
			{
				var desiredMem = currentMem;
				var suffix = " MB\n";
				if (desiredMem > 1000)
				{
					desiredMem = FlxMath.roundDecimal(desiredMem / 1000, 2);
					suffix = " GB\n";
				}
				text.text += "Mem: " + desiredMem + suffix;
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
				text.text += "Peak Mem: " + desiredMem + suffix;
			}

			cacheCount = currentCount;
		}

		text.x = Std.int(PADDING / 2);

		bg.scaleX = text.textWidth + PADDING * 2;
		bg.scaleY = text.textHeight + PADDING;
	}
}