-- Usage:
-- midi = midiParser( filePath )

local midiParser = function( _path )

  local ret = {}

  ------------------
  -- prepare file --
  ------------------

  if _path == nil then
    error( 'path is not defined' )
  end

  local file = io.open( _path, 'rb' )
  if file == nil then
		error( 'not found: ' .. _path )
	end

  local midi = file:read( '*all' )
  midi = string.gsub( midi, '\r\n', '\n' )

  --------------------
  -- some functions --
  --------------------

  local byteArray = function( _start, _length )
    local retArray = {}
    for i = 1, _length do
      retArray[ i ] = string.byte( midi, i + _start - 1 )
    end
    return retArray
  end

  local bytesToNumber = function( _start, _length )
    local retNumber = 0
    for i = 1, _length do
      retNumber = retNumber + string.byte( midi, i + _start - 1 ) * math.pow( 256, _length - i )
    end
    return retNumber
  end

  local vlq = function( _start ) -- Variable-length quantity
    local retNumber = 0
    local head = 0
    local byte = 0
    repeat
      byte = string.byte( midi, _start + head )
      retNumber = retNumber * 128 + ( byte - math.floor( byte / 128 ) * 128 )
      head = head + 1
    until math.floor( byte / 128 ) ~= 1
    return retNumber, head
  end

  local isSameTable = function( _a, _b )
    for i, v in ipairs( _a ) do
      if _a[ i ] ~= _b[ i ] then
        return false
      end
    end
    return true
  end

  ------------------
  -- check format --
  ------------------

  local head = 1

  if not isSameTable( byteArray( head, 4 ), { 77, 84, 104, 100 } ) then
    error( 'input file seems not to be a .mid file' )
  end
  head = head + 4 -- header chunk magic number
  head = head + 4 -- header chunk length

  ret.format = bytesToNumber( head, 2 )

  if not ( ret.format == 0 or ret.format == 1 ) then
    error( 'not supported such format of .mid' )
  end
  head = head + 2 -- format

  head = head + 2 -- trackCount

  ret.timebase = bytesToNumber( head, 2 )
  head = head + 2 -- timeBase

  ------------------------
  -- fight against .mid --
  ------------------------

  ret.tracks = {}

  while head < string.len( midi ) do

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
            type = 'off',
            channel = channel,
            number = data[ 1 ],
            velocity = data[ 2 ]
          } )

        elseif type == 9 then -- note on
          local data = byteArray( head, 2 )
          head = head + 2

          table.insert( track.messages, {
            time = deltaTime,
            type = 'on',
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
            track.name = string.sub( midi, head, head + metaLength - 1 )
            head = head + metaLength

            table.insert( track.messages, {
              time = deltaTime,
              type = 'meta',
              meta = 'Track Name',
              text = track.name
            } )

          elseif metaType == 4 then -- instrument name
            head = head + metaHead
            track.instrument = string.sub( midi, head, head + metaLength - 1 )
            head = head + metaLength

            table.insert( track.messages, {
              time = deltaTime,
              type = 'meta',
              meta = 'Instrument Name',
              text = track.instrument
            } )

          elseif metaType == 5 then -- lyric
            head = head + metaHead
            track.lyric = string.sub( midi, head, head + metaLength - 1 )
            head = head + metaLength

            table.insert( track.messages, {
              time = deltaTime,
              type = 'meta',
              meta = 'Lyric',
              text = track.lyric
            } )

          elseif metaType == 47 then -- end of track
            head = head + 1

            table.insert( track.messages, {
              time = deltaTime,
              type = 'meta',
              meta = 'End of Track'
            } )

            break

          elseif metaType == 81 then -- tempo
            head = head + 1

            local micros = bytesToNumber( head, 3 )
            head = head + 3

            table.insert( track.messages, {
              time = deltaTime,
              type = 'meta',
              meta = 'Set Tempo',
              tempo = micros
            } )

          elseif metaType == 88 then -- time signature
            head = head + 1

            local sig = byteArray( head, 4 )
            head = head + 4

            table.insert( track.messages, {
              time = deltaTime,
              type = 'meta',
              meta = 'Time Signature',
              signature = sig
            } )

          elseif metaType == 89 then -- key signature
            head = head + 1

            local sig = byteArray( head, 2 )
            head = head + 2

            table.insert( track.messages, {
              time = deltaTime,
              type = 'meta',
              meta = 'Key Signature',
              signature = sig
            } )

          else -- comment
            head = head + metaHead
            local text = string.sub( midi, head, head + metaLength - 1 )
            head = head + metaLength

            table.insert( track.messages, {
              time = deltaTime,
              type = 'meta',
              meta = 'Unknown Text: ' .. event[ 2 ],
              text = text
            } )

          end

        end

      end

    end

  end

  return ret

end

return midiParser
