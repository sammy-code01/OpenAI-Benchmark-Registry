;; OpenAI Benchmark Registry
;; Decentralized leaderboard for AI model performance tracking

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-already-exists (err u302))
(define-constant err-invalid-score (err u303))
(define-constant err-unauthorized (err u304))

;; Data Variables
(define-data-var benchmark-count uint u0)
(define-data-var submission-count uint u0)
(define-data-var comment-count uint u0)
(define-data-var category-count uint u0)
(define-data-var platform-fee uint u100) ;; 1% fee in basis points
(define-data-var contract-paused bool false)

;; Data Maps
(define-map benchmarks uint
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    max-score: uint,
    created-by: principal,
    created-at: uint
  }
)

(define-map submissions uint
  {
    benchmark-id: uint,
    model-name: (string-ascii 50),
    submitter: principal,
    score: uint,
    result-hash: (buff 32),
    verified: bool,
    submitted-at: uint
  }
)

(define-map model-verifiers principal bool)

(define-map benchmark-categories uint
  {
    category-name: (string-ascii 50),
    description: (string-ascii 150)
  }
)

(define-map benchmark-to-category uint uint)

(define-map submitter-reputation principal
  {
    total-submissions: uint,
    verified-submissions: uint,
    total-score: uint,
    reputation-points: uint
  }
)

(define-map submission-comments uint
  {
    submission-id: uint,
    commenter: principal,
    comment: (string-ascii 500),
    commented-at: uint
  }
)

;; Read-only functions
(define-read-only (get-benchmark (benchmark-id uint))
  (map-get? benchmarks benchmark-id)
)

(define-read-only (get-submission (submission-id uint))
  (map-get? submissions submission-id)
)

(define-read-only (is-verifier (address principal))
  (default-to false (map-get? model-verifiers address))
)

(define-read-only (get-benchmark-count)
  (ok (var-get benchmark-count))
)

(define-read-only (get-submission-count)
  (ok (var-get submission-count))
)

(define-read-only (get-category (category-id uint))
  (map-get? benchmark-categories category-id)
)

(define-read-only (get-benchmark-category (benchmark-id uint))
  (map-get? benchmark-to-category benchmark-id)
)

(define-read-only (get-submitter-reputation (submitter principal))
  (default-to 
    { total-submissions: u0, verified-submissions: u0, total-score: u0, reputation-points: u0 }
    (map-get? submitter-reputation submitter)
  )
)

(define-read-only (get-comment (comment-id uint))
  (map-get? submission-comments comment-id)
)

(define-read-only (get-platform-fee)
  (ok (var-get platform-fee))
)

(define-read-only (calculate-reputation-score (total-submissions uint) (verified-submissions uint) (total-score uint))
  (ok (+ (* verified-submissions u10) (/ total-score u100)))
)

(define-read-only (get-top-score-for-benchmark (benchmark-id uint))
  ;; This would need to iterate through submissions in practice
  ;; For now, returns a placeholder structure
  (ok { highest-score: u0, model-name: "", submitter: contract-owner })
)

(define-read-only (is-paused)
  (ok (var-get contract-paused))
)

;; Helper function to check if contract is active
(define-private (check-contract-active)
  (not (var-get contract-paused))
)

;; #[allow(unchecked_data)]
(define-public (create-category (category-name (string-ascii 50)) (description (string-ascii 150)))
  (let
    (
      (category-id (var-get category-count))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set benchmark-categories category-id
      {
        category-name: category-name,
        description: description
      }
    )
    (var-set category-count (+ category-id u1))
    (ok category-id)
  )
)

