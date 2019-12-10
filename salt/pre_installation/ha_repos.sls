ha-factory-repo:
  pkgrepo.managed:
    - name: ha-factory
    - baseurl: {{ grains['ha_sap_deployment_repo'] }}
    - gpgautoimport: True
    # Reduce the ha-factory priority in order to install HA packages from there
    {% if grains.get('devel_mode') %}
    - priority: 98
    {% else %}
    - priority: 110
    {% endif %}
    - refresh: True
    - retry:
        attempts: 3
        interval: 15

{% if grains.get('devel_mode') %}
allow_all_vendor_changes:
  file.append:
    - name: /etc/zypp/zypp.conf
    - text: solver.allowVendorChange = true
{% endif %}

refresh_ha_factory_repos:
  cmd.run:
    - name: zypper --non-interactive --gpg-auto-import-keys refresh
    - requre:
      - pkgrepo: ha-factory-repo


workaround_susecloud_register:
  cmd.run:
    - name: |
        rm /etc/SUSEConnect && /
        rm -f $(ls /etc/zypp/{repos,services,credentials}.d/* | grep -v -e 'ha-factory' -e 'server_monitoring') && /
        rm -f /usr/lib/zypp/plugins/services/* && /
        sed -i '/^# Added by SMT reg/,+1d' /etc/hosts && /
        /usr/sbin/registercloudguest --force-new && /
        zypper --non-interactive --gpg-auto-import-keys refresh
    - retry:
        attempts: 3
        interval: 15
    - onlyif: 'test -e /usr/sbin/registercloudguest'
    - onfail:
      - cmd: refresh_repos
