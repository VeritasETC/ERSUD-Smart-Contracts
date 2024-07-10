// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Managing all common errors of entire project
/// @author Syed Mokarram
/// @notice a returnError method is used thorughout the project to return the responce 
/// which includes status and ErrorMessage.
/// @dev Add all error constants here 
library ErrorHandler {
    
   struct ErrorDTO{
       uint256 code;
   }

   string constant ONLY_OWNER ="1001";
   string constant NOT_AUTHORIZED_1 = "ERUSD/1011";
   string constant NOT_AUTHORIZED_3 = "ERUSDJOIN/1024";
   string constant NOT_AUTHORIZED_4 = "ETHCJOIN/1025";
   string constant NOT_AUTHORIZED_5 = "ETHCJOIN/1029";
   string constant NOT_AUTHORIZED_6 = "VAULT/1030";
   string constant NOT_AUTHORIZED_7 = "Oracle/1033";

   string constant NOT_FOUND ="1002";
   string constant OVERFLOW_PAGE ="1003";
   string constant DUPLICATE_ENTRY ="1004";
   string constant NOT_AN_ADMIN ="1005";
   string constant ZERO_ADDRESS ="1006";
   string constant ID_DOES_NOT_EXISTS ="1007";
   string constant INVALID_RATIO = "Actions/1008";
   string constant INVALID_ETH_AMOUNT = "Actions/1009";
   string constant LESS_ETH_AMOUNT = "Actions/1010";
   string constant INVALID_TAX_AMOUNT = "Actions/1012";
   string constant ZERO_AMOUNT = "ERUSDJoin/1013";
   
   string constant NOT_LIVE_1 = "ERUSDJoin/1014";
   string constant NOT_LIVE_2 = "ERUSDJoin/1023";
   string constant NOT_LIVE_3 = "ETHCJoin/1026";
   string constant NOT_LIVE_4 = "TransacionHistory/1028";
   string constant NOT_LIVE_5 = "TransacionHistory/1031";

   string constant OVERFLOW_AMOUNT_1 = "ERUSDJOIN/1015";
   string constant OVERFLOW_AMOUNT_2 = "ETHCJOIN/1027";

   string constant INVALID_AMOUNT = "ETHJOIN/1016";
   string constant INVALID_BORROW_AMOUNT = "VAULT/1017";
   string constant INVALID_COLLATERAL_AMOUNT = "VAULT/1018";
   string constant OVER_FLOW = "TRANSHISTORY/1019";
   string constant UNDER_FLOW = "TRANSHISTORY/1020";
   string constant INVALID_APY = "Actions/1021";
   string constant NOT_AUTHORIZED_2 = "APY/1022";

   string constant NOT_ENOUGH_COLLATERAL = "ACTIONS/1032";

   string constant ALREADY_OPERATOR = "Oracle/1034";
   string constant ALREADY_REMOVED = "Oracle/1035";

   string constant Vault_OVER_FLOW = "VAULT/1036";
   
   string constant Vault_UNDER_FLOW = "TRANSHISTORY/1037";

   string constant INSUFFICIENT_FUND = "ACTION/1038";  

   string constant INVALID_APY_AMOUNT = "ACTION/1039";  

   string constant NO_COLLATERAL = "ACTION/1040";

   string constant SET_SWAP_CONTRACT = "LIQUIDATION/1041";  

   string constant NOT_AUTHORIZED_8 = "LIQUIDATION/1042";  

   string constant CANNOT_LIQUIDATE = "LIQUIDATION/1043";  

   string constant EMPTY_MASTER_WALLLET = "LIQUIDATION/1044";

   string constant INVALID_PENALTY_AMOUNT = "LIQUIDATION/1045";  

   string constant ERUSD_MUST_BURN = "VAULT/1046";  

   string constant INVALID_FEE_AMOUNT = "VAULT/1047";  

   string constant NOT_AUTHORIZED_9 = "LIQUIDATION/1048";  
   string constant NOT_AUTHORIZED_10 = "APY_MAPPER/1049";  
   string constant NOT_AUTHORIZED_11 = "APY_FACTORY/1050";  
   string constant NOT_LIVE_6 = "APY/1051";
}