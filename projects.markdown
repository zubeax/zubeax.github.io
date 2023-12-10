---
layout: page
title: Projects
permalink: /projects/
---
{% for repo in site.github.public_repositories %}

{% include project-display.html repo=repo %}

{% endfor %}
