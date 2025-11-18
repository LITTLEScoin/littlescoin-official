// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LITTLES ($LITL)
 * @notice BEP-20 (ERC-20 compatível) com taxas automáticas de doação e criador.
 * Supply fixo: 1,000,000 LITL
 * Taxas padrão: 3% doação + 2% criador (total 5%)
 */
contract LITTLES is ERC20, Ownable {
    // ===== Parâmetros de taxa (em basis points: 100 = 1%) =====
    uint16 public charityFeeBps = 300;  // 3.00%
    uint16 public creatorFeeBps = 200;  // 2.00%
    uint16 public constant MAX_TOTAL_FEE_BPS = 500; // teto de 5.00%

    // ===== Carteiras =====
    address public charityWallet; // recebe doações
    address public creatorWallet; // recebe taxa do criador

    // ===== Controles =====
    bool public feesEnabled = true; // pode pausar taxas em emergência

    // isenções de taxa (ex.: router, par de liquidez, carteiras específicas)
    mapping(address => bool) public isFeeExempt;

    event FeesUpdated(uint16 charityFeeBps, uint16 creatorFeeBps);
    event WalletsUpdated(address indexed charity, address indexed creator);
    event FeesEnabled(bool enabled);
    event FeeExemptSet(address indexed account, bool isExempt);

   constructor(
    address _charityWallet,
    address _creatorWallet
) ERC20("LITTLES", "LITL") {
    require(_charityWallet != address(0), "charity zero");
    require(_creatorWallet != address(0), "creator zero");
    charityWallet = _charityWallet;
    creatorWallet = _creatorWallet;

    // define o dono inicial do contrato
    _transferOwnership(msg.sender);

    // mint supply fixo para o owner
    uint256 total = 1_000_000 * 10 ** decimals();
    _mint(msg.sender, total);

    // owner e o próprio contrato isentos de taxa
    isFeeExempt[msg.sender] = true;
    isFeeExempt[address(this)] = true;
}

    // ===== Overrides com coleta de taxas =====
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!feesEnabled || isFeeExempt[from] || isFeeExempt[to] || amount == 0) {
            super._transfer(from, to, amount);
            return;
        }

        uint16 totalFeeBps = charityFeeBps + creatorFeeBps;
        if (totalFeeBps > 0) {
            uint256 feeAmount = (amount * totalFeeBps) / 10_000; // 10000 bps = 100%
            uint256 amountAfterFee = amount - feeAmount;

            // separa as taxas
            uint256 charityPortion = (feeAmount * charityFeeBps) / totalFeeBps;
            uint256 creatorPortion = feeAmount - charityPortion; // resto vai ao criador

            if (charityPortion > 0) {
                super._transfer(from, charityWallet, charityPortion);
            }
            if (creatorPortion > 0) {
                super._transfer(from, creatorWallet, creatorPortion);
            }
            super._transfer(from, to, amountAfterFee);
        } else {
            super._transfer(from, to, amount);
        }
    }

    // ===== Admin =====
    function setWallets(address _charity, address _creator) external onlyOwner {
        require(_charity != address(0) && _creator != address(0), "zero addr");
        charityWallet = _charity;
        creatorWallet = _creator;
        emit WalletsUpdated(_charity, _creator);
    }

    function setFees(uint16 _charityBps, uint16 _creatorBps) external onlyOwner {
        uint16 total = _charityBps + _creatorBps;
        require(total <= MAX_TOTAL_FEE_BPS, "fee too high");
        charityFeeBps = _charityBps;
        creatorFeeBps = _creatorBps;
        emit FeesUpdated(_charityBps, _creatorBps);
    }

    function setFeesEnabled(bool _enabled) external onlyOwner {
        feesEnabled = _enabled;
        emit FeesEnabled(_enabled);
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        isFeeExempt[account] = exempt;
        emit FeeExemptSet(account, exempt);
    }

    // resgate de tokens enviados por engano
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        require(token != address(this), "cannot rescue LITL");
        ERC20(token).transfer(owner(), amount);
    }
}
