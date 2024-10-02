package a2.time.states.editors;

import a2.time.objects.gameplay.Character;
import a2.time.objects.gameplay.Character.CharacterMetadata;
import a2.time.objects.gameplay.HealthIcon;
import a2.time.util.ClientPrefs;
import a2.time.util.Paths;
import a2.time.util.Discord.DiscordClient;
import a2.time.util.UIShortcuts as UiS;

import haxe.ui.Toolkit;

import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import lime.system.Clipboard;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.FlxBasic;
import lime.app.Application;
import flixel.util.FlxTimer;
import openfl.Lib;
import flixel.ui.FlxBar;

import haxe.ui.Toolkit;

import sys.FileSystem;
import sys.io.File;

using StringTools;

class CharacterEditorState extends MusicBeatState
{
	var char:Character;
	var ghostChar:Character;

	var daAnim:String = 'bf';
	var goToPlayState:Bool = true;

	var camFollow:FlxObject;

	var isPlayer:Bool = true;

	public function new(daAnim:String = 'bf', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.goToPlayState = goToPlayState;

		this.isPlayer = !goToPlayState;
	}

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;

	var stage:FlxSprite;

	var bfOutline:FlxSprite;
	var dadOutline:FlxSprite;

	var outlines:FlxSpriteGroup;
	var dadPosition = FlxPoint.weak();
	var bfPosition = FlxPoint.weak();

	var positionText:FlxText;
	var animText:FlxText;
	var trailText:FlxText;
	var editText:FlxText;
	var mouseText:FlxText;
	var helpText:FlxText;

	var positionEditMode:String = 'Offsets';

	var mouseLocked:Bool = true;
	var prevMouseLocked:Bool = true;

	var charNamesAndPaths:Map<String, String> = new Map();

	var charHealthBar:FlxSprite;
	var charIcons:FlxSprite;
	
	var iconColSelectOverlay:FlxSprite;
	var iconForColButton:FlxSprite;
	var gettingIconCol:Bool = false;

	var alertTitleString = 'FNF: TIME';

	var curAnim:Dynamic = 
	{
		index: 0,
		name: '',
		ref: null
	}
	var curTrailAnim:Dynamic = 
	{
		index: 0,
		name: '',
		ref: null
	}

	// HAXE UI
	var haxeUIBox:haxe.ui.containers.TabView;

	var animationsTab:haxe.ui.containers.Box;
	var characterTab:haxe.ui.containers.Box;
	var contentTab:haxe.ui.containers.Box;
	var createTab:haxe.ui.containers.Box;
	var metaTab:haxe.ui.containers.Box;
	//
	
	override function create()
	{
		super.create();

		FlxG.sound.pause();

		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);

		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

		cameraFollowPointer = new FlxSprite().loadGraphic(Paths.image('cursorCross'));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;

		dadPosition.set(100, 100);
		bfPosition.set(770, 100);

		camFollow = new FlxObject(dadPosition.x + 700, 475);
		add(camFollow);

		camEditor.zoom = 0.5;
		camEditor.follow(camFollow);

		stage = new FlxSprite(-335, 675).loadGraphic(Paths.image('floor'));
		stage.antialiasing = ClientPrefs.data.antialiasing;
		add(stage);

		outlines = new FlxSpriteGroup();
		add(outlines);

		dadOutline = new FlxSprite(dadPosition.x, dadPosition.y).loadGraphic(Paths.image('silhouetteDad'));
		dadOutline.antialiasing = ClientPrefs.data.antialiasing;
		dadOutline.offset.set(-4, 1);
		outlines.add(dadOutline);

		bfOutline = new FlxSprite(bfPosition.x, bfPosition.y + 350).loadGraphic(Paths.image('silhouetteBF'));
		bfOutline.antialiasing = ClientPrefs.data.antialiasing;
		bfOutline.offset.set(-6, 2);
		outlines.add(bfOutline);

		outlines.alpha = 0.25;

		FlxG.mouse.visible = true;

		char = new Character(0, 0, daAnim, isPlayer, NORMAL, true);

		add(char.trailChar);
		add(char);
		add(cameraFollowPointer);

		trace(cameraFollowPointer);

		setCharAnim(char.animationsArray[0].anim);
		resetTrail();

		var bigBox = new haxe.ui.containers.HBox();
		UiS.addSpacer(880, 0, bigBox);

		haxeUIBox = new haxe.ui.containers.TabView();
		haxeUIBox.closable = false;
		haxeUIBox.width = 400;

		animationsTab = new haxe.ui.containers.Box();
		animationsTab.text = 'Animations';

		characterTab = new haxe.ui.containers.Box();
		characterTab.text = 'Character';

		contentTab = new haxe.ui.containers.Box();
		contentTab.text = 'Content';

		createTab = new haxe.ui.containers.Box();
		createTab.text = 'Create';

		metaTab = new haxe.ui.containers.Box();
		metaTab.text = 'Metadata';

		haxeUIBox.addComponent(animationsTab);
		haxeUIBox.addComponent(characterTab);
		haxeUIBox.addComponent(contentTab);
		haxeUIBox.addComponent(createTab);
		haxeUIBox.addComponent(metaTab);

		addAnimationHaxeUI();
		addCharacterHaxeUI();
		addContentHaxeUI();
		addCreateHaxeUI();
		addMetaHaxeUI();

		bigBox.addComponent(haxeUIBox);
		uiLayer.addComponent(bigBox);

		haxeUIBox.selectedPage = characterTab;

		positionText = new FlxText(5, FlxG.height, 0, 'Position: (${char.positionArray[0]}, ${char.positionArray[1]})', 16);
		positionText.cameras = [camMenu];
		positionText.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		positionText.borderColor = FlxColor.BLACK;
		positionText.scrollFactor.set();
		positionText.borderSize = 2;
		positionText.y -= positionText.height + 5;
		add(positionText);

		animText = new FlxText(5, FlxG.height, 0, '', 16);
		animText.cameras = [camMenu];
		animText.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		animText.borderColor = FlxColor.BLACK;
		animText.scrollFactor.set();
		animText.borderSize = 2;
		animText.y -= positionText.height + animText.height + 5;
		add(animText);

		trailText = new FlxText(5, FlxG.height, 0, '', 16);
		trailText.cameras = [camMenu];
		trailText.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		trailText.borderColor = FlxColor.BLACK;
		trailText.scrollFactor.set();
		trailText.borderSize = 2;
		trailText.alpha = 0.5;
		trailText.y -= positionText.height + animText.height + trailText.height + 5;
		add(trailText);

		editText = new FlxText(5, FlxG.height, 0, "", 16);
		editText.cameras = [camMenu];
		editText.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		editText.borderColor = FlxColor.BLACK;
		editText.scrollFactor.set();
		editText.borderSize = 2;
		editText.y -= positionText.height + animText.height + trailText.height + editText.height + 5;
		add(editText);

