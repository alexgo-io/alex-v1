(define-trait semi-fungible-token-trait
	(
		;; Get a token type balance of the passed principal.
		(get-balance (uint principal) (response uint uint))

		;; Get the total SFT balance of the passed principal.
		(get-overall-balance (principal) (response uint uint))

		;; Get the current total supply of a token type.
		(get-total-supply (uint) (response uint uint))

		;; Get the overall SFT supply.
		(get-overall-supply () (response uint uint))

		;; Get the number of decimal places of a token type.
		(get-decimals (uint) (response uint uint))

		;; Get an optional token URI that represents metadata for a specific token.
		(get-token-uri (uint) (response (optional (string-utf8 256)) uint))

		;; Transfer from one principal to another.
		(transfer (uint uint principal principal) (response bool uint))

		;; Transfer from one principal to another with a memo.
		(transfer-memo (uint uint principal principal (buff 34)) (response bool uint))

		;; Transfer many tokens at once.
		(transfer-many ((list 200 {token-id: uint, amount: uint, sender: principal, recipient: principal})) (response bool uint))

		;; Transfer many tokens at once with memos.
		(transfer-many-memo ((list 200 {token-id: uint, amount: uint, sender: principal, recipient: principal, memo: (buff 34)})) (response bool uint))

    	(mint (uint uint principal) (response bool uint))    
    	(burn (uint uint principal) (response bool uint))

		;; helper functions for 8-digit fixed notation
		(transfer-fixed (uint uint principal principal) (response bool uint))
    	(get-balance-fixed (uint principal) (response uint uint))
    	(get-total-supply-fixed (uint) (response uint uint))
		(get-overall-balance-fixed (uint principal) (response uint uint))
		(get-total-supply-fixed (uint uint) (response uint uint))
		(get-overall-supply (uint) (response uint uint))	
		(mint-fixed (uint principal) (response bool uint))
		(burn-fixed (uint principal) (response bool uint))    		
	)
)