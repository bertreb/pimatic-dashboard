module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  

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

  class DashboardMeasurement extends env.devices.PresenceSensor

    constructor: (@config, lastState, @framework, plugin) ->
      @id = @config.id
      @name = @config.name

      if @_destroyed then return

      @measurement = @config.measurement
      @variables = @config.variables
      @active = @config.active ? true
      @devMgr = @framework.deviceManager
      @varMgr = @framework.variableManager
      if @active then @_setPresence(on) else @_setPresence(off)

      ###
      @varMgr.waitForInit()
      .then(()=>
        unless @active then return
        for variable in @variables
          if _.size(variable.attributes) > 0
            for attr in variable.attributes
              _variableName = variable.deviceId + "." + attr.attributeId
              env.logger.info "variable.deviceId: " + variable.deviceId
              _device = @devMgr.getDeviceById(variable.deviceId)
              env.logger.info "_device.id: " + _device._attributesMeta[attr.attributeId].value
              _variable = _device._attributesMeta[attr.attributeId].value
              #env.logger.info "_variable: " + JSON.stringify(_variable)
              if _variable?
                env.logger.info "_variableName " + _variableName + ", value: " + _variable.value
                _numberedValue = Number _variable.value
              if _variable? and not Number.isNaN(_numberedValue)
                field1 = {}
                field1[attr.attributeId] = _numberedValue
                tag1 = {}
                tag1["device"] = variable.deviceId
                if attr.tag?
                  tag1["label"] = attr.tag
                plugin.Connector.writeMeasurement(@measurement, tag1, field1).then( (result) =>
                  env.logger.debug "Measurement1 #{@measurement} written, tag: #{JSON.stringify(tag1)}, field: #{JSON.stringify(field1)}"
                ).catch( (err) =>
                  env.logger.debug "Error handled: " + err.message
                )
          else
            _device = @varMgr.getDeviceById(variable.deviceId)
            if _device?
              for name, _attr of _device.attributes
                 _variableName = _device.id + "." + name
                _variable = @varMgr.getVariableByName(_variableName)
                _numberedValue = Number _variable.value
                if _variable? and not Number.isNaN(_numberedValue)
                  field2 = {}
                  field2[attr.attributeId] = _numberedValue
                  tag2 = {}
                  tag2["device"] = _device.id
                  if attr.tag?
                    tag2["label"] = attr.tag
                  plugin.Connector.writeMeasurement(@measurement, tag2, field2).then( (result) =>
                    env.logger.debug "Measurement2 #{@measurement} written, tag: #{JSON.stringify(tag2)}, field: #{JSON.stringify(field2)}"
                  ).catch( (err) =>
                    env.logger.debug "Error handled: " + err.message
                  )
      )
      ###

      @eventHandler = (attrEvent) =>
        unless plugin.ready and @active 
          @_setPresence(off)
          return
        @_setPresence(on) unless @_presence
        # <device-id>.<attribute>
        _variable = _.find(@variables, (v)=> v.deviceId.indexOf(attrEvent.device.id)>=0)
        _numberedValue = Number attrEvent.value
        #env.logger.debug "_numberedValue3 " + _numberedValue
        if _variable? and not Number.isNaN(_numberedValue)
          #env.logger.info "DEBUG attrEvent #{@id} + variables #{JSON.stringify(@variables)} device: " + attrEvent.device.id + ', foundVar: ' + (JSON.stringify(_variable.attributes)) + ', attr: ' + attrEvent.attributeName
          if _.size(_variable.attributes) > 0
            _attribute = _.find(_variable.attributes, (a)=> attrEvent.attributeName is a.attributeId)
            unless _attribute? then return
          field3 = {}
          field3[attrEvent.attributeName] = _numberedValue
          tag3 = {}
          tag3["device"] = attrEvent.device.id
          if _attribute.tag?
            tag3["label"] = _attribute.tag
          plugin.Connector.writeMeasurement(@measurement, tag3, field3).then( (result) =>
            env.logger.debug "Measurement3 #{@measurement} written, tag: #{JSON.stringify(tag3)}, field: #{JSON.stringify(field3)}"
          ).catch( (err) =>
            env.logger.debug "Error handled: " + err.message
          )

      @varMgr.waitForInit()
      .then(()=>
        @framework.on 'deviceAttributeChanged', @eventHandler
      )
             
      #@framework.on 'deviceAttributeChanged', @eventHandler
      super()

    destroy: ->
      @framework.removeListener('deviceAttributeChanged', @eventHandler)
      super()


  dashboardPlugin = new DashboardPlugin()
  return dashboardPlugin
