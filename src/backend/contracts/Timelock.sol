// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/TimelockController.sol";

// minDelay - quanto tempo você tem que esperar até executar
// Módulo de contrato que atua como um controlador timelocked. Quando definido como proprietário de um Ownablecontrato inteligente, 
// ele impõe um timelock em todas onlyOwneras operações de manutenção. 
// Isso dá tempo para que os usuários do contrato controlado saiam antes que uma operação de manutenção potencialmente perigosa seja aplicada.
contract TimeLock is TimelockController {
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors
  ) TimelockController(minDelay, proposers, executors) {}
}