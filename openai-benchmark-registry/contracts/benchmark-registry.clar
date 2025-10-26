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