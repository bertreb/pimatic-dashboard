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
      variables:
        description: "Variables to stream to database"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            deviceId:
              description: "Name for the corresponding attribute."
              type: "string"
   }
}
