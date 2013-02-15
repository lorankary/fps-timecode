# Timecode library
# Implements Timecode class
# Vesion 0.0.1
#
# Author: Loran Kary
# Copyright 2013 Focal Point Software, all rights reserved

# A timecode library has two main purposes.
# 1.) Given the timecode address of the first frame of a sequence of frames, 
#     and given n, what is the timecode address of the nth frame of a sequence?
# 2.) Given the timecode address of the first frame of a sequence, and
#     given the timecode address for the nth frame of the sequence,  what is n?

# An instance of the Timecode class represents one timecode address.
# A timecode mode is always required to be given.  The mode determines the frame
# rate and the dropness (drop-frame or non-drop-frame) of the timecode address.
# The mode must be one of Timecode::Counts.keys.  E.g. :fps_24, :fps_25.
# Create an instance of a Timecode using either a string in the format "xx:xx:xx:xx"
# or a frame count.  The frame count represents n for the nth frame of a sequence
# that begins with timecode address "00:00:00:00" (the zeroeth frame of the sequence).
# If a frame count is given when creating a timecode instance, the string argument
# is ignored and the string is calculated from the frame count.
# If the frame count given is nil, the string argument is used to
# calculate a frame count.  

module FPS      # Focal Point Software

class Timecode

  attr_reader :tc_count, :tc_string, :tc_mode

  Counts = { fps_24:     { fp24h: 2073600, fph: 86400,  fptm: 14400, fpm: 1440, fps: 24 },
             fps_25:     { fp24h: 2160000, fph: 90000,  fptm: 15000, fpm: 1500, fps: 25 },
             fps_30_df:  { fp24h: 2589408, fph: 107892, fptm: 17982, fpm: 1798, fps: 30 },             
             fps_30_ndf: { fp24h: 2592000, fph: 108000, fptm: 18000, fpm: 1800, fps: 30 },
             fps_48:     { fp24h: 4147200, fph: 172800, fptm: 28800, fpm: 2880, fps: 48 },
             fps_50:     { fp24h: 4320000, fph: 180000, fptm: 30000, fpm: 3000, fps: 50 },
             fps_60_df:  { fp24h: 5178816, fph: 215784, fptm: 35964, fpm: 3596, fps: 60 },
             fps_60_ndf: { fp24h: 5184000, fph: 216000, fptm: 36000, fpm: 3600, fps: 60 },
           }

# initialize
# Construct a new instance of Timecode, given a mode and either a 
# timecode string or a frame count.
# Raises ArgumentError           
  def initialize(tc_mode, tc_string, tc_count = nil)
    # tc_string and tc_count cannot both be nil
    if(tc_string === nil && tc_count === nil)
      raise ArgumentError, "string and count both nil"
    end
    # tc_mode must be given and must be one of the known tc modes
    unless Counts.include?(tc_mode)
      raise ArgumentError,  "invalid timecode mode"
    end
   
    # if a count is given, use that and ignore the string, if any 
    if(tc_count != nil)
        unless tc_count.is_a? Fixnum 
          raise ArgumentError, "invalid frame count"
        end
        # normalize to 24 hours
        _24h = Counts[tc_mode][:fp24h]
        while tc_count < 0 do tc_count += _24h end
        while tc_count >= _24h do tc_count -= _24h end
    else # must be tc_string given and must be well-formatted and valid
        unless tc_string.is_a? String 
          raise ArgumentError, "invalid timecode string"
        end
        unless tc_string =~ /\A(\d{2})[:;.](\d{2})[:;.](\d{2})[:;.](\d{2})\Z/
          raise ArgumentError, "invalid timecode string"
        end
        if($1.to_i >= 24 || $2.to_i >= 60 || $3.to_i >= 60 || $4.to_i >= Counts[tc_mode][:fps])
          raise ArgumentError, "invalid timecode string"
        end
    end
    
    @tc_mode = tc_mode                  # now init instance variables
    if(tc_count)                        # give precedence to the count arg
      @tc_count = tc_count
      @tc_string = count_to_string      # ignore string arg if count given
    else
      @tc_string = tc_string
      @tc_count = string_to_count
      @tc_string = count_to_string      # in case illegal df time was given
    end    
  end   #initialize

#compute a count from the string  
  def string_to_count
    counts = Counts[@tc_mode]
    @tc_string =~ /\A(\d{2})[:;.](\d)(\d)[:;.](\d{2})[:;.](\d{2})\Z/
    $1.to_i * counts[:fph] +
      $2.to_i * counts[:fptm] +
      $3.to_i * counts[:fpm] +
      $4.to_i * counts[:fps] + $5.to_i
  end

#compute a string from the frame count
  def count_to_string(duration = false)  
    counts = Counts[@tc_mode]
    hours = @tc_count / counts[:fph]
    rem = @tc_count % counts[:fph]
    tens_mins = rem / counts[:fptm]
    rem = rem % counts[:fptm]
    units_mins = rem / counts[:fpm]
    rem = rem % counts[:fpm]
    
    if(duration == false)  # not a duration, do drop-frame processing
        # handle 30 fps drop frame
        if(@tc_mode == :fps_30_df && units_mins > 0 && rem <= 1)
          units_mins -= 1
          rem += counts[:fpm]
        end
        # handle 60 fps drop frame
        if(@tc_mode == :fps_60_df && units_mins > 0 && rem <= 3)
          units_mins -= 1
          rem += counts[:fpm]
        end
    end
    
    secs = rem / counts[:fps]
    frms = rem % counts[:fps]
    
    "%02d:%d%d:%02d:%02d" % [hours, tens_mins, units_mins, secs, frms]
  end
  
  # string_as_duration
  # The difference of two timecodes might be used as a duration.
  # For non-drop frame, the duration string does not differ from the
  # string as a timecode address.  But for drop-frame, timecodes 
  # that don't exist as an address can exist as a duration.
  # One minute in drop frame is 1798 frames or 00:00:59:28.
  # "00:01:00:00" as a drop-frame timecode address does not exist.
  # But the difference between 00:01:59:28 and 00:00:59:28
  # should be displayed as "00:01:00:00" -- one minute.
  # 
  def string_as_duration
    count_to_string(true)
  end
  
  # succ
  # return the next timecode address in the sequence
  def succ
    Timecode.new(@tc_mode, nil, @tc_count+1)
  end
  
  # compare two timecodes for equality    
  # equality operator does string compare
  # two timecodes may be considered equal even though their modes and counts
  # may be different.
  def ==(other)
    @tc_string == other.tc_string
  end
  
  # compare two timecodes
  # comparison (spaceship) operator does string compare
  def <=>(other)
    @tc_string <=> other.tc_string
  end

end #class
end #module