		mouseText = new FlxText(0, 0, 0, "x", 4);
		mouseText.cameras = [camMenu];
		mouseText.setFormat(null, 16, FlxColor.RED, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		mouseText.borderColor = FlxColor.BLACK;
		mouseText.scrollFactor.set();
		mouseText.borderSize = 2;
		mouseText.alignment = 'right';
		add(mouseText);

		helpText = new FlxText(FlxG.width - 5, FlxG.height, 0, 'Press "F1" for help', 16);
		helpText.cameras = [camMenu];
		helpText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		helpText.borderColor = FlxColor.BLACK;
		helpText.scrollFactor.set();
		helpText.borderSize = 2;
		helpText.y -= helpText.height + 5;
		helpText.x -= helpText.width + 5;
		add(helpText);

		charHealthBar = new FlxSprite(5, editText.y - 50).makeGraphic(250, 5);
		charHealthBar.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
		charHealthBar.cameras = [camMenu];

		var outline = new FlxSprite(charHealthBar.x - 4, charHealthBar.y - 4).makeGraphic(Std.int(charHealthBar.width + 8), Std.int(charHealthBar.height + 8), 0xFF000000);
		outline.cameras = [camMenu];

		add(outline);
		add(charHealthBar);

		charIcons = new FlxSprite(charHealthBar.x, charHealthBar.y - 150);
		charIcons.cameras = [camMenu];
		add(charIcons);

		iconColSelectOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		iconColSelectOverlay.cameras = [camMenu];
		iconColSelectOverlay.alpha = 0;
		add(iconColSelectOverlay);

		iconForColButton = new FlxSprite();
		iconForColButton.cameras = [camMenu];
		iconForColButton.visible = false;
		add(iconForColButton);

		loadCharIcons();

		updateCharacterPositions();

		updatePointerPos();

		FlxG.mouse.visible = true;

		uiLayer.cameras = [camMenu];
	}

	var animHeader:haxe.ui.components.SectionHeader;
	var animSheet:haxe.ui.components.TextField;
	var animTag:haxe.ui.components.TextField;
	var animIndices:haxe.ui.components.TextField;
	var animFPS:haxe.ui.components.NumberStepper;
	var animLoop:haxe.ui.components.CheckBox;

	var animNamesView:haxe.ui.containers.ScrollView;
	var animNamesViewContent:haxe.ui.components.Label;

	var animCreateDialogue:haxe.ui.containers.dialogs.Dialog;
	var animCreateName:haxe.ui.components.TextField;
	function addAnimationHaxeUI()
	{
		var formatBox = new haxe.ui.containers.VBox();

		animHeader = new haxe.ui.components.SectionHeader();
		animHeader.text = curAnim.name;
		formatBox.addComponent(animHeader);

		UiS.addLabel('Spritesheet', formatBox);

		animSheet = new haxe.ui.components.TextField();
		animSheet.text = curAnim.ref.sheet;
		animSheet.placeholder = 'Enter sheet name...';
		formatBox.addComponent(animSheet);

		UiS.addSpacer(0, 10, formatBox);
		UiS.addLabel('XML Tag', formatBox);

		animTag = new haxe.ui.components.TextField();
		animTag.text = curAnim.ref.name;
		animTag.placeholder = 'Enter XML tag...';
		formatBox.addComponent(animTag);

		UiS.addSpacer(0, 10, formatBox);
		UiS.addLabel('Indices', formatBox);

		animIndices = new haxe.ui.components.TextField();
		animIndices.text = '${curAnim.ref.indices}'.replace('[', '').replace(']', '');
		animIndices.placeholder = '0, 1, 2, 3, etc';
		formatBox.addComponent(animIndices);

		UiS.addHR(7, formatBox);

		UiS.addLabel('FPS', formatBox);

		animFPS = new haxe.ui.components.NumberStepper();
		animFPS.min = 1;
		animFPS.max = 999;
		animFPS.step = 1;
		animFPS.precision = 0;
		animFPS.pos = curAnim.ref.fps;
		formatBox.addComponent(animFPS);

		UiS.addSpacer(0, 15, formatBox);

		animLoop = new haxe.ui.components.CheckBox();
		animLoop.text = 'Loop?';
		animLoop.selected = curAnim.ref.loop;
		formatBox.addComponent(animLoop);

		UiS.addHR(7, formatBox);

		var buttonBox = new haxe.ui.containers.HBox();

		var updateButton = new haxe.ui.components.Button();
		updateButton.text = 'Update';
		updateButton.onClick = function(e)
		{
			curAnim.ref.name = animTag.text;

			var sheet = animSheet.text;
			curAnim.ref.sheet = sheet;

			if (Paths.charImage(char.name, sheet) == null)
				return;

			curAnim.ref.fps = animFPS.value;

			curAnim.ref.loop = animLoop.selected;

			// normal
			var addFrames:Bool = false;
			if (!char.spriteSheets.contains(sheet))
			{
				char.spriteSheets.push(sheet);
				char.sheetAnimations.push(new FlxAnimationController(char));
				addFrames = true;

				updateContentUI();
			}

			char.frames = Paths.getCharSparrow(char.name, sheet);
			var controller = char.sheetAnimations[char.spriteSheets.indexOf(sheet)];

			if (addFrames)
				char.sheetFrames.push(char.frames);

			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animIndices.text.trim().split(',');
			if(indicesStr.length > 1) 
			{
				for (i in 0...indicesStr.length) 
				{
					var index:Int = Std.parseInt(indicesStr[i]);

					if(indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1) 
						indices.push(index);
				}
			}
			curAnim.ref.indices = indices;

			if(indices != null && indices != [] && indices.length > 0)
				controller.addByIndices(curAnim.ref.anim, curAnim.ref.name, indices, "", curAnim.ref.fps, curAnim.ref.loop);
			else
				controller.addByPrefix(curAnim.ref.anim, curAnim.ref.name, curAnim.ref.fps, curAnim.ref.loop);

			if(!char.animOffsets.exists(curAnim.ref.anim))
				char.addOffset(curAnim.ref.anim, 0, 0);
			//

			// trail
			if (!char.trailChar.spriteSheets.contains(sheet))
			{
				char.trailChar.spriteSheets.push(sheet);
				char.trailChar.sheetAnimations.push(new FlxAnimationController(char));
				addFrames = true;
			}

			char.trailChar.frames = Paths.getCharSparrow(char.name, sheet);
			var controller = char.trailChar.sheetAnimations[char.spriteSheets.indexOf(sheet)];

			if (addFrames)
				char.trailChar.sheetFrames.push(char.frames);

			if(indices != null && indices.length > 0)
				controller.addByIndices(curAnim.ref.anim, curAnim.ref.name, indices, "", curAnim.ref.fps, true);
			else
				controller.addByPrefix(curAnim.ref.anim, curAnim.ref.name, curAnim.ref.fps, true);

			if(!char.trailChar.animOffsets.exists(curAnim.ref.anim))
				char.trailChar.addOffset(curAnim.ref.anim, 0, 0);
			//

			setCharAnim(curAnim.name);
			setTrailAnim(curTrailAnim.name);
		}
		buttonBox.addComponent(updateButton);

		UiS.addVR(5, buttonBox);

		var newButton = new haxe.ui.components.Button();
		newButton.text = 'Create New';
		newButton.onClick = function(e)
		{
			animCreateName = new haxe.ui.components.TextField();
			animCreateName.placeholder = 'Enter animation name...';

			var dialogue = haxe.ui.containers.dialogs.Dialogs.dialog(animCreateName, 'Create' | haxe.ui.containers.dialogs.Dialog.DialogButton.CANCEL);

			// thank you haxe discord "destroy dialog in:haxeui"
			dialogue.destroyOnClose = false;

			dialogue.title = 'Create Animation';
			dialogue.cameras = [camMenu];
			@:privateAccess dialogue._overlay.cameras = [camMenu];

			blockInput = true;

			dialogue.onDialogClosed = function(e)
			{
				blockInput = false;

				switch(e.button)
				{
					case '{{cancel}}':
						return;

					case 'Create':
						if (animCreateName.text == '')
							return;

						if (char.hasAnim(animCreateName.text))
							return;

						var newAnim = animCreateName.text;

						var newAnimObject:AnimArray = 
						{
							anim: newAnim,
							sheet: char.spriteSheets[0],
							name: newAnim,
							fps: 24,
							loop: false,
							indices: [],
							offsets: []
						}

						char.frames = Paths.getCharSparrow(char.name, newAnimObject.sheet);
						var controller = char.sheetAnimations[0];

						controller.addByPrefix(newAnim, newAnim, 24, false);

						if(!char.animOffsets.exists(newAnim))
							char.addOffset(newAnim, 0, 0);

						char.animationsArray.push(newAnimObject);

						char.trailChar.frames = Paths.getCharSparrow(char.name, newAnimObject.sheet);
						var controller = char.trailChar.sheetAnimations[0];

						controller.addByPrefix(newAnim, newAnim, 24, false);

						if(!char.trailChar.animOffsets.exists(newAnim))
							char.trailChar.addOffset(newAnim, 0, 0);

						char.trailChar.animationsArray.push(newAnimObject);

						setCharAnim(newAnim);
						setTrailAnim(curTrailAnim.name);

						updateAnimNamesView();
				}
			}
		}
		buttonBox.addComponent(newButton);

		formatBox.addComponent(buttonBox);

		UiS.addHR(7, formatBox);

		animNamesView = new haxe.ui.containers.ScrollView();
		animNamesView.percentWidth = 100;
		animNamesView.height = 80;
		
		animNamesViewContent = new haxe.ui.components.Label();
		animNamesViewContent.text = '';

		updateAnimNamesView();

		animNamesView.addComponent(animNamesViewContent);
		formatBox.addComponent(animNamesView);

		UiS.addHR(7, formatBox);

		var removeButton = new haxe.ui.components.Button();
		removeButton.backgroundColor = 0xFFFF0000;
		removeButton.color = 0xFFFFFFFF;
		removeButton.text = 'Remove';
		removeButton.onClick = function(e)
		{
			if(char.animOffsets.exists(curAnim.name) && char.animationsArray.length > 1)
			{
				char.animation.remove(curAnim.name);
				char.animOffsets.remove(curAnim.name);
				char.animationsArray.remove(char.getAnimByName(curAnim.name));

				var controller:FlxAnimationController = char.sheetAnimations[char.spriteSheets.indexOf(curAnim.ref.sheet)];
				controller.remove(curAnim.name);

				char.trailChar.animation.remove(curAnim.name);
				char.trailChar.animOffsets.remove(curAnim.name);
				char.trailChar.animationsArray.remove(char.trailChar.getAnimByName(curAnim.name));

				var controller:FlxAnimationController = char.trailChar.sheetAnimations[char.trailChar.spriteSheets.indexOf(curAnim.ref.sheet)];
				controller.remove(curAnim.name);

				setCharAnim(char.animationsArray[0].anim);
				resetTrail();

				updateAnimNamesView();
			}
		}
		formatBox.addComponent(removeButton);

		animationsTab.addComponent(formatBox);
	}

