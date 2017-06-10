
--[[-----------------------------------------------------------------------------------------------
Copyright (c) 2017 Garry's Mod Lua
Copyright (c) 2016 FMS_Cat

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-------------------------------------------------------------------------------------------------]]

--[[-----------------------------------------------------------------------------------------------
-- USAGE --
require( "midi-parser" )
midiResult = midi.Parse(string midiData) -- To parse a MIDI data
midiResult = midi.ParseFile(string fileName[, string path="DATA"]) -- To parse a MID file

-- EXAMPLE --
local firstMidi = midi.ParseFile( "midis/first.mid" ) -- Will attempt to parse "GarrysMod/garrysmod/data/midis/first.mid" file

local testingMidi = midi.ParseFile( "test.mid", "LUA" ) -- Will attempt to parse "GarrysMod/garrysmod/lua/test.mid" file

PrintTable( testingMidi ) -- Prints the contents of testingMidi table
-------------------------------------------------------------------------------------------------]]

module( "midi", package.seeall )

-- Forward-declaration of local functions
local byteArray, bytesToNumber, vlq, isSameTable, Parse_Internal

--- @summary Parses a given MIDI data as string.
--- @param string midiData: MIDI data to be parsed.
--- @returns table: Returns a parsed result.
function Parse( midiData )
	---------------------------
	-- verify argument types --
	---------------------------

	do
		local dbginfo = debug.getinfo( 1, "n" )
		local __func__ = dbginfo and dbginfo.name or "Parse"
		assert( isstring( midiData ), string.format( "bad argument #%d to '%s' (string expected, got %s)", 1, __func__, type( midiData ) ) )
	end

	return Parse_Internal( midiData )
end

--- @summary Parses a MID file.
--- @param string fileName: File name of the file to be parsed.
--- @param string path="DATA": Path where to search for the file. See also: https://wiki.garrysmod.com/page/File_Search_Paths
--- @returns table: Returns a parsed result.
function ParseFile( fileName, path )
	---------------------------
	-- verify argument types --
	---------------------------

	do
		local dbginfo = debug.getinfo( 1, "n" )
		local __func__ = dbginfo and dbginfo.name or "ParseFile"
		assert( isstring( fileName ), string.format( "bad argument #%d to '%s' (string expected, got %s)", 1, __func__, type( fileName ) ) )
		assert( path == nil or isstring( path ), string.format( "bad argument #%d to '%s' (string expected, got %s)", 2, __func__, type( path ) ) )
	end

	------------------
	-- prepare file --
	------------------

	path = path or "DATA"
	local hFile = file.Open( fileName, "rb", path )
	if not hFile then
		error( "file not found: " .. path .. "/" .. fileName )
	end

	local midiData = hFile:Read( hFile:Size() )
	if not midiData then
		error( "could not read a file: " .. path .. "/" .. fileName )
	end
	hFile:Close()

	return Parse_Internal( midiData )
end

