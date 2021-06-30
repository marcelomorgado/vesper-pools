// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./MakerStrategy.sol";

/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in Vesper DAI pool to earn interest.
abstract contract VesperMakerStrategy is MakerStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor(
        address _controller,
        address _pool,
        address _cm,
        address _vPool,
        bytes32 _collateralType
    ) public MakerStrategy(_controller, _pool, _cm, _vPool, _collateralType) {
        require(IController(_controller).isPool(_vPool), "not-a-valid-vPool");
        require(IVesperPool(_vPool).token() == DAI, "not-a-valid-dai-pool");
    }

    function _getDaiBalance() internal override view returns (uint256) {
        return
            (IVesperPool(receiptToken).getPricePerShare())
                .mul(IVesperPool(receiptToken).balanceOf(address(this)))
                .div(1e18);
    }

    function _depositDaiToLender(uint256 _amount) internal override {
        IVesperPool(receiptToken).deposit(_amount);
    }

    function _withdrawDaiFromLender(uint256 _amount) internal override {
        uint256 vAmount = _amount.mul(1e18).div(IVesperPool(receiptToken).getPricePerShare());
        IVesperPool(receiptToken).withdrawByStrategy(vAmount);
    }

    function _withdrawExcessDaiFromLender(uint256 _base) internal override {
        uint256 balance = _getDaiBalance();
        if (balance > _base) {
            _withdrawDaiFromLender(balance.sub(_base));
        }
    }
}
