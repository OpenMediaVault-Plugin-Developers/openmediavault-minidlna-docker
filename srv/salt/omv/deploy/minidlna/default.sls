# @license   http://www.gnu.org/licenses/gpl.html GPL Version 3
# @author    OpenMediaVault Plugin Developers <plugins@omv-extras.org>
# @copyright Copyright (c) 2019-2022 OpenMediaVault Plugin Developers
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

{%- set config = salt['omv_conf.get']('conf.service.minidlna') %}
{%- set dbdir = salt['pillar.get']('default:OMV_MINIDLNA_DB_DIR', '/var/cache/minidlna') %}
{%- set logdir = salt['pillar.get']('default:OMV_MINIDLNA_LOG_DIR', '/var/log') %}
{%- set serial = salt['pillar.get']('default:OMV_MINIDLNA_SERIAL', '31446138') %}

{%- if config.enable | to_bool %}
{%- set count = namespace(a=0) %}

minidlna_container:
  docker_container.running:
    - image: vladgh/minidlna:latest
    - port_bindings: 
      - {{ config.port }}:8200
    - environment:
      - port: {{ config.port }}
      - friendly_name: "{{ config.name }}"
      - db_dir: "{{ dbdir }}"
      - log_dir: "{{ logdir }}"
      - enable_tivo: "{{ 'yes' if config.tivo else 'no' }}"
      - wide_links: "{{ 'yes' if config.widelinks else 'no' }}"
      - strict_dlna: "{{ 'yes' if config.strict else 'no' }}"
      - serial: "{{ serial }}"
{%- if config.rootcontainer | length > 0 %}
      - root_container: "{{ config.rootcontainer }}"
{%- else %}
      - root_container: "."
{%- endif %}
      - log_level: "log_level=general,artwork,database,inotify,scanner,metadata,http,ssdp,tivo={{ config.loglevel }}"
{%- for share in config.shares.share %}
{%- set sfpath = salt['omv_conf.get_sharedfolder_path'](share.sharedfolderref) %}
{%- set count.a = count.a + 1 %}
      - MINIDLNA_MEDIA_DIR_{{ count.a }}: "{% if share.mtype | length > 0 %}{{ share.mtype }},{% endif %}{{ sfpath }}"
{%- endfor %}

{%- else %}

minidlna_container:
  docker_container.absent:
  - force: True

{%- endif %}
