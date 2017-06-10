# MIDI Parser for Garry's Mod Lua

**It is not perfect!!** Use it for just experiment.
This is a GLua fork of [Lua_midiParser](https://github.com/FMS-Cat/Lua_midiParser).

## Usage

```lua
-- Will attempt to parse "garrysmod/data/abcdef.mid" file
-- myMidi = midiParser( "abcdef.mid" )

-- Will attempt to parse "garrysmod/lua/test.mid" file
-- myMidi = midiParser( "test.mid", "LUA" )
```

## Return sample

```Lua
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

## License

MIT
