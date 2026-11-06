resource "opensearch_index" "geo_fence_events" {
  name               = "geo-fence-events"
  number_of_shards   = "1"
  number_of_replicas = "1"

  mappings = jsonencode({
    properties = {
      eventTimestampUtc = {
        type = "date"
      }
      geoFenceCenter = {
        type = "geo_point"
      }
      geoFenceInnerRadiusMeters = {
        type = "double"
      }
      geoFenceOuterRadiusMeters = {
        type = "double"
      }
      geoFencePolygonInner = {
        type = "geo_shape"
      }
      geoFencePolygonOuter = {
        type = "geo_shape"
      }
      siteId = {
        type = "keyword"
      }
    }
  })
}

resource "opensearch_index" "radar_event_path" {
  name               = "radar-event-path"
  number_of_shards   = "1"
  number_of_replicas = "1"

  mappings = jsonencode({
    properties = {
      distanceFromCenter = {
        type = "double"
      }
      docId = {
        type = "keyword"
      }
      eventLocation = {
        type = "geo_point"
      }
      eventTimestampUtc = {
        type = "date"
      }
      id = {
        type = "keyword"
      }
      siteId = {
        type = "keyword"
      }
      trackId = {
        type = "keyword"
      }
      zone = {
        type = "keyword"
      }
    }
  })
}

resource "opensearch_index" "voice_cdr_events" {
  name               = "voice-cdr-events"
  number_of_shards   = "1"
  number_of_replicas = "1"

  mappings = jsonencode({
    properties = {
      callDuration = {
        type = "keyword"
      }
      callingPosition = {
        type = "geo_point"
      }
      dateTimeConnect = {
        type = "date"
      }
      dateTimeDisconnect = {
        type = "date"
      }
      datetime = {
        type = "date"
      }
      destCalledPartyNumber = {
        type = "keyword"
      }
      id = {
        type = "keyword"
      }
      origCallingPartyNumber = {
        type = "keyword"
      }
      siteId = {
        type = "keyword"
      }
    }
  })
}


resource "opensearch_index" "radar_l01" {
  name               = "radar-l01"
  number_of_shards   = "1"
  number_of_replicas = "1"

  mappings = jsonencode({
    properties = {
      distance = {
        type = "float"
      }
      id = {
        type = "text"
        fields = {
          keyword = {
            type         = "keyword",
            ignore_above = 256
          }
        }
      }
      position = {
        type = "geo_point"
      }
      siteId = {
        type = "keyword"
      }
      timestamp = {
        type = "date"
      }
      trackId = {
        type = "keyword"
      }
    }
  })
}

resource "opensearch_index" "radar_l02" {
  name               = "radar-l02"
  number_of_shards   = "1"
  number_of_replicas = "1"

  mappings = jsonencode({
    properties = {
      distance = {
        type = "float"
      }
      id = {
        type = "text"
        fields = {
          keyword = {
            type         = "keyword",
            ignore_above = 256
          }
        }
      }
      position = {
        type = "geo_point"
      }
      siteId = {
        type = "keyword"
      }
      timestamp = {
        type = "date"
      }
      trackId = {
        type = "keyword"
      }
    }
  })
}

resource "opensearch_index" "radar_l03" {
  name               = "radar-l03"
  number_of_shards   = "1"
  number_of_replicas = "1"

  mappings = jsonencode({
    properties = {
      distance = {
        type = "float"
      }
      id = {
        type = "text"
        fields = {
          keyword = {
            type         = "keyword",
            ignore_above = 256
          }
        }
      }
      position = {
        type = "geo_point"
      }
      siteId = {
        type = "keyword"
      }
      timestamp = {
        type = "date"
      }
      trackId = {
        type = "keyword"
      }
    }
  })
}

resource "opensearch_index" "correlated_event" {
  name               = "correlated-event"
  number_of_shards   = "1"
  number_of_replicas = "1"

  mappings = jsonencode({
    properties = {
      forensicIntelligenceMarker = {
        fields = {
          keyword = {
            type         = "keyword",
            ignore_above = 256
          }
        },
        type = "text"
      }
      id = {
        fields = {
          keyword = {
            type         = "keyword",
            ignore_above = 256
          }
        },
        type = "text"
      }
      position = {
        type = "geo_point"
      }
      radarTrackEventTimestamp = {
        type = "date"
      }
      siteId = {
        type = "keyword"
      }
      timestamp = {
        type = "date"
      }
      trackId = {
        type = "keyword"
      }
      voiceCdrConnectTime = {
        type = "date"
      }
      voiceCdrDestinationNumber = {
        fields = {
          keyword = {
            type         = "keyword",
            ignore_above = 256
          }
        },
        type = "text"
      }
      voiceCdrDisconnectTime = {
        type = "date"
      }
      voiceCdrEventTimestamp = {
        type = "date"
      }
      voiceCdrId = {
        fields = {
          keyword = {
            type         = "keyword",
            ignore_above = 256
          }
        },
        type = "text"
      }
      voiceCdrOriginNumber = {
        fields = {
          keyword = {
            type         = "keyword",
            ignore_above = 256
          }
        },
        type = "text"
      }
    }
  })
}


resource "opensearch_index" "radar_event_position" {
  name               = "radar-event-position"
  number_of_shards   = "1"
  number_of_replicas = "1"

  mappings = jsonencode({
    properties = {
      distanceFromCenter = {
        type = "double"
      }
      docId = {
        type = "keyword"
      }
      eventLocation = {
        type = "geo_point"
      }
      eventTimestampUtc = {
        type = "date"
      }
      id = {
        type = "keyword"
      }
      siteId = {
        type = "keyword"
      }
      trackId = {
        type = "keyword"
      }
      zone = {
        type = "keyword"
      }
    }
  })
}

resource "opensearch_index" "radar_heartbeat_event" {
  name               = "radar-heartbeat-event"
  number_of_shards   = "1"
  number_of_replicas = "1"

  mappings = jsonencode({
    properties = {
      dateTime = {
        type = "date"
      }
      id = {
        type = "keyword"
      }
      radarTemperature = {
        type = "double"
      }
      radarTransmitPowerLevel = {
        type = "double"
      }
      siteId = {
        type = "keyword"
      }
    }
  })
}