-- Internal.
function Parse_Internal( midiData )
	midiData = string.gsub( midiData, "\r\n", "\n" )

	------------------
	-- check format --
	------------------

	local ret = {}
	local head = 1

	if not isSameTable( byteArray( head, 4 ), { 77, 84, 104, 100 } ) then
		error( "input data seems not to be valid MIDI data" )
	end
	head = head + 4 -- header chunk magic number
	head = head + 4 -- header chunk length

	ret.format = bytesToNumber( head, 2 )

	if not ( ret.format == 0 or ret.format == 1 ) then
		error( "not supported such format of MIDI" )
	end
	head = head + 2 -- format

	head = head + 2 -- trackCount

	ret.timebase = bytesToNumber( head, 2 )
	head = head + 2 -- timeBase

	------------------------
	-- fight against .mid --
	------------------------

	ret.tracks = {}

	while head < string.len( midiData ) do
		if not isSameTable( byteArray( head, 4 ), { 77, 84, 114, 107 } ) then -- if chunk is not track chunk
			head = head + 4 -- unknown chunk magic number
			head = head + 4 + bytesToNumber( head, 4 ) -- chunk length + chunk data
		else
			head = head + 4 -- track chunk magic number

			local chunkLength = bytesToNumber( head, 4 )
			head = head + 4 -- chunk length
			local chunkStart = head

			local track = {}
			track.messages = {}
			table.insert( ret.tracks, track )

			local status = 0
			while head < chunkStart + chunkLength do
				local deltaTime, deltaHead = vlq( head ) -- timing
				head = head + deltaHead

				local tempStatus = byteArray( head, 1 )[ 1 ]

				if math.floor( tempStatus / 128 ) == 1 then -- event, running status
					head = head + 1
					status = tempStatus
				end

				local type = math.floor( status / 16 )
				local channel = status - type * 16

				if type == 8 then -- note off
					local data = byteArray( head, 2 )
					head = head + 2

					table.insert( track.messages, {
						time = deltaTime,
						type = "off",
						channel = channel,
						number = data[ 1 ],
						velocity = data[ 2 ]
					} )
				elseif type == 9 then -- note on
					local data = byteArray( head, 2 )
					head = head + 2

					table.insert( track.messages, {
						time = deltaTime,
						type = "on",
						channel = channel,
						number = data[ 1 ],
						velocity = data[ 2 ]
					} )
				elseif type == 10 then -- polyphonic keypressure
					head = head + 2
				elseif type == 11 then -- control change
					head = head + 2
				elseif type == 12 then -- program change
					head = head + 1
				elseif type == 13 then -- channel pressure
					head = head + 1
				elseif type == 14 then -- pitch bend
					head = head + 2
				elseif status == 255 then -- meta event
					local metaType = byteArray( head, 1 )[ 1 ]
					head = head + 1
					local metaLength, metaHead = vlq( head )

					if metaType == 3 then -- track name
						head = head + metaHead
						track.name = string.sub( midiData, head, head + metaLength - 1 )
						head = head + metaLength

						table.insert( track.messages, {
							time = deltaTime,
							type = "meta",
							meta = "Track Name",
							text = track.name
						} )
					elseif metaType == 4 then -- instrument name
						head = head + metaHead
						track.instrument = string.sub( midiData, head, head + metaLength - 1 )
						head = head + metaLength

						table.insert( track.messages, {
							time = deltaTime,
							type = "meta",
							meta = "Instrument Name",
							text = track.instrument
						} )
					elseif metaType == 5 then -- lyric
						head = head + metaHead
						track.lyric = string.sub( midiData, head, head + metaLength - 1 )
						head = head + metaLength

						table.insert( track.messages, {
							time = deltaTime,
							type = "meta",
							meta = "Lyric",
							text = track.lyric
						} )
					elseif metaType == 47 then -- end of track
						head = head + 1

						table.insert( track.messages, {
							time = deltaTime,
							type = "meta",
							meta = "End of Track"
						} )

						break
					elseif metaType == 81 then -- tempo
						head = head + 1

						local micros = bytesToNumber( head, 3 )
						head = head + 3

						table.insert( track.messages, {
							time = deltaTime,
							type = "meta",
							meta = "Set Tempo",
							tempo = micros
						} )
					elseif metaType == 88 then -- time signature
						head = head + 1

						local sig = byteArray( head, 4 )
						head = head + 4

						table.insert( track.messages, {
							time = deltaTime,
							type = "meta",
							meta = "Time Signature",
							signature = sig
						} )
					elseif metaType == 89 then -- key signature
						head = head + 1

						local sig = byteArray( head, 2 )
						head = head + 2

						table.insert( track.messages, {
							time = deltaTime,
							type = "meta",
							meta = "Key Signature",
							signature = sig
						} )
					else -- comment
						head = head + metaHead
						local text = string.sub( midiData, head, head + metaLength - 1 )
						head = head + metaLength

						table.insert( track.messages, {
							time = deltaTime,
							type = "meta",
							meta = "Unknown Text",
							text = text
						} )
					end
				end
			end
		end
	end

	return ret
end

function byteArray( _start, _length )
	local retArray = {}
	for i = 1, _length do
		retArray[ i ] = string.byte( midiData, i + _start - 1 )
	end
	return retArray
end

function bytesToNumber( _start, _length )
	local retNumber = 0
	for i = 1, _length do
		retNumber = retNumber + string.byte( midiData, i + _start - 1 ) * math.pow( 256, _length - i )
	end
	return retNumber
end

function vlq( _start ) -- Variable-length quantity
	local retNumber = 0
	local head = 0
	local byte = 0
	repeat
		byte = string.byte( midiData, _start + head )
		retNumber = retNumber * 128 + ( byte - math.floor( byte / 128 ) * 128 )
		head = head + 1
	until math.floor( byte / 128 ) ~= 1
	return retNumber, head
end

function isSameTable( _a, _b )
	for i in next, _a do
		if _a[ i ] ~= _b[ i ] then
			return false
		end
	end
	return true
end
