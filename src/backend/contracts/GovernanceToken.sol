// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface EscrowContract{
function supplyErc20ToCompound(uint256 _numTokensToSupply) external returns (uint256);
function getHolderRewards(uint256 _stage) external view returns (uint256);
}

// Contrato do token de governaça
contract GovernanceToken is ERC20Votes {
// Numero maximo de tokens
uint256 public maxSupply = 1000000 * 10**18;
// chamada do contrato do USDC
IERC20 public USDC;
// contrato de garantia que pode fornecer fundos e consultar as recompensas
EscrowContract public escrowContract;
// endereço do contrato de garantia
address public escrow;
// Mapa dos endereços com seus depositos
mapping(address => mapping(uint256 => bool)) public isInterestClaimed;

// construção do token de governanca e a garantia em USDC //ERC20Permit refere-se ao endereco executar permissoes
// recebe como argumento o endereço de contrato da garantia _escrow
constructor(address _escrow)
ERC20("GovernanceToken", "GT")
ERC20Permit("GovernanceToken")
{
    
USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
escrowContract = EscrowContract(_escrow);
escrow = _escrow;
}

//Approve this contract address(GovernanceToken) in USDC before executing this function
// Aprove este endereço de contrato (GovernanceToken) no USDC antes de executar esta função
// Envie USDC e realize o mint
function sendUSDCandMint(uint256 _amountInUSDC) public {
//Transfering USDC to this contract address
// transferindo USDC para este endereço de contrato
USDC.transferFrom(msg.sender, escrow, _amountInUSDC);
//GOV - decimal is 18 and for USDC it's 6. (conversao)
uint256 amountToMint = _amountInUSDC * 10**12; //not sure if this is fine (conferir esta conta, vi um post no redit que confirma isso)
// Funcao mint: cunhagem da quantidade de USDC ao contrato
_mint(msg.sender, amountToMint);
// fornecendo o valor de garantia ao Compound
escrowContract.supplyErc20ToCompound(_amountInUSDC);
}

// Reivindicar juros: necessita do estagio atual como argumento
function claimInterest(uint256 _stage) public {
// verifica se quem chama a funcao ja fez o resgate no estagio atual
require(isInterestClaimed[msg.sender][_stage] == false, "You have already claimed your interest for this campaign");
// verifica se quem chama a funcao possui saldo
require(balanceOf(msg.sender) > 0, "You are not authorized");
// total de juros
uint256 totalInterest = escrowContract.getHolderRewards(_stage);
// Percentual da sua participação no total fornecido (banca)
uint256 tokenPercent = (balanceOf(msg.sender)*100)/totalSupply();
// Sua parte = juros * participação
uint256 yourShare = (totalInterest*tokenPercent)/100;
// transferencia da sua parte para o seu endereço
USDC.transfer(msg.sender, yourShare);
// passa para o estado true apos resgatar os juros (as recompensas)
isInterestClaimed[msg.sender][_stage] = true;
}


function _afterTokenTransfer(
address from,
address to,
uint256 amount
) internal override(ERC20Votes) {
super._afterTokenTransfer(from, to, amount);
}

// Função para mint (cunhagem)
function _mint(address to, uint256 amount) internal override(ERC20Votes) {
super._mint(to, amount);
}

// Funcao para queima de tokens
function _burn(address account, uint256 amount)
internal
override(ERC20Votes)
{
super._burn(account, amount);
}

// Função para receber fundos
receive() external payable{}

}
