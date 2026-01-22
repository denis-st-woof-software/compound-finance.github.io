---

---

# Compound III

## Introduction

[Compound III](https://github.com/compound-finance/comet){:target="_blank"} is an EVM compatible protocol that enables supplying of crypto assets as collateral in order to borrow the *base asset*. Accounts can also earn interest by supplying the base asset to the protocol.

The initial deployment of Compound III is on Ethereum and the base asset is USDC.

Please join the **#development** room in the Compound community [Discord](https://compound.finance/discord){:target="_blank"} server as well as the forums at [comp.xyz](https://www.comp.xyz){:target="_blank"}; Compound Labs and members of the community look forward to helping you build an application on top of Compound III. Your questions help us improve, so please don't hesitate to ask if you can't find what you are looking for here.

For documentation of the Compound v2 Protocol, see [docs.compound.finance/v2](/v2/).

### Networks

The network deployment artifacts with contract addresses are available in the [Comet](https://github.com/compound-finance/comet){:target="_blank"} repository `deployments/` folder.

The v3 proxy is the only address to be used to interact with a Compound III instance. It is the first address listed in each of the tabs below. To generate the proper [Comet Interface ABI](/public/files/comet-interface-abi-98f438b.json){:target="_blank"} (`CometInterface.sol`), compile the Comet project using `yarn compile`.

<br />
> **Note:** The deployment data shown below is sourced from the [compound-docs-aggregator](https://github.com/woof-software/compound-docs-aggregator){:target="_blank"} repository. Data collected on: **2026-01-15 09:12:06.080 UTC**.

<div id="networks-widget-container"></div>

### Protocol Contracts

#### cUSDCv3

This is the main proxy contract for interacting with the first Compound III market. The address is fixed and independent from future upgrades to the market. It is an [OpenZeppelin TransparentUpgradeableProxy contract](https://docs.openzeppelin.com/contracts/4.x/api/proxy){:target="_blank"}.

#### cUSDCv3 Implementation

This is the implementation of the market logic contract, as deployed by the Comet Factory via the Configurator.

Do not interact with this contract directly; instead use the cUSDCv3 proxy address with the Comet Interface ABI.

#### cUSDCv3 Ext

This is an extension of the market logic contract which supports some auxiliary/independent interfaces for the protocol. This is used to add additional functionality without requiring contract space in the main protocol contract.

Do not interact with this contract directly; instead use the cUSDCv3 proxy address with the Comet Interface ABI.

#### Configurator

This is a [proxy](https://docs.openzeppelin.com/contracts/4.x/api/proxy#TransparentUpgradeableProxy){:target="_blank"} contract for the `configurator`, which is used to set and update parameters of a Comet proxy contract. The configurator deploys implementations of the Comet logic contract according to its configuration. This pattern allows significant gas savings for users of the protocol by 'constantizing' the parameters of the protocol.

#### Configurator Implementation

This is the implementation of the Configurator contract, which can also be upgraded to support unforeseen changes to the protocol.

#### Proxy Admin

This is the admin of the Comet and Configurator proxy contracts. It is a [ProxyAdmin](https://docs.openzeppelin.com/contracts/4.x/api/proxy#ProxyAdmin){:target="_blank"} as recommended/implemented by OpenZeppelin according to their upgradeability pattern.

#### Comet Factory

This is the factory contract capable of producing instances of the Comet implementation/logic contract, and invoked by the Configurator.

#### Rewards

This is a rewards contract which can hold rewards tokens (e.g. COMP, WETH) and allows claiming rewards by users, according to the core protocol tracking indices.

#### Bulker

This is an external contract that is not integral to Comet's function. It allows accounts to bulk multiple operations into a single transaction. This is a useful contract for Compound III user interfaces. The following is an example of steps in a bulked transaction.

- Wrap Ether to WETH
- Supply WETH collateral
- Supply WBTC collateral
- Borrow USDC

In addition to supplying, borrowing, and wrapping, the bulker contract can also transfer collateral within the protocol and claim rewards.

## Developer Resources

The following developer guides and code repositories serve as resources for community members building on Compound. They detail the protocol deployment process, construction of new features, and code examples for implementing external apps that depend on Compound III as infrastructure.

1. [Compound III Developer FAQ](https://github.com/compound-developers/compound-3-developer-faq){:target="_blank"}
2. [Scenarios, Migrations, and Workflows](https://www.comp.xyz/t/compound-iii-scenarios-migrations-and-workflows/3771){:target="_blank"}
3. [Creating a Compound III Liquidator](https://www.comp.xyz/t/the-compound-iii-liquidation-guide/3452){:target="_blank"}
4. [Building a Comet Extension](https://www.comp.xyz/t/building-a-comet-extension/3854){:target="_blank"}
   {: .mega-ordered-list }

## Security

The security of the Compound protocol is our highest priority; our development team, alongside third-party auditors and consultants, has invested considerable effort to create a protocol that we believe is safe and dependable. All contract code and balances are publicly verifiable, and security researchers are eligible for a bug bounty for reporting undiscovered vulnerabilities.

We believe that size, visibility, and time are the true test for the security of a smart contract; please exercise caution, and make your own determination of security and suitability.

### Audits

The Compound protocol has been reviewed & audited by [OpenZeppelin](https://openzeppelin.com/) and [ChainSecurity](https://chainsecurity.com/){:target="_blank"}.

1. [Compound III Audit by OpenZeppelin](https://blog.openzeppelin.com/compound-iii-audit/){:target="_blank"}
2. [Compound III Security Audit by ChainSecurity](https://chainsecurity.com/security-audit/compound-iii/){:target="_blank"}
   {: .mega-ordered-list }