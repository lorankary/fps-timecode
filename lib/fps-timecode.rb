# Timecode library
# Implements Timecode class
# Version 0.0.2
#
# Author: Loran Kary
# Copyright 2013 Focal Point Software, all rights reserved

module FPS      # Focal Point Software

# The Focal Point Systems timecode library has two main purposes.
# * 1.) Given the timecode address of the first frame of a sequence of frames, and given n, what is the timecode address of the nth frame of a sequence?
# * 2.) Given the timecode address of the first frame of a sequence, and given the timecode address for the nth frame of the sequence,  what is n?
#
# Example 1.  A non-drop-frame 30 fps sequence starts at 00:01:00:00.  What is
# the timecode address of the 100th frame of the sequence?
# FPS::Timecode.count_to_string(:fps_30_ndf,
# FPS::Timecode.string_to_count(:fps_30_ndf,"00:01:00:00") + 100)  => "00:01:03:10"
#
# Example 2.  A non-drop-frame 30 fps sequence starts at 00:01:00:00. What is n
# for the frame with the address 00:01:03:10?
# FPS::Timecode.string_to_count(:fps_30_ndf,"00:01:03:10") -
# FPS::Timecode.string_to_count(:fps_30_ndf,"00:01:00:00") => 100
#
# An instance of the Timecode class represents one timecode address.
# A timecode mode is always required to be given.  The mode determines the frame
# rate and the dropness (drop-frame or non-drop-frame) of the timecode address.
# The mode must be one of Timecode::Counts.keys.  E.g. :fps_24, :fps_25, :fps_30_df, :fps_30_ndf
#
# Create an instance of a Timecode using either a string in the format "xx:xx:xx:xx"
# or a frame count.  The frame count represents n for the nth frame of a sequence
# that begins with timecode address "00:00:00:00" (the zeroeth frame of the sequence).
#
# When creating a timecode instance, the default is to use the string argument
# ignoring the frame count argument
# and falling back to using the frame count argument if the string is invalid.
#
# Since there are many class methods, often there is no need to create
# an instance of class Timecode.

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

  # count_to_string
  # Class method to produce a timecode string from a frame count
  def self.count_to_string(tc_mode, tc_count, duration = false)
    tc_count = Timecode.normalize(tc_mode, tc_count)

    counts = Counts[tc_mode]
    hours = tc_count / counts[:fph]
    rem = tc_count % counts[:fph]
    tens_mins = rem / counts[:fptm]
    rem = rem % counts[:fptm]
    units_mins = rem / counts[:fpm]
    rem = rem % counts[:fpm]

    if(duration == false)  # not a duration, do drop-frame processing
        # handle 30 fps drop frame
        if(tc_mode == :fps_30_df && units_mins > 0 && rem <= 1)
          units_mins -= 1
          rem += counts[:fpm]
        end
        # handle 60 fps drop frame
        if(tc_mode == :fps_60_df && units_mins > 0 && rem <= 3)
          units_mins -= 1
          rem += counts[:fpm]
        end
    end

    secs = rem / counts[:fps]
    frms = rem % counts[:fps]

    "%02d:%d%d:%02d:%02d" % [hours, tens_mins, units_mins, secs, frms]
  end

  # string_to_count
  # Class method to compute a frame count from a timecode string
  def self.string_to_count(tc_mode, tc_string)
    unless Counts.include?(tc_mode)
      raise ArgumentError,  "invalid timecode mode"
    end
    unless tc_string.is_a? String
      raise ArgumentError, "invalid timecode string"
    end
    unless tc_string =~ /\A(\d{2})[:;.](\d{2})[:;.](\d{2})[:;.](\d{2})\Z/
      raise ArgumentError, "invalid timecode string"
    end
    if($1.to_i >= 24 || $2.to_i >= 60 || $3.to_i >= 60 || $4.to_i >= Counts[tc_mode][:fps])
      raise ArgumentError, "invalid timecode string"
    end

    counts = Counts[tc_mode]
    tc_string =~ /\A(\d{2})[:;.](\d)(\d)[:;.](\d{2})[:;.](\d{2})\Z/
    $1.to_i * counts[:fph] +
      $2.to_i * counts[:fptm] +
      $3.to_i * counts[:fpm] +
      $4.to_i * counts[:fps] + $5.to_i
  end

  # Class method to normalize a frame count >= 0 and < 24h.
  # Corrects 24 hour overflow or underflow
  def self.normalize(tc_mode, tc_count)
    # tc_mode must be given and must be one of the known tc modes
    unless Counts.include?(tc_mode)
      raise ArgumentError,  "invalid timecode mode"
    end

    unless tc_count.is_a? Fixnum
      raise ArgumentError, "invalid frame count #{tc_count}"
    end
    # normalize to 24 hours
    _24h = Counts[tc_mode][:fp24h]
    while tc_count < 0 do tc_count += _24h end
    while tc_count >= _24h do tc_count -= _24h end
    tc_count
  end

# Class method to produce a timecode string as a duration from a frame count
# The difference of two timecodes might be used as a duration.
# For non-drop frame, the duration string does not differ from the
# string as a timecode address.  But for drop-frame, timecodes
# that don't exist as an address can exist as a duration.
# One minute in drop frame is 1798 frames or 00:00:59:28.
# "00:01:00:00" as a drop-frame timecode address does not exist.
# But the difference between 00:01:59:28 and 00:00:59:28
# should be displayed as "00:01:00:00" -- one minute.

 def self.string_as_duration(tc_mode, tc_count)
    Timecode.count_to_string(tc_mode, tc_count, true)
  end



# initialize
#
# Construct a new instance of FPS::Timecode, given a mode and either a
# timecode string or a frame count.
#
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

    @tc_mode = tc_mode

    # Try to use the string to construct the instance and fall back
    # to the count if an exception is raised
    begin
      @tc_count = Timecode.string_to_count(@tc_mode, tc_string)
      # always convert back to string because given string may not be drop-frame legal
      @tc_string = Timecode.count_to_string(@tc_mode, @tc_count)
    rescue
      @tc_count = Timecode.normalize(@tc_mode, tc_count)
      @tc_string = Timecode.count_to_string(@tc_mode, @tc_count)
    end

  end   #initialize

   # string_as_duration
   # instance method
  def string_as_duration
    Timecode.string_as_duration(@tc_mode, @tc_count)
  end

  # Return the next timecode address in the sequence
  def succ
    Timecode.new(@tc_mode, nil, @tc_count+1)
  end

  # Compare two timecodes for equality.
  # Equality operator does string comparison.
  # Two timecodes may be considered equal even though their modes and counts
  # may be different.
  def ==(other)
    @tc_string == other.tc_string
  end

  # Compare two timecodes.
  # Comparison (spaceship) operator does string compare
  def <=>(other)
    @tc_string <=> other.tc_string
  end

end #class
end #module
