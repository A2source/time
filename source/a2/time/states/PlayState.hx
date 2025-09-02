package a2.time.states;

import a2.time.backend.Paths;

import a2.time.objects.gameplay.Character;
import a2.time.objects.gameplay.notes.Note;
import a2.time.objects.gameplay.notes.StrumNote;

import a2.time.backend.managers.CameraManager;
import a2.time.backend.managers.CameraManager.ManagerCamera;
import a2.time.backend.managers.ChartEventManager;
import a2.time.backend.managers.ChartEventManager.EventGrouping;
import a2.time.backend.managers.HscriptManager;

import a2.time.objects.song.Conductor;
import a2.time.objects.song.Song.TimeSong;

import a2.time.states.LoadingState.LoadingBatch;

import a2.time.backend.ClientPrefs;
import a2.time.backend.Controls;

import flash.media.Sound;

import flixel.FlxCamera;
import flixel.FlxG;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxRuntimeShader;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

import flixel.input.keyboard.FlxKey;

import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.OneOfTwo;

import openfl.events.KeyboardEvent;

class PlayState extends MusicBeatState
{
	public static var gameInstance(get, default):PlayState;
	public static function get_gameInstance():PlayState
	{
		if (gameInstance == null) gameInstance = new PlayState(null);
		return gameInstance;
	}

	public var scriptTweens:Map<String, FlxTween> = new Map();
	public var scriptTimers:Map<String, FlxTimer> = new Map();

	public static function setScriptTween(name:String, tween:FlxTween):Void gameInstance.scriptTweens.set(name, tween);

	public static var NUM_KEYS:Int = 4;

	public static var STRUMLINE_Y:Float = 0;
	public static var STRUM_INIT_X:Float = 42;

	public static var DEFAULT_STRUM_GAP:Float = 250;
	public static var currentStrumGap:Float = DEFAULT_STRUM_GAP;

	public static final NOTE_SPAWN_TIME:Float = 2000;
	public static final NOTE_KILL_OFFSET:Float = 350;

	public static var LOADED_SONG_NAME:String = 'test';
	public static var CAMPAIGN_SONG_ORDER:Array<String> = [];
	public static var LOADED_DIFFICULTY:String = 'normal';
	public static var LOADED_MOD_DIRECTORY:String = Main.MOD_NAME;
	private var loading:Bool = false;

	public var postSongState:String = 'MasterEditorMenu';
	public var postSongModDir:String = 'core';

	private var chart:TimeSong;
	private var events:Array<EventGrouping> = [];
	private var diff:String;

	// gameplay
	public var botplay:Bool = false;
	//

	private var strumGroupings:Array<Array<StrumNote>> = [];

	private var opponentStrums(get, never):Array<StrumNote>;
	private function get_opponentStrums():Array<StrumNote> return strumGroupings[0];

	private var playerStrums(get, never):Array<StrumNote>;
	private function get_playerStrums():Array<StrumNote> return strumGroupings[1];

	private var characters:Map<String, Character> = new Map();

	private var prevOpp:String = '';
	private var prevPlay:String = '';

	public var curOpponent(get, never):Character;
	public var curPlayer(get, never):Character;

	public function get_curOpponent():Character return characters.get(prevOpp);
	public function get_curPlayer():Character return characters.get(prevPlay);

	private var instSound:Sound;
	private var vocSound:Sound;

	private var inst:FlxSound;
	private var vocals:FlxSound;

	public var paused:Bool = false;

	public var hscriptManager:HscriptManager;
	public var camManager:CameraManager;

	public static inline final LOADING_PLAYSTATE:String = 'LOADING_PLAYSTATE';
	public var loadingBatches:Array<LoadingBatch> = [];

