package a2.time.backend.managers;

import a2.time.objects.song.Conductor;
import a2.time.backend.ClientPrefs;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;

import openfl.ui.Mouse;

class ManagerCamera
{
    public var cam:FlxCamera;
    public var name:String;
    public var isDefault:Bool = false;

    public var follow:Bool = false;

    public var defaultZoom:Float = 1;
    public var zooms:Bool = true;

    private var manager:CameraManager;

    public var i:Int = -1;

    public var bumpAmt:Float = 0;

    public function new(_manager:CameraManager, _name:String, ?_follow:Bool = false, ?_bgColor:Int = 0x00000000)
    {
        manager = _manager;

        name = _name;
        follow = _follow;

        cam = new FlxCamera();
        cam.bgColor = _bgColor;
    }

    public function toString():String return '(Name: $name | Follow: $follow | Zooms: $zooms | Is Default: $isDefault)';
}

class ZoomManager
{
    public var zooming:Bool = true;
    public var defaultDoesZooming:Bool = true;
    
    public var interval:Int = 4;

    public var speed:Float = 40;

    public function new() zooming = ClientPrefs.get('camZooms');
}

typedef CameraInputData =
{
    var name:String;
    var follow:Bool;
    @:optional var bumpAmt:Float;
    @:optional var bgColor:Int;
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

    public var cams:Array<ManagerCamera> = [];
    public var inEditor:Bool = false;
    private var followCam:FlxCamera;

    public function new(_cams:Array<CameraInputData>, ?defaultIndex:Int = 0)
    {
        zoom = new ZoomManager();

        desiredPos = new FlxPoint(0, 0);
        currentPos = new FlxObject(0, 0);
        
        var camsToAdd:Array<ManagerCamera> = [];
        for (i in 0..._cams.length)
        {
            var data = _cams[i];
            var cam:ManagerCamera = new ManagerCamera(this, data.name, data.follow, data.bgColor != null ? data.bgColor : 0x00000000);

            if (data.bumpAmt != null) cam.bumpAmt = data.bumpAmt;
            else cam.bumpAmt = 0;

            cam.i = i;
            if (cam.follow)
            {
                if (followCam == null) followCam = cam.cam;
                cam.cam.follow(currentPos, LOCKON, 1);
		        cam.cam.zoom = defaultZoom;
            }

            cams.push(cam);
        }

        var defaultCam:ManagerCamera = cams[defaultIndex];
        FlxG.cameras.reset(defaultCam.cam);
        FlxG.camera = defaultCam.cam;
        defaultCam.isDefault = true;

        for (cam in cams) 
        {
            if (cam.isDefault) continue;
            
            if (cam.i < defaultIndex) FlxG.cameras.insert(cam.cam, cam.i, false);
            else FlxG.cameras.add(cam.cam, false);
        }
    }

    public function update(dt:Float):Void
    {
        if (!moving) return;

        if (inEditor) updateMouseControl(dt);
                
        var expValue:Float = -speed * dt * 3.5;
        if (!inEditor) expValue *= Conductor.timescale;

        var lerpVal:Float = 1 - Math.exp(expValue);
        currentPos.setPosition(FlxMath.lerp(currentPos.x, desiredPos.x, lerpVal), FlxMath.lerp(currentPos.y, desiredPos.y, lerpVal));

        expValue = dt * -zoom.speed * 3;
        if (!inEditor) expValue *= Conductor.timescale;

        var zoomVal:Float = 1 - Math.exp(expValue);
        for (cam in cams) 
        {
            if (!zoom.zooming) break;
            if (!cam.zooms) continue;
            if (cam.isDefault && !zoom.defaultDoesZooming) continue;

            if (!cam.follow) 
            {
                cam.cam.zoom = FlxMath.lerp(cam.defaultZoom, cam.cam.zoom, zoomVal);
                continue;
            }

            cam.cam.zoom = FlxMath.lerp(defaultZoom, cam.cam.zoom, zoomVal);
        }
    }

    public var disableXControl:Bool = false;
    public var disableYControl:Bool = false;

    public static var CAM_ZOOM_AMT = 1;

    public var maxZoom:Float = -1; 
    public var minZoom:Float = -1;
    private function updateMouseControl(dt:Float):Void
    {
        if (a2.time.states.BaseState.instance.blockInput) return;

        // if you have camZooms turned off editor cams wont zoom at all lol
        // fix for that
        zoom.zooming = true;

        var shift:Bool = FlxG.keys.pressed.SHIFT; 
        var alt:Bool = FlxG.keys.pressed.ALT;

        var xAmt:Float = FlxG.mouse.deltaX;
        var yAmt:Float = FlxG.mouse.deltaY;
        var zAmt:Float = CAM_ZOOM_AMT;

        if (shift) 
        { 
            if (!disableXControl) xAmt *= 2; 
            if (!disableYControl) yAmt *= 2; 
            zAmt *= 2; 
        }
        else if (alt) 
        { 
            if (!disableXControl) xAmt /= 2; 
            if (!disableYControl) yAmt /= 2; 
            zAmt /= 2; 
        }

        zoomCameraWithScroll(zAmt * 0.36);
        moveCameraWithMouse(xAmt, yAmt);
    }

    private function zoomCameraWithScroll(z:Float):Void
    {
        if (!FlxG.keys.pressed.CONTROL || FlxG.mouse.wheel == 0) return;

        defaultZoom += z * FlxG.mouse.wheel * defaultZoom;

        if (maxZoom != -1) if (defaultZoom >= maxZoom) defaultZoom = maxZoom;
        if (minZoom != -1) if (defaultZoom <= minZoom) defaultZoom = minZoom;
    }

    private var changeCursor:Bool = false;
    private function moveCameraWithMouse(x:Float, y:Float):Void
    {
        if (!FlxG.mouse.pressed)
        {
            if (changeCursor)
            {
                Mouse.cursor = lime.ui.MouseCursor.DEFAULT;
                changeCursor = false;
            }

            return;
        }
        else 
        {
            if (FlxG.mouse.justMoved)
            {
                Mouse.cursor = lime.ui.MouseCursor.MOVE;
                changeCursor = true;
            }
        }

        if (!FlxG.mouse.justMoved) return;
        if (FlxG.mouse.gameX < 0 || FlxG.mouse.gameX > FlxG.width || FlxG.mouse.gameY < 0 || FlxG.mouse.gameY > FlxG.height) return;

        var zoomTarget:Float = followCam != null ? followCam.zoom : FlxG.camera.zoom;
        
        if (!disableXControl) desiredPos.x -= x / zoomTarget;
        if (!disableYControl) desiredPos.y -= y / zoomTarget;
    }

    public function forEachCamera(callback:ManagerCamera->Void):Void for (cam in cams) callback(cam);
    public function getCameraByName(name:String):Null<ManagerCamera> 
    {
        for (cam in cams) if (cam.name == name) return cam;
        return null;
    }

    private function getMousePosition(cam:FlxCamera):{x:Float, y:Float}
    {
        return {
            x: cam.scroll.x + Main.halfWidth + (FlxG.mouse.viewX - Main.halfWidth) / cam.zoom,
            y: cam.scroll.y + Main.halfHeight + (FlxG.mouse.viewY - Main.halfHeight) / cam.zoom
        }
    }

    public function getMousePositionInCamera(name:String):{x:Float, y:Float} return getMousePosition(getCameraByName(name).cam);
    
    public var mousePosition(get, never):{x:Float, y:Float};
    public function get_mousePosition():{x:Float, y:Float} return getMousePosition(FlxG.camera);

    // cam focus segment
    //
    private function focusOn(x:Float, y:Float):Void if (!locked && moving) desiredPos.set(x, y);
    

    private function lockTo(x:Float, y:Float):Void
    {
        unlock();
        focusOn(x, y);
        lock();
    }

    private function snapTo(x:Float, y:Float):Void
    {
        halt();
        currentPos.setPosition(x, y);
    
        trace("Make sure to run 'camManager.resume()' to resume normal camera movement!");
    }

    public function focusOnSprite(obj:FlxObject):Void focusOn(obj.x, obj.y);
    public function lockToSprite(obj:FlxObject):Void lockTo(obj.x, obj.y);
    public function snapToSprite(obj:FlxObject):Void snapTo(obj.x, obj.y);

    public function focusOnPos(x:Float, y:Float):Void focusOn(x, y);
    public function lockToPos(x:Float, y:Float):Void lockTo(x, y);
    public function snapToPos(x:Float, y:Float):Void snapTo(x, y);

    public function focusOnPoint(p:FlxPoint):Void focusOn(p.x, p.y);
    public function lockToPoint(p:FlxPoint):Void lockTo(p.x, p.y);
    public function snapToPoint(p:FlxPoint):Void snapTo(p.x, p.y);

    public function unlock():Void
    {
        // cleaner than having to set game.camManager.locked = false in a modchart
        // instead you can run game.camManager.unlock()
        // just makes more sense to me
        locked = false;
    }

    public function lock():Void
    {
        // adding this one to stay consistent lel
        locked = true;
    }
    //

    // movement stuff
    public function halt():Void
    {
        // i don't want to set camManager.moving directly
        // same reason as lock() and unlock(), just looks better
        moving = false;
    }

    public function resume():Void
    {
        // keep on keepin' on
        moving = true;
    }
    //
}