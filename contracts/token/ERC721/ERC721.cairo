// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.4.0b (token/erc721/presets/ERC721MintableBurnable.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math import assert_lt
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721

from contracts.token.ERC20.IERC20 import IERC20

struct Animal{
    legs : felt,
    wings : felt,
    sex : felt,
}

const REGIST_PRICE = 100000;

// storage varialbes that store the data of the tokens
@storage_var
func Animals(token_id: Uint256) -> (res: Animal) {
}

@storage_var
func maxTokenId() -> (res: Uint256) {
}

@storage_var
func dummy_token_address_storage() -> (address: felt) {
}

@storage_var
func isBreeder(address: felt) -> (bool: felt) {
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, owner: felt, dummy_token_address: felt
) {
    ERC721.initializer(name, symbol);
    Ownable.initializer(owner);

    //set the dummy token's address
    dummy_token_address_storage.write(dummy_token_address);

    return ();
}

//
// Inner Function
//
func getNextTokenId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (tokenId: Uint256){
    let (currentTokenId) = maxTokenId.read();
    let (nextTokenId: Uint256,_) = uint256_add(currentTokenId,Uint256(1,0));

    // if you erase 'tokenId =', compiler will give you an error. why is that?
    return (tokenId = nextTokenId);
}

//
// Getters
//

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return ERC721.name();
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return ERC721.symbol();
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    return ERC721.balance_of(owner);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    return ERC721.owner_of(tokenId);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    return ERC721.get_approved(tokenId);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved=isApproved);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI: felt) {
    let (tokenURI: felt) = ERC721.token_uri(tokenId);
    return (tokenURI=tokenURI);
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (tokens: felt){
    let (tokenCount) = maxTokenId.read();
    return (tokens = tokenCount.low);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}

@view
func token_of_owner_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
account: felt, index:felt) -> (tokenId: Uint256){

    let maxIndex : Uint256 = balanceOf(account);
    // assert_lt gives me an error message when it has error, so I didn't use with_attr
    assert_lt(index, maxIndex.low);
    
    let (maxTokenSupply) = maxTokenId.read();

    let (_,tokenId) = get_tokens_recursivly(account, index+1, maxTokenSupply.low);

    return (tokenId = tokenId);
}

// return argument account is breeder or not
@view
func is_breeder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
account: felt) -> (bool: felt){

    let (bool: felt) = isBreeder.read(account);

    return (bool = bool);
}

@view
func registration_price{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (price: Uint256){

    let amount: felt = REGIST_PRICE;

    return (price = Uint256(amount,0));
}

//
// inner function
//

func get_tokens_recursivly{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
account: felt, target:felt, maxIndex: felt) -> (nowIndex: felt, tokenId: Uint256){

    if (maxIndex == 0){
        return (0, Uint256(0,0));
    }

    let (nowIndex, tokenId) = get_tokens_recursivly(account,target,maxIndex - 1);
    
    if (nowIndex == target){
        return (nowIndex, tokenId);
    }

    let (owner) = ownerOf(Uint256(maxIndex,0));

    if (owner == account) {
        return (nowIndex+1, Uint256(maxIndex,0));
    }else {
        return (nowIndex, tokenId);
    }

}

//
// Externals
//

@external
func get_animal_characteristics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (sex: felt, legs: felt, wings: felt) {
    // get the value of the Animal
    let res: Animal = Animals.read(tokenId);

    return (res.sex, res.legs, res.wings);
}

@external
func declare_animal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sex: felt, legs: felt, wings: felt
) -> (tokenId: Uint256){
    let (caller) = get_caller_address();
    let (newTokenId: Uint256) = mint(caller, sex, legs, wings);
    return (tokenId = newTokenId);
}

@external
func declare_dead_animal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256){
    
    burn(tokenId);

    return ();
}

@external
func register_me_as_breeder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (is_added: felt) {
    let (tokenAddress : felt) = dummy_token_address_storage.read();
    let (thisContract: felt) = get_contract_address();
    let (caller: felt) = get_caller_address();
    
    with_attr  error_message("Transfer makes error"){
        let (result: felt) = IERC20.transferFrom(contract_address = tokenAddress, sender = caller, recipient = thisContract, amount = Uint256(REGIST_PRICE, 0));
        assert result = 1;
    }

    isBreeder.write(caller,1);

    return (is_added = 1);
}

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ERC721.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, sex: felt, legs: felt, wings: felt
) -> (tokenId: Uint256){
    Ownable.assert_only_owner();
    //get next tokenID
    let (tokenId: Uint256) = getNextTokenId();
    ERC721._mint(to, tokenId);
    
    maxTokenId.write(tokenId);
    //set that animal's feature
    Animals.write(tokenId, value = Animal(legs = legs, wings = wings, sex = sex));

    return (tokenId = tokenId);
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    ERC721.assert_only_token_owner(tokenId);
    ERC721._burn(tokenId);
    Animals.write(tokenId, value = Animal(legs = 0, wings = 0, sex = 0));
    return ();
}

@external
func setTokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256, tokenURI: felt
) {
    Ownable.assert_only_owner();
    ERC721._set_token_uri(tokenId, tokenURI);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}