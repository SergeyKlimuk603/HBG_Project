public with sharing class MeetingService {
    public static Map<Id, Set<Id>> getMeetingIdsByAccountIds(Set<Id> accountIds) {
        List<Meeting__c> meetings = [
            SELECT Id, OwnerId, Account__c, Name
            FROM Meeting__c 
            WHERE Account__c IN :accountIds
        ];

        Map<Id, Set<Id>> meetingIdsByAccountIds = new Map<Id, Set<Id>>();
        for (Meeting__c meeting : meetings) {
            if (!meetingIdsByAccountIds.containsKey(meeting.Account__c)) {
                meetingIdsByAccountIds.put(meeting.Account__c, new Set<Id>());
            }
            meetingIdsByAccountIds.get(meeting.Account__c).add(meeting.Id);
        }

        return meetingIdsByAccountIds;
    }
}