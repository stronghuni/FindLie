# FindLie — Intent Map

This map defines expectations for function/method intents based on their naming patterns. It is used during Phase 2 (Semantic Analysis).

| Name pattern | Expected operation | Red flag if missing |
|-------------|-------------------|-------------------|
| `send*`, `email*`, `notify*`, `dispatch*`, `publish*` | HTTP/SMTP/WebSocket call | No `fetch`/`axios`/`http`/`smtp`/`nodemailer` |
| `save*`, `store*`, `persist*`, `write*`, `insert*`, `update*` | DB or file write | No `prisma`/`knex`/`mongoose`/`sql`/`fs.write` |
| `validate*`, `verify*`, `check*`, `isValid*` | Conditional rejection | Always returns `true` or has no `if`/`throw` |
| `fetch*`, `get*`, `load*`, `retrieve*` | External data read | Returns hardcoded data |
| `auth*`, `login*`, `authenticate*`, `authorize*` | Token/password check | No `jwt`/`bcrypt`/`crypto`/`session` |
| `delete*`, `remove*`, `destroy*`, `purge*` | Removal operation | No `DELETE`/`remove`/`destroy`/`unlink` |
| `encrypt*`, `hash*`, `sign*` | Crypto operation | No `crypto`/`bcrypt`/`argon` |

## Secondary signals
- **Ignored parameters:** function accepts arguments but never references them in body.
- **Constant returns:** function always returns the same value regardless of input path.
- **Single-branch control flow:** conditional statements that always evaluate the same way.
- **Fake-async:** function is declared async but performs no await operations.
