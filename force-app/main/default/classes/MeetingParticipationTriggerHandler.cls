public with sharing class MeetingParticipationTriggerHandler {
    public static void onBeforeInsert(List<Meeting_Participation__c> newParticipations) {
        // TODO: Implement logic for before insert trigger
    }

    public static void onAfterInsert(List<Meeting_Participation__c> newParticipations) {
        grantMeetingShare(newParticipations);
    }

    public static void onBeforeUpdate(List<Meeting_Participation__c> newParticipations, Map<Id, Meeting_Participation__c> oldParticipationsMap) {
        // TODO: Implement logic for before insert trigger
    }

    public static void onAfterUpdate(List<Meeting_Participation__c> newParticipations, Map<Id, Meeting_Participation__c> oldParticipationsMap) {
        shareByLinkedUser(newParticipations, oldParticipationsMap);
    }

    public static void onBeforeDelete(Map<Id, Meeting_Participation__c> oldParticipationsMap) {
        
    }

    public static void onAfterDelete(Map<Id, Meeting_Participation__c> oldParticipationsMap) {
        removeMeetingShare(oldParticipationsMap.values());
    }

    public static void shareByLinkedUser(
        List<Meeting_Participation__c> newParticipations, 
        Map<Id, Meeting_Participation__c> oldParticipationsMap
    ) {
        List<Meeting_Participation__c> changedOldUserParticipations = new List<Meeting_Participation__c>();
        List<Meeting_Participation__c> changedUserParticipations = new List<Meeting_Participation__c>();
        for (Meeting_Participation__c participant : newParticipations) {
            if (participant.User__c == oldParticipationsMap.get(participant.Id).User__c) {
                continue;
            }

            changedOldUserParticipations.add(oldParticipationsMap.get(participant.Id));
            changedUserParticipations.add(participant);
        }

        if (changedUserParticipations.isEmpty()) {
            return;
        }

        //---------------------------------------------------------------------------------------------

        List<Meeting__Share> removedMeetingShares = removeMeetingShare(changedOldUserParticipations);
        List<Meeting__Share> grandMeetingShares = grantMeetingShare(changedUserParticipations);

        System.debug('----- 55 removedMeetingShares.size(): ' + removedMeetingShares.size());
        for (Integer i = 0; i < removedMeetingShares.size(); i++) {
            System.debug('-----removedMeetingShares[' + i + ']: ' + removedMeetingShares[i]);
        }
        System.debug('-----56 grandMeetingShares.size(): ' + grandMeetingShares.size());
        for (Integer i = 0; i < grandMeetingShares.size(); i++) {
            System.debug('-----grandMeetingShares[' + i + ']: ' + grandMeetingShares[i]);
        }
    }

    // old
    public static List<Meeting__Share> removeMeetingShare(List<Meeting_Participation__c> participations) {
        Set<Id> meetingIds = new Set<Id>();
        Map<Id, Set<Id>> meetingIdsByOldUserIds = new Map<Id, Set<Id>>();
        for (Meeting_Participation__c participant : participations) {
            Id oldUserId = participant.User__c;
            Id oldMeetingId = participant.Meeting__c;
            if (oldUserId != null && oldMeetingId != null) {
                meetingIds.add(oldMeetingId);
                Util.addValueToMapOfSets(meetingIdsByOldUserIds, oldUserId, oldMeetingId);
            }
        }

        List<Meeting__c> meetings = [
            SELECT Id, Account__c
            FROM Meeting__c
            WHERE Id IN :meetingIds
        ];
        Map<Id, Meeting__c> meetingsById = new Map<Id, Meeting__c>(meetings);

        List<Id> accountId = new List<Id>();
        for (Meeting__c meeting : meetings) {
            accountId.add(meeting.Account__c);
        }
            
        List<String> sharingRowCauses = new List<String>{'Manual', 'Owner'};
        List<AccountShare> accountShares = [
            SELECT Id, AccountId, UserOrGroupId, RowCause
            FROM AccountShare
            WHERE AccountId IN :accountId
                AND UserOrGroupId IN :meetingIdsByOldUserIds.keySet()
                AND RowCause IN :sharingRowCauses
        ];

        Map<Id, Set<Id>> sharedAccountsByUser = new Map<Id, Set<Id>>();
        for (AccountShare accountShare : accountShares) {
            Util.addValueToMapOfSets(sharedAccountsByUser, accountShare.UserOrGroupId, accountShare.AccountId);
        }

        Map<Id, Set<Id>> meetingIdsByUserIdForRemoveShares = new Map<Id, Set<Id>>();
        for (Id oldUserId : meetingIdsByOldUserIds.keySet()) {
            Set<Id> oldMeetingIds = meetingIdsByOldUserIds.get(oldUserId);
            for (Id oldMeetingId : oldMeetingIds) {
                Set<Id> sharedAccounts = sharedAccountsByUser.get(oldUserId);
                Id linkedAccountId = meetingsById.get(oldMeetingId).Account__c;
                if (sharedAccounts?.contains(linkedAccountId) == true) {
                    continue;
                }

                Util.addValueToMapOfSets(meetingIdsByUserIdForRemoveShares, oldUserId, oldMeetingId);
            }
        }

        List<Meeting__Share> removedMeetingShares = MeetingShareService.removeMeetingAccess(meetingIdsByUserIdForRemoveShares);

        return removedMeetingShares;
    }

    public static List<Meeting__Share> grantMeetingShare(List<Meeting_Participation__c> participations) {
        Map<Id, Set<Id>> meetingIdsByNewUserIds = new Map<Id, Set<Id>>();
        for (Meeting_Participation__c participant : participations) {
            Id newUserId = participant.User__c;
            if (newUserId != null) {
                Util.addValueToMapOfSets(meetingIdsByNewUserIds, newUserId, participant.Meeting__c);
            }
        }

        List<Meeting__Share> grandMeetingShares = MeetingShareService.grantMeetingAccess(meetingIdsByNewUserIds);

        return grandMeetingShares;
    }
}