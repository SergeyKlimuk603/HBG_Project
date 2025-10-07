trigger MeetingTrigger on Meeting__c (after insert, after update) {
    if (Trigger.isInsert) {
        if (Trigger.isAfter) {
            MeetingTriggerHandler.onAfterInsert(Trigger.new);
        }
    }

    if (Trigger.isUpdate) {
        if (Trigger.isAfter) {
            MeetingTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}