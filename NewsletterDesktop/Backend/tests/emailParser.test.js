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
"First quote continues over a second line."
Source: Book One

II.
Author Two
"Second quote."
Source: Book Two

1 Question For You

Writer
"What should you do next?"

Want to share this issue`,
  });
  assert.equal(entry.ideas[0], "First full idea line one. Continues on line two.");
  assert.equal(entry.quotes[0].quote, "First quote continues over a second line.");
  assert.equal(entry.quotes[1].source, "Book Two");
  assert.equal(entry.question.text, "What should you do next?");
});

test("curly-quoted quote starting with 'A' is fully captured", () => {
  const entry = parseNewsletter({
    subject: "3-2-1: decisions, alive, and systems",
    date: "Thu, 24 Sep 2026 10:00:00 +0000",
    text: `3 Ideas From Me

I.
Idea one.

II.
Idea two.

III.
Idea three.

2 Quotes From Others

I.
Somebody Famous
\u201CThis is the first quote.\u201D
Source: Some Book

II.
Another Person
\u201CA good heuristic when making a big decision: would choosing this make me feel more alive?\u201D
Source: Another Book

1 Question For You

\u201CWhat decision are you avoiding?\u201D

Want to share this issue`,
  });
  assert.equal(
    entry.quotes[1].quote,
    "A good heuristic when making a big decision: would choosing this make me feel more alive?"
  );
  assert.equal(entry.quotes[1].source, "Another Book");
  assert.equal(entry.question.text, "What decision are you avoiding?");
});

test("question with no attribution is parsed correctly", () => {
  const entry = parseNewsletter({
    subject: "3-2-1: focus, courage, and goals",
    date: "Thu, 24 Sep 2026 10:00:00 +0000",
    text: `3 Ideas From Me

I.
Idea one.

II.
Idea two.

III.
Idea three.

2 Quotes From Others

I.
Person A
\u201CQuote one.\u201D
Source: Book A

II.
Person B
\u201CQuote two.\u201D
Source: Book B

1 Question For You

\u201CWhat would you attempt if you knew you could not fail?\u201D

Want to share this issue`,
  });
  assert.equal(entry.question.text, "What would you attempt if you knew you could not fail?");
  assert.equal(entry.question.attribution, undefined);
});
