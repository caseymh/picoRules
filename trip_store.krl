ruleset trip_store{
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
        clear_trip = { }
        clear_long_trip = {}
    }
    
    rule collect_trips{
        select when explicit trip_processed milage re#(.*)# setting(mile); 
        pre{
            time = time:now().klog("time ")
            }
        send_directive("say") with
        something = "Hello " + ent:trips.klog("trips ")
        always{
            ent:trips := ent:trips.defaultsTo(clear_trip, "initialization was needed");
            ent:trips{[time, "milage"]} := mile
        }
    }
    
    rule collect_long_trips{
        select when explicit found_long_trip milage re#(.*)# setting(mile);
        pre{
            time = time:now().klog("time ")
            }
        send_directive("say") with
        something = "Hello " + ent:trips.klog("trips ")
        always{
            ent:long_trip := ent:long_trip.defaultsTo(clear_long_trip, "initialization was needed");
            ent:long_trip{[time, "milage"]} := mile;
            klog(ent:long_trip)
        }
    }
    
    rule clear_trips{
        select when car trip_reset 
        always{ 
            ent:trips := clear_trip;
            ent:long_trip := clear_long_trip
        }
        
    }
}