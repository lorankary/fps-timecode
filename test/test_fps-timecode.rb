# Timecode test suite for Timecode class
# Author: Loran Kary, Focal Point Software
# to run from parent directory, "ruby -I lib test/test_fps-timecode.rb"


require 'fps-timecode'

require 'test/unit'

class TestFpsTimecode < Test::Unit::TestCase

  def test_create_legally_doesnt_fail
    assert_nothing_raised do
      FPS::Timecode.new(:fps_24, nil, 1000)
      FPS::Timecode.new(:fps_30_ndf, "00:01:00:00", nil)
      FPS::Timecode.new(:fps_25, "00:01:00:00")
      FPS::Timecode.new(:fps_30_df, "00:02:00:00", 1798*2)
      end
  end
  
  def test_create_must_have_valid_tc_mode
    assert_raises(ArgumentError) do
      FPS::Timecode.new(:not_a_valid_tc_mode, nil, 1000)
    end
  end
  
  def test_create_string_and_count_cannot_both_be_nil
    assert_raises(ArgumentError) do
      FPS::Timecode.new(:fps_30_ndf, nil, nil)
    end
  end
  
  def test_create_count_is_used_when_both_are_given
    assert_equal "00:01:00:00", FPS::Timecode.new(:fps_30_ndf, "invalid", 1800).tc_string
  end
  
  def test_create_count_if_given_must_be_fixnum
    assert_raises(ArgumentError) do
      FPS::Timecode.new(:fps_30_ndf, nil, "1800")
    end
  end
  
  def test_create_negative_counts_will_be_normalized
    assert_equal "23:59:00:00", FPS::Timecode.new(:fps_30_ndf, nil, -1800).tc_string
  end

  def test_create_counts_greater_than_24_hours_will_be_normalized
    assert_equal "00:01:00:00", 
      FPS::Timecode.new(:fps_30_ndf, nil, FPS::Timecode::Counts[:fps_30_ndf][:fp24h] + 1800).tc_string
  end
    
  def test_create_string_must_be_valid_if_no_count_given
    assert_raises(ArgumentError) do
      FPS::Timecode.new(:fps_30_ndf, "invalid", nil)
    end
  end
        
  def test_create_string_all_fields_must_be_within_bounds # e.g. 24:60:60:30 for fps 30  
    assert_nothing_raised do 
      FPS::Timecode.new(:fps_30_ndf, "23:59:59:29", nil)
    end
    assert_raises(ArgumentError) do
      FPS::Timecode.new(:fps_30_ndf, "23:59:59:30", nil)
    end
    assert_raises(ArgumentError) do
      FPS::Timecode.new(:fps_30_ndf, "24:00:00:00", nil)
    end
  end
  
  def test_create_nonexistent_drop_frame_times_will_be_corrected
    # "00:01:00:00" doesn't exist in drop-frame
    assert_equal("00:00:59:28", 
      FPS::Timecode.new(:fps_30_df, "00:01:00:00", nil).tc_string)
    # "00:10:00:00" does exist in drop-frame
    assert_equal("00:10:00:00", 
      FPS::Timecode.new(:fps_30_df, "00:10:00:00", nil).tc_string)
  end
  
  def test_comparison_works_on_strings_regardless_of_counts
    # 00:10:00:00 drop-frame is equal to 00:10:00:00 non-drop
    # despite different frame counts
    assert_equal true,        
      FPS::Timecode.new(:fps_30_ndf, nil, FPS::Timecode::Counts[:fps_30_ndf][:fptm]) ==
      FPS::Timecode.new(:fps_30_df, nil, FPS::Timecode::Counts[:fps_30_df][:fptm])
    assert_equal 0,        
      FPS::Timecode.new(:fps_30_ndf, nil, FPS::Timecode::Counts[:fps_30_ndf][:fptm]) <=>
      FPS::Timecode.new(:fps_30_df, nil, FPS::Timecode::Counts[:fps_30_df][:fptm])
  end
  
  def test_dropframe_string_as_duration
    a = FPS::Timecode.new(:fps_30_df, "00:01:59:28", nil)
    b = FPS::Timecode.new(:fps_30_df, "00:00:59:28", nil)
    difference = a.tc_count - b.tc_count
    assert_equal 1798, difference
    assert_equal "00:01:00:00", 
        FPS::Timecode.new(:fps_30_df, nil, difference).string_as_duration       
  end
      
  def test_succ
    a = []
    b = FPS::Timecode.new(:fps_30_df, "00:01:00:00", nil)
    4.times do
        a << b.tc_string
        b = b.succ
        end
    assert_equal ["00:00:59:28", "00:00:59:29", "00:01:00:02", "00:01:00:03"], a
  end
    

end