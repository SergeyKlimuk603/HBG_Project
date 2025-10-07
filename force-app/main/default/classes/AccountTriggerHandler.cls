public with sharing class AccountTriggerHandler {
    public static void onAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        recalculateMeetingSharesAfterOwnerChanged(newAccounts, oldAccountsMap);
    }

    public static void onBeforeDelete(Map<Id, Account> oldAccountsMap) {
        recalculateMeetingSharesAfterAccountDelete(oldAccountsMap);
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

        MeetingShareService.removeMeetingAccess(meetingIdsByUserIdForRemoveAccess);
        MeetingShareService.grantMeetingAccess(meetingIdsByUserIdForGrandAccess);
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

        Map<Id, Set<Id>> meetingIdsByUserIds = MeetingShareService.getMeetingIdsByUserIdBasedOnAccountShares(accountShares);
        MeetingShareService.removeMeetingAccess(meetingIdsByUserIds);
    }


}