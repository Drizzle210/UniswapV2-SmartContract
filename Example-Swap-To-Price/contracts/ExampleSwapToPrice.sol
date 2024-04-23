// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/libraries/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/UniswapV2Router01.sol";

contract ExampleSwapToPice {
    using SafeMath for uint256;
    
    IUniswapV2Router01 public immutable router;
    address immutable factory;

    constructor (address _factory, IuniSwapV2Router01 _router) {
        factory = _factory;
        router = _router;
    }
    
    // cung cap swap token A -> B
    // parameter: dia chi 2 token, ty gia giua A va B, so luong token max co the trao doi, dia chi nguoi nhan, deadline
    // tinh amountIn 
    // goi swap token to token cua router
    function swapToPrice(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 maxSpendTokenA,
        uint256 maxSpendTokenB,
        address to,
        uint256 dealine
    ) public {
        require(truePriceTokenA != 0 && truePriceTokenB != 0, "Zero_Price");
        require(maxSpendTokenA != 0 && maxSpendTokenB != 0, "Zero_Spend");

        bool aToB;
        uint256 amountIn;
        {
            (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
            (aToB, amountIn) = UniswapV2LiquidityMathLibrary.computeProfitMaximizingTrade(
                truePriceTokenA, truePriceTokenB,
                reserveA, reserveB
            );
        }
        require(amountIn > 0, "Zero_Amount_In");
        uint256 maxSpend = aToB ? maxSpendTokenA : maxSpendTokenB;
        if (amountIn > maxSpend) {
            amountIn = maxSpend;
        }

        address tokenIn = aToB ? tokenA : tokenB;
        address tokenOut = aToB ? tokenB : tokenA;
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        router.swapExactTokensForTokens(amountIn, 0, path, to, deadline);
    }

}