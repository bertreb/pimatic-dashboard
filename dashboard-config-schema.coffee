module.exports = {
  title: "Dashboard plugin config options"
  type: "object"
  required: []
  properties:
    database:
      description: "Database name used in influxdb"
      type: "string"
      default: "pimatic"
    username:
      description: "Username for access influx api"
      type: "string"
      required: true
    password:
      description: "Password for access influx api"
      type: "string"
      required: true
    ip:
      description: "IP address of the influxdb rest api"
      type: "string"
      required: true
    port:
      description: "Port of the influxdb rest api"
      type: "string"
      default: "8086"
    debug:
      description: "Enabled debug messages"
      type: "boolean"
      default: false
}
