const monday = date => {
  const d = new Date(date); const day = d.getUTCDay(); d.setUTCDate(d.getUTCDate() - (day === 0 ? 6 : day - 1)); d.setUTCHours(0, 0, 0, 0); return d;
};
const clean = value => value.replace(/[\u200B-\u200D\uFEFF]/g, "").replace(/\r/g, "").replace(/[ \t]+\n/g, "\n").replace(/\n{3,}/g, "\n\n").trim();
const inline = value => clean(value).replace(/\s*\n\s*/g, " ").replace(/^[“"]|[”"]$/g, "").trim();

// Gmail's text/html part is the more complete source for some issues. Keep block boundaries before stripping tags.
export function htmlToText(html = "") {
  return clean(html
    .replace(/<(script|style)[^>]*>[\s\S]*?<\/\1>/gi, "")
    .replace(/<\s*br\s*\/?>/gi, "\n")
    .replace(/<\/(p|div|li|h[1-6]|tr|blockquote)>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/gi, " ").replace(/&amp;/gi, "&").replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;/gi, "'").replace(/&ldquo;/gi, "“").replace(/&rdquo;/gi, "”"));
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
  return markers.map((marker, index) => clean(value.slice(marker.index + marker[0].length, markers[index + 1]?.index))).filter(Boolean).slice(0, expected);
}

function quoted(value) {
  const curly = value.match(/“([\s\S]+?)”/); if (curly) return curly[1];
  return value.match(/"([\s\S]{4,}?)"/)?.[1];
}

function parseQuote(block) {
  const sourceMatch = block.match(/(?:^|\n)\s*Source\s*:\s*([\s\S]*?)(?=$|\n\s*$)/im);
  let rawText = block.replace(/(?:^|\n)\s*Source\s*:\s*([\s\S]*?)(?=$|\n\s*$)/im, "").trim();

  let attribution = "";
  let quote = rawText;

  // If there are explicit quotes, try to separate attribution, but only if it looks like an attribution (e.g. ends with colon and has a newline)
  const curly = rawText.match(/^([\s\S]*?:\s*\n+)?(?:[“"]\s*)?([\s\S]+?)(?:[”"]\s*)?$/);
  if (curly && curly[1]) {
     attribution = curly[1].trim();
     quote = curly[2].trim();
  } else {
     // If no clear attribution, or it doesn't end with colon/newline, treat the whole block as the quote.
     // Remove wrapping quotes if present.
     quote = rawText.replace(/^[“"]|[”"]$/g, "").trim();
  }

  return { attribution: inline(attribution), quote: inline(quote), source: inline(sourceMatch?.[1] || "") };
}

export function parseNewsletter({ subject = "", date, text = "", html = "" }) {
  const plain = clean(text); const renderedHTML = htmlToText(html);
  const body = (renderedHTML.length > plain.length + 120 ? renderedHTML : plain) || renderedHTML;
  const useful = body.split(/want to share this issue/i)[0];
  const topicLine = subject.match(/3\s*[-–—]\s*2\s*[-–—]\s*1\s*:\s*(.+)/i)?.[1] || "";
  const topics = topicLine.split(/,\s*|\s+and\s+/i).map(inline).map(item => item.replace(/^and\s+/i, "")).filter(Boolean).slice(0, 3);
  const ideas = romanBlocks(section(useful, "3\\s+Ideas\\s+From\\s+Me", "2\\s+Quotes\\s+From\\s+Others"), 3).map(inline);
  const quoteBlocks = romanBlocks(section(useful, "2\\s+Quotes\\s+From\\s+Others", "1\\s+Question\\s+For\\s+You"), 2);
  const quotes = quoteBlocks.map(parseQuote).filter(Boolean);
  const questionBlock = section(useful, "1\\s+Question\\s+For\\s+You"); const questionText = quoted(questionBlock);
  const questionStart = questionText ? questionBlock.indexOf(questionText) : -1;
  const attribution = questionStart > 0 ? inline(questionBlock.slice(0, questionStart).replace(/[“"]\s*$/, "")) : undefined;
  // The canonical URL appears in the share line, which deliberately sits after our display-content cutoff.
  const issueUrl = body.match(/https?:\/\/jamesclear\.com\/3-2-1\/[^\s)<]+/i)?.[0] || "https://jamesclear.com/3-2-1";
  const missing = [ideas.length !== 3 && "ideas", quotes.length !== 2 && "quotes", !questionText && "question"].filter(Boolean);
  if (missing.length) throw new Error(`3-2-1 parser could not find ${missing.join(", ")}. Keep the source text and adjust the parser for this issue.`);
  return { receivedDate: new Date(date), weekOf: monday(date), issueUrl, topics, ideas, quotes, question: { attribution: attribution || undefined, text: inline(questionText) } };
}
