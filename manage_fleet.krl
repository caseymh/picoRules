ruleset manage_fleet{
    meta {
        shares __testing, vehicles, vehicleFromID
    }
    
    global {
        __testing = { 
            "queries": [ { "name": "vehicles"}, {"name": "vehicleFromID", "args": ["id"] }],
            "events": [ 
                { "domain": "car", "type": "new_vehicle", "attrs": [ "vehicle_id" ]} 
                , {"domain": "car", "type": "unneeded_vehicle", "attrs": [ "vehicle_id"]}
                , {"domain": "debug", "type": "clear"}
                ]
            }
        
        vehicles = function(){ent:vehicles}
        vehicleFromID = function(id){ vehicle = ent:vehicles{[id]}.klog("id vehicle ");
            tmp = id.klog("ID ");
            vehicle
            }
    }
    
    rule create_vehicle{
        select when car new_vehicle vehicle_id re#(.*)# setting(id);
        pre{
            exists = ent:vehicles >< id
            eci = meta:eci
        }
        if exists then
            send_directive("vehicle_ready") with
            vehicle_id = id
        
        fired{
        } else {
            raise pico event "new_child_request"
                attributes { "dname": ("Vehicle " + id), "color": "#FF0000", "vehicle_id": id}
        }
    }
    
    rule pico_child_initialized {
        select when pico child_initialized
        pre{
            vehicle = event:attr("new_child")
            id = event:attr("rs_attrs"){"vehicle_id"}
        }
        if id.klog("Found vehicle_id") then
            event:send(
                { "eci": vehicle.eci, "eid": "install-ruleset",
                    "domain": "pico", "type": "new_ruleset",
                    "attrs": { "base": meta:rulesetURI, "url": "trip_tracker.krl", "vehicle_id": id}
                })
        fired {
            ent:vehicles := ent:vehicles.defaultsTo({});
            ent:vehicles{[id]} := vehicle
        }
    }
    
    rule delete_vehicle{
        select when car unneeded_vehicle vehicle_id re#(.*)# setting(id);
        pre{
            exists = ent:vehicles >< id
            eci = meta:eci
            vehicle_to_delete = vehicleFromID(id)
        }
        if exists then
            send_directive("vehicle_deleted") with
            vehicle_id = id
        fired{
            raise pico event "delete_child_request"
                attributes vehicle_to_delete;
            ent:vehicles{[id]} := null
        }
    }
    
    rule clear{
        select when debug clear 
        always{
            ent:vehicles := {}
        }
    }
}