ruleset trip_tracker{
    meta {
        shares process_trip, __testing
    }
    
    global {
        __testing = { 
            "events": [ 
                { "domain": "car", "type": "new_trip"} 
                ]
            }
    }
    
    rule process_trip{
        select when car new_trip milage re#(.*)# setting(mile);
        pre{ tmp = event:attr("milage").klog("milage passed in: ")}
        send_directive("trip") with
        trip_length = mile
    }
}