ruleset track_trips{
    meta {
        shares message, __testing
    }
    
    global {
        __testing = { 
            "events": [ 
                { "domain": "echo", "type": "message", "attrs": ["milage"] } 
                ]
            }
    }
    
    rule process_trip{
        select when echo message milage re#(.*)# setting(mile);
        send_directive("trip") with
        trip_length = mile
    }
}