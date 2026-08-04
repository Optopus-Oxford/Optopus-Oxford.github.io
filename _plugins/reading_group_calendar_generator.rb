# frozen_string_literal: true

require "digest"
require "time"

module ReadingGroupCalendar
  class CalendarPage < Jekyll::PageWithoutAFile
    def initialize(site, term, events)
      @site = site
      @base = site.source
      @dir = "calendars"
      @name = "#{slug(term)}.ics"

      process(@name)
      self.content = CalendarBuilder.new(site, term, events).render
      self.data = {
        "layout" => nil,
        "sitemap" => false,
        "permalink" => "/calendars/#{slug(term)}.ics",
      }
      self.ext = ".ics"
    end

    def output_ext
      ".ics"
    end

    private

    def slug(term)
      term.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-+\z/, "")
    end
  end

  class CalendarBuilder
    CALENDAR_NAME = "Optopus Schedule"
    TIMEZONE = "Europe/London"

    def initialize(site, term, events)
      @site = site
      @term = term
      @events = events
    end

    def render
      lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//Optopus//Reading Group Schedule//EN",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        "X-WR-CALNAME:#{escape("#{CALENDAR_NAME} #{@term}")}",
        "X-WR-TIMEZONE:#{TIMEZONE}",
      ]

      @events.each { |event| lines.concat(event_lines(event)) }

      lines << "END:VCALENDAR"
      fold_lines(lines).join("\r\n") + "\r\n"
    end

    private

    def event_lines(event)
      starts_at = Time.parse("#{event["date"]} #{event["time"]}")
      ends_at = starts_at + 3600
      canceled = event["canceled"]
      kind = event["kind"] == "seminar" ? "Seminar" : "Reading Group"
      title = canceled ? "Canceled: #{kind}" : event["title"].to_s
      description = description_for(event, kind)

      lines = [
        "BEGIN:VEVENT",
        "UID:#{uid_for(event)}",
        "DTSTAMP:#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}",
        "DTSTART;TZID=#{TIMEZONE}:#{starts_at.strftime("%Y%m%dT%H%M%S")}",
        "DTEND;TZID=#{TIMEZONE}:#{ends_at.strftime("%Y%m%dT%H%M%S")}",
        "SUMMARY:#{escape(title)}",
        "DESCRIPTION:#{escape(description)}",
        "LOCATION:#{escape(event["room"].to_s)}",
      ]

      lines << "STATUS:CANCELLED" if canceled
      lines << "URL:#{event["link_url"]}" if event["link_url"]
      lines << "END:VEVENT"
      lines
    end

    def description_for(event, kind)
      parts = ["Type: #{kind}", "Term: #{event["term"]}", "Week: #{event["week_number"]}"]
      parts << "Speaker: #{event["speaker"]}" if present?(event["speaker"])
      parts << "Title: #{event["title"]}" if present?(event["title"])
      parts << "Note: #{event["note"]}" if present?(event["note"])
      parts.join("\\n")
    end

    def present?(value)
      value && value.to_s != ""
    end

    def uid_for(event)
      source = [@site.config["url"], @site.config["baseurl"], event["term"], event["date"], event["time"], event["kind"], event["title"]].join("|")
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
      schedule = Array(site.data["reading_group_schedule"])
      schedule.group_by { |event| event["term"] }.each do |term, events|
        site.pages << CalendarPage.new(site, term, events)
      end
    end
  end
end
