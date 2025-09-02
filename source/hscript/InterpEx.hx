package hscript;

import a2.time.backend.Paths;
import a2.time.backend.Paths.FileReturnPayload;

import flixel.input.keyboard.FlxKey;

import hscript.Expr.ModuleDecl;

import openfl.display.BlendMode;

using StringTools;

@:access(hscript.ScriptClass)
@:access(hscript.AbstractScriptClass)
class InterpEx extends Interp 
{
    private var _proxy:AbstractScriptClass = null;
    private var dir:String;
    
    public function new(name:String, _dir:String, proxy:AbstractScriptClass = null) 
    {
        super(name);
        dir = _dir;

        _proxy = proxy;

        initBasicInterps();
    }
    
    private static var _scriptClassDescriptors:Map<String, ClassDeclEx> = new Map<String, ClassDeclEx>();
    
    private static function registerScriptClass(c:ClassDeclEx) {
        var name = c.name;
        if (c.pkg != null) {
            name = c.pkg.join(".") + "." + name;
        }
        _scriptClassDescriptors.set(name, c);
    }
    
    public static function findScriptClassDescriptor(name:String) {
        return _scriptClassDescriptors.get(name);
    }
    
    override function cnew(cl:String, args:Array<Dynamic>):Dynamic {
        if (_scriptClassDescriptors.exists(cl)) {
            var proxy:AbstractScriptClass = new ScriptClass(nameToLog, dir, _scriptClassDescriptors.get(cl), args);
            return proxy;
        } else if (_proxy != null) {
            if (_proxy._c.pkg != null) {
                var packagedClass = _proxy._c.pkg.join(".") + "." + cl;
                if (_scriptClassDescriptors.exists(packagedClass)) {
                    var proxy:AbstractScriptClass = new ScriptClass(nameToLog, dir, _scriptClassDescriptors.get(packagedClass), args);
                    return proxy;
                }
            }

            if (_proxy._c.imports != null && _proxy._c.imports.exists(cl)) {
                var importedClass = _proxy._c.imports.get(cl).join(".");
                if (_scriptClassDescriptors.exists(importedClass)) {
                    var proxy:AbstractScriptClass = new ScriptClass(nameToLog, dir, _scriptClassDescriptors.get(importedClass), args);
                    return proxy;
                }
                
                var c = Type.resolveClass(importedClass);
                if (c != null) {
                    return Type.createInstance(c, args);
                }
            }
        }
        return super.cnew(cl, args);
    }
    
    // override function assign( e1 : Expr, e2 : Expr ) : Dynamic {
    //     var v = expr(e2);
    //     switch ( Tools.expr(e1) ) {
    //         case EIdent(id):
    //             if (_proxy.superClass != null && Reflect.hasField(_proxy.superClass, id)) {
    //                 Reflect.setProperty(_proxy.superClass, id, v);
    //                 return v;
    //             }
    //         case _:    
    //     }
    //     return super.assign(e1, e2);
    // }
    
	override function fcall( o : Dynamic, f : String, args : Array<Dynamic> ) : Dynamic {
        if (Std.is(o, ScriptClass)) {
            _nextCallObject = null;
            var proxy:ScriptClass = cast(o, ScriptClass);
            return proxy.callFunction(f, args);
        }
		return super.fcall(o, f, args);
	}

	override function call( o : Dynamic, f : Dynamic, args : Array<Dynamic> ) : Dynamic {
        // TODO: not sure if this make sense !! seems hacky, but fn() in hscript wont resolve an object first (this.fn() or super.fn() would work fine)
        if (o == null && _nextCallObject != null) {
            o = _nextCallObject;
        }
		var r = super.call(o, f, args);
        _nextCallObject = null;
        return r;
	}
    
    override function get( o : Dynamic, f : String ) : Dynamic {
        if ( o == null ) error(EInvalidAccess(f));
        if (Std.is(o, ScriptClass)) {
            var proxy:AbstractScriptClass = cast(o, ScriptClass);
            if (proxy._interp.variables.exists(f)) {
                return proxy._interp.variables.get(f);
            } else if (proxy.superClass != null && Reflect.hasField(proxy.superClass, f)) {
                return Reflect.getProperty(proxy.superClass, f);
            } else {
                try {
                    return proxy.resolveField(f);
                } catch (e:Dynamic) { }
                error(EUnknownVariable(f));
            }
        }
        return super.get(o, f);
    }
    
    override function set( o : Dynamic, f : String, v : Dynamic ) : Dynamic {
        if ( o == null ) error(EInvalidAccess(f));
        if (Std.is(o, ScriptClass)) {
            var proxy:ScriptClass = cast(o, ScriptClass);
            if (proxy._interp.variables.exists(f)) {
                proxy._interp.variables.set(f, v);
            } else if (proxy.superClass != null && Reflect.hasField(proxy.superClass, f)) {
                Reflect.setProperty(proxy.superClass, f, v);
            } else {
                error(EUnknownVariable(f));
            }
            return v;
        }
        return super.set(o, f, v);
    }
    
    private var _nextCallObject:Dynamic = null;
    override function resolve(id:String):Dynamic {
        _nextCallObject = null;
        if (id == "super" && _proxy != null) {
            if (_proxy.superClass == null) {
                return _proxy.superConstructor;
            } else {
                return _proxy.superClass;
            }
        } else if (id == "this" && _proxy != null) {
            return _proxy;
        }
        
		var l = locals.get(id);
		if( l != null )
			return l.r;
		var v = variables.get(id);
		if (v == null && !variables.exists(id)) {
            if (_proxy != null && _proxy.findFunction(id) != null) {
                _nextCallObject = _proxy;
                return _proxy.resolveField(id);
            } else if (_proxy != null && _proxy.superClass != null && (Reflect.hasField(_proxy.superClass, id) || Reflect.getProperty(_proxy.superClass, id) != null)) {
                _nextCallObject = _proxy.superClass;
                return Reflect.getProperty(_proxy.superClass, id);
            } else if (_proxy != null) {
                try {
                    var r = _proxy.resolveField(id);
                    _nextCallObject = _proxy;
                    return r;
                } catch (e:Dynamic) {}
                error(EUnknownVariable(id));
            } else {
                error(EUnknownVariable(id));
            }
        }
        return v;
    }
    
    public function addModule(moduleContents:String) 
    {
        var parser = new hscript.ParserEx();
        var decls = parser.parseModule(moduleContents);
        registerModule(decls);
    }
    
    public function createScriptClassInstance(className:String, args:Array<Dynamic> = null):AbstractScriptClass {
        if (args == null) {
            args = [];
        }
        var r:AbstractScriptClass = cnew(className, args);
        return r;
    }
    
    public function registerModule(module:Array<ModuleDecl>) {
        var pkg:Array<String> = null;
        var imports:Map<String, Array<String>> = [];
        for (decl in module) {
            switch (decl) {
                case DPackage(path):
                    pkg = path;
                case DImport(path, _):
                    var last = path[path.length - 1];
                    imports.set(last, path);
                case DClass(c):
                    var extend = c.extend;
                    if (extend != null) {
                        var superClassPath = new Printer().typeToString(extend);
                        if (imports.exists(superClassPath)) {
                            switch (extend) {
                                case CTPath(_, params):
                                    extend = CTPath(imports.get(superClassPath), params);
                                case _:    
                            }
                        }
                    }
                    var classDecl:ClassDeclEx = {
                        imports: imports,
                        pkg: pkg,
                        name: c.name,
                        params: c.params,
                        meta: c.meta,
                        isPrivate: c.isPrivate,
                        extend: extend,
                        implement: c.implement,
                        fields: c.fields,
                        isExtern: c.isExtern
                    };
                    registerScriptClass(classDecl);
                case DTypedef(_):
            }
        }
    }

