package a2.time.util;

import a2.time.backend.Paths;

import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.windows.Window;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.core.Component;
import haxe.ui.dragdrop.DragManager;
import haxe.ui.events.MouseEvent;
import haxe.ui.geom.Rectangle;

import flixel.FlxCamera;
import flixel.FlxG;

typedef DialogOptions =
{
	var content:Component;
	var title:String;
	@:optional var buttons:Array<String>; 
	@:optional var modal:Bool;
	@:optional var callback:Dynamic; 
	@:optional var camera:FlxCamera;
	@:optional var persist:Bool;
}

typedef QuitDialogOptions =
{
	var callback:Dynamic;
	@:optional var content:Component;
	@:optional var title:String;
	@:optional var prompt:String;
	@:optional var buttons:Array<String>;
	@:optional var camera:FlxCamera;
}

class UIShortcuts
{
	public static inline function buildXml(keys:Array<String>, ?allowDispose:Bool = true, mod:String = Main.MOD_NAME)
	{
		var xml = Paths.mods.ui.xml(keys, mod);
		var build:Component = haxe.ui.RuntimeComponentBuilder.fromString(xml.content);

		return build;
	}

	// `get` instead of `getChild` for brevity
	// also depth of -1 only searches 100 layers deep
	// if your ui has that many layers just abstract parts please
	public static inline function get(styleName:String, target:Component, ?typeCast:Dynamic) return target.findComponents(styleName, typeCast, -1)[0];
	public static inline function gets(styleName:String, target:Component, ?typeCast:Dynamic) return target.findComponents(styleName, typeCast, -1);

	public static inline function getContextMenu(e:MouseEvent, key:String, mod:String = Main.MOD_NAME)
	{
		var context = buildXml([key], true, mod);
		context.left = e.screenX + 1;
        context.top = e.screenY + 1;

		return context;
	}

	public static inline function addNotification(data:Dynamic, camera:FlxCamera) haxe.ui.notifications.NotificationManager.instance.addNotification(data).cameras = [camera];

	public static inline function registerDraggable(target:Component, ?handle:Component)
	{
		DragManager.instance.registerDraggable(target, {
			dragBounds: new Rectangle(0, 0, FlxG.width, FlxG.height),
			mouseTarget: handle != null ? handle : null
		});
	}

	public static inline function openOpenFileDialog(extData:Dynamic, callback:haxe.ui.containers.dialogs.DialogButton->Array<Dynamic>->Void, ?defaultPath:String):Void 
		haxe.ui.containers.dialogs.Dialogs.openFile(callback, {multiple: false, extensions: extData, defaultPath: defaultPath});
	
	public static inline function openDialog(options:DialogOptions)
	{
		var buttonString:String = '';
		
		if (options.buttons != null) for (button in options.buttons)
			buttonString += '$button | ';

		buttonString = buttonString.substring(0, buttonString.length - 3);

		var modal:Bool = options.modal != null ? options.modal : true;
		var dialogue = haxe.ui.containers.dialogs.Dialogs.dialog(options.content, options.title, cast buttonString, modal);

		var persist = options.persist != null ? options.persist : false;

        // thank you haxe discord "destroy dialog in:haxeui"
        dialogue.destroyOnClose = !persist;

		if (options.camera != null)
		{
			dialogue.cameras = [options.camera];
			@:privateAccess dialogue._overlay.cameras = [options.camera];
		}

		if (options.callback != null)
        	dialogue.onDialogClosed = options.callback;

		return dialogue;
	}
	
	public static var QUIT_DIALOG_TITLE:String = 'Warning!';
	public static var QUIT_DIALOG_PROMPT:String = 'Unsaved changes will be lost!\nAre you sure you want to quit?';
	public static var QUIT_DIALOG_CONTENT:String = '
	<?xml version="1.0" encoding="utf-8"?>
	<hbox width="100%">
        <image resource="haxeui-core/styles/shared/error-large.png" />
		<label styleNames="content-text" text="$QUIT_DIALOG_PROMPT" width="100%" verticalAlign="center" />
    </hbox>';
	public static var QUIT_DIALOG_BUTTONS:Array<String> = ['Save & Quit', 'Quit Without Saving', 'No, Stay'];

	public static inline function openQuitDialog(options:QuitDialogOptions)
	{
		var title:String = Reflect.hasField(options, 'title') ? options.title : QUIT_DIALOG_TITLE;

		var content:Component;
		var setCustomContent:Bool = false;
		if (Reflect.hasField(options, 'content')) 
		{
			content = options.content;
			setCustomContent = true;
		}
		else content = haxe.ui.RuntimeComponentBuilder.fromString(QUIT_DIALOG_CONTENT);

		if (Reflect.hasField(options, 'prompt') && !setCustomContent) 
			get('content-text', content).text = options.prompt;

		return openDialog({
			content: content,
			title: title,
			buttons: Reflect.hasField(options, 'buttons') ? options.buttons : QUIT_DIALOG_BUTTONS,
			callback: options.callback,
			camera: Reflect.hasField(options, 'camera') ? options.camera : null
		});
	}

	public static inline function getModsDropdown(callback:Dynamic):haxe.ui.components.DropDown
	{
		var source = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (mod in Paths.directories)
			source.add({text: mod});

		var drop = new haxe.ui.components.DropDown();
		drop.dataSource = source;
		drop.searchable = true;
		drop.searchPrompt = 'Find mod...';
		drop.width = 150;
		drop.selectedItem = {text: Paths.WORKING_MOD_DIRECTORY};
		drop.onChange = (e) ->
		{
			if (drop.selectedItem == null)
				return;

			Paths.WORKING_MOD_DIRECTORY = drop.selectedItem.text;

			if (callback != null)
				callback();
		}

		return drop;
	}

    public static inline function addSpacer(w:Int, h:Int, uiElement:Dynamic):haxe.ui.components.Spacer
    {
        var spacer = new haxe.ui.components.Spacer();
		spacer.height = h;
		spacer.width = w;

        uiElement.addComponent(spacer);

		return spacer;
    }

    public static inline function addHR(padding, uiElement:Dynamic):haxe.ui.components.HorizontalRule
	{
		var spacer = new haxe.ui.components.Spacer();
		spacer.height = padding;

		var rule = new haxe.ui.components.HorizontalRule();

		uiElement.addComponent(spacer);
		uiElement.addComponent(rule);
		uiElement.addComponent(spacer);

		return rule;
	}

	public static inline function addVR(padding, uiElement:Dynamic):haxe.ui.components.VerticalRule
	{
		var spacer = new haxe.ui.components.Spacer();
		spacer.width = padding;

		var rule = new haxe.ui.components.VerticalRule();
		rule.percentHeight = 100;

		uiElement.addComponent(spacer);
		uiElement.addComponent(rule);
		uiElement.addComponent(spacer);

		return rule;
	}

	public static inline function addHeader(text:String, uiElement:Dynamic):haxe.ui.components.SectionHeader
	{
		var header = new haxe.ui.components.SectionHeader();
		header.text = text;

		uiElement.addComponent(header);

		return header;
	}

	public static inline function addLabel(text:String, uiElement:Dynamic):haxe.ui.components.Label
	{
		var label = new haxe.ui.components.Label();
		label.text = text;

		uiElement.addComponent(label);

		return label;
	}

	public static inline function getWindow(title:String, closable:Bool = false, minimizable:Bool = true, maximizable:Bool = false, draggable:Bool = true):haxe.ui.containers.windows.Window
	{
		var window = new haxe.ui.containers.windows.Window();
		window.title = title;

		window.closable = closable;
		window.minimizable = minimizable;
		window.maximizable = maximizable;
		window.draggable = draggable;

		// @:privateAccess window._allowDispose = false;

		return window;
	}
}