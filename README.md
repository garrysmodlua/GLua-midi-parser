# midiParser for Lua

**It is not perfect!!** Use it for just experiment.

Works with Lua 5.0, also 5.3 (because it must be running on Stepmania...)

## Usage

```
midi = midiParser( "path/to/midi.mid" )
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
