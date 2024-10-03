package a2.time.objects.gameplay;

import a2.time.util.ClientPrefs;

import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

class ZoomAmounts
{
    public var game:Float = 0.03;
    public var hud:Float = 0.015;
    public var other:Float = 0;

    public function new () {}
}

class ZoomManager
{
    public var zooming:Bool = false;
    public var gameZooming:Bool = true;
    
    public var interval:Int = 4;

    public var mult:Float = 1;
    public var decay:Float = 1;

    public var amounts:ZoomAmounts = new ZoomAmounts();

    public function new()
    {
        zooming = ClientPrefs.data.camZooms;
    }
}

class CameraManager
{
    public var zoom:ZoomManager;
    public var defaultZoom:Float = 1;

    private var moving:Bool = true;
    public var speed:Float = 1.6;

    private var locked:Bool = false;

    public var desiredPos:FlxPoint;
    public var currentPos:FlxObject;

    public function new()
    {
        zoom = new ZoomManager();

        desiredPos = new FlxPoint(0, 0);
        currentPos = new FlxObject(0, 0);
    }

    public function update(dt:Float, playbackRate:Float)
    {
        if (moving)
        {
            var lerpVal:Float = 1 - Math.exp(-speed * dt * playbackRate * 3.5);
            currentPos.setPosition(FlxMath.lerp(currentPos.x, desiredPos.x, lerpVal), FlxMath.lerp(currentPos.y, desiredPos.y, lerpVal));
        }
    }

    // cam focus segment
    //
    private function focusOn(x:Float, y:Float)
    {
        if (!locked && moving)
            desiredPos.set(x, y);
    }

    private function lockTo(x:Float, y:Float)
    {
        unlock();
        focusOn(x, y);
        lock();
    }

    private function snapTo(x:Float, y:Float)
    {
        halt();
        currentPos.setPosition(x, y);
    
        trace("Make sure to run 'camManager.resume()' to resume normal camera movement!");
    }

    public function focusOnSprite(obj:FlxObject)
    {
        focusOn(obj.x, obj.y);
    }

    public function lockToSprite(obj:FlxObject)
    {
        lockTo(obj.x, obj.y);
    }

    public function snapToSprite(obj:FlxObject)
    {
        snapTo(obj.x, obj.y);
    }

    public function focusOnPos(x:Float, y:Float)
    {
        focusOn(x, y);
    }

    public function lockToPos(x:Float, y:Float)
    {
        lockTo(x, y);
    }

    public function snapToPos(x:Float, y:Float)
    {
        snapTo(x, y);
    }

    public function focusOnPoint(p:FlxPoint)
    {
        focusOn(p.x, p.y);
    }

    public function lockToPoint(p:FlxPoint)
    {
        lockTo(p.x, p.y);
    }

    public function snapToPoint(p:FlxPoint)
    {
        snapTo(p.x, p.y);
    }

    public function unlock()
    {
        // cleaner than having to set game.camManager.locked = false in a modchart
        // instead you can run game.camManager.unlock()
        // just makes more sense to me
        locked = false;
    }

    public function lock()
    {
        // adding this one to stay consistent lel
        locked = true;
    }
    //

    // movement stuff
    public function halt()
    {
        // i don't want to set camManager.moving directly
        // same reason as lock() and unlock(), just looks better
        moving = false;
    }

    public function resume()
    {
        // keep on keepin' on
        moving = true;
    }
    //
}