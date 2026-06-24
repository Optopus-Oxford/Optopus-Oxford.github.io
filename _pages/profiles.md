---
layout: page
permalink: /people/
title: Current Members
nav_title: People
nav: true
nav_order: 2
---

{% assign fallback_image = 'prof_pic.jpg' %}

<section class="people-section">
  <div class="people-grid">
    {% for person in site.data.people.current %}
      {% assign image = fallback_image %}
      {% if person.image and person.image != '' %}
        {% assign image = person.image %}
      {% endif %}

      {% if image contains '://' %}
        {% assign image_src = image %}
      {% else %}
        {% assign image_src = image | prepend: 'assets/img/' | relative_url %}
      {% endif %}

      <article class="person-card">
        <div class="person-photo">
          <img src="{{ image_src }}" alt="{{ person.name }}">
        </div>

        <div class="person-name">
          {% if person.website and person.website != '' %}
            <a href="{{ person.website }}">{{ person.name }}</a>
          {% else %}
            {{ person.name }}
          {% endif %}
        </div>
        <div class="person-meta">{{ person.title }}</div>
        {% unless person.title == 'Professor' %}
          <div class="person-meta">{{ person.years }}</div>
        {% endunless %}
      </article>
    {% endfor %}

  </div>
</section>

<section class="people-section people-section-old" aria-labelledby="old-members-heading">
  <h2 id="old-members-heading">Old Members</h2>

  <div class="people-grid">
    {% for person in site.data.people.old %}
      {% assign image = fallback_image %}
      {% if person.image and person.image != '' %}
        {% assign image = person.image %}
      {% endif %}

      {% if image contains '://' %}
        {% assign image_src = image %}
      {% else %}
        {% assign image_src = image | prepend: 'assets/img/' | relative_url %}
      {% endif %}

      <article class="person-card">
        <div class="person-photo">
          <img src="{{ image_src }}" alt="{{ person.name }}">
        </div>

        <div class="person-name">
          {% if person.website and person.website != '' %}
            <a href="{{ person.website }}">{{ person.name }}</a>
          {% else %}
            {{ person.name }}
          {% endif %}
        </div>
        <div class="person-meta">{{ person.title }}</div>
        {% unless person.title == 'Professor' %}
          <div class="person-meta">{{ person.years }}</div>
        {% endunless %}
      </article>
    {% endfor %}

  </div>
</section>

<style>
  .people-section {
    margin-top: 1.25rem;
  }

  .people-section-old {
    margin-top: 3rem;
  }

  .people-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    gap: 1.5rem;
  }

  .person-card {
    min-width: 0;
  }

  .person-photo {
    aspect-ratio: 9 / 16;
    width: 100%;
    overflow: hidden;
    background: var(--global-divider-color);
    border-radius: 4px;
  }

  .person-photo img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }

  .person-name {
    margin-top: 0.75rem;
    font-weight: 700;
  }

  .person-meta {
    margin-top: 0.1rem;
    color: var(--global-text-color);
    line-height: 1.4;
  }

  @media (max-width: 575px) {
    .people-grid {
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 1.25rem 1rem;
    }
  }
</style>
