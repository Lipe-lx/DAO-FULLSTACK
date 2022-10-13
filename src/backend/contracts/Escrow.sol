// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface cERC20 {
function mint(uint256) external returns (uint256);
function balanceOf(address owner) external view returns (uint256 balance);
function redeem(uint256) external returns (uint256);
function exchangeRateCurrent() external returns (uint256);
}


// contrato de garantia junto a Compound
contract Escrow is Ownable {
// variaveis de estado
address public payee;
uint256 public currentStage = 1;
uint256 public totalStages;
mapping(uint256 => uint256) holderRewardsPerStage;
uint256 public totalFunds;
uint256 public fundsRemaining;
//cUSDC é o USDC da Compound
uint256 public totalcUSDC;
uint256 public cUSDCRemaining;
address public govToken;
address USDCContract = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
address cUSDCContract = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
IERC20 public USDC;
cERC20 public cToken;

// o construtor necessita dos argumentos endereço do beneficiário e o estagio atual
constructor(address _payee, uint256 _totalStages) {
USDC = IERC20(USDCContract);
cToken = cERC20(cUSDCContract);
payee = _payee;
totalStages = _totalStages;
}

// função para liberar os fundos (parametro é o estagio atual)// so podera ser feita pelo dono do contrato
function releaseFunds(uint256 _stage) public onlyOwner {
// adiciona mais um estagio ao chamar a funcao de liberar fundos
currentStage++;
// Saldo cUSDC para o resgate = total de cUSDC divido pelo numero total de estagios
uint256 cUSDCBalanceForRedeeming = totalcUSDC / totalStages;
// Taxa de cambio atual entre os tokens 
uint256 exchangeRate = cToken.exchangeRateCurrent();
// Quanto recebido em USDC já convertido e em decimal
uint256 USDCReceived = (cUSDCBalanceForRedeeming * exchangeRate) / 10**18;
// Aplica a função para realização do resgate
redeemCErc20Tokens(cUSDCBalanceForRedeeming);
// USDC a pagar = total de USDC divido pelo numero total de estagios
uint256 USDCToPay = totalFunds / totalStages;
// Recompensa dos holders para esse estagio = USDC recebido - pago
uint256 holdersRewardForThisStage = USDCReceived - USDCToPay;
// Recompensa dos holders por estagio // [_stage] é o estagio atual aqual e adicionado ao total
holderRewardsPerStage[_stage] += holdersRewardForThisStage;
// fundos (USDC) restantes
fundsRemaining -= USDCToPay;
// cUSDC restantes
cUSDCRemaining -= cUSDCBalanceForRedeeming;
// transfere ao beneficiario o valor pago
USDC.transfer(payee, USDCToPay);
// transfere ao contrato o valor resgatado do estagio atual
USDC.transfer(govToken, holderRewardsPerStage[_stage]);
}

//Send funds to compound
// enviando tokens para o Compound para pegar cUSDC// argumento recebe o valor a enviar
function supplyErc20ToCompound(uint256 _numTokensToSupply)
external returns (uint256) {
// conferir se o endereço que esta chamando a funcao e o do govToken
if(govToken == address(0)){
    govToken = msg.sender;
}
require(msg.sender == govToken, "You can't call This function");
// adiciona o valor enviado ao valor total
totalFunds += _numTokensToSupply;
// adiciona o valor enviado aos fundos restantes
fundsRemaining += _numTokensToSupply;
USDC.approve(cUSDCContract, _numTokensToSupply);
// taxa de cambio entre os tokens
uint256 exchangeRate = cToken.exchangeRateCurrent();
// quantidade de tokens recebidos apos a conversao e em decimal
uint256 ctokensReceived = (_numTokensToSupply*10**18)/exchangeRate;
// mint dos tokens
uint256 mintResult = cToken.mint(_numTokensToSupply);
// adicao dos tokens novos ao total de tokens
totalcUSDC += ctokensReceived;
// adição dos tokens novos aos fundos restantes
cUSDCRemaining += ctokensReceived;

return mintResult;
}

//redeem the USDC back
//resgatar USDC de volta
function redeemCErc20Tokens(uint256 amount) private returns (bool) {
uint256 redeemResult;
redeemResult = cToken.redeem(amount);
return true;
}

// função para visualizar os premios dos holders
function getHolderRewards(uint256 _stage) external view returns(uint256){
return holderRewardsPerStage[_stage];
}

}
