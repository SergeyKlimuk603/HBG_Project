Id standardUser1Id = '005J7000001hqAZ'; // 'StandardUser1'
Id myUserId = '0057Q0000081Ifw'; // 'Ian Lin'
Id acc1_Id = '001J700000TjVxlIAF'; // 'Meeting Account 1'
Id acc2_Id = '001J700000TjrEDIAZ'; // 'Meeting Account 2'
Id meeting1_1_Id = 'a01J7000004jhjfIAA'; // 'Meeting 1-1'
Id meeting1_2_Id = 'a01J7000004jhQbIAI'; // 'Meeting 1-2'
Id meeting2_1_Id = 'a01J7000004jhs5IAA'; // 'Meeting 2-1'
Id meeting2_2_Id = 'a01J7000004jhsAIAQ'; // 'Meeting 2-2'

Id userId = standardUser1Id;

//---------------------------------------------------------------------------------------------
// AccountShare created
List<Id> meetingIds = new List<Id>{
    meeting1_1_Id
    // , meeting1_2_Id
};
List<Meeting__c> meetings = [
    SELECT Id, OwnerId 
    FROM Meeting__c 
    WHERE Id = :meetingIds
];
RegistrationHandlerNew.grantMeetingAccess(new Map<Id, List<Meeting__c>>{
    userId => meetings
});
//---------------------------------------------------------------------------------------------

// Meeting__c createMeeting(Id accountId) {
//     Meeting__c meeting = new Meeting__c();
//     meeting.AccountId = accountId;

//     return meeting;
// }