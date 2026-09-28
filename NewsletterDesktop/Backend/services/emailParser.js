const monday = date => {
  const d = new Date(date); const day = d.getUTCDay(); d.setUTCDate(d.getUTCDate() - (day === 0 ? 6 : day - 1)); d.setUTCHours(0, 0, 0, 0); return d;
};

const clean = value =>
  value
    .replace(/[\u200B-\u200D\uFEFF]/g, "")  // zero-width chars
    .replace(/\r/g, "")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();

// Collapse multi-line value into a single line, strip leading/trailing curly or straight quotes
const inline = value =>
  clean(value)
    .replace(/\s*\n\s*/g, " ")
    .replace(/^[\u201C\u201D"']|[\u201C\u201D"']$/g, "")
    .trim();

// Gmail's text/html part is the more complete source for some issues. Keep block boundaries before stripping tags.
export function htmlToText(html = "") {
  return clean(html
    .replace(/<(script|style)[^>]*>[\s\S]*?<\/\1>/gi, "")
    .replace(/<\s*br\s*\/?>/gi, "\n")
    .replace(/<\/(p|div|li|h[1-6]|tr|blockquote)>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/gi, " ").replace(/&amp;/gi, "&").replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&ldquo;/gi, "\u201C").replace(/&rdquo;/gi, "\u201D")
    .replace(/&lsquo;/gi, "\u2018").replace(/&rsquo;/gi, "\u2019"));
}

function section(body, heading, nextHeading) {
  const start = body.search(new RegExp(`^\\s*${heading}\\s*$`, "im"));
  if (start < 0) return "";
  const after = body.slice(start).replace(new RegExp(`^\\s*${heading}\\s*`, "i"), "");
  const end = nextHeading ? after.search(new RegExp(`^\\s*${nextHeading}\\s*$`, "im")) : -1;
  return clean(end < 0 ? after : after.slice(0, end));
}

function romanBlocks(value, expected) {
  const markers = [...value.matchAll(/(?:^|\n)\s*(I{1,3})[.)]\s*/gim)];
  return markers
    .map((marker, index) => clean(value.slice(marker.index + marker[0].length, markers[index + 1]?.index)))
    .filter(Boolean)
    .slice(0, expected);
}

/**
 * Extract the quote text from a block.
 *
 * James Clear's format is typically:
 *   \u201CQuote text here.\u201D
 *   -- Attribution Name
 *   Source: URL
 *
 * Or sometimes straight quotes, or no quotes at all for the question.
 * We match the OUTERMOST quote pair to avoid cutting off the start.
 */
function extractQuote(block) {
  // Try curly quotes first (most common in the HTML-rendered version)
  const curlyMatch = block.match(/\u201C([\s\S]+?)\u201D/);
  if (curlyMatch) return curlyMatch[1];

  // Try straight double quotes (plain text version)
  const straightMatch = block.match(/"([\s\S]{6,}?)"/);
  if (straightMatch) return straightMatch[1];

  // No quotes found — return the whole block stripped of source line
  return null;
}

function parseQuote(block) {
  // Strip the Source line first, then work on remaining text
  const sourceMatch = block.match(/(?:^|\n)\s*(?:Source|From)\s*:\s*(.+?)(?:\n|$)/im);
  const withoutSource = block.replace(/(?:^|\n)\s*(?:Source|From)\s*:\s*.+?(?:\n|$)/gim, "\n").trim();

  const quoteText = extractQuote(withoutSource);
  if (!quoteText) return null;

  // Everything before the opening quote character is the attribution
  const quoteIndex = withoutSource.indexOf(quoteText);
  // Walk back to find the opening quote character
  const openingQuoteIndex = Math.max(0, quoteIndex - 1);
  const before = withoutSource.slice(0, openingQuoteIndex).trim();

  // Strip trailing punctuation / dashes from attribution that appear before the quote
  const attribution = before
    .replace(/[-–—]+\s*$/, "")
    .replace(/:\s*$/, "")
    .trim();

  return {
    attribution: inline(attribution),
    quote: inline(quoteText),
    source: inline(sourceMatch?.[1] || ""),
  };
}

export function parseNewsletter({ subject = "", date, text = "", html = "" }) {
  const plain = clean(text);
  const renderedHTML = htmlToText(html);
  // Prefer HTML if it is substantially longer (it often has more complete quote text)
  const body = (renderedHTML.length > plain.length + 120 ? renderedHTML : plain) || renderedHTML;
  const useful = body.split(/want to share this issue/i)[0];

  const topicLine = subject.match(/3\s*[-–—]\s*2\s*[-–—]\s*1\s*:\s*(.+)/i)?.[1] || "";
  const topics = topicLine
    .split(/,\s*|\s+and\s+/i)
    .map(inline)
    .map(item => item.replace(/^and\s+/i, ""))
    .filter(Boolean)
    .slice(0, 3);

  const ideas = romanBlocks(section(useful, "3\\s+Ideas\\s+From\\s+Me", "2\\s+Quotes\\s+From\\s+Others"), 3).map(inline);

  const quoteBlocks = romanBlocks(section(useful, "2\\s+Quotes\\s+From\\s+Others", "1\\s+Question\\s+For\\s+You"), 2);
  const quotes = quoteBlocks.map(parseQuote).filter(Boolean);

  // Question — extract from block (may or may not have quotes around it)
  const questionBlock = section(useful, "1\\s+Question\\s+For\\s+You");
  const questionText = extractQuote(questionBlock) ?? inline(questionBlock);

  const questionStart = questionBlock.indexOf(questionText);
  const openingQuoteIndex = Math.max(0, questionStart - 1);
  const beforeQuestion = questionBlock.slice(0, openingQuoteIndex).trim();
  const questionAttribution = beforeQuestion.replace(/[-–—]+\s*$/, "").replace(/:\s*$/, "").trim() || undefined;

  // The canonical URL appears in the share line, after our display-content cutoff
  const issueUrl = body.match(/https?:\/\/jamesclear\.com\/3-2-1\/[^\s)<]+/i)?.[0] || "https://jamesclear.com/3-2-1";

  const missing = [
    ideas.length !== 3 && "ideas",
    quotes.length !== 2 && "quotes",
    !questionText && "question",
  ].filter(Boolean);

  if (missing.length) {
    throw new Error(
      `3-2-1 parser could not find ${missing.join(", ")}. Keep the source text and adjust the parser for this issue.`
    );
  }

  return {
    receivedDate: new Date(date),
    weekOf: monday(date),
    issueUrl,
    topics,
    ideas,
    quotes,
    question: {
      attribution: questionAttribution ? inline(questionAttribution) : undefined,
      text: inline(questionText),
    },
  };
}
