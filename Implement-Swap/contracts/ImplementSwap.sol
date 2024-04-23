// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DaiToken.sol";

contract ImplementSwap is DAI {
    address private daiTokenAddress;
    IERC20 Dai;
    uint amountIn = 50 ** 10 ** Dai.decimals();

    constructor(address _daiTokenAddress) {
        Dai = DAI(_daiTokenAddress);
    }

    function swap() public {
        require(Dai.transferFrom(msg.sender, address(this), amountIn), 'Transferfrom Failed.');
        require(Dai.approve(address(UniswapV2Router02), amountIn), 'Approve failed.');
        address[] memory path = new address[](2);
        path[0] = daiTokenAddress;
        path[1] = UniswapV2Router02.WETH();
        UniswapV2Router02.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, block.timestamp);
    }

}