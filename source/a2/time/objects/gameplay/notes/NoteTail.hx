package a2.time.objects.gameplay.notes;

import flixel.FlxSprite;

import openfl.geom.Rectangle;

class NoteTail extends FlxSprite
{
    public var parentNote:Note;
    public var parentStrum:StrumNote;

    public function new(_parentNote:Note)
    {
        super();

        parentNote = _parentNote;
        parentStrum = _parentNote.parentStrum;

        antialiasing = _parentNote.antialiasing;
    }

    public function render():Void
	{
		var notePos:Float = Math.abs(parentNote.calculateDistance(parentNote.ms));
		var tailCapPos:Float = Math.abs(parentNote.calculateDistance(parentNote.ms + parentNote.l));

		var tailLengthPx:Int = Math.floor(tailCapPos - notePos);
		var tailBodyLength:Int = tailLengthPx - parentStrum.tailCapHeight;

		makeGraphic(parentStrum.tailBodyWidth, tailBodyLength, 0x00000000, true);

		var sampleHeight:Int = parentStrum.tailBodyHeight - parentStrum.tailRenderer.cutoff;

		var drawPoint:Int = 0;
		while(drawPoint < height)
		{
			var bodyRect:Rectangle = new Rectangle(0, drawPoint, parentStrum.tailBodyFrame.frame.width, parentStrum.tailBodyFrame.frame.height);
			graphic.bitmap.setPixels(bodyRect, parentStrum.tailBodyPixels);
			drawPoint += sampleHeight;
		}

		var capRect:Rectangle = new Rectangle(0, height - parentStrum.tailCapFrame.frame.height, parentStrum.tailBodyFrame.frame.width, parentStrum.tailCapFrame.frame.height);
		graphic.bitmap.setPixels(capRect, parentStrum.tailCapPixels);

		origin.set(width / 2, 0);
		antialiasing = antialiasing;

		if (parentStrum.flipTail) parentNote.tailAngleOffset = 180;
	}
}