Id standardUser1Id = '005J7000001hqAZ'; // 'StandardUser1'
Id myUserId = '0057Q0000081Ifw'; // 'Ian Lin'
Id acc1_Id = '001J700000TjVxlIAF'; // 'Meeting Account 1'
Id meeting1_1_Id = 'a01J7000004jhjfIAA'; // 'Meeting 1-1'
Id meeting1_2_Id = 'a01J7000004jhQbIAI'; // 'Meeting 1-2'

Id userId = standardUser1Id;

//---------------------------------------------------------------------------------------------
// AccountShare created
AccountShare accountShare = createAccountShare(acc1_Id, userId);
RegistrationHandlerNew.grantMeetingAccess(new List<AccountShare>{accountShare});
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