    private function initBasicInterps():Void
    {
        variables.set('Type', Type);
        variables.set('Dynamic', Dynamic);

        variables.set('Math', Math);
        variables.set('Std', Std);

        variables.set('Date', Date);
        variables.set('Enum', Enum);
        variables.set('Lambda', Lambda);
        variables.set('Reflect', Reflect);

        variables.set('StringTools', StringTools);
        variables.set('stringContains', StringTools.contains);
        variables.set('stringReplace', StringTools.replace);
        variables.set('stringStartsWith', StringTools.startsWith);
        variables.set('stringEndsWith', StringTools.endsWith);
        variables.set('stringTrim', StringTools.trim);

        variables.set('String', String);
        variables.set('Bool', Bool);
        variables.set('Int', Int);
        variables.set('Float', Float);
        
        variables.set('ValueType', Type.ValueType);
        variables.set('TNull', Type.ValueType.TNull);
        variables.set('TInt', Type.ValueType.TInt);
        variables.set('TFloat', Type.ValueType.TFloat);
        variables.set('TBool', Type.ValueType.TBool);
        variables.set('TObject', Type.ValueType.TObject);
        variables.set('TClass', Type.ValueType.TClass);
        variables.set('TEnum', Type.ValueType.TEnum);
        variables.set('TFunction', Type.ValueType.TFunction);
        variables.set('TUnknown', Type.ValueType.TUnknown);

        variables.set('Array', Array);
        variables.set('sortArray', (arr:Array<Dynamic>, f:Dynamic) -> 
        {
            if (f == null)
            {
                openfl.Lib.application.window.alert('Please provide sorting function.', Main.ALERT_TITLE);
                return arr;
            }

            arr.sort((a:Dynamic, b:Dynamic) -> { return f(a, b); });
            return arr; 
        });

        variables.set('Sys', Sys);

        variables.set('Main', Main);
		variables.set('ALERT_TITLE', Main.ALERT_TITLE);
		variables.set('MOD_NAME', Main.MOD_NAME);

		variables.set('TimeSprite', a2.time.objects.TimeSprite);
		variables.set('FlxSprite', a2.time.objects.DynamicSprite);
		variables.set('DynamicSprite', a2.time.objects.DynamicSprite);
        variables.set('FlxVideoSprite', hxvlc.flixel.FlxVideoSprite);
		variables.set('FlxRect', flixel.math.FlxRect);
		variables.set('FlxSpriteUtil', flixel.util.FlxSpriteUtil);

		variables.set('InteractiveSprite', a2.time.objects.InteractiveSprite);

        variables.set('FlxBasic', flixel.FlxBasic);
		variables.set('FlxObject', flixel.FlxObject);
        variables.set('FlxGraphic', flixel.graphics.FlxGraphic);
        variables.set('FlxImageFrame', flixel.graphics.frames.FlxImageFrame);

		variables.set('FlxText', flixel.text.FlxText);
		variables.set('FlxTextFormat', flixel.text.FlxText.FlxTextFormat);
		variables.set('FlxTextFormatMarkerPair', flixel.text.FlxText.FlxTextFormatMarkerPair);
        variables.set('DEFAULT_FONT', openfl.utils.Assets.getFont('assets/fonts/pixel.otf').fontName);

		variables.set('BORDER_NONE', flixel.text.FlxText.FlxTextBorderStyle.NONE);
		variables.set('BORDER_SHADOW', flixel.text.FlxText.FlxTextBorderStyle.SHADOW);
		variables.set('BORDER_SHADOW_XY', flixel.text.FlxText.FlxTextBorderStyle.SHADOW_XY);
		variables.set('BORDER_OUTLINE', flixel.text.FlxText.FlxTextBorderStyle.OUTLINE);
		variables.set('BORDER_OUTLINE_FAST', flixel.text.FlxText.FlxTextBorderStyle.OUTLINE_FAST);

		variables.set('FlxSave', flixel.util.FlxSave);

		variables.set('IntroState', a2.time.states.IntroState);
		
        variables.set('LoadingState', a2.time.states.LoadingState);

		variables.set('Conductor', a2.time.objects.song.Conductor);

		variables.set('HealthIcon', a2.time.objects.gameplay.HealthIcon);
		
        variables.set('FlxTransitionableState', flixel.addons.transition.FlxTransitionableState);
		
        variables.set('Paths', Paths);
        variables.set('PNG_FILE_EXT', Paths.PNG_FILE_EXT);
        variables.set('OGG_FILE_EXT', Paths.OGG_FILE_EXT);
        variables.set('TTF_FILE_EXT', Paths.TTF_FILE_EXT);
        variables.set('OTF_FILE_EXT', Paths.OTF_FILE_EXT);
        variables.set('HSCRIPT_FILE_EXT', Paths.HSCRIPT_FILE_EXT);
        variables.set('HX_FILE_EXT', Paths.HX_FILE_EXT);
        variables.set('FRAG_FILE_EXT', Paths.FRAG_FILE_EXT);
        variables.set('CSS_FILE_EXT', Paths.CSS_FILE_EXT);
        variables.set('UI_XML_FILE_EXT', Paths.UI_XML_FILE_EXT);
        variables.set('XML_FILE_EXT', Paths.XML_FILE_EXT);
        variables.set('JSON_FILE_EXT', Paths.JSON_FILE_EXT);
        variables.set('MP4_FILE_EXT', Paths.MP4_FILE_EXT);

        variables.set('Assets', a2.time.backend.Assets);
		variables.set('Path', haxe.io.Path);

		variables.set('FileSystem', sys.FileSystem);
		variables.set('File', sys.io.File);

		variables.set('Controls', a2.time.backend.Controls);
        variables.set('controls', a2.time.backend.Controls.instance);

		variables.set('FlxCamera', flixel.FlxCamera);
        variables.set('CAMERA_FOLLOW_LOCKON', flixel.FlxCamera.FlxCameraFollowStyle.LOCKON);
        variables.set('CAMERA_FOLLOW_PLATFORMER', flixel.FlxCamera.FlxCameraFollowStyle.PLATFORMER);
        variables.set('CAMERA_FOLLOW_TOPDOWN', flixel.FlxCamera.FlxCameraFollowStyle.TOPDOWN);
        variables.set('CAMERA_FOLLOW_TOPDOWN_TIGHT', flixel.FlxCamera.FlxCameraFollowStyle.TOPDOWN_TIGHT);
        variables.set('CAMERA_FOLLOW_SCREEN_BY_SCREEN', flixel.FlxCamera.FlxCameraFollowStyle.SCREEN_BY_SCREEN);
        variables.set('CAMERA_FOLLOW_NO_DEAD_ZONE', flixel.FlxCamera.FlxCameraFollowStyle.NO_DEAD_ZONE);

		variables.set('FlxStringUtil', flixel.util.FlxStringUtil);

		variables.set('colorFromCMYK', flixel.util.FlxColor.fromCMYK);
		variables.set('colorFromHSB', flixel.util.FlxColor.fromHSB);
		variables.set('colorFromHSL', flixel.util.FlxColor.fromHSL);
		variables.set('colorFromInt', flixel.util.FlxColor.fromInt);
		variables.set('colorFromRGB', flixel.util.FlxColor.fromRGB);
		variables.set('colorFromRGBFloat', flixel.util.FlxColor.fromRGBFloat);
		variables.set('colorFromString', flixel.util.FlxColor.fromString);

		variables.set('intTo24Bit', (col:Int) -> 
		{
			return flixel.util.FlxColor.fromInt(col).to24Bit();
		});

        variables.set('colorLightened', (col:Int, factor:Float) ->
        {
            return flixel.util.FlxColor.fromInt(col).getLightened(factor);
        });
        variables.set('colorDarkened', (col:Int, factor:Float) ->
        {
            return flixel.util.FlxColor.fromInt(col).getDarkened(factor);
        });

		variables.set('getColorFloatValues', (col:Int) ->
		{
			var parsed:flixel.util.FlxColor = flixel.util.FlxColor.fromInt(col);
			return [parsed.redFloat, parsed.greenFloat, parsed.blueFloat];
		});

		variables.set('FlxEffectSprite', flixel.addons.effects.chainable.FlxEffectSprite);
		variables.set('FlxWaveEffect', flixel.addons.effects.chainable.FlxWaveEffect);
		variables.set('FlxGlitchEffect', flixel.addons.effects.chainable.FlxGlitchEffect);
		
        variables.set('Song', a2.time.objects.song.Song);

		variables.set('PlayState', a2.time.states.PlayState);

		variables.set('DiscordClient', 
        {
            changePresence: (options:a2.time.backend.DiscordClient.DiscordPresenceOptions) ->
            {
                a2.time.backend.DiscordClient.instance.changePresence(options);
            },
            shutdown: () -> 
            {
                a2.time.backend.DiscordClient.instance.shutdown();
            }
        });

		variables.set('CustomState', a2.time.states.CustomState);
		variables.set('CustomSubState', a2.time.substates.CustomSubState);

		variables.set('FlxAngle', flixel.math.FlxAngle);
		variables.set('ANGLE_TO_DEG', flixel.math.FlxAngle.TO_DEG);
		variables.set('ANGLE_TO_RAD', flixel.math.FlxAngle.TO_RAD);

		variables.set('Mouse', openfl.ui.Mouse);

		variables.set('CURSOR_ARROW', openfl.ui.MouseCursor.ARROW);
		variables.set('CURSOR_AUTO', openfl.ui.MouseCursor.AUTO);
		variables.set('CURSOR_BUTTON', openfl.ui.MouseCursor.BUTTON);
		variables.set('CURSOR_CROSSHAIR', lime.ui.MouseCursor.CROSSHAIR);
		variables.set('CURSOR_CROSSHAIR', lime.ui.MouseCursor.CUSTOM);
		variables.set('CURSOR_DEFAULT', lime.ui.MouseCursor.DEFAULT);
		variables.set('CURSOR_HAND', openfl.ui.MouseCursor.HAND);
        variables.set('CURSOR_MOVE', lime.ui.MouseCursor.MOVE);
		variables.set('CURSOR_IBEAM', openfl.ui.MouseCursor.IBEAM);
        variables.set('CURSOR_POINTER', lime.ui.MouseCursor.POINTER);
        variables.set('CURSOR_RESIZE_NESW', lime.ui.MouseCursor.RESIZE_NESW);
        variables.set('CURSOR_RESIZE_NS', lime.ui.MouseCursor.RESIZE_NS);
        variables.set('CURSOR_RESIZE_NWSE', lime.ui.MouseCursor.RESIZE_NWSE);
        variables.set('CURSOR_RESIZE_WE', lime.ui.MouseCursor.RESIZE_WE);
        variables.set('CURSOR_TEXT', lime.ui.MouseCursor.TEXT);
        variables.set('CURSOR_WAIT', lime.ui.MouseCursor.WAIT);
        variables.set('CURSOR_WAIT_ARROW', lime.ui.MouseCursor.WAIT_ARROW);

		// NEXT LEVEL GOAT
		variables.set('privateAccess', (func:Void->Void) -> { @:privateAccess if (func != null) func(); });

		variables.set('FlxEmitter', flixel.effects.particles.FlxEmitter);
		variables.set('FlxParticle', flixel.effects.particles.FlxParticle);
		variables.set('FlxDestroyUtil', flixel.util.FlxDestroyUtil);

		variables.set('ClientPrefs', a2.time.backend.ClientPrefs);

        variables.set('BaseState', a2.time.states.BaseState);

		variables.set('MusicBeatState', a2.time.states.MusicBeatState);
		variables.set('MusicBeatSubstate', a2.time.substates.MusicBeatSubstate);

		variables.set('Note', a2.time.objects.gameplay.notes.Note);

		variables.set('StrumNote', a2.time.objects.gameplay.notes.StrumNote);
        variables.set('DEFAULT_STRUM_SKIN_NAME', a2.time.objects.gameplay.notes.StrumNote.DEFAULT_STRUM_SKIN_NAME);
        variables.set('STRUM_IDLE', a2.time.objects.gameplay.notes.StrumNote.STRUM_IDLE);
        variables.set('STRUM_PRESS', a2.time.objects.gameplay.notes.StrumNote.STRUM_PRESS);
        variables.set('STRUM_CONFIRM', a2.time.objects.gameplay.notes.StrumNote.STRUM_CONFIRM);
        variables.set('SCROLL_DIRECTION_DOWN', a2.time.objects.gameplay.notes.StrumNote.ScrollDirection.DOWN);
        variables.set('SCROLL_DIRECTION_UP', a2.time.objects.gameplay.notes.StrumNote.ScrollDirection.UP);
        variables.set('LANE_FOLLOW_INHERIT', a2.time.objects.gameplay.notes.StrumNote.LaneAngleFollowType.INHERIT);
        variables.set('LANE_FOLLOW_CONSTANT', a2.time.objects.gameplay.notes.StrumNote.LaneAngleFollowType.CONSTANT);
        @:privateAccess variables.set('STRUM_DEFAULT_SCALE', a2.time.objects.gameplay.notes.StrumNote.DEFAULT_SCALE);

		variables.set('Section', a2.time.objects.song.Section);

		variables.set('FlxFlicker', flixel.effects.FlxFlicker);

		variables.set('FlxGroup', flixel.group.FlxGroup);
		variables.set('FlxTrailArea', flixel.addons.effects.FlxTrailArea);

		variables.set('ShaderFilter', openfl.filters.ShaderFilter);

		variables.set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);

