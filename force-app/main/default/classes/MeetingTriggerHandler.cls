public without sharing class MeetingTriggerHandler {


    public static void onAfterInsert(List<Meeting__c> newMeetings) {
        shareByLinkedAccount(newMeetings, null);
    }

    public static void onAfterUpdate(List<Meeting__c> newMeetings, Map<Id, Meeting__c> oldMeetings) {
        shareByLinkedAccount(newMeetings, oldMeetings);
        shareMeetingsWithOldOwner(newMeetings, oldMeetings);
    }

    public static void shareByLinkedAccount(List<Meeting__c> newMeetings, Map<Id, Meeting__c> oldMeetingsMap) {
        if (newMeetings == null || newMeetings.isEmpty()) {
            return;
        }
        List<Meeting__c> changedAccountMeetings = new List<Meeting__c>();
        if (oldMeetingsMap == null || oldMeetingsMap.isEmpty()) {
            for (Meeting__c meeting : newMeetings) {
                if (String.isBlank(meeting.Account__c)) continue;

                changedAccountMeetings.add(meeting);
            }
        } else {
            for (Meeting__c meeting : newMeetings) {
                if (oldMeetingsMap.get(meeting.Id) == meeting.Account__c) continue;

                changedAccountMeetings.add(meeting);
            }
        }

        if (changedAccountMeetings.isEmpty()) {
            return;
        }

        Map<Id, Set<Id>> meetingIdsByOldAccountIds = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> meetingIdsByNewAccountIds = new Map<Id, Set<Id>>();
        for (Meeting__c meeting : changedAccountMeetings) {
            Id oldAccountId = oldMeetingsMap.get(meeting.Id).Account__c;
            if (String.isNotBlank(oldAccountId)) {
                if (!meetingIdsByOldAccountIds.containsKey(oldAccountId)) {
                    meetingIdsByOldAccountIds.put(oldAccountId, new Set<Id>());
                }
                meetingIdsByOldAccountIds.get(oldAccountId).add(meeting.Id);
            }

            Id newAccountId = meeting.Account__c;
            if (String.isNotBlank(newAccountId)) {
                if (!meetingIdsByNewAccountIds.containsKey(newAccountId)) {
                    meetingIdsByNewAccountIds.put(newAccountId, new Set<Id>());
                }
                meetingIdsByNewAccountIds.get(newAccountId).add(meeting.Id);
            }
        }

        List<String> sharingRowCauses = new List<String>{'Manual'};
        List<AccountShare> accountShares = [
            SELECT Id, AccountId, UserOrGroupId, RowCause
            FROM AccountShare
            WHERE (AccountId IN :meetingIdsByOldAccountIds.keySet()
                    OR AccountId IN :meetingIdsByNewAccountIds.keySet())
                AND RowCause IN :sharingRowCauses
        ];

        Map<Id, Set<Id>> meetingIdsByUserIdForRemoveShare = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> meetingIdsByUserIdForGrandShare = new Map<Id, Set<Id>>();
        for(AccountShare accountShare : accountShares) {
            Id accountId = accountShare.AccountId;
            Id userId = accountShare.UserOrGroupId;
            if (meetingIdsByOldAccountIds.containsKey(accountId)) {
                if (!meetingIdsByUserIdForRemoveShare.containsKey(userId)) {
                    meetingIdsByUserIdForRemoveShare.put(userId, new Set<Id>());
                }
                meetingIdsByUserIdForRemoveShare.get(userId).addAll(meetingIdsByOldAccountIds.get(accountId));
            }
            if (meetingIdsByNewAccountIds.containsKey(accountId)) {
                if (!meetingIdsByUserIdForGrandShare.containsKey(userId)) {
                    meetingIdsByUserIdForGrandShare.put(userId, new Set<Id>());
                }
                meetingIdsByUserIdForGrandShare.get(userId).addAll(meetingIdsByNewAccountIds.get(accountId));
            }
        }

        Map<Id, Set<Id>> filteredMeetingIdsByUserIdsForRemoveShare = removeMeetingIdsWhereUserParticipant(meetingIdsByUserIdForRemoveShare);

        MeetingShareService.removeMeetingAccess(filteredMeetingIdsByUserIdsForRemoveShare);
        MeetingShareService.grantMeetingAccess(meetingIdsByUserIdForGrandShare);
    }

    public static void shareMeetingsWithOldOwner(List<Meeting__c> newMeetings, Map<Id, Meeting__c> oldMeetingsMap) {
        if (newMeetings == null || newMeetings.isEmpty() || oldMeetingsMap == null || oldMeetingsMap.isEmpty()) {
            return;
        }

        List<Meeting__c> ownerChangedOldMeetings = new List<Meeting__c>();
        for (Meeting__c meeting : newMeetings) {
            Meeting__c oldMeeting = oldMeetingsMap.get(meeting.Id);
            if (meeting.OwnerId != oldMeeting.OwnerId && String.isNotBlank(oldMeeting.Account__c)) {
                ownerChangedOldMeetings.add(oldMeeting);
            }
        }

        if (ownerChangedOldMeetings.isEmpty()) {
            return;
        }

        List<Id> linkedAccountIds = new List<Id>();
        List<Id> oldOwnerIds = new List<Id>();
        for (Meeting__c meeting : ownerChangedOldMeetings) {
            linkedAccountIds.add(meeting.Account__c);
            oldOwnerIds.add(meeting.OwnerId);
        }

        // TODO Duplicated in AttendeeHandler.removeMeetingShare() start 1
        List<String> sharingRowCauses = new List<String>{'Manual'};
        List<AccountShare> accountShares = [
            SELECT Id, AccountId, UserOrGroupId, RowCause
            FROM AccountShare
            WHERE AccountId IN :linkedAccountIds
                AND UserOrGroupId IN :oldOwnerIds
                AND RowCause IN :sharingRowCauses
        ];

        Map<Id, Set<Id>> sharedAccountIdsByUserIds = new Map<Id, Set<Id>>();
        for (AccountShare accountShare : accountShares) {
            if (!sharedAccountIdsByUserIds.containsKey(accountShare.UserOrGroupId)) {
                sharedAccountIdsByUserIds.put(accountShare.UserOrGroupId, new Set<Id>());
            }
            sharedAccountIdsByUserIds.get(accountShare.UserOrGroupId).add(accountShare.AccountId);
        }
        // TODO Duplicated in AttendeeHandler.removeMeetingShare() end 1

        Map<Id, Set<Id>> meetingIdsByUserIdForSharing = new Map<Id, Set<Id>>();
        for (Meeting__c oldMeeting : ownerChangedOldMeetings) {
            Id oldOwner = oldMeeting.OwnerId;
            Set<Id> sharedAccounts = sharedAccountIdsByUserIds.get(oldOwner);
            if (sharedAccounts == null || sharedAccounts.isEmpty() || !sharedAccounts.contains(oldMeeting.Account__c)) {
                continue;
            }

            if (!meetingIdsByUserIdForSharing.containsKey(oldOwner)) {
                meetingIdsByUserIdForSharing.put(oldOwner, new Set<Id>());
            }
            meetingIdsByUserIdForSharing.get(oldOwner).add(oldMeeting.Id);
        }

        MeetingShareService.grantMeetingAccess(meetingIdsByUserIdForSharing);
    }























    
    //ForExample--------------------------------------------------------------------

    public static void shareByLinkedAccount1(List<Meeting__c> meetings) {
        if (meetings == null || meetings.isEmpty()) {
            return;
        }

        List<Meeting__c> linkedToAccountMeetings = new List<Meeting__c>();

        for (Meeting__c meeting : meetings) {
            if (String.isBlank(meeting.Account__c)) continue;

            linkedToAccountMeetings.add(meeting);
        }

        if (linkedToAccountMeetings.isEmpty()) {
            return;
        }

        Map<Id, Set<Id>> meetingIdsByAccountIds = new Map<Id, Set<Id>>();

        if (!meetingIdsByAccountIds.containsKey(newAccountId)) {
            meetingIdsByAccountIds.put(newAccountId, new Set<Id>());
        }
        meetingIdsByAccountIds.get(newAccountId).add(meeting.Id);

        List<String> sharingRowCauses = new List<String>{'Manual'};
        List<AccountShare> accountShares = [
            SELECT Id, AccountId, UserOrGroupId, RowCause
            FROM AccountShare
            WHERE AccountId IN :meetingIdsByAccountIds.keySet()
                AND RowCause IN :sharingRowCauses
        ];

        Map<Id, Set<Id>> meetingIdsByUserIdForGrandShare = new Map<Id, Set<Id>>();
        for(AccountShare accountShare : accountShares) {
            Id accountId = accountShare.AccountId;
            Id userId = accountShare.UserOrGroupId;
            if (meetingIdsByAccountIds.containsKey(accountId)) {
                if (!meetingIdsByUserIdForGrandShare.containsKey(userId)) {
                    meetingIdsByUserIdForGrandShare.put(userId, new Set<Id>());
                }
                meetingIdsByUserIdForGrandShare.get(userId).addAll(meetingIdsByAccountIds.get(accountId));
            }
        }

        MeetingShareService.removeMeetingAccess(filteredMeetingIdsByUserIdsForRemoveShare);
        MeetingShareService.grantMeetingAccess(meetingIdsByUserIdForGrandShare);
    }
}