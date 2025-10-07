trigger MeetingParticipationTrigger on Meeting_Participation__c (
    before insert, 
    after insert, 
    before update, 
    after update,
    before delete, 
    after delete
) {
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            MeetingParticipationTriggerHandler.onBeforeInsert(Trigger.new);
        }
        if (Trigger.isAfter) {
            MeetingParticipationTriggerHandler.onAfterInsert(Trigger.new);
        }
    }

    if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            MeetingParticipationTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isAfter) {
            MeetingParticipationTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isDelete) {
        if (Trigger.isBefore) {
            MeetingParticipationTriggerHandler.onBeforeDelete(Trigger.oldMap);
        }
        if (Trigger.isAfter) {
            MeetingParticipationTriggerHandler.onAfterDelete(Trigger.oldMap);
        }
    }
}