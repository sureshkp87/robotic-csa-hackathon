trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert, after insert) {
    if(UtilityClass.dontRunTrig)
        return;
    if(Trigger.isBefore){
        for (ContentDocumentLink cdl : Trigger.new) {
            Schema.SObjectType sobjectType = cdl.LinkedEntityId.getSObjectType();
            if(sobjectType.getDescribe().getName().equalsIgnoreCase('MessagingSession')){
                // Automatically change visibility to AllUsers
                cdl.Visibility = 'AllUsers';
                // Ensure the ShareType is correct (V = Viewer, I = Inferred)
                cdl.ShareType = 'V'; 
            }
        }
    }
    if(Trigger.isAfter){
        for (ContentDocumentLink cdlnk : Trigger.new) {
            Id myFileId = cdlnk.ContentDocumentId; // Example ContentDocumentId
            Id targetRecordId = '005bm00000PBD5BAAX'; // Example Account/User Id
            
            // 2. Create the link
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = myFileId;
            cdl.LinkedEntityId = targetRecordId; // Target record or user ID
            cdl.ShareType = 'V'; // 'V' for Viewer, 'C' for Collaborator, 'I' for Inferred [9]
            cdl.Visibility = 'AllUsers'; // 'AllUsers', 'InternalUsers', or 'SharedUsers' [9]
            UtilityClass.dontRunTrig = true;
            //insert cdl;
        }
    }
}