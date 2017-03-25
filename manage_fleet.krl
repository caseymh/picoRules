ruleset manage_fleet{
    meta {
        shares __testing, long_trip
    }
    
    global {
        __testing = { 
            "events": [ 
                { "domain": "car", "type": "new_trip", "attrs": [ "milage" ]} 
                ]
            }
        
        vehicles() = function(){val = "Here are all vehicles I know about";
        val}
    }
    
    rule create_vehicle{
        select when car new_vehicle 
        send_directive("say") with
        something = "Creating vehicle"
    }
    
    rule delete_vehicle{
        select when car unneeded_vehicle
        send_derictive("say") with      
        something = "Deleting vehicle"
    }
}