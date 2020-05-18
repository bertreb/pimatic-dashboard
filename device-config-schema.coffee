module.exports = {
  title: "DashboardMeasurement"
  DashboardMeasurement: {
    title: "DashboardMeasurement config"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      measurement:
        description: "The measurement name for grouping the variables"
        type: "string"     
      active:
        description: "If enabled the data of this measurement will be streamed"
        type: "boolean"     
      variables:
        description: "Variables to stream to database"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            deviceId:
              description: "DeviceId of the to be used attributes"
              type: "string"
            attributes:
              description: "Attributes to stream to database"
              type: "array"
              default: []
              format: "table"
              items:
                type: "object"
                properties:
                  attributeId:
                    description: "AttributeId of the to be used attributes"
                    type: "string"

   }
}
