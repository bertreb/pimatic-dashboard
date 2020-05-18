module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  Flatted = require 'flatted'


  InfluxConnection = require('./influx-connector')(env)

  class DashboardPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      @ip = @config.ip
      @port = @config.port
      @username = @config.username
      @password = @config.password
      @database = @config.database ? "pimatic"

      @ready=false

      @connect()

      @dev_map={}

      deviceConfigDef = require("./device-config-schema.coffee")
      @framework.deviceManager.registerDeviceClass("DashboardMeasurement", {
        configDef: deviceConfigDef["DashboardMeasurement"],
        createCallback: (deviceConfig, lastState) => new DashboardMeasurement(deviceConfig, lastState, @framework, this)
      })
      
      @framework.deviceManager.on 'discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-dashboard', "scan for databases ..."
        @Connector.getDatabaseNames().then( (dbase) =>
          for db in dbase
            if db is @database
              @framework.deviceManager.discoverMessage 'pimatic-dashboard', "scan for databases ... database #{@database} found!"
            ###
            do (db) =>
              @Connector.getMeasurements(db).then( (names) =>
                for nam in names
                  do (nam) =>
                    @framework.deviceManager.discoverMessage 'pimatic-dashboard', "scan for databases ... found: #{nam}"
              )
            ###
        )

    connect: () =>
      @Connector = new InfluxConnection(@username, @password, @ip, @port, @database)
      @Connector.on "ready", =>
        @ready = true
        @emit "ready"
      @Connector.on "notready", =>
        @ready = false

  class DashboardMeasurement extends env.devices.Device

    constructor: (@config, lastState, @framework, plugin) ->
      @id = @config.id
      @name = @config.name
      @measurement = @config.measurement
      @variables = @config.variables
      @active = @config.active ? true

      @framework.variableManager.waitForInit()
      .then(() =>
        unless @active then return
        for variable in @variables
          if _.size(variable.attributes) > 0
            env.logger.info "variable.attributes: " + JSON.stringify(variable.attributes,null,2)
            for attr in variable.attributes
               _variableName = variable.deviceId + "." + attr.attributeId
              env.logger.info "Attributes: " + _variableName
              _variable = @framework.variableManager.getVariableByName(_variableName)
              env.logger.info "_variable: " + _variable.value
              if _variable.value? and not Number.isNaN(Number _variable.value)
                env.logger.debug variable.deviceId + " write " + attr.attributeId + " with "+ _variable.value
                field = {}
                field[attr.attributeId] = _variable.value
                plugin.Connector.writeMeasurement(@measurement, {device: variable.deviceId}, field).then( (result) =>
                  env.logger.debug "ok"
                ).catch( (err) =>
                  env.logger.error err.message
                )
          else
            _device = @framework.deviceManager.getDeviceById(variable.deviceId)
            if _device?
              for name, _attr of _device.attributes
                 _variableName = _device.id + "." + name
                env.logger.info "Attributes: " + _variableName
                _variable = @framework.variableManager.getVariableByName(_variableName)
                if _variable? and not Number.isNaN(Number _variable.value)
                  env.logger.debug _device.id + " write " + attr.attributeId + " with "+ _variable.value
                  field = {}
                  field[attr.attributeId] = _variable.value
                  plugin.Connector.writeMeasurement(@measurement, {device: _device.id}, field).then( (result) =>
                    env.logger.debug "ok"
                  ).catch( (err) =>
                    env.logger.error err.message
                  )
      )

      @eventHandler = (attrEvent) =>
        unless plugin.ready and @active then return
        # <device-id>.<attribute>
        _variable = _.find(@config.variables, (d)=> d.deviceId is attrEvent.device.id)
        if _variable?
          if _.size(_variable.attributes) > 0
            unless _.find(_variable.attributes, (a)=> attrEvent.attributeName is a.attributeId) then return
          env.logger.debug "measurement: " + @measurement + ", " + attrEvent.device.id + " write " + attrEvent.attributeName + " with "+ attrEvent.value
          field = {}
          field[attrEvent.attributeName] = attrEvent.value
          plugin.Connector.writeMeasurement(@measurement, {device: attrEvent.device.id}, field).then( (result) =>
            env.logger.debug "ok"
          ).catch( (err) =>
            env.logger.error err.message
          )
             
      @framework.on 'deviceAttributeChanged', @eventHandler
      super()

    destroy: ->
      @framework.removeListener('deviceAttributeChanged', @eventHandler)
      super()


  dashboardPlugin = new DashboardPlugin()
  return dashboardPlugin
