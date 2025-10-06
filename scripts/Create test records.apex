Account account = new Account(Name = 'Meeting 3');
insert account;

List<Meeting__c> meetings = new List<Meeting__c>{
    new Meeting__c(Name = 'Meeting 3-1', Account__c = account.Id),
    new Meeting__c(Name = 'Meeting 3-2', Account__c = account.Id)
};
insert meetings;