	function updateAnimNamesView()
	{
		if (animNamesViewContent == null)
			return;

		animNamesViewContent.text = '';
		for (anim in char.animationsArray)
			animNamesViewContent.text += '${anim.anim}\n';
	}

	var charHeader:haxe.ui.components.SectionHeader;
	var characterDropdown:haxe.ui.components.DropDown;
	var saveCharacterButton:haxe.ui.components.Button;
	var isPlayerCheckbox:haxe.ui.components.CheckBox;
	var flipXCheckbox:haxe.ui.components.CheckBox;
	var antialiasingCheckbox:haxe.ui.components.CheckBox;
	var singDurStepper:haxe.ui.components.NumberStepper;
	var scaleStepper:haxe.ui.components.NumberStepper;
	var iconColourPicker:haxe.ui.components.ColorPicker;
	var getIconColButton:haxe.ui.components.Button;
	var initializedColPicker:Bool = false;
	function addCharacterHaxeUI()
	{
		var formatBox = new haxe.ui.containers.VBox();

		charHeader = new haxe.ui.components.SectionHeader();
		charHeader.text = daAnim;
		formatBox.addComponent(charHeader);

		isPlayerCheckbox = new haxe.ui.components.CheckBox();
		isPlayerCheckbox.text = 'Is Player?';
		isPlayerCheckbox.selected = char.isPlayer;
		isPlayerCheckbox.allowInteraction = false;
		isPlayerCheckbox.onChange = function(e)
		{
			trace(e.value);
		}
		formatBox.addComponent(isPlayerCheckbox);

		UiS.addSpacer(0, 15, formatBox);

		flipXCheckbox = new haxe.ui.components.CheckBox();
		flipXCheckbox.text = 'Flip X';
		flipXCheckbox.selected = char.flipX;
		flipXCheckbox.onChange = function(e)
		{
			char.flipX = flipXCheckbox.selected;
			char.trailChar.flipX = flipXCheckbox.selected;
		}
		formatBox.addComponent(flipXCheckbox);

		antialiasingCheckbox = new haxe.ui.components.CheckBox();
		antialiasingCheckbox.text = 'Antialiasing';
		antialiasingCheckbox.selected = char.antialiasing;
		antialiasingCheckbox.onChange = function(e)
		{
			char.antialiasing = antialiasingCheckbox.selected;
			char.trailChar.antialiasing = antialiasingCheckbox.selected;
		}
		formatBox.addComponent(antialiasingCheckbox);

		UiS.addHR(7, formatBox);

		UiS.addLabel('Sing Duration', formatBox);

		singDurStepper = new haxe.ui.components.NumberStepper();
		singDurStepper.precision = 1;
		singDurStepper.min = 1;
		singDurStepper.max = 50;
		singDurStepper.step = 0.1;
		singDurStepper.pos = char.singDuration;
		singDurStepper.onChange = function(e)
		{
			char.singDuration = singDurStepper.value;
			char.trailChar.singDuration = singDurStepper.value;
		}
		formatBox.addComponent(singDurStepper);

		UiS.addLabel('Scale', formatBox);

		scaleStepper = new haxe.ui.components.NumberStepper();
		scaleStepper.precision = 3;
		scaleStepper.min = 0.1;
		scaleStepper.max = 5;
		scaleStepper.step = 0.001;
		scaleStepper.pos = char.jsonScale;
		scaleStepper.onChange = function(e)
		{
			char.playAnim(char.animSetScale, true);
			char.playTrailAnim(false, char.animSetScale, true, false, 0);

			char.setScale(scaleStepper.value);

			setCharAnim(curAnim.name);
			setTrailAnim(curTrailAnim.name);

			updateCharacterPositions();
		}
		formatBox.addComponent(scaleStepper);

		UiS.addHR(7, formatBox);

		iconColourPicker = new haxe.ui.components.ColorPicker();
		iconColourPicker.styleNames = 'no-controls';
		iconColourPicker.width = 200;
		iconColourPicker.height = 200;
		iconColourPicker.onChange = function(e)
		{
			if (!initializedColPicker)
			{
				FlxTimer.wait(0.05, updateIconPickerCol);
				initializedColPicker = true;

				return;
			}

			var newCol = FlxColor.fromInt(iconColourPicker.currentColor);

			char.healthColorArray[0] = newCol.red;
			char.healthColorArray[1] = newCol.green;
			char.healthColorArray[2] = newCol.blue;

			updateHealthbarCol();
		}
		formatBox.addComponent(iconColourPicker);

		getIconColButton = new haxe.ui.components.Button();
		getIconColButton.text = 'Get Icon Col';
		getIconColButton.onClick = function(e)
		{
			Lib.application.window.alert('Click a place on the icon to select its colour!', alertTitleString);

			iconColSelectOverlay.alpha = 0.5;
			iconForColButton.visible = true;

			gettingIconCol = true;

			haxeUIBox.fadeOut();

			prevMouseLocked = mouseLocked;
			mouseLocked = true;
		}
		formatBox.addComponent(getIconColButton);

		UiS.addSpacer(0, 10, formatBox);

		UiS.addLabel('Icon Postfix', formatBox);
		
		var iconPostfixField = new haxe.ui.components.TextField();
		iconPostfixField.placeholder = 'Enter postfix...';
		iconPostfixField.onChange = function(e)
		{
			var postfix = iconPostfixField.text;
			if (postfix != '')
				postfix = '-$postfix';

			loadCharIcons(postfix);
		}
		formatBox.addComponent(iconPostfixField);

		UiS.addHR(7, formatBox);

		var buttonBox = new haxe.ui.containers.HBox();

		saveCharacterButton = new haxe.ui.components.Button();
		saveCharacterButton.text = 'Save';
		saveCharacterButton.onClick = function(e:haxe.ui.events.MouseEvent)
		{
			saveChar();
		}
		buttonBox.addComponent(saveCharacterButton);

		UiS.addVR(5, buttonBox);

		var loadButton = new haxe.ui.components.Button();
		loadButton.text = 'Load New';
		loadButton.onClick = function(e)
		{
			var dataSource = new haxe.ui.data.ArrayDataSource<Dynamic>();
			var chars:Array<String> = [];

			var root:String = Paths.mods('characters');
			for (folder in FileSystem.readDirectory(root))
			{
				if (FileSystem.isDirectory('$root/$folder'))
				{
					if (FileSystem.exists('$root/$folder/character.json'))
					{
						dataSource.add({text: folder});
						chars.push(folder);
					}
				}
			}

			var select = new haxe.ui.containers.ListView();
			select.width = 200;
			select.height = 500;
			select.dataSource = dataSource;

			var dialogue = haxe.ui.containers.dialogs.Dialogs.dialog(select, 'Load' | haxe.ui.containers.dialogs.Dialog.DialogButton.CANCEL);

			dialogue.destroyOnClose = false;
			dialogue.title = 'Select Character';
			dialogue.cameras = [camMenu];
			@:privateAccess dialogue._overlay.cameras = [camMenu];

			blockInput = true;

			dialogue.onDialogClosed = function(e)
			{
				blockInput = false;

				switch(e.button)
				{
					case '{{cancel}}':
						return;

					case 'Load':
						loadChar(select.selectedItem.text, false);
				}
			}
		}
		buttonBox.addComponent(loadButton);
		formatBox.addComponent(buttonBox);

		characterTab.addComponent(formatBox);
	}

