/// 
module starex1::manager_shop {
    // use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event;
    use aptos_framework::object;
    use starex1::nft_starship::{Self, StarShip};
    use starex1::nft_asset::{Self, Asset};
    use std::string::{Self, String};
    use aptos_framework::timestamp;
    use std::signer::address_of;
    use std::error;
    use std::signer;
    use std::vector;
    use aptos_framework::account;
    use aptos_std::ed25519;
    // use aptos_token::token::{Self, TokenDataId};
    use aptos_framework::resource_account;
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    use aptos_std::ed25519::ValidatedPublicKey;
    use aptos_framework::randomness;

    // use starex1::nft_asset::{Self, };
    // use starex1::nft_gacha::{Self, };

    // for test
    const UNIT_PRICE: u64 = 100000000;

    #[event]
    // This struct stores the token receiver's address and token_data_id in the event of token minting
    struct ProductPurchased has drop, store {
        token_receiver_address: address,
        product_name: String,
        price: u64,
    }

    // This struct stores an ADMIN store's relevant information
    struct ModuleData has key {
        public_key: ed25519::ValidatedPublicKey,
        signer_cap: account::SignerCapability,
        purchase_enabled: bool,
    }

    struct PurchaseProofChallenge has key, drop{
        receiver_account_address: address,
        product_name: String,
        price: u64,
    }


    /// Action not authorized because the signer is not the admin of this module
    const ENOT_AUTHORIZED: u64 = 1;
    /// The shop purchase is disabled
    const EPURCHASE_DISABLED: u64 = 3;
    /// Specified public key is not the same as the admin's public key
    const EWRONG_PUBLIC_KEY: u64 = 4;
    /// Specified scheme required to proceed with the smart contract operation - can only be ED25519_SCHEME(0) OR MULTI_ED25519_SCHEME(1)
    const EINVALID_SCHEME: u64 = 5;
    /// Specified proof of knowledge required to prove ownership of a public key is invalid
    const EINVALID_PROOF_OF_KNOWLEDGE: u64 = 6;


    // // This function is only callable during publishing
    fun init_module(account: &signer) {

        let resource_signer_cap = resource_account::retrieve_resource_account_cap(account, @source_addr);
        // hardcoded public key - we will update it to the real one by calling `set_public_key` from the admin account
        let pk_bytes = x"9c7afbda08988e4d36a784a7aa0405bbd091043319cee3bb6eb25c3519996104";
        let public_key = std::option::extract(&mut ed25519::new_validated_public_key_from_bytes(pk_bytes));
        move_to(account, ModuleData {
            public_key,
            signer_cap: resource_signer_cap,
            purchase_enabled: true,
        });
    }

    public entry fun purchase_product_gacha(
        from: &signer,
        price: u64,
        product_name: String,
        tiers: vector<u64> ,
        purchase_proof_signature: vector<u8>,
    )  acquires ModuleData {
        let receiver_addr = signer::address_of(from);

        // Generate a random number between 0 and 99
        let random_number = randomness::u64_range(0, 99);

        // todo: admin can setup the rate and length 
        // Determine the tier based on the random number
        let new_tier: u64 = 0;
        // if (random_number < 50) {
        //     new_tier = tiers[0]; // Select tier at index 0
        // } else if (random_number < 85) {
        //     new_tier = tiers[1]; // Select tier at index 1
        // } else if (random_number < 98) {
        //     new_tier = tiers[2]; // Select tier at index 2
        // } else {
        //     new_tier = tiers[3]; // Select tier at index 3
        // };
        if (random_number < 50) {
            new_tier = 0; // Select tier at index 0
        } else if (random_number < 85) {
            new_tier = 1;
        } else if (random_number < 98) {
            new_tier = 2;
        } else {
            new_tier = 3;
        };

        // get the store resource and check if it is disabled 
        let module_data = borrow_global_mut<ModuleData>(@starex1);
        assert!(module_data.purchase_enabled, error::permission_denied(EPURCHASE_DISABLED));

        // verify that the `purchase_proof_signature` is valid against the admin's public key
        verify_proof_of_knowledge(
            receiver_addr,
            purchase_proof_signature,
            product_name,
            price,
            module_data.public_key
        );

        coin::transfer<AptosCoin>(from, @starex1, price);
     
        nft_starship::mint_collectible_operator(from, product_name, new_tier);

        // emit events
        event::emit(
            ProductPurchased {
                token_receiver_address: receiver_addr,
                product_name,
                price
            }
        );
    }
   