		variables.set('Json', haxe.Json);
		variables.set('stringifyJson', (object:Dynamic, ?space:String) -> { return haxe.Json.stringify(object, space); });
		variables.set('parseJson', (text:String) -> { return haxe.Json.parse(text); });
		
        variables.set('FlxSound', flixel.sound.FlxSound);
        variables.set('Sound', openfl.media.Sound);

		variables.set('FlxGridOverlay', flixel.addons.display.FlxGridOverlay);

		variables.set('FlxG', flixel.FlxG);

		variables.set('FlxTimer', flixel.util.FlxTimer);

        variables.set('Lib', openfl.Lib);
		variables.set('window', openfl.Lib.application.window);
        variables.set('alert', openfl.Lib.application.window.alert);

		variables.set('blendModeFromString', (blend:String) -> 
        { 
            @:privateAccess
            return BlendMode.fromString(blend.toLowerCase().trim()); 
        });
        variables.set('blendModeToString', (blend:BlendMode) -> { return '$blend'; });
		
        variables.set('InputFormatter', a2.time.objects.util.InputFormatter);
		
        variables.set('FlxTween', flixel.tweens.FlxTween);
		variables.set('FlxEase', flixel.tweens.FlxEase);

		variables.set('FlxAtlasFrames', flixel.graphics.frames.FlxAtlasFrames);
		
