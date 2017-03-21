ruleset trip_tracker{
    meta {
        logging on
        shares process_trip, __testing, find_long_trips, found_long_trip
    }
    
    global {
        __testing = { 
            "events": [ 
                { "domain": "car", "type": "new_trip"} 
                ]
            }
        
        long_trip = 15
    }
    
    rule process_trip{
        select when car new_trip milage re#(.*)# setting(mile);
        pre { 
            tmp = attrr("milage").klog("Processing")
        }
        send_directive("trip") with
        trip_length = mile
        fired{
            raise explicit event "trip_processed" 
             attributes event:attrs()
        }
    }
    
    rule find_long_trips{
        select when explicit trip_processed  milage re#(.*)# setting(mile);
        
        pre { 
            tmp = event:attr("milage").klog("find_long_trips milage: ")
        }
        fired{
            raise explicit event "found_long_trip"
            attributes event:attrs()
        } else{
            klog("Not fired")}
    }
    
    rule found_long_trip{
        select when explicit found_long_trip 
        pre { 
            tmp = event:attrs().klog("found_long_trip attributes: ")
        }
        
    }
}