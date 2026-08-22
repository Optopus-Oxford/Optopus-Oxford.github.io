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
  end

  class CalendarPage < Jekyll::PageWithoutAFile
    def initialize(site, term, schedule)
      @site = site
      @base = site.source
      @dir = "calendars"
      @name = "#{slug(term)}.ics"

      process(@name)
      self.content = CalendarBuilder.new(site, term, schedule).render
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

    def initialize(site, term, schedule)
      @site = site
      @term = term
      @term_name = schedule["name"].to_s.empty? ? term : schedule["name"]
      @start_date = schedule["start_date"]
      @events = Array(schedule["events"])
    end

    def render
      lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//Optopus//Reading Group Schedule//EN",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        "X-WR-CALNAME:#{escape("#{CALENDAR_NAME} #{@term_name}")}",
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
      title = calendar_title(event, kind, canceled)
      description = description_for(event, kind)
      url = event["link_url"] || refs_for(event).first&.fetch("url", nil)

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
      lines << "URL:#{url}" if url
      lines << "END:VEVENT"
      lines
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

    def week_number(event)
      ((Date.parse(event["date"].to_s) - Date.parse(@start_date.to_s)).to_i / 7).floor + 1
    end

    def refs_for(event)
      refs = Array(event["refs"])
      return refs unless refs.empty? && present?(event["link_url"])

      [{ "label" => "Link", "url" => event["link_url"] }]
    end

    def uid_for(event)
      source = [@site.config["url"], @site.config["baseurl"], @term_name, event["date"], event["time"], event["kind"], event["title"]].join("|")
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
      schedule_terms(site).each do |term, schedule|
        site.pages << CalendarPage.new(site, term, schedule)
      end
    end

    private

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
