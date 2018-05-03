public class ObjectAccessController {
	// General Approach:
	// -  Get all the profiles where there is a restriction.
	// -  Get all the users for those profiles
	// -  Get all the permission sets of those users
	// -  For all the profiles and permission sets, get the custom objects they give access to (not in a namespace, with suffix __c)
	// -  For each user, get the number of unique custom objects they have access to across profile and permission sets
	// -  List the users and their number of custom objects
	// -  Visualize Order, Case, Contract, Quote, Opportunity, Contact, Lead, Account, Campaign


    @AuraEnabled
    public static Map<String, Map<String, String>> getCustomObjectCount(Id ProfileId){
        // Get all the users of the profile
        List<User> liUsers = getUsers(ProfileId);

        // Get all the permission sets of those users
        // Maps User IDs to a set of Permission Sets
        Map<Id, Set<Id>> mpPermSets = getUserPermissionSets(liUsers);

        // Add the Profile-owned permission set
        List<PermissionSet> liProfilePermSetId = [SELECT id FROM PermissionSet WHERE ProfileId =: ProfileId];
        if(liProfilePermSetId.size() > 1){
            System.debug('ERROR: More than one permission set assigned to this profile?');
        }
        for (User u: liUsers){
            mpPermSets.get(u.Id).add(liProfilePermSetId.get(0).Id);
        }

       // get the custom objects the profile/permsets give access to
       // Set of all Permission Set IDs involved
        Set<Id> setAllPermSets = new Set<Id>();

        for(Id uId: mpPermSets.keySet()){
            setAllPermSets.addAll(mpPermSets.get(uId));
        }

        // Prepare the resultmap
        // Maps Usernames to map containing counts and standard objects
        Map<String, Map<String, String>> mpUserResult = new Map<String, Map<String, String>>();

        // Prepare the result lists on permission set basis
        Map<Id, Set<String>> mpPermSetstoObjects = getCustomObjectPermissions(setAllPermSets);
        Map<Id, Map<String,String>> mpPermSetstoStandardObjects = getStandardObjectPermissions(setAllPermSets);


        // Loop over user to transform to per-user basis
        for (User u: liUsers){
            Set<String> setObjectNames = new Set<String>();
            Map<String,String> resultByUser = new Map<String,String>();


            for(Id permSetId: mpPermSets.get(u.Id)){
                // Convert Custom Object Count
                if(mpPermSetstoObjects.keySet().contains(permSetId)){
               	    setObjectNames.addAll(mpPermSetstoObjects.get(permSetId));
                }
                // Convert Standard Objects
                if(mpPermSetstoStandardObjects.keySet().contains(permSetId)){
                    // temporarily store Standard Object names to access level for this PermSet
                    Map<String, String> mpStandardObjectAccess = mpPermSetstoStandardObjects.get(permSetId);

                    // Loop over each object for this PermSet
                    for(String standardobject : mpStandardObjectAccess.keyset()){
                        // access is the (R, C, E, C/E) access this permission set has for this object
                        String access = mpStandardObjectAccess.get(standardobject);

                        if (!resultByUser.containsKey(standardobject)){
                            resultByUser.put(standardobject, access);
                            continue;
                        }

                        String currentAccess = resultByUser.get(standardobject);

                        if(currentAccess == 'C/E'){
                            continue;
                        }
                        if(currentAccess == 'C' && (access == 'E' || access == 'C/E')){
                            resultByUser.put(standardobject, 'C/E');
                            continue;
                        }
                        if(currentAccess == 'E' && (access == 'C' || access == 'C/E')){
                            resultByUser.put(standardobject, 'C/E');
                            continue;
                        }
                        if(currentAccess == 'R' && (access == 'C' || access == 'E' || access == 'C/E')){
                            resultByUser.put(standardobject, access);
                            continue;
                        }
                    }
                }

            }
            resultByUser.put('customobjects', String.valueOf(setObjectNames.size()));

            mpUserResult.put(u.Username, resultByUser);
        }

        return mpUserResult;
    }

    public static List<User> getUsers(Id ProfileId) {
        return [SELECT Name, Username from User WHERE ProfileId =: ProfileId];
    }

    public static List<User> getUsers(List<Id> ProfileIds) {
        return [SELECT Name, Username from User WHERE ProfileId =: ProfileIds];
    }

    public static Map<ID, Set<Id>> getUserPermissionSets(List<Id> UserIds){
        List<PermissionSetAssignment> liPSAs = [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =: UserIds];

        Map<ID, Set<Id>> mpUsersToPermissionSets = new Map<ID, Set<Id>>();

        for(PermissionSetAssignment PSA: liPSAs){
            if(!mpUsersToPermissionSets.containsKey(PSA.AssigneeId)){
            	// user not known yet
            	mpUsersToPermissionSets.put(PSA.AssigneeId, new Set<ID>());
            }
            mpUsersToPermissionSets.get(PSA.AssigneeId).add(PSA.PermissionSetId);
        }
        return mpUsersToPermissionSets;
    }

    public static Map<ID, Set<Id>> getUserPermissionSets(List<User> userList){
		List<Id> liUserIds = new List<Id>();
        for (User u: userList){
            liUserIds.add(u.Id);
        }
        return getUserPermissionSets(liUserIds);
    }

    public static Map<Id, Set<String>> getCustomObjectPermissions(Set<Id> profilesPermSets){
        Map<Id, Set<String>> mpObjectPerms = new Map<Id, Set<String>>();
        Map<String, Schema.SObjectType> mpSchema = Schema.getGlobalDescribe();
        Set<String> setRelevantObjects = new Set<String>();

        // Find relevant objects (custom, non-namespaced)
        for(String objName: mpSchema.keySet()){
            Schema.DescribeSObjectResult dor = mpSchema.get(objName).getDescribe();
            if(dor.isCustom() && !dor.isCustomSetting() && objName.endsWith('__c') && objName.indexOf('__') == objName.length()-3){
                setRelevantObjects.add(objName);
            }
        }

		List<ObjectPermissions> liObjectPerms = [SELECT ParentId, SobjectType FROM ObjectPermissions WHERE ParentId IN :profilesPermSets AND SObjectType IN :setRelevantObjects];
        for(ObjectPermissions op: liObjectPerms){
        	if(!mpObjectPerms.containsKey(op.ParentId)){
            	mpObjectPerms.put(op.ParentId, new Set<String>());
            }
            mpObjectPerms.get(op.ParentId).add(op.SobjectType);
        }
        return mpObjectPerms;

    }

    public static Map<Id, Map<String,String>> getStandardObjectPermissions(Set<Id> profilesPermSets){
        Map<Id, Map<String,String>> mpObjectPerms = new Map<Id, Map<String,String>>();
        String[] relevantObjects = new String[]{'Order', 'Case', 'Contract', 'Quote', 'Opportunity', 'Contact', 'Lead', 'Account', 'Campaign'};

        List<ObjectPermissions> liObjectPerms = [SELECT ParentId, SobjectType, PermissionsCreate, PermissionsRead, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
                                                 FROM ObjectPermissions
                                                 WHERE ParentId IN :profilesPermSets AND SObjectType IN :relevantObjects];

        for(ObjectPermissions op: liObjectPerms){
        	if(!mpObjectPerms.containsKey(op.ParentId)){
            	mpObjectPerms.put(op.ParentId, new Map<String, String>());
            }
            if(op.PermissionsCreate && op.PermissionsEdit){
            	mpObjectPerms.get(op.ParentId).put(op.SobjectType, 'C/E');
                continue;
            }
            if(op.PermissionsCreate){
            	mpObjectPerms.get(op.ParentId).put(op.SobjectType, 'C');
                continue;
            }
            if(op.PermissionsEdit){
            	mpObjectPerms.get(op.ParentId).put(op.SobjectType, 'E');
                continue;
            }
            if(op.PermissionsRead){
            	mpObjectPerms.get(op.ParentId).put(op.SobjectType, 'R');
                continue;
            }
        }
        return mpObjectPerms;
    }


    @AuraEnabled
   	public static List<Object> getProfiles(){
        List<Object> li = [SELECT MAX(Profile.Id) Id, Profile.Name, COUNT(Id) usercount FROM User WHERE Profile.usertype = 'standard' GROUP BY Profile.Name];
        return li;
    }
}
