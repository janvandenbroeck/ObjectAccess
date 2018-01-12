public class ObjectAccessController {
	// General Approach:
	// -  Get all the profiles where there is a restriction.
	// -  Get all the users for those profiles
	// -  Get all the permission sets of those users
	// -  For all the profiles and permission sets, get the custom objects they give access to (not in a namespace, with suffix __c)
	// -  For each user, get the number of unique custom objects they have access to across profile and permission sets
	// -  List the users and their number of custom objects

    @AuraEnabled
    public static Map<String, Integer> getCustomObjectCount(Id ProfileId){
        // Get all the users of the profile
        List<User> liUsers = getUsers(ProfileId);

        // Get all the permission sets of those users
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
		Set<Id> setAllPermSets = new Set<Id>();

        for(Id uId: mpPermSets.keySet()){
            setAllPermSets.addAll(mpPermSets.get(uId));
        }

        Map<Id, Set<String>> mpPermSetstoObjects = getObjectPermissions(setAllPermSets);

        // get the number of unique custom objects each user has access to across profile and permission sets
        Map<String, Integer> mpUserObjectCount = new Map<String, Integer>();

        for (User u: liUsers){
            Set<String> setObjectNames = new Set<String>();
            for(Id permSetId: mpPermSets.get(u.Id)){
                if(mpPermSetstoObjects.keySet().contains(permSetId)){
               		setObjectNames.addAll(mpPermSetstoObjects.get(permSetId));
                }
            }
            mpUserObjectCount.put(u.Username, setObjectNames.size());
        }

        return mpUserObjectCount;
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

    public static Map<Id, Set<String>> getObjectPermissions(Set<Id> profilesPermSets){
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

    @AuraEnabled
   	public static List<Object> getProfiles(){
        List<Object> li = [SELECT MAX(Profile.Id) Id, Profile.Name, COUNT(Id) usercount FROM User WHERE Profile.usertype = 'standard' GROUP BY Profile.Name];
        return li;
    }
}
