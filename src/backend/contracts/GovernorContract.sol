// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Governor - O contrato principal que contém toda a lógica e primitivas. É abstrato e requer a escolha de um de cada um dos módulos abaixo
import "@openzeppelin/contracts/governance/Governor.sol";
// GovernorCountingSimple - Mecanismo de votação simples com 3 opções de votação: Contra, A favor e Abstenção.
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
// GovernorVotes - Extrai o peso do voto de um ERC20Votestoken.
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
// GovernorVotesQuorumFraction - Combina com GovernorVotes para definir o quorum como uma fração do fornecimento total de tokens.
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
// GovernorTimelockControl - Conecta-se a uma instância do TimelockController. Permite múltiplos proponentes e executores, além do próprio Governador.
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
// GovernorSettings - gerencia algumas das configurações (atraso de votação, duração do período de votação e limite de proposta), 
// de forma que possam ser atualizadas por meio de uma proposta de governança, sem a necessidade de atualização.
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";

// Contrato das regras de governança da DAO
// eranca dos contratos da openzeppelin acima
contract GovernorContract is
  Governor,
  GovernorSettings,
  GovernorCountingSimple,
  GovernorVotes,
  GovernorVotesQuorumFraction,
  GovernorTimelockControl
{
// Estrutura para cada proposta, Id e a proposta
  struct EachProposal{
    uint256 proposalId;
    string description;
  }

  uint256 public proposalNum;
  mapping(uint256 => EachProposal) public allProposals;
  // TODO: should we pass in the voring delap and period and hardcode proposal threshol to 0?
  // No construtor as variaveis de estado separa-se, o delay e o period sofrem alteracoes realizadas pelo governador
  // as demais sao utilizadas de forma autonoma pelos contratos de eranca
  constructor(
    IVotes _token,
    TimelockController _timelock,
    uint256 _quorumPercentage,
    uint256 _votingPeriod,
    uint256 _votingDelay
  )
    Governor("GovernorContract")
    GovernorSettings(
      _votingDelay,
      _votingPeriod,
      0
    )
    GovernorVotes(_token)
    GovernorVotesQuorumFraction(_quorumPercentage)
    GovernorTimelockControl(_timelock)
  {}

  // Atraso, em número de bloco, entre a criação da proposta e o início da votação. 
  // Isso pode ser aumentado para deixar tempo para os usuários comprarem o poder de voto, ou delegá-lo, antes do início da votação de uma proposta
  function votingDelay()
    public
    view
    override(IGovernor, GovernorSettings)
    returns (uint256)
  {
    return super.votingDelay();
  }
  // Atraso, em número de blocos, entre o início e o término da votação.
  function votingPeriod()
    public
    view
    override(IGovernor, GovernorSettings)
    returns (uint256)
  {
    return super.votingPeriod();
  }

  // Número mínimo de elenco votado necessário para que uma proposta seja bem-sucedida. 
  // Nota: O blockNumberparâmetro corresponde ao instantâneo usado para contagem de votos.
  // Isso permite dimensionar o quorum dependendo de valores como o totalSupply de um token neste bloco
  function quorum(uint256 blockNumber)
    public
    view
    override(IGovernor, GovernorVotesQuorumFraction)
    returns (uint256)
  {
    return super.quorum(blockNumber);
  }

  // Poder de voto de uma account em um específico blockNumber. 
  function getVotes(address account, uint256 blockNumber)
    public
    view
    override(IGovernor, Governor)
    returns (uint256)
  {
    return super.getVotes(account, blockNumber);
  }

  //  Estado atual de uma proposta, seguindo a convenção de Composto
  function state(uint256 proposalId)
    public
    view
    override(Governor, GovernorTimelockControl)
    returns (ProposalState)
  {
    return super.state(proposalId);
  }

  // Criacao de uma nova proposta, atribuindo uma nova id e descricao
  function propose(address[] memory targets,uint256[] memory values,bytes[] memory calldatas, string memory description
  ) public override(Governor, IGovernor) returns (uint256) {
    uint256 id = super.propose(targets, values, calldatas, description);
    proposalNum++;
    EachProposal storage prop = allProposals[proposalNum];
    prop.proposalId = id;
    prop.description = description;
    return id;
  }

  // Busca as propostas do contrato pelo Id
  function getAllProposals(uint256 _num) public view returns(EachProposal memory){
      return allProposals[_num];
  }

  // Parte da interface do Governador Holder: "O número de votos necessários para que um eleitor se torne um proponente"
  function proposalThreshold()
    public
    view
    override(Governor, GovernorSettings)
    returns (uint256)
  {
    return super.proposalThreshold();
  }

  // Mecanismo interno de execução.
  function _execute(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) {
    super._execute(proposalId, targets, values, calldatas, descriptionHash);
  }

  // Mecanismo interno de cancelamento: trava o cronômetro da proposta, impedindo que ela seja reenviada. 
  // Marca-a como cancelada para permitir distingui-la das propostas executadas.
  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
    return super._cancel(targets, values, calldatas, descriptionHash);
  }

  // Endereço através do qual o governador executa a ação. 
  // Será sobrecarregado por módulos que executam ações por meio de outro contrato, como um timelock.
  function _executor()
    internal
    view
    override(Governor, GovernorTimelockControl)
    returns (address)
  {
    return super._executor();
  }

  
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(Governor, GovernorTimelockControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}