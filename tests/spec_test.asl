(module asl-contracts/tests/spec-test
  :d "Unit tests for pure functional smart contract specification, address checks, and transition invariants."
  :x [test-address-validation test-block-context test-transition-result test-balance-invariant run-tests]
  :i [(spec :a s)])

(df test-address-validation [] -> Bool
  :d "Verifies 0x-prefixed 42-character address validator."
  (let [(valid "0x1234567890123456789012345678901234567890")
        (invalid-prefix "123456789012345678901234567890123456789012")
        (invalid-len "0x1234")]
    (assert (s/is-valid-address valid) "Valid 42-char address must pass")
    (assert (not (s/is-valid-address invalid-prefix)) "Address without 0x prefix must fail")
    (assert (not (s/is-valid-address invalid-len)) "Address with wrong length must fail")
    true))

(df test-block-context [] -> Bool
  :d "Verifies execution block context construction."
  (let [(sender "0x0000000000000000000000000000000000000001")
        (ctx (s/make-block-context sender 1000000 1725573000 12500000))]
    (assert (= (.-sender ctx) sender) "Sender must match")
    (assert (= (.-value ctx) 1000000) "Value must match 1000000")
    (assert (= (.-timestamp ctx) 1725573000) "Timestamp must match 1725573000")
    (assert (= (.-height ctx) 12500000) "Block height must match 12500000")
    true))

(df test-transition-result [] -> Bool
  :d "Verifies success and revert outcomes in contract transitions."
  (let [(event (s/ContractEvent :name "Transfer" :data "from=0x1,to=0x2,amount=50"))
        (succ (s/transition-success (list event)))
        (rev (s/transition-revert "Insufficient funds"))]
    (assert (.-success succ) "Transition success must have success true")
    (assert (= (list-length (.-events succ)) 1) "Transition success must have 1 event")
    (assert (not (.-success rev)) "Transition revert must have success false")
    (assert (= (.-error-msg rev) "Insufficient funds") "Transition revert error must match")
    true))

(df test-balance-invariant [] -> Bool
  :d "Verifies non-negative balance guard prevents underflow."
  (assert (s/validate-non-negative-balance 0) "Zero balance must be valid")
  (assert (s/validate-non-negative-balance 500) "Positive balance must be valid")
  (assert (not (s/validate-non-negative-balance -1)) "Negative balance must be invalid")
  true)

(df run-tests [] -> Bool
  :d "Executes full contract specification test suite."
  (let [(_t1 (test-address-validation))
        (_t2 (test-block-context))
        (_t3 (test-transition-result))
        (_t4 (test-balance-invariant))]
    true))
