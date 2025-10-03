public without sharing class RegistrationHandlerNew {

    //---------------------------------------------------------------------------------------------
    // AccountShare added
    public static List<Meeting__Share> grantMeetingAccess(List<AccountShare> accountShares) {
        Map<Id, Set<Id>> userIdsByAccountId = new Map<Id, Set<Id>>();
        for (AccountShare share : accountShares) {
            if (!userIdsByAccountId.containsKey(share.AccountId)) {
                userIdsByAccountId.put(share.AccountId, new Set<Id>());
            }
            userIdsByAccountId.get(share.AccountId).add(share.UserOrGroupId);
        }

        List<Meeting__c> meetings = [
            SELECT Id, OwnerId, Account__c, Name
            FROM Meeting__c 
            WHERE Account__c IN :userIdsByAccountId.keySet()
        ];

        Map<Id, List<Meeting__c>> meetingsByAccountId = new Map<Id, List<Meeting__c>>();
        for (Meeting__c meeting : meetings) {
            if (!meetingsByAccountId.containsKey(meeting.Account__c)) {
                meetingsByAccountId.put(meeting.Account__c, new List<Meeting__c>());
            }
            meetingsByAccountId.get(meeting.Account__c).add(meeting);
        }

        Map<Id, List<Meeting__c>> meetingsByUserId = new Map<Id, List<Meeting__c>>();
        for (Id accountId : userIdsByAccountId.keySet()) {
            Set<Id> userIds = userIdsByAccountId.get(accountId);
            if (userIds == null || userIds.isEmpty()) {
                continue;
            }

            List<Meeting__c> accountMeetings = meetingsByAccountId.get(accountId);
            if (accountMeetings == null || accountMeetings.isEmpty()) {
                continue;
            }

            for (Id userId : userIds) {
                meetingsByUserId.put(userId, accountMeetings);
            }
        }

        System.debug('-----2 meetingsByUserId: ' + meetingsByUserId);

        List<Meeting__Share> meetingShares = grantMeetingAccess(meetingsByUserId);

        System.debug('-----3 meetingShares: ' + meetingShares);

        return null;
    }


    //---------------------------------------------------------------------------------------------
    // Insert/Delete meetings shares

    private static List<String> sharingRowCauses = new List<String>{'Manual'};
    

    public static List<Meeting__Share> removeMeetingAccess(Map<Id, List<Id>> meetingIdsByUserId) {
        List<Meeting__Share> existingShares = getExistingShares(meetingIdsByUserId);

        List<Meeting__Share> sharesToDelete = new List<Meeting__Share>();


        for (Meeting__Share share : existingShares) {
            List<Id> meetingIds = meetingIdsByUserId.get(share.UserOrGroupId);
            if (meetingIds == null || meetingIds.isEmpty()) {
                continue;
            }

            if (meetingIds.contains(share.ParentId)) {
                sharesToDelete.add(share);
            }
        }
        System.debug('-----sharesToDelete: ' + sharesToDelete);

        //TODO
        if (!sharesToDelete.isEmpty()) {
            Database.delete(sharesToDelete, false);
        }

        return sharesToDelete;
    }

    public static List<Meeting__Share> grantMeetingAccess(Map<Id, List<Meeting__c>> meetingsByUserId) {

        List<Meeting__Share> existingShares = getExistingShares(meetingsByUserId);
                
        Map<Id, Set<Id>> existingSharedMeetingIdsByUser = new Map<Id, Set<Id>>();
        for (Meeting__Share share : existingShares) {
            if (!existingSharedMeetingIdsByUser.containsKey(share.UserOrGroupId)) {
                existingSharedMeetingIdsByUser.put(share.UserOrGroupId, new Set<Id>());
            }
            existingSharedMeetingIdsByUser.get(share.UserOrGroupId).add(share.ParentId);
        }

        List<Meeting__Share> sharesToInsert = new List<Meeting__Share>();
        for(Id userId : meetingsByUserId.keySet()) {
            for (Meeting__c meeting : meetingsByUserId.get(userId)) {
                if (meeting.OwnerId == userId) {
                    continue; // Owner has access by default
                }

                if (existingSharedMeetingIdsByUser.get(userId) != null 
                    && existingSharedMeetingIdsByUser.get(userId).contains(meeting.Id)
                ) {
                    continue; // Already has share
                }

                sharesToInsert.add(createMeetingShare(userId, meeting.Id));
            }
        }


        System.debug('-----sharesToInsert: ' + sharesToInsert);

        //TODO
        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }

        return sharesToInsert;
    }

    public static List<Meeting__Share> getExistingShares(Map<Id, List<Meeting__c>> meetingsByUserId) {

        Map<Id, List<Id>> meetingIdsByUserId = new Map<Id, List<Id>>();
        for (Id userId : meetingsByUserId.keySet()) {
            List<Id> meetingIds = new List<Id>();
            for (Meeting__c meeting : meetingsByUserId.get(userId)) {
                meetingIds.add(meeting.Id);
            }
            meetingIdsByUserId.put(userId, meetingIds);
        }


        
        return getExistingShares(meetingIdsByUserId);
    }

    public static List<Meeting__Share> getExistingShares(Map<Id, List<Id>> meetingIdsByUserId) {
        Set<Id> userIds = meetingIdsByUserId.keySet();
        Set<Id> allMeetingIds = new Set<Id>();
        for( Id userId : userIds) {
            for (Id meetingId : meetingIdsByUserId.get(userId)) {
                allMeetingIds.add(meetingId);
            }
        }

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
        share.RowCause = 'Manual'; // Important for delete
        
        return share;
    }

}