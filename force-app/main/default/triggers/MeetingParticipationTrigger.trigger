trigger MeetingParticipationTrigger on Meeting_Participation__c (
    after insert, 
    after update,
    after delete
) {
    if (Trigger.isInsert) {
        if (Trigger.isAfter) {
            MeetingParticipationTriggerHandler.onAfterInsert(Trigger.new);
        }
    }

    if (Trigger.isUpdate) {
        if (Trigger.isAfter) {
            MeetingParticipationTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isDelete) {
        if (Trigger.isAfter) {
            MeetingParticipationTriggerHandler.onAfterDelete(Trigger.oldMap);
        }
    }
}