
;; VaultAuthorization
(impl-trait .IVault-trait.ivault-trait)

;; <add a description here>
;; constants

(define-type-alias hashtype (string-ascii 256))

;;

(define-constant _JOIN_TYPE_HASH '0x3f7b71252bd19113ff48c19c6e004a9bcfcca320a0d74d58e85877cbd7dcae58)
;; _JOIN_TYPE_HASH = keccak256("JoinPool(bytes calldata,address sender,uint256 nonce,uint256 deadline)");

    ;; // _EXIT_TYPE_HASH = keccak256("ExitPool(bytes calldata,address sender,uint256 nonce,uint256 deadline)");
    ;; bytes32 private constant _EXIT_TYPE_HASH = 0x8bbc57f66ea936902f50a71ce12b92c43f3c5340bb40c27c4e90ab84eeae3353;

    ;; // _SWAP_TYPE_HASH = keccak256("Swap(bytes calldata,address sender,uint256 nonce,uint256 deadline)");
    ;; bytes32 private constant _SWAP_TYPE_HASH = 0xe192dcbc143b1e244ad73b813fd3c097b832ad260a157340b4e5e5beda067abe;

    ;; // _BATCH_SWAP_TYPE_HASH = keccak256("BatchSwap(bytes calldata,address sender,uint256 nonce,uint256 deadline)");
    ;; bytes32 private constant _BATCH_SWAP_TYPE_HASH = 0x9bfc43a4d98313c6766986ffd7c916c7481566d9f224c6819af0a53388aced3a;

    ;; // _SET_RELAYER_TYPE_HASH =
    ;; //     keccak256("SetRelayerApproval(bytes calldata,address sender,uint256 nonce,uint256 deadline)");
    ;; bytes32
    ;;     private constant _SET_RELAYER_TYPE_HASH = 0xa3f865aa351e51cfeb40f5178d1564bb629fe9030b83caf6361d1baaf5b90b5a;

    ;; IAuthorizer private _authorizer;

;; data maps and vars
;;

;; private functions
;;

;; public functions
;;
