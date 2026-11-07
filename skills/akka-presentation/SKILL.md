---
name: akka-presentation
description: Tyler's standard for every presentation, deck, keynote, briefing, customer session or narrated demo film, in any project. Use whenever asked to design, build, restyle or review a presentation, slides, a deck, a talk, a walkthrough, an overview film or a video with voice-over. It sets the method (storyboard first, one idea per scene, render and look at every frame), the Akka visual language, the language rules (complete plain sentences, never selling), and the voice and film pipeline.
---

# Akka presentation standard

Tyler's bar is the main Akka demo: `C:\Users\tyler\ai-console\demo\mock` (the animated film),
`demo\talk` (the governance keynote) and `demo\full` (the recorded console demo). Every new presentation
is held to that bar. It came out professional because of the method below, not because of one prompt.
Follow the method in order; skipping the storyboard or cramming a frame is what made weaker decks fail.

## 1. Understand before designing

- Read the sources first: meeting notes, requirements, the audience, what they asked for, what is
  internal. Separate what may be shown to the audience from what is internal-only (politics, competitors,
  other customers' names, pricing, roadmap dates). Internal notes go in a separate presenter brief, never
  in the deck, its speaker notes or its file.
- Verify every technical claim against the product docs (`akka-context/` or doc.akka.io) and cite the
  source in the presenter brief. Figures from a managed platform never stand in for self-managed ones.
  Laptop measurements are labelled as such.
- Ask only what is genuinely the user's call: audience, length, purpose, due date, live versus rendered.

## 2. Storyboard before any code

Write `storyboard.md` first and show it before building:
- **One spine.** One idea carries the whole piece (the main demo: "a change travelling safely", one system
  followed end to end). Everything else serves it.
- **One idea per scene.** Each scene has its visual, its narration (spoken words, ~2.5 words a second) and
  its duration. If a scene needs two ideas, it is two scenes.
- **Show, don't list.** A component list is not an architecture. Show what components do: flows, interaction
  (sequence) diagrams, what moves where. Explain every term the first time it appears (for example
  "parity", "parity harness") in one plain sentence.
- **Say what went in.** When something was "built from a specification", show what the specification held.

## 3. Build on the engine, never from scratch

- Start from the deck engine: `demo\talk\lib\deck.js`, `kit.js`, `presenter.js` over `demo\mock\lib`
  (`core.js` rise, fade, draw, countUp, rail, dotGrid, cardGlow; `camera.js` loop, abs). A deck lives in its
  own folder (pattern: `demo\rbc\`) and reuses these by relative path; it does not copy them.
- Every scene is a pure function of time: `render(root)` once, `at(t)` sets every style for instant t, with
  beats `{ t, say }`. No state carried between frames, so it scrubs, prints and captures.
- Interaction diagrams: `demo\rbc\lib\seq.js` (`Seq.build`, `Seq.at`).

## 4. Visual language (akka.io)

- Pure black, one yellow `#FFCE4A`, Instrument Sans 700 tracked tight for titles; uppercase eyebrows with no
  rule beside them; the faint 48 px yellow dot grid; hairline cards with even borders (never a one-sided
  accent border); rise-in reveals, line draws, count-ups, dashed flow rails with moving work.
- Status colours only for status: cyan `#00DBDD`, green `#72D35B`, red-orange `#FF5400`.
- Mono only for code and identifiers. No chapter numbering. No rule bars beside words.
- **Few, large elements per frame** (the keynote's system scene: about nine cards, label + big name + one
  line). The subject of the current sentence glows; everything else steps back. Motion carries meaning:
  work travels the connector being spoken about.
- Projector and screen-share sizes: headlines 64–84 px, body 26–36 px, labels 20–26 px, on 1920×1080 with
  150 px gutters. Nothing overlaps, nothing runs off the stage.

## 5. Language

- Every title, subtitle, panel sentence and bullet is a complete sentence. No fragments ("Fast, and still
  under control."), no noun lists as subtitles. Labels, chips, table cells and figure captions may be short.
- Plain engineering statements. Never selling: no "fast", "under control", "prove", "best", no chips that
  pitch, no claims the evidence does not carry.
- No negative framing ("no cloud stack", "not on the critical path"); say what is, positively.
- Never write "event store" or "design target".
- Do not set the customer's dates or tell them what must happen by when; offer milestones "to target with
  you" and "to discuss together". The customer sets the plan.
- A customer-facing opening is personal: greet the named people, say what we appreciate, then the overview.
- Canadian or British spelling when the audience uses it (cheque, centre).

## 6. Render and look at every frame

- Render every beat: `node demo/talk/render/render.mjs --deck=<folder> --pdf=<name>.pdf` (`--only=<ids>`
  while iterating). Open the PNGs and look: overlaps, text under lines, cards on titles, anything clipped.
  Fix and re-render until each frame is clean. Never hand over an unseen frame.
- Keep a presenter brief (`BRIEF.md`): timing per section and speaker, watch-outs, the source of every
  figure, questions the docs do not answer.
- Deliver as a local file opened in Edge (never published). Confidential customer material never goes into
  a public repository.

## 7. Narrated film

- Narration is written for the ear, per beat, in `film/narration.json`; then
  `node demo/sample/tts.mjs --dir=<film folder>` with Tyler Pro (`ELEVENLABS_VOICE_ID=Bnd74uonOEZYmdUm8SZs`
  until the user variable is updated), `eleven_multilingual_v2`, `ELEVENLABS_OUTPUT_FORMAT=mp3_44100_192`,
  no voice_settings, no denoise.
- Names and terms the voice misreads go in `SPOKEN` in `tts.mjs`; generate a few spellings in context, let
  Tyler pick, and pin the chosen take as the cached clip.
- Render with the film renderer pattern (`demo\rbc\film\render.mjs`): each beat animates, its line starts
  0.35 s in, the beat ends 2.2 s after the line; slides change through black; each line tapers over 0.55 s;
  the music bed (`demo\mock\sound\music.mp3`) sits ~18 dB under the voice and ducks a further 18 dB under each
  line on a fixed curve; one fixed gain to −16 LUFS, −1.8 dBTP; AAC 192k 48 kHz; SRT captions.
- Checks before handing over: length; `blackdetect` shows no dark run over 1.2 s outside cards; integrated
  loudness −16 to −17.5 LUFS; no gap between lines over 4.5 s; a contact sheet of frames across the film.
  Copy the MP4, silent MP4 and SRT to Downloads and open the MP4 in Edge.

## 8. When Tyler corrects something

Fix it everywhere it applies, then add the rule here (or to the project's README rules) so it holds for
every future presentation. When the method itself changes, update `ai-console\demo\storytelling.md`, the
write-up that explains to colleagues how the demos are made.
