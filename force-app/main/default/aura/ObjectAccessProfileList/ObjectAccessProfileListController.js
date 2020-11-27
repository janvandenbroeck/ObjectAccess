({
	doInit : function(cmp, event, helper) {
        var action = cmp.get("c.getProfiles");
        
        action.setCallback(this, function(response){
            if (response.getState() === "SUCCESS") {
				var resp = response.getReturnValue();
                resp.sort(helper.dynamicSort('-usercount'));
               	cmp.set('v.listProfiles', resp);
            }
            else if (response.getState() === "ERROR") {
                var errors = response.getError();
	            if (errors) {
               		if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message); 
                    }
                } else {
                    console.log("Unknown error");
            	}
            }
        });
        $A.enqueueAction(action);
	},
    
    selectProfile : function(cmp, event, helper) {
        var objEvent = cmp.getEvent("ObjectAccessProfileEvent");
		objEvent.setParams({"profileid" : event.getSource().get("v.name")});
		objEvent.fire();
    }
    
})