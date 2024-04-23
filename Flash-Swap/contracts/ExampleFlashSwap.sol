// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-periphery/contracts/interfaces/V1/IUniswapV1Exchange.sol";
import "@uniswap/v2-periphery/contracts/interfaces/V1/IUniswapV1Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";

contract ExampleFlashSwap is IUniswapV2Callee {
    IUniswapV1Factory immutable factoryV1;
    address immutable factory;
    IWETH immutable WETH;

    constructor(address _factory, address _factoryV1, address router) {
        factoryV1 = IUniswapV1Factory(_factoryV1);
        factory = _factory;
        WETH = IWETH(IUniswapV2Router01(router).WETH());
    }

    receive() external payable {}
    
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address[] memory path = new address[](2);
        uint amountToken;
        uint amountETH;
        {
            address token0 = IUniswapV2Pair(msg.sender).token0(); 
            address token1 = IUniswapV2Pair(msg.sender).token1();
            assert(msg.sender == UniswapV2Library.pairFor(factory, token0, token1)); // nguoi goi ham phai la mot pair
            assert(amount0 == 0 || amount1 == 0);
            path[0] = amount0 == 0 ? token0 : token1;
            path[1] = amount0 == 0 ? token1 : token0;
            amountToken = token0 == address(WETH) ? amount1 : amount0;
            amountETH = token0 == address(WETH) ? amount0 : amount1;
        }

        assert(path[0] == address(WETH) || path[1] == address(WETH));
        IERC20 token = (path[0] == address(WETH) ? path[1] : path[0]);
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(address(token)));

        if(amountToken > 0) {
            (uint minETH) = abi.decode(data, (uint)); // gia tri truot gia toi thieu ma nguoi dung co the chap nhan
            token.approve(address(exchangeV1), amountToken);
            uint amountReceived = exchangeV1.tokenToEthSwapInput(amountToken, minETH, uint(-1));
            uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0];
            assert(amountReceived > amountRequired); // phai tra lai du eth da vay
            WETH.deposit{value: amountRequired}();
            assert (WETH.transfer(msg.sender, amountRequired)); // tra WETH cho v2 pair
            (bool access, ) = sender.call{value: amountReceived - amountRequired}(new bytes(0));
        } else {
            (uint minToken) = abi.decode(data, (uint));
            WETH.withdraw(amountETH);
            uint amountReceived = exchangeV1.tokenToEthSwapInput(amountETH, minToken, uint(-1));
            uint amountRequired = UniswapV2Library.getAmountIn(factory, amountETH, path)[0];
            assert(amountReceived > amountRequired);
            assert(token.transfer(msg.sender, amountRequired));
            assert(token.transfer(sender, amountReceived - amountRequired));
        }

    }

}