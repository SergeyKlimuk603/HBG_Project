public without sharing class MeetingShareService {

    private static List<String> sharingRowCauses = new List<String>{
        'CustomSharing__c'
        // , 'Manual'
        , 'Owner'
    };

    public static List<Meeting__Share> removeMeetingAccess(Map<Id, Set<Id>> meetingIdsByUserId) {

        List<Meeting__Share> existingShares = getExistingShares(
            meetingIdsByUserId, 
            new List<String>{'CustomSharing__c'}
        );

        List<Meeting__Share> sharesToDelete = new List<Meeting__Share>();

        for (Meeting__Share share : existingShares) {
            Set<Id> meetingIds = meetingIdsByUserId.get(share.UserOrGroupId);
            if (meetingIds == null || meetingIds.isEmpty()) {
                continue;
            }

            if (meetingIds.contains(share.ParentId)) {
                sharesToDelete.add(share);
            }
        }

        //TODO
        if (!sharesToDelete.isEmpty()) {
            Database.delete(sharesToDelete, false);
        }

        return sharesToDelete;
    }

    


    
    // Checked--------------------------------------------------------------------
    public static List<Meeting__Share> grantMeetingAccess(Map<Id, Set<Id>> meetingIdsByUserId) {

        Map<Id, Set<Id>> sharedMeetingIdsByUserId = getSharedMeetingIdsByUserId(
            meetingIdsByUserId,
            new List<String>{'CustomSharing__c', 'Owner'}
        );

        List<Meeting__Share> sharesToInsert = new List<Meeting__Share>();
        for(Id userId : meetingIdsByUserId.keySet()) {
            for (Id meetingId : meetingIdsByUserId.get(userId)) {
                if (sharedMeetingIdsByUserId.get(userId)?.contains(meetingId) == true) {
                    continue; // has access
                }

                sharesToInsert.add(createMeetingShare(userId, meetingId));
            }
        }
        System.debug('-----sharesToInsert: ' + sharesToInsert);

        //TODO
        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }

        return sharesToInsert;
    }

    public static Map<Id, Set<Id>> getSharedMeetingIdsByUserId(
        Map<Id, Set<Id>> meetingIdsByUserId,
        List<String> sharingRowCauses
    ) {
        List<Meeting__Share> existingShares = getExistingShares(meetingIdsByUserId, sharingRowCauses);

        Map<Id, Set<Id>> sharedMeetingIdsByUserId = new Map<Id, Set<Id>>();
        for (Meeting__Share meetingShare : existingShares) {
            Id userId = meetingShare.UserOrGroupId;
            Id meetingId = meetingShare.ParentId;
            if (meetingIdsByUserId.get(userId)?.contains(meetingId) != true){
                continue;
            }

            if (!sharedMeetingIdsByUserId.containsKey(userId)) {
                sharedMeetingIdsByUserId.put(userId, new Set<Id>());
            }
            sharedMeetingIdsByUserId.get(userId).add(meetingId);
        }

        return sharedMeetingIdsByUserId;
    }

    // public static Map<Id, Set<Id>> getExistMeetingShareIdsByUserId(
    //     Map<Id, Set<Id>> meetingIdsByUserId,
    //     List<String> sharingRowCauses
    // ) {
    //     List<Meeting__Share> existingShares = getExistingShares(meetingIdsByUserId, sharingRowCauses);

    //     Map<Id, Set<Id>> meetingShareIdsByUserId = new Map<Id, Set<Id>>();
    //     for (Meeting__Share meetingShare : existingShares) {
    //         Id userId = meetingShare.UserOrGroupId;
    //         if (meetingIdsByUserId.get(userId)?.contains(meetingShare.ParentId) != true){
    //             continue;
    //         }

    //         if (!meetingShareIdsByUserId.containsKey(userId)) {
    //             meetingShareIdsByUserId.put(userId, new Set<Id>());
    //         }
    //         meetingShareIdsByUserId.get(userId).add(meetingShare.Id);
    //     }

    //     return meetingShareIdsByUserId;
    // }

    public static List<Meeting__Share> getExistingShares(
        Map<Id, Set<Id>> meetingIdsByUserId,
        List<String> sharingRowCauses
    ) {
        Set<Id> userIds = meetingIdsByUserId.keySet();
        Set<Id> allMeetingIds = new Set<Id>();
        for(Id userId : userIds) {
            allMeetingIds.addAll(meetingIdsByUserId.get(userId));
        }

        //TODO Delete
        // System.debug('-----userIds: ' + userIds);
        // System.debug('-----allMeetingIds: ' + allMeetingIds);
        // System.debug('-----sharingRowCauses: ' + sharingRowCauses);

        List<Meeting__Share> existingShares = [
            SELECT Id, ParentId, UserOrGroupId, RowCause 
            FROM Meeting__Share 
            WHERE RowCause IN :sharingRowCauses
                AND UserOrGroupId IN :userIds 
                AND ParentId IN :allMeetingIds 
        ];

        return existingShares;
    }
    
    public static Meeting__Share createMeetingShare(Id userId, Id meetingId) {
        Meeting__Share share = new Meeting__Share();
        share.ParentId = meetingId;
        share.UserOrGroupId = userId;
        share.AccessLevel = 'Read';
        share.RowCause = 'CustomSharing__c'; // Important for delete
        // share.RowCause = 'Manual'; // Important for delete
        
        return share;
    }
}