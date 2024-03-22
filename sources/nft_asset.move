module starex1::nft_asset {
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
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::resource_account;

    friend starex1::manager_shop;
    friend starex1::manager_claim;

    // for test
    const UNIT_PRICE: u64 = 100000000;

    #[event]
    struct MintAssetEvent has drop, store {
        name: String,
        tier: u64,
        model_type: String,
    }

    struct AppCapability has key {
        extend_ref: ExtendRef,
    }

    // This struct stores an NFT collection's relevant information
    struct ModuleData has key {
        // Storing the signer capability here, so the module can programmatically sign for transactions
        signer_cap: SignerCapability,
        minting_enabled: bool,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Asset has key {
        name: String,
        tier: u64,
        model_type: String,
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef,
    }


    const APP_OBJECT_SEED: vector<u8> = b"STAREX_ASSET";
    const ASSET_COLLECTION_NAME: vector<u8> = b"STAREX ASSETS Collection";
    const ASSET_COLLECTION_DESCRIPTION: vector<u8> = b"Some utility asset";
    const ASSET_COLLECTION_URI: vector<u8> = b"https://yt3.ggpht.com/zw7AMLPxGb5ebP5FomQdqt3M9UbxGUsF_dfYErUoUY0yH2THhY_O_N5PUlECgIOiCCV0-cAl=s88-c-k-c0x00ffffff-no-rj";

    /// Action not authorized because the signer is not the admin of this module
    const ENOT_AUTHORIZED: u64 = 1;
    /// The collection minting is expired
    const ECOLLECTION_EXPIRED: u64 = 2;
    /// The collection minting is disabled
    const EMINTING_DISABLED: u64 = 3;

    // This function is only callable during publishing
    fun init_module(account: &signer) {
        let constructor_ref = &object::create_named_object(account, APP_OBJECT_SEED);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let app_signer = &object::generate_signer(constructor_ref);

        move_to(app_signer, AppCapability {
            extend_ref,
        });

        create_asset_collection(app_signer);

        // todo: add operator signer here


        // store the token data id within the module, so we can refer to it later
        // when we're minting the NFT
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(account, @source_addr);
        move_to(account, ModuleData {
            signer_cap: resource_signer_cap,
            minting_enabled: false,
        });
    }

    // Create the collection that will hold all the Assets
    // todo: change into dynamics collection for 1155
    fun create_asset_collection(creator: &signer) {
        let name = string::utf8(ASSET_COLLECTION_NAME);
        let description = string::utf8(ASSET_COLLECTION_DESCRIPTION);
        let uri = string::utf8(ASSET_COLLECTION_URI);

        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );
    }

    // admin
    public entry fun mint_collectible_admin(user: &signer, model_type: String) acquires AppCapability, ModuleData{
        let module_data = borrow_global_mut<ModuleData>(@starex1);
        assert!(module_data.minting_enabled, error::permission_denied(EMINTING_DISABLED));
        
        let user_addr = address_of(user);
        let name: String = string::utf8(ASSET_COLLECTION_NAME);
        let description: String =  string::utf8(ASSET_COLLECTION_DESCRIPTION);
        let uri: String = string::utf8(ASSET_COLLECTION_URI);
        let tier:u64 = 1;


        let constructor_ref = token::create_named_token(
            &get_app_signer(get_app_signer_address()), // or using module_data.signer_cap ?
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
        let collectible = Asset {
            name,
            tier,
            model_type,
            mutator_ref,
            burn_ref,
        };

        move_to(&token_signer, collectible);

        // Emit event for minting token
        event::emit<MintAssetEvent>(
            MintAssetEvent {
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
        let name = string::utf8(ASSET_COLLECTION_NAME);
        let uri = string::utf8(ASSET_COLLECTION_URI); // different uri
        let description = string::utf8(ASSET_COLLECTION_DESCRIPTION);
        let user_addr = address_of(user);
        let tier:u64 = 1;


        let constructor_ref = token::create_named_token(
            &get_app_signer(get_app_signer_address()),
            name,
            description,
            model_type, 
            option::none(),
            uri,
        );

        let token_signer = object::generate_signer(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);

        let collectible = Asset {
            name,
            tier,
            model_type,
            mutator_ref,
            burn_ref,
        };

        move_to(&token_signer, collectible);

        // Emit event for minting token
        event::emit<MintAssetEvent>(
            MintAssetEvent {
            name,
            tier,
            model_type,
            },
        );

        object::transfer_with_ref(object::generate_linear_transfer_ref(&transfer_ref), address_of(user));
    }

 

    // // add multiple admins
    // public entry fun add_operator(){
    //     // 
    // }

    /// Set if minting is enabled for this minting contract.
    public entry fun set_minting_enabled(caller: &signer, minting_enabled: bool) acquires ModuleData {
        let caller_address = signer::address_of(caller);
        // Abort if the caller is not the admin of this module.
        assert!(caller_address == @admin_addr, error::permission_denied(ENOT_AUTHORIZED));
        let module_data = borrow_global_mut<ModuleData>(@starex1);
        module_data.minting_enabled = minting_enabled;
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


    #[view]
    public fun has_asset(owner_addr: address): (bool) {
        let token_address = get_asset_address(&owner_addr);
        let has_asset = exists<Asset>(token_address);

        has_asset
    }

    // Get reference token object (CAN'T modify the reference)
    fun get_asset_address(creator_addr: &address): (address) {
        let token_address = token::create_token_address(
            &get_app_signer_address(),
            &string::utf8(ASSET_COLLECTION_NAME),
            &string::utf8(ASSET_COLLECTION_NAME),
        );
        token_address
    }

    
  

    /// 
    /// 
    /// 
    /// ==== TESTS ====
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

    // Test minting direct asset
    // #[test(aptos = @0x1, account = @starex1, creator = @0x123)]
    // fun test_mint_collectible(aptos: &signer, account: &signer, creator: &signer) acquires AppCapability {
    //     setup_test(aptos, account, creator);

    //     mint_collectible_direct(creator, string::utf8(b"test-1"));

    // }

}