        variables.set('FlxMath', flixel.math.FlxMath);

		variables.set('FlxBar', flixel.ui.FlxBar);
		variables.set('FlxBarFillDirection', flixel.ui.FlxBar.FlxBarFillDirection);

		variables.set('Bitmap', openfl.display.Bitmap);
		variables.set('BitmapData', openfl.display.BitmapData);
		variables.set('Image', lime.graphics.Image);
		variables.set('OpenFLGraphics', flash.display.Graphics);

		variables.set('FlxBackdrop', flixel.addons.display.FlxBackdrop);

		variables.set('AXES_X', flixel.util.FlxAxes.X);
		variables.set('AXES_Y', flixel.util.FlxAxes.Y);
		variables.set('AXES_XY', flixel.util.FlxAxes.XY);

		variables.set('Character', a2.time.objects.gameplay.Character);
		variables.set('CHARACTER_NORMAL', a2.time.objects.gameplay.Character.CharacterType.NORMAL);
		variables.set('CHARACTER_TRAIL', a2.time.objects.gameplay.Character.CharacterType.TRAIL);
		variables.set('CHARACTER_SHADOW', a2.time.objects.gameplay.Character.CharacterType.SHADOW);
		variables.set('ANIMATION_STANDARD', 'STANDARD');
		variables.set('ANIMATION_DANCE', 'DANCE');
		variables.set('ANIMATION_SING', 'SING');
		variables.set('ANIMATION_MISS', 'MISS');

        variables.set('getIndices', (dynamicIndices:Array<Int>) ->
        {
            var indices:Array<Int> = [];
            for (index in dynamicIndices) indices.push(cast (index, Int));

            return indices;
        });

        variables.set('FlxAnimationController', flixel.animation.FlxAnimationController);
        variables.set('FlxAnimation', flixel.animation.FlxAnimation);

		variables.set('byteArrayFromFile', openfl.utils.ByteArray.fromFile);
		variables.set('byteArrayFromBytes', openfl.utils.ByteArray.fromBytes);
		variables.set('byteArrayfromArrayBuffer', openfl.utils.ByteArray.fromArrayBuffer);
		variables.set('BitmapFilter', openfl.filters.BitmapFilter);

		variables.set('WORKING_MOD_DIRECTORY', Paths.WORKING_MOD_DIRECTORY);

		variables.set('CHART_VERSION_STRING', a2.time.objects.song.Song.CHART_VERSION_STRING);

		variables.set('getMap', () ->
		{
			return new Map<Dynamic, Dynamic>();
		});

		variables.set('getMap2', () ->
		{
			return new Map<Dynamic, Map<Dynamic, Dynamic>>();
		});
        variables.set('StringMap', haxe.ds.StringMap);

		variables.set('InterpEx', InterpEx);
		variables.set('ParserEx', ParserEx);

		variables.set('UIShortcuts', a2.time.util.UIShortcuts);
		variables.set('UiS', a2.time.util.UIShortcuts);

		variables.set('tweening', a2.time.states.CustomState.tweening);
		variables.set('mPos', a2.time.states.CustomState.mPos);
		variables.set('tweenMouse', a2.time.states.CustomState.tweenMouse);

		variables.set('Button', haxe.ui.components.Button);
		variables.set('Label', haxe.ui.components.Label);
		variables.set('TextField', haxe.ui.components.TextField);
		variables.set('TextArea', haxe.ui.components.TextArea);
		variables.set('HorizontalSlider', haxe.ui.components.HorizontalSlider);
		variables.set('VerticalSlider', haxe.ui.components.VerticalSlider);
		variables.set('CheckBox', haxe.ui.components.CheckBox);
		variables.set('DropDown', haxe.ui.components.DropDown);
		variables.set('NumberStepper', haxe.ui.components.NumberStepper);

		variables.set('RuntimeComponentBuilder', haxe.ui.RuntimeComponentBuilder);
		variables.set('Component', haxe.ui.core.Component);

		variables.set('Box', haxe.ui.containers.Box);
		variables.set('HBox', haxe.ui.containers.HBox);
		variables.set('VBox', haxe.ui.containers.VBox);
		variables.set('TabView', haxe.ui.containers.TabView);
		variables.set('ListView', haxe.ui.containers.ListView);
		variables.set('ScrollView', haxe.ui.containers.ScrollView);
		variables.set('getDataSource', () ->
		{
			return new haxe.ui.data.ArrayDataSource<Dynamic>();
		});
		variables.set('Dialogs', haxe.ui.containers.dialogs.Dialogs);
		variables.set('Dialog', haxe.ui.containers.dialogs.Dialog);

		variables.set('ToolTipManager', haxe.ui.tooltips.ToolTipManager);

		variables.set('FocusManager', haxe.ui.focus.FocusManager);

		variables.set('DragManager', haxe.ui.dragdrop.DragManager);
		variables.set('UIPoint', haxe.ui.geom.Point);
		variables.set('UIRect', haxe.ui.geom.Rectangle);
		variables.set('UISize', haxe.ui.geom.Size);
		variables.set('UISlice9', haxe.ui.geom.Slice9);

        variables.set('OpenFLPoint', openfl.geom.Point);
		variables.set('OpenFLRect', openfl.geom.Rectangle);

		variables.set('Menu', haxe.ui.containers.menus.Menu);
		variables.set('MenuBar', haxe.ui.containers.menus.MenuBar);
		variables.set('MenuCheckBox', haxe.ui.containers.menus.MenuCheckBox);
		variables.set('MenuItem', haxe.ui.containers.menus.MenuItem);
		variables.set('MenuOptionBox', haxe.ui.containers.menus.MenuOptionBox);
		variables.set('MenuSeparator', haxe.ui.containers.menus.MenuSeparator);

		variables.set('Window', haxe.ui.containers.windows.Window);
		variables.set('WindowManager', haxe.ui.containers.windows.WindowManager.instance);

        variables.set('variantFromFrame', (frame:flixel.graphics.frames.FlxFrame) -> {return haxe.ui.util.Variant.fromImageData(frame); });

        variables.set('Property', haxe.ui.containers.properties.Property);
        variables.set('PropertyGroup', haxe.ui.containers.properties.PropertyGroup);
        variables.set('PropertyGrid', haxe.ui.containers.properties.PropertyGrid);

		variables.set('FlxShape', flixel.addons.display.shapes.FlxShape);
		variables.set('FlxShapeArrow', flixel.addons.display.shapes.FlxShapeArrow);
		variables.set('FlxShapeBox', flixel.addons.display.shapes.FlxShapeBox);
		variables.set('FlxShapeCircle', flixel.addons.display.shapes.FlxShapeCircle);
		variables.set('FlxShapeCross', flixel.addons.display.shapes.FlxShapeCross);
		variables.set('FlxShapeDonut', flixel.addons.display.shapes.FlxShapeDonut);
		variables.set('FlxShapeLine', flixel.addons.display.shapes.FlxShapeLine);
		variables.set('FlxShapeSquareDonut', flixel.addons.display.shapes.FlxShapeSquareDonut);

