pragma solidity >0.5.4;

import "@daostack/arc/contracts/controller/Avatar.sol";
import "@daostack/arc/contracts/controller/ControllerInterface.sol";

/* @title Scheme for switching to AMB bridge
 */
contract ChangeUBICyclePeriod {
	Avatar avatar;

	/* @dev constructor. Sets the factory address. Reverts if given address is null
	 * @param _factory The address of the bridge factory
	 */
	constructor(Avatar _avatar) public {
		avatar = _avatar;
	}

	/* @dev Adds the bridge address to minters, deploys the home bridge on
	 * current network, and then self-destructs, transferring any ether on the
	 * contract to the avatar. Reverts if scheme is not registered
	 */
	function setPeriod(address _ubi, uint256 _length) public {
		ControllerInterface controller = ControllerInterface(avatar.owner());
		(bool ok, ) =
			controller.genericCall(
				_ubi,
				abi.encodeWithSignature("setCycleLength(uint256)", _length),
				avatar,
				0
			);

		require(ok, "setting cycle length period failed");

		selfdestruct(address(avatar));
	}
}
