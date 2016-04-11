require_relative "test_helper"
require 'timecop'

class TestTimecop < Minitest::Test
  def teardown
    Timecop.thread_safe = false
    Timecop.global_thread_safe = false
    Thread.current[:__timecop_instance] = nil
  end

  def test_thread_safe
    Timecop.thread_safe = true
    tc = Timecop.instance
    assert_equal Thread.current[:__timecop_instance], tc
  end

  def test_thread_unsafe
    tc = Timecop.instance
    assert_equal Timecop.thread_safe?, false
    assert_equal Thread.current[:__timecop_instance], nil
  end

  def test_nested_threads
    Timecop.thread_safe = true
    time = Time.now
    ts = []
    3.times do |i|
      ts << Thread.new(i) do |i|
        Timecop.freeze(time+3600*(i+1)) do
          assert_equal Time.now, time+3600*(i+1)
        end
      end
    end
    ts.each{ |t| t.join }
    assert Time.now < time + 5
  end

  def test_threads_uniq_instance
    main_thread_instance = Timecop.instance
    Timecop.thread_safe = true
    ts = []
    instances = [ main_thread_instance ]
    3.times do |i|
      ts << Thread.new(i) do |i|
        Timecop.thread_safe = false
        tc_instance = Timecop.instance
        instances << tc_instance
      end
    end
    ts.each{ |t| t.join }
    assert_equal instances.uniq.size, 1
  end

  def test_threads_safe_same_instance
    main_thread_instance = Timecop.instance
    ts = []
    instances = [ main_thread_instance ]
    3.times do |i|
      ts << Thread.new(i) do |i|
        Timecop.thread_safe = true
        tc_instance = Timecop.instance
        instances << tc_instance.object_id
        assert tc_instance.object_id != main_thread_instance.object_id
      end
    end
    ts.each{ |t| t.join }
    assert_equal instances.uniq.size, 4
  end
  
  def test_global_threads_safe
    main_thread_instance = Timecop.instance
    Timecop.global_thread_safe = true
    ts = []
    timecop_inst = Timecop.instance
    instances = [ main_thread_instance, timecop_inst ]
    3.times do |i|
      ts << Thread.new(i) do |i|
        tc_instance = Timecop.instance
        instances << tc_instance.object_id
        assert tc_instance.object_id != main_thread_instance.object_id
      end
    end
    ts.each{ |t| t.join }
    assert_equal instances.uniq.size, 5
    Timecop.global_thread_safe = false
    assert main_thread_instance === Timecop.instance
  end
end
