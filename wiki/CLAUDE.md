# Wiki Schema — reptrack

This file defines the structure, conventions, and workflows for this wiki.
Claude should follow these rules when ingesting sources, answering queries, and updating pages.

---

## Directory Structure

```
wiki/
├── CLAUDE.md             ← this file (schema + rules)
├── index.md              ← master catalog of all pages
├── log.md                ← append-only record of all operations
├── _templates/
│   └── note.md           ← template for new wiki pages
├── sources/              ← raw source files (immutable, never edited)
└── <topic>/              ← one folder per topic domain
    └── *.md              ← wiki pages for that topic
```

Current topic folders:
- `bash/` — bash scripting, shell commands, unix concepts
- `kubernetes/` — kubernetes manifests, kubectl, deployments

---

## Page Format

Every wiki page must follow this structure:

```markdown
# Title

**Summary:** One sentence describing what this page covers.

**Tags:** tag1, tag2, tag3

**Last updated:** YYYY-MM-DD

---

## <Section>

...content...

## See Also
- [[related-page]]
```

---

## Ingesting a Source

When given a source file to ingest:

1. Read the full source
2. Extract key concepts, commands, patterns, and explanations
3. Find existing wiki pages that are related — update them with new info
4. Create new pages for concepts not yet covered
5. Update `index.md` with any new or changed pages
6. Append an entry to `log.md`

Do NOT copy the source verbatim. Synthesize and integrate.

---

## Answering a Query

When asked a question:

1. Check `index.md` for relevant pages
2. Read those pages
3. Synthesize an answer with citations to wiki pages
4. If the answer reveals a gap, create or update a page
5. Append to `log.md`

---

## log.md Format

Each entry in `log.md`:

```
## YYYY-MM-DD — <operation>
- Source/Query: <name or question>
- Pages affected: page1.md, page2.md
- Notes: <brief description of what changed>
```

---

## Conventions

- File names: lowercase, hyphens, no spaces (e.g. `file-permissions.md`)
- Cross-links use `[[page-name]]` syntax
- Code blocks always specify the language (` ```bash `, ` ```yaml `)
- Keep pages focused — one concept per page is better than one giant page
