# Integration EVM Smart Contracts & Cosmwasm for Transfer Cross-Chain Tokens

In a nutshell, This repository verfies messages originating from an EVM chain and forwards them as memo fields through ICS20 packets.

For chains with enabled Wasm modules, calling a CosmWasm contract from an EVM smart contract.

Two integration methods are currently implemented:

1- **Native Network Integration:** Forwards arbitrary payloads to the destination Cosmos chain. The receiving chain must implement an IBC middleware with a custom handler to decode and process the payload.

2- **EVM Networks Integration:** For chains with enabled Wasm modules, calling a CosmWasm contract from an EVM smart contract. The receiving chain must install the general-purpose IBC hook middleware. Message sender have the option to either encode the payload using defined schema or pass the JSON CosmWasm contract call directly. Payload will be verified and translates it into a Wasm execute message.
