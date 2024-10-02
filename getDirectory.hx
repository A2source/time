static public function getDirectory(path:String):Array<String>
{
    var list:Array<String> = [];

    if(FileSystem.exists(path)) 
    {
        for (folder in FileSystem.readDirectory(path))
        {
            var path = haxe.io.Path.join([modsFolder, folder]);
            if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder))
                list.push(folder);
        }
    }
    return list;
}