({
    handleObjectAccessProfileEvent : function(cmp, event, helper) {
        var profileId = event.getParam("profileid");
        cmp.set('v.profileId', profileId);
    }
})