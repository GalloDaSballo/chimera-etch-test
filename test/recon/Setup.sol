// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm, IHevm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";

// Helpers
import {Utils} from "@recon/Utils.sol";

// Your deps
import "src/Counter.sol";

// Extend IHevm with etch function (not present in base chimera Hevm.sol)
interface IHevmEtch is IHevm {
    function etch(address target, bytes calldata newRuntimeBytecode) external;
}

// Cast vm to extended interface with etch support
IHevmEtch constant vmEtch = IHevmEtch(address(vm));

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    Counter counter;

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        // New Actor, beside address(this)
        _addActor(address(0x411c3));
        _newAsset(18); // New 18 decimals token

        counter = new Counter();

        // Mints to all actors and approves allowances to the counter
        address[] memory approvalArray = new address[](1);
        approvalArray[0] = address(counter);
        _finalizeAssetDeployment(_getActors(), approvalArray, type(uint88).max);

        // Test vm.etch functionality
        address targetAddr = address(0xBEEF);

        // Assert initial code length is zero
        require(targetAddr.code.length == 0, "Initial code should be zero");

        // Etch some bytecode (simple STOP opcode: 0x00)
        bytes memory bytecode = hex"AA";
        vmEtch.etch(targetAddr, bytecode);

        // Assert code was etched successfully
        require(targetAddr.code.length > 0, "Etched code length should be greater than zero");
        require(targetAddr.code.length == bytecode.length, "Etched code length mismatch");
        require(keccak256(targetAddr.code) == keccak256(bytecode), "Etched code content mismatch");
    }

    /// === MODIFIERS === ///
    /// Prank admin and actor
    
    modifier asAdmin {
        vm.prank(address(this));
        _;
    }

    modifier asActor {
        vm.prank(address(_getActor()));
        _;
    }
}
