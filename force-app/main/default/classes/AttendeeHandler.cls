/****************************************************************************************************
* Class AttendeeHandler
*
*   Create By   :  Andrei Pivavarchyk (mindsquare GmbH)
*   Create Date :  10.09.2025
*   Description  :  Trigger Handler for the Attendee__c SObject. This class implements the ITrigger
*           interface to help ensure the trigger code is bulkified and all in one place.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                             Date           Description
*   * -----------------------------------------------------------------------------------------------
*   * Andrei Pivavarchyk (mindsquare GmbH)  10.09.2025     Init version.
****************************************************************************************************/

public with sharing class AttendeeHandler extends MeetingPlusTriggerExecutor {

    public override void bulkAfter() {
        if (Trigger.isInsert) {
            grantMeetingShare(Trigger.new);
        } else if (Trigger.isUpdate) {
            updateAccessAfterOwnerIsChanged(Trigger.new, (Map<Id, Attendee__c>) Trigger.oldMap);
            updateAccessIfMeetingIsChanged(Trigger.new, (Map<Id, Attendee__c>) Trigger.oldMap);
        } else if (Trigger.isDelete) {
            removeMeetingShare(Trigger.old);
        }
    }

    public static void grantMeetingShare(List<Attendee__c> participantList) {
        if (participantList == null) return;

        Map<Id, Set<Id>> meetingIdsByUserId = new Map<Id, Set<Id>>();

        for (Attendee__c participant : participantList) {
            Id userId = participant.User__c;

            if (userId != null) {
                if (!meetingIdsByUserId.containsKey(userId)) {
                    meetingIdsByUserId.put(userId, new Set<Id>());
                }
                meetingIdsByUserId.get(userId).add(participant.Meeting__c);
            }
        }
        MeetingShareService.grantMeetingAccess(meetingIdsByUserId);
    }

    public static void updateAccessIfMeetingIsChanged(List<Attendee__c> newParticipants, Map<Id, Attendee__c> oldParticipantsMap) {
        if (newParticipants == null || newParticipants.isEmpty() || oldParticipantsMap == null || oldParticipantsMap.isEmpty()) {
            return;
        }

        List<Attendee__c> participantsToRemoveMeetingAccess = new List<Attendee__c>();
        List<Attendee__c> participantsToAddMeetingAccess = new List<Attendee__c>();

        for (Attendee__c newParticipant : newParticipants) {
            Attendee__c oldParticipant = oldParticipantsMap.get(newParticipant.Id);

            if (newParticipant.Meeting__c != oldParticipantsMap.get(newParticipant.Id).Meeting__c) {

                if (oldParticipant.Meeting__c != null) {
                    participantsToRemoveMeetingAccess.add(oldParticipant);
                }

                if (newParticipant.Meeting__c != null) {
                    participantsToAddMeetingAccess.add(newParticipant);
                }

            }

        }
        removeMeetingShare(participantsToRemoveMeetingAccess);
        grantMeetingShare(participantsToAddMeetingAccess);

    }

    public static void updateAccessAfterOwnerIsChanged(List<Attendee__c> newParticipants, Map<Id, Attendee__c> oldParticipantsMap
    ) {

        if (newParticipants == null || newParticipants.isEmpty() || oldParticipantsMap == null || oldParticipantsMap.isEmpty()) {
            return;
        }

        List<Attendee__c> changedOldUserParticipants = new List<Attendee__c>();
        List<Attendee__c> changedNewUserParticipants = new List<Attendee__c>();

        for (Attendee__c participant : newParticipants) {
            Attendee__c oldParticipant = oldParticipantsMap.get(participant.Id);

            if (participant.User__c == oldParticipant.User__c) {
                continue;
            }

            if (oldParticipant.User__c != null) {
                changedOldUserParticipants.add(oldParticipantsMap.get(participant.Id));
            }

            if (participant.User__c != null) {
                changedNewUserParticipants.add(participant);
            }
        }

        if (changedNewUserParticipants.isEmpty()) {
            return;
        }

        removeMeetingShare(changedOldUserParticipants);
        grantMeetingShare(changedNewUserParticipants);
    }

    public static void removeMeetingShare(List<Attendee__c> participants) {
        Set<Id> allMeetingIds = new Set<Id>();
        Map<Id, Set<Id>> userIdToMeetingIdsToProcess = new Map<Id, Set<Id>>();
        Set<Id> participantUserIds = new Set<Id>();

        for (Attendee__c participant : participants) {
            allMeetingIds.add(participant.Meeting__c);
            participantUserIds.add(participant.User__c);
            if (!userIdToMeetingIdsToProcess.containsKey(participant.User__c)) {
                userIdToMeetingIdsToProcess.put(participant.User__c, new Set<Id>());
            }
            userIdToMeetingIdsToProcess.get(participant.User__c).add(participant.Meeting__c);
        }

        List<Meeting__c> meetings = [
                SELECT Id, Company__c
                FROM Meeting__c
                WHERE Id IN :allMeetingIds
        ];

        Map<Id, Id> meetingIdToAccountId = new Map<Id, Id>();
        for (Meeting__c meeting : meetings) {
            meetingIdToAccountId.put(meeting.Id, meeting.Company__c);
        }

        // TODO Duplicated in MeetingTriggerHandler.shareMeetingsWithOldOwner() start 11
        List<String> sharingRowCauses = new List<String>{
                'Manual'
        };

        List<AccountShare> accountShares = [
                SELECT Id, AccountId, UserOrGroupId, RowCause
                FROM AccountShare
                WHERE AccountId IN :meetingIdToAccountId.values()
                AND UserOrGroupId IN :participantUserIds
                AND RowCause IN :sharingRowCauses
        ];

        Map<Id, Set<Id>> sharedAccountIdToUserIds = new Map<Id, Set<Id>>();
        for (AccountShare accountShare : accountShares) {
            Id sharedAccountId = accountShare.AccountId;

            if (sharedAccountIdToUserIds.get(sharedAccountId) == null) {
                sharedAccountIdToUserIds.put(sharedAccountId, new Set<Id>());
            }
            sharedAccountIdToUserIds.get(accountShare.AccountId).add(accountShare.UserOrGroupId);
        }
        // TODO Duplicated in MeetingTriggerHandler.shareMeetingsWithOldOwner() end 11

        Map<Id, Set<Id>> userIdToMeetingIdsToRemoveAccess = new Map<Id, Set<Id>>();

        for (Id userIdToProcess : userIdToMeetingIdsToProcess.keySet()) {
            if (userIdToMeetingIdsToRemoveAccess.get(userIdToProcess) == null) {
                userIdToMeetingIdsToRemoveAccess.put(userIdToProcess, new Set<Id>());
            }

            Set<Id> meetingsToProcessIds = userIdToMeetingIdsToProcess.get(userIdToProcess);

            for (Id meetingIdToProcess : meetingsToProcessIds) {
                Id accountId = meetingIdToAccountId.get(meetingIdToProcess);
                //TODO Есть вопрос по немингу, accountSharedWithUserIds содержит UserIds
                Set<Id> accountSharedWithUserIds = sharedAccountIdToUserIds.get(accountId);
                if (accountSharedWithUserIds != null && !accountSharedWithUserIds.contains(userIdToProcess)) {
                    userIdToMeetingIdsToRemoveAccess.get(userIdToProcess).add(meetingIdToProcess);
                }
            }
        }

        // MeetingShareService.removeMeetingIdsWhereUserParticipant(userIdToMeetingIdsToRemoveAccess);
        //Похоже, что должно быть так
        Map<Id, Set<Id>> filteredMeetingIdsByUserId = removeMeetingIdsWhereUserParticipant(meetingIdsByUserId);
        removeMeetingAccess(filteredMeetingIdsByUserId);
    }
}