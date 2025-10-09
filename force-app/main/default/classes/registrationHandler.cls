/*****************************************************************
 * @description: Handles creation and update of a user based on
 * * the data provided by Keycloak through OpenID
 * @testclass: registrationHandlerTest
 * @author david.lewakis@mindsquare.de
 * @data 04.07.2025
 * *
 * @modifiedBy  : Andrei Pivavarchyk (mindsquare GmbH)
 * @modifiedDate: 10.09.2025
 * @modification: Extended logic for meeting sharing and updated related tests
*****************************************************************/

global without sharing class registrationHandler implements Auth.RegistrationHandler {
    @TestVisible
    private static final String PROFILE_NAME = 'Standard HBG User';
    @TestVisible
    private static final String STANDARD_PERMISSION_SET = 'HBG_Standard_Permissions';
    @TestVisible
    private static final String VIEW_ALL_PERMISSION_SET = 'HBG_View_All_Accounts';
    @TestVisible
    private static final String VIEW_ALL_MEETINGS_PERMISSION_SET = 'HBG_View_All_Meetings';
    @TestVisible
    private static final String DOCUMENTS_STANDARD_USER_PERMISSION_SET = 'dvelop_standard';
    @TestVisible
    private static final String MEETING_PERMISSION_SET = 'Meeting_Permission';
    @TestVisible
    private static final String PACKAGE_LICENSE_DOCUMENTS_NAME_SPACE = 'dvelop_docs_dev';
    @TestVisible
    private static final String ALL_ACCESS_ROLE = 'ssf';

    global User createUser(Id portalId, Auth.UserData data) {
        User user = new User();

        setBasicAttributes(user, data);

        Profile pofile = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME LIMIT 1];

        user.ProfileId = pofile.Id;
        user.LanguageLocaleKey = 'de';
        user.LocaleSidKey = 'de_DE';
        user.EmailEncodingKey = 'UTF-8';
        user.TimeZoneSidKey = 'Europe/Berlin';

        insert user;

        assignUserPackageLicense(user.Id, new Set<String>{ PACKAGE_LICENSE_DOCUMENTS_NAME_SPACE });

        if (data.idTokenJSONString != null && data.idTokenJSONString.contains(ALL_ACCESS_ROLE)) {
            assignUserPermissionSet(user.Id, new Set<String>{DOCUMENTS_STANDARD_USER_PERMISSION_SET, MEETING_PERMISSION_SET, STANDARD_PERMISSION_SET, VIEW_ALL_PERMISSION_SET,VIEW_ALL_MEETINGS_PERMISSION_SET});
        }else{
            assignUserPermissionSet(user.Id, new Set<String>{DOCUMENTS_STANDARD_USER_PERMISSION_SET, MEETING_PERMISSION_SET, STANDARD_PERMISSION_SET});
            getManufactureIdsAndGrantAcess(user, data);
        }

        return user;
    }

    // is called automatically after createUser
    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
        User user = new User(Id = userId);

        setBasicAttributes(user, data);

        assignUserPackageLicense(user.Id, new Set<String>{ PACKAGE_LICENSE_DOCUMENTS_NAME_SPACE });

        if (data.idTokenJSONString != null && data.idTokenJSONString.contains(ALL_ACCESS_ROLE)) {
            assignUserPermissionSet(user.Id, new Set<String>{DOCUMENTS_STANDARD_USER_PERMISSION_SET, MEETING_PERMISSION_SET, STANDARD_PERMISSION_SET, VIEW_ALL_PERMISSION_SET,VIEW_ALL_MEETINGS_PERMISSION_SET});
        }else{
            assignUserPermissionSet(user.Id, new Set<String>{DOCUMENTS_STANDARD_USER_PERMISSION_SET, MEETING_PERMISSION_SET, STANDARD_PERMISSION_SET});
            getManufactureIdsAndGrantAcess(user, data);
        }

        update user;
    }

    public void mDebugUntruncated(String sMsg) {
        for (Integer i = 0; i < sMsg.length(); i=i+300) {
            Integer iEffectiveEnd = (i+300 > (sMsg.length()) ? sMsg.length()-1 : i+300);
            System.debug(sMsg.substring(i,iEffectiveEnd));
        }
    }


    private void setBasicAttributes(User user, Auth.UserData data) {
        this.mDebugUntruncated('JSON: ' + data);
        System.Debug('D!__' + data);
        if (data.attributeMap.get('username') == null) {
            throw new IllegalArgumentException('Username is missing!');
        }
        user.Username = data.attributeMap.get('username');

        if (data.attributeMap.get('email') == null) {
            throw new IllegalArgumentException('E-Mail is missing!');
        }
        user.Email = data.attributeMap.get('email');

        if (data.lastName == null) {
            throw new IllegalArgumentException('Last name is missing!');
        }
        user.FirstName = data.firstName != null ? data.firstName : '';
        user.LastName = data.lastName;

        String alias =  String.isNotBlank(user.FirstName) ? user.FirstName.substring(0, 1) + user.LastName : user.LastName;

        if (alias.length() > 8){
            alias = alias.substring(0, 8);
        }

        user.Alias = alias;

        if (data.attributeMap.get('sub') != null) {
            user.KeyCloackId__c = data.attributeMap.get('sub');
        }

        if (data.attributeMap.get('mandantID') != null) {
            user.MandantId__c = data.attributeMap.get('mandantID');
        }
    }

    private static void assignUserPermissionSet(Id userId, Set<String> permissionSetNames) {
        if (String.isBlank(userId) || permissionSetNames.isEmpty()) {
            return;
        }

        List<PermissionSet> permissionSetsToAssign = [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetNames];
        if (permissionSetsToAssign.isEmpty()) {
            return;
        }

        List<PermissionSetAssignment> existingAssignments = [
                SELECT Id,PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
                AND PermissionSetId IN :permissionSetsToAssign
        ];

        Set<Id> assignedPermissionSetIds = new Set<Id>();
        for (PermissionSetAssignment existingAssignment : existingAssignments) {
            assignedPermissionSetIds.add(existingAssignment.PermissionSetId);
        }
        Set<Id> missedPermissionIds = new Set<Id>();
        for (PermissionSet permissionSet : permissionSetsToAssign) {
            if (!assignedPermissionSetIds.contains(permissionSet.Id)) {
                missedPermissionIds.add(permissionSet.Id);
            }
        }
        if (!missedPermissionIds.isEmpty()) {
            assignUserPermissionSet(userId, missedPermissionIds);
        }
    }

    @Future
    private static void assignUserPermissionSet(Id userId, Set<Id> permissionSetIds) {
        if (String.isBlank(userId) || permissionSetIds.isEmpty()) {
            return;
        }

        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        Set<Id> existingPermissionSetIdAssignments = new Set<Id>();

        List<PermissionSetAssignment> existingAssignments = [
                SELECT Id,PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
                AND PermissionSetId IN :permissionSetIds
        ];

        for (PermissionSetAssignment permissionSetAssignment : existingAssignments) {
            existingPermissionSetIdAssignments.add(permissionSetAssignment.PermissionSetId);
        }

        for (Id permissionSetId : permissionSetIds) {
            if (existingPermissionSetIdAssignments.contains(permissionSetId)) {
                continue;
            }
            PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSetId) ;
            permissionSetAssignments.add(permissionSetAssignment);
        }

        insert permissionSetAssignments;
    }

    @Future
    public static void assignUserPackageLicense(Id userId, Set<String> namespacePrefixList) {
        if (String.isBlank(userId) || namespacePrefixList.isEmpty()) {
            return;
        }

        Set<Id> assignedLicenseIds = new Set<Id>();
        List<UserPackageLicense> licenseAssignmentToInsert = new List<UserPackageLicense>();

        List<PackageLicense> packageLicenseList = [
                SELECT Id, NamespacePrefix, AllowedLicenses, UsedLicenses
                FROM PackageLicense
                WHERE NamespacePrefix IN :namespacePrefixList
                AND (Status = 'Active' OR Status = 'Free')
                AND (ExpirationDate = null OR ExpirationDate >= :Date.today())

        ];

        List<UserPackageLicense> userPackageLicenses = [
                SELECT PackageLicenseId
                FROM UserPackageLicense
                WHERE UserId = :userId
                AND PackageLicense.NamespacePrefix IN :namespacePrefixList
        ];

        for (UserPackageLicense userPackageLicense : userPackageLicenses) {
            assignedLicenseIds.add(userPackageLicense.PackageLicenseId);
        }

        for (PackageLicense packageLicense : packageLicenseList) {
            if ((packageLicense.AllowedLicenses == -1
                    || packageLicense.UsedLicenses < packageLicense.AllowedLicenses)
                    && !assignedLicenseIds.contains(packageLicense.Id)) {

                licenseAssignmentToInsert.add(new UserPackageLicense(UserId = userId, PackageLicenseId = packageLicense.Id));
            }
        }

        insert licenseAssignmentToInsert;
    }

    private static void getManufactureIdsAndGrantAcess(User user,  Auth.UserData data) {
        List<String> manufactureIds = getAccountIdsTheUserShouldHaveAccessTo(data);
        grantAndRemoveAccountAccess(user.Id, manufactureIds);
    }

    private static List<String> getAccountIdsTheUserShouldHaveAccessTo(Auth.UserData data) {
        List<String> manufactureIds = new List<String>();

        if (data.idTokenJSONString.contains('SF-Sparte')) {
            manufactureIds = getManufactureIdsFromSparte(data);
        }

        if (data.idTokenJSONString.contains('KAM-Manufacturer')) {
            manufactureIds = getManufactureIdsFromKAM(data);
        }

        return manufactureIds;
    }

    private static List<String> getManufactureIdsFromSparte(Auth.UserData data) {
        List<String> manufactureIds = new List<String>();
        Map<String, Object> tokenMap = (Map<String, Object>) JSON.deserializeUntyped(data.idTokenJSONString);

		List<Object> devisionList = (List<Object>) tokenMap.get('SF-Sparte');

        for (Object devision : devisionList) {
            Map<String, Object> devisionParsed = (Map<String, Object>) devision;
            if (devisionParsed.containsKey('Hersteller')) {
                List<Object> manufactureList = (List<Object>) devisionParsed.get('Hersteller');

                for (Object manufacture : manufactureList) {
                    Map<String, Object> manufactureParsed = (Map<String, Object>) manufacture;
                    String id = (String) manufactureParsed.get('ManufacturerID');
                    manufactureIds.add(id);
                }
            }
        }
        return manufactureIds;
    }

    private static List<String> getManufactureIdsFromKAM(Auth.UserData data) {
        List<String> manufactureIds = new List<String>();
        Map<String, Object> tokenMap = (Map<String, Object>) JSON.deserializeUntyped(data.idTokenJSONString);

		List<Object> manufactureList = (List<Object>) tokenMap.get('KAM-Manufacturer');

        for (Object manufacture : manufactureList) {
            Map<String, Object> manufactureParsed = (Map<String, Object>) manufacture;

            String id = (String) manufactureParsed.get('ManufacturerID');
            manufactureIds.add(id);
        }
        return manufactureIds;
    }

    private static void grantAndRemoveAccountAccess(Id userId, List<String> manufactureIds) {
        if (manufactureIds.isEmpty()) {
            return;
        }

        List<Account> targetAccounts = [SELECT Id, ManufacturerId__c FROM Account WHERE ManufacturerId__c IN :manufactureIds];

        Set<Id> targetAccountIds = new Set<Id>();

        for (Account acc : targetAccounts) {
            targetAccountIds.add(acc.Id);
        }

        List<AccountShare> existingShares = [SELECT Id, AccountId,UserOrGroupId FROM AccountShare WHERE UserOrGroupId = :userId AND RowCause = 'Manual']; // Or 'ExplicitUser' if not using RowCause

        Set<Id> existingAccountIds = new Set<Id>();

        for (AccountShare share : existingShares) {
            existingAccountIds.add(share.AccountId);
        }
        // Determine which shares to delete 
        Set<Id> sharesToRemove = existingAccountIds.clone();
        sharesToRemove.removeAll(targetAccountIds);

        List<AccountShare> sharesToDelete = new List<AccountShare>();

        for (AccountShare share : existingShares) {
            if (sharesToRemove.contains(share.AccountId)) {
                sharesToDelete.add(share);
            }
        }
        // Determine which shares to add (new ones not already shared)
        Set<Id> sharesToAdd = targetAccountIds.clone();
        sharesToAdd.removeAll(existingAccountIds);

        List<AccountShare> sharesToInsert = new List<AccountShare>();
        for (Account acc : targetAccounts) {
            if (sharesToAdd.contains(acc.Id)) {
                sharesToInsert.add(createAccountShare(userId, acc.Id));
            }
        }

        if (!sharesToDelete.isEmpty()) {
            Database.delete(sharesToDelete, false);
            MeetingShareService.removeAccessFromAccountMeetings(sharesToDelete);
        }

        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
            system.debug('account sharesToInsert:'+sharesToInsert);
            MeetingShareService.grantAccessToAccountMeetings(sharesToInsert);
        }
    }

    private static AccountShare createAccountShare(Id userId, Id accoountId) {
        AccountShare share = new AccountShare();
        share.AccountId = accoountId;
        share.UserOrGroupId = userId;
        share.AccountAccessLevel = 'Edit';
        share.OpportunityAccessLevel = 'None';
        share.CaseAccessLevel = 'None';
        share.RowCause = Schema.AccountShare.RowCause.Manual; // Important for delete

        return share;
    }
}