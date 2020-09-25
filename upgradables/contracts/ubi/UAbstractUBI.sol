pragma solidity >0.6.0;


import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades-core/contracts/Initializable.sol";
import "../dao/UIdentityGuard.sol";
import "../Interfaces.sol";
import ".../dao/UFeelessScheme.sol";

/* @title Base contract template for UBI scheme
 */
contract UAbstractUBI is UFeelessScheme {
    using SafeMath for uint256;

    uint256 initialReserve;

    uint256 public claimDistribution;

    struct Day {
        mapping(address => bool) hasClaimed;
        uint256 amountOfClaimers;
        uint256 claimAmount;
    }

    mapping(uint256 => Day) claimDay;

    mapping(address => uint256) public lastClaimed;

    uint256 public currentDay;

    uint256 public periodStart;

    event UBIStarted(uint256 balance, uint256 time);
    event UBIClaimed(address indexed claimer, uint256 amount);
    event UBIEnded(uint256 claimers, uint256 claimamount);

    /**
     * @dev Constructor. Checks if avatar is a zero address
     * and if periodEnd variable is after periodStart.
     * @param _avatar the avatar contract
     */
    function initialize(
        address _avatar,
        address _identity,
        uint256 _initialReserve
    )
        public initializer
    {
        UFeelessScheme.initialize(_identity, _avatar);
        initialReserve = _initialReserve;
        periodStart = now;
    }

    /**
     * @dev function that returns an uint256 that
     * represents the amount each claimer can claim.
     * @param reserve the account balance to calculate from
     * @return The distribution for each claimer
     */
    function distributionFormula(uint256 reserve, address user)
        internal
        returns (uint256);

    /* @dev function that gets the amount of people who claimed on the given day
     * @param day the day to get claimer count from, with 0 being the starting day
     * @return an integer indicating the amount of people who claimed that day
     */
    function getClaimerCount(uint256 day) public view returns (uint256) {
        return claimDay[day].amountOfClaimers;
    }

    /* @dev function that gets the amount that was claimed on the given day
     * @param day the day to get claimer count from, with 0 being the starting day
     * @return an integer indicating the amount that has been claimed on the given day
     */
    function getClaimAmount(uint256 day) public view returns (uint256) {
        return claimDay[day].claimAmount;
    }

    /* @dev function that gets count of claimers and amount claimed for the current day
     * @return the amount of claimers and the amount claimed.
     */
    function getDailyStats() public view returns (uint256 count, uint256 amount) {
        uint256 today = (now.sub(periodStart)) / 1 days;
        return (getClaimerCount(today), getClaimAmount(today));
    }

    /* @dev Function that commences distribution period on contract.
     * Can only be called after periodStart and before periodEnd and
     * can only be done once. The reserve is sent
     * to this contract to allow claimers to claim from said reserve.
     * The claim distribution is then calculated and true is returned
     * to indicate that claiming can be done.
     */
    function start() public onlyRegistered {
        addRights();

        currentDay = now.sub(periodStart) / 1 days;

        // Transfer the fee reserve to this contract
        cERC20 token = cERC20(avatar.nativeToken());

        if (initialReserve > 0) {
            require(
                initialReserve <= token.balanceOf(address(avatar)),
                "Not enough funds to start"
            );

            controller.genericCall(
                address(token),
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    address(this),
                    initialReserve
                ),
                avatar,
                0
            );
        }
        emit UBIStarted(token.balanceOf(address(this)), now);
    }

    /**
     * @dev Function that ends the claiming period. Can only be done if
     * Contract has been started and periodEnd is passed.
     * Sends the remaining funds on contract back to the avatar contract
     * address
     */
    function end() public onlyAvatar {
        cERC20 token = cERC20(avatar.nativeToken());

        uint256 remainingReserve = token.balanceOf(address(this));

        if (remainingReserve > 0) {
            require(
                token.transfer(address(avatar), remainingReserve),
                "end transfer failed"
            );
        }

        removeRights();
        // selfdestruct(address(avatar));
    }

    /* @dev UBI claiming function. Can only be called by users that were
     * whitelisted before start of contract
     * Each claimer can only claim once per UBI contract
     * @return true if the user claimed successfully
     */
    function claim()
        public
        onlyWhitelisted
        returns (bool)
    {
        require(!claimDay[currentDay].hasClaimed[msg.sender], "has already claimed");
        claimDay[currentDay].hasClaimed[msg.sender] = true;

        cERC20 token = cERC20(address(avatar.nativeToken()));

        claimDay[currentDay].amountOfClaimers = claimDay[currentDay].amountOfClaimers.add(
            1
        );
        claimDay[currentDay].claimAmount = claimDay[currentDay].claimAmount.add(
            claimDistribution
        );

        lastClaimed[msg.sender] = now;
        require(token.transfer(msg.sender, claimDistribution), "claim transfer failed");
        emit UBIClaimed(msg.sender, claimDistribution);
        return true;
    }
}