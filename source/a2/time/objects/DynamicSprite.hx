package a2.time.objects;

import a2.time.objects.TimeSprite;
import a2.time.util.Paths;

class DynamicSprite extends TimeSprite 
{
    public var verbose:Bool = false;

    public function load(key:String, _animated:Bool = false, _width:Int = 0, _height:Int = 0, _unique:Bool = false, ?_key:String)
    {
        if (verbose)
            trace('loading graphic "$key"');

        return super.loadGraphic(Paths.timeImage(key), _animated, _width, _height, _unique, _key);
    }

    public function loadSparrow(folder:String, key:String, modDirectory:String = Main.MOD_NAME)
    {
        if (verbose)
            trace('loading sparrow "$folder/$key" from mod "$modDirectory"');

        frames = Paths.modsSparrow(folder, key, modDirectory);
        return this;
    }
}