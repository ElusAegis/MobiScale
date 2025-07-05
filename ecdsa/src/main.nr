use noir_ecdsa::ecdsa::verify_secp256r1_ecdsa;
use bigcurve::CurveParamsTrait;
use bigcurve::curves::secp256r1::{Secp256r1_Fq, Secp256r1_Fr, Secp256r1_Params};
use bigcurve::scalar_field::ScalarField;
use bigcurve::scalar_field::ScalarFieldTrait;
use bignum::BigNum;
use sha256::sha256_var;

fn main(
    sha256_hash: [u8; 32],
    r: [u8; 32],
    s: [u8; 32],
    public_key_x: [u8; 32],
    public_key_y: [u8; 32],
) {
    let r: Secp256r1_Fr = Secp256r1_Fr::from_be_bytes(r);
    let s: Secp256r1_Fr = Secp256r1_Fr::from_be_bytes(s);
    let public_key_x: Secp256r1_Fq = Secp256r1_Fq::from_be_bytes(public_key_x);
    let public_key_y: Secp256r1_Fq = Secp256r1_Fq::from_be_bytes(public_key_y);
    assert(verify_secp256r1_ecdsa(public_key_x, public_key_y, sha256_hash, (r, s)));
}