    public entry fun purchase_product(
        from: &signer,
        price: u64,
        product_name: String,
        tier: u64,
        purchase_proof_signature: vector<u8>,
        category: u64
    ) acquires ModuleData  {
        let receiver_addr = signer::address_of(from);

        // get the store resource and check if it is disabled 
        let module_data = borrow_global_mut<ModuleData>(@starex1);
        assert!(module_data.purchase_enabled, error::permission_denied(EPURCHASE_DISABLED));

        // verify that the `purchase_proof_signature` is valid against the admin's public key
        verify_proof_of_knowledge(
            receiver_addr,
            purchase_proof_signature,
            product_name,
            price,
            module_data.public_key
        );

        // todo: get tier function instead?
        // todo: change it into escrow? so it's flexible 
        coin::transfer<AptosCoin>(from, @starex1, price);

       

        // todo: make this dynamic? so operator admin have power to change the address
        // Conditional minting based on category
        if (category == 0) {
            nft_starship::mint_collectible_operator(from, product_name, tier);
        } else if (category == 1) {
            nft_asset::mint_collectible_operator(from, product_name);
        } else {
            // Handle invalid category
            // You can choose to revert or handle this case differently based on your requirements
            // For example, you can emit an error event
            // event::emit(InvalidCategory {
            //     category,
            //     product_name
            // });
        };

        // emit events
        event::emit(
            ProductPurchased {
                token_receiver_address: receiver_addr,
                product_name,
                price
            }
        );
    }

    // // ASSIGN PRODUCT
    // public entry fun set_product() acquires  {
    // }

    /// Set if purchasing is enabled for this shop contract
    public entry fun set_purchase_enabled(caller: &signer, purchase_enabled: bool) acquires ModuleData {
        let caller_address = signer::address_of(caller);
        assert!(caller_address == @admin_addr, error::permission_denied(ENOT_AUTHORIZED));
        let module_data = borrow_global_mut<ModuleData>(@starex1);
        module_data.purchase_enabled = purchase_enabled;
    }


    /// Set the public key of this shop contract
    public entry fun set_public_key(caller: &signer, pk_bytes: vector<u8>) acquires ModuleData {
        let caller_address = signer::address_of(caller);
        assert!(caller_address == @admin_addr, error::permission_denied(ENOT_AUTHORIZED));
        let module_data = borrow_global_mut<ModuleData>(@starex1);
        module_data.public_key = std::option::extract(&mut ed25519::new_validated_public_key_from_bytes(pk_bytes));
    }


    /// Verifying
    fun verify_proof_of_knowledge(
        receiver_addr: address,
        purchase_proof_signature: vector<u8>,
        product_name: String,
        price: u64,
        public_key: ValidatedPublicKey
    ) {

        let proof_challenge = PurchaseProofChallenge {
            receiver_account_address: receiver_addr,
            product_name,
            price
        };

        let signature = ed25519::new_signature_from_bytes(purchase_proof_signature);
        let unvalidated_public_key = ed25519::public_key_to_unvalidated(&public_key);
        assert!(
            ed25519::signature_verify_strict_t(&signature, &unvalidated_public_key, proof_challenge),
            error::invalid_argument(EINVALID_PROOF_OF_KNOWLEDGE)
        );
    }



    /// ==== TESTS ====
    /// ==== TESTS ====
    /// ==== TESTS ====
    /// ==== TESTS ====
    /// ==== TESTS ====
   
 
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    #[test_only]
    use aptos_framework::aptos_coin;
    // #[test_only]
    // fun setup_test(aptos: &signer, account: &signer, creator: &signer) {
    //     let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos);

    //     // create fake accounts (only for testing purposes) and deposit initial balance
    //     create_account_for_test(address_of(account));
    //     coin::register<AptosCoin>(account);

    //     let creator_addr = address_of(creator);
    //     create_account_for_test(address_of(creator));
    //     coin::register<AptosCoin>(creator);

    //     let coins = coin::mint(3 * UNIT_PRICE, &mint_cap);
    //     coin::deposit(creator_addr, coins);

    //     coin::destroy_burn_cap(burn_cap);
    //     coin::destroy_mint_cap(mint_cap);

    //     timestamp::set_time_has_started_for_testing(aptos);
    //     init_module(account);
    // }

    // // Test minting direct starship
    // #[test(aptos = @0x1, account = @starex1, creator = @0x123)]
    // fun test_shop_mint(aptos: &signer, account: &signer, creator: &signer) acquires AppCapability {
    //     setup_test(aptos, account, creator);

    //     // purchase_product_direct(creator, string::utf8(b"test-1"));
    //     purchase_product_direct(creator, string::utf8(b"test-1"));

    //     nft_starship::has_starship(creator);
    //     assert!(nft_starship::has_starship(creator) == true, 0);

    // }

}