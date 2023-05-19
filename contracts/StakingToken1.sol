//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RewardToken.sol";
import "./StakeToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingToken is Ownable, ERC20 {
    using SafeERC20 for StakeToken;

    RewardToken public rewardToken; // reward Token
    StakeToken public stakeToken;

    uint256 private rewardTokensPerBlock; // reward tokens gotten per block
    uint256 private constant BIG_INT_FORMATTER = 1e12;
    uint256 private totalMultiplier;

    // Each person staking
    struct StakerInfo {
        uint256 amount; // amount of staked token
        uint256 startBlock; // the block that the staker start earn in
        uint256 depositStartTime;
    }

    // Pool information
    struct Pool {
        StakeToken stakeToken; // Token to be staked
        uint256 tokensStaked; // Total number of tokens staked
        uint256 endStakeTime;
        uint256 farmMultiplier;
    }

    Pool[] public pools; // Array of pools

    // Mapping poolId => staker address => PoolStaker
    mapping(uint256 => mapping(address => StakerInfo)) public stakerInfo;

    // Events
    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );
    event CollectRewards(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event PoolCreated(uint256 poolId);

    event ChangeFarmMultifier(uint256 indexed poolId, uint256 farmMultiplier);

    event UpdateRewardTokenPerBlock(uint256 _newReward);

    // Constructor
    constructor(address _rewardTokenAddress, uint256 _rewardTokensPerBlock)
        ERC20("Pool Token", "PTK")
    {
        rewardToken = RewardToken(_rewardTokenAddress);
        rewardTokensPerBlock = _rewardTokensPerBlock;
    }

    /**
     * Create the Staking pool
     */
    function createStakingPool(
        StakeToken _stakeToken,
        uint256 _endStakeTime,
        uint256 _farmMultiplier
    ) external onlyOwner {
        Pool memory pool;
        pool.stakeToken = _stakeToken;
        pool.endStakeTime = _endStakeTime;
        pool.farmMultiplier = _farmMultiplier;
        pools.push(pool);
        totalMultiplier += _farmMultiplier;
        uint256 poolId = pools.length - 1;
        emit PoolCreated(poolId);
    }

    /**
     * Return all pool
     */
    function getAllPool() public view returns (Pool[] memory) {
        return pools;
    }

    /**
     * Deposit to pool
     */
    function deposit(uint256 _poolId, uint256 _amount) external payable {
        require(_amount > 0, "Deposit amount can't be zero");
        Pool storage pool = pools[_poolId];
        StakerInfo storage staker = stakerInfo[_poolId][msg.sender];

        // Update pool stakers and if anyone is collecting reward at this block, they collect their reward
        if (staker.amount > 0) {
            collectRewards(_poolId);
        }

        // Update current staker
        staker.startBlock = block.number;
        staker.depositStartTime = block.timestamp;
        staker.amount = staker.amount + _amount; //adds up if staker comes to stakes extra

        // Update pool
        pool.tokensStaked = pool.tokensStaked + _amount;

        // Deposit tokens
        emit Deposit(msg.sender, _poolId, _amount);
        pool.stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * Withdraw all tokens from an existing pool
     */
    function withdraw(uint256 _poolId, uint256 _amount) public {
        require(_amount > 0, "Withdraw amount can't be zero");
        Pool storage pool = pools[_poolId];
        StakerInfo storage staker = stakerInfo[_poolId][msg.sender];
        uint256 depositDuration = block.timestamp - staker.depositStartTime;

        //Check deposit duration
        require(depositDuration > pool.endStakeTime);

        // Pay rewards
        collectRewards(_poolId);

        // Update staker
        staker.amount = 0; //staker is withdrawing hence amount is 0 ?!?
        staker.startBlock = 0;
        staker.depositStartTime = 0;

        // Update pool
        pool.tokensStaked = pool.tokensStaked - _amount;

        // Withdraw tokens
        emit Withdraw(msg.sender, _poolId, _amount);
        pool.stakeToken.safeTransfer(msg.sender, _amount);
    }

    /**
     * Collect rewards from a given pool id
     */
    function collectRewards(uint256 _poolId) public {
        Pool storage pool = pools[_poolId];
        StakerInfo storage staker = stakerInfo[_poolId][msg.sender];

        require(staker.startBlock > 0);

        uint256 blocksSinceLastReward = block.number - staker.startBlock;
        uint256 rewards = (blocksSinceLastReward *
            rewardTokensPerBlock *
            BIG_INT_FORMATTER *
            pool.farmMultiplier) / totalMultiplier;

        uint256 rewardsToHarvest = (staker.amount * rewards) /
            pool.tokensStaked;

        require(rewardsToHarvest > 0);

        staker.startBlock = block.number;

        emit CollectRewards(msg.sender, _poolId, rewardsToHarvest);
        rewardToken.mint(msg.sender, rewardsToHarvest);
    }

    /**
     * Get staker reward
     */
    function getRewardsInfor(uint256 _poolId) public view returns (uint256) {
        Pool memory pool = pools[_poolId];
        StakerInfo memory staker = stakerInfo[_poolId][msg.sender];

        require(staker.amount > 0);

        uint256 blocksSinceLastReward = block.number - staker.startBlock;
        uint256 rewards = (blocksSinceLastReward *
            rewardTokensPerBlock *
            BIG_INT_FORMATTER *
            pool.farmMultiplier) / totalMultiplier;

        uint256 rewardsToHarvest = (staker.amount * rewards) /
            pool.tokensStaked;

        return rewardsToHarvest;
    }

    /**
     * Get Current Block Number
     */
    function getCurrentBlock() public view returns (uint256) {
        return block.number;
    }

    /**
     * Change Farm Multifier
     */
    function changeFarmMultifier(uint256 _poolId, uint256 _newFarmMultifier)
        public
    {
        Pool storage pool = pools[_poolId];

        require(msg.sender == owner());
        totalMultiplier -= pool.farmMultiplier;
        pool.farmMultiplier = _newFarmMultifier;
        totalMultiplier += _newFarmMultifier;

        emit ChangeFarmMultifier(_poolId, pool.farmMultiplier);
    }

    /**
     * Get total Multifier
     */
    function getTotalMultiplier() public view returns (uint256) {
        return totalMultiplier;
    }

    /**
     * Get reward token per block
     */
    function getRewardTokenPerBlock() public view returns (uint256) {
        return rewardTokensPerBlock;
    }

    /**
     * Update Reward token per Block
     */
    function updateRewardTokenPerBlock(uint256 _newReward) public {
        require(msg.sender == owner());
        rewardTokensPerBlock = _newReward;
        emit UpdateRewardTokenPerBlock(_newReward);
    }
}
