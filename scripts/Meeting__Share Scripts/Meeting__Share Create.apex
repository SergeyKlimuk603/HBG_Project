Id standardUser1Id = '005J7000001hqAZ'; // 'StandardUser1'
Id myUserId = '0057Q0000081Ifw'; // 'Ian Lin'
Id acc1_Id = '001J700000TjVxlIAF'; // 'Meeting Account 1'
Id acc2_Id = '001J700000TjrEDIAZ'; // 'Meeting Account 2'
Id meeting1_1_Id = 'a01J7000004jhjfIAA'; // 'Meeting 1-1'
Id meeting1_2_Id = 'a01J7000004jhQbIAI'; // 'Meeting 1-2'
Id meeting2_1_Id = 'a01J7000004jhs5IAA'; // 'Meeting 2-1'
Id meeting2_2_Id = 'a01J7000004jhsAIAQ'; // 'Meeting 2-2'

Id userId = standardUser1Id;

List<Meeting__Share> meetingShares = new List<Meeting__Share>{createMeetingShare(meeting1_1_Id, userId)};
// meetingShares.add(createMeetingShare(meeting1_2_Id, userId));

insert meetingShares;
System.debug('-----meetingShares: ' + meetingShares);

Meeting__Share createMeetingShare(Id meetingId, Id userId) {
    Meeting__Share share = new Meeting__Share();
    share.ParentId = meetingId;
    share.UserOrGroupId = userId;
    share.AccessLevel  = 'Read'; // Edit Read All

    share.RowCause = 'CustomSharing__c'; // Important for delete
    // share.RowCause = Schema.AccountShare.RowCause.Manual; // Important for delete

    return share;
}

