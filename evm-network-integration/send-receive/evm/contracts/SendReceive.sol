// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { StringToAddress, AddressToString } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/AddressString.sol";

contract SendReceive is AxelarExecutable {
    IAxelarGasService public immutable gasService;

    using StringToAddress for string;
    using AddressToString for address;


    string public chainName; // name of the chain this contract is deployed to

    struct Message {
        string sender;
        string message;
    }

    Message public storedMessage; // message received from _execute

    constructor(
        address gateway_,
        address gasReceiver_,
        string memory chainName_
    ) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
        chainName = chainName_;
    }

    function send(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata message
    ) external payable {
        // 1. Generate GMP payload
        bytes memory executeMsgPayload = abi.encode(msg.sender.toString(), message);
        bytes memory payload = _encodePayloadToCosmWasm(executeMsgPayload);

        // 2. Pay for gas
        gasService.payNativeGasForContractCall{value: msg.value}(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            msg.sender
        );

        // 3. Make GMP call
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    function _encodePayloadToCosmWasm(bytes memory executeMsgPayload) internal view returns (bytes memory) {

        // contract call arguments for ExecuteMsg::receive_message_evm{ source_chain, source_address, payload }
        bytes memory argValues = abi.encode(
            chainName,
            address(this).toString(),
            executeMsgPayload
        );

        string[] memory argumentNameArray = new string[](3);
        argumentNameArray[0] = "source_chain";
        argumentNameArray[1] = "source_address";
        argumentNameArray[2] = "payload";

        string[] memory abiTypeArray = new string[](3);
        abiTypeArray[0] = "string";
        abiTypeArray[1] = "string";
        abiTypeArray[2] = "bytes";

        bytes memory gmpPayload;
        gmpPayload = abi.encode(
            "receive_message_evm",
            argumentNameArray,
            abiTypeArray,
            argValues
        );

        return abi.encodePacked(
            bytes4(0x00000001),
            gmpPayload
        );
    }

    /** 
        The _execute method is called whenever a message is received from Axelar GMP. 
        By initiating a new message with a call to callContract from within _execute, 
        the Axelar network recognizes this as a two-way call and will use the gas from the initial transaction 
        to pay for the return message. 
    */
    function _execute(
        string calldata /*sourceChain*/,
        string calldata /*sourceAddress*/,
        bytes calldata payload
    ) internal override {      
        (string memory sender, string memory message) = abi.decode(payload, (string, string));
        storedMessage = Message(sender, message);
    }
}