	var contentSheetsViewContent:haxe.ui.components.Label;
	var contentSheetsView:haxe.ui.containers.ScrollView;
	var contentIconsViewContent:haxe.ui.components.Label;
	var contentIconsView:haxe.ui.containers.ScrollView;
	function addContentHaxeUI()
	{
		var formatBox = new haxe.ui.containers.VBox();

		var openFolder = new haxe.ui.components.Button();
		openFolder.text = 'Open Character Folder';
		openFolder.onClick = function(e)
		{
			var fullPath = haxe.io.Path.join([Sys.getCwd(), Paths.charFolder(char.name)]).replace('/', '\\');

			Sys.command('explorer "$fullPath"');
		}
		formatBox.addComponent(openFolder);

		UiS.addHeader('Sheets', formatBox);

		contentSheetsViewContent = new haxe.ui.components.Label();
		contentSheetsViewContent.text = '';
		
		contentSheetsView = new haxe.ui.containers.ScrollView();
		contentSheetsView.percentWidth = 100;
		contentSheetsView.height = 40;
		contentSheetsView.addComponent(contentSheetsViewContent);

		var addSheetButton = new haxe.ui.components.Button();
		addSheetButton.text = 'Add New Sheet';
		addSheetButton.onClick = function(e)
		{
			var extData = [{label: 'Spritesheet XML Pairing', extension: 'png, xml'}];

			haxe.ui.containers.dialogs.Dialogs.openFile(function(button, files)
			{
				if (files == null || files == [])
					return;

				var pngXmlPairs = [];
				var blacklist = [];
				var foundXMLs:Map<String, Dynamic> = [];
				var foundPNGs:Map<String, Dynamic> = [];
				for (file in files)
				{
					var split = file.name.split('.');

					var ext = split[1];
					var name = split[0];

					trace(split);

					switch(ext)
					{
						case 'png':
							foundPNGs[name] = file;

						case 'xml':
							foundXMLs[name] = file;
					}
				}

				for (png in foundPNGs)
				{
					var name = png.name.split('.')[0];
					
					if (blacklist.contains(name))
					{
						trace('Sheet "$name" already exists, skipping.');
						continue;
					}

					if (foundXMLs[name] == null)
						continue; 

					if (char.spriteSheets.contains(name))
						continue;

					pngXmlPairs.push({png: foundPNGs[name], xml: foundXMLs[name]});
					blacklist.push(name);

					contentSheetsViewContent.text += '$name\n';
				}

				var charPath = Paths.charFolder(char.name);
				for (pair in pngXmlPairs)
				{
					File.copy(pair.png.fullPath, '$charPath/${pair.png.name}');
					File.copy(pair.xml.fullPath, '$charPath/${pair.xml.name}');
				}

			}, {multiple: true, extensions: extData});
		}

		//
		var removeBox = new haxe.ui.containers.HBox();

		var contentSheetsField = new haxe.ui.components.TextField();
		contentSheetsField.width = 200;
		contentSheetsField.placeholder = 'Enter sheet name...';
		removeBox.addComponent(contentSheetsField);

		UiS.addSpacer(7, 0, removeBox);

		var sheetRemove = new haxe.ui.components.Button();
		sheetRemove.text = 'Remove';
		sheetRemove.backgroundColor = 0xFFFF0000;
		sheetRemove.color = 0xFFFFFFFF;
		sheetRemove.onClick = function(e)
		{
			var sheetToRemove = contentSheetsField.text;

			if (sheetToRemove == '' || !char.spriteSheets.contains(sheetToRemove))
				return;

			if (Paths.charImage(char.name, sheetToRemove) == null)
				return;

			var path = Paths.charFolder(char.name);

			FileSystem.deleteFile(Paths.charImage(char.name, sheetToRemove));
			FileSystem.deleteFile(Paths.charXml(char.name, sheetToRemove));

			updateContentUI();
		}
		removeBox.addComponent(sheetRemove);

		formatBox.addComponent(addSheetButton);
		formatBox.addComponent(contentSheetsView);
		formatBox.addComponent(removeBox);
		//

		UiS.addHeader('Icons', formatBox);

		contentIconsViewContent = new haxe.ui.components.Label();
		contentIconsViewContent.text = '';
		
		contentIconsView = new haxe.ui.containers.ScrollView();
		contentIconsView.percentWidth = 100;
		contentIconsView.height = 40;
		contentIconsView.addComponent(contentIconsViewContent);

		var addIconButton = new haxe.ui.components.Button();
		addIconButton.text = 'Add New Icon';
		addIconButton.onClick = function(e)
		{
			haxe.ui.containers.dialogs.Dialogs.openFile(function(button, files)
			{
				if (files == null || files == [])
					return;

				for (file in files)
				{
					var iconRenameField = new haxe.ui.components.TextField();
					iconRenameField.placeholder = 'Enter postfix (eg. alt, evil, pixel)';

					var dialogue = haxe.ui.containers.dialogs.Dialogs.dialog(iconRenameField, 'Set Postfix' | haxe.ui.containers.dialogs.Dialog.DialogButton.CANCEL);

					dialogue.destroyOnClose = false;
					dialogue.title = 'Set Icon Postfix';
					dialogue.cameras = [camMenu];
					@:privateAccess dialogue._overlay.cameras = [camMenu];

					blockInput = true;

					dialogue.onDialogClosed = function(e)
					{
						blockInput = false;

						var charPath = Paths.charFolder(char.name);
						var finalPath = '$charPath/${file.name}';

						switch(e.button)
						{
							case '{{cancel}}':
								if (Paths.charImage(char.name, 'icons') != null)
									return;

								File.copy(file.fullPath, finalPath);
								FileSystem.rename(finalPath, '$charPath/icons.png');

								updateContentUI();

							case 'Set Postfix':
								if (iconRenameField.text == '')
								{
									if (Paths.charImage(char.name, 'icons') != null)
										return;

									File.copy(file.fullPath, finalPath);
									FileSystem.rename(finalPath, '$charPath/icons.png');

									updateContentUI();
								}

								var postfix = iconRenameField.text;

								if (FileSystem.exists(Paths.charImage(char.name, 'icons-$postfix')))
									return;

								File.copy(file.fullPath, finalPath);
								FileSystem.rename(finalPath, '$charPath/icons-$postfix.png');

								updateContentUI();
						}
					}
				}


			}, {multiple: true, extensions: [{label: 'PNG Files', extension: 'png'}]});
		}

		//
		var removeBox = new haxe.ui.containers.HBox();

		var contentIconsField = new haxe.ui.components.TextField();
		contentIconsField.width = 200;
		contentIconsField.placeholder = 'Enter icon name...';
		removeBox.addComponent(contentIconsField);

		UiS.addSpacer(7, 0, removeBox);

		var iconRemove = new haxe.ui.components.Button();
		iconRemove.text = 'Remove';
		iconRemove.backgroundColor = 0xFFFF0000;
		iconRemove.color = 0xFFFFFFFF;
		iconRemove.onClick = function(e)
		{
			var iconToRemove = contentIconsField.text;

			if (iconToRemove == '')
				return;

			if (Paths.charImage(char.name, iconToRemove) == null)
				return;

			var path = Paths.charFolder(char.name);

			for (file in FileSystem.readDirectory(path))
			{
				if (file == '$iconToRemove.png')
					FileSystem.deleteFile(Paths.charImage(char.name, iconToRemove));
			}

			updateContentUI();
		}
		removeBox.addComponent(iconRemove);

		formatBox.addComponent(addIconButton);
		formatBox.addComponent(contentIconsView);
		formatBox.addComponent(removeBox);
		//

		updateContentUI();

		contentTab.addComponent(formatBox);
	}

