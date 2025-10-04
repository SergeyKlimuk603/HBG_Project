trigger AccountShareTrigger on Meeting__Share (after insert, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            RegistrationHandlerNew.grantMeetingAccess(Trigger.new);
        }
        if (Trigger.isDelete) {

        }
    }
}