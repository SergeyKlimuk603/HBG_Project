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
//
private static List<String> sharingRowCauses = new List<String>{
    'CustomSharing__c'
    // , 'Manual'
    // , 'Owner'
};

Set<Id> meetingIds = new Set<Id>{
    meeting1_1_Id
    , meeting1_2_Id
    , meeting2_1_Id
    , meeting2_2_Id
};

//---------------------------------------------------------------------------------------------
// Test MeetingShareService.getExistingShares()
// List<Meeting__Share> meetingShares = MeetingShareService.getExistingShares(
//     new Map<Id, Set<Id>>{
//         userId => meetingIds
//     },
//     sharingRowCauses
// );

// System.debug('-----meetingShares.size(): ' + meetingShares.size());
// for (Integer i = 0; i < meetingShares.size(); i++) {
//     System.debug('-----meetingShares[' + i + ']: ' + meetingShares[i]);
// }
//---------------------------------------------------------------------------------------------
// Test MeetingShareService.getSharedMeetingIdsByUserId()
// Map<Id, Set<Id>> sharedMeetingIdsByUserId = MeetingShareService.getSharedMeetingIdsByUserId(
//     new Map<Id, Set<Id>>{
//         userId => meetingIds
//     },
//     sharingRowCauses
// );

// System.debug('-----sharedMeetingIdsByUserId: ' + sharedMeetingIdsByUserId);
//---------------------------------------------------------------------------------------------
// Test MeetingShareService.getExistMeetingShareIdsByUserId()
// Map<Id, Set<Id>> meetingShareIdsByUserId = MeetingShareService.getExistMeetingShareIdsByUserId(
//     new Map<Id, Set<Id>>{userId => meetingIds}
//     , new List<String>{'CustomSharing__c'}
// );

// System.debug('-----meetingShareIdsByUserId: ' + meetingShareIdsByUserId);
//---------------------------------------------------------------------------------------------
// Test MeetingShareService.grantMeetingAccess()
// List<Meeting__Share> meetingShares = MeetingShareService.grantMeetingAccess(
//     new Map<Id, Set<Id>>{userId => meetingIds}
// );

// System.debug('-----meetingShares.size(): ' + meetingShares.size());
// for (Integer i = 0; i < meetingShares.size(); i++) {
//     System.debug('-----meetingShares[' + i + ']: ' + meetingShares[i]);
// }
//---------------------------------------------------------------------------------------------
// Test MeetingShareService.removeMeetingAccess()
List<Meeting__Share> meetingShares = MeetingShareService.removeMeetingAccess(
    new Map<Id, Set<Id>>{userId => meetingIds}
);

System.debug('-----meetingShares.size(): ' + meetingShares.size());
for (Integer i = 0; i < meetingShares.size(); i++) {
    System.debug('-----meetingShares[' + i + ']: ' + meetingShares[i]);
}