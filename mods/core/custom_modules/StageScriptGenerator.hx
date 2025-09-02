class StageScriptGenerator
{
    var script:String = '';

    var name:String;
    var stagePath:String;
    var version:String;

    public var modDir:String;

    var simpleShadows:Bool = false;

    var vars:Array<String> = [];
    var jobs:Array<String> = [];

    var layerNames:Array<String> = [];
    var layers:Array<String> = [];

    var blendModes:Array<String> = [];

    public function new(_name:String, _stagePath:String, _version:String)
    {
        name = _name;
        stagePath = _stagePath;
        version = _version;
    }

    function pushVarToDatabase(_name:String)
    {
        if (vars.contains(_name)) return;
        vars.push(_name);
    }

    function buildVars()
    {
        script += '\n';
        for (_name in vars)
            script += concat(['\n', 'var ', _name, ';']);
    }

    function pushLayerToDatabase(_name:String)
    {
        if (layerNames.contains(_name)) return;

        layerNames.push(_name);
        layers.push(concat(['layer_', _name, ' = {', '\n    name: ', "'", _name, "',", '\n    elements: []', '\n}']));
    }

    function createLayers()
    {
        script += '\n';
        for (layer in layers) script += concat(['\nvar ', layer]);
    }

    function completeLayers()
    {
        for (layer in layerNames) script += concat(['\n    addLayerToStageLayers(layer_', layer, ');']);
    }

    function setModDirectory(_dir:String)
    {
        modDir = _dir;
    }

    function buildComment(date:String, windowTitle:String)
    {
        var pathString = '';
        if (stagePath != null)
            pathString = concat(['\n// ', windowTitle, ' - ', stagePath]);

        script += concat(['// generated with TIME Stage Editor v', version, 
                           '\n// ', date, 
                           pathString, 
                           '\n\n// Do NOT add new functionality to this script. Please create a new one,', 
                           '\n// all changes get overwritten if stage is saved again in the editor.']);
    }

    function createFunction(_name:String, args:Array<String>)
    {
        script += concat(['\n\nfunction ', _name, '(', concat(args), ')', '\n{']);
    }

    function completeFunction(newLine:Bool = true)
    {
        script += concat([newLine ? '\n' : '', '}']);
    }

    var pad:String = '\n    ';
    var pos:String;
    var declr:String;
    var animations:String;
    var visible:String;
    var scroll:String;
    var scale:String;
    var skew:String;
    var offset:String;
    var alpha:String;
    var flipX:String;
    var flipY:String;
    var color:String;
    var antialias:String;
    var blend:String;

    var o:Dynamic;
    var varName:String;
    var objName:String;
    var objDeclr:String;
    var sobj:String;

    var pay:Array<Dynamic>;
    var payString:String;
    var push:Bool;

    function buildSprite(object:SObj)
    {
        o = object.object;

        pos = '';
        if ((o.x != 0 || o.y != 0))
            pos = concat([o.x, ', ', o.y]);

        varName = getVarName(object.name);
        objName = varName + '_obj';

        declr = concat([varName, ' = new FlxSprite(', pos, ").load(Paths.mods.stage.image(['", name, "', '", object.graphic, "'], '", modDir, "').content);"], pad);
        objDeclr = concat([objName, " = new SObj('", object.name, "', '", object.graphic, "', ", varName, ", ", object.zIndex, ");"], pad);

        if (object.isBackdrop)
        {
            declr = concat([varName, " = new FlxBackdrop(Paths.mods.stage.image(['", name, "', '", object.graphic, "'], '", modDir, "').content));"], pad);
            if (o.x != 0 || o.y != 0)
                declr += concat([varName, '.setPosition(', pos, ');'], pad);

            if (object.tileAxes != 'AXES_XY')
                declr += concat([varName, '.repeatAxes = ', object.payload[1], ';'], pad);
        
            objDeclr += concat([objName, '.isBackdrop = true;'], pad);
        }

        animations = '';
        if (object.isAnimated)
        {
            declr = concat([varName, " = new FlxSprite(", pos, ").loadAtlas(Paths.mods.stage.atlas(['", name "', '", object.graphic, "'], '", modDir, "').content);"], pad);
            objDeclr += concat([objName, '.isAnimated = true;'], pad);

            privateAccess(() ->
            {
                for (anim in o.animation._animations.keys())
                {
                    var animData = object.getAnimationByName(anim);
                    var flxAnim = o.animation._animations.get(anim);

                    animations += concat(["\n    addObjectAnimation(", objName, ", '", animData.name, "', '", animData.tag, "', ", flxAnim.frameRate, ", ", 
                                                                       flxAnim.looped, ", ", flxAnim.loopPoint, ", ", flxAnim.flipX, ", ", flxAnim.flipY, ");"]);
                }
            });

            jobs.push(concat(['\n    registerAssetToLoad({', '\n        method: Paths.mods.stage.atlas,', 
                              "\n        keys: ['", name, "', '", object.graphic, "']\n    });"], pad));
        }
        else
            jobs.push(concat(['\n    registerAssetToLoad({', '\n        method: Paths.mods.stage.image,', 
                              "\n        keys: ['", name, "', '", object.graphic, "']\n    });"], pad));

        visible = '';
        if (!o.visible)
            visible = concat([varName, '.visible = false;'], pad);

        scroll = '';
        if ((o.scrollFactor.x != 1 || o.scrollFactor.y != 1))
            scroll = concat([varName, '.scrollFactor.set(', o.scrollFactor.x, ', ', o.scrollFactor.y, ');'], pad);

        scale = '';
        if ((o.scale.x != 1 || o.scale.y != 1))
            scale = concat([varName, '.scale.set(', o.scale.x, ', ', o.scale.y, ');'], pad);

        if (!object.isBackdrop)
        {
            skew = '';
            if ((o.skew.x != 0 || o.skew.y != 0))
                skew = concat([varName, '.skew.set(', o.skew.x, ', ', o.skew.y, ');'], pad);
        }

        offset = '';
        if ((o.offset.x != 0 || o.offset.y != 0))
            scale = concat([varName, '.offset.set(', o.offset.x, ', ', o.offset.y, ');'], pad);

        alpha = '';
        if (o.alpha != 1)
            alpha = concat([varName, '.alpha = ', o.alpha, ';'], pad);

        flipX = '';
        if (o.flipX)
            flipX = concat([varName, '.flipX = ', o.flipX, ';'], pad);

        flipY = '';
        if (o.flipY)
            flipY = concat([varName, '.flipY = ', o.flipY, ';'], pad);

        color = '';
        if (o.color != -1)
            color = concat([varName, '.color = ', o.color, ';'], pad);

        antialias = '';
        if (object.tryAntialias)
            antialias = concat([varName, ".antialiasing = ClientPrefs.get('antialiasing');"], pad);

        blend = '';
        if (o.blend != null && blendModes[o.blend] != 'Normal')
            blend = concat([varName, ".blend = blendModeFromString('", blendModes[o.blend], "');"], pad);

        sobj = concat(["var obj = new SObj('", object.name, "', '", object.graphic, "', ", varName, ", ", object.zIndex, ");"], pad);
        push = true;

        if (!object.tryAntialias) sobj += concat(["obj.tryAntialias = false;"], pad);
        else 
        {
            sobj = concat(['layer_', object.layer, ".elements.push(", objName, ");"], pad);
            push = false;
        }

        if (push)
            sobj += concat(['layer_', object.layer, '.elements.push(obj);'], pad);

        script += concat([declr, visible, scroll, scale, skew, offset, alpha, flipX, flipY, color, antialias, blend, objDeclr, animations, sobj, '\n']);
    }

    var opp:String;
    var checkShadows:Bool = true;

    var zIndex:String;

    var shadows:String;

    var offsets:Map<String, Array<String>>;
    var scales:Map<String, Array<String>>;
    var skews:Map<String, Array<String>>;

    var hasOff:Bool;
    var hasScale:Bool;
    var hasSkew:Bool;

    var baseOrigin:Array<Float>;
    var baseOffset:Array<Float>;
    var baseScale:Array<Float>;
    var baseSkew:Array<Float>;

    var shadowAlpha:Float;

    var curName:String;

    var anyChange:Bool = false;
    var animsDone:Array<String> = [];

    var sprAngle:Float;

    function buildCharacter(object:SObj, lastOne:Bool = false)
    {
        animsDone = [];
        o = object.object;

        pos = '';
        if (o.x != 0 || o.y != 0)
            pos = concat(['.setPosition(', o.x, ', ', o.y, ')']);

        varName = concat(["char('", o.name, "')"], pad);
        jobs.push(concat(["registerCharacterToLoad('", o.name, "');"], pad));

        opp = '';
        if (!o.player)
            opp = concat(["registerAsOpp('", o.name, "');"], pad);

        declr = concat([varName, pos, ';']);

        zIndex = '';
        if (object.zIndex != 0)
            zIndex = concat([varName, '.zIndex = ', object.zIndex, ';']);

        scale = '';
        if (o.scale.x != o.characterJsonData.scale || o.scale.y != o.characterJsonData.scale)
            scale = concat([varName, '.setScale(', o.scale.x, ', ', o.scale.y, ');']);

        scroll = '';
        if (o.scrollFactor.x != 1 || o.scrollFactor.y != 1)
            scroll = concat([varName, '.scrollFactor.set(', o.scrollFactor.x, ', ', o.scrollFactor.y, ');']);

        skew = '';
        if (o.skew.x != 0 || o.skew.y != 0)
            skew = concat([varName, '.skew.set(', o.skew.x, ', ', o.skew.y, ');']);

        sprAngle = '';
        if (o.angle != 0)
            sprAngle = concat([varName, '.angle = ', o.angle, ';']);

        alpha = '';
        if (o.alpha != 1)
            alpha = concat([varName, '.alpha = ', o.alpha, ';']);

        visible = '';
        if (!o.visible)
            visible = concat([varName, '.visible = false;']);

        flipY = '';
        if (o.flipY)
            flipY = concat([varName, '.flipY = ', o.flipY, ';']);

        color = '';
        if (o.color != -1)
            color = concat([varName, '.color = ', o.color, ';']);

        if (checkShadows)
        {
            simpleShadows = o.simpleShadows;
            checkShadows = false;
        }

        shadows = '';

        baseOrigin = o.baseOrigin;
        baseOffset = o.baseOffset;
        baseScale = o.baseScale;
        baseSkew = o.baseSkew;

        shadowAlpha = o.shadowAlpha;

        if (baseOrigin.x != 0 || baseOrigin.y != 0) shadows += concat([varName, '.baseOrigin = {x: ', baseOrigin.x, ', y: ', baseOrigin.y '}']);
        if (baseOffset.x != 0 || baseOffset.y != 0) shadows += concat([varName, '.baseOffset = {x: ', baseOffset.x, ', y: ', baseOffset.y '}']);
        if (baseScale.x != 1 || baseScale.y != 1) shadows += concat([varName, '.baseScale = {x: ', baseScale.x, ', y: ', baseScale.y '}']);
        if (baseSkew.x != 0 || baseSkew.y != 0) shadows += concat([varName, '.baseSkew = {x: ', baseSkew.x, ', y: ', baseSkew.y '}']);

        if (o.shadowAlpha != 0) shadows += concat([varName, '.shadowAlpha = ', shadowAlpha, ';']);

        for (key in o.animations.keys())
        {
            var anim = o.animations.get(key);

            curName = anim.name;
            if (animsDone.contains(curName)) continue;

            animsDone.push(curName);

            offsets = o.shadowOffsets.get(curName);
            scales = o.shadowScales.get(curName);
            skews = o.shadowSkews.get(curName);

            hasOff = offsets.x != 0 || offsets.y != 0;
            hasScale = scales.x != 0 || scales.y != 0;
            hasSkew = skews.x != 0 || skews.y != 0;

            if (hasOff) shadows += concat([varName, ".shadowOffsets.set('", curName, "', {x: ", offsets.x, ', y: ', offsets.y, '});']);
            if (hasScale) shadows += concat([varName, ".shadowScales.set('", curName, "', {x: ", scales.x, ', y: ', scales.y, '});']);
            if (hasSkew) shadows += concat([varName, ".shadowSkews.set('", curName, "', {x: ", skews.x, ', y: ', skews.y, '});']);

            anyChange = hasOff || hasScale || hasSkew;
        }

        script += concat([opp, declr, zIndex, scale, scroll, skew, sprAngle, alpha, visible, flipY, color, shadows, lastOne ? '' : (anyChange ? '' : '\n')]);
    }

    var light:Dynamic;
    var rim:String;

    var hasOverlay:Bool = false;
    var hasSatin:Bool = false;
    var hasInner:Bool = false;
    var hasAngle:Bool = false;
    var hasDist:Bool = false;

    var overlay:Array<Float>;
    var satin:Array<Float>;
    var inner:Array<Float>;
    var angle:Float;
    var dist:Float;

    function buildRimLight(obj:SObj)
    {
        o = obj.object;
        light = o.rimLightShader;

        varName = '';
        if (obj.isCharacter) varName = concat(["char('", o.name, "')"], pad);
        else varName = concat([getVarName(obj.name)], pad);

        if (light == null) return;

        overlay = light.getFloatArray('overlayColor');
        satin = light.getFloatArray('satinColor');
        inner = light.getFloatArray('innerShadowColor');
        angle = light.getFloat('innerShadowAngle');
        dist = light.getFloat('innerShadowDistance');

        hasOverlay = overlay[3] != 0;
        hasSatin = satin[3] != 0;
        hasInner = inner[3] != 0;
        hasAngle = angle != 0;
        hasDist = dist != 0;

        if (!hasOverlay && !hasSatin && !hasInner && !hasAngle && !hasDist) return;

        rim = '';

        if (obj.isCharacter)
        {
            if (hasOverlay) rim += concat([varName, ".rimLightShader.setFloatArray('overlayColor', ", overlay, ');']);
            if (hasSatin) rim += concat([varName, ".rimLightShader.setFloatArray('satinColor', ", satin, ');']);
            if (hasInner) rim += concat([varName, ".rimLightShader.setFloatArray('innerShadowColor', ", inner, ');']);
            if (hasAngle) rim += concat([varName, ".rimLightShader.setFloat('innerShadowAngle', ", angle, ');']);
            if (hasDist) rim += concat([varName, ".rimLightShader.setFloat('innerShadowDistance', ", dist, ');']);
        }
        else
        {
            if (hasOverlay) rim += concat([pad, "rimFloatArray('", obj.name, "', 'overlayColor', ", overlay, ');']);
            if (hasSatin) rim += concat([pad, "rimFloatArray('", obj.name, "', 'satinColor', ", satin, ');']);
            if (hasInner) rim += concat([pad, "rimFloatArray('", obj.name, "', 'innerShadowColor', ", inner, ');']);
            if (hasAngle) rim += concat([pad, "rimFloat('", obj.name, "', 'innerShadowAngle', ", angle, ');']);
            if (hasDist) rim += concat([pad, "rimFloat('", obj.name, "', 'innerShadowDistance', ", dist, ');']);
        }
        
        script += concat([rim, '\n']);
    }

    function setShadowMode()
    {
        if (!simpleShadows) return;

        script += '\n\n    setSimpleShadows(true);';
    }

    function buildLoadingFunction()
    {
        createFunction('load', []);
        for (job in jobs) script += job;
        script += '\n';
        completeFunction();
    }

    var numbersToLetters = [
        'zero',
        'one',
        'two',
        'three',
        'four',
        'five',
        'six',
        'seven',
        'eight',
        'nine'
    ];

    var output:String;
    function getVarName(_name:String):String
    {
        output = _name;

        output = StringTools.replace(output, ' ', '_');
        output = StringTools.replace(output, '-', '_');
        output.toLowerCase();

        var replaced = false;
        for (i in 0...10) 
        {
            if (replaced) break;

            var num = '' + i;
            if (StringTools.startsWith(output, num)) 
            {
                output = StringTools.replace(output, num, numbersToLetters[i]);
                replaced = true;
            }
        }

        // trace(concat(['Var Name: ', output]));

        return output;
    }
}