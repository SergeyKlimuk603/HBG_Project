trigger AccountTrigger on Account (
    before insert, 
    after insert, 
    before update, 
    after update
) {
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            AccountTriggerHandler.onBeforeInsert(Trigger.new);
        }
        if (Trigger.isAfter) {
            AccountTriggerHandler.onAfterInsert(Trigger.new);
        }
    }

    if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            AccountTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isAfter) {
            AccountTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}