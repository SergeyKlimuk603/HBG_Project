public without sharing class MeetingTriggerHandler {


    public static void onBeforeInsert(List<Meeting__c> newMeetings) {
        // TODO: Implement logic for before insert trigger
    }

    public static void onAfterInsert(List<Meeting__c> newMeetings) {
        // TODO: Implement logic for after insert trigger
    }

    public static void onBeforeUpdate(List<Meeting__c> newMeetings, Map<Id, Meeting__c> oldMeetings) {
        getShares(oldMeetings.keySet(), 'onBeforeUpdate');
    }

    public static void onAfterUpdate(List<Meeting__c> newMeetings, Map<Id, Meeting__c> oldMeetings) {
        getShares(oldMeetings.keySet(), 'onAfterUpdate');
    }
    
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