module 0x8e46115deae69c3ffc41c50f29c94501935467de0212a666d2f0f0b83f1574ac::SimpleVoting {
    use aptos_framework::account;
    use aptos_framework::signer;
    use std::vector;

    /// Error codes
    const E_ALREADY_VOTED: u64 = 1;
    const E_VOTING_CLOSED: u64 = 2;

    /// Structure to store voting information
    struct VotingPoll has key {
        creator: address,
        options: vector<vector<u8>>,
        votes: vector<u64>,
        voters: vector<address>,
        is_active: bool
    }

    /// Creates a new voting poll with the specified options
    public entry fun create_poll(
        creator: &signer,
        options: vector<vector<u8>>
    ) {
        let creator_addr = signer::address_of(creator);
        let options_count = vector::length(&options);
        let votes = vector::empty<u64>();
        
        // Initialize vote count for each option to 0
        let i = 0;
        while (i < options_count) {
            vector::push_back(&mut votes, 0);
            i = i + 1;
        };

        let poll = VotingPoll {
            creator: creator_addr,
            options,
            votes,
            voters: vector::empty<address>(),
            is_active: true
        };

        move_to(creator, poll);
    }

    /// Cast a vote for a specific option in the poll
    public entry fun vote(
        voter: &signer,
        poll_creator: address,
        option_index: u64
    ) acquires VotingPoll {
        let poll = borrow_global_mut<VotingPoll>(poll_creator);
        let voter_addr = signer::address_of(voter);
        
        // Check if poll is still active
        assert!(poll.is_active, E_VOTING_CLOSED);
        
        // Check if voter has already voted
        let i = 0;
        let voters_len = vector::length(&poll.voters);
        while (i < voters_len) {
            assert!(vector::borrow(&poll.voters, i) != &voter_addr, E_ALREADY_VOTED);
            i = i + 1;
        };
        
        // Record the vote
        let current_votes = vector::borrow_mut(&mut poll.votes, option_index);
        *current_votes = *current_votes + 1;
        vector::push_back(&mut poll.voters, voter_addr);
    }
}