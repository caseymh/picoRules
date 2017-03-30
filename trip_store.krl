ruleset trip_store{
    meta {
        shares __testing,trips, long_trips, short_trips
        provides trips, long_trips, short_trips
    }
    
    global {
        __testing = { "queries": [ { "name": "trips" },
                           { "name": "long_trips" } ,
                           { "name": "short_trips"}],
            "events": [ 
                { "domain": "car", "type": "new_trip"} 
                , {"domain": "explicit", "type": "car_report", "attrs":["vehicle_id","parent_eci"]}
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
    
    rule car_report{
        select when explicit car_report parent_eci re#(.*)# setting (par_eci);
        pre{
            vehicle_id = event:attr("vehicle_id").klog("vehicle_id")
            
            trips = trips().klog("trips")
        }
        fired{
            
            event:send(
                { "eci": par_eci, "eid": "car_report",
                    "domain": "car", "type": "car_report_results",
                    "attrs": { "report": trips.klog("report to send"), "vehicle_id": id}
                })
        }
    }
    
    rule test{
        select when car test
        pre{
            tmp = "testing".klog("test")
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