		variables.set('NotificationManager', haxe.ui.notifications.NotificationManager);
		variables.set('NOTIFICATION_INFO', haxe.ui.notifications.NotificationType.Info);
		variables.set('NOTIFICATION_ERROR', haxe.ui.notifications.NotificationType.Error);
		variables.set('NOTIFICATION_WARNING', haxe.ui.notifications.NotificationType.Warning);
		variables.set('NOTIFICATION_SUCCESS', haxe.ui.notifications.NotificationType.Success);

		variables.set('Screen', haxe.ui.Toolkit.screen);
		variables.set('Toolkit', haxe.ui.Toolkit);

		variables.set('blockInput', a2.time.states.BaseState.instance.blockInput);

		variables.set('HscriptManager', a2.time.backend.managers.HscriptManager);
		variables.set('CameraManager', a2.time.backend.managers.CameraManager);
		variables.set('UndoManager', a2.time.backend.managers.UndoManager);
		
        variables.set('LoadingScreenManager', a2.time.backend.managers.LoadingScreenManager);
        variables.set('LOADING_PLAYSTATE', a2.time.states.PlayState.LOADING_PLAYSTATE);

		variables.set('StateTransitionManager', a2.time.backend.managers.StateTransitionManager);
		variables.set('PRE_EVERYTHING', a2.time.backend.managers.StateTransitionManager.TransitionPhase.PRE_EVERYTHING);
		variables.set('TRANSITION_IN', a2.time.backend.managers.StateTransitionManager.TransitionPhase.TRANSITION_IN);
		variables.set('TRANSITION_OUT', a2.time.backend.managers.StateTransitionManager.TransitionPhase.TRANSITION_OUT);

        variables.set('SoundTrayManager', a2.time.backend.managers.SoundTrayManager);

        variables.set('screenResolutionX', openfl.system.Capabilities.screenResolutionX);
		variables.set('screenResolutionY', openfl.system.Capabilities.screenResolutionY);
		variables.set('Capabilities', openfl.system.Capabilities);

        variables.set('FlxWaveform', flixel.addons.display.waveform.FlxWaveform);
        variables.set('WAVEFORM_COMBINED', flixel.addons.display.waveform.FlxWaveform.WaveformDrawMode.COMBINED);
        variables.set('WAVEFORM_SPLIT_CHANNELS', flixel.addons.display.waveform.FlxWaveform.WaveformDrawMode.SPLIT_CHANNELS);
        variables.set('WAVEFORM_SINGLE_CHANNEL', flixel.addons.display.waveform.FlxWaveform.WaveformDrawMode.SINGLE_CHANNEL);
        variables.set('WAVEFORM_HORIZONTAL', flixel.addons.display.waveform.FlxWaveform.WaveformOrientation.HORIZONTAL);
        variables.set('WAVEFORM_VERTICAL', flixel.addons.display.waveform.FlxWaveform.WaveformOrientation.VERTICAL);

        variables.set('ChartVersionUtil', a2.time.objects.util.ChartVersionUtil);
        variables.set('ChartEventManager', a2.time.backend.managers.ChartEventManager);
        variables.set('BPM_CHANGE_EVENT_NAME', a2.time.backend.managers.ChartEventManager.BPM_CHANGE_EVENT_NAME);
        variables.set('CHAR_FOCUS_EVENT_NAME', a2.time.backend.managers.ChartEventManager.CHAR_FOCUS_EVENT_NAME);

        variables.set('Base64', haxe.crypto.Base64);
        variables.set('encodeBase64', haxe.crypto.Base64.encode);
        variables.set('decodeBase64', haxe.crypto.Base64.decode);

        variables.set('keyFromString', FlxKey.fromString);
        variables.set('keyToString', (code:Int) ->
        {
            var key:FlxKey = cast code;
            return key.toString();
        });

