ruleset manage_fleet{
    meta {
        shares __testing, vehicles, vehicleFromID, report, reports, get_reports
    }
    
    global {
        __testing = { 
            "queries": [ { "name": "vehicles"}, {"name": "vehicleFromID", "args": ["id"] }, {"name":"report"}, {"name":"reports"}, {"name":"get_reports"}],
            "events": [ 
                { "domain": "car", "type": "new_vehicle", "attrs": [ "vehicle_id" ]} 
                , {"domain": "car", "type": "unneeded_vehicle", "attrs": [ "vehicle_id"]}
                , {"domain": "car", "type": "create_fleet_report"}
                , {"domain": "debug", "type": "clear"}
                , {"domain": "debug", "type": "clear_reports"}
                ]
            }
        
        vehicles = function(){ent:vehicles}
        vehicleFromID = function(id){ vehicle = ent:vehicles{[id]}.klog("id vehicle ");
            tmp = id.klog("ID ");
            vehicle
            }
            
        host = function() {meta:host()}
        
        reports = function(){ent:reports}
        
        get_reports = function(){
            keys = get_reports_get_keys();
            rep = {};
            get_reports_build_reports(keys,rep)
        }
        
        get_reports_build_reports = function(keys, rep){
            keys.length() > 0 =>
            get_reports_help(keys,rep).klog("return from get_reports_help")
            | rep
        }
        
        get_reports_help = function(keys, rep){
            key = keys.head().klog("key ");
            head = ent:reports{key}.klog("head");
            singleRep = get_reports_build_vehicle_report(head);
            tail = keys.tail().klog("tail");
            rep{key} = singleRep;
            rep = get_reports_build_reports(tail,rep).klog("ret");
            rep.klog("help help cont")
            
        }
        
        get_reports_build_vehicle_report = function(vehicles){        
            cont = {};
            cont = get_reports_reportHelp(vehicles, vehicles.keys().klog("keys"),cont);
            numResp = cont.keys().length().klog("Number responses");
            numVehicles = vehicles.keys().length().klog("Num vehicles");
            cont.klog("cont");
            ret = { "vehicles": numVehicles, "responding" : numResp,"trips":cont};
            ret.klog("Report")
        }
        
        get_reports_reportHelp = function(vehicles, keys, cont){
            keys.length() > 0 =>
             get_reports_reportHelpHelp(vehicles, keys,cont,pos,size).klog("return from reportHelp")
            | cont.klog("last")
            
        }
        //todo Get this to work with multiple trips
        get_reports_reportHelpHelp = function(vehicles, keys, cont){
            tmp = keys.klog("keys help help");
            key = keys.head().klog("head ");
            head = vehicles{key}.klog("head");
            cont = addCont(cont,key,head).klog("get_reports_reportHelpHelp cont");
            tail = keys.tail().klog("tail");
            cont = get_reports_reportHelp(vehicles, tail,cont).klog("ret");
            cont.klog("help help cont")
        }
        
        get_reports_get_keys = function(){
            keys = ent:reports.keys().klog("keys");
            last_pos = keys.length().klog("keys length");
            last_pos = last_pos - 1;
            keys.length() < 5 =>
                keys
            | keys.reverse().slice(0,4).reverse()        
        }
            
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
            
            contLen = response{"content_length"};
            contLen > 0 => response{"content"}.decode().klog("content") | []
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
    
    rule create_report{
        select when car create_fleet_report        
        foreach ent:vehicles.keys() setting(key)
        pre{
            report_num = ent:report_num.defaultsTo(1).klog("report_num")
            corr_id = "report #" + report_num
            vehicle = ent:vehicles{key.klog("key")}.klog("vehicle")
            num_keys = ent:vehicles.keys().length()
            last_key = ent:vehicles.keys()[num_keys -1].klog("last_key")
        }
        event:send(
            { "eci": vehicle.eci.klog("vehicle eci"), "eid": "create_fleet_report",
                "domain": "car", "type": "car_report",
                "attrs": { "parent_eci": meta:eci.klog("parent eci"), "vehicle_id": key, "correlation_id": corr_id}
            }.klog("send")) 
        fired{
            ent:report_num := report_num + 1 if(key == ent:vehicles.keys()[num_keys -1])
        }   
    }
    
    rule car_report_created{
        select when car car_report_created report re#(.*)# setting (rpt)
        pre{
            veh_rept = rpt.klog("report: ")
            vehicle_id = event:attr("vehicle_id").klog("Report for vehicle")
            corr_id = event:attr("correlation_id").klog("corr_id")
            reports = ent:reports.defaultsTo({})
            vehicles = reports{corr_id}.defaultsTo({}).klog("vehicles")
            vehicles{vehicle_id} = veh_rept
            reports{corr_id} = vehicles
        }
        fired{
            ent:reports := reports.klog("report created:")
        }
    }
    
    rule clear_reports{
        select when debug clear_reports
        always{
            ent:reports := {};
            ent:report_num := 1
        }
    }
    
    
    rule clear{
        select when debug clear 
        always{
            ent:vehicles := {}
        }
    }
}