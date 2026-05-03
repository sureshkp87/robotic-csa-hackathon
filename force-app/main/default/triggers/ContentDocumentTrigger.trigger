trigger ContentDocumentTrigger on ContentDocument (after insert) {
    for(ContentDocument cd : Trigger.new){
        
        // Get the ContentDocumentId (can be queried or from a trigger)
        Id myFileId = cd.Id; // Example ContentDocumentId
        Id targetRecordId = '005bm00000PBD5BAAX'; // Example Account/User Id
        
        // 2. Create the link
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = myFileId;
        cdl.LinkedEntityId = targetRecordId; // Target record or user ID
        cdl.ShareType = 'V'; // 'V' for Viewer, 'C' for Collaborator, 'I' for Inferred [9]
        cdl.Visibility = 'AllUsers'; // 'AllUsers', 'InternalUsers', or 'SharedUsers' [9]
        
        //insert cdl;
    }
}