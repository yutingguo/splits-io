module TimeSplitTracker
  def self.to_s
    "Time Split Tracker"
  end

  def self.to_sym
    :timesplittracker
  end

  def self.file_extension
    'timesplittracker'
  end

  def self.website
    'https://dunnius.itch.io/time-split-tracker-windows'
  end

  class Parser < BabelBridge::Parser
    rule :timesplittracker_file, :first_line, :title_line, many?(:splits)

    rule :first_line,  :attempts, :tab, /([^\t\r\n]*)/, :optional_tab, :game_name, :newline
    rule :title_line,  :title, :tab, /([^\t\r\n]*)/, :newline
    rule :splits,      :title, :tab, :duration, :newline, :image_path, :tab, :newline

    rule :attempts,   /([^\t\r\n]*)/
    rule :title,      /([^\t]*)/
    rule :game_name,       /([^\r\n]*)/
    rule :duration,   :time
    rule :image_path, /([^\t\r\n]*)/

    rule :time,       /((\d+:)?\d*\.\d*)/

    rule :newline,         :windows_newline
    rule :newline,         :unix_newline
    rule :tab,             "\t"
    rule :optional_tab,    /\t?/
    rule :windows_newline, "\r\n"
    rule :unix_newline,    "\n"

    def parse(file, options = {})
      return unless file.ascii_only?

      run = super(file)
      return nil if run.nil?
      {
        name: run.title.to_s,
        attempts: run.attempts.to_s.to_i,
        offset: run.offset.to_f,
        splits: parse_splits(run.splits),
        history: [],
        indexed_history: {}
      }
    end

    private

    def parse_splits(splits)
      splits.map.with_index do |split, index|
        parse_split(split, index == 0 ? 0 : splits.slice(0, index).map { |s| duration_in_seconds_of(s.duration.to_s) }.sum)
      end
    end

    def parse_split(segment, run_duration_so_far)
      Split.new.tap do |split|
        split.name = segment.title.to_s
        split.duration = duration_in_seconds_of(segment.duration.to_s)
        split.finish_time = run_duration_so_far + split.duration
      end
    end

    def duration_in_seconds_of(time)
      return 0 if time.blank?

      time.sub!('.', ':') if time.count('.') == 2
      ChronicDuration.parse(time, keep_zero: true)
    end
  end
end
