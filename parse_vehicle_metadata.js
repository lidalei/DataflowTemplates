/**
 * Parse vehicleId and receivedAt in the Pub/Sub message's attributes.
 * @param {string} inJson: JSON string of a map {"message_id": "xx", "data": "xx", "attributes": "xx"}.
 * @return {string} outJson
 */
function transform(inJson) {
    var obj = JSON.parse(inJson);

    if (obj.hasOwnProperty('attributes')) {
        var attributes = JSON.parse(obj.attributes);

        if (attributes.hasOwnProperty("vehicleId")) {
            obj['vehicle_id'] = attributes.vehicleId;
        }

        if (attributes.hasOwnProperty("receivedAt")) {
            obj['received_at'] = new Date(Number(attributes.receivedAt)).toISOString();
        }
    }

    return JSON.stringify(obj);
}