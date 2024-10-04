package a2.time.util;

import Sys.sleep;
import discord_rpc.DiscordRpc;

using StringTools;

class DiscordClient
{
	public static var currentDetail:String = '';
	public static var currentState:Null<String> = null;

	public static var startupTime:Null<Int> = Std.int(Date.now().getTime() / 1000);

	public static var isInitialized:Bool = false;
	public function new()
	{
		trace("Discord Client starting...");

		DiscordRpc.start({
			clientID: "1291613430167502879",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		
		trace("Discord Client started.");

		while (true)
		{
			DiscordRpc.process();

			DiscordClient.changePresence(DiscordClient.currentDetail, DiscordClient.currentState);

			sleep(2);
		}

		DiscordRpc.shutdown();
	}
	
	public static function shutdown()
	{
		DiscordRpc.shutdown();
	}
	
	static function onReady()
	{
		DiscordRpc.presence({
			details: '',
			state: null,
			largeImageKey: 'icon',
			largeImageText: 'FNF: TIME',
			startTimestamp: startupTime,
            endTimestamp: Std.int(Date.now().getTime() / 1000)
		});
	}

	static function onError(_code:Int, _message:String)
	{
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		trace("Discord Client initialized");
		isInitialized = true;
	}

	public static function changePresence(details:String, state:Null<String> = null)
	{
		var currentTime:Null<Int> = Std.int(Date.now().getTime() / 1000);

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'icon',
			largeImageText: 'FNF: TIME',
			smallImageKey : null,
			startTimestamp: startupTime,
            endTimestamp: currentTime
		});

		currentDetail = details;
		currentState = state;

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}
}
