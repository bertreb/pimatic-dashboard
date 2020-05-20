module.exports = (env) ->

  Influx = require 'influx'
  events = require 'events'
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  Flatted = require 'flatted'

  class InfluxConnection extends events.EventEmitter

    constructor: (username,password,ip,port,database="pimatic") ->
      super()
      @ready=false
      @ip=ip
      @port=port
      @database=database
      @username=username
      @password=password
      @connect()
      reconnect = setInterval =>
        if not @ready
          @emit 'notready'
          @connect()
        else
          @ready=false
          @influxcon.ping(5000).then( (hosts) =>
            hosts.forEach( (host) =>
              if host.online
                env.logger.debug "influxdb keep alive check ok"
                @ready=true
              else
                env.logger.debug "host.online " + JSON.stringify(host.online,null,2)
                #env.logger.debug "keep alive not responding " + Flatted.stringify(host.res,null,2)
            )
          ).catch( (err) =>
            env.logger.debug "Error handled: " + err.message
          )
      ,60000

    connect: () =>
      env.logger.debug "reconnecting to influxdb"
      dbConfig = 
        username: @username
        password: @password
        database: @database
        host: @ip
        port: @port
      @influxcon = new Influx.InfluxDB(dbConfig)
      #@influxcon = new Influx.InfluxDB('http://'+@ip+":"+@port+'/'+@database, )

      @influxcon.getDatabaseNames().then( (dbs) =>
        if (!dbs.includes(@database))
          env.logger.debug "pimatic database not found"
          env.logger.debug "creating new '#{@database}'' database"
          @influxcon.createDatabase(@database)
        @ready=true
        @emit 'ready'
        env.logger.debug @database + " database ok"
      ).catch( (err) =>
        env.logger.error "could not connect to influxdb: " + JSON.stringify(err.message,null,2)
      )

    getDatabaseNames: () =>
      return @influxcon.getDatabaseNames()

    getMeasurements: (db) =>
      return @influxcon.getMeasurements(db)

    getSeries: (measure,db) =>
      return @influxcon.getSeries({measurement: measure, database: db})

    query: (query,db=pimatic) =>
      env.logger.debug query
      return @influxcon.query(query,{database: db})

    writeMeasurement: (measurement, tags,fields) =>
      # measurement_name,tag keys + value separated by comma Field keys with value separated by comma
      return @influxcon.writeMeasurement(measurement, [
        {
          tags: tags,
          fields: fields
        }
      ])
