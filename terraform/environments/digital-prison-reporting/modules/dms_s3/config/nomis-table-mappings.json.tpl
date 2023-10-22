{
    "rules": [
        {
            "rule-type": "selection",
            "rule-id": "516455653",
            "rule-name": "516455653",
            "object-locator": {
                "schema-name": "OMS_OWNER",
                "table-name": "OFFENDERS"
            },
            "rule-action": "include",
            "filters": []
        },
        {
            "rule-type": "selection",
            "rule-id": "870343798",
            "rule-name": "870343798",
            "object-locator": {
                "schema-name": "OMS_OWNER",
                "table-name": "OFFENDER_BOOKINGS"
            },
            "rule-action": "include",
            "filters": []
        },
        {
            "rule-type": "selection",
            "rule-id": "870343799",
            "rule-name": "870343799",
            "object-locator": {
                "schema-name": "OMS_OWNER",
                "table-name": "AGENCY_LOCATIONS"
            },
            "rule-action": "include",
            "filters": []
        },
        {
            "rule-type": "selection",
            "rule-id": "870343800",
            "rule-name": "870343800",
            "object-locator": {
                "schema-name": "OMS_OWNER",
                "table-name": "AGENCY_INTERNAL_LOCATIONS"
            },
            "rule-action": "include",
            "filters": []
        },
        {
            "rule-type": "selection",
            "rule-id": "870343801",
            "rule-name": "870343801",
            "object-locator": {
                "schema-name": "OMS_OWNER",
                "table-name": "OFFENDER_EXTERNAL_MOVEMENTS"
            },
            "rule-action": "include",
            "filters": []
        },
        {
            "rule-type": "selection",
            "rule-id": "870343802",
            "rule-name": "870343802",
            "object-locator": {
                "schema-name": "OMS_OWNER",
                "table-name": "MOVEMENT_REASONS"
            },
            "rule-action": "include",
            "filters": []
        },
        {
            "rule-type": "transformation",
            "rule-id": "870343803",
            "rule-name": "870343803",
            "rule-action": "add-column",
            "rule-target": "column",
            "object-locator": {
              "schema-name": "%",
              "table-name": "%"
            },
            "rule-action": "add-column",
            "value":"_source",
            "expression": "$AR_M_SOURCE_SCHEMA",
            "data-type": {
               "type": "string",
               "length": 50
            }
        },
        {
            "rule-type": "transformation",
            "rule-id": "870343804",
            "rule-name": "870343804",
            "rule-action": "add-column",
            "rule-target": "column",
            "object-locator": {
              "schema-name": "%",
              "table-name": "%"
            },
            "rule-action": "add-column",
            "value":"_table",
            "expression": "$AR_M_SOURCE_TABLE_NAME",
            "data-type": {
               "type": "string",
               "length": 70
            }
        }
    ]
}