ruleset manage_fleet{
    meta {
        shares __testing, vehicles, vehicleFromID, report
    }
    
    global {
        __testing = { 
            "queries": [ { "name": "vehicles"}, {"name": "vehicleFromID", "args": ["id"] }, {"name":"report"}],
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
            
        host = function() {meta:host()}
            
        reportold = function(){
            last = {};
            c = ent:vehicles.map(function(x) {
                ind = ent:vehicles.index(x).klog("index");
                vehicle = x.klog("vehicle");                
                eci = vehicle["eci"].klog("eci");
                res = cloud(eci,"trip_store","trips",{}).klog("resp ")
                });
            last
        }
        
        reportHelp = function(keys, cont){
            keys.length() > 0 =>
             reportHelpHelp(keys,cont,pos,size).klog("return from reportHelp")
            | cont.klog("last")
            
        }
        //todo Get this to work with multiple trips
        reportHelpHelp = function(keys, cont){
            key = keys.head().klog("head ");
            head = ent:vehicles{key}.klog("head");
            eci = head["eci"].klog("eci");
            res = cloud(eci, "trip_store", "trips", {}).klog("resp ");
            cont = addCont(cont,key,res);
            tail = keys.tail().klog("tail");
            cont = reportHelp(tail,cont).klog("ret");
            cont.klog("help help cont")
        }
        
        addCont = function(cont, key, res){
            res.length().klog("results leng") > 0 =>
                addContHelp(cont,key,res).klog("addcontHelp results")
                | cont
        }
        
        addContHelp = function(cont,key,res){
            cont{key} = res;
            cont
        }
        
        report = function(){
            cont = {};
            cont = reportHelp(ent:vehicles.keys().klog("keys"),cont);
            numResp = cont.keys().length().klog("Number responses");
            numVehicles = ent:vehicles.keys().length().klog("Num vehicles");
            cont.klog("cont");
            ret = { "vehicles": numVehicles, "responding" : numResp,"trips":cont};
            ret.klog("Report")
        }
        
        cloud_url = ("http://localhost:8080/sky/cloud/")
 
        cloud = function(eci, mod, func, params) {
            url = (cloud_url + eci+ "/" + mod + "/" +func).klog("url ");
            response = http:get(url, params).klog("response ");
 
 
            status = response{"status_code"};
            
            contLen = response{"content_length"};
            contLen > 0 => response{"content"}.decode()[0].klog("content") | []
 
 
            //response_content = response{"content"}.decode().klog("content ")
            //status eq "200"  => response_content | "{}"
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
            event:send(
                { "eci": vehicle.eci, "eid": "install-ruleset",
                    "domain": "pico", "type": "new_ruleset",
                    "attrs": { "base": meta:rulesetURI, "url": "trip_store.krl", "vehicle_id": id}
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