ruleset trip_store{
    meta {
        shares __testing , long_trips, short_trips
        provides trips, long_trips, short_trips
    }
    
    global {
        __testing = { 
            "events": [ 
                { "domain": "car", "type": "new_trip"} 
                ]
            }
        
        clear_trip = []
        clear_long_trip = []
        
        trips = function(){
            ent:trips
        }
        
        long_trips = function(){
            ent:long_trips
        }
        
        short_trips = function(){
            a = trips().difference(long_trips())  
        }
    }
    
    rule collect_trips{
        select when explicit trip_processed milage re#(.*)# setting(mile); 
        pre{
            time = event:attr("timestamp")
            trip = {"time": time,"milage": mile}
            }
        always{
            ent:trips := ent:trips.defaultsTo(clear_trip, "initialization was needed");
            ent:trips := ent:trips.append([trip]).klog("ent:trips: ")
        }
    }
    
    rule collect_long_trips{
        select when explicit found_long_trip milage re#(.*)# setting(mile);
        pre{
            time = event:attr("timestamp")
            long_trip = {"time": time,"milage": mile}
            tmp = long_trip.klog("long_trip: ")
            }
        always{
            ent:long_trips := ent:long_trips.defaultsTo(clear_long_trip, "initialization was needed");
            ent:long_trips := ent:long_trips.append([long_trip]).klog("ent:long:trips: ")
        }
    }
    
    rule clear_trips{
        select when car trip_reset 
        pre{
            tmp = trips().klog("trips")
            tmp = long_trips().klog("long_trips")
            tmp = short_trips().klog("short_trips")
            }
        always{ 
            ent:trips := clear_trip;
            ent:long_trips := clear_long_trip
        }
        
    }
}