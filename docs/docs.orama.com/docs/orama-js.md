---
Source: https://docs.orama.com/docs/orama-js
Generated: 2026-01-05
Updated: 2026-01-05
---

# Introduction

Orama is an [open source](https://github.com/oramasearch/orama), high performance full-text and vector search engine entirely written in TypeScript, with zero dependencies.

## [Requirements](#requirements)

A JavaScript runtime is the **only** requirement. Orama has been designed to work on any JS runtime and has no dependencies.

## [Installation](#installation)

You can install Orama using any JavaScript package manager of your choice.

```bash
npm install orama
```

Or import it directly in a browser module:

```html
<html>
  <body>
    <script type="module">
      import {
        create,
        search,
        insert,
      } from "https://unpkg.com/@orama/orama@latest/dist/index.js";

      // ...
    </script>
  </body>
</html>
```

## [Basic usage](#basic-usage)

```javascript
import { create, search, insert } from "@orama/orama";

// Create a new Orama instance
const db = create({
  schema: {
    name: "string",
    description: "string",
    price: "number",
    meta: {
      rating: "number",
    },
  },
});

// Insert documents into the database
insert(db, {
  name: "Wireless Headphones",
  description: "Experience immersive sound quality with these noise-cancelling wireless headphones.",
  price: 99.99,
  meta: {
    rating: 4.5,
  },
});

// Search for documents
const searchResult = search(db, {
  term: "headphones",
});

console.log(searchResult.hits.map((hit) => hit.document));
```

For more information, check out the [Usage](/docs/orama-js/usage/create) section.

## [CommonJS Imports](#commonjs-imports)

Orama ships **ESM** modules by default. This allows us to move faster when providing new features and bug fixes, as well as using the `"exports"` field in `package.json` to provide a better developer experience.

CommonJS imports are still supported, but we suggest you to migrate to ESM.

## [TypeScript](#typescript)

Set `moduleResolution` in the `compilerOptions` in your `tsconfig.json` to be either `Node16` or `NodeNext`.

When importing types, always refer to the standard orama import:

```python
import type { Language } from "@orama/orama";
```
