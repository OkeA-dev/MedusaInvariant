// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import { Test, console } from "forge-std/Test.sol";
import { KittyCoin } from "src/KittyCoin.sol";
import { KittyPool } from "src/KittyPool.sol";
import { KittyVault, IAavePool } from "src/KittyVault.sol";
import { DeployKittyFi, HelperConfig } from "script/DeployKittyFi.s.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { MockV3Aggregator } from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { WETH9Mock } from "./Mocks/MockWeth.sol";
import "./Utils/Cheats.sol";
import "./Utils/PropertyHelper.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract KittyInv is PropertiesAsserts {
    using Math for uint256;

    StdCheats vm = StdCheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    KittyCoin kittyCoin;
    KittyPool kittyPool;
    KittyVault wethVault;
    
    address meowntainer;
    uint256 AMOUNT = 10e18;

    address aavePool = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address euroPriceFeed = 0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910;
    address ethUsdPriceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address btcUsdPriceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address usdcUsdPriceFeed = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
    WETH9Mock weth;
    address wbtc = 0x29f2D40B0605204364af54EC677bD022dA425d03;
    address usdc = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;

    uint totalCattyNip;

    uint256 private constant COLLATERAL_PERCENT = 169;
    uint256 private constant COLLATERAL_PRECISION = 100;

    constructor() {
        meowntainer = msg.sender;
    
        kittyPool = new KittyPool(meowntainer, euroPriceFeed, aavePool);
        weth = new WETH9Mock("Weth Mock", "mWeth", address(this));


        vm.prank(meowntainer);
        kittyPool.meownufactureKittyVault(address(weth), ethUsdPriceFeed);

        kittyCoin = KittyCoin(kittyPool.getKittyCoin());
        wethVault = KittyVault(kittyPool.getTokenToVault(address(weth)));
    }

    // function testConstructorValuesSetUpCorrectly() public view {
    //     assert(address(kittyPool.getMeowntainer()) == meowntainer);
    //     assert(address(kittyPool.getKittyCoin()) == address(kittyCoin));
    //     assert(address(kittyPool.getTokenToVault(address(weth))) == address(wethVault));
    //     assert(address(kittyPool.getAavePool()) == aavePool);
    // }

    //  function test_MeowntainerAddingTokenSetUpCorrectly() public {
    //     // initially there is no vault for wbtc
    //     require(kittyPool.getTokenToVault(wbtc) == address(0));

    //     vm.prank(meowntainer);
    //     kittyPool.meownufactureKittyVault(wbtc, btcUsdPriceFeed);

    //     address vaultCreated = kittyPool.getTokenToVault(wbtc);

    //     require(vaultCreated != address(0), "Vault not created");

    //     KittyVault _vault = KittyVault(vaultCreated);

    //     assert(_vault.i_token() == wbtc);
    //     assert(_vault.i_pool() == address(kittyPool));
    //     assert(address(_vault.i_priceFeed()) == btcUsdPriceFeed);
    //     assert(address(_vault.i_euroPriceFeed()) == euroPriceFeed);
    //     assert(address(_vault.i_aavePool()) == aavePool);
    //     assert(_vault.meowntainer() == meowntainer);
    //     assert(address(_vault.i_aavePool()) == aavePool);
    // }

     function test_UserDepositsInVault(uint256 toDeposit) public {
        toDeposit = clampBetween(toDeposit, 1 ether, 100_000 ether);
        
        weth.mint(msg.sender, toDeposit);

        uint256 userInitialBalance = wethVault.userToCattyNip(msg.sender);

        vm.prank(msg.sender);
        weth.approve(address(wethVault), toDeposit);

        vm.prank(msg.sender);
        kittyPool.depawsitMeowllateral(address(weth), toDeposit);

        totalCattyNip += toDeposit;

        uint256 userAfterBalance = wethVault.userToCattyNip(msg.sender);

        if (wethVault.totalMeowllateralInVault() > 0 ) {
           uint userShare =  toDeposit.mulDiv(wethVault.totalCattyNip(), wethVault.totalMeowllateralInVault());
            assert(wethVault.userToCattyNip(msg.sender) - userShare == userInitialBalance);
        }

        assert(userAfterBalance - userInitialBalance == toDeposit);
        assert(wethVault.totalCattyNip() == totalCattyNip);
        
    }
    // Check the total weth token value at every instance
    function test_vaultWethBalance() public view {
        assert(weth.balanceOf(address(wethVault)) == totalCattyNip);
    }

    function test_UserWithdrawsInVault(uint amount) public {
        amount = clampBetween(amount, 1 ether, 100_000 ether);

        uint256 userInitialBalance = wethVault.userToCattyNip(msg.sender);
        
        vm.prank(msg.sender);
        kittyPool.whiskdrawMeowllateral(address(weth), amount);

        totalCattyNip -= amount;

        uint256 userAfterBalance = wethVault.userToCattyNip(msg.sender);


        assert(wethVault.totalCattyNip() == totalCattyNip);
        assert(userInitialBalance - amount  == userAfterBalance);
    }

    function test_userMintCattyNip(uint amount) public {

        vm.prank(msg.sender);
        kittyPool.meowintKittyCoin(amount);
        // check underCollateral minting 
        assert(wethVault.getUserVaultMeowllateralInEuros(msg.sender)  >= kittyCoin.balanceOf(msg.sender).mulDiv(COLLATERAL_PERCENT, COLLATERAL_PRECISION));
    }

    function test_userBurnCattyNip(uint256 amount, address user) public {
        uint userInitialBalance = kittyCoin.balanceOf(msg.sender);

        vm.prank(msg.sender);
        kittyPool.burnKittyCoin(user, amount);

        uint userAfterBalance = kittyCoin.balanceOf(msg.sender);

        assert(userAfterBalance + amount == userInitialBalance);

    }

    function test_ownerSupplyToAave(uint256 amount) public {

        uint256 vaultInitialBalance = wethVault.totalMeowllateralInVault();
        vm.prank(meowntainer);
        wethVault.purrrCollateralToAave(amount);
        
        uint256 vaultAfterBalance = wethVault.totalMeowllateralInVault();

        assert(vaultInitialBalance - amount == vaultAfterBalance);


    }

    
}