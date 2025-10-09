/****************************************************************************************************
* Class MeetingShareService
*
*   Create By   :  Andrei Pivavarchyk (mindsquare GmbH)
*   Create Date :  10.09.2025
*   Description :  MeetingShareService contains logic to share meetings based on different conditions
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                             Date           Description
*   * -----------------------------------------------------------------------------------------------
*   * Andrei Pivavarchyk (mindsquare GmbH)  10.09.2025     Init version.
****************************************************************************************************/

public without sharing class MeetingShareService {

    public static void removeAccessFromAccountMeetings(List<AccountShare> accountShareRecords) {
        if (accountShareRecords == null || accountShareRecords.isEmpty()) return;

        Map<Id, Set<Id>> meetingIdsByUserId = getMeetingIdsByUserIdBasedOnAccountShares(accountShareRecords);
        Map<Id, Set<Id>> filteredMeetingIdsByUserId = removeMeetingIdsWhereUserParticipant(meetingIdsByUserId);

        removeMeetingAccess(filteredMeetingIdsByUserId);
    }

    public static Map<Id, Set<Id>> removeMeetingIdsWhereUserParticipant(Map<Id, Set<Id>> meetingIdsByUserId) {
        Map<Id, Set<Id>> filteredMeetingIdsByUserId = new Map<Id, Set<Id>>();
        if (meetingIdsByUserId == null || meetingIdsByUserId.isEmpty()) {
            return filteredMeetingIdsByUserId;
        }

        Map<Id, Set<Id>> participantMeetingIdsByUserId = new Map<Id, Set<Id>>();
        participantMeetingIdsByUserId = getParticipantMeetingIdsByUserId (meetingIdsByUserId);

        for (Id userId : meetingIdsByUserId.keySet()) {
            Set<Id> meetingIds = meetingIdsByUserId.get(userId);
            Set<Id> meetingIdsWhereUserParticipant = participantMeetingIdsByUserId.get(userId);
            if (filteredMeetingIdsByUserId.get(userId) == null) {
                filteredMeetingIdsByUserId.put(userId, new Set<Id>());
            }
            for (Id meetingToCheckId : meetingIds) {
                if (meetingIdsWhereUserParticipant == null || !meetingIdsWhereUserParticipant.contains(meetingToCheckId)) {
                    filteredMeetingIdsByUserId.get(userId).add(meetingToCheckId);
                }
            }
        }
        return filteredMeetingIdsByUserId;
    }

    public static void grantAccessToAccountMeetings(List<AccountShare> accountShareRecords) {
        if (accountShareRecords == null || accountShareRecords.isEmpty()) return;

        Map<Id, Set<Id>> meetingIdsByUserId = getMeetingIdsByUserIdBasedOnAccountShares(accountShareRecords);
        System.debug('TESTDEBIG_meetingIdsByUserId:'+meetingIdsByUserId);
        grantMeetingAccess(meetingIdsByUserId);
    }

    public static Map<Id, Set<Id>> getMeetingIdsByUserIdBasedOnAccountShares(List<AccountShare> accountShareRecords) {
        Map<Id, Set<Id>> meetingIdsByUserId = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> userIdsByAccountId = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> meetingIdsByAccountIds = new Map<Id, Set<Id>>();

        if (accountShareRecords == null || accountShareRecords.isEmpty()) return meetingIdsByUserId;

        for (AccountShare share : accountShareRecords) {
            if (!userIdsByAccountId.containsKey(share.AccountId)) {
                userIdsByAccountId.put(share.AccountId, new Set<Id>());
            }
            userIdsByAccountId.get(share.AccountId).add(share.UserOrGroupId);
        }

        meetingIdsByAccountIds = getMeetingIdsByAccountIds(userIdsByAccountId.keySet());

        System.debug('TESTDEBIG_meetingIdsByAccountIds:'+meetingIdsByAccountIds);
        for (Id accountId : userIdsByAccountId.keySet()) {
            Set<Id> userIds = userIdsByAccountId.get(accountId);

            Set<Id> accountMeetings = meetingIdsByAccountIds.get(accountId);
            if (accountMeetings == null || accountMeetings.isEmpty()) {
                continue;
            }

            for (Id userId : userIds) {
                if(meetingIdsByUserId.get(userId)==null){
                    meetingIdsByUserId.put(userId, new Set<Id>());
                }
                meetingIdsByUserId.get(userId).addAll(accountMeetings);
            }
        }

        return meetingIdsByUserId;
    }

    public static Map<Id, Set<Id>> getMeetingIdsByAccountIds(Set<Id> accountIds) {
        Map<Id, Set<Id>> meetingIdsByAccountIds = new Map<Id, Set<Id>>();
        if (accountIds == null || accountIds.isEmpty()) return meetingIdsByAccountIds;

        List<Meeting__c> meetings = [
                SELECT Id, Company__c
                FROM Meeting__c
                WHERE Company__c IN :accountIds
        ];


        for (Meeting__c meeting : meetings) {
            if (!meetingIdsByAccountIds.containsKey(meeting.Company__c)) {
                meetingIdsByAccountIds.put(meeting.Company__c, new Set<Id>());
            }
            meetingIdsByAccountIds.get(meeting.Company__c).add(meeting.Id);
        }

        return meetingIdsByAccountIds;
    }

    public static void grantMeetingAccess(Map<Id, Set<Id>> meetingIdsByUserId) {
        if (meetingIdsByUserId == null || meetingIdsByUserId.isEmpty()) return;
        System.debug('TESTDEBIG_meetingIdsByUserId:'+meetingIdsByUserId);
        List<Meeting__Share> shareRecordsToInsert = new List<Meeting__Share>();

        Map<Id, List<Meeting__Share>> existingMeetingShareRecordsByUserId = getExistingMeetingShareRecordsByUserId(
                meetingIdsByUserId,
                new List<String>{
                        'Manual', 'Owner'
                }
        );
        System.debug('TESTDEBIG_existingMeetingShareRecordsByUserId:'+existingMeetingShareRecordsByUserId);
        for (Id userId : meetingIdsByUserId.keySet()) {
            Set<Id> userMeetingsIdsToShare = meetingIdsByUserId.get(userId);
            Set<Id> alreadySharedMeetingIds = new Set<Id>();
            if (userMeetingsIdsToShare == null) continue;
            System.debug('TESTDEBIG_userMeetingsIdsToShare_1:');
            System.debug('TESTDEBIG_userId:'+userId);
            List<Meeting__Share> existingShareRecords = existingMeetingShareRecordsByUserId.get(userId);
            System.debug('TESTDEBIG_existingShareRecords:'+existingShareRecords);

            if(existingShareRecords!=null){
                for (Meeting__Share shareRecord : existingShareRecords) {
                    alreadySharedMeetingIds.add(shareRecord.ParentId);
                }
            }


            for (Id meetingId : userMeetingsIdsToShare) {

                if (alreadySharedMeetingIds.contains(meetingId)) {
                    continue;
                }
                shareRecordsToInsert.add(createMeetingShare(userId, meetingId));
            }
        }
        System.debug('TESTDEBIG_insert shareRecordsToInsert;:'+existingMeetingShareRecordsByUserId);
        insert shareRecordsToInsert;
    }

    public static void removeMeetingAccess(Map<Id, Set<Id>> meetingIdsByUserId) {
        if (meetingIdsByUserId == null || meetingIdsByUserId.isEmpty()) return;

        Map<Id, List<Meeting__Share>> existingMeetingShareRecordsByUserId = getExistingMeetingShareRecordsByUserId(
                meetingIdsByUserId,
                new List<String>{
                        'Manual'
                }
        );

        List<Meeting__Share> allShareRecordIdsToDelete = new List<Meeting__Share>();

        for (Id userId : existingMeetingShareRecordsByUserId.keySet()) {

            allShareRecordIdsToDelete.addAll(existingMeetingShareRecordsByUserId.get(userId));
        }
        delete allShareRecordIdsToDelete;
    }


    public static Map<Id, Set<Id>> getParticipantMeetingIdsByUserId(Map<Id, Set<Id>> meetingIdsByUserId) {
        Map<Id, Set<Id>> participantMeetingIdsByUserId = new Map<Id, Set<Id>>();
        if (meetingIdsByUserId == null || meetingIdsByUserId.isEmpty()) {
            return participantMeetingIdsByUserId;
        }
        Set<Id> allMeetings = new Set<Id>();

        for (Id userId : meetingIdsByUserId.keySet()) {
            allMeetings.addAll(meetingIdsByUserId.get(userId));
        }

        List<Attendee__c> meetingParticipants = [
                SELECT Id, Meeting__c, User__c
                FROM Attendee__c
                WHERE User__c IN :meetingIdsByUserId.keySet()
                AND Meeting__c IN :allMeetings
        ];

        for (Attendee__c meetingParticipant : meetingParticipants) {
            Id meetingId = meetingParticipant.Meeting__c;
            Id userId = meetingParticipant.User__c;
            if (!participantMeetingIdsByUserId.containsKey(userId)) {
                participantMeetingIdsByUserId.put(userId, new Set<Id>());
            }
            participantMeetingIdsByUserId.get(userId).add(meetingId);
        }
        return participantMeetingIdsByUserId;

    }

    public static Map<Id, List<Meeting__Share>> getExistingMeetingShareRecordsByUserId(
            Map<Id, Set<Id>> meetingIdsByUserId,
            List<String> sharingRowCauses) {

        Map<Id, List<Meeting__Share>> sharedMeetingsByUserId = new Map<Id, List<Meeting__Share>>();
        Set<Id> allMeetingIds = new Set<Id>();

        if (meetingIdsByUserId == null || meetingIdsByUserId.isEmpty() || sharingRowCauses == null || sharingRowCauses.isEmpty()) {
            return sharedMeetingsByUserId;
        }

        for (Id userId : meetingIdsByUserId.keySet()) {
            allMeetingIds.addAll(meetingIdsByUserId.get(userId));
        }

        List<Meeting__Share> existingShareRecords = [
                SELECT Id, ParentId, UserOrGroupId, RowCause
                FROM Meeting__Share
                WHERE RowCause IN :sharingRowCauses
                AND UserOrGroupId IN :meetingIdsByUserId.keySet()
                AND ParentId IN :allMeetingIds
        ];

        for (Meeting__Share meetingShare : existingShareRecords) {
            Id userId = meetingShare.UserOrGroupId;
            Id meetingId = meetingShare.ParentId;
            Set<Id> userMeetings = meetingIdsByUserId.get(userId);

            if (!sharedMeetingsByUserId.containsKey(userId)) {
                sharedMeetingsByUserId.put(userId, new List<Meeting__Share>());
            }
            if (userMeetings.contains(meetingId)) {
                sharedMeetingsByUserId.get(userId).add(meetingShare);
            }
        }

        return sharedMeetingsByUserId;
    }

    public static Meeting__Share createMeetingShare(Id userId, Id meetingId) {
        Meeting__Share share = new Meeting__Share();
        share.ParentId = meetingId;
        share.UserOrGroupId = userId;
        share.AccessLevel = 'Read';
        share.RowCause = 'Manual';
        return share;
    }
}