        variables.set('KEY_UNKNOWN', lime.ui.KeyCode.UNKNOWN);
        variables.set('KEY_BACKSPACE', lime.ui.KeyCode.BACKSPACE);
        variables.set('KEY_TAB', lime.ui.KeyCode.TAB);
        variables.set('KEY_RETURN', lime.ui.KeyCode.RETURN);
        variables.set('KEY_ESCAPE', lime.ui.KeyCode.ESCAPE);
        variables.set('KEY_SPACE', lime.ui.KeyCode.SPACE);
        variables.set('KEY_EXCLAMATION', lime.ui.KeyCode.EXCLAMATION);
        variables.set('KEY_QUOTE', lime.ui.KeyCode.QUOTE);
        variables.set('KEY_HASH', lime.ui.KeyCode.HASH);
        variables.set('KEY_DOLLAR', lime.ui.KeyCode.DOLLAR);
        variables.set('KEY_PERCENT', lime.ui.KeyCode.PERCENT);
        variables.set('KEY_AMPERSAND', lime.ui.KeyCode.AMPERSAND);
        variables.set('KEY_SINGLE_QUOTE', lime.ui.KeyCode.SINGLE_QUOTE);
        variables.set('KEY_LEFT_PARENTHESIS', lime.ui.KeyCode.LEFT_PARENTHESIS);
        variables.set('KEY_RIGHT_PARENTHESIS', lime.ui.KeyCode.RIGHT_PARENTHESIS);
        variables.set('KEY_ASTERISK', lime.ui.KeyCode.ASTERISK);
        variables.set('KEY_PLUS', lime.ui.KeyCode.PLUS);
        variables.set('KEY_COMMA', lime.ui.KeyCode.COMMA);
        variables.set('KEY_MINUS', lime.ui.KeyCode.MINUS);
        variables.set('KEY_PERIOD', lime.ui.KeyCode.PERIOD);
        variables.set('KEY_SLASH', lime.ui.KeyCode.SLASH);
        variables.set('KEY_NUMBER_0', lime.ui.KeyCode.NUMBER_0);
        variables.set('KEY_NUMBER_1', lime.ui.KeyCode.NUMBER_1);
        variables.set('KEY_NUMBER_2', lime.ui.KeyCode.NUMBER_2);
        variables.set('KEY_NUMBER_3', lime.ui.KeyCode.NUMBER_3);
        variables.set('KEY_NUMBER_4', lime.ui.KeyCode.NUMBER_4);
        variables.set('KEY_NUMBER_5', lime.ui.KeyCode.NUMBER_5);
        variables.set('KEY_NUMBER_6', lime.ui.KeyCode.NUMBER_6);
        variables.set('KEY_NUMBER_7', lime.ui.KeyCode.NUMBER_7);
        variables.set('KEY_NUMBER_8', lime.ui.KeyCode.NUMBER_8);
        variables.set('KEY_NUMBER_9', lime.ui.KeyCode.NUMBER_9);
        variables.set('KEY_COLON', lime.ui.KeyCode.COLON);
        variables.set('KEY_SEMICOLON', lime.ui.KeyCode.SEMICOLON);
        variables.set('KEY_LESS_THAN', lime.ui.KeyCode.LESS_THAN);
        variables.set('KEY_GREATER_THAN', lime.ui.KeyCode.GREATER_THAN);
        variables.set('KEY_QUESTION', lime.ui.KeyCode.QUESTION);
        variables.set('KEY_AT', lime.ui.KeyCode.AT);
        variables.set('KEY_LEFT_BRACKET', lime.ui.KeyCode.LEFT_BRACKET);
        variables.set('KEY_CARET', lime.ui.KeyCode.CARET);
        variables.set('KEY_UNDERSCORE', lime.ui.KeyCode.UNDERSCORE);
        variables.set('KEY_GRAVE', lime.ui.KeyCode.GRAVE);
        variables.set('KEY_A', lime.ui.KeyCode.A);
        variables.set('KEY_B', lime.ui.KeyCode.B);
        variables.set('KEY_C', lime.ui.KeyCode.C);
        variables.set('KEY_D', lime.ui.KeyCode.D);
        variables.set('KEY_E', lime.ui.KeyCode.E);
        variables.set('KEY_F', lime.ui.KeyCode.F);
        variables.set('KEY_G', lime.ui.KeyCode.G);
        variables.set('KEY_H', lime.ui.KeyCode.H);
        variables.set('KEY_I', lime.ui.KeyCode.I);
        variables.set('KEY_J', lime.ui.KeyCode.J);
        variables.set('KEY_K', lime.ui.KeyCode.K);
        variables.set('KEY_L', lime.ui.KeyCode.L);
        variables.set('KEY_M', lime.ui.KeyCode.M);
        variables.set('KEY_N', lime.ui.KeyCode.N);
        variables.set('KEY_O', lime.ui.KeyCode.O);
        variables.set('KEY_P', lime.ui.KeyCode.P);
        variables.set('KEY_Q', lime.ui.KeyCode.Q);
        variables.set('KEY_R', lime.ui.KeyCode.R);
        variables.set('KEY_S', lime.ui.KeyCode.S);
        variables.set('KEY_T', lime.ui.KeyCode.T);
        variables.set('KEY_U', lime.ui.KeyCode.U);
        variables.set('KEY_V', lime.ui.KeyCode.V);
        variables.set('KEY_W', lime.ui.KeyCode.W);
        variables.set('KEY_X', lime.ui.KeyCode.X);
        variables.set('KEY_Y', lime.ui.KeyCode.Y);
        variables.set('KEY_Z', lime.ui.KeyCode.Z);
        variables.set('KEY_DELETE', lime.ui.KeyCode.DELETE);
        variables.set('KEY_CAPS_LOCK', lime.ui.KeyCode.CAPS_LOCK);
        variables.set('KEY_F1', lime.ui.KeyCode.F1);
        variables.set('KEY_F2', lime.ui.KeyCode.F2);
        variables.set('KEY_F3', lime.ui.KeyCode.F3);
        variables.set('KEY_F4', lime.ui.KeyCode.F4);
        variables.set('KEY_F5', lime.ui.KeyCode.F5);
        variables.set('KEY_F6', lime.ui.KeyCode.F6);
        variables.set('KEY_F7', lime.ui.KeyCode.F7);
        variables.set('KEY_F8', lime.ui.KeyCode.F8);
        variables.set('KEY_F9', lime.ui.KeyCode.F9);
        variables.set('KEY_F10', lime.ui.KeyCode.F10);
        variables.set('KEY_F11', lime.ui.KeyCode.F11);
        variables.set('KEY_F12', lime.ui.KeyCode.F12);
        variables.set('KEY_PRINT_SCREEN', lime.ui.KeyCode.PRINT_SCREEN);
        variables.set('KEY_SCROLL_LOCK', lime.ui.KeyCode.SCROLL_LOCK);
        variables.set('KEY_PAUSE', lime.ui.KeyCode.PAUSE);
        variables.set('KEY_INSERT', lime.ui.KeyCode.INSERT);
        variables.set('KEY_HOME', lime.ui.KeyCode.HOME);
        variables.set('KEY_PAGE_UP', lime.ui.KeyCode.PAGE_UP);
        variables.set('KEY_END', lime.ui.KeyCode.END);
        variables.set('KEY_PAGE_DOWN', lime.ui.KeyCode.PAGE_DOWN);
        variables.set('KEY_RIGHT', lime.ui.KeyCode.RIGHT);
        variables.set('KEY_LEFT', lime.ui.KeyCode.LEFT);
        variables.set('KEY_DOWN', lime.ui.KeyCode.DOWN);
        variables.set('KEY_UP', lime.ui.KeyCode.UP);
        variables.set('KEY_NUM_LOCK', lime.ui.KeyCode.NUM_LOCK);
        variables.set('KEY_NUMPAD_DIVIDE', lime.ui.KeyCode.NUMPAD_DIVIDE);
        variables.set('KEY_NUMPAD_MULTIPLY', lime.ui.KeyCode.NUMPAD_MULTIPLY);
        variables.set('KEY_NUMPAD_MINUS', lime.ui.KeyCode.NUMPAD_MINUS);
        variables.set('KEY_NUMPAD_PLUS', lime.ui.KeyCode.NUMPAD_PLUS);
        variables.set('KEY_NUMPAD_ENTER', lime.ui.KeyCode.NUMPAD_ENTER);
        variables.set('KEY_NUMPAD_1', lime.ui.KeyCode.NUMPAD_1);
        variables.set('KEY_NUMPAD_2', lime.ui.KeyCode.NUMPAD_2);
        variables.set('KEY_NUMPAD_3', lime.ui.KeyCode.NUMPAD_3);
        variables.set('KEY_NUMPAD_4', lime.ui.KeyCode.NUMPAD_4);
        variables.set('KEY_NUMPAD_5', lime.ui.KeyCode.NUMPAD_5);
        variables.set('KEY_NUMPAD_6', lime.ui.KeyCode.NUMPAD_6);
        variables.set('KEY_NUMPAD_7', lime.ui.KeyCode.NUMPAD_7);
        variables.set('KEY_NUMPAD_8', lime.ui.KeyCode.NUMPAD_8);
        variables.set('KEY_NUMPAD_9', lime.ui.KeyCode.NUMPAD_9);
        variables.set('KEY_NUMPAD_0', lime.ui.KeyCode.NUMPAD_0);
        variables.set('KEY_NUMPAD_PERIOD', lime.ui.KeyCode.NUMPAD_PERIOD);
        variables.set('KEY_APPLICATION', lime.ui.KeyCode.APPLICATION);
        variables.set('KEY_POWER', lime.ui.KeyCode.POWER);
        variables.set('KEY_NUMPAD_EQUALS', lime.ui.KeyCode.NUMPAD_EQUALS);
        variables.set('KEY_F13', lime.ui.KeyCode.F13);
        variables.set('KEY_F14', lime.ui.KeyCode.F14);
        variables.set('KEY_F15', lime.ui.KeyCode.F15);
        variables.set('KEY_F16', lime.ui.KeyCode.F16);
        variables.set('KEY_F17', lime.ui.KeyCode.F17);
        variables.set('KEY_F18', lime.ui.KeyCode.F18);
        variables.set('KEY_F19', lime.ui.KeyCode.F19);
        variables.set('KEY_F20', lime.ui.KeyCode.F20);
        variables.set('KEY_F21', lime.ui.KeyCode.F21);
        variables.set('KEY_F22', lime.ui.KeyCode.F22);
        variables.set('KEY_F23', lime.ui.KeyCode.F23);
        variables.set('KEY_F24', lime.ui.KeyCode.F24);
        variables.set('KEY_EXECUTE', lime.ui.KeyCode.EXECUTE);
        variables.set('KEY_HELP', lime.ui.KeyCode.HELP);
        variables.set('KEY_MENU', lime.ui.KeyCode.MENU);
        variables.set('KEY_SELECT', lime.ui.KeyCode.SELECT);
        variables.set('KEY_STOP', lime.ui.KeyCode.STOP);
        variables.set('KEY_AGAIN', lime.ui.KeyCode.AGAIN);
        variables.set('KEY_UNDO', lime.ui.KeyCode.UNDO);
        variables.set('KEY_CUT', lime.ui.KeyCode.CUT);
        variables.set('KEY_COPY', lime.ui.KeyCode.COPY);
        variables.set('KEY_PASTE', lime.ui.KeyCode.PASTE);
        variables.set('KEY_FIND', lime.ui.KeyCode.FIND);
        variables.set('KEY_MUTE', lime.ui.KeyCode.MUTE);
        variables.set('KEY_VOLUME_UP', lime.ui.KeyCode.VOLUME_UP);
        variables.set('KEY_VOLUME_DOWN', lime.ui.KeyCode.VOLUME_DOWN);
        variables.set('KEY_NUMPAD_COMMA', lime.ui.KeyCode.NUMPAD_COMMA);
        variables.set('KEY_ALT_ERASE', lime.ui.KeyCode.ALT_ERASE);
        variables.set('KEY_SYSTEM_REQUEST', lime.ui.KeyCode.SYSTEM_REQUEST);
        variables.set('KEY_CANCEL', lime.ui.KeyCode.CANCEL);
        variables.set('KEY_CLEAR', lime.ui.KeyCode.CLEAR);
        variables.set('KEY_PRIOR', lime.ui.KeyCode.PRIOR);
        variables.set('KEY_RETURN2', lime.ui.KeyCode.RETURN2);
        variables.set('KEY_SEPARATOR', lime.ui.KeyCode.SEPARATOR);
        variables.set('KEY_OUT', lime.ui.KeyCode.OUT);
        variables.set('KEY_OPER', lime.ui.KeyCode.OPER);
        variables.set('KEY_CLEAR_AGAIN', lime.ui.KeyCode.CLEAR_AGAIN);
        variables.set('KEY_CRSEL', lime.ui.KeyCode.CRSEL);
        variables.set('KEY_EXSEL', lime.ui.KeyCode.EXSEL);
        variables.set('KEY_NUMPAD_00', lime.ui.KeyCode.NUMPAD_00);
        variables.set('KEY_NUMPAD_000', lime.ui.KeyCode.NUMPAD_000);
        variables.set('KEY_THOUSAND_SEPARATOR', lime.ui.KeyCode.THOUSAND_SEPARATOR);
        variables.set('KEY_DECIMAL_SEPARATOR', lime.ui.KeyCode.DECIMAL_SEPARATOR);
        variables.set('KEY_CURRENCY_UNIT', lime.ui.KeyCode.CURRENCY_UNIT);
        variables.set('KEY_CURRENCY_SUBUNIT', lime.ui.KeyCode.CURRENCY_SUBUNIT);
        variables.set('KEY_NUMPAD_LEFT_PARENTHESIS', lime.ui.KeyCode.NUMPAD_LEFT_PARENTHESIS);
        variables.set('KEY_NUMPAD_RIGHT_PARENTHESIS', lime.ui.KeyCode.NUMPAD_RIGHT_PARENTHESIS);
        variables.set('KEY_NUMPAD_LEFT_BRACE', lime.ui.KeyCode.NUMPAD_LEFT_BRACE);
        variables.set('KEY_NUMPAD_RIGHT_BRACE', lime.ui.KeyCode.NUMPAD_RIGHT_BRACE);
        variables.set('KEY_NUMPAD_TAB', lime.ui.KeyCode.NUMPAD_TAB);
        variables.set('KEY_NUMPAD_BACKSPACE', lime.ui.KeyCode.NUMPAD_BACKSPACE);
        variables.set('KEY_NUMPAD_A', lime.ui.KeyCode.NUMPAD_A);
        variables.set('KEY_NUMPAD_B', lime.ui.KeyCode.NUMPAD_B);
        variables.set('KEY_NUMPAD_C', lime.ui.KeyCode.NUMPAD_C);
        variables.set('KEY_NUMPAD_D', lime.ui.KeyCode.NUMPAD_D);
        variables.set('KEY_NUMPAD_E', lime.ui.KeyCode.NUMPAD_E);
        variables.set('KEY_NUMPAD_F', lime.ui.KeyCode.NUMPAD_F);
        variables.set('KEY_NUMPAD_XOR', lime.ui.KeyCode.NUMPAD_XOR);
        variables.set('KEY_NUMPAD_POWER', lime.ui.KeyCode.NUMPAD_POWER);
        variables.set('KEY_NUMPAD_PERCENT', lime.ui.KeyCode.NUMPAD_PERCENT);
        variables.set('KEY_NUMPAD_LESS_THAN', lime.ui.KeyCode.NUMPAD_LESS_THAN);
        variables.set('KEY_NUMPAD_GREATER_THAN', lime.ui.KeyCode.NUMPAD_GREATER_THAN);
        variables.set('KEY_NUMPAD_AMPERSAND', lime.ui.KeyCode.NUMPAD_AMPERSAND);
        variables.set('KEY_NUMPAD_VERTICAL_BAR', lime.ui.KeyCode.NUMPAD_VERTICAL_BAR);
        variables.set('KEY_NUMPAD_DOUBLE_VERTICAL_BAR', lime.ui.KeyCode.NUMPAD_DOUBLE_VERTICAL_BAR);
        variables.set('KEY_NUMPAD_COLON', lime.ui.KeyCode.NUMPAD_COLON);
        variables.set('KEY_NUMPAD_HASH', lime.ui.KeyCode.NUMPAD_HASH);
        variables.set('KEY_NUMPAD_SPACE', lime.ui.KeyCode.NUMPAD_SPACE);
        variables.set('KEY_NUMPAD_AT', lime.ui.KeyCode.NUMPAD_AT);
        variables.set('KEY_NUMPAD_EXCLAMATION', lime.ui.KeyCode.NUMPAD_EXCLAMATION);
        variables.set('KEY_NUMPAD_MEM_STORE', lime.ui.KeyCode.NUMPAD_MEM_STORE);
        variables.set('KEY_NUMPAD_MEM_RECALL', lime.ui.KeyCode.NUMPAD_MEM_RECALL);
        variables.set('KEY_NUMPAD_MEM_CLEAR', lime.ui.KeyCode.NUMPAD_MEM_CLEAR);
        variables.set('KEY_NUMPAD_MEM_ADD', lime.ui.KeyCode.NUMPAD_MEM_ADD);
        variables.set('KEY_NUMPAD_MEM_SUBTRACT', lime.ui.KeyCode.NUMPAD_MEM_SUBTRACT);
        variables.set('KEY_NUMPAD_MEM_MULTIPLY', lime.ui.KeyCode.NUMPAD_MEM_MULTIPLY);
        variables.set('KEY_NUMPAD_MEM_DIVIDE', lime.ui.KeyCode.NUMPAD_MEM_DIVIDE);
        variables.set('KEY_NUMPAD_PLUS_MINUS', lime.ui.KeyCode.NUMPAD_PLUS_MINUS);
        variables.set('KEY_NUMPAD_CLEAR', lime.ui.KeyCode.NUMPAD_CLEAR);
        variables.set('KEY_NUMPAD_CLEAR_ENTRY', lime.ui.KeyCode.NUMPAD_CLEAR_ENTRY);
        variables.set('KEY_NUMPAD_BINARY', lime.ui.KeyCode.NUMPAD_BINARY);
        variables.set('KEY_NUMPAD_OCTAL', lime.ui.KeyCode.NUMPAD_OCTAL);
        variables.set('KEY_NUMPAD_DECIMAL', lime.ui.KeyCode.NUMPAD_DECIMAL);
        variables.set('KEY_NUMPAD_HEXADECIMAL', lime.ui.KeyCode.NUMPAD_HEXADECIMAL);
        variables.set('KEY_LEFT_CTRL', lime.ui.KeyCode.LEFT_CTRL);
        variables.set('KEY_LEFT_SHIFT', lime.ui.KeyCode.LEFT_SHIFT);
        variables.set('KEY_LEFT_ALT', lime.ui.KeyCode.LEFT_ALT);
        variables.set('KEY_LEFT_META', lime.ui.KeyCode.LEFT_META);
        variables.set('KEY_RIGHT_CTRL', lime.ui.KeyCode.RIGHT_CTRL);
        variables.set('KEY_RIGHT_SHIFT', lime.ui.KeyCode.RIGHT_SHIFT);
        variables.set('KEY_RIGHT_ALT', lime.ui.KeyCode.RIGHT_ALT);
        variables.set('KEY_RIGHT_META', lime.ui.KeyCode.RIGHT_META);
        variables.set('KEY_MODE', lime.ui.KeyCode.MODE);
        variables.set('KEY_AUDIO_NEXT', lime.ui.KeyCode.AUDIO_NEXT);
        variables.set('KEY_AUDIO_PREVIOUS', lime.ui.KeyCode.AUDIO_PREVIOUS);
        variables.set('KEY_AUDIO_STOP', lime.ui.KeyCode.AUDIO_STOP);
        variables.set('KEY_AUDIO_PLAY', lime.ui.KeyCode.AUDIO_PLAY);
        variables.set('KEY_AUDIO_MUTE', lime.ui.KeyCode.AUDIO_MUTE);
        variables.set('KEY_MEDIA_SELECT', lime.ui.KeyCode.MEDIA_SELECT);
        variables.set('KEY_WWW', lime.ui.KeyCode.WWW);
        variables.set('KEY_MAIL', lime.ui.KeyCode.MAIL);
        variables.set('KEY_CALCULATOR', lime.ui.KeyCode.CALCULATOR);
        variables.set('KEY_COMPUTER', lime.ui.KeyCode.COMPUTER);
        variables.set('KEY_APP_CONTROL_SEARCH', lime.ui.KeyCode.APP_CONTROL_SEARCH);
        variables.set('KEY_APP_CONTROL_HOME', lime.ui.KeyCode.APP_CONTROL_HOME);
        variables.set('KEY_APP_CONTROL_BACK', lime.ui.KeyCode.APP_CONTROL_BACK);
        variables.set('KEY_APP_CONTROL_FORWARD', lime.ui.KeyCode.APP_CONTROL_FORWARD);
        variables.set('KEY_APP_CONTROL_STOP', lime.ui.KeyCode.APP_CONTROL_STOP);
        variables.set('KEY_APP_CONTROL_REFRESH', lime.ui.KeyCode.APP_CONTROL_REFRESH);
        variables.set('KEY_APP_CONTROL_BOOKMARKS', lime.ui.KeyCode.APP_CONTROL_BOOKMARKS);
        variables.set('KEY_BRIGHTNESS_DOWN', lime.ui.KeyCode.BRIGHTNESS_DOWN);
        variables.set('KEY_BRIGHTNESS_UP', lime.ui.KeyCode.BRIGHTNESS_UP);
        variables.set('KEY_DISPLAY_SWITCH', lime.ui.KeyCode.DISPLAY_SWITCH);
        variables.set('KEY_BACKLIGHT_TOGGLE', lime.ui.KeyCode.BACKLIGHT_TOGGLE);
        variables.set('KEY_BACKLIGHT_DOWN', lime.ui.KeyCode.BACKLIGHT_DOWN);
        variables.set('KEY_EJECT', lime.ui.KeyCode.EJECT);
        variables.set('KEY_SLEEP', lime.ui.KeyCode.SLEEP);

