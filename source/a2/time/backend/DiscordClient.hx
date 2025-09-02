package a2.time.backend;

import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types.DiscordButton;
import hxdiscord_rpc.Types.DiscordEventHandlers;
import hxdiscord_rpc.Types.DiscordRichPresence;
import hxdiscord_rpc.Types.DiscordUser;

import sys.thread.Thread;

typedef DiscordPresenceOptions =
{
    var state:String;
    @:optional var details:String;

    @:optional var largeImageKey:String;
    @:optional var smallImageKey:String;
}

class DiscordClient
{
    public static final CLIENT_ID:String = "1291613430167502879";

    public static var instance(get, never):DiscordClient;
    private static var _instance:Null<DiscordClient> = null;

    static function get_instance():DiscordClient
    {
        if (DiscordClient._instance == null) _instance = new DiscordClient();
        if (DiscordClient._instance == null) throw "Could not initialize singleton DiscordClient!";
        return DiscordClient._instance;
    }

    private var handlers:DiscordEventHandlers;
    private function new()
    {
        handlers = DiscordEventHandlers.create();

        handlers.ready = cpp.Function.fromStaticFunction(onReady);
        handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
        handlers.errored = cpp.Function.fromStaticFunction(onError);
    }

    public function init():Void
    {
        Discord.Initialize(CLIENT_ID, cpp.RawPointer.addressOf(handlers), 1, "");
        createDaemon();
    }

    private var daemon:Null<Thread> = null;
    private function createDaemon():Void daemon = Thread.create(() ->
    {
        while (true)
        {
            Discord.runCallbacks();
            Sys.sleep(2);
        }
    });

    public function shutdown():Void
    {
        trace('Shutting down Discord Client...');
        Discord.shutdown();
    }

    public static var LARGE_IMAGE_TEXT:String = 'FNF: TIME';
    public static var LARGE_IMAGE_KEY:String = 'icon';
    public static var SMALL_IMAGE_KEY:String = '';

    public function changePresence(options:DiscordPresenceOptions):Void 
    {
        var presence = DiscordRichPresence.create();

        presence.type = DiscordActivityType_Playing;
        presence.largeImageText = LARGE_IMAGE_TEXT;

        presence.state = cast (options.state, Null<String>) ?? '';
        presence.details = cast (options.details, Null<String>) ?? '';

        presence.largeImageKey = cast (options.largeImageKey, Null<String>) ?? LARGE_IMAGE_KEY;
        presence.smallImageKey = cast (options.smallImageKey, Null<String>) ?? SMALL_IMAGE_KEY;

        final button1:DiscordButton = DiscordButton.create();
        button1.label = 'Test Button';
        button1.url = 'https://youtube.com/@A2music';
        presence.buttons[0] = button1;

        final button2:DiscordButton = DiscordButton.create();
        button2.label = 'TIME 2.0 in development!';
        button2.url = 'https://github.com/A2source/time';
        presence.buttons[1] = button2;

        Discord.updatePresence(presence);
    }

    private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
    {
        trace('Discord Client has connected!');

        final username:String = request[0].username;
        final globalName:String = request[0].username;
        final discriminator:Null<Int> = Std.parseInt(request[0].discriminator);

        if (discriminator != null && discriminator != 0) trace('User: $username#$discriminator ($globalName)');
        else trace('User: @$username ($globalName)');
    }

    private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
        trace('Discord Client has disconnected! ($errorCode) "${cast (message, String)}"');
    }
    
    private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
        trace('Discord Client has received an error! ($errorCode) "${cast (message, String)}"');
    }
}