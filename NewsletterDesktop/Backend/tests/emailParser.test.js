import test from "node:test";
import assert from "node:assert/strict";
import { parseNewsletter } from "../services/emailParser.js";

test("retains every line in a normal 3-2-1 issue", () => {
  const entry = parseNewsletter({
    subject: "3-2-1: opportunity, volume, and decisions", date: "Thu, 24 Sep 2026 10:00:00 +0000",
    text: `3 Ideas From Me

I.
First full idea line one.
Continues on line two.

II.
Second idea.

III.
Third idea.

2 Quotes From Others

I.
Author One
“First quote continues over a second line.”
Source: Book One

II.
Author Two
“Second quote.”
Source: Book Two

1 Question For You

Writer
“What should you do next?”

Want to share this issue`,
  });
  assert.equal(entry.ideas[0], "First full idea line one. Continues on line two.");
  assert.equal(entry.quotes[0].quote, "First quote continues over a second line.");
  assert.equal(entry.quotes[1].source, "Book Two");
  assert.equal(entry.question.text, "What should you do next?");
});
