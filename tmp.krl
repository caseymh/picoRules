ruleset trip_tracker{
    meta {
        shares __testing, long_trip
    }
    
    global {
        __testing = { 
            "events": [ 
                { "domain": "car", "type": "new_trip"} 
                ]
            }
        
        long_trip = function(){val = 15;
        val}
    }
    
    rule process_trip{
        select when car new_trip milage re#(.*)# setting(mile);
        send_directive("trip") with
        trip_length = mile
        fired{
            raise explicit event "trip_processed" 
             attributes event:attrs()
        }
    }
    
    rule find_long_trips{
        select when explicit trip_processed milage re#(.*)# setting(mile);
        
        pre { 
            tmp = mile.klog("Milage: ")
            tmp = (mile > long_trip()).klog("Is longest trip: ")
            tmp = long_trip().klog("long_trip: ")
        }
        fired{
            raise explicit event "found_long_trip"
            attributes event:attrs() if (mile > long_trip())
        }
    }
    
    rule found_long_trip{
        select when explicit found_long_trip 
        pre { 
            tmp = event:attr("milage").klog("found_long_trip milage: ")
        }
        
    }
}