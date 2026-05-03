global class ShareContentWithEinsteinAction {

    global class ActionInput {
        @InvocableVariable(
            label='Messaging Session Id'
            description='The Id of the MessagingSession record'
            required=true
        )
        global Id messagingSessionId;
    }

    global class ActionOutput {
        @InvocableVariable(
            label='Content Document Id'
            description='The ContentDocument Id of the uploaded image'
        )
        global String contentDocumentId;

        @InvocableVariable(
            label='Status'
            description='Success or Error'
        )
        global String status;

        @InvocableVariable(
            label='Error'
            description='Error message if something went wrong'
        )
        global String error;
    }

    @InvocableMethod(
        label='Share Content With Einstein User'
        description='Finds the latest ContentDocument linked to the MessagingSession and shares it with the Einstein Agent User'
        category='Financial Services'
    )
    global static List<ActionOutput> execute(
        List<ActionInput> inputs
    ) {
        List<ActionOutput> outputs = new List<ActionOutput>();


        Id einsteinUserId = '005bm00000PBD5B';

        for (ActionInput input : inputs) {
            ActionOutput output = new ActionOutput();

            try {
                if (input.messagingSessionId == null) {
                    output.status = 'Error';
                    output.error  = 'Messaging Session Id is required.';
                    outputs.add(output);
                    continue;
                }

                // Step 1 — Find latest ContentDocumentLink
                // on the MessagingSession
                List<ContentDocumentLink> cdls = [
                    SELECT Id, ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :input.messagingSessionId
                    ORDER BY SystemModstamp DESC
                    LIMIT 1
                ];

                if (cdls.isEmpty()) {
                    output.status = 'Error';
                    output.error  = 'No file found linked to ' +
                                    'this messaging session.';
                    outputs.add(output);
                    continue;
                }

                Id contentDocumentId = cdls[0].ContentDocumentId;

                // Step 2 — Check if share already exists
                // to avoid duplicate insert
                List<ContentDocumentLink> existingShare = [
                    SELECT Id
                    FROM ContentDocumentLink
                    WHERE ContentDocumentId = :contentDocumentId
                      AND LinkedEntityId    = :einsteinUserId
                    LIMIT 1
                ];

                if (existingShare.isEmpty()) {
                    // Step 3 — Share with Einstein User
                    ContentDocumentLink share =
                        new ContentDocumentLink(
                            ContentDocumentId = contentDocumentId,
                            LinkedEntityId    = einsteinUserId,
                            ShareType         = 'V',
                            Visibility        = 'AllUsers'
                        );
                    insert share;

                    System.debug(
                        'ContentDocument ' + contentDocumentId +
                        ' shared with Einstein User ' + einsteinUserId
                    );
                } else {
                    System.debug(
                        'Share already exists for ContentDocument: '
                        + contentDocumentId
                    );
                }

                output.contentDocumentId = contentDocumentId;
                output.status            = 'Success';

            } catch (Exception e) {
                output.status = 'Error';
                output.error  = 'Error sharing content: '
                                + e.getMessage();
                System.debug('ShareContentWithEinsteinAction ERROR: '
                    + e.getMessage());
            }

            outputs.add(output);
        }

        return outputs;
    }
}