	function updateContentUI()
	{
		if (contentSheetsViewContent == null)
			return;

		contentSheetsViewContent.text = '';
		for (sheet in char.spriteSheets)
			contentSheetsViewContent.text += '$sheet\n';

		contentIconsViewContent.text = '';
		for (file in FileSystem.readDirectory(Paths.charFolder(char.name)))
		{
			if (!file.startsWith('icons'))
				continue;
			
			contentIconsViewContent.text += '${file.split('.')[0]}\n';
		}
	}

	var createName:haxe.ui.components.TextField;
	var createSheetsView:haxe.ui.containers.ScrollView;
	var createAddSheet:haxe.ui.components.Button;
	var createIconsView:haxe.ui.containers.ScrollView;
	var createAddIcons:haxe.ui.components.Button;
	var createIsPlayer:haxe.ui.components.CheckBox;
	function addCreateHaxeUI()
	{
		var formatBox = new haxe.ui.containers.VBox();

		UiS.addHeader('Create New Character', formatBox);

		UiS.addLabel('Name', formatBox);

		createName = new haxe.ui.components.TextField();
		createName.placeholder = 'Enter name...';
		formatBox.addComponent(createName);

		UiS.addSpacer(0, 10, formatBox);
		UiS.addLabel('Sheets', formatBox);

		var createSheetsViewContent = new haxe.ui.components.Label();
		createSheetsViewContent.text = '';

		createSheetsView = new haxe.ui.containers.ScrollView();
		createSheetsView.percentWidth = 100;
		createSheetsView.height = 40;
		createSheetsView.addComponent(createSheetsViewContent);

		formatBox.addComponent(createSheetsView);

		var pngXmlPairs = [];

		createAddSheet = new haxe.ui.components.Button();
		createAddSheet.text = 'Add New Sheet';
		createAddSheet.onClick = function(e)
		{
			var extData = [{label: 'Spritesheet XML Pairing', extension: 'png, xml'}];

			haxe.ui.containers.dialogs.Dialogs.openFile(function(button, files)
			{
				if (files == null || files == [])
					return;

				pngXmlPairs = [];
				var blacklist = [];
				var foundXMLs:Map<String, Dynamic> = [];
				var foundPNGs:Map<String, Dynamic> = [];
				for (file in files)
				{
					var split = file.name.split('.');

					var ext = split[1];
					var name = split[0];

					trace(split);

					switch(ext)
					{
						case 'png':
							foundPNGs[name] = file;

						case 'xml':
							foundXMLs[name] = file;
					}
				}

				for (png in foundPNGs)
				{
					var name = png.name.split('.')[0];
					
					if (blacklist.contains(name))
					{
						trace('Sheet "$name" already exists, skipping.');
						continue;
					}

					if (foundXMLs[name] != null)
					{ 
						pngXmlPairs.push({png: foundPNGs[name], xml: foundXMLs[name]});
						blacklist.push(name);

						createSheetsViewContent.text += '$name\n';
					}
					else
						trace('Pairing not found: $name');
				}

			}, {multiple: true, extensions: extData});
		}
		formatBox.addComponent(createAddSheet);

		UiS.addSpacer(0, 10, formatBox);
		UiS.addLabel('Icons', formatBox);

		var createIconsViewContent = new haxe.ui.components.Label();
		createIconsViewContent.text = '';

		createIconsView = new haxe.ui.containers.ScrollView();
		createIconsView.percentWidth = 100;
		createIconsView.height = 40;
		createIconsView.addComponent(createIconsViewContent);

		formatBox.addComponent(createIconsView);

		var iconFiles = [];
		var iconNames = [];

		createAddIcons = new haxe.ui.components.Button();
		createAddIcons.text = 'Add New Icon';
		createAddIcons.onClick = function(e)
		{
			haxe.ui.containers.dialogs.Dialogs.openFile(function(button, files)
			{
				for (file in files)
				{
					var newName = createName.text;

					var iconRenameField = new haxe.ui.components.TextField();
					iconRenameField.placeholder = 'Enter postfix here (eg. alt, pixel)';
					
					var dialogue = haxe.ui.containers.dialogs.Dialogs.dialog(iconRenameField, 'Set Postfix' | haxe.ui.containers.dialogs.Dialog.DialogButton.CANCEL);

					dialogue.destroyOnClose = false;
					dialogue.title = 'Set Icon Postfix';
					dialogue.cameras = [camMenu];
					@:privateAccess dialogue._overlay.cameras = [camMenu];

					blockInput = true;

					dialogue.onDialogClosed = function(e)
					{
						blockInput = false;

						switch(e.button)
						{
							case '{{cancel}}':
								if (iconNames.contains('icons'))
									return;

								createIconsViewContent.text += 'icons\n';
								iconNames.push('icons');

							case 'Set Postfix':
								var postfix = iconRenameField.text;

								if (postfix == '' || postfix == null)
								{
									if (iconNames.contains('icons'))
										return;

									iconNames.push('icons');
									createIconsViewContent.text += 'icons\n';

									return;
								}

								var iconName = 'icons-$postfix';

								if (Paths.charImage(newName, iconName) != null)
									return;

								iconNames.push(iconName);
								createIconsViewContent.text += '$iconName\n';
						}
					}

					iconFiles.push(file);
				}
			}, {multiple: true, extensions: [{label: 'PNG Files', extension: 'png'}]});
		}
		formatBox.addComponent(createAddIcons);

		UiS.addHR(7, formatBox);

		createIsPlayer = new haxe.ui.components.CheckBox();
		createIsPlayer.text = 'Is Player?';
		formatBox.addComponent(createIsPlayer);

		UiS.addHR(7, formatBox);

		var openAfterCreate = new haxe.ui.components.CheckBox();
		openAfterCreate.text = 'Load character after creation?';
		openAfterCreate.selected = true;
		formatBox.addComponent(openAfterCreate);

		var createButton = new haxe.ui.components.Button();
		createButton.text = 'Create Character';
		createButton.onClick = function(e)
		{
			var name = createName.text;

			if (Paths.charFolder(name) != null)
			{
				Lib.application.window.alert('Character "$name" already exists!', alertTitleString);
				return;
			}

			var charPath = '${Paths.mods('characters')}/$name';

			FileSystem.createDirectory(charPath);

			for (pair in pngXmlPairs)
			{
				File.copy(pair.png.fullPath, '$charPath/${pair.png.name}');
				File.copy(pair.xml.fullPath, '$charPath/${pair.xml.name}');
			}

			var i:Int = 0;
			for (icon in iconFiles)
			{
				var iconPath = '$charPath/${icon.name}';
				File.copy(icon.fullPath, iconPath);
				FileSystem.rename(iconPath, '$charPath/${iconNames[i]}.png');

				i++;
			}

			var charFile:CharacterFile = 
			{
				name: name,

				scale: 1,
				sing_duration: 4,

				flip_x: false,
				antialiasing: true,
				healthbar_colors: [161, 161, 161],

				metadata: {
					artists: [],
					animators: []
				}
			}

			var charContent:String = haxe.Json.stringify(charFile, '\t');
			File.saveContent('$charPath/character.json', charContent);

			var animJsonData = 
			{
				animations: [{
					anim: 'idle',
					name: 'idle',
					sheet: pngXmlPairs[0].png.name.split('.')[0],
					fps: 24,
					loop: false,
					indices: [],
					offsets: [0, 0]
				}],

				position: [0, 0],
				camera_position: [0, 0]
			}

			var scriptName = createIsPlayer.selected ? 'player' : 'opponent';
			var animContent:String = haxe.Json.stringify(animJsonData, '\t');
			File.saveContent('$charPath/$scriptName.json', animContent);

			for (pair in pngXmlPairs)
			{
				File.copy(pair.png.fullPath, '$charPath/${pair.png.name}');
				File.copy(pair.xml.fullPath, '$charPath/${pair.xml.name}');
			}

			Lib.application.window.alert('Created new character "$name"!\n"$charPath"', alertTitleString);
		
			if (openAfterCreate.selected)
				loadChar(name, false);

			createSheetsViewContent.text = '';
			createIconsViewContent.text = '';

			pngXmlPairs = [];

			iconFiles = [];
			iconNames = [];
		}
		formatBox.addComponent(createButton);

		createTab.addComponent(formatBox);
	}