	override public function new(songsToLoad:OneOfTwo<String, Array<String>>, ?diffToLoad:String = 'normal', ?dirToLoad:String = Main.MOD_NAME):Void
	{
		super();

		if (songsToLoad is String) LOADED_SONG_NAME = songsToLoad;
		else
		{
			var arr:Array<String> = cast songsToLoad;
			if (songsToLoad == null)
			{
				paused = true;
				return;
			}

			LOADED_SONG_NAME = arr[0];
			
			// only progress campaign if we have loaded
			if (LoadingState.leavingLoadingScreen)
				arr.remove(LOADED_SONG_NAME);

			CAMPAIGN_SONG_ORDER = arr;
		}

		LOADED_DIFFICULTY = diffToLoad;
		LOADED_MOD_DIRECTORY = dirToLoad;

		if (LOADED_SONG_NAME == null) 
		{
			paused = true;
			return;
		}

		PlayState.STRUMLINE_Y = FlxG.height * (ClientPrefs.get('downscroll') ? 0.75 : 0.05);

		chart = Conductor.loadSong(LOADED_SONG_NAME);

		countdownTickDelay = Conductor.crochet / 1000;
		countdownTickDelay /= Conductor.timescale;
		startedCountdown = false;

		// reluctantly crouched, at the starting line
		Conductor.songPosition = countdownTimeOffset * 1000;

		diff = diffToLoad;

		prevOpp = chart.opponents[0];
		prevPlay = chart.players[0];
	}

	private var tempCharacter:Character;
	private function playstateInterp(interp:hscript.InterpEx) 
	{
		interp.variables.set('game', PlayState.gameInstance);

		interp.variables.set('NUM_KEYS', PlayState.NUM_KEYS);

		interp.variables.set('STRUMLINE_Y', PlayState.STRUMLINE_Y);
		interp.variables.set('STRUM_INIT_X', PlayState.STRUM_INIT_X);

		interp.variables.set('DEFAULT_STRUM_GAP', PlayState.DEFAULT_STRUM_GAP);
		interp.variables.set('currentStrumGap', PlayState.currentStrumGap);

		interp.variables.set('NOTE_SPAWN_TIME', PlayState.NOTE_SPAWN_TIME);
		interp.variables.set('NOTE_KILL_OFFSET', PlayState.NOTE_KILL_OFFSET);

		interp.variables.set('LOADED_SONG_NAME', PlayState.LOADED_SONG_NAME);
		interp.variables.set('LOADED_DIFFICULTY', PlayState.LOADED_DIFFICULTY);
		interp.variables.set('LOADED_MOD_DIRECTORY', PlayState.LOADED_MOD_DIRECTORY);

		interp.variables.set('add', PlayState.gameInstance.add);
		interp.variables.set('remove', PlayState.gameInstance.remove);
		interp.variables.set('insert', PlayState.gameInstance.insert);

		interp.variables.set('getStrum', (player:Bool, i:Int) -> { return strumGroupings[player ? 1 : 0][i]; });
		interp.variables.set('setStrumPos', (player:Bool, i:Int, x:Float, y:Float) ->
		{
			var strumsToChange:Array<StrumNote> = player ? playerStrums : opponentStrums;
			strumsToChange[i].setPosition(x, y);
		});

		interp.variables.set('char', (name:String) -> 
		{ 
			var character:Character = characters.get(name);

			if (character == null) 
			{
				if (tempCharacter == null)
				{
					tempCharacter = new Character(0, 0, {
						name: 'bf', 
						player: true, 
						dir: LOADED_MOD_DIRECTORY
					});

					tempCharacter.rimLightShader = new FlxRuntimeShader(Paths.mods.shader(['rimLighting']).content, null);
				}

				return tempCharacter;
			}
			return character;
		});

		interp.variables.set('playerStrums', strumGroupings[1]);
		interp.variables.set('opponentStrums', strumGroupings[0]);

		interp.variables.set('getCurOpponent', () -> { return curOpponent; });
		interp.variables.set('getCurPlayer', () -> { return curPlayer; });

		// simpler hscript implementation
		// you can still access camManager for deeper interaction
		interp.variables.set('cams', {
			game: camManager.cams[0].cam,
			mid: camManager.cams[1].cam,
			hud: camManager.cams[2].cam,
			top: camManager.cams[3].cam
		});
	}

	public static function callAllScripts(func:String, args:Array<Dynamic>, ?exclude:Array<String>):Void 
	{
		if (gameInstance.hscriptManager != null)
			gameInstance.hscriptManager.callAll(func, args, exclude);
	}
	public static function callScript(func:String, args:Array<Dynamic>, script:String):Void 
	{
		if (gameInstance.hscriptManager != null)
			gameInstance.hscriptManager.call(func, args, script);
	}

	public static function setOnAllScripts(key:String, value:Dynamic):Void 
	{
		if (gameInstance.hscriptManager != null)
			gameInstance.hscriptManager.setAll(key, value);
	}
	public static function setOnScript(key:String, value:Dynamic, script:String):Void 
	{
		if (gameInstance.hscriptManager != null)
			gameInstance.hscriptManager.setVar(key, value, script);
	}

