public without sharing class MeetingTriggerHandler {


    public static void onBeforeInsert(List<Meeting__c> newMeetings) {
        // TODO: Implement logic for before insert trigger
    }

    public static void onAfterInsert(List<Meeting__c> newMeetings) {
        shareByLinkedAccount(newMeetings, null);
    }

    public static void onBeforeUpdate(List<Meeting__c> newMeetings, Map<Id, Meeting__c> oldMeetings) {
    }

    public static void onAfterUpdate(List<Meeting__c> newMeetings, Map<Id, Meeting__c> oldMeetings) {
        shareByLinkedAccount(newMeetings, oldMeetings);
        shareForOldOwner(newMeetings, oldMeetings);
    }

    public static void shareByLinkedAccount(List<Meeting__c> newMeetings, Map<Id, Meeting__c> oldMeetings) {
        Map<Id, Set<Id>> oldMeetingIdsByAccountId = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> newMeetingIdsByAccountId = new Map<Id, Set<Id>>();
        for (Meeting__c meeting : newMeetings) {
            Id newAccount = meeting.Account__c;
            if (String.isNotBlank(meeting.Account__c)) {
                if (!newMeetingIdsByAccountId.containsKey(newAccount)) {
                    newMeetingIdsByAccountId.put(newAccount, new Set<Id>());
                }
                newMeetingIdsByAccountId.get(newAccount).add(meeting.Id);
            }
            Id oldAccount = oldMeetings?.get(meeting.Id).Account__c;
            System.debug('----- 23232 oldAccount: ' + oldAccount);
            if (String.isNotBlank(oldAccount)) {
                if (!oldMeetingIdsByAccountId.containsKey(oldAccount)) {
                    oldMeetingIdsByAccountId.put(oldAccount, new Set<Id>());
                }
                oldMeetingIdsByAccountId.get(oldAccount).add(meeting.Id);
            }
        }

        System.debug('-----oldMeetingIdsByAccountId: ' + oldMeetingIdsByAccountId);
        System.debug('-----newMeetingIdsByAccountId: ' + newMeetingIdsByAccountId);

        List<String> sharingRowCauses = new List<String>{'Manual', 'Owner'};
        List<AccountShare> accountShares = [
            SELECT Id, AccountId, UserOrGroupId, RowCause
            FROM AccountShare
            WHERE (AccountId IN :oldMeetingIdsByAccountId.keySet()
                    OR AccountId IN :newMeetingIdsByAccountId.keySet())
                AND RowCause IN :sharingRowCauses
        ];

        System.debug('-----12 accountShares.size(): ' + accountShares.size());
        for (Integer i = 0; i < accountShares.size(); i++) {
            System.debug('-----accountShares[' + i + ']: ' + accountShares[i]);
        }

        Map<Id, Set<Id>> meetingIdsByUserIdForRemoveShare = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> meetingIdsByUserIdForGrandShare = new Map<Id, Set<Id>>();
        for(AccountShare accountShare : accountShares) {
            Id accountId = accountShare.AccountId;
            Id userId = accountShare.UserOrGroupId;
            if (oldMeetingIdsByAccountId.containsKey(accountId)) {
                if (!meetingIdsByUserIdForRemoveShare.containsKey(userId)) {
                    meetingIdsByUserIdForRemoveShare.put(userId, new Set<Id>());
                }
                meetingIdsByUserIdForRemoveShare.get(userId).addAll(oldMeetingIdsByAccountId.get(accountId));
            }
            if (newMeetingIdsByAccountId.containsKey(accountId)) {
                if (!meetingIdsByUserIdForGrandShare.containsKey(userId)) {
                    meetingIdsByUserIdForGrandShare.put(userId, new Set<Id>());
                }
                meetingIdsByUserIdForGrandShare.get(userId).addAll(newMeetingIdsByAccountId.get(accountId));
            }
        }

        List<Meeting__Share> removedMeetingShares = MeetingShareService.removeMeetingAccess(meetingIdsByUserIdForRemoveShare);
        List<Meeting__Share> grandMeetingShares = MeetingShareService.grantMeetingAccess(meetingIdsByUserIdForGrandShare);

        System.debug('----- 45 removedMeetingShares.size(): ' + removedMeetingShares.size());
        for (Integer i = 0; i < removedMeetingShares.size(); i++) {
            System.debug('-----removedMeetingShares[' + i + ']: ' + removedMeetingShares[i]);
        }
        System.debug('-----46 grandMeetingShares.size(): ' + grandMeetingShares.size());
        for (Integer i = 0; i < grandMeetingShares.size(); i++) {
            System.debug('-----grandMeetingShares[' + i + ']: ' + grandMeetingShares[i]);
        }
    }

    public static void shareForOldOwner(List<Meeting__c> newMeetings, Map<Id, Meeting__c> oldMeetings) {
        List<Meeting__c> ownerChangedOldMeetings = new List<Meeting__c>();
        for (Meeting__c meeting : newMeetings) {
            Meeting__c oldMeeting = oldMeetings.get(meeting.Id);
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

        List<AccountShare> accountShares = [
            SELECT Id, AccountId, UserOrGroupId, RowCause
            FROM AccountShare
            WHERE AccountId IN :linkedAccountIds
                AND UserOrGroupId IN :oldOwnerIds
                AND RowCause IN :new List<String>{'Manual', 'Owner'}
        ];

        Map<Id, Set<Id>> sharedAccountIdsByUserIds = new Map<Id, Set<Id>>();
        for (AccountShare accountShare : accountShares) {
            if (!sharedAccountIdsByUserIds.containsKey(accountShare.UserOrGroupId)) {
                sharedAccountIdsByUserIds.put(accountShare.UserOrGroupId, new Set<Id>());
            }
            sharedAccountIdsByUserIds.get(accountShare.UserOrGroupId).add(accountShare.AccountId);
        }

        Map<Id, Set<Id>> meetingIdsByUserIdForSharing = new Map<Id, Set<Id>>();
        for (Meeting__c oldMeeting : ownerChangedOldMeetings) {
            Id oldOwner = oldMeeting.OwnerId;
            Set<Id> sharedAccounts = sharedAccountIdsByUserIds.get(oldOwner);
            if (sharedAccounts?.contains(oldMeeting.Account__c) != true) {
                continue;
            }

            if (!meetingIdsByUserIdForSharing.containsKey(oldOwner)) {
                meetingIdsByUserIdForSharing.put(oldOwner, new Set<Id>());
            }
            meetingIdsByUserIdForSharing.get(oldOwner).add(oldMeeting.Id);
        }

        List<Meeting__Share> grandMeetingShares = MeetingShareService.grantMeetingAccess(meetingIdsByUserIdForSharing);

        System.debug('-----97 grandMeetingShares.size(): ' + grandMeetingShares.size());
        for (Integer i = 0; i < grandMeetingShares.size(); i++) {
            System.debug('-----grandMeetingShares[' + i + ']: ' + grandMeetingShares[i]);
        }
    }





    //TODO delete this
    public static List<Meeting__Share> getShares(Set<Id> meetingIds, String callMethod) {
        List<Meeting__Share>  meetingShares = [
            SELECT Id, ParentId, UserOrGroupId, UserOrGroup.Name, AccessLevel, RowCause
            FROM Meeting__Share
            WHERE ParentId IN :Trigger.new
        ];

        for (Meeting__Share meetingShare : meetingShares) {
            System.debug('-----' + callMethod + ' meetingShare: ' + meetingShare);
        }

        return meetingShares;
    }
}