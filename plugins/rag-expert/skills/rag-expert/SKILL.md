---
name: rag-expert
description: "Expert Retrieval-Augmented Generation: chunking, embeddings, vector/hybrid search, reranking, and grounded answers. Trigger keywords: RAG, retrieval, embeddings, vector database, chunking, reranking, hybrid search, BM25, grounding, citations, hallucination, context window, recall. Use to build or debug RAG pipelines and improve answer quality/faithfulness."
---

# RAG Engineering Expert

> Garbage retrieval in, hallucination out. Answer quality is bounded by what you retrieve, so fix retrieval before touching the prompt. Measure retrieval and generation separately.

## When to Use
- Building a RAG / "chat with your docs" / knowledge-assistant system.
- Tuning chunking, embeddings, retrieval, hybrid search, or reranking.
- Poor answers: missing context, wrong/irrelevant chunks, hallucinations, no citations.
- Choosing a vector store or designing metadata/filtering.

## When NOT to Use
- Prompt wording/format only → `prompt-engineering-expert`.
- Training/fine-tuning a model → `deep-learning-expert`.
- Eval harness/regression design → `llm-testing-expert`.
- Serving infra/API shape → `api-design-expert`.

## Core Principles

### 1. Ingestion & chunking
- Chunk on **semantic boundaries** (headings, paragraphs, code blocks), not fixed byte counts. Start ~256–512 tokens with ~10–15% overlap; tune per corpus.
- Preserve structure: keep tables/code intact, prepend section/title context to each chunk. Attach metadata (source, title, section, URL, timestamp, ACL) and a stable chunk ID for citations and filtering.

### 2. Retrieval quality (the highest-leverage area)
- Use a strong, task-matched embedding model; **query and document embeddings must come from the same model/version**. Re-index when you change models.
- **Hybrid search**: combine dense vectors with keyword/BM25 and fuse (e.g., RRF). Pure vector search misses exact terms — error codes, names, IDs, acronyms.
- Add a **cross-encoder reranker** over the top ~20 candidates and keep the top ~3–5. This is usually the biggest single quality win.
- Apply metadata filters (tenant, recency, doc type, ACL) — and enforce access control at retrieval, never just in the prompt.

### 3. Generation & grounding
- Pass only the reranked chunks that fit a sensible context budget (more is not better — it dilutes and raises cost/latency). Mark each with a source id.
- Instruct the model to answer **only** from context, **cite** sources, and say "I don't know" when context is insufficient. Return citations to the user for verifiability.

### 4. Evaluate & iterate
- Measure retrieval (recall@k, MRR, hit-rate) and generation (faithfulness/groundedness, answer relevance) **separately** on a labeled set. Low recall → fix chunking/retrieval/reranking; high recall but bad answers → fix the prompt/context budget.

## Decision Guide
| Symptom | Likely fix |
|---------|-----------|
| Right doc never retrieved | better embeddings, hybrid search, smaller/structured chunks |
| Retrieved but answer ignores it | reranker, fewer/cleaner chunks, stronger grounding prompt |
| Misses exact codes/names | add keyword/BM25 (hybrid) |
| Confident but wrong | enforce "answer only from context" + citations + "I don't know" |
| Slow/expensive | fewer chunks, cache embeddings, smaller reranker, pre-filter |

## Common Mistakes
- **Fixed-size character chunking** that splits sentences/tables → semantic chunking + overlap.
- **Mismatched query/doc embedding models** → silently poor recall.
- **Vector-only search** → misses exact-match terms; go hybrid.
- **No reranker** → top-k is noisy; cross-encoder rerank.
- **Stuffing 50 chunks into context** → dilution, cost, lost-in-the-middle; retrieve more, send few.
- **No citations / no "I don't know" path** → unverifiable, hallucination-prone.
- **ACL only in the prompt** → data leakage; filter at retrieval.

## Examples

**Retrieve → hybrid → rerank → grounded prompt**
```python
dense = store.search(embed(query), top_k=20, filter={"tenant": tid, "acl": user.groups})
sparse = bm25.search(query, top_k=20)
candidates = rrf_fuse(dense, sparse)                 # reciprocal-rank fusion
ranked = reranker.rank(query, dedupe(candidates))[:5]  # cross-encoder

context = "\n\n".join(f"[{i+1}] {c.text}\n(source: {c.meta['title']})"
                      for i, c in enumerate(ranked))
prompt = (
    "Answer using ONLY the context. Cite sources as [n]. "
    "If the answer is not in the context, say you don't know.\n\n"
    f"Context:\n{context}\n\nQuestion: {query}"
)
```

## See Also
- `prompt-engineering-expert` — structuring the grounded generation prompt.
- `llm-testing-expert` — measuring faithfulness and retrieval metrics.
- `sql-expert` — metadata filtering / `pgvector` storage.
- `api-design-expert` — streaming retrieval/answer endpoints.