        variables.set('KEY_MODIFIER_NONE', lime.ui.KeyModifier.NONE);
        variables.set('KEY_MODIFIER_LEFT_SHIFT', lime.ui.KeyModifier.LEFT_SHIFT);
        variables.set('KEY_MODIFIER_RIGHT_SHIFT', lime.ui.KeyModifier.RIGHT_SHIFT);
        variables.set('KEY_MODIFIER_LEFT_CTRL', lime.ui.KeyModifier.LEFT_CTRL);
        variables.set('KEY_MODIFIER_RIGHT_CTRL', lime.ui.KeyModifier.RIGHT_CTRL);
        variables.set('KEY_MODIFIER_LEFT_ALT', lime.ui.KeyModifier.LEFT_ALT);
        variables.set('KEY_MODIFIER_RIGHT_ALT', lime.ui.KeyModifier.RIGHT_ALT);
        variables.set('KEY_MODIFIER_LEFT_META', lime.ui.KeyModifier.LEFT_META);
        variables.set('KEY_MODIFIER_RIGHT_META', lime.ui.KeyModifier.RIGHT_META);
        variables.set('KEY_MODIFIER_NUM_LOCK', lime.ui.KeyModifier.NUM_LOCK);
        variables.set('KEY_MODIFIER_CAPS_LOCK', lime.ui.KeyModifier.CAPS_LOCK);
        variables.set('KEY_MODIFIER_MODE', lime.ui.KeyModifier.MODE);
        variables.set('KEY_MODIFIER_CTRL', lime.ui.KeyModifier.CTRL);
        variables.set('KEY_MODIFIER_SHIFT', lime.ui.KeyModifier.SHIFT);
        variables.set('KEY_MODIFIER_ALT', lime.ui.KeyModifier.ALT);
        variables.set('KEY_MODIFIER_META', lime.ui.KeyModifier.META);

