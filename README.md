# MIDI Parser for Garry's Mod Lua

**It is not perfect**! Use it for experimental purposes.  
This is a GLua fork of [Lua_midiParser](https://github.com/FMS-Cat/Lua_midiParser).

## Installation

### Download

You must download the source code first, there are 4 ways to do it, use any way you like:  
* Download the latest release from [here](https://github.com/garrysmodlua/GLua-midi-parser/releases/latest).  
* Download ZIP of this repository [here](https://github.com/garrysmodlua/GLua-midi-parser/archive/master.zip).
* Clone this repository using [git](https://git-scm.com/downloads): `git clone https://github.com/garrysmodlua/GLua-midi-parser.git midi-parser`.
* Save the <code><a href="https://raw.github.com/garrysmodlua/GLua-midi-parser/master/lua/includes/modules/midi-parser.lua">midi-parser.lua</a></code> file (Press <kbd>Ctrl</kbd>+<kbd>S</kbd>; Or, <kbd>Cmd</kbd>+<kbd>S</kbd> on Mac).

### GMod Setup

1. Navigate to your `./Steam/steamapps/common/GarrysMod/garrysmod` folder.
2. Depending on which download method you have used, make sure you have the following directory structure (create any necessary folder yourself if it doesn't exist):

![Expected directory structure](https://user-images.githubusercontent.com/9789070/27001572-ba3c1c16-4dcd-11e7-9348-a2954c8bd033.png)

3. You are done. Have fun!

## Usage / Code Example

1. Must require our `midi-parser` module:
	```lua
	require( "midi-parser" )
	```

2. Call either of these 2 functions:
	* `[table] = midi.Parse(string midiData)` - To parse MIDI data as string.
	* `[table] = midi.ParseFile(string fileName[, string path="DATA"])` - To parse a given `.mid` file.

```lua
-- Notes/Information:
-- ParseFile function: A fileName argument, if you are dealing with multiple directories, remember to use forward-slash (/) character as directory separator; do NOT use backslash (\) character.
-- ParseFile function: A path argument is optional, it defaults to "DATA" when omitted; by default it will search relative to "GarrysMod/garrysmod/data" folder.
-- Both of the Parse functions will throw an error if something goes wrong (e.g. if a given file does not exist, or could not be read, etc).
-- Moreover, if MIDI file/data is succesfully parsed, a function will return a table as a result.

local firstMidi = midi.ParseFile( "midis/first.mid" ) -- Will attempt to parse "GarrysMod/garrysmod/data/midis/first.mid" file

local testingMidi = midi.ParseFile( "test.mid", "LUA" ) -- Will attempt to parse "GarrysMod/garrysmod/lua/test.mid" file

PrintTable( testingMidi ) -- Prints the contents of testingMidi table
```

### Return Sample

```lua
{
	format = 1,
	timebase = 96,
	tracks = {
		{
			messages = {
				{
					time = 0,
					type = "meta",
					meta = "Time Signature",
					signature = { 4, 2, 24, 8 }
				},
				{
					time = 0,
					type = "meta",
					meta = "End of Track"
				}
			}
		},
		{
			messages = {
				{
					time = 0,
					type = "meta",
					meta = "Set Tempo",
					tempo = 468375
				},
				{
					time = 0,
					type = "meta",
					meta = "End of Track"
				}
			}
		},
		{
			name = "TrackName",
			messages = {
				{
					time = 0,
					type = "meta",
					meta = "Track Name",
					text = "TrackName"
				},
				{
					time = 0,
					type = "on",
					channel = 0,
					number = 48,
					velocity = 100
				},
				{
					time = 96,
					type = "off",
					channel = 0,
					number = 48,
					velocity = 64
				},
				{
					time = 0,
					type = "meta",
					meta = "End of Track"
				}
			}
		}
	}
}
```

## Documentation

Sorry, there is no wiki nor docs...

## Contribution

Visit the [Contributor Guidelines](https://github.com/garrysmodlua/GLua-midi-parser/blob/master/.github/CONTRIBUTING.md) for more details. All contributors are expected to follow our [Code of Conduct](https://github.com/garrysmodlua/GLua-midi-parser/blob/master/.github/CODE_OF_CONDUCT.md).

## Support

If you think you have found a bug or have a feature/enhancement request for GLua MIDI parser, use our [issue tracker](https://github.com/garrysmodlua/GLua-midi-parser/issues/new).  

Before opening a new issue, please be kind and search to see if your problem has already been reported. Try to be as detailed as possible in your issue reports.  
When creating an issue, clearly explain  

* What you were trying to do?
* What you expected to happen?
* What actually happened?
* Steps to reproduce the problem.

Also include any other information you think is relevant to reproduce the problem.

## License

[GLua MIDI parser](https://github.com/garrysmodlua/GLua-midi-parser) repository/code is freely distributed under the [MIT](LICENSE) license. See [LICENSE](LICENSE) for more details.

## Credits

[FMS-Cat](https://github.com/FMS-Cat) for the original Lua code.  
[CaptainPRICE](https://github.com/CaptainPRICE) for making it compatible with [Garry's Mod](http://gmod.facepunch.com/) (GLua).

## Related Projects

[GMod-Expression2-midi-parser](https://github.com/garrysmodlua/GMod-Expression2-midi-parser): MIDI Parser (Wire Expression 2 extension).
