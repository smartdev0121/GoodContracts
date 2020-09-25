pragma solidity >0.5.4;

import "./USchemeGuard.sol";
import "../DAOStackInterfaces.sol";
import "../Interfaces.sol";
import "../dao/UIdentityGuard.sol";
import "@openzeppelin/upgrades-core/contracts/Initializable.sol";

/**
 * @dev Contract for letting scheme add itself to identity
 * to allow transferring GoodDollar without paying fees
 * and transfer ownership to Avatar
 */
contract UFeelessScheme is Initializable, USchemeGuard, UIdentityGuard {

    /* @dev Constructor
     * @param _identity The identity contract
     * @param _avatar The avatar of the DAO
     */
    function initialize(address _identity, address _avatar)
        public
        initializer
    {
        USchemeGuard.initialize(_avatar);
        UIdentityGuard.initialize(_identity);
    }

    /* @dev Internal function to add contract to identity.
     * Can only be called if scheme is registered.
     */
    function addRights() internal onlyRegistered {
        controller.genericCall(
            address(identity),
            abi.encodeWithSignature("addContract(address)", address(this)),
            avatar,
            0
        );
        // transferOwnership(address(avatar));
    }

    /* @dev Internal function to remove contract from identity.
     * Can only be called if scheme is registered.
     */
    function removeRights() internal onlyRegistered {
        controller.genericCall(
            address(identity),
            abi.encodeWithSignature("removeContract(address)", address(this)),
            avatar,
            0
        );
    }
}