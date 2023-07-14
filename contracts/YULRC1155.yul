/**
* YULRC1155
*
* This is a basic implementation of the ERC1155 token standard written entirely in Yul.
*
* The approach used here prioritizes readability over efficiency. Variables related to calldata are prefixed with `cd`,
* storage with `s` and memory with `m` for better clarity.
*/
object "YULRC1155" {

    /**
    * Constructor
    *
    * The constructor stores the caller as the contract owner, stores the URI string passed in
    * the constructor and deploys the contract.
    */
    code {
        // The contract owner is stored in slot 0
        sstore(0, caller())

        // The URI 'https://token-cdn-domain/{id}.json' is hardcoded for storage
        sstore(3, 0x22) //  length of the URI string in storage slot 3
        sstore(4, 0x68747470733a2f2f746f6b656e2d63646e2d646f6d61696e2f7b69647d2e6a73) // first part of the URI string in storage slot 4
        sstore(5, 0x6f6e000000000000000000000000000000000000000000000000000000000000) // second part of the URI string in storage slot 5

        // The contract is deployed
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

     object "runtime" {

        code {
            // A free memory pointer is initialized at 0x00
            mstore(0x00, 0x20)

            /**
             * Storage slots
             */
            // Slot 0: `owner` address
            function sOwnerSlot() -> slot { slot := 0 }

            // Slot 1: Mapping uint256 `tokenID` => (address `account` => uint256 `balance`)
            function sBalancesSlot() -> slot { slot := 1 }

            // Slot 2: Mapping address `account` => (address `operator` => bool `approved`)
            function sOperatorApprovalsSlot() -> slot { slot := 2 }

            // Slot 3: uint256 `uri` length
            function sUriLengthSlot() -> slot { slot := 3 }

            /**
             * Dispatcher
             * 
             * Dispatches to the relevant function based on the function selector
             * extracted from the calldata (the first 4 bytes of keccak256(functionSignature)).
             */

            switch functionSelector()
            // balanceOf(address,uint256)
            case 0x00fdd58e {
                returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }
             // uri(uint256)
            case 0x0e89341c {
                uri(0) // Token id isn't used so don't bother decoding it
            }
            // balanceOfBatch(address[],uint256[])
            case 0x4e1273f4 {
                returnArray(balanceOfBatch(decodeAsAddressArray(0), decodeAsUintArray(1)))
            }
            // setApprovalForAll(address,bool)
            case 0xa22cb465 {
                setApprovalForAll(decodeAsAddress(0), decodeAsBool(1))
            }
            // isApprovedForAll(address,address)
            case 0xe985e9c5 {
                returnBool(isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1)))
            }
            // safeTransferFrom(address,address,uint256,uint256,bytes)
            case 0xf242432a {
                safeTransferFrom(
                    decodeAsAddress(0), 
                    decodeAsAddress(1), 
                    decodeAsUint(2), 
                    decodeAsUint(3), 
                    decodeAsBytes(4)
                )
            }
            // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            case 0x2eb2c2d6 {
                safeBatchTransferFrom(
                    decodeAsAddress(0), 
                    decodeAsAddress(1), 
                    decodeAsUintArray(2), 
                    decodeAsUintArray(3), 
                    decodeAsBytes(4)
                )
            }
            // mint(address,uint256,uint256,bytes)
            case 0x731133e9 {
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2), decodeAsBytes(3))
            }
            // mintBatch(address,uint256[],uint256[],bytes)
            case 0x1f7fdffa {
                mintBatch(
                    decodeAsAddress(0), 
                    decodeAsUintArray(1), 
                    decodeAsUintArray(2), 
                    decodeAsBytes(3)
                )
            }
            // burn(address,uint256,uint256)
            case 0xf5298aca {
                burn(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }
            // burnBatch(address,uint256[],uint256[])
            case 0x6b20c454 {
                burnBatch(decodeAsAddress(0), decodeAsUintArray(1), decodeAsUintArray(2))
            }
            default {
                revert(0, 0)
            }

            /**
             * This function is used to return a uint256 value to the caller of the contract.
             * It stores the value in memory and then returns the memory to the caller.
             *
             * @param value The uint256 value to return.
             */
            function returnUint(value) {
                // Store the value in memory at position 0.
                mstore(0x00, value)

                // Return the 32 bytes of memory starting at position 0 to the caller.
                // This is the standard way to return data from a contract function in Ethereum.
                return(0x00, 0x20)
            }

            /**
             * This function is used to return a boolean value to the caller of the contract.
             * It checks that the value is a valid boolean, stores the value in memory, and then returns the memory to the caller.
             *
             * @param value The boolean value to return.
             */
            function returnBool(value) {
                // Check that the value is a valid boolean (0 or 1).
                // If the value is not a valid boolean, this function will revert the transaction.
                requireValidBoolValue(value)
                
                // Store the value in memory at position 0.
                mstore(0x00, value)

                // Return the 32 bytes of memory starting at position 0 to the caller.
                return(0x00, 0x20)
            }

            /**
             * This function is used to return an array of uint256 values to the caller of the contract.
             * It calculates the start and end of the array in memory, and then returns the memory to the caller.
             *
             * @param mArrayLengthPointer A pointer to the length of the array in memory.
             */
            function returnArray(mArrayLengthPointer) {
                // Calculate the position in memory where the array starts.
                // The array starts 32 bytes before the array length.
                let mArrayOffsetPointer := sub(mArrayLengthPointer, 0x20)

                // Store the offset of the array within the response.
                // The offset is always 32 bytes because the first 32 bytes of the response are reserved for the array length.
                mstore(mArrayOffsetPointer, 0x20)
                
                // Load the length of the array from memory.
                let arrayLength := mload(mArrayLengthPointer)

                // Return the memory from the start of the array to the end of the array.
                // The start of the array is at `mArrayOffsetPointer`.
                // The end of the array is at `mArrayOffsetPointer` plus the size of the array length plus the size of the array data.
                return(mArrayOffsetPointer, add(mArrayOffsetPointer, mul(add(arrayLength, 2), 0x20)))
            }


            /**
             * This function is used to return the URI of a token.
             * The URI is stored in contract storage and is returned as a string.
             *
             * @param id The id of the token.
             */
            function uri(id) {
                // Load the length of the URI from storage.
                let uriLength := sload(sUriLengthSlot())

                // Store the offset of the URI string within the response.
                // The offset is always 32 bytes because the first 32 bytes of the response are reserved for the string length.
                mstore(0x00, 0x20)

                // Store the length of the URI string.
                mstore(0x20, uriLength)

                // Store the URI string data.
                // The URI string data is stored in storage after the URI length.
                // The URI string data is copied into memory after the URI string length.
                
                // The loop uses an index i to navigate through storage slots and memory locations. 
                // Starting at 1, i points to the storage slot following the one that holds the URI length. 
                // The URI data is read from this storage slot and written into memory. 
                // In memory, the data is placed in a location determined by add(0x20, mul(i, 0x20)), 
                // which ensures the data comes after the memory slot where the URI's length is saved. 
                // With each iteration, i increases by 1, moving the index to the next storage slot and corresponding memory location.

                // div(uriLength, 0x20): This divides the length of the URI string by 32 (0x20 in hexadecimal). 
                // Each storage slot in Ethereum can hold 32 bytes of data, so this calculates how many storage slots are needed to store the URI string.
                // add(2, div(uriLength, 0x20)): This adds 2 to the result of the division. 
                // The reason for adding 2 is that the first storage slot is reserved for storing the length of the URI string, 
                // and i is initialized to 1, so adding 2 aligns the loop with these offsets.
                for { let i := 1 } lt(i, add(2, div(uriLength, 0x20))) { i := add(i, 1) }
                {
                    let dataSlot := add(sUriLengthSlot(), i) // This points to the location in storage where the current part of the URI string is stored.
                    let uriData := sload(dataSlot)

                    mstore(add(0x20, mul(i, 0x20)), uriData)
                }

                // Return the URI string offset, length, and data.
                return(0x00, add(0x40, mul(uriLength, 0x20)))
            }
            
            /**
             * This function is used to return the balance of a token for a specific account.
             * The balance is stored in contract storage and is returned as a uint256.
             *
             * @param account The address of the account.
             * @param id The id of the token.
             * @return accountBalance The balance of the token for the account.
             */
            function balanceOf(account, id) -> accountBalance {
                // Check that the account address is not the zero address.
                // If the account address is the zero address, this function will revert the transaction.
                requireNonZeroAddress(account)

                // Calculate the storage key for the balance of the token for the account.
                let sBalanceKey := sGenerateBalanceKey(account, id)

                // Load the balance from storage.
                accountBalance := sload(sBalanceKey)
            }

            /**
             * This function is used to return the balances of multiple tokens for multiple accounts.
             * The balances are stored in contract storage and are returned as an array of uint256 values.
             *
             * @param mAccountsArrayLengthPointer A pointer to the length of the accounts array in memory.
             * @param mIdsArrayLengthPointer A pointer to the length of the ids array in memory.
             * @return mBalancesArrayLengthPointer A pointer to the balances array in memory.
             * The function returns the balances of the given accounts for the corresponding token IDs. 
             * The balances are returned as an array in memory. 
             * The function returns a pointer to the start of this balances array (mBalancesArrayLengthPointer).
             */

            function balanceOfBatch(mAccountsArrayLengthPointer, mIdsArrayLengthPointer) -> mBalancesArrayLengthPointer {
                // Load the lengths of the accounts and ids arrays from memory.
                let accountsArrayLength := mload(mAccountsArrayLengthPointer)
                let idsArrayLength := mload(mIdsArrayLengthPointer)

                // Check that the lengths of the accounts and ids arrays are equal.
                // If the lengths are not equal, this function will revert the transaction.
                requireEqual(accountsArrayLength, idsArrayLength)

                // Get the current free memory pointer. This is where we'll store the balances array.
                let mFreeMemoryPointer := mload(0x00)
                let mBalancesArrayLengthPointer_ := mFreeMemoryPointer

                // Store the length of the balances array in memory.
                mStoreWordAndUpdateFreeMemoryPointer(mBalancesArrayLengthPointer_, accountsArrayLength)

                // For each account, load its token id balance into balances array
                // i is less than accountsArrayLength + 1
                for { let i := 1 } lt(i, add(accountsArrayLength, 1)) { i := add(i, 1) }
                {
                    // Get account and id at this index position
                    let account := mload(add(mAccountsArrayLengthPointer, mul(i, 0x20)))
                    requireValidAddress(account)
                    let id := mload(add(mIdsArrayLengthPointer, mul(i, 0x20)))

                    // Get account balance
                    let accountBalance := balanceOf(account, id)

                    mStoreWordAndUpdateFreeMemoryPointer(mload(0x00), accountBalance)
                }

                mBalancesArrayLengthPointer := mBalancesArrayLengthPointer_
            }

            /**
             * This function is used to set whether an operator is approved to manage all of the caller's tokens.
             * The approval is stored in contract storage.
             *
             * @param operator The address of the operator.
             * @param approved Whether the operator is approved.
             */
            function setApprovalForAll(operator, approved) {
                // Check that the caller is not the same as the operator.
                // If the caller is the same as the operator, this function will revert the transaction.
                requireNotEqual(caller(), operator)

                // Calculate the storage key for the operator approval.
                let sOperatorApprovalKey := sGenerateOperatorApprovalKey(caller(), operator)

                // Store the approval in storage.
                sstore(sOperatorApprovalKey, approved)

                // Emit an ApprovalForAll event.
                emitApprovalForAll(caller(), operator, approved)
            }

            /**
             * This function is used to check whether an operator is approved to manage all of an account's tokens.
             * The approval is stored in contract storage and is returned as a boolean.
             *
             * @param account The address of the account.
             * @param operator The address of the operator.
             * @return isApproved Whether the operator is approved.
             */
            function isApprovedForAll(account, operator) -> isApproved {
                 // Calculate the storage key for the operator approval.
                let sOperatorApprovalKey := sGenerateOperatorApprovalKey(account, operator)

                // Load the approval from storage.
                isApproved := sload(sOperatorApprovalKey)
            }

            /**
             * This function is used to transfer a certain amount of a token from one account to another.
             * The balances are stored in contract storage and are updated by this function.
             *
             * @param from The address of the account to transfer from.
             * @param to The address of the account to transfer to.
             * @param id The id of the token to transfer.
             * @param amount The amount of the token to transfer.
             */
            function _transfer(from, to, id, amount) {
            }


            /**
             * This function is used to safely transfer a certain amount of a token from one account to another.
             * The function checks if the recipient is a contract and if so, calls its `onERC1155Received` function.
             * The function also emits a `TransferSingle` event.
             *
             * @param from The address of the account to transfer from.
             * @param to The address of the account to transfer to.
             * @param id The id of the token to transfer.
             * @param amount The amount of the token to transfer.
             * @param data Additional data to pass to the `onERC1155Received` function if the recipient is a contract.
             */
            function safeTransferFrom(from, to, id, amount, data) {
            }

            /**
             * This function is used to safely transfer multiple tokens from one account to another.
             * The function checks if the recipient is a contract and if so, calls its `onERC1155BatchReceived` function.
             * The function also emits a `TransferBatch` event.
             *
             * @param from The address of the account to transfer from.
             * @param to The address of the account to transfer to.
             * @param mIdsArrayLengthPointer A pointer to the length of the ids array in memory.
             * @param mAmountsArrayLengthPointer A pointer to the length of the amounts array in memory.
             * @param data Additional data to pass to the `onERC1155BatchReceived` function if the recipient is a contract.
             */
            function safeBatchTransferFrom(
                from, 
                to, 
                mIdsArrayLengthPointer, 
                mAmountsArrayLengthPointer, 
                data
            ) {
            }

            /**
             * This function is used to mint a certain amount of a token for an account.
             * The balance is stored in contract storage and is updated by this function.
             *
             * @param to The address of the account to mint the token for.
             * @param id The id of the token to mint.
             * @param amount The amount of the token to mint.
             */
            function _mint(to, id, amount) {
            }

            /**
             * This function is used to mint a certain amount of a token for an account and emit a `TransferSingle` event.
             * The function calls the `_mint` function to mint the token and then emits the event.
             *
             * @param to The address of the account to mint the token for.
             * @param id The id of the token to mint.
             * @param amount The amount of the token to mint.
             * @param data Additional data to include in the `TransferSingle` event.
             */
            function mint(to, id, amount, data) {
            }

            /**
             * This function is used to mint multiple tokens for an account and emit a `TransferBatch` event.
             * The function calls the `_mint` function to mint each token and then emits the event.
             *
             * @param toAccount The address of the account to mint the tokens for.
             * @param mIdsArrayLengthPointer A pointer to the length of the ids array in memory.
             * @param mAmountsArrayLengthPointer A pointer to the length of the amounts array in memory.
             * @param data Additional data to include in the `TransferBatch` event.
             */
            function mintBatch(
                toAccount, 
                mIdsArrayLengthPointer, 
                mAmountsArrayLengthPointer,
                data
            ) {
            }

            /**
             * This function is used to burn a certain amount of a token from an account.
             * The balance is stored in contract storage and is updated by this function.
             *
             * @param from The address of the account to burn the token from.
             * @param id The id of the token to burn.
             * @param amount The amount of the token to burn.
             */
            function _burn(from, id, amount) {
            }

            /**
             * This function is used to burn a certain amount of a token from an account and emit a `TransferSingle` event.
             * The function calls the `_burn` function to burn the token and then emits the event.
             *
             * @param from The address of the account to burn the token from.
             * @param id The id of the token to burn.
             * @param amount The amount of the token to burn.
             */
            function burn(from, id, amount) {
            }

            /**
             * This function is used to burn multiple tokens from an account and emit a `TransferBatch` event.
             * The function calls the `_burn` function to burn each token and then emits the event.
             *
             * @param from The address of the account to burn the tokens from.
             * @param mIdsArrayLengthPointer A pointer to the length of the ids array in memory.
             * @param mAmountsArrayLengthPointer A pointer to the length of the amounts array in memory.
             */
            function burnBatch(from, mIdsArrayLengthPointer, mAmountsArrayLengthPointer) {
            }

            /**
             * This function is used to call the `onERC1155Received` function on a contract.
             * It builds the calldata for the function call, and then makes the call using the `call` opcode.
             * If the call fails, or the returned value is not the expected value, this function will revert the transaction.
             *
             * @param from The address of the sender of the tokens.
             * @param to The address of the recipient of the tokens.
             * @param id The id of the token.
             * @param amount The amount of the token.
             * @param data Additional data to pass to the `onERC1155Received` function.
             */
            function callOnERC1155Received(from, to, id, amount, data) {
               
            }

            /**
             * This function is used to call the `onERC1155BatchReceived` function on a contract.
             * It builds the calldata for the function call, and then makes the call using the `call` opcode.
             * If the call fails, or the returned value is not the expected value, this function will revert the transaction.
             *
             * @param from The address of the sender of the tokens.
             * @param to The address of the recipient of the tokens.
             * @param mIdsArrayLengthPointer A pointer to the start of the array of token ids.
             * @param mAmountsArrayLengthPointer A pointer to the start of the array of token amounts.
             * @param data Additional data to pass to the `onERC1155BatchReceived` function.
             */
            function callOnERC1155BatchReceived(
                from, 
                to, 
                mIdsArrayLengthPointer, 
                mAmountsArrayLengthPointer, 
                data
            ) {
            }

            /**
             * Calldata decoding functions
             */
            function functionSelector() -> selector {
                // Shift right by 28 bytes leaving the first 4 bytes used by selector
                selector := shr(0xE0, calldataload(0))
            }

            /**
             * This function is used to decode an Ethereum address from the calldata.
             * Ethereum addresses are represented as 20-byte values, but they are often
             * passed around as 32-byte uint256 values for consistency and convenience.
             * This function takes an offset into the calldata, decodes the next 32 bytes
             * as a uint256, checks that it's a valid Ethereum address, and then returns
             * it.
             *
             * @param cdOffset The offset into the calldata where the address is located.
             * @return value The decoded Ethereum address.
             */
            function decodeAsAddress(cdOffset) -> value {
                // Decode the next 32 bytes of calldata at the given offset as a uint256.
                let uintAtOffset := decodeAsUint(cdOffset)
                
                // Check that the decoded uint256 is a valid Ethereum address. Ethereum
                // addresses are 20 bytes, so they must be less than 2^160. This function
                // will revert the transaction if the value is not a valid address.
                requireValidAddress(uintAtOffset)

                // If the value is a valid address, return it.
                value := uintAtOffset
            }

            function decodeAsAddressArray(cdOffset) -> value {
                value := decodeAsArray(cdOffset)
            }

            function decodeAsUintArray(cdOffset) -> value {
                value := decodeAsArray(cdOffset)
            }

            function decodeAsUint(cdOffset) -> value {
                // Calculate the position in the calldata where the uint256 value is located.
                // The `4` accounts for the 4-byte function selector at the start of the calldata.
                // The `mul(cdOffset, 0x20)` part is converting the offset from a 32-byte word
                // offset to a byte offset.
                let cdPosition := add(4, mul(cdOffset, 0x20))
                requireValidCalldataPosition(cdPosition)

                value := calldataload(cdPosition)
            }

            /**
             * This function is used to decode a boolean value from the calldata.
             * Boolean values are represented as single bytes, but they are often
             * passed around as 32-byte uint256 values for consistency and convenience.
             * This function takes an offset into the calldata, decodes the next 32 bytes
             * as a uint256, checks that it's a valid boolean value (0 or 1), and then returns
             * it.
             *
             * @param cdOffset The offset into the calldata where the boolean value is located.
             * @return value The decoded boolean value.
             */
            function decodeAsBool(cdOffset) -> value {
                // Calculate the position in the calldata where the boolean value is located.
                // The `4` accounts for the 4-byte function selector at the start of the calldata.
                // The `mul(cdOffset, 0x20)` part is converting the offset from a 32-byte word
                // offset to a byte offset.
                let cdPosition := add(4, mul(cdOffset, 0x20))
                
                // Check that the calculated position is within the bounds of the calldata.
                // This function will revert the transaction if the position is out of bounds.
                requireValidCalldataPosition(cdPosition)

                // Load the 32-byte value at the calculated position in the calldata.
                let valueAtPosition := calldataload(cdPosition)
                
                // Check that the loaded value is a valid boolean value (0 or 1).
                // This function will revert the transaction if the value is not a valid boolean.
                requireValidBoolValue(valueAtPosition)

                // If the value is a valid boolean, return it.
                value := valueAtPosition
            }

            /**
             * This function is used to decode an array of uint256 values from the calldata.
             * The array is represented in the calldata as a length followed by the array elements.
             * This function takes an offset into the calldata, decodes the array, and then returns
             * a pointer to the array in memory.
             *
             * @param cdOffset The offset into the calldata where the array is located.
             * @return mArrayLengthPointer A pointer to the decoded array in memory.
             */
            function decodeAsArray(cdOffset) -> mArrayLengthPointer {
                // Calculate the position in the calldata where the array is located.
                // The `4` accounts for the 4-byte function selector at the start of the calldata.
                // The `mul(cdOffset, 0x20)` part is converting the offset from a 32-byte word
                // offset to a byte offset.
                let cdOffsetOfArrayPosition := add(4, mul(cdOffset, 0x20))
                
                // Load the position of the array from the calldata.
                let cdOffsetOfArray := calldataload(cdOffsetOfArrayPosition)
                
                // Calculate the position in the calldata where the array length is located.
                // The array length is located at the start of the array.
                let cdArrayLengthPosition := add(4, cdOffsetOfArray)
                
                // Load the length of the array from the calldata.
                let arrayLength := calldataload(cdArrayLengthPosition)

                // Get the current free memory pointer. This is where we'll store the array.
                let mArrayLengthPointer_ := mload(0x00)
                
                // Store the length of the array in memory.
                mstore(mArrayLengthPointer_, arrayLength)

                // If the array has elements, copy them into memory.
                if arrayLength {
                    // Copy the array data from the calldata into memory.
                    // The array data starts after the array length in the calldata.
                    // The array data is copied into memory after the array length.
                    calldatacopy(add(mArrayLengthPointer_, 0x20), add(cdArrayLengthPosition, 0x20), mul(arrayLength, 0x20))

                    // Increment the free memory pointer to after the array.
                    // This ensures that the next time we store something in memory, we don't overwrite the array.
                    mIncrementFreeMemoryPointerBy(mArrayLengthPointer_, add(0x20, mul(arrayLength, 0x20)))
                }
                
                // Return a pointer to the array in memory.
                mArrayLengthPointer := mArrayLengthPointer_
            }

            /**
             * This function is used to decode a bytes array from the calldata.
             * The bytes array is represented in the calldata as a length followed by the array elements.
             * This function takes an offset into the calldata, decodes the bytes array, and then returns
             * a pointer to the bytes array in memory.
             *
             * @param cdOffset The offset into the calldata where the bytes array is located.
             * @return mBytesLengthPointer A pointer to the decoded bytes array in memory.
             */
            function decodeAsBytes(cdOffset) -> mBytesLengthPointer {
                // Calculate the position in the calldata where the bytes array is located.
                // The `4` accounts for the 4-byte function selector at the start of the calldata.
                // The `mul(cdOffset, 0x20)` part is converting the offset from a 32-byte word
                // offset to a byte offset.
                let cdOffsetOfBytesPosition := add(4, mul(cdOffset, 0x20))
                
                // Load the position of the bytes array from the calldata.
                let cdOffsetOfBytes := calldataload(cdOffsetOfBytesPosition)
                
                // Calculate the position in the calldata where the bytes array length is located.
                // The bytes array length is located at the start of the bytes array.
                let cdBytesLengthPosition := add(4, cdOffsetOfBytes)
                
                // Load the length of the bytes array from the calldata.
                let bytesLength := calldataload(cdBytesLengthPosition)

                // Get the current free memory pointer. This is where we'll store the bytes array.
                let mBytesLengthPointer_ := mload(0x00)
                
                // Store the length of the bytes array in memory.
                mStoreWordAndUpdateFreeMemoryPointer(mBytesLengthPointer_, bytesLength)

                // If the bytes array has elements, copy them into memory.
                if bytesLength {
                    // Calculate the number of 32-byte words needed to store the bytes array.
                    let bytesWords := add(div(bytesLength, 0x20), 1)

                    // Copy the bytes array data from the calldata into memory.
                    // The bytes array data starts after the bytes array length in the calldata.
                    // The bytes array data is copied into memory after the bytes array length.
                    calldatacopy(add(mBytesLengthPointer_, 0x20), add(cdBytesLengthPosition, 0x20), bytesWords)

                    // Increment the free memory pointer to after the bytes array data.
                    // This ensures that the next time we store something in memory, we don't overwrite the bytes array.
                    mIncrementFreeMemoryPointerBy(mBytesLengthPointer_, add(0x20, bytesWords))
                }
                
                // Return a pointer to the bytes array in memory.
                mBytesLengthPointer := mBytesLengthPointer_
            }

            /**
             * ERC1155 Events
             */
            
            
            /**
             * This function is used to emit the `TransferSingle` event, which is part of the ERC1155 standard.
             * The `TransferSingle` event is emitted when a single token is transferred, either by a `safeTransferFrom` or a `safeBatchTransferFrom` operation.
             *
             * @param operator The address executing the function.
             * @param from The address of the sender of the token.
             * @param to The address of the recipient of the token.
             * @param id The id of the token.
             * @param value The amount of the token.
             */
            function emitTransferSingle(operator, from, to, id, value) {
                // The keccak256 hash of the `TransferSingle` event signature.
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62

                // Store the `id` and `value` in memory.
                mstore(0x00, id)
                mstore(0x20, value)

                /**
                 * The `TransferSingle` event.
                 * 
                 * event TransferSingle
                 * 
                 * address indexed `_operator`
                 * address indexed `_from`
                 * address indexed `_to`
                 * uint256 `_id`
                 * uint256 `_value`
                 */
                log4(0x00, 0x40, signatureHash, operator, from, to)
            }

            /**
             * This function is used to emit the `TransferBatch` event, which is part of the ERC1155 standard.
             * The `TransferBatch` event is emitted when multiple tokens are transferred, either by a `safeBatchTransferFrom` operation.
             *
             * @param operator The address executing the function.
             * @param from The address of the sender of the tokens.
             * @param to The address of the recipient of the tokens.
             * @param mIdsArrayLengthPointer The pointer to the memory location where the array of token ids is stored.
             * @param mAmountsArrayLengthPointer The pointer to the memory location where the array of token amounts is stored.
             */
            function emitTransferBatch(
                operator, 
                from, 
                to, 
                mIdsArrayLengthPointer, 
                mAmountsArrayLengthPointer
            ) {
                // The keccak256 hash of the `TransferBatch` event signature.
                let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb

                // Get the current free memory pointer.
                let mFreeMemoryPointer := mload(0x00)
                let mIdsArrayOffsetPointer := mFreeMemoryPointer
                let idsArrayLength := mload(mIdsArrayLengthPointer)
                let amountsArrayLength := mload(mAmountsArrayLengthPointer)
                
                // Store the offsets of the `_ids` and `_values` arrays in memory.
                mStoreWordAndUpdateFreeMemoryPointer(mIdsArrayOffsetPointer, 0x40)
                let amountsArrayOffset := add(mul(idsArrayLength, 0x20), 0x60)
                mStoreWordAndUpdateFreeMemoryPointer(mload(0x00), amountsArrayOffset)

                // Store the `_ids` array in memory.
                mStoreWordAndUpdateFreeMemoryPointer(mload(0x00), idsArrayLength)
                mStoreArrayToFreeMemory(mload(0x00), mIdsArrayLengthPointer)

                // Store the `_values` array in memory.
                mStoreWordAndUpdateFreeMemoryPointer(mload(0x00), amountsArrayLength)
                mStoreArrayToFreeMemory(mload(0x00), mAmountsArrayLengthPointer)

                /**
                 * The `TransferBatch` event.
                 * 
                 * event TransferBatch
                 * 
                 * address indexed `_operator`
                 * address indexed `_from`
                 * address indexed `_to`
                 * uint256[] `_ids`
                 * uint256[] `_values`
                 */
                log4(
                    mIdsArrayOffsetPointer, 
                    add(add(amountsArrayOffset, 0x20), mul(amountsArrayLength, 0x20)), 
                    signatureHash, 
                    operator,
                    from, 
                    to
                )
            }

            /**
             * This function is used to emit the `ApprovalForAll` event, which is part of the ERC1155 standard.
             * The `ApprovalForAll` event is emitted when the approval status of an operator for a specific owner is changed.
             *
             * @param owner The address of the owner.
             * @param operator The address of the operator.
             * @param approved The approval status. True if the operator is approved, false otherwise.
             */
            function emitApprovalForAll(owner, operator, approved) {
                // The keccak256 hash of the `ApprovalForAll` event signature.
                let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31

                // Store the approval status in memory.
                mstore(0x00, approved)

                /**
                 * The `ApprovalForAll` event.
                 * 
                 * event ApprovalForAll
                 * 
                 * address indexed `owner`
                 * address indexed `operator`
                 * bool `_approved`
                 */
                log3(0x00, 0x20, signatureHash, owner, operator)
            }

            /**
             * This function is used to emit the `URI` event, which is part of the ERC1155 standard.
             * The `URI` event is emitted when the URI for a token ID is updated.
             *
             * @param value The new URI.
             * @param id The token ID.
             */
            function emitURIInformation(value, id) {
                // The keccak256 hash of the `URI` event signature.
                let signatureHash := 0x6bb7ff708619ba0610cba295a58592e0451dee2622938c8755667688daf3529b

                // Load the length of the URI from storage.
                let uriLength := sload(sUriLengthSlot())

                // Store the offset of the `uri` string within the response in memory.
                mstore(0x00, 0x20)

                // Store the length of the `uri` string in memory.
                mstore(0x20, uriLength)

                // Store the `uri` string data in memory.
                for { let i := 1 } lt(i, add(2, div(uriLength, 0x20))) { i := add(i, 1) }
                {
                    let sDataSlot := add(sUriLengthSlot(), i)
                    let uriData := sload(sDataSlot)

                    mstore(add(0x20, mul(i, 0x20)), uriData)
                }

                /**
                 * The `URI` event.
                 * 
                 * event URI
                 * 
                 * string `_value`
                 * uint256 indexed `id`
                 */
                log2(0x00, add(1, div(uriLength, 0x20)), signatureHash, id)
            }

            /**
             * Storage access functions
             */
            
            /**
             * This function is used to generate a unique key for each account's balance of a specific token in storage.
             * In Solidity, mappings are implemented as a hash table. The key of the hash table is generated by hashing
             * the keys of the mapping. In this case, the keys are the `account` and `tokenId`.
             *
             * @param account The address of the account.
             * @param tokenId The ID of the token.
             * @return sBalanceKey The unique key for the account's balance of the token in storage.
             */
            function sGenerateBalanceKey(account, tokenId) -> sBalanceKey {
                // The mapping in Solidity would look like this:
                // Balances: mapping uint256 `tokenID` => (address `account` => uint256 `balance`)

                // First, we hash `tokenId` and `sBalancesSlot()` together.
                // `sBalancesSlot()` returns the starting storage slot for the `balances` mapping.
                let hashOfIdandBalancesSlot := calculateKeccakHash(tokenId, sBalancesSlot())

                // Then, we hash `account` and the previously computed hash together.
                // This gives us a unique key for each account's balance of a specific token.
                // `sBalanceKey` = keccak256(`account`, keccak256(`tokenId`, `sBalancesSlot()`))
                sBalanceKey := calculateKeccakHash(account, hashOfIdandBalancesSlot)
            }

            /**
             * This function is used to generate a unique key for each operator approval status in storage.
             * In Solidity, mappings are implemented as a hash table. The key of the hash table is generated by hashing
             * the keys of the mapping. In this case, the keys are the `account` and `operator`.
             *
             * @param account The address of the account.
             * @param operator The address of the operator.
             * @return sOperatorApprovalKey The unique key for the operator's approval status in storage.
             */
            function sGenerateOperatorApprovalKey(account, operator) -> sOperatorApprovalKey {
                // The mapping in Solidity would look like this:
                // Approvals: mapping address `account` => (address `operator` => bool `approved`)

                // First, we hash `account` and `sOperatorApprovalsSlot()` together.
                // `sOperatorApprovalsSlot()` returns the starting storage slot for the `approvals` mapping.
                let hashOfAccountAndOperatorApprovalsSlot := calculateKeccakHash(account, sOperatorApprovalsSlot())

                // Then, we hash `operator` and the previously computed hash together.
                // This gives us a unique key for each operator's approval status.
                // `sOperatorApprovalKey` = keccak256(`operator`, keccak256(`account`, `sOperatorApprovalsSlot()`))
                sOperatorApprovalKey := calculateKeccakHash(operator, hashOfAccountAndOperatorApprovalsSlot)
            }

             /**
             * Guard functions
             */

            /**
             * This function checks if the given position is within the calldata size. If not, it reverts the transaction.
             * 
             * @param cdPosition The position to check.
             */
            function requireValidCalldataPosition(cdPosition) {
                if lt(calldatasize(), add(cdPosition, 0x20)) {
                    revert(0, 0)
                }
            }

            /**
             * This function checks if the caller of the contract is the owner. If not, it reverts the transaction.
             */
            function requireCallerIsOwner() {
                let owner := sload(sOwnerSlot())

                if iszero(eq(caller(), owner)) {
                    revert(0, 0)
                }
            }

            /**
             * This function checks if the given address is a valid Ethereum address. If not, it reverts the transaction.
             * 
             * @param address_ The address to check.
             */
            function requireValidAddress(address_) {
                // Checks if a given Ethereum address is valid or not.
                // If the address is longer than 20 bytes (160 bits), it's considered invalid and the transaction is reverted.
                if iszero(iszero(and(address_, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            /**
             * Memory functions
             */
            
            /**
             * This function is used to increment the free memory pointer in EVM.
             * The free memory pointer points to the next free memory slot available for allocations.
             * It's stored at position 0x00 in memory.
             *
             * @param currentValue The current value of the free memory pointer.
             * @param incrementBy The value to increment the free memory pointer by.
             */
            function mIncrementFreeMemoryPointerBy(currentValue, incrementBy) {
                // The free memory pointer is stored at position 0x00 in memory.
                // We add the `currentValue` of the free memory pointer and `incrementBy` to get the new value.
                // Then we store this new value back at position 0x00.
                mstore(0x00, add(currentValue, incrementBy))
            }

            /**
             * This function is used to append a word to the free memory.
             * It stores the word at the specified memory location and then increments the free memory pointer.
             *
             * @param mLocation The memory location where the word should be stored.
             * @param value The word to be stored in memory.
             */
            function mStoreWordAndUpdateFreeMemoryPointer(mLocation, value) {
                // Store the word at the specified memory location.
                mstore(mLocation, value)

                // Increment the free memory pointer by 0x20 (32 bytes), which is the size of a word in EVM.
                mIncrementFreeMemoryPointerBy(mLocation, 0x20)
            }

            /**
             * This function is used to append an array to the free memory.
             * It iterates over the array, storing each element at the next free memory location, and then increments the free memory pointer.
             *
             * @param mLocation The memory location where the first element of the array should be stored.
             * @param mArrayLengthPointer A pointer to the length of the array.
             */
            function mStoreArrayToFreeMemory(mLocation, mArrayLengthPointer) {
                // Load the length of the array from memory.
                let arrayLength := mload(mArrayLengthPointer)

                // Iterate over the array.
                for { let i := 1 } lt(i, add(arrayLength, 1)) { i := add(i, 1) }
                {
                    // Load the data at the current index of the array.
                    let data := mload(add(mArrayLengthPointer, mul(i, 0x20)))

                    // Store the data at the next free memory location.
                    mstore(add(mLocation, sub(mul(i, 0x20), 0x20)), data)
                }

                // Increment the free memory pointer by the size of the array.
                mIncrementFreeMemoryPointerBy(mload(0), mul(arrayLength, 0x20))
            }

            /**
             * This function checks if the given address is the zero address. If it is, it reverts the transaction.
             * 
             * @param address_ The address to check.
             */
            function requireNonZeroAddress(address_) {
                if iszero(address_) {
                    revert(0, 0)
                }
            }

            /**
             * This function checks if the given value is a boolean (0 or 1). If not, it reverts the transaction.
             * 
             * @param value The value to check.
             */
            function requireValidBoolValue(value) {
                let isBool := 0

                if eq(value, 0) {
                    isBool := 1
                }
                if eq(value, 1) {
                    isBool := 1
                }

                if iszero(isBool) {
                    revert(0, 0)
                }
            }

            /**
             * This function checks if the balance is greater than or equal to the amount. If not, it reverts the transaction.
             * 
             * @param balance_ The balance to check.
             * @param amount The amount to compare with.
             */
            function requireSufficientBalance(balance_, amount) {
                let gte := 0

                if gt(balance_, amount) {
                    gte := 1
                }
                if eq(balance_, amount) {
                    gte := 1
                }
                
                if iszero(gte) {
                    revert(0, 0)
                }
            }

            /**
             * This function checks if two values are equal. If they are, it reverts the transaction.
             * 
             * @param valueOne The first value to compare.
             * @param valueTwo The second value to compare.
             */
            function requireNotEqual(valueOne, valueTwo) {
                if eq(valueOne, valueTwo) {
                    revert(0, 0)
                }
            }

            /**
             * This function checks if two values are not equal. If they are equal, it reverts the transaction.
             * 
             * @param valueOne The first value to compare.
             * @param valueTwo The second value to compare.
             */
            function requireEqual(valueOne, valueTwo) {
                if iszero(eq(valueOne, valueTwo)) {
                    revert(0, 0)
                }
            }

            /**
             * This function checks if an operator is approved for an account. If not, it reverts the transaction.
             * 
             * @param account The account to check.
             * @param operator The operator to check.
             */
            function requireOperatorApproved(account, operator) {
                let sOperatorApprovalKey := sGenerateOperatorApprovalKey(account, operator)
                let operatorIsApproved := sload(sOperatorApprovalKey)

                if iszero(operatorIsApproved) {
                    revert(0, 0)
                }
            }

            /**
             * Utility functions
             */

            /**
             * This function takes two values, stores them in memory, and then computes the Keccak-256 hash of the memory area 
             * where these values are stored. The result is stored back into the same memory area and returned.
             * 
             * @param valueOne The first value to be hashed.
             * @param valueTwo The second value to be hashed.
             * @return keccakHash The Keccak-256 hash of the two input values.
             */
            function calculateKeccakHash(valueOne, valueTwo) -> keccakHash {
                let mFreeMemoryPointer := mload(0x00)

                // Store words `valueOne` and `valueTwo` in free memory
                mstore(mFreeMemoryPointer, valueOne)
                mstore(add(mFreeMemoryPointer, 0x20), valueTwo)

                // Store hash of `valueOne` and `valueTwo` in free memory
                mstore(mFreeMemoryPointer, keccak256(mFreeMemoryPointer, 0x40))

                keccakHash := mload(mFreeMemoryPointer)
            }

            /**
             * This function checks if an address is a contract address. In Ethereum, contract addresses have associated code, 
             * so the function checks the size of the code associated with the address. If the size is non-zero, the address 
             * is a contract address.
             * 
             * @param address_ The address to be checked.
             * @return isContract A boolean indicating whether the address is a contract address (true) or not (false).
             */
            function isAddressContract(address_) -> isContract {
                isContract := extcodesize(address_)
            }
        }
    }
}
