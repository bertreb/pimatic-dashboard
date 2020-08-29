# pimatic-dashboard
Plugin for presenting Pimatic data via an Influx database and Grafana dashboard

This plugin pushes pimatic device attribute values to an influx database with a grafana dashboard.
The plugin is based on the pimatic-influxdb plugin from [treban](https://github.com/treban/pimatic-influxdb).

This plugin is focussed on presenting pimatic data in one or more grafana dashboards. You create a dashboard device and give it a measument name. Add devices that you want to add to this measurement. You can add all the device attribute to be used in the measurement or you can select specific attributes. If no attribute is selected, ALL device attributes will be used.

Influxdb needs to be installed before the first device is added. For the dashboards Grafana needs to bee installed.

Influxdb installation
--------

Influxdb is a time-series database and designed for realtime IoT applications.
Several instructions for installing Influxdb on your machine can be found on the internet.
The following Influxdb information is important for the connection and is used in the Pimatic dashboard plugin config.

```
  database: Database name used in influxdb. If absent, the database is automatically created (default: pimatic)
  username: Username for access influx api
  password: Password for access influx api
  ip: The IP address of the influxdb rest api
  port: port from the influxdb rest api (default: 8086)
```


Grafana installation
--------
t.b.d.

## Measurement Device

In the measurement device you can add Pimatic device attributes to be streamed to Influxdb. You can add a device with all the numeric attributes or select specific attributes per device. Per Measurement device an Influx measurement is created. The measurements name must be set in the device config.
This way you can create a set of data combined into a measurement series of data. Influx will store this data and in Grafana you can create a dashboard with this data.

After the device is created and pimatic devices/attributes are added, the fields and data will be added automatically to the database after the first updates of attributes.

**Device configuration**

```
  measurement: The measurement name for grouping the variables
  active: If enabled the data of this measurement will be streamed (default: true)
  variables: Variables to be streamed to Influx database (name from plugin config)
    [ 
      deviceId: Pimatic deviceId of the to be used attributes
      attributes: Attributes to stream to database
        [
          attributeId: AttributeId of the to be used attributes
          tag: Extra tag for Grafana queries
        ]
    ]
```