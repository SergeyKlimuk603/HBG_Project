public static Map<Id, Set<Id>> getSharedMeetingIdsByUserId(
        Map<Id, Set<Id>> meetingIdsByUserId,
        List<String> sharingRowCauses
    ) {
        List<Meeting__Share> existingShares = getExistingShares(meetingIdsByUserId, sharingRowCauses);

        Map<Id, Set<Id>> sharedMeetingIdsByUserId = new Map<Id, Set<Id>>();
        for (Meeting__Share meetingShare : existingShares) {
            Id userId = meetingShare.UserOrGroupId;
            Id meetingId = meetingShare.ParentId;
            if (meetingIdsByUserId.get(userId)?.contains(meetingId) != true){
                continue;
            }

            if (!sharedMeetingIdsByUserId.containsKey(userId)) {
                sharedMeetingIdsByUserId.put(userId, new Set<Id>());
            }
            sharedMeetingIdsByUserId.get(userId).add(meetingId);
        }

        return sharedMeetingIdsByUserId;
    }
    //---------------------------------------------------------------------------------------------

    public static List<Meeting__Share> getExistingShares(Map<Id, List<Meeting__c>> meetingsByUserId) {
        Map<Id, Set<Id>> meetingIdsByUserId = new Map<Id, Set<Id>>();
        for (Id userId : meetingsByUserId.keySet()) {
            Set<Id> meetingIds = new Set<Id>();
            for (Meeting__c meeting : meetingsByUserId.get(userId)) {
                meetingIds.add(meeting.Id);
            }
            meetingIdsByUserId.put(userId, meetingIds);
        }

        return getExistingShares(meetingIdsByUserId);
    }
    //---------------------------------------------------------------------------------------------


    public static List<Meeting__Share> removeMeetingAccess(Map<Id, Set<Id>> meetingIdsByUserId) {

        Map<Id, Set<Id>> existMeetingShareIdsByUserId = getExistMeetingShareIdsByUserId(
            meetingIdsByUserId,
            new List<String>{'CustomSharing__c'}
        );

        List<Meeting__Share> sharesToDelete = new List<Meeting__Share>();
        for(Id userId : meetingIdsByUserId.keySet()) {
            for (Id meetingId : meetingIdsByUserId.get(userId)) {
                if (existMeetingShareIdsByUserId.get(userId)?.contains(meetingId) != true) {
                    continue; // not delete
                }

                sharesToDelete.add(new Meeting__Share(Id = meetingId));
            }
        }

        //TODO
        if (!sharesToDelete.isEmpty()) {
            // Database.delete(sharesToDelete, false);
        }

        return sharesToDelete;
    }
    //---------------------------------------------------------------------------------------------