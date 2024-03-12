///
module starex1::manager_shop {
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event;
    use aptos_framework::object;
    use starex1::nft_starship::{Self, StarShip};
    use std::string::{Self, String};

    // use starex1::nft_asset::{Self, };
    // use starex1::nft_gacha::{Self, };


    // // Tokens require a signer to create, so this is the signer for the collection
    // struct CollectionCapability has key {
    //     capability: SignerCapability,
    //     burn_signer_capability: SignerCapability,
    // }

    // // events
    // const APP_SIGNER_CAPABILITY_SEED: vector<u8> = b"APP_SIGNER_CAPABILITY";
    // const BURN_SIGNER_CAPABILITY_SEED: vector<u8> = b"BURN_SIGNER_CAPABILITY";

    // // This function is only callable during publishing
    // fun init_module(account: &signer) {
    //     let (token_resource, token_signer_cap) = account::create_resource_account(
    //         account,
    //         APP_SIGNER_CAPABILITY_SEED,
    //     );
        
    //     let (_, burn_signer_capability) = account::create_resource_account(
    //         account,
    //         BURN_SIGNER_CAPABILITY_SEED,
    //     );

    //     move_to(account, CollectionCapability {
    //         capability: token_signer_cap,
    //         burn_signer_capability,
    //     });

    //     move_to(account, MintAptogotchiEvents {
    //         mint_aptogotchi_events: account::new_event_handle<MintAptogotchiEvent>(account),
    //     });

    //     create_aptogotchi_collection(&token_resource);
    //     create_accessory_collection(&token_resource);
    // }


    // public friend -> mint
    // pay with coins
    // public entry fun purchase_product(
    //     from: &signer,
    //     model_type: String
    // ) acquires StarShip {
    //     // use number
    //     // model_type: String
    //     nft_starship::mint_collectible_operator(from, model_type);
    // }

    // test without friend function
    public entry fun purchase_product_direct(
        from: &signer,
        model_type: String
    )  {
        // use number
        // model_type: String
        nft_starship::mint_collectible_direct(from, model_type);
    }

    /// 
    /// 
    /// 
    /// 
    /// 
    /// 
    /// 
    /// 
    /// ==== TESTS ====
    /// 
    /// 
    /// 
    /// 
    /// 
    /// 
    /// 
    /// 
 
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    #[test_only]
    use aptos_framework::aptos_coin;
    #[test_only]
    fun setup_test(aptos: &signer, account: &signer, creator: &signer) {
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos);

        // create fake accounts (only for testing purposes) and deposit initial balance
        create_account_for_test(address_of(account));
        coin::register<AptosCoin>(account);

        let creator_addr = address_of(creator);
        create_account_for_test(address_of(creator));
        coin::register<AptosCoin>(creator);

        let coins = coin::mint(3 * UNIT_PRICE, &mint_cap);
        coin::deposit(creator_addr, coins);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        timestamp::set_time_has_started_for_testing(aptos);
        init_module(account);
    }

    // Test minting direct starship
    #[test(aptos = @0x1, account = @starex1, creator = @0x123)]
    fun test_shop_mint(aptos: &signer, account: &signer, creator: &signer) acquires AppCapability {
        setup_test(aptos, account, creator);

        // purchase_product_direct(creator, string::utf8(b"test-1"));
        purchase_product_direct(creator, string::utf8(b"test-1"));
    }

}