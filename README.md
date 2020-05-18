# pimatic-dashboard
Plugin for presenting Pimatic data via an Influx database and Grafana dashboard

This plugin pushes pimatic device attribute values to an influx database with a grafana dashboard.
The plugin is based on the pimatic-influxdb plugin from [treban](https://github.com/treban/pimatic-influxdb).


This plugin is focussed on presenting pimatic data in one or more grafana dashboards. You create a dashboard device and give it a measument name. Add devices that you want to add to this measurement. You can add all the device attribute to be used in the measurement or you can select specific attributes. If no attribute is selected, ALL device attributes will be used.
