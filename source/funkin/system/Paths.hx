package funkin.system;

import funkin.mods.LimeLibrarySymbol;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import funkin.mods.ModsFolder;
import funkin.scripting.Script;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class Paths
{
	/**
	 * Preferred sound extension for the game's audio files.
	 * Currently is set to `mp3` for web targets, and `ogg` for other targets.
	 */
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	private static var __useSourceAssets = false;

	public static function getPath(file:String, type:AssetType, library:Null<String>, skipModsVerification:Bool = false)
	{
		if (library != null && library.startsWith("mods/")) {
			library = library.toLowerCase();
		} else if (!skipModsVerification && ModsFolder.currentModFolder != null) {
			var modPath = getPath(file, type, 'mods/${ModsFolder.currentModFolder}');
			if (OpenFlAssets.exists(modPath)) return modPath;
		}

		if (library != null)
			return getLibraryPath(file, library);

		return getPreloadPath(file);
	}

	static public function video(key:String) {
		return getPath('videos/$key.mp4', BINARY, null);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		if (library.startsWith("mods")) library = library.toLowerCase();
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		return (__useSourceAssets) ? getLibraryPathForce(file, 'sourceassets') : 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function fragShader(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	inline static public function vertShader(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline static public function voices(song:String, difficulty:String = "normal")
	{
		var diff = getPath('songs/${song.toLowerCase()}/Voices-$difficulty.$SOUND_EXT', MUSIC, null);
		return OpenFlAssets.exists(diff) ? diff : getPath('songs/${song.toLowerCase()}/Voices.$SOUND_EXT', MUSIC, null);
	}

	inline static public function inst(song:String, difficulty:String = "normal")
	{
		var diff = getPath('songs/${song.toLowerCase()}/Inst-$difficulty.$SOUND_EXT', MUSIC, null);
		return OpenFlAssets.exists(diff) ? diff : getPath('songs/${song.toLowerCase()}/Inst.$SOUND_EXT', MUSIC, null);
	}

	inline static public function image(key:String, ?library:String, checkForAtlas:Bool = false)
	{
		var atlasPath = checkForAtlas ? getPath('images/$key/spritemap.png', IMAGE, library) : null;
		return (checkForAtlas && OpenFlAssets.exists(atlasPath)) ? atlasPath.substr(0, atlasPath.length - 14) : getPath('images/$key.png', IMAGE, library);
	}

	inline static public function script(key:String, ?library:String, isAssetsPath:Bool = false) {
		var scriptPath = isAssetsPath ? key : getPath(key, TEXT, library);
		var p:String;
		for(ex in Script.scriptExtensions) {
			p = isAssetsPath ? '$key.$ex' : getPath('$key.$ex', TEXT, library);
			if (OpenFlAssets.exists(p)) {
				scriptPath = p;
				break;
			}
		}
		return scriptPath;
	}

	static public function chart(song:String, ?difficulty:String = "normal"):String {
		difficulty = difficulty.toLowerCase();
		song = song.toLowerCase();

		var difficultyEnd = (difficulty == "normal") ? "" : '-$difficulty';

		// data/charts/your-song/hard.json
		var p = json('charts/$song/$difficulty');
		if (OpenFlAssets.exists(p)) return p;

		// data/charts/your-song/your-song-hard.json
		var p2 = json('charts/$song/$song$difficultyEnd');
		if (OpenFlAssets.exists(p2)) return p2;

		// data/your-song/your-song-hard.json (default old format)
		p2 = json('$song/$song$difficultyEnd');
		if (OpenFlAssets.exists(p2)) return p2;

		return p; // returns the normal one so that it shows the correct path in the error message.
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}
	inline static public function getSparrowAtlasAlt(key:String)
	{
		return FlxAtlasFrames.fromSparrow('$key.png', '$key.xml');
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}

	inline static public function getPackerAtlasAlt(key:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker('$key.png', '$key.txt');
	}

	static public function getFolderContent(key:String, includeSource:Bool = true, addPath:Bool = false, scanSource:Bool = false):Array<String> {
		// designed to work both on windows and web
		
		if (!key.endsWith("/")) key = key + "/";

		if (ModsFolder.currentModFolder == null && !scanSource)
			return getFolderContent(key, false, addPath, true);

		var folderPath:String = scanSource ? getPreloadPath(key) : getLibraryPathForce(key, 'mods/${ModsFolder.currentModFolder}');
		var libThing = new LimeLibrarySymbol(folderPath);
		var library = libThing.library;

		if (library is openfl.utils.AssetLibrary) {
			var lib = cast(libThing.library, openfl.utils.AssetLibrary);
			@:privateAccess
			if (lib.__proxy != null) library = lib.__proxy;
		}
		
		var content:Array<String> = [];
		#if MOD_SUPPORT
		if (library is funkin.mods.ModsAssetLibrary) {
			// easy task, can immediatly scan for files!
			var lib = cast(library, funkin.mods.ModsAssetLibrary);
			content = lib.getFiles(libThing.symbolName);
			if (addPath) 
				for(i in 0...content.length)
					content[i] = '$folderPath${content[i]}';
		} else #end {
			@:privateAccess
			for(k=>e in library.paths) {
				if (k.toLowerCase().startsWith(libThing.symbolName.toLowerCase())) {
					if (addPath) {
						if (libThing.libraryName != "")
							content.push('${libThing.libraryName}:$k');
						else
							content.push(k);
					} else {
						var barebonesFileName = k.substr(libThing.symbolName.length);
						if (!barebonesFileName.contains("/"))
							content.push(barebonesFileName);
					}
				}
			}
		}



		if (includeSource) {
			var sourceResult = getFolderContent(key, false, addPath, true);
			for(e in sourceResult)
				if (!content.contains(e))
					content.push(e);
		}


		return content;
	}
}
