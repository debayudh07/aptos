module 0x8e46115deae69c3ffc41c50f29c94501935467de0212a666d2f0f0b83f1574ac::MedicineStorage {
    use aptos_framework::account;
    use aptos_framework::signer;
    use aptos_framework::timestamp;
    use std::vector;
    use std::string::{Self, String};

    /// Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_MEDICINE_NOT_FOUND: u64 = 2;
    const E_INSUFFICIENT_QUANTITY: u64 = 3;
    const E_EXPIRED_MEDICINE: u64 = 4;
    const E_MEDICINE_ALREADY_EXISTS: u64 = 5;

    /// Structure to represent a medicine
    struct Medicine has store, drop, copy {
        id: u64,
        name: String,
        batch_number: String,
        expiry_timestamp: u64,  // Unix timestamp
        quantity: u64
    }

    /// Structure to store the entire inventory
    struct MedicineInventory has key {
        owner: address,
        medicines: vector<Medicine>,
        authorized_addresses: vector<address>,
        next_medicine_id: u64
    }

    /// Structure for logging events
    struct MedicineEvent has drop, store {
        medicine_id: u64,
        medicine_name: String,
        quantity: u64,
        timestamp: u64,
        action_type: String,  // "add", "remove", "update"
        actor: address
    }

    /// Events for tracking medicine inventory changes
    struct MedicineEventHandle has key {
        events: vector<MedicineEvent>
    }

    /// Initialize a new medicine inventory
    public entry fun create_inventory(owner: &signer) {
        let owner_addr = signer::address_of(owner);
        
        // Create the inventory
        let inventory = MedicineInventory {
            owner: owner_addr,
            medicines: vector::empty<Medicine>(),
            authorized_addresses: vector::empty<address>(),
            next_medicine_id: 0
        };

        // Create event handle
        let event_handle = MedicineEventHandle {
            events: vector::empty<MedicineEvent>()
        };

        // Add owner as an authorized address
        vector::push_back(&mut inventory.authorized_addresses, owner_addr);
        
        // Store the structures in the owner's account
        move_to(owner, inventory);
        move_to(owner, event_handle);
    }

    /// Check if an address is authorized
    fun is_authorized(inventory: &MedicineInventory, addr: address): bool {
        let i = 0;
        let len = vector::length(&inventory.authorized_addresses);
        
        while (i < len) {
            if (vector::borrow(&inventory.authorized_addresses, i) == &addr) {
                return true
            };
            i = i + 1;
        };
        
        false
    }

    /// Add a new authorized address
    public entry fun add_authorized_address(
        account: &signer,
        inventory_owner: address,
        new_address: address
    ) acquires MedicineInventory {
        let inventory = borrow_global_mut<MedicineInventory>(inventory_owner);
        let account_addr = signer::address_of(account);
        
        // Only the owner can add authorized addresses
        assert!(account_addr == inventory.owner, E_NOT_AUTHORIZED);
        
        // Add the new authorized address if not already present
        if (!is_authorized(inventory, new_address)) {
            vector::push_back(&mut inventory.authorized_addresses, new_address);
        };
    }

    /// Add a new medicine to the inventory
    public entry fun add_medicine(
        account: &signer,
        inventory_owner: address,
        name: vector<u8>,
        batch_number: vector<u8>,
        expiry_timestamp: u64,
        quantity: u64
    ) acquires MedicineInventory, MedicineEventHandle {
        let inventory = borrow_global_mut<MedicineInventory>(inventory_owner);
        let account_addr = signer::address_of(account);
        
        // Check authorization
        assert!(is_authorized(inventory, account_addr), E_NOT_AUTHORIZED);
        
        // Create the new medicine
        let name_str = string::utf8(name);
        let batch_str = string::utf8(batch_number);
        let medicine_id = inventory.next_medicine_id;
        
        let medicine = Medicine {
            id: medicine_id,
            name: name_str,
            batch_number: batch_str,
            expiry_timestamp,
            quantity
        };
        
        // Add to inventory
        vector::push_back(&mut inventory.medicines, medicine);
        inventory.next_medicine_id = medicine_id + 1;
        
        // Log event
        let event_handle = borrow_global_mut<MedicineEventHandle>(inventory_owner);
        vector::push_back(&mut event_handle.events, MedicineEvent {
            medicine_id,
            medicine_name: name_str,
            quantity,
            timestamp: timestamp::now_seconds(),
            action_type: string::utf8(b"add"),
            actor: account_addr
        });
    }

    /// Update medicine quantity (can be used to both add or remove)
    public entry fun update_medicine_quantity(
        account: &signer,
        inventory_owner: address,
        medicine_id: u64,
        new_quantity: u64
    ) acquires MedicineInventory, MedicineEventHandle {
        let inventory = borrow_global_mut<MedicineInventory>(inventory_owner);
        let account_addr = signer::address_of(account);
        
        // Check authorization
        assert!(is_authorized(inventory, account_addr), E_NOT_AUTHORIZED);
        
        // Find and update the medicine
        let i = 0;
        let len = vector::length(&inventory.medicines);
        let medicine_idx = len;
        
        while (i < len) {
            let medicine = vector::borrow(&inventory.medicines, i);
            if (medicine.id == medicine_id) {
                medicine_idx = i;
                break
            };
            i = i + 1;
        };
        
        // Ensure medicine exists
        assert!(medicine_idx < len, E_MEDICINE_NOT_FOUND);
        
        // Update quantity
        let medicine = vector::borrow_mut(&mut inventory.medicines, medicine_idx);
        let old_quantity = medicine.quantity;
        medicine.quantity = new_quantity;
        
        // Log event
        let event_handle = borrow_global_mut<MedicineEventHandle>(inventory_owner);
        vector::push_back(&mut event_handle.events, MedicineEvent {
            medicine_id,
            medicine_name: medicine.name,
            quantity: new_quantity,
            timestamp: timestamp::now_seconds(),
            action_type: string::utf8(b"update"),
            actor: account_addr
        });
    }

    /// Remove medicine from inventory (when completely depleted or expired)
    public entry fun remove_medicine(
        account: &signer,
        inventory_owner: address,
        medicine_id: u64
    ) acquires MedicineInventory, MedicineEventHandle {
        let inventory = borrow_global_mut<MedicineInventory>(inventory_owner);
        let account_addr = signer::address_of(account);
        
        // Check authorization
        assert!(is_authorized(inventory, account_addr), E_NOT_AUTHORIZED);
        
        // Find the medicine
        let i = 0;
        let len = vector::length(&inventory.medicines);
        let medicine_idx = len;
        let medicine_name = string::utf8(b"");
        
        while (i < len) {
            let medicine = vector::borrow(&inventory.medicines, i);
            if (medicine.id == medicine_id) {
                medicine_idx = i;
                medicine_name = medicine.name;
                break
            };
            i = i + 1;
        };
        
        // Ensure medicine exists
        assert!(medicine_idx < len, E_MEDICINE_NOT_FOUND);
        
        // Remove medicine
        let removed_medicine = vector::remove(&mut inventory.medicines, medicine_idx);
        
        // Log event
        let event_handle = borrow_global_mut<MedicineEventHandle>(inventory_owner);
        vector::push_back(&mut event_handle.events, MedicineEvent {
            medicine_id,
            medicine_name,
            quantity: 0,
            timestamp: timestamp::now_seconds(),
            action_type: string::utf8(b"remove"),
            actor: account_addr
        });
    }

    /// Check if a medicine has expired
    public fun is_expired(medicine: &Medicine): bool {
        medicine.expiry_timestamp < timestamp::now_seconds()
    }

    /// View medicine details (returns boolean success and medicine details)
    public fun get_medicine_details(
        inventory_owner: address,
        medicine_id: u64
    ): (bool, Medicine) acquires MedicineInventory {
        let inventory = borrow_global<MedicineInventory>(inventory_owner);
        
        let i = 0;
        let len = vector::length(&inventory.medicines);
        
        while (i < len) {
            let medicine = vector::borrow(&inventory.medicines, i);
            if (medicine.id == medicine_id) {
                return (true, *medicine)
            };
            i = i + 1;
        };
        
        // Return default values if medicine not found
        let default_medicine = Medicine {
            id: 0,
            name: string::utf8(b""),
            batch_number: string::utf8(b""),
            expiry_timestamp: 0,
            quantity: 0
        };
        
        (false, default_medicine)
    }

    /// Check if a specific medicine exists in inventory
    public fun medicine_exists(
        inventory_owner: address,
        medicine_id: u64
    ): bool acquires MedicineInventory {
        let (exists, _) = get_medicine_details(inventory_owner, medicine_id);
        exists
    }
}