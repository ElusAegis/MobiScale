use appattest_rs::assertion::Assertion;

fn main() {
    let base64_client_data_json = "eCA9IDE1";
    let app_id = "LMRM26A744.xyz.elus.aegis.app-attester"; // replace this with yours. E.g 9000738UU8.auth.iphone.com
    let public_key = "-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEheMiyqD5gbwYzVNXTx3HYcE50VAw
o2sbJJzBWMgixFBrFXS2scW1v6+OKh3+PeqofIgC2GPIqsI6qZBWCopWtA==
-----END PUBLIC KEY-----";

    let previous_counter = 0;
    let base64_cbor_data = "omlzaWduYXR1cmVYRzBFAiA4+3V+mKaN4IvrhpAZug9nG5EgTLf9urMYoZIdDdt36AIhAMmP99pwoOaRqYCV4Q3Km4vQqebxCzfhdb2ow038AMWycWF1dGhlbnRpY2F0b3JEYXRhWCXXwWIjgKCprB/bVvaYf7bZmcJ35UnK1TNWcBhOwgdSS0AAAAAB";

    // Convert from base64 CBOR to Assertion
    let assertion_result = Assertion::from_base64(base64_cbor_data);
    
    match assertion_result {
        Ok(assertion) => {
            match assertion.verify(base64_client_data_json, app_id, public_key, previous_counter, None) {
                Ok(_) => println!("Verification successful!"),
                Err(e) => println!("Verification failed: {:?}", e),
            }
        },
        Err(e) => println!("Failed to decode and create assertion: {:?}", e),
    }
}