        variables.set('altKeyModifier', (modifiers:lime.ui.KeyModifier) -> { return modifiers.altKey; });
        variables.set('capsLockModifier', (modifiers:lime.ui.KeyModifier) -> { return modifiers.capsLock; });
        variables.set('ctrlKeyModifier', (modifiers:lime.ui.KeyModifier) -> { return modifiers.ctrlKey; });
        variables.set('metaKeyModifier', (modifiers:lime.ui.KeyModifier) -> { return modifiers.metaKey; });
        variables.set('numLockModifier', (modifiers:lime.ui.KeyModifier) -> { return modifiers.numLock; });
        variables.set('shiftKeyModifier', (modifiers:lime.ui.KeyModifier) -> { return modifiers.shiftKey; });

        variables.set('concat', (inputs:Array<String>, ?append:String) ->
        {
            var string = '';
            if (append != null) string = append;
            for (input in inputs) string += input;
    
            return string;
        });

        variables.set('moveFPS', Main.moveFPS);

        variables.set('HALF_WIDTH', Main.halfWidth);
        variables.set('HALF_HEIGHT', Main.halfHeight);

        variables.set('intersectsRect', (p:{x:Dynamic, y:Dynamic}, x:Float, y:Float, w:Float, h:Float) ->
        {
            return ((p.x >= x && p.x <= x + w) &&
                    (p.y >= y && p.y <= y + h));
        });
		
		var path:String = Paths.folder('custom_modules', dir);
		if (path == null) return;
		
		// add custom modules
		for (file in sys.FileSystem.readDirectory(path))
		{
			if (!file.endsWith(Paths.HX_FILE_EXT)) continue;
			addModule(Paths.mods.module([file.split('.')[0]], dir).content);
		}
    }
}