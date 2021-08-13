// SPDX-License-Identifier: MIT

/*
 * Copyright © 2020 reflect.finance. ALL RIGHTS RESERVED.
 */

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Dealz is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    address public teamAddress;
    address public advisorAddress;
    address public operationAddress;
    address public governanceAddress;
    address public stakingAddress;
    address public privatesaleAddress;
    address public publicAddress;
    address public grantAddress;
    uint public unlockDate;
    address[] internal stakeholders;
    address[] internal teams;

    mapping(address => uint256) internal stakes;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 2 * (10**9) * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private _name = 'Dealz';
    string private _symbol = 'DLZ';
    uint8 private _decimals = 9;

    constructor(    
    address _teamAddress,
    address _advisorAddress,
    address _operationAddress,
    address _governanceAddress,
    address _stakingAddress,
    address _privatesaleAddress,
    address _publicAddress,
    address _grantAddress) public {
      teamAddress = _teamAddress;
      advisorAddress = _advisorAddress;
      operationAddress = _operationAddress;
      governanceAddress = _governanceAddress;
      stakingAddress = _stakingAddress;
      privatesaleAddress = _privatesaleAddress;
      publicAddress = _publicAddress;
      grantAddress = _grantAddress;
      uint256 totalSupply = _rTotal-_tTotal-_rTotal;
      
        //mint all tokens according to token economics
      _rOwned[teamAddress] = totalSupply.div(10).mul(3);
      _rOwned[operationAddress] = totalSupply.div(10).mul(1);
      _rOwned[advisorAddress] = totalSupply.div(100).mul(3);
      _rOwned[governanceAddress] = totalSupply.div(20).mul(1);
      _rOwned[stakingAddress] = totalSupply.div(5).mul(1);
      _rOwned[privatesaleAddress] = totalSupply.div(20).mul(1);
      _rOwned[publicAddress] = totalSupply.div(100).mul(23);
      _rOwned[grantAddress] = totalSupply.div(25).mul(1);

      emit Transfer(address(0), teamAddress, _tTotal.div(10).mul(3));
      emit Transfer(address(0), advisorAddress, _tTotal.div(100).mul(3));
      emit Transfer(address(0), operationAddress, _tTotal.div(10).mul(1));
      emit Transfer(address(0), governanceAddress, _tTotal.div(20).mul(1));
      emit Transfer(address(0), stakingAddress, _tTotal.div(5).mul(1));
      emit Transfer(address(0), privatesaleAddress, _tTotal.div(20).mul(1));
      emit Transfer(address(0), publicAddress, _tTotal.div(100).mul(23));
      emit Transfer(address(0), grantAddress, _tTotal.div(25).mul(1));

      teams.push(teamAddress);
      teams.push(advisorAddress);
      teams.push(operationAddress);
      teams.push(governanceAddress);
      teams.push(stakingAddress);
      teams.push(privatesaleAddress);
      teams.push(publicAddress);
      teams.push(grantAddress);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_rOwned[_msgSender()] >= amount, "ERC20: burn amount exceeds balance");
        uint256 currentRate =  _getRate();
        _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(amount.mul(currentRate));
        emit Transfer(_msgSender(), address(0), amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        uint256 currentRate =  _getRate();
        _rOwned[_msgSender()] = _rOwned[_msgSender()].add(amount.mul(currentRate));
        emit Transfer(_msgSender(), address(0), amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        (uint256 total_StakingAmount,uint256 total_RecipientAmount,uint256 stakingFee,uint256 recipientFee) = _getStakingValue(tAmount,tTransferAmount,rAmount,rTransferAmount); 
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[stakingAddress] = _rOwned[stakingAddress].add(stakingFee);
        _rOwned[recipient] = _rOwned[recipient].add(recipientFee);       
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, total_RecipientAmount);
        emit Transfer(sender, stakingAddress, total_StakingAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        (uint256 total_StakingAmount,uint256 total_RecipientAmount,uint256 stakingFee,uint256 recipientFee) = _getStakingValue(tAmount,tTransferAmount,rAmount,rTransferAmount); 
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(total_RecipientAmount);
        _rOwned[recipient] = _rOwned[recipient].add(recipientFee); 
        _rOwned[stakingAddress] = _rOwned[stakingAddress].add(stakingFee);
        _tOwned[stakingAddress] = _tOwned[stakingAddress].add(stakingFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, total_RecipientAmount);
        emit Transfer(sender, recipient, total_StakingAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        (uint256 total_StakingAmount,uint256 total_RecipientAmount,uint256 stakingFee,uint256 recipientFee) = _getStakingValue(tAmount,tTransferAmount,rAmount,rTransferAmount); 
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(recipientFee);   
        _rOwned[stakingAddress] = _rOwned[stakingAddress].add(stakingFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, total_RecipientAmount);
        emit Transfer(sender, recipient, total_StakingAmount);    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        (uint256 total_StakingAmount,uint256 total_RecipientAmount,uint256 stakingFee,uint256 recipientFee) = _getStakingValue(tAmount,tTransferAmount,rAmount,rTransferAmount); 
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(total_RecipientAmount);
        _rOwned[recipient] = _rOwned[recipient].add(recipientFee);     
        _rOwned[stakingAddress] = _rOwned[stakingAddress].add(stakingFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, total_RecipientAmount);
        emit Transfer(sender, recipient, total_StakingAmount);    }
    
    function _getStakingValue(uint256 tAmount,uint256 tTransferAmount,uint256 rAmount,uint256 rTransferAmount) private pure returns(uint256,uint256,uint256,uint256){
        uint256 total_StakingAmount = tAmount.div(1000).mul(25);
        uint256 total_RecipientAmount = tTransferAmount.sub(total_StakingAmount);
        uint256 stakingFee = rAmount.div(1000).mul(25);
        uint256 recipientFee = rTransferAmount.sub(stakingFee);
        return (total_StakingAmount,total_RecipientAmount,stakingFee,recipientFee);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }
    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee = tAmount.div(1000).mul(25);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function createStake(uint256 _stake,uint _unlockDate)
        public
    {
        require(
            block.timestamp+30 days <= _unlockDate,
            "Invalid token Expiry date"
        );
        require(
            _stake != 500000 * (10**9), "Lawyer must stake 0.025%"
        );
        _burn(msg.sender, _stake);
        unlockDate = _unlockDate;
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }
    
    function createVestingAdmin(uint256 _stake,uint _unlockDate, address _address)
        public 
    {
        require(isTeamholder(),'not a team member address');
        _burn(msg.sender, _stake);
        unlockDate = _unlockDate;
        if(stakes[_address] == 0) addStakeholder(_address);
        stakes[_address] = stakes[_address].add(_stake);
    }
    function removeStakeAdmin(uint256 _stake, address _address)
        public
    {   
        require(block.timestamp >= unlockDate, 'Cannot withdraw before unlockDate');
        stakes[_address] = stakes[_address].sub(_stake);
        if(stakes[_address] == 0) removeStakeholder(_address);
        _mint(_address, _stake);
    }
    function addStakeholder(address _stakeholder)
        public
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }
    function isTeamholder()
        public 
        view 
        returns(bool)
    {
        for (uint256 s = 0; s < teams.length; s += 1){
            if (msg.sender == teams[s]) return (true);
        }
        return (false);
    }
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }
    function removeStakeholder(address _stakeholder)
        public
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }
    function buyContract(address recipient, uint256 amount)public{
        
    }
}