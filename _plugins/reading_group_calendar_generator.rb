# frozen_string_literal: true

require "digest"
require "date"
require "time"

module ReadingGroupCalendar
  module ScheduleFilters
    def schedule_day(date)
      Date.parse(date.to_s).strftime("%A")
    end

    def schedule_week(date, start_date)
      ((Date.parse(date.to_s) - Date.parse(start_date.to_s)).to_i / 7).floor + 1
    end

    def schedule_title(title)
      normalized = title.to_s.strip
      normalized.empty? || normalized.downcase == "to be announced" ? "TBA" : normalized
    end

    def schedule_terms_by_start_date(terms)
      term_entries = if terms.is_a?(Hash)
                       terms.map { |term, schedule| [term, schedule] }
                     else
                       Array(terms)
                     end

      term_entries.sort do |(first_term, first_schedule), (second_term, second_schedule)|
        first_start_date = start_date_for_sort(first_schedule)
        second_start_date = start_date_for_sort(second_schedule)

        date_order = second_start_date <=> first_start_date
        date_order.zero? ? second_term.to_s <=> first_term.to_s : date_order
      end
    end

    def start_date_for_sort(schedule)
      Date.parse(schedule["start_date"].to_s)
    rescue ArgumentError
      Date.new(1, 1, 1)
    end
  end

  class CalendarPage < Jekyll::PageWithoutAFile
    def initialize(site, schedules, name = "optopus.ics")
      @site = site
      @base = site.source
      @dir = "calendars"
      @name = name

      process(@name)
      self.content = CalendarBuilder.new(site, schedules).render
      self.data = {
        "layout" => nil,
        "sitemap" => false,
        "permalink" => "/calendars/#{@name}",
      }
      self.ext = ".ics"
    end

    def output_ext
      ".ics"
    end
  end

  class CalendarBuilder
    CALENDAR_NAME = "Optopus Schedule"
    TIMEZONE = "Europe/London"
    EVENT_DURATION_SECONDS = 60 * 60

    def initialize(site, schedules)
      @site = site
      @events = schedules.flat_map { |term, schedule| events_for_schedule(term, schedule) }
    end

    def render
      future_events = @events.select { |event| future_event?(event) }.sort_by { |event| starts_at(event) }
      lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//Optopus//Reading Group Schedule//EN",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        "X-WR-CALNAME:#{escape(CALENDAR_NAME)}",
        "X-WR-TIMEZONE:#{TIMEZONE}",
      ]
      lines.concat(timezone_lines)

      future_events.each { |event| lines.concat(event_lines(event)) }

      lines << "END:VCALENDAR"
      fold_lines(lines).join("\r\n") + "\r\n"
    end

    private

    def events_for_schedule(term, schedule)
      term_name = schedule["name"].to_s.empty? ? term : schedule["name"]
      Array(schedule["events"]).map { |event| event.merge("_term_name" => term_name) }
    end

    def future_event?(event)
      starts_at(event) >= local_now
    end

    def event_lines(event)
      starts_at = starts_at(event)
      ends_at = ends_at(starts_at)
      timestamp = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      canceled = event["canceled"]
      kind = event["kind"] == "seminar" ? "Seminar" : "Reading Group"
      title = calendar_title(event, kind, canceled)
      description = description_for(event, kind)
      url = event["link_url"] || refs_for(event).first&.fetch("url", nil)

      lines = [
        "BEGIN:VEVENT",
        "UID:#{uid_for(event)}",
        "SEQUENCE:1",
        "DTSTAMP:#{timestamp}",
        "LAST-MODIFIED:#{timestamp}",
        "DTSTART;TZID=#{TIMEZONE}:#{format_local_time(starts_at)}",
        "DTEND;TZID=#{TIMEZONE}:#{format_local_time(ends_at)}",
        "SUMMARY:#{escape(title)}",
        "DESCRIPTION:#{escape(description)}",
        "LOCATION:#{escape(event["room"].to_s)}",
      ]

      lines << "STATUS:CANCELLED" if canceled
      lines << "URL:#{url}" if url
      lines << "END:VEVENT"
      lines
    end

    def starts_at(event)
      with_timezone { Time.parse("#{event["date"]} #{event["time"]}") }
    end

    def ends_at(starts_at)
      starts_at + EVENT_DURATION_SECONDS
    end

    def format_local_time(time)
      with_timezone { time.strftime("%Y%m%dT%H%M%S") }
    end

    def timezone_lines
      [
        "BEGIN:VTIMEZONE",
        "TZID:#{TIMEZONE}",
        "X-LIC-LOCATION:#{TIMEZONE}",
        "BEGIN:DAYLIGHT",
        "TZOFFSETFROM:+0000",
        "TZOFFSETTO:+0100",
        "TZNAME:BST",
        "DTSTART:19700329T010000",
        "RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU",
        "END:DAYLIGHT",
        "BEGIN:STANDARD",
        "TZOFFSETFROM:+0100",
        "TZOFFSETTO:+0000",
        "TZNAME:GMT",
        "DTSTART:19701025T020000",
        "RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU",
        "END:STANDARD",
        "END:VTIMEZONE",
      ]
    end

    def local_now
      @local_now ||= with_timezone { Time.now }
    end

    def with_timezone
      previous_timezone = ENV["TZ"]
      ENV["TZ"] = TIMEZONE
      yield
    ensure
      ENV["TZ"] = previous_timezone
    end

    def description_for(event, kind)
      parts = ["Type: #{kind}"]
      parts << "Speaker: #{speaker_for_description(event)}" if present?(event["speaker"])
      parts << "Title: #{title_for_description(event)}"
      parts << "Note: #{event["note"]}" if present?(event["note"])
      parts.join("\\n")
    end

    def present?(value)
      value && value.to_s != ""
    end

    def speaker_for_description(event)
      speaker = event["speaker"].to_s
      return speaker unless present?(event["speaker_affiliation"])

      "#{speaker} (#{event["speaker_affiliation"]})"
    end

    def title_for_description(event)
      normalized_title(event["title"])
    end

    def calendar_title(event, kind, canceled)
      title = "[#{event["form"] || kind}]"
      title = "#{title} #{event["speaker"]}" if present?(event["speaker"])
      title = title_for_description(event) if !present?(event["speaker"])
      canceled ? "Canceled: #{title}" : title
    end

    def normalized_title(title)
      normalized = title.to_s.strip
      normalized.empty? || normalized.downcase == "to be announced" ? "TBA" : normalized
    end

    def refs_for(event)
      refs = Array(event["refs"])
      return refs unless refs.empty? && present?(event["link_url"])

      [{ "label" => "Link", "url" => event["link_url"] }]
    end

    def uid_for(event)
      source = [@site.config["url"], @site.config["baseurl"], event["_term_name"], event["date"], event["time"], event["kind"], event["title"]].join("|")
      "#{Digest::SHA256.hexdigest(source)[0, 24]}@optopus"
    end

    def escape(value)
      value.to_s.gsub("\\", "\\\\").gsub("\n", "\\n").gsub(",", "\\,").gsub(";", "\\;")
    end

    def fold_lines(lines)
      lines.flat_map do |line|
        next [line] if line.bytesize <= 75

        chunks = []
        remaining = line.dup
        first_line = true

        until remaining.empty?
          limit = first_line ? 75 : 74
          chunk = byteslice_utf8(remaining, limit)
          chunks << (first_line ? chunk : " #{chunk}")
          remaining = remaining[chunk.length..] || ""
          first_line = false
        end

        chunks
      end
    end

    def byteslice_utf8(value, limit)
      index = 0
      bytes = 0

      value.each_char do |char|
        char_bytes = char.bytesize
        break if bytes + char_bytes > limit

        bytes += char_bytes
        index += char.length
      end

      value[0, index]
    end
  end

  class Generator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      schedules = schedule_terms(site)
      site.pages << CalendarPage.new(site, schedules)

      schedules.each do |term, schedule|
        site.pages << CalendarPage.new(site, [[term, schedule]], "#{slug(term)}.ics")
      end
    end

    private

    def slug(term)
      term.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-+\z/, "")
    end

    def schedule_terms(site)
      data = site.data["reading_group_schedule"]
      if data.is_a?(Hash)
        return data.map { |term, schedule| [term, schedule] }
      end

      Array(data)
        .group_by { |event| event["term"] }
        .map { |term, events| [term, { "name" => term, "events" => events }] }
    end
  end
end

Liquid::Template.register_filter(ReadingGroupCalendar::ScheduleFilters)
