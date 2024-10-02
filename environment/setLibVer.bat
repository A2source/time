haxelib set flixel-addons 3.2.3
haxelib set flixel-ui 2.6.1
haxelib set flixel 5.6.0
haxelib set actuate 1.9.0
haxelib set hscript-ex 0.0.0
haxelib set hscript 2.5.0
haxelib set hxcpp 4.3.2
haxelib set lime-samples 7.0.0
haxelib set lime 8.1.2
haxelib set openfl 9.3.3
haxelib set tjson 1.4.0

haxelib run lime setup flixel

haxelib git haxeui-flixel https://github.com/haxeui/haxeui-flixel && haxelib git haxeui-core https://github.com/haxeui/haxeui-core

haxelib remove discord_rpc
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc

haxelib remove extension-webm
haxelib git extension-webm https://github.com/GrowtopiaFli/extension-webm
lime rebuild extension-webm windows