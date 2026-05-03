public class VerifyOTPOfTheCustomer {
	@InvocableMethod(label='Verify SMS OTP' description='Verify and set verified true')
        public static List<VerifyCustResponse> verifyTheOTPFromCust(List<VerifyCustRequest> requests) {
            String enteredOTP = (String)requests[0].enteredOTP;
            String twillioOTP = (String)requests[0].otpFromTwillio;
            
            VerifyCustResponse response = new VerifyCustResponse();
            if(enteredOTP.equalsIgnoreCase(twillioOTP))
            	response.isCustomerVerified = true;
            else
                response.isCustomerVerified = false;
            
            return new List<VerifyCustResponse>{ response };
        }
    	public class VerifyCustRequest {
            @InvocableVariable(required=true description='Entered OTP By Cust')
            public String enteredOTP;
            @InvocableVariable(required=true description='Twillio OTP')
            public String otpFromTwillio;
        }

        public class VerifyCustResponse {
            @InvocableVariable(description='is verified')
            public boolean isCustomerVerified;
        }
}