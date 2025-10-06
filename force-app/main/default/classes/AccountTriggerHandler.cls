public with sharing class AccountTriggerHandler {
    public static void onBeforeInsert(List<Account> newAccounts) {
        // TODO: Implement logic for before insert trigger
    }

    public static void onAfterInsert(List<Account> newAccounts) {
        // TODO: Implement logic for after insert trigger
    }

    public static void onBeforeUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        // TODO: Implement logic for before insert trigger
    }

    public static void onAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        ownerChanged(newAccounts, oldAccountsMap);
    }

    // Run in after context
    public static void ownerChanged(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        List<Account> changedOwnersAccounts = new List<Account>();
        Map<Id, Id> oldOwnerIdByAccountId = new Map<Id, Id>();
        Map<Id, Id> newOwnerIdByAccountId = new Map<Id, Id>();
        for (Account acc : newAccounts) {
            Account oldAcc = oldAccountsMap.get(acc.Id);
            if (acc.OwnerId == oldAcc.OwnerId) {
                continue;
            }

            oldOwnerIdByAccountId.put(acc.Id, oldAcc.OwnerId);
            newOwnerIdByAccountId.put(acc.Id, acc.OwnerId);
            changedOwnersAccounts.add(acc);
        }

        if (changedOwnersAccounts.isEmpty()) {
            return;
        }

        Map<Id, Set<Id>> meetingIdsByAccountIds = MeetingService.getMeetingIdsByAccountIds(newOwnerIdByAccountId.keySet());

        Map<Id, Set<Id>> meetingIdsByUserIdForRemoveAccess = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> meetingIdsByUserIdForGrandAccess = new Map<Id, Set<Id>>();
        for (Id accountId : oldOwnerIdByAccountId.keySet()) {
            meetingIdsByUserIdForRemoveAccess.put(
                oldOwnerIdByAccountId.get(accountId), 
                meetingIdsByAccountIds.get(accountId)
            );
            meetingIdsByUserIdForGrandAccess.put(
                newOwnerIdByAccountId.get(accountId), 
                meetingIdsByAccountIds.get(accountId)
            );
        }

        List<Meeting__Share> removedMeetingShares = MeetingShareService.removeMeetingAccess(meetingIdsByUserIdForRemoveAccess);
        List<Meeting__Share> grandMeetingShares = MeetingShareService.grantMeetingAccess(meetingIdsByUserIdForGrandAccess);

        System.debug('-----removedMeetingShares: ' + removedMeetingShares);
        System.debug('-----grandMeetingShares: ' + grandMeetingShares);
        System.debug('-----meetingIdsByAccountIds: ' + meetingIdsByAccountIds);
    }


}