---
layout: page
title: Schedule
permalink: /reading-group/
nav: true
nav_order: 1
description: Schedule for the Optopus Reading Group.
---

{% assign schedule_terms = site.data.reading_group_schedule %}

<div class="schedule-subscribe" aria-label="Calendar subscriptions">
  {% for term in schedule_terms %}
    {% assign term_name = term[0] %}
    {% assign calendar_slug = term_name | downcase %}
    {% assign calendar_url = '/calendars/' | append: calendar_slug | append: '.ics' | relative_url %}
    <div class="calendar-link">
      <a href="{{ calendar_url }}">{{ term_name }} calendar</a>
      <button type="button" data-copy-url="{{ calendar_url }}">Copy ICS URL</button>
    </div>
  {% endfor %}
</div>

<div class="schedule-controls" aria-label="Schedule filters">
  <label>
    <span>Term</span>
    <select id="term-filter">
      {% for term in schedule_terms %}
        <option value="{{ term[0] }}">{{ term[0] }}</option>
      {% endfor %}
    </select>
  </label>

  <label>
    <span>Activity</span>
    <select id="kind-filter">
      <option value="all" selected>All activities</option>
      <option value="reading-group">Reading Group</option>
      <option value="seminar">Seminar</option>
    </select>
  </label>
</div>

<p class="schedule-empty" data-empty-message hidden>No events scheduled for this selection.</p>

<div class="schedule-table-wrap">
  <table class="schedule-table">
    <thead>
      <tr>
        <th scope="col">Week</th>
        <th scope="col">Date</th>
        <th scope="col">Talk</th>
        <th scope="col">Speaker</th>
      </tr>
    </thead>
    <tbody>
      {% for schedule_term in schedule_terms %}
        {% assign term_name = schedule_term[0] %}
        {% assign term_schedule = schedule_term[1] %}
        {% for event in term_schedule.events %}
        {% assign week_number = event.date | schedule_week: term_schedule.start_date %}
        <tr
          class="{% if event.canceled %}is-cancelled{% endif %} {% if event.canceled and event.kind == 'reading-group' %}is-cancelled-rg{% endif %}"
          data-term="{{ term_name }}"
          data-kind="{{ event.kind }}"
        >
          <td data-label="Week">
            <span class="week-code">{{ week_number }}</span>
          </td>
          <td data-label="Date">
            <span class="date-time-line">
              <span class="date-code">{{ event.date | schedule_day }} {{ event.date | date: "%d/%m" }}</span>
              <span class="time-code">{{ event.time }}</span>
            </span>
            <span class="room-code">{{ event.room }}</span>
          </td>
          <td data-label="Talk">
            <div class="talk-cell">
              {% if event.kind == 'seminar' %}
                <span class="event-chip seminar-chip">Sem</span>
              {% else %}
                <span class="event-chip">RG</span>
              {% endif %}

              <span class="talk-title">
                {% if event.canceled %}
                  {% if event.note %}
                    {{ event.note }}
                  {% else %}
                    Canceled
                  {% endif %}
                {% elsif event.link_url %}
                  <a href="{{ event.link_url }}">{{ event.title }}</a>
                {% else %}
                  {{ event.title }}
                {% endif %}
              </span>
            </div>
          </td>
          <td data-label="Speaker">
            {% if event.canceled %}
              <span class="muted">-</span>
            {% elsif event.speaker and event.speaker != '' %}
              {{ event.speaker }}
              {% if event.speaker_affiliation and event.speaker_affiliation != '' %}
                <span class="muted">({{ event.speaker_affiliation }})</span>
              {% endif %}
            {% else %}
              <span class="muted">TBA</span>
            {% endif %}
          </td>
        </tr>
        {% endfor %}
      {% endfor %}
    </tbody>

  </table>
</div>

<script>
  (() => {
    const termFilter = document.getElementById("term-filter");
    const kindFilter = document.getElementById("kind-filter");
    const rows = Array.from(document.querySelectorAll(".schedule-table tbody tr"));
    const emptyMessage = document.querySelector("[data-empty-message]");
    const copyButtons = Array.from(document.querySelectorAll("[data-copy-url]"));

    const updateSchedule = () => {
      const selectedTerm = termFilter.value;
      const selectedKind = kindFilter.value;
      let visibleCount = 0;

      rows.forEach((row) => {
        const termMatches = row.dataset.term === selectedTerm;
        const kindMatches = selectedKind === "all" || row.dataset.kind === selectedKind;
        const isVisible = termMatches && kindMatches;

        row.hidden = !isVisible;
        if (isVisible) visibleCount += 1;
      });

      emptyMessage.hidden = visibleCount > 0;
    };

    termFilter.addEventListener("change", updateSchedule);
    kindFilter.addEventListener("change", updateSchedule);
    copyButtons.forEach((button) => {
      const initialText = button.textContent;

      button.addEventListener("click", async () => {
        const url = new URL(button.dataset.copyUrl, window.location.href).href;

        try {
          await navigator.clipboard.writeText(url);
          button.textContent = "Copied";
          window.setTimeout(() => {
            button.textContent = initialText;
          }, 1600);
        } catch (_error) {
          window.prompt("Copy this ICS URL", url);
        }
      });
    });

    updateSchedule();
  })();