(define-public (assign-benchmark-to-category (benchmark-id uint) (category-id uint))
  (begin
    (asserts! (is-some (map-get? benchmarks benchmark-id)) err-not-found)
    (asserts! (is-some (map-get? benchmark-categories category-id)) err-not-found)
    (map-set benchmark-to-category benchmark-id category-id)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (add-comment (submission-id uint) (comment (string-ascii 500)))
  (let
    (
      (comment-id (var-get comment-count))
      (submission-data (unwrap! (map-get? submissions submission-id) err-not-found))
    )
    (map-set submission-comments comment-id
      {
        submission-id: submission-id,
        commenter: tx-sender,
        comment: comment,
        commented-at: stacks-block-height
      }
    )
    (var-set comment-count (+ comment-id u1))
    (ok comment-id)
  )
)

;; #[allow(unchecked_data)]
(define-public (increment-submitter-reputation (submitter principal) (score uint) (verified bool))
  (let
    (
      (current-rep (get-submitter-reputation submitter))
      (new-total-submissions (+ (get total-submissions current-rep) u1))
      (new-verified-count (if verified
        (+ (get verified-submissions current-rep) u1)
        (get verified-submissions current-rep)))
      (new-total-score (+ (get total-score current-rep) score))
    )
    (map-set submitter-reputation submitter
      {
        total-submissions: new-total-submissions,
        verified-submissions: new-verified-count,
        total-score: new-total-score,
        reputation-points: (+ (* new-verified-count u10) (/ new-total-score u100))
      }
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set model-verifiers verifier true)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set model-verifiers verifier false)
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (toggle-verifier (verifier principal))
  (let
    (
      (current-status (is-verifier verifier))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set model-verifiers verifier (not current-status))
    (ok (not current-status))
  )
)

(define-public (update-benchmark-description (benchmark-id uint) (new-description (string-ascii 200)))
  (let
    (
      (benchmark-data (unwrap! (map-get? benchmarks benchmark-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get created-by benchmark-data)) err-unauthorized)
    (map-set benchmarks benchmark-id
      (merge benchmark-data { description: new-description })
    )
    (ok true)
  )
)

(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u1000) err-invalid-score) ;; Max 10% fee
    (var-set platform-fee new-fee)
    (ok true)
  )
)

(define-public (delete-submission (submission-id uint))
  (let
    (
      (submission-data (unwrap! (map-get? submissions submission-id) err-not-found))
    )
    (asserts! (or 
      (is-eq tx-sender (get submitter submission-data))
      (is-eq tx-sender contract-owner)
    ) err-unauthorized)
    (map-delete submissions submission-id)
    (ok true)
  )
)

(define-public (update-submission-score (submission-id uint) (new-score uint))
  (let
    (
      (submission-data (unwrap! (map-get? submissions submission-id) err-not-found))
      (benchmark-data (unwrap! (map-get? benchmarks (get benchmark-id submission-data)) err-not-found))
    )
    (asserts! (is-verifier tx-sender) err-unauthorized)
    (asserts! (<= new-score (get max-score benchmark-data)) err-invalid-score)
    (map-set submissions submission-id
      (merge submission-data { score: new-score })
    )
    (ok true)
  )
)

(define-public (archive-benchmark (benchmark-id uint))
  (let
    (
      (benchmark-data (unwrap! (map-get? benchmarks benchmark-id) err-not-found))
    )
    (asserts! (or 
      (is-eq tx-sender (get created-by benchmark-data))
      (is-eq tx-sender contract-owner)
    ) err-unauthorized)
    ;; In a real implementation, we'd add an 'archived' field
    ;; For now, we'll just return success
    (ok true)
  )
)

(define-public (reward-top-performer (benchmark-id uint) (reward-amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? benchmarks benchmark-id)) err-not-found)
    ;; In a real implementation, this would identify top performer and send reward
    ;; This is a placeholder
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (submit-with-metadata 
  (benchmark-id uint) 
  (model-name (string-ascii 50)) 
  (score uint) 
  (result-hash (buff 32))
  (metadata (string-ascii 200)))
  (let
    (
      (benchmark-data (unwrap! (map-get? benchmarks benchmark-id) err-not-found))
      (submission-id (var-get submission-count))
    )
    (asserts! (<= score (get max-score benchmark-data)) err-invalid-score)
    (map-set submissions submission-id
      {
        benchmark-id: benchmark-id,
        model-name: model-name,
        submitter: tx-sender,
        score: score,
        result-hash: result-hash,
        verified: false,
        submitted-at: stacks-block-height
      }
    )
    (var-set submission-count (+ submission-id u1))
    ;; Store metadata as a comment
    (unwrap-panic (add-comment submission-id metadata))
    (ok submission-id)
  )
)

(define-public (bulk-create-benchmarks (benchmarks-data (list 5 { name: (string-ascii 50), desc: (string-ascii 200), max: uint })))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map create-single-benchmark benchmarks-data))
  )
)

(define-private (create-single-benchmark (data { name: (string-ascii 50), desc: (string-ascii 200), max: uint }))
  (let
    (
      (benchmark-id (var-get benchmark-count))
    )
    (map-set benchmarks benchmark-id
      {
        name: (get name data),
        description: (get desc data),
        max-score: (get max data),
        created-by: tx-sender,
        created-at: stacks-block-height
      }
    )
    (var-set benchmark-count (+ benchmark-id u1))
    benchmark-id
  )
)

;; Emergency pause functionality
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused false)
    (ok true)
  )
)