---
layout: page
title: Schedule
permalink: /reading-group/
nav: true
nav_order: 1
description: Schedule for the Optopus Reading Group.
---

{% assign schedule_terms = site.data.reading_group_schedule | schedule_terms_by_start_date %}

<div class="schedule-controls" aria-label="Schedule filters">
  <label>
    <span>Term</span>
    <select id="term-filter">
      {% for term in schedule_terms %}
        {% assign term_name = term[0] %}
        {% assign calendar_slug = term_name | downcase %}
        {% assign calendar_url = '/calendars/' | append: calendar_slug | append: '.ics' | relative_url %}
        {% assign term_schedule = term[1] %}
        {% assign term_identifier = term_name | append: ' ' | append: term_schedule.name | upcase %}
        {% assign show_week_numbers = true %}
        {% if term_identifier contains 'LV' %}
          {% assign show_week_numbers = false %}
        {% endif %}
        <option
          value="{{ term_name }}"
          data-calendar-url="{{ calendar_url }}"
          data-start-date="{{ term_schedule.start_date }}"
          data-show-week-numbers="{{ show_week_numbers }}"
        >
          {{ term_name }}
        </option>
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

  <button class="subscribe-button" type="button" data-subscribe-open>Subscribe</button>
</div>

<div class="subscribe-modal" data-subscribe-modal hidden>
  <div class="subscribe-dialog" role="dialog" aria-modal="true" aria-labelledby="subscribe-title">
    <div class="subscribe-header">
      <h2 id="subscribe-title">Subscribe to calendar</h2>
      <button class="subscribe-close" type="button" aria-label="Close" data-subscribe-close>&times;</button>
    </div>

    <label class="subscribe-provider">
      <span>Calendar app</span>
      <select id="calendar-provider">
        <option value="apple">Apple Calendar</option>
        <option value="outlook">Outlook</option>
        <option value="gmail">Gmail</option>
      </select>
    </label>

    <ol class="subscribe-steps" data-subscribe-steps></ol>

    <label class="subscribe-url">
      <span>Calendar URL</span>
      <div class="subscribe-url-row">
        <input type="text" readonly data-subscribe-url>
        <button type="button" data-copy-subscribe-url>Copy</button>
      </div>
    </label>
  </div>
</div>

<p class="schedule-empty" data-empty-message hidden>No events scheduled for this selection.</p>

<div class="schedule-table-wrap">
  <table class="schedule-table">
    <thead>
      <tr>
        <th scope="col" data-week-column>Week</th>
        <th scope="col">Date</th>
        <th scope="col">Talk</th>
        <th scope="col">Speaker</th>
      </tr>
    </thead>
    <tbody>
      {% for schedule_term in schedule_terms %}
        {% assign term_name = schedule_term[0] %}
        {% assign term_schedule = schedule_term[1] %}
        {% assign term_identifier = term_name | append: ' ' | append: term_schedule.name | upcase %}
        {% assign show_week_numbers = true %}
        {% if term_identifier contains 'LV' %}
          {% assign show_week_numbers = false %}
        {% endif %}
        {% for event in term_schedule.events %}
        {% if show_week_numbers %}
          {% assign week_number = event.date | schedule_week: term_schedule.start_date %}
        {% endif %}
        <tr
          class="{% if event.canceled %}is-cancelled{% endif %} {% if event.canceled and event.kind == 'reading-group' %}is-cancelled-rg{% endif %}"
          data-term="{{ term_name }}"
          data-kind="{{ event.kind }}"
        >
          <td data-label="Week" data-week-column>
            {% if show_week_numbers %}
              <span class="week-code">{{ week_number }}</span>
            {% else %}
              <span class="muted"></span>
            {% endif %}
          </td>
          <td data-label="Date">
            <span class="date-time-code">{{ event.date | date: "%a %d/%m" }}, {{ event.time }}</span>
            <span class="room-code">{{ event.room }}</span>
          </td>
          <td data-label="Talk">
            <div class="talk-cell">
              {% if event.kind == 'seminar' %}
                <span class="event-chip seminar-chip">Sem</span>
              {% else %}
                <span class="event-chip">RG</span>
              {% endif %}

              {% assign ref_count = event.refs | size %}
              {% assign talk_title = event.title | schedule_title %}
              <div class="talk-copy">
                <span class="talk-title">
                  {% if event.canceled %}
                    {{ talk_title }}
                  {% elsif event.link_url and ref_count == 0 %}
                    <a href="{{ event.link_url }}">{{ talk_title }}</a>
                  {% else %}
                    {{ talk_title }}
                  {% endif %}
                  {% for ref in event.refs %}
                    <a class="talk-ref" href="{{ ref.url }}">{{ ref.label }}</a>
                  {% endfor %}
                </span>
                {% if event.canceled and event.note %}
                  <span class="talk-note">{{ event.note }}</span>
                {% endif %}
              </div>
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
    const scheduleTable = document.querySelector(".schedule-table");
    const rows = Array.from(document.querySelectorAll(".schedule-table tbody tr"));
    const emptyMessage = document.querySelector("[data-empty-message]");
    const subscribeButton = document.querySelector("[data-subscribe-open]");
    const subscribeModal = document.querySelector("[data-subscribe-modal]");
    const closeSubscribeButton = document.querySelector("[data-subscribe-close]");
    const providerSelect = document.getElementById("calendar-provider");
    const subscribeTitle = document.getElementById("subscribe-title");
    const subscribeSteps = document.querySelector("[data-subscribe-steps]");
    const subscribeUrlInput = document.querySelector("[data-subscribe-url]");
    const copySubscribeButton = document.querySelector("[data-copy-subscribe-url]");

    const providerSteps = {
      apple: [
        "Open Apple Calendar.",
        "Choose File > New Calendar Subscription.",
        "Paste the calendar URL, then click Subscribe.",
        "Choose refresh settings and click OK.",
      ],
      outlook: [
        "Open Outlook Calendar.",
        "Choose Add calendar.",
        "Choose Subscribe from web.",
        "Paste the calendar URL, name the calendar, and save.",
      ],
      gmail: [
        "Open Google Calendar in a browser.",
        "Next to Other calendars, click +.",
        "Choose From URL.",
        "Paste the calendar URL and click Add calendar.",
      ],
    };

    const termOptions = Array.from(termFilter.options);

    const parseLocalDate = (dateValue) => {
      const parts = dateValue.split("-").map(Number);
      if (parts.length !== 3 || parts.some(Number.isNaN)) return null;

      return new Date(parts[0], parts[1] - 1, parts[2]);
    };

    const todayLocalDate = () => {
      const now = new Date();
      return new Date(now.getFullYear(), now.getMonth(), now.getDate());
    };

    const selectedOption = () => termFilter.options[termFilter.selectedIndex];

    const selectedCalendarUrl = () => new URL(selectedOption().dataset.calendarUrl, window.location.href).href;

    const selectedTermName = () => selectedOption().textContent.trim();

    const selectedTermFromUrl = () => {
      const params = new URLSearchParams(window.location.search);
      const term = params.get("term");
      return termOptions.some((option) => option.value === term) ? term : null;
    };

    const selectedKindFromUrl = () => {
      const params = new URLSearchParams(window.location.search);
      const kind = params.get("activity");
      return Array.from(kindFilter.options).some((option) => option.value === kind) ? kind : null;
    };

    const persistFilters = () => {
      const url = new URL(window.location.href);
      url.searchParams.set("term", termFilter.value);
      url.searchParams.set("activity", kindFilter.value);
      window.history.replaceState({}, "", url);
    };

    const sortTermOptions = () => {
      termOptions
        .sort((firstOption, secondOption) => {
          const firstStartDate = parseLocalDate(firstOption.dataset.startDate) || new Date(9999, 11, 31);
          const secondStartDate = parseLocalDate(secondOption.dataset.startDate) || new Date(9999, 11, 31);

          return secondStartDate - firstStartDate || secondOption.value.localeCompare(firstOption.value);
        })
        .forEach((option) => termFilter.append(option));
    };

    const selectDefaultTerm = () => {
      const urlTerm = selectedTermFromUrl();
      if (urlTerm) {
        termFilter.value = urlTerm;
        return;
      }

      const selectionThreshold = todayLocalDate();
      selectionThreshold.setDate(selectionThreshold.getDate() + 7);

      const defaultOption = termOptions.reduce((candidate, option) => {
        const startDate = parseLocalDate(option.dataset.startDate);
        if (!startDate || startDate > selectionThreshold) return candidate;
        if (!candidate) return option;

        const candidateStartDate = parseLocalDate(candidate.dataset.startDate);
        return startDate > candidateStartDate ? option : candidate;
      }, null);

      termFilter.value = defaultOption ? defaultOption.value : termOptions[0].value;
    };

    const selectDefaultKind = () => {
      kindFilter.value = selectedKindFromUrl() || "all";
    };

    const renderSubscribeModal = () => {
      subscribeTitle.textContent = `Subscribe to ${selectedTermName()} calendar`;
      subscribeUrlInput.value = selectedCalendarUrl();
      subscribeSteps.replaceChildren(
        ...providerSteps[providerSelect.value].map((step) => {
          const item = document.createElement("li");
          item.textContent = step;
          return item;
        }),
      );
    };

    const openSubscribeModal = () => {
      renderSubscribeModal();
      subscribeModal.hidden = false;
      providerSelect.focus();
    };

    const closeSubscribeModal = () => {
      subscribeModal.hidden = true;
      subscribeButton.focus();
    };

    const updateSchedule = () => {
      const selectedTerm = termFilter.value;
      const selectedKind = kindFilter.value;
      const showWeekNumbers = selectedOption().dataset.showWeekNumbers === "true";
      let visibleCount = 0;

      scheduleTable.classList.toggle("has-no-week-column", !showWeekNumbers);

      rows.forEach((row) => {
        const termMatches = row.dataset.term === selectedTerm;
        const kindMatches = selectedKind === "all" || row.dataset.kind === selectedKind;
        const isVisible = termMatches && kindMatches;

        row.hidden = !isVisible;
        if (isVisible) visibleCount += 1;
      });

      emptyMessage.hidden = visibleCount > 0;
    };

    termFilter.addEventListener("change", () => {
      persistFilters();
      updateSchedule();
    });
    kindFilter.addEventListener("change", () => {
      persistFilters();
      updateSchedule();
    });
    termFilter.addEventListener("change", renderSubscribeModal);
    providerSelect.addEventListener("change", renderSubscribeModal);
    subscribeButton.addEventListener("click", openSubscribeModal);
    closeSubscribeButton.addEventListener("click", closeSubscribeModal);
    subscribeModal.addEventListener("click", (event) => {
      if (event.target === subscribeModal) closeSubscribeModal();
    });
    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && !subscribeModal.hidden) closeSubscribeModal();
    });
    copySubscribeButton.addEventListener("click", async () => {
      const initialText = copySubscribeButton.textContent;

      try {
        await navigator.clipboard.writeText(subscribeUrlInput.value);
        copySubscribeButton.textContent = "Copied";
        window.setTimeout(() => {
          copySubscribeButton.textContent = initialText;
        }, 1600);
      } catch (_error) {
        subscribeUrlInput.select();
        window.prompt("Copy this calendar URL", subscribeUrlInput.value);
      }
    });

    sortTermOptions();
    selectDefaultTerm();
    selectDefaultKind();
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

  .subscribe-button {
    background: var(--global-theme-color);
    border: 0;
    border-radius: 6px;
    color: #fff;
    cursor: pointer;
    font-weight: 700;
    margin-left: auto;
    padding: 0.52rem 0.75rem;
  }

  .subscribe-modal {
    align-items: center;
    background: rgba(0, 0, 0, 0.42);
    display: flex;
    inset: 0;
    justify-content: center;
    padding: 1rem;
    position: fixed;
    z-index: 1100;
  }

  .subscribe-modal[hidden] {
    display: none;
  }

  .subscribe-dialog {
    background: var(--global-bg-color);
    border: 1px solid var(--global-divider-color);
    border-radius: 8px;
    box-shadow: 0 1.25rem 3rem rgba(0, 0, 0, 0.24);
    color: var(--global-text-color);
    max-width: 34rem;
    padding: 1rem;
    width: min(100%, 34rem);
  }

  .subscribe-header {
    align-items: center;
    display: flex;
    gap: 1rem;
    justify-content: space-between;
    margin-bottom: 0.9rem;
  }

  .subscribe-header h2 {
    font-size: 1.2rem;
    line-height: 1.2;
    margin: 0;
  }

  .subscribe-close {
    background: transparent;
    border: 0;
    color: var(--global-text-color);
    cursor: pointer;
    font-size: 1.6rem;
    line-height: 1;
    padding: 0.1rem 0.2rem;
  }

  .subscribe-provider,
  .subscribe-url {
    display: grid;
    gap: 0.35rem;
  }

  .subscribe-provider span,
  .subscribe-url span {
    font-size: 0.85rem;
    font-weight: 700;
  }

  .subscribe-provider select,
  .subscribe-url input {
    border: 1px solid var(--global-divider-color);
    border-radius: 6px;
    padding: 0.55rem 0.6rem;
  }

  .subscribe-steps {
    margin: 1rem 0;
    padding-left: 1.35rem;
  }

  .subscribe-steps li {
    margin: 0.35rem 0;
  }

  .subscribe-url-row {
    display: flex;
    gap: 0.5rem;
  }

  .subscribe-url-row input {
    flex: 1 1 auto;
    min-width: 0;
  }

  .subscribe-url-row button {
    background: var(--global-theme-color);
    border: 0;
    border-radius: 6px;
    color: #fff;
    cursor: pointer;
    font-weight: 700;
    padding: 0.55rem 0.7rem;
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

  .schedule-table.has-no-week-column [data-week-column] {
    display: none;
  }

  .schedule-table td:first-child,
  .schedule-table td:nth-child(2) {
    white-space: nowrap;
  }

  .week-code {
    font-weight: 700;
  }

  .date-time-code,
  .room-code,
  .talk-note {
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

  .talk-copy {
    display: block;
  }

  .talk-ref {
    white-space: nowrap;
  }

  .talk-note {
    font-size: 0.88rem;
    line-height: 1.35;
    margin-top: 0.2rem;
    opacity: 0.78;
  }

  .muted {
    color: var(--global-text-color);
    opacity: 0.7;
  }

  .is-cancelled {
    opacity: 0.72;
  }

  .is-cancelled-rg .week-code,
  .is-cancelled-rg .date-time-code {
    color: #b00020;
    text-decoration: line-through;
    text-decoration-thickness: 0.12em;
  }

  .is-cancelled-rg .talk-title {
    color: #b00020;
    text-decoration: line-through;
    text-decoration-thickness: 0.12em;
  }

  @media (max-width: 760px) {
    .subscribe-button {
      margin-left: 0;
      width: 100%;
    }

    .subscribe-url-row {
      display: grid;
    }

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
