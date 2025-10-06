Id standardUser1Id = '005J7000001hqAZIAY'; // 'StandardUser1'
Id myUserId = '0057Q0000081Ifw'; // 'Ian Lin'
Id acc1_Id = '001J700000TjVxlIAF'; // 'Meeting Account 1'
Id acc2_Id = '001J700000TjrEDIAZ'; // 'Meeting Account 2'
Id meeting1_1_Id = 'a01J7000004jhjfIAA'; // 'Meeting 1-1'
Id meeting1_2_Id = 'a01J7000004jhQbIAI'; // 'Meeting 1-2'
Id meeting2_1_Id = 'a01J7000004jhs5IAA'; // 'Meeting 2-1'
Id meeting2_2_Id = 'a01J7000004jhsAIAQ'; // 'Meeting 2-2'

Id userId = standardUser1Id;

//---------------------------------------------------------------------------------------------
// AccountShare deleted
AccountShare accountShare = createAccountShare(acc1_Id, userId);
RegistrationHandlerNew.removeMeetingAccess(new List<AccountShare>{accountShare});
//---------------------------------------------------------------------------------------------

AccountShare createAccountShare(Id accountId, Id userId) {
    AccountShare share = new AccountShare();
    share.AccountId = accountId;
    share.UserOrGroupId = userId;
    share.AccountAccessLevel = 'Read'; // Edit Read All
    share.OpportunityAccessLevel = 'None';
    share.CaseAccessLevel = 'None';

    // share.RowCause = 'CustomSharing'; // Important for delete
    share.RowCause = Schema.AccountShare.RowCause.Manual; // Important for delete

    return share;
}