trigger MeetingTrigger on Meeting__c (
    before insert, 
    after insert, 
    before update, 
    after update
) {
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            MeetingTriggerHandler.onBeforeInsert(Trigger.new);
        }
        if (Trigger.isAfter) {
            MeetingTriggerHandler.onAfterInsert(Trigger.new);
        }
    }

    if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            MeetingTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isAfter) {
            MeetingTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}