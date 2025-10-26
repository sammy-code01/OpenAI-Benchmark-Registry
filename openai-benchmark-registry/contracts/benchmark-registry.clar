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