	var metaArtistsField:haxe.ui.components.TextField;
	var metaAnimatorsField:haxe.ui.components.TextField;
	function addMetaHaxeUI()
	{
		var placeholderMeta:CharacterMetadata =
		{
			artists: [],
			animators: []
		}

		if (char.metadata != null)
		{
			placeholderMeta.artists = char.metadata.artists;
			placeholderMeta.animators = char.metadata.animators;
		}

		var formatBox = new haxe.ui.containers.VBox();

		UiS.addHeader('Artists', formatBox);

		var artistsString:String = '';
		var list:Array<String> = placeholderMeta.artists;
		for (art in list)
			artistsString += '${art},';

		metaArtistsField = new haxe.ui.components.TextField();
		metaArtistsField.text = artistsString.substring(0, artistsString.length - 1);
		metaArtistsField.width = 200;
		metaArtistsField.placeholder = 'Name 1, Name 2, etc';
		formatBox.addComponent(metaArtistsField);

		UiS.addHeader('Animators', formatBox);

		var animatorsString:String = '';
		var list:Array<String> = placeholderMeta.animators;
		for (anim in list)
			animatorsString += '${anim},';

		metaAnimatorsField = new haxe.ui.components.TextField();
		metaAnimatorsField.text = animatorsString.substring(0, animatorsString.length - 1);
		metaAnimatorsField.width = 200;
		metaAnimatorsField.placeholder = 'Name 1, Name 2, Name 3, etc';
		formatBox.addComponent(metaAnimatorsField);

		metaTab.addComponent(formatBox);
	}

	function updateHealthbarCol()
	{
		charHealthBar.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
	}

