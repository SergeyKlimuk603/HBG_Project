public with sharing class MeetingParticipationTriggerHandler {
    public static void onBeforeInsert(List<Meeting_Participation__c> newParticipations) {
        // TODO: Implement logic for before insert trigger
    }

    public static void onAfterInsert(List<Meeting_Participation__c> newParticipations) {
        // TODO: Implement logic for after insert trigger
    }

    public static void onBeforeUpdate(List<Meeting_Participation__c> newParticipations, Map<Id, Meeting_Participation__c> oldParticipationsMap) {
        // TODO: Implement logic for before insert trigger
    }

    public static void onAfterUpdate(List<Meeting_Participation__c> newParticipations, Map<Id, Meeting_Participation__c> oldParticipationsMap) {
        
    }

    public static void onBeforeDelete(Map<Id, Meeting_Participation__c> newParticipations) {
        
    }

    public static void onAfterDelete(Map<Id, Meeting_Participation__c> newParticipations) {
        // TODO: Implement logic for before insert trigger
    }

    public static void shareByLinkedUser(
        List<Meeting_Participation__c> newParticipations, 
        Map<Id, Meeting_Participation__c> oldParticipationsMap
    ) {
        List<Meeting_Participation__c> changedUserParticipations = new List<Meeting_Participation__c>();
        for (Meeting_Participation__c participant : newParticipations) {
            if (participant.User__c == oldParticipationsMap?.get(participant.Id).User__c) {
                continue;
            }

            changedUserParticipations.add(participant);
        }

        if (changedUserParticipations.isEmpty()) {
            return;
        }

        //---------------------------------------------------------------------------------------------
        
        
        Set<Id> meetingIds = new Set<Id>();
        Map<Id, Set<Id>> meetingIdsByOldUserIds = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> meetingIdsByNewUserIds = new Map<Id, Set<Id>>();
        for (Meeting_Participation__c participant : changedUserParticipations) {
            
            Id oldUserId = oldParticipationsMap?.get(participant.Id).User__c;
            if (userId != null) {
                
            }




            System.debug('----- 23232 oldAccount: ' + oldAccount);
            if (String.isNotBlank(oldAccount)) {
                if (!oldMeetingIdsByAccountId.containsKey(oldAccount)) {
                    oldMeetingIdsByAccountId.put(oldAccount, new Set<Id>());
                }
                oldMeetingIdsByAccountId.get(oldAccount).add(meeting.Id);
            }
            // Id newUserId = participant.User__c;
            // if (userId != null) {
            //     if (!meetingIdsByNewUserIds.containsKey(newUserId)) {
            //         meetingIdsByNewUserIds.put(newUserId, new Set<Id>());
            //     }
            //     meetingIdsByNewUserIds.get(newUserId).add(participant.Meeting__c);
            // }
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
}