({
	processProfileId : function(cmp, event, helper) {
		var action = cmp.get("c.getCustomObjectCount");
        var profileId = cmp.get('v.profileId');
        
        action.setParams({ ProfileId : profileId});
        
        action.setCallback(this, function(response){
            if (response.getState() === "SUCCESS") {
				var resp = response.getReturnValue();
               	var users = [];
                for (var key in resp) {
      				users.push({
        				username: key,
                        value: resp[key]
      				});
                }
                users.sort(helper.dynamicSort('-value'));
               	cmp.set('v.listUsers', users);
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
	}
})