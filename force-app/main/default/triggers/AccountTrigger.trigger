trigger AccountTrigger on Account ( after update, before delete) {
    if (Trigger.isUpdate) {
        if (Trigger.isAfter) {
            AccountTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isDelete) {
        if (Trigger.isBefore) {
            AccountTriggerHandler.onBeforeDelete(Trigger.oldMap);
        }
    }
}