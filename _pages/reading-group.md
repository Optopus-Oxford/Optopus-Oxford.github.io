---
layout: page
title: Schedule
permalink: /reading-group/
nav: true
nav_order: 1
description: Schedule for the Optopus Reading Group.
---

<div class="schedule-controls" aria-label="Schedule filters">
  <label>
    <span>Term</span>
    <select id="term-filter">
      <option value="TT25">TT25</option>
      <option value="MT25">MT25</option>
      <option value="HT26">HT26</option>
      <option value="TT26" selected>TT26</option>
      <option value="MT26">MT26</option>
    </select>
  </label>

  <label>
    <span>Event type</span>
    <select id="event-filter">
      <option value="all" selected>All events</option>
      <option value="reading-group">Reading Group</option>
      <option value="seminar">Seminars</option>
    </select>
  </label>
</div>

<p class="schedule-empty" data-empty-message hidden>No events scheduled for this selection.</p>

<div class="schedule-list">
  {% for event in site.data.reading_group_schedule %}
    <article class="schedule-entry {% if event.canceled %}is-cancelled{% endif %}" data-term="{{ event.term }}" data-kind="{{ event.kind }}">
      <div class="schedule-entry-header">
        <span class="event-tag {% if event.kind == 'seminar' %}seminar-tag{% endif %}">{{ event.form }}</span>
        {% assign hour = event.time | slice: 0, 2 | plus: 0 %}
        {% if hour == 0 %}
          {% assign display_time = '12am' %}
        {% elsif hour < 12 %}
          {% assign display_time = hour | append: 'am' %}
        {% elsif hour == 12 %}
          {% assign display_time = '12pm' %}
        {% else %}
          {% assign display_hour = hour | minus: 12 %}
          {% assign display_time = display_hour | append: 'pm' %}
        {% endif %}
        <span class="date-line {% if event.canceled %}date-canceled{% endif %}">
          Week {{ event.week_number }} - {{ event.day }} {{ event.date | date: "%d/%m/%Y" }} - {{ display_time }}
          {%- if event.canceled %} - Cancelled{% endif -%}
        </span>
      </div>

      {% if event.canceled %}
        {% if event.note %}
          <p><strong>Note:</strong> {{ event.note }}</p>
        {% endif %}
      {% else %}
        <h2>
          {% if event.title == 'To be announced' %}
            <strong>{{ event.title }}</strong>
          {% else %}
            {{ event.title }}
          {% endif %}
          {% if event.link_url %}
            [<a href="{{ event.link_url }}">URL</a>]
          {% endif %}
        </h2>

        {% if event.note %}
          <p><strong>Note:</strong> {{ event.note }}</p>
        {% endif %}

        {% if event.speaker and event.speaker != '' %}
          <p><strong>Speaker:</strong> {{ event.speaker }}</p>
        {% endif %}

        {% if event.authors %}
          <p><strong>Authors:</strong> {{ event.authors }}</p>
        {% endif %}

        {% if event.published %}
          <p><strong>Published:</strong> {{ event.published }}</p>
        {% endif %}

        <p class="room-line"><strong>Room:</strong> {{ event.room }}</p>
      {% endif %}
    </article>

{% endfor %}

</div>

<script>
  (() => {
    const termFilter = document.getElementById("term-filter");
    const eventFilter = document.getElementById("event-filter");
    const entries = Array.from(document.querySelectorAll(".schedule-entry"));
    const emptyMessage = document.querySelector("[data-empty-message]");

    const updateSchedule = () => {
      const selectedTerm = termFilter.value;
      const selectedEvent = eventFilter.value;
      let visibleCount = 0;

      entries.forEach((entry) => {
        const termMatches = entry.dataset.term === selectedTerm;
        const eventMatches = selectedEvent === "all" || entry.dataset.kind === selectedEvent;
        const isVisible = termMatches && eventMatches;

        entry.hidden = !isVisible;
        if (isVisible) visibleCount += 1;
      });

      emptyMessage.hidden = visibleCount > 0;
    };

    termFilter.addEventListener("change", updateSchedule);
    eventFilter.addEventListener("change", updateSchedule);
    updateSchedule();
  })();
</script>

<style>
  .schedule-controls {
    align-items: end;
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin-bottom: 1.25rem;
  }

  .schedule-controls label {
    display: grid;
    gap: 0.25rem;
    min-width: 11rem;
  }

  .schedule-controls span {
    font-size: 0.85rem;
    font-weight: 600;
  }

  .schedule-controls select {
    border: 1px solid var(--global-divider-color);
    border-radius: 6px;
    padding: 0.45rem 0.55rem;
  }

  .schedule-list {
    display: grid;
    gap: 1rem;
  }

  .schedule-entry {
    border: 1px solid var(--global-divider-color);
    border-radius: 8px;
    padding: 1rem;
  }

  .schedule-entry-header {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-bottom: 0.75rem;
  }

  .schedule-entry h2 {
    font-size: 1.05rem;
    line-height: 1.45;
    margin-bottom: 0.75rem;
  }

  .schedule-entry p {
    margin-bottom: 0.35rem;
  }

  .event-tag {
    background: var(--global-theme-color);
    border-radius: 999px;
    color: #fff;
    display: inline-block;
    font-size: 0.8rem;
    font-weight: 600;
    padding: 0.2rem 0.55rem;
  }

  .date-line {
    font-size: 1.05rem;
    font-weight: 600;
  }

  .date-canceled {
    color: #b00020;
  }

  .seminar-tag {
    background: #002147;
  }

  .is-cancelled {
    opacity: 0.82;
  }

  .room-line {
    margin-top: 0.75rem;
  }

  .schedule-empty {
    font-weight: 600;
  }
</style>
