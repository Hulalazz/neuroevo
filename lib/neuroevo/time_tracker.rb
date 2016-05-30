# Simple time tracking class with neat formatting.
# @note Check the code, it's its own documentation
# @attr @start_time [Time]
# @attr @end_time [Time]
# @attr @elapsed_time [Time]
class TimeTracker

  attr_reader :date_format, :time_format, :datetime_join,
    :elapsed_days_format, :elapsed_join

  ONE_DAY = Time.at(60*60*24)

  def initialize **opts
    defaults = {
      date_format: "%d.%m",
      time_format: "%H:%M:%S",
      datetime_join: " @ ",
      elapsed_days_format: "%-dd",
      elapsed_join: " "
    }
    defaults.merge(opts).each do |var, val|
      instance_variable_set "@#{var}", val
    end
  end

  def start_date
    @start_time.strftime date_format
  end

  def start_time
    @start_time.strftime time_format
  end

  def start_datetime
    start_date + datetime_join + start_time
  end

  def end_date
    @end_time.strftime date_format
  end

  def end_time
    @end_time.strftime time_format
  end

  def end_datetime
    end_date + datetime_join + end_time
  end

  def elapsed_time
    @elapsed_time.strftime time_format
  end

  def elapsed_days
    # minus oneday since elapsed holds a date, which is Jan 01 on day ZERO
    (Time.at(@elapsed_time - ONE_DAY)).strftime elapsed_days_format
  end

  def elapsed_time_w_days
    elapsed_days + elapsed_join + elapsed_time
  end

  # API (others are public just for easy hacking)

  def start_tracking
    @start_time = Time.now()
  end

  def end_tracking
    @end_time = Time.now() # + ONE_DAY.to_i # to debug date printing ;)
    @elapsed_time = Time.at(@end_time - @start_time).utc
    @date_changed = start_date != end_date
    # The date changes usually before 24h elapsed
    @run_for_days = @elapsed_time >= ONE_DAY
  end

  # Reporting

  def start_string
    "Starting execution at #{start_datetime}"
  end

  def end_string
    "Ending execution at #{end_datetime}"
  end

  def summary
    start_str = @date_changed ? start_datetime : start_time
    end_str = @date_changed ? end_datetime : end_time
    elapsed_str = @run_for_days ? elapsed_time_w_days : elapsed_time
    "Start: #{start_str} -- End: #{end_str} -- Elapsed: #{elapsed_str}"
  end
end
