///
module starex1::nft_starship {
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event;
    use aptos_framework::object::{Self, ExtendRef};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use std::error;
    use std::option;
    use std::signer::address_of;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::timestamp;
    friend starex1::manager_shop;
    // friend starex1:manager_claim;



    // for test
    const UNIT_PRICE: u64 = 100000000;

    #[event]
    struct MintStarShipEvent has drop, store {
        name: String,
        tier: u64,
        model_type: String,
    }

    struct AppCapability has key {
        extend_ref: ExtendRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct StarShip has key {
        name: String,
        tier: u64,
        model_type: String,
        // metadata:
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef,
    }

    // events
    const APP_OBJECT_SEED: vector<u8> = b"STARSHIP";
    const STARSHIP_COLLECTION_NAME: vector<u8> = b"STARSHIP Collection";
    const STARSHIP_COLLECTION_DESCRIPTION: vector<u8> = b"Race through the cosmos, collect unique spaceship NFTs, and dominate the stars";
    const STARSHIP_COLLECTION_URI: vector<u8> = b"https://starex-demo-crosschain.vercel.app/assets/ship2-XzJSueHd.png";


    // This function is only callable during publishing
    fun init_module(account: &signer) {
       let constructor_ref = &object::create_named_object(account, APP_OBJECT_SEED);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let app_signer = &object::generate_signer(constructor_ref);

        move_to(app_signer, AppCapability {
            extend_ref,
        });

        create_starship_collection(app_signer);


        // todo: add operator signer here
    }

    // Create the collection that will hold all the Starships
    // todo: change into dynamics collection for 1155
    fun create_starship_collection(creator: &signer) {
        let name = string::utf8(STARSHIP_COLLECTION_NAME);
        let description = string::utf8(STARSHIP_COLLECTION_DESCRIPTION);
        let uri = string::utf8(STARSHIP_COLLECTION_URI);

        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );
    }

    // test mint public
    public entry fun mint_collectible_direct(user: &signer, model_type: String ) acquires AppCapability {
        let name = string::utf8(STARSHIP_COLLECTION_NAME);
        let uri = string::utf8(STARSHIP_COLLECTION_URI);
        let description = string::utf8(STARSHIP_COLLECTION_DESCRIPTION);
        let user_addr = address_of(user);
        let tier:u64 = 1; //will be randomised later 

        let constructor_ref = token::create_named_token(
            &get_app_signer(get_app_signer_address()),
            name,
            description,
            model_type, //get it from client?
            option::none(),
            uri,
        );

        let token_signer = object::generate_signer(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);

        // name: String,
        // tier: u64,
        // model_type: String,
        // initialize/set default struct values
        let collectible = StarShip {
            name,
            tier,
            model_type,
            mutator_ref,
            burn_ref,
        };

        move_to(&token_signer, collectible);

        // Emit event for minting token
        event::emit<MintStarShipEvent>(
            MintStarShipEvent {
            name,
            tier,
            model_type,
            },
        );

        object::transfer_with_ref(object::generate_linear_transfer_ref(&transfer_ref), address_of(user));
    }


    // update with admin operator?
    // friends because of operator
    // cross call
    public(friend) fun mint_collectible_operator(user: &signer, model_type: String) acquires AppCapability  {
        let name = string::utf8(STARSHIP_COLLECTION_NAME);
        let uri = string::utf8(STARSHIP_COLLECTION_URI);
        let description = string::utf8(STARSHIP_COLLECTION_DESCRIPTION);
        let user_addr = address_of(user);
        let tier:u64 = 1; //will be randomised later 

        let constructor_ref = token::create_named_token(
            &get_app_signer(get_app_signer_address()),
            name,
            description,
            model_type, //get it from client?
            option::none(),
            uri,
        );

        // make it 1155?
        // primary_fungible_store::create_primary_store_enabled_fungible_asset(
        //     new_armor_type_constructor_ref,
        //     maximum_number_of_armors,
        //     armor_type,
        //     "ARMOR",
        //     0, // Armor cannot be divided so decimals is 0,
        //     "https://mycollection.com/armor-icon.jpeg",
        //     "https://myarmor.com",
        // );

        let token_signer = object::generate_signer(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);

        // name: String,
        // tier: u64,
        // model_type: String,
        // initialize/set default struct values
        let collectible = StarShip {
            name,
            tier,
            model_type,
            mutator_ref,
            burn_ref,
        };

        move_to(&token_signer, collectible);

        // Emit event for minting token
        event::emit<MintStarShipEvent>(
            MintStarShipEvent {
            name,
            tier,
            model_type,
            },
        );

        object::transfer_with_ref(object::generate_linear_transfer_ref(&transfer_ref), address_of(user));
    }

    // private mint
    // fun _mint(){

    // mintToken private
    // has randomness resources active?
    // has type category input
    // metadata offchain?
    // tier
    // }


    // do i need operator?
    public entry fun add_operator(){
        // 
    }

    // since it's public, guess should be fine revealing it
    #[view]
    public fun get_app_signer_address(): address {
        object::create_object_address(&@starex1, APP_OBJECT_SEED)
    }
    
    #[view]
    public fun get_app_signer(app_signer_address: address): signer acquires AppCapability {
        object::generate_signer_for_extending(&borrow_global<AppCapability>(app_signer_address).extend_ref)
    }
    // #[view]
    // public fun balance_of(): signer acquires AppCapability {
    // }

    #[view]
    public fun has_starship(owner_addr: address): (bool) {
        let token_address = get_starship_address(&owner_addr);
        let has_asset = exists<StarShip>(token_address);

        has_asset
    }

    // Get reference token object (CAN'T modify the reference)
    fun get_starship_address(creator_addr: &address): (address) {
        let token_address = token::create_token_address(
            &get_app_signer_address(),
            &string::utf8(STARSHIP_COLLECTION_NAME),
            &string::utf8(STARSHIP_COLLECTION_NAME),
        );
        token_address
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
    fun test_mint_collectible(aptos: &signer, account: &signer, creator: &signer) acquires AppCapability {
        setup_test(aptos, account, creator);

        mint_collectible_direct(creator, string::utf8(b"test-1"));

    }

}