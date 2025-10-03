Id standardUser1Id = '005J7000001hqAZ'; // 'StandardUser1'
Id myUserId = '0057Q0000081Ifw'; // 'Ian Lin'
Id acc1_Id = '001J700000TjVxlIAF'; // 'Meeting Account 1'
Id meeting1_1_Id = 'a01J7000004jhjfIAA'; // 'Meeting 1-1'
Id meeting1_2_Id = 'a01J7000004jhQbIAI'; // 'Meeting 1-2'

List<Id> accountIds = new List<Id>{acc1_Id};
List<Id> userIds = new List<Id>{standardUser1Id, myUserId};
List<Id> meetingIds = new List<Id>{meeting1_1_Id, meeting1_2_Id};

List<AccountShare> accountSharesForDelete = [
    SELECT Id
    FROM AccountShare
    WHERE AccountId IN :accountIds
        AND UserOrGroupId IN :userIds
        AND RowCause IN ('Manual')
];
delete accountSharesForDelete;

List<Meeting__Share> meetingSharesForDelete = [
    SELECT Id
    FROM Meeting__Share
    WHERE ParentId IN :meetingIds
        AND UserOrGroupId IN :userIds
        AND RowCause IN ('Manual')
];
delete meetingSharesForDelete;