	override public function create():Void
	{
		if (LOADED_SONG_NAME == null || paused) return;

		super.create();
		gameInstance = this;

		camManager = new CameraManager([
			{name: 'game', follow: true, bumpAmt: 0.03},
			{name: 'mid', follow: false},
			{name: 'hud', follow: false, bumpAmt: 0.015},
			{name: 'top', follow: false}
		]);

		hscriptManager = new HscriptManager(playstateInterp);

		hscriptManager.addScriptsFromFolder(Paths.mods.song.folder(chart.song.toLowerCase(), LOADED_MOD_DIRECTORY));
		hscriptManager.addScriptsFromFolder(Paths.mods.stage.folder(chart.stage.toLowerCase(), LOADED_MOD_DIRECTORY));

		for (player in chart.players)
			hscriptManager.addScriptsFromFolder(Paths.mods.character.folder(player, LOADED_MOD_DIRECTORY));

		for (opp in chart.opponents)
			hscriptManager.addScriptsFromFolder(Paths.mods.character.folder(opp, LOADED_MOD_DIRECTORY));

		for (mod in Paths.directories) hscriptManager.addScriptsFromFolder(Paths.folder('scripts', mod));

		hscriptManager.sortAlphabetically();

		if (!LoadingState.leavingLoadingScreen)
		{
			loading = true;
			
			hscriptManager.callAll('preLoad', []);
			hscriptManager.callAll('load', []);
			LoadingState.initializeLoadingScreen(loadingBatches, {state: LOADING_PLAYSTATE});
			
			if (CAMPAIGN_SONG_ORDER.length <= 0) CAMPAIGN_SONG_ORDER = [LOADED_SONG_NAME];

			return;
		}

		for (i in 0...2)
		{
			var grouping:Array<StrumNote> = [];
			for (j in 0...NUM_KEYS) grouping.push(new StrumNote(j));

			strumGroupings.push(grouping);
		}

		for (opponent in chart.opponents)
		{
			var opp:Character = new Character(0, 0, {
				name: opponent, 
				player: false,
				dir: LOADED_MOD_DIRECTORY
			});

			characters.set(opponent, opp);
			for (note in getCharacterNotes(opponent)) new Note(note, opponentStrums[note.d], opponent);
		}

		for (player in chart.players) 
		{
			var play:Character = new Character(0, 0, {
				name: player, 
				player: true,
				dir: LOADED_MOD_DIRECTORY
			});

			characters.set(player, play);
			for (note in getCharacterNotes(player)) new Note(note, playerStrums[note.d], player);
		}

		positionStrums();

		for (strum in playerStrums) 
		{
			strum.sortNotes();

			strum.player = true;
			strum.updateNoteSkins();
		}
		for (strum in opponentStrums) 
		{
			strum.sortNotes();
			strum.updateNoteSkins();
		}

		for (ms in chart.events.keys())
		{
			var grouping:EventGrouping = {
				ms: Std.parseFloat(ms),
				events: chart.events.get(ms)
			}
			events.push(grouping);
		}
		events.sort((a:EventGrouping, b:EventGrouping) ->
		{
			return a.ms < b.ms ? -1 : a.ms == b.ms ? 0 : 1;
		});

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, keyRelease);
		FlxG.signals.preStateSwitch.add(removeControlListeners);

		vocSound = Paths.mods.song.voices([chart.song], Paths.WORKING_MOD_DIRECTORY).content;
		instSound = Paths.mods.song.inst([chart.song], Paths.WORKING_MOD_DIRECTORY).content;

		startSong();

		hscriptManager.callAll('start', [chart.song]);
		hscriptManager.callAll('startPost', [chart.song]);
		hscriptManager.callAll('startPostAll', [chart.song]);

		LoadingState.leavingLoadingScreen = false;
	}

	private function removeControlListeners():Void
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, keyRelease);

		FlxG.signals.preStateSwitch.remove(removeControlListeners);
	}

	public function positionStrums():Void
	{
		var curX:Float = STRUM_INIT_X;

		var gap:Null<Float> = opponentStrums[opponentStrums.length - 1].skinData.strumGap;
		if (gap != null && gap != 0)
		{
			PlayState.currentStrumGap = gap;
			if (hscriptManager != null) hscriptManager.setAll('currentStrumGap', PlayState.currentStrumGap);
		}
		else PlayState.currentStrumGap = PlayState.DEFAULT_STRUM_GAP;

		forEachStrumGrouping((grouping) ->
		{
			for (strum in grouping)
			{
				strum.setPosition(curX, STRUMLINE_Y);
				strum.cameras = [camManager.cams[2].cam];
				strum.speed = chart.speed;
				add(strum);

				strum.noteTails.cameras = [camManager.cams[2].cam];
				add(strum.noteTails);

				strum.notes.cameras = [camManager.cams[2].cam];
				add(strum.notes);

				curX += strum.width * strum.scale.x;
			}

			curX += currentStrumGap;
		});
	}

	public var countdownTickDelay:Float = 0;
	public var countdownTimeOffset(get, never):Float;
	public function get_countdownTimeOffset():Float return -countdownTickDelay * 5;

	public var startedCountdown:Bool = false;
	public var finishedCountdown:Bool = false;
	private function startSong():Void
	{	
		vocals = new FlxSound().loadEmbedded(vocSound);

		trace(LOADED_SONG_NAME, LOADED_DIFFICULTY, LOADED_MOD_DIRECTORY);
		trace('Campaign order: $CAMPAIGN_SONG_ORDER');

		hscriptManager.callAll('preCountdown', []);

		countdownTickDelay /= Conductor.timescale;
		trace('Delay time $countdownTickDelay');

		Conductor.songPosition = countdownTimeOffset * 1000;
		
		for (i in 0...6)
		{
			FlxTimer.wait(countdownTickDelay * (i + 1), () ->
			{
				startedCountdown = true;

				var countdownTick:Int = i - 1;
				if (countdownTick >= 0 && countdownTick <= 3)
					hscriptManager.callAll('onCountdownTick', [countdownTick]);

				if (i != 5) return;

				FlxG.sound.playMusic(instSound, 1, true);
				vocals.play();
				
				vocals.time = 0;
				FlxG.sound.music.time = 0;

				FlxG.sound.music.onComplete = endSong;
				FlxG.sound.music.looped = false;

				finishedCountdown = true;
				hscriptManager.callAll('postCountdown', []);
			});
		}

		paused = false;
	}

	private var offsetTime:Float = Conductor.songPosition;
	override function update(dt:Float):Void
	{
		if (loading) return;

		if (paused)
		{
			hscriptManager.callAll('updatePaused', [dt]);
			return;
		}
		
		super.update(dt);
		hscriptManager.callAll('update', [dt]);

		updateSong(dt);
		updateEvents();
		camManager.update(dt);

		hscriptManager.callAll('updatePost', [dt]);
	}

	private var lastFocus:String = '';
	private function updateSong(dt:Float):Void
	{
		if (!finishedCountdown)
		{
			if (startedCountdown) Conductor.songPosition += dt * 1000;
			return;
		}

		FlxG.sound.music.pitch = Conductor.timescale;
		vocals.pitch = Conductor.timescale;

		Conductor.songPosition = FlxG.sound.music.time;
		
		updateResync(dt);

		var thisFocus:String = Conductor.focus;
		if (lastFocus != thisFocus) updateFocus(thisFocus);

		offsetTime = Conductor.songPosition + ClientPrefs.get('ratingOffset');
	}

	// thank you codename

	private static inline var VOCAL_RESYNC_THRESHOLD:Float = 12.5;
	private var vocalResyncOffset:Float = 0;
	private function updateResync(dt:Float)
	{
		var curTime = FlxG.sound.music.time;
		var offsync:Bool = vocals.time != curTime;

		vocalResyncOffset = Math.max(0, vocalResyncOffset + (offsync ? dt : -dt / 2));
		if (vocalResyncOffset > VOCAL_RESYNC_THRESHOLD) 
		{
			resyncVocals();
			vocalResyncOffset = 0;
		}
	}

	private function resyncVocals()
	{
		vocals.pause();
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private function updateFocus(focus:String):Void
	{
		lastFocus = focus;
		camManager.focusOnPoint(characters.get(focus).cameraPosition);

		hscriptManager.callAll('onUpdateFocus', [focus]);
	}

	private function updateEvents():Void
	{
		if (events.length <= 0) return;
		var currentGrouping:EventGrouping = events[0];

		if (currentGrouping.ms > offsetTime) return;

		for (event in currentGrouping.events)
			hscriptManager.callAll('onEvent', [event, currentGrouping]);

		events.splice(events.indexOf(currentGrouping), 1);
	}

	private function endSong():Void
	{
		hscriptManager.callAll('onEndSong', []);

		if (CAMPAIGN_SONG_ORDER.length > 0) LoadingState.switchState(new PlayState(CAMPAIGN_SONG_ORDER, LOADED_DIFFICULTY, LOADED_MOD_DIRECTORY));
		else LoadingState.switchCustomState(postSongState, postSongModDir);

		hscriptManager.callAll('onEndSongPost', []);
	}

	private static var KEYS_ARRAY:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];
	private var pressing:Array<Bool> = [false, false, false, false];
	private function keyPress(e:KeyboardEvent):Void 
	{
		var i:Int = getDirectionFromKeyCode(e.keyCode);
		if (pressing[i]) return;

		pressing[i] = true;

		hscriptManager.callAll('onKeyPress', [e]);
		if (controls.PAUSE) pauseGame();

		if (i < 0) return;

		hitDirection(i);
	}

	private function keyRelease(e:KeyboardEvent):Void
	{
		hscriptManager.callAll('onKeyRelease', [e]);

		var i:Int = getDirectionFromKeyCode(e.keyCode);
		if (i < 0) return;

		pressing[i] = false;
		releaseDirection(i);
	}

	private function hitDirection(i:Int):Void
	{
		hscriptManager.callAll('onHitDirection', [i]);

		if (botplay) return;

		var strum = playerStrums[i];
		
		var lastTime:Float = Conductor.songPosition;
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		var sorted:Array<Note> = [];
		strum.notes.forEach((note:Note) -> { sorted.push(note); });

		sorted.sort((a:Note, b:Note) ->
		{
			if (a.lowPriority && !b.lowPriority) return 1;
			else if (!a.lowPriority && b.lowPriority) return -1;

			return a.ms < b.ms ? -1 : a.ms == b.ms ? 0 : 1;
		});

		var pressedNotes:Array<Note> = [];
		var stopped:Bool = false;

		var hitAny:Bool = false;
		for (note in sorted)
		{
			if (sorted.length <= 0) break;

			for (double in pressedNotes)
			{
				if (Math.abs(double.ms - note.ms) < 1) 
				{
					note.kill();

					strum.notes.remove(double, true);
					double.destroy();
				}
				else stopped = true;
			}

			if (!stopped && note.getShouldHit(offsetTime))
			{
				hitAny = true;

				hitNote(note, offsetTime - note.ms);
				pressedNotes.push(note);
				if (note.hasTail) currentlyHeldNotes.push(note);
			}
		}

		Conductor.songPosition = lastTime;
	
		if (hitAny) return;

		if (ClientPrefs.get('ghostTapping')) 
		{
			hscriptManager.callAll('onGhostTap', [i]);
			strum.playAnimation(StrumNote.STRUM_PRESS);
		}
		else onMiss(i);
	}

	public var currentlyHeldNotes:Array<Note> = [];
	private function releaseDirection(i:Int):Void 
	{
		hscriptManager.callAll('onReleaseDirection', [i]);

		var curPressing:Bool = pressing[i];

		// if a note is here that means it hasn't been held fully alr
		// in that case, KILL!
		for (note in currentlyHeldNotes)
		{
			if (note.d != i) continue;

			hscriptManager.callAll('onMissSustainNote', [note]);
			missNote(note);
			hscriptManager.callAll('onMissSustainNotePost', [note]);

			@:privateAccess note.runKill();
		}
	}

	private function getDirectionFromKeyCode(code:Int):Int
	{
		for (i in 0...KEYS_ARRAY.length)
		{
			var binds:Array<FlxKey> = controls.keyboardBinds[KEYS_ARRAY[i]];
			for (bind in binds) if (bind == code) return i;
		}

		return -1;
	}
 
	private function hitNote(note:Note, ms:Float):Void 
	{
		hscriptManager.callAll('onHitNote', [note, ms]);

		prevPlay = note.c;

		onHit(note.d);
		note.hit();

		var character:Character = characters.get(note.c);
		playCharacterAnimation(character, note, character.getSingAnimationFromData(note.d));

		hscriptManager.callAll('onHitNotePost', [note, ms]);
	}

	private function hitSustainNote(note:Note):Void
	{
		hscriptManager.callAll('onHitSustainNote', [note]);
		characters.get(note.c).hitSustainNote = false;
		hscriptManager.callAll('onHitSustainNotePost', [note]);
	}

	private function missNote(note:Note):Void 
	{
		hscriptManager.callAll('onMissNote', [note]);

		onMiss(note.d);
		var character:Character = characters.get(note.c);
		if (character.hasMissAnimations) playCharacterAnimation(character, note, character.getMissAnimationFromData(note.d), true);

		hscriptManager.callAll('onMissNotePost', [note]);
	}

	private function opponentHit(note:Note):Void 
	{
		prevOpp = note.c;

		var character:Character = characters.get(note.c);
		playCharacterAnimation(characters.get(note.c), note, character.getSingAnimationFromData(note.d));
		hscriptManager.callAll('onOpponentHit', [note]);
	}

	function playCharacterAnimation(character:Character, note:Note, animToPlay:String, ?isMiss:Bool = false):Void
	{
		if (!note.hasTail) character.prevDirKeep = note.d;
		if (note.noAnimation) return;

		animToPlay += character.animSuffix;

		character.holdTimer = 0;
		character.justHitNote = !isMiss;

		if (note.hasTail) 
		{
			if (character.hasHoldAnimations) 
				character.playAnim(character.getHoldAnimationFromData(note.d) + character.animSuffix, true);
			else 
				character.playAnim(animToPlay, true);

			character.hitSustainNote = true;
		}
		else character.playAnim(animToPlay, true);
	}

	private function onHit(i:Int):Void 
	{
		hscriptManager.callAll('onHit', [i]);
		hscriptManager.callAll('onHitPost', [i]);
	}

	private function onMiss(i:Int):Void 
	{
		hscriptManager.callAll('onMiss', [i]);
		hscriptManager.callAll('onMissPost', [i]);
	}

	override public function stepHit():Void
	{
		super.stepHit();
		hscriptManager.callAll('onStepHit', [curStep]);
	}

	override public function beatHit():Void
	{
		super.beatHit();
		hscriptManager.callAll('onBeatHit', [curBeat]);

		if (curBeat % camManager.zoom.interval == 0)
			camManager.forEachCamera((cam:ManagerCamera) -> 
			{ 
				// debug mode
				if (camManager.inEditor) return;
				
				cam.cam.zoom += cam.bumpAmt; 
			});

		if (curBeat % 2 == 0) 
			forEachCharacter((character) -> 
			{ 
				if (character.holdTimer > 0) return;
				
				character.dance();
				hscriptManager.callAll('charDance', [character]);
			});
	}

	public function pauseGame():Void
	{
		if (!finishedCountdown) return;
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		for (tween in scriptTweens) tween.active = false;
		for (timer in scriptTimers) timer.active = false;

		paused = true;

		hscriptManager.callAll('onPause', []);
	}

	public function unPauseGame():Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.play();
			vocals.play();
		}
		for (tween in scriptTweens) tween.active = true;
		for (timer in scriptTimers) timer.active = true;

		paused = false;

		hscriptManager.callAll('onUnPause', []);
	}

	private var prevPlayingFocus:Bool = false;
	override function onFocus():Void
	{
		super.onFocus();

		if (prevPlayingFocus) vocals.play();
		prevPlayingFocus = false;

		hscriptManager.callAll('onFocus', []);
	}

	override function onFocusLost():Void
	{
		super.onFocusLost();

		prevPlayingFocus = vocals.playing;
		vocals.pause();

		hscriptManager.callAll('onFocusLost', []);
	}

	override function destroy():Void
	{
		hscriptManager.callAll('onDestroy', []);
		super.destroy();
	}

	private function getCharacterNotes(character:String):Array<NoteFile> return chart.notes.get(diff).get(character);

	private function forEachCharacter(callback:Character->Void):Void for (key in characters.keys()) callback(characters.get(key));

	private function forEachStrumGrouping(callback:Array<StrumNote>->Void):Void for (grouping in strumGroupings) callback(grouping);
	private function forEachStrum(callback:StrumNote->Void):Void forEachStrumGrouping((grouping) -> { for (strum in grouping) callback(strum); });
}