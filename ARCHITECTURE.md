# DocuManage AI - Architecture & Placement Viva Guide

## 1. System Architecture Diagram

```
+-----------------------------------------------------------------------+
|                              FRONTEND                                 |
|            React 18 + Vite + Tailwind CSS + Responsive UI             |
|                                                                       |
|  [Document Upload (Drag & Drop)]   [Repository List (Newest First)]   |
|  [Document Content Viewer Modal]   [AI Chatbot with Sources Badges]   |
+-----------------------------------+-----------------------------------+
                                    | REST APIs (JSON / Multipart)
                                    v
+-----------------------------------------------------------------------+
|                               BACKEND                                 |
|                     Node.js + Express.js API                          |
|                                                                       |
|  +--------------------+  +--------------------+  +-----------------+  |
|  | Document Controller|  |   Chat Controller  |  |   Swagger UI    |  |
|  +---------+----------+  +---------+----------+  | (/api-docs &    |  |
|            |                       |             |  /api-docs.json)|  |
|            v                       v             +-----------------+  |
|  +--------------------+  +--------------------+                       |
|  | Document Service   |  | Retrieval Service  |                       |
|  | (Storage & Parser) |  | (Tokenize & Rank)  |                       |
|  +---------+----------+  +---------+----------+                       |
|            |                       |                                  |
|            v                       v                                  |
|  +--------------------+  +--------------------+                       |
|  | Document Store     |  | AI Provider Service|                       |
|  | (JSON Persistence) |  | (Gemini / OpenAI / |                       |
|  +--------------------+  |  Offline Heuristic)|                       |
|                          +--------------------+                       |
+-----------------------------------------------------------------------+
```

---

## 2. Core Workflows

### 2.1 Document Ingestion Workflow
1. User uploads a file (`.txt`, `.md`, `.json`).
2. Multer middleware validates extension and MIME type (rejects unallowed formats with HTTP 400).
3. Secure unique filename generated (`<timestamp>-<uuid>.<ext>`) to prevent overwrite attacks.
4. Content is read and text extracted (JSON files are parsed and formatted).
5. Document metadata (`_id`, `originalName`, `fileName`, `mimeType`, `size`, `extractedText`, `uploadedAt`) is saved in persistent JSON storage.
6. Returns HTTP 201 Created.

### 2.2 Question Answering (RAG) Workflow
1. Client sends `POST /api/chat` with `{ "question": "..." }`.
2. Controller validates non-empty string; returns HTTP 400 if empty.
3. Query preprocessor filters English stop words and generates meaningful keyword tokens.
4. **Retrieval Strategy**:
   - Computes query token presence & Term Frequency (TF) across documents.
   - Applies filename boost and exact phrase match bonuses.
   - Extracts top candidate sentences per document.
   - Ranks documents by relevance score descending.
5. Builds a structured context from top-ranked documents.
6. Calls AI Provider:
   - If `GEMINI_API_KEY` exists -> Google Gemini API.
   - If `OPENAI_API_KEY` exists -> OpenAI API.
   - If no key configured -> Built-in intelligent extractive NLP engine (works 100% offline).
7. Returns response with exact schema:
   ```json
   {
     "answer": "...",
     "sources": [
       {
         "_id": "...",
         "originalName": "..."
       }
     ]
   }
   ```

---

## 3. Top Placement Viva Questions & Answers

### Q1: What is RAG (Retrieval-Augmented Generation)?
**Answer**: RAG is an architecture where an AI language model is augmented with external, proprietary knowledge. Instead of relying solely on parametric training memory, relevant document snippets are dynamically retrieved from a local repository and injected into the prompt context for the LLM to generate an accurate, grounded answer with citations.

### Q2: Why did you implement an offline fallback mode for the AI provider?
**Answer**: In real-world enterprise applications and offline evaluation environments (like campus placement evaluations), external API keys may be unavailable, throttled, or expired. The offline fallback implements extractive NLP that ranks matching sentences from the retrieved context and synthesizes a structured response with exact source attribution.

### Q3: How do you prevent file collisions and path traversal attacks?
**Answer**: Uploaded files are renamed using UUID v4 and millisecond timestamps on disk, while the user's `originalName` is preserved strictly in the metadata store. File download uses verified stored filenames rather than arbitrary user-supplied paths.

### Q4: Why is document sorting done "newest first"?
**Answer**: Users expect the most recent policy updates or handbooks to appear at the top of their repository. In `getAll()`, documents are sorted by `uploadedAt` in descending order.

### Q5: How do you test the API?
**Answer**: Using automated integration tests with Jest and Supertest that exercise endpoints without launching an external server process. The tests cover upload, invalid file types, listing, download, deletion, 404s, empty questions, source ranking, and fallback responses.
