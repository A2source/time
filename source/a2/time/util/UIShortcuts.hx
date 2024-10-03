package a2.time.util;

class UIShortcuts
{
	public static inline function getModsDropdown(callback:Dynamic):haxe.ui.components.DropDown
	{
		var source = new haxe.ui.data.ArrayDataSource<Dynamic>();
		for (mod in Paths.getModDirectories())
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

    public static inline function addSpacer(w:Int, h:Int, uiElement:Dynamic)
    {
        var spacer = new haxe.ui.components.Spacer();
		spacer.height = h;
		spacer.width = w;

        uiElement.addComponent(spacer);
    }

    public static inline function addHR(padding, uiElement:Dynamic)
	{
		var spacer = new haxe.ui.components.Spacer();
		spacer.height = padding;

		uiElement.addComponent(spacer);
		uiElement.addComponent(new haxe.ui.components.HorizontalRule());
		uiElement.addComponent(spacer);
	}

	public static inline function addVR(padding, uiElement:Dynamic)
	{
		var spacer = new haxe.ui.components.Spacer();
		spacer.width = padding;

		var rule = new haxe.ui.components.VerticalRule();
		rule.percentHeight = 100;

		uiElement.addComponent(spacer);
		uiElement.addComponent(rule);
		uiElement.addComponent(spacer);
	}

	public static inline function addHeader(text:String, uiElement:Dynamic)
	{
		var header = new haxe.ui.components.SectionHeader();
		header.text = text;

		uiElement.addComponent(header);
	}

	public static inline function addLabel(text:String, uiElement:Dynamic)
	{
		var label = new haxe.ui.components.Label();
		label.text = text;

		uiElement.addComponent(label);
	}

	public static inline function getWindow(title:String, closable:Bool = false, minimizable:Bool = true, maximizable:Bool = false, draggable:Bool = true):haxe.ui.containers.windows.Window
	{
		var window = new haxe.ui.containers.windows.Window();
		window.title = title;

		window.closable = closable;
		window.minimizable = minimizable;
		window.maximizable = maximizable;
		window.draggable = draggable;

		@:privateAccess window._allowDispose = false;

		return window;
	}
}