// Works only for custom objects
public with sharing class ShareService {
    private static String CUSTOM_SHARING_ROW_CAUSE = 'CustomSharing__c';// Manual
    private static Strind EXIST_SHARE_QUERY = 'SELECT ParentId, UserOrGroupId, RowCause, AccessLevel FROM {0} WHERE ParentId IN :recordIds AND UserOrGroupId IN :userIds AND RowCause = IN :rowCauses';

    public static List<SObject> grandAccess(Map<Id, Set<Id>> sharedRecordsByUsers) {
        String shareName = getShareName(new List<Id>(sharedRecordsByUsers.keySet()).get(0));
        
        Map<Id, List<SObject>> existShares = getSharedRecordsByUsers(sharedRecordsByUsers);
        
        return null;
    }

    public static List<SObject> removeAccess(Map<Id, Set<Id>> sharedRecordsByUsers) {
        return null;
    }
    public static List<SObject> createShare() {
        return null;
    }

    public static String getShareName(Id recordId) {
        return recordId.getSobjectType().toString().replace('__c', '__Share');
    }

    public static List<SObject> getSharedRecordsByUsers(Map<Id, Set<Id>> sharedRecordsByUsers) {
        List<SObject> shares = new List<SObject>();
        for (Id userId : sharedRecordsByUsers.keySet()) {
            Set<Id> recordIds = sharedRecordsByUsers.get(userId);
            if (recordIds == null || recordIds.isEmpty()) {
                continue;
            }   
            shares.addAll(getSharedRecordsByUser(userId, recordIds));
        }
        return shares;
    }
}