	function updateIconPickerCol()
	{
		iconColourPicker.currentColor = Std.int(FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]));
	}

	override function onFocusLost()
	{
		prevMouseLocked = mouseLocked;
	}

	override function onFocus()
	{
		mouseLocked = true;

		// so sexy
		new FlxTimer().start(0.5, function(timer:FlxTimer)
		{
			mouseLocked = prevMouseLocked;
		});
	}

	function loadCharIcons(postfix:String = '', ?charPath:String)
	{
		var path = '${Paths.charFolder(char.name)}/icons$postfix.png';

		if (FileSystem.exists(path))
		{
			charIcons.loadGraphic(Paths.timeImage(Paths.charImage(char.name, 'icons$postfix')));
			iconForColButton.loadGraphic(Paths.timeImage(Paths.charImage(char.name, 'icons$postfix')));
		}
		else
		{
			charIcons.loadGraphic(Paths.image('icons/icon-face'));
			iconForColButton.loadGraphic(Paths.image('icons/icon-face'));
		}

		charIcons.setGraphicSize(200, 100);
		charIcons.antialiasing = char.antialiasing;
		charIcons.updateHitbox();

		charIcons.x = charHealthBar.x + 20;
		charIcons.y = charHealthBar.y - 50;

		iconForColButton.setGraphicSize(600, 300);
		iconForColButton.antialiasing = char.antialiasing;
		iconForColButton.updateHitbox();
		iconForColButton.screenCenter();
	}

	function setCharAnim(anim)
	{
		curAnim.index = char.animationsArray.indexOf(char.getAnimByName(anim));
		curAnim.name = char.animationsArray[curAnim.index].anim;
		curAnim.ref = char.animationsArray[curAnim.index];

		char.playAnim(anim, true);

		updateAnimationHaxeUI();
	}

	function setTrailAnim(anim)
	{
		curTrailAnim.index = char.trailChar.animationsArray.indexOf(char.trailChar.getAnimByName(anim));
		curTrailAnim.name = char.trailChar.animationsArray[curTrailAnim.index].anim;
		curTrailAnim.ref = char.trailChar.animationsArray[curTrailAnim.index];

		char.playTrailAnim(false, anim, true, false, 0);
	}

	function updateAnimationHaxeUI()
	{
		if (animHeader == null)
			return;

		animHeader.text = curAnim.name;
		animSheet.text = curAnim.ref.sheet;
		animTag.text = curAnim.ref.name;
		animIndices.text = '${curAnim.ref.indices}'.replace('[', '').replace(']', '');
		animFPS.pos = curAnim.ref.fps;
		animLoop.selected = curAnim.ref.loop;
	}

	function updateCharacterHaxeUI()
	{
		if (charHeader == null)
			return;

		charHeader.text = char.name;
		isPlayerCheckbox.selected = char.isPlayer;
		flipXCheckbox.selected = char.originalFlipX;
		antialiasingCheckbox.selected = char.antialiasing;
		singDurStepper.pos = char.singDuration;
		scaleStepper.pos = char.jsonScale;

		updateIconPickerCol();
	}

	function updateMetaHaxeUI()
	{
		if (char.metadata == null)
		{
			metaArtistsField.text = '';
			metaAnimatorsField.text = '';
			return;
		}

		if (metaArtistsField == null)
			return;

		var artistsString:String = '';
		var list:Array<String> = char.metadata.artists;
		for (art in list)
			artistsString += '${art},';

		metaArtistsField.text = artistsString.substring(0, artistsString.length - 1);

		var animatorsString:String = '';
		var list:Array<String> = char.metadata.animators;
		for (anim in list)
			animatorsString += '${anim},';

		metaAnimatorsField.text = animatorsString.substring(0, animatorsString.length - 1);
	}

	function loadChar(name, reload)
	{
		var directories:Array<String> = [Paths.mods('characters')];

		for (i in 0...directories.length) 
		{
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) 
			{
				for (folder in FileSystem.readDirectory(directory)) 
				{
					var charFolder = haxe.io.Path.join([directory, folder]);
					if (sys.FileSystem.isDirectory(charFolder) && folder == name)
					{
						var isPlayer = (reload ? char.isPlayer : Paths.charJson(name, 'player') != null);

						remove(char.trailChar);
						remove(char);

						char = new Character(0, 0, name, isPlayer, NORMAL, true);

						resetTrail();

						add(char.trailChar);
						add(char);

						updateCharacterPositions();
						setCharAnim(char.animationsArray[0].anim);

						loadCharIcons('', charFolder);

						updateAnimNamesView();
						updateCharacterHaxeUI();
						updateContentUI();
						updateMetaHaxeUI();

						return;
					}
				}
			}
		}

		Lib.application.window.alert('Unable to find character "$name".', alertTitleString);
	}

	function resetTrail()
	{
		if (char.trailChar.hasAnim('idle'))
			char.playTrailAnim(false, 'idle', true, false, 0);
		else
			char.playTrailAnim(false, char.trailChar.animationsArray[0].anim, true, false, 0);

		char.trailChar.alpha = 0.5;

		curTrailAnim.index = char.trailChar.animationsArray.indexOf(char.trailChar.getAnimByName(char.trailChar.animation.name));
		curTrailAnim.name = char.trailChar.animation.name;
		curTrailAnim.ref = char.trailChar.getAnimByName(char.trailChar.animation.name);
	}

	function saveChar()
	{
		var formattedMetadata:CharacterMetadata =
		{
			artists: StringTools.trim(metaArtistsField.text).split(','),
			animators: StringTools.trim(metaAnimatorsField.text).split(',')
		}

		var charJsonData = 
		{
			name: char.name,

			scale: char.jsonScale,
			sing_duration: char.singDuration,
			
			flip_x: flipXCheckbox.selected,
			antialiasing: char.antialiasing,
			healthbar_colors: char.healthColorArray,

			metadata: formattedMetadata
		}

		var charPath = Paths.charFolder(char.name);

		var charContent:String = haxe.Json.stringify(charJsonData, '\t');
		File.saveContent('$charPath/character.json', charContent);

		var animJsonData = 
		{
			animations: [],

			position: char.positionArray,
			camera_position: char.cameraPosition
		}

		for (animData in char.animationsArray)
		{
			animJsonData.animations.push({
				anim: animData.anim,
				name: animData.name,
				sheet: animData.sheet,
				fps: animData.fps,
				loop: animData.loop,
				indices: animData.indices,
				offsets: animData.offsets
			});
		}

		var scriptName = char.isPlayer ? 'player' : 'opponent';
		var animContent:String = haxe.Json.stringify(animJsonData, '\t');
		File.saveContent('$charPath/$scriptName.json', animContent);

		Lib.application.window.alert('Successfully saved "${char.name}" to \n"$charPath"', alertTitleString);
	}

	function updatePresence() {
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + daAnim, leHealthIcon.getCharacter());
		#end
	}

	var prevMouseX = FlxG.mouse.screenX;
	var prevMouseY = FlxG.mouse.screenY;
	var changedOffset = false;
	override function update(elapsed:Float)
	{
		MusicBeatState.camBeat = FlxG.camera;

		var mouse = FlxG.mouse.getPositionInCameraView(camHUD);
		mouseText.x = mouse.x - (mouseText.width + 4);
		mouseText.y = mouse.y - mouseText.height / 2;

		handleInput(elapsed);
		updateHUDTexts();

		super.update(elapsed);
	}

	function handleInput(dt:Float)
	{
		if (blockInput)
			return;

		if (FlxG.keys.justPressed.ESCAPE) 
		{
			if(goToPlayState) 
				MusicBeatState.switchState(new PlayState());
			else 
				LoadingState.loadAndSwitchCustomState('MasterEditorMenu');
			
			FlxG.mouse.visible = false;
			return;
		}

		if (FlxG.keys.justPressed.F1)
			Lib.application.window.alert('W/S: Cycle char animation\nA/D: Cycle trail animation\n\nQ/E: Zoom\nIJKL: Move Camera\n\nArrow Keys: Move selected option\nC: Cycle move options\n\nR: Reset camera\n\nM: Toggle mouse input\n\nV: Toggle ghost visibility', alertTitleString);

		if (FlxG.keys.justPressed.R) 
			FlxG.camera.zoom = 0.5;

		if (FlxG.keys.justPressed.M)
			mouseLocked = !mouseLocked;

		if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) 
		{
			FlxG.camera.zoom += dt * FlxG.camera.zoom;
			if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		}

		if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) 
		{
			FlxG.camera.zoom -= dt * FlxG.camera.zoom;
			if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			var addToCam:Float = 500 * dt;
			if (FlxG.keys.pressed.SHIFT)
				addToCam *= 4;

			if (FlxG.keys.pressed.I)
				camFollow.y -= addToCam;
			else if (FlxG.keys.pressed.K)
				camFollow.y += addToCam;

			if (FlxG.keys.pressed.J)
				camFollow.x -= addToCam;
			else if (FlxG.keys.pressed.L)
				camFollow.x += addToCam;
		}

		if(char.animationsArray.length > 0) 
		{
			if (FlxG.keys.justPressed.W)
				curAnim.index -= 1;

			if (FlxG.keys.justPressed.S)
				curAnim.index += 1;

			if (curAnim.index < 0)
				curAnim.index = char.animationsArray.length - 1;

			if (curAnim.index >= char.animationsArray.length)
				curAnim.index = 0;

			if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
				setCharAnim(char.animationsArray[curAnim.index].anim);
		}

		if(char.trailChar.animationsArray.length > 0) 
		{
			if (FlxG.keys.justPressed.A)
				curTrailAnim.index -= 1;

			if (FlxG.keys.justPressed.D)
				curTrailAnim.index += 1;

			if (curTrailAnim.index < 0)
				curTrailAnim.index = char.trailChar.animationsArray.length - 1;

			if (curTrailAnim.index >= char.trailChar.animationsArray.length)
				curTrailAnim.index = 0;

			if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D)
				setTrailAnim(char.trailChar.animationsArray[curTrailAnim.index].anim);
		}

		var controlArray:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];

		for (i in 0...controlArray.length) 
		{
			if(controlArray[i]) 
			{
				var holdShift = FlxG.keys.pressed.SHIFT;
				var holdCtrl = FlxG.keys.pressed.CONTROL;
				var multiplier = 1;

				if (holdShift)
					multiplier = 10;
				else if (holdCtrl)
					multiplier = 100;
				else 
					multiplier = 1;

				var arrayVal = 0;
				if(i > 1) arrayVal = 1;

				var negaMult:Int = 1;
				if(i % 2 == 1) negaMult = -1;

				switch(positionEditMode)
				{
					case 'Offsets':
						char.animationsArray[curAnim.index].offsets[arrayVal] += negaMult * multiplier;
						char.addOffset(curAnim.name, char.animationsArray[curAnim.index].offsets[0], char.animationsArray[curAnim.index].offsets[1]);

						char.trailChar.animationsArray[curAnim.index].offsets[arrayVal] += negaMult * multiplier;
						char.trailChar.addOffset(curAnim.name, char.animationsArray[curAnim.index].offsets[0], char.animationsArray[curAnim.index].offsets[1]);

						setCharAnim(curAnim.name);
						
						if (char.animationsArray[curAnim.index].anim == char.trailChar.animationsArray[curTrailAnim.index].anim)
							char.playTrailAnim(false, char.animationsArray[curAnim.index].anim, true);
					
					case 'Position':
						char.positionArray[arrayVal] += -negaMult * multiplier;
						updateCharacterPositions();

					case 'Camera':
						char.cameraPosition[arrayVal] += (arrayVal == 0 ? negaMult : -negaMult) * multiplier;
						updatePointerPos();
				}
			}
		}

		if (FlxG.keys.justPressed.C)
		{
			switch(positionEditMode)
			{
				case 'Offsets':
					positionEditMode = 'Position';
				
				case 'Position':
					positionEditMode = 'Camera';

				case 'Camera':
					positionEditMode = 'Offsets';
			}
		}

		if (FlxG.keys.justPressed.V)
		{	
			char.trailChar.visible = !char.trailChar.visible;
			trailText.visible = char.trailChar.visible;
		}

		var mouseDeltaX = prevMouseX - FlxG.mouse.screenX;
		var mouseDeltaY = prevMouseY - FlxG.mouse.screenY;

		if (FlxG.mouse.pressed && !mouseLocked && !gettingIconCol)
		{
			switch(positionEditMode)
			{
				case 'Offsets':
					char.offset.x += mouseDeltaX;
					char.offset.y += mouseDeltaY;
				
				case 'Position':
					char.positionArray[0] -= mouseDeltaX;
					char.positionArray[1] -= mouseDeltaY;

					updateCharacterPositions();

				case 'Camera':
					char.cameraPosition[0] += mouseDeltaX;
					char.cameraPosition[1] -= mouseDeltaY;

					updatePointerPos();
			}

			changedOffset = true;
		}

		var camPoint = new FlxPoint(FlxG.mouse.getPositionInCameraView(camMenu).x, FlxG.mouse.getPositionInCameraView(camMenu).y);
		if (FlxG.mouse.justPressed && gettingIconCol && FlxG.overlap(new FlxObject(FlxG.mouse.getPositionInCameraView(camMenu).x, FlxG.mouse.getPositionInCameraView(camMenu).y), iconForColButton))
		{
			var pixelCol:FlxColor = iconForColButton.pixels.getPixel32(Std.int((camPoint.x - iconForColButton.x) / iconForColButton.scale.x), Std.int((camPoint.y - iconForColButton.y) / iconForColButton.scale.y));
			trace(pixelCol);

			char.healthColorArray[0] = pixelCol.red;
			char.healthColorArray[1] = pixelCol.green;
			char.healthColorArray[2] = pixelCol.blue;
			charHealthBar.color = pixelCol;

			updateIconPickerCol();
			updateHealthbarCol();

			iconColSelectOverlay.alpha = 0;
			iconForColButton.visible = false;

			gettingIconCol = false;

			haxeUIBox.fadeIn();

			new FlxTimer().start(0.5, function(timer:FlxTimer)
			{
				mouseLocked = prevMouseLocked;
			});
		}

		if (FlxG.mouse.justReleased && changedOffset && !mouseLocked)
		{
			switch(positionEditMode)
			{
				case 'Offsets':
					char.animationsArray[curAnim.index].offsets[0] = Std.int(char.offset.x);
					char.animationsArray[curAnim.index].offsets[1] = Std.int(char.offset.y);
					char.addOffset(curAnim.name, char.animationsArray[curAnim.index].offsets[0], char.animationsArray[curAnim.index].offsets[1]);

					char.trailChar.animationsArray[curAnim.index].offsets[0] = Std.int(char.offset.x);
					char.trailChar.animationsArray[curAnim.index].offsets[1] = Std.int(char.offset.y);
					char.trailChar.addOffset(curAnim.name, char.animationsArray[curAnim.index].offsets[0], char.animationsArray[curAnim.index].offsets[1]);

					setCharAnim(curAnim.name);

					if (curAnim.name == curTrailAnim.name)
						char.playTrailAnim(false, curAnim.name, true);

				case 'Camera':
					updatePointerPos();
			}

			changedOffset = false;
		}

		prevMouseX = FlxG.mouse.screenX;
		prevMouseY = FlxG.mouse.screenY;
	}

	inline function updateCharacterPositions()
	{
		if((char != null && !char.isPlayer)) char.setPosition(dadPosition.x, dadPosition.y);
		else char.setPosition(bfPosition.x, bfPosition.y);

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];

		updatePointerPos();
	}

	function updatePointerPos() 
	{
		var point = char.getCameraPosition();

		camFollow.setPosition(point.x, point.y);

		point.x -= cameraFollowPointer.width / 2;
		point.y -= cameraFollowPointer.height / 2;
		cameraFollowPointer.setPosition(point.x, point.y);
	}

	function updateHUDTexts()
	{
		var anim = curAnim.name;
		var trailAnim = curTrailAnim.name;

		editText.text = 'Currently editing: ${positionEditMode}';
		positionText.text = 'Position: (${char.positionArray[0]}, ${char.positionArray[1]})';

		if (char.animOffsets.get(anim) != null)
		{
			animText.text = '${anim} [${char.animOffsets.get(anim)[0]}, ${char.animOffsets.get(anim)[1]}]';
			animText.color = animHeader.text == anim ? FlxColor.LIME : FlxColor.WHITE;
		}

		if (char.trailChar.animOffsets.get(trailAnim) != null)
		{
			trailText.text = '${trailAnim} [${char.trailChar.animOffsets.get(trailAnim)[0]}, ${char.animOffsets.get(trailAnim)[1]}]';
			trailText.color = animHeader.text == trailAnim ? FlxColor.LIME : FlxColor.WHITE;
		}
	
		mouseText.visible = mouseLocked;
	}
}
