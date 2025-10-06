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
        recalculateMeetingSharesAfterOwnerChanged(newAccounts, oldAccountsMap);
    }

    public static void onBeforeDelete(Map<Id, Account> oldAccountsMap) {
        recalculateMeetingSharesAfterAccountDelete(oldAccountsMap);
    }

    public static void onAfterDelete(Map<Id, Account> oldAccountsMap) {
        // TODO: Implement logic for before insert trigger
    }

    // Run in after context
    public static void recalculateMeetingSharesAfterOwnerChanged(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
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

    // Run in before context
    public static void recalculateMeetingSharesAfterAccountDelete(Map<Id, Account> oldAccountsMap) {
        List<String> sharingRowCauses = new List<String>{'Manual', 'Owner'};
        List<AccountShare> accountShares = [
            SELECT Id, AccountId, UserOrGroupId, RowCause
            FROM AccountShare
            WHERE AccountId IN :oldAccountsMap.keySet()
                AND RowCause IN :sharingRowCauses
        ];

        System.debug('-----accountShares.size(): ' + accountShares.size());
        for (Integer i = 0; i < accountShares.size(); i++) {
            System.debug('-----accountShares[' + i + ']: ' + accountShares[i]);
        }

        Map<Id, Set<Id>> meetingIdsByUserIds = MeetingShareService.getMeetingIdsByUserIdBasedOnAccountShares(accountShares);

        System.debug('-----111 meetingIdsByUserIds: ' + meetingIdsByUserIds);

        List<Meeting__Share> removedMeetingShares = MeetingShareService.removeMeetingAccess(meetingIdsByUserIds);

        System.debug('-----111 removedMeetingShares: ' + removedMeetingShares);
    }


}