typedef ObjectAnimation =
{
    var name:String;
    var tag:String;
}

class SObj
{
    var name:String;
    var layer:String;

    var object:Dynamic;
    var zIndex:Int;
    
    var graphic:String;

    var tryAntialias:Bool;

    var isAnimated:Bool;
    var animations:Array<ObjectAnimation>;

    var isBackdrop:Bool;
    var tileAxes:String;

    var isCharacter:Bool;

    public function new(_name:String = 'STAGE_EDITOR_TEMPLATE', _graphic:String, _object:Dynamic, _zIndex:Int = 0)
    {
        name = _name;
        layer = 'Elements';

        object = _object;
        zIndex = _zIndex;

        graphic = _graphic;

        tryAntialias = true;

        isAnimated = false;
        animations = [];

        isBackdrop = false;
        tileAxes = '';

        isCharacter = false;
    }

    public function getAnimationByName(name:String)
    {
        for (animation in animations) if (animation.name == name) return animation;
        return {name: 'NONE', tag: 'NONE'};
    }
}

class PanelVisibilityManager
{
    var show:Bool;
    var ui:Bool;
    var object:Bool;
    var value:Bool;
    var rim:Bool;
    var shadow:Bool;
    var animations:Bool;
    var picker:Bool;

    public function new(init:Bool)
    {
        show = init;
        ui = init;
        object = init;
        value = init;
        rim = init;
        shadow = init;
        animations = init;
        picker = init;
    }
}