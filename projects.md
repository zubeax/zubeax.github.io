---
layout: page
title: Projects
permalink: /projects/
description: >
  Proof-of-concept and utility projects that i am hosting on Github. 
---
{% for repo in site.github.public_repositories %}

{% if repo.fork == false and repo.topics.size > 0 %}

{% include project-display.html repo=repo %}

{% endif %}

{% endfor %}