</script>

<style>
  .schedule-subscribe {
    display: flex;
    flex-wrap: wrap;
    gap: 0.65rem;
    margin: 1rem 0 1.25rem;
  }

  .calendar-link {
    align-items: center;
    border: 1px solid var(--global-divider-color);
    border-radius: 8px;
    display: inline-flex;
    gap: 0.5rem;
    padding: 0.45rem 0.55rem;
  }

  .calendar-link a {
    font-weight: 700;
    white-space: nowrap;
  }

  .calendar-link button {
    background: var(--global-theme-color);
    border: 0;
    border-radius: 6px;
    color: #fff;
    cursor: pointer;
    font-size: 0.82rem;
    font-weight: 700;
    padding: 0.35rem 0.5rem;
    white-space: nowrap;
  }

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

  .schedule-empty {
    font-weight: 600;
  }

  .schedule-table-wrap {
    border: 1px solid var(--global-divider-color);
    border-radius: 8px;
    margin-top: 1.25rem;
    overflow: hidden;
  }

  .schedule-table {
    border-collapse: collapse;
    font-size: 0.95rem;
    margin: 0;
    width: 100%;
  }

  .schedule-table th,
  .schedule-table td {
    border-bottom: 1px solid var(--global-divider-color);
    padding: 0.8rem 0.9rem;
    text-align: left;
    vertical-align: top;
  }

  .schedule-table th {
    background: rgba(0, 0, 0, 0.03);
    color: var(--global-text-color);
    font-size: 0.78rem;
    font-weight: 700;
    letter-spacing: 0;
    text-transform: uppercase;
  }

  .schedule-table tbody tr:last-child td {
    border-bottom: 0;
  }

  .schedule-table tbody tr:hover {
    background: rgba(0, 0, 0, 0.03);
  }

  .schedule-table td:first-child,
  .schedule-table td:nth-child(2) {
    white-space: nowrap;
  }

  .week-code {
    font-weight: 700;
  }

  .date-time-line {
    display: inline-flex;
    gap: 0.45rem;
  }

  .date-code,
  .room-code,
  .time-code {
    display: block;
  }

  .room-code {
    margin-top: 0.1rem;
    opacity: 0.78;
  }

  .talk-cell {
    align-items: flex-start;
    display: flex;
    gap: 0.55rem;
  }

  .event-chip {
    background: var(--global-theme-color);
    border-radius: 999px;
    color: #fff;
    display: inline-flex;
    flex: 0 0 auto;
    font-size: 0.75rem;
    font-weight: 700;
    line-height: 1;
    padding: 0.35rem 0.55rem;
    white-space: nowrap;
  }

  .seminar-chip {
    background: #002147;
  }

  .talk-title {
    line-height: 1.45;
  }

  .muted {
    color: var(--global-text-color);
    opacity: 0.7;
  }

  .is-cancelled {
    opacity: 0.72;
  }

  .is-cancelled-rg .week-code,
  .is-cancelled-rg .date-code,
  .is-cancelled-rg .time-code {
    color: #b00020;
    text-decoration: line-through;
    text-decoration-thickness: 0.12em;
  }

  .is-cancelled-rg .talk-title {
    color: #b00020;
  }

  @media (max-width: 760px) {
    .schedule-table-wrap {
      border: 0;
      border-radius: 0;
      overflow: visible;
    }

    .schedule-table,
    .schedule-table tbody,
    .schedule-table tr,
    .schedule-table td {
      display: block;
      width: 100%;
    }

    .schedule-table thead {
      display: none;
    }

    .schedule-table tr {
      border: 1px solid var(--global-divider-color);
      border-radius: 8px;
      margin-bottom: 0.85rem;
      padding: 0.75rem;
    }

    .schedule-table td {
      border-bottom: 0;
      display: grid;
      gap: 0.35rem;
      padding: 0.25rem 0;
      white-space: normal;
    }

    .schedule-table td::before {
      color: var(--global-text-color);
      content: attr(data-label);
      font-size: 0.75rem;
      font-weight: 700;
      opacity: 0.7;
      text-transform: uppercase;
    }

    .talk-cell {
      display: grid;
      gap: 0.45rem;
    }
  }
</style>
