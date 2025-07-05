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
    let sha256_hash: [u8; 32] = sha256_var("Hello World! This is Noir-ECDSA".as_bytes(), 31);
    assert_eq(
        sha256_hash,
        [
            42, 204, 207, 15, 192, 246, 143, 215, 180, 110, 75, 247, 21, 126, 103, 225, 251, 180,
            86, 221, 251, 68, 216, 63, 17, 236, 32, 223, 169, 198, 9, 98,
        ],
    );
    let r: Secp256r1_Fr = Secp256r1_Fr::from_limbs([
        0x6e6dd8df9cec8c31892d01e14318fb,
        0x3109c73f335657be981f6387c44d3c,
        0x8e0e,
    ]);
    let s: Secp256r1_Fr = Secp256r1_Fr::from_limbs([
        0x262ed99e46e6577a71a75b1d5c7f4a,
        0xcefc34f4b68aa019eda376372f2e76,
        0x2c2d,
    ]);
    let public_key_x: Secp256r1_Fq = Secp256r1_Fq::from_limbs([
        0xd54378ffd74c0a0692ea56dc91e14a,
        0xa683ef4c166c55cfb8d135863fc8f9,
        0xaa1d,
    ]);
    let public_key_y: Secp256r1_Fq = Secp256r1_Fq::from_limbs([
        0x6b6c3604db3440d3dc4ee95a24f0f0,
        0xc4eae722e511eeb583122a0f6ab255,
        0x4b36,
    ]);
    assert(verify_secp256r1_ecdsa(public_key_x, public_key_y, sha256_hash, (